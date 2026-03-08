---
document: "5_LoopReport_PM_{{TIMESTAMP}}"
title: "{{PROJECT_NAME}} PDCA Loop Report ({{TIMESTAMP}})"
owner: "u-PM"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - ".u-maker/docs/common/01-plan/1_Index_PM.md"
  - ".u-maker/docs/{{APP_NAME}}/01-plan/1_SRS_RA.md"
  - ".u-maker/docs/{{APP_NAME}}/04-check/4_Case_QA.md"
  - ".u-maker/docs/{{APP_NAME}}/04-check/4_Report_QA.md"
  - ".u-maker/docs/common/05-act/5_IterationLog_RA.md"
external_links: []
---

# {{PROJECT_NAME}} PDCA Loop Report

## 1. Meta

| Key | Value |
|-----|-------|
| Timestamp | {{TIMESTAMP}} |
| Date | {{DATE}} |
| Iteration | {{ITERATION}} |
| Loop Result | {{PASS / FAIL}} |
| Total Iterations | {{TOTAL_ITERATIONS}} |
| Author | u-PM |

---

## 2. KPI Dashboard

| Metric | Value | Status |
|--------|-------|--------|
| Total User Stories | {{US_TOTAL}} | - |
| Total Features (FT) | {{FT_TOTAL}} | - |
| FT Implemented | {{FT_IMPL}} / {{FT_TOTAL}} | {{PASS/FAIL}} |
| Total FR | {{FR_TOTAL}} | - |
| Test Cases | {{TC_TOTAL}} | - |
| Test Pass Rate | {{PASS_RATE}}% | {{PASS/FAIL}} |
| Critical/Major Defects | {{DEFECT_COUNT}} | {{PASS/FAIL}} |
| Build Status | {{BUILD_STATUS}} | {{PASS/FAIL}} |
| Technical Debt Items | {{DEBT_COUNT}} | - |
| Final Match Rate (Gap) | {{MATCH_RATE}}% | {{PASS/FAIL}} |
| Total Gap Attempts | {{GAP_ATTEMPTS}} | - |

---

## 3. Requirements Summary

### 3.1 User Types (USR)

| USR-ID | Name | Description |
|--------|------|-------------|
| USR-{{NNNN}} | {{사용자 유형}} | {{설명}} |

### 3.2 User Stories (US)

| US-ID | As a... | I want to... | So that... | Priority | Status |
|-------|---------|-------------|------------|----------|--------|
| US-{{NNNN}} | {{역할}} | {{필요}} | {{효과}} | {{Must/Should/Could}} | {{Done/WIP/Todo}} |

### 3.3 Features (FT)

| FT-ID | Feature | US Mapping | Priority | Impl Status | Test Status |
|-------|---------|-----------|----------|-------------|-------------|
| FT-{{NNNN}} | {{기능명}} | US-{{NNNN}} | {{Must/Should/Could}} | {{Implemented/Partial/NotImpl}} | {{Pass/Fail/NoTest}} |

### 3.4 Functional Requirements (FR)

| FR-ID | Requirement | FT Mapping | Priority | Status |
|-------|-------------|-----------|----------|--------|
| FR-{{NNNN}} | {{요구사항}} | FT-{{NNNN}} | {{Must/Should/Could}} | {{Done/WIP/Todo}} |

---

## 4. Gap Analysis History

### 4.1 Match Rate Trend

| Iter | Gap Attempt | Match Rate | Gap FTs | Resolved | Result |
|------|------------|-----------|---------|----------|--------|
| 1 | 1 | {{N}}% | {{FT list}} | {{FT list}} | {{Pass/Retry}} |
| 1 | 2 | {{N}}% | {{FT list}} | {{FT list}} | {{Pass/Retry}} |
| 2 | 1 | {{N}}% | {{FT list}} | {{FT list}} | {{Pass/Retry}} |

### 4.2 Gap FT Detail

| FT-ID | Feature | First Detected | Attempts | Resolution | Final Status |
|-------|---------|---------------|----------|------------|-------------|
| FT-{{NNNN}} | {{기능명}} | Iter {{N}} Attempt {{N}} | {{N}} | {{내용}} | {{Resolved/Remaining}} |

### 4.3 Gap Resolution Summary

| Metric | Value |
|--------|-------|
| Initial Match Rate | {{N}}% |
| Final Match Rate | {{N}}% |
| Total Gap Attempts | {{N}} |
| Gap FTs Detected | {{N}} |
| Gap FTs Resolved | {{N}} |
| Gap FTs Remaining | {{N}} |

---

## 5. Implementation Summary

### 4.1 Code Statistics

| Metric | Value |
|--------|-------|
| Total Files Changed | {{FILE_COUNT}} |
| Lines Added | +{{LINES_ADD}} |
| Lines Removed | -{{LINES_DEL}} |
| Components Created | {{COMP_COUNT}} |
| API Endpoints | {{API_COUNT}} |
| DB Entities | {{ENTITY_COUNT}} |

