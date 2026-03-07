---
name: u-agent-ux
description: |
  Agent UX(UX Designer)에게 직접 작업을 요청한다. IA, 화면 설계, 디자인 시스템, 와이어프레임 등.
  Triggers: /u-agent-ux, UX에게, 디자이너에게
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
  - ${PLUGIN_ROOT}/.u-maker/u-ssot.config.json
agents:
  - u-maker:u-agent-ux
---

# u-agent-ux

`u-agent-ux` 에이전트를 호출하여 사용자가 요청한 작업을 수행한다.

## Scope

- 정보 구조도 (IA) 작성
- 화면 상세 설계
- 화면 흐름도 (ScreenFlow)
- 디자인 시스템, 디자인 토큰, UI 컴포넌트
- 와이어프레임

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
