---
name: u-tools-figma-screen
description: "Generate Screen Specifications in Figma and/or markdown+JSON from existing screen-plan + design-system inputs. Use when the user asks to '/u-tools-figma-screen', 'generate screen plan', 'screens to figma', 'wireframe to figma', 'figma 화면기획', 'screen specification generation', '피그마 화면 생성', '화면 스펙 피그마', or 'screens.md 생성'. Auto-delegated from /u-plan when both screen-plan source and design-system source are detected. Inputs: (Figma URL | screens.{md,json}) for the screen plan, (Figma DS URL | design-system.{md,json,tsx,css}) for the design system."
version: 1.0.0
---

# u-tools-figma-screen — Screen Specification Generator

`/u-tools-figma-screen [--app {name}] [--screen-source {figma-url|md|json|auto}] [--ds-source {figma-url|md|json|code|auto}] [--output figma|md|both] [--prefer figma|md] [--loop]`

External-tool wrapper that produces a **new** screen specification (in Figma frames, in markdown+JSON, or both) from existing screen-plan and design-system sources. This skill is the write-side counterpart to the read-only `/u-tools-figma` analyzer.

**Primary Agent:** u-agent-design (consumer); orchestrated by u-agent-pm
**Engine Dependencies:** doc-engine, dep-engine, digest-engine
**External skills delegated to:** `figma:figma-generate-design` (Figma writes), `figma:figma-use` (mandatory prerequisite for `use_figma`)
**PBGD Phase:** Plan.Plan (auto-invoked) and Build.UIDesign (manual / `/u-design` follow-up)
**Parent invokers:** `/u-plan` (auto-delegation when sources detected), `/u-design` (Step 4.5), standalone

## Use Figma Writes Only Through This Engine

All u-maker phase skills MUST call `/u-tools-figma-screen` instead of invoking `figma:figma-generate-design` or `mcp__plugin_figma_figma__use_figma` directly. Centralising it here keeps:

- **Source resolution** consistent (Figma URL vs md/json vs both — single decision point)
- **Manifest tracking** consistent (`data/figma/manifest.json` hashes for incremental regen)
- **Link traceability** identical (`figmaUrl` deep links propagated to screens.json)
- **Conflict prompts** identical when Figma and md sources disagree
- **DS rule pack** loaded once (the Step 3 component bindings respect `skills/u-design/references/design-system-rules.md`)

If the platform offers multiple Figma write paths, always pick **`figma:figma-generate-design`** (delegation). Never call `mcp__plugin_figma_figma__use_figma` directly from u-maker phase skills.

## Source Resolution Matrix

The skill always resolves **two inputs**: (1) the screen-plan source and (2) the design-system source. Each may come from Figma OR from documents/code under the project tree.

| Source | Discovery order | Notes |
|--------|-----------------|-------|
| Screen plan — Figma | (a) `--screen-source <url>`, (b) `data/figma/aggregate.json` frames classified as `screen-design` or `screen-planning`, (c) `.figma-link` entries in `data/dropzone/` tagged `screens` | Triggers refresh via `/u-tools-figma --verify` if manifest is stale |
| Screen plan — md/json | (a) `--screen-source ./path/screens.json`, (b) `docs/{app}/design/screens.{md,json}` if Final, (c) `docs/{app}/plan/ia.json` page inventory as fallback | Pure-doc mode; no Figma read needed |
| Design system — Figma | (a) `--ds-source <url>`, (b) `data/figma/aggregate.json` frames classified as `design-tokens` / `assets`, (c) `.figma-link` tagged `design-system` | |
| Design system — md/json | (a) `--ds-source ./path/design-system.json`, (b) `docs/{app}/design/design-system.{md,json}` if Final, (c) `out/{app}/design/design-system.html` parsed back | |
| Design system — code | (a) `--ds-source ./packages/ui-*`, (b) auto-detect `packages/tokens/`, `packages/ui-*/src/components/`, (c) `apps/*/src/styles/tokens.css` | Used to recover token values when the doc layer is missing |

If both Figma and md sources are present, **Figma wins by default** (visual SoT). Pass `--prefer md` to invert. The chosen winner is recorded in the run log.

### Mandatory pre-flight

1. If `--screen-source` and `--ds-source` are both unspecified and **no candidate** is found via auto-discovery → HALT with the message:
   > "u-tools-figma-screen needs a screen-plan source AND a design-system source. Provide them via flags or place inputs under `data/dropzone/` (Figma links) / `docs/{app}/design/` (md+json) / `packages/ui-*` (code)."
2. If exactly one of the two is missing → ask via `AskUserQuestion` whether to (a) abort, (b) generate a default DS via `/u-tools-figma-ds`, (c) skip the missing input and let the writer infer from primitives (Figma) or the IA (md). Default = (a).

