---
document: "3_Screen_UX"
title: "{{PROJECT_NAME}} Screen Implementation Guide"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
app: "{{APP_NAME}}"
related_docs:
  - "u-docs/{{APP_NAME}}/02-design/2_Screen_UX.md"
  - "u-docs/{{APP_NAME}}/02-design/2_API_SA.md"
  - "u-docs/{{APP_NAME}}/03-dev/3_Code_DV.md"
  - "u-docs/shared/01-plan/1_Index_PM.md"
external_links: []
---

# {{PROJECT_NAME}} Screen Implementation Guide

## 1. Overview

### 1.1 Purpose

{{화면 구현 가이드의 목적. 2_Screen_UX.md의 설계를 실제 코드로 변환하기 위한 상세 구현 명세를 제공한다.}}

### 1.2 Tech Stack

| Item | Value |
|------|-------|
| Framework | Next.js App Router |
| Styling | CSS Modules + Design Tokens |
| Data Fetching | react-query |
| State Management | React Server Components + Client State |

---

## 2. Screen Implementation

### 2.1 S-0010: {{Screen Name}}

**Route**: `app/{{path}}/page.tsx`
**Type**: Server Component | Client Component
**Related FR**: FR-XXX

#### File Structure

```
app/{{path}}/
├── page.tsx              # 페이지 컴포넌트
├── layout.tsx            # 레이아웃 (optional)
├── loading.tsx           # 로딩 UI
├── error.tsx             # 에러 UI
└── components/
    ├── {{Component}}.tsx
    └── {{Component}}.module.css
```

#### Data Requirements

| Data | Source | Hook | Cache |
|------|--------|------|-------|
| {{데이터}} | `GET /api/{{resource}}` | `use{{Resource}}()` | 30s stale |
| {{데이터}} | `POST /api/{{resource}}` | `useCreate{{Resource}}()` | invalidate |

#### State Management

| State | Type | Initial | Trigger |
|-------|------|---------|---------|
| {{상태}} | local | {{초기값}} | {{트리거}} |
| {{상태}} | server | fetched | mount |

#### Implementation Notes

- {{구현 시 주의사항}}
- {{성능 최적화 포인트}}
- {{접근성 고려사항}}

---

## 3. Component Decision Flow

```mermaid
flowchart TD
    START[New Component] --> Q1{Data fetching needed?}
    Q1 -->|Yes| Q2{User interaction?}
    Q1 -->|No| SC[Server Component]
    Q2 -->|Yes| CC["Client Component\n'use client'"]
    Q2 -->|No| SC
    SC --> Q3{Dynamic data?}
    Q3 -->|Yes| SSR["SSR with\nreact-query prefetch"]
    Q3 -->|No| STATIC["Static Generation"]
    CC --> RQ["react-query hook\nuse{{Resource}}()"]
```

---

## 4. Routing Map

| Screen ID | Route | Page File | Menu ID | Guard |
|-----------|-------|-----------|---------|-------|
| S-0010 | `/` | `app/page.tsx` | MN-XXX-NNNN | - |
| S-0020 | `/dashboard` | `app/dashboard/page.tsx` | MN-XXX-NNNN | auth |
| S-0030 | `/{{path}}` | `app/{{path}}/page.tsx` | MN-XXX-NNNN | {{guard}} |

---

## 5. Route Hierarchy

```mermaid
flowchart TD
    ROOT["/ (Root Layout)"]
    ROOT --> AUTH["(auth) Group"]
    ROOT --> DASH["(dashboard) Group"]
    AUTH --> LOGIN["/auth/login"]
    AUTH --> REGISTER["/auth/register"]
    DASH --> HOME["/dashboard"]
    DASH --> FEAT1["/{{path}}"]
    FEAT1 --> SUB1["/{{path}}/{{sub}}"]
    DASH --> SET["/settings"]
    SET --> PROFILE["/settings/profile"]
```

---

## 6. Shared Layouts

| Layout | Route Group | Components |
|--------|-----------|-----------|
| Root | `app/layout.tsx` | Header, Footer |
| Dashboard | `app/(dashboard)/layout.tsx` | Sidebar, Header |
| Auth | `app/(auth)/layout.tsx` | AuthHeader |

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-UX | Initial draft |
