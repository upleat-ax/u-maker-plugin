# Code Generation Rules

This reference defines the patterns, conventions, and verification procedures for generating code from Design phase specifications. All generated code must maintain a traceable link back to its originating specification item.

## 1. Spec-to-Code Mapping Principle

Every generated file traces back to a specific design artifact. The mapping is:

| Design Artifact | Code Output | ID Prefix |
|----------------|-------------|-----------|
| Screen Spec (screens.json) | FE components, pages, layouts | SC- |
| API Contract (api.json) | BE route handlers, controllers | API- |
| ERD (erd.json) | DB schema, migrations, models | ENT- |
| Design System (design-system.json) | Theme config, shared components | DS- |

Each generated file MUST include a header comment referencing the spec item it implements:

```typescript
/**
 * @spec SC-010 LoginScreen
 * @generated u-dev 4.0.0
 * @sync-hash abc123  // hash of spec content at generation time
 */
```

## 2. FE Component Generation from Screen Spec

### 2.1 Screen Spec Structure

The `screens.json` companion contains screen definitions with the following structure:

```json
{
  "id": "SC-010",
  "name": "LoginScreen",
  "route": "/login",
  "layout": "auth",
  "sections": [
    {
      "id": "SC-010-S1",
      "name": "LoginForm",
      "type": "form",
      "fields": [
        { "name": "email", "type": "email", "validation": "required|email" },
        { "name": "password", "type": "password", "validation": "required|min:8" }
      ],
      "actions": [
        { "label": "Sign In", "type": "submit", "api": "API-010" },
        { "label": "Forgot Password", "type": "link", "route": "/forgot-password" }
      ]
    }
  ],
  "state": { "loading": false, "error": null },
  "guards": ["guest-only"]
}
```

### 2.2 Generation Rules

For each screen item in `screens.json`:

1. **Page Component**: Generate `src/app/(group)/[route]/page.tsx` (Next.js) or `src/pages/[Route].vue` (Vue)
2. **Section Components**: Each `sections[]` item becomes a child component under `src/components/[screen-name]/`
3. **Form Sections**: Generate form with validation rules mapped from `fields[].validation`
4. **Action Bindings**: Map `actions[].api` references to API call hooks/composables
5. **State Management**: Generate local state from `screen.state` definition
6. **Route Guards**: Map `guards[]` to middleware/route protection

### 2.3 Component File Template

```typescript
// src/components/LoginScreen/LoginForm.tsx
// @spec SC-010-S1 LoginForm

"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { loginFormSchema, type LoginFormData } from "@/schemas/login";
import { useLogin } from "@/hooks/api/use-login"; // links to API-010

export function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<LoginFormData>({
    resolver: zodResolver(loginFormSchema),
  });
  const { mutate: login, isPending } = useLogin();

  return (
    <form onSubmit={handleSubmit((data) => login(data))}>
      {/* Generated fields from spec */}
    </form>
  );
}
```

### 2.4 Design Token Application

When `design-system.json` is available:

- Map color tokens to Tailwind CSS theme extensions or CSS custom properties
- Map typography tokens to font size/weight/line-height utilities
- Map spacing tokens to consistent padding/margin values
- Map component variants (e.g., `button.primary`, `button.secondary`) to component prop variants

## 3. BE Route Generation from API Contract

### 3.1 API Contract Structure

The `api.json` companion contains endpoint definitions:

```json
{
  "id": "API-010",
  "method": "POST",
  "path": "/api/v1/auth/login",
  "group": "auth",
  "summary": "User login",
  "request": {
    "body": {
      "email": { "type": "string", "format": "email", "required": true },
      "password": { "type": "string", "minLength": 8, "required": true }
    }
  },
  "response": {
    "200": { "schema": "AuthTokenResponse" },
    "401": { "schema": "ErrorResponse", "message": "Invalid credentials" }
  },
  "auth": "none",
  "rateLimit": "10/min"
}
```

### 3.2 Generation Rules

For each endpoint in `api.json`:

