---
name: u-skill-build
description: |
  프로젝트 빌드를 실행한다. bun run build 실행 및 결과를 보고한다.
  Triggers: /u-skill-build, 빌드, build, build project, 프로젝트 빌드, 빌드 실행, run build, 컴파일, compile, 빌드 확인, build check, 배포 빌드, production build
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

# u-skill-build

## Purpose

프로젝트 빌드를 실행하고 결과를 보고한다. 배포 전 빌드 성공 여부와 오류를 확인한다.

## Scope

- `bun run build` 명령 실행
- 빌드 성공/실패 여부 확인
- 오류 발생 시 원인 분석 및 수정 방안 제시
- 빌드 경고(warning) 목록 정리

## Flow

1. `.u-maker/u-maker.config.json`에서 앱 컨텍스트와 빌드 스크립트를 확인한다.
2. 프로젝트 루트(또는 지정 앱 경로)에서 `bun run build`를 실행한다.
3. 빌드 출력 로그를 분석한다.
4. 성공 시 빌드 산출물 경로와 크기 정보를 요약한다.
5. 실패 시 오류 메시지를 분석하고 원인과 해결 방안을 제시한다.
6. Post-Execution Summary Box를 출력한다.

## Output

- 빌드 결과 요약 (성공/실패, 경고 수, 산출물 크기)
- 실패 시 오류 원인 분석 및 수정 제안

## Rules

- 멀티앱 프로젝트에서 앱을 특정하지 않은 경우 AskUserQuestion으로 앱 선택 요청
- 빌드 오류를 자동으로 수정할 경우 변경된 파일 목록을 반드시 보고
- Post-Execution Summary Box 출력 필수
