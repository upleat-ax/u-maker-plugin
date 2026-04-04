# u-reverse Design Spec

**Date:** 2026-04-04
**Status:** Approved
**Scope:** New skill — reverse-engineer existing code into SSoT documents

## Problem

u-maker's PDCA pipeline assumes a greenfield workflow: raw requirements → Plan → Design → Dev → Check. Projects with existing code but no SSoT documents cannot enter this pipeline. `/u-reverse` fills this gap by analyzing code and generating the full SSoT document set in reverse order.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Scope | Full reverse (Plan + Design) | Both Plan and Design documents needed for `/u-check` and future PDCA cycles |
| Order | Bottom-up (Code → Design → Plan) | Extract concrete facts first (schemas, routes, components), then infer abstract requirements |
| Target detection | Auto-detect + manual override | Handles most projects automatically; `--src/--db/--api/--pages` for monorepos and non-standard layouts |
| Initial status | Draft | Reverse-inferred documents require human review before promotion |
| Init relationship | Auto-init if `.u-maker/` absent | Single command experience; no prerequisite steps |

## Command Signature

```
/u-reverse [--app {name}] [--src {path}] [--db {path}] [--api {path}] [--pages {path}] [--loop]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--app` | Project directory name | App name for `docs/{app}/` |
| `--src` | Auto-detect | Source code root |
| `--db` | Auto-detect | DB schema/migration path |
| `--api` | Auto-detect | API route/controller path |
| `--pages` | Auto-detect | Page/screen component path |
| `--loop` | false | Run gatekeeper validation after generation |

## Execution Flow

### Step 0: Bootstrap

1. Check for `.u-maker/` directory
2. If absent → invoke u-init internally (auto-detect or use `--app`)
3. If present with `Final` documents → warn user, require confirmation to overwrite
4. Validate config version is v4

### Step 1: Code Scan & Stack Detection

1. Scan project root for stack indicators:
   - `package.json` → Node.js ecosystem (check for Next.js, Express, Nest, etc.)
   - `requirements.txt` / `pyproject.toml` → Python (Django, FastAPI, Flask)
   - `go.mod` → Go
   - `Cargo.toml` → Rust
   - `Gemfile` → Ruby (Rails)
   - `composer.json` → PHP (Laravel)
2. Detect framework-specific conventions:
   - ORM: Prisma, TypeORM, Sequelize, SQLAlchemy, Django ORM, ActiveRecord
   - Router: Express, FastAPI, Nest controllers, Rails routes, Next.js App Router
   - UI: React, Vue, Svelte, Angular (page/component directories)
3. Apply `--src/--db/--api/--pages` overrides where provided
4. Produce internal `scan-result`: stack info + file map (not persisted as SSoT doc)

### Step 2: Extract Design — ERD

**Input:** DB schema files, ORM model definitions, type definitions
**Output:** `docs/{app}/design/erd.md` + `erd.json` (status: Draft)

1. Locate DB schema sources (priority order):
   - Explicit `--db` path
   - ORM schema files (e.g., `prisma/schema.prisma`, `**/models.py`, `**/entity.ts`)
   - Migration files (SQL DDL)
   - Fallback: scan code for model/type definitions with persistent fields
2. Extract per entity: name (PascalCase domain prefix per existing ERD convention), columns, types, constraints (PK/FK/UK — never combined)
3. Derive relationships from foreign keys, join tables, ORM decorators
4. Apply ID 10-increment: ENT-010, REL-010, etc.
5. Generate Mermaid erDiagram
6. Render via `_meta/templates/erd.template.md`
7. Generate companion `erd.json` per `doc-companion.schema.json`
8. Update `data/links.json`

### Step 3: Extract Design — API

**Input:** Route/controller files, middleware, ERD output
**Output:** `docs/{app}/design/api.md` + `api.json` (status: Draft)

1. Locate API route sources (priority order):
   - Explicit `--api` path
   - Framework router files (Express `router.*`, FastAPI decorated functions, Nest `*.controller.ts`)
   - Next.js `app/**/route.ts` or `pages/api/**`
2. Extract per endpoint: path, HTTP method, request/response schemas, auth/role requirements
3. Map endpoints to ERD entities where applicable
4. Apply ID 10-increment: API-010, API-020, etc.
5. Generate Mermaid classDiagram for data models
6. Render via `_meta/templates/api.template.md`
7. Generate companion `api.json`
8. Update `data/links.json`

### Step 4: Extract Design — Screens + Design System

**Input:** Page/component files, styling config, ERD + API output
**Output:**
- `docs/{app}/design/screens.md` + `screens.json` (status: Draft)
- `docs/{app}/design/design-system.md` + `design-system.json` (status: Draft)

#### Screens

1. Locate page/screen sources (priority order):
   - Explicit `--pages` path
   - Framework page directories (`app/`, `pages/`, `src/views/`, `src/screens/`)
