# Variant Detection — Four-Source Union

> `/u-tools-figma` must be **variant-exhaustive**: every variant of every component/screen must be detected, regardless of how the designer organized it. Four parallel heuristics; the union of their outputs is the final variant set. Authoritative spec: `skills/u-plan/references/figma-analysis.md` PART II §7.

## Why four sources

Designers use inconsistent conventions. Relying on only one heuristic misses variants organized by another. The union strategy trades a little deduplication cost for recall — and missed variants in digest ⇒ missing UI states in SRS/Screen Spec.

## Source 1 — Component-set properties (authoritative when present)

For Figma component sets (the `ComponentSet` node type), variant properties are explicit:

```
{
  "componentSetId": "...",
  "variantProperties": {
    "State": ["Default", "Hover", "Active", "Disabled"],
    "Size": ["Small", "Medium", "Large"]
  }
}
```

Every combination is a variant. Weight: highest.

## Source 2 — Naming patterns

Look for nodes whose names follow `Base/Modifier` or `Base=Value` patterns:

- `Button/Hover`, `Button/Active`, `Button/Disabled`
- `Input=default`, `Input=focused`, `Input=error`

Parse as variants when the `Base` prefix appears on 2+ sibling nodes. Weight: medium.

## Source 3 — Positional clusters

Sibling frames that share a name prefix AND are positioned in an adjacent cluster (same row or column, within 2× their own width/height) are likely variants laid out side-by-side for review:

- `LoginScreen-empty`, `LoginScreen-typing`, `LoginScreen-error` in a horizontal row

Weight: low-medium; confirm with naming heuristic before committing.

## Source 4 — Suffix conventions

Single-node names ending with a known modifier suffix:

- `-default`, `-hover`, `-active`, `-disabled`, `-focused`, `-error`, `-empty`, `-loading`, `-success`, `-readonly`

Extract the base name by stripping the suffix; group nodes sharing the same base. Weight: low (easy false positives).

## Union + conflict resolution

1. Run all four detectors in parallel.
2. Each detector emits `{baseName, variantName, nodeId, source}`.
3. Group by `(baseName, variantName)`; if multiple sources agree → confidence=high.
4. If only one source detected → confidence=medium. Include but flag.
5. Record the sources used in the digest:
   ```json
   "variantSources": ["component-set", "naming"]
   ```

## Failure mode

If a node is suspected to be a variant (e.g., sibling to a known variant) but no detector fires, emit `coverageWarnings: [{"code": "unknown-variant-source", ...}]` and surface the node for human review.

## Completeness check

At Phase 4 (verify), for every detected variant base:

- Enumerate the expected variant set from Source 1 (if the base is a component set) — this is the "ground truth".
- Diff against variants detected by Sources 2-4 (if the base is scattered frames).
- Flag missing variants.

This catches the common bug where a designer added a `Hover` variant to the component set but forgot to export it as a standalone frame elsewhere.
