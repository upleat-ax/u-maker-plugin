---
name: u-skill-daily-report
description: |
  PM 데일리 리포트를 생성한다.
  파일명은 5_DailyReport_PM_yyyymmddhhmm.md 형식을 사용한다.
  Triggers: /u-skill-daily-report, daily report, 데일리 리포트
model: sonnet
user-invocable: true
argument-hint: "[yyyymmddhhmm]"
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
  - ${PLUGIN_ROOT}/templates/05-act/5_DailyReport_PM.template.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  - u-maker:u-agent-pm
---

# u-skill-daily-report

`u-agent-pm` 에이전트를 호출하여 PM 데일리 리포트를 생성한다.

## Output Path

- `.u-maker/docs/common/05-act/5_DailyReport_PM_yyyymmddhhmm.md`

## Rules

- 타임스탬프는 반드시 `yyyymmddhhmm` 형식(12자리 숫자)
- 인자가 없으면 현재 시각으로 생성
- 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
