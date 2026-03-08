---
name: u-skill-loop
description: |
  종료 조건 충족까지 PDCA 사이클을 자동 반복한다.
  DO Phase 완료 후 gap-detector로 Match Rate를 측정하고, 90% 미달 시 Gap FT별로 DO를 반복한다.
  Triggers: /u-skill-loop, 루프, 자동 반복, auto loop
model: sonnet
user-invocable: true
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

> PDCA 사이클(PLAN→DESIGN→DO→GAP CHECK→CHECK→ACT)을 종료 조건 충족까지 자동 반복한다.
> DO Phase 완료 후 `u-skill-gap-detector`로 Match Rate를 측정하고,
> **90% 미달 시 Gap FT별로 DO를 반복(Inner Gap Loop)**하여 90% 이상이 된 후 CHECK Phase로 진행한다.

## Exit Criteria (모두 충족 시 종료)

1. Critical/Major 결함 0건
2. SRS 전체 FT 구현 완료 (모든 FT Implemented)
3. 빌드 성공 (`bun run build`)

## Loop Flow

```
Iteration N 시작
    |
    +-- PLAN Phase (u-skill-plan)
    |       |
    |   [PLAN Gate] -- Fail --> PLAN 보완
    |       |
    +-- DESIGN Phase (u-skill-design)
    |       |
    |   [DESIGN Gate] -- Fail --> DESIGN 보완
    |       |
    +-- DO Phase (u-skill-dev)
    |       |
    +-- [Gap Analysis] ← u-skill-gap-detector 실행
    |       |
    |   Match Rate >= 90%? -- No --> [Inner Gap Loop]
    |       |                              |
    |       |                  Gap FT 목록 추출
    |       |                  (미구현 FT 식별)
    |       |                              |
    |       |                  FT별 DO 재실행
    |       |                  (해당 FT만 증분 구현)
    |       |                              |
    |       |                  gap-detector 재측정
    |       |                              |
    |       |                  >= 90%? -- No --> FT별 DO 재실행 (최대 maxGapRetries)
    |       |                         -- Yes --> CHECK Phase
    |       |
    +-- CHECK Phase (u-skill-check)
    |       |
    |   Exit Criteria 충족? -- Yes --> Loop Report 생성 --> COMPLETE
    |                        -- No  --> ACT Phase
    |                                       |
    +---------------------------------------+
              다음 Iteration
```

## Inner Gap Loop 상세

DO Phase 완료 후 gap-detector를 실행하여 Match Rate를 산출한다:

| Match Rate | Action |
|-----------|--------|
| >= 90% | Gap 기준 통과 → CHECK Phase 진행 |
| < 90% | Gap FT 목록 추출 → FT별 DO 재실행 → 재측정 반복 |

### Gap FT별 DO 재실행 규칙

- `1_SRS_RA.md`에서 미구현(NotImplemented/Partial) FT 목록 추출
- 각 Gap FT에 대해 `u-agent-dv-fe` + `u-agent-dv-be`를 FT 단위로 호출
- 재실행 시 해당 FT 관련 파일만 증분 수정 (전체 재작성 금지)
- `u-skill-build`로 빌드 확인 후 gap-detector 재측정
- 최대 재시도: `maxGapRetries` (기본 3회, config에서 설정 가능)

### Gap 진행 현황 출력 형식

```
[Gap Loop] Iter-N / Gap Attempt-M
  Match Rate: 72% → 85% → 92% (PASS)
  Gap FTs: FT-0030 (API 연동), FT-0040 (화면 구현)
  Resolved: FT-0030 ✓  FT-0040 ✓
```

## Loop Report

루프 종료 시 (Exit Criteria 충족 또는 최대 Iteration 도달) `u-skill-report`를 자동 호출한다.
보고서는 `.md` + `.html` 2종으로 생성되며, FR/US/FT/NFR 구현 현황, QA 결과, 결함, 기술 부채, Iteration 이력을 포함한다.

## Rules

- 매 Iteration 시작 시 진행률 보고
- 최대 반복 제한: `maxIterations` (기본 10)
- Inner Gap Loop 최대 재시도: `maxGapRetries` (기본 3, config에서 설정)
- Gap Loop 횟수 초과 시: 현재 Match Rate를 기록하고 CHECK Phase로 강제 진행
- Iteration 2+: 변경 필요한 문서/코드만 증분 갱신 (전체 재작성 금지)
- gap-detector 결과는 `3_Code_DV.md`의 Gap 섹션에 이력으로 누적
- 루프 종료 시 Loop Report 자동 생성 필수 (Gap 이력 포함)
- Post-Execution Summary Box 출력 필수
