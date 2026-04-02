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

`/u-discuss [scope] [type] "topic" [--wrap]` 명령으로 구조화된 다자간 토론 세션 진행. 5가지 유형 지원, 결과물 SSoT 자동 반영.

**Primary Agent:** u-agent-orchestrator (engine-facilitator 사용)

---

## Arguments & Flags

| Argument/Flag | Required | Description |
|---------------|----------|-------------|
| `scope` | Optional | 대상 앱 (생략 시 자동 선택) |
| `type` | Required | `brainstorm` / `review` / `decision` / `workshop` / `retro` |
| `"topic"` | Required | 토론 주제 |
| `--wrap` | - | 세션 종료 시 결과물 SSoT 자동 반영 |
| `--agents "list"` | - | 참여 에이전트 지정 (기본: 유형별 자동) |
| `--context "refs"` | - | 참고 문서/항목 ID (예: "FR-0001, screens.md") |

---

## Execution Flow

### Step 1: Initialize Session

1. 세션 ID `DS-{NNN}` 생성 → `.state/sessions/DS-{NNN}.json` 생성
2. 관련 문서/항목 로드 → 참여 에이전트 결정

**세션 구조:** `{ id, type, topic, scope, status, startedAt, participants, context, transcript[], tags: { idea, decide, concern, action }, currentPhase }`

### Step 2: Session Type Execution

---

## Session Types

### 1. brainstorm -- 발산적 아이디어 확장

**참여:** planner, sa, ux | **규칙:** 비판 금지, 양 우선, 빌드업 장려

- 에이전트가 각자 관점(비즈니스/기술/UX)에서 아이디어 제시
- `/idea` 태그 항목 추출 → wrap 시 `data/classified/requirements/` (status: extracted)

### 2. review -- 수렴적 평가

**참여:** Owner agent + gatekeeper

- Owner가 분석 제시, Gatekeeper이 검증 관점 코멘트
- FDE가 항목별 Approve(→Review/Final) / Revise(즉시 반영) / Reject(사유 기록)
- wrap 시 `/decide` → `data/classified/decisions/`, 대상 문서 status 갱신

### 3. decision -- 트레이드오프 분석

**참여:** 전체(@all)

- 선택지 나열 → 각 선택지: Pros/Cons/Impact/Risk/Effort 분석
- 각 에이전트가 관점별 선호 옵션+근거 제시
- FDE 최종 결정 + rationale → wrap 시 `data/classified/decisions/DC-{NNN}.json`

### 4. workshop -- 다단계 복합 세션 (Diverge → Group → Prioritize → Decide)

**참여:** 전체(@all)

| Phase | Goal | Tags |
|-------|------|------|
| Diverge | 자유 아이디어 발산 | `/idea` |
| Group | 카테고리 분류, 중복 제거 | -- |
| Prioritize | MoSCoW/Impact-Effort 정렬 | -- |
| Decide | 최종 선정 + 액션 할당 | `/decide`, `/action` |

- `/next-phase`로 전환 (순방향만)
- wrap 시: idea→requirements, decide→decisions, action→backlog

### 5. retro -- Keep / Problem / Try 회고

**참여:** 전체(@all)

- Data Collection: Phase별 소요시간, 결함 패턴, 공수 예측 vs 실제, 백로그 완료율
- Keep → Problem(`/concern`) → Try(`/action`)
- wrap 시: concern→constraints/questions, action→backlog, retrospective.md 갱신

---

## Micro-Commands (세션 중)

### Agent Opinion: `@planner`, `@builder`, `@gatekeeper`, `@ux`, `@sa`, `@all`

### Tagging

| Command | Wrap Destination |
|---------|-----------------|
| `/idea "..."` | `data/classified/requirements/` |
| `/decide "..."` | `data/classified/decisions/` |
| `/concern "..."` | `data/classified/constraints/` or `questions/` |
| `/action "..."` | `data/backlog/` |

### Session Control: `/next-phase`, `/pause`, `/resume`, `/wrap`, `/transcript`, `/summary`

---

## Session Lifecycle

```
Initialize → Active → (Pause ↔ Resume) → Wrap → Archived
```

재개: `/u-discuss --resume DS-003` → `.state/sessions/DS-003.json` 로드 → transcript/tags/phase 복원

---

## Wrap Process

1. **태그 항목 분류:** idea→requirements(extracted), decide→decisions, concern→constraints/questions, action→backlog(improvement)
2. **Source metadata 부착:** `{ session, type, topic, taggedAt }`
3. **세션 아카이브:** status→archived, transcript 보존
4. **인덱스 갱신:** `data/classified/` 및 `data/backlog/_index.json`
5. **Wrap Summary:** 유형, 주제, 소요시간, 태그별 count+destination, Next Steps

---

## Safety Rules

1. 동시 활성 세션 최대 3개
2. 세션 데이터 항상 `.state/sessions/`에 파일 저장 (메모리 유실 방지)
3. `/wrap` 전까지 SSoT 직접 수정 없음 (태그로만 수집)
4. brainstorm에서 비판 금지, decision에서 FDE 결정 없이 종료 불가
5. retro는 실제 iteration 데이터 없이 진행 불가
6. transcript 불변 (수정/삭제 금지), workshop `/next-phase` 순방향만
