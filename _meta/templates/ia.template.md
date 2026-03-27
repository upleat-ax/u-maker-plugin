---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Information Architecture (IA)

## 1. Site/App Map

```
{{appName}}
{{#siteMap}}
├── {{name}} ({{route}})
{{#children}}
│   ├── {{name}} ({{route}})
{{#children}}
│   │   └── {{name}} ({{route}})
{{/children}}
{{/children}}
{{/siteMap}}
```

## 2. Screen Hierarchy

| Level | Screen | Route | Parent | Description |
|-------|--------|-------|--------|-------------|
{{#screenHierarchy}}
| {{level}} | {{name}} | {{route}} | {{parent}} | {{description}} |
{{/screenHierarchy}}

### L1 (Top-Level)
{{#l1Screens}}
- **{{name}}** — {{description}}
{{/l1Screens}}

### L2 (Sub-Level)
{{#l2Screens}}
- **{{name}}** (under {{parent}}) — {{description}}
{{/l2Screens}}

### L3 (Detail-Level)
{{#l3Screens}}
- **{{name}}** (under {{parent}}) — {{description}}
{{/l3Screens}}

## 3. Navigation Patterns

| Pattern | Description | Applicable Screens |
|---------|-------------|--------------------|
{{#navigationPatterns}}
| {{pattern}} | {{description}} | {{screens}} |
{{/navigationPatterns}}

## 4. User Flows

{{#userFlows}}
### {{name}}

- **Actor:** {{actor}}
- **Goal:** {{goal}}
- **Steps:**
{{#steps}}
  1. {{description}} → `{{screen}}`
{{/steps}}

```mermaid
graph LR
{{#mermaidSteps}}
    {{from}} --> {{to}}
{{/mermaidSteps}}
```
{{/userFlows}}
