---
name: u-maker
description: |
  PDCA 기반 SSoT 협업 오케스트레이터 v2.0. 자연어 요청을 분석하여
  적절한 /u-* 커맨드로 라우팅하는 메타 라우터.
  Triggers: u-maker, ssot, pdca, 프로젝트, 에이전트, orchestrator,
  자동화, automation, 에이전트 라우팅, 소프트웨어 개발, 협업
  Do NOT use for: non-PDCA workflows, standalone code editing without project context.
version: 2.0.0
model: opus
user-invocable: true
argument-hint: "[command] [args]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/shared/references/ssot-standard.md
  - ${PLUGIN_ROOT}/shared/references/post-execution-summary.md
  - ${PLUGIN_ROOT}/skills/u-maker/references/slash-commands.md
  - ${PLUGIN_ROOT}/skills/u-maker/references/scope-resolution.md
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-maker -- PDCA 협업 오케스트레이터 v2.0

> 자연어 요청을 분석하여 적절한 `/u-*` 커맨드로 라우팅하는 메타 라우터.
> 각 커맨드의 상세 로직은 개별 스킬에 정의되어 있다.

## Core Principles

1. **문서 중심** -- 모든 결정과 산출물은 `.u-maker/docs/` SSoT 문서에 기록
2. **Phase Gate** -- 각 Phase 전환은 Gate 조건 충족 필수
3. **자동 반복** -- CHECK 실패 시 ACT → 다음 Iteration 자동 전환
4. **역할 분리** -- 4개 전문 에이전트가 명확한 역할 분담
5. **기술 스택 강제** -- tech-stack-rules 위반 시 거부
6. **JSON 내보내기** -- `.md` 문서 생성/갱신 시 `.json` 동시 생성

## PDCA 4-Phase

| Phase | 활동 | 주요 커맨드 |
|-------|------|-------------|
| **PLAN** | 요구사항 분석, SRS, IA, Roadmap, Wireframe | `/u-plan`, `/u-ingest` |
| **DO** | Design(ERD, API, Screen, UXGuide) + Dev(FE, BE) | `/u-design`, `/u-build` |
| **CHECK** | TC 설계, 테스트 실행, QA Report, Exit Criteria | `/u-check` |
| **ACT** | 판정, Iteration Log, Retrospective, Archive | `/u-ship` |

## Agent Routing Table

| Agent | Role | 주요 담당 |
|-------|------|-----------|
| `u-agent-orchestrator` | 중앙 조율자 | Phase 관리, 라우팅, 의존성 분석 |
| `u-agent-planner` | 분석/설계자 | SRS, IA, ERD, API, Screen, Roadmap |
| `u-agent-builder` | 구현자 | FE/BE 코드 생성, DB 마이그레이션 |
| `u-agent-guardian` | 검증자 | TC 설계, 테스트 실행, 일관성 검증, Gate 판정 |

## Request Analysis Flow

```
1. 사용자 입력 수신
2. Slash Command 매칭
   ├── /u-* 명시적 커맨드 → 해당 스킬 직접 실행
   └── 자연어 → 키워드 분석 → 커맨드 라우팅
3. 현재 Phase 확인 (.u-maker/u-ssot.config.json)
4. Scope 해석 (앱 자동 감지 또는 명시)
5. 커맨드/에이전트 실행
6. 결과 보고 + Post-Execution Summary Box
```

## App Context Resolution

| Condition | Behavior |
|-----------|----------|
| Single app in config | 자동 선택, 인자 불필요 |
| Multiple apps + argument given | 지정된 앱 사용 |
| Multiple apps + no argument | AskUserQuestion으로 선택 요청 |

## Slash Command Reference

### Lifecycle (7)

| Command | Skill | 설명 |
|---------|-------|------|
| `/u-init` | u-init | 프로젝트 초기화, .u-maker/ 구조 생성 |
| `/u-ingest` | u-ingest | _input/ raw data → _classified/ 정제 적재 |
| `/u-plan` | u-plan | PLAN Phase: SRS + IA + Roadmap 연쇄 생성 |
| `/u-design` | u-design | DESIGN: ERD + API + Screen + Flow + UXGuide |
| `/u-build` | u-build | BUILD: FE + BE 코드 생성 |
| `/u-check` | u-check | CHECK: TC 설계 + 테스트 + QA Report |
| `/u-ship` | u-ship | ACT: 최종 검증 + 회고 + Archive |

