---
document: "5_Retrospective_PM"
title: "{{PROJECT_NAME}} Retrospective"
owner: "u-RA"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - "u-docs/backlog.md"
  - "u-docs/shared/05-act/5_IterationLog_RA.md"
  - "u-docs/shared/01-plan/1_Index_PM.md"
external_links: []
---

# {{PROJECT_NAME}} Retrospective

## 1. Background

### 1.1 Purpose

{{회고 문서의 목적. 각 Iteration의 성과를 돌아보고 개선 사항을 도출한다.}}

### 1.2 Context

| Item | Value |
|------|-------|
| Iteration | {{ITERATION}} |
| Date | {{DATE}} |
| Phase Reached | {{PHASE}} |
| Result | {{RESULT}} |

---

## 2. Iteration {{N}} Retrospective

### 2.1 Good (잘한 점)

| # | Category | Description |
|---|----------|-------------|
| G-001 | Process | {{잘한 점}} |
| G-002 | Quality | {{잘한 점}} |
| G-003 | Collaboration | {{잘한 점}} |

### 2.2 Improve (개선할 점)

| # | Category | Description | Impact |
|---|----------|-------------|--------|
| I-001 | Process | {{개선할 점}} | High |
| I-002 | Quality | {{개선할 점}} | Medium |
| I-003 | Efficiency | {{개선할 점}} | Low |

### 2.3 Actions (실행 항목)

| # | Action | Owner | Target Iteration | Status |
|---|--------|-------|-----------------|--------|
| A-001 | {{실행 항목}} | {{담당}} | Iter {{N+1}} | Planned |
| A-002 | {{실행 항목}} | {{담당}} | Iter {{N+1}} | Planned |
| A-003 | {{실행 항목}} | {{담당}} | Iter {{N+1}} | Planned |

---

## 3. Improvement Cycle

```mermaid
flowchart LR
    IDENTIFY["Identify\nImprove Items"] --> PLAN_ACTION["Plan\nActions"]
    PLAN_ACTION --> EXECUTE["Execute\nin Next Iter"]
    EXECUTE --> MEASURE["Measure\nEffect"]
    MEASURE --> IDENTIFY
```

---

## 4. Retrospective History

### 3.1 Iteration 1

**Good**:
- {{잘한 점 요약}}

**Improve**:
- {{개선할 점 요약}}

**Actions Taken**:
- {{실행 결과}}

### 3.2 Iteration 2

**Good**:
- {{잘한 점 요약}}

**Improve**:
- {{개선할 점 요약}}

**Actions Taken**:
- {{실행 결과}}

---

## 5. Action Items Tracking

| A-ID | Action | Origin Iter | Target Iter | Owner | Status |
|------|--------|------------|------------|-------|--------|
| A-001 | {{실행 항목}} | Iter 1 | Iter 2 | {{담당}} | Done |
| A-002 | {{실행 항목}} | Iter 1 | Iter 2 | {{담당}} | In Progress |
| A-003 | {{실행 항목}} | Iter 2 | Iter 3 | {{담당}} | Planned |

---

## 6. Team Health

```mermaid
xychart-beta
    title "Team Health Trend"
    x-axis ["Iter 1", "Iter 2", "Iter 3"]
    y-axis "Score (1-5)" 0 --> 5
    line "Process" [3, 4, 4]
    line "Doc Quality" [2, 3, 4]
    line "Code Quality" [3, 3, 4]
    line "Test Coverage" [2, 3, 3]
    line "Collaboration" [4, 4, 5]
```

| Category | Iter 1 | Iter 2 | Iter 3 | Trend |
|----------|--------|--------|--------|-------|
| Process Adherence | {{1-5}} | {{1-5}} | {{1-5}} | {{up/down/same}} |
| Document Quality | {{1-5}} | {{1-5}} | {{1-5}} | {{up/down/same}} |
| Code Quality | {{1-5}} | {{1-5}} | {{1-5}} | {{up/down/same}} |
| Test Coverage | {{1-5}} | {{1-5}} | {{1-5}} | {{up/down/same}} |
| Collaboration | {{1-5}} | {{1-5}} | {{1-5}} | {{up/down/same}} |

---

## 7. Lessons Learned

| # | Lesson | Applied From |
|---|--------|-------------|
| L-001 | {{교훈}} | Iter {{N}} |
| L-002 | {{교훈}} | Iter {{N}} |

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-RA | Iteration {{N}} retrospective |
