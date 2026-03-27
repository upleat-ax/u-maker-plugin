---
name: u-add
description: |
  SSoT 항목 추가. FR, NR, US, FT, Screen, TC 등 개별 항목을 문서에 추가.
  Triggers: /u-add, 추가, add, 항목 추가, FR 추가, US 추가, FT 추가, TC 추가, Screen 추가
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [type] \"title\""
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

# u-add -- 항목 추가

> SSoT 문서에 새로운 항목(FR, NR, US, FT, Screen, TC 등)을 추가한다.

## 문법

```
/u-add [scope] [type] "title"
```

- `scope`: 앱 이름 | `common` (생략 시 자동 감지)
- `type`: 추가할 항목 유형
- `title`: 항목 제목 (큰따옴표로 감싸기)

## 지원 타입

| Type | 대상 문서 | ID 패턴 | 설명 |
|------|-----------|---------|------|
| `fr` | SRS | FR-XXXX | 기능 요구사항 |
| `nr` | SRS | NR-XXXX | 비기능 요구사항 |
| `us` | SRS | US-XXXX | 유저 스토리 |
| `ft` | SRS | FT-XXXX | 기능 단위 (구현 추적 기본 단위) |
| `usr` | SRS | USR-XXXX | 사용자 유형 |
| `screen` | Screen | SCR-XXXX | 화면 |
| `tc` | TestCase | TC-XXXX | 테스트 케이스 |
| `api` | API | API-XXXX | API 엔드포인트 |

## 실행 흐름

1. **인자 파싱** -- scope, type, title 추출
2. **대상 문서 로드** -- engine-doc으로 해당 SSoT 문서 읽기
3. **ID 채번** -- 기존 최대 ID + 1로 신규 ID 할당
4. **항목 생성** -- 타입별 템플릿에 맞춰 항목 구성
5. **문서 갱신** -- `.md` + `.json` 동시 갱신
6. **의존성 업데이트** -- engine-dep으로 상위/하위 항목 연결
7. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-doc | 문서 읽기/쓰기 |
| engine-dep | 의존성 연결 갱신 |

## 에이전트 시퀀스

```
orchestrator → planner (항목 생성 + 의존성 연결)
```

## 규칙

- ID는 자동 채번 (수동 지정 불가)
- 추적 체계 준수: USR → FR → US → FT
- 중복 타이틀 경고 (동일 scope 내)
- 추가 후 관련 문서의 `.json`도 동시 갱신

## 사용 예시

```
/u-add my-app fr "사용자 로그인 기능"
/u-add my-app us "관리자가 대시보드에서 매출을 확인할 수 있다"
/u-add common ft "공통 인증 모듈"
/u-add tc "로그인 실패 시 에러 메시지 표시"
```
