---
name: u-skill-create-project
description: |
  새 프로젝트 초기화. Turborepo 모노레포 + .u-maker/docs SSoT 문서 구조를 생성한다.
  Triggers: /u-skill-create-project, 프로젝트 생성, 프로젝트 시작, new project
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
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
  - ${PLUGIN_ROOT}/_refer/tech-stack-rules.md
agents:
  - u-maker:u-agent-ra
---

# u-agent-create-project

`u-agent-ra` 에이전트를 호출하여 Turborepo 모노레포 + .u-maker/docs SSoT 문서 구조를 생성한다. 새 프로젝트 초기화.

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- 생성된 프로젝트 기본 의존성에 `@tabler/icons-react`를 포함
- Post-Execution Summary Box 출력 필수
