# Slash Commands Reference

> u-maker v2 플러그인의 모든 슬래시 커맨드 정의 및 동작 명세.

---

## 1. Grammar

```
/u-{command} [scope] [target] [flags]
```

- **scope**: 앱 이름 | `common` | `all` | 생략 (→ scope-resolution.md 참조)
- **target**: 문서/항목 이름 (command에 따라 선택적)
- **flags**: `-i` | `--step` | `--only X` | `--cascade` | `--verbose` | `--dry-run` | `--json`

---

## 2. Lifecycle Commands (7)

### /u-init

| Field | Value |
|-------|-------|
| **Syntax** | `/u-init [project-name]` |
| **Description** | .u-maker/ 구조 생성, config 초기화, 앱 등록 |
| **Primary Agent** | orchestrator → planner |
| **Engines** | engine-router, engine-doc, engine-phase-detector |
| **Output** | `.u-maker/` 전체 디렉토리 구조, `u-maker.config.json`, common/ 기본 문서 |

### /u-ingest

| Field | Value |
|-------|-------|
| **Syntax** | `/u-ingest [scope]` |
| **Description** | _input/ raw data → _classified/ 분석 적재 |
| **Primary Agent** | orchestrator → planner |
| **Engines** | engine-router, engine-analyzer |
| **Flags** | `--review` (extracted 항목 리뷰), `--incremental` (신규분만) |
| **Output** | `_classified/` 카테고리별 JSON, `_index.json`, `_summary.json` |

### /u-plan

| Field | Value |
|-------|-------|
| **Syntax** | `/u-plan [scope]` |
| **Description** | classified → SRS + IA + Roadmap 연쇄 생성 |
| **Primary Agent** | orchestrator → planner → guardian |
| **Engines** | engine-router, engine-workflow-runner, engine-doc, engine-designer, engine-estimator, engine-validator |
| **Flags** | `--only srs\|ia\|roadmap` |
| **Output** | `docs/01-plan/srs.md`, `ia.md`, `roadmap.md` + JSON |

### /u-design

| Field | Value |
|-------|-------|
| **Syntax** | `/u-design [scope]` |
| **Description** | SRS/IA 기반 → ERD + API + Screen + Flow + UXGuide |
| **Primary Agent** | orchestrator → planner → guardian |
| **Engines** | engine-router, engine-workflow-runner, engine-doc, engine-designer, engine-validator |
| **Flags** | `--only erd\|api\|screens\|screen-flow\|ux-guide` |
| **Output** | `docs/02-design/` 문서들 + JSON |

### /u-build

| Field | Value |
|-------|-------|
| **Syntax** | `/u-build [scope]` |
| **Description** | 명세 기반 코드 생성 (FE + BE + DB) |
| **Primary Agent** | orchestrator → builder |
| **Engines** | engine-router, engine-workflow-runner, engine-code |
| **Flags** | `--only fe\|be\|db` |
| **Output** | 소스 코드 + `docs/03-dev/code.md` |

### /u-check

| Field | Value |
|-------|-------|
| **Syntax** | `/u-check [scope]` |
| **Description** | TC 설계 + 테스트 실행 + Report + exit criteria 판정 |
| **Primary Agent** | orchestrator → guardian |
| **Engines** | engine-router, engine-workflow-runner, engine-test, engine-validator |
| **Output** | `docs/04-check/test-cases.md`, `test-report.md` |

### /u-ship

| Field | Value |
|-------|-------|
| **Syntax** | `/u-ship [scope]` |
| **Description** | 최종 검증 + iteration log + retrospective |
| **Primary Agent** | orchestrator → guardian |
| **Engines** | engine-router, engine-workflow-runner, engine-validator, engine-dep |
| **Output** | `iteration-log.md`, `retrospective.md`, archive |

---

## 3. Operations Commands (5)

### /u-add

| Field | Value |
|-------|-------|
| **Syntax** | `/u-add [scope] [type] "title"` |
| **Description** | 항목 추가 (FR/NR/US/Screen 등) |
| **Primary Agent** | orchestrator → planner |
| **Engines** | engine-router, engine-doc, engine-dep |

### /u-update

