# plan-synthesis Reference

Rules for reverse-inferring Plan-level documents (SRS, IA) from Design-level artifacts. Used by `/u-reverse` Steps 5-6.

## 1. SRS Synthesis

### 1.1 FR (Functional Requirements) Derivation

**Source:** ERD entity groups + API endpoint clusters

**Algorithm:**

1. Group ERD entities by domain (from domain grouping in code-extraction § 1.4)
2. Group API endpoints by URL prefix
3. Merge entity groups and API groups that share the same domain
4. For each merged domain group → one FR

**FR generation rule:**

```
FR-{N} {Domain Area Title}

Description: The system shall provide {domain summary} capabilities,
including {list key operations from API endpoints}.

Priority: {Must|Should|Could}
  - Must: domain has ≥3 entities OR ≥5 API endpoints
  - Should: domain has 2 entities OR 3-4 endpoints
  - Could: domain has 1 entity OR 1-2 endpoints
```

**Example:**
```
ERD entities: User, UserProfile, UserSession, UserRole
API endpoints: POST /auth/login, POST /auth/register, POST /auth/logout,
               GET /users/me, PUT /users/me, GET /users/:id

→ FR-010 User Management & Authentication
  Description: The system shall provide user authentication (login, register, logout)
  and user profile management (view, update) with role-based access control.
  Priority: Must
```

### 1.2 US (User Stories) Derivation

**Source:** API endpoint groups + screen workflows

**Algorithm:**

1. For each API endpoint group within a domain:
   - Identify the actor from auth/role data:
     - No auth required → "public user"
     - Basic auth → "authenticated user"  
     - Admin guard → "administrator"
     - Specific role → use role name
   - Identify the action from HTTP method + resource:
     - GET /items → "view the list of items"
     - POST /items → "create a new item"
     - PUT /items/:id → "update an item"
     - DELETE /items/:id → "delete an item"
   - Infer benefit from domain context:
     - CRUD on own resource → "so that I can manage my {resource}"
     - CRUD on others' resource → "so that I can administer {resource}"
     - Read-only → "so that I can review {resource} information"

2. Format: "As a {actor}, I can {action} so that {benefit}"

3. Each US traces to its parent FR (same domain group)

**US generation rule:**

```
US-{N} {Action Summary}

As a {actor}, I can {action} so that {benefit}.

Acceptance Criteria:
- {Derive from API request/response: required fields, validation rules}
- {Derive from auth: must be authenticated, must have role X}
- {Derive from response: returns expected data format}

Traced From: FR-{parent}
```

### 1.3 FT (Feature) Derivation

**Source:** Screens (screens.json) + distinct API capabilities

**Algorithm:**

1. For each screen (SC item):
   - One FT per screen
   - Title: screen name
   - Description: what the screen allows users to do (infer from components + API calls)
   - Story Points: estimate from complexity:
     - Simple (1-3 components, 0-1 API calls) → 1 SP
     - Medium (4-7 components, 2-3 API calls) → 2 SP
     - Complex (8+ components, 4+ API calls, forms) → 3 SP
     - Very Complex (multi-step wizard, real-time, file upload) → 5 SP

2. For API endpoints with no corresponding screen (e.g., webhooks, background jobs):
   - One FT per distinct capability
   - Title: describe the capability

3. Each FT traces to its parent US (match via API calls in the screen → US that covers that API group)

**FT generation rule:**

```
FT-{N} {Screen/Capability Name}

Description: {What users can do on this screen / what this capability provides}
Story Points: {1|2|3|5}

Traced From: US-{parent}
Implements: SC-{screen-id} (if screen-based)
```

### 1.4 NFR (Non-Functional Requirements) Derivation

**Source:** Observable code patterns

Scan the codebase for these patterns:

| Code Pattern | NFR Category | NFR Title |
|-------------|-------------|-----------|
| Rate limiting middleware (`express-rate-limit`, `slowapi`, `@Throttle`) | Performance | Request Rate Limiting |
| CORS configuration (`cors()`, `CorsMiddleware`, `CORS_ALLOWED_ORIGINS`) | Security | Cross-Origin Resource Sharing |
| Cache config (`redis`, `node-cache`, `Cache-Control` headers, `@CacheKey`) | Performance | Response Caching |
| Auth middleware (`passport`, `next-auth`, `django.contrib.auth`, JWT) | Security | Authentication |
| RBAC/permissions (`@Roles`, `has_perm`, `can?`, `@authorize`) | Security | Authorization & Access Control |
| Input validation (`zod`, `joi`, `class-validator`, `pydantic`) | Security | Input Validation |
| Error boundary/handler (global error handler, `ErrorBoundary`) | Reliability | Error Handling |
| Logging (`winston`, `pino`, `logging`, `slog`) | Observability | Application Logging |
| Health check endpoint (`/health`, `/healthz`, `/api/health`) | Reliability | Health Monitoring |
| i18n (`next-intl`, `react-i18next`, `django.utils.translation`) | Usability | Internationalization |
| Responsive breakpoints (Tailwind breakpoints, media queries) | Usability | Responsive Design |
| Tests directory (`__tests__/`, `tests/`, `spec/`) | Quality | Test Coverage |
| CI config (`.github/workflows/`, `Jenkinsfile`, `.gitlab-ci.yml`) | Quality | Continuous Integration |
| Docker (`Dockerfile`, `docker-compose.yml`) | Deployment | Containerization |
| Environment config (`.env.example`, `dotenv`) | Security | Environment Configuration |

