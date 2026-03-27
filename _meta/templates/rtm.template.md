---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Requirements Traceability Matrix (RTM)

## 1. FR → US → FT → Screen → TC Mapping

| FR ID | FR Title | US ID | US Title | FT ID | FT Title | Screen ID | TC ID | Status |
|-------|----------|-------|----------|-------|----------|-----------|-------|--------|
{{#traceabilityRows}}
| {{frId}} | {{frTitle}} | {{usId}} | {{usTitle}} | {{ftId}} | {{ftTitle}} | {{screenId}} | {{tcId}} | {{status}} |
{{/traceabilityRows}}

## 2. Coverage Statistics

### By FR

| FR ID | FR Title | US Count | FT Count | Screen Count | TC Count | Coverage |
|-------|----------|----------|----------|--------------|----------|----------|
{{#frCoverage}}
| {{id}} | {{title}} | {{usCount}} | {{ftCount}} | {{screenCount}} | {{tcCount}} | {{coverage}} |
{{/frCoverage}}

### Summary

| Metric | Count | Covered | Coverage % |
|--------|-------|---------|------------|
| Functional Requirements | {{totalFR}} | {{coveredFR}} | {{frCoveragePercent}} |
| User Stories | {{totalUS}} | {{coveredUS}} | {{usCoveragePercent}} |
| Features | {{totalFT}} | {{coveredFT}} | {{ftCoveragePercent}} |
| Screens | {{totalScreens}} | {{coveredScreens}} | {{screenCoveragePercent}} |
| Test Cases | {{totalTC}} | {{executedTC}} | {{tcCoveragePercent}} |

## 3. Gaps

{{#gaps}}
### {{type}} Gap

| Item ID | Item Title | Missing | Severity |
|---------|-----------|---------|----------|
{{#items}}
| {{id}} | {{title}} | {{missing}} | {{severity}} |
{{/items}}
{{/gaps}}
