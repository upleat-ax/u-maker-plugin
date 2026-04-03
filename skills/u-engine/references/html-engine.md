# html-engine Reference

The html-engine converts SSoT markdown documents into polished, self-contained HTML pages. It handles markdown parsing, inline SVG diagram generation (primary), Mermaid fallback for UML diagrams, base64 image embedding, Tailwind CSS styling, dark/light mode toggling, sidebar navigation, and Table of Contents generation. **SVG is the preferred diagram format** — self-contained, offline-capable, instantly rendered without CDN dependencies.

## 1. MD to HTML Conversion Pipeline

The full conversion pipeline processes a single `.md` document into a standalone `.html` file:

```
Step 1: Read .md source
Step 2: Parse YAML frontmatter → extract metadata
Step 3: Convert markdown body → HTML fragments
Step 4: Generate inline SVG diagrams from .json companion data (primary)
Step 5: Detect and prepare Mermaid code blocks (fallback: erDiagram, classDiagram, sequenceDiagram only)
Step 6: Scan for image references → encode as base64
Step 7: Generate Table of Contents from headings
Step 8: Apply output-page.template.html wrapper
Step 9: Inject dark/light toggle, Tailwind, Mermaid CDN
Step 10: Write to output/{app}/{phase}/{docName}.html
Step 11: Update output/{app}/index.html sidebar navigation
```

### Input / Output Paths

| Input | Output |
|-------|--------|
| `docs/{app}/plan/srs.md` | `output/{app}/plan/srs.html` |
| `docs/{app}/plan/ia.md` | `output/{app}/plan/ia.html` |
| `docs/{app}/design/erd.md` | `output/{app}/design/erd.html` |
| `docs/{app}/design/api.md` | `output/{app}/design/api.html` |
| `docs/{app}/design/screens.md` | `output/{app}/design/screens.html` |
| `docs/{app}/design/design-system.md` | `output/{app}/design/design-system.html` |
| `docs/{app}/check/testcases.md` | `output/{app}/check/testcases.html` |
| `docs/{app}/check/test-results.md` | `output/{app}/check/test-results.html` |

### Markdown Conversion Rules

- **Headings** (`# H1` through `###### H6`): Convert to `<h1>` through `<h6>` with auto-generated `id` attributes for TOC anchoring. The `id` is derived from the heading text: lowercase, spaces replaced with hyphens, special characters removed.
- **Tables**: Convert to `<table>` with Tailwind classes: `class="w-full border-collapse text-sm"`. Header row uses `<thead>` with `class="bg-gray-100 dark:bg-gray-800"`. Body rows alternate with `even:bg-gray-50 dark:even:bg-gray-900`.
- **Code blocks**: Wrap in `<pre><code>` with `class="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 overflow-x-auto text-sm font-mono"`. Language-specific syntax highlighting via class `language-{lang}`.
- **Lists**: Convert `- item` to `<ul>` and `1. item` to `<ol>` with appropriate Tailwind spacing classes.
- **Bold / Italic**: `**bold**` → `<strong>`, `*italic*` → `<em>`.
- **Links**: `[text](url)` → `<a href="url" class="text-blue-600 dark:text-blue-400 underline">text</a>`.

## 2. Mandatory Diagram Requirements

Every HTML document MUST include diagrams appropriate to its document type. Diagrams are not optional — they are a core part of the HTML output that distinguishes it from the raw markdown. When converting `.md` to `.html`, the engine MUST ensure the following diagrams exist. Generate them from the companion `.json` data if not present in source `.md`.

### Rendering Priority: SVG-first

**Inline SVG is the preferred rendering method for all diagrams.** SVG is self-contained, works offline, renders instantly without CDN dependencies, and supports dark/light mode via CSS variables.

| Priority | Method | When to Use |
|----------|--------|-------------|
| **1st** | Inline SVG | All diagrams by default — flowcharts, trees, pie charts, matrices, navigation maps, state diagrams |
| **2nd** | Mermaid CDN | Only for complex UML-specific diagrams where SVG hand-generation is impractical: `erDiagram`, `classDiagram`, `sequenceDiagram` |

### Diagram Requirements per Document

