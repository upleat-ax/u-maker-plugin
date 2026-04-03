# Design System Specification Reference

> Detailed rules for generating the Design System document, including token naming conventions, component variant definitions, responsive breakpoints, accessibility requirements, and JSON companion structure.

## 1. Overview

The Design System document defines the visual language and component library for the application. It establishes design tokens (colors, typography, spacing, border radius), component variants with their visual states, responsive breakpoints, and accessibility requirements. The Design System ensures visual consistency across all screens and serves as the contract between design and implementation.

The Design System is produced as a pair: `design-system.md` (human-readable) and `design-system.json` (machine-readable companion conforming to `_meta/schemas/doc-companion.schema.json`). The Design System is derived from analyzing SRS/IA patterns and the Screen Specification component usage to determine the appropriate visual language.

## 2. Token Naming Conventions

Design tokens are CSS custom properties (variables) that define the atomic visual values. All tokens follow strict naming conventions to ensure predictability and discoverability.

### 2.1 Color Tokens

Color tokens use the `--color-` prefix with a semantic name and optional shade level.

```css
/* Brand Colors */
--color-primary-50: #eff6ff;
--color-primary-100: #dbeafe;
--color-primary-200: #bfdbfe;
--color-primary-300: #93c5fd;
--color-primary-400: #60a5fa;
--color-primary-500: #3b82f6;    /* Base */
--color-primary-600: #2563eb;
--color-primary-700: #1d4ed8;
--color-primary-800: #1e40af;
--color-primary-900: #1e3a8a;

/* Semantic Colors */
--color-success-500: #22c55e;
--color-warning-500: #f59e0b;
--color-error-500: #ef4444;
--color-info-500: #3b82f6;

/* Neutral Colors */
--color-gray-50: #f9fafb;
--color-gray-100: #f3f4f6;
--color-gray-200: #e5e7eb;
--color-gray-300: #d1d5db;
--color-gray-400: #9ca3af;
--color-gray-500: #6b7280;
--color-gray-600: #4b5563;
--color-gray-700: #374151;
--color-gray-800: #1f2937;
--color-gray-900: #111827;

/* Surface Colors (for dark/light mode) */
--color-bg-primary: var(--color-white);
--color-bg-secondary: var(--color-gray-50);
--color-bg-tertiary: var(--color-gray-100);
--color-text-primary: var(--color-gray-900);
--color-text-secondary: var(--color-gray-600);
--color-text-tertiary: var(--color-gray-400);
--color-border-default: var(--color-gray-200);
--color-border-strong: var(--color-gray-300);
```

### 2.2 Naming Rules for Colors

1. Brand colors use descriptive names: `primary`, `secondary`, `accent`.
2. Shade levels use the 50-900 scale (50 = lightest, 900 = darkest). The base shade is 500.
3. Semantic colors map intent to color: `success`, `warning`, `error`, `info`.
4. Surface colors use functional names: `bg-primary`, `text-primary`, `border-default`.
5. Never use raw hex values in component styles -- always reference tokens.
6. Dark mode overrides the surface color tokens only; shade tokens remain constant.

### 2.3 Typography Tokens

Typography tokens use the `--font-` prefix.

```css
/* Font Families */
--font-family-sans: 'Inter', system-ui, -apple-system, sans-serif;
--font-family-mono: 'JetBrains Mono', 'Fira Code', monospace;

/* Font Sizes */
--font-size-xs: 0.75rem;     /* 12px */
--font-size-sm: 0.875rem;    /* 14px */
--font-size-base: 1rem;      /* 16px */
--font-size-lg: 1.125rem;    /* 18px */
--font-size-xl: 1.25rem;     /* 20px */
--font-size-2xl: 1.5rem;     /* 24px */
--font-size-3xl: 1.875rem;   /* 30px */
--font-size-4xl: 2.25rem;    /* 36px */

/* Font Weights */
--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;

/* Line Heights */
--font-leading-tight: 1.25;
--font-leading-normal: 1.5;
--font-leading-relaxed: 1.75;

/* Letter Spacing */
--font-tracking-tight: -0.025em;
--font-tracking-normal: 0;
--font-tracking-wide: 0.025em;
```

### 2.4 Spacing Tokens

Spacing tokens use the `--space-` prefix with a numeric scale.

```css
--space-0: 0;
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
--space-20: 5rem;     /* 80px */
--space-24: 6rem;     /* 96px */
```

### 2.5 Border Radius Tokens

Border radius tokens use the `--radius-` prefix.

