# Comments — 3-Tier Fallback

> `/u-figma` must capture design-time comments regardless of how the team records them. Three tiers, merged into one unified `comments.json`. Authoritative spec: `figma-analysis.md` PART II §11.

## Tier 1 — In-canvas sticky notes (FigJam + Figma)

Nodes of type `STICKY` or shape-with-text that are positioned near target frames. Characteristics:

- Visible without authentication.
- Arbitrary author (whoever last edited the node).
- Position-anchored to the canvas, not a specific node.

Extraction: via `get_node` / `scan_nodes_by_types`. Associate with the nearest target frame by distance (within 200px) unless an arrow/connector explicitly links them.

## Tier 2 — Figma REST `comments` API

Official design-review comments on `.figma.com/design/...` files. Requires:

- `FIGMA_PERSONAL_ACCESS_TOKEN` env var.
- REST endpoint: `GET https://api.figma.com/v1/files/{fileKey}/comments`.

Returns a list of `{id, message, user, client_meta, order_id, parent_id, resolved_at, reactions[]}` entries. Each `client_meta` anchors the comment to a node or a canvas coordinate.

Client: `skills/u-figma/lib/comment-rest.js` (per the implementation plan).

When `FIGMA_PERSONAL_ACCESS_TOKEN` is absent, `u-figma` logs a notice and proceeds with tiers 1 + 3 only.

## Tier 3 — Inline review threads

Some teams embed review comments inside the design itself as text annotations (e.g., red-text callouts, annotation-shape nodes). Detected heuristically by:

- Font color in a review palette (red / orange / pink).
- Text starting with review prefixes: `REVIEW:`, `TODO:`, `FIX:`, `Q:`, `NOTE:`, `참고:`, `확인:`.
- Nodes inside a layer named `annotations`, `review`, `피드백`, etc.

## Merge & dedupe

Output schema (written to `data/figma/raw/{fileKey}/comments.json`):

```json
{
  "fetchedAt": "...",
  "tierAvailability": {"tier1": true, "tier2": true, "tier3": true},
  "comments": [
    {
      "id": "merged-...",
      "tier": 2,
      "sources": ["rest"],
      "author": "...",
      "body": "...",
      "anchorNode": "1:234",
      "anchorCoords": {"x": 120, "y": 300},
      "resolved": false,
      "createdAt": "...",
      "reactions": [...]
    }
  ]
}
```

Dedupe rule: same `anchorNode` + `body` similarity > 0.9 ⇒ merge; keep highest-tier source, union the `sources[]` array.

Resolved comments (REST `resolved_at` not null) are kept with `resolved: true`; downstream extraction weights them lower but does not drop them.

## Priority in extraction

When the same issue surfaces across multiple tiers, the highest-tier source wins for primary attribution, but all tiers' text is concatenated in the extracted item's `rationale` so no wording is lost.

Tier priority (high → low): **REST (tier 2) > inline review (tier 3) > sticky notes (tier 1)**.

## Missing-comments policy

If a file has zero comments across all tiers, `u-figma` flags this in `coverageSummary.commentsNote = "no-comments-found"` — not an error, but unusual for a design-in-review. Useful for downstream agents to adjust their extraction confidence.
