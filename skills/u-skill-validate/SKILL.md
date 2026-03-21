---
name: u-skill-validate
description: |
  SSoT 문서 무결성을 검증한다. 헤더 누락, 추적성 깨짐, 구조 위반을 탐지한다.
  Triggers: /u-skill-validate, 검증, 무결성, validate, ssot 검증, 문서 검증, document validate, 추적성 검증, traceability check, 구조 검증, structure check, 헤더 검증, 일관성 확인, consistency check
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
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
agents:
  u-agent-ra: u-maker:u-agent-ra
---

# u-skill-validate

## Purpose

`u-agent-ra` 에이전트를 호출하여 SSoT 문서 전체의 무결성을 검증한다.
헤더 누락, 추적성 깨짐(ID 참조 오류), 구조 위반, 문서 간 모순을 자동으로 탐지하고 보고한다.

## Scope

- 헤더 검증 — 필수 섹션(Purpose, Scope, Rules 등) 누락 여부 확인
- 추적성 검증 — USR→FR→US→FT 연결 끊김, 존재하지 않는 ID 참조 탐지
- 구조 위반 — 파일명 네이밍 규칙, 디렉토리 위치, `.json` 쌍 파일 누락 확인
- 모순 검수 — 동일 항목에 대해 문서 간 내용이 상충하는 경우 탐지
- 타임스탬프 검증 — 오래된 문서(갱신 필요) 탐지

## Flow

1. `.u-maker/docs/` 하위 모든 `.md` 파일을 Glob으로 수집한다.
2. `u-maker.config.json`의 `currentPhase`를 읽어 현재 PDCA Phase를 확인한다.
3. 각 문서의 필수 헤더/섹션 존재 여부를 검사한다.
4. FT/US/FR/USR ID의 상호 참조 일관성을 검증한다.
5. `.json` 쌍 파일 누락 여부를 확인한다.
6. **Phase-aware 검증**: 현재 Phase에 따라 적용할 규칙을 조정한다.
   - CHECK 이후 ~ ACT 이전: DEF→BL 변환 미완료는 WARNING (ACT에서 수행 예정)
   - ACT 이후: DEF→BL 변환 미완료는 ERROR
   - PLAN 이전: DESIGN/DO/CHECK 산출물 미존재는 검증 대상에서 제외
7. 위반 항목을 심각도(ERROR/WARNING/INFO)별로 분류하여 검증 리포트를 작성한다.
8. Post-Execution Summary Box를 출력한다.

## Output

- 검증 리포트 (터미널 출력) — 심각도별 위반 항목 목록
- ERROR 항목은 즉시 수정 권고, WARNING은 검토 권고로 표시

## Rules

- 검증은 읽기 전용 — 문서를 자동 수정하지 않음 (수정은 해당 스킬 사용)
- 모든 `.md` 파일 대상 검증 (아카이브 경로 `iterations/` 제외)
- Post-Execution Summary Box 출력 필수
