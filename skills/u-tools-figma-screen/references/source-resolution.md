# Source Resolution — u-tools-figma-screen

How `/u-tools-figma-screen` decides which screen-plan and design-system source to use when multiple are available. Same protocol applies to both inputs; the matrix below is generic.

## 1. Discovery Order (per input)

The skill walks each tier in order and stops at the first hit. The chosen source is recorded in `.u-maker/.state/figma-screen-run.json`.

### Tier 1 — Explicit flag

`--screen-source <value>` or `--ds-source <value>`. The value can be:

| Value pattern | Interpretation |
|---------------|----------------|
| `https://www.figma.com/file/<key>/...` or `https://www.figma.com/design/<key>/...` | Figma source. Extract `fileKey` (path[2]) and `nodeId` (`?node-id=...` query) |
| `https://www.figma.com/board/<key>/...` | FigJam board (treated as Figma source with `--include-fig-jam`) |
| `./relative/path/screens.json` | md/json source. JSON is preferred over md when both exist; md is used to recover narrative fields missing from JSON |
| `./relative/path/screens.md` | md source. Companion JSON is read if it exists alongside |
| `./packages/ui-buttons` (DS only) | Code source. Walk for `*.tokens.json`, `*.css`, and `*.tsx` files |
| `auto` | Skip Tier 1; fall through to Tier 2 |

### Tier 2 — Manifest-driven discovery

Read `data/figma/aggregate.json` (refreshed by `/u-tools-figma --verify` if stale). For each frame digest, inspect `figmaContentType`:

| `figmaContentType` | Eligible as |
|--------------------|-------------|
| `screen-design` | screen-plan source |
| `screen-planning` | screen-plan source |
| `design-tokens` | DS source |
| `assets` | DS source (asset-only fragment) |
| `prototype` | screen-plan source (with flow data) |
| `diagram` / `annotation` / `specification` | metadata only — never used as primary source |

If multiple frames qualify, prefer the one with the highest `coverageScore` from the digest, then the most recent `analyzedAt`.

### Tier 3 — Doc layer

Look under the project tree:

| Input | Path | Acceptance criteria |
|-------|------|---------------------|
| Screen plan | `docs/{app}/design/screens.json` | `status` ∈ {`Draft`, `Final`}; `phase: "design"` |
| Screen plan (fallback) | `docs/{app}/plan/ia.json` | Used when no `screens.json` — generates a thin draft from the IA page inventory |
| DS | `docs/{app}/design/design-system.json` | `status` ∈ {`Draft`, `Final`} |
| DS (fallback) | `out/{app}/design/design-system.html` | Parsed back into JSON via the same logic `/u-design` Step 4b uses |

### Tier 4 — Code layer (DS only)

Walk the Turborepo layout produced by `/u-createproject`:

| Path | Token kind |
|------|-----------|
| `packages/tokens/src/**/*.css` | CSS custom properties (`--token-name`) → `tokens.color`, `tokens.spacing`, etc. (matched by prefix) |
| `packages/tokens/src/**/*.json` | Pre-baked token JSON (Style Dictionary or W3C tokens spec) |
| `packages/ui-*/src/components/**/*.tsx` | Component shape (props, variants from discriminated union types or `cva` calls) |
| `apps/*/src/styles/tokens.css` | App-local override layer (lower precedence than `packages/tokens`) |

If neither Tier 3 nor Tier 4 yields a DS, the skill HALTs (per SKILL.md "Mandatory pre-flight" #1).

## 2. Tie-breakers

When two tiers both yield a source for the same input:

1. **Tier number wins** — lower tier (more explicit) trumps higher tier
2. Within the same tier:
   - Figma URL with explicit `node-id` > Figma URL without
   - JSON > md (machine-readable wins)
   - Higher coverageScore > lower
   - More recent timestamp > older

## 3. Cross-input consistency

Once both inputs are resolved, run a one-pass consistency check:

- If both inputs come from the **same Figma file**, that's the ideal case — record `crossInputAffinity: "same-file"`.
- If screen plan = Figma but DS = doc/code, verify the DS doc/code cites the same Figma file via `figmaUrl` in `design-system.json`. If it cites a different file, warn the user once and ask whether to (a) continue with the mixed sources, (b) re-resolve DS from the screen-plan file. Default = (a).
- If screen plan = doc and DS = Figma, the same warn-and-ask applies in reverse.

## 4. Conflict precedence (`--prefer`)

When both Figma and a doc-layer source resolve for the **same** input (e.g., `screen-source` finds both a Figma URL and `screens.json` with the same SC IDs), `--prefer` decides:

| `--prefer` | Behaviour |
|------------|-----------|
| `figma` (default) | Figma wins; doc fields override only if the Figma frame is missing the field |
| `md` | Doc wins; Figma fields override only if the doc is missing the field |

Field-by-field overrides are NOT supported in v1 — it's per-input all-or-nothing for conflict cases. Field-level override is on the v1.1 roadmap.

## 5. State recording

Every run writes:

```json
// .u-maker/.state/figma-screen-run.json
{
  "runId": "20260419-152312-ab3f",
  "app": "myapp",
  "screensSource": {
    "tier": 2,
    "kind": "figma",
    "ref": "fileKey:abc123, nodeId:42:1138",
    "figmaContentType": "screen-design"
  },
  "dsSource": {
    "tier": 4,
    "kind": "code",
    "ref": "packages/tokens + packages/ui-*"
  },
  "prefer": "figma",
  "output": "both",
  "ts": "2026-04-19T15:23:12+09:00"
}
```

This is the single source of truth for "what was used" — referenced by `/u-design`, `/u-build`, and `/u-tools-figma --verify`.
