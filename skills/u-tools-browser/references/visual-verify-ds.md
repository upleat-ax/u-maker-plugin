# visual-verify-ds — Design System HTML Verification (Step 6e)

Verifies the HTML-first DS artifact (`out/{app}/design/design-system.html`) renders correctly. Runs against `file://` (no dev server required). Triggered automatically by `/u-design` Step 4a.

## 1. Load expected inventory

Load from `docs/{app}/design/design-system.json`:
- `tokens[]` — every token row (color / spacing / type / shadow / radius / motion / breakpoint / z-index)
- `components[]` — every component (CMP-xxx) with variants and states
- `themes[]` — should include `light` and `dark` (per `design-system-rules.md` §0#11)

## 2. Navigate the static HTML

```
browser_navigate url: file://{absolute-path-to-out}/design/design-system.html
browser_wait_for text: <DS title from JSON>
```

## 3. Token render check

Query the rendered `:root` CSS variables via `browser_evaluate`:

```js
() => {
  const cs = getComputedStyle(document.documentElement);
  const sample = {};
  // sample at least 1 token per scale
  ['--color-primary-500','--space-4','--radius-md','--shadow-md','--font-base','--motion-base'].forEach(k => {
    sample[k] = cs.getPropertyValue(k).trim();
  });
  return sample;
}
```

Compare every sampled value to the JSON expectation. Missing or empty → record under `mismatches[]`.

## 4. Component showcase check

For each `components[*]`, assert the live showcase exists:

```
browser_snapshot                                                  # collect element refs
```

Verify a `[data-cmp-id="CMP-{nnn}"]` (or fallback `data-component={key}`) element is present and visible. For each `variants[*]` and `states[*]`, verify the `[data-variant=...]` / `[data-state=...]` selector exists.

## 5. Dark-mode toggle

Flip `[data-theme="dark"]` via `browser_evaluate`:

```js
() => { document.documentElement.dataset.theme = 'dark'; }
```

Re-sample the same tokens (Step 3). Assert at least the semantic-layer tokens differ from light. Take a second screenshot.

## 6. Accessibility audit (mandatory per design-system-rules.md §0#7)

When running on chrome-devtools MCP, request a Lighthouse a11y audit:

```
mcp__plugin_chrome-devtools-mcp_chrome-devtools__lighthouse_audit  categories: ["accessibility"]
```

When running on Playwright MCP, run an axe-core injection via `browser_evaluate`. WCAG-AA contrast violations and missing focus indicators are recorded under `a11yViolations[]`.

## 7. Screenshots

Full-page light + dark, written to:
- `.u-maker/.state/screenshots/{YYYY-MM-DD}/{app}-design-system-light.png`
- `.u-maker/.state/screenshots/{YYYY-MM-DD}/{app}-design-system-dark.png`

## 8. Figma parity check (MANDATORY when a Figma DS source is registered)

When `data/figma/manifest.json` records a `dsFileKey` AND `design-system.json.figmaUrl` is set, this sub-step runs unconditionally. It is the gate the user requires when "design system was extracted from Figma → implemented as HTML/CSS → verify identical".

1. Pull the Figma reference once per run via `mcp__plugin_figma_figma__get_screenshot` for the DS file's documentation page (or each component frame). Cache under `.u-maker/.state/figma-ref/{dsFileKey}/{frameId}.png`.
2. Pull the Figma Variables list via `mcp__plugin_figma_figma__get_variable_defs` for the DS file. Build a name→resolved-value map (`color`, `dimension`, `number`, `string`).
3. **Token parity** — for every Figma Variable that maps to a CSS variable (per `design-system.json` `tokens[*].figmaVarKey`), assert the resolved value matches the rendered `:root` value (Step 3). Tolerance: colors → ΔE < 1 in OKLCH; dimensions → ±0.5 px; others → exact. Mismatches → `figmaTokenDrift[]`.
4. **Component / page screenshot diff** — for each documentation page in the Figma DS file (or each `CMP-{nnn}` showcase frame when frame mapping is available), pixel-diff against the corresponding rendered region of `design-system.html` (use the `data-cmp-id` selector to crop). Pass threshold: SSIM ≥ 0.95 AND pixel-diff ≤ 5 %. Write each comparison PNG triplet (figma / impl / diff) to `.u-maker/.state/visual-verify/diffs/{app}-ds-{frameSlug}.{figma,impl,diff}.png`.
5. **Coverage parity** — every Figma component MUST have a corresponding `CMP-{nnn}` in `design-system.json`, and every `CMP-{nnn}` MUST be rendered in the HTML. One-sided gaps → `figmaCoverageGaps[]`.

When `dsFileKey` is unset BUT Figma provenance exists elsewhere (`design-system.json.figmaUrl`, or any `data/digest/figma/**`), do **NOT** skip silently — record `figmaSourceUnlinked: true` in the result and emit a `figma-sync-todos.json` p1 so Gatekeeping **GK-12** flags "Figma source present but never round-tripped → parity unverifiable". Only skip silently when there is **no** Figma provenance at all (this DS was genuinely not derived from Figma).
When `dsFileKey` is set but the user is not authenticated against Figma → **HALT** with the message `"Figma parity is mandatory for Figma-sourced DS. Authenticate via mcp__plugin_figma_figma__authenticate or pass --no-figma-parity to skip explicitly."` Never silently skip.

## 9. Diff record

Write the verification result to `.u-maker/.state/visual-verify/{app}-design-system.json`:

```json
{
  "verifiedAt": "ISO-8601",
  "html": "out/{app}/design/design-system.html",
  "expectedTokens": N,
  "renderedTokens": M,
  "missingTokens": [],
  "expectedComponents": K,
  "renderedComponents": L,
  "missingComponents": [],
  "darkModeToggled": true,
  "a11yViolations": [],
  "figmaParity": {
    "dsFileKey": "abc123",
    "checked": true,
    "tokenDrift": [],
    "screenshotDiffs": [
      { "frame": "Buttons", "ssim": 0.97, "pixelDiffPct": 2.1, "pass": true }
    ],
    "coverageGaps": [],
    "result": "pass|fail"
  },
  "screenshots": ["…light.png","…dark.png"],
  "result": "pass|partial|fail"
}
```

`result` rules:
- `result == "pass"` requires **all** of: zero `missingTokens`, zero `missingComponents`, dark-mode toggled, zero WCAG-AA contrast violations, AND (when Figma parity ran) `figmaParity.result == "pass"`.
- `result == "fail"` when **any** Figma parity violation exists (`figmaTokenDrift`, `coverageGaps`, or any screenshot diff below threshold).
- `result == "partial"` only for non-Figma-parity issues (e.g., a11y warnings, low-priority drift).
