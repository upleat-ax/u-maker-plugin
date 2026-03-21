---
name: u-skill-backlog
description: |
  백로그 Open 항목을 조회한다. 5_IterationLog_RA.md 내 미해결 항목을 표시한다.
  Triggers: /u-skill-backlog, 백로그, backlog, open items, 미완료 항목, 잔여 작업, remaining tasks, 백로그 조회, backlog list, 열린 항목, open backlog, 할 일 목록, todo list
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
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
agents:
  - u-maker:u-agent-ra
---

# u-skill-backlog

## Purpose

`u-agent-ra` 에이전트를 호출하여 현재 Open 상태인 백로그 항목을 조회하고 표시한다.
미완료 FT, 결함, 기술부채, 이월 항목을 우선순위와 함께 파악한다.

## Scope

- `5_IterationLog_RA.md`에서 Open/미완료 항목 추출
- FT(Feature), 결함(Bug), 기술부채(TechDebt) 유형별 분류
- 우선순위(High/Medium/Low) 기준 정렬

## Flow

1. `.u-maker/docs/common/05-act/5_IterationLog_RA.md`를 읽는다.
2. 상태가 Open/미완료인 항목을 필터링한다.
3. 유형(FT/Bug/TechDebt)과 우선순위 기준으로 분류·정렬한다.
4. 백로그 현황 표를 출력한다.
5. 전체 Open 항목 수와 유형별 집계를 요약한다.
6. Post-Execution Summary Box를 출력한다.

## Output (표시 형식)

- 유형별 Open 항목 테이블 (ID, 제목, 우선순위, 담당 에이전트, 이월 이터레이션)
- 집계 요약 (전체 Open: N건, FT: N건, Bug: N건, TechDebt: N건)

## Source

`.u-maker/docs/common/05-act/5_IterationLog_RA.md`

## Rules

- 조회 전용이므로 문서를 수정하지 않음
- 백로그 항목 추가는 `/u-skill-backlog-add` 사용
- Post-Execution Summary Box 출력 필수
