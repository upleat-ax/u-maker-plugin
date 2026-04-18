---
name: u-reverse
description: "This skill should be used when the user asks to 'reverse', 'reverse-engineer', 'analyze existing code', 'extract docs from code', 'code to docs', '/u-reverse', or wants to generate SSoT documents from an existing codebase."
version: 4.0.0
triggers:
  - "/u-reverse"
  - "reverse engineer"
  - "reverse-engineer"
  - "code to docs"
  - "extract from code"
  - "analyze existing code"
---

# u-reverse — Reverse Engineering Phase

`/u-reverse [--app {name}] [--loop] [--src {path}] [--db {path}] [--api {path}] [--pages {path}] [--figma {url}]`

Reverse-engineer an existing codebase into SSoT documents. Bottom-up: Code → Design (ERD, API, Screens, DS) → Plan (SRS, IA). All documents start as `Draft`.

**Figma auto-delegation:** If `--figma {url}` is passed, or if the project root contains a `figma-link.json` / `.figma-link`, `/u-reverse` first delegates to `/u-tools-figma --app {app} --url {url}` so the Figma digest (pages + variants + assets + components + comments + semantics) is available as a cross-reference during code extraction. See `skills/u-tools-figma/references/integration.md`.

**Primary Agent:** u-agent-pm (orchestrates u-agent-design + u-agent-plan)
**Engine Dependencies:** doc-engine, dep-engine

## Arguments

| Option | Default | Description |
|--------|---------|-------------|
| `--app` | Project directory name | App name for `docs/{app}/` |
| `--src` | Auto-detect | Source code root |
| `--db` | Auto-detect | DB schema/migration path |
| `--api` | Auto-detect | API route/controller path |
| `--pages` | Auto-detect | Page/screen component path |
| `--figma {url}` | (none) | Figma file URL to co-analyze (auto-delegated to `/u-tools-figma`) |
| `--loop` | false | Run gatekeeper validation after generation |

## Execution Flow

### Step 0: Bootstrap

1. Check for `.u-maker/` directory
2. If absent → invoke u-init internally (use `--app` value or detect from directory name)
3. If `.u-maker/` exists, read `u-maker.config.json`:
   - Resolve app name from `--app` option or config default
   - Validate config version is `4.0`
4. If `docs/{app}/` already has `Final` documents → warn user:
   "Existing Final documents found. Reverse will overwrite with Draft versions. Continue? (y/n)"
   - If `--auto` → back up existing docs to `data/reverse-backup-{YYYYMMDD-HHmmss}/` and proceed
   - If user declines → abort

### Step 1: Code Scan & Stack Detection

1. Scan project root for stack indicators (see `references/stack-detection.md`):
   - Package managers: `package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`
   - Frameworks: detect from dependencies (Next.js, Express, NestJS, FastAPI, Django, Rails, Laravel, etc.)
   - ORM/DB: Prisma, TypeORM, Sequelize, SQLAlchemy, Django ORM, ActiveRecord, Drizzle
   - UI: React, Vue, Svelte, Angular (detect component directories)
2. Apply `--src`, `--db`, `--api`, `--pages` overrides where provided
3. If no recognizable stack → error: "Could not detect project stack. Use --src, --db, --api, --pages to specify paths."
4. Print detected stack summary:
   ```
   Stack detected:
     Language:  TypeScript
     Framework: Next.js 14 (App Router)
     ORM:       Prisma
     UI:        React + Tailwind CSS
     Paths:     src=src/, db=prisma/, api=src/app/api/, pages=src/app/
   ```

### Step 2: Extract Design — ERD

**Agent:** u-agent-design (reversed input: code → ERD instead of SRS → ERD)
**Input:** DB schema files, ORM model definitions, type definitions
**Output:** `docs/{app}/design/erd.md` + `erd.json` (status: Draft)

1. Locate DB schema sources (see `references/code-extraction.md` § 1):
   - Priority: `--db` path > ORM schema files > migration files > code model/type definitions
   - Prisma: `*.prisma` files (model blocks)
   - TypeORM/Sequelize: entity/model decorators in `*.ts`/`*.js`
   - SQLAlchemy/Django: model class definitions in `*.py`
   - SQL migrations: `*.sql` DDL files
   - Fallback: grep for interface/type definitions with persistent-looking fields
2. Extract per entity:
   - Name: PascalCase with domain prefix (per existing ERD convention)
   - Columns: name, type, constraints (PK/FK/UK — never combined per agent quality rules)
   - Relationships: derive from foreign keys, join tables, ORM decorators
