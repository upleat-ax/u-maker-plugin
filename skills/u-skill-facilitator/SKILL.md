---
name: u-skill-facilitator
description: "/u-discuss 세션을 관리하고, 마이크로 커맨드 파싱, 세션 직렬화/복원, 결과물 분류 및 백로그 반영을 수행하는 내부 엔진."
---

# u-skill-facilitator -- Discussion Facilitation Engine

`/u-discuss` 세션 lifecycle 관리: 생성, 마이크로 커맨드 파싱, 태그 분류, pause/resume, wrap 시 SSoT 반영, 아카이브.

**Owner Agent:** u-agent-orchestrator

---

## 1. Session Types

| Type | Purpose | Default Participants | Phase Model |
|------|---------|---------------------|-------------|
| `brainstorm` | 발산적 아이디어 | planner, sa, ux | Single (diverge) |
| `review` | 수렴적 평가 | Owner + gatekeeper | Single (evaluate) |
| `decision` | 트레이드오프+결정 | All | Single (decide) |
| `workshop` | 복합 다단계 | All | 4-Phase (diverge→group→prioritize→decide) |
| `retro` | KPT 회고 | All | 3-Phase (collect→analyze→action) |

---

## 2. Session Creation

`DS-{NNN}` ID 생성 (`.state/sessions/_counter.json`) → 참여 에이전트 결정 → 컨텍스트 로드 → `.state/sessions/DS-{NNN}.json` 생성

**세션 구조:** `{ id, type, topic, scope, status, startedAt, participants, context, currentPhase, transcript[], tags: { idea, decide, concern, action }, checkpoints[] }`

---

## 3. Micro-Command Parsing

### Agent Opinion: `@planner`, `@builder`, `@gatekeeper`, `@orchestrator`, `@all` + question

에이전트 역할 관점 응답 → transcript에 기록

### Tagging

| Pattern | Tag | Wrap Destination |
|---------|-----|-----------------|
| `/idea "..."` | idea | `data/classified/requirements/` |
| `/decide "..."` | decide | `data/classified/decisions/` |
| `/concern "..."` | concern | `data/classified/constraints/` or `questions/` |
| `/action "..."` | action | `data/backlog/` |

### Session Control: `/next-phase`, `/pause`, `/resume`, `/wrap`, `/transcript`, `/summary`

---

## 4. Workshop Phase Management

```
Diverge → Group → Prioritize → Decide (순방향만)
```

| Phase | Goal | Tags | Rules |
|-------|------|------|-------|
| Diverge | 아이디어 최대 발산 | `/idea` | 비판 금지, 양 우선 |
| Group | 그룹핑 | -- | 중복 제거, 카테고리 분류 |
| Prioritize | 우선순위 정렬 | -- | MoSCoW / Impact-Effort |
| Decide | 최종 선정+액션 | `/decide`, `/action` | FDE 최종 결정 |

역방향 전환 불가. 마지막 Phase에서 `/next-phase` → "/wrap 사용" 안내.

---

## 5. Pause & Resume

- **pause:** status→paused, checkpoint 저장 (currentPhase, transcriptLength, tagCounts)
- **resume:** status→active, paused 상태 아니면 에러, 복원 요약 표시

---

## 6. Session Wrap

1. **태그 항목 분류:** idea→requirements(extracted), decide→decisions, concern→constraints/questions, action→backlog(improvement)
2. **Source metadata 부착:** `{ session, type, topic, taggedAt }`
3. **인덱스 갱신:** `data/classified/` 및 `data/backlog/_index.json`
4. **아카이브:** status→archived, transcript 보존

---

## 7. Transcript Management

Entry types: user-input, agent-opinion, tag, phase-transition, system. Append-only (수정/삭제 금지), 세션 종료 후 보존, 최대 500 entries.

---

## 8. Safety Rules

1. 동시 활성 세션 최대 3개
2. 세션 데이터 항상 `.state/sessions/`에 파일 저장 (메모리 유실 방지)
3. `/wrap` 전까지 SSoT 직접 수정 금지 (태그로만 수집)
4. brainstorm 비판 감지 시 리다이렉트, decision FDE 결정 없이 종료 불가
5. retro는 iteration 데이터 없이 진행 불가
6. transcript 불변, workshop phase 순방향만
