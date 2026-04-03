# Test Execution

This reference defines the execution protocol, result recording format, defect classification system, coverage matrix construction, pass rate calculation, and regression test selection strategy.

## 1. Execution Protocol

### 1.1 Execution Order

Tests execute in a deterministic order based on type and priority:

```
Phase 1: Unit Tests (all priorities)
  → Fastest feedback loop, catches logic errors early
  → If P1 unit tests fail → HALT, do not proceed

Phase 2: Integration Tests (all priorities)
  → Validates module interactions
  → If P1 integration tests fail → HALT, do not proceed

Phase 3: E2E Tests (P1 first, then P2, then P3)
  → Full user journey validation
  → P1 failures block; P2/P3 failures are recorded but do not block

Phase 4: Accessibility Tests
  → WCAG compliance verification
  → Failures recorded as defects; critical a11y issues block

Phase 5: Performance Tests
  → Benchmark against thresholds
  → Failures recorded; only critical regressions block

Phase 6: Security Tests
  → Vulnerability scan
  → Any security failure is treated as P1 blocker
```

### 1.2 Execution Environment

Before execution begins, verify the environment:

```markdown
**Environment Checklist:**
- [ ] Build succeeds without errors (`bun run build`)
- [ ] Database migrations applied (`bunx prisma migrate deploy`)
- [ ] Test database seeded (`bunx prisma db seed`)
- [ ] Environment variables loaded from `.env.test`
- [ ] External services mocked (no real API calls in tests)
- [ ] Port conflicts resolved (test server on unique port)
```

### 1.3 Execution Commands

| Type | Command | Config |
|------|---------|--------|
| Unit | `bun run test:unit` | `vitest.config.ts` with `include: ["**/*.test.ts"]` |
| Integration | `bun run test:integration` | `vitest.config.ts` with `include: ["**/*.integration.test.ts"]` |
| E2E | `bun run test:e2e` | `playwright.config.ts` |
| Accessibility | `bun run test:a11y` | `vitest.config.ts` with `include: ["**/*.a11y.test.ts"]` |
| Performance | `bun run test:perf` | `vitest.config.ts` with `include: ["**/*.perf.test.ts"]` |
| Security | `bun run test:security` | `vitest.config.ts` with `include: ["**/*.security.test.ts"]` |
| All | `bun run test` | Runs all in order above |

### 1.4 Halt Conditions

Execution halts (does not proceed to next phase) when:

1. Any P1 test in the current phase fails
2. More than 30% of tests in the current phase fail (regardless of priority)
3. A security test of any priority fails
4. The test runner encounters an infrastructure error (DB connection, port conflict)

When halted, the executor records partial results and outputs a halt report with the failing TC IDs.

### 1.5 Retry Policy

Flaky test handling:

- Each failed TC is retried up to 2 times before marking as FAIL
- If a TC passes on retry, it is marked as PASS with a `flaky: true` flag
- Flaky tests are logged for investigation but do not block execution
- Retry configuration: `retries: 2` in Vitest/Playwright config

## 2. Result Recording Format

### 2.1 test-results.json Structure

```json
{
  "$schema": "test-results.schema.json",
  "version": "4.0.0",
  "app": "my-app",
  "executedAt": "2026-04-03T14:30:00Z",
  "duration": "3m 42s",
  "environment": {
    "node": "22.x",
    "runtime": "bun 1.x",
    "os": "linux",
    "ci": true
  },
  "summary": {
    "total": 45,
    "pass": 42,
    "fail": 2,
    "skip": 1,
    "blocked": 0,
    "flaky": 1,
    "passRate": 93.33,
    "passRateP1": 100.0,
    "byType": {
      "unit": { "total": 18, "pass": 18, "fail": 0 },
      "integration": { "total": 12, "pass": 11, "fail": 1 },
      "e2e": { "total": 8, "pass": 7, "fail": 1 },
      "accessibility": { "total": 3, "pass": 3, "fail": 0 },
      "performance": { "total": 2, "pass": 2, "fail": 0 },
      "security": { "total": 2, "pass": 2, "fail": 0 }
    }
  },
  "results": [
    {
      "tcId": "TC-010",
      "title": "Successful login with valid credentials",
      "type": "e2e",
      "priority": "P1",
      "ftRef": "FT-010",
      "status": "pass",
      "duration": "2.3s",
      "retries": 0,
      "flaky": false,
      "logs": []
    },
    {
      "tcId": "TC-030",
      "title": "Login fails with wrong password",
      "type": "integration",
      "priority": "P1",
      "ftRef": "FT-010",
      "status": "fail",
      "duration": "1.1s",
      "retries": 2,
      "flaky": false,
      "error": {
        "message": "Expected status 401, received 500",
        "stack": "at loginHandler (src/routes/auth/login.ts:42)",
        "screenshot": null
      },
      "defect": {
        "id": "DEF-001",
        "severity": "Major",
        "component": "auth/login"
      },
      "logs": [
        "POST /api/v1/auth/login → 500 Internal Server Error",
        "PrismaClientKnownRequestError: connection refused"
      ]
    }
  ]
}
```

