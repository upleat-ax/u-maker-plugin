---
name: u-coverage
description: |
  classified 데이터 대비 산출물 커버리지 리포트 생성.
  Triggers: /u-coverage, 커버리지, coverage, 누락, 갭 분석, gap, 추적 분석
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

# u-coverage -- 커버리지 리포트

> classified 입력 데이터 대비 산출물의 커버리지를 분석한다.

## 문법

```
/u-coverage [scope]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 전체)

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 범위 결정
2. **Classified 로드** -- `_classified/` 항목 전체 수집
3. **산출물 매핑** -- classified 항목 → SSoT 문서 항목 매핑
4. **커버리지 산정** -- 매핑된 비율 계산
5. **갭 식별** -- 매핑되지 않은 classified 항목 추출
6. **리포트 생성** -- 커버리지 요약 + 갭 목록

## 출력 형식

```
=== Coverage Report: my-app ===

Classified → SRS:
  FR Coverage:  85% (17/20)
  US Coverage:  78% (32/41)
  FT Coverage:  72% (58/81)

Classified → Design:
  ERD Coverage: 90% (18/20 entities)
  API Coverage: 85% (34/40 endpoints)

Gaps (미반영 항목):
  - [CLS-015] 알림 발송 규칙 → FR 미반영
  - [CLS-023] 다국어 지원 요건 → NR 미반영
  - [CLS-031] 모바일 레이아웃 → Screen 미반영
```

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-analyzer | classified↔산출물 매핑 분석 |

## 에이전트 시퀀스

```
orchestrator → planner (매핑 분석 + 리포트 생성)
```

## 규칙

- 읽기 전용 (문서 수정 없음)
- 갭 항목에는 반영 대상 문서 + 추천 액션 표시
- 커버리지 100% 미만 시 `/u-add` 또는 `/u-plan` 실행 안내

## 사용 예시

```
/u-coverage my-app
/u-coverage all
```
