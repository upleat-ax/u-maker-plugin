---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
App: {{app}}
Companion: design-system.json
Source: ../../out/{{app}}/design/design-system.html
---

# Design System

> **This document is derived from the primary HTML artifact:** `out/{{app}}/design/design-system.html`
> To modify the Design System, edit the HTML first, then re-derive this MD and the JSON companion.
>
> JSON companion: `design-system.json`
> ID Rule: DS-010, DS-020, ... (token groups), CMP-010, CMP-020, ... (components)

## 1. Design Tokens

### 1.1 Brand Colors (DS-010)

| Token | Value | Usage |
|-------|-------|-------|
{{#brandColorTokens}}
| `{{name}}` | `{{value}}` | {{usage}} |
{{/brandColorTokens}}

### 1.2 Semantic Colors (DS-020)

| Token | Value | Usage |
|-------|-------|-------|
{{#semanticColorTokens}}
| `{{name}}` | `{{value}}` | {{usage}} |
{{/semanticColorTokens}}

### 1.3 Neutral Colors (DS-030)

| Token | Value | Usage |
|-------|-------|-------|
{{#neutralColorTokens}}
| `{{name}}` | `{{value}}` | {{usage}} |
{{/neutralColorTokens}}

### 1.4 Surface Colors (DS-040)

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
{{#surfaceColorTokens}}
| `{{name}}` | `{{lightValue}}` | `{{darkValue}}` | {{usage}} |
{{/surfaceColorTokens}}

### 1.5 Typography (DS-050)

| Token | Value | Usage |
|-------|-------|-------|
{{#typographyTokens}}
| `{{name}}` | `{{value}}` | {{usage}} |
{{/typographyTokens}}

### 1.6 Spacing (DS-060)

| Token | Value | Pixels | Usage |
|-------|-------|--------|-------|
{{#spacingTokens}}
| `{{name}}` | `{{value}}` | {{px}} | {{usage}} |
{{/spacingTokens}}

### 1.7 Border Radius (DS-070)

| Token | Value | Usage |
|-------|-------|-------|
{{#radiusTokens}}
| `{{name}}` | `{{value}}` | {{usage}} |
{{/radiusTokens}}

### 1.8 Shadows (DS-080)

| Token | Value |
|-------|-------|
{{#shadowTokens}}
| `{{name}}` | `{{value}}` |
{{/shadowTokens}}

### 1.9 Transitions (DS-090)

| Token | Value |
|-------|-------|
{{#transitionTokens}}
| `{{name}}` | `{{value}}` |
{{/transitionTokens}}

## 2. UI Components

### CMP-010: Button

| Variant | Background | Text | Border | Usage |
|---------|-----------|------|--------|-------|
{{#buttonVariants}}
| {{name}} | `{{bg}}` | `{{text}}` | `{{border}}` | {{usage}} |
{{/buttonVariants}}

| Size | Height | Padding X | Font Size | Radius |
|------|--------|----------|-----------|--------|
{{#buttonSizes}}
| {{name}} | {{height}} | `{{paddingX}}` | `{{fontSize}}` | `{{radius}}` |
{{/buttonSizes}}

### CMP-020: Input

| State | Border | Background | Text |
|-------|--------|-----------|------|
{{#inputStates}}
| {{name}} | `{{border}}` | `{{bg}}` | `{{text}}` |
{{/inputStates}}

### CMP-030: Card

| Property | Value |
|----------|-------|
{{#cardProps}}
| {{name}} | `{{value}}` |
{{/cardProps}}

### CMP-040: Table

| Property | Value |
|----------|-------|
{{#tableProps}}
| {{name}} | `{{value}}` |
{{/tableProps}}

### CMP-050: Modal

| Property | Value |
|----------|-------|
{{#modalProps}}
| {{name}} | `{{value}}` |
{{/modalProps}}

### CMP-060: Toast

| Variant | Background | Border | Text |
|---------|-----------|--------|------|
{{#toastVariants}}
| {{name}} | `{{bg}}` | `{{border}}` | `{{text}}` |
{{/toastVariants}}

### CMP-070: Badge

| Variant | Background | Text |
|---------|-----------|------|
{{#badgeVariants}}
| {{name}} | `{{bg}}` | `{{text}}` |
{{/badgeVariants}}

## 3. Layout Patterns

| Pattern | Description | Breakpoints |
|---------|-------------|-------------|
{{#layoutPatterns}}
| {{name}} | {{description}} | {{breakpoints}} |
{{/layoutPatterns}}

## 4. Accessibility

- **Contrast:** Normal text 4.5:1, large text 3:1 (WCAG AA)
- **Focus:** 2px solid ring `--color-primary-300`, offset 2px
- **Motion:** Respects `prefers-reduced-motion`
- **ARIA:** All interactive elements have appropriate ARIA attributes
