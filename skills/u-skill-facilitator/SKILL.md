---
name: u-skill-facilitator
description: "/u-discuss 세션을 관리하고, 마이크로 커맨드 파싱, 세션 직렬화/복원, 결과물 분류 및 백로그 반영을 수행하는 내부 엔진."
---

# u-skill-facilitator -- Discussion Facilitation Engine

`/u-discuss` 세션의 전체 lifecycle을 관리한다. 세션 생성, 마이크로 커맨드 파싱, 태그 분류, 세션 일시정지/재개, wrap 시 결과물을 SSoT에 반영하고, 트랜스크립트를 아카이브한다.

**Owner Agent:** u-agent-orchestrator

---

## 1. Session Types

| Type | Purpose | Default Participants | Phase Model |
|------|---------|---------------------|-------------|
| `brainstorm` | 발산적 아이디어 생성 | planner, sa, ux | Single (diverge) |
| `review` | 수렴적 평가/검토 | Owner agent + guardian | Single (evaluate) |
| `decision` | 트레이드오프 분석 + 결정 | All agents | Single (decide) |
| `workshop` | 복합 다단계 세션 | All agents | 4-Phase (diverge→group→prioritize→decide) |
| `retro` | Keep/Problem/Try 회고 | All agents | 3-Phase (collect→analyze→action) |

---

## 2. Session Creation

### createSession(type, topic, scope, options)

새 토론 세션을 초기화한다.

**프로세스:**

1. 세션 ID 생성: `DS-{NNN}` (전역 sequential, `_sessions/_counter.json`에서 관리)
2. 참여 에이전트 결정:
   - `options.agents` 지정 시 → 해당 에이전트
   - 미지정 시 → 세션 유형별 기본값
3. 컨텍스트 로드:
   - `options.context` 지정 시 → 해당 문서/항목 로드
   - 미지정 시 → scope의 `_index.json`에서 관련 문서 자동 탐지
4. 세션 파일 생성: `_sessions/DS-{NNN}.json`

**세션 파일 구조:**

```json
{
  "id": "DS-{NNN}",
  "type": "brainstorm",
  "topic": "결제 시스템 개선 방안",
  "scope": "retail",
  "status": "active",
  "startedAt": "{ISO 8601}",
  "participants": ["u-agent-planner", "u-agent-sa", "u-agent-ux"],
  "context": ["FR-0001", "screens.md"],
  "currentPhase": null,
  "transcript": [],
  "tags": {
    "idea": [],
    "decide": [],
    "concern": [],
    "action": []
  },
  "checkpoints": []
}
```

---

## 3. Micro-Command Parsing

### parseCommand(input)

세션 중 사용자 입력을 파싱하여 마이크로 커맨드를 식별한다.

### Agent Opinion Requests

| Pattern | Action |
|---------|--------|
| `@planner {question}` | u-agent-planner에게 의견 요청 |
| `@builder {question}` | u-agent-builder에게 의견 요청 |
| `@guardian {question}` | u-agent-guardian에게 의견 요청 |
| `@orchestrator {question}` | u-agent-orchestrator에게 의견 요청 |
| `@all {question}` | 모든 참여 에이전트에게 의견 요청 |

**처리 로직:**

```
function handleAgentRequest(agent, question, session):
  // 에이전트 역할에 맞는 관점에서 응답 생성
  context = loadSessionContext(session)
  response = dispatch(agent, "opine", { question, context, session.topic })

  // transcript에 기록
  session.transcript.push({
    type: "agent-opinion",
    agent: agent,
    question: question,
    response: response,
    timestamp: now()
  })
```

### Tagging Commands

| Pattern | Tag | Destination |
|---------|-----|-------------|
| `/idea "content"` | idea | `_classified/requirements/` |
| `/decide "content"` | decide | `_classified/decisions/` |
| `/concern "content"` | concern | `_classified/constraints/` or `questions/` |
| `/action "content"` | action | `_backlog/` |

**처리 로직:**

```
function handleTag(tag, content, session):
  item = {
    id: generateTagId(tag, session),
    content: content,
    taggedBy: "user",
    taggedAt: now(),
    sessionId: session.id
  }
  session.tags[tag].push(item)
  session.transcript.push({
    type: "tag",
    tag: tag,
    content: content,
    timestamp: now()
  })
```

### Session Control Commands

| Pattern | Action |
|---------|--------|
| `/next-phase` | Workshop 다음 Phase로 전환 |
| `/pause` | 세션 일시 중단 + 상태 저장 |
| `/resume` | 중단된 세션 재개 |
| `/wrap` | 세션 종료 + 결과물 반영 |
| `/transcript` | 현재까지 대화 기록 표시 |
| `/summary` | 태그 항목 요약 표시 |

---

## 4. Workshop Phase Management

Workshop 세션은 4개 Phase를 순차 진행한다.

### Phase Transitions

```
Phase 1: Diverge ──/next-phase──→ Phase 2: Group
Phase 2: Group ──/next-phase──→ Phase 3: Prioritize
Phase 3: Prioritize ──/next-phase──→ Phase 4: Decide
```