```css
--radius-none: 0;
--radius-sm: 0.125rem;   /* 2px */
--radius-base: 0.25rem;  /* 4px */
--radius-md: 0.375rem;   /* 6px */
--radius-lg: 0.5rem;     /* 8px */
--radius-xl: 0.75rem;    /* 12px */
--radius-2xl: 1rem;      /* 16px */
--radius-full: 9999px;   /* Pill shape */
```

### 2.6 Shadow Tokens

```css
--shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
--shadow-base: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1);
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
--shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
```

### 2.7 Transition Tokens

```css
--transition-fast: 150ms ease;
--transition-base: 200ms ease;
--transition-slow: 300ms ease;
```

## 3. Component Variant Definitions

Each component from the Screen Specification taxonomy is defined with its visual variants and states.

### 3.1 Component Definition Format

Each component is specified with:

| Aspect | Description |
|--------|-----------|
| **Variants** | Visual variations (Primary, Secondary, Ghost, etc.) |
| **Sizes** | Size options (sm, md, lg) |
| **States** | Interactive states (default, hover, active, focus, disabled) |
| **Tokens** | Design tokens applied to each variant/state combination |

### 3.2 Button Component

| Variant | Background | Text | Border | Hover BG | Active BG |
|---------|-----------|------|--------|----------|-----------|
| Primary | --color-primary-500 | white | none | --color-primary-600 | --color-primary-700 |
| Secondary | --color-gray-100 | --color-gray-800 | --color-border-default | --color-gray-200 | --color-gray-300 |
| Danger | --color-error-500 | white | none | --color-error-600 | --color-error-700 |
| Ghost | transparent | --color-primary-500 | none | --color-primary-50 | --color-primary-100 |

| Size | Height | Padding X | Font Size | Radius |
|------|--------|----------|-----------|--------|
| sm | 32px | --space-3 | --font-size-sm | --radius-md |
| md | 40px | --space-4 | --font-size-base | --radius-md |
| lg | 48px | --space-6 | --font-size-lg | --radius-lg |

| State | Modifier |
|-------|---------|
| default | Base styles |
| hover | Background shifts one shade darker |
| active | Background shifts two shades darker |
| focus | 2px ring with --color-primary-300, offset 2px |
| disabled | opacity: 0.5, cursor: not-allowed |
| loading | Show spinner icon, disable interaction |

### 3.3 Input Component

| Property | Value |
|----------|-------|
| Height | 40px (md), 32px (sm), 48px (lg) |
| Border | 1px solid --color-border-default |
| Border (focus) | 1px solid --color-primary-500 + ring |
| Border (error) | 1px solid --color-error-500 |
| Background | --color-bg-primary |
| Text | --color-text-primary |
| Placeholder | --color-text-tertiary |
| Radius | --radius-md |
| Padding | --space-3 horizontal |
| Label | --font-size-sm, --font-weight-medium, --color-text-primary |
| Helper text | --font-size-xs, --color-text-secondary |
| Error text | --font-size-xs, --color-error-500 |

### 3.4 Card Component

| Property | Value |
|----------|-------|
| Background | --color-bg-primary |
| Border | 1px solid --color-border-default |
| Radius | --radius-lg |
| Shadow | --shadow-sm |
| Shadow (hover) | --shadow-md (if interactive) |
| Padding | --space-6 |
| Header font | --font-size-lg, --font-weight-semibold |
| Body font | --font-size-base, --font-weight-normal |

### 3.5 Table Component

| Property | Value |
|----------|-------|
| Header BG | --color-bg-secondary |
| Header font | --font-size-sm, --font-weight-semibold, uppercase |
| Row BG | --color-bg-primary |
| Row BG (hover) | --color-bg-secondary |
| Row BG (striped) | alternate --color-bg-primary / --color-bg-secondary |
| Border | 1px solid --color-border-default (bottom of each row) |
| Cell padding | --space-3 vertical, --space-4 horizontal |

### 3.6 Modal Component

| Property | Value |
|----------|-------|
| Overlay | rgba(0, 0, 0, 0.5) |
| Background | --color-bg-primary |
| Radius | --radius-xl |
| Shadow | --shadow-xl |
| Width | 480px (sm), 640px (md), 960px (lg) |
| Max height | 85vh |
| Padding | --space-6 |
| Header | --font-size-xl, --font-weight-semibold |
| Close button | top-right, Icon Button |
| Animation | fade + scale, --transition-base |

