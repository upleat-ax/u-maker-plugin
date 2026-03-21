---
name: u-skill-loop
description: |
  종료 조건 충족까지 PDCA 사이클을 자동 반복한다.
  DO Phase 완료 후 gap-detector로 Match Rate를 측정하고, 90% 미달 시 Gap FT별로 DO를 반복한다.
  Args: `[all]` — 모든 FT를 하나씩 순회하며 PDCA 구현
  Triggers: /u-skill-loop, 루프, 자동 반복, auto loop, PDCA 루프, pdca loop, 자동화 루프, 반복 실행, loop start, 루프 시작, 전체 루프, full loop
model: sonnet
user-invocable: true
argument-hint: "[all]"
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
  u-agent-pm: u-maker:u-agent-pm
  u-agent-ra: u-maker:u-agent-ra
  u-agent-sa: u-maker:u-agent-sa
  u-agent-ux: u-maker:u-agent-ux
  u-agent-dv-fe: u-maker:u-agent-dv-fe
  u-agent-dv-be: u-maker:u-agent-dv-be
  u-agent-qa: u-maker:u-agent-qa
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

## Arguments

| Argument | Description |
|----------|-------------|
| (없음) | 기본 모드. 전체 FT를 일괄 DO 후 Gap Check |
| `all` | FT 순회 모드. 모든 FT를 하나씩 순회하며 구현→빌드→갭체크를 반복 |

## Exit Criteria (모두 충족 시 종료)

1. Critical/Major 결함 0건
2. SRS 전체 FT 구현 완료 (모든 FT Implemented)
3. 빌드 성공 (`bun run build`)

---

## Mode 1: 기본 모드 (인자 없음)

### Loop Flow

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
    +-- DO Phase (u-skill-dev)  ← 전체 FT 일괄 구현
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

---

## Mode 2: FT 순회 모드 (`all`)

SRS의 모든 FT를 하나씩 순회하며 PDCA로 구현한다.
PLAN/DESIGN은 최초 1회 일괄 실행하고, DO Phase에서 FT 단위로 반복한다.

### all 모드 Flow

```
[Phase 0] PLAN + DESIGN (1회 일괄)
    |
    +-- PLAN Phase (u-skill-plan)
    |       [PLAN Gate] -- Fail --> PLAN 보완
    |
    +-- DESIGN Phase (u-skill-design)
            [DESIGN Gate] -- Fail --> DESIGN 보완
    |
[Phase 1] FT 순회 DO Loop
    |
    +-- SRS에서 전체 FT 목록 추출
    |   (Implemented=No/Partial인 FT 우선, 이후 Yes인 FT도 검증)
    |
    +-- FT Queue 생성 (FR 그룹 → FT 순서)
    |
    +-- FOR EACH FT in Queue:
    |       |
    |       +-- [FT 진행률 출력]
    |       |     "FT-XXXX (N/M): {Feature Name}"
    |       |
    |       +-- DO: FT 단위 구현
    |       |     u-agent-dv-fe + u-agent-dv-be (해당 FT 관련 파일만)
    |       |
    |       +-- BUILD: u-skill-build (빌드 확인)
    |       |     -- Fail --> 빌드 오류 수정 후 재시도 (최대 3회)
    |       |
    |       +-- VERIFY: 해당 FT 구현 확인
    |       |     SRS의 FT Implemented 컬럼 → Yes로 갱신
    |       |     3_Code_DV.md 갱신 (해당 FT 파일 매핑 추가)
    |       |
    |       +-- [FT 완료 출력]
    |       |     "FT-XXXX DONE (N/M, elapsed: Xs)"
    |       |
    |       +-- 다음 FT로 이동
    |
[Phase 2] 전체 Gap Analysis
    |
    +-- u-skill-gap-detector 실행
    |   Match Rate >= 90%? -- No --> Inner Gap Loop (기본 모드와 동일)
    |                      -- Yes --> CHECK Phase
    |
[Phase 3] CHECK Phase (u-skill-check)
    |
    +-- Exit Criteria 충족? -- Yes --> Loop Report --> COMPLETE
    |                        -- No  --> ACT Phase → 다음 Iteration
    |                                  (Iteration 2+는 미구현 FT만 순회)
```

### FT Queue 생성 규칙

1. `{app}/01-plan/1_SRS_RA.md`의 Features(FT) 테이블 읽기
2. FT를 FR 그룹별로 정렬 (FR-0010 소속 FT → FR-0020 소속 FT → ...)
3. 구현 상태별 우선순위:
   - `No` (미구현) → 최우선
   - `Partial` (부분 구현) → 차순위
   - `Yes` (구현 완료) → 검증만 수행 (코드 존재 확인, 빌드 확인)
4. 의존성이 있는 FT는 피의존 FT 이후에 배치

### FT 단위 DO 실행 규칙

- 각 FT에 대해 `u-agent-dv-fe` + `u-agent-dv-be`를 **해당 FT 스코프로만** 호출
- 에이전트에게 전달할 컨텍스트:
  - FT-ID, Feature Name, Description
  - 관련 FR/US 매핑
  - API Contract에서 해당 FT 관련 엔드포인트
  - Screen Design에서 해당 FT 관련 화면
  - ERD에서 해당 FT 관련 엔티티
- 구현 범위: 해당 FT 관련 파일만 생성/수정 (다른 FT 파일 수정 금지)
- FT 완료 후 즉시 `1_SRS_RA.md`의 해당 FT `Implemented` 컬럼을 `Yes`로 갱신

### FT 순회 진행 현황 출력 형식

```
================================================================
[PDCA Loop ALL] Iteration 1 — FT 순회 DO Phase
================================================================
  Total FTs: 8 | Todo: 1 | Partial: 1 | Done: 6
  Queue: FT-0020 → FT-0070 → (verify: FT-0010, FT-0030~0060, FT-0080)
----------------------------------------------------------------
  [1/8] FT-0020 (Existing Repo Init) .............. IN PROGRESS
        DO: u-agent-dv-fe + u-agent-dv-be
        BUILD: PASS
        VERIFY: Yes
        FT-0020 DONE (12s)
  [2/8] FT-0070 (Agent/Skill Registry) ............ VERIFY ONLY
        Code exists: Yes
        BUILD: PASS
        FT-0070 VERIFIED (3s)
  ...
----------------------------------------------------------------
  FT Loop Complete: 8/8
  Overall Match Rate: 95% (PASS)
================================================================
```

### Iteration 2+ 동작 (all 모드)

- ACT Phase에서 다음 Iteration으로 전환 시, SRS를 다시 읽어 미구현 FT만 Queue에 추가
- 이미 `Yes`인 FT는 다시 순회하지 않음 (검증 생략)
- 새로 추가된 FT가 있으면 Queue에 포함

---

## Inner Gap Loop 상세 (공통)

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
