# figma/manifest.json — Coverage Ledger

> Tracks per-frame analysis status for every Figma file the project has ever touched. Used by `/u-tools-figma` to skip unchanged frames and by downstream phases to warn about incomplete coverage. Authoritative schema: `_meta/schemas/figma-manifest.schema.json` (to be added when the full pipeline is implemented).

## Top-level shape

```json
{
  "version": "1.0",
  "generatedAt": "2026-04-18T10:00:00Z",
  "files": {
    "{fileKey}": {
      "fileName": "Shopping Mall Design",
      "fileUrl": "https://figma.com/design/{fileKey}/...",
      "lastFullScanAt": "2026-04-18T10:00:00Z",
      "pages": {
        "{pageId}": {
          "pageName": "Home",
          "frames": {
            "{nodeId}": {
              "frameName": "LoginForm",
              "nodeHash": "sha256:…",
              "status": "done",
              "contentTypes": ["screen-planning", "screen-design"],
              "variantSources": ["component-set", "naming"],
              "coverageWarnings": [],
              "analyzedAt": "2026-04-18T10:00:00Z",
              "digestPath": "data/digest/figma/{fileKey}/home/loginform.digest.json",
              "rawPath": "data/figma/raw/{fileKey}/pages/{pageId}.nodes.json#{nodeId}"
            }
          }
        }
      },
      "comments": {
        "fetchedAt": "2026-04-18T10:00:00Z",
        "restAvailable": true,
        "stickyNoteCount": 12,
        "restCount": 45,
        "inlineThreadCount": 7,
        "mergedPath": "data/figma/raw/{fileKey}/comments.json"
      },
      "aggregatePath": "data/figma/aggregate.json"
    }
  }
}
```

## Frame status values

| Status | Meaning |
|--------|---------|
| `pending` | Detected, not yet analyzed |
| `processing` | Analysis in progress (crash-recovery marker) |
| `done` | Digest written, passes schema validation |
| `skipped` | Explicitly skipped (e.g., empty frame, duplicate variant) |
| `error` | Extraction attempted but failed (see `error` field for detail) |
| `stale` | `nodeHash` differs from last-analyzed hash; needs re-extraction |

## coverageWarnings[]

Emitted by Phase 4 (verify). Each warning has a `code` and a `suggestedFix`:

| Code | Meaning |
|------|---------|
| `missing-validation-rules` | Frame contains input fields but digest has no `validationRules[]` |
| `missing-button-actions` | Frame contains buttons/CTAs but digest has no `uiSpecifications[]` or `processingRules[]` with trigger |
| `missing-data-model` | Frame references entity-like fields but digest has no `businessRules[]` or `domainRules[]` entries |
| `missing-flow-target` | Prototype reaction references a node not in any digest |
| `unknown-variant-source` | Variant detected but none of the 4 source heuristics matched — manual review needed |
| `dense-frame-not-chunked` | Frame exceeds density threshold but was not chunked (possible extraction loss) |

## Re-run semantics

`/u-tools-figma` uses the manifest as follows:

1. Fetch current `nodeHash` for each targeted frame.
2. Compare to stored hash in manifest.
3. If matches → skip (status remains `done`).
4. If differs → mark `stale`, re-extract in Phase 3.
5. If not present → mark `pending`, extract.

`/u-tools-figma --verify` re-runs Phase 4 against existing digests without re-extracting — used to catch coverage gaps after the schema has been extended.
