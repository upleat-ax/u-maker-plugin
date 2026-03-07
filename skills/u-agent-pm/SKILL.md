---
name: u-agent-pm
description: |
  Agent PM(Product Manager)에게 직접 작업을 요청한다.
  로드맵, 인덱스, 회고, 데일리 리포트 문서 작성/갱신을 담당한다.
  Triggers: /u-agent-pm, PM에게, daily report, roadmap
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
  - u-maker:u-agent-pm
---

# u-agent-pm

`u-agent-pm` 에이전트를 호출하여 사용자가 요청한 PM 작업을 수행한다.

## Scope

- 프로젝트 로드맵 (`1_Roadmap_PM.md`)
- 문서 인덱스 (`1_Index_PM.md`)
- 회고 (`5_Retrospective_PM.md`)
- 데일리 리포트 (`5_DailyReport_PM_yyyymmddhhmm.md`)

## Rules

- 데일리 리포트 파일명은 반드시 `yyyymmddhhmm` 12자리 타임스탬프를 포함
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
