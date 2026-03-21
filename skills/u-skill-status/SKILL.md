---
name: u-skill-status
description: |
  현재 프로젝트 상태를 보고한다. Iteration, Phase, 문서 상태, 진행률을 표시한다.
  Triggers: /u-skill-status, 상태, 현황, project status, 진행 상황, 진행률, progress, 현재 상태, current status, 프로젝트 현황, iteration status, 상태 보고
user-invocable: true
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
agents:
  u-agent-ra: u-maker:u-agent-ra
---

# Status Report

> 현재 프로젝트 상태를 보고한다. Iteration, Phase, 문서 상태, 진행률을 표시한다.

## Output Format

====================================
  u-Agent SSoT Status Report
====================================
  Project: [project-name]
  Iteration: [N] / [maxIterations]
  Phase: [PLAN | DESIGN | DO | CHECK | ACT]
  Loop Status: [RUNNING | PAUSED | STOPPED]
  Apps: [web, admin, ...]
------------------------------------
  Shared Documents: [status list]
  App Documents: [per-app status list]
------------------------------------
  FR Progress: [N/M] implemented
  Open Defects: [Critical: X, Major: Y]
  Backlog: [N] open items
  Build: [PASS | FAIL]
====================================

## Rules

- u-agent-ra 에이전트가 담당
- Post-Execution Summary Box 출력 필수