### 4.2 Implementation by FT

| FT-ID | Feature | Frontend | Backend | DB | Status |
|-------|---------|----------|---------|----|--------|
| FT-{{NNNN}} | {{기능명}} | {{Done/WIP/NA}} | {{Done/WIP/NA}} | {{Done/WIP/NA}} | {{Complete/Partial}} |

### 4.3 Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | Next.js (App Router) | {{VER}} |
| State | react-query | {{VER}} |
| Backend | API Routes | - |
| ORM | Prisma / Drizzle | {{VER}} |
| Test | Vitest + Playwright | {{VER}} |

---

## 6. Test Summary

### 5.1 Test Execution

| Metric | Value |
|--------|-------|
| Total Test Cases | {{TC_TOTAL}} |
| Passed | {{TC_PASS}} |
| Failed | {{TC_FAIL}} |
| Skipped | {{TC_SKIP}} |
| Pass Rate | {{PASS_RATE}}% |

### 5.2 Test Results by FT

| FT-ID | Feature | Unit Total | Unit Pass | E2E Total | E2E Pass | Overall |
|-------|---------|-----------|----------|----------|---------|---------|
| FT-{{NNNN}} | {{기능명}} | {{N}} | {{N}} | {{N}} | {{N}} | {{Pass/Fail}} |

### 5.3 Failed Test Cases

| TC-ID | FT-ID | Type | Description | Expected | Actual | Severity |
|-------|-------|------|-------------|----------|--------|----------|
| TC-{{NNNN}} | FT-{{NNNN}} | {{Unit/E2E}} | {{설명}} | {{기대}} | {{실제}} | {{Critical/Major/Minor}} |

---

## 7. Defect Summary

### 6.1 Defects by Severity

| Severity | Count | Status |
|----------|-------|--------|
| Critical | {{N}} | {{Open/Fixed}} |
| Major | {{N}} | {{Open/Fixed}} |
| Minor | {{N}} | {{Open/Fixed}} |
| Trivial | {{N}} | {{Open/Fixed}} |
| **Total** | **{{N}}** | - |

### 6.2 Defect Details

| DEF-ID | Severity | FT-ID | Description | Root Cause | Fix Status |
|--------|----------|-------|-------------|------------|------------|
| DEF-{{NNNN}} | {{Severity}} | FT-{{NNNN}} | {{결함 설명}} | {{원인}} | {{Open/Fixed/Deferred}} |

---

## 8. Technical Debt

### 7.1 Debt Items

| # | Category | Description | Impact | Priority | Source |
|---|----------|-------------|--------|----------|--------|
| TD-{{NNNN}} | {{Code/Test/Doc/Infra}} | {{부채 설명}} | {{High/Medium/Low}} | {{Must/Should/Could}} | {{Iteration N / Code Review}} |

### 7.2 Debt by Category

| Category | Count | High | Medium | Low |
|----------|-------|------|--------|-----|
| Code Quality | {{N}} | {{N}} | {{N}} | {{N}} |
| Test Coverage | {{N}} | {{N}} | {{N}} | {{N}} |
| Documentation | {{N}} | {{N}} | {{N}} | {{N}} |
| Infrastructure | {{N}} | {{N}} | {{N}} | {{N}} |

---

## 9. Traceability Matrix

| US-ID | FT-ID | FR-ID | Screen | API | DB Entity | TC-ID | Status |
|-------|-------|-------|--------|-----|-----------|-------|--------|
| US-{{NNNN}} | FT-{{NNNN}} | FR-{{NNNN}} | {{화면}} | {{endpoint}} | {{entity}} | TC-{{NNNN}} | {{Pass/Fail}} |

---

## 10. Exit Criteria

| # | Criteria | Status | Value |
|---|---------|--------|-------|
| 1 | Critical/Major Defects = 0 | {{PASS/FAIL}} | {{count}} remaining |
| 2 | All FT Implemented | {{PASS/FAIL}} | {{count}} / {{total}} |
| 3 | Build Success | {{PASS/FAIL}} | {{result}} |
| **Overall** | | **{{PASS/FAIL}}** | |

---

## 11. Iteration History

| Iter | Phase Reached | Match Rate | Gap Attempts | Pass Rate | Defects | FT Impl | Result |
|------|--------------|-----------|-------------|-----------|---------|---------|--------|
| 1 | {{PHASE}} | {{N}}% | {{N}} | {{N}}% | {{N}} | {{N}}/{{T}} | {{Pass/Fail}} |
| 2 | {{PHASE}} | {{N}}% | {{N}} | {{N}}% | {{N}} | {{N}}/{{T}} | {{Pass/Fail}} |

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-PM | Loop report created |
