---
name: u-check
description: |
  CHECK Phase. TC 설계 + 테스트 실행 + Report + exit criteria 판정.
  Triggers: /u-check, 검증, 테스트, check, test, QA, TC, 테스트 케이스, 품질 검사
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [-i] [--step]"
model: sonnet
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
  - ${PLUGIN_ROOT}/shared/references/ssot-standard.md
  - ${PLUGIN_ROOT}/shared/references/post-execution-summary.md
  - ${PLUGIN_ROOT}/templates/04-check/testcase.template.md
  - ${PLUGIN_ROOT}/templates/04-check/qa-report.template.md
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-check -- CHECK Phase 실행

> TC(Test Case)를 설계하고 테스트를 실행하여 품질을 검증한다.

## 문법

```
/u-check [scope] [-i] [--step]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 자동 감지)

## Flags

| Flag | 설명 |
|------|------|
| `-i` | 대화형 모드 |
| `--step` | 단계별 실행 (TC 설계 → 실행 → 리포트 → 판정) |

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **선행 확인** -- 구현 코드 및 설계 문서 존재 검증
3. **TC 설계** -- FT/US 기반 테스트 케이스 자동 생성
   - Unit TC, Integration TC, E2E TC 분류
4. **테스트 실행** -- engine-test로 자동 테스트 수행
5. **결과 수집** -- Pass/Fail/Skip 집계
6. **QA Report 생성** -- 테스트 결과 + 결함 목록 + 커버리지
7. **Exit Criteria 판정** -- 통과 기준 충족 여부 결정
   - Pass → CHECK 완료, ACT Phase로 전환 가능
   - Fail → 결함 목록 + 재작업 대상 FT 식별
8. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-workflow-runner | 테스트 오케스트레이션 |
| engine-test | TC 실행 |
| engine-validator | exit criteria 판정 |

## 에이전트 시퀀스

```
orchestrator → guardian (TC 설계 + 테스트 실행 + 판정)
```

## 규칙

- TC는 FT ID와 1:N 매핑 (하나의 FT에 여러 TC 가능)
- QA Report는 `.md` + `.json` + `.html` 3종 생성
- Exit Criteria 미충족 시 ACT Phase 전환 차단
- 결함은 severity(Critical/Major/Minor/Trivial) 분류 필수

## 사용 예시

```
/u-check my-app
/u-check my-app --step
/u-check -i
```
