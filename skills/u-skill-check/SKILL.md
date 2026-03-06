---
name: u-skill-check
description: |
  CHECK Phase 실행. 테스트 케이스 설계 → 실행 → 결함 분석 순서로 진행한다.
  테스트 케이스는 Unit Test와 E2E Test를 모두 포함해야 하며,
  각 테스트는 재현 가능한 상세 스텝으로 문서화한다.
  Optional [app] argument for multi-app projects (e.g., `/u-skill-check web`).
  Triggers: /u-skill-check, check phase, 검증, 테스트
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
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-ssot.config.json
agents:
  u-agent-qa: u-maker:u-agent-qa
---

# CHECK Phase

> 테스트 케이스 설계 → 실행 → 결함 분석 순서로 진행한다.

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app (e.g., `/u-skill-check web`) |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Execution Sequence

1. `u-agent-qa`: 테스트 케이스 설계 (`{app}/04-check/4_Case_QA.md`)
   - SRS FR 기반 케이스 도출
   - 정상/비정상/경계값 시나리오
   - Unit Test + E2E Test 모두 포함
2. `u-agent-qa`: 테스트 실행 및 결과 기록
   - 각 케이스 Pass/Fail 판정
   - `{app}/04-check/4_Report_QA.md`에 실행 결과 기록
3. `u-agent-qa`: 결함 분석
   - Fail 케이스 분류 (Critical/Major/Minor/Trivial)
   - 재현 시나리오, 원인 분석, 수정 제안

## Gate → COMPLETE

Critical/Major 0건 + 전체 FR 구현 + 빌드 성공

## Gate → ACT

위 조건 미충족 시

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
