---
name: u-discuss
description: "다자간 토론 세션. brainstorm, review, decision, workshop, retro 5가지 유형으로 구조화된 협업을 수행하고, 결과를 SSoT에 반영한다."
triggers:
  - "/u-discuss"
  - "discuss"
  - "토론"
  - "브레인스토밍"
  - "리뷰"
  - "회고"
---

# u-discuss -- Structured Collaboration Sessions

`/u-discuss [scope] [type] "topic" [--wrap]` 명령으로 구조화된 다자간 토론 세션을 진행한다. 5가지 세션 유형을 지원하며, 결과물을 SSoT에 자동 반영한다.

**Primary Agent:** u-agent-orchestrator (engine-facilitator 사용)

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 자동 선택 |
| `type` | Required | 세션 유형: `brainstorm`, `review`, `decision`, `workshop`, `retro` |
| `"topic"` | Required | 토론 주제 (따옴표로 감싸기 권장) |

## Flags

| Flag | Description |
|------|-------------|
| `--wrap` | 세션 종료 시 결과물을 SSoT에 자동 반영 |
| `--agents "list"` | 참여 에이전트 지정 (기본: 유형별 자동 선택) |
| `--context "refs"` | 참고 문서/항목 ID 지정 (예: "FR-0001, screens.md") |

---

## Execution Flow

### Step 1: Initialize Session

1. 세션 ID 생성: `DS-{NNN}` (전역 sequential)
2. `_sessions/` 디렉토리에 세션 파일 생성:
   ```json
   {
     "id": "DS-{NNN}",
     "type": "{type}",
     "topic": "{topic}",
     "scope": "{app}",
     "status": "active",
     "startedAt": "{ISO 8601}",
     "participants": ["{agents}"],
     "context": ["{refs}"],
     "transcript": [],
     "tags": { "idea": [], "decide": [], "concern": [], "action": [] },
     "currentPhase": null
   }
   ```
3. 관련 문서/항목 로드 (`--context` 기반 또는 자동)
4. 참여 에이전트 결정 (유형별 기본값 또는 `--agents`)

### Step 2: Session Type Execution

---

## Session Type 1: brainstorm

**목적:** 발산적 사고. 비판 없이 아이디어를 최대한 확장.

**기본 참여:** u-agent-planner, u-agent-sa, u-agent-ux

**프로세스:**

1. **Diverge Phase:**
   - 에이전트가 topic에 대해 각자 관점에서 아이디어 제시
   - planner: 비즈니스/요구사항 관점
   - sa: 기술/아키텍처 관점
   - ux: 사용자 경험 관점
   - 사용자도 자유롭게 아이디어 추가 가능

2. **규칙:**
   - 비판/평가 금지 (수렴은 review에서)
   - 양 우선 (질은 나중에 정제)
   - 기존 아이디어에 빌드업 장려
   - 야생적 아이디어 환영

3. **출력:**
   - 모든 아이디어를 transcript에 기록
   - `/idea` 태그된 항목 추출

**wrap 시 결과:**
- `/idea` 태그 항목 → `_classified/requirements/` (status: extracted)
- 세션 아카이브 → `_sessions/DS-{NNN}.json`

---

## Session Type 2: review

**목적:** 수렴적 평가. 에이전트가 분석을 제시하고 FDE가 판정.

**기본 참여:** 대상 문서의 Owner 에이전트 + u-agent-guardian

**프로세스:**

1. **Presentation Phase:**
   - Owner 에이전트가 대상 문서/항목의 분석 제시
   - Guardian이 검증 관점에서 코멘트
   - 주요 포인트: 완성도, 일관성, 누락 사항, 위험 요소

2. **Evaluation Phase:**
   - FDE(사용자)가 항목별로 판정:
     - **Approve:** 승인 → status = Review 또는 Final
     - **Revise:** 수정 요청 → 에이전트가 즉시 반영
     - **Reject:** 기각 → status 유지, 사유 기록

3. **출력:**
   - 판정 결과 기록
   - `/decide` 태그된 항목 추출

**wrap 시 결과:**
- `/decide` 태그 항목 → `_classified/decisions/`
- 대상 문서 status 갱신 (Approve → Review/Final)
- 세션 아카이브

---

## Session Type 3: decision

**목적:** 트레이드오프 분석. 선택지별 장단점을 분석하고 FDE가 결정.