### Phase Rules

| Phase | Goal | Allowed Tags | Rules |
|-------|------|-------------|-------|
| Diverge | 아이디어 최대 발산 | `/idea` | 비판 금지, 양 우선 |
| Group | 아이디어 그룹핑 | -- | 중복 제거, 카테고리 분류 |
| Prioritize | 우선순위 정렬 | -- | MoSCoW 또는 Impact/Effort |
| Decide | 최종 선정 + 액션 | `/decide`, `/action` | FDE 최종 결정 |

### Phase Transition Logic

```
function nextPhase(session):
  if session.type !== "workshop":
    return error("Only workshop sessions have phases")

  phases = ["diverge", "group", "prioritize", "decide"]
  currentIdx = phases.indexOf(session.currentPhase)

  if currentIdx >= phases.length - 1:
    return error("Already in final phase. Use /wrap to finish.")

  // 역방향 전환 불가
  session.currentPhase = phases[currentIdx + 1]
  saveCheckpoint(session)

  session.transcript.push({
    type: "phase-transition",
    from: phases[currentIdx],
    to: session.currentPhase,
    timestamp: now()
  })
```

---

## 5. Context Serialization & Restoration

### pause(sessionId)

세션 상태를 직렬화하여 저장한다.

```
function pause(sessionId):
  session = loadSession(sessionId)
  session.status = "paused"
  session.pausedAt = now()

  checkpoint = {
    sessionId: sessionId,
    status: "paused",
    currentPhase: session.currentPhase,
    transcriptLength: session.transcript.length,
    tagCounts: {
      idea: session.tags.idea.length,
      decide: session.tags.decide.length,
      concern: session.tags.concern.length,
      action: session.tags.action.length
    },
    savedAt: now()
  }
  session.checkpoints.push(checkpoint)
  saveSession(session)
```

### resume(sessionId)

중단된 세션을 복원한다.

```
function resume(sessionId):
  session = loadSession(sessionId)
  if session.status !== "paused":
    return error("Session is not paused")

  session.status = "active"
  session.resumedAt = now()

  // 복원 요약 표시
  showResumeSummary(session)
  saveSession(session)
```

---

## 6. Session Wrap

### wrap(sessionId)

세션을 종료하고 결과물을 SSoT에 반영한다.

**프로세스:**

1. **태그 항목 분류 및 반영:**

   | Tag | Target Path | Item Schema |
   |-----|------------|-------------|
   | `/idea` | `_classified/requirements/` | `{ id, type: "FR", title, description, status: "extracted", source: { session } }` |
   | `/decide` | `_classified/decisions/` | `{ id: "DC-{NNN}", date, topic, decision, rationale, participants, source: { session } }` |
   | `/concern` | `_classified/constraints/` or `_classified/questions/` | `{ id, type, description, impact, status: "open", source: { session } }` |
   | `/action` | `_backlog/_index.json` | `{ type: "improvement", title, priority: "Medium", status: "todo", source: "discuss" }` |

2. **소스 메타데이터 부착:**
   모든 항목에 세션 출처를 기록한다.
   ```json
   {
     "source": {
       "session": "DS-{NNN}",
       "type": "{sessionType}",
       "topic": "{topic}",
       "taggedAt": "{ISO 8601}"
     }
   }
   ```

3. **인덱스 갱신:**
   - `_classified/` 각 카테고리의 `_index.json` 갱신
   - `_backlog/_index.json` 갱신

4. **세션 아카이브:**
   - status → `archived`
   - 전체 transcript 보존
   - `_sessions/DS-{NNN}.json` 최종 저장

5. **Wrap Summary 생성:**
   세션 결과 요약을 사용자에게 표시한다.

---

## 7. Transcript Management

### Transcript Entry Types

| Type | Fields |
|------|--------|
| `user-input` | speaker, content, timestamp |
| `agent-opinion` | agent, question, response, timestamp |
| `tag` | tag, content, taggedBy, timestamp |
| `phase-transition` | from, to, timestamp |
| `system` | message, timestamp |

### Rules

- Transcript는 append-only (수정/삭제 금지)
- 세션 종료 후에도 보존 (아카이브)
- 최대 500 entries (초과 시 오래된 항목 요약 + 보존)

---

## 8. Safety Rules

1. 동시 활성 세션 최대 3개 (초과 시 기존 세션 pause 요청)
2. 세션 데이터는 항상 `_sessions/`에 파일로 저장 (메모리 유실 방지)
3. `/wrap` 전까지 SSoT 문서 직접 수정 금지 (태그로만 수집)
4. brainstorm 세션에서 비판/평가 내용 감지 시 facilitator가 리다이렉트
5. decision 세션에서 FDE 최종 결정 없이 종료 불가
6. retro 세션은 실제 iteration 데이터 없이 진행 불가
7. transcript는 불변 (수정/삭제 금지)
8. workshop의 `/next-phase`는 순방향만 (이전 Phase 복귀 불가)
