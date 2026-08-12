---
name: u-gatekeeping
description: "This skill should be used when the user asks to '/u-gatekeeping', '/u-check', '/u-qa', 'gatekeep', 'quality gate', 'u-maker QA', 'test cases', 'run tests', 'u-maker 검수', '검수 단계', '품질 게이트', '테스트 케이스 생성', 'u-maker 테스트', 'generate test cases', '디자인 일치성', 'Figma 일치', 'design conformance', or 'score documents'. Covers document scoring (11-criteria gatekeeper), runtime QA (testcases + execution), and design conformance (GK-12 Figma/reference ↔ implementation pixel-perfect)."
version: 4.1.0
---

# u-gatekeeping — Gatekeeping Phase (PBGD Gatekeeping)

`/u-gatekeeping [--auto] [--loop] [--app {name}] [--only doc|qa]`
**Aliases:** `/u-check`, `/u-qa`

Gatekeeping phase unifies three responsibilities:

- **Doc scoring** (Gatekeeping.DocScoring) — 11-criteria gatekeeper validation with avg ≥ 95 pass threshold (and ≥ 98 deploy-readiness threshold).
- **Runtime QA** (Gatekeeping.RuntimeQA) — testcase design from SRS Features (FT), test execution, result recording, coverage matrix.
- **Design Conformance** (Gatekeeping.DesignConformance) — GK-12: implemented UI is **pixel-perfect** to the Figma source of truth + ingested reference materials (token/layout/variant/text parity, reference-rule coverage, zero drift). Gates Deploy.

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

> **Step 2.5 (Design Conformance) ALWAYS runs** — it is a deploy-readiness gate, not doc/QA work, so it is **not** skipped by `--only doc` or `--only qa`. When no Figma/reference provenance exists it is a fast N/A.

## Execution Flow

### Step 1: Doc Scoring (Gatekeeping.DocScoring)

1. Invoke `u-agent-gatekeeper` with scope = all docs of the current app.
2. Score each doc against the 11 doc-quality criteria (GK-01..GK-11) in `_meta/schemas/gate-rules.json`. (GK-12 Design Conformance is scored separately in **Step 2.5**, not per-doc here.)
3. Compute avg score.
4. Write `reports/gatekeeper/{app}-{timestamp}.md` + companion JSON.
5. Result states:
   - `avg >= 98` → `deployReady: true, docScore: pass` (cleared for Deploy).
   - `98 > avg >= 95` → `deployReady: false, docScore: pass` (cleared for Gatekeeping complete, not Deploy).
   - `avg < 95` → `docScore: fail` (block until improvement).

> **Plain language check (GK-06):** GK-06 (Content Composition) includes the `plain-language-middle-school` check — all explanatory prose in scored docs must read at middle-school level on first pass: short sentences, everyday words, jargon glossed at first use; IDs/code/schema/figures stay intact. Rule source: `skills/u-engine/references/doc-engine.md` § 8 / `html-engine.md` § 0.6. The gatekeeper reports this skill writes follow the same rule.

### Step 2: Runtime QA (Gatekeeping.RuntimeQA)

1. Load `docs/{app}/plan/srs.json` — extract FT items.
2. For each FT → generate TC (1:N mapping). TC types: unit, integration, e2e, accessibility, performance, security.
3. Apply ID 10-increment (TC-010, TC-020…).
4. Define preconditions, steps, expected results, test data.
5. Write `docs/{app}/gatekeeping/testcases.md` + `testcases.json`.
6. Execute each TC against implemented code; record PASS/FAIL.
   - **Browser-bound TCs (type = `e2e`, `accessibility`, browser-based `performance`) MUST route through `skills/u-tools-browser/SKILL.md`** — never call MCP Playwright tools or `agent-browser` CLI directly. The engine handles port detection, headed/headless selection, dev-server verification, error screenshots, and failure triage (fix/todo/skip).
7. Aggregate results; calculate pass rate by type.
8. Build coverage matrix (FR→US→FT→TC→Result).
9. Write `docs/{app}/gatekeeping/test-results.md` + `test-results.json`.
10. Update `data/links.json` (FT→TC `tests` edges).

### Step 2.5: Design Conformance (Gatekeeping.DesignConformance) — Figma/reference ↔ implementation, PIXEL-PERFECT

Verifies the implemented UI is **pixel-perfect** to the Figma source of truth and the ingested reference materials (참고자료). Feeds **GK-12** and the Deploy gate. Routes **all** browser/Figma work through `/u-tools-browser` — never call MCP Playwright/Figma tools directly.

