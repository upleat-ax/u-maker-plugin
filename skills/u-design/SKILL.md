---
name: u-design
description: "This skill should be used when the user asks to 'design', 'create ERD', 'generate API contract', 'screen specification', 'design system', '/u-design', or wants to produce Design phase documents from Plan documents."
version: 4.0.0
triggers:
  - "/u-design"
  - "design phase"
  - "ERD"
  - "API contract"
  - "screen spec"
  - "design system"
---

# u-design — UI Design Sub-phase (PBGD Build.UIDesign)

`/u-design [--auto] [--loop] [--app {name}]`

UI Design sub-phase of the Build phase: generate `docs/{app}/design/` documents (ERD, API, Screens, Design System) from Plan phase documents (SRS + IA). Callable standalone or via the `/u-build` orchestrator.

**Primary Agent:** u-agent-design
**Engine Dependencies:** doc-engine, dep-engine
**Gate Prerequisite:** Plan phase gate passed (SRS=Final, IA=Final)
**PBGD Phase:** Build.UIDesign
**Parent orchestrator:** `/u-build`

## Execution Flow

### Step 0: Verify Plan Prerequisite

1. Check `docs/{app}/plan/` for required files: `srs.json`, `ia.json`
2. If **any file missing** → inform user: "Plan documents not found. Running /u-plan first." → invoke `/u-plan --app {name}` automatically, then return here
3. Read `docs/{app}/plan/srs.json` and `ia.json` status
4. Both must be `Final`
5. If not → error: "Plan documents exist but are not Final. Run /u-plan --loop or manually set status to Final"
6. **Figma freshness check:** if `data/figma/manifest.json` exists, compare file hashes against current Figma state. If stale, delegate to `/u-tools-figma --verify` (or `/u-tools-figma --refresh-comments` if the user just asked to "sync design from Figma"). Use the refreshed `data/figma/aggregate.json` as an input to Steps 1–4 below so ERD/API/Screens/DS pick up every variant, validation rule, default, action, and permission captured from Figma. See `skills/u-tools-figma/references/integration.md`.

### Step 1: Generate ERD

1. Load SRS entities, data models from `srs.json`
2. Derive entity list, columns, types, relationships
3. Generate ERD diagram in `.md` (format depends on `--diagram` mode: `svg` → inline SVG entity boxes with curved connectors and cardinality labels; `mermaid`/`all` → Mermaid `erDiagram`). PK/FK/UK constraints — never combined.
4. Apply ID 10-increment (ENT-010, REL-010)
5. Write `docs/{app}/design/erd.md` + `erd.json`
6. Update `data/links.json`

### Step 2: Generate API Contract

1. Load SRS functional requirements, IA page inventory
2. Derive API endpoints, methods, request/response schemas
3. Map endpoints to FR IDs
4. Apply ID 10-increment (API-010, API-020)
5. Generate data model diagram in `.md` (format depends on `--diagram` mode: `svg` → inline SVG class boxes with method lists and relationship arrows; `mermaid`/`all` → Mermaid `classDiagram`)
6. Write `docs/{app}/design/api.md` + `api.json`
7. Update `data/links.json`

### Step 3: Generate Screen Specification

1. Load IA page inventory, SRS user stories
2. Define screen layout, components, API calls, state, validation
3. Apply ID 10-increment (SC-010, SC-020)
4. **Figma link traceability:** Figma 소스가 있는 화면은 `screens.json` item에 `figmaUrl` (deep link) 포함, `screens.md`에 `> Figma: <url>` 기재
5. Write `docs/{app}/design/screens.md` + `screens.json`
6. Update `data/links.json`

### Step 4: Generate Design System (HTML-First)

**Unlike other artifacts, the Design System uses an HTML-first pipeline.** The live HTML with CSS variables and component showcases is the primary artifact; MD and JSON are derived from it.

**Rule pack:** Before starting Step 4, load `references/design-system-rules.md` into context. The §0 MUST-APPLY checklist (15 items — token architecture, 10 scales, dark mode, contrast, focus, ARIA, compound components) is non-negotiable and is verified at Step 4a.7.

#### Step 4a: Generate HTML/CSS/Variables (Primary)

