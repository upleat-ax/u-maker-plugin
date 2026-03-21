---
name: u-skill-testcase
description: |
  테스트 케이스를 설계한다. SRS Feature(FT) 기반으로 정상/비정상/경계값 케이스를 작성하며,
  각 FT에 대해 Unit Test 케이스와 E2E Test 케이스를 모두 포함해야 한다.
  테스트 스텝은 Actor/Screen/Element/Action/Input/Expected를 상세하게 작성한다.
  u-agent-qa 에이전트가 담당한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-testcase, 테스트 케이스, test case, QA, TC 생성, 테스트 설계, test design, 케이스 작성, generate test case, 테스트 케이스 생성, write test case, 품질 테스트
model: sonnet
user-invocable: true
argument-hint: "[app]"
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
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
agents:
  u-agent-qa: u-maker:u-agent-qa
---

# u-skill-testcase

`u-agent-qa` 에이전트를 호출하여 테스트 케이스를 설계한다. Unit(Vitest) + E2E(Playwright).

## Output

`.u-maker/docs/{app}/04-check/4_Case_QA.md`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
