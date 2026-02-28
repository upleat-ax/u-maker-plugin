---
document: "4QA_Report"
title: "{{PROJECT_NAME}} QA Report"
owner: "u-QA-T"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - "u-docs/04-check/4QA_Case.md"
  - "u-docs/05-act/5ACT_Backlog.md"
  - "u-docs/01-plan/1M_Index.md"
external_links: []
---

# {{PROJECT_NAME}} QA Report

## 1. Background

### 1.1 Purpose

{{QA 리포트 문서의 목적. 테스트 실행 결과를 기록하고 결함을 분석한다.}}

### 1.2 Test Execution Summary

| Item | Value |
|------|-------|
| Iteration | {{ITERATION}} |
| Test Date | {{DATE}} |
| Tester | u-QA-T |
| Environment | Local / CI |
| Build Version | {{BUILD_VERSION}} |

---

## 2. Test Results

### 2.1 Execution Summary

| Metric | Value |
|--------|-------|
| Total Test Cases | {{TOTAL}} |
| Passed | {{PASS}} |
| Failed | {{FAIL}} |
| Skipped | {{SKIP}} |
| Pass Rate | {{PASS_RATE}}% |

```mermaid
pie title Test Results
    "Pass" : {{PASS}}
    "Fail" : {{FAIL}}
    "Skip" : {{SKIP}}
```

### 2.2 Results by FR

| FR-ID | Feature | Total | Pass | Fail | Skip | Status |
|-------|---------|-------|------|------|------|--------|
| FR-001 | {{기능명}} | 2 | 1 | 1 | 0 | Partial |
| FR-002 | {{기능명}} | 1 | 1 | 0 | 0 | Pass |
| FR-003 | {{기능명}} | 1 | 0 | 0 | 1 | Skip |

---

## 3. Actual vs Expected

| TC-ID | FR | Expected | Actual | Result | Evidence |
|-------|-----|----------|--------|--------|----------|
| TC-001 | FR-001 | {{기대 결과}} | {{실제 결과}} | Pass | [Log](u-docs/assets/tc-001.log) |
| TC-002 | FR-001 | {{기대 결과}} | {{실제 결과}} | Fail | [Screenshot](u-docs/assets/tc-002.png) |
| TC-003 | FR-002 | {{기대 결과}} | {{실제 결과}} | Pass | [Log](u-docs/assets/tc-003.log) |

---

## 4. Defect Report

### 4.1 Defect Summary

| Severity | Count |
|----------|-------|
| Critical | {{COUNT}} |
| Major | {{COUNT}} |
| Minor | {{COUNT}} |
| Trivial | {{COUNT}} |
| **Total** | **{{TOTAL}}** |

```mermaid
pie title Defects by Severity
    "Critical" : {{CRITICAL}}
    "Major" : {{MAJOR}}
    "Minor" : {{MINOR}}
    "Trivial" : {{TRIVIAL}}
```

### 4.2 Defect Details

#### DEF-001: {{결함 제목}}

| Field | Value |
|-------|-------|
| **DEF-ID** | DEF-001 |
| **Severity** | Critical / Major / Minor / Trivial |
| **TC-ID** | TC-002 |
| **FR-ID** | FR-001 |
| **Status** | Open |
| **Found Date** | {{DATE}} |
| **Found By** | u-QA-T |

**Description**: {{결함 상세 설명}}

**Steps to Reproduce**:
1. {{재현 단계 1}}
2. {{재현 단계 2}}

**Expected**: {{기대 결과}}

**Actual**: {{실제 결과}}

**Evidence**: [Screenshot](u-docs/assets/def-001.png)

**Root Cause**: {{원인 분석 (u-QA-N이 작성)}}

**Fix Suggestion**: {{수정 제안}}

---

## 5. Evidence

| TC-ID | Evidence Type | Path | Status |
|-------|-------------|------|--------|
| TC-001 | API Response Log | `u-docs/assets/tc-001.log` | Collected |
| TC-002 | Error Screenshot | `u-docs/assets/tc-002.png` | Collected |

---

## 6. Test Conditions Verification

| # | Condition | Status | Notes |
|---|-----------|--------|-------|
| PRE-001 | 빌드 성공 | Pass | `bun run build` OK |
| PRE-002 | DB 초기화 | Pass | Seed data loaded |
| PRE-003 | 환경 변수 | Pass | `.env.test` configured |

---

## 7. Exit Criteria Check

| # | Criteria | Status | Value |
|---|---------|--------|-------|
| 1 | All backlog items Done | {{PASS/FAIL}} | {{open count}} open |
| 2 | No Critical/Major defects | {{PASS/FAIL}} | {{count}} remaining |
| 3 | All FR implemented | {{PASS/FAIL}} | {{count}} remaining |
| 4 | Build success | {{PASS/FAIL}} | {{result}} |
| **Overall** | | **{{PASS/FAIL}}** | |

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-QA-T | Initial draft |
