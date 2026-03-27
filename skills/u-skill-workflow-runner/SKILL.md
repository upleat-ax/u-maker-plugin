---
name: u-skill-workflow-runner
description: "다단계 워크플로우를 실행하고, 진행 추적, 중간 실패 처리, 체크포인트 기반 재개를 지원하는 내부 실행 엔진."
---

# u-skill-workflow-runner -- Multi-Step Workflow Execution Engine

다단계 워크플로우를 정의된 순서대로 실행하고, 단계별 진행 추적, 체크포인트 저장, 실패 시 롤백, 중단 지점에서의 재개를 지원하는 내부 엔진이다.

**Owner Agent:** u-agent-orchestrator

---

## 1. Workflow Definition

워크플로우는 순서가 있는 Step 배열로 정의된다.

### Workflow Schema

```json
{
  "id": "WF-{command}-{scope}-{timestamp}",
  "command": "plan",
  "scope": "retail",
  "mode": "auto",
  "steps": [
    {
      "id": "step-1",
      "name": "validate-prerequisites",
      "description": "classified 데이터 존재 확인",
      "agent": "planner",
      "engine": null,
      "action": "validatePrerequisites",
      "params": { "scope": "retail", "required": ["requirements", "stakeholders"] },
      "timeout": 30000,
      "rollbackAction": null,
      "checkpoint": true
    },
    {
      "id": "step-2",
      "name": "generate-srs",
      "description": "SRS 문서 생성",
      "agent": "planner",
      "engine": "engine-doc",
      "action": "create",
      "params": { "type": "srs", "scope": "retail" },
      "timeout": 120000,
      "rollbackAction": "deleteDocument",
      "checkpoint": true
    }
  ],
  "status": "pending",
  "currentStep": 0,
  "startedAt": null,
  "completedAt": null,
  "checkpoints": []
}
```

---

## 2. Standard Workflow Definitions

### /u-plan Workflow

```
Step 1: validate-prerequisites → classified 데이터 존재 확인
Step 2: generate-srs → SRS 문서 생성 (.md + .json)
Step 3: generate-ia → IA 문서 생성 (.md + .json)
Step 4: generate-roadmap → Roadmap 생성 (.md + .json)
Step 5: update-index → _index.json 갱신
Step 6: update-links → _links.json 갱신
```

### /u-design Workflow

```
Step 1: verify-plan-gate → Plan phase gate 확인
Step 2: generate-erd → ERD 생성
Step 3: generate-api → API Contract 생성
Step 4: generate-screens → Screen 설계 생성
Step 5: generate-screen-flow → ScreenFlow 생성
Step 6: generate-ux-override → UX Override 생성 (조건부)
Step 7: generate-design-token → Design Token 생성 (조건부)
Step 8: generate-rtm → RTM 생성
Step 9: update-index → _index.json 갱신
Step 10: update-links → _links.json 갱신
```

### /u-dev Workflow

```
Step 1: verify-design-gate → Design phase gate 확인
Step 2: read-tech-stack → techStack 설정 읽기
Step 3: generate-fe → FE 코드 생성
Step 4: generate-be → BE 코드 생성
Step 5: generate-db → DB schema 생성
Step 6: generate-storybook → Storybook stories 생성
Step 7: spec-sync → 명세 일치 검증
Step 8: build-verify → 빌드 실행 + 검증
Step 9: update-docs → code.md + code.json 생성
Step 10: register-tech-debt → 기술부채 백로그 등록
```

### /u-qa Workflow

```
Step 1: verify-do-gate → Do phase gate 확인
Step 2: generate-test-cases → TC 자동 생성
Step 3: execute-unit-tests → Vitest 실행
Step 4: execute-e2e-tests → Playwright 실행
Step 5: classify-defects → 결함 분류
Step 6: register-bugs → 백로그 자동 등록
Step 7: generate-test-report → 테스트 리포트 생성 (3종)
Step 8: evaluate-exit-criteria → exit criteria 판정
Step 9: update-rtm → RTM 테스트 결과 갱신
```

### /u-ship Workflow

```
Step 1: verify-check-gate → Check phase gate 확인
Step 2: final-validation → 최종 검증 (전체 consistency)
Step 3: update-iteration-log → iteration log 작성
Step 4: run-retrospective → 회고 세션 (retro)
Step 5: groom-backlog → 백로그 정리
Step 6: archive-iteration → 현재 iteration 아카이브
Step 7: prepare-next → 다음 iteration 준비
```

---

## 3. Execution Engine

### run(workflow)

워크플로우를 실행한다.

```
function run(workflow):
  workflow.status = "running"
  workflow.startedAt = now()

  for i = workflow.currentStep to workflow.steps.length:
    step = workflow.steps[i]
    workflow.currentStep = i

    // Step mode: 승인 대기
    if workflow.mode === "step":
      showStepPreview(step)
      if not userApproved(): return pause(workflow)

    // 실행
    result = executeStep(step)

    if result.status === "success":
      logStepResult(workflow, step, result)
      if step.checkpoint:
        saveCheckpoint(workflow)
      showProgress(i + 1, workflow.steps.length, step.name)

    elif result.status === "failure":
      handleFailure(workflow, step, result)
      return

    elif result.status === "skipped":
      logStepSkipped(workflow, step, result.reason)

  workflow.status = "completed"
  workflow.completedAt = now()
  return generateSummary(workflow)
```

