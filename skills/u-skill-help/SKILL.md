---
name: u-skill-help
description: |
  u-maker 전체 명령어 도움말 표시.
  Show all available u-maker commands and agents.
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
  - ${PLUGIN_ROOT}/_refer/slash-commands.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
---

# u-maker Help

> 전체 명령어와 에이전트 도움말을 표시한다.

slash-commands.md의 내용을 참조하여 사용 가능한 모든 명령어를 카테고리별로 출력한다.

## Agent Table

| Agent | Role | Phase |
|-------|------|-------|
| u-agent-pm | Product Manager | PLAN, ACT |
| u-agent-ra | Requirements & Admin | PLAN, ACT, ALL |
| u-agent-sa | Solution Architect | PLAN, DESIGN |
| u-agent-ux | UX Designer | PLAN, DESIGN, DO |
| u-agent-dv-fe | Frontend Developer | DO |
| u-agent-dv-be | Backend Developer | DO |
| u-agent-qa | QA Engineer | CHECK |
