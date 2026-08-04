---
name: u-tools-figma-ds
description: "Generate a Figma design system (Variables, styles, master components) from existing DS-applied source code (.tsx + .json + .css). Use when the user asks to '/u-tools-figma-ds', 'code to figma ds', 'design system to figma', 'figma 디자인시스템 생성', 'DS to Figma', 'tokens to Figma', '코드에서 피그마 DS', '디자인시스템 피그마 동기화', or '피그마 변수 생성'. Auto-delegated from /u-analyze when DS source code is detected, and from /u-design Step 4.5 for outbound sync. Delegates Figma writes to figma:figma-generate-library; never calls use_figma directly."
version: 1.0.0
---

# u-tools-figma-ds — Code → Figma Design System Generator

`/u-tools-figma-ds [--app {name}] [--source {path|auto}] [--target-figma {url}] [--mode foundations|components|both] [--theme light|dark|both] [--loop]`

External-tool wrapper that produces a **new** Figma design system (Variable collections + token modes + Paint/Text/Effect styles + master components and variants) from existing DS-applied source code (`.tsx`, `.json`, `.css`). The write-side counterpart to the read-only DS-extraction work that `/u-tools-figma` performs against an existing Figma DS.

**Primary Agent:** u-agent-design (consumer); orchestrated by u-agent-pm
**Engine Dependencies:** doc-engine, dep-engine
**External skills delegated to:** `figma:figma-generate-library` (the heavy lifting), `figma:figma-use` (mandatory prerequisite)
**PBGD Phase:** Plan.Prepare (auto-invoked from `/u-analyze`) and Build.UIDesign (manual / `/u-design` Step 4.5)
**Parent invokers:** `/u-analyze` (when DS code detected), `/u-design` (after `design-system.{md,json,html}` is Final), standalone

## Use Figma DS Writes Only Through This Engine

All u-maker phase skills MUST call `/u-tools-figma-ds` instead of invoking `figma:figma-generate-library` or `mcp__plugin_figma_figma__use_figma` directly. Centralising it here keeps:

- **Source extraction** consistent (token / component discovery rules apply once)
- **Variable / mode taxonomy** consistent (light + dark mode handled the same way every time)
- **Manifest tracking** consistent — `data/figma/manifest.json` records which Figma file holds which DS version
- **Doc traceability** identical (`figmaUrl` propagated back into `design-system.json`)
- **Rule pack** loaded once (`skills/u-design/references/design-system-rules.md` enforces 3-layer tokens / 10 scales / dark-mode / contrast / focus / ARIA / compound components)

If the platform offers multiple Figma DS write paths, always pick **`figma:figma-generate-library`** (delegation). Never call `mcp__plugin_figma_figma__use_figma` directly from u-maker phase skills.

## Source Discovery

The skill expects DS-applied source to live under one of (auto-discovery order):

| Tier | Path | What gets extracted |
|------|------|---------------------|
| 1 | `--source <path>` (explicit) | Whatever the path resolves to (file or directory) |
| 2 | `packages/tokens/src/**/*.{json,css}` | Primitive + semantic tokens (W3C tokens spec preferred; falls back to Style Dictionary, then to raw CSS custom properties prefixed `--ds-` / `--token-` / `--brand-`) |
| 3 | `packages/ui-*/src/components/**/*.tsx` | Component shapes (props from TS types, variants from `cva()`, `tv()`, or discriminated unions; sub-parts from compound-component naming `Component.Trigger` / `Component.Content`) |
| 4 | `packages/ui-*/src/components/**/*.css` | Component-level styles (resolved against Tier 2 tokens) |
| 5 | `apps/*/src/styles/tokens.css` + `apps/*/src/components/ui/**/*.tsx` (next-forge / shadcn layout) | App-local token + component overrides |

If neither Tier 2 nor any of Tiers 3–5 returns at least one token AND one component → HALT:
> "u-tools-figma-ds needs a token source and a component source. Provide via `--source` or place DS code under `packages/tokens` and `packages/ui-*`."

## Workflow

### Step 0: Verify Tool Availability

1. Confirm `figma:figma-generate-library` is reachable. If absent → HALT:
   > "`figma` plugin is not installed. Install it (`/plugin install figma`) before running `/u-tools-figma-ds`."