| Document | Required Diagrams | Rendering |
|----------|-------------------|-----------|
| **SRS** | FR→US→FT traceability tree | SVG |
| **SRS** | MoSCoW priority distribution (donut/bar chart) | SVG |
| **SRS** | Stakeholder-FR responsibility matrix | SVG |
| **IA** | Site map hierarchy | SVG |
| **IA** | User flows (per major US) | SVG |
| **IA** | Navigation structure | SVG |
| **ERD** | Full entity-relationship diagram | Mermaid `erDiagram` |
| **ERD** | Entity grouping by domain | SVG |
| **API** | Data model class diagram | Mermaid `classDiagram` |
| **API** | Request/response sequence per endpoint group | Mermaid `sequenceDiagram` |
| **API** | Endpoint-to-FR traceability | SVG |
| **Screens** | Screen flow / navigation map | SVG |
| **Screens** | State transitions per interactive screen | SVG |
| **Design System** | Token hierarchy (color, spacing, typography) | SVG |
| **Design System** | Color palette swatches | SVG |
| **Test Cases** | FT→TC coverage map | SVG |
| **Test Cases** | TC distribution by type (donut chart) | SVG |
| **Test Results** | FR→US→FT→TC→Result full traceability | SVG |
| **Test Results** | Pass/Fail summary (donut chart) | SVG |

### SVG Diagram Generation Rules

1. **Placement:** Insert each diagram immediately after the relevant section heading.
2. **Responsive:** Use `viewBox` + `width="100%"` on all `<svg>` elements. Never use fixed pixel widths.
3. **Curved connectors:** All arrows/lines MUST use `<path>` with cubic Bezier curves (`C` or `Q`). NEVER use `<line>` or straight `<polyline>`.
4. **Arrowhead markers:** Define reusable `<marker id="arrowhead">` inside `<defs>`. Use `marker-end="url(#arrowhead)"` on paths.
5. **Node labels:** Every node must display a human-readable label. Use `<text>` inside `<g>` groups with the node shape.
6. **Color coding:**
   - Plan phase: `#3b82f6` (blue-500)
   - Design phase: `#10b981` (green-500)
   - Check phase: `#f59e0b` (amber-500)
   - Failed/blocked: `#ef4444` (red-500)
   - Neutral/border: `#334155` (slate-700)
   - Background: `#f8fafc` (slate-50)
7. **Dark mode:** Use CSS variables or `currentColor` so diagrams adapt. Wrap color-sensitive fills in `class` attributes that respond to `dark:` selectors:
   ```svg
   <rect class="fill-white dark:fill-gray-800" ... />
   <text class="fill-gray-900 dark:fill-gray-100" ... />
   ```
8. **Node shapes by type:**
   - Rectangles with rounded corners (`rx="8"`) for entities/screens/features
   - Circles for status indicators
   - Diamonds (`<polygon>`) for decision points
   - Pill shapes (`rx="16"`) for start/end nodes
9. **Maximum nodes:** If a diagram exceeds 30 nodes, split into sub-diagrams by logical grouping.
10. **Chart types (SVG):**
    - **Donut chart:** `<circle>` with `stroke-dasharray` for segments. Include center label with count/percentage.
    - **Bar chart:** `<rect>` elements with labels. Horizontal bars for comparison.
    - **Tree/hierarchy:** Top-down layout with curved parent→child connectors.
    - **Matrix:** Grid of `<rect>` cells with fill color intensity indicating coverage.
11. **Fallback:** If source data is insufficient, insert a placeholder `<div class="text-center text-gray-400 py-8">` with note: `"Diagram will be generated when {dependency} data is available."`

## 3. Mermaid Rendering Configuration (Fallback Only)

Mermaid is used ONLY for complex UML diagrams (`erDiagram`, `classDiagram`, `sequenceDiagram`) where inline SVG hand-generation is impractical. All other diagram types MUST use inline SVG (see § 2). Mermaid code blocks are preserved as `<pre class="mermaid">` elements for Mermaid.js to process client-side.

### CDN Script Inclusion

```html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js';
  mermaid.initialize({
    startOnLoad: true,
    theme: 'default',
    flowchart: {
      curve: 'basis',
      useMaxWidth: true,
      htmlLabels: true
    },
    er: {
      useMaxWidth: true
    },
    sequence: {
      useMaxWidth: true,
      mirrorActors: false
    },
    themeVariables: {
      fontFamily: 'Inter, system-ui, sans-serif',
      fontSize: '14px'
    }
  });
</script>
```

### Key Configuration Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `theme` | `'default'` | Use Mermaid default theme (light-friendly) |
| `flowchart.curve` | `'basis'` | Curved connectors instead of straight-line arrows |
| `startOnLoad` | `true` | Auto-render all `.mermaid` blocks on page load |
| `useMaxWidth` | `true` | Responsive diagram sizing |

### Mermaid Diagram Types