## 4. Responsive Breakpoints

### 4.1 Breakpoint Definitions

| Name | Token | Width | Columns | Gutter | Margin |
|------|-------|-------|---------|--------|--------|
| xs (mobile) | --bp-xs | < 640px | 4 | --space-4 | --space-4 |
| sm (tablet portrait) | --bp-sm | >= 640px | 8 | --space-6 | --space-6 |
| md (tablet landscape) | --bp-md | >= 768px | 8 | --space-6 | --space-8 |
| lg (desktop) | --bp-lg | >= 1024px | 12 | --space-8 | --space-8 |
| xl (wide desktop) | --bp-xl | >= 1280px | 12 | --space-8 | auto (max-width: 1280px) |

### 4.2 Layout Patterns

**Sidebar + Content (Desktop):**
- Sidebar: 256px fixed width
- Content: fluid, fills remaining space
- Breakpoint lg and above

**Drawer + Content (Mobile/Tablet):**
- Sidebar collapses to off-canvas drawer
- Content fills full width
- Below breakpoint lg

**Grid System:**
- CSS Grid with variable columns per breakpoint
- Gap uses --space-6 (desktop), --space-4 (mobile)

**Container:**
- Max width: 1280px
- Centered with auto margins
- Padding: --space-4 (mobile), --space-8 (desktop)

### 4.3 Responsive Typography

| Level | Mobile | Desktop |
|-------|--------|---------|
| h1 | --font-size-2xl | --font-size-4xl |
| h2 | --font-size-xl | --font-size-3xl |
| h3 | --font-size-lg | --font-size-2xl |
| h4 | --font-size-base | --font-size-xl |
| body | --font-size-base | --font-size-base |
| small | --font-size-sm | --font-size-sm |
| caption | --font-size-xs | --font-size-xs |

## 5. Accessibility Requirements

### 5.1 Color Contrast

- **Normal text:** Minimum contrast ratio 4.5:1 against background (WCAG AA).
- **Large text (>= 18px bold or >= 24px):** Minimum contrast ratio 3:1 (WCAG AA).
- **Interactive elements:** Focus indicators must have 3:1 contrast against adjacent colors.
- **Disabled elements:** Exempt from contrast requirements but must still be visually distinguishable.

### 5.2 Focus Management

- All interactive elements must have a visible focus indicator.
- Focus indicator style: 2px solid ring using `--color-primary-300` with 2px offset.
- Focus order must follow logical reading order (left-to-right, top-to-bottom).
- Modal focus trap: when a modal opens, focus is trapped within the modal. Pressing Escape closes the modal and returns focus to the trigger element.
- Skip navigation link: first focusable element on the page must be a "Skip to content" link.

### 5.3 Keyboard Navigation

| Element | Key | Action |
|---------|-----|--------|
| Button | Enter, Space | Activate |
| Link | Enter | Navigate |
| Input | Tab | Focus next |
| Select | Arrow Up/Down | Navigate options |
| Modal | Escape | Close |
| Tabs | Arrow Left/Right | Switch tabs |
| Menu | Arrow Up/Down | Navigate items |
| Checkbox | Space | Toggle |

### 5.4 ARIA Attributes

- Buttons with icons only must have `aria-label`.
- Form inputs must have associated `<label>` elements or `aria-label`.
- Error messages must use `aria-live="polite"` for dynamic updates.
- Loading states must announce via `aria-busy="true"` and screen reader text.
- Modals must use `role="dialog"` with `aria-modal="true"` and `aria-labelledby`.
- Navigation landmarks: `<nav>`, `<main>`, `<aside>`, `<header>`, `<footer>`.

### 5.5 Motion and Animation

- Respect `prefers-reduced-motion` media query. When enabled, reduce or disable animations.
- No animation should rely solely on motion to convey meaning (provide text alternatives).
- Maximum animation duration: 300ms for transitions, 500ms for entrance animations.

## 6. Dark/Light Mode

The design system supports both light and dark themes via CSS custom property overrides.

### 6.1 Theme Toggle

Per project convention, all HTML output includes a dark/light mode toggle switch. The toggle stores preference in `localStorage` and applies a `data-theme="dark"` attribute to the root element.

### 6.2 Dark Mode Token Overrides

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

Only surface tokens are overridden. Brand colors, semantic colors, and shade tokens remain unchanged. Components automatically adapt because they reference surface tokens, not raw values.

## 7. ID Convention

Design System items use two ID prefixes:

