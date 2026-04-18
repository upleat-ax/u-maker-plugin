# Design System Specification Reference

> Detailed rules for generating the Design System document. **HTML-first pipeline**: CSS variables, component styles, and a live showcase HTML are created first as the primary artifact. Markdown and JSON companions are then derived from the HTML.
>
> **Rule pack:** Token scales, dark mode, accessibility, and component-API shape are governed by **`design-system-rules.md`** (compiled from dylantarre/design-system-skills). This file defines *how* to assemble the HTML pipeline; `design-system-rules.md` defines *what* the tokens and components must look like. Both files are mandatory inputs for `/u-design` Step 4.

## 1. Overview

The Design System defines the visual language and component library for the application. It establishes design tokens (colors, typography, spacing, border radius), component variants with their visual states, responsive breakpoints, and accessibility requirements.

### 1.1 HTML-First Pipeline

Unlike other SSoT documents (ERD, API, Screens) that follow the standard template→MD→JSON→HTML flow, the Design System uses a **reversed pipeline**:

```
Source Data (SRS/IA) → HTML/CSS/Variables (primary) → MD + JSON (derived)
```

| Phase | Artifact | Role |
|-------|----------|------|
| **Phase A** | `out/{app}/design/design-system.html` | **Primary** — live style guide with real CSS variables, component showcases, dark/light mode |
| **Phase B** | `docs/{app}/design/design-system.md` | **Derived** — extracted token tables, component specs for SSoT documentation |
| **Phase C** | `docs/{app}/design/design-system.json` | **Derived** — machine-readable companion extracted from the HTML |

**Rationale:** The Design System is the only SSoT document that defines actual implementation artifacts (CSS custom properties, component styles). Creating the live HTML first ensures the visual language is validated in a real rendering context before being documented.

### 1.2 Template

The primary template is `_meta/templates/design-system.template.html`. It contains:
- CSS custom properties in `:root` and `[data-theme="dark"]` blocks
- Component class definitions (`.ds-btn`, `.ds-input`, `.ds-card`, etc.)
- Live component showcases with all variants, sizes, and states
- Dark/light mode toggle with `localStorage` persistence
- Color palette swatches, typography scale, spacing scale visualizations

## 2. Phase A: Generate HTML/CSS/Variables (Primary)

### 2.1 Step-by-Step

1. **Analyze SRS/IA** for UI patterns, component needs, brand requirements
2. **Extract from Figma (if available):** When a Figma source is linked, extract tokens and components before determining values. Figma actuals take precedence over SRS/IA-derived defaults. Use `figma-mcp-go` MCP (primary) or Figma Official MCP at `https://mcp.figma.com/mcp` (fallback, requires auth). See `u-plan/references/figma-analysis.md` § 1.3 for server detection.
   - **Variables** (`get_variable_defs` / Official MCP: `get_variables`): Map Figma variable collections to CSS custom properties
     - Color variables → `--color-{name}-{shade}` (DS-010~DS-040)
     - Number variables → `--space-{n}`, `--radius-{name}` (DS-060~DS-070)
     - String variables → `--font-family-{name}` (DS-050)
   - **Styles** (`get_styles`): Map paint/text/effect/grid styles to tokens
     - Paint styles → color tokens
     - Text styles → typography tokens (family, size, weight, line-height)
     - Effect styles → shadow tokens (DS-080)
     - Grid styles → layout breakpoint validation
   - **Variable Modes**: Map mode variants to theme/responsive overrides
     - Light mode → `:root` defaults
     - Dark mode → `[data-theme="dark"]` overrides
   - **Components** (`get_local_components`): Map to CMP-xxx IDs, extract variant/size/state matrix
   - **Fonts** (`get_fonts`): Validate font availability, map to `--font-family-*` tokens
   > Full Figma extraction spec: `u-plan/references/figma-analysis.md` § 3.5 (tokens), § 4.2 (design system context)
3. **Determine token values** from project context (used when no Figma source, or to fill gaps):
   - Brand colors (derive from client requirements or use defaults)
   - Typography (font family, scale)
   - Spacing, radius, shadow, transition values
4. **Load template**: `_meta/templates/design-system.template.html`
5. **Render CSS custom properties** into the `:root` block with actual values
6. **Render component styles** — adjust component class definitions to match the token values
7. **Render showcases** — populate live examples with project-specific content
8. **Write**: `out/{app}/design/design-system.html`

### 2.2 CSS Custom Property Structure