### 2.2 Result Status Values

| Status | Meaning | Counted In Pass Rate |
|--------|---------|---------------------|
| `pass` | TC executed successfully, expected result matched | Yes (numerator) |
| `fail` | TC executed, expected result not matched | Yes (denominator only) |
| `skip` | TC not executed (precondition not met, or explicitly skipped) | No |
| `blocked` | TC cannot execute due to dependency failure | No |

### 2.3 test-results.md Format

The markdown companion provides a human-readable summary:

```markdown
# Test Results — my-app

**Executed:** 2026-04-03 14:30 UTC
**Duration:** 3m 42s
**Pass Rate:** 93.33% (42/45) | P1: 100% (20/20)

## Summary by Type

| Type | Total | Pass | Fail | Rate |
|------|-------|------|------|------|
| Unit | 18 | 18 | 0 | 100% |
| Integration | 12 | 11 | 1 | 91.7% |
| E2E | 8 | 7 | 1 | 87.5% |
| Accessibility | 3 | 3 | 0 | 100% |
| Performance | 2 | 2 | 0 | 100% |
| Security | 2 | 2 | 0 | 100% |

## Failures

### TC-030: Login fails with wrong password [FAIL]
- **Type:** integration | **Priority:** P1 | **FT:** FT-010
- **Error:** Expected status 401, received 500
- **Defect:** DEF-001 (Major) — auth/login
- **Root Cause:** Database connection not established in test environment

## Coverage Matrix
(see Section 4 below)
```

## 3. Defect Classification

### 3.1 Severity Levels

| Severity | Criteria | SLA | Example |
|----------|----------|-----|---------|
| **Critical** | System crash, data loss, security breach, complete feature failure | Must fix before release | Login endpoint returns 500, user data leaked in response, payment double-charged |
| **Major** | Feature partially broken, incorrect behavior, significant UX issue | Must fix in current sprint | Wrong error message displayed, form submission loses data on validation error, pagination skips items |
| **Minor** | Cosmetic issue, minor UX inconsistency, non-blocking edge case | Fix when convenient, may defer | Tooltip misaligned by 2px, empty state message has typo, date format inconsistent on one screen |

### 3.2 Severity Assignment Rules

When a TC fails, assign severity based on these criteria:

1. **Does the failure affect data integrity?** Yes → Critical
2. **Does the failure expose a security vulnerability?** Yes → Critical
3. **Does the failure prevent the user from completing the task?** Yes → Critical (if primary path) or Major (if alternate path exists)
4. **Does the failure produce incorrect results?** Yes → Major
5. **Is the failure cosmetic or non-functional?** Yes → Minor

### 3.3 Defect Record Structure

```json
{
  "id": "DEF-001",
  "tcId": "TC-030",
  "ftRef": "FT-010",
  "severity": "Major",
  "status": "open",
  "component": "auth/login",
  "summary": "Login returns 500 instead of 401 for invalid password",
  "description": "When submitting login with correct email but wrong password, the API returns HTTP 500 instead of the expected 401. Root cause: unhandled PrismaClientKnownRequestError when bcrypt comparison fails.",
  "stepsToReproduce": [
    "POST /api/v1/auth/login with valid email, wrong password",
    "Observe 500 response instead of 401"
  ],
  "expectedBehavior": "401 Unauthorized with error message 'Invalid credentials'",
  "actualBehavior": "500 Internal Server Error with stack trace",
  "assignee": null,
  "createdAt": "2026-04-03T14:30:00Z",
  "resolvedAt": null
}
```

### 3.4 Defect Lifecycle

```
open → in-progress → fixed → verified → closed
                   → won't-fix → closed
                   → deferred → (re-open later)
```

- `fixed`: Developer has applied a fix
- `verified`: QA re-ran the TC and confirmed it passes
- `closed`: Defect resolved and verified in release candidate

## 4. Coverage Matrix Construction

### 4.1 Matrix Structure

The coverage matrix traces every requirement through to its test result:

