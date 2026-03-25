---
name: u-agent-pm
description: |
  Agent PM(Product Manager)에게 직접 작업을 요청한다.
  로드맵, 인덱스, 회고, 데일리 리포트 문서 작성/갱신을 담당한다.
  Triggers: /u-agent-pm, PM에게, 프로덕트 매니저에게, daily report, 데일리 리포트, roadmap, 로드맵, 회고, retrospective, 인덱스 갱신, report 작성, 일일 보고
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
  - u-maker:u-agent-pm
---

# u-agent-pm

## Purpose

`u-agent-pm` 에이전트를 호출하여 사용자가 요청한 PM(Product Manager) 작업을 수행한다.
로드맵 관리, 데일리 리포트 작성, 회고, 문서 인덱스 갱신을 담당한다.

## Scope

- 프로젝트 로드맵 (`1_Roadmap_PM.md`) — 마일스톤, 릴리즈 계획 수립 및 갱신
- 글로벌 정책 (`1_GlobalPolicies_PM.md`) — 서비스/개발/디자인 정책 정의
- 문서 인덱스 (`1_Index_PM.md`) — 전체 산출물 목록 최신화
- 회고 (`5_Retrospective_PM.md`) — 이터레이션 완료 후 Keep/Problem/Try 기록
- 데일리 리포트 (`5_DailyReport_PM_yyyymmddhhmm.md`) — 일일 진척 요약

## Flow

1. 사용자 요청을 분석하여 수행할 PM 작업 유형을 결정한다.
2. `.u-maker/u-maker.config.json`에서 프로젝트 컨텍스트(이름, 앱 목록, 현재 이터레이션)를 읽는다.
3. 관련 기존 문서를 읽어 현재 상태를 파악한다.
4. 요청된 문서를 생성하거나 갱신한다.
5. 동명의 `.json` 파일을 동일 경로에 함께 저장한다.
6. Post-Execution Summary Box를 출력한다.

## Output

- `.u-maker/docs/common/01-plan/1_Roadmap_PM.md` + `.json`
- `.u-maker/docs/common/01-plan/1_GlobalPolicies_PM.md` + `.json`
- `.u-maker/docs/common/01-plan/1_Index_PM.md` + `.json`
- `.u-maker/docs/common/05-act/5_Retrospective_PM.md` + `.json`
- `.u-maker/docs/common/05-act/5_DailyReport_PM_yyyymmddhhmm.md` + `.json` + `.html`

## When NOT to use

- 요구사항 분석이나 SRS 작성 → `/u-agent-ra` 또는 `/u-agent-sa` 사용
- 테스트 실행 → `/u-agent-qa` 사용
- 코드 구현 → `/u-agent-dv-fe` 또는 `/u-agent-dv-be` 사용

## Rules

- 데일리 리포트 파일명은 반드시 `yyyymmddhhmm` 12자리 타임스탬프를 포함
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- 데일리 리포트는 `.md` + `.json` + `.html` 3종 동시 생성
- Post-Execution Summary Box 출력 필수
