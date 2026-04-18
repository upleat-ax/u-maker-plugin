---
name: u-figma
description: "Comprehensive Figma analyzer. Use when the user mentions 'figma', shares a figma.com URL, asks to 'analyze figma', 'extract figma', '/u-figma'. Also auto-delegated from /u-prepare, /u-analyze, /u-reverse when any Figma source is detected. Covers every page, every variant, every asset, every component, and every comment — never a partial scan."
version: 4.0.0
triggers:
  - "/u-figma"
  - "figma"
  - "figma.com"
  - "analyze figma"
  - "extract figma"
---

# u-figma — Comprehensive Figma Analyzer

`/u-figma [--app {name}] [--loop] [--file-key {key}] [--url {figma-url}] [--page {pageId|all}] [--include-fig-jam] [--refresh-comments] [--verify]`

Comprehensive Figma analysis pipeline. Unconditionally scans **every page**, **every variant** (component-set / naming / positional / suffix), **every asset**, **every component**, and **every comment** (3-tier: sticky notes in-canvas → Figma REST comments → inline review threads). Extracts semantic content required by downstream PBGD phases: input validation rules, value policies, initial values, button actions, layout, screen-to-screen flow, data model hints, user/role/permission rules.

**Primary Agent:** u-agent-figma
**Engine Dependencies:** digest-engine, doc-engine, dep-engine
**PBGD Phase:** Plan.Prepare (analysis sub-step; co-equal with `/u-analyze` for Figma sources)
**Parent umbrella:** `/u-prepare` (auto-delegation) — also callable standalone
**Authoritative spec:** `skills/u-plan/references/figma-analysis.md` (PART I + PART II, ~1000 lines)

## Scope — non-negotiable

Every `/u-figma` run must cover the following for every referenced Figma file:

### Surfaces (exhaustive)

| Surface | Coverage rule |
|---------|--------------|
| Pages | Every page in the file, not just the landing page |
| Variants | Variant-exhaustive: union of (a) component-set properties, (b) naming patterns (`Name/Variant-A`), (c) positional clusters (adjacent frames sharing name prefix), (d) suffix conventions (`-default`, `-hover`, `-active`, `-disabled`) |
| Assets | Icons, logos, illustrations, exports — cataloged with filename + format + dimensions |
| Components | Master components and instances; properties + variant map + variant usages |
| Comments | 3-tier fallback: (1) in-canvas sticky notes, (2) Figma REST `comments` API, (3) inline review threads. Dedupe by author+body+anchorNode. |

### Semantic extraction (per frame)

All of these must be produced when the frame content supports them:

| Category | What to extract | Output digest field |
|----------|-----------------|---------------------|
| Input validation | Format / range / required / required-if / cross-field rules | `validationRules[]` |
| Value policies | Allowed values, state systems, code classifications | `domainRules[]` (type=state-system/classification/code-system) |
| Initial values | Defaults, auto-fill sources, master-data references | `dataRules[]` (type=default-value/auto-fill/reference/master-data) |
| Button actions | What each CTA triggers — navigation targets, API calls, modal opens, state transitions | `uiSpecifications[]` + `processingRules[]` |
| Layout | Inferred from node position, size, grouping, auto-layout settings | `screenDescriptions[].components[]` |
| Screen flow | Prototype reactions + named links in annotations | `crossRefs[]` + dedicated flow JSON |
| Data model | Entity fields, labels, implied relationships, FK hints | `businessRules[]` + `domainRules[]` |
| Users / roles / permissions | Role-tagged frames, RBAC annotations, permission matrices in tables | `permissionRules[]` |

## Execution Flow (6-phase pipeline)

Implementing agent (`u-agent-figma`) runs:

1. **Scan** — enumerate pages, frames, components, assets. Build a target list.
2. **Gate** — consult `manifest.json` to skip frames whose canonical node-tree hash is unchanged.
3. **Extract** — for each pending frame, run:
   - node-tree walk (via Figma MCP `get_design_context` / `get_node`),
   - variant detection (union of four sources),
   - density-aware chunking for dense frames,
   - comment merge across 3 tiers,
   - Figma-content-type classification (screen-design / screen-planning / diagram / annotation / specification / design-tokens / assets / prototype),
   - semantic extraction per the table above.
4. **Verify** — validate each digest against `digest.schema.json` + `figmaMeta` required fields; compute `coverageWarnings`.
5. **Aggregate** — roll per-frame digests into `aggregate.json` for downstream consumption.
6. **Sync** — write / update `manifest.json` (coverage ledger) and `data/links.json` (digest nodes + `derives` edges).

Per `references/pipeline.md` (and the plan doc §10 / figma-analysis.md PART II §10).

## Persistence (nothing is discarded)

Both raw material and analysis outputs are written under `.u-maker/data/`:

