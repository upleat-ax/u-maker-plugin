# ERD Specification Reference

> Detailed rules for generating the Entity-Relationship Diagram (ERD) document, including entity derivation from SRS, Mermaid erDiagram syntax rules, relationship cardinality, common table patterns, naming conventions, and JSON companion structure.

## 1. Overview

The ERD is the first deliverable of the Design phase. It defines the data model for the application by translating SRS requirements into a normalized entity-relationship structure. The ERD serves as the foundation for both the API contract (which exposes these entities via endpoints) and the Screen specification (which displays them in the UI).

The ERD is produced as a pair: `erd.md` (human-readable with Mermaid diagram) and `erd.json` (machine-readable companion conforming to `_meta/schemas/doc-companion.schema.json`). The ERD must trace every entity back to at least one FR from the SRS.

## 2. Entity Derivation from SRS

Entities are extracted from the SRS through a systematic derivation process.

### 2.1 Derivation Algorithm

1. **Scan data models:** Look for explicit data model references in FR descriptions, US descriptions, and FT details. Terms like "store", "save", "record", "manage", "track", and "maintain" typically indicate persistent entities.

2. **Identify nouns:** Extract significant nouns from FRs and USs that represent persistent business objects. Examples: "user", "product", "order", "payment", "category", "review".

3. **Filter candidates:** Remove nouns that are:
   - Actions or processes (not persistent data)
   - UI elements (these go to the Screen spec)
   - External systems (these become integration interfaces, not entities)
   - Attributes rather than entities (e.g., "name" is an attribute, not an entity)

4. **Map to entities:** Each remaining noun becomes an entity candidate. Consolidate synonyms (e.g., "customer" and "user" may be the same entity depending on context).

5. **Derive columns:** For each entity, derive columns from:
   - FR descriptions mentioning attributes of the entity
   - US acceptance criteria specifying data fields
   - FT descriptions detailing what data is captured or displayed
   - Glossary terms that define entity attributes

6. **Identify relationships:** Analyze FRs for relationship language: "belongs to", "has many", "contains", "is part of", "references".

### 2.2 Standard Columns

Every entity automatically includes these standard columns unless explicitly excluded:

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| `id` | `bigint` | PK | Auto-increment primary key |
| `createdAt` | `timestamp` | — | Record creation timestamp |
| `updatedAt` | `timestamp` | — | Last modification timestamp |

For soft-delete enabled entities, add:

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| `deletedAt` | `timestamp` | — | Soft-delete timestamp (null = active) |

## 3. Mermaid erDiagram Syntax Rules

The ERD diagram uses Mermaid's `erDiagram` syntax. This section documents critical syntax rules and constraints.

### 3.1 Basic Entity Syntax

```mermaid
erDiagram
    User {
        bigint id PK
        varchar email UK
        varchar passwordHash
        varchar name
        timestamp createdAt
        timestamp updatedAt
    }
```

### 3.2 PK/FK/UK Constraint Rule (Critical)

**PK, FK, and UK must NEVER be combined on a single column.** This is a Mermaid parser limitation and a strict project rule. Each column can have at most one constraint marker.

**Correct:**
```
bigint id PK
bigint categoryId FK
varchar email UK
```

**Incorrect (will break Mermaid rendering):**
```
bigint id PK UK        ← FORBIDDEN: combined constraints
bigint userId PK FK    ← FORBIDDEN: combined constraints
```

### 3.3 Handling Multi-Constraint Columns

When a column logically requires multiple constraints (common in junction tables), use the following pattern:

1. Annotate the column with the **most important** constraint in the Mermaid diagram (priority: PK > FK > UK).
2. Document the additional constraints in the entity table in Section 1 of the ERD Markdown.
3. Add a comment in the Mermaid diagram using `%%` syntax:

```mermaid
erDiagram
    OrderItem {
        bigint id PK
        bigint orderId FK
        bigint productId FK
        int quantity
        decimal unitPrice
    }
    %% orderId + productId also forms a unique composite key
```

### 3.4 Supported Column Types

| Type | Usage | Example |
|------|-------|---------|
| `bigint` | Primary keys, foreign keys, large counters | `bigint id PK` |
| `int` | Small integers, quantities, counts | `int quantity` |
| `varchar` | Variable-length strings | `varchar email UK` |
| `uuid` | UUIDs (alternative to bigint PK) | `uuid id PK` |
| `text` | Long text content | `text description` |
| `boolean` | True/false flags | `boolean is_active` |
| `decimal` | Money, precise numbers | `decimal price` |
| `timestamp` | Date and time | `timestamp created_at` |
| `date` | Date only | `date birth_date` |
| `json` | JSON data (flexible schema) | `json metadata` |
| `enum` | Enumerated values | `enum status` |