| Mermaid Type | u-maker Usage | Document |
|--------------|---------------|----------|
| `erDiagram` | Entity-Relationship diagrams | ERD |
| `classDiagram` | API model diagrams | API |
| `flowchart` | Navigation flows, workflows | IA, Screens |
| `sequenceDiagram` | API interaction sequences | API, Screens |
| `stateDiagram-v2` | State transitions | Screens |

### erDiagram Constraint Rules

In Mermaid `erDiagram`, PK, FK, and UK constraints MUST NEVER be combined on a single attribute. Each constraint occupies its own annotation:

```
CORRECT:
  entity {
    string id PK
    string email UK
    string org_id FK
  }

INCORRECT (never do this):
  entity {
    string id PK,FK
    string email PK,UK
  }
```

### Dark Mode Mermaid

When dark mode is active, re-initialize Mermaid with the `dark` theme:

```javascript
function toggleMermaidTheme(isDark) {
  mermaid.initialize({
    theme: isDark ? 'dark' : 'default',
    flowchart: { curve: 'basis' }
  });
  // Re-render all mermaid diagrams
  document.querySelectorAll('.mermaid').forEach(el => {
    const code = el.getAttribute('data-mermaid-source');
    if (code) {
      el.removeAttribute('data-processed');
      el.innerHTML = code;
    }
  });
  mermaid.run();
}
```

## 4. SVG Inline Generation

For diagrams that are not Mermaid-based (custom flow diagrams, architecture diagrams, wireframes), html-engine generates inline SVG directly in the HTML output.

### SVG Rules

1. **Curved connectors**: All connectors (arrows, lines) MUST use curved paths (`<path>` with cubic Bezier curves), never straight lines (`<line>`).

```svg
<!-- CORRECT: Curved connector -->
<path d="M 50,100 C 100,100 100,200 150,200"
      stroke="#334155" stroke-width="2" fill="none"
      marker-end="url(#arrowhead)" />

<!-- INCORRECT: Straight line -->
<line x1="50" y1="100" x2="150" y2="200" stroke="#334155" />
```

2. **Arrowhead marker definition**: Include a reusable arrowhead marker in each SVG:

```svg
<defs>
  <marker id="arrowhead" markerWidth="10" markerHeight="7"
          refX="10" refY="3.5" orient="auto">
    <polygon points="0 0, 10 3.5, 0 7" fill="#334155" />
  </marker>
</defs>
```

3. **Responsive sizing**: Use `viewBox` attribute and `width="100%"` for responsive SVGs:

```svg
<svg viewBox="0 0 800 600" width="100%" xmlns="http://www.w3.org/2000/svg">
```

4. **Color palette**: Use Tailwind-aligned colors for consistency:
   - Backgrounds: `#f8fafc` (slate-50), `#f1f5f9` (slate-100)
   - Borders/lines: `#334155` (slate-700)
   - Primary accent: `#3b82f6` (blue-500)
   - Success: `#22c55e` (green-500)
   - Warning: `#f59e0b` (amber-500)
   - Error: `#ef4444` (red-500)

5. **Text styling**: Use `font-family="Inter, system-ui, sans-serif"` and appropriate font sizes (12-16px).

## 5. Base64 Image Encoding

All images referenced in the markdown source MUST be embedded as base64 data URIs in the output HTML. This ensures the HTML file is completely self-contained.

### Encoding Procedure

1. Scan the rendered HTML for `<img src="...">` tags
2. For each image with a local file path (not an external URL):
   a. Read the image file as binary
   b. Detect MIME type from file extension
   c. Encode as base64
   d. Replace `src` attribute with `data:{mime};base64,{encoded}`

### Supported Image Formats

| Extension | MIME Type |
|-----------|-----------|
| `.png` | `image/png` |
| `.jpg`, `.jpeg` | `image/jpeg` |
| `.gif` | `image/gif` |
| `.svg` | `image/svg+xml` |
| `.webp` | `image/webp` |

### Example Transformation

```html
<!-- Before -->
<img src="assets/logo.png" alt="Logo" />

<!-- After -->
<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUg..." alt="Logo" />
```

### External Images

External images (URLs starting with `http://` or `https://`) are left as-is. They are NOT converted to base64.

## 6. Tailwind CSS Integration

All generated HTML uses Tailwind CSS utility classes for styling. Tailwind is loaded via CDN to keep output files self-contained.

### CDN Inclusion

```html
<script src="https://cdn.tailwindcss.com"></script>
<script>
  tailwind.config = {
    darkMode: 'class',
    theme: {
      extend: {
        fontFamily: {
          sans: ['Inter', 'system-ui', 'sans-serif'],
          mono: ['JetBrains Mono', 'Fira Code', 'monospace']
        }
      }
    }
  };
</script>
```