## Workflow

### Step 0: Verify Tool Availability

1. Check that the `figma:figma-generate-design` skill is reachable. If absent → HALT:
   > "`figma` plugin is not installed. Install it (e.g., `/plugin install figma`) or run with `--output md` only."
2. If `--output` includes `figma`, also verify `figma:figma-use` and `mcp__plugin_figma_figma__authenticate` (or an existing session). If unauthenticated → ask the user to authenticate, then continue.

### Step 1: Resolve Sources

1. Walk the **Source Resolution Matrix** in order; record the chosen winner for screens and DS into `.u-maker/.state/figma-screen-run.json` (`{runId, app, screensSource, dsSource, prefer, output, ts}`).
2. If a Figma source is chosen and `data/figma/manifest.json` is stale (hash mismatch), delegate to `/u-tools-figma --verify` first to refresh `data/figma/aggregate.json`. Do NOT continue with a stale aggregate.
3. Materialise both inputs into normalised in-memory objects:
   - `screensInput` — `{screens: [{id, name, route?, components[], states[], validations[], apis[], figmaNodeId?, figmaUrl?}]}`
   - `dsInput` — `{tokens: {color, spacing, type, radius, shadow, motion, breakpoint, zIndex}, components: [{key, name, variants[], props[], figmaKey?}]}`

### Step 2: Build Conflict / Coverage Report

1. Cross-check screensInput components vs dsInput components. Any component referenced in screens but missing in DS → record under `coverageGaps[]`.
2. Cross-check Figma vs md when **both** are present. Any field disagreement (e.g., screen name, component prop list) → record under `conflicts[]` with both values.
3. If `conflicts[]` is non-empty:
   - In `--auto` mode → resolve by `--prefer` (default Figma) and continue, logging each resolution.
   - Interactive → present a single `AskUserQuestion` with up to 5 representative conflicts and ask: (1) keep Figma everywhere, (2) keep md everywhere, (3) abort. Selection is sticky for the rest of the run.

### Step 3: Generate Outputs

Branch by `--output`:

#### 3a. Output = `md` or `both` — Markdown + JSON Generation

1. Render `_meta/templates/screens.template.md` populated from `screensInput`. Apply ID 10-increment (SC-010, SC-020, …); preserve any pre-existing IDs from md source.
2. Emit `docs/{app}/design/screens.md` and `docs/{app}/design/screens.json` (doc-companion schema, `phase: "design"`, `subPhase: "uidesign"`, `status: "Draft"`).
3. For each screen with a Figma counterpart, set `figmaUrl` (deep link) on the JSON item and prepend `> Figma: <url>` in the md item.
4. Update `data/links.json` with `derives` edges from `screensInput.source` → screen item nodes.

> **Conflict with `/u-design`:** If `docs/{app}/design/screens.json` already exists with `status: "Final"`, do NOT overwrite. Instead, write to `docs/{app}/design/screens.proposal.{md,json}` and emit a diff summary; ask the user to merge via `/u-design --apply-proposal screens` when ready.

#### 3b. Output = `figma` or `both` — Figma Frame Generation

1. Load **MANDATORY** prerequisite skills before any Figma write:
   - `figma:figma-use` (always)
   - `figma:figma-generate-design` (this run)
2. Hand off to `figma:figma-generate-design` with the following bundle:
   ```
   {
     targetFile: <figma-url-or-fileKey>,
     sectionPlan: screensInput.screens.map(s => ({
       name: s.name,
       route: s.route,
       components: s.components,  // resolved against dsInput
       states: s.states,
       annotations: { businessProcess: s.businessProcess, validations: s.validations }
     })),
     dsHints: dsInput,  // so the delegated skill skips re-discovery
     skillNames: "u-tools-figma-screen"   // for telemetry
   }
   ```
3. After the delegated skill returns, capture per-screen `figmaNodeId` and deep-link URL; write back into `screensInput[*].figmaUrl` so subsequent `--output md` re-runs can re-emit traceability.
4. Update `data/figma/manifest.json` with the generated frame hashes (so `/u-tools-figma --verify` recognises them as up-to-date downstream).

#### 3c. Output = `both`

Run 3a first (md is faster, idempotent), then 3b (Figma can take 5–30 min). Halt on 3a errors before touching Figma.

### Step 4: Visual Verification (only when `--output` includes `figma`)

Delegate to `/u-tools-browser` (Step 6c — Visual Verify) with the generated Figma frames and the just-written `screens.json`. Records mismatches under `.u-maker/.state/visual-verify/{app}-{screen}.json`.

### Step 5: Summary Output

