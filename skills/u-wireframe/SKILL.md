---
name: u-wireframe
description: "This skill should be used when the user asks to 'generate wireframes', 'create wireframe', '/u-wireframe', or wants to produce per-screen HTML wireframe files from Screen Specification documents."
version: 3.2.0
triggers:
  - "/u-wireframe"
  - "wireframe"
  - "generate wireframe"
  - "screen wireframe"
---

# u-wireframe — Screen Wireframe Generator

`/u-wireframe [--app {name}] [--screen {SCR-ID}] [--all]`

Generate individual HTML wireframe files for each screen defined in `docs/{app}/design/screens.md` + `screens.json`. Each wireframe is a self-contained HTML page with mockup UI, Design/Develop annotations, related ERD entities, Sequence Diagram, and Screen Flow.

**Engine Dependencies:** doc-engine, html-engine, dep-engine
**Gate Prerequisite:** Design phase documents exist (screens.json, erd.json, api.json)

## Input Sources

| Source | Path | Purpose |
|--------|------|---------|
| Screen Spec | `docs/{app}/design/screens.md` + `screens.json` | Screen inventory, components, API calls, state, validation |
| ERD | `docs/{app}/design/erd.md` + `erd.json` | Data model entities related to each screen |
| API Contract | `docs/{app}/design/api.md` + `api.json` | API endpoints for sequence diagrams |
| Screen Flow | `docs/{app}/design/screen-flow.md` + `screen-flow.json` | Navigation flow between screens |
| Design System | `docs/{app}/design/design-system.md` + `design-system.json` | Design tokens, UI component specs |
| IA | `docs/{app}/plan/ia.md` + `ia.json` | Page hierarchy for sidebar navigation |

## Output Structure

```
output/{app}/design/wireframes/
  index.html              # Wireframe browser (sidebar + iframe viewer)
  {SCR-ID}.html           # Per-screen wireframe page (e.g., SCR-APP-001.html)
```

## Execution Flow

### Step 0: Verify Design Documents

1. Read `docs/{app}/design/screens.json` — MUST exist
2. Read `docs/{app}/design/erd.json` — for entity mapping
3. Read `docs/{app}/design/api.json` — for sequence diagrams
4. Read `docs/{app}/design/screen-flow.json` — for flow navigation
5. Read `docs/{app}/design/design-system.json` — for tokens/components
6. If screens.json missing -> error: "Run /u-design first"

### Step 1: Build Screen-to-Data Map

For each screen in `screens.json`:

1. **Components**: Extract component list with types, props, interactions
2. **API Calls**: Map API endpoint IDs to `api.json` definitions -> build sequence diagram data
3. **ERD Entities**: Trace API response types -> find matching entities in `erd.json`
4. **Screen Flow**: Find inbound/outbound navigation edges from `screen-flow.json`
5. **Design Tokens**: Map component types to design-system tokens

### Step 2: Generate Per-Screen HTML

For each screen, generate `{SCR-ID}.html` using `references/wireframe-page.template.html`.

**Page Structure — 6 Sections (top→bottom):**

