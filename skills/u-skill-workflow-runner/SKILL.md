---
name: u-skill-workflow-runner
description: "다단계 워크플로우를 실행하고, 진행 추적, 중간 실패 처리, 체크포인트 기반 재개를 지원하는 내부 실행 엔진."
---

# u-skill-workflow-runner -- Multi-Step Workflow Execution Engine

다단계 워크플로우 순차 실행, 단계별 진행 추적, 체크포인트 저장, 실패 시 롤백, 중단 지점 재개.

**Owner Agent:** u-agent-orchestrator

---

## 1. Workflow Definition

Step 배열로 정의. 각 Step: `{ id, name, description, agent, engine, action, params, timeout, rollbackAction, checkpoint: bool }`

---

## 2. Standard Workflows

### /u-plan
validate-prerequisites → generate-srs → generate-ia → generate-roadmap → update-index → update-links

### /u-design
verify-plan-gate → generate-erd → generate-api → generate-screens → generate-screen-flow → generate-ux-override(조건부) → generate-design-token(조건부) → generate-rtm → update-index → update-links

### /u-dev
verify-design-gate → read-tech-stack → generate-fe → generate-be → generate-db → generate-storybook → spec-sync → build-verify → update-docs → register-tech-debt

### /u-qa
verify-do-gate → generate-test-cases → execute-unit-tests → execute-e2e-tests → classify-defects → register-bugs → generate-test-report → evaluate-exit-criteria → update-rtm

### /u-ship
verify-check-gate → final-validation → update-iteration-log → run-retrospective → groom-backlog → archive-iteration → prepare-next

---

## 3. Execution Engine

### run(workflow)

```
for each step:
  step mode → showPreview + userApprove (거부 시 pause)
  execute → success: log + checkpoint(설정 시) + progress 표시
           → failure: handleFailure
           → skipped: logSkipped
completed → generateSummary
```

### executeStep(step)

step.timeout 내에서 dispatch(agent, engine, action, params) 실행. 타임아웃/에러 시 failure 반환.

---

## 4. Progress Tracking

각 Step 완료 시 진행 바 + Step별 상태(completed/running/pending) 표시. Step result log: `{ stepId, name, status, startedAt, completedAt, duration, output }`

---

## 5. Checkpoint & Resume

### Checkpoint Save

`checkpoint: true` Step 완료 후 자동 저장 → `.state/sessions/workflows/WF-{id}.checkpoint.json`: completedSteps, generatedFiles, intermediateData

### Resume

checkpoint 로드 → 완료 Step 산출물 검증 (유실 시 해당 Step부터 재실행) → 다음 Step부터 재개

---

## 6. Failure Handling

### Rollback

rollbackAction 정의됨 → 완료 Step 역순 롤백. 미정의 → failed 상태 + 마지막 체크포인트 안내.

### Retry Policy

| Failure Type | Auto-Retry | Max |
|-------------|-----------|-----|
| Timeout | Yes | 2 |
| Transient error | Yes | 1 |
| Missing prerequisite | No | -- |
| Validation failure | No | -- |

---

## 7. --only Flag

전제조건 Step 항상 포함 + onlyValue 매칭 Step + 후처리 Step(update-index/links) 항상 포함.

---

## 8. --loop Quality Loop Mode

`--loop` 플래그 활성화 시, 각 workflow step(또는 전체 workflow)에 gatekeeper 품질 평가 루프를 적용.

### 8.1 적용 범위

| 모드 | 동작 |
|------|------|
| **단일 command** (`/u-plan --loop`) | 전체 workflow 완료 후 1회 loop 평가 |
| **multi-step workflow** (`/u-loop --loop`) | 각 phase 완료 시마다 loop 평가 |

### 8.2 Step 실행 with Loop

```
for each step (or workflow):
  execute(agent, engine, action, params)
    ↓
  if --loop enabled:
    loopIteration = 0
    do:
      loopIteration++
      gatekeeperScore = dispatch(gatekeeper, "loop-quality-gate", results)
      save scorecard to .state/sessions/loop-scores/
      if gatekeeperScore.average > threshold:
        break  // PASS
      if loopIteration >= maxIterations:
        break  // STOP (max reached)
      enhancedParams = merge(params, gatekeeperScore.directive)
      re-execute(agent, engine, action, enhancedParams)
    while true
    ↓
  checkpoint + progress (include loop score)
```

### 8.3 Checkpoint 확장

Loop 활성화 시 checkpoint에 loop state 포함:

```json
{
  "stepId": "generate-srs",
  "status": "completed",
  "loop": {
    "iterations": 2,
    "finalAverage": 96.4,
    "verdict": "PASS",
    "scoresFile": ".state/sessions/loop-scores/LOOP-plan-20260402T120000.json"
  }
}
```

### 8.4 Resume with Loop

체크포인트에서 재개 시 loop state도 복원. 이전 iteration 스코어 참조하여 이미 PASS한 step은 재평가 생략.

---

## 9. Safety Rules

1. Gate 검증 실패 시 후속 Step 진행 불가
2. 체크포인트는 파일 저장 (메모리 유실 방지)
3. rollback은 best-effort, step mode 거부 시 pause
4. 타임아웃 Step별 (기본 120초, 빌드/테스트 300초)
5. 동일 scope에서 2개+ 워크플로우 동시 실행 금지
