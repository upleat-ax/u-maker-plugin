---
name: u-skill-ux-dsystem
description: |
  pencil.dev를 사용해 컴포넌트, 디자인 시스템, 화면을 시각적으로 구성하고 업데이트한다.
  IA, Screen, DesignToken, UIComponents 문서를 참고하여 .pen 파일에 디자인을 반영한다.
  Triggers: /u-skill-ux-dsystem, pencil, 디자인 시각화, 화면 디자인, 컴포넌트 디자인, design system visual,
  screen visual, ui design, pen file, pencil design
model: sonnet
user-invocable: true
argument-hint: "[app] [screen-id|component|all]"
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
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
agents:
  - u-maker:u-agent-ux
---

# u-agent-ux-ds

`u-agent-ux` 에이전트를 호출하여 pencil.dev로 컴포넌트, 디자인 시스템, 화면을 시각적으로 구성/업데이트한다.

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
