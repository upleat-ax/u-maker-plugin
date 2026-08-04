# Test Case Specification

This reference defines how test cases (TC) are derived from SRS Feature items (FT), the six supported TC types, priority mapping rules, precondition formatting, test data specification, and the JSON companion structure.

## 1. TC Derivation from FT Items

### 1.1 Derivation Principle

Every test case traces directly to one or more Feature (FT) items from the SRS. The mapping is 1:N -- each FT produces one or more TCs depending on:

- Number of acceptance criteria in the FT
- Number of boundary conditions
- Number of error scenarios
- Complexity of the user interaction

### 1.2 Traceability Chain

The full traceability chain is:

```
FR (Functional Requirement)
  └─ US (User Story)
       └─ FT (Feature / Implementation Unit)
            └─ TC (Test Case) ← derived here
                 └─ Result (PASS/FAIL)
```

This chain is recorded in `data/links.json` as edges:

```json
{
  "edges": [
    { "from": "FT-010", "to": "TC-010", "type": "tests" },
    { "from": "FT-010", "to": "TC-020", "type": "tests" },
    { "from": "FT-020", "to": "TC-030", "type": "tests" }
  ]
}
```

### 1.3 ID Convention

Test case IDs use 10-increment numbering within the scope of the entire test suite:

- `TC-010` — first test case
- `TC-020` — second test case
- `TC-030` — third test case

The 10-increment gap allows inserting additional TCs later without renumbering:

```
TC-010 (original)
TC-015 (inserted later)
TC-020 (original)
```

### 1.4 Derivation Algorithm

For each FT item in `srs.json`:

1. **Read FT definition**: Extract name, description, acceptance criteria
2. **Happy path TC**: One TC for the primary success scenario
3. **Validation TCs**: One TC per input validation rule (required, format, length, range)
4. **Boundary TCs**: One TC per boundary condition (min, max, edge values)
5. **Error TCs**: One TC per documented error case
6. **Permission TCs**: One TC per role-based access variation (if applicable)
7. **State TCs**: One TC per significant state transition (if applicable)

**Example derivation for FT-010 "User Login":**

| TC ID | FT Source | Scenario | Type |
|-------|-----------|----------|------|
| TC-010 | FT-010 | Successful login with valid credentials | e2e |
| TC-020 | FT-010 | Login fails with invalid email format | unit |
| TC-030 | FT-010 | Login fails with wrong password | integration |
| TC-040 | FT-010 | Login fails after 5 failed attempts (rate limit) | integration |
| TC-050 | FT-010 | Login session expires after timeout | e2e |

## 2. Six TC Types

### 2.1 Unit Tests

**Scope:** Individual functions, utilities, validators, pure logic
**Framework:** Vitest
**File pattern:** `*.test.ts` colocated with source

```markdown
### TC-020: Email validation rejects invalid format

- **Type:** unit
- **FT:** FT-010
- **Priority:** P1
- **Preconditions:** None
- **Steps:**
  1. Call `validateEmail("not-an-email")`
  2. Assert return value is `false`
- **Expected Result:** Function returns `false`
- **Test Data:** `"not-an-email"`, `"@missing.com"`, `""`, `"valid@email.com"`
```

### 2.2 Integration Tests

**Scope:** Module interactions, API endpoints, database operations, service-to-service calls
**Framework:** Vitest + supertest (API), Vitest + Prisma test utils (DB)
**File pattern:** `*.integration.test.ts`

Tests verify that multiple modules work together correctly: route handler + validation + service + database.

### 2.3 E2E Tests

**Scope:** Full user flows through the UI, simulating real browser interaction
**Framework:** Playwright
**File pattern:** `e2e/*.spec.ts`

E2E tests follow the user journey from screen entry to completion, covering navigation, form submission, feedback display, and state persistence.

### 2.4 Accessibility Tests

**Scope:** WCAG 2.1 AA compliance, keyboard navigation, screen reader compatibility
**Framework:** axe-core (via @axe-core/playwright or vitest-axe)
**File pattern:** `*.a11y.test.ts`

Checks include:
- Color contrast ratios (minimum 4.5:1 for normal text)
- Keyboard-only navigation (all interactive elements focusable)
- ARIA labels on non-text elements
- Focus management after dynamic content changes
- Form error announcements

### 2.5 Performance Tests

**Scope:** Response times, rendering performance, bundle size, Core Web Vitals
**Framework:** Lighthouse CI, Playwright performance API
**File pattern:** `*.perf.test.ts`

Metrics evaluated:
- API response time < threshold (default: 200ms for reads, 500ms for writes)
- LCP (Largest Contentful Paint) < 2.5s
- FID (First Input Delay) < 100ms
- CLS (Cumulative Layout Shift) < 0.1
- Bundle size within budget

### 2.6 Security Tests

**Scope:** Authentication, authorization, injection prevention, data exposure
**Framework:** Vitest + custom security utilities
**File pattern:** `*.security.test.ts`

Checks include:
- SQL injection prevention (parameterized queries verified)
- XSS prevention (output encoding verified)
- CSRF token validation
- Authentication bypass attempts
- Authorization boundary enforcement (role A cannot access role B resources)
- Sensitive data not exposed in API responses (password, tokens)

## 3. Priority Mapping

### 3.1 Priority Levels

| Priority | Label | Meaning | Test Execution |
|----------|-------|---------|---------------|
| P1 | Must | Core functionality, blocking defects | Run on every commit (CI) |
| P2 | Should | Important but non-blocking | Run on PR merge |
| P3 | Could | Nice-to-have, edge cases | Run on release candidate |

