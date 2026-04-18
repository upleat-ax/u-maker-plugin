---
name: u-prepare
description: "This skill should be used when the user asks to 'prepare', 'start', 'initialize + ingest', 'set up project for u-maker', '/u-prepare', or '/u-init' (alias). Umbrella for the Preparation sub-phase: foldertree init + dropzone ingest + analysis (u-analyze) or reverse-engineering (u-reverse) + 요구사항 협의."
version: 4.0.0
triggers:
  - "/u-prepare"
  - "/u-init"
  - "prepare project"
  - "start project"
  - "initialize u-maker"
---

# u-prepare — Preparation Umbrella (PBGD Plan.Prepare)

`/u-prepare [--app {name}] [--loop] [--scenario {A|B1|B2}] [--migrate]`

Preparation-phase umbrella. Sets up `.u-maker/`, ingests raw source material into `data/dropzone/`, analyzes it into `data/digest/`, optionally reverse-engineers an existing codebase, and runs a 요구사항 협의 (requirements clarification) pass with the user. After `/u-prepare`, the project is ready for `/u-plan` (SRS + IA generation).

**Primary Agent:** u-agent-plan (Preparation responsibility)
**Engine Dependencies:** doc-engine, digest-engine, dep-engine
**PBGD Phase:** Plan.Prepare (umbrella)
**Aliased by:** `/u-init`

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--app {name}` | No | App scope. If omitted, ask user (single-app projects auto-select). Positional `app-name` also accepted. |
| `--loop` | No | Loop mode: after analysis, gatekeeper-scores the digest (coverage / completeness) and re-runs clarification / analysis up to `loopMaxRetries` if below threshold. |
| `--scenario {A\|B1\|B2}` | No | Force a specific Preparation scenario. If omitted → auto-detect. |
| `--migrate` | No | Pass through to `/u-prepare-foldertree` for legacy migration |

## Scenarios

`/u-prepare` supports three scenarios. See `references/scenario-decision.md` for auto-detection heuristics.

| Scenario | Project state | Flow |
|----------|---------------|------|
| **A** — New project | Empty dir, no source code, no `.u-maker/` | foldertree → dropzone ingest → `/u-analyze` → 요구사항 협의 |
| **B1** — Existing project + dropzone | Source code present, user has supplementary docs/links | foldertree → dropzone ingest (including links to code) → `/u-analyze` → 요구사항 협의 |
| **B2** — Existing project + reverse | Source code present, no supplementary docs available | foldertree → `/u-reverse` (reverse-engineers code into digest) → 요구사항 협의 |

When scenario is ambiguous (e.g., existing code present but user wants to skip reverse), `/u-prepare` prompts the user to choose.

## Execution Flow

### Step 1: Foldertree

Invoke `/u-prepare-foldertree [app-name] [--migrate]`. On success, `.u-maker/` is scaffolded or migrated. On failure, abort with a clear error.

### Step 2: Scenario detection

1. Check if `data/dropzone/` contains any files.
2. Check if the project root (parent of `.u-maker/`) contains source code (package.json / pom.xml / go.mod / Cargo.toml / pyproject.toml / etc.).
3. Apply decision matrix from `references/scenario-decision.md`:
   - no source + no dropzone → **A** (prompt user to add files/links; wait)
   - source + dropzone → **B1**
   - source + no dropzone → prompt user: "B1 (add files first)" vs "B2 (reverse-engineer now)"
   - no source + dropzone → **A** (proceed)
4. `--scenario` arg overrides auto-detection.

### Step 3: Dropzone ingestion (scenarios A, B1)

1. Prompt the user to drop files, paste links, or attach Figma URLs into `data/dropzone/`.
2. For URL/link inputs → create a `.figma-link` or `.url` descriptor file in `data/dropzone/links/`.
3. Wait for user confirmation ("done adding").

### Step 4: Analysis dispatch

- Scenario A or B1 → invoke `/u-analyze [--app {name}]`.
- Scenario B2 → invoke `/u-reverse [--app {name}]` (which writes digest-equivalent output into `data/digest/`).

**Auto-delegation to `/u-figma`:** If the dropzone (or the `--figma` arg on reverse) references any Figma source (`.figma-link`, `.figma-make-link`, `figma.com` URL), delegate that source's analysis to `/u-figma --app {app}` *before* completing Step 4. `/u-figma` runs the comprehensive 6-phase pipeline (scan → gate → extract → verify → aggregate → sync) across every page, variant, asset, component, and comment of the file — never a partial scan. See `skills/u-figma/references/integration.md` for the delegation contract.

On completion, `data/digest/` (including `data/digest/figma/…`) contains structured analysis results.

### Step 5: 요구사항 협의 (Requirements clarification)

1. Scan the generated digest for common gaps using these heuristics:
   - No non-functional requirements detected → ask about performance / availability / security
   - No stakeholders with decision authority → ask who approves scope
   - Conflicting requirements in `_conflicts.json` → walk through each with the user
   - Pain points with no corresponding requirement → ask whether to add one
   - Ambiguous priorities (Must vs Should) → confirm
2. Record the Q&A pairs into `data/digest/_clarifications.json` so `/u-plan` can cite them as additional source material.
3. Skip this step if `--auto` was passed; only generate a gap report instead.

### Step 6: Summary

```
Preparation complete.
  App:         {app-name}
  Scenario:    {A|B1|B2}
  Digest:      {N} files / {M} items extracted
  Clarifications: {K} Q&A pairs
  Next:        Run /u-plan --app {app-name} to generate SRS + IA
```

## Preconditions

- Write access to the project root.
- For scenario B2, project root must contain recognizable source code.

## Postconditions

- `.u-maker/` exists and is v4-compliant.
- `data/digest/` is populated (at least one digest file).
- `data/digest/_index.json` has no `pending` or `processing` entries.
- `data/digest/_clarifications.json` exists (possibly empty).
- `data/links.json` has at least one `digest` node per source.

## Reference Files

- **`references/scenario-new-project.md`** — Scenario A flow details.
- **`references/scenario-existing-project.md`** — Scenarios B1 & B2 flow details.
- **`references/dropzone-ingest.md`** — File/link intake rules, accepted types, link descriptor formats.
- **`references/scenario-decision.md`** — Auto-detection heuristics and user-override prompt wording.

## Related Commands

- `/u-prepare-foldertree` — Granular foldertree/state scaffolding only (Step 1 alone).
- `/u-analyze` — Standalone dropzone → digest analysis (Step 4 for scenarios A/B1).
- `/u-reverse` — Reverse-engineer existing code → digest (Step 4 for scenario B2).
- `/u-plan` — Next command in the PBGD pipeline (Plan.Plan sub-phase).
