# visual-verify-screens — Step 6g: Screen / Route ↔ Figma Frame parity (PIXEL-PERFECT)

Screen-level (route-level) implementation verification. Closes the gap that Steps 6e (Design System)
and 6f (components) do not cover: a fully composed, rendered app **route** versus its Figma **frame**.
Invoked by `/u-gatekeeping` **Step 2.5** (Design Conformance) and scored by **GK-12**.

> All Figma/browser access routes through `/u-tools-browser`. Never call MCP Playwright/Figma tools
> from the gatekeeper agent directly.

## 0. Pixel-perfect thresholds (GATE)

This is a **gate**, not fast Build iteration — use the stricter `gate-rules.json` GK-12 thresholds:

| Metric | Build-phase (6e/6f) | **GATE (6g / GK-12)** |
|--------|--------------------|------------------------|
| SSIM | ≥ 0.95 | **≥ 0.99** |
| Pixel diff | ≤ 5 % | **≤ 1 %** |
| Region bounds | ± 2 px | **± 1 px** |

The GATE default is **fixed** at the pixel-perfect values above (from `gate-rules.json` GK-12.thresholds);
`--figma-ssim-threshold` / `--figma-diff-threshold` may only **tighten** it (lower the diff / raise the
SSIM), never loosen it below the gate default.

## 1. When it runs (MANDATORY when any screen has a Figma frame)

Runs for every `screens.json` item whose row has `figmaUrl` set.

- No screen has `figmaUrl` AND no Figma provenance exists at all → skip; `result: "na"`.
- A screen has `figmaUrl` but the user is not authenticated against Figma → **HALT** with
  `"Figma parity is mandatory for Figma-sourced screens. Authenticate via mcp__plugin_figma_figma__authenticate or pass --no-figma-parity to skip explicitly (recorded; blocks Deploy)."`
- `figmaUrl` present but screen never rendered/round-tripped → record `figmaSourceUnlinked: true`
  (a GK-12 FAIL, not a silent pass). Never `try/catch` the parity away.

## 2. Procedure (per screen)

1. **Resolve route** — map the `screens.json` item to its app route/path. Ensure the dev server is up
   (reuse Step 5 dev-server detection/start; pass `--auto` to skip the headed/headless prompt).
2. **Render** — navigate to the route, wait for network idle + fonts loaded, set the viewport to the
   Figma frame's dimensions, capture a full-page screenshot. Cache under
   `.u-maker/.state/figma-ref/{dsFileKey|app}/screen-{SC-id}.impl.png`.
3. **Fetch Figma frame** — `mcp__plugin_figma_figma__get_screenshot` for the frame referenced by
   `figmaUrl` (extract the node id from the URL). Cache `…/screen-{SC-id}.figma.png`.
4. **Pixel diff** — compute SSIM + pixel-diff for the full frame and for each labelled region
   (header / sidebar / body / footer / each annotated component). Assert each region's bounding box is
   within ± 1 px of the Figma frame's region. Write the PNG triplet (figma / impl / diff) to
   `.u-maker/.state/visual-verify/diffs/{app}-screen-{SC-id}.{figma,impl,diff}.png`. Mismatches → `diffs[]`.
5. **Text parity** — assert critical visible text (titles, labels, button captions, error messages)
   matches the Figma frame's text layers. Mismatches → `textDrift[]`.
6. **Token-resolution parity** — sample computed styles (color/spacing/radius/typography) on key
   regions and compare against the resolved DS tokens (reuse 6e token map). Mismatches → `tokenDrift[]`.

## 3. Reference-material rule coverage (참고자료 ↔ 구현)

Beyond Figma visuals, assert that ingested reference-material semantics are implemented:

- For each digest under `data/digest/**`, every `validationRules[] / domainRules[] / permissionRules[] /
  processingRules[]` must trace to an implemented guard (FE validation, BE check, route guard) **or** a TC.
- Orphans (rule with no implementation and no TC) → `referenceGaps[]`.

## 4. Result rules

- `result == "pass"` requires, for **every** screen with a Figma source: `figmaParity.result == "pass"`
  at the pixel-perfect thresholds, **zero** `diffs` / `textDrift` / `tokenDrift` above tolerance, **zero**
  `coverageGaps` / `referenceGaps`, and no `figmaSourceUnlinked`.
- ANY screen `fail`, any unrendered-but-provenance screen, or an unacknowledged `--no-figma-parity`
  override → `result: "fail"`.
- `result: "na"` only when there is no Figma/reference provenance at all.

## 5. Output — `.u-maker/.state/visual-verify/{app}-screens.json`

```json
{
  "app": "{app}",
  "thresholds": { "ssimMin": 0.99, "pixelDiffMaxPct": 1, "boundsTolerancePx": 1 },
  "result": "pass | fail | na",
  "screens": [
    {
      "id": "SC-010",
      "route": "/dashboard",
      "figmaUrl": "https://www.figma.com/file/…?node-id=…",
      "figmaParity": { "result": "pass", "ssim": 0.994, "pixelDiffPct": 0.4 },
      "diffs": [],
      "textDrift": [],
      "tokenDrift": [],
      "figmaSourceUnlinked": false
    }
  ],
  "referenceGaps": [],
  "coverageGaps": [],
  "checkedAt": "…"
}
```

Consumed by `/u-gatekeeping` Step 2.5 (aggregated into `design-conformance.json`) and scored by GK-12.
