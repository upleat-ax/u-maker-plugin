---
name: u-dev
description: "This skill should be used when the user asks to '/u-dev', 'dev phase', 'code generation', 'implement', 'u-maker 개발', '개발 단계', '코드 생성', 'FE BE 생성', '구현 단계', or wants to generate code from Design phase specifications."
version: 4.2.0
---

# u-dev — Development Sub-phase (PBGD Build.Development)

`/u-dev [--auto] [--loop] [--app {name}] [--only fe|be|db] [--sideeffect off|on|strict]`

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

### Step 0.5: Side-Effect Gatekeeping — mandatory hard gate for behavior-MODIFYING fixes to ALREADY-IMPLEMENTED, DEPENDED-UPON code

Before Steps 1–3 generation, and before **every** individual Edit/Write/Bash that could mutate an
**already-implemented file that other code depends on**, enforce the adversarial change-safety
protocol in `references/change-safety.md`. The policy (사용자 지시) is *"fix하는 경우에만 다른 기능이나
UI/UX에 사이드이펙트가 있을지 검토하고, 사이드이펙트가 있을 수 있는 경우에만 물어본다"* — so the prompt fires
**only** when a fix **rewrites/deletes existing behavior** in committed code that other code depends on.
It is **default-deny** for such risky fixes (especially **bug fixes** to shipped features / UI-UX).
Forward construction (new files, or iterating on untracked/dirty in-progress files) is **not** gated;
neither is fixing a **leaf** file that nothing imports; neither is a **purely additive** edit (inserting
new code while leaving every existing line intact). Every prompt — the guard's and yours — leads with
the emphasized banner **`⚠️ SIDE-EFFECT IMPACT — 사이드이펙트 영향도 있음`**.

1. **Classify each target as NEW / IN-PROGRESS / IMPLEMENTED·LEAF / IMPLEMENTED·SHARED, then for SHARED split ADDITIVE vs MODIFYING** (IMPLEMENTED = git-tracked AND clean vs HEAD; **LEAF** = nothing imports/references it; **SHARED** = ≥1 other source file imports/references it; **ADDITIVE** = the edit only inserts new code, keeping every existing line verbatim; **MODIFYING** = it rewrites/deletes existing behavior). NEW + IN-PROGRESS (untracked/dirty) create/iterate freely; **IMPLEMENTED·LEAF** and **IMPLEMENTED·SHARED·ADDITIVE** are not gated (neither can side-effect other features); only **IMPLEMENTED·SHARED·MODIFYING** is gated. `.u-maker/**` is out of scope. *Caveat (Boundary 2/3):* API routes / DB schema / env contracts are cross-feature surfaces the import-graph can't detect — treat them as SHARED; and an insertion that still alters behavior reads as ADDITIVE — judge the behavior-delta yourself even when the guard stays silent.
2. **For every IMPLEMENTED·SHARED·MODIFYING file you intend to change or delete, produce an Impact / Side-Effect (blast-radius) analysis**: reverse-dependency scan (who imports/calls it), public-surface delta (exported signature / prop / API route / DB column / env), behavior delta, test/spec coverage, and whether the edit is strictly required by the spec/bug or is scope creep. Default the verdict to **UNSAFE** when anything is ambiguous or unverifiable.
3. **Adversarial self-review**: argue against the change — name the worst plausible regression. If you can't rule it out, treat as UNSAFE and make the smallest reversible change.
4. **Mandatory user approval (gatekeeping)**: present a single `AskUserQuestion` per file (or per `--auto` batch), **led by the `⚠️ SIDE-EFFECT IMPACT — 사이드이펙트 영향도 있음` banner** — path · NEW/IN-PROGRESS/IMPLEMENTED·LEAF/IMPLEMENTED·SHARED(ADDITIVE|MODIFYING) · intent + diff · blast-radius · top regression risk. Options: Approve / Approve-batch / Skip / Abort. **You MUST NOT apply a behavior-modifying edit to IMPLEMENTED·SHARED code until the user Approves.** `--auto` may batch but **never** auto-approves deletions, renames, or signature/schema/route changes.
5. **Record approval**: on Approve, write the marker `.u-maker/.state/edit-approvals/{sha1(absPath)}.json` so the PreToolUse guard (`hooks/on-edit-guard.js`) authorizes the edit instead of re-prompting (TTL `U_MAKER_EDIT_APPROVAL_TTL_MIN`, default 480 min). Without a fresh marker the guard forces a native approval prompt (`permissionDecision: "ask"`).
6. **Scope lock**: only approved paths may be touched. Touching an unapproved implemented file to "finish" the task is scope creep = FAIL — raise a new approval instead.

