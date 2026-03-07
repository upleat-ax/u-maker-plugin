---
name: u-skill-storybook
description: |
  Storybook을 실행한다. 컴포넌트 문서화 및 시각적 확인.
  Triggers: /u-skill-storybook, 스토리북, storybook run
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

# u-skill-storybook

`bun run storybook` 실행. 컴포넌트 문서화 및 시각적 확인.

## Rules

- Post-Execution Summary Box 출력 필수
