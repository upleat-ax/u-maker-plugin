---
name: u-skill-screen
description: |
  화면 상세 설계 문서를 생성하거나 갱신한다. u-agent-ux 에이전트가 담당한다.
  Optional [app] argument for multi-app projects (e.g., `/u-skill-screen web`).
  Triggers: /u-skill-screen, 화면 설계, wireframe, screen design
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
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
agents:
  - u-maker:u-agent-ux
---

# u-agent-screen

`u-agent-ux` 에이전트를 호출하여 화면 설계 문서를 생성/갱신한다.

## Output

`.u-maker/docs/{app}/02-design/2_Screen_UX.md`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
