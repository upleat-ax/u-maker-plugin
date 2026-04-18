---
name: u-gatekeeping
description: "This skill should be used when the user asks to 'gatekeep', 'quality gate', 'QA', 'generate test cases', 'run tests', 'score documents', '/u-gatekeeping', '/u-check', or '/u-qa'. Covers both document scoring (11-criteria gatekeeper) and runtime QA (testcases + execution)."
version: 4.0.0
triggers:
  - "/u-gatekeeping"
  - "/u-check"
  - "/u-qa"
  - "gatekeep"
  - "quality gate"
  - "QA"
  - "test cases"
  - "run tests"
---

# u-gatekeeping — Gatekeeping Phase (PBGD Gatekeeping)

`/u-gatekeeping [--auto] [--loop] [--app {name}] [--only doc|qa]`
**Aliases:** `/u-check`, `/u-qa`

Gatekeeping phase unifies two responsibilities:

- **Doc scoring** (Gatekeeping.DocScoring) — 11-criteria gatekeeper validation with avg ≥ 95 pass threshold (and ≥ 98 deploy-readiness threshold).
- **Runtime QA** (Gatekeeping.RuntimeQA) — testcase design from SRS Features (FT), test execution, result recording, coverage matrix.

**Primary Agents:** u-agent-gatekeeper (doc scoring), u-agent-qa (runtime QA)
**Engine Dependencies:** doc-engine, dep-engine
**Gate Prerequisite:** Build phase gate passed (design docs Final + code generated)
**PBGD Phase:** Gatekeeping

> **Migration note (v3.x → v4.0):** In PDCA this skill was named `/u-check`. In PBGD the name is `/u-gatekeeping` and it now explicitly covers both doc scoring and runtime QA as sub-phases. `/u-check` and `/u-qa` remain as aliases.

## Arguments

| Argument | Description |
|----------|-------------|
| `--auto` | Non-interactive; default ON |
| `--loop` | Run until avg score ≥ 95 or max retries |
| `--app {name}` | App scope |
| `--only doc` | Run doc scoring only (skip runtime QA) |
| `--only qa` | Run runtime QA only (skip doc scoring) |

## Execution Flow

### Step 1: Doc Scoring (Gatekeeping.DocScoring)

1. Invoke `u-agent-gatekeeper` with scope = all docs of the current app.
2. Score each doc against the 11 criteria in `_meta/schemas/gate-rules.json`.
3. Compute avg score.
4. Write `reports/gatekeeper/{app}-{timestamp}.md` + companion JSON.
5. Result states:
   - `avg >= 98` → `deployReady: true, docScore: pass` (cleared for Deploy).
   - `98 > avg >= 95` → `deployReady: false, docScore: pass` (cleared for Gatekeeping complete, not Deploy).
   - `avg < 95` → `docScore: fail` (block until improvement).

### Step 2: Runtime QA (Gatekeeping.RuntimeQA)

1. Load `docs/{app}/plan/srs.json` — extract FT items.
2. For each FT → generate TC (1:N mapping). TC types: unit, integration, e2e, accessibility, performance, security.
3. Apply ID 10-increment (TC-010, TC-020…).
4. Define preconditions, steps, expected results, test data.
5. Write `docs/{app}/gatekeeping/testcases.md` + `testcases.json`.
6. Execute each TC against implemented code; record PASS/FAIL.
7. Aggregate results; calculate pass rate by type.
8. Build coverage matrix (FR→US→FT→TC→Result).
9. Write `docs/{app}/gatekeeping/test-results.md` + `test-results.json`.
10. Update `data/links.json` (FT→TC `tests` edges).

### Step 3: Loop (if `--loop`)

1. If avg doc score < 95 → surface improvement list to `u-agent-design` / `u-agent-dev` (escalate via `u-agent-pm`).
2. If any critical-severity test failed → same escalation path.
3. Max 3 retries.
4. After 3 failed attempts → alert user; do not proceed to Deploy.

### Step 4: Deploy gate readiness

After a successful run, emit a `deploy-readiness.json` snapshot:

```json
{
  "app": "{app}",
  "docScore": 97.2,
  "deployReady": false,
  "reason": "docScore 97.2 < deployThreshold 98; improve doc quality before /u-deploy.",
  "checkedAt": "…"
}
```

This file is read by `/u-deploy` to enforce the ≥ 98 gate.

## Output Files

| Path | Sub-phase | Description |
|------|-----------|-------------|
| `reports/gatekeeper/{app}-{ts}.md` | DocScoring | Per-run scoring report |
| `reports/gatekeeper/{app}-{ts}.json` | DocScoring | Machine-readable scores |
| `docs/{app}/gatekeeping/testcases.{md,json}` | RuntimeQA | Test case definitions |
| `docs/{app}/gatekeeping/test-results.{md,json}` | RuntimeQA | Execution results |
| `.state/deploy-readiness.json` | Gate | Consumed by `/u-deploy` |

> **Note on `docs/{app}/gatekeeping/`:** In v3.x these docs lived under `docs/{app}/check/`. New projects in v4.0 use `gatekeeping/`. The `/u-prepare-foldertree` migration step renames `check/` → `gatekeeping/` on v3→v4 upgrade.

## Reference Files

- **`references/doc-scoring.md`** — 11-criteria scoring methodology; pass (≥95) vs deploy-ready (≥98) thresholds.
- **`references/runtime-qa.md`** — Test case design rules, execution protocol, result recording.
- **`references/testcase-spec.md`** — TC derivation from FT, 6 TC types, priority mapping.
- **`references/test-execution.md`** — Execution protocol, result recording, defect classification.

## Related Commands

- `/u-build` — Previous phase; must pass before Gatekeeping can start.
- `/u-deploy` — Next phase; blocked if `deployReady: false` (doc score < 98).
