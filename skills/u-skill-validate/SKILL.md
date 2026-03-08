---
name: u-skill-validate
description: |
  SSoT 문서 무결성을 검증한다. 헤더 누락, 추적성 깨짐, 구조 위반을 탐지한다.
  Triggers: /u-skill-validate, 검증, 무결성, validate
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
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
agents:
  - u-maker:u-agent-ra
---

# u-agent-validate

`u-agent-ra` 에이전트를 호출하여 SSoT 무결성을 검증한다. 헤더 누락, 추적성 깨짐, 구조 위반을 탐지한다.

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