1. **Route File**: Generate handler in `src/routes/[group]/[action].ts` (Express) or `src/[group]/[group].controller.ts` (NestJS)
2. **Request Validation**: Generate Zod/class-validator schema from `request.body`/`request.params`/`request.query`
3. **Response Types**: Generate TypeScript interfaces from `response[].schema`
4. **Auth Middleware**: Map `auth` field to middleware (`none`, `bearer`, `api-key`, `session`)
5. **Rate Limiting**: Apply rate limit configuration from `rateLimit` field
6. **Error Handling**: Generate error responses matching `response` error codes

### 3.3 Route Handler Template (Express)

```typescript
// src/routes/auth/login.ts
// @spec API-010 POST /api/v1/auth/login

import { Router } from "express";
import { z } from "zod";
import { validate } from "@/middleware/validate";
import { rateLimit } from "@/middleware/rate-limit";
import { AuthService } from "@/services/auth.service";

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

const router = Router();

router.post(
  "/login",
  rateLimit({ max: 10, window: "1m" }),
  validate(loginSchema),
  async (req, res, next) => {
    try {
      const result = await AuthService.login(req.body);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
);

export default router;
```

## 4. DB Schema Generation from ERD

### 4.1 ERD Structure

The `erd.json` companion contains entity definitions:

```json
{
  "id": "ENT-010",
  "name": "Users",
  "tableName": "users",
  "columns": [
    { "name": "id", "type": "uuid", "primary": true, "default": "gen_random_uuid()" },
    { "name": "email", "type": "varchar(255)", "unique": true, "nullable": false },
    { "name": "password_hash", "type": "varchar(255)", "nullable": false },
    { "name": "created_at", "type": "timestamptz", "default": "now()" }
  ],
  "relations": [
    { "type": "hasMany", "target": "ENT-020", "foreignKey": "user_id" }
  ],
  "indexes": [
    { "columns": ["email"], "unique": true }
  ]
}
```

### 4.2 Generation Rules

For each entity in `erd.json`:

1. **Prisma Model**: Generate model block in `prisma/schema.prisma`
2. **Migration**: Generate SQL migration in `prisma/migrations/[timestamp]_[name]/migration.sql`
3. **Type Definitions**: Generate TypeScript types reflecting the entity shape
4. **Seed Data**: Generate seed template if entity has `seedData` defined

### 4.3 Prisma Model Template

```prisma
// @spec ENT-010 User
model User {
  id           String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  email        String   @unique @db.VarChar(255)
  passwordHash String   @db.VarChar(255)
  createdAt    DateTime @default(now()) @db.Timestamptz
  updatedAt    DateTime @updatedAt @db.Timestamptz

  // Relations
  posts        Post[]   // ENT-020

  @@map("users")
  @@index([email])
}
```

> **Rule:** Both Prisma model fields and DB column names use camelCase. No `@map` needed for columns. Only `@@map("pluralCamelCase")` at the model level for the table name. See `erd-spec.md § 8` for full conventions.

## 5. File Naming Conventions

### 5.1 FE Files

| Type | Pattern | Example |
|------|---------|---------|
| Page | `src/app/(group)/[route]/page.tsx` | `src/app/(auth)/login/page.tsx` |
| Layout | `src/app/(group)/layout.tsx` | `src/app/(auth)/layout.tsx` |
| Component | `src/components/[ScreenName]/[SectionName].tsx` | `src/components/LoginScreen/LoginForm.tsx` |
| Hook | `src/hooks/[category]/use-[name].ts` | `src/hooks/api/use-login.ts` |
| Schema | `src/schemas/[name].ts` | `src/schemas/login.ts` |
| Type | `src/types/[name].ts` | `src/types/auth.ts` |

### 5.2 BE Files

| Type | Pattern | Example |
|------|---------|---------|
| Controller | `src/[group]/[group].controller.ts` | `src/auth/auth.controller.ts` |
| Service | `src/[group]/[group].service.ts` | `src/auth/auth.service.ts` |
| Route (Express) | `src/routes/[group]/[action].ts` | `src/routes/auth/login.ts` |
| Middleware | `src/middleware/[name].ts` | `src/middleware/validate.ts` |
| DTO | `src/[group]/dto/[name].dto.ts` | `src/auth/dto/login.dto.ts` |

### 5.3 DB Files

