---
name: u-agent-dv-be
description: |
  Backend 개발을 실행한다. API Routes + Prisma/Drizzle ORM 기반. u-agent-dv-be 에이전트가 담당한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-agent-dv-be, 백엔드, backend, API 구현, be 개발, api routes, prisma, drizzle, orm, 서버 개발, server side, 데이터베이스 구현, db 구현, 서버리스 함수
model: sonnet
user-invocable: true
argument-hint: "[app]"
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
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
  - ${PLUGIN_ROOT}/_refer/tech-stack-rules.md
agents:
  - u-maker:u-agent-dv-be
---

# u-agent-dv-be

## Purpose

`u-agent-dv-be` 에이전트를 호출하여 Backend 개발을 실행한다.
API Routes + Prisma/Drizzle ORM 기반으로 서버 로직, DB 스키마, 마이그레이션 코드를 구현한다.

## Scope

- Next.js API Routes 엔드포인트 구현 (또는 별도 서버 앱)
- Prisma / Drizzle ORM 스키마 정의 및 마이그레이션
- 비즈니스 로직 서비스 레이어 작성
- API Contract(`2_APIContract_SA.md`)를 준수하는 요청/응답 처리
- 인증/인가, 미들웨어 구현
- 코드 문서 (`3_Code_DV.md`) 갱신

## Flow

1. 앱 컨텍스트를 결정한다 (단일 앱이면 자동 선택, 복수 앱이면 사용자 확인).
2. `.u-maker/u-maker.config.json`에서 tech stack, DB 종류, 앱 경로를 확인한다.
3. API Contract(`2_APIContract_SA.md`)와 ERD(`2_ERD_SA.md`)를 읽는다.
4. 구현 대상 FT(Feature) 목록을 확인하고 코드를 작성한다.
5. `3_Code_DV.md`를 갱신한다.
6. 동명의 `.json` 파일을 동일 경로에 함께 저장한다.
7. Post-Execution Summary Box를 출력한다.

## Output

- 소스 코드 파일 (api routes, services, schema 등)
- `.u-maker/docs/{app}/03-dev/3_Code_DV.md` + `.json`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## When NOT to use

- UI 컴포넌트 / 페이지 구현 → `/u-agent-dv-fe` 사용
- 테스트 작성 및 실행 → `/u-agent-qa` 사용
- ERD / API Contract 문서 설계 → `/u-agent-sa` 사용

## Rules

- tech-stack-rules.md에 정의된 기술 스택 이외 라이브러리 도입 금지
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