| Section | Description |
|---------|-------------|
| **A. Document Header** | Sticky top bar: SCR-ID badge, screen name, route path, related FT/FR links, 전체 목록 link |
| **B. Stage** | 2-column grid: App Frame (sidebar + main mockup) + Annotation Panel (annotations + business rules) |
| **C. Component Spec** | Component specification table (#, 컴포넌트, 타입, Props, API) |
| **D. Logic Flow Diagrams** | **2-column grid** of inline SVG diagrams (Condition Flow, Sequence, Data Flow, etc.) |
| **E. Overlay UI** | Modals, BottomSheets, Popups, Drawers, Toast — each as a rendered card with component mockup |
| **F. Annotation Legend** | Flat list of all annotation markers with component names |

#### B. Stage — App Frame + Annotation Panel

**App Frame** (left, `grid-template-columns: 1fr 300px`):
- **Sidebar** (196px, dark): App name/description + IA navigation menu. Current screen = `.active`
- **Main Area**: Page header (breadcrumb + title with back button) + Page body (components rendered as HTML mockup with annotation markers `<span class="mk">N</span>`) + Footer action bar (submit/cancel buttons)

**Annotation Panel** (right, 300px):
- Numbered annotation items matching mockup markers
- Each item: marker number + title (bold) + description (component behavior, API calls, conditions)
- Business rules section at bottom: `BR-{SCR-ID}-NN` items

#### B. Wireframe Mockup Rendering Rules

Components are rendered as styled HTML elements (not SVG, not images) using the template's built-in CSS classes:

| Component Type | CSS Class / Rendering |
|---------------|-----------|
| **Table** | `.wf-table` with thead/tbody, sample rows, `.wf-badge-*` status badges |
| **Form** | `.wf-input`, `.wf-label`, `.wf-select` fields with sample values |
| **Button** | `.btn.primary`, `.btn.secondary`, `.btn.danger`, `.btn.outline` |
| **Card** | `.card` with `.card-title` + content |
| **Tabs** | `.wf-tabs` + `.wf-tab.active` |
| **Photo Grid** | `.photo-grid` + `.photo-thumb` + `.photo-add` (dashed border) |
| **Signature** | `.sign-canvas` + `.sign-reset` |
| **Info Grid** | `.info-grid` + `.info-row` (label/value pairs) |
| **Sidebar Nav** | `.sb-list` + `.sbi` items (`.sbi.active`, `.sbi.sub`) |
| **Badge** | `.wf-badge-blue`, `.wf-badge-green`, `.wf-badge-red`, `.wf-badge-amber`, `.wf-badge-gray` |
| **Stats Card** | `.wf-stat` with `.wf-stat-value` + `.wf-stat-label` |

All annotation markers use `<span class="mk">N</span>` (blue circle with number).

#### D. Logic Flow Diagrams — 2-Column Grid

Diagrams are rendered as **inline SVG** (`<svg class="diag">`) in a **2-column grid** (`.diag-grid`).

Each diagram block (`.diag-block`) has:
- `<h3>` title (uppercase, cyan accent)
- `<svg class="diag" viewBox="...">` with inline SVG content

**Diagram types per screen** (generate what's relevant):

| Diagram | Purpose | When to include |
|---------|---------|-----------------|
| **Condition Flow** | Submit/action activation conditions, validation logic | Screens with conditional button states or multi-step validation |
| **Sequence Diagram** | API call sequence (Actor → Frontend → Backend → DB) | Screens with API calls |
| **Data Flow** | State/data flow between components and stores | Screens with complex state management |
| **Screen Flow** | Navigation inbound/outbound with trigger labels | All screens (from screen-flow.json) |

SVG style tokens (use CSS variables from template):
- Node: `var(--svg-node)` (#3b82f6) + `var(--svg-node-text)` (#fff)
- Condition diamond: `var(--svg-condition)` (#f59e0b)
- Action/success: `var(--svg-action)` (#10b981)
- Arrows: `var(--svg-arrow)` (#6b7280)
- Actor: `var(--svg-actor)` (#8b5cf6)
- Background: `var(--svg-bg)` (#f8fafc)

Use `.diag-block.full` (spans 2 columns) for wide diagrams like sequence diagrams.

#### E. Overlay UI — Modals / BottomSheets / Popups

**All overlay components (modals, bottomsheets, popups, drawers, toasts) used by the screen MUST be rendered at the bottom** in a 2-column grid (`.overlay-grid`).

Each overlay is an `.overlay-card` containing:
- **Header**: Type badge (`.overlay-type-badge`) + overlay name + annotation marker
- **Body**: Rendered component mockup (same HTML rendering rules as main wireframe body)

Overlay types and badge colors:

| Type | Badge Style | Example |
|------|------------|---------|
| `modal` | Blue | Confirm dialog, form modal, detail modal |
| `bottomsheet` | Amber | Mobile action sheet, filter panel |
| `popup` | Purple | Tooltip, popover, context menu |
| `drawer` | Green | Side panel, filter drawer |
| `toast` | Red | Success/error notification |

Extract overlays from `screens.json` component list — components with type containing `Modal`, `BottomSheet`, `Popup`, `Drawer`, `Toast`, or `Dialog`.

If the screen has **no overlay components**, omit section E entirely.

### Step 3: Generate Index HTML (Browser)

Generate `index.html` as a sidebar browser using the dark-theme template.

See `references/wireframe-index.template.html` for the full template.

**Key structure:**
- Dark sidebar (260px) with search, tree navigation grouped by IA category
- iframe viewer (flex:1) loading individual wireframe pages
- Mobile-responsive hamburger menu
- Footer with screen count and generation date

**FILES array generation:**
```javascript
// Auto-generated from screens.json
const FILES = [
  {"path":"{SCR-ID}.html","name":"{SCR-ID}: {screenName}","icon":"...","dir":"wireframes","section":"Wireframes","group":"{category}"}
];
```

### Step 4: Update Parent Navigation

1. Add wireframes link to `output/{app}/index.html` sidebar under Design section
2. Add link: `<a href="design/wireframes/index.html">Wireframes</a>`

## Checklist

- [ ] All screens from screens.json have individual HTML files
- [ ] Each wireframe has: mockup + sequence diagram + screen flow + ERD
- [ ] Design/Develop annotations panel is populated
- [ ] Mermaid diagrams render correctly (erDiagram, sequenceDiagram, flowchart)
- [ ] Index browser has correct FILES array with all screens
- [ ] Sidebar groups match IA categories
- [ ] Dark/light toggle works on all pages
- [ ] Navigation links (Index, FT, FR) are correct
- [ ] ERD constraints: PK/FK/UK never combined
- [ ] Curved connectors on all Mermaid flowcharts (curve: 'basis')
- [ ] Footer: Copyright(c) 2026 U PLEAT
- [ ] Self-contained HTML (Tailwind CDN, Mermaid CDN, no external deps)

## Reference Files

- **`references/wireframe-page.template.html`** — Single screen wireframe page template
- **`references/wireframe-index.template.html`** — Browser index page template (sidebar + iframe)