2. Confirm `figma:figma-use` is reachable.
3. Confirm an authenticated Figma session exists (`mcp__plugin_figma_figma__authenticate`). If missing → ask user to authenticate, then retry.
4. Resolve `--target-figma`:
   - If provided → parse `fileKey` and treat as the destination.
   - Else look up `data/figma/manifest.json` → `dsFileKey` field. If missing → ask the user for a Figma URL via `AskUserQuestion`. Offer "create a new file" only if `figma:figma-use` exposes that capability; otherwise provide instructions for the user to create one and rerun.

### Step 1: Extract Tokens

1. Walk Tier-2 sources first. For each token file:
   - **W3C tokens spec** (`.tokens.json` with `$value` / `$type`): keep as-is.
   - **Style Dictionary** (`.tokens.json` without `$value`): convert to W3C shape on the fly.
   - **CSS custom properties**: parse, group by prefix, classify by name (`--color-*`, `--space-*`, `--radius-*`, `--shadow-*`, `--font-*`, `--motion-*`, `--bp-*`, `--z-*`).
2. Apply the **3-layer architecture** required by `design-system-rules.md` §1:
   - **Primitive layer** — raw values (colors, sizes), 1 mode.
   - **Semantic layer** — aliased to primitives; mode-aware (`light`, `dark`).
   - **Component layer** — aliased to semantic; per-component overrides.
3. Apply **10 scales** required by `design-system-rules.md` §2 (color OKLCH 50–950, spacing 0–96, type, shadow, radius, breakpoints, motion, z-index, responsive type via `clamp()`).
4. If `--theme` is `light` or `dark`, emit only that mode's overrides on semantic tokens. If `both` (default), emit both modes; primitives get one mode.
5. Persist the normalised token tree to `.u-maker/.state/figma-ds-tokens.{runId}.json` for hand-off.

### Step 2: Extract Components

1. Walk Tier-3 sources. For each component:
   - Extract props from TS types (use `ts-morph` or a regex fallback) — record name, type (`TEXT` | `BOOLEAN` | `INSTANCE_SWAP`), default.
   - Extract variants from `cva()`, `tv()`, or discriminated-union props — record axis name + values.
   - Detect compound components by naming pattern `<Root>.<Sub>` exported from the same file — group into a single Figma component-set with sub-part variants.
2. Resolve token references inside the component CSS / Tailwind classes back to semantic tokens (Step 1.2). Hardcoded values get logged as `unresolvedBindings[]`.
3. Order components for build by dependency (atoms first, then molecules, then organisms). Use `figma-generate-library` Phase-3's component-order rule.
4. Persist to `.u-maker/.state/figma-ds-components.{runId}.json`.

### Step 3: Build Delegation Bundle

Hand off to `figma:figma-generate-library` with:

```ts
{
  targetFile: { fileKey, pageStrategy: "create-or-reuse" },
  phases: ["foundations", "components"],   // narrowed by --mode
  themes: ["light", "dark"],                // narrowed by --theme
  tokens: <Step 1 normalised tree>,
  components: <Step 2 ordered list>,
  rulePackVersion: "design-system-rules.md@v4.0",
  skillNames: "u-tools-figma-ds",
  options: {
    runId,
    askBeforeEachComponent: !auto,           // matches figma-generate-library Phase 3 checkpoint
    overwriteExistingPages: false
  }
}
```

The bundle contract is documented in `references/delegation-bundle.md`.

### Step 4: Sync Back to Doc Layer

After the plugin returns:

1. For each generated component, capture `figmaKey` and write into `docs/{app}/design/design-system.json` `components[*].figmaKey`.
2. Capture the destination Figma URL into `data/figma/manifest.json` `dsFileKey` + `dsFileUrl`.
3. Re-render the live design-system HTML (`out/{app}/design/design-system.html`) so the `> Figma: <url>` header reflects the new file.
4. Update `data/links.json` with `derives` edges from source-code nodes (`.tsx` / `.css`) → DS item nodes → Figma node IDs.

### Step 5: Visual Spot-check (optional)

If `figma:figma-generate-library` returned per-component screenshots, render them into a single HTML report at `.u-maker/.state/ds-build-report-{runId}.html` for the user to scan.

### Step 6: Summary Output