**NFR generation rule:**

```
NFR-{N} {Category}: {Title}

Description: The system implements {description of what was detected}.
Evidence: {file path where pattern was detected}

Priority: Must (security/reliability), Should (performance/quality), Could (usability/observability)
```

### 1.5 Stakeholder Derivation

**Source:** Role/permission model from auth system

| Auth Pattern | Stakeholder |
|-------------|-------------|
| No auth (public routes) | Public User |
| Basic auth (login required) | Authenticated User |
| Admin role/guard | Administrator |
| Specific named roles | Named role (e.g., "Editor", "Reviewer") |
| API key auth | External System / Integration |
| Service-to-service auth | Internal Service |

### 1.6 Glossary Derivation

**Source:** Domain terms from code

- Entity/model names → domain nouns
- Enum values → domain vocabulary
- Constants with descriptive names → domain concepts
- Abbreviations in code → expand and define

### 1.7 Traceability Chain

After all items are generated, verify the chain:

```
FR-010 → US-010 → FT-010
FR-010 → US-020 → FT-020
FR-010 → US-020 → FT-030
FR-020 → US-030 → FT-040
...
```

Rules:
- Every FR must have ≥1 US
- Every US must have ≥1 FT
- Every FT must trace back to exactly 1 US
- Every US must trace back to exactly 1 FR
- No orphan items (every item must be in a chain)

## 2. IA Synthesis

### 2.1 Site Map Derivation

**Source:** Routing structure from screen extraction

**Algorithm:**

1. Parse route paths into a tree:
   ```
   /                    → Home (level 0)
   /dashboard           → Dashboard (level 1)
   /dashboard/analytics → Analytics (level 2)
   /users               → Users (level 1)
   /users/[id]          → User Detail (level 2)
   /settings            → Settings (level 1)
   /settings/profile    → Profile Settings (level 2)
   /settings/security   → Security Settings (level 2)
   ```

2. Dynamic routes (`[id]`, `:id`, `{id}`) → indicate detail/edit pages

3. Route groups (Next.js `(group)/`) → logical groupings, not URL segments

4. Map each route to its SC item from screens.json

### 2.2 Page Inventory

**Source:** screens.json + route tree

For each page:

| Field | Source |
|-------|--------|
| ID | IA-{N} (10-increment) |
| Title | Screen name from SC item |
| Route | URL path |
| Parent | Parent route in tree |
| Level | Depth in route tree |
| Type | List / Detail / Form / Dashboard / Auth / Static |
| Auth Required | From screen's auth guard |
| Description | From SC item description |

### 2.3 Navigation Structure

**Source:** Layout components (navbar, sidebar, footer)

Scan layout/navigation components for link lists:

```typescript
// Example detection targets:
<Link href="/dashboard">Dashboard</Link>
<NavItem to="/users">Users</NavItem>
menuItems = [{ path: '/...', label: '...' }]
```

Classify:
- **Primary Navigation:** Top navbar or main sidebar items
- **Secondary Navigation:** Tabs, sub-menus, breadcrumbs
- **Footer Navigation:** Footer links
- **User Navigation:** Profile menu, settings dropdown

### 2.4 User Flow Derivation

**Source:** Screen→API→Screen transitions

**Algorithm:**

1. For each screen, identify:
   - Entry points: routes with no parent or linked from auth pages
   - API calls: which endpoints are called
   - Navigation targets: where links/buttons navigate to

2. Common flow patterns:
   - **Auth Flow:** Login Page → Auth API → Dashboard
   - **CRUD Flow:** List Page → Detail Page → Edit Form → Save API → List Page
   - **Onboarding Flow:** Register → Verify Email → Setup Profile → Dashboard
   - **Checkout Flow:** Cart → Shipping → Payment → Confirmation

3. For each detected flow:
   ```
   Flow: {Flow Name}
   Entry: {Start screen}
   Steps:
     1. {Screen A} — {user action}
     2. {API call} — {system response}
     3. {Screen B} — {next user action}
   Exit: {End screen or redirect}
   ```

### 2.5 ID Assignment

- Site map items: IA-010, IA-020 (10-increment)
- Order: breadth-first from root (level 0 first, then level 1, etc.)
