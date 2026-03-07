---
name: u-skill-archive
description: |
  현재 Iteration 문서를 아카이브한다. .u-maker/docs/iterations/iter-N/ 으로 복사한다.
  Triggers: /u-skill-archive, 아카이브, archive iteration
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
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  - u-maker:u-agent-ra
---

# u-agent-archive

`u-agent-ra` 에이전트를 호출하여 현재 Iteration 문서를 `.u-maker/docs/iterations/iter-N/`으로 복사한다.

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
