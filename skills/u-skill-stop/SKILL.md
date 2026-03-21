---
name: u-skill-stop
description: |
  실행 중인 PDCA 루프를 중단한다. 현재 Phase와 상태를 저장한다.
  Triggers: /u-skill-stop, 루프 중단, stop loop, stop, 중단, 정지, pause, 일시 정지, 루프 정지, pdca 중단, loop pause, 작업 중단, 루프 멈춤
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
agents:
  - u-agent-ra: u-maker:u-agent-ra
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
---

# u-skill-stop

## Purpose

실행 중인 PDCA 루프를 안전하게 중단한다. 현재 Phase와 진행 상태를 저장하여 나중에 재개할 수 있도록 한다.

## Scope

- `u-maker.config.json`의 `loopStatus` 필드 갱신
- 현재 실행 중인 Phase와 세부 단계 상태 저장
- 중단 시점 메모(사용자 입력) 기록

## Flow

1. 현재 루프 상태를 `.u-maker/u-maker.config.json`에서 읽는다.
2. 사용자에게 중단 사유 또는 메모를 선택적으로 입력받는다(AskUserQuestion, 스킵 가능).
3. `loopStatus`를 `PAUSED`로 변경하고 현재 Phase, 단계, 타임스탬프를 기록한다.
4. 변경된 `u-maker.config.json`을 저장한다.
5. 중단 상태 요약을 출력한다 (중단 Phase, 저장된 진행 상태, 재개 방법 안내).
6. Post-Execution Summary Box를 출력한다.

## Output

- `.u-maker/u-maker.config.json` — `loopStatus: "PAUSED"` 갱신

## Resume

중단된 루프를 재개하려면 `/u-skill-loop-from` 또는 `/u-skill-resume` 명령을 사용한다.

## Rules

- 루프가 실행 중이 아닌 경우(IDLE/PAUSED)에도 오류 없이 현재 상태를 보고
- `u-maker.config.json` 외 산출물 문서는 수정하지 않음
- Post-Execution Summary Box 출력 필수
