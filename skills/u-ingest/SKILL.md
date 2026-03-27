---
name: u-ingest
description: |
  외부 입력 데이터를 분석하여 정제/분류한다. _input/ raw data를 _classified/로 적재.
  Triggers: /u-ingest, 데이터 수집, 입력 정제, ingest, 분류, classify, raw data, 데이터 적재
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [--review] [--incremental]"
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

# u-ingest -- 입력 데이터 정제 적재

> `_input/` 디렉토리의 raw data를 분석하여 `_classified/`로 정제 적재한다.

## 문법

```
/u-ingest [scope] [--review] [--incremental]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 자동 감지)

## Flags

| Flag | 설명 |
|------|------|
| `--review` | 분석 결과를 사용자에게 리뷰 요청 후 적재 |
| `--incremental` | 신규분만 처리 (이미 분류된 항목 스킵) |

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **입력 스캔** -- `_input/` 하위 파일 목록 수집
3. **포맷 감지** -- 텍스트, 이미지, PDF, 스프레드시트 등 포맷 판별
4. **내용 분석** -- engine-analyzer로 핵심 정보 추출
   - 요구사항, 비즈니스 규칙, 제약조건, 용어, 사용자 유형 식별
5. **분류 태깅** -- 각 항목에 카테고리 태그 부여
   - `requirement`, `constraint`, `glossary`, `user-type`, `reference`, `misc`
6. **정제 적재** -- `_classified/` 디렉토리에 구조화된 형태로 저장
7. **리뷰** (--review) -- 분류 결과 요약 제시, 사용자 승인 대기
8. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-analyzer | 콘텐츠 분석 및 분류 |

## 에이전트 시퀀스

```
orchestrator → planner (분석 전략 수립 + 분류 실행)
```

## 규칙

- `_input/` 원본 파일은 수정하지 않음 (읽기 전용)
- `_classified/` 항목에는 출처(source) 파일 경로를 반드시 기록
- `--incremental` 시 이미 `_classified/`에 존재하는 항목은 스킵

## 사용 예시

```
/u-ingest my-app --review
/u-ingest --incremental
/u-ingest common
```
