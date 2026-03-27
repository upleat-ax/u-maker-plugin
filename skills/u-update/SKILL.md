---
name: u-update
description: |
  SSoT 문서 수정. 변경 사항 반영 및 cascade 옵션으로 의존 문서 자동 갱신.
  Triggers: /u-update, 수정, 갱신, update, 문서 수정, 변경, modify, cascade
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [doc] [--cascade]"
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

# u-update -- 문서 수정

> SSoT 문서를 수정하고, 필요 시 의존 문서를 자동으로 함께 갱신한다.

## 문법

```
/u-update [scope] [doc] [--cascade]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 자동 감지)
- `doc`: 대상 문서 이름 (예: `srs`, `erd`, `api`, `screen`)

## Flags

| Flag | 설명 |
|------|------|
| `--cascade` | 의존 문서 자동 갱신. 변경이 영향을 미치는 하위 문서까지 전파 |

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **대상 문서 로드** -- engine-doc으로 지정 문서 읽기
3. **변경 사항 수집** -- 사용자와 대화하여 수정 내용 확정
4. **문서 갱신** -- `.md` + `.json` 동시 갱신
5. **영향 분석** (--cascade) -- engine-dep으로 의존 문서 파악
   - 예: SRS 변경 → ERD, API, Screen, TC 영향 분석
6. **의존 문서 갱신** (--cascade) -- 영향받는 문서 자동 수정
7. **일관성 검증** -- 갱신된 전체 문서 정합성 확인
8. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-doc | 문서 읽기/쓰기 |
| engine-dep | 의존성 분석 및 cascade 전파 |

## 에이전트 시퀀스

```
orchestrator → planner (문서 수정) 또는 builder (코드 관련 수정)
```

## Cascade 전파 규칙

| 변경 문서 | 영향 범위 |
|-----------|-----------|
| SRS (FR/US/FT) | ERD, API, Screen, TC |
| IA | Screen, Screen-Flow |
| ERD | API, BE 코드 |
| API | FE/BE 코드, TC |
| Screen | FE 코드, TC |

## 규칙

- `--cascade` 없이 수정 시 영향 범위만 표시하고 갱신하지 않음
- cascade 갱신 시 각 문서의 변경 내역을 변경 로그에 기록
- 문서 상태(Status)가 Approved에서 Draft로 자동 전환

## 사용 예시

```
/u-update my-app srs --cascade
/u-update my-app erd
/u-update common api
```
