---
name: u-agent-dv-be
description: |
  Backend 개발을 실행한다. API Routes + Prisma/Drizzle ORM 기반. u-agent-dv-be 에이전트가 담당한다.
  Optional [app] argument for multi-app projects (e.g., `/u-agent-dv-be web`).
  Triggers: /u-agent-dv-be, 백엔드, backend, API 구현
model: sonnet
user-invocable: true
argument-hint: "[web]"
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
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-ssot.config.json
  - ${PLUGIN_ROOT}/_refer/tech-stack-rules.md
agents:
  - u-maker:u-agent-dv-be
---

# u-agent-dv-be

`u-agent-dv-be` 에이전트를 호출하여 Backend 개발을 실행한다.

## Output

- code (소스 파일)
- `.u-maker/docs/{app}/03-dev/3_Code_DV.md`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
