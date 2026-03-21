---
name: u-skill-history
description: |
  Iteration 이력을 조회한다. 5_IterationLog_RA.md 내용을 표시한다.
  Triggers: /u-skill-history, 이력, history, iteration history, 이터레이션 이력, 변경 이력, change log, 히스토리, 작업 이력, 이전 이터레이션, past iterations, 로그 조회
model: sonnet
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  u-agent-ra: u-maker:u-agent-ra
---

# u-skill-history

## Purpose

`u-agent-ra` 에이전트를 호출하여 이터레이션 이력(`5_IterationLog_RA.md`)을 조회하고 요약하여 표시한다.
완료된 이터레이션 목록, 주요 완료 항목, 미완료 이월 항목을 한눈에 파악한다.

## Scope

- `5_IterationLog_RA.md` 읽기 및 파싱
- 이터레이션별 완료/미완료 항목 집계
- 아카이브 디렉토리(`iterations/`) 존재 여부 확인

## Flow

1. `.u-maker/docs/common/05-act/5_IterationLog_RA.md`를 읽는다.
2. 이터레이션별 항목을 파싱하여 완료/미완료/이월 현황을 집계한다.
3. 아카이브 경로(`.u-maker/docs/iterations/`)가 있으면 각 이터레이션 스냅샷 존재 여부를 확인한다.
4. 이터레이션 이력 요약 표를 출력한다.
5. Post-Execution Summary Box를 출력한다.

## Output (표시 형식)

- 이터레이션 이력 요약 테이블 (이터레이션 번호, 기간, 완료 항목 수, 미완료 항목 수)
- 최근 이터레이션 상세 내역

## Source

`.u-maker/docs/common/05-act/5_IterationLog_RA.md`

## Rules

- 파일이 존재하지 않으면 이력 없음을 안내하고 `/u-skill-init` 실행을 권장
- 조회 전용이므로 문서를 수정하지 않음
- Post-Execution Summary Box 출력 필수
