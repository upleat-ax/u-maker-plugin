---
name: u-skill-build
description: |
  프로젝트 빌드를 실행한다. bun run build 실행 및 결과를 보고한다.
  Triggers: /u-skill-build, 빌드, build project
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
---

# u-skill-build

`bun run build` 실행 및 결과 보고.

## Rules

- Post-Execution Summary Box 출력 필수
