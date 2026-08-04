---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
App: {{app}}
Companion: api.json
---

# API Contract

> JSON companion: `api.json`
> ID Rule: API-010, API-020, ...

## 1. API Summary

| ID | Method | Path | Description | Auth | Related FR |
|----|--------|------|-------------|------|-----------|
| API-010 | GET/POST/PUT/DELETE | {{path}} | {{description}} | Bearer/None | FR-010 |

## 2. API Details

### API-010: {{title}}

**Endpoint:** `{{method}} {{path}}`

**Request:**
```json
{
  "field": "type — description"
}
```

**Response (200):**
```json
{
  "field": "type — description"
}
```

**Error Responses:**

| Code | Message | Condition |
|------|---------|-----------|
| 400 | Bad Request | {{condition}} |
| 401 | Unauthorized | {{condition}} |
| 404 | Not Found | {{condition}} |

## 3. Authentication & Authorization

| Role | Endpoints | Permissions |
|------|-----------|-------------|
| {{role}} | API-010, API-020 | read/write/admin |

## 4. Common Models

```mermaid
classDiagram
    class {{ModelName}} {
        +bigint id
        +string name
        +datetime createdAt
    }
```
