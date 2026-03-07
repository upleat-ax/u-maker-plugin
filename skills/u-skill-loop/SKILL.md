---
name: u-skill-loop
description: |
  종료 조건 충족까지 PDCA 사이클을 자동 반복한다.
  Triggers: /u-skill-loop, 루프, 자동 반복, auto loop
model: sonnet
user-invocable: true
argument-hint: "[args]"
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
agents:
  - u-agent-pm: u-maker:u-agent-pm
  - u-agent-ra: u-maker:u-agent-ra
  - u-agent-sa: u-maker:u-agent-sa
  - u-agent-ux: u-maker:u-agent-ux
  - u-agent-dv-fe: u-maker:u-agent-dv-fe
  - u-agent-dv-be: u-maker:u-agent-dv-be
  - u-agent-qa: u-maker:u-agent-qa
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/_refer/tech-stack-rules.md
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
---

# PDCA Auto Loop

> 종료 조건 충족까지 PDCA 사이클(PLAN→DESIGN→DO→CHECK→ACT)을 자동 반복한다.

## Exit Criteria (4가지 모두 충족 시 종료)

1. Critical/Major 결함 0건
2. SRS 전체 FT 구현 (모든 FT가 Implemented)
3. 빌드 성공 (bun run build)

## Loop Flow

1. Iteration N 진행률 보고
2. PLAN Phase → Gate 검증 → DESIGN Phase → Gate 검증 → DO Phase → Gate 검증 → CHECK Phase
3. Exit Criteria 충족 → Loop Report 생성 → COMPLETE
4. 미충족 → ACT Phase → 다음 Iteration

각 Phase는 해당 Phase의 skill을 호출하여 실행한다:
- PLAN: u-skill-plan skill의 로직 수행
- DESIGN: u-skill-design skill의 로직 수행
- DO: u-skill-dev skill의 로직 수행
- CHECK: u-skill-check skill의 로직 수행
- ACT: u-skill-act skill의 로직 수행

## Loop Report

루프 종료 시 (Exit Criteria 충족 또는 최대 Iteration 도달) `u-skill-loop-report`를 호출하여 종합 보고서를 자동 생성한다.
보고서는 `.md` + `.json` + `.html` 3종으로 생성된다.

## Rules

- 매 Iteration 시작 시 진행률 보고
- 최대 반복 제한: .u-maker/u-maker.config.json의 maxIterations (기본 10)
- Iteration 2+: 변경 필요한 문서/코드만 증분 갱신 (전체 재작성 금지)
- 루프 종료 시 Loop Report 자동 생성 필수
- Post-Execution Summary Box 출력 필수
