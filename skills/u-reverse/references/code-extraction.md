# code-extraction Reference

Rules for extracting Design-level artifacts (ERD, API, Screens, Design System) from existing code. Used by `/u-reverse` Steps 2-4.

## 1. ERD Extraction

### 1.1 Source Priority

1. **ORM schema files** (highest fidelity):
   - Prisma: Parse `model` blocks for fields, types, `@id`, `@unique`, `@relation`
   - TypeORM: Parse `@Entity()`, `@Column()`, `@PrimaryGeneratedColumn()`, `@ManyToOne()`, etc.
   - Sequelize: Parse `Model.init()` / `define()` field definitions
   - Drizzle: Parse table definitions with `pgTable()`, `mysqlTable()`
   - Django: Parse `models.Model` subclasses, field types, `ForeignKey`, `ManyToManyField`
   - SQLAlchemy: Parse `Base` subclasses, `Column()`, `relationship()`, `ForeignKey()`
   - ActiveRecord: Parse `app/models/*.rb` for `belongs_to`, `has_many`, `has_one`

2. **Migration files** (good fidelity):
   - SQL DDL: Parse `CREATE TABLE`, `ALTER TABLE`, `ADD CONSTRAINT`
   - ORM migrations: Parse framework-specific migration syntax

3. **Type definitions** (lower fidelity, fallback):
   - TypeScript interfaces/types with fields that look like DB columns
   - Heuristic: has `id`, `createdAt`, `updatedAt` fields → likely a persistent entity

### 1.2 Entity Extraction Rules

For each detected entity:

| Field | Extraction Method |
|-------|-------------------|
| **Name** | Model/table name → PascalCase. Apply domain prefix convention per project (e.g., if entities are `User`, `UserProfile`, `UserSession`, domain prefix = `Auth`) |
| **Columns** | Each field/column → name, type, nullable |
| **PK** | `@id`, `PRIMARY KEY`, `PrimaryGeneratedColumn`, `AutoField` |
| **FK** | `@relation`, `REFERENCES`, `ForeignKey`, `belongs_to` |
| **UK** | `@unique`, `UNIQUE`, `unique=True` |
| **Indexes** | `@@index`, `CREATE INDEX`, `db_index=True` |
| **Defaults** | `@default`, `DEFAULT`, `default=` |

### 1.3 Relationship Extraction Rules

| ORM Pattern | Relationship Type | Mermaid Cardinality |
|------------|-------------------|---------------------|
| `@relation` (1 FK field) | Many-to-One | `}o--\|\|` |
| `@relation` (both sides) | One-to-One | `\|\|--\|\|` |
| Implicit join table | Many-to-Many | `}o--o{` |
| `has_many` / `ForeignKey` | One-to-Many | `\|\|--o{` |

### 1.4 Domain Grouping

Group entities by domain area for ERD organization:
- Analyze naming prefixes (e.g., `User*`, `Order*`, `Product*`)
- Analyze FK relationships (connected components)
- Each group becomes an ERD section with a comment separator

### 1.5 ID Assignment

- Entities: ENT-010, ENT-020, ENT-030 (10-increment)
- Relationships: REL-010, REL-020 (10-increment)
- Order: entities first (alphabetical by domain group), then relationships

## 2. API Extraction

### 2.1 Source Priority

1. **Framework route files** (highest fidelity):
   - Express: `router.get('/path', handler)`, `app.use('/prefix', router)`
   - Next.js App Router: `export async function GET(request)` in `route.ts`
   - Next.js Pages: `export default function handler(req, res)` in `pages/api/`
   - FastAPI: `@app.get('/path')` or `@router.get('/path')`
   - NestJS: `@Controller('prefix')` + `@Get('path')` + `@Body()` / `@Param()`
   - Django: `path('url/', view)` in `urls.py`
   - Rails: `resources :items` / `get '/path', to: 'controller#action'`
   - Laravel: `Route::get('/path', [Controller::class, 'method'])`

2. **OpenAPI/Swagger spec** (if exists):
   - `openapi.json`, `openapi.yaml`, `swagger.json`, `swagger.yaml`
   - Parse directly — highest fidelity when available

3. **tRPC / GraphQL schemas** (alternative API styles):
   - tRPC: Parse router definitions
   - GraphQL: Parse `*.graphql` or `typeDefs`

### 2.2 Endpoint Extraction Rules

For each detected endpoint:

