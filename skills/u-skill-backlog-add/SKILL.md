---
name: u-skill-backlog-add
description: |
  새로운 백로그 항목을 추가한다. 5_IterationLog_RA.md에 항목을 생성하고 인덱스를 갱신한다.
  Triggers: /u-skill-backlog-add, 백로그 추가, backlog add, 항목 추가, new backlog
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
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
agents:
  - u-maker:u-agent-ra
---

# Backlog Add

> 새로운 백로그 항목을 5_IterationLog_RA.md의 Backlog 섹션에 추가한다.

## Syntax

/u-skill-backlog-add <description>

## Flow

1. 5_IterationLog_RA.md 존재 확인 (없으면 템플릿에서 자동 생성)
2. 기존 BL-ID 최대값 확인 → 다음 BL-ID 자동 채번 (10단위 올림)
3. 항목 정보 추출/입력
4. Backlog Table (Section 2)에 행 추가
5. Backlog Details (Section 6)에 상세 블록 추가
6. Summary (Section 1.2) 카운트 갱신 + 완료율 재계산
7. Backlog by Priority/Origin 갱신
8. Change Log 갱신

## Input Fields

| Field | Required | Default | Values |
|-------|----------|---------|--------|
| Description | Y | - | 자연어 설명 |
| Type | N | Task | Bug, Enhancement, Task |
| Priority | N | Minor | Critical, Major, Minor, Trivial |
| Origin | N | DEV | PLAN, DESIGN, DEV, CHECK |
| Est. Hours | N | TBD | 숫자 + h |
| Related Request | N | - | FR-NNNN, SC-NNNN, US-NNNN |
| Acceptance Criteria | N | - | Given-When-Then 체크리스트 (최소 1개 필수) |

## Auto-Assignment Rules

| Origin | Type / Keyword | Default Assignee |
|--------|---------------|-----------------|
| PLAN | - | u-agent-ra |
| DESIGN | - | u-agent-sa |
| DEV/CHECK | Bug (frontend: 화면, UI, 페이지, 스타일) | u-agent-dv-fe |
| DEV/CHECK | Bug (backend: API, DB, 서버, 인증) | u-agent-dv-be |
| DEV/CHECK | Bug (기타) | u-agent-dv-be |
| - | Enhancement (Screen/화면) | u-agent-ux |
| - | Enhancement (API/ERD) | u-agent-sa |
| - | Task | u-agent-ra |

## Rules

- u-agent-ra 에이전트가 담당
- BL-ID는 10단위 자동 채번 (4자리)
- Status는 항상 Open으로 생성
- Impl. Status는 항상 Not Implemented로 설정
- 완료율: Done / (Total - Cancelled) x 100
- Post-Execution Summary Box 출력 필수
