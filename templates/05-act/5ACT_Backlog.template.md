---
document: "5ACT_Backlog"
title: "{{PROJECT_NAME}} Backlog"
owner: "u-QA-N"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - "u-docs/04-check/4QA_Report.md"
  - "u-docs/05-act/5ACT_Iteration_Log.md"
  - "u-docs/01-plan/1M_Index.md"
external_links: []
---

# {{PROJECT_NAME}} Backlog

## 1. Background

### 1.1 Purpose

{{백로그 문서의 목적. CHECK Phase에서 발견된 결함 및 미구현 항목을 정리한다.}}

### 1.2 Summary

| Metric | Value |
|--------|-------|
| Total Items | {{TOTAL}} |
| Open | {{OPEN}} |
| In Progress | {{IN_PROGRESS}} |
| Done | {{DONE}} |
| Current Iteration | {{ITERATION}} |

---

## 2. Backlog Table

| BL-ID | Type | Origin | Description | Priority | Status | Iteration | Assignee |
|-------|------|--------|-------------|----------|--------|-----------|----------|
| BL-001 | Bug | CHECK | {{설명}} | Critical | Open | Iter {{N}} | {{agent}} |
| BL-002 | Enhancement | DESIGN | {{설명}} | Major | Open | Iter {{N}} | {{agent}} |
| BL-003 | Task | DEV | {{설명}} | Minor | Open | Iter {{N}} | {{agent}} |

---

## 3. Backlog by Priority

| Priority | Open | In Progress | Done | Total |
|----------|------|------------|------|-------|
| Critical | {{N}} | {{N}} | {{N}} | {{N}} |
| Major | {{N}} | {{N}} | {{N}} | {{N}} |
| Minor | {{N}} | {{N}} | {{N}} | {{N}} |
| Trivial | {{N}} | {{N}} | {{N}} | {{N}} |

---

## 4. Backlog by Origin

| Origin | Count | Description |
|--------|-------|-------------|
| CHECK | {{N}} | QA Phase에서 발견된 결함 |
| DESIGN | {{N}} | 설계 누락 또는 변경 필요 |
| DEV | {{N}} | 개발 과정에서 발견된 이슈 |
| PLAN | {{N}} | 요구사항 변경/추가 |

---

## 5. Backlog Details

### BL-001: {{제목}}

| Field | Value |
|-------|-------|
| **BL-ID** | BL-001 |
| **Type** | Bug |
| **Origin** | CHECK (DEF-001) |
| **Priority** | Critical |
| **Status** | Open |
| **Iteration** | Iter {{N}} |
| **Assignee** | {{agent}} |
| **Related FR** | FR-001 |
| **Related DEF** | DEF-001 |

**Description**: {{상세 설명}}

**Acceptance Criteria**: {{완료 조건}}

### BL-002: {{제목}}

| Field | Value |
|-------|-------|
| **BL-ID** | BL-002 |
| **Type** | Enhancement |
| **Origin** | DESIGN |
| **Priority** | Major |
| **Status** | Open |
| **Iteration** | Iter {{N}} |
| **Assignee** | {{agent}} |
| **Related FR** | FR-002 |

**Description**: {{상세 설명}}

**Acceptance Criteria**: {{완료 조건}}

---

## 6. Next Iteration Focus

다음 Iteration에서 처리할 항목 (Priority 기준 정렬):

| Order | BL-ID | Priority | Type | Description |
|-------|-------|----------|------|-------------|
| 1 | BL-001 | Critical | Bug | {{설명}} |
| 2 | BL-002 | Major | Enhancement | {{설명}} |
| 3 | BL-003 | Minor | Task | {{설명}} |

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-QA-N | Initial backlog from Iter {{N}} |
