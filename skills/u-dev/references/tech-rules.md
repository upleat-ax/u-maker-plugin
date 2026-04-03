# Tech Rules

This reference defines the supported technology stacks, naming conventions, package management preferences, and project structure patterns that u-dev uses when generating code. These rules ensure consistency across all generated artifacts.

## 1. Supported Stacks

### 1.1 Frontend Frameworks

| Framework | Versions | Router | State Management |
|-----------|----------|--------|-----------------|
| React | 18.x, 19.x | React Router 6/7 | Zustand, Jotai, TanStack Query |
| Next.js | 14.x, 15.x | App Router (default), Pages Router (legacy) | Server Components + TanStack Query |
| Vue | 3.x | Vue Router 4 | Pinia |
| Nuxt | 3.x | File-based routing | useState, Pinia |

**Default Selection Logic:**
- If `u-maker.config.json` specifies a stack, use it
- If no config, default to **Next.js 15 App Router** for new projects
- If existing project detected, match the existing stack

### 1.2 Backend Frameworks

| Framework | Versions | ORM | Validation |
|-----------|----------|-----|------------|
| Express | 4.x, 5.x | Prisma | Zod |
| NestJS | 10.x | Prisma, TypeORM | class-validator, Zod |
| Hono | 4.x | Prisma, Drizzle | Zod |
| Fastify | 4.x, 5.x | Prisma | Zod, TypeBox |

**Default Selection Logic:**
- If config specifies, use it
- If NestJS patterns detected (modules, decorators), use NestJS
- Otherwise default to **Express 5** for simplicity or **NestJS 10** for enterprise

### 1.3 Database & ORM

| Database | Versions | ORM | Migration Tool |
|----------|----------|-----|---------------|
| PostgreSQL | 14, 15, 16 | Prisma 5/6 | Prisma Migrate |
| MySQL | 8.x | Prisma 5/6 | Prisma Migrate |
| SQLite | 3.x | Prisma 5/6, Drizzle | Prisma Migrate |
| MongoDB | 6.x, 7.x | Prisma 5/6, Mongoose | Prisma db push |

**Default:** PostgreSQL 16 + Prisma 6

### 1.4 CSS & Styling

| Technology | Usage |
|-----------|-------|
| Tailwind CSS 4.x | Primary utility framework (REQUIRED) |
| CSS Modules | Fallback for complex animations |
| shadcn/ui | Component library (when React/Next.js) |
| Radix UI | Headless primitives (when custom styling needed) |

**Rule:** All HTML output uses Tailwind CSS utility classes. Inline styles are prohibited. Custom CSS is limited to `@layer` definitions and complex animations only.

### 1.5 Testing

| Layer | Tool | Config |
|-------|------|--------|
| Unit | Vitest | `vitest.config.ts` |
| Component | Testing Library (React/Vue) | Integrated with Vitest |
| E2E | Playwright | `playwright.config.ts` |
| API | Vitest + supertest | Integrated with Vitest |

## 2. Naming Conventions

### 2.1 File Naming

| Type | Convention | Example |
|------|-----------|---------|
| React Component | PascalCase | `LoginForm.tsx` |
| Vue Component | PascalCase | `LoginForm.vue` |
| Hook / Composable | camelCase with prefix | `useLogin.ts` / `useLogin.ts` |
| Utility function | camelCase | `formatDate.ts` |
| Constant file | camelCase | `apiEndpoints.ts` |
| Type/Interface file | camelCase | `auth.ts` (inside `types/`) |
| Route handler | camelCase | `login.ts` |
| Controller (NestJS) | kebab-case with suffix | `auth.controller.ts` |
| Service | kebab-case with suffix | `auth.service.ts` |
| Module (NestJS) | kebab-case with suffix | `auth.module.ts` |
| Migration | snake_case with timestamp | `20260403_120000_create_users.sql` |
| Test file | same as source + `.test` | `LoginForm.test.tsx` |
| Story file | same as source + `.stories` | `LoginForm.stories.tsx` |

