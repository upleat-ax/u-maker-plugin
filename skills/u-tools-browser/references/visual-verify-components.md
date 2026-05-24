# visual-verify-components — Per-Component Implementation Verification (Step 6f)

Verifies directly-implemented FE components render correctly against their `Screen.json` + `design-system.json` specs. Requires a dev server (Storybook on port 6006 OR app routes on the app port). Triggered automatically by `/u-dev` Step 1.5.

## 1. Choose render target (priority)

1. Storybook on port 6006 (`packages/ui-*/.storybook` exists) — use `iframe.html?id={story-id}` deep links.
2. App route (`apps/{app}/src/app/**/page.tsx` rendering the component).
3. Static demo file (`apps/{app}/public/_demo/{cmp-id}.html`) if neither of the above is available.

## 2. Per-component loop

Load the component list from `docs/{app}/design/design-system.json` `components[]`. For each `CMP-{nnn}`:
- Navigate to its render target.
- `browser_snapshot` to collect element refs.
- Assert prop default values render (text content, icon presence, default variant CSS class).
- For each `variants[*]` / `states[*]` combination: navigate to the variant URL (Storybook story ID `cmp-{nnn}--{variant}-{state}`), screenshot it, assert variant-specific selectors.

## 3. Token binding check

For each rendered component, sample the resolved fill / border / spacing via `browser_evaluate`:

```js
(selector) => {
  const el = document.querySelector(selector);
  if (!el) return null;
  const cs = getComputedStyle(el);
  return { bg: cs.backgroundColor, fg: cs.color, padding: cs.padding, radius: cs.borderRadius };
}
```

Compare to the expected token resolution from `design-system.json`. Drift → record under `tokenDrift[]`.

## 4. Figma parity (MANDATORY when `figmaKey` is present)

For every `CMP-{nnn}` whose `design-system.json` row has `figmaKey` set, this sub-step runs unconditionally. When `figmaKey` is **not** set → skip that single component (HTML-only origin); when ANY component has `figmaKey` AND the user is not authenticated → **HALT** with the same message as Step 6e.8 (`"Figma parity is mandatory…"`). Never silently skip.

1. Fetch the Figma component screenshot via `mcp__plugin_figma_figma__get_screenshot` (cache under `.u-maker/.state/figma-ref/{dsFileKey}/{figmaKey}.png`).
2. Fetch the Figma component's variant grid (each variant + state combination) via `mcp__plugin_figma_figma__get_node`. For each combination, capture an individual screenshot.
3. Pixel-diff the Figma reference against the implementation screenshot for the same variant/state combination. Pass threshold: SSIM ≥ 0.95 AND pixel-diff ≤ 5 % per component instance. Bounds (width / height / padding / gap) must match within ±2 px (extracted via `getBoundingClientRect()` and Figma node `absoluteBoundingBox`).
4. **Token resolution parity** — sample the rendered component's resolved CSS variables (Step 3), then compare against the Figma component's bound variable values (`mcp__plugin_figma_figma__get_variable_defs`). Mismatch → `figmaTokenDrift[]`.
5. Write each comparison PNG triplet (figma / impl / diff) to `.u-maker/.state/visual-verify/diffs/{app}-cmp-{nnn}-{variant}-{state}.{figma,impl,diff}.png`.

## 5. Per-component a11y

Same audit pattern as Step 6e.6 (see `visual-verify-ds.md`), scoped to the component subtree.

## 6. Screenshots

`.u-maker/.state/screenshots/{YYYY-MM-DD}/{app}-cmp-{nnn}-{variant}-{state}.png`

## 7. Diff record

Write `.u-maker/.state/visual-verify/{app}-components.json`:

```json
{
  "verifiedAt": "ISO-8601",
  "renderTarget": "storybook|app|demo",
  "totalComponents": K,
  "verified": L,
  "tokenDrift": [{ "cmpId": "CMP-010", "variant": "primary", "field": "bg", "expected": "...", "actual": "..." }],
  "figmaParity": {
    "checked": L_figma,
    "passed": P,
    "failed": F,
    "diffs": [
      { "cmpId": "CMP-020", "variant": "primary", "state": "default",
        "ssim": 0.91, "pixelDiffPct": 8.4, "boundsDelta": { "w": 3, "h": 0 },
        "diffScreenshot": ".u-maker/.state/visual-verify/diffs/...diff.png", "pass": false }
    ],
    "tokenDrift": [],
    "result": "pass|fail"
  },
  "a11yViolations": [],
  "result": "pass|partial|fail"
}
```

`result` rules (mandatory parity):
- `result == "pass"` requires zero `tokenDrift`, zero a11y violations, AND (for every component with `figmaKey`) `figmaParity.result == "pass"`.
- `result == "fail"` when ANY Figma-bound component has a screenshot diff below threshold OR a `figmaTokenDrift` row.
- `result == "partial"` reserved for HTML-only components with non-Figma drift.
