---
name: u-skill-maker
description: |
  PDCA 기반 SSoT 협업 오케스트레이터. 6개 전문 에이전트를 조율하여
  Plan-Design-Do-Check-Act 사이클로 소프트웨어 개발을 자동화한다.

  이 스킬은 자연어 라우터 역할을 한다. 명시적 슬래시 커맨드가 아닌
  자연어 요청을 분석하여 적절한 에이전트로 라우팅한다.

  Triggers: u-agent, ssot, pdca, 프로젝트 시작, 프로젝트 초기화,
  문서 관리, 에이전트, 협업

  Do NOT use for: non-PDCA workflows, standalone code editing without project context.
model: sonnet
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
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
  - ${PLUGIN_ROOT}/_refer/slash-commands.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-ssot.config.json
agents:
  u-agent-ra: u-maker:u-agent-ra
  u-agent-sa: u-maker:u-agent-sa
  u-agent-ux: u-maker:u-agent-ux
  u-agent-dv-fe: u-maker:u-agent-dv-fe
  u-agent-dv-be: u-maker:u-agent-dv-be
  u-agent-qa: u-maker:u-agent-qa
---

# u-Agent SSoT Orchestrator

> 자연어 요청을 분석하여 적절한 에이전트/스킬로 라우팅하는 오케스트레이터.
> 각 Phase/Command별 상세 로직은 개별 스킬(u-skill-plan, u-skill-design 등)에 정의되어 있다.

## Core Principles

1. **문서 중심**: 모든 결정과 산출물은 `.u-maker/docs/` SSoT 문서에 기록
2. **Phase Gate**: 각 Phase 전환은 Gate 조건 충족 필수
3. **자동 반복**: CHECK 실패 시 ACT → 다음 Iteration 자동 전환
4. **역할 분리**: 6개 전문 에이전트가 명확한 역할 분담
5. **기술 스택 강제**: 10가지 기술 스택 규칙 위반 시 거부
6. **JSON 내보내기**: 마크다운 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 반드시 함께 생성

## Agent Routing Table

| Agent | Role | Phase | Triggers |
|-------|------|-------|----------|
| `u-agent-ra` | Requirements & Admin | PLAN, ACT, ALL | 로드맵, 마일스톤, 프로젝트 시작, 문서 인덱스, 상태 추적, 모순 검수, 백로그 관리 |
| `u-agent-sa` | Solution Architect | PLAN, DESIGN | SRS, ERD, API Contract, 유저 스토리, FR |
| `u-agent-ux` | UX Designer | PLAN, DESIGN, DO | 정보 구조도(IA), 화면 설계, Design System, Screen 구현, UI Components, Design Token |
| `u-agent-dv-fe` | Frontend Developer | DO | Next.js, react-query, Storybook |
| `u-agent-dv-be` | Backend Developer | DO | API Routes, Prisma/Drizzle |
| `u-agent-qa` | QA Engineer | CHECK | Unit+E2E 테스트 케이스, 테스트 실행, 결함 분석 |

## Request Analysis Flow

```
1. 사용자 입력 수신
2. Slash Command 매칭
   ├── /u-skill-* 명령어 → 해당 스킬 직접 실행
   └── 자연어 → 키워드 분석 → Agent 라우팅
3. 현재 Phase 확인 (.u-maker/u-ssot.config.json)
4. Phase에 활동 가능한 Agent만 호출
5. Agent 작업 실행
6. 결과 보고 + Post-Execution Summary Box
```

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Slash Command → Skill Mapping

명시적 슬래시 커맨드는 해당 스킬로 직접 라우팅한다.
전체 커맨드 목록은 `slash-commands.md` 참조.

### Lifecycle
| Command | Skill |
|---------|-------|
| `/u-skill-create-project` | u-skill-create-project |
| `/u-skill-init` | u-skill-init |
| `/u-skill-plan` | u-skill-plan |
| `/u-skill-design` | u-skill-design |
| `/u-skill-dev` | u-skill-dev |
| `/u-skill-check` | u-skill-check |
| `/u-skill-act` | u-skill-act |

### Loop
| Command | Skill |
|---------|-------|
| `/u-skill-loop` | u-skill-loop |
| `/u-skill-loop-from` | u-skill-loop-from |
| `/u-skill-stop` | u-skill-stop |
| `/u-skill-resume` | u-skill-resume |

### Document Management
| Command | Skill |
|---------|-------|
| `/u-skill-status` | u-skill-status |
| `/u-skill-docs` | u-skill-docs |
| `/u-skill-validate` | u-skill-validate |
| `/u-skill-backlog` | u-skill-backlog |
| `/u-skill-backlog-add` | u-skill-backlog-add |
| `/u-skill-us-add` | u-skill-us-add |
| `/u-skill-fr-add` | u-skill-fr-add |
| `/u-skill-index` | u-skill-index |

### Individual Agent
| Command | Skill |
|---------|-------|
| `/u-skill-srs` | u-skill-srs |
| `/u-skill-erd` | u-skill-erd |
| `/u-skill-api` | u-skill-api |
| `/u-skill-screen` | u-skill-screen |
| `/u-skill-wireframe` | u-skill-wireframe |
| `/u-skill-ux-design` | u-skill-ux-design |
| `/u-skill-fe` | u-skill-fe |
| `/u-skill-be` | u-skill-be |
| `/u-skill-test` | u-skill-test |
| `/u-skill-bug-report` | u-skill-bug-report |

### Utility
| Command | Skill |
|---------|-------|
| `/u-skill-help` | u-skill-help |
| `/u-skill-history` | u-skill-history |
| `/u-skill-archive` | u-skill-archive |
| `/u-skill-storybook` | u-skill-storybook |
| `/u-skill-build` | u-skill-build |
| `/u-skill-summary` | u-skill-summary |
| `/u-skill-git-pr` | u-skill-git-pr |
| `/u-skill-gap-detector` | u-skill-gap-detector |

## Error Handling

| Situation | Action |
|-----------|--------|
| Phase Gate 미충족 | 미충족 조건 목록 출력, 해당 Phase 보완 안내 |
| 문서 경로 위반 | 올바른 경로 안내, 작업 거부 |
| 기술 스택 위반 | 위반 규칙 표시, 대안 제시, 코드 거부 |
| 최대 Iteration 초과 | 강제 종료, 최종 상태 보고 |
| Agent 호출 실패 | 에러 기록, 대체 수동 작업 안내 |
| 문서 누락 | 템플릿 기반 자동 생성 제안 |
