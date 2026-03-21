---
name: u-skill-index
description: |
  문서 인덱스(1_Index_PM.md)를 갱신한다.
  Triggers: /u-skill-index, 인덱스, index, index update, 인덱스 갱신, 문서 목록, document list, 인덱스 재생성, rebuild index, 목차 갱신, 문서 인덱스
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
agents:
  u-agent-pm: u-maker:u-agent-pm
---

# u-skill-index

## Purpose

`u-agent-pm` 에이전트를 호출하여 문서 인덱스(`1_Index_PM.md`)를 갱신한다.
`.u-maker/docs/` 하위의 모든 산출물을 스캔하여 최신 목록으로 업데이트한다.

## Scope

- `.u-maker/docs/` 전체 디렉토리 구조 스캔
- 각 앱별 문서 현황 파악 (존재 여부, 최종 수정일)
- 공통 문서(`common/`) + 앱별 문서 통합 목록 작성

## Flow

1. `.u-maker/docs/` 하위 모든 `.md` 파일을 Glob으로 수집한다.
2. 문서를 카테고리(01-plan, 02-design, 03-dev, 04-qa, 05-act)별로 분류한다.
3. 각 문서의 존재 여부와 최종 수정 타임스탬프를 확인한다.
4. `1_Index_PM.md`를 현재 상태로 갱신한다.
5. 동명의 `.json` 파일을 동일 경로에 함께 저장한다.
6. Post-Execution Summary Box를 출력한다.

## Output

- `.u-maker/docs/common/01-plan/1_Index_PM.md` + `.json`

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- 존재하지 않는 문서는 `미작성` 상태로 표시 (삭제하지 않음)
- Post-Execution Summary Box 출력 필수
