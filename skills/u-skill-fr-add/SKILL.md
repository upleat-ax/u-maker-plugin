---
name: u-skill-fr-add
description: |
  새로운 기능 요구사항(FR)을 추가한다. {app}/01-plan/1_SRS_RA.md에 FR 항목과 상세 블록을 생성하고 Change Log를 갱신한다.
  Optional [app] argument for multi-app projects (e.g., `/u-skill-fr-add web`).
  Triggers: /u-skill-fr-add, 기능요구사항 추가, FR 추가, functional requirement add, new FR
user-invocable: true
argument-hint: "[web] [desc]"
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
  - u-maker:u-agent-sa
---

# Functional Requirement Add

> 새로운 FR을 1_SRS_RA.md의 Section 3에 추가한다.

## Syntax

/u-skill-fr-add [app] <description>

## Flow

1. 1_SRS_RA.md 존재 확인
2. 기존 FR-ID 최대값 → 다음 FR-ID 채번 (10단위 올림)
3. 항목 정보 추출
4. FR 테이블에 행 추가
5. FR Details 블록 추가
6. Change Log 갱신

## Input Fields

| Field | Required | Default |
|-------|----------|---------|
| Feature | Y | - |
| Description | Y | - |
| Priority | N | Should |
| US Mapping | N | TBD (Technical FR은 -) |
| Input/Output/Business Rule/Exception | N | {{TODO}} |

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app | Auto-select |
| Multiple apps + argument | Use specified app |
| Multiple apps + no argument | AskUserQuestion |

## Rules

- u-agent-sa 에이전트가 담당
- FR-ID: 4자리 10단위 채번. 도메인 그룹: AUTH 0010~0099, CORE 0110~0199, ADMIN 0210~0299
- Implemented 상태는 항상 [ ] Not Started로 생성
- Version은 Minor 증가
- Post-Execution Summary Box 출력 필수
