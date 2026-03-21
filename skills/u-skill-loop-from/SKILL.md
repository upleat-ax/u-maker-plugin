---
name: u-skill-loop-from
description: |
  지정 Phase부터 PDCA 루프를 시작한다. 예: /u-skill-loop-from design
  Args: `<phase>` — 시작 Phase (plan|design|do|check|act) (필수)
  Triggers: /u-skill-loop-from, 루프 시작점, 특정 페이즈부터 시작, start from phase, resume loop, 루프 재개, loop from, 페이즈 지정, phase resume, 중간부터 시작, restart from, continue from
model: sonnet
user-invocable: true
argument-hint: "<plan|design|do|check|act>"
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

# PDCA Loop from Phase

> 지정 Phase부터 PDCA 루프를 시작한다.

## Syntax

`/u-skill-loop-from <phase>` (phase: `plan` | `design` | `do` | `check` | `act`)

예: `/u-skill-loop-from design` → DESIGN Phase부터 시작

## Execution Steps

1. **인자 검증**
   - `<phase>` 미입력 시 AskUserQuestion으로 요청
   - 유효 값: `plan`, `design`, `do`, `check`, `act`

2. **전제조건 검증** (`u-agent-ra`)
   - `u-maker.config.json` 읽기 → `loopStatus` 확인
   - `loopStatus`가 `RUNNING`이면 "이미 루프 실행 중" 경고 후 중단
   - 지정 Phase 이전 Phase의 Gate 조건 충족 여부 검증:
     - `design`부터 시작 → PLAN Gate 충족 확인 (Roadmap, SRS, IA = Final)
     - `do`부터 시작 → DESIGN Gate 충족 확인 (ERD, API, Screen 등 = Final)
     - `check`부터 시작 → DO Gate 충족 확인 (코드 구현 완료 + 빌드 성공)
     - `act`부터 시작 → CHECK 결과 존재 확인
     - `plan`부터 시작 → 전제조건 없음
   - Gate 미충족 시 AskUserQuestion: "이전 Phase Gate가 미충족입니다. 강제 진행하시겠습니까?"

3. **루프 상태 설정**
   - `loopStatus` → `RUNNING`
   - `currentPhase` → 지정 Phase
   - `loopStartedAt` → 현재 타임스탬프

4. **Phase 실행**
   - 지정 Phase부터 CHECK까지 순차 실행 (각 Phase의 u-skill 호출)
   - Phase 순서: PLAN → DESIGN → DO → CHECK
   - 각 Phase 완료 시 Gate 검증 후 다음 Phase 진행

5. **Exit Criteria 검증** (`iteration-rules.md` 기준)
   - 충족 시 → COMPLETE, `loopStatus` → `IDLE`
   - 미충족 시 → ACT Phase 실행 → 다음 Iteration (PLAN부터 재개)

6. **반복 제한**: `maxIterations` (기본 10회) 도달 시 강제 종료

## Rules

- `u-skill-loop`의 `all` 모드(FT-by-FT)는 지원하지 않음. 기본(bulk) 모드로만 동작
- 나머지 규칙은 `u-skill-loop`과 동일 (Gap Loop, 빌드 검증 등)
- Post-Execution Summary Box 출력 필수 (규격: `post-execution-summary.md`)
