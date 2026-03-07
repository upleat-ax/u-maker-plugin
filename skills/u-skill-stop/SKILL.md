---
name: u-skill-stop
description: |
  실행 중인 PDCA 루프를 중단한다. 현재 Phase와 상태를 저장한다.
  Triggers: /u-skill-stop, 루프 중단, stop loop
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
agents:
  - u-agent-ra: u-maker:u-agent-ra
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
---

# Loop Stop

> 실행 중인 PDCA 루프를 중단한다.

## Action

1. .u-maker/u-maker.config.json의 loopStatus를 PAUSED로 설정
2. 현재 Phase와 상태 저장
3. 중단 상태 보고

## Rules

- Post-Execution Summary Box 출력 필수
