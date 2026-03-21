---
name: u-skill-storybook
description: |
  Storybook을 실행한다. 컴포넌트 문서화 및 시각적 확인.
  Triggers: /u-skill-storybook, 스토리북, storybook, storybook run, 스토리북 실행, 컴포넌트 문서화, component docs, 스토리북 시작, storybook start, UI 미리보기, component preview
model: sonnet
user-invocable: true
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
---

# u-skill-storybook

## Purpose

Storybook 개발 서버를 실행하여 UI 컴포넌트를 시각적으로 확인하고 문서화한다.

## Scope

- `bun run storybook` 명령 실행
- 실행 포트 및 브라우저 접속 URL 안내
- Storybook 빌드 오류 발생 시 원인 분석 및 보고

## Flow

1. `.u-maker/u-maker.config.json`에서 앱 컨텍스트와 패키지 매니저를 확인한다.
2. 프로젝트 루트(또는 지정 앱 경로)에서 `bun run storybook`을 실행한다.
3. 서버 시작 로그를 확인하고 접속 URL을 사용자에게 안내한다.
4. 오류 발생 시 오류 메시지를 분석하여 원인과 해결 방안을 보고한다.
5. Post-Execution Summary Box를 출력한다.

## Output

- Storybook 개발 서버 (기본 포트 6006)
- 터미널에 접속 URL 출력 (예: `http://localhost:6006`)

## Rules

- 멀티앱 프로젝트에서 앱을 특정하지 않은 경우 AskUserQuestion으로 앱 선택 요청
- Storybook이 설치되어 있지 않으면 설치 방법을 안내하고 중단
- Post-Execution Summary Box 출력 필수
