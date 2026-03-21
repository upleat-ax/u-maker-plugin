---
name: u-skill-archive
description: |
  현재 Iteration 문서를 아카이브한다. .u-maker/docs/iterations/iter-N/ 으로 복사한다.
  Triggers: /u-skill-archive, 아카이브, archive, archive iteration, 이터레이션 아카이브, iteration archive, 문서 보관, 버전 보관, snapshot, 스냅샷, 이터레이션 완료, iteration done
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
  u-agent-ra: u-maker:u-agent-ra
---

# u-skill-archive

## Purpose

`u-agent-ra` 에이전트를 호출하여 현재 Iteration의 산출물 스냅샷을 아카이브 경로에 보관한다.
이터레이션 완료 후 문서 이력을 보존하기 위해 실행한다.

## Scope

- 현재 이터레이션 번호 확인 (`u-maker.config.json`의 `currentIteration`)
- `.u-maker/docs/` 하위 모든 산출물을 대상 경로로 복사
- 아카이브 메타데이터 파일 생성

## Flow

1. `.u-maker/u-maker.config.json`에서 현재 이터레이션 번호(`currentIteration`)를 읽는다.
2. 아카이브 경로 `.u-maker/docs/iterations/iter-{N}/`를 결정한다.
3. 해당 경로가 이미 존재하면 사용자에게 덮어쓸지 확인(AskUserQuestion)한다.
4. `.u-maker/docs/` 하위 파일 전체를 아카이브 경로로 복사한다.
5. 아카이브 타임스탬프와 이터레이션 정보를 `archive-meta.json`으로 저장한다.
6. Post-Execution Summary Box를 출력한다.

## Output

- `.u-maker/docs/iterations/iter-{N}/` — 현재 docs 스냅샷
- `.u-maker/docs/iterations/iter-{N}/archive-meta.json` — 아카이브 메타데이터

## Rules

- 기존 아카이브 덮어쓰기 전 반드시 사용자 확인 필요
- 모든 `.md` 파일과 `.json` 파일을 함께 복사
- Post-Execution Summary Box 출력 필수