**기본 참여:** 전체 에이전트 (@all)

**프로세스:**

1. **Options Presentation:**
   - 에이전트가 선택지 나열 (자동 또는 사용자 제시)
   - 각 선택지에 대해:
     ```markdown
     ### Option A: {title}
     **Pros:** {장점 목록}
     **Cons:** {단점 목록}
     **Impact:** {영향 범위 - 문서, 코드, 일정}
     **Risk:** {위험 수준 - Low/Medium/High}
     **Effort:** {예상 공수}
     ```

2. **Agent Opinions:**
   - 각 에이전트가 자기 관점에서 선호 옵션 + 근거 제시
   - planner: 요구사항 적합성
   - sa: 기술 타당성
   - ux: 사용자 경험 영향
   - builder: 구현 복잡도
   - guardian: 테스트/검증 용이성

3. **Decision:**
   - FDE가 최종 결정 + 근거(rationale) 기록
   - 결정 사항은 `/decide` 태그

**wrap 시 결과:**
- `/decide` → `_classified/decisions/DC-{NNN}.json`:
  ```json
  {
    "id": "DC-{NNN}",
    "date": "{ISO 8601}",
    "topic": "{topic}",
    "options": [...],
    "decision": "{selected option}",
    "rationale": "{FDE의 근거}",
    "impact": ["{affected items}"],
    "participants": ["{agents}"]
  }
  ```
- 세션 아카이브

---

## Session Type 4: workshop

**목적:** 다단계 복합 세션. Diverge → Group → Prioritize → Decide.

**기본 참여:** 전체 에이전트 (@all)

**4개 Phase:**

1. **Phase 1: Diverge** (brainstorm과 동일)
   - 자유 아이디어 발산
   - `/next-phase`로 다음 단계 전환

2. **Phase 2: Group**
   - Phase 1 아이디어를 카테고리별 그룹핑
   - 에이전트가 자동 분류 제안 → 사용자 확인/수정
   - 중복 제거, 유사 항목 병합

3. **Phase 3: Prioritize**
   - 그룹별 우선순위 정렬
   - MoSCoW 또는 Impact/Effort 매트릭스 적용
   - 에이전트 의견 + 사용자 최종 결정

4. **Phase 4: Decide**
   - 최종 선정 항목 확정
   - 각 항목에 액션 아이템 할당
   - `/action` 태그로 액션 기록

**wrap 시 결과:**
- Phase 1 `/idea` → `_classified/requirements/`
- Phase 4 `/decide` → `_classified/decisions/`
- Phase 4 `/action` → `_backlog/` (improvement type)
- 세션 아카이브

---

## Session Type 5: retro

**목적:** Keep / Problem / Try 회고. 데이터 기반 분석.

**기본 참여:** 전체 에이전트 (@all)

**프로세스:**

1. **Data Collection:**
   - 에이전트가 현재 iteration 데이터 자동 수집:
     - Phase별 소요 시간
     - 결함 패턴 분석
     - 공수 예측 vs 실제
     - 가정 정확도
     - 백로그 완료율

2. **Keep (잘한 점):**
   - 에이전트가 데이터 기반 인사이트 제시
   - 사용자가 추가 항목 입력

3. **Problem (문제점):**
   - 에이전트가 결함 패턴, 지연 원인, 병목 분석
   - 사용자가 추가 문제점 제시
   - `/concern` 태그

4. **Try (다음 개선):**
   - Problem 항목에 대한 개선 방안 제시
   - 구체적 액션 아이템으로 변환
   - `/action` 태그

**wrap 시 결과:**
- `/concern` → `_classified/constraints/` 또는 `_classified/questions/`
- `/action` → `_backlog/` (improvement type)
- 전체 → `docs/common/project/retrospective.md` 갱신
- 세션 아카이브

---

## Micro-Commands (세션 중 사용)

### Agent Opinion Requests

| Command | Description |
|---------|-------------|
| `@planner` | Planner 에이전트 의견 요청 |
| `@builder` | Builder 에이전트 의견 요청 |
| `@guardian` | Guardian 에이전트 의견 요청 |
| `@ux` | UX 에이전트 의견 요청 |
| `@sa` | SA 에이전트 의견 요청 |
| `@all` | 전체 에이전트 의견 요청 |

