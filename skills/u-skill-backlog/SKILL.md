---
name: u-skill-backlog
description: |
  백로그 Open 항목을 조회한다. 5_IterationLog_RA.md 내 미해결 항목을 표시한다.
  Triggers: /u-skill-backlog, 백로그, open items
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
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
agents:
  - u-maker:u-agent-ra
---

# u-agent-backlog

`u-agent-ra` 에이전트를 호출하여 백로그 Open 항목을 조회한다.

## Source

`.u-maker/docs/common/05-act/5_IterationLog_RA.md`

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
