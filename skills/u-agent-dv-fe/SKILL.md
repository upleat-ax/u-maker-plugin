---
name: u-agent-dv-fe
description: |
  Frontend 개발을 실행한다. Next.js App Router + react-query 기반. u-agent-dv-fe 에이전트가 담당한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-agent-dv-fe, 프론트엔드, frontend, 화면 구현, fe 개발, next.js, react, 컴포넌트 구현, component, UI 개발, ui implementation, 클라이언트 개발, client side
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
  - u-maker:u-agent-dv-fe
---

# u-agent-dv-fe

## Purpose

`u-agent-dv-fe` 에이전트를 호출하여 Frontend 개발을 실행한다.
Next.js App Router + react-query 기반으로 화면 컴포넌트, 페이지, 상태 관리 코드를 구현한다.

## Scope

- Next.js App Router 페이지 및 레이아웃 구현
- React 컴포넌트 작성 (Client/Server Component 구분)
- react-query를 활용한 서버 상태 관리
- Tailwind CSS 유틸리티 클래스 기반 스타일링
- Storybook Story 파일 작성 (컴포넌트 단위)
- 코드 문서 (`3_Code_DV.md`) 갱신

## Flow

1. 앱 컨텍스트를 결정한다 (단일 앱이면 자동 선택, 복수 앱이면 사용자 확인).
2. `.u-maker/u-maker.config.json`에서 tech stack과 앱 경로를 확인한다.
3. 관련 화면 설계 문서(`2_Screen_UX.md`)와 API Contract를 읽는다.
4. 구현 대상 FT(Feature) 목록을 확인하고 코드를 작성한다.
5. `3_Code_DV.md`를 갱신한다.
6. 동명의 `.json` 파일을 동일 경로에 함께 저장한다.
7. Post-Execution Summary Box를 출력한다.

## Output

- 소스 코드 파일 (pages, components, hooks 등)
- `.u-maker/docs/{app}/03-dev/3_Code_DV.md` + `.json`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## When NOT to use

- API Route / DB 스키마 구현 → `/u-agent-dv-be` 사용
- 테스트 작성 및 실행 → `/u-agent-qa` 사용
- 화면 설계 문서 작성 → `/u-agent-ux` 사용

## Rules

- tech-stack-rules.md에 정의된 기술 스택 이외 라이브러리 도입 금지
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