### Operations (5)

| Command | Skill | 설명 |
|---------|-------|------|
| `/u-add` | u-add | FR, NR, US, FT, Screen, TC 등 항목 추가 |
| `/u-update` | u-update | 문서 수정 + --cascade 의존 문서 자동 갱신 |
| `/u-doc` | u-doc | 특정 문서 조회/편집/재생성 |
| `/u-sync` | u-sync | 전체 문서 일관성 검증 + 수정 제안 |
| `/u-gate` | u-gate | Phase Gate 충족 여부 검사 + 전환 |

### Observability (3)

| Command | Skill | 설명 |
|---------|-------|------|
| `/u-status` | u-status | 대시보드: Phase, 진행률, 미완료 항목 |
| `/u-coverage` | u-coverage | classified → 산출물 커버리지 리포트 |
| `/u-trace` | u-trace | raw → classified → docs 추적 체인 |

### Collaboration (1)

| Command | Skill | 설명 |
|---------|-------|------|
| `/u-discuss` | u-discuss | 다자간 토론: brainstorm, review, decision |

### Review (1)

| Command | Skill | 설명 |
|---------|-------|------|
| `/u-assume` | u-assume | Assumption approve/reject + cascade 전파 |

### Agent Direct (4)

| Command | Skill | 설명 |
|---------|-------|------|
| `/u-agent-orchestrator` | u-agent-orchestrator | Orchestrator에게 직접 작업 요청 |
| `/u-agent-planner` | u-agent-planner | Planner에게 직접 분석/설계 요청 |
| `/u-agent-builder` | u-agent-builder | Builder에게 직접 구현 요청 |
| `/u-agent-guardian` | u-agent-guardian | Guardian에게 직접 검증/QA 요청 |

## CLI Grammar

```
/u-{command} [scope] [target] [flags]
```

- `scope` = 앱 이름 | `common` | `all` | 생략(자동) | 콤마 구분
- `target` = 문서/항목 이름
- `flags` = `-i` | `--step` | `--only X` | `--cascade` | `--verbose` | `--dry-run` | `--json` | `--review` | `--incremental` | `--wrap` | `--assumptions`

## Natural Language → Command Mapping

| 키워드 패턴 | 라우팅 대상 |
|-------------|-------------|
| 초기화, 새 프로젝트, init | `/u-init` |
| 입력 분석, 데이터 수집, ingest | `/u-ingest` |
| 계획, 기획, SRS, IA, 요구사항 | `/u-plan` |
| 설계, ERD, API, 화면, design | `/u-design` |
| 구현, 코드 생성, 빌드, build | `/u-build` |
| 테스트, QA, 검증, check | `/u-check` |
| 배포, 출시, 회고, ship | `/u-ship` |
| 추가, add, FR 추가, US 추가 | `/u-add` |
| 수정, update, 변경 | `/u-update` |
| 문서 조회, 편집, doc | `/u-doc` |
| 동기화, sync, 일관성 | `/u-sync` |
| 게이트, gate, phase 전환 | `/u-gate` |
| 상태, status, 대시보드 | `/u-status` |
| 커버리지, 누락, coverage | `/u-coverage` |
| 추적, trace, 의존성 | `/u-trace` |
| 토론, 논의, discuss | `/u-discuss` |
| 가정, assumption, assume | `/u-assume` |

## Error Handling

| Situation | Action |
|-----------|--------|
| Phase Gate 미충족 | 미충족 조건 목록 출력, 해당 Phase 보완 안내 |
| 문서 경로 위반 | 올바른 경로 안내, 작업 거부 |
| 기술 스택 위반 | 위반 규칙 표시, 대안 제시, 코드 거부 |
| 최대 Iteration 초과 | 강제 종료, 최종 상태 보고 |
| 커맨드/에이전트 실패 | 에러 기록, 대체 수동 작업 안내 |
| 문서 누락 | 템플릿 기반 자동 생성 제안 |
| 모호한 요청 | AskUserQuestion으로 명확화 |
