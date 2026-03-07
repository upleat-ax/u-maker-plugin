---
name: u-skill-erd
description: |
  ERD(Entity-Relationship Diagram) 문서를 생성하거나 갱신한다. u-agent-sa 에이전트가 담당한다.
  Triggers: /u-skill-erd, ERD, 데이터 모델
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
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
agents:
  - u-maker:u-agent-sa
---

# u-skill-erd

`u-agent-sa` 에이전트를 호출하여 ERD 문서를 생성/갱신한다.

## Output

`.u-maker/docs/common/02-design/2_ERD_SA.md`

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
