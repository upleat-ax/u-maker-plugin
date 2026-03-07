---
name: u-agent-ra
description: |
  Agent RA(Requirements Analyst)에게 직접 작업을 요청한다. 프로젝트 기획, 문서 관리, SSoT 검증, 백로그 관리 등.
  Triggers: /u-agent-ra, RA에게, 요구사항 분석
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
  - u-maker:u-agent-ra
---

# u-agent-ra

`u-agent-ra` 에이전트를 호출하여 사용자가 요청한 작업을 수행한다.

## Scope

- 프로젝트 기획/관리 (로드맵, 마일스톤)
- 문서 인덱스 관리
- SSoT 검증, 모순 검수
- 백로그 관리, 이터레이션 로그
- 회고

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
