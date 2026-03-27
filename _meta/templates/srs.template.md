---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Software Requirements Specification (SRS)

## 1. Project Overview

| Item | Value |
|------|-------|
| Project Name | {{projectName}} |
| Description | {{description}} |
| Target Users | {{targetUsers}} |
| Platform | {{platform}} |

## 2. Stakeholders

{{#stakeholders}}
| ID | Name | Role | Department | Needs |
|----|------|------|------------|-------|
| {{id}} | {{name}} | {{role}} | {{department}} | {{needs}} |
{{/stakeholders}}

## 3. Functional Requirements

{{#requirements}}
| ID | Title | Description | Priority | Status | Traced From |
|----|-------|-------------|----------|--------|-------------|
| {{id}} | {{title}} | {{description}} | {{priority}} | {{status}} | {{tracedFrom}} |
{{/requirements}}

## 4. Non-Functional Requirements

{{#nfRequirements}}
| ID | Category | Title | Description | Priority | Metric |
|----|----------|-------|-------------|----------|--------|
| {{id}} | {{category}} | {{title}} | {{description}} | {{priority}} | {{metric}} |
{{/nfRequirements}}

## 5. User Stories

{{#userStories}}
### {{id}}: {{title}}

- **As a** {{actor}}
- **I want to** {{action}}
- **So that** {{benefit}}
- **Acceptance Criteria:**
{{#criteria}}
  - [ ] {{.}}
{{/criteria}}
- **Traced From:** {{tracedFrom}}
{{/userStories}}

## 6. Features

{{#features}}
| ID | Title | Description | Story Points | Iteration | Status | Traced From |
|----|-------|-------------|--------------|-----------|--------|-------------|
| {{id}} | {{title}} | {{description}} | {{storyPoints}} | {{iteration}} | {{status}} | {{tracedFrom}} |
{{/features}}

## 7. Constraints

{{#constraints}}
- **{{type}}**: {{description}}
{{/constraints}}

## 8. Assumptions

{{#assumptions}}
- {{description}} _(Confidence: {{confidence}})_
{{/assumptions}}

## 9. Glossary

| Term | Definition |
|------|-----------|
{{#glossary}}
| {{term}} | {{definition}} |
{{/glossary}}
