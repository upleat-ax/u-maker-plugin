---
name: u-skill-bug-report
description: |
  결함 분석 리포트를 생성한다. Fail 케이스 분류, 원인 분석, 수정 제안. u-agent-qa 에이전트가 담당한다.
  Optional [app] argument for multi-app projects (e.g., `/u-skill-bug-report web`).
  Triggers: /u-skill-bug-report, 버그 리포트, 결함 분석, defect report
model: sonnet
user-invocable: true
argument-hint: "[web]"
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
---

# u-skill-bug-report

agent: u-maker:u-agent-qa

`u-agent-qa` 에이전트를 호출하여 결함 분석 리포트를 생성한다.

## Output

`.u-maker/docs/{app}/04-check/4_Report_QA.md`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
