---
name: u-agent-qa
description: |
  Agent QA(Tester)에게 직접 작업을 요청한다. 테스트 설계, 실행, 결함 분석 등.
  Triggers: /u-agent-qa, QA에게, 테스터에게
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
  - u-maker:u-agent-qa
---

# u-agent-qa

`u-agent-qa` 에이전트를 호출하여 사용자가 요청한 작업을 수행한다.

## Scope

- 테스트 케이스 설계 (Unit/Vitest + E2E/Playwright)
- 테스트 실행
- 결함 분석 리포트
- 커버리지 매트릭스

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
