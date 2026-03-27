---
name: u-gate
description: |
  Phase Gate 충족 여부 검사 + 다음 Phase 전환.
  Triggers: /u-gate, 게이트, gate, phase 전환, 단계 전환, phase check, 게이트 검사
version: 2.0.0
user-invocable: true
argument-hint: "[scope]"
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
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-gate -- Phase Gate 검사

> 현재 Phase의 Gate 충족 여부를 검사하고 다음 Phase로 전환한다.

## 문법

```
/u-gate [scope]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 자동 감지)

## Phase Gate 조건

| Phase | Gate 조건 | 다음 Phase |
|-------|-----------|------------|
| PLAN | SRS + IA + Roadmap 모두 Approved | DO (Design) |
| DO (Design) | ERD + API + Screen + UXGuide Approved | DO (Dev) |
| DO (Dev) | 모든 FT 구현 완료 | CHECK |
| CHECK | Exit Criteria 통과 | ACT |
| ACT | Retrospective 완료 | PLAN (다음 Iteration) |

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **현재 Phase 감지** -- engine-phase-detector로 현재 상태 확인
3. **Gate 조건 수집** -- 현재 Phase의 Gate 조건 목록 로드
4. **충족 여부 검사** -- engine-validator로 각 조건 점검
5. **결과 표시** -- 조건별 Pass/Fail 상태 표시
   ```
   [PASS] SRS -- Approved (2026-03-25)
   [PASS] IA -- Approved (2026-03-26)
   [FAIL] Roadmap -- Draft (미완료)
   ```
6. **Phase 전환** -- 모든 조건 Pass 시 다음 Phase로 전환
7. **Config 갱신** -- `u-ssot.config.json`의 Phase 값 업데이트
8. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-phase-detector | 현재 Phase 감지 |
| engine-validator | Gate 조건 검증 |

## 에이전트 시퀀스

```
orchestrator → guardian (Gate 검증 + 전환 판정)
```

## 규칙

- 하나라도 Fail이면 Phase 전환 차단
- 전환 시 Phase 변경 로그 기록
- 강제 전환 불가 (모든 조건 충족 필수)
- Gate 검사 결과는 JSON으로도 출력 가능

## 사용 예시

```
/u-gate my-app
/u-gate
```
