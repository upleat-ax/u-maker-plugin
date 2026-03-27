---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Screen Design

## 1. Screen List

| ID | Name | Route | Description | Traced From |
|----|------|-------|-------------|-------------|
{{#screens}}
| {{id}} | {{name}} | {{route}} | {{description}} | {{tracedFrom}} |
{{/screens}}

## 2. Screen Details

{{#screens}}
### {{id}}: {{name}}

- **Route:** `{{route}}`
- **Description:** {{description}}
- **Traced From:** {{tracedFrom}}

#### Components

| Component | Type | Description | Interaction |
|-----------|------|-------------|-------------|
{{#components}}
| {{name}} | {{type}} | {{description}} | {{interaction}} |
{{/components}}

#### Interactions

{{#interactions}}
- **{{trigger}}** on `{{element}}` → {{action}}
{{/interactions}}

#### States

| State | Condition | Display |
|-------|-----------|---------|
{{#states}}
| {{name}} | {{condition}} | {{display}} |
{{/states}}

---
{{/screens}}

## 3. Responsive Breakpoints

| Breakpoint | Min Width | Layout Changes |
|------------|-----------|----------------|
{{#breakpoints}}
| {{name}} | {{minWidth}} | {{changes}} |
{{/breakpoints}}