1. Analyze SRS/IA for UI patterns, component needs, brand colors
1a. **Figma source (if available):** Extract design tokens and component specs from Figma via `u-plan/references/figma-analysis.md` § 4.2 (Design System Context). Figma Variables → CSS custom properties, Paint/Text/Effect styles → token values, Local components → CMP-xxx mapping. Figma actuals override SRS/IA-derived defaults.
1b. **Figma link traceability:** Figma 소스 URL을 `design-system.json`의 `figmaUrl` 필드에 기록, `design-system.md` 상단에 `> Figma: <url>` 기재. 개별 토큰/컴포넌트도 Figma 프레임 deep link 포함 권장.
2. Load template: `_meta/templates/design-system.template.html`
3. Render CSS custom properties in `:root` block with actual token values — emit **all three token layers** (primitive → semantic → component) per `design-system-rules.md` §1
4. Emit all 10 token scales per `design-system-rules.md` §2 (color OKLCH 50–950, spacing, type, shadow, radius, breakpoints, motion, z-index, responsive typography via `clamp()`)
5. Render `[data-theme="dark"]` overrides on **semantic tokens only** (`design-system-rules.md` §3 dark-mode + §0#11)
6. Render component styles (`.ds-btn`, `.ds-input`, `.ds-card`, etc.) using **compound-component API** for multi-part widgets (`design-system-rules.md` §3 + §0#15)
7. Render live showcases: color swatches, typography scale, component variants/sizes/states; include an accessibility audit footer (WCAG AA/AAA contrast sweep + focus-state check) per `design-system-rules.md` §4
8. Apply ID convention (DS-010~DS-110 for tokens, CMP-010~CMP-070 for components)
9. Write `out/{app}/design/design-system.html`
10. **Browser verify the HTML — mandatory hard gate** — delegate to `/u-tools-browser` Step 6e. The engine opens the file via `file://`, samples every token from `:root`, asserts every `CMP-xxx` showcase is present, toggles `[data-theme="dark"]`, runs a Lighthouse / axe-core a11y audit, captures full-page screenshots in both modes, AND (when the DS originated from Figma) performs the mandatory Figma parity sub-step (6e.8: token parity + per-frame screenshot diff at SSIM ≥ 0.95 / pixel diff ≤ 5 % + coverage parity).
   - On `--auto` → run headless, no prompts. **Even in `--auto` the Figma parity is NOT skippable** unless the user explicitly passed `--no-figma-parity` (which is logged to the run summary).
   - Verification result is read from `.u-maker/.state/visual-verify/{app}-design-system.json`.
   - **`result == "fail"` is a hard gate.** Re-execute Steps 4a.3–9 with the full diff (`missingTokens` + `missingComponents` + `figmaParity.tokenDrift` + `figmaParity.screenshotDiffs` + `figmaParity.coverageGaps`) as the improvement list. Max 3 retries; on the third failure, surface to the user — do NOT mark the DS as Final and do NOT proceed to Step 4b.
   - `result == "partial"` is allowed only for non-parity issues (a11y warnings without contrast violations, low-priority drift). Logged to `.u-maker/.state/figma-sync-todos.json` (priority p2) and continues.
   - Any Figma parity failure (`figmaParity.result == "fail"`) MUST surface as the top-level `result == "fail"` — it cannot be downgraded to `partial`.

#### Step 4b: Derive MD + JSON from HTML

1. Parse CSS variables from the HTML `:root` block → token tables
2. Parse component classes from the HTML `<style>` block → component specs
3. Write `docs/{app}/design/design-system.md` (with `Source:` pointing to HTML)
4. Write `docs/{app}/design/design-system.json` (with `source` field pointing to HTML)
5. Verify sync: every token/component in HTML is documented in MD and JSON
6. Update `data/links.json`

### Step 4.5: Optional Outbound Figma Sync

After the doc layer is written and (if `--loop`) gatekept to Final, offer to mirror the design system + screens back into Figma:

1. **DS sync — `/u-tools-figma-ds`** — invoked when `design-system.json` has changed and either:
   - `data/figma/manifest.json.dsFileKey` is set (update existing Figma DS), OR
   - The user explicitly opts in to creating a new DS file (interactive prompt; skipped under `--auto`).
   
   Pass `--source docs/{app}/design/design-system.json` to round-trip the doc into Figma. The skill writes back `figmaKey` per component into `design-system.json`.

2. **Screen sync — `/u-tools-figma-screen --output figma --prefer md`** — invoked when `screens.json` has changed and a Figma destination is known (manifest or `--target-figma`). The `--prefer md` flag ensures dev-validated md wins over any stale Figma content.

3. Both delegations are **opt-in by default** (interactive prompt). They become opt-out under `--auto` only when `data/figma/manifest.json` already records a destination — implying the user has previously opted in.

4. If either sync fails, write the failure to `.u-maker/.state/figma-sync-todos.json` (priority p2) and continue with `/u-design` Step 5; do NOT block the doc-layer completion on Figma availability.

> **Why opt-in?** Figma writes are slow (5–30 min for a full DS, 1–10 min per screen) and require an active Figma session. We surface the option but don't gate doc completion on it.

### Step 5: Gatekeeper (if --loop)

1. Invoke u-agent-gatekeeper on design documents
2. If avg score < 95 → improvement list → re-execute failed steps
3. Max 3 retries

### Step 6: Completion & Next Step Guide

Design phase 완료 후 아래 안내를 출력한다:

```
✅ Design phase completed.
  Generated: ERD, API Contract, Screen Specification, Design System

🔜 Next Step:
  /u-wireframe --app {app} --all
  → Screen Specification 기반으로 화면별 HTML 와이어프레임을 생성합니다.
  → 각 화면의 목업 UI, 어노테이션, ERD 매핑, Sequence Diagram, Screen Flow가 포함됩니다.

  이후:
  /u-dev --app {app}      → FE + BE 코드 생성
  /u-check --app {app}    → 테스트 케이스 + 결과
```

## Reference Files

- **`references/erd-spec.md`** — Entity derivation, Mermaid erDiagram rules, constraint syntax
- **`references/api-spec.md`** — Endpoint derivation, OpenAPI structure, auth/role mapping
- **`references/screen-spec.md`** — Component taxonomy, state management, validation rules
- **`references/design-system-spec.md`** — Token naming, component variants, responsive breakpoints (HTML-first pipeline spec)
- **`references/design-system-rules.md`** — **Rule pack for Step 4** (dylantarre/design-system-skills: 3-layer token architecture, 10 scales, dark-mode, contrast, focus, ARIA, compound components). Mandatory input.
- **`../u-plan/references/figma-analysis.md`** — Figma frame analysis, content type detection, design token extraction from Figma
- **`../u-tools-figma-screen/SKILL.md`** — Step 4.5 outbound sync target for screens
- **`../u-tools-figma-ds/SKILL.md`** — Step 4.5 outbound sync target for design system
