---
name: u-build
description: |
  BUILD Phase. 명세 기반 FE + BE 코드 생성.
  Triggers: /u-build, 빌드, 구현, build, 코드 생성, code gen, FE, BE, 개발
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [-i] [--only fe|be|db]"
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

# u-build -- 코드 생성

> 설계 문서(ERD, API, Screen)를 기반으로 FE + BE 코드를 생성한다.

## 문법

```
/u-build [scope] [-i] [--only fe|be|db]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 자동 감지)

## Flags

| Flag | 설명 |
|------|------|
| `-i` | 대화형 모드. FT 단위로 사용자 확인 |
| `--only` | 특정 영역만 생성: `fe`, `be`, `db` |

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **선행 문서 확인** -- ERD, API, Screen 명세 존재 검증
3. **FT 목록 로드** -- SRS에서 구현 대상 FT 추출
4. **구현 계획 수립** -- FT 의존성 순서로 빌드 순서 결정
5. **DB 스키마 생성** (--only db) -- ERD 기반 마이그레이션 파일
6. **BE 코드 생성** (--only be) -- API Contract 기반 라우트/서비스
7. **FE 코드 생성** (--only fe) -- Screen + UX Guide 기반 컴포넌트/페이지
8. **코드 검증** -- 린트, 타입 체크, 빌드 테스트
9. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-workflow-runner | 빌드 오케스트레이션 |
| engine-code | 코드 생성/수정 |

## 에이전트 시퀀스

```
orchestrator → builder (코드 생성 실행)
```

## 규칙

- 설계 문서가 Approved 상태가 아니면 경고
- 기술 스택 규칙(`tech-stack-rules`)을 반드시 준수
- 생성된 코드는 FT ID로 추적 가능해야 함
- DB 마이그레이션은 기존 스키마와 호환성 검증 필수

## 사용 예시

```
/u-build my-app
/u-build my-app --only fe
/u-build -i --only be
```
