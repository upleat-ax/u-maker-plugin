---
name: u-skill-resume
description: |
  중단된 PDCA 루프를 재개한다. 중단점부터 이어서 진행한다.
  Triggers: /u-skill-resume, 루프 재개, resume loop, 재개, 이어서, continue, 중단 재개, resume pdca, 루프 계속, loop continue, 작업 재개, resume task
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
agents:
  - u-agent-pm: u-maker:u-agent-pm
  - u-agent-ra: u-maker:u-agent-ra
  - u-agent-sa: u-maker:u-agent-sa
  - u-agent-ux: u-maker:u-agent-ux
  - u-agent-dv-fe: u-maker:u-agent-dv-fe
  - u-agent-dv-be: u-maker:u-agent-dv-be
  - u-agent-qa: u-maker:u-agent-qa
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/_refer/tech-stack-rules.md
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
---

# Loop Resume

> 중단된 PDCA 루프를 재개한다.

## Action

1. .u-maker/u-maker.config.json에서 중단 상태 확인
2. loopStatus를 RUNNING으로 설정
3. 중단점(Phase)부터 루프 재개

## Rules

- 중단점부터 이어서 진행
- 나머지 규칙은 u-skill-loop과 동일
- Post-Execution Summary Box 출력 필수