### 3.5 Entity Naming Convention

- Entity names use `PascalCase` (singular) in Mermaid diagrams: `User`, `OrderItem`, `ProductCategory`.
- Column names use `camelCase`: `createdAt`, `userId`, `productName`.
- Foreign key columns follow the pattern `{referencedEntity}Id`: `userId`, `categoryId`, `orderId`.
- Actual DB table names use `{Domain}{EntityPlural}` PascalCase: `AuthUsers`, `SalesOrders`, `SalesOrderItems`.
- Domain prefix is **mandatory** — see § 8 for comprehensive naming conventions.

## 4. Relationship Cardinality Notation

Mermaid erDiagram uses a specific notation for relationship cardinality.

### 4.1 Cardinality Symbols

| Notation | Meaning | Read As |
|----------|---------|---------|
| `\|\|` | Exactly one | one and only one |
| `o\|` | Zero or one | zero or one |
| `}o` | Zero or many | zero or many |
| `}\|` | One or many | one or many |

### 4.2 Relationship Syntax

```
ENTITY_A <cardinality>--<cardinality> ENTITY_B : "label"
```

### 4.3 Common Relationship Patterns

**One-to-Many (1:N):**
```
User ||--o{ Order : "places"
```
Read: "One User places zero or many Orders."

**Many-to-Many (N:M) via junction table:**
```
Product ||--o{ OrderItem : "included in"
Order ||--o{ OrderItem : "contains"
```
Read: "Many-to-many between Product and Order via OrderItem junction."

**One-to-One (1:1):**
```
User ||--o| Profile : "has"
```
Read: "One User has zero or one Profile."

**Self-referencing:**
```
Category ||--o{ Category : "parent of"
```
Read: "A Category can be parent of zero or many Categories."

### 4.4 Relationship Label Conventions

- Labels should be verbs or verb phrases in lowercase: "places", "contains", "belongs to", "has", "manages".
- Labels are enclosed in double quotes: `"places"`.
- For bidirectional clarity, the label reads from left entity to right entity.

## 5. Common Table Patterns

### 5.1 User/Auth Pattern

```mermaid
erDiagram
    User {
        bigint id PK
        varchar email UK
        varchar passwordHash
        varchar name
        enum role
        boolean isActive
        timestamp lastLoginAt
        timestamp createdAt
        timestamp updatedAt
    }
    Session {
        bigint id PK
        bigint userId FK
        varchar token UK
        timestamp expiresAt
        timestamp createdAt
    }
    User ||--o{ Session : "has"
    %% Domain: Auth → tables: AuthUsers, AuthSessions
```

### 5.2 CRUD with Categories Pattern

```mermaid
erDiagram
    Category {
        bigint id PK
        varchar name
        bigint parentId FK
        int sortOrder
    }
    Item {
        bigint id PK
        bigint categoryId FK
        varchar title
        text description
        enum status
        timestamp createdAt
        timestamp updatedAt
    }
    Category ||--o{ Item : "contains"
    Category ||--o{ Category : "parent of"
    %% Domain: Catalog → tables: CatalogCategories, CatalogItems
```

### 5.3 Audit Log Pattern

```mermaid
erDiagram
    AuditLog {
        bigint id PK
        bigint userId FK
        varchar entityType
        bigint entityId
        enum action
        json changes
        timestamp createdAt
    }
```

### 5.4 File/Media Attachment Pattern

```mermaid
erDiagram
    Attachment {
        bigint id PK
        varchar entityType
        bigint entityId
        varchar fileName
        varchar filePath
        varchar mimeType
        bigint fileSize
        timestamp createdAt
    }
```

## 6. ID Convention

ERD items use two ID prefixes:

| Prefix | Usage | Example |
|--------|-------|---------|
| ENT | Entity definitions | ENT-010, ENT-020 |
| REL | Relationship definitions | REL-010, REL-020 |

IDs follow the standard 10-increment rule. Each entity gets an ENT ID, and each relationship gets a REL ID. IDs are assigned in the order entities and relationships appear in the document.

## 7. JSON Companion Structure (erd.json)

The `erd.json` file conforms to `_meta/schemas/doc-companion.schema.json`:

