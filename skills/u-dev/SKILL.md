---
name: u-dev
description: "This skill should be used when the user asks to '/u-dev', 'dev phase', 'code generation', 'implement', 'u-maker 개발', '개발 단계', '코드 생성', 'FE BE 생성', '구현 단계', or wants to generate code from Design phase specifications."
version: 4.1.0
---

# u-dev — Development Sub-phase (PBGD Build.Development)

`/u-dev [--auto] [--loop] [--app {name}] [--only fe|be|db]`

Development sub-phase of the Build phase: generate FE + BE + DB code from Design specifications. Callable standalone or via the `/u-build` orchestrator. On spec gaps, emits `.state/build-gap-report.json` so `/u-build` can ping-pong back to `/u-design`.

**Primary Agent:** u-agent-dev
**Engine Dependencies:** doc-engine, dep-engine
**Gate Prerequisite:** UI Design sub-phase gate passed (ERD, API, Screens, Design System = Final)
**PBGD Phase:** Build.Development
**Parent orchestrator:** `/u-build`

## Execution Flow

### Step 0: Verify Design Prerequisite

1. Check `docs/{app}/design/` for required files: `erd.json`, `api.json`, `screens.json`, `design-system.json`
2. If **any file missing** → inform user: "Design documents not found. Running /u-design first." → invoke `/u-design --app {name}` automatically, then return here
3. Read design doc statuses from companion JSONs
4. All must be `Final`: erd.json, api.json, screens.json, design-system.json
5. If not → error with missing doc list and statuses

### Step 1: Generate FE Code

1. Load `screens.json` + `design-system.json`
2. **Load `references/fe-rules.md`** — authoritative React/Next.js rule set (Vercel react-best-practices + composition-patterns). The MUST-APPLY checklist (§0, 15 rules) is non-negotiable.
3. For each screen → generate component files
4. Apply design tokens from design-system
5. Follow tech-rules for framework conventions
6. **Self-review every file against `fe-rules.md` §0 MUST-APPLY before marking Final.** Hot-path code additionally checks §A5/§A6/§A7; shared components under `packages/ui-*/` additionally enforce §B1–B3 (and §B4 if React ≥ 19).
7. **Honor the design dependency pipeline `apps/* → ui-* → tokens` (project `DESIGN.md` §0 is the SSoT when present).** `apps/*` screens are composed from `@{ns}/ui-*` components only — no raw form/interactive HTML, no layout/visual inline `style`, minimal raw CSS/`className`; styling is owned by `ui-*`. When a screen needs UI that the existing `ui-*` components **cannot express** (missing component / variant / state), do **not** silently emit raw HTML or inline style in `apps/*`. Instead: (a) extend the relevant `ui-*` package (token + design-system compliant; CSS Modules `*.module.css` allowed in `ui-*`), or (b) if the gap is a missing spec, emit a `.state/build-gap-report.json` entry and **surface it to the user** so `/u-build` can ping-pong back to `/u-design`. Never paper over a `ui-*` gap inside `apps/*`.

### Step 1.5: Browser-verify implemented components — mandatory hard gate

After component files are written, delegate to `/u-tools-browser` Step 6f to render every `CMP-{nnn}` (and its variants/states) in a real browser and compare against the spec. **When any component has `figmaKey` set in `design-system.json`, Figma parity (6f.4) is mandatory** — Step 6f either passes parity or HALTs the run.

1. **Resolve render target** — Storybook on port 6006 if `packages/ui-*/.storybook` exists, else app routes on the app's dev port, else static demo HTML under `apps/{app}/public/_demo/`.
2. **Start dev server if needed** — `/u-tools-browser` Step 5 prints the start hint (`bun run storybook --filter=ui-common` or `bun run dev --filter={app}`) and HALTs until the server is reachable. Pass `--auto` to skip the headed/headless prompt.
3. **Per-component verification** — the engine samples computed styles, asserts variant/state selectors, runs the **mandatory** Figma pixel-diff per variant/state (SSIM ≥ 0.95, pixel diff ≤ 5 %, bounds within ±2 px) for every component with `figmaKey`, and runs a per-subtree a11y audit. Components without `figmaKey` skip parity but still get token-binding + a11y checks.
4. **Read result** — `.u-maker/.state/visual-verify/{app}-components.json`.
5. **Failure handling — hard gate**:
   - `result == "fail"` → re-execute Step 1 for the failing components only, using `tokenDrift` + `figmaParity.diffs` + `figmaParity.tokenDrift` rows as the improvement list. Max 3 retries; on the third failure, surface to the user — do NOT proceed to Step 2 (BE) and do NOT mark the FE work complete.
   - **Any Figma parity failure (`figmaParity.result == "fail"`) MUST surface as the top-level `fail`.** It cannot be silently downgraded to `partial` or carried forward as a build-gap.
   - `result == "partial"` is allowed only for non-parity issues (a11y warnings, HTML-only drift). Continues but emits a `.state/build-gap-report.json` entry so `/u-build` can ping-pong back to `/u-design` if the gap is in the spec rather than the implementation.

Skip Step 1.5 entirely when `--only be` or `--only db` is passed (no FE work happened) or when the FE generation produced zero changed files. The user may also pass through `--no-figma-parity` to `/u-tools-browser` for an explicit override (logged to the run summary) — never silently.

### Step 2: Generate BE Code

1. Load `api.json` + `erd.json`
2. For each API endpoint → generate route handler
3. Apply authentication/authorization from API contract
4. Follow tech-rules for framework conventions

### Step 3: Generate DB Code

1. Load `erd.json`
2. Generate migration/schema files
3. Apply relationships, constraints, indexes

### Step 4: Spec-Sync Verification

1. Compare generated code against design specs
2. Verify all SC items have corresponding components
3. Verify all API items have corresponding routes
4. Verify all ENT items have corresponding tables
5. Report coverage gaps

### Step 5: Gatekeeper (if --loop)

1. Invoke u-agent-gatekeeper on generated code
2. If avg score < 95 → improvement list → re-generate
3. Max 3 retries

## Reference Files

- **`references/code-gen-rules.md`** — Code generation patterns, file naming, component structure
- **`references/tech-rules.md`** — Supported stacks, naming conventions, package management
- **`references/fe-rules.md`** — React/Next.js rule set (Vercel react-best-practices 70 rules + composition-patterns 9 rules). Mandatory input for Step 1 FE generation.
- **`../u-tools-browser/SKILL.md`** Step 6f — Component visual verification engine (Step 1.5 delegation target).
