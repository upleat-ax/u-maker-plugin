---
name: u-agent-builder
description: |
  Builder 에이전트에게 직접 구현 작업을 요청한다. FE/BE 코드 생성, DB 마이그레이션 등.
  Triggers: /u-agent-builder, 빌더, builder, 구현, 코딩, 코드 생성, FE, BE, 개발
version: 2.0.0
user-invocable: true
argument-hint: "자유 형식 작업 요청"
model: opus
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
agents:
  u-agent-builder: u-maker:u-agent-builder
---

# u-agent-builder -- Builder 직접 호출

> Builder 에이전트에게 자유 형식으로 구현 작업을 직접 요청한다.

## 문법

```
/u-agent-builder [자유 형식 요청]
```

## 역할

Builder는 코드 구현을 담당하는 에이전트로서 다음 역할을 수행한다:

- **FE 코드 생성** -- Screen 명세 + UX Guide 기반 프론트엔드 구현
- **BE 코드 생성** -- API Contract + ERD 기반 백엔드 구현
- **DB 마이그레이션** -- ERD 기반 스키마 마이그레이션 생성
- **코드 수정** -- 결함 수정, 리팩토링, 기능 추가
- **빌드/린트** -- 코드 품질 검증, 타입 체크

## 실행 흐름

1. **요청 수신** -- 사용자의 구현 요청 분석
2. **명세 참조** -- 관련 설계 문서(ERD, API, Screen) 로드
3. **코드 생성/수정** -- 명세 기반 구현
4. **검증** -- 린트, 타입 체크, 빌드 테스트
5. **결과 보고** -- Post-Execution Summary 출력

## 적합한 요청 유형

- "FT-0012 Google OAuth 콜백을 구현해줘"
- "Screen SCR-0005 로그인 화면 컴포넌트를 만들어줘"
- "API-0011 엔드포인트 라우트를 생성해줘"
- "결함 BUG-003을 수정해줘"
- "users 테이블 마이그레이션을 생성해줘"

## 규칙

- 기술 스택 규칙 반드시 준수
- 생성 코드는 FT ID로 추적 가능해야 함
- 설계 문서 없이 임의 구현 금지 (명세 참조 필수)

## 사용 예시

```
/u-agent-builder FT-0012 Google OAuth 콜백 핸들러를 구현해줘
/u-agent-builder 로그인 페이지 컴포넌트를 Screen 명세대로 만들어줘
/u-agent-builder ERD 기반으로 Prisma 스키마를 생성해줘
```