```markdown
## u-tools-figma-screen Run Summary

**App:** {app}
**Screens Source:** {figma|md|both} — {url-or-path}
**DS Source:** {figma|md|code|both} — {url-or-path}
**Output:** {figma|md|both}
**Prefer:** {figma|md}

### Generated
| Screen | md | json | Figma frame | Visual diff |
|--------|----|------|-------------|-------------|
| SC-010 — Login | yes | yes | https://… | clean |
| SC-020 — Dashboard | yes | yes | https://… | 2 mismatches → todo |

### Coverage Gaps: {n}
- DS missing component `Card.Compact` referenced by SC-040

### Conflicts Resolved: {n}
- SC-020 component list — kept Figma (per `--prefer figma`)

### Result: {PASS | PARTIAL | FAIL}
```

The calling phase skill (e.g., `/u-plan` Step 2.5, `/u-design` Step 4.5) consumes this summary, not the raw delegated output.

## Consumer Integration Table

| Caller Skill | Trigger | Default `--output` | Notes |
|--------------|---------|-------------------|-------|
| `/u-plan` Step 2.5 | screens source + DS source detected after IA generation | `md` | Pre-populates `screens.{md,json}` so `/u-design` Step 3 can verify-and-finalise instead of generate-from-scratch |
| `/u-analyze` Step 2 (delegation) | Figma `screen-planning` digest with attached DS link | `md` | Same pre-population path; runs as part of analysis loop |
| `/u-design` Step 4.5 (new) | After DS doc is final, user asked for Figma sync | `figma` | Mirrors finalised md back into Figma; uses `--prefer md` |
| `/u-build` orchestrator | When ping-pong gap requires Figma update | `both` | Forced `--prefer md` so dev-validated md wins |

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--app {name}` | required | App scope under `docs/{app}/` and `apps/{app}/` |
| `--screen-source {url|path|auto}` | `auto` | Override source discovery for screen plan |
| `--ds-source {url|path|auto}` | `auto` | Override source discovery for design system |
| `--output {figma|md|both}` | `both` | Which artifact(s) to emit |
| `--prefer {figma|md}` | `figma` | Conflict resolution when both sources present |
| `--screen {SC-ID|all}` | `all` | Limit to a subset of screens |
| `--loop` | OFF | Gate generated artifacts via `u-agent-gatekeeper`; retry up to `loopMaxRetries` if score < pass threshold |
| `--auto` | OFF | Skip interactive prompts; resolve conflicts via `--prefer` |
| `--dry-run` | OFF | Print the plan and conflict report without writing |

## Anti-patterns

- ❌ Phase skill calling `mcp__plugin_figma_figma__use_figma` directly
- ❌ Phase skill calling `figma:figma-generate-design` directly (bypasses source resolution + manifest tracking)
- ❌ Overwriting `docs/{app}/design/screens.json` when its `status: "Final"` (use `screens.proposal.*` instead)
- ❌ Running `--output figma` without first refreshing a stale `data/figma/manifest.json`
- ✅ Load `u-tools-figma-screen`, follow Steps 0→5, consume the summary

## Error Handling

| Condition | Action |
|-----------|--------|
| `figma` plugin not installed | HALT with install instructions OR fall back to `--output md` only |
| Figma authentication missing | Ask user to run `mcp__plugin_figma_figma__authenticate`, then retry Step 0 |
| Stale Figma manifest | Auto-delegate to `/u-tools-figma --verify`, then retry Step 1 |
| Both sources missing | HALT (per Mandatory pre-flight #1) |
| Coverage gap (DS missing component) | Continue with placeholder, append to `todos.json` priority p2 |
| Conflict count > 20 | Force interactive prompt even in `--auto` mode |
| Delegated `figma-generate-design` fails mid-frame | Capture screenshot via `/u-tools-browser`, append to errors, ask user to retry / skip |

## Reference Files

- **`references/source-resolution.md`** — Detailed discovery rules per source type (Figma URL parsing, md/json schema validation, code path inference)
- **`references/conflict-resolution.md`** — Field-by-field conflict matrix and resolution strategies (auto vs interactive)
- **`references/delegation-bundle.md`** — Exact JSON payload contract for `figma:figma-generate-design`
- **`../u-design/references/screen-spec.md`** — Component taxonomy and validation rules (shared with `/u-design`)
- **`../u-design/references/design-system-rules.md`** — DS rule pack applied to component bindings (shared)
- **`../u-tools-figma/references/integration.md`** — Manifest hash protocol (shared with the analyzer)

## Related Commands

- `/u-tools-figma` — Read-side comprehensive Figma analyzer (siblings)
- `/u-tools-figma-ds` — Generate Figma design system from source code (siblings)
- `/u-design` — Owns `docs/{app}/design/screens.{md,json}` final state; this skill pre-populates / mirrors it
- `/u-wireframe` — Downstream consumer of the generated screens for HTML wireframe rendering
- `/u-tools-browser` — Visual verification engine used in Step 4