All tokens are defined as CSS custom properties in the `:root` block. The naming convention follows a strict hierarchy:

```css
:root {
  /* DS-010: Brand Colors */
  --color-primary-{50..900}: {value};

  /* DS-020: Semantic Colors */
  --color-{success|warning|error|info}-500: {value};

  /* DS-030: Neutral Colors */
  --color-gray-{50..900}: {value};

  /* DS-040: Surface Colors */
  --color-bg-{primary|secondary|tertiary}: {value};
  --color-text-{primary|secondary|tertiary}: {value};
  --color-border-{default|strong}: {value};

  /* DS-050: Typography */
  --font-family-{sans|mono}: {value};
  --font-size-{xs|sm|base|lg|xl|2xl|3xl|4xl}: {value};
  --font-weight-{normal|medium|semibold|bold}: {value};
  --font-leading-{tight|normal|relaxed}: {value};

  /* DS-060: Spacing */
  --space-{0|1|2|3|4|5|6|8|10|12|16|20|24}: {value};

  /* DS-070: Border Radius */
  --radius-{none|sm|base|md|lg|xl|2xl|full}: {value};

  /* DS-080: Shadows */
  --shadow-{sm|base|md|lg|xl}: {value};

  /* DS-090: Transitions */
  --transition-{fast|base|slow}: {value};

  /* DS-100: Breakpoints */
  --bp-{xs|sm|md|lg|xl}: {value};

  /* DS-110: Z-Index */
  --z-{dropdown|sticky|fixed|modal-backdrop|modal|popover|tooltip|toast}: {value};
}
```

### 2.3 Dark Mode Override Block

Only surface tokens are overridden. Brand, semantic, and shade tokens remain constant:

```css
[data-theme="dark"] {
  --color-bg-primary: var(--color-gray-900);
  --color-bg-secondary: var(--color-gray-800);
  --color-bg-tertiary: var(--color-gray-700);
  --color-text-primary: var(--color-gray-50);
  --color-text-secondary: var(--color-gray-400);
  --color-text-tertiary: var(--color-gray-500);
  --color-border-default: var(--color-gray-700);
  --color-border-strong: var(--color-gray-600);
}
```

### 2.4 Component Class Naming Convention

Each component maps to a CMP-xxx ID. Class names follow BEM-like convention with `ds-` prefix:

| CMP ID | Base Class | Variants | Sizes |
|--------|-----------|----------|-------|
| CMP-010 | `.ds-btn` | `--primary`, `--secondary`, `--danger`, `--ghost` | `--sm`, `--md`, `--lg` |
| CMP-020 | `.ds-input` | `--error` | `--sm`, `--md`, `--lg` |
| CMP-030 | `.ds-card` | `--interactive` | — |
| CMP-040 | `.ds-table` | — | — |
| CMP-050 | `.ds-modal` | — | `--sm`, `--md`, `--lg` |
| CMP-060 | `.ds-toast` | `--success`, `--error`, `--warning`, `--info` | — |
| CMP-070 | `.ds-badge` | `--primary`, `--success`, `--warning`, `--error`, `--neutral` | — |

### 2.5 Showcase Sections

The HTML must include live, rendered examples for every component:

1. **Color Tokens** — swatch grids showing brand, semantic, neutral, and surface colors
2. **Typography** — type scale with actual rendered text at each size
3. **Spacing** — visual bars showing each spacing value
4. **Components** — each component shown with:
   - All variants in a single row
   - All sizes in a single row
   - Key states (default, disabled, error, focus)
5. **Layout Patterns** — visual representation of page layouts
6. **Accessibility** — focus indicator demo, contrast requirements summary

## 3. Phase B: Derive Markdown (design-system.md)

After the HTML is created, derive the markdown documentation from it.

### 3.1 Extraction Rules

1. **Parse CSS custom properties** from the `:root` block:
   - Extract each `--token-name: value;` pair
   - Group by DS-xxx category (DS-010 colors, DS-050 typography, etc.)
   - Write as markdown tables with columns: ID, Token, Value, Usage
2. **Parse component classes** from the `<style>` block:
   - Extract each `.ds-*` class and its properties
   - Group by CMP-xxx ID
   - Write component tables with: Variant, Properties, States
3. **Extract layout patterns** from showcase sections
4. **Write frontmatter**: Owner, Status, Version, Last Updated, App, Companion, Source, Figma (if applicable)
5. **Write** to `docs/{app}/design/design-system.md`

