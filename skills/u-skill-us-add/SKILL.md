---
name: u-skill-us-add
description: |
  새로운 유저 스토리를 추가한다. 1_SRS_RA.md의 User Stories 섹션에 US 항목을 생성하고 Change Log를 갱신한다.
  Args: `[description]` — 유저 스토리 설명 (생략 시 대화형 입력)
  Triggers: /u-skill-us-add, 유저스토리 추가, user story add, US 추가, new user story, 스토리 추가, add user story, US 신규, 사용자 스토리 추가, 요구사항 추가, append user story, new US
user-invocable: true
argument-hint: "[description]"
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
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  - u-maker:u-agent-sa
---

# User Story Add

> 새로운 유저 스토리를 1_SRS_RA.md의 User Stories 섹션에 추가한다.

## Syntax

/u-skill-us-add <description>

## Flow

1. 1_SRS_RA.md 존재 확인 (없으면 템플릿에서 자동 생성)
2. 기존 US-ID 최대값 → 다음 US-ID 채번 (10단위 올림)
3. 항목 정보 추출: As a [role], I want to [need], So that [benefit]
4. User Stories 테이블에 행 추가
5. Change Log 갱신

## Input Fields

| Field | Required | Default | Values |
|-------|----------|---------|--------|
| As a... | Y | - | 역할 |
| I want to... | Y | - | 사용자 필요/의도 |
| So that... | Y | - | 기대 효과 |
| Priority | N | Should | Must, Should, Could, Won't |
| FR Mapping | Y | - | FR-NNNN |
| FT Mapping | N | TBD | FT-NNNN |

## Rules

- u-agent-sa 에이전트가 담당
- US-ID는 4자리 10단위 자동 채번
- FR Mapping은 필수
- FT Mapping 기본값은 TBD
- Version은 Minor 증가
- Post-Execution Summary Box 출력 필수
