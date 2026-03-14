---
name: u-skill-workflow
description: |
  주요 워크플로우 정의(Workflow) 문서를 생성하거나 갱신한다. u-agent-ra 에이전트가 담당한다.
  비즈니스 프로세스, 사용자 흐름, 시스템 간 연동 플로우를 정의한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-workflow, 워크플로우, workflow, 업무 흐름, 프로세스 정의, business process
model: sonnet
user-invocable: true
argument-hint: "[app]"
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
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
agents:
  - u-maker:u-agent-ra
---

# u-skill-workflow

`u-agent-ra` 에이전트를 호출하여 주요 워크플로우 정의 문서를 생성/갱신한다.

## Output

`.u-maker/docs/{app}/01-plan/1_Workflow_RA.md`

## Purpose

- 프로젝트의 핵심 비즈니스 프로세스와 사용자 흐름을 시각적으로 정의
- 시스템 간 연동, 상태 전이, 분기 조건을 명확히 문서화
- SRS의 FR/US/FT와 연결하여 구현 범위를 시각적으로 확인

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Document Structure

```markdown
# Workflow Definition — {Project Name}

## Meta
| Key | Value |
|-----|-------|
| Document ID | 1_Workflow_RA |
| Phase | PLAN |
| Owner | RA (Requirements Analyst) |
| Status | Draft / Reviewed / Approved |
| Last Updated | YYYY-MM-DD |

## Workflow Index

| ID | Workflow Name | Category | Actor(s) | Related FR | Status |
|----|--------------|----------|----------|------------|--------|
| WF-0010 | ... | Core / Support / Admin | USR-XXXX | FR-XXXX | Draft |

## WF-0010: {Workflow Name}

### Overview
| Key | Value |
|-----|-------|
| Category | Core / Support / Admin |
| Trigger | ... |
| Actor(s) | USR-XXXX |
| Precondition | ... |
| Postcondition | ... |
| Related FR | FR-XXXX, FR-XXXX |
| Related FT | FT-XXXX, FT-XXXX |

### Flow Diagram

(Mermaid flowchart 또는 인라인 SVG)

### Steps

| Step | Actor | Action | System Response | Branch Condition | Next Step |
|------|-------|--------|-----------------|------------------|-----------|
| 1 | ... | ... | ... | — | 2 |
| 2 | ... | ... | ... | 조건 A → 3, 조건 B → 4 | — |

### Exception Flows

| ID | Trigger Condition | Handling | Recovery |
|----|-------------------|----------|----------|
| EX-01 | ... | ... | ... |

## Change Log
| Date | Author | Description |
|------|--------|-------------|
```

## Rules

- 워크플로우 ID는 `WF-{4자리숫자}` 형식, 10단위 증분
- 각 워크플로우는 반드시 Mermaid flowchart 또는 인라인 SVG 다이어그램 포함
- SRS의 FR/US/FT와 추적성(traceability) 유지 — Related FR, Related FT 필수 기입
- Actor는 SRS의 USR-XXXX를 참조
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