3. Apply ID 10-increment: ENT-010, ENT-020, REL-010, REL-020
4. Generate Mermaid erDiagram
5. Render via `_meta/templates/erd.template.md`
6. Generate companion `erd.json` per `_meta/schemas/doc-companion.schema.json`
7. Update `data/links.json`
8. If no DB schema found → skip this step, warn: "No DB schema detected. ERD skipped. Use --db to specify path."

### Step 3: Extract Design — API

**Agent:** u-agent-design (reversed input: code → API instead of SRS → API)
**Input:** Route/controller files, middleware, ERD output from Step 2
**Output:** `docs/{app}/design/api.md` + `api.json` (status: Draft)

1. Locate API route sources (see `references/code-extraction.md` § 2):
   - Priority: `--api` path > framework router files
   - Express: `router.get/post/put/delete()` patterns
   - FastAPI: `@app.get/post()` decorators
   - NestJS: `@Controller()` + `@Get/@Post()` decorators
   - Django: `urlpatterns` + view functions/classes
   - Next.js App Router: `app/**/route.ts` files (export GET/POST/PUT/DELETE)
   - Next.js Pages: `pages/api/**/*.ts`
   - Rails: `config/routes.rb` + controller actions
2. Extract per endpoint:
   - Path, HTTP method
   - Request params/body schema (from types, validation, decorators)
   - Response schema (from return types, serializers)
   - Auth/role requirements (from middleware, guards, decorators)
3. Map endpoints to ERD entities where applicable
4. Apply ID 10-increment: API-010, API-020
5. Generate Mermaid classDiagram for data models
6. Render via `_meta/templates/api.template.md`
7. Generate companion `api.json`
8. Update `data/links.json`
9. If no API routes found → skip this step, warn: "No API routes detected. API doc skipped. Use --api to specify path."

### Step 4: Extract Design — Screens + Design System

**Agent:** u-agent-design (reversed input: code → Screens/DS)
**Input:** Page/component files, styling config, ERD + API output
**Output:**
- `docs/{app}/design/screens.md` + `screens.json` (status: Draft)
- `docs/{app}/design/design-system.md` + `design-system.json` (status: Draft)

#### 4a: Screens

1. Locate page/screen sources (see `references/code-extraction.md` § 3):
   - Priority: `--pages` path > framework page directories
   - Next.js App Router: `app/**/page.tsx`
   - Next.js Pages: `pages/**/*.tsx`
   - React Router: components referenced in route config
   - Vue: `views/` or `pages/` directory
   - Svelte: `routes/` directory
   - Angular: routed components
2. Extract per screen:
   - Name, route path
   - Layout structure (from JSX/template analysis)
   - Components used (imports)
   - API calls (fetch, axios, tRPC, server actions)
   - State management (useState, store references, context)
   - Form validation (zod, yup, native validation)
3. Derive navigation structure from routing config
4. Apply ID 10-increment: SC-010, SC-020
5. Render via `_meta/templates/screens.template.md`
6. Generate companion `screens.json`

#### 4b: Design System

1. Locate design tokens (see `references/code-extraction.md` § 4):
   - `tailwind.config.*` → colors, spacing, fonts, breakpoints
   - CSS custom properties (`:root` variables in `globals.css`, `variables.css`)
   - Theme files (`theme.ts`, `tokens.js`, `styles/theme.*`)
   - Component library config (shadcn `components.json`, MUI theme)
2. Scan shared components for UI patterns:
   - Button, Input, Select, Card, Modal, Table, Toast, Avatar, Badge, etc.
   - Identify variants (size, color, state) from props/types
3. Apply ID 10-increment: DS-010, CMP-010
4. Render via `_meta/templates/design-system.template.md`
5. Generate companion `design-system.json`

6. Update `data/links.json` for both Screens and Design System
7. If no UI pages found → skip Screens and Design System, warn: "No UI pages detected. Screens and Design System skipped. Use --pages to specify path."

### Step 5: Synthesize Plan — SRS

**Agent:** u-agent-plan (reversed input: Design docs → SRS instead of dropzone digest → SRS)
**Input:** All Design documents from Steps 2-4
**Output:** `docs/{app}/plan/srs.md` + `srs.json` (status: Draft)

Reverse-infer requirements from concrete artifacts (see `references/plan-synthesis.md` § 1):

1. **FR (Functional Requirements):**
   - Group ERD entities + API endpoints by domain area
   - One FR per domain group
   - Example: entities `User`, `Session`, `Role` + endpoints `/auth/*` → FR-010 "User Authentication & Authorization"
   - Priority: `Must` for core domains (most entities/endpoints), `Should` for secondary, `Could` for peripheral