### 3.2 Frontmatter Schema

The markdown includes a `Source` field pointing back to the primary HTML:

```yaml
---
Owner: u-agent-design
Status: Draft
Version: 1.0.0
Last Updated: {ISO-8601}
App: {app-name}
Companion: design-system.json
Source: ../../out/{app}/design/design-system.html
Figma: https://www.figma.com/design/{file_key}/{file_name}?node-id={node_id}
---
```

> `Figma` 필드는 Figma 소스가 있는 경우 필수. deep link (`?node-id=...`) 형태 권장. 없으면 생략.

### 3.3 Template

Use `_meta/templates/design-system.template.md` as the structural guide for the extracted markdown, but fill content from the HTML rather than from raw source data.

## 4. Phase C: Derive JSON (design-system.json)

### 4.1 Extraction Rules

1. **Parse the HTML** `<style>` block for token definitions and component classes
2. **Build items array** with two types:
   - `token-group`: one item per DS-xxx group, containing `tokens` object mapping names to values
   - `component`: one item per CMP-xxx, containing `variants`, `sizes`, `states` arrays
3. **Build crossRefs** from token→component references (which tokens each component uses)
4. **Set metadata**: docType, app, status, version, lastUpdated
5. **Validate** against `_meta/schemas/doc-companion.schema.json`
6. **Write** to `docs/{app}/design/design-system.json`

### 4.2 JSON Structure

```json
{
  "docType": "design-system",
  "app": "{app-name}",
  "status": "Draft",
  "version": "1.0.0",
  "lastUpdated": "{ISO-8601}",
  "source": "../../out/{app}/design/design-system.html",
  "figmaUrl": "https://www.figma.com/design/{file_key}/{file_name}?node-id={node_id}",
  "items": [
    {
      "id": "DS-010",
      "type": "token-group",
      "title": "Brand Colors",
      "tokens": {
        "--color-primary-50": "#eff6ff",
        "--color-primary-500": "#3b82f6",
        "--color-primary-900": "#1e3a8a"
      },
      "status": "Draft",
      "tracedFrom": [],
      "tracedTo": ["CMP-010", "CMP-020"]
    },
    {
      "id": "CMP-010",
      "type": "component",
      "title": "Button",
      "className": ".ds-btn",
      "variants": ["Primary", "Secondary", "Danger", "Ghost"],
      "sizes": ["sm", "md", "lg"],
      "states": ["default", "hover", "active", "focus", "disabled"],
      "status": "Draft",
      "tracedFrom": ["DS-010", "DS-050", "DS-060", "DS-070"],
      "tracedTo": ["SC-010", "SC-020"]
    }
  ],
  "crossRefs": [
    { "from": "DS-010", "to": "CMP-010", "relation": "applied-by" },
    { "from": "CMP-010", "to": "SC-010", "relation": "used-in" }
  ]
}
```

### 4.3 Extended Fields

- **Token group items**: `tokens` object mapping CSS variable names to values
- **Component items**: `className` (CSS class), `variants`, `sizes`, `states` arrays
- These enable downstream tools to directly import design tokens and component metadata

## 5. Token Naming Conventions

### 5.1 Color Tokens

Color tokens use the `--color-` prefix with a semantic name and optional shade level.

```css
/* Brand Colors — primary, secondary, accent */
--color-primary-{50..900}: {value};

/* Semantic Colors — intent-based */
--color-{success|warning|error|info}-500: {value};

/* Neutral Colors — gray scale */
--color-gray-{50..900}: {value};

/* Surface Colors — functional, dark-mode-aware */
--color-bg-{primary|secondary|tertiary}: {value};
--color-text-{primary|secondary|tertiary}: {value};
--color-border-{default|strong}: {value};
```

**Naming Rules:**
1. Brand colors use descriptive names: `primary`, `secondary`, `accent`
2. Shade levels use the 50-900 scale (50=lightest, 900=darkest). Base shade is 500
3. Semantic colors map intent to color: `success`, `warning`, `error`, `info`
4. Surface colors use functional names: `bg-primary`, `text-primary`, `border-default`
5. Never use raw hex values in component styles — always reference tokens
6. Dark mode overrides surface tokens only; shade tokens remain constant

### 5.2 Typography Tokens

```css
--font-family-{sans|mono}: {value};
--font-size-{xs|sm|base|lg|xl|2xl|3xl|4xl}: {value};
--font-weight-{normal|medium|semibold|bold}: {value};
--font-leading-{tight|normal|relaxed}: {value};
--font-tracking-{tight|normal|wide}: {value};
```

