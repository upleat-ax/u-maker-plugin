---
name: u-analyze
description: "This skill should be used when the user asks to '/u-analyze', 'analyze dropzone', 'generate digest', 'rescan', 'u-maker 분석', '드롭존 분석', '다이제스트 생성', '데이터 재스캔', or wants to convert raw files/links in data/dropzone/ into structured digest JSONs under data/digest/."
version: 4.0.0
---

# u-analyze — Dropzone Analysis (Digest Generation)

`/u-analyze [--app {name}] [--loop] [--force]`

Analyze raw files/links in `data/dropzone/` and produce structured digest JSONs under `data/digest/`. This is the analysis sub-step of the Preparation sub-phase in the PBGD workflow (v4.0). Downstream skills (`/u-plan`, `/u-build`) consume `data/digest/` as their authoritative input.

**Primary Agent:** u-agent-plan (Preparation responsibility)
**Engine Dependencies:** digest-engine, dep-engine
**PBGD Phase:** Plan.Prepare (analysis sub-step)
**Parent umbrella:** `/u-prepare`

> **Migration note:** In v3.x this logic lived as Steps 1–2 of `/u-plan`. In v4.0 (PBGD) it is extracted into this discrete skill so Preparation can be reasoned about separately from Plan (SRS/IA generation).

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--app {name}` | No | Filter to a specific app's dropzone sub-path |
| `--loop` | No | After analysis, gatekeeper-scores digest coverage/completeness; re-runs extraction with improvement list up to `loopMaxRetries` if below `passThreshold` (95). |
| `--force` | No | Re-analyze all files even if hashes match (bypass incremental mode) |

## Execution Flow

### Step 1: Scan Dropzone

1. Scan `data/dropzone/` recursively for all files and `.figma-link` entries.
2. Compute SHA-256 hash per file (composite hash for >100 MB: SHA-256 of first 1 MB + size + mtime).
3. Load `data/digest/_index.json`; if missing, create it.
4. Compare each scanned hash against the stored hash:
   - Not present → mark `pending` (new file).
   - Hash differs → mark `pending` (changed file; old digest queued for overwrite).
   - Hash matches → skip.
5. If no pending entries and `--force` is not set → print "No changes" and exit successfully.

### Step 2: Generate Digest

For each `pending` or `error` entry:

1. Set `_index.json` status to `processing` (crash-recovery marker).
2. Read source file from `data/dropzone/{path}`.
3. **Figma delegation:** if the file is a `.figma-link`, `.figma-make-link`, or its content is a `figma.com` URL, **delegate to `/u-tools-figma --app {app}`** and skip the remaining steps for this entry. `/u-tools-figma` handles the comprehensive analysis (pages + variants + assets + components + comments + semantic extraction) and writes outputs to `data/digest/figma/…` and `data/figma/…`. On return, mark the original entry in `_index.json` with `status: "delegated"` and `digestPath: "figma://{fileKey}"`. See `skills/u-tools-figma/references/integration.md`.
4. **DS-code delegation:** if the file (or directory referenced by a `.ds-source-link` pointer file) is a DS-applied source bundle — detected by any of:
   - A `.ds-source-link` pointer file containing a path to `packages/tokens/` and/or `packages/ui-*/`
   - A `package.json` whose name matches `*tokens*`, `*design-system*`, `*ui-kit*`, or whose `keywords` includes `design-system`
   - A directory dropped under `data/dropzone/ds/` containing any combination of `.tokens.json`, `tailwind.config.{js,ts}`, `globals.css` with `--token-`/`--ds-` prefixes, plus at least one `.tsx` component
   
   then **delegate to `/u-tools-figma-ds --app {app} --source <resolved-path>`**. The skill extracts tokens + components and pushes a new (or updated) Figma DS file. On return:
   - Mark the original entry in `_index.json` with `status: "delegated"` and `digestPath: "figma-ds://{fileKey}"`.
   - Capture the resulting `dsFileKey` into `data/figma/manifest.json` so subsequent `/u-tools-figma-screen` and `/u-design` runs find the DS automatically.
   - If the user has not authenticated against Figma yet, fall back to `--dry-run` and persist the bundle under `.u-maker/.state/figma-ds-bundles/{runId}.json` for later replay; mark `_index.json` status as `"deferred"` (not `error`).
   
   See `skills/u-tools-figma-ds/SKILL.md`.
5. Otherwise, apply type-specific extraction strategy (see `references/digest-extraction.md`).
6. Extract: requirements, constraints, stakeholders, domain terms, workflows, pain points.
7. Write `data/digest/{mirror-path}/{filename}.digest.json` conforming to `_meta/schemas/digest.schema.json`.
8. Update `_index.json`: status=`done`, `analyzedAt`=ISO-8601 now, `digestPath`=relative path, `hash`=computed SHA-256.
9. On failure → status=`error` with `error` field; continue to next file.

> **Plain language (HARD RULE):** All explanatory prose in digest outputs (summaries, descriptions, rationale fields) is written so a middle-school student understands it on first read — rule source: `skills/u-engine/references/doc-engine.md` § 8 / `html-engine.md` § 0.6, enforced by the GK-06 `plain-language-middle-school` check. Structured extraction detail (requirements, constraints, domain rules, IDs, values) is never reduced — only the wording gets simpler.

### Step 3: Aggregate (light)

1. After all per-file digests are written, optionally emit a lightweight aggregate summary (counts by source type, keywords frequency) into `data/digest/_summary.json`. This is advisory — `/u-plan` re-aggregates at SRS time.

### Step 4: Update Links

1. For each new/changed digest, register a `digest` node in `data/links.json` with `phase: "plan"`.
2. Do not create edges yet — downstream skills (`/u-plan`) create the `derives` edges when they consume the digest.

## Preconditions

- `.u-maker/` folder tree must exist. If not → error with instruction to run `/u-prepare-foldertree` (or `/u-prepare`) first.
- `data/dropzone/` must contain at least one file. If empty → warn and exit.

## Postconditions

- Every file under `data/dropzone/` has an entry in `data/digest/_index.json` (status ∈ {done, skipped, error, removed}).
- Every `done` entry has a corresponding digest JSON file.
- `data/links.json` contains a `digest` node for each new/changed digest.

## Reference Files

- **`references/digest-extraction.md`** — Per-file-type extraction strategies (md, pdf, docx, xlsx/csv, images, plain text, Figma links, unsupported types), chunking, hash-based change detection, `_index.json` lifecycle.
- **`references/analysis-rules.md`** — Requirement/constraint/stakeholder/domain-term extraction rules and aggregation conflict resolution.

## Related Commands

- `/u-prepare` — umbrella that orchestrates foldertree + dropzone ingestion + this skill (or `/u-reverse`).
- `/u-reverse` — alternative analysis path for existing projects (reverse-engineers code → digest).
- `/u-tools-figma` — auto-delegated for Figma sources (Step 2.3).
- `/u-tools-figma-ds` — auto-delegated for DS-applied source code bundles (Step 2.4).
- `/u-plan` — consumes `data/digest/` to produce SRS + IA; also auto-delegates to `/u-tools-figma-screen` in its Step 2.5.
