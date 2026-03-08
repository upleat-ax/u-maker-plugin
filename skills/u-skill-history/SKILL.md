---
name: u-skill-history
description: |
  Iteration 이력을 조회한다. 5_IterationLog_RA.md 내용을 표시한다.
  Triggers: /u-skill-history, 이력, iteration history
model: sonnet
user-invocable: true
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
agents:
  - u-maker:u-agent-ra
---

# u-agent-history

`u-agent-ra` 에이전트를 호출하여 5_IterationLog_RA.md 내용을 표시한다.

## Source

`.u-maker/docs/common/05-act/5_IterationLog_RA.md`

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
