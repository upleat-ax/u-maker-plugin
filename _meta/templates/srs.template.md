---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
App: {{app}}
Companion: srs.json
---

# Software Requirements Specification (SRS)

> JSON companion: `srs.json` — all items with IDs, statuses, and cross-references.
> ID Rule: 10-increment (FR-010, FR-020, ...). Insert between: FR-015.

## 1. Project Overview

| Item | Value |
|------|-------|
| Project Name | {{projectName}} |
| Description | {{description}} |
| Target Users | {{targetUsers}} |
| Platform | {{platform}} |

## 2. Stakeholders

| ID | Name | Role | Department | Needs |
|----|------|------|------------|-------|
| STK-010 | {{name}} | {{role}} | {{department}} | {{needs}} |

## 3. Functional Requirements

| ID | Title | Description | Priority | Status | Traced From |
|----|-------|-------------|----------|--------|-------------|
| FR-010 | {{title}} | {{description}} | Must/Should/Could/Won't | Draft | — |

## 4. Non-Functional Requirements

| ID | Category | Title | Description | Priority | Metric |
|----|----------|-------|-------------|----------|--------|
| NFR-010 | {{category}} | {{title}} | {{description}} | {{priority}} | {{metric}} |

## 5. User Stories

### US-010: {{title}}

- **As a** {{actor}}
- **I want to** {{action}}
- **So that** {{benefit}}
- **Acceptance Criteria:**
  - [ ] {{criterion}}
- **Traced From:** FR-010

## 6. Features (FT)

| ID | Title | Description | Story Points | Status | Traced From |
|----|-------|-------------|--------------|--------|-------------|
| FT-010 | {{title}} | {{description}} | {{sp}} | Draft | US-010 |

## 7. Constraints

- **{{type}}**: {{description}}

## 8. Glossary

| Term | Definition |
|------|-----------|
| {{term}} | {{definition}} |
