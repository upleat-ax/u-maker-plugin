---
name: u-skill-index
description: |
  문서 인덱스(1_Index_PM.md)를 갱신한다.
  Triggers: /u-skill-index, 인덱스, index update
model: sonnet
user-invocable: true
argument-hint: "[args]"
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
---

# u-skill-index

agent: u-maker:u-agent-ra

`u-agent-ra` 에이전트를 호출하여 1_Index_PM.md를 갱신한다.

## Output

`.u-maker/docs/shared/01-plan/1_Index_PM.md`

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
