---
name: u-skill-test
description: |
  테스트 케이스를 설계한다. SRS FR 기반으로 정상/비정상/경계값 케이스를 작성하며,
  각 FR에 대해 Unit Test 케이스와 E2E Test 케이스를 모두 포함해야 한다.
  테스트 스텝은 Actor/Screen/Element/Action/Input/Expected를 상세하게 작성한다.
  u-agent-qa 에이전트가 담당한다.
  Optional [app] argument for multi-app projects (e.g., `/u-skill-test web`).
  Triggers: /u-skill-test, 테스트 케이스, test case, QA
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
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
---

# u-skill-test

agent: u-maker:u-agent-qa

`u-agent-qa` 에이전트를 호출하여 테스트 케이스를 설계한다. Unit + E2E.

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