Skip this gate for NEW, IN-PROGRESS (untracked/dirty), IMPLEMENTED·LEAF (no-dependent), and IMPLEMENTED·SHARED·ADDITIVE (insert-only) edits. It is never skippable for behavior-modifying edits/deletes of already-implemented code that **has dependents** (IMPLEMENTED·SHARED·MODIFYING), regardless of `--auto` / `--loop`. Gate scope is set by `U_MAKER_EDIT_GATE` (**`off` default = disabled** — the gate is OFF unless you opt in · `on`=`auto` = implemented **and** depended-upon **and** modifying · `strict` = every add+modify to every existing file). **The `--sideeffect {off|on|strict}` skill param sets this mode per-project**: when passed, FIRST persist it **before any generation** — `mkdir -p .u-maker/.state && printf '<mode>\n' > .u-maker/.state/edit-gate-mode` (writes under `.u-maker/` are never gated; `on`=`auto`) — and the PreToolUse guard reads it on every edit (env `U_MAKER_EDIT_GATE` still overrides the file). Omit the param to keep the current state-file value (or `off` if none). Full protocol + marker schema → **`references/change-safety.md`**.

### Step 1: Generate FE Code

1. Load `screens.json` + `design-system.json`
2. **Load `references/fe-rules.md`** — authoritative React/Next.js rule set (Vercel react-best-practices + composition-patterns). The MUST-APPLY checklist (§0, 15 rules) is non-negotiable.
3. For each screen → generate component files
4. Apply design tokens from design-system
5. Follow tech-rules for framework conventions
6. **Self-review every file against `fe-rules.md` §0 MUST-APPLY before marking Final.** Hot-path code additionally checks §A5/§A6/§A7; shared components under `packages/ui-*/` additionally enforce §B1–B3 (and §B4 if React ≥ 19).
7. **Honor the Atomic Design dependency pipeline `apps/* → ui-organisms → ui-molecules → ui-atomics → tokens` (project `DESIGN.md` §0 is the SSoT when present).** **raw HTML, CSS (`.css`/CSS Modules), and inline `style` live ONLY in `@{ns}/ui-atomics`** (the atom layer wrapping native elements — `Button`/`Input`/`Label`/`Text`/`Form`/`Box`/`Stack` etc.; inline-style themeable values use `var(--*)` token-first, raw only for dynamic/computed values). `ui-molecules`, `ui-organisms`, and `apps/*` **compose lower-tier components only** — no raw form/interactive HTML, no inline `style`, no own CSS; layout via `Box`/`Stack` atoms; variation via props. `apps/*` screens are assembled mainly from `@{ns}/ui-organisms` (page-level semantic wrappers like `<main>`/`<section>` are fine). When a layer needs UI that the lower tiers **cannot express** (missing atom / molecule / organism / variant / state), do **not** silently emit raw HTML or inline style outside `ui-atomics`. Instead: (a) extend the appropriate tier — add/extend an atom in `ui-atomics` (token + design-system compliant; inline style + CSS Modules allowed there) or a composite in `ui-molecules`/`ui-organisms`, or (b) if the gap is a missing spec, emit a `.state/build-gap-report.json` entry and **surface it to the user** so `/u-build` can ping-pong back to `/u-design`. Never paper over a gap with raw HTML/inline style outside `ui-atomics`.

### Step 1.5: Browser-verify implemented components — mandatory hard gate

After component files are written, delegate to `/u-tools-browser` Step 6f to render every `CMP-{nnn}` (and its variants/states) in a real browser and compare against the spec. **When any component has `figmaKey` set in `design-system.json`, Figma parity (6f.4) is mandatory** — Step 6f either passes parity or HALTs the run.

1. **Resolve render target** — Storybook on port 6006 if `packages/ui-*/.storybook` exists, else app routes on the app's dev port, else static demo HTML under `apps/{app}/public/_demo/`.
2. **Start dev server if needed** — `/u-tools-browser` Step 5 prints the start hint (`bun run storybook --filter=ui-atomics` or `bun run dev --filter={app}`) and HALTs until the server is reachable. Pass `--auto` to skip the headed/headless prompt.
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
- **`references/change-safety.md`** — **Side-effect gatekeeping (Step 0.5)**: NEW / IN-PROGRESS / IMPLEMENTED·LEAF / IMPLEMENTED·SHARED classification, reverse-dependency-driven blast-radius/impact analysis, mandatory AskUserQuestion approval before editing already-implemented code **that has dependents** (git-tracked + clean **and** imported elsewhere), the `U_MAKER_EDIT_GATE` mode switch, and the approval-marker contract for the `hooks/on-edit-guard.js` PreToolUse guard. Default-deny for risky fixes; leaf/no-dependent fixes pass freely. Mandatory whenever a run could modify a depended-upon already-implemented file.
- **`references/tech-rules.md`** — Supported stacks, naming conventions, package management
- **`references/fe-rules.md`** — React/Next.js rule set (Vercel react-best-practices 70 rules + composition-patterns 9 rules). Mandatory input for Step 1 FE generation.
- **`../u-tools-browser/SKILL.md`** Step 6f — Component visual verification engine (Step 1.5 delegation target).
