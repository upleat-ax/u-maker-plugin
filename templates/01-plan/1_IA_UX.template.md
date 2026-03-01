---
document: "1_IA_UX"
title: "{{PROJECT_NAME}} Information Architecture"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - "u-docs/01-plan/1_Roadmap_RA.md"
  - "u-docs/01-plan/1_SRS_SA.md"
  - "u-docs/02-design/2_Screen_UX.md"
  - "u-docs/01-plan/1_Index_RA.md"
external_links: []
---

# {{PROJECT_NAME}} Information Architecture

## 1. Background

### 1.1 Purpose

{{IA 문서의 목적을 서술한다. 사용자 관점의 정보 구조와 네비게이션 체계를 정의한다.}}

### 1.2 Target Users

| User Type | Description | Primary Goals |
|-----------|-------------|--------------|
| {{사용자 유형 1}} | {{설명}} | {{주요 목표}} |
| {{사용자 유형 2}} | {{설명}} | {{주요 목표}} |

---

## 2. Site Map (Mindmap)

```mermaid
mindmap
    root(({{PROJECT_NAME}}))
        Auth
            Login
            Register
            Password Reset
        Dashboard
            Overview
            {{기능 1}}
            {{기능 2}}
        {{메뉴 1}}
            {{하위 메뉴 1-1}}
            {{하위 메뉴 1-2}}
            {{하위 메뉴 1-3}}
        {{메뉴 2}}
            {{하위 메뉴 2-1}}
            {{하위 메뉴 2-2}}
        Settings
            Profile
            Notifications
            Preferences
```

---

## 3. Navigation Structure

### 3.1 Global Navigation

| Menu | Path | Screen ID | FR Mapping | Auth Required |
|------|------|-----------|------------|---------------|
| Home | `/` | S-001 | - | No |
| Dashboard | `/dashboard` | S-002 | FR-001 | Yes |
| {{메뉴}} | `/{{path}}` | S-003 | FR-002 | Yes |
| Settings | `/settings` | S-004 | - | Yes |

### 3.2 Navigation Flow

```mermaid
flowchart LR
    HOME[Home] --> AUTH{Logged in?}
    AUTH -->|Yes| DASH[Dashboard]
    AUTH -->|No| LOGIN[Login]
    LOGIN --> DASH
    DASH --> MENU1[{{메뉴 1}}]
    DASH --> MENU2[{{메뉴 2}}]
    DASH --> SETTINGS[Settings]
    MENU1 --> SUB1[{{하위 1-1}}]
    MENU1 --> SUB2[{{하위 1-2}}]
```

---

## 4. Screen Inventory

| Screen ID | Screen Name | Path | Parent | FR Mapping | Priority |
|-----------|------------|------|--------|------------|----------|
| S-001 | Home | `/` | - | - | Must |
| S-002 | Dashboard | `/dashboard` | - | FR-001 | Must |
| S-003 | {{화면명}} | `/{{path}}` | Dashboard | FR-002 | Must |
| S-004 | {{화면명}} | `/{{path}}` | Dashboard | FR-003 | Should |
| S-005 | Settings | `/settings` | - | - | Must |
| S-006 | Login | `/auth/login` | - | - | Must |
| S-007 | Register | `/auth/register` | - | - | Must |

---

## 5. User Flows

### 5.1 {{주요 플로우 1}}

```mermaid
flowchart TD
    START([User]) --> A[{{단계 1}}]
    A --> B[{{단계 2}}]
    B --> C{{{조건}}}
    C -->|Success| D[{{성공 화면}}]
    C -->|Fail| E[{{에러 처리}}]
    E --> B
    D --> END([Complete])
```

### 5.2 {{주요 플로우 2}}

```mermaid
flowchart TD
    START([User]) --> A[{{단계 1}}]
    A --> B[{{단계 2}}]
    B --> C[{{단계 3}}]
    C --> END([Complete])
```

---

## 6. Content Model

| Content Type | Fields | Source | Display Screen |
|-------------|--------|--------|---------------|
| {{컨텐츠 유형 1}} | {{필드 목록}} | {{데이터 소스}} | S-002, S-003 |
| {{컨텐츠 유형 2}} | {{필드 목록}} | {{데이터 소스}} | S-003, S-004 |

---

## 7. Scope

### 7.1 In-Scope

- {{범위 내 항목}}

### 7.2 Out-of-Scope

- {{범위 외 항목}}

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-UX | Initial draft |