```json
{
  "docType": "erd",
  "app": "my-app",
  "status": "Draft",
  "version": "1.0.0",
  "lastUpdated": "2026-04-03T11:00:00Z",
  "items": [
    {
      "id": "ENT-010",
      "type": "entity",
      "title": "User",
      "description": "Application user account",
      "status": "Draft",
      "tracedFrom": ["FR-010"],
      "tracedTo": ["API-010", "SC-010"],
      "tableName": "AuthUsers",
      "columns": [
        { "name": "id", "type": "bigint", "constraint": "PK", "nullable": false },
        { "name": "email", "type": "varchar", "constraint": "UK", "nullable": false },
        { "name": "passwordHash", "type": "varchar", "constraint": null, "nullable": false },
        { "name": "name", "type": "varchar", "constraint": null, "nullable": false },
        { "name": "role", "type": "enum", "constraint": null, "nullable": false, "values": ["admin", "user", "manager"] },
        { "name": "createdAt", "type": "timestamp", "constraint": null, "nullable": false },
        { "name": "updatedAt", "type": "timestamp", "constraint": null, "nullable": false }
      ]
    },
    {
      "id": "REL-010",
      "type": "relationship",
      "title": "User places Order",
      "description": "One user places zero or many orders",
      "status": "Draft",
      "from": "ENT-010",
      "to": "ENT-020",
      "cardinality": "1:N",
      "fkColumn": "userId"
    }
  ],
  "crossRefs": [
    {
      "from": "ENT-010",
      "to": "FR-010",
      "relation": "implements"
    }
  ]
}
```

### 7.1 Item Type Values for ERD

| type | Used For |
|------|---------|
| `entity` | Entity definitions (tables) |
| `relationship` | Relationship definitions between entities |

### 7.2 Extended Fields

Entity items include a `columns` array not present in the base doc-companion schema. Each column object contains: `name`, `type`, `constraint` (PK/FK/UK or null), `nullable`, and optionally `default` and `values` (for enum types). This extended structure enables downstream tools (API generator, code engine) to create database schemas automatically.

## 8. Naming Conventions (Advanced — camelCase Standard)

> **Core Principle:** Consistency above all. Pick a convention and enforce it across the entire project — tables, columns, indexes, constraints, views. Mixed conventions are worse than any single choice.

### 8.1 General Rules

- **English full names only** — no abbreviations (`customer`, not `cust`; `organization`, not `org`).
- **camelCase** for table names and column names — aligned with Prisma, JS/TS ecosystem, and modern ORM conventions.
- **No special characters or spaces** — only `[a-zA-Z0-9]`.
- **Avoid reserved words** — never use `user`, `order`, `select`, `group` as bare table names. Use plural forms (`users`, `orders`) which naturally avoids most collisions.
- **Length guideline** — meaningful but concise, ideally ≤ 30 characters.

### 8.2 Table Naming

| Rule | Convention | Example |
|------|-----------|---------|
| **Format** | `{Domain}{EntityPlural}` PascalCase | `AuthUsers`, `SalesOrders`, `CatalogProducts` |
| **Domain prefix** | **Mandatory** — PascalCase domain name | `Auth`, `Sales`, `Catalog`, `Hr`, `Inventory` |
| **Entity part** | PascalCase plural after domain prefix | `AuthUsers`, `SalesOrderItems`, `CatalogCategories` |
| **Junction tables** (M:N) | `{Domain}{Entity1}{Entity2Plural}` | `AuthRoleUsers`, `SalesOrderProducts` |
| **History/log tables** | `{Domain}{Entity}AuditLogs` | `AuthUserAuditLogs`, `SalesOrderHistory` |
| **Mermaid display** | `PascalCase` singular (model name, no prefix) | `User`, `OrderItem` |
| **Document title** | PascalCase singular (no prefix) | "OrderItem" |

### 8.3 Column Naming

| Rule | Convention | Example |
|------|-----------|---------|
| **Number** | **Singular** always | `userId`, `firstName` |
| **Case** | **camelCase** | `billingAddressLine1` |
| **Primary Key** | `id` (simple) | `bigint id PK` |
| **Foreign Key** | `{referencedEntity}Id` | `userId`, `categoryId`, `orderId` |
| **Timestamps** | `createdAt`, `updatedAt`, `deletedAt` | `timestamp createdAt` |
| **Boolean flags** | `is` prefix (camelCase) | `isActive`, `isVerified`, `isPublished` |
| **Status fields** | `status` (enum/string) | `enum status` |
| **Enum values** | camelCase or lowercase | `active`, `inProgress`, `pendingReview` |

