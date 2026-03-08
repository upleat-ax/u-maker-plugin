---
name: u-agent-sa
description: |
  Agent SA(Software Architect)에게 직접 작업을 요청한다. SRS, ERD, API Contract 작성 등.
  Triggers: /u-agent-sa, SA에게, 아키텍처
model: sonnet
user-invocable: true
argument-hint: "[task description]"
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
  - u-maker:u-agent-sa
---

# u-agent-sa

`u-agent-sa` 에이전트를 호출하여 사용자가 요청한 작업을 수행한다.

## Scope

- SRS (Software Requirements Specification) 작성
- ERD (Entity-Relationship Diagram) 작성
- API Contract (OpenAPI 3.0) 작성
- USR/FR/US/FT 도출 및 매핑

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