### 2.2 Code Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Component | PascalCase | `export function LoginForm()` |
| Function | camelCase | `function validateEmail()` |
| Variable | camelCase | `const userName = ...` |
| Constant | UPPER_SNAKE_CASE | `const MAX_RETRY_COUNT = 3` |
| Type / Interface | PascalCase | `interface UserProfile` |
| Enum | PascalCase (members too) | `enum Role { Admin, User }` |
| CSS class (Tailwind) | kebab-case utility | `className="flex items-center"` |
| DB table | camelCase plural | `users`, `userProfiles`, `orderItems` |
| DB column | camelCase | `createdAt`, `userId`, `passwordHash` |
| API path | kebab-case | `/api/v1/user-profiles` |
| Environment variable | UPPER_SNAKE_CASE | `DATABASE_URL` |
| Event name | camelCase with `on` prefix | `onSubmit`, `onClick` |
| Boolean variable | camelCase with `is/has/can` prefix | `isLoading`, `hasError`, `canEdit` |

### 2.3 Import Ordering

All generated files follow this import order, separated by blank lines:

```typescript
// 1. Built-in Node.js modules
import { readFile } from "node:fs/promises";

// 2. External packages
import { z } from "zod";
import { PrismaClient } from "@prisma/client";

// 3. Internal aliases (@/)
import { Button } from "@/components/ui/button";
import { useAuth } from "@/hooks/use-auth";

// 4. Relative imports
import { LoginFormSchema } from "./schema";
import type { LoginFormProps } from "./types";

// 5. Type-only imports (at end, using `import type`)
import type { User } from "@/types/user";
```

## 3. Package Manager

### 3.1 Preference Order

1. **bun** (default, preferred)
2. **pnpm** (if bun unavailable or project uses pnpm-lock.yaml)
3. **npm** (fallback)
4. **yarn** (only if yarn.lock exists)

### 3.2 Detection Logic

```
if bun.lockb exists → bun
elif pnpm-lock.yaml exists → pnpm
elif yarn.lock exists → yarn
elif package-lock.json exists → npm
else → bun (default)
```

### 3.3 Command Mapping

| Action | bun | pnpm | npm |
|--------|-----|------|-----|
| Install | `bun install` | `pnpm install` | `npm install` |
| Add dep | `bun add [pkg]` | `pnpm add [pkg]` | `npm install [pkg]` |
| Add dev dep | `bun add -d [pkg]` | `pnpm add -D [pkg]` | `npm install -D [pkg]` |
| Run script | `bun run [script]` | `pnpm [script]` | `npm run [script]` |
| Execute | `bunx [pkg]` | `pnpx [pkg]` | `npx [pkg]` |

## 4. Project Structure Patterns

### 4.1 Next.js App Router (Default FE)

```
src/
  app/
    (auth)/
      login/page.tsx
      register/page.tsx
      layout.tsx
    (dashboard)/
      page.tsx
      settings/page.tsx
      layout.tsx
    layout.tsx
    not-found.tsx
    error.tsx
    globals.css
  components/
    ui/               # shadcn/ui components
    [ScreenName]/     # screen-specific components
      [Section].tsx
      index.ts        # barrel export
  hooks/
    api/              # API call hooks (TanStack Query)
      use-login.ts
    use-[name].ts     # generic hooks
  lib/
    api-client.ts     # HTTP client config
    utils.ts          # utility functions
  schemas/            # Zod validation schemas
    login.ts
  types/              # TypeScript type definitions
    auth.ts
  stores/             # Zustand/Jotai stores (if needed)
    auth-store.ts
```

### 4.2 Express/NestJS (Default BE)

**Express pattern:**

```
src/
  routes/
    auth/
      login.ts
      register.ts
      index.ts         # Router aggregation
    users/
      list.ts
      [id].ts
      index.ts
  middleware/
    validate.ts
    auth.ts
    rate-limit.ts
    error-handler.ts
  services/
    auth.service.ts
    user.service.ts
  lib/
    prisma.ts          # Prisma client singleton
    logger.ts
  types/
    auth.ts
  index.ts             # App entry point
```

**NestJS pattern:**

```
src/
  auth/
    auth.module.ts
    auth.controller.ts
    auth.service.ts
    dto/
      login.dto.ts
    guards/
      jwt-auth.guard.ts
  users/
    users.module.ts
    users.controller.ts
    users.service.ts
    dto/
      create-user.dto.ts
  common/
    decorators/
    filters/
    interceptors/
    pipes/
  prisma/
    prisma.module.ts
    prisma.service.ts
  app.module.ts
  main.ts
```

### 4.3 Shared / Monorepo

When both FE and BE exist in one project:

```
apps/
  web/               # Next.js frontend
    src/
    package.json
  api/               # Express/NestJS backend
    src/
    package.json
packages/
  shared/            # Shared types, validation schemas
    src/
      types/
      schemas/
    package.json
  ui/                # Shared UI components (optional)
    src/
    package.json
prisma/
  schema.prisma
  migrations/
package.json         # Workspace root
turbo.json           # Turborepo config (if monorepo)
```

