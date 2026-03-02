---
document: "2_ERD_SA"
title: "{{PROJECT_NAME}} Entity Relationship Diagram"
owner: "u-SA"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - "u-docs/{{APP_NAME}}/01-plan/1_SRS_RA.md"
  - "u-docs/{{APP_NAME}}/02-design/2_API_SA.md"
  - "u-docs/{{APP_NAME}}/03-dev/3_Code_DV.md"
  - "u-docs/shared/01-plan/1_Index_PM.md"
external_links: []
---

# {{PROJECT_NAME}} ERD

## 1. Background

### 1.1 Purpose

{{ERD 문서의 목적. SRS의 기능 요구사항을 데이터 모델로 구체화한다.}}

### 1.2 Data Specification

| Item | Value |
|------|-------|
| Database | PostgreSQL / SQLite |
| ORM | Prisma / Drizzle |
| Naming | snake_case (DB), camelCase (Code) |

---

## 2. ER Diagram

```mermaid
erDiagram
    USER {
        int id PK
        string email UK
        string password_hash
        string name
        enum role
        datetime created_at
        datetime updated_at
    }
    {{ENTITY}} {
        int id PK
        int user_id FK
        string title
        string status
        datetime created_at
        datetime updated_at
    }
    {{CHILD_ENTITY}} {
        int id PK
        int parent_id FK
        string content
        datetime created_at
    }

    USER ||--o{ {{ENTITY}} : "creates"
    {{ENTITY}} ||--|{ {{CHILD_ENTITY}} : "contains"
```

---

## 2.5 Domain Class Model

```mermaid
classDiagram
    class USER {
        +int id
        +string email
        +string passwordHash
        +string name
        +Role role
        +datetime createdAt
        +datetime updatedAt
        +login() bool
        +updateProfile() void
    }
    class {{ENTITY}} {
        +int id
        +int userId
        +string title
        +{{ENTITY_STATUS}} status
        +datetime createdAt
        +datetime updatedAt
        +create() {{ENTITY}}
        +update() void
        +delete() void
    }
    class {{CHILD_ENTITY}} {
        +int id
        +int parentId
        +string content
        +datetime createdAt
        +create() {{CHILD_ENTITY}}
    }
    class Role {
        <<enumeration>>
        ADMIN
        USER
    }
    class {{ENTITY_STATUS}} {
        <<enumeration>>
        ACTIVE
        INACTIVE
        DELETED
    }

    USER "1" --> "0..*" {{ENTITY}} : creates
    {{ENTITY}} "1" --> "1..*" {{CHILD_ENTITY}} : contains
    USER --> Role : has
    {{ENTITY}} --> {{ENTITY_STATUS}} : has
```

---

## 3. Entity Definitions

### 3.1 USER

| Attribute | Type | Constraint | Description |
|-----------|------|-----------|-------------|
| id | int | PK, Auto Increment | 고유 식별자 |
| email | string(255) | UK, NOT NULL | 이메일 주소 |
| password_hash | string(255) | NOT NULL | 암호화된 비밀번호 |
| name | string(100) | NOT NULL | 사용자 이름 |
| role | enum('admin','user') | NOT NULL, DEFAULT 'user' | 사용자 역할 |
| created_at | datetime | NOT NULL, DEFAULT NOW | 생성일시 |
| updated_at | datetime | NOT NULL | 수정일시 |

### 3.2 {{ENTITY_NAME}}

| Attribute | Type | Constraint | Description |
|-----------|------|-----------|-------------|
| id | int | PK, Auto Increment | 고유 식별자 |
| {{attribute}} | {{type}} | {{constraint}} | {{설명}} |

---

## 4. Relationships

| From | To | Cardinality | Description |
|------|-----|------------|-------------|
| USER | {{ENTITY}} | 1:N | {{관계 설명}} |
| {{ENTITY}} | {{CHILD_ENTITY}} | 1:N | {{관계 설명}} |

---

## 4.5 Data Flow

```mermaid
flowchart LR
    DB[(Database)] --> USER_E["USER Entity"]
    DB --> ENTITY["{{ENTITY}}"]
    DB --> CHILD["{{CHILD_ENTITY}}"]
    USER_E --> AuthAPI["Auth API"]
    ENTITY --> ResourceAPI["Resource API"]
    CHILD --> ResourceAPI
    AuthAPI --> FE["Frontend"]
    ResourceAPI --> FE
```

---

## 5. State Changes

```mermaid
stateDiagram-v2
    [*] --> Active : Create
    Active --> Inactive : Deactivate
    Inactive --> Active : Reactivate
    Active --> Deleted : Delete
    Inactive --> Deleted : Delete
    Deleted --> [*]
```

---

## 6. Exceptions

| # | Exception Case | Entity | Handling |
|---|---------------|--------|----------|
| E-001 | 중복 이메일 가입 시도 | USER | 409 Conflict 반환 |
| E-002 | {{예외 케이스}} | {{Entity}} | {{처리 방법}} |

---

## 7. FR Mapping

| FR-ID | Feature | Related Entities |
|-------|---------|-----------------|
| FR-001 | {{기능명}} | USER |
| FR-002 | {{기능명}} | {{Entity 목록}} |

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-SA | Initial draft |