### 8.4 Constraints & Indexes

| Object | Pattern | Example |
|--------|---------|---------|
| **Primary Key** | `pk_{table}` | `pk_users` |
| **Foreign Key** | `fk_{table}_{referenced}` | `fk_orders_users` |
| **Unique** | `uq_{table}_{column}` | `uq_users_email` |
| **Index** | `idx_{table}_{columns}` | `idx_users_email_status` |
| **Check** | `ck_{table}_{column}` | `ck_orders_totalPositive` |

### 8.5 Other Database Objects

| Object | Pattern | Example |
|--------|---------|---------|
| **View** | `v_{description}` or `vw_` prefix | `vActiveUsers`, `vwOrderSummary` |
| **Schema** | Domain-based separation | `auth.`, `sales.`, `hr.`, `inventory.` |
| **Trigger** | `trg_{table}_{event}` | `trg_users_beforeUpdate` |
| **Function** | `fn_{description}` | `fnCalculateTotal` |

### 8.6 ORM Compatibility Notes

| ORM / Framework | Convention | Notes |
|-----------------|-----------|-------|
| **Prisma** | PascalCase model, camelCase fields | Native — no `@map` needed. `@@map("tableName")` for plural table |
| **Drizzle ORM** | camelCase schema, camelCase columns | Direct mapping, zero friction |
| **Supabase** | camelCase via JS client | PostgreSQL stores lowercase, JS client maps camelCase |
| **TypeORM** | PascalCase entity, camelCase columns | `@Entity('tableName')` for plural |
| **Sequelize** | camelCase model fields | `underscored: false` (default) |
| **Laravel / Eloquent** | snake_case native | Needs `$snakeAttributes = false` for camelCase |
| **Django** | snake_case native | Needs custom `db_column` for camelCase |

### 8.7 Quick Reference (Prisma)

```prisma
// Model: PascalCase singular (no domain prefix)
// Table: {Domain}{EntityPlural} PascalCase via @@map
// Columns: camelCase (no @map needed)
model User {
  id           String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  email        String   @unique @db.VarChar(255)
  passwordHash String   @db.VarChar(255)
  firstName    String?  @db.VarChar(100)
  lastName     String?  @db.VarChar(100)
  isActive     Boolean  @default(true)
  createdAt    DateTime @default(now()) @db.Timestamptz
  updatedAt    DateTime @updatedAt @db.Timestamptz

  orders       Order[]

  @@map("AuthUsers")          // domain: Auth
  @@index([email])
}

model Order {
  id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId    String   @db.Uuid
  status    String   @db.VarChar(20)
  total     Decimal  @db.Decimal(10, 2)
  createdAt DateTime @default(now()) @db.Timestamptz
  updatedAt DateTime @updatedAt @db.Timestamptz

  user      User     @relation(fields: [userId], references: [id])
  items     OrderItem[]

  @@map("SalesOrders")        // domain: Sales
  @@index([userId])
}

// Junction: {Domain}{Entity1}{Entity2Plural}
model RoleUser {
  userId String @db.Uuid
  roleId String @db.Uuid
  user   User   @relation(fields: [userId], references: [id])
  role   Role   @relation(fields: [roleId], references: [id])

  @@id([userId, roleId])
  @@map("AuthRoleUsers")      // domain: Auth
}
```

### 8.8 u-maker ID Conventions

| Prefix | Usage | Example |
|--------|-------|---------|
| ENT | Entity definitions | ENT-010, ENT-020 |
| REL | Relationship definitions | REL-010, REL-020 |

## 9. Validation Checks

After ERD generation, the following validations are performed:

1. **ID uniqueness:** No duplicate ENT or REL IDs.
2. **ID format:** All IDs match `^(ENT|REL)-\d{3}$`.
3. **PK/FK/UK never combined:** No column has more than one constraint marker in the Mermaid diagram.
4. **Every entity has a PK:** At least one column with PK constraint per entity.
5. **FK references valid entities:** Every FK column references an existing entity.
6. **Relationship consistency:** Every REL item references valid entity IDs in `from` and `to`.
7. **SRS traceability:** Every entity traces to at least one FR.
8. **Standard columns present:** Every entity includes `id`, `createdAt`, `updatedAt` (warning if missing).
9. **Mermaid syntax validity:** The erDiagram block is syntactically valid Mermaid.
10. **JSON-Markdown sync:** Every item in `erd.json` has a corresponding entry in `erd.md`.
11. **Link graph update:** `data/links.json` contains nodes and edges for all ERD items.
