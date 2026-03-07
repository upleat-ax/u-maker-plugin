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
  - ${PLUGIN_ROOT}/_refer/html-report-standard.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  - u-maker:u-agent-qa
---

# u-agent-bug-report

`u-agent-qa` 에이전트를 호출하여 결함 분석 리포트를 생성한다.

## Output

- `.u-maker/docs/{app}/04-check/4_Report_QA.md`
- `.u-maker/docs/{app}/04-check/4_Report_QA.json`
- `.u-maker/docs/{app}/04-check/4_Report_QA.html`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- 3종 파일 동시 생성: `.md` + `.json` + `.html`
- `.html`은 `html-report-standard.md`의 템플릿 구조를 따름
- `.md`와 `.html`은 동일한 데이터, 동일한 버전
- HTML은 단일 파일로 완결 (외부 CSS/JS 금지, Pretendard CDN만 허용)
- Post-Execution Summary Box 출력 필수