| Type | Pattern | Example |
|------|---------|---------|
| Prisma Schema | `prisma/schema.prisma` | Single file, all models |
| Migration | `prisma/migrations/[ts]_[name]/migration.sql` | `prisma/migrations/20260403_add_users/migration.sql` |
| Seed | `prisma/seed.ts` | Single entry point |

## 6. Spec-Sync Verification Procedures

After code generation, a verification pass ensures 100% coverage between specs and generated code.

### 6.1 Verification Matrix

```
Screen Spec (SC-*) → Component files exist
  - Each SC item has a page file
  - Each SC section has a component file
  - Each SC action with API ref has a hook/composable

API Contract (API-*) → Route handlers exist
  - Each API item has a route handler
  - Request validation schema matches API request spec
  - Response types match API response spec
  - Auth middleware matches API auth field

ERD (ENT-*) → DB schema entries exist
  - Each ENT item has a Prisma model
  - All columns present with correct types
  - All relations defined
  - All indexes created
```

### 6.2 Sync Hash

Each generated file stores a `@sync-hash` computed from the spec content at generation time. During verification:

1. Recompute hash from current spec content
2. Compare with stored `@sync-hash`
3. If mismatch → spec has changed since generation → flag for regeneration

### 6.3 Coverage Report Format

```json
{
  "timestamp": "2026-04-03T12:00:00Z",
  "coverage": {
    "screens": { "total": 12, "covered": 12, "gaps": [] },
    "apis": { "total": 24, "covered": 23, "gaps": ["API-150"] },
    "entities": { "total": 8, "covered": 8, "gaps": [] }
  },
  "syncStatus": {
    "stale": ["SC-030"],
    "current": ["SC-010", "SC-020", "..."]
  }
}
```

### 6.4 Gap Resolution

When coverage gaps are found:

1. Log gap with spec item ID and expected file path
2. If `--auto` flag is set, generate missing files automatically
3. If manual mode, output gap report and pause for user review
4. Re-run verification after gap resolution to confirm 100% coverage

## 7. Incremental Generation

### 7.1 Re-generation Policy

When specs change after initial code generation:

1. **Detect changed specs**: Compare current spec JSON hash against stored `@sync-hash` in generated files
2. **Scope the change**: Identify which spec items changed (added, modified, deleted)
3. **Generate only affected files**: Do not regenerate files whose spec items are unchanged
4. **Preserve manual edits**: If a generated file has been manually modified (detected via git diff), warn before overwriting and require `--force` flag

### 7.2 Change Impact Analysis

```
Spec Change          → Code Impact
─────────────────────────────────────────────
SC item added        → New page + component files
SC item modified     → Regenerate affected components
SC item deleted      → Mark files for removal (manual confirmation)
API item added       → New route handler + validation + types
API item modified    → Regenerate route, update validation schema
API item deleted     → Mark route for removal
ENT column added     → Update Prisma model, generate migration
ENT column modified  → Update Prisma model, generate migration
ENT relation changed → Update both sides of relation in Prisma
```

### 7.3 Conflict Resolution

When a generated file has both spec changes and manual edits:

1. Show a diff between the current file and the newly generated version
2. Offer three options: accept generated, keep manual, merge manually
3. Log the conflict resolution choice for audit trail

## 8. Barrel Export Generation

### 8.1 Component Barrel Files

Each screen component directory gets an `index.ts` barrel export:

```typescript
// src/components/LoginScreen/index.ts
// @generated u-dev 4.0.0

export { LoginForm } from "./LoginForm";
export { SocialLoginButtons } from "./SocialLoginButtons";
export { ForgotPasswordLink } from "./ForgotPasswordLink";
```

### 8.2 Route Barrel Files

Each route group gets an `index.ts` that aggregates sub-routes:

```typescript
// src/routes/auth/index.ts
// @generated u-dev 4.0.0

import { Router } from "express";
import loginRouter from "./login";
import registerRouter from "./register";
import resetPasswordRouter from "./reset-password";

const router = Router();
router.use(loginRouter);
router.use(registerRouter);
router.use(resetPasswordRouter);

export default router;
```

### 8.3 Update Rules

Barrel files are regenerated whenever files are added to or removed from their directory. They are always fully regenerated (not incrementally patched) to avoid stale exports.