### executeStep(step)

개별 Step을 실행한다.

```
function executeStep(step):
  timer = setTimeout(step.timeout)

  try:
    result = dispatch(step.agent, step.engine, step.action, step.params)
    clearTimeout(timer)
    return { status: "success", data: result }
  catch TimeoutError:
    return { status: "failure", error: "Step timed out after " + step.timeout + "ms" }
  catch Error as e:
    return { status: "failure", error: e.message }
```

---

## 4. Progress Tracking

### Progress Display

각 Step 완료 시 진행 상황을 표시한다.

```
▓▓▓▓▓▓▓░░░ Step 3/5: generate-ia (60%)
✓ Step 1: validate-prerequisites (2s)
✓ Step 2: generate-srs (45s)
▶ Step 3: generate-ia (running...)
○ Step 4: generate-roadmap
○ Step 5: update-index
```

### Step Result Log

```json
{
  "stepId": "step-2",
  "name": "generate-srs",
  "status": "success",
  "startedAt": "{ISO 8601}",
  "completedAt": "{ISO 8601}",
  "duration": 45200,
  "output": {
    "filesCreated": ["srs.md", "srs.json"],
    "itemsGenerated": { "FR": 12, "US": 28, "FT": 45 }
  }
}
```

---

## 5. Checkpoint & Resume

### Checkpoint Save

`checkpoint: true`가 설정된 Step 완료 후 자동 저장.

```json
{
  "workflowId": "WF-plan-retail-20260327",
  "checkpointStep": 2,
  "savedAt": "{ISO 8601}",
  "state": {
    "completedSteps": ["step-1", "step-2"],
    "generatedFiles": ["srs.md", "srs.json"],
    "intermediateData": { /* Step 간 전달 데이터 */ }
  }
}
```

저장 위치: `_sessions/workflows/WF-{id}.checkpoint.json`

### Resume from Checkpoint

```
function resume(workflowId):
  checkpoint = loadCheckpoint(workflowId)
  workflow = loadWorkflow(workflowId)

  // 완료된 Step 검증
  for step in checkpoint.state.completedSteps:
    if not verifyStepOutput(step):
      // 산출물이 유실됨 → 해당 Step부터 재실행
      workflow.currentStep = getStepIndex(step)
      return run(workflow)

  // 다음 Step부터 재개
  workflow.currentStep = checkpoint.checkpointStep + 1
  workflow.status = "running"
  return run(workflow)
```

---

## 6. Failure Handling

### Rollback Strategy

Step 실패 시:

1. **rollbackAction이 정의된 경우:**
   - 완료된 Step을 역순으로 rollback 시도
   - 각 rollback 결과 로깅

2. **rollbackAction이 없는 경우:**
   - 워크플로우를 `failed` 상태로 전환
   - 마지막 성공 체크포인트 정보 제공
   - 수동 복구 안내

### Failure Response

```json
{
  "workflowId": "WF-plan-retail-20260327",
  "status": "failed",
  "failedStep": {
    "id": "step-3",
    "name": "generate-ia",
    "error": "Missing workflow data in classified"
  },
  "completedSteps": ["step-1", "step-2"],
  "rollbackPerformed": true,
  "rollbackResults": [
    { "step": "step-2", "action": "deleteDocument", "result": "success" }
  ],
  "lastCheckpoint": "step-2",
  "recommendation": "/u-ingest retail 실행 후 /u-plan retail --resume WF-plan-retail-20260327"
}
```

### Retry Policy

| Failure Type | Auto-Retry | Max Retries |
|-------------|-----------|-------------|
| Timeout | Yes | 2 |
| Transient error | Yes | 1 |
| Missing prerequisite | No | -- |
| Validation failure | No | -- |

---

## 7. --only Flag Integration

`--only` 플래그가 설정된 경우, 워크플로우에서 해당 Step만 실행한다.

```
function applyOnlyFilter(workflow, onlyValue):
  // 전제조건 Step은 항상 포함
  // onlyValue에 해당하는 생성 Step만 포함
  // 후처리 Step(update-index, update-links)은 항상 포함

  filteredSteps = workflow.steps.filter(step =>
    step.type === "prerequisite" ||
    step.name.includes(onlyValue) ||
    step.type === "postprocess"
  )
  workflow.steps = filteredSteps
```

---

## 8. Safety Rules

1. Gate 검증 Step 실패 시 절대 후속 Step 진행 불가
2. 체크포인트는 `_sessions/workflows/`에 파일로 저장 (메모리 유실 방지)
3. rollback은 best-effort (실패해도 워크플로우는 계속 `failed` 상태)
4. Step mode에서 사용자가 거부하면 워크플로우를 pause 상태로 전환
5. 타임아웃은 Step별로 설정 (기본 120초, 빌드/테스트는 300초)
6. 동시에 동일 scope에서 2개 이상 워크플로우 실행 금지
