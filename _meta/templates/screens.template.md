---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
App: {{app}}
Companion: screens.json
---

# Screen Specification

> JSON companion: `screens.json`
> ID Rule: SC-010, SC-020, ...

## 1. Screen Inventory

| ID | Screen Name | Path | Category | Related IA | Related FR |
|----|------------|------|----------|-----------|-----------|
| SC-010 | {{screenName}} | {{path}} | {{category}} | IA-010 | FR-010 |

## 2. Screen Details

### SC-010: {{screenName}}

**Layout:**
- Header: {{headerDescription}}
- Body: {{bodyDescription}}
- Footer: {{footerDescription}}

**Components:**

| # | Component | Type | Props/Data | Interaction |
|---|-----------|------|-----------|-------------|
| 1 | {{name}} | Button/Input/Card/Table/... | {{props}} | {{interaction}} |

**API Calls:**

| Trigger | API | Method | Purpose |
|---------|-----|--------|---------|
| onLoad | API-010 | GET | {{purpose}} |

**State:**

| State | Type | Default | Description |
|-------|------|---------|-------------|
| {{name}} | {{type}} | {{default}} | {{description}} |

**Validation Rules:**

| Field | Rule | Message |
|-------|------|---------|
| {{field}} | required/minLength/pattern/... | {{message}} |
