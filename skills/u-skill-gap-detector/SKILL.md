---
name: u-skill-gap-detector
description: |
  설계-구현 Gap 분석을 수행한다. SRS/ERD/API/Screen 설계 vs 실제 코드 비교, Match Rate 산출.
  Triggers: /u-skill-gap-detector, 갭 분석, gap analysis
user-invocable: true
argument-hint: "[args]"
model: sonnet
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
  - ${PLUGIN_ROOT}/.u-maker/u-ssot.config.json
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
agents:
  - u-maker:u-agent-ra
  - u-maker:u-agent-qa
---

# Gap Detector

> 설계 문서와 구현 코드 사이의 Gap을 자동 분석한다.

## Analysis Targets

| Design Document | Comparison Target | Check Items |
|----------------|-------------------|-------------|
| {app}/1_SRS_RA.md | 구현 코드 | 모든 FT 구현 여부 |
| common/2_ERD_SA.md | DB Schema/ORM | Entity, Relationship 일치 |
| {app}/2_API_SA.md | API Route | Endpoint, 스키마 일치 |
| {app}/2_Screen_UX.md | 페이지/컴포넌트 | 화면 구현, 인터랙션 |

## Flow

1. u-agent-ra: 모든 앱의 SSoT 설계 문서 수집
2. u-agent-ra: 구현 코드 파일 스캔
3. u-agent-qa: 설계 항목별 구현 매칭 검사
4. Match Rate 산출: (구현 항목 / 전체 설계 항목) x 100
5. Gap 리포트 생성 → .u-maker/docs/{app}/04-check/

## Rules

- Match Rate >= 90%: PASS
- Match Rate < 90%: FAIL → ACT Phase에서 Gap 항목을 백로그로 전환
- Post-Execution Summary Box 출력 필수
