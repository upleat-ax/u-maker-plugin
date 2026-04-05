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

# u-design — Design Phase

`/u-design [--auto] [--loop] [--app {name}]`

Design phase: generate `docs/{app}/design/` documents (ERD, API, Screens, Design System) from Plan phase documents (SRS + IA).

**Primary Agent:** u-agent-design
**Engine Dependencies:** doc-engine, dep-engine
**Gate Prerequisite:** Plan phase gate passed (SRS=Final, IA=Final)

## Execution Flow

### Step 0: Verify Plan Prerequisite

1. Check `docs/{app}/plan/` for required files: `srs.json`, `ia.json`
2. If **any file missing** → inform user: "Plan documents not found. Running /u-plan first." → invoke `/u-plan --app {name}` automatically, then return here
3. Read `docs/{app}/plan/srs.json` and `ia.json` status
4. Both must be `Final`
5. If not → error: "Plan documents exist but are not Final. Run /u-plan --loop or manually set status to Final"

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
4. Write `docs/{app}/design/screens.md` + `screens.json`
5. Update `data/links.json`

### Step 4: Generate Design System

1. Analyze SRS/IA for UI patterns, component needs
2. Define design tokens (colors, typography, spacing, radius)
3. Define UI components (Button, Input, Card, Table, Modal, etc.)
4. Define layout patterns (Sidebar+Content, Grid, Form Stack)
5. Apply ID 10-increment (DS-010, CMP-010)
6. Write `docs/{app}/design/design-system.md` + `design-system.json`
7. Update `data/links.json`

### Step 5: Gatekeeper (if --loop)

1. Invoke u-agent-gatekeeper on design documents
2. If avg score < 95 → improvement list → re-execute failed steps
3. Max 3 retries

## Reference Files

- **`references/erd-spec.md`** — Entity derivation, Mermaid erDiagram rules, constraint syntax
- **`references/api-spec.md`** — Endpoint derivation, OpenAPI structure, auth/role mapping
- **`references/screen-spec.md`** — Component taxonomy, state management, validation rules
- **`references/design-system-spec.md`** — Token naming, component variants, responsive breakpoints