2. **US (User Stories):**
   - One US per API endpoint group or screen workflow
   - Derive actor from auth/role data: admin, authenticated user, public
   - Format: "As a {role}, I can {action} so that {benefit}"
   - Infer benefit from domain context
   - Each US traces to parent FR

3. **FT (Features):**
   - One FT per screen (from screens.json) or distinct API capability
   - Most granular level — maps directly to testable units
   - Story points: estimate from screen complexity (component count, API calls)
   - Each FT traces to parent US

4. **NFR (Non-Functional Requirements):**
   - Scan code for observable patterns:
     - Rate limiting middleware → NFR "Performance: Rate Limiting"
     - CORS config → NFR "Security: Cross-Origin Policy"
     - Cache headers/config → NFR "Performance: Caching Strategy"
     - Auth middleware → NFR "Security: Authentication"
     - Error boundary/handler → NFR "Reliability: Error Handling"
     - i18n config → NFR "Usability: Internationalization"
     - Responsive breakpoints → NFR "Usability: Responsive Design"

5. **Stakeholders:** Derive from role/permission model (admin, user, guest, etc.)

6. **Glossary:** Extract domain terms from model names, enum values, constants

7. Build traceability chains: FR→US→FT with ID 10-increment (FR-010, US-010, FT-010)

8. Render via `_meta/templates/srs.template.md`
9. Generate companion `srs.json`
10. Update `data/links.json`

### Step 6: Synthesize Plan — IA

**Agent:** u-agent-plan (reversed input: Screens + routing → IA instead of SRS → IA)
**Input:** Screens document, routing config, SRS output from Step 5
**Output:** `docs/{app}/plan/ia.md` + `ia.json` (status: Draft)

Reverse-infer information architecture (see `references/plan-synthesis.md` § 2):

1. **Site Map:** Derive from routing structure
   - Nested routes → hierarchy levels
   - Route groups → logical groupings, not URL segments
   - Dynamic routes → parameterized pages

2. **Page Inventory:** From screens.json
   - Each SC item → one page entry
   - Include: route, title, description, parent section

3. **Navigation Structure:** From layout components
   - Scan for navbar, sidebar, breadcrumb, footer components
   - Extract navigation items from link lists, menu configs
   - Identify primary vs secondary navigation

4. **User Flows:** Infer from screen→API→screen transitions
   - Login flow, registration flow, CRUD flows, checkout flow, etc.
   - Identify entry points and exit points

5. Apply ID 10-increment: IA-010, IA-020
6. Render via `_meta/templates/ia.template.md`
7. Generate companion `ia.json`
8. Update `data/links.json`

### Step 7: Finalize

**Agent:** u-agent-gatekeeper (if `--loop`), otherwise u-agent-pm wraps up

1. Build complete `data/links.json` traceability graph (all FR→US→FT→SC→API→ENT edges)
2. If `--loop` → invoke u-agent-gatekeeper on all documents, max 3 retries per doc

### Output Summary

Print after completion:

```
u-reverse complete.
  App:       {app-name}
  Stack:     {detected framework} ({language})
  Generated: {N} documents (all Draft)

  Plan:    srs.md, ia.md
  Design:  erd.md, api.md, screens.md, design-system.md
  Skipped: {list of skipped docs, if any}

  Next:    Review Draft documents, then run /u-output to generate HTML
```

## Error Handling

| Condition | Action |
|-----------|--------|
| No recognizable stack detected | Error: "Could not detect project stack. Use --src, --db, --api, --pages to specify paths." |
| No DB schema found | Skip ERD; warn user. Continue with remaining docs. |
| No API routes found | Skip API; warn user. Continue with remaining docs. |
| No UI pages found | Skip Screens, Design System, IA; warn user. Generate ERD, API, SRS only. |
| All extraction steps skipped | Error: "No extractable artifacts found. Ensure --src points to a valid source directory." |
| Existing Final documents | Warn + confirm. Backup to `data/reverse-backup-{timestamp}/` before overwriting. |
| `.u-maker/` absent | Auto-run u-init (no error, handled transparently). |
| Config version mismatch | Error: "Config version {version} is not supported. Run /u-init --migrate." |

## Reference Files

- **`references/stack-detection.md`** — Framework detection rules, file patterns, override behavior
- **`references/code-extraction.md`** — ERD/API/Screens/DS extraction logic per stack
- **`references/plan-synthesis.md`** — SRS/IA reverse-inference rules from Design docs
