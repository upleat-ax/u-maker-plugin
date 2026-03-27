---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Iteration Log

## Iteration {{iterationNumber}}

| Item | Value |
|------|-------|
| Start Date | {{startDate}} |
| End Date | {{endDate}} |
| Phase | {{phase}} |
| Status | {{iterationStatus}} |

## 1. Planned vs Completed Items

### Planned

| ID | Type | Title | Story Points | Assignee |
|----|------|-------|--------------|----------|
{{#plannedItems}}
| {{id}} | {{type}} | {{title}} | {{storyPoints}} | {{assignee}} |
{{/plannedItems}}

### Completed

| ID | Type | Title | Story Points | Completed Date |
|----|------|-------|--------------|----------------|
{{#completedItems}}
| {{id}} | {{type}} | {{title}} | {{storyPoints}} | {{completedDate}} |
{{/completedItems}}

### Incomplete / Carry-Over

| ID | Type | Title | Story Points | Reason | Carry To |
|----|------|-------|--------------|--------|----------|
{{#incompleteItems}}
| {{id}} | {{type}} | {{title}} | {{storyPoints}} | {{reason}} | {{carryTo}} |
{{/incompleteItems}}

## 2. Velocity

| Metric | Value |
|--------|-------|
| Planned SP | {{plannedSP}} |
| Completed SP | {{completedSP}} |
| Velocity | {{velocity}} |
| Completion Rate | {{completionRate}} |
| Avg Velocity (Last 3) | {{avgVelocity}} |

## 3. Backlog Changes

{{#backlogChanges}}
- **{{action}}**: {{id}} — {{title}} _({{reason}})_
{{/backlogChanges}}

## 4. Decisions Made

{{#decisions}}
- **{{date}}**: {{decision}} _(Rationale: {{rationale}})_
{{/decisions}}
