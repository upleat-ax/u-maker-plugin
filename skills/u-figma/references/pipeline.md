# /u-figma — 6-Phase Pipeline

> High-level description of the scan → gate → extract → verify → aggregate → sync pipeline. Authoritative spec: `skills/u-plan/references/figma-analysis.md` PART II §10.

## Phase 1 — Scan

**Input:** target selector (`--file-key`, `--url`, or auto-detected dropzone `.figma-link` files).

**Actions:**

1. Resolve every target to `{fileKey, nodeId?}`.
2. Query Figma MCP (`get_metadata`) to enumerate pages.
3. For each page, enumerate top-level frames.
4. Build a target list: `[{fileKey, pageId, frameId, frameName, nodeHash}]`.

**Output:** in-memory target list.

## Phase 2 — Gate

**Actions:**

1. Load `data/figma/manifest.json` (if present).
2. For each target, compare `nodeHash` to the manifest entry.
3. Classify: `fresh` (skip) / `stale` (re-extract) / `new` (extract).
4. If `--refresh-comments`, force a comments re-fetch in Phase 3 regardless of gate.

**Output:** `[needsExtraction[], skipped[]]`.

## Phase 3 — Extract

For each `needsExtraction` target:

1. Fetch full node subtree (`get_design_context` or `get_node`).
2. Classify content types (screen-design / screen-planning / diagram / annotation / specification / design-tokens / assets / prototype).
3. Detect variants (four-source union, see `variant-detection.md`).
4. Chunk dense frames (see density heuristic in plan §7.3).
5. Extract semantic fields per `digest.schema.json` Figma extensions:
   - `screenDescriptions[]`, `businessRules[]`, `decisions[]`, `domainRules[]`,
   - `processingRules[]`, `commonRules[]`, `stateTransitions[]`,
   - `validationRules[]`, `permissionRules[]`, `uiSpecifications[]`, `dataRules[]`.
6. Merge comments (3-tier, see `comments-fallback.md`).
7. Write digest to `data/digest/figma/{fileKey}/{pageSlug}/{frameSlug}.digest.json`.
8. Write raw subtree to `data/figma/raw/{fileKey}/pages/{pageId}.nodes.json` (partial if chunked).

## Phase 4 — Verify

For each new/stale digest:

1. Validate against `digest.schema.json` + `figma-manifest.schema.json`.
2. Run `coverageWarnings` checks (missing-validation-rules, missing-button-actions, etc.).
3. Ensure `variantSources[]` is populated (no `unknown-variant-source` without a reason).

Digests that fail validation revert to `status: "error"` with details; the pipeline does not overwrite the previous `done` digest.

## Phase 5 — Aggregate

1. Load all `done` digests for the file(s).
2. Build `data/figma/aggregate.json`:
   - Unified screen inventory (from `screenDescriptions[]` across all frames).
   - Unified rule sets (validation, business, domain, processing, permission).
   - Unified flow graph (from prototype reactions + cross-refs).
   - Unified token catalog (from `designTokens`).
3. Compute `coverageSummary`: total pages / frames / variants / comments; counts of coverageWarnings by code.

## Phase 6 — Sync

1. Write `manifest.json` atomically.
2. Update `data/links.json`: add `digest` nodes for each new/changed digest with `phase: "plan"` (Preparation sub-phase).
3. Emit a one-line summary to the caller:
   ```
   /u-figma done: {files} files, {pages} pages, {frames} frames, {variants} variants,
                  {comments} comments. Coverage: {pct}% (warnings: {n}).
   ```

## Loop mode

With `--loop`:

1. Run Phases 1–6 normally.
2. Invoke `u-agent-gatekeeper` on the aggregate + high-warning-count digests.
3. If score < 95 or `coverageWarnings.length` exceeds threshold, re-enter Phase 3 for the flagged frames with an improvement prompt.
4. Retry up to `loopMaxRetries` (default 3).

## Idempotency

Running `/u-figma` twice on unchanged Figma content produces zero writes:

- Node hashes match → Phase 2 skips all targets.
- `manifest.json` `lastFullScanAt` updates but artifacts are byte-identical.
