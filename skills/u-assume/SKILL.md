---
name: u-assume
description: |
  Assumption 관리. approve/reject 액션으로 가정을 채택하거나 기각한다.
  Triggers: /u-assume, 가정, assumption, assume, approve, reject, 가정 승인, 가정 기각
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [action] [id]"
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
  - ${PLUGIN_ROOT}/skills/u-assume/references/assumptions-spec.md
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-assume -- Assumption 관리

> SSoT 문서 작성 시 발생한 가정(Assumption)을 관리한다. 승인 또는 기각하고 영향을 전파한다.

## 문법

```
/u-assume [scope] [action] [id]
```

- `scope`: 앱 이름 | `common` (생략 시 자동 감지)
- `action`: `approve` | `reject` (생략 시 미리뷰 목록 표시)
- `id`: Assumption ID (예: `ASM-0001`)

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **Assumption 로드** -- 전체 assumption 목록 수집
3. **액션 분기**
   - 액션 생략: 미리뷰 assumption 목록 표시
   - `approve`: 해당 assumption을 채택, 문서에 확정 반영
   - `reject`: 해당 assumption을 기각, cascade impact 분석
4. **Impact 분석** (reject) -- engine-dep으로 영향받는 문서/항목 식별
5. **전파** (reject) -- 영향받는 항목에 `[ASSUMPTION_REJECTED]` 태그 부여
6. **문서 갱신** -- `.md` + `.json` 동시 갱신
7. **결과 보고** -- Post-Execution Summary 출력

## Assumption 상태

| 상태 | 설명 |
|------|------|
| `pending` | 미리뷰 (기본 상태) |
| `approved` | 채택됨 -- 문서에 확정 반영 |
| `rejected` | 기각됨 -- cascade 전파 |

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-dep | reject 시 cascade impact 분석 |

## 에이전트 시퀀스

```
orchestrator → planner (assumption 평가 + 문서 갱신)
```

## 규칙

- rejected assumption에 의존하는 항목은 모두 재검토 필요
- approve 시 가정 내용이 해당 문서의 정식 내용으로 확정
- 모든 assumption에는 출처(origin) 문서와 항목 ID 기록

## 사용 예시

```
/u-assume my-app
/u-assume my-app approve ASM-0001
/u-assume my-app reject ASM-0003
```
