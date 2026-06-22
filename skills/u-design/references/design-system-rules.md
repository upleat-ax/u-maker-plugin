# Design System Rules

Authoritative rule pack for every `/u-design` Design System artifact (Phase A HTML + derived MD/JSON) and any downstream `/u-dev` FE emission that touches shared design tokens or primitive components.

Compiled from **dylantarre/design-system-skills** (28 skills). The upstream SKILL.md files are the source of truth for exhaustive examples.

- Upstream: https://github.com/dylantarre/design-system-skills/tree/main/skills
- Canonical URL pattern: `https://github.com/dylantarre/design-system-skills/blob/main/skills/{group}/{skill}/SKILL.md`

## 0. MUST-APPLY (checked on every Design System artifact)

| # | Rule | What to produce / enforce |
|---|------|---------------------------|
| 1 | 3-layer token architecture (`design-tokens-structure`) | **Primitive → Semantic → Component** — never skip a layer, never reference primitives directly from components |
| 2 | OKLCH color scale (`color-scale`) | 11-step scales (50, 100, 200, …, 950) per brand/neutral/semantic hue; generate in OKLCH for perceptual uniformity |
| 3 | Spacing scale (`spacing-scale`) | 8–12 steps centered on a 4px / 0.25rem base; consistent ratio (1.5 balanced / 2 dramatic) |
| 4 | Type scale (`type-scale`) | Modular ratio (1.125 / 1.2 / 1.25 / 1.333 / 1.414 / 1.5); body 1rem anchor |
| 5 | Shadow scale (`shadow-scale`) | Elevation ramp (xs/sm/md/lg/xl/2xl) with consistent y-offset + blur scaling |
| 6 | Radius scale (`radius-scale`) | 0 / xs / sm / md / lg / xl / full — semantic naming; document which tokens go to which component |
| 7 | Breakpoints (`breakpoints`) | Mobile-first; sm 640 / md 768 / lg 1024 / xl 1280 / 2xl 1536 (adjust only with explicit reason) |
| 8 | Motion scale (`motion-scale`) | Durations 75/100/150/200/300/500/700/1000 ms + easing curves (`standard`, `decelerate`, `accelerate`, `emphasized`) |
| 9 | Z-index scale (`z-index-scale`) | Named tiers (base/docked/dropdown/sticky/banner/overlay/modal/popover/skip/toast/max) — no magic numbers |
| 10 | Responsive typography (`responsive-typography`) | `clamp(min, preferred, max)` for headings; prevents jumps at breakpoint changes |
| 11 | Dark mode (`dark-mode`) | `[data-theme="dark"]` + `prefers-color-scheme` fallback + semantic tokens only (never primitive) |
| 12 | WCAG contrast (`color-contrast`) | All token pairs used together pass **AA** (4.5:1 normal, 3:1 large / UI); target **AAA** (7:1 / 4.5:1) for body text |
| 13 | Focus states (`focus-states`) | Visible focus indicator on every interactive primitive — 2px min outline with offset, not `outline:none` |
| 14 | ARIA patterns (`aria-patterns`) | Every interactive primitive maps to a WAI-ARIA authoring-practice pattern (Dialog, Listbox, Tabs, Combobox, Menu, Disclosure…) |
| 15 | Compound-component API (`compound-components`) | Multi-part widgets ship as `<X>`, `<X.Trigger>`, `<X.Content>` with context-driven state — not prop-driven monoliths |
| 16 | No single-side accent border (`no-single-side-border`) | 카드·콜아웃·배너를 한 변만 색 입힌 border(`border-left:4px solid`)로 강조 금지; nav/tab **active**도 한쪽 컬러 바 금지 → 전체 4변 `border` + 배경 틴트 + `font-weight`로 강조. 1px 중립 divider·focus ring·차트 마커만 단면 허용 (전면 배제, html-engine.md §6) |

---

## 1. Token Architecture

Three layers, strict direction — upper references lower, never reverse.

```
Component  (button-bg, card-border)      ← references Semantic
Semantic   (color-primary, color-surface) ← references Primitive
Primitive  (blue-500, gray-100)           ← raw values only
```

- **Primitive**: raw values, context-free (`--color-blue-500: #3b82f6`). Never used directly in components.
- **Semantic**: purpose-based aliases (`--color-primary: var(--color-blue-500)`). Mode-switchable.
- **Component**: component-scoped (`--button-bg: var(--color-primary)`). Opt-in — only when variants/states need isolation.

Upstream: `tokens/design-tokens-structure`

## 2. Token Scales (10)

| Scale | Upstream skill | Default shape |
|-------|----------------|---------------|
| Color | `tokens/color-scale` | 11-step OKLCH (50/100/…/950) per hue; neutrals + brand + semantic (success/warning/danger/info) |
| Spacing | `tokens/spacing-scale` | 4px base, ratio 1.5, 10 steps |
| Type | `tokens/type-scale` | 1rem anchor, ratio 1.25 (7 steps: xs…4xl) |
| Shadow | `tokens/shadow-scale` | 6 elevations (xs→2xl) |
| Radius | `tokens/radius-scale` | 0/xs/sm/md/lg/xl/full |
| Breakpoints | `tokens/breakpoints` | sm 640 / md 768 / lg 1024 / xl 1280 / 2xl 1536 |
| Motion | `tokens/motion-scale` | 8 durations × 4 easings |
| Z-index | `tokens/z-index-scale` | 11 named tiers |
| Responsive typography | `tokens/responsive-typography` | `clamp()` for h1–h6 + body |

