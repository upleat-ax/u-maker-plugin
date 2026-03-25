---
name: u-agent-ra
description: |
  Agent RA(Requirements Analyst)에게 직접 작업을 요청한다. 프로젝트 기획, 문서 관리, SSoT 검증, 백로그 관리 등.
  Triggers: /u-agent-ra, RA에게, 요구사항 분석, requirements analyst, 기획, 문서 검증, ssot 검증, 백로그 관리, backlog, 마일스톤, milestone, 이터레이션, iteration, 모순 검수
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

## Purpose

`u-agent-ra` 에이전트를 호출하여 사용자가 요청한 RA(Requirements Analyst) 작업을 수행한다.
프로젝트 기획 관리, SSoT 문서 무결성 검증, 백로그 관리, 이터레이션 로그 기록을 담당한다.

## Scope

- 문제/솔루션 정의 — `1_ProblemSolution_RA.md` 작성
- 프로젝트 기획/관리 — 로드맵, 마일스톤, 이터레이션 계획
- 문서 인덱스 관리 — `1_Index_PM.md` 최신화
- SSoT 검증 — 헤더 누락, 추적성 깨짐, 구조 위반 탐지
- 모순 검수 — 문서 간 상충 내용 탐지 및 보고
- 백로그 관리 — 미완료 항목 추적, 우선순위 조정
- 이터레이션 로그 (`5_IterationLog_RA.md`) — 완료/미완료 항목 기록

## Flow

1. 사용자 요청을 분석하여 수행할 RA 작업 유형을 결정한다.
2. `.u-maker/u-maker.config.json`에서 현재 이터레이션 번호와 프로젝트 컨텍스트를 읽는다.
3. 관련 SSoT 문서를 읽어 현재 상태를 파악한다.
4. 요청된 작업을 수행하고 문서를 생성하거나 갱신한다.
5. 동명의 `.json` 파일을 동일 경로에 함께 저장한다.
6. Post-Execution Summary Box를 출력한다.

## Output

- `.u-maker/docs/common/01-plan/1_ProblemSolution_RA.md` + `.json`
- `.u-maker/docs/common/01-plan/1_Common_RA.md` + `.json`
- `.u-maker/docs/common/05-act/5_IterationLog_RA.md` + `.json`

## When NOT to use

- SRS/ERD/API Contract 작성 → `/u-agent-sa` 사용
- 화면 설계 → `/u-agent-ux` 사용
- 코드 구현 → `/u-agent-dv-fe` 또는 `/u-agent-dv-be` 사용

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
