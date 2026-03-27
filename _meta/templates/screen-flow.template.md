---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Screen Flow

## 1. Navigation Map

```mermaid
graph TD
{{#navigationMap}}
    {{from}}["{{fromLabel}}"] -->|{{action}}| {{to}}["{{toLabel}}"]
{{/navigationMap}}
```

## 2. User Journey Flows

{{#journeyFlows}}
### {{name}}

- **Actor:** {{actor}}
- **Goal:** {{goal}}
- **Entry Point:** {{entryPoint}}
- **Exit Point:** {{exitPoint}}

| Step | Screen | Action | Next Screen | Condition |
|------|--------|--------|-------------|-----------|
{{#steps}}
| {{number}} | {{screen}} | {{action}} | {{nextScreen}} | {{condition}} |
{{/steps}}

```mermaid
graph LR
{{#mermaidSteps}}
    {{from}} -->|"{{action}}"| {{to}}
{{/mermaidSteps}}
```
{{/journeyFlows}}

## 3. Transition Rules

| From Screen | To Screen | Trigger | Guard Condition | Side Effect |
|-------------|-----------|---------|-----------------|-------------|
{{#transitionRules}}
| {{from}} | {{to}} | {{trigger}} | {{guard}} | {{sideEffect}} |
{{/transitionRules}}
