---
name: engine-workflow-runner
description: |
  다단계 워크플로우를 실행하고, 진행 추적, 중간 실패 처리,
  체크포인트 기반 재개를 지원하는 워크플로우 실행 엔진.
version: 2.0.0
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
imports:
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
---

# Engine: Workflow Runner

> 멀티 스텝 워크플로우를 실행하고 진행 상태를 추적하며, 실패 시 복구를 지원한다.

## 역할

- 워크플로우 정의 로드 및 순차 실행
- 스텝별 진행률 추적 (N/M 형식)
- 실행 모드 지원: auto, interactive, step
- 중간 실패 시 롤백 가이드 제공
- 체크포인트 저장 및 재개

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | 워크플로우 ID (예: `plan`, `design`, `loop`), 실행 모드, 스코프 |
| **Output** | `{ status, completedSteps[], currentStep, checkpoint, errors[] }` |

## 워크플로우 정의

각 워크플로우는 순서가 정해진 스텝 배열:

```
plan:  [Roadmap → Common_RA → SRS → IA → Index]
design: [ERD → API → Screen → ScreenFlow → Index]
do:    [DesignSystem → Figma → FE-Code → BE-Code → Build]
check: [TestCase → TestExec → TestReport]
act:   [Review → IterationLog → Retrospective]
loop:  [plan → design → do → check → act] (전체 사이클)
```

## 실행 절차

### Step 1. 워크플로우 로드

1. 워크플로우 ID로 스텝 배열 결정
2. 현재 스코프(앱, 공용)에 맞게 파라미터 바인딩
3. 기존 체크포인트 확인 → 있으면 재개 여부 질의

### Step 2. 실행 모드 적용

| 모드 | 동작 |
|------|------|
| `auto` | 모든 스텝 자동 연속 실행. 실패 시만 정지 |
| `interactive` | 결정 포인트(Gate, 분기)에서 사용자 확인 후 진행 |
| `step` | 매 스텝 완료 후 일시정지. 사용자 승인으로 다음 스텝 |

### Step 3. 스텝 순차 실행

각 스텝에 대해:
1. **Pre-check**: 이전 스텝 산출물 존재 확인
2. **Execute**: 해당 스킬/에이전트 호출
3. **Post-check**: 산출물 생성 확인 + _index.json 갱신 확인
4. **Checkpoint 저장**: `.u-maker/.checkpoint.json`에 현재 상태 기록
5. **Progress 출력**: `[3/5] SRS 작성 완료 ✓`

### Step 4. 실패 처리

스텝 실행 실패 시:
1. 에러 로그 기록
2. 체크포인트에 실패 스텝 표시
3. 롤백 가이드 제공:
   - 부분 생성된 파일 목록
   - 수동 정정 필요 항목
   - 재시도 커맨드 안내
4. `interactive`/`step` 모드: 재시도/건너뛰기/중단 선택지 제공

### Step 5. 체크포인트 재개

`.u-maker/.checkpoint.json` 구조:
```json
{
  "workflow": "plan",
  "scope": "web",
  "mode": "auto",
  "completedSteps": ["Roadmap", "Common_RA"],
  "currentStep": "SRS",
  "status": "paused",
  "timestamp": "2026-03-27T10:00:00Z"
}
```

재개 시: `completedSteps` 이후의 `currentStep`부터 실행 계속

## 오류 처리

| 상황 | 처리 |
|------|------|
| 이전 스텝 산출물 미존재 | 해당 스텝부터 재실행 제안 |
| 에이전트 호출 실패 | 3회 재시도 후 실패 기록 + 체크포인트 저장 |
| 체크포인트 파일 손상 | 처음부터 재시작 제안 |
| 워크플로우 ID 미인식 | 사용 가능한 워크플로우 목록 출력 |

## 연동

- **호출원**: `u-skill-plan`, `u-skill-design`, `u-skill-dev`, `u-skill-loop` 등 Phase 스킬
- **호출 대상**: 각 스텝에 해당하는 에이전트/스킬
- **의존 엔진**: engine-phase-detector (Phase 전환 판단), engine-doc (산출물 확인)
