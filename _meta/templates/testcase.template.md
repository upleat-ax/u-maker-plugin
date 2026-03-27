---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Test Cases

## 1. TC List

{{#testCases}}
### {{id}}: {{title}}

| Item | Value |
|------|-------|
| Priority | {{priority}} |
| Type | {{type}} |
| Traced From | {{tracedFrom}} |
| Status | {{status}} |
| Precondition | {{precondition}} |

**Steps:**

| Step | Action | Expected Result |
|------|--------|-----------------|
{{#steps}}
| {{number}} | {{action}} | {{expected}} |
{{/steps}}

**Test Data:**

{{#testData}}
- {{name}}: `{{value}}`
{{/testData}}

---
{{/testCases}}

## 2. Coverage by FT

| FT ID | FT Title | TC Count | Normal | Abnormal | Boundary | Coverage |
|-------|----------|----------|--------|----------|----------|----------|
{{#ftCoverage}}
| {{ftId}} | {{ftTitle}} | {{tcCount}} | {{normal}} | {{abnormal}} | {{boundary}} | {{coverage}} |
{{/ftCoverage}}

## 3. Priority Classification

| Priority | Count | Description |
|----------|-------|-------------|
| Critical | {{criticalCount}} | Core functionality, must pass for release |
| High | {{highCount}} | Important features, blocking issues |
| Medium | {{mediumCount}} | Standard functionality |
| Low | {{lowCount}} | Edge cases, nice-to-have validations |