### Base Layout Classes

```html
<body class="bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100
             font-sans leading-relaxed">
  <div class="flex min-h-screen">
    <!-- Sidebar -->
    <nav class="w-64 bg-gray-50 dark:bg-gray-900 border-r border-gray-200
                dark:border-gray-800 p-4 sticky top-0 h-screen overflow-y-auto">
    </nav>
    <!-- Main content -->
    <main class="flex-1 max-w-4xl mx-auto px-8 py-12">
    </main>
  </div>
</body>
```

### Typography Scale

| Element | Classes |
|---------|---------|
| `<h1>` | `text-3xl font-bold mt-12 mb-6 text-gray-900 dark:text-white` |
| `<h2>` | `text-2xl font-semibold mt-10 mb-4 text-gray-800 dark:text-gray-100` |
| `<h3>` | `text-xl font-semibold mt-8 mb-3 text-gray-800 dark:text-gray-200` |
| `<h4>` | `text-lg font-medium mt-6 mb-2 text-gray-700 dark:text-gray-300` |
| `<p>` | `text-base leading-7 mb-4 text-gray-700 dark:text-gray-300` |
| `<code>` inline | `bg-gray-100 dark:bg-gray-800 px-1.5 py-0.5 rounded text-sm font-mono` |

## 7. Dark/Light Toggle

Every generated HTML page includes a dark/light mode toggle switcher in the top-right corner of the page header.

### Default Mode

Light mode is the default. The `<html>` element starts without the `dark` class.

### Toggle Implementation

```html
<button id="theme-toggle"
        class="fixed top-4 right-4 z-50 p-2 rounded-lg
               bg-gray-200 dark:bg-gray-700
               hover:bg-gray-300 dark:hover:bg-gray-600
               transition-colors duration-200"
        aria-label="Toggle dark mode">
  <svg id="sun-icon" class="w-5 h-5 hidden dark:block" fill="currentColor" viewBox="0 0 20 20">
    <!-- Sun icon SVG path -->
  </svg>
  <svg id="moon-icon" class="w-5 h-5 block dark:hidden" fill="currentColor" viewBox="0 0 20 20">
    <!-- Moon icon SVG path -->
  </svg>
</button>

<script>
  const toggle = document.getElementById('theme-toggle');
  const html = document.documentElement;

  // Check saved preference or system preference
  if (localStorage.getItem('theme') === 'dark' ||
      (!localStorage.getItem('theme') &&
       window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    html.classList.add('dark');
  }

  toggle.addEventListener('click', () => {
    html.classList.toggle('dark');
    const isDark = html.classList.contains('dark');
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
    // Re-initialize Mermaid with appropriate theme
    if (typeof mermaid !== 'undefined') {
      toggleMermaidTheme(isDark);
    }
  });
</script>
```

### Persistence

Theme preference is saved in `localStorage` under the key `theme`. On page load, the saved preference is checked before the system preference.

## 8. Sidebar Navigation (output-index.html)

The `output/{app}/index.html` file serves as the project's documentation portal with a sidebar navigation listing all generated HTML documents.

### Sidebar Structure

```html
<nav class="w-64 bg-gray-50 dark:bg-gray-900 border-r border-gray-200
            dark:border-gray-800 p-4 sticky top-0 h-screen overflow-y-auto">
  <h2 class="text-lg font-bold mb-4 text-gray-900 dark:text-white">
    {App Name}
  </h2>

  <!-- Plan Phase -->
  <div class="mb-6">
    <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-500
               dark:text-gray-400 mb-2">Plan</h3>
    <ul class="space-y-1">
      <li>
        <a href="plan/srs.html"
           class="block px-3 py-1.5 rounded text-sm text-gray-700
                  dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-800">
          SRS
        </a>
      </li>
      <li>
        <a href="plan/ia.html" class="...">IA</a>
      </li>
    </ul>
  </div>

  <!-- Design Phase -->
  <div class="mb-6">
    <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-500
               dark:text-gray-400 mb-2">Design</h3>
    <ul class="space-y-1">
      <li><a href="design/erd.html" class="...">ERD</a></li>
      <li><a href="design/api.html" class="...">API</a></li>
      <li><a href="design/screens.html" class="...">Screens</a></li>
      <li><a href="design/design-system.html" class="...">Design System</a></li>
    </ul>
  </div>

  <!-- Check Phase -->
  <div class="mb-6">
    <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-500
               dark:text-gray-400 mb-2">Check</h3>
    <ul class="space-y-1">
      <li><a href="check/testcases.html" class="...">Test Cases</a></li>
      <li><a href="check/test-results.html" class="...">Test Results</a></li>
    </ul>
  </div>
</nav>
```

