---
name: u-skill-srs
description: |
  SRS(Software Requirements Specification) 문서를 생성하거나 갱신한다. u-agent-sa 에이전트가 담당한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-srs, SRS, 요구사항
model: sonnet
user-invocable: true
argument-hint: "[app]"
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
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
agents:
  - u-maker:u-agent-sa
---

# u-skill-srs

`u-agent-sa` 에이전트를 호출하여 SRS 문서를 생성/갱신한다.

## Output

`.u-maker/docs/{app}/01-plan/1_SRS_RA.md`

## Prerequisites

- Roadmap optional (단, SRS 내부 구조는 항상 `FR+NFR → US → FT`)

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- `1_SRS_RA.json`은 `fr + nonFunctionalRequirements + userStories + features` 구조를 유지해야 함
- `1_SRS_RA.json`의 `userStories[]`는 `id`, `role`, `need`, `benefit`, `priority`, `fr`, `ft`를 모두 포함해야 함 (값 미확정 시 `null`)
- Post-Execution Summary Box 출력 필수
