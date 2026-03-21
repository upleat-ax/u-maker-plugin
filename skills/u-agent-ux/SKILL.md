---
name: u-agent-ux
description: |
  Agent UX(UX Designer)에게 직접 작업을 요청한다. IA, 화면 설계, 디자인 시스템, 와이어프레임 등.
  Triggers: /u-agent-ux, UX에게, 디자이너에게, ux designer, ia, 정보구조도, 화면 설계, screen design, 디자인 시스템, design system, 와이어프레임, wireframe, 화면 흐름도, screen flow, 디자인 토큰
model: sonnet
user-invocable: true
argument-hint: "[task description]"
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
agents:
  - u-maker:u-agent-ux
---

# u-agent-ux

## Purpose

`u-agent-ux` 에이전트를 호출하여 사용자가 요청한 UX(UX Designer) 작업을 수행한다.
정보 구조 설계부터 화면 상세 설계, 디자인 시스템 정의, 와이어프레임 작성까지 담당한다.

## Scope

- 정보 구조도 (IA) — 메뉴 트리, 네비게이션 구조, 사이트맵 정의
- 화면 상세 설계 (`2_Screen_UX.md`) — 화면별 레이아웃, 컴포넌트, 인터랙션 명세
- 화면 흐름도 (`2_ScreenFlow_UX.md`) — 사용자 시나리오 기반 화면 전환 흐름
- 디자인 시스템 (`2_UXGuide_UX.md`) — 디자인 토큰, 컬러/타이포그래피, UI 컴포넌트 가이드
- 와이어프레임 — SVG 인라인 또는 Figma 링크 기반 저충실도 레이아웃

## Flow

1. 사용자 요청을 분석하여 수행할 UX 작업 유형을 결정한다.
2. `.u-maker/u-maker.config.json`에서 앱 컨텍스트와 디자인 가이드를 확인한다.
3. 관련 상위 문서(SRS, 공통 요구사항)를 읽어 기능 범위를 파악한다.
4. 요청된 문서를 생성하거나 갱신한다.
5. 동명의 `.json` 파일을 동일 경로에 함께 저장한다.
6. Post-Execution Summary Box를 출력한다.

## Output

- `.u-maker/docs/{app}/02-design/2_Screen_UX.md` + `.json`
- `.u-maker/docs/{app}/02-design/2_ScreenFlow_UX.md` + `.json`
- `.u-maker/docs/common/02-design/2_UXGuide_UX.md` + `.json`

## When NOT to use

- Figma 파일 직접 조작 → `/u-skill-ux-figma` 사용
- 디자인 시스템 문서만 단독 생성 → `/u-skill-ux-designsystem` 사용
- API/ERD 설계 → `/u-agent-sa` 사용

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- SVG 다이어그램은 직선이 아닌 곡선 커넥터(curved connector) 사용
- Post-Execution Summary Box 출력 필수