```
FR-010 "Authentication"
  └─ US-010 "As a user, I want to log in"
       └─ FT-010 "Login form submission"
            ├─ TC-010 → PASS
            ├─ TC-020 → PASS
            ├─ TC-030 → FAIL (DEF-001)
            └─ TC-040 → PASS
       └─ FT-020 "Password reset"
            ├─ TC-050 → PASS
            └─ TC-060 → PASS
```

### 4.2 Matrix JSON Format

```json
{
  "matrix": [
    {
      "frId": "FR-010",
      "frTitle": "Authentication",
      "userStories": [
        {
          "usId": "US-010",
          "usTitle": "User login",
          "features": [
            {
              "ftId": "FT-010",
              "ftTitle": "Login form submission",
              "testcases": [
                { "tcId": "TC-010", "result": "pass" },
                { "tcId": "TC-020", "result": "pass" },
                { "tcId": "TC-030", "result": "fail", "defect": "DEF-001" },
                { "tcId": "TC-040", "result": "pass" }
              ],
              "ftPassRate": 75.0
            }
          ],
          "usPassRate": 83.3
        }
      ],
      "frPassRate": 83.3
    }
  ]
}
```

### 4.3 Coverage Gaps

A coverage gap exists when:

- An FR has no US → **requirement gap**
- A US has no FT → **feature gap**
- An FT has no TC → **test gap**
- A TC has no result → **execution gap**

All gaps are reported in the coverage matrix with status `uncovered`.

## 5. Pass Rate Calculation

### 5.1 Overall Pass Rate

```
Pass Rate = (PASS count) / (PASS count + FAIL count) * 100

Note: SKIP and BLOCKED are excluded from calculation
```

### 5.2 P1 Pass Rate

```
P1 Pass Rate = (P1 PASS count) / (P1 PASS + P1 FAIL) * 100
```

P1 pass rate is the primary release gate metric. Target: 100%.

### 5.3 Pass Rate Thresholds

| Metric | Gate (minimum) | Target |
|--------|---------------|--------|
| Overall pass rate | 90% | 98%+ |
| P1 pass rate | 100% | 100% |
| P2 pass rate | 85% | 95%+ |
| Unit test pass rate | 95% | 100% |
| Security test pass rate | 100% | 100% |

### 5.4 Pass Rate by FT

Each FT gets its own pass rate, enabling targeted re-work:

```
FT-010 pass rate = TC-010(pass) + TC-020(pass) + TC-030(fail) + TC-040(pass)
                 = 3/4 = 75%
```

FTs with pass rate below 90% are flagged for developer attention.

## 6. Regression Test Selection

### 6.1 When to Run Regression

Regression tests are selected and executed when:

- A defect fix is applied (verify fix + no side effects)
- A new feature is added (verify existing features unaffected)
- A dependency is updated (verify compatibility)
- Before each release candidate

### 6.2 Selection Strategy

#### 6.2.1 Change-Based Selection

Analyze `git diff` to determine affected modules:

```
Changed: src/routes/auth/login.ts
  → Select all TCs referencing FT items that touch auth/login
  → Select all TCs with type=integration that test auth endpoints
  → Select all TCs with type=e2e that include login flow
```

#### 6.2.2 Dependency-Based Selection

Use `data/links.json` to trace impact:

```
Changed: ENT-010 (User entity)
  → API-010, API-020 (endpoints using User)
    → FT-010, FT-020 (features using those APIs)
      → TC-010..TC-060 (tests for those features)
```

#### 6.2.3 Risk-Based Selection

Always include in regression:

- All P1 test cases (regardless of change analysis)
- All security test cases
- All tests that previously failed and were fixed (verify non-regression)
- All tests marked as `flaky: true` (verify stability)

### 6.3 Regression Suite Tiers

| Tier | Contents | When to Run | Duration Target |
|------|----------|-------------|-----------------|
| Smoke | P1 happy-path TCs only (10-15 TCs) | Every commit | < 2 min |
| Core | All P1 + P2 TCs (30-50 TCs) | Every PR merge | < 10 min |
| Full | All TCs including P3 | Release candidate | < 30 min |

### 6.4 Regression Result Handling

When a regression test fails:

1. Mark the TC result as `fail` with `regression: true` flag
2. Create a defect with severity determined by impact assessment
3. If the failure is in a P1 TC → block the release
4. If the failure is in a previously passing TC → elevated severity (bump Minor to Major)
5. Trace back to the change that caused the regression using git bisect analysis

### 6.5 Continuous Regression

In CI/CD pipelines, configure:

```yaml
# Smoke on every push
on: push
  → run: bun run test:smoke

# Core on PR
on: pull_request
  → run: bun run test:core

# Full on release branch
on: push (release/*)
  → run: bun run test:full
```
