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

For each screen, generate `{SCR-ID}.html` using the wireframe page template:

**Page Structure (3-column layout):**

```
+------------------+---------------------------+---------------------+
| Left Sidebar     | Main Content              | Right Annotations   |
| (App Navigation) | (Wireframe Mockup)        | (Design + Develop)  |
+------------------+---------------------------+---------------------+
|                  | A. Wireframe Mockup       |                     |
|                  | B. Sequence Diagram       |                     |
|                  | C. Screen Flow            |                     |
|                  | D. Related ERD            |                     |
+------------------+---------------------------+---------------------+
```

**A. Wireframe Mockup Section:**
- Render actual UI layout based on screen components
- Use Tailwind CSS for component rendering (not SVG)
- Components: tables, forms, buttons, inputs, cards, modals, tabs, badges, etc.
- Include sample data from screen spec
- Show numbered annotation markers (circled numbers)

**B. Sequence Diagram (Mermaid):**
- Participants: User, Frontend ({SCR-ID}), Backend API, Database
- Show API calls from screen's `apiCalls` section
- Include request/response flow

**C. Screen Flow:**
- Show inbound screens (which screens navigate here)
- Show outbound screens (where this screen navigates to)
- Use Mermaid flowchart with curved connectors
- Include trigger labels (e.g., "Click row", "Back button")

**D. Related ERD (Mermaid):**
- Extract only entities related to this screen's API responses
- Use Mermaid erDiagram subset
- PK/FK/UK constraints never combined

**Right Annotations Panel:**
- **Design Annotations**: Numbered list matching mockup markers
  - Component descriptions, layout notes, loading states, error states
- **Develop Annotations**: Implementation guidance
  - API endpoints with keys, state management, error handling

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

## Per-Screen HTML Template

See `references/wireframe-page.template.html` for the complete template.

### Header Bar

```html
<div class="header-bar">
  <span class="scr-badge">{SCR-ID}</span>
  <span class="scr-title">{screenName}</span>
  <span class="scr-path">{routePath}</span>
  <!-- Right links -->
  <a href="index.html">Index</a>
  <a href="#">FT-{related}</a>
  <a href="#">FR-{related}</a>
</div>
```

### Wireframe Mockup Rendering Rules

Components are rendered as Tailwind-styled HTML elements (not images):

| Component Type | Rendering |
|---------------|-----------|
| **Table** | `<table>` with thead/tbody, sample rows, status badges |
| **Form** | Input fields, labels, validation indicators |
| **Button** | Styled buttons with variant (primary/secondary/danger) |
| **Card** | Bordered container with header/body |
| **Tabs** | Tab bar with active indicator + tab content panels |
| **Modal** | Overlay dialog with backdrop |
| **Sidebar Nav** | Vertical menu with icons and active state |
| **Header** | Top bar with breadcrumb, user info, actions |
| **Badge** | Colored pill with status text |
| **Pagination** | Page numbers with prev/next |
| **Search** | Input with search icon |
| **Stats Card** | Number + label + trend indicator |

### Design Token Application

Map design-system tokens to wireframe styles:

```css
:root {
  /* From design-system.json tokens */
  --color-bg-c1: #ffffff;    /* card background */
  --color-bg-c9: #f0f4ff;    /* accent background */
  --color-line-c2: #e2e8f0;  /* border */
  --color-text-c7: #334155;  /* body text */
  --radius-r3: 8px;          /* medium radius */
  --radius-r4: 12px;         /* large radius */
  --font-size-t7: 14px;      /* body text */
}
```

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
