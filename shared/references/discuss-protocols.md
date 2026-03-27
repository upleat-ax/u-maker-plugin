# Discussion Protocols

> /u-discuss 세션의 5가지 타입별 진행 규칙과 micro-commands 정의.

---

## 1. Overview

/u-discuss는 FDE의 암묵지 + Agent의 분석력을 세션 안에서 결합. 세션 결과는 자동으로 _classified/에 적재.

---

## 2. Session Types

### brainstorm — 발산

| 항목 | 내용 |
|------|------|
| **목적** | 아이디어 수집. 비판 금지. |
| **진행** | Agent가 연관 아이디어 확장. 모든 아이디어 기록. |
| **Output** | ideas[] → _classified/requirements/ (status: extracted) |
| **종료 조건** | FDE가 `/wrap` 또는 자연스러운 수렴 |

### review — 수렴

| 항목 | 내용 |
|------|------|
| **목적** | 산출물 검토 |
| **진행** | Agent가 분석 결과 제시. FDE가 approve/revise/reject. |
| **Output** | review comments + decisions |
| **종료 조건** | 모든 항목 검토 완료 |

### decision — 의사결정

| 항목 | 내용 |
|------|------|
| **목적** | 트레이드오프 결정 |
| **진행** | Agent가 선택지별 pros/cons/impact 분석. FDE가 최종 결정. 근거 필수. |
| **Output** | decision record → _classified/decisions/ |
| **종료 조건** | 결정 + 근거 기록 완료 |

### workshop — 다단계 협업

| 항목 | 내용 |
|------|------|
| **목적** | brainstorm + decision 결합 |
| **진행** | 발산 → 그룹핑 → 우선순위 → 결정. Orchestrator가 단계 전환. |
| **Output** | 복합 (ideas + decisions + requirements) |
| **종료 조건** | 4단계 모두 완료 |

### retro — 회고

| 항목 | 내용 |
|------|------|
| **목적** | Iteration 종료 시 회고 |
| **진행** | Keep/Problem/Try. Agent가 데이터 기반 분석. |
| **Output** | retrospective record → docs/common/project/ |
| **종료 조건** | Action items 도출 |

---

## 3. Micro-Commands

세션 중 사용 가능한 명령어.

### Agent 호출
| Command | 설명 |
|---------|------|
| `@planner` | planner에게 직접 질문/의견 요청 |
| `@builder` | builder에게 기술적 판단 요청 |
| `@guardian` | guardian에게 검증/리스크 의견 요청 |
| `@all` | 모든 agent에게 의견 요청 (라운드 로빈) |

### 태깅
| Command | 설명 |
|---------|------|
| `/idea [text]` | 아이디어 태깅 |
| `/decide [text]` | 결정사항 기록. 근거 필수. |
| `/concern [text]` | 우려/리스크 기록 |
| `/action [who] [text]` | 액션 아이템 기록 |

### 제어
| Command | 설명 |
|---------|------|
| `/next-phase` | 워크숍 다음 단계로 전환 |
| `/pause` | 세션 일시정지 |
| `/resume [session-id]` | 중단된 세션 재개 |
| `/wrap` | 세션 종료 + _classified 적재 |

---

## 4. Session → Pipeline 연결

`/wrap` 실행 시 자동 분류:

| 태그 | _classified 대상 | status |
|------|-----------------|--------|
| /idea | requirements/ | extracted |
| /decide | decisions/ | validated |
| /concern | constraints/ 또는 questions/ | extracted |
| /action | 해당 문서에 TODO 플래그 | — |

전체 transcript → `_sessions/` 아카이브

---

## 5. Session 스키마

```json
{
  "id": "S-001",
  "type": "brainstorm | review | decision | workshop | retro",
  "topic": "세션 주제",
  "scope": "retail | common | all",
  "status": "active | paused | completed",
  "startedAt": "ISO 8601",
  "completedAt": null,
  "participants": ["FDE", "planner", "builder"],
  "items": [],
  "summary": null
}
```
