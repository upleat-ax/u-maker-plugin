---
name: u-dev
description: "This skill should be used when the user asks to 'develop', 'generate code', 'implement', 'build frontend/backend', '/u-dev', or wants to generate code from Design phase specifications."
version: 4.0.0
triggers:
  - "/u-dev"
  - "dev phase"
  - "code generation"
  - "implement"
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
