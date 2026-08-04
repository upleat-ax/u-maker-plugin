---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
App: {{app}}
Companion: test-results.json
---

# Test Results

> JSON companion: `test-results.json`

## 1. Execution Summary

| Metric | Value |
|--------|-------|
| Total TCs | {{total}} |
| Passed | {{passed}} |
| Failed | {{failed}} |
| Skipped | {{skipped}} |
| Pass Rate | {{passRate}}% |
| Execution Date | {{date}} |

## 2. Results by Type

| Type | Total | Passed | Failed | Pass Rate |
|------|-------|--------|--------|-----------|
| Unit | {{n}} | {{p}} | {{f}} | {{rate}}% |
| Integration | {{n}} | {{p}} | {{f}} | {{rate}}% |
| E2E | {{n}} | {{p}} | {{f}} | {{rate}}% |

## 3. Failed Test Details

### TC-{{id}}: {{title}}

| Field | Value |
|-------|-------|
| Status | FAIL |
| Error | {{errorMessage}} |
| Severity | Critical / Major / Minor |
| Root Cause | {{rootCause}} |
| Action | Fix / Retest / Skip |

## 4. Coverage Matrix

| FR | US | FT | TC | Result |
|----|----|----|-----|--------|
| FR-010 | US-010 | FT-010 | TC-010 | PASS/FAIL |