### 5.3 Spacing Tokens

```css
--space-{0|1|2|3|4|5|6|8|10|12|16|20|24}: {rem value};
```

### 5.4 Border Radius, Shadow, Transition Tokens

```css
--radius-{none|sm|base|md|lg|xl|2xl|full}: {value};
--shadow-{sm|base|md|lg|xl}: {value};
--transition-{fast|base|slow}: {duration} ease;
```

## 6. Component Variant Definitions

### 6.1 Component Definition Format

Each component is defined by CSS classes in the HTML `<style>` block and showcased in the `<body>`:

| Aspect | Definition Location | Description |
|--------|---------------------|-------------|
| **Base styles** | `.ds-{component}` class | Shared layout, font, transition |
| **Variants** | `.ds-{component}--{variant}` | Color, border, background variations |
| **Sizes** | `.ds-{component}--{size}` | Height, padding, font-size |
| **States** | `:hover`, `:active`, `:focus-visible`, `:disabled` | Interaction feedback |

### 6.2 Button (CMP-010)

| Variant | Background | Text | Border | Hover BG | Active BG |
|---------|-----------|------|--------|----------|-----------|
| Primary | --color-primary-500 | white | none | --color-primary-600 | --color-primary-700 |
| Secondary | --color-gray-100 | --color-gray-800 | --color-border-default | --color-gray-200 | --color-gray-300 |
| Danger | --color-error-500 | white | none | darker | darkest |
| Ghost | transparent | --color-primary-500 | none | --color-primary-50 | --color-primary-100 |

| Size | Height | Padding X | Font Size | Radius |
|------|--------|----------|-----------|--------|
| sm | 32px | --space-3 | --font-size-sm | --radius-md |
| md | 40px | --space-4 | --font-size-base | --radius-md |
| lg | 48px | --space-6 | --font-size-lg | --radius-lg |

### 6.3 Input (CMP-020)

| Property | Value |
|----------|-------|
| Height | 32px (sm), 40px (md), 48px (lg) |
| Border | 1px solid --color-border-default |
| Border (focus) | 1px solid --color-primary-500 + ring |
| Border (error) | 1px solid --color-error-500 |
| Background | --color-bg-primary |
| Placeholder | --color-text-tertiary |
| Radius | --radius-md |

### 6.4 Card (CMP-030)

| Property | Value |
|----------|-------|
| Background | --color-bg-primary |
| Border | 1px solid --color-border-default |
| Radius | --radius-lg |
| Shadow | --shadow-sm |
| Shadow (interactive hover) | --shadow-md |
| Padding | --space-6 |

### 6.5 Table (CMP-040)

| Property | Value |
|----------|-------|
| Header BG | --color-bg-secondary |
| Header font | --font-size-xs, uppercase, semibold |
| Row hover BG | --color-bg-secondary |
| Cell padding | --space-3 vertical, --space-4 horizontal |
| Border | bottom 1px --color-border-default |

### 6.6 Modal (CMP-050)

| Property | Value |
|----------|-------|
| Overlay | rgba(0,0,0,0.5) |
| Background | --color-bg-primary |
| Radius | --radius-xl |
| Shadow | --shadow-xl |
| Sizes | 480px (sm), 640px (md), 960px (lg) |
| Max height | 85vh |

### 6.7 Toast (CMP-060)

| Variant | Background | Border | Text |
|---------|-----------|--------|------|
| Success | #f0fdf4 | #bbf7d0 | #166534 |
| Error | #fef2f2 | #fecaca | #991b1b |
| Warning | #fffbeb | #fed7aa | #92400e |
| Info | #eff6ff | #bfdbfe | #1e40af |

### 6.8 Badge (CMP-070)

| Variant | Background | Text |
|---------|-----------|------|
| Primary | --color-primary-100 | --color-primary-700 |
| Success | #dcfce7 | #166534 |
| Warning | #fef3c7 | #92400e |
| Error | #fee2e2 | #991b1b |
| Neutral | --color-gray-100 | --color-gray-700 |

## 7. Responsive Breakpoints

### 7.1 Breakpoint Definitions