```
.u-maker/data/
├── figma/
│   ├── raw/{file-key}/
│   │   ├── metadata.json               # file name, pages, thumbnail
│   │   ├── pages/{page-id}.nodes.json  # full node tree per page
│   │   ├── components.json             # component-set catalog
│   │   ├── variables.json              # design-tokens
│   │   ├── comments.json               # merged 3-tier comments
│   │   ├── prototype-reactions.json    # flow edges
│   │   └── screenshots/*.png
│   ├── manifest.json                   # coverage ledger (schema below)
│   └── aggregate.json                  # rollup for downstream
├── digest/
│   └── figma/{file-key}/
│       └── {page-slug}/{frame-slug}.digest.json    # per-frame digest
└── links.json                          # updated with digest nodes + edges
```

`manifest.json` schema defined in `_meta/schemas/figma-manifest.schema.json` (see implementation plan).

## Arguments

| Argument | Description |
|----------|-------------|
| `--app {name}` | App scope |
| `--loop` | After analysis, gatekeeper-scores `coverageWarnings[]` + digest completeness; re-runs extraction on weak frames up to `loopMaxRetries` |
| `--file-key {key}` | Target a specific Figma file by key |
| `--url {figma-url}` | Target by URL (fileKey + nodeId parsed automatically) |
| `--page {pageId\|all}` | Scope to one page or `all` (default: `all`) |
| `--include-fig-jam` | Also ingest any referenced FigJam boards via `get_figjam` |
| `--refresh-comments` | Force a fresh `comments` API pull even if frames are cached |
| `--verify` | Re-run Phase 4 (verify) against the existing manifest without re-extracting |

## Auto-delegation

When any of these skills encounter a Figma source, they must delegate to `/u-figma` instead of attempting their own partial extraction:

- `/u-prepare` — during Scenario A/B1 dropzone scan, if any `.figma-link` / `figma.com` URL is present.
- `/u-analyze` — if a file under `data/dropzone/` is a `.figma-link` or `.figma-make-link`.
- `/u-reverse` — if the user passes `--figma {url}` or the project contains a `figma-link.json` at repo root.
- `/u-design` — when the user asks to "sync design from Figma" or when `data/figma/manifest.json` is stale.

The delegating skill must pass `--app` and `--loop` through verbatim.

## Preconditions

- Figma MCP server available (`figma-mcp-go` preferred, official `mcp.figma.com` fallback — see `figma-analysis.md` PART I §1).
- For REST comments tier: `FIGMA_PERSONAL_ACCESS_TOKEN` env var (optional; skill falls back to tier-1 + tier-3 if absent).
- `.u-maker/` folder tree exists (`/u-prepare-foldertree` run).

## Postconditions

- Every targeted frame has either a fresh digest in `data/digest/figma/…` or an explicit `skipped`/`error` entry in `manifest.json`.
- `manifest.json` reports coverage (pages analyzed / total, variants detected, comments merged).
- Downstream skills can consume `data/figma/aggregate.json` to build SRS/ERD/API/Screen Spec without round-tripping to Figma.

## Quality Standards

- **Completeness principle:** 프레임의 모든 기획 텍스트는 digest에서 구조화되어 보존된다. 누락 ⇒ 다운스트림 복구 불가.
- **Variant-exhaustive:** `variantSources[]` in each digest must list which of (component-set / naming / positional / suffix) detected the variant. `unknown` is a failure mode.
- **Coverage warnings:** any frame with missing semantic fields the content implies exist (e.g., form frame with no `validationRules[]`) is flagged.
- **Idempotency:** re-running with unchanged Figma content must produce no new writes (hashes match).

## Reference Files

- **`references/manifest-schema.md`** — Human-readable `figma-manifest.schema.json` doc (from plan §8).
- **`references/variant-detection.md`** — Four-source union algorithm (from plan §7).
- **`references/pipeline.md`** — Phase-by-phase details (from plan §10).
- **`references/comments-fallback.md`** — 3-tier comment merge (from plan §11).
- **`references/integration.md`** — Auto-delegation wiring with `/u-prepare`, `/u-analyze`, `/u-reverse`, `/u-design` (from plan §12).
- **`skills/u-plan/references/figma-analysis.md`** — Authoritative Figma analysis spec (PART I + PART II, pre-existing).

## Related Commands

- `/u-prepare`, `/u-analyze`, `/u-reverse`, `/u-design` — auto-delegate to `/u-figma` as described above.
- `/u-plan`, `/u-build` — consume `data/figma/aggregate.json` and per-frame digests downstream.

## Implementation status

This SKILL.md defines the contract and scope. The runtime implementation (Phase 1–6 pipeline, lib modules, schemas, tests) is scheduled as the next major work stream after the PBGD v4.0 migration lands; details live in this skill's `references/` (manifest-schema, variant-detection, pipeline, comments-fallback, integration) and in `skills/u-plan/references/figma-analysis.md`.

Until the full pipeline is implemented, `u-agent-figma` runs a **reduced extraction** path that still honors the *scope* requirements above (covers all pages, all variants, all comments) but may lack the schema-strict manifest ledger. Reduced-path extractions still write to the same persistence locations so downstream tooling can treat them uniformly once the full pipeline is turned on.
