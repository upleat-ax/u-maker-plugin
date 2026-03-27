---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# UX Guide

## 1. Design Principles

{{#designPrinciples}}
### {{name}}

{{description}}

- **Do:** {{do}}
- **Don't:** {{dont}}
{{/designPrinciples}}

## 2. Accessibility Standards

| Standard | Level | Description |
|----------|-------|-------------|
{{#accessibilityStandards}}
| {{standard}} | {{level}} | {{description}} |
{{/accessibilityStandards}}

### Key Requirements

- Minimum contrast ratio: {{contrastRatio}}
- Focus indicator: {{focusIndicator}}
- Keyboard navigation: {{keyboardNav}}
- Screen reader support: {{screenReader}}
- Touch target minimum: {{touchTarget}}

## 3. Interaction Patterns

{{#interactionPatterns}}
### {{name}}

- **Use When:** {{useWhen}}
- **Behavior:** {{behavior}}
- **Feedback:** {{feedback}}
- **Example:** {{example}}
{{/interactionPatterns}}

## 4. Typography Scale

| Level | Size | Weight | Line Height | Use |
|-------|------|--------|-------------|-----|
{{#typographyScale}}
| {{level}} | {{size}} | {{weight}} | {{lineHeight}} | {{use}} |
{{/typographyScale}}

- **Primary Font:** {{primaryFont}}
- **Secondary Font:** {{secondaryFont}}
- **Monospace Font:** {{monospaceFont}}

## 5. Color System

### Brand Colors

| Name | Hex | Usage |
|------|-----|-------|
{{#brandColors}}
| {{name}} | {{hex}} | {{usage}} |
{{/brandColors}}

### Semantic Colors

| Role | Light Mode | Dark Mode | Usage |
|------|------------|-----------|-------|
{{#semanticColors}}
| {{role}} | {{light}} | {{dark}} | {{usage}} |
{{/semanticColors}}

## 6. Spacing System

| Token | Value | Usage |
|-------|-------|-------|
{{#spacingSystem}}
| {{token}} | {{value}} | {{usage}} |
{{/spacingSystem}}

- **Base Unit:** {{baseUnit}}
- **Scale:** {{scale}}