| Field | Value |
|-------|-------|
| **Syntax** | `/u-update [scope] [doc]` |
| **Description** | 문서 수정 + 변경 cascade 자동 전파 |
| **Primary Agent** | orchestrator → planner/builder |
| **Engines** | engine-router, engine-doc, engine-dep |
| **Flags** | `--cascade` |

### /u-doc

| Field | Value |
|-------|-------|
| **Syntax** | `/u-doc [scope] [doc]` |
| **Description** | 특정 문서 조회/편집/재생성 |
| **Primary Agent** | orchestrator → planner |
| **Engines** | engine-router, engine-doc |

### /u-sync

| Field | Value |
|-------|-------|
| **Syntax** | `/u-sync [scope]` |
| **Description** | 전체 문서 일관성 검증 + 불일치 자동 수정 제안 |
| **Primary Agent** | orchestrator → guardian |
| **Engines** | engine-router, engine-validator, engine-dep |

### /u-gate

| Field | Value |
|-------|-------|
| **Syntax** | `/u-gate [scope]` |
| **Description** | 현재 phase gate 충족 여부 검사 + 다음 phase 전환 |
| **Primary Agent** | orchestrator → guardian |
| **Engines** | engine-router, engine-phase-detector, engine-validator |

---

## 4. Observability Commands (3)

### /u-status

| Field | Value |
|-------|-------|
| **Syntax** | `/u-status [scope]` |
| **Description** | 대시보드 (phase, 진행률, 미완료 항목, impact flags) |
| **Primary Agent** | orchestrator |
| **Engines** | engine-router, engine-phase-detector |
| **Flags** | `--assumptions` (미리뷰 assumptions 표시) |

### /u-coverage

| Field | Value |
|-------|-------|
| **Syntax** | `/u-coverage [scope]` |
| **Description** | classified → 산출물 커버리지 리포트 |
| **Primary Agent** | orchestrator → planner |
| **Engines** | engine-router, engine-analyzer |

### /u-trace

| Field | Value |
|-------|-------|
| **Syntax** | `/u-trace [scope] [id]` |
| **Description** | raw → classified → docs 전체 추적 체인 |
| **Primary Agent** | orchestrator |
| **Engines** | engine-router, engine-dep |

---

## 5. Collaboration Command (1)

### /u-discuss

| Field | Value |
|-------|-------|
| **Syntax** | `/u-discuss [scope] [type] "topic"` |
| **Description** | 구조화된 협업 세션 |
| **Types** | brainstorm, review, decision, workshop, retro |
| **Primary Agent** | orchestrator → (all via @) |
| **Engines** | engine-router, engine-facilitator |

---

## 6. Review Command (1)

### /u-assume

| Field | Value |
|-------|-------|
| **Syntax** | `/u-assume [scope] [action] [id]` |
| **Description** | assumptions 리뷰 (approve/reject) |
| **Actions** | approve, reject |
| **Primary Agent** | orchestrator → planner |
| **Engines** | engine-router, engine-dep |

---

## 7. Global Flags

| Flag | 설명 | 적용 대상 |
|------|------|-----------|
| (없음) | config default (auto) | all |
| `-i` | interactive mode | lifecycle |
| `--step` | step mode | lifecycle |
| `--only X` | 특정 산출물만 | lifecycle |
| `--cascade` | 변경 시 의존 문서 자동 갱신 | /u-update |
| `--verbose` | 상세 출력 | all |
| `--dry-run` | 실행 안 하고 계획만 표시 | lifecycle |
| `--json` | JSON 형식 출력 | all |
| `--review` | extracted 항목 리뷰 | /u-ingest |
| `--incremental` | 신규분만 처리 | /u-ingest |
| `--assumptions` | assumptions 표시 | /u-status |

---

## 8. Phase Gates

| Gate | 조건 | Validator |
|------|------|-----------|
| plan → design | SRS Final + IA Final + Roadmap approved | guardian |
| design → do | ERD + RTM + Screen + API Final & consistency | guardian |
| do → check | Code complete + build success | guardian |
| check → complete | Critical/Major 0건, all FR implemented | guardian |
| check → act | check-to-complete 실패 시 | orchestrator |
| act → plan | Retrospective complete + archive | orchestrator |
