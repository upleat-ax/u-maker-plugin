---
name: u-check
description: "This skill should be used when the user asks to 'check', 'test', 'QA', 'generate test cases', 'run tests', '/u-check', or wants to perform quality assurance on implemented code."
version: 4.0.0
triggers:
  - "/u-check"
  - "/u-qa"
  - "check phase"
  - "QA"
  - "test cases"
  - "run tests"
---

# u-check — Check Phase

`/u-check [--auto] [--loop] [--app {name}]`
**Alias:** `/u-qa`

Check phase: design test cases from SRS Features (FT), execute tests, record results, verify coverage.

**Primary Agent:** u-agent-qa
**Engine Dependencies:** doc-engine, dep-engine
**Gate Prerequisite:** Dev phase gate passed (code-complete, build-success)

## Execution Flow

### Step 1: Design Test Cases

1. Load `docs/{app}/plan/srs.json` — extract FT items
2. For each FT → generate TC (1:N mapping)
3. TC types: unit, integration, e2e, accessibility, performance, security
4. Apply ID 10-increment (TC-010, TC-020...)
5. Define preconditions, steps, expected results, test data
6. Write `docs/{app}/check/testcases.md` + `testcases.json`
7. Update `data/links.json` (FT→TC edges)

### Step 2: Execute Tests

1. Load `testcases.json`
2. Execute each TC against implemented code
3. Record results: PASS/FAIL per TC

### Step 3: Record Results

1. Aggregate execution results
2. Calculate pass rate by type (unit/integration/e2e)
3. Build coverage matrix (FR→US→FT→TC→Result)
4. Write `docs/{app}/check/test-results.md` + `test-results.json`

### Step 4: Generate HTML Output

1. **Test Cases → Domain Split** (see html-engine § 12):
   - Read `testcases.json` → group TCs by parent FT's FR
   - Create `output/{app}/check/testcases/` directory
   - Generate `output/{app}/check/testcases/index.html` (split index):
     - Stats: TC count by type (unit/integration/e2e/...), total TC count
     - Domain cards: one card per FR group
     - Overview: FT→TC coverage matrix (SVG), TC distribution by type donut chart (SVG)
   - Generate `output/{app}/check/testcases/{fr-group-slug}.html` per FR group (split page):
     - Content: TCs for that FR group + preconditions, steps, expected results
     - Sidebar + prev/next navigation
   - Template: `output-split-index.template.html` + `output-split-page.template.html`

2. Convert `test-results.md` → `output/{app}/check/test-results.html` via html-engine (single file — summary)
   - MUST include (inline SVG): FR→US→FT→TC→Result full traceability tree, Pass/Fail summary donut chart
   - Generate SVG diagrams from `test-results.json` data

3. Update `output/{app}/index.html` navigation:
   - Test Cases → `check/testcases/index.html`
   - Test Results → `check/test-results.html`
4. Update root index files: `output/index.html`, `index.html` (see html-engine § 8 "Root Index Navigation System")
5. See `html-engine.md` § 2 — SVG preferred, Mermaid only for UML fallback

### Step 5: Gatekeeper (if --loop)

1. Invoke u-agent-gatekeeper on check documents
2. If avg score < 95 → improvement list → re-execute
3. Max 3 retries

## Reference Files

- **`references/testcase-spec.md`** — TC derivation from FT, 6 TC types, priority mapping
- **`references/test-execution.md`** — Execution protocol, result recording, defect classification