### 3.2 Priority Assignment Rules

- **P1 (Must):** Happy path for each FT, critical validation (auth, payment, data integrity), security tests
- **P2 (Should):** Error handling, boundary conditions, integration between modules, accessibility
- **P3 (Could):** Performance benchmarks, edge cases, cosmetic validation, rare state transitions

### 3.3 FT-to-Priority Mapping

The FT's own priority (from SRS) influences TC priority:

| FT Priority | TC Happy Path | TC Validation | TC Error | TC Edge Case |
|-------------|--------------|---------------|----------|-------------|
| Must (P1) | P1 | P1 | P1 | P2 |
| Should (P2) | P1 | P2 | P2 | P3 |
| Could (P3) | P2 | P2 | P3 | P3 |

## 4. Precondition Format

Each TC defines preconditions using a structured format:

```markdown
**Preconditions:**
1. [ENV] Database seeded with test user (email: test@example.com, password: Test1234!)
2. [STATE] User is not authenticated (no active session)
3. [NAV] Browser is on the login page (/login)
4. [DATA] Rate limit counter for test IP is reset to 0
```

### 4.1 Precondition Categories

| Prefix | Category | Description |
|--------|----------|-------------|
| `[ENV]` | Environment | Server running, DB seeded, external services mocked |
| `[STATE]` | Application State | User logged in/out, feature flags, session data |
| `[NAV]` | Navigation | Current page/route, modal open/closed |
| `[DATA]` | Test Data | Specific records exist, counters reset, queues empty |
| `[CONFIG]` | Configuration | Feature flags, environment variables, settings |

### 4.2 Setup/Teardown Mapping

Each precondition category maps to test lifecycle hooks:

- `[ENV]` → `beforeAll` (one-time setup)
- `[STATE]` → `beforeEach` (reset per test)
- `[NAV]` → test body (navigate as first step)
- `[DATA]` → `beforeEach` or factory function
- `[CONFIG]` → `beforeAll` or environment variable override

## 5. Test Data Specification

### 5.1 Test Data Definition

Each TC specifies its test data inline or references a data fixture:

```markdown
**Test Data:**
- Valid user: `{ email: "test@example.com", password: "Test1234!" }`
- Invalid email: `{ email: "not-an-email", password: "Test1234!" }`
- Empty fields: `{ email: "", password: "" }`
```

### 5.2 Data-Driven Tests

When a single TC logic applies to multiple data sets, use parameterized format:

```markdown
**Test Data (parameterized):**

| # | Input Email | Input Password | Expected Result |
|---|------------|---------------|-----------------|
| 1 | test@example.com | Test1234! | Login success |
| 2 | not-an-email | Test1234! | Validation error: invalid email |
| 3 | test@example.com | short | Validation error: min 8 chars |
| 4 | unknown@example.com | Test1234! | Auth error: invalid credentials |
```

### 5.3 Fixture Files

For complex test data, reference fixture files:

```markdown
**Test Data:** See `fixtures/users.json` — records 1-5
```

Fixture files live at `tests/fixtures/` and are versioned alongside test code.

## 6. JSON Companion Structure

### 6.1 testcases.json

The companion JSON file contains structured TC data for machine processing:

```json
{
  "$schema": "testcases.schema.json",
  "version": "4.0.0",
  "app": "my-app",
  "generatedAt": "2026-04-03T12:00:00Z",
  "summary": {
    "total": 45,
    "byType": {
      "unit": 18,
      "integration": 12,
      "e2e": 8,
      "accessibility": 3,
      "performance": 2,
      "security": 2
    },
    "byPriority": {
      "P1": 20,
      "P2": 18,
      "P3": 7
    }
  },
  "testcases": [
    {
      "id": "TC-010",
      "title": "Successful login with valid credentials",
      "type": "e2e",
      "priority": "P1",
      "ftRef": "FT-010",
      "preconditions": [
        { "category": "ENV", "description": "Database seeded with test user" },
        { "category": "STATE", "description": "User is not authenticated" },
        { "category": "NAV", "description": "Browser on /login" }
      ],
      "steps": [
        { "seq": 1, "action": "Enter email 'test@example.com'", "target": "email input" },
        { "seq": 2, "action": "Enter password 'Test1234!'", "target": "password input" },
        { "seq": 3, "action": "Click 'Sign In' button", "target": "submit button" }
      ],
      "expectedResult": "User redirected to /dashboard, session cookie set",
      "testData": {
        "email": "test@example.com",
        "password": "Test1234!"
      },
      "status": "pending"
    }
  ]
}
```

### 6.2 Key Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique TC identifier (TC-NNN format) |
| `title` | string | Human-readable TC description |
| `type` | enum | One of: unit, integration, e2e, accessibility, performance, security |
| `priority` | enum | One of: P1, P2, P3 |
| `ftRef` | string | Source FT item ID |
| `preconditions` | array | Categorized precondition list |
| `steps` | array | Ordered test steps with seq number |
| `expectedResult` | string | What success looks like |
| `testData` | object | Input data for this TC |
| `status` | enum | pending, pass, fail, skip, blocked |

### 6.3 Validation Rules

- Every TC must have a unique `id`
- Every TC must reference a valid `ftRef` that exists in `srs.json`
- Every TC must have at least one step
- `expectedResult` must not be empty
- `type` must be one of the six defined types
- `priority` must be P1, P2, or P3
