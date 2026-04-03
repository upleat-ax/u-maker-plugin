---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
App: {{app}}
Companion: design-system.json
---

# Design System

> JSON companion: `design-system.json`
> ID Rule: DS-010, DS-020, ... (tokens), CMP-010, CMP-020, ... (components)

## 1. Design Tokens

### 1.1 Colors

| ID | Token | Value | Usage |
|----|-------|-------|-------|
| DS-010 | --color-primary | {{value}} | Primary actions, links |
| DS-020 | --color-secondary | {{value}} | Secondary elements |
| DS-030 | --color-bg | {{value}} | Page background |
| DS-040 | --color-surface | {{value}} | Card/panel background |
| DS-050 | --color-text | {{value}} | Body text |
| DS-060 | --color-border | {{value}} | Borders, dividers |
| DS-070 | --color-error | {{value}} | Error states |
| DS-080 | --color-success | {{value}} | Success states |

### 1.2 Typography

| Token | Font | Size | Weight | Line Height |
|-------|------|------|--------|-------------|
| --font-heading-1 | {{font}} | {{size}} | {{weight}} | {{lineHeight}} |
| --font-body | {{font}} | {{size}} | {{weight}} | {{lineHeight}} |

### 1.3 Spacing

| Token | Value | Usage |
|-------|-------|-------|
| --space-xs | 4px | Tight spacing |
| --space-sm | 8px | Compact elements |
| --space-md | 16px | Default gap |
| --space-lg | 24px | Section spacing |
| --space-xl | 32px | Major sections |

### 1.4 Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| --radius-sm | 4px | Inputs, small elements |
| --radius-md | 8px | Cards, buttons |
| --radius-lg | 16px | Modals, large panels |

## 2. UI Components

### CMP-010: Button

| Variant | Background | Text | Border | Usage |
|---------|-----------|------|--------|-------|
| Primary | --color-primary | #fff | none | Main CTA |
| Secondary | transparent | --color-primary | --color-primary | Alternative action |
| Danger | --color-error | #fff | none | Destructive action |

### CMP-020: Input

| State | Border | Background | Text |
|-------|--------|-----------|------|
| Default | --color-border | --color-surface | --color-text |
| Focus | --color-primary | --color-surface | --color-text |
| Error | --color-error | --color-surface | --color-text |

### CMP-030: Card

| Property | Value |
|----------|-------|
| Background | --color-surface |
| Border | 1px solid --color-border |
| Radius | --radius-md |
| Shadow | 0 1px 3px rgba(0,0,0,0.1) |
| Padding | --space-md |

## 3. Layout Patterns

| Pattern | Description | Breakpoints |
|---------|-------------|-------------|
| Sidebar + Content | 280px sidebar + fluid content | < 768px: stack |
| Grid Cards | Auto-fill grid, min 280px | Responsive |
| Form Stack | Vertical form fields, max-width 480px | Always stacked |
