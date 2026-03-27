---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Roadmap

## 1. Milestones

{{#milestones}}
### {{name}}

| Item | Value |
|------|-------|
| Target Date | {{targetDate}} |
| Status | {{status}} |
| Description | {{description}} |

**Deliverables:**
{{#deliverables}}
- [ ] {{name}}
{{/deliverables}}
{{/milestones}}

## 2. Iteration Plan

{{#iterations}}
### Iteration {{number}} ({{startDate}} ~ {{endDate}})

| Item | Value |
|------|-------|
| Goal | {{goal}} |
| Velocity (Planned) | {{plannedVelocity}} SP |
| Status | {{status}} |

**Assigned Features:**

| FT ID | Title | Story Points | Status |
|-------|-------|--------------|--------|
{{#features}}
| {{id}} | {{title}} | {{storyPoints}} | {{status}} |
{{/features}}
{{/iterations}}

## 3. Dependencies

| From | To | Type | Description |
|------|----|------|-------------|
{{#dependencies}}
| {{from}} | {{to}} | {{type}} | {{description}} |
{{/dependencies}}

## 4. Risks

| ID | Risk | Probability | Impact | Mitigation | Status |
|----|------|-------------|--------|------------|--------|
{{#risks}}
| {{id}} | {{description}} | {{probability}} | {{impact}} | {{mitigation}} | {{status}} |
{{/risks}}