## 5. TypeScript Configuration

### 5.1 Strict Mode

All generated `tsconfig.json` files MUST include:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "forceConsistentCasingInFileNames": true,
    "verbatimModuleSyntax": true,
    "moduleResolution": "bundler",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

### 5.2 Rules

- `any` is prohibited. Use `unknown` with type narrowing instead.
- All function parameters and return types must be explicitly typed (no implicit `any`).
- Prefer `interface` for object shapes; use `type` for unions, intersections, and utility types.
- Use `satisfies` operator for type-safe assignments where inference is desired.
- Use `as const` for literal constants.
- Prefer `Record<K, V>` over `{ [key: string]: V }`.

## 6. Code Quality Rules

### 6.1 General

- No `console.log` in production code. Use a structured logger (e.g., `pino`, `winston`).
- No hardcoded secrets or URLs. All configuration via environment variables.
- No magic numbers. Extract to named constants with UPPER_SNAKE_CASE.
- All async functions must have error handling (try/catch or .catch()).
- Prefer early returns to reduce nesting depth.
- Maximum function length: 50 lines. Extract sub-functions if longer.
- Maximum file length: 300 lines. Split into modules if longer.

### 6.2 React-Specific

- Use function components exclusively. No class components.
- Prefer Server Components (Next.js). Use `"use client"` only when needed.
- Memoize expensive computations with `useMemo`, callbacks with `useCallback`.
- Always provide `key` prop for list rendering (never use array index as key for dynamic lists).
- Colocate related code: component, hook, schema, types in the same directory.

### 6.3 API-Specific

- All endpoints return consistent JSON shape: `{ data, error, meta }`.
- Use HTTP status codes correctly (201 for creation, 204 for deletion, 422 for validation).
- All request bodies validated before processing.
- Paginated endpoints use cursor-based pagination by default.
- Rate limiting on all public endpoints.

### 6.4 Database-Specific

- Always use parameterized queries. Never interpolate user input into SQL strings.
- Define explicit indexes for all foreign key columns and frequently queried fields.
- Use database transactions for operations that modify multiple tables.
- Apply soft deletes (`deletedAt` column) for user-facing entities; hard deletes only for ephemeral data.
- All timestamps stored as `timestamptz` (timezone-aware) in UTC.

## 7. Environment Configuration

### 7.1 Environment Files

| File | Purpose | Git-tracked |
|------|---------|-------------|
| `.env` | Local development defaults | No (gitignored) |
| `.env.example` | Template with all required variables (values blanked) | Yes |
| `.env.test` | Test environment overrides | Yes (no secrets) |
| `.env.local` | Developer-specific overrides | No (gitignored) |

### 7.2 Required Variables

Every generated project must define at minimum:

```bash
# .env.example
DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
NODE_ENV="development"
PORT="3000"
JWT_SECRET="<generate-random-secret>"
CORS_ORIGINS="http://localhost:3000"
LOG_LEVEL="debug"
```

### 7.3 Variable Naming

- All environment variables use UPPER_SNAKE_CASE
- Group by prefix: `DB_`, `AUTH_`, `MAIL_`, `S3_`, `REDIS_`
- Boolean values: `"true"` / `"false"` (string, parsed at app startup)
- List values: comma-separated (e.g., `CORS_ORIGINS="http://localhost:3000,http://localhost:5173"`)

## 8. Error Handling Patterns

### 8.1 Application Error Class

All generated backends include a base error class:

```typescript
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: string,
    message: string,
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "AppError";
  }
}

// Usage
throw new AppError(404, "USER_NOT_FOUND", "User with given ID does not exist");
throw new AppError(422, "VALIDATION_ERROR", "Invalid input", { fields: errors });
```

### 8.2 Error Response Shape

All API error responses follow this consistent structure:

```json
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User with given ID does not exist",
    "details": null
  },
  "data": null,
  "meta": {
    "requestId": "req_abc123",
    "timestamp": "2026-04-03T12:00:00Z"
  }
}
```

### 8.3 Frontend Error Boundaries

React applications include error boundaries at the layout level:

- Root error boundary in `app/error.tsx` (catches unhandled errors)
- Route-level error boundaries in `app/(group)/error.tsx`
- Component-level error handling via TanStack Query `onError` callbacks