### Dynamic Sidebar Update

When a new HTML document is generated, the sidebar navigation in `output/{app}/index.html` MUST be updated:

1. Read existing `index.html`
2. Parse the `<nav>` sidebar section
3. Determine which phase group the new document belongs to (Plan, Design, Check)
4. Add a new `<li><a>` entry if it does not already exist
5. Sort entries within each phase group alphabetically
6. Write updated `index.html`

### Active Page Highlighting

When viewing a specific document page, the corresponding sidebar entry is highlighted:

```html
<a href="plan/srs.html"
   class="block px-3 py-1.5 rounded text-sm bg-blue-100 dark:bg-blue-900
          text-blue-700 dark:text-blue-300 font-medium">
  SRS
</a>
```

## 9. TOC Auto-Generation

Every document HTML page includes an auto-generated Table of Contents derived from the document's headings.

### TOC Generation Algorithm

1. Scan the HTML body for all heading elements (`<h2>` through `<h4>` — skip `<h1>` as it is the document title)
2. Build a nested list structure based on heading levels
3. Each TOC entry links to the heading's `id` attribute via anchor
4. Insert the TOC after the document title (`<h1>`) and before the first `<h2>`

### TOC HTML Structure

```html
<div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-6 mb-8 border
            border-gray-200 dark:border-gray-800">
  <h2 class="text-lg font-semibold mb-3 text-gray-900 dark:text-white">
    Table of Contents
  </h2>
  <ul class="space-y-1 text-sm">
    <li>
      <a href="#functional-requirements"
         class="text-blue-600 dark:text-blue-400 hover:underline">
        Functional Requirements
      </a>
      <ul class="ml-4 mt-1 space-y-1">
        <li>
          <a href="#user-registration"
             class="text-gray-600 dark:text-gray-400 hover:underline">
            User Registration
          </a>
        </li>
      </ul>
    </li>
  </ul>
</div>
```

### Heading ID Generation

Heading `id` attributes are derived from the heading text:

1. Convert to lowercase
2. Replace spaces with hyphens
3. Remove special characters (except hyphens and underscores)
4. Remove consecutive hyphens
5. Trim leading/trailing hyphens

Example: `## 3. Functional Requirements` → `id="3-functional-requirements"`

## 10. Footer Template

Every generated HTML page includes a standard footer at the bottom of the main content area.

### Footer HTML

```html
<footer class="mt-16 pt-8 border-t border-gray-200 dark:border-gray-800">
  <div class="flex items-center justify-between text-sm text-gray-500
              dark:text-gray-400">
    <p>Copyright(c) 2026 U PLEAT</p>
    <p>Generated by u-maker v4.0.0</p>
  </div>
</footer>
```

### Footer Rules

1. The copyright notice is always `Copyright(c) 2026 U PLEAT` — no variation.
2. The version shown matches the u-maker plugin version from `SKILL.md` frontmatter.
3. The footer appears inside `<main>`, after all document content and before the closing `</main>` tag.
4. The footer border separates it visually from the document content.

## 11. Complete HTML Page Structure

The final assembled HTML page follows this structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{Document Title} — {App Name}</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>/* Tailwind config */</script>
  <script type="module">/* Mermaid init */</script>
</head>
<body class="bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100 font-sans">
  <!-- Dark/Light Toggle -->
  <button id="theme-toggle">...</button>

  <div class="flex min-h-screen">
    <!-- Sidebar (on index.html) or hidden (on doc pages) -->
    <nav>...</nav>

    <!-- Main Content -->
    <main class="flex-1 max-w-4xl mx-auto px-8 py-12">
      <h1>{Document Title}</h1>

      <!-- Metadata Badge Bar -->
      <div class="flex gap-2 mb-6">
        <span class="badge">Status: {status}</span>
        <span class="badge">Version: {version}</span>
        <span class="badge">App: {app}</span>
      </div>

      <!-- Table of Contents -->
      <div class="toc">...</div>

      <!-- Document Body -->
      {converted HTML content}

      <!-- Footer -->
      <footer>
        <p>Copyright(c) 2026 U PLEAT</p>
      </footer>
    </main>
  </div>

  <script>/* Theme toggle logic */</script>
</body>
</html>
```