2. Extract per screen: name, route, layout, components used, API calls, state management
3. Derive navigation structure from routing config
4. Apply ID 10-increment: SC-010, SC-020, etc.
5. Render via `_meta/templates/screens.template.md`

#### Design System

1. Locate design tokens:
   - `tailwind.config.*` → colors, spacing, fonts, breakpoints
   - CSS custom properties (`:root` variables)
   - Theme files (`theme.ts`, `tokens.js`)
2. Scan components for recurring UI patterns (Button, Input, Card, Modal, Table, etc.)
3. Apply ID 10-increment: DS-010, CMP-010, etc.
4. Render via `_meta/templates/design-system.template.md`

### Step 5: Synthesize Plan — SRS

**Input:** All Design documents (ERD, API, Screens, Design System)
**Output:** `docs/{app}/plan/srs.md` + `srs.json` (status: Draft)

Reverse-infer requirements from concrete artifacts:

1. **FR (Functional Requirements):** One FR per domain area derived from ERD entity groups + API endpoint clusters. Example: if ERD has `User`, `Session`, `Role` entities and API has `/auth/*` endpoints → FR-010 "User Authentication & Authorization"
2. **US (User Stories):** One US per API endpoint group or screen workflow. Derive actor from auth/role data. Format: "As a {role}, I can {action} so that {benefit}"
3. **FT (Features):** One FT per screen or distinct API capability. Most granular level — maps directly to testable units
4. Build traceability: FR→US→FT with ID 10-increment
5. Infer NFRs from observable code patterns (e.g., rate limiting → performance NFR, CORS config → security NFR)
6. Derive stakeholders from role/permission model
7. Build glossary from domain terms in code (model names, enum values)
8. Render via `_meta/templates/srs.template.md`

### Step 6: Synthesize Plan — IA

**Input:** Screens document, routing config, SRS output
**Output:** `docs/{app}/plan/ia.md` + `ia.json` (status: Draft)

1. Derive site map from routing structure (nested routes → hierarchy)
2. Build page inventory from Screens document
3. Extract navigation structure from layout components (navbar, sidebar, breadcrumbs)
4. Infer user flows from screen→API→screen transitions
5. Apply ID 10-increment: IA-010, IA-020, etc.
6. Render via `_meta/templates/ia.template.md`

### Step 7: Generate HTML Output + Finalize

1. For each generated document, produce HTML via html-engine:
   - `output/{app}/plan/srs.html` — FR→US→FT traceability tree, MoSCoW donut, stakeholder matrix
   - `output/{app}/plan/ia.html` — site map, user flows, navigation structure
   - `output/{app}/design/erd.html` — Mermaid erDiagram + entity grouping SVG
   - `output/{app}/design/api.html` — Mermaid classDiagram + endpoint traceability SVG
   - `output/{app}/design/screens.html` — screen flow SVG, state transitions
   - `output/{app}/design/design-system.html` — token hierarchy, color swatches
2. Build `data/links.json` traceability graph (all FR→US→FT→SC→API→ENT edges)
3. Update `output/{app}/index.html`, `output/index.html`, root `index.html`
4. If `--loop` → invoke u-agent-gatekeeper on all documents, max 3 retries per doc

## Agent Assignment

Reuses existing agents with reversed input direction:

| Step | Agent | Role |
|------|-------|------|
| 0-1 | u-agent-pm | Bootstrap + orchestration |
| 2-4 | u-agent-design | Design document generation (input: code instead of Plan docs) |
| 5-6 | u-agent-plan | Plan document synthesis (input: Design docs instead of dropzone digest) |
| 7 | u-agent-gatekeeper | Validation (unchanged) |

## Post-Reverse Workflow

After `/u-reverse` completes, all documents are `Draft`. The user workflow:

```
/u-reverse
  → User reviews & edits Draft documents
  → /u-check --loop (generates test cases, validates, promotes to Final)
  → Normal PDCA cycle for future changes
```

## Error Handling

| Condition | Action |
|-----------|--------|
| No recognizable stack detected | Error: "Could not detect project stack. Use --src, --db, --api, --pages to specify paths." |
| No DB schema found | Skip ERD; warn user. Generate API/Screens/SRS/IA without ERD. |
| No API routes found | Skip API; warn user. Generate ERD/Screens/SRS/IA without API. |
| No UI pages found | Skip Screens/DS/IA; warn user. Generate ERD/API/SRS only. |
| Existing Final documents | Warn + confirm before overwriting. Backup existing docs to `data/reverse-backup-{timestamp}/`. |
| `.u-maker/` absent | Auto-run u-init |

## Output Summary

After successful execution, print:

```
u-reverse complete.
  App:       {app-name}
  Stack:     {detected framework} ({language})
  Generated: {N} documents (all Draft)
  
  Plan:    srs.md, ia.md
  Design:  erd.md, api.md, screens.md, design-system.md
  HTML:    {N} files in output/{app}/
  
  Next:    Review Draft documents, then run /u-check --app {app}
```
