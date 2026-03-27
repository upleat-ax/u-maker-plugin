---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# API Contract

## 1. Base URL and Auth

| Item | Value |
|------|-------|
| Base URL | `{{baseUrl}}` |
| API Version | {{apiVersion}} |
| Auth Method | {{authMethod}} |
| Auth Header | `{{authHeader}}` |

## 2. Endpoints

{{#endpoints}}
### {{method}} `{{path}}`

- **Summary:** {{summary}}
- **Auth Required:** {{authRequired}}
- **Traced From:** {{tracedFrom}}

**Request:**

{{#requestParams}}
| Parameter | In | Type | Required | Description |
|-----------|-----|------|----------|-------------|
| {{name}} | {{in}} | {{type}} | {{required}} | {{description}} |
{{/requestParams}}

{{#requestBody}}
```json
{{{schema}}}
```
{{/requestBody}}

**Response:**

| Status | Description |
|--------|-------------|
{{#responses}}
| {{status}} | {{description}} |
{{/responses}}

```json
{{{responseSchema}}}
```

---
{{/endpoints}}

## 3. Error Codes

| Code | Name | Description | Resolution |
|------|------|-------------|------------|
{{#errorCodes}}
| {{code}} | {{name}} | {{description}} | {{resolution}} |
{{/errorCodes}}

## 4. Common Headers

| Header | Value | Description |
|--------|-------|-------------|
{{#commonHeaders}}
| {{name}} | {{value}} | {{description}} |
{{/commonHeaders}}
