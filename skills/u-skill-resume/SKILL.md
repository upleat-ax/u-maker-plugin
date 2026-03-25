---
name: u-skill-resume
description: |
  중단된 PDCA 루프를 재개한다. 중단점부터 이어서 진행한다.
  Triggers: /u-skill-resume, 루프 재개, resume loop, 재개, 이어서, continue, 중단 재개, resume pdca, 루프 계속, loop continue, 작업 재개, resume task
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

# Loop Resume

> 중단된 PDCA 루프를 재개한다.

## Execution Steps

1. **중단 상태 읽기**
   - `u-maker.config.json`에서 `loopStatus`, `currentPhase`, `pausedAt`, `pauseMemo` 확인

2. **상태 검증**
   - `loopStatus`가 `PAUSED`가 아닌 경우:
     - `IDLE` → "중단된 루프가 없습니다. `/u-skill-loop`으로 새 루프를 시작하세요." 출력 후 종료
     - `RUNNING` → "이미 루프가 실행 중입니다." 출력 후 종료
   - `currentPhase`가 유효한 Phase가 아닌 경우 → AskUserQuestion으로 Phase 확인

3. **문서 상태 재검증** (`u-agent-ra`)
   - 중단 이후 문서가 외부에서 변경되었을 수 있음
   - 현재 Phase 이전까지의 Gate 조건 재확인
   - Gate 미충족 시 AskUserQuestion: "중단 이후 문서 상태가 변경되었습니다. [변경 내역]. 해당 Phase(미충족 Gate의 Phase)부터 재실행하시겠습니까?"
   - "이전 Phase"란 **Gate가 미충족된 Phase** (예: DESIGN Gate 미충족 시 DESIGN부터 재실행)
   - 중단 Phase의 산출 문서가 Draft로 돌아간 경우 → 해당 Phase 처음부터 재실행

4. **루프 상태 갱신**
   - `loopStatus` → `RUNNING`
   - `resumedAt` → 현재 타임스탬프

5. **중단점부터 루프 재개**
   - `currentPhase`부터 CHECK까지 순차 실행
   - 이후 `u-skill-loop`과 동일한 흐름 (Exit Criteria 검증 → COMPLETE 또는 ACT → 다음 Iteration)

## Rules

- 나머지 규칙은 `u-skill-loop`과 동일 (Gap Loop, 반복 제한 등)
- Post-Execution Summary Box 출력 필수 (규격: `post-execution-summary.md`)
