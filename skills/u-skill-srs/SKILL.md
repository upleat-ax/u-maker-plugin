---
name: u-skill-srs
description: |
  SRS(Software Requirements Specification) 문서를 생성하거나 갱신한다. u-agent-sa 에이전트가 담당한다.
  Optional [app] argument for multi-app projects (e.g., `/u-skill-srs web`).
  Triggers: /u-skill-srs, SRS, 요구사항
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
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
---

# u-skill-srs

agent: u-maker:u-agent-sa

`u-agent-sa` 에이전트를 호출하여 SRS 문서를 생성/갱신한다.

## Output

`.u-maker/docs/{app}/01-plan/1_SRS_RA.md`

## Prerequisites

- Roadmap optional (FR-First 시 없이도 실행 가능)

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- `1_SRS_RA.json`의 `userStories[]`는 `id`만이 아니라 `role`, `feature`, `benefit`, `priority`, `fr`까지 모두 포함해야 함 (값 미확정 시 `null`)
- Post-Execution Summary Box 출력 필수
