---
document: "3_Screen_UX"
title: "{{PROJECT_NAME}} Screen Implementation Guide"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - "u-docs/02-design/2_Screen_UX.md"
  - "u-docs/02-design/2_API_SA.md"
  - "u-docs/03-dev/3_Code_DV.md"
  - "u-docs/01-plan/1_Index_RA.md"
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

### 2.1 S-001: {{Screen Name}}

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

## 3. Routing Map

| Screen ID | Route | Page File | Guard |
|-----------|-------|-----------|-------|
| S-001 | `/` | `app/page.tsx` | - |
| S-002 | `/dashboard` | `app/dashboard/page.tsx` | auth |
| S-003 | `/{{path}}` | `app/{{path}}/page.tsx` | {{guard}} |

---

## 4. Shared Layouts

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