| Field | Extraction Method |
|-------|-------------------|
| **Path** | Route path string (normalize: strip prefix, resolve dynamic segments) |
| **Method** | HTTP method from handler registration (GET/POST/PUT/PATCH/DELETE) |
| **Request Body** | Type annotation, validation schema (zod, joi, class-validator), or `@Body()` decorator |
| **Response** | Return type, serializer class, or response schema |
| **Path Params** | Dynamic segments: `:id`, `[id]`, `{id}`, `<int:id>` |
| **Query Params** | Type annotation on query object, `@Query()` decorator, `request.query` usage |
| **Auth** | Middleware chain: `auth()`, `@UseGuards()`, `@login_required`, `before_action :authenticate` |
| **Roles** | Role-based guards: `@Roles('admin')`, permission decorators |

### 2.3 Endpoint Grouping

- Group by URL prefix (e.g., `/api/users/*` → "Users" group)
- Each group maps to one API section in the document
- Groups correspond to ERD domain groups where possible

### 2.4 ID Assignment

- Endpoints: API-010, API-020, API-030 (10-increment)
- Order: grouped by domain, then by CRUD order within group (List, Get, Create, Update, Delete)

## 3. Screen Extraction

### 3.1 Source Priority

1. **Framework page files**:
   - Next.js App Router: `app/**/page.tsx` (each file = one screen)
   - Next.js Pages: `pages/**/*.tsx` (each file = one screen, exclude `_app`, `_document`, `api/`)
   - React Router: components referenced in `<Route>` elements
   - Vue Router: components in `routes` array
   - SvelteKit: `src/routes/**/+page.svelte`
   - Angular: components in route module `routes` array

2. **Layout files** (for structure analysis):
   - Next.js: `layout.tsx` files
   - Common: `Layout.tsx`, `Sidebar.tsx`, `Navbar.tsx`, `Header.tsx`, `Footer.tsx`

### 3.2 Screen Extraction Rules

For each detected page/screen:

| Field | Extraction Method |
|-------|-------------------|
| **Name** | File name or component name → human-readable title |
| **Route** | File path → route path (follow framework conventions) |
| **Layout** | Parent layout component reference |
| **Components** | Import statements → list of used components |
| **API Calls** | `fetch()`, `axios.*`, `useSWR()`, `useQuery()`, server actions, `getServerSideProps` |
| **State** | `useState()`, store hooks, context consumers |
| **Forms** | `<form>`, form libraries (react-hook-form, formik), validation schemas |
| **Auth Guard** | Route-level auth checks, middleware, `getServerSession()` |

### 3.3 Navigation Derivation

- Extract from routing config: nested routes → parent-child relationships
- Extract from navigation components: `<Link>`, `<NavLink>`, menu items
- Identify: primary nav (top/sidebar), secondary nav (tabs, breadcrumbs), footer nav

### 3.4 ID Assignment

- Screens: SC-010, SC-020, SC-030 (10-increment)
- Order: by route path depth (top-level first, then nested)

## 4. Design System Extraction

### 4.1 Design Token Sources

#### Tailwind CSS (`tailwind.config.*`)

```
theme.extend.colors → color tokens (color.primary.500, color.gray.100, etc.)
theme.extend.spacing → spacing tokens
theme.extend.fontFamily → typography tokens
theme.extend.fontSize → typography size tokens
theme.extend.borderRadius → radius tokens
theme.extend.screens → breakpoint tokens
theme.extend.boxShadow → shadow tokens
```

#### CSS Custom Properties

Scan for `:root { --variable-name: value; }` patterns:
```
--color-primary → color.primary
--spacing-md → spacing.md
--font-sans → typography.fontFamily.sans
```

#### Theme Files

Parse exported theme objects:
```typescript
export const theme = {
  colors: { ... } → color tokens,
  spacing: { ... } → spacing tokens,
  ...
}
```

### 4.2 Component Pattern Detection

Scan shared component directories (`components/ui/`, `components/common/`, `lib/ui/`):

| Component Pattern | Detection Signal |
|-------------------|-----------------|
| Button | File named `button.*`, exports `Button` component |
| Input / TextField | File named `input.*`, `text-field.*` |
| Select / Dropdown | File named `select.*`, `dropdown.*` |
| Card | File named `card.*` |
| Modal / Dialog | File named `modal.*`, `dialog.*` |
| Table / DataTable | File named `table.*`, `data-table.*` |
| Toast / Notification | File named `toast.*`, `notification.*`, `sonner` usage |
| Avatar | File named `avatar.*` |
| Badge | File named `badge.*` |
| Tabs | File named `tabs.*` |

For each component, extract:
- **Variants:** From props/types (size: sm/md/lg, variant: primary/secondary/outline)
- **Props interface:** From TypeScript types/interfaces
- **Dependencies:** Other components imported

### 4.3 ID Assignment

- Design tokens: DS-010, DS-020 (10-increment, one per token category)
- Components: CMP-010, CMP-020 (10-increment)
- Order: tokens first (color, typography, spacing, radius, shadow, breakpoint), then components (alphabetical)
