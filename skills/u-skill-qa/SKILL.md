---
name: u-skill-qa
description: |
  테스트를 실행한다. Unit Test(Vitest) + E2E Test(Playwright) 실행 및 결과 리포트.
  4_Case_QA.md의 테스트 케이스를 기반으로 실행하고 4_Report_QA.md에 결과를 기록한다.
  Optional [app] argument for multi-app projects (e.g., `/u-skill-qa web`).
  Triggers: /u-skill-qa, 테스트 실행, test run, test execute
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
agents:
  - u-maker:u-agent-qa
---

# u-skill-qa

`u-agent-qa` 에이전트를 호출하여 테스트를 실행한다.

## Output

- `.u-maker/docs/{app}/04-check/4_Report_QA.md`

## Prerequisites

- `4_Case_QA.md` 존재 (테스트 케이스 설계 완료)
- `bun run build` 성공 상태

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Workflow

1. `4_Case_QA.md`에서 테스트 케이스 목록 읽기
2. Unit Test 실행: `bun run test`
3. E2E Test 실행: `bunx playwright test`
4. 결과 수집 및 `4_Report_QA.md` 생성/갱신
5. Fail 케이스 → DEF(결함) 항목 생성
6. Exit Criteria 평가

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
