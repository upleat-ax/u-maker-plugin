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

# u-dev — Dev Phase

`/u-dev [--auto] [--loop] [--app {name}] [--only fe|be|db]`

Dev phase: generate FE + BE + DB code from Design specifications.

**Primary Agent:** u-agent-dev
**Engine Dependencies:** doc-engine, dep-engine
**Gate Prerequisite:** Design phase gate passed (ERD, API, Screens, Design System = Final)

## Execution Flow

### Step 0: Verify Design Gate

1. Read design doc statuses from companion JSONs
2. All must be `Final`: erd.json, api.json, screens.json, design-system.json
3. If not → error with missing doc list

### Step 1: Generate FE Code

1. Load `screens.json` + `design-system.json`
2. For each screen → generate component files
3. Apply design tokens from design-system
4. Follow tech-rules for framework conventions

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
