---
name: u-agent-qa
description: |
  Agent QA(Tester)에게 직접 작업을 요청한다. 테스트 설계, 실행, 결함 분석 등.
  Triggers: /u-agent-qa, QA에게, 테스터에게, qa agent, 테스트 설계, test design, 결함 분석, defect analysis, 테스트 실행, test execution, 커버리지, coverage, 품질 검증, quality check
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

## Purpose

`u-agent-qa` 에이전트를 호출하여 사용자가 요청한 QA(Quality Assurance) 작업을 수행한다.
테스트 설계, 실행, 결함 분석, 커버리지 리포트를 담당한다.

## Scope

- 테스트 케이스 설계 — Unit(Vitest) / E2E(Playwright) 기반 TC 작성
- 테스트 실행 — `bun run test` / `bun run test:e2e` 실행 및 결과 수집
- 결함 분석 리포트 — 실패 케이스 원인 분석 및 버그 티켓 생성
- 커버리지 매트릭스 — FT별 테스트 커버리지 현황 표

## Flow

1. 사용자 요청을 분석하여 수행할 QA 작업 유형을 결정한다.
2. `.u-maker/u-maker.config.json`에서 앱 컨텍스트와 tech stack을 확인한다.
3. 관련 FT 목록과 기존 테스트 케이스(`4_TestCase_QA.md`)를 읽는다.
4. 요청된 작업(설계/실행/분석)을 수행한다.
5. 산출 문서를 생성하거나 갱신한다.
6. 동명의 `.json` 파일을 동일 경로에 함께 저장한다.
7. Post-Execution Summary Box를 출력한다.

## Output

- `.u-maker/docs/{app}/04-qa/4_TestCase_QA.md` + `.json`
- `.u-maker/docs/{app}/04-qa/4_QAReport_QA_yyyymmddhhmm.md` + `.json` + `.html`
- `.u-maker/docs/{app}/04-qa/4_CoverageMatrix_QA.md` + `.json`

## When NOT to use

- 테스트 케이스 문서만 설계(코드 실행 없이) → `/u-skill-testcase` 사용
- 단순 빌드 확인 → `/u-skill-build` 사용

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- QA 리포트는 `.md` + `.json` + `.html` 3종 동시 생성
- Post-Execution Summary Box 출력 필수