### Output formats (all scales)

Emit in ALL three formats so downstream (FE, Figma, docs) can consume any:

1. **CSS custom properties** — `:root { --color-primary: oklch(…) }`
2. **Tailwind config** — `theme.extend.colors.primary.500`
3. **JSON tokens (DTCG-compatible)** — Style Dictionary consumable

## 3. Patterns (5)

| Pattern | Upstream | Rule |
|---------|----------|------|
| Dark mode | `patterns/dark-mode` | Toggle via `[data-theme]`; system detect via `prefers-color-scheme`; persist in `localStorage`; semantic tokens only |
| Compound components | `patterns/compound-components` | Root+parts with Context; ARIA roles + `data-state`; keyboard nav; focus trap/return |
| Icon system | `patterns/icon-system` | SVG sprite (<24 icons) or React/Vue icon component (≥24 icons); `currentColor` for inheritance |
| Layout primitives | `patterns/layout-primitives` | Ship `<Stack>`, `<Cluster>`, `<Grid>`, `<Sidebar>`, `<Center>` as composable primitives |
| Animation principles | `patterns/animation-principles` | Disney's 12 principles applied to UI; respect `prefers-reduced-motion` |

## 4. Accessibility (3)

| Rule | Upstream | Acceptance criteria |
|------|----------|---------------------|
| Color contrast | `accessibility/color-contrast` | AA min (4.5:1 text, 3:1 large/UI); test every semantic pair before publishing token |
| Focus states | `accessibility/focus-states` | Visible outline ≥ 2px, offset ≥ 2px, `:focus-visible` preferred; never remove without replacement |
| ARIA patterns | `accessibility/aria-patterns` | Match each interactive widget to [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/patterns/) |

## 5. Framework Output

When the Design System artifact needs component source code (handed to `/u-dev`), pick the framework skill matching the target project:

| Framework | Upstream | u-maker default? |
|-----------|----------|------------------|
| React (+ TS) | `frameworks/react` | ✅ Default (matches `/u-createproject` Turborepo stack) |
| Vue 3 (Composition API) | `frameworks/vue` | opt-in |
| Svelte 5 (runes) | `frameworks/svelte` | opt-in |
| Angular (signals) | `frameworks/angular` | opt-in |

For React output: combine with `skills/u-dev/references/fe-rules.md` (Vercel react-best-practices + composition-patterns) — the two rule packs are complementary, not overlapping.

## 6. Tools

| Tool | Upstream | Role in u-maker pipeline |
|------|----------|--------------------------|
| Figma | `tools/figma` | Source extraction via `skills/u-tools-figma`; variable → token mapping |
| Storybook | `tools/storybook` | Component docs per `packages/ui-*/.storybook/` |
| Style Dictionary | `tools/style-dictionary` | Multi-platform token transform (CSS / Tailwind / JSON / iOS / Android) |
| Framer | `tools/framer` | Optional — Framer token sync for marketing surfaces |

## 7. Documentation (2)

| Artifact | Upstream | Location |
|----------|----------|----------|
| Token docs | `documentation/token-docs` | Embedded in `out/{app}/design/design-system.html` showcase + derived `docs/{app}/design/design-system.md` |
| Component docs | `documentation/component-docs` | Per-component API section in the same HTML; one `<section id="cmp-{id}">` per CMP item |

---

## 8. Integration with `/u-design` Phase A (HTML generation)

The Design System pipeline is HTML-first (`design-system-spec.md` §1.1). Apply these rules at the points below.

1. **Before writing the HTML template** — load this rule pack into context.
2. **Token resolution step** — run all `§0 MUST-APPLY` items as a checklist (incl. #16 no-single-side-accent-border). Output must pass every row.
3. **CSS custom-property emission** — all three layers present (primitive block, semantic block, component block, in that order inside `:root`).
4. **`[data-theme="dark"]` block** — only overrides semantic tokens; never redeclares primitives.
5. **Live showcase region** — every token scale visualized (swatches / typography ramp / spacing ruler / shadow ladder / radius ramp / motion demo / z-index stack).
6. **Component showcase** — each CMP in `design-system.json` has a card with all variants × sizes × states, using compound-component API where applicable.
7. **Accessibility self-check** — automated color-contrast sweep; every semantic foreground/background pair logs AA/AAA pass/fail into the showcase footer.
8. **Focus-state sweep** — tab through the showcase manually or via `u-tools-browser` Step 6c; every interactive element must show a visible focus ring.
9. **MD/JSON derivation** — extract token tables and component specs from the HTML; the HTML remains the source of truth.

## 9. Integration with `/u-build` orchestration

`/u-build` ping-pongs `/u-design` ↔ `/u-dev`. During orchestration:

- If the FE gap report (`.state/build-gap-report.json`) cites missing tokens or inconsistent scales → the gap is routed back to `/u-design`, which re-runs §2 for the affected scales.
- If the gap cites a11y failures (contrast, focus, ARIA) → routed to `/u-design`, which re-runs §4.
- If the gap cites component-API shape issues (boolean-prop proliferation, prop-drilling) → routed to `/u-design` §3 compound-components, then `/u-dev` applies `fe-rules.md` §B.

## 10. Version pinning

- Source: `dylantarre/design-system-skills` @ main (28 skills across 7 groups)
- Last sync: 2026-04-19

Re-sync and bump `u-design` `version` on upstream schema changes (new scale type, new pattern, new accessibility rule).