| Name | Token | Width | Columns | Gutter | Margin |
|------|-------|-------|---------|--------|--------|
| xs (mobile) | --bp-xs | < 640px | 4 | --space-4 | --space-4 |
| sm (tablet portrait) | --bp-sm | >= 640px | 8 | --space-6 | --space-6 |
| md (tablet landscape) | --bp-md | >= 768px | 8 | --space-6 | --space-8 |
| lg (desktop) | --bp-lg | >= 1024px | 12 | --space-8 | --space-8 |
| xl (wide desktop) | --bp-xl | >= 1280px | 12 | --space-8 | auto (max-width: 1280px) |

### 7.2 Layout Patterns

- **Sidebar + Content (Desktop):** Sidebar 256px fixed, content fluid. Below lg: off-canvas drawer.
- **Grid System:** CSS Grid with variable columns per breakpoint. Gap: --space-6 (desktop), --space-4 (mobile).
- **Container:** Max width 1280px, centered, padding --space-4 (mobile) / --space-8 (desktop).

### 7.3 Responsive Typography

| Level | Mobile | Desktop |
|-------|--------|---------|
| h1 | --font-size-2xl | --font-size-4xl |
| h2 | --font-size-xl | --font-size-3xl |
| h3 | --font-size-lg | --font-size-2xl |
| body | --font-size-base | --font-size-base |
| small | --font-size-sm | --font-size-sm |

## 8. Accessibility Requirements

### 8.1 Color Contrast

- **Normal text:** 4.5:1 minimum (WCAG AA)
- **Large text (>=18px bold or >=24px):** 3:1 minimum
- **Interactive focus indicators:** 3:1 against adjacent colors
- **Disabled elements:** Exempt but must be visually distinguishable

### 8.2 Focus Management

- All interactive elements must have a visible focus indicator
- Focus style: 2px solid ring using `--color-primary-300` with 2px offset
- Focus order follows logical reading order
- Modal focus trap with Escape to close

### 8.3 Keyboard Navigation

| Element | Key | Action |
|---------|-----|--------|
| Button | Enter, Space | Activate |
| Input | Tab | Focus next |
| Select | Arrow Up/Down | Navigate options |
| Modal | Escape | Close |
| Tabs | Arrow Left/Right | Switch tabs |

### 8.4 ARIA Attributes

- Icon-only buttons: `aria-label`
- Form inputs: associated `<label>` or `aria-label`
- Error messages: `aria-live="polite"`
- Loading states: `aria-busy="true"`
- Modals: `role="dialog"` + `aria-modal="true"` + `aria-labelledby`

### 8.5 Motion

- Respect `prefers-reduced-motion` media query
- Max animation: 300ms transitions, 500ms entrance

## 9. ID Convention

Design System items use two ID prefixes:

| Prefix | Usage | Example |
|--------|-------|---------|
| DS | Design token groups (colors, typography, spacing, radius, shadow, transition, breakpoint, z-index) | DS-010, DS-020, ..., DS-110 |
| CMP | Component definitions (Button, Input, Card, etc.) | CMP-010, CMP-020, ..., CMP-070 |

IDs follow the standard 10-increment rule.

## 10. Synchronization & Updates

### 10.1 Source of Truth Chain

```
HTML (primary) → MD (derived) → JSON (derived)
```

When the design system needs updating:
1. **Edit the HTML** (`out/{app}/design/design-system.html`) — modify CSS variables or component styles
2. **Re-derive MD** from the updated HTML
3. **Re-derive JSON** from the updated HTML
4. **Update `data/links.json`** dependency graph

### 10.2 Sync Verification

After any design system operation, verify:
1. All CSS variables in HTML `:root` are documented in MD token tables
2. All `.ds-*` component classes in HTML are documented in MD component specs
3. All items in JSON match the HTML definitions
4. `source` field in JSON points to the correct HTML path

### 10.3 Validation Checks

1. **ID uniqueness:** No duplicate DS or CMP IDs
2. **ID format:** All IDs match `^(DS|CMP)-\d{3}$`
3. **Token naming:** All tokens follow `--{category}-{name}` convention
4. **Contrast ratios:** Primary text vs background meets 4.5:1 WCAG AA
5. **Component coverage:** All component types from Screen Specification have definitions
6. **Variant completeness:** Each component defines at least default, hover, focus, and disabled states
7. **Dark mode coverage:** All surface tokens have dark mode overrides in `[data-theme="dark"]`
8. **HTML-MD sync:** Every token in HTML `:root` has a matching row in MD
9. **HTML-JSON sync:** Every token/component in HTML has a matching item in JSON
10. **Link graph:** `data/links.json` contains nodes and edges for all design system items
