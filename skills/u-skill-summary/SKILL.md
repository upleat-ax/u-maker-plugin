---
name: u-skill-summary
description: |
  프로젝트 개요와 개발 상태를 콘솔에 요약 출력한다 (파일 생성 없음).
  Triggers: /u-skill-summary, 요약, 프로젝트 요약, project summary
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
agents:
  - u-maker:u-agent-ra
---

# Project Summary

> 프로젝트 개요와 개발 상태를 콘솔에 요약 출력한다.

## Flow

1. .u-maker/u-ssot.config.json에서 프로젝트 메타정보 수집
2. 1_Roadmap_PM.md에서 프로젝트 목표, 마일스톤 추출
3. 1_SRS_RA.md에서 FT 구현 현황 추출
4. 1_Index_PM.md에서 문서 상태 수집
5. 현재 Iteration, Phase, Loop 상태 확인
6. 콘솔에 요약 출력

## Rules

- u-agent-ra 에이전트가 담당
- 존재하지 않는 문서는 - 또는 N/A로 표시
- Post-Execution Summary Box 출력 필수