| Prefix | Usage | Example |
|--------|-------|---------|
| DS | Design system sections (tokens, patterns) | DS-010, DS-020 |
| CMP | Component definitions | CMP-010, CMP-020 |

IDs follow the standard 10-increment rule.

## 8. JSON Companion Structure (design-system.json)

The `design-system.json` file conforms to `_meta/schemas/doc-companion.schema.json`:

```json
{
  "docType": "design-system",
  "app": "my-app",
  "status": "Draft",
  "version": "1.0.0",
  "lastUpdated": "2026-04-03T11:45:00Z",
  "items": [
    {
      "id": "DS-010",
      "type": "token-group",
      "title": "Color Tokens",
      "description": "Brand, semantic, neutral, and surface color definitions",
      "status": "Draft",
      "tracedFrom": [],
      "tracedTo": ["CMP-010", "CMP-020"]
    },
    {
      "id": "DS-020",
      "type": "token-group",
      "title": "Typography Tokens",
      "description": "Font families, sizes, weights, line heights, letter spacing",
      "status": "Draft",
      "tracedFrom": [],
      "tracedTo": ["CMP-010", "CMP-020"]
    },
    {
      "id": "DS-030",
      "type": "token-group",
      "title": "Spacing Tokens",
      "description": "Spacing scale from 0 to 24 (0-96px)",
      "status": "Draft",
      "tracedFrom": [],
      "tracedTo": []
    },
    {
      "id": "DS-040",
      "type": "token-group",
      "title": "Border Radius Tokens",
      "description": "Radius scale from none to full",
      "status": "Draft",
      "tracedFrom": [],
      "tracedTo": []
    },
    {
      "id": "CMP-010",
      "type": "component",
      "title": "Button",
      "description": "Interactive button with Primary, Secondary, Danger, Ghost variants in sm/md/lg sizes",
      "status": "Draft",
      "tracedFrom": ["DS-010", "DS-020", "DS-030", "DS-040"],
      "tracedTo": ["SC-010", "SC-020"],
      "variants": ["Primary", "Secondary", "Danger", "Ghost", "Icon", "Link"],
      "sizes": ["sm", "md", "lg"],
      "states": ["default", "hover", "active", "focus", "disabled", "loading"]
    },
    {
      "id": "CMP-020",
      "type": "component",
      "title": "Input",
      "description": "Form input with Text, Textarea, Number, Password, Email, Select, and other variants",
      "status": "Draft",
      "tracedFrom": ["DS-010", "DS-020", "DS-030", "DS-040"],
      "tracedTo": [],
      "variants": ["Text", "Textarea", "Number", "Password", "Email", "Phone", "Date", "DateTime", "File", "Select", "MultiSelect", "Checkbox", "Radio", "Toggle"],
      "sizes": ["sm", "md", "lg"],
      "states": ["default", "focus", "error", "disabled", "readonly"]
    }
  ],
  "crossRefs": [
    {
      "from": "CMP-010",
      "to": "SC-010",
      "relation": "references"
    }
  ]
}
```

### 8.1 Item Type Values for Design System

| type | Used For |
|------|---------|
| `token-group` | Groups of design tokens (colors, typography, spacing, radius) |
| `component` | UI component definitions with variants and states |
| `pattern` | Layout patterns (sidebar+content, grid, form stack) |

### 8.2 Extended Fields

Component items include additional fields: `variants` (array of variant names), `sizes` (array of size options), and `states` (array of interactive states). Token group items may include a `tokens` object mapping token names to values. These enable downstream tools to generate CSS variable files and component style sheets.

## 9. Validation Checks

After Design System generation, the following validations are performed:

1. **ID uniqueness:** No duplicate DS or CMP IDs.
2. **ID format:** All IDs match `^(DS|CMP)-\d{3}$`.
3. **Token naming:** All tokens follow the naming convention (`--color-*`, `--font-*`, `--space-*`, `--radius-*`).
4. **Contrast ratios:** Primary text color against background meets 4.5:1 WCAG AA.
5. **Component coverage:** All component types used in the Screen Specification have definitions.
6. **Variant completeness:** Each component defines at least default, hover, focus, and disabled states.
7. **Dark mode coverage:** All surface tokens have dark mode overrides.
8. **Breakpoint consistency:** Breakpoints match those referenced in the Screen Specification.
9. **JSON-Markdown sync:** Every item in `design-system.json` has a corresponding entry in `design-system.md`.
10. **Link graph update:** `data/links.json` contains nodes and edges for all design system items.