### Tagging

| Command | Description | Wrap Destination |
|---------|-------------|-----------------|
| `/idea` | 아이디어 태깅 | `_classified/requirements/` |
| `/decide` | 결정 사항 태깅 | `_classified/decisions/` |
| `/concern` | 우려/문제 태깅 | `_classified/constraints/` 또는 `questions/` |
| `/action` | 액션 아이템 태깅 | `_backlog/` |

사용법:
```
/idea "사용자 프로필에 활동 히스토리 표시"
/decide "REST API 대신 GraphQL 사용"
/concern "외부 결제 API 응답 시간 불확실"
/action "Playwright E2E 테스트 자동화 파이프라인 구축"
```

### Session Control

| Command | Description |
|---------|-------------|
| `/next-phase` | Workshop 다음 Phase로 전환 |
| `/pause` | 세션 일시 중단 (상태 저장) |
| `/resume` | 일시 중단된 세션 재개 |
| `/wrap` | 세션 종료 + 결과물 반영 (= `--wrap` 효과) |
| `/transcript` | 현재까지의 대화 기록 표시 |
| `/summary` | 현재까지의 태그 항목 요약 |

---

## Session Lifecycle

```
/u-discuss → Initialize → Active → (Pause ↔ Resume) → Wrap → Archived
```

| Status | Description |
|--------|-------------|
| `active` | 세션 진행 중 |
| `paused` | 일시 중단 (상태 보존) |
| `wrapped` | 결과물 반영 완료 |
| `archived` | `_sessions/` 에 저장 완료 |

### Session Resume

중단된 세션 재개:

```
/u-discuss --resume DS-003
```

1. `_sessions/DS-003.json` 로드
2. 마지막 상태 복원 (transcript, tags, currentPhase)
3. 세션 status → `active`

---

## Wrap Process (--wrap 또는 /wrap)

세션 종료 시 결과물 자동 반영:

1. **태그 항목 분류:**

   | Tag | Destination | Item Type |
   |-----|------------|-----------|
   | `/idea` | `_classified/requirements/` | status: extracted |
   | `/decide` | `_classified/decisions/` | DC-{NNN} |
   | `/concern` | `_classified/constraints/` 또는 `_classified/questions/` | CN/QS-{NNN} |
   | `/action` | `_backlog/_index.json` | type: improvement, source: discuss |

2. **각 항목에 source 메타데이터 부착:**
   ```json
   {
     "source": {
       "session": "DS-{NNN}",
       "type": "{type}",
       "topic": "{topic}",
       "taggedAt": "{ISO 8601}"
     }
   }
   ```

3. **세션 아카이브:**
   - `_sessions/DS-{NNN}.json` 최종 저장
   - status → `archived`
   - 전체 transcript 보존

4. **인덱스 갱신:**
   - `_classified/` 각 카테고리 `_index.json` 갱신
   - `_backlog/_index.json` 갱신

5. **Wrap Summary 표시:**
   ```markdown
   ## Session Wrapped: DS-{NNN}

   **Type:** {type}
   **Topic:** {topic}
   **Duration:** {minutes}min
   **Participants:** {agents}

   ### Results
   | Tag | Count | Destination |
   |-----|-------|-------------|
   | /idea | {n} | _classified/requirements/ |
   | /decide | {n} | _classified/decisions/ |
   | /concern | {n} | _classified/constraints/ |
   | /action | {n} | _backlog/ |

   ### Next Steps
   - Review new items: /u-ingest {scope} --review
   - Approve assumptions: /u-assume {scope}
   - View backlog: /u-backlog {scope}
   ```

---

## Safety Rules

1. 동시에 활성 세션은 최대 3개 (초과 시 기존 세션 pause 요청)
2. 세션 데이터는 항상 `_sessions/`에 저장 (메모리 유실 방지)
3. `/wrap` 전까지 SSoT 문서 직접 수정 없음 (태그로만 수집)
4. brainstorm 세션에서 비판/평가 금지 (facilitator가 리다이렉트)
5. decision 세션에서 FDE 최종 결정 없이 종료 불가
6. retro 세션은 실제 iteration 데이터 없이 진행 불가
7. 세션 transcript는 불변 (수정/삭제 금지)
8. workshop의 `/next-phase`는 순방향만 (이전 phase로 돌아가기 불가)
