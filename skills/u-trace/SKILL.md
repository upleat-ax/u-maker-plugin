---
name: u-trace
description: |
  raw → classified → docs 전체 추적 체인 조회.
  Triggers: /u-trace, 추적, trace, traceability, 연결 고리, 의존성 추적
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [id]"
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

# u-trace -- 추적 체인 조회

> 특정 항목 또는 전체의 추적 체인(raw → classified → SSoT docs)을 조회한다.

## 문법

```
/u-trace [scope] [id]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 자동 감지)
- `id`: 추적할 항목 ID (예: `FR-0001`, `FT-0012`, `US-0003`)
  - 생략 시 전체 추적 매트릭스 표시

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 범위 결정
2. **ID 파싱** -- 항목 유형 및 번호 식별
3. **상향 추적** -- 해당 ID의 상위 체인 탐색
   - FT → US → FR → USR → classified → raw
4. **하향 추적** -- 해당 ID의 하위 체인 탐색
   - FR → US → FT → Screen → TC → Code
5. **체인 출력** -- 트리 또는 테이블 형태로 표시

## 출력 형식

```
=== Trace: FT-0012 ===

상향 추적:
  raw/_input/요구사항.pdf (p.3)
    → CLS-007 "사용자 인증 요건"
      → FR-0003 "OAuth2 소셜 로그인"
        → US-0008 "사용자가 Google 계정으로 로그인할 수 있다"
          → FT-0012 "Google OAuth 콜백 처리" ← 현재

하향 추적:
  FT-0012 "Google OAuth 콜백 처리"
    → SCR-0005 "로그인 화면"
    → API-0011 "POST /auth/google/callback"
    → TC-0019 "Google 로그인 성공 시나리오"
    → TC-0020 "Google 로그인 실패 시나리오"
    → src/app/api/auth/google/callback/route.ts
```

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-dep | 의존성 그래프 탐색 |

## 에이전트 시퀀스

```
orchestrator (단독 실행 -- 읽기 전용)
```

## 규칙

- 읽기 전용 (문서 수정 없음)
- 끊어진 체인(broken link)은 `[BROKEN]` 태그로 표시
- 전체 매트릭스 조회 시 HTML 테이블로도 출력 가능

## 사용 예시

```
/u-trace my-app FT-0012
/u-trace my-app FR-0003
/u-trace all
```