1. **Provenance discovery.** Collect every registered design source: `data/figma/manifest.json.dsFileKey`, `design-system.json.components[*].figmaKey`, `screens.json[*].figmaUrl`, and any `data/digest/figma/**`. If NONE exist → write `.state/design-conformance.json {"result":"na"}` and skip (GK-12 auto-passes).
2. **DS + component parity (re-verify — do NOT trust stale state).** Re-run `/u-tools-browser` Step 6e (Design System) and Step 6f (components) when the recorded `.state/visual-verify/*.json` is missing or older than the current code/Figma hash. Apply the **pixel-perfect GATE thresholds** (SSIM ≥ 0.99, pixel diff ≤ 1 %, bounds ± 1 px — `gate-rules.json` GK-12.thresholds), stricter than the Build-phase iteration thresholds (0.95 / 5 % / ±2 px).
3. **Screen/route parity (NEW — Step 6g).** Run `/u-tools-browser` Step 6g for every `screens.json` item with `figmaUrl`: render the route, diff against the Figma frame at the pixel-perfect thresholds, check critical text + token resolution.
4. **Reference-rule coverage.** Assert every digest `validationRules[] / domainRules[] / permissionRules[] / processingRules[]` maps to an implemented guard or a TC. List orphans as `coverageGaps`.
5. **Override policy.** A `--no-figma-parity` used here (at the GATE) **without an explicit acknowledged record is a FAIL** — it is not silently defeatable at the gate the way it is during fast Build iteration.
6. **Aggregate** into `.state/design-conformance.json`:

```json
{
  "app": "{app}",
  "result": "pass | fail | na",
  "thresholds": { "ssimMin": 0.99, "pixelDiffMaxPct": 1, "boundsTolerancePx": 1 },
  "figmaParity": { "designSystem": "pass", "components": "pass", "screens": "pass" },
  "referenceCoverage": "pass",
  "coverageGaps": [],
  "drift": [],
  "overrides": [],
  "checkedAt": "…"
}
```

7. **Gate.** ANY `fail` / stale / missing-while-provenance-exists / `figmaSourceUnlinked` / unacknowledged override → block Gatekeeping pass and feed **GK-12** a critical (< 95) score. Requires the app dev server + an authenticated Figma session; when unavailable, HALT with the same instructions UX as Steps 6e/6f, or take an explicit **acknowledged** skip that is recorded and **still blocks Deploy**.

### Step 3: Loop (if `--loop`)

1. If avg doc score < 95 → surface improvement list to `u-agent-design` / `u-agent-dev` (escalate via `u-agent-pm`).
2. If any critical-severity test failed → same escalation path.
3. If `design-conformance.json.result == "fail"` (GK-12) → surface the `drift[]` / `coverageGaps[]` to `u-agent-dev` (implementation drift) or `u-agent-design` (spec/Figma drift), fix to pixel-perfect, then re-run **Step 2.5**.
4. Max 3 retries.
5. After 3 failed attempts → alert user; do not proceed to Deploy.

### Step 4: Deploy gate readiness

After a successful run, emit a `deploy-readiness.json` snapshot:

```json
{
  "app": "{app}",
  "docScore": 97.2,
  "designConformance": "pass",
  "deployReady": false,
  "reason": "docScore 97.2 < deployThreshold 98; improve doc quality before /u-deploy.",
  "checkedAt": "…"
}
```

`deployReady` is `true` only when **BOTH** `docScore ≥ 98` **AND** `designConformance ∈ {"pass","na"}` (GK-12, copied from `.state/design-conformance.json.result`). A `designConformance: "fail"` forces `deployReady: false` with `reason: "design conformance (GK-12) fail — implementation drifts from Figma/reference"`, regardless of doc score.

> **Staleness guard (do NOT copy a stale pass):** if `.state/design-conformance.json` is **missing or older than the current code/Figma hash** while Figma/reference provenance exists, treat `designConformance` as `"fail"` and re-run **Step 2.5** — never inherit a prior `"pass"`. (Mirrors the gatekeeper agent's GK-12 staleness rule.)

This file is read by `/u-deploy` to enforce the ≥ 98 + pixel-perfect-conformance gate.

## Output Files

| Path | Sub-phase | Description |
|------|-----------|-------------|
| `reports/gatekeeper/{app}-{ts}.md` | DocScoring | Per-run scoring report |
| `reports/gatekeeper/{app}-{ts}.json` | DocScoring | Machine-readable scores |
| `docs/{app}/gatekeeping/testcases.{md,json}` | RuntimeQA | Test case definitions |
| `docs/{app}/gatekeeping/test-results.{md,json}` | RuntimeQA | Execution results |
| `.state/design-conformance.json` | DesignConformance | GK-12 Figma/reference ↔ implementation **pixel-perfect** drift report; consumed by GK-12 + the Deploy gate |
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
