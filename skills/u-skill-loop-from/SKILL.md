---
name: u-skill-loop-from
description: |
  지정 Phase부터 PDCA 루프를 시작한다. 예: /u-skill-loop-from design
  Args: `<phase>` — 시작 Phase (plan|design|do|check|act) (필수)
  Triggers: /u-skill-loop-from, 루프 시작점, 특정 페이즈부터 시작, start from phase, resume loop, 루프 재개, loop from, 페이즈 지정, phase resume, 중간부터 시작, restart from, continue from
model: sonnet
user-invocable: true
argument-hint: "<plan|design|do|check|act>"
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

# PDCA Loop from Phase

> 지정 Phase부터 PDCA 루프를 시작한다.

## Syntax

/u-skill-loop-from [phase]

예: /u-skill-loop-from design → DESIGN Phase부터 시작

## Rules

- 지정 Phase부터 CHECK까지 실행 후 Exit Criteria 검증
- 미충족 시 ACT → 다음 Iteration (PLAN부터)
- 나머지 규칙은 u-skill-loop과 동일
- Post-Execution Summary Box 출력 필수