```markdown
## u-tools-figma-ds Run Summary

**App:** {app}
**Source:** {tier-N path or explicit}
**Target Figma:** {url}
**Mode:** {foundations | components | both}
**Theme:** {light | dark | both}

### Foundations
- Variable collections: {n}
- Variables (primitive / semantic / component): {a / b / c}
- Effect styles: {n}
- Text styles: {n}

### Components
| Component | Variants | Props | Bindings resolved | figmaKey |
|-----------|---------:|------:|------------------:|----------|
| Button | 12 | 3 | 100% | abc:001 |
| Card | 3 | 2 | 75% | abc:002 |

### Unresolved Bindings: {n}
- `Card` — `padding: 12px` not in spacing scale (closest: `space.3` = 12px) — auto-bound

### Result: {PASS | PARTIAL | FAIL}
```

## Consumer Integration Table

| Caller Skill | Trigger | Default `--mode` | Default `--theme` | Notes |
|--------------|---------|------------------|-------------------|-------|
| `/u-analyze` Step 2 | DS source code detected in dropzone or `packages/` | `both` | `both` | Runs as part of analysis loop; emits new Figma DS file when none exists |
| `/u-design` Step 4.5 | After `design-system.{md,json,html}` is Final and user opted in | `both` | `both` | Mirrors finalised doc DS into Figma; uses existing `dsFileKey` |
| Standalone | Direct user invocation | `both` | `both` | Useful for one-off DS bootstrap |

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--app {name}` | required | Scopes source discovery and doc updates |
| `--source {path|auto}` | `auto` | Override source discovery |
| `--target-figma {url}` | `auto` | Destination Figma file; defaults to `manifest.dsFileKey` |
| `--mode {foundations|components|both}` | `both` | Limit which phase of the build runs |
| `--theme {light|dark|both}` | `both` | Token modes to emit |
| `--loop` | OFF | Gate via `u-agent-gatekeeper`; retry up to `loopMaxRetries` |
| `--auto` | OFF | Skip per-component checkpoint prompts |
| `--dry-run` | OFF | Print the plan and bundle preview without writing |

## Anti-patterns

- ❌ Phase skill calling `mcp__plugin_figma_figma__use_figma` directly
- ❌ Phase skill calling `figma:figma-generate-library` directly (bypasses source extraction + manifest tracking)
- ❌ Skipping `figma:figma-use` prerequisite when issuing the bundle (the figma plugin will reject the call)
- ❌ Running with hardcoded values in CSS without first surfacing them in `unresolvedBindings[]`
- ❌ Overwriting an existing Figma DS file without `--overwrite` (data loss risk)
- ✅ Load `u-tools-figma-ds`, follow Steps 0→6, consume the summary

## Error Handling

| Condition | Action |
|-----------|--------|
| `figma` plugin not installed | HALT with install instructions |
| Figma authentication missing | Ask user to authenticate, retry Step 0 |
| Tier 2 + Tiers 3–5 yield zero tokens or zero components | HALT (per Source Discovery) |
| Token file fails W3C / Style Dictionary parse | Log to `unresolvedBindings[]`, continue with the parsable subset |
| Plugin returns `ok: false` for a component | Add to `todos.json` p1, continue with remaining components |
| Plugin returns coverage warning (`unresolved: > 20%`) | Force user prompt: continue / abort / edit DS first |
| Existing Figma DS detected in target file without `--overwrite` | Ask user: (a) merge, (b) abort, (c) overwrite (with confirm) |

## Reference Files

- **`references/token-extraction.md`** — Per-format extraction rules (W3C tokens, Style Dictionary, CSS custom properties, Tailwind config) and the normalisation contract
- **`references/component-extraction.md`** — TypeScript prop / variant detection (cva, tv, discriminated unions, compound components) and dependency ordering
- **`references/delegation-bundle.md`** — Exact JSON contract for `figma:figma-generate-library`
- **`../u-design/references/design-system-rules.md`** — Mandatory rule pack (3-layer tokens, 10 scales, dark-mode, contrast, focus, ARIA, compound components)
- **`../u-design/references/design-system-spec.md`** — Doc-side spec consumed for round-tripping

## Related Commands

- `/u-tools-figma` — Read-side analyzer (extracts existing Figma DS into `data/figma/aggregate.json`)
- `/u-tools-figma-screen` — Sibling skill: generates screen plans (in Figma and/or md+json)
- `/u-design` Step 4 — Owns `docs/{app}/design/design-system.{md,json,html}`; this skill mirrors it into Figma
- `/u-analyze` — Auto-invokes this skill when DS code is detected in dropzone
