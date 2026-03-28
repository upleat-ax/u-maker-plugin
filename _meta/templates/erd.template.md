---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Entity-Relationship Diagram (ERD)

## 1. Entity List

{{#entities}}
### {{name}}

| Column | Type | PK | FK | Nullable | Default | Description |
|--------|------|----|----|----------|---------|-------------|
{{#columns}}
| {{name}} | {{type}} | {{pk}} | {{fk}} | {{nullable}} | {{default}} | {{description}} |
{{/columns}}
{{/entities}}

## 2. Relationships

| From Entity | To Entity | Type | FK Column | Description |
|-------------|-----------|------|-----------|-------------|
{{#relations}}
| {{from}} | {{to}} | {{type}} | {{fkColumn}} | {{description}} |
{{/relations}}

## 3. ERD Diagram

<!-- constraints: PK, FK, UK 중 하나만 사용 (PK_FK, FK_UK 등 결합 표기 금지 — Mermaid 구문 오류 발생) -->
```mermaid
erDiagram
{{#entities}}
    {{name}} {
{{#columns}}
        {{type}} {{name}} {{constraints}}
{{/columns}}
    }
{{/entities}}

{{#relations}}
    {{from}} {{cardinality}} {{to}} : "{{label}}"
{{/relations}}
```

## 4. Common Table References

| Table | Referenced By | Context |
|-------|---------------|---------|
{{#commonTables}}
| {{name}} | {{referencedBy}} | {{context}} |
{{/commonTables}}
