# Scaffolding Specification — Turborepo + Bun Monorepo

모든 `{{PROJECT_NAME}}`은 실행 시 입력받은 project-name으로 치환한다.

---

## §1. 기본 정보

| 항목 | 값 |
|------|-----|
| 프로젝트명 | `{{PROJECT_NAME}}` |
| 패키지 매니저 | Bun (workspace 프로토콜) |
| 모노레포 도구 | Turborepo |
| 네임스페이스 | `@{{PROJECT_NAME}}/*` |
| TypeScript | strict 모드 필수 |
| Node 버전 | >=20 |

---

## §2. 폴더 구조

```
{{PROJECT_NAME}}/
├── apps/
│   ├── web/                    → Next.js 15 (App Router)
│   ├── admin/                  → Next.js 15 (App Router) — 관리자 대시보드
│   └── backend/                → Nest.js API 서버 (포트 2920, prefix /v1)
├── packages/
│   ├── ui-atomics/             → @{{PROJECT_NAME}}/ui-atomics    (atoms: raw HTML + css + inline style)
│   ├── ui-molecules/           → @{{PROJECT_NAME}}/ui-molecules  (atomics 조합만)
│   ├── ui-organisms/           → @{{PROJECT_NAME}}/ui-organisms  (molecules + atomics 조합만)
│   ├── hooks/                  → @{{PROJECT_NAME}}/hooks
│   ├── data/                   → @{{PROJECT_NAME}}/data
│   ├── domain/                 → @{{PROJECT_NAME}}/domain
│   ├── infrastructure/         → @{{PROJECT_NAME}}/infrastructure
│   ├── tokens/                 → @{{PROJECT_NAME}}/tokens
│   └── config/                 → @{{PROJECT_NAME}}/config
└── .u-maker/
    └── docs/
```

---

## §3. 의존 흐름

```
apps/* → hooks → data → domain ← infrastructure
apps/* → ui-organisms → ui-molecules → ui-atomics → tokens
```

UI 패키지는 **Atomic Design 계층**으로 나뉘며, 각 계층은 **자신보다 엄격히 하위인 계층만** 의존한다 (역방향·동위 의존 금지).

패키지별 의존 관계:

| Package | Dependencies |
|---------|-------------|
| `domain` | 없음 (순수 타입/상수) |
| `tokens` | 없음 (순수 CSS) |
| `config` | 없음 (설정 프리셋) |
| `data` | `@{{PROJECT_NAME}}/domain` |
| `infrastructure` | `@{{PROJECT_NAME}}/domain` |
| `hooks` | `@{{PROJECT_NAME}}/data`, `@{{PROJECT_NAME}}/domain` |
| `ui-atomics` | `@{{PROJECT_NAME}}/tokens` |
| `ui-molecules` | `@{{PROJECT_NAME}}/ui-atomics`, `@{{PROJECT_NAME}}/tokens` |
| `ui-organisms` | `@{{PROJECT_NAME}}/ui-molecules`, `@{{PROJECT_NAME}}/ui-atomics`, `@{{PROJECT_NAME}}/tokens` |
| `apps/*` | `@{{PROJECT_NAME}}/hooks`, `@{{PROJECT_NAME}}/ui-organisms`(+`ui-molecules`/`ui-atomics`), `@{{PROJECT_NAME}}/infrastructure`, `@{{PROJECT_NAME}}/domain` |

**역방향 의존 절대 금지.**

**디자인(UI/UX)도 이 파이프라인을 따른다** — `apps/*` 는 `ui-*` 컴포넌트 **조립**만 담당하고, UI 패키지 내부는 Atomic Design 계층(atomics → molecules → organisms)으로 흐른다. **raw HTML·CSS·inline style 은 오직 `ui-atomics`(원자) 에서만 허용**되고, `ui-molecules`·`ui-organisms`·`apps/*` 는 하위 컴포넌트를 **조립만** 한다. 상세 do/don't 는 생성되는 `DESIGN.md` §0 참조.

---

## §4. 기술 스택

| 영역 | 기술 | 비고 |
|------|------|------|
| FE Framework | Next.js 15 (App Router) | Server Component 기본 |
| BE Framework | Nest.js 10+ | apps/backend 전용 |
| 서버 상태 | TanStack Query v5 | packages/hooks |
| 클라이언트 상태 | Zustand | 최소한으로 사용 |
| 스타일링 | 순수 CSS (.css 파일) + token | **`ui-atomics` 한정** raw HTML·CSS Modules(.module.css)·inline style(`style={{…}}`) 허용. `ui-molecules`·`ui-organisms` 는 하위 컴포넌트 조립만(자체 CSS·inline·raw HTML 금지). `apps/*` 도 조립만. CSS-in-JS·Sass·SCSS 는 전 계층 금지 |
| 디자인 토큰 | CSS Custom Properties | packages/tokens. atomics 의 inline style 도 themeable 값은 `var(--*)` 우선(동적 계산값만 raw 허용) |
| 컴포넌트 문서화 | Storybook 8 | packages/ui-atomics · ui-molecules · ui-organisms |
| 린트 | ESLint 9 (Flat Config) | eslint-plugin-header 사용 금지 |
| 타입 | TypeScript 5.x (Strict) | 공유 tsconfig 상속 |

---

## §5. 핵심 규칙

1. **함수형 Only** — class 사용 절대 금지 (Nest.js 제외)
2. **TanStack Query 훅 = usecase** — 별도 usecase 레이어 없음
3. **Server Component 기본** — `'use client'`는 필요 시에만
4. **Atomic Design 스타일 경계** — **raw HTML·CSS·inline style 은 `ui-atomics`(원자) 에서만.** `ui-molecules`·`ui-organisms`·`apps/*` 는 하위 컴포넌트 조립만(자체 raw HTML·inline style·CSS 금지). atomics 의 inline style 도 themeable 값은 `var(--*)` 우선. CSS Modules(`*.module.css`)는 `ui-atomics` 한정 허용
5. **Named export만 사용** — default export 금지 (Next.js page/layout 제외)
6. **Import alias**: `@/` → `src/` (앱 내부), `@{{PROJECT_NAME}}/` → `packages/*`
7. **디자인 의존 파이프라인** — `apps/* → ui-organisms → ui-molecules → ui-atomics → tokens`. 각 상위 계층은 하위 계층 컴포넌트를 **조립만** 한다. 필요한 atom·molecule·organism 이 없으면 우회(raw HTML/inline style)하지 말고 **사용자에게 알린 뒤** 해당 계층 패키지를 확장 (DESIGN.md §0)

---

## §6. 패키지별 생성 상세

### §6.1 packages/config

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/config",
  "version": "0.0.0",
  "private": true,
  "exports": {
    "./eslint": "./eslint/index.js",
    "./tsconfig/base": "./tsconfig/base.json",
    "./tsconfig/nextjs": "./tsconfig/nextjs.json",
    "./tsconfig/library": "./tsconfig/library.json"
  }
}
```

#### tsconfig/base.json

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "bundler",
    "module": "ESNext",
    "target": "ES2022",
    "lib": ["ES2022"],
    "resolveJsonModule": true,
    "isolatedModules": true,
    "incremental": true
  },
  "exclude": ["node_modules"]
}
```

#### tsconfig/nextjs.json

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "extends": "./base.json",
  "compilerOptions": {
    "jsx": "preserve",
    "allowJs": true,
    "noEmit": true,
    "module": "ESNext",
    "plugins": [{ "name": "next" }]
  }
}
```

#### tsconfig/library.json

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "extends": "./base.json",
  "compilerOptions": {
    "declaration": true,
    "declarationMap": true,
    "outDir": "dist",
    "rootDir": "src"
  }
}
```

#### eslint/index.js

```js
import js from "@eslint/js";
import tsPlugin from "@typescript-eslint/eslint-plugin";
import tsParser from "@typescript-eslint/parser";

/** @type {import("eslint").Linter.Config[]} */
export const baseConfig = [
  js.configs.recommended,
  {
    files: ["**/*.{ts,tsx}"],
    plugins: {
      "@typescript-eslint": tsPlugin,
    },
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
      },
    },
    rules: {
      ...tsPlugin.configs.recommended.rules,
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/no-explicit-any": "warn",
    },
  },
  {
    ignores: ["dist/", ".next/", "node_modules/", ".turbo/"],
  },
];

export const nextConfig = [
  ...baseConfig,
  {
    files: ["**/*.{ts,tsx}"],
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
    },
  },
];

export const libraryConfig = [
  ...baseConfig,
];

export const nestConfig = [
  ...baseConfig,
  {
    files: ["**/*.ts"],
    rules: {
      "@typescript-eslint/no-explicit-any": "off",
    },
  },
];
```

#### eslint/package.json (eslint 디렉토리용이 아님 — 위 index.js의 devDependencies는 config의 package.json에 포함)

config의 package.json devDependencies:

```json
{
  "devDependencies": {
    "@eslint/js": "^9.0.0",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "eslint": "^9.0.0",
    "typescript": "^5.0.0"
  }
}
```

---

### §6.2 packages/tokens

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/tokens",
  "version": "0.0.0",
  "private": true,
  "main": "src/index.css",
  "files": ["src/**/*.css"]
}
```

#### src/colors.css

```css
:root {
  --color-primary: #2563eb;
  --color-primary-hover: #1d4ed8;
  --color-secondary: #64748b;
  --color-on-primary: #ffffff;
  --color-on-secondary: #ffffff;
  --color-surface: #ffffff;
  --color-background: #f8fafc;
  --color-border: #e2e8f0;
  --color-text: #0f172a;
  --color-text-muted: #64748b;
  --color-error: #ef4444;
  --color-success: #22c55e;
}
```

#### src/typography.css

```css
:root {
  --font-family-sans: 'Pretendard', -apple-system, sans-serif;
  --font-family-mono: 'JetBrains Mono', monospace;
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.875rem;
  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
}
```

#### src/spacing.css

```css
:root {
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;
  --spacing-2xl: 3rem;
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-full: 9999px;
}
```

#### src/shadows.css

```css
:root {
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}
```

#### src/index.css

```css
@import './colors.css';
@import './typography.css';
@import './spacing.css';
@import './shadows.css';
```

---

### §6.3 packages/domain

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/domain",
  "version": "0.0.0",
  "private": true,
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc --project tsconfig.json",
    "lint": "eslint ."
  },
  "dependencies": {
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "@{{PROJECT_NAME}}/config": "workspace:*",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0"
  }
}
```

#### tsconfig.json

```json
{
  "extends": "@{{PROJECT_NAME}}/config/tsconfig/library",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

#### eslint.config.js

```js
import { libraryConfig } from "@{{PROJECT_NAME}}/config/eslint";

export default libraryConfig;
```

#### src/models/user.ts

```ts
export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  createdAt: string;
  updatedAt: string;
}

export type UserRole = "admin" | "manager" | "member";

export interface CreateUserInput {
  email: string;
  name: string;
  role: UserRole;
}

export interface UpdateUserInput {
  name?: string;
  role?: UserRole;
}
```

#### src/models/index.ts

```ts
export { type User, type UserRole, type CreateUserInput, type UpdateUserInput } from "./user";
```

#### src/repositories/user.repository.ts

```ts
import type { User, CreateUserInput, UpdateUserInput } from "../models";

export interface UserRepository {
  findAll(): Promise<User[]>;
  findById(id: string): Promise<User | null>;
  create(input: CreateUserInput): Promise<User>;
  update(id: string, input: UpdateUserInput): Promise<User>;
  delete(id: string): Promise<void>;
}
```

#### src/repositories/index.ts

```ts
export { type UserRepository } from "./user.repository";
```

#### src/validators/user.schema.ts

```ts
import { z } from "zod";

export const userRoleSchema = z.enum(["admin", "manager", "member"]);

export const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: userRoleSchema,
});

export const updateUserSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  role: userRoleSchema.optional(),
});
```

#### src/validators/index.ts

```ts
export { userRoleSchema, createUserSchema, updateUserSchema } from "./user.schema";
```

#### src/services/index.ts

```ts
// Services barrel export
```

#### src/constants/index.ts

```ts
// Constants barrel export
```

#### src/index.ts

```ts
export * from "./models";
export * from "./repositories";
export * from "./validators";
export * from "./services";
export * from "./constants";
```

---

### §6.4 packages/data

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/data",
  "version": "0.0.0",
  "private": true,
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc --project tsconfig.json",
    "lint": "eslint ."
  },
  "dependencies": {
    "@{{PROJECT_NAME}}/domain": "workspace:*"
  },
  "devDependencies": {
    "@{{PROJECT_NAME}}/config": "workspace:*",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0"
  }
}
```

#### tsconfig.json

```json
{
  "extends": "@{{PROJECT_NAME}}/config/tsconfig/library",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

#### eslint.config.js

```js
import { libraryConfig } from "@{{PROJECT_NAME}}/config/eslint";

export default libraryConfig;
```

#### src/routes/api-routes.ts

```ts
export const API_ROUTES = {
  USERS: {
    LIST: "/v1/users",
    DETAIL: (id: string) => `/v1/users/${id}`,
    CREATE: "/v1/users",
    UPDATE: (id: string) => `/v1/users/${id}`,
    DELETE: (id: string) => `/v1/users/${id}`,
  },
} as const;
```

#### src/routes/index.ts

```ts
export { API_ROUTES } from "./api-routes";
```

#### src/query-keys/user.keys.ts

```ts
export const userKeys = {
  all: ["users"] as const,
  lists: () => [...userKeys.all, "list"] as const,
  list: (filters?: Record<string, unknown>) =>
    [...userKeys.lists(), filters] as const,
  details: () => [...userKeys.all, "detail"] as const,
  detail: (id: string) => [...userKeys.details(), id] as const,
};
```

#### src/query-keys/index.ts

```ts
export { userKeys } from "./user.keys";
```

#### src/mappers/user.mapper.ts

```ts
import type { User } from "@{{PROJECT_NAME}}/domain";

export interface UserApiResponse {
  id: string;
  email: string;
  name: string;
  role: string;
  created_at: string;
  updated_at: string;
}

export const userMapper = {
  toDomain(raw: UserApiResponse): User {
    return {
      id: raw.id,
      email: raw.email,
      name: raw.name,
      role: raw.role as User["role"],
      createdAt: raw.created_at,
      updatedAt: raw.updated_at,
    };
  },

  toDomainList(rawList: UserApiResponse[]): User[] {
    return rawList.map(userMapper.toDomain);
  },
};
```

#### src/mappers/index.ts

```ts
export { userMapper, type UserApiResponse } from "./user.mapper";
```

#### src/repositories/user.repository.impl.ts

```ts
import type { User, UserRepository, CreateUserInput, UpdateUserInput } from "@{{PROJECT_NAME}}/domain";
import { API_ROUTES } from "../routes";
import { userMapper, type UserApiResponse } from "../mappers";

const MOCK_USERS: User[] = [
  {
    id: "1",
    email: "admin@example.com",
    name: "Admin User",
    role: "admin",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
];

const createUserRepository = (
  fetcher: (url: string, options?: RequestInit) => Promise<Response>,
): UserRepository => ({
  async findAll(): Promise<User[]> {
    try {
      const response = await fetcher(API_ROUTES.USERS.LIST);
      const data: UserApiResponse[] = await response.json();
      return userMapper.toDomainList(data);
    } catch {
      return MOCK_USERS;
    }
  },

  async findById(id: string): Promise<User | null> {
    try {
      const response = await fetcher(API_ROUTES.USERS.DETAIL(id));
      const data: UserApiResponse = await response.json();
      return userMapper.toDomain(data);
    } catch {
      return MOCK_USERS.find((u) => u.id === id) ?? null;
    }
  },

  async create(input: CreateUserInput): Promise<User> {
    const response = await fetcher(API_ROUTES.USERS.CREATE, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    const data: UserApiResponse = await response.json();
    return userMapper.toDomain(data);
  },

  async update(id: string, input: UpdateUserInput): Promise<User> {
    const response = await fetcher(API_ROUTES.USERS.UPDATE(id), {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    const data: UserApiResponse = await response.json();
    return userMapper.toDomain(data);
  },

  async delete(id: string): Promise<void> {
    await fetcher(API_ROUTES.USERS.DELETE(id), {
      method: "DELETE",
    });
  },
});

export { createUserRepository };
```

#### src/repositories/index.ts

```ts
export { createUserRepository } from "./user.repository.impl";
```

#### src/utils/index.ts

```ts
// Utils barrel export
```

#### src/index.ts

```ts
export * from "./repositories";
export * from "./mappers";
export * from "./query-keys";
export * from "./routes";
export * from "./utils";
```

---

### §6.5 packages/infrastructure

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/infrastructure",
  "version": "0.0.0",
  "private": true,
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc --project tsconfig.json",
    "lint": "eslint ."
  },
  "dependencies": {
    "@{{PROJECT_NAME}}/domain": "workspace:*",
    "axios": "^1.7.0"
  },
  "devDependencies": {
    "@{{PROJECT_NAME}}/config": "workspace:*",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0"
  }
}
```

#### tsconfig.json

```json
{
  "extends": "@{{PROJECT_NAME}}/config/tsconfig/library",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

#### eslint.config.js

```js
import { libraryConfig } from "@{{PROJECT_NAME}}/config/eslint";

export default libraryConfig;
```

#### src/api/api-client.ts

```ts
import axios, { type AxiosInstance, type InternalAxiosRequestConfig, type AxiosError } from "axios";

const createApiClient = (baseURL?: string): AxiosInstance => {
  const client = axios.create({
    baseURL: baseURL || process.env.NEXT_PUBLIC_API_URL || "http://localhost:2920",
    timeout: 10000,
    headers: {
      "Content-Type": "application/json",
    },
  });

  client.interceptors.request.use(
    (config: InternalAxiosRequestConfig) => {
      const token =
        typeof window !== "undefined"
          ? localStorage.getItem("access_token")
          : null;
      if (token && config.headers) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    },
    (error: AxiosError) => Promise.reject(error),
  );

  client.interceptors.response.use(
    (response) => response,
    (error: AxiosError) => {
      if (error.response?.status === 401) {
        if (typeof window !== "undefined") {
          localStorage.removeItem("access_token");
        }
      }
      return Promise.reject(error);
    },
  );

  return client;
};

export { createApiClient };
```

#### src/api/index.ts

```ts
export { createApiClient } from "./api-client";
```

#### src/auth/index.ts

```ts
// Auth barrel export
```

#### src/storage/storage.ts

```ts
const createStorage = (storage: Storage) => ({
  get<T>(key: string): T | null {
    try {
      const item = storage.getItem(key);
      return item ? (JSON.parse(item) as T) : null;
    } catch {
      return null;
    }
  },

  set<T>(key: string, value: T): void {
    storage.setItem(key, JSON.stringify(value));
  },

  remove(key: string): void {
    storage.removeItem(key);
  },

  clear(): void {
    storage.clear();
  },
});

export const localStore =
  typeof window !== "undefined"
    ? createStorage(window.localStorage)
    : null;

export const sessionStore =
  typeof window !== "undefined"
    ? createStorage(window.sessionStorage)
    : null;
```

#### src/storage/index.ts

```ts
export { localStore, sessionStore } from "./storage";
```

#### src/index.ts

```ts
export * from "./api";
export * from "./auth";
export * from "./storage";
```

---

### §6.6 packages/hooks

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/hooks",
  "version": "0.0.0",
  "private": true,
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc --project tsconfig.json",
    "lint": "eslint ."
  },
  "dependencies": {
    "@{{PROJECT_NAME}}/data": "workspace:*",
    "@{{PROJECT_NAME}}/domain": "workspace:*",
    "@tanstack/react-query": "^5.0.0"
  },
  "peerDependencies": {
    "react": "^18.0.0 || ^19.0.0"
  },
  "devDependencies": {
    "@{{PROJECT_NAME}}/config": "workspace:*",
    "@types/react": "^19.0.0",
    "react": "^19.0.0",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0"
  }
}
```

#### tsconfig.json

```json
{
  "extends": "@{{PROJECT_NAME}}/config/tsconfig/library",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src",
    "jsx": "react-jsx"
  },
  "include": ["src"]
}
```

#### eslint.config.js

```js
import { libraryConfig } from "@{{PROJECT_NAME}}/config/eslint";

export default libraryConfig;
```

#### src/queries/use-users.ts

```ts
import { useQuery } from "@tanstack/react-query";
import { userKeys, createUserRepository } from "@{{PROJECT_NAME}}/data";
import type { User } from "@{{PROJECT_NAME}}/domain";

const repo = createUserRepository(fetch);

export const useUsers = () => {
  return useQuery<User[]>({
    queryKey: userKeys.lists(),
    queryFn: () => repo.findAll(),
  });
};

export const useUser = (id: string) => {
  return useQuery<User | null>({
    queryKey: userKeys.detail(id),
    queryFn: () => repo.findById(id),
    enabled: !!id,
  });
};
```

#### src/queries/index.ts

```ts
export { useUsers, useUser } from "./use-users";
```

#### src/mutations/index.ts

```ts
// Mutations barrel export
```

#### src/index.ts

```ts
export * from "./queries";
export * from "./mutations";
```

---

### §6.7 packages/ui-atomics

**원자(atom) 계층.** raw HTML 요소를 감싸 디자인 시스템의 기본 빌딩블록을 만든다. **이 모노레포에서 raw HTML·CSS(`.css`/CSS Modules)·inline style(`style={{…}}`)·`style` 속성을 직접 쓸 수 있는 유일한 패키지**다. 상위 계층(`ui-molecules`·`ui-organisms`)과 `apps/*` 는 atomics 를 **조립만** 한다. inline style 의 themeable 값(색·간격·radius 등)은 `var(--*)` 토큰을 우선 사용하고, 동적 계산값(progress width·차트 좌표 등)만 raw 값을 허용한다. → `@{{PROJECT_NAME}}/tokens` 의존.

원자 세트(스캐폴드 기본): 콘텐츠·인터랙션 atom `Button`·`Input`·`Label`·`Text`·`Form`, 레이아웃 atom `Box`·`Stack`. 상위 계층이 raw HTML 없이 조립할 수 있도록 레이아웃 atom 을 함께 제공한다.

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/ui-atomics",
  "version": "0.0.0",
  "private": true,
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc --project tsconfig.json",
    "lint": "eslint .",
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build"
  },
  "dependencies": {
    "@{{PROJECT_NAME}}/tokens": "workspace:*"
  },
  "peerDependencies": {
    "react": "^18.0.0 || ^19.0.0",
    "react-dom": "^18.0.0 || ^19.0.0"
  },
  "devDependencies": {
    "@{{PROJECT_NAME}}/config": "workspace:*",
    "@storybook/react": "^8.0.0",
    "@storybook/react-vite": "^8.0.0",
    "storybook": "^8.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0"
  }
}
```

#### tsconfig.json

```json
{
  "extends": "@{{PROJECT_NAME}}/config/tsconfig/library",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src",
    "jsx": "react-jsx"
  },
  "include": ["src"]
}
```

#### eslint.config.js

```js
import { libraryConfig } from "@{{PROJECT_NAME}}/config/eslint";

export default libraryConfig;
```

#### .storybook/main.ts

```ts
import type { StorybookConfig } from "@storybook/react-vite";

const config: StorybookConfig = {
  stories: ["../src/**/*.stories.@(ts|tsx)"],
  framework: {
    name: "@storybook/react-vite",
    options: {},
  },
  addons: [],
};

export { config };
export default config;
```

#### .storybook/preview.ts

```ts
import "@{{PROJECT_NAME}}/tokens/src/index.css";
import type { Preview } from "@storybook/react";

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
  },
};

export default preview;
```

#### src/components/Button/Button.tsx

```tsx
import type { ButtonHTMLAttributes, ReactNode } from "react";
import "./Button.css";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost";
  size?: "sm" | "md" | "lg";
  children: ReactNode;
}

const Button = ({
  variant = "primary",
  size = "md",
  children,
  className = "",
  ...props
}: ButtonProps) => {
  return (
    <button
      className={`btn btn--${variant} btn--${size} ${className}`.trim()}
      {...props}
    >
      {children}
    </button>
  );
};

export { Button, type ButtonProps };
```

#### src/components/Button/Button.css

```css
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: var(--radius-md);
  font-family: var(--font-family-sans);
  font-weight: var(--font-weight-medium);
  cursor: pointer;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.btn--primary {
  background-color: var(--color-primary);
  color: var(--color-on-primary);
}

.btn--primary:hover {
  background-color: var(--color-primary-hover);
}

.btn--secondary {
  background-color: var(--color-secondary);
  color: var(--color-on-secondary);
}

.btn--ghost {
  background-color: transparent;
  color: var(--color-text);
}

.btn--ghost:hover {
  background-color: var(--color-background);
}

.btn--sm {
  padding: var(--spacing-xs) var(--spacing-sm);
  font-size: var(--font-size-sm);
}

.btn--md {
  padding: var(--spacing-sm) var(--spacing-md);
  font-size: var(--font-size-base);
}

.btn--lg {
  padding: var(--spacing-md) var(--spacing-lg);
  font-size: var(--font-size-lg);
}
```

#### src/components/Button/Button.stories.tsx

```tsx
import type { Meta, StoryObj } from "@storybook/react";
import { Button } from "./Button";

const meta: Meta<typeof Button> = {
  title: "Components/Button",
  component: Button,
  argTypes: {
    variant: {
      control: "select",
      options: ["primary", "secondary", "ghost"],
    },
    size: {
      control: "select",
      options: ["sm", "md", "lg"],
    },
  },
};

export default meta;
type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: {
    children: "Button",
    variant: "primary",
    size: "md",
  },
};

export const Secondary: Story = {
  args: {
    children: "Button",
    variant: "secondary",
    size: "md",
  },
};

export const Ghost: Story = {
  args: {
    children: "Button",
    variant: "ghost",
    size: "md",
  },
};
```

#### src/components/Button/index.ts

```ts
export { Button, type ButtonProps } from "./Button";
```

#### src/components/Input/Input.tsx

```tsx
import type { InputHTMLAttributes } from "react";
import "./Input.css";

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  invalid?: boolean;
}

const Input = ({ invalid = false, className = "", ...props }: InputProps) => {
  return (
    <input
      className={`input ${invalid ? "input--invalid" : ""} ${className}`.trim()}
      aria-invalid={invalid || undefined}
      {...props}
    />
  );
};

export { Input, type InputProps };
```

#### src/components/Input/Input.css

```css
.input {
  width: 100%;
  padding: var(--spacing-sm) var(--spacing-md);
  font-family: var(--font-family-sans);
  font-size: var(--font-size-base);
  color: var(--color-text);
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.input:focus {
  outline: 2px solid var(--color-primary);
  outline-offset: 1px;
}

.input--invalid {
  border-color: var(--color-error);
}
```

#### src/components/Input/index.ts

```ts
export { Input, type InputProps } from "./Input";
```

#### src/components/Label/Label.tsx

```tsx
import type { LabelHTMLAttributes, ReactNode } from "react";
import "./Label.css";

interface LabelProps extends LabelHTMLAttributes<HTMLLabelElement> {
  children: ReactNode;
}

const Label = ({ children, className = "", ...props }: LabelProps) => {
  return (
    <label className={`label ${className}`.trim()} {...props}>
      {children}
    </label>
  );
};

export { Label, type LabelProps };
```

#### src/components/Label/Label.css

```css
.label {
  display: inline-block;
  font-family: var(--font-family-sans);
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-medium);
  color: var(--color-text);
}
```

#### src/components/Label/index.ts

```ts
export { Label, type LabelProps } from "./Label";
```

#### src/components/Text/Text.tsx

```tsx
import type { ElementType, ReactNode } from "react";
import "./Text.css";

interface TextProps {
  as?: ElementType;
  size?: "sm" | "base" | "lg" | "xl";
  weight?: "regular" | "medium" | "semibold" | "bold";
  tone?: "default" | "muted" | "error";
  children: ReactNode;
}

const Text = ({
  as: Tag = "span",
  size = "base",
  weight = "regular",
  tone = "default",
  children,
}: TextProps) => {
  return (
    <Tag className={`text text--${size} text--${weight} text--${tone}`}>
      {children}
    </Tag>
  );
};

export { Text, type TextProps };
```

#### src/components/Text/Text.css

```css
.text { font-family: var(--font-family-sans); }
.text--sm { font-size: var(--font-size-sm); }
.text--base { font-size: var(--font-size-base); }
.text--lg { font-size: var(--font-size-lg); }
.text--xl { font-size: var(--font-size-xl); }
.text--regular { font-weight: var(--font-weight-regular); }
.text--medium { font-weight: var(--font-weight-medium); }
.text--semibold { font-weight: var(--font-weight-semibold); }
.text--bold { font-weight: var(--font-weight-bold); }
.text--default { color: var(--color-text); }
.text--muted { color: var(--color-text-muted); }
.text--error { color: var(--color-error); }
```

#### src/components/Text/index.ts

```ts
export { Text, type TextProps } from "./Text";
```

#### src/components/Form/Form.tsx

```tsx
import type { FormHTMLAttributes, ReactNode } from "react";

interface FormProps extends FormHTMLAttributes<HTMLFormElement> {
  children: ReactNode;
}

// raw <form> 은 atom 에서만. 상위 계층은 이 Form 을 조립한다.
const Form = ({ children, ...props }: FormProps) => {
  return <form {...props}>{children}</form>;
};

export { Form, type FormProps };
```

#### src/components/Form/index.ts

```ts
export { Form, type FormProps } from "./Form";
```

#### src/components/Box/Box.tsx

```tsx
import type { CSSProperties, ElementType, ReactNode } from "react";

interface BoxProps {
  as?: ElementType;
  padding?: string;
  background?: string;
  radius?: string;
  style?: CSSProperties;
  children?: ReactNode;
}

// 레이아웃 atom — inline style 로 표현(atomics 한정 허용). themeable 값은 token 우선.
const Box = ({ as: Tag = "div", padding, background, radius, style, children }: BoxProps) => {
  return (
    <Tag
      style={{
        padding,
        background,
        borderRadius: radius,
        ...style,
      }}
    >
      {children}
    </Tag>
  );
};

export { Box, type BoxProps };
```

#### src/components/Box/index.ts

```ts
export { Box, type BoxProps } from "./Box";
```

#### src/components/Stack/Stack.tsx

```tsx
import type { CSSProperties, ReactNode } from "react";

interface StackProps {
  direction?: "row" | "column";
  gap?: string;
  align?: CSSProperties["alignItems"];
  justify?: CSSProperties["justifyContent"];
  children?: ReactNode;
}

// 레이아웃 atom — flex 를 inline style 로 표현(atomics 한정 허용). gap 은 token 우선.
const Stack = ({
  direction = "column",
  gap = "var(--spacing-md)",
  align,
  justify,
  children,
}: StackProps) => {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: direction,
        gap,
        alignItems: align,
        justifyContent: justify,
      }}
    >
      {children}
    </div>
  );
};

export { Stack, type StackProps };
```

#### src/components/Stack/index.ts

```ts
export { Stack, type StackProps } from "./Stack";
```

#### src/index.ts (barrel — 모든 atom)

```ts
export * from "./components/Button";
export * from "./components/Input";
export * from "./components/Label";
export * from "./components/Text";
export * from "./components/Form";
export * from "./components/Box";
export * from "./components/Stack";
```

> **ui-atomics 규칙:** atom 만 raw HTML·CSS·inline style 을 쓴다. 같은 raw 패턴(같은 native 요소 + 스타일)이 두 번 이상 필요하면 그때마다 새 atom 으로 만들고, 상위 계층은 atom 을 조립한다. inline style 의 themeable 값은 `var(--*)` 우선.

---

### §6.8 packages/ui-molecules

**분자(molecule) 계층.** `ui-atomics` 의 atom 들을 **조립만** 해 한 단계 높은 재사용 단위(예: 라벨+입력+에러로 구성된 `Field`)를 만든다. **raw HTML·inline style·자체 `.css` 를 쓰지 않는다** — 시각 표현은 atom 의 props 로만 준다. 필요한 시각 기능이 없으면 molecule 에서 때우지 말고 `ui-atomics` 의 atom 을 추가/확장한다. → `@{{PROJECT_NAME}}/ui-atomics`, `@{{PROJECT_NAME}}/tokens` 의존.

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/ui-molecules",
  "version": "0.0.0",
  "private": true,
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc --project tsconfig.json",
    "lint": "eslint .",
    "storybook": "storybook dev -p 6007",
    "build-storybook": "storybook build"
  },
  "dependencies": {
    "@{{PROJECT_NAME}}/ui-atomics": "workspace:*",
    "@{{PROJECT_NAME}}/tokens": "workspace:*"
  },
  "peerDependencies": {
    "react": "^18.0.0 || ^19.0.0",
    "react-dom": "^18.0.0 || ^19.0.0"
  },
  "devDependencies": {
    "@{{PROJECT_NAME}}/config": "workspace:*",
    "@storybook/react": "^8.0.0",
    "@storybook/react-vite": "^8.0.0",
    "storybook": "^8.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0"
  }
}
```

`tsconfig.json` · `eslint.config.js` · `.storybook/main.ts` · `.storybook/preview.ts` 는 **§6.7 ui-atomics 와 동일**(storybook 포트만 6007).

#### src/components/Field/Field.tsx

```tsx
import { useId } from "react";
import { Stack, Label, Input, Text, type InputProps } from "@{{PROJECT_NAME}}/ui-atomics";

interface FieldProps extends InputProps {
  label: string;
  error?: string;
}

// molecule: atomics 조합만 — raw HTML·inline style·자체 CSS 없음.
const Field = ({ label, error, id, ...inputProps }: FieldProps) => {
  const autoId = useId();
  const fieldId = id ?? autoId;
  return (
    <Stack gap="var(--spacing-xs)">
      <Label htmlFor={fieldId}>{label}</Label>
      <Input id={fieldId} invalid={!!error} {...inputProps} />
      {error ? (
        <Text size="sm" tone="error">
          {error}
        </Text>
      ) : null}
    </Stack>
  );
};

export { Field, type FieldProps };
```

#### src/components/Field/index.ts

```ts
export { Field, type FieldProps } from "./Field";
```

#### src/index.ts

```ts
export * from "./components/Field";
```

---

### §6.9 packages/ui-organisms

**유기체(organism) 계층.** `ui-molecules` 와 `ui-atomics` 를 **조립만** 해 한 화면 안의 독립 섹션(예: `LoginForm`)을 만든다. molecule 과 마찬가지로 **raw HTML·inline style·자체 `.css` 금지** — 하위 컴포넌트 조립과 props 로만 구성한다. `apps/*` 는 주로 이 organism 들을 가져다 화면을 조립한다. → `@{{PROJECT_NAME}}/ui-molecules`, `@{{PROJECT_NAME}}/ui-atomics`, `@{{PROJECT_NAME}}/tokens` 의존.

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/ui-organisms",
  "version": "0.0.0",
  "private": true,
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc --project tsconfig.json",
    "lint": "eslint .",
    "storybook": "storybook dev -p 6008",
    "build-storybook": "storybook build"
  },
  "dependencies": {
    "@{{PROJECT_NAME}}/ui-molecules": "workspace:*",
    "@{{PROJECT_NAME}}/ui-atomics": "workspace:*",
    "@{{PROJECT_NAME}}/tokens": "workspace:*"
  },
  "peerDependencies": {
    "react": "^18.0.0 || ^19.0.0",
    "react-dom": "^18.0.0 || ^19.0.0"
  },
  "devDependencies": {
    "@{{PROJECT_NAME}}/config": "workspace:*",
    "@storybook/react": "^8.0.0",
    "@storybook/react-vite": "^8.0.0",
    "storybook": "^8.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0"
  }
}
```

`tsconfig.json` · `eslint.config.js` · `.storybook/main.ts` · `.storybook/preview.ts` 는 **§6.7 ui-atomics 와 동일**(storybook 포트만 6008).

#### src/components/LoginForm/LoginForm.tsx

```tsx
"use client";

import type { FormEvent } from "react";
import { Form, Stack, Button } from "@{{PROJECT_NAME}}/ui-atomics";
import { Field } from "@{{PROJECT_NAME}}/ui-molecules";

interface LoginFormProps {
  onSubmit?: (data: { email: string; password: string }) => void;
}

// organism: molecules + atomics 조합만 — raw HTML·inline style·자체 CSS 없음.
const LoginForm = ({ onSubmit }: LoginFormProps) => {
  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    onSubmit?.({
      email: String(data.get("email") ?? ""),
      password: String(data.get("password") ?? ""),
    });
  };

  return (
    <Form onSubmit={handleSubmit}>
      <Stack gap="var(--spacing-md)">
        <Field label="Email" name="email" type="email" required />
        <Field label="Password" name="password" type="password" required />
        <Button type="submit" variant="primary">
          Sign In
        </Button>
      </Stack>
    </Form>
  );
};

export { LoginForm, type LoginFormProps };
```

#### src/components/LoginForm/index.ts

```ts
export { LoginForm, type LoginFormProps } from "./LoginForm";
```

#### src/index.ts

```ts
export * from "./components/LoginForm";
```

---

### §6.10 apps/web, apps/admin (Next.js)

두 Next.js 앱 모두 동일 구조. `{{APP_NAME}}`은 각각 `web`, `admin`으로 치환.
포트: web=3000, admin=3001.

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/{{APP_NAME}}",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev --port {{PORT}}",
    "build": "next build",
    "start": "next start --port {{PORT}}",
    "lint": "eslint ."
  },
  "dependencies": {
    "@{{PROJECT_NAME}}/domain": "workspace:*",
    "@{{PROJECT_NAME}}/hooks": "workspace:*",
    "@{{PROJECT_NAME}}/infrastructure": "workspace:*",
    "@{{PROJECT_NAME}}/tokens": "workspace:*",
    "@{{PROJECT_NAME}}/ui-atomics": "workspace:*",
    "@{{PROJECT_NAME}}/ui-molecules": "workspace:*",
    "@{{PROJECT_NAME}}/ui-organisms": "workspace:*",
    "@tanstack/react-query": "^5.0.0",
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@{{PROJECT_NAME}}/config": "workspace:*",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0"
  }
}
```

`web`·`admin` 두 앱 모두 동일하게 UI 계층(`ui-organisms` → `ui-molecules` → `ui-atomics`)을 의존한다. admin/web 의 시각 차이는 organism 의 variant props 또는 앱별 token 테마로 표현하며, 별도 surface 패키지를 만들지 않는다.

#### next.config.ts

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  transpilePackages: [
    "@{{PROJECT_NAME}}/ui-atomics",
    "@{{PROJECT_NAME}}/ui-molecules",
    "@{{PROJECT_NAME}}/ui-organisms",
    "@{{PROJECT_NAME}}/hooks",
    "@{{PROJECT_NAME}}/data",
    "@{{PROJECT_NAME}}/domain",
    "@{{PROJECT_NAME}}/infrastructure",
  ],
};

export default nextConfig;
```

#### tsconfig.json

```json
{
  "extends": "@{{PROJECT_NAME}}/config/tsconfig/nextjs",
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src", "next-env.d.ts", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

#### eslint.config.js

```js
import { nextConfig } from "@{{PROJECT_NAME}}/config/eslint";

export default nextConfig;
```

#### src/app/globals.css

```css
@import "@{{PROJECT_NAME}}/tokens/src/index.css";

*,
*::before,
*::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: var(--font-family-sans);
  font-size: var(--font-size-base);
  color: var(--color-text);
  background-color: var(--color-background);
  line-height: 1.6;
}

.page-main {
  padding: var(--spacing-xl);
}
```

#### src/app/layout.tsx

```tsx
import type { ReactNode } from "react";
import "./globals.css";

export const metadata = {
  title: "{{APP_NAME}}",
  description: "{{APP_NAME}} application",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
```

#### src/app/page.tsx

```tsx
import { Stack, Text, Button } from "@{{PROJECT_NAME}}/ui-atomics";

export default function HomePage() {
  return (
    <main className="page-main">
      <Stack gap="var(--spacing-md)">
        <Text as="h1" size="xl" weight="bold">
          {{APP_NAME}}
        </Text>
        <Text tone="muted">Welcome to {{APP_NAME}}</Text>
        <Button variant="primary">Get Started</Button>
      </Stack>
    </main>
  );
}
```

> Note: `page.tsx`와 `layout.tsx`는 Next.js 규칙상 default export를 사용한다.
> 이 시작 `page.tsx` 는 **의도적인 최소 placeholder**다 — `<main className="page-main">` 은 허용되는 페이지 레벨 semantic wrapper 이고, 내용은 `ui-atomics` atom(`Stack`/`Text`/`Button`) 조립으로 구성했다. 실제 화면 구현 시 DESIGN.md §0 의 apps/* 계층 규칙(주로 `ui-organisms` 조립, raw HTML/inline style·raw CSS·className 최소화)에 맞춰 교체한다.

#### src/lib/api.ts

```ts
import { createApiClient } from "@{{PROJECT_NAME}}/infrastructure";

export const apiClient = createApiClient();
```

#### src/features/

빈 디렉토리. `.gitkeep` 파일 생성.

---

### §6.11 apps/backend (Nest.js)

#### package.json

```json
{
  "name": "@{{PROJECT_NAME}}/backend",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev": "nest start --watch",
    "build": "nest build",
    "start": "node dist/main",
    "lint": "eslint ."
  },
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/platform-express": "^10.0.0",
    "@nestjs/swagger": "^8.0.0",
    "reflect-metadata": "^0.2.0",
    "rxjs": "^7.8.0"
  },
  "devDependencies": {
    "@{{PROJECT_NAME}}/config": "workspace:*",
    "@nestjs/cli": "^10.0.0",
    "@types/express": "^5.0.0",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0"
  }
}
```

#### nest-cli.json

```json
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "src",
  "compilerOptions": {
    "deleteOutDir": true
  }
}
```

#### tsconfig.json

```json
{
  "extends": "@{{PROJECT_NAME}}/config/tsconfig/base",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src",
    "module": "commonjs",
    "target": "ES2022",
    "moduleResolution": "node",
    "declaration": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "sourceMap": true,
    "incremental": true
  },
  "include": ["src"]
}
```

#### eslint.config.js

```js
import { nestConfig } from "@{{PROJECT_NAME}}/config/eslint";

export default nestConfig;
```

#### src/main.ts

```ts
import { NestFactory } from "@nestjs/core";
import { SwaggerModule, DocumentBuilder } from "@nestjs/swagger";
import { AppModule } from "./app.module";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix("v1");
  app.enableCors();

  const swaggerConfig = new DocumentBuilder()
    .setTitle("{{PROJECT_NAME}} API")
    .setDescription("{{PROJECT_NAME}} Backend API")
    .setVersion("1.0")
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);

  // GET /v1/reference → Swagger UI
  SwaggerModule.setup("v1/reference", app, document);

  // GET /v1/openapi.json → raw OpenAPI spec
  app.getHttpAdapter().get("/v1/openapi.json", (_req: unknown, res: { json: (doc: unknown) => void }) => {
    res.json(document);
  });

  await app.listen(2920);
  console.log("Backend running on http://localhost:2920");
}

bootstrap();
```

#### src/app.module.ts

```ts
import { Module } from "@nestjs/common";
import { UsersModule } from "./users/users.module";

@Module({
  imports: [UsersModule],
})
export class AppModule {}
```

#### src/users/users.module.ts

```ts
import { Module } from "@nestjs/common";
import { UsersController } from "./users.controller";
import { UsersService } from "./users.service";

@Module({
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}
```

#### src/users/users.controller.ts

```ts
import { Controller, Get, Param } from "@nestjs/common";
import { ApiTags, ApiOperation, ApiResponse } from "@nestjs/swagger";
import { UsersService } from "./users.service";

@ApiTags("Users")
@Controller("users")
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @ApiOperation({ summary: "Get all users" })
  @ApiResponse({ status: 200, description: "List of users" })
  findAll() {
    return this.usersService.findAll();
  }

  @Get(":id")
  @ApiOperation({ summary: "Get user by ID" })
  @ApiResponse({ status: 200, description: "User found" })
  @ApiResponse({ status: 404, description: "User not found" })
  findOne(@Param("id") id: string) {
    return this.usersService.findOne(id);
  }
}
```

#### src/users/users.service.ts

```ts
import { Injectable } from "@nestjs/common";

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  created_at: string;
  updated_at: string;
}

@Injectable()
export class UsersService {
  private readonly users: User[] = [
    {
      id: "1",
      email: "admin@example.com",
      name: "Admin User",
      role: "admin",
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    {
      id: "2",
      email: "member@example.com",
      name: "Member User",
      role: "member",
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
  ];

  findAll(): User[] {
    return this.users;
  }

  findOne(id: string): User | undefined {
    return this.users.find((user) => user.id === id);
  }
}
```

---

## §7. Root Configuration Files

### package.json

```json
{
  "name": "{{PROJECT_NAME}}",
  "private": true,
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "lint": "turbo lint",
    "storybook": "turbo storybook --filter=@{{PROJECT_NAME}}/ui-atomics",
    "clean": "turbo clean && rm -rf node_modules"
  },
  "devDependencies": {
    "turbo": "^2.0.0"
  },
  "packageManager": "bun@1.2.0"
}
```

### turbo.json

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "storybook": {
      "cache": false,
      "persistent": true
    },
    "test": {
      "dependsOn": ["^build"]
    }
  }
}
```

### tsconfig.json (root)

```json
{
  "extends": "@{{PROJECT_NAME}}/config/tsconfig/base"
}
```

### .gitignore

```
node_modules/
.next/
dist/
.turbo/
bun.lockb
.env*.local
.u-maker/.state/
.u-maker/output/
.u-maker/reports/
*.tsbuildinfo
```

### CLAUDE.md

프로젝트 루트에 생성하는 **AI 에이전트 가이드**(정본). Claude Code가 이 프로젝트에서 작업할 때 컨텍스트로 로드되어 동작 기준이 된다. **실제 스캐폴드된 구조·스택·규칙만** 기술한다 — 스캐폴드에 없는 컴포넌트(예: 아직 추출하지 않은 layout primitive)를 강제하지 않는다. `{{PROJECT_NAME}}` 치환을 적용하고, Step 6 git commit 에 포함된다.

디자인시스템 섹션 끝의 `@DESIGN.md` 한 줄은 Claude Code 의 **import 문법** — CLAUDE.md 로드 시 `DESIGN.md` 전체를 컨텍스트로 함께 끌어온다(최대 4 hop). 별도 `AGENTS.md`(§AGENTS.md 참조)가 이 CLAUDE.md 를 심볼릭 링크해 Codex CLI 등 AGENTS.md 기반 에이전트도 동일 가이드를 자동 로드한다.

```markdown
# {{PROJECT_NAME}}

Turborepo 모노레포. 패키지 매니저 `bun@1.2.0`, Clean Architecture 레이어 구조.

## 디자인시스템

- 디자인/UI 공통 룰은 **`DESIGN.md`** 가 단일 출처(SSoT). 화면·컴포넌트 작업 전 반드시 참조한다.
- 요약 — **Atomic Design 의존 파이프라인 `apps/* → ui-organisms → ui-molecules → ui-atomics → tokens`**:
  - **`ui-atomics` (원자)**: raw HTML·CSS·inline style·`style` 속성을 쓸 수 있는 **유일한** 계층. native 요소를 감싼 기본 빌딩블록(`Button`/`Input`/`Label`/`Text`/`Form`/`Box`/`Stack` 등). inline style 의 themeable 값은 `var(--*)` 토큰 우선.
  - **`ui-molecules` (분자)**: `ui-atomics` 조립만. raw HTML·inline style·자체 CSS **금지**.
  - **`ui-organisms` (유기체)**: `ui-molecules`+`ui-atomics` 조립만. raw HTML·inline style·자체 CSS **금지**.
  - **`apps/*` (소비자)**: 화면을 `ui-*`(주로 organisms) 컴포넌트 **조립만**으로 구현. raw form·interactive HTML / inline style 금지, raw CSS·`className` 최소화. 필요한 atom·molecule·organism 이 없으면 우회하지 말고 **사용자에게 알리고** 해당 계층 패키지를 확장.
- layout·token·props 변형·폼 정렬·상태 표현·접근성 등 세부 규칙은 `DESIGN.md` 참조. DESIGN.md 와 충돌하면 DESIGN.md 가 우선한다.

@DESIGN.md

## 명령어

- 전체: `bun run dev|build|lint|storybook`
- 단일 앱/패키지: `bun --filter @{{PROJECT_NAME}}/<name> run dev|build`
- Push 전 필수: `bun run build && bun run lint` 통과 확인

## 앱

| 앱 | 포트 | 스택 |
|----|------|------|
| web | 3000 | Next.js 15 App Router |
| admin | 3001 | Next.js 15 App Router (관리자 대시보드) |
| backend | 2920 | Nest.js API, prefix `/v1`, Swagger (`GET /v1/reference`, `GET /v1/openapi.json`) |

## 아키텍처 (Clean Architecture)

의존 흐름: `apps/* → hooks → data → domain ← infrastructure`, `apps/* → ui-organisms → ui-molecules → ui-atomics → tokens`

- **domain** (`@{{PROJECT_NAME}}/domain`): 타입, 인터페이스, Zod 검증, 서비스. 외부 의존 없음.
- **data** (`@{{PROJECT_NAME}}/data`): Repository 구현, Mapper, queryKeys, routes. → domain.
- **infrastructure** (`@{{PROJECT_NAME}}/infrastructure`): axios apiClient, storage. → domain.
- **hooks** (`@{{PROJECT_NAME}}/hooks`): TanStack Query 훅 = usecase. → data, domain.
- **ui-atomics** (`@{{PROJECT_NAME}}/ui-atomics`): 원자 — raw HTML+CSS+inline style 허용 + Storybook. → tokens.
- **ui-molecules** (`@{{PROJECT_NAME}}/ui-molecules`): 분자 — atomics 조합 + Storybook. → ui-atomics, tokens.
- **ui-organisms** (`@{{PROJECT_NAME}}/ui-organisms`): 유기체 — molecules+atomics 조합 + Storybook. → ui-molecules, ui-atomics, tokens.

Repository: 인터페이스는 `domain/src/repositories/`, 구현은 `data/src/repositories/`. API 호출 실패 시 mock fallback (`try { await api(...) } catch { return mockData }`).

Import alias: `@/` → 앱의 `src/`, `@{{PROJECT_NAME}}/` → `packages/*`.

## SSoT

설계 문서(`.u-maker/docs/`): SRS → ERD → API Contract → Screen 이 구현 기준. 코드와 문서가 어긋나면(gap) 문서를 먼저 갱신한 뒤 구현한다.

## 코딩 컨벤션

- TypeScript strict, 함수형(class 금지 — Nest.js 제외), Named export(Next.js page/layout 제외).
- 네이밍: 변수/함수 `camelCase`, 타입 `PascalCase`, 상수 `UPPER_SNAKE_CASE`, 파일 `kebab-case.ts`(컴포넌트 `PascalCase.tsx`).
- Server Component 기본, 필요 시에만 `'use client'`.
- 서버 상태는 TanStack Query(설치됨). 클라이언트 상태가 필요하면 Zustand 권장(스캐폴드 미포함 — 필요 시 추가).
- 스타일: **raw HTML·CSS(`.css`/CSS Modules `*.module.css`)·inline style 은 `ui-atomics`(원자) 에서만** + design token. `ui-molecules`·`ui-organisms`·`apps/*` 는 하위 컴포넌트 조립만(자체 raw HTML·inline style·CSS 금지). atomics 의 inline style 도 themeable 값은 `var(--*)` 우선. CSS-in-JS / Sass / SCSS 는 전 계층 금지(DESIGN.md §0).
- 공통 모듈은 `packages/*` 에 구현.

## 금지사항

1. **앱에서 API 직접 호출 금지** — 반드시 `domain → data → hooks → apps` 경유.
2. **Next.js API Route / Route Handler 금지** — 백엔드는 `apps/backend`(Nest.js, `/v1`) 가 담당.
3. **클래스 금지** — 함수형만 (Nest.js 제외).
4. **역방향 의존 금지** — domain 이 data/infrastructure/hooks 를 import 불가. UI 계층도 `ui-atomics → ui-molecules → ui-organisms` 단방향(상위가 하위만 import).
5. **`packages/` 새 폴더 생성 금지** — 기존 패키지만 사용(원자/분자/유기체는 `ui-atomics`/`ui-molecules`/`ui-organisms` 에만 추가).
6. **`ui-atomics` 밖에서 raw HTML·inline style 금지** — molecules·organisms·apps 는 하위 컴포넌트 조립 + props 로만 표현. 필요한 원시 표현이 없으면 atom 을 추가/확장.

## Git

- Commit: `type(scope): message` (type: feat/fix/refactor/chore/docs/style/test, scope: 패키지·앱명).
- Branch: `feat/|fix/|refactor/|chore/`.
- Push 전 `bun run build && bun run lint` 통과 필수.
```

### DESIGN.md

프로젝트 루트에 생성하는 **디자인/UI 공통 룰**. 모든 프론트엔드 앱(`web`, `admin`)에 공통 적용되며, CLAUDE.md 의 디자인시스템 섹션이 이 문서를 단일 출처로 가리킨다. **실제 스캐폴드된 Atomic Design UI 패키지(`ui-atomics` / `ui-molecules` / `ui-organisms`)와 token(`@{{PROJECT_NAME}}/tokens`) 구조에 맞춰** 기술한다 — 스캐폴드에 없는 컴포넌트를 강제하지 않되, **계층별 스타일 경계(원자만 raw HTML·inline style)** 는 항상 강제한다. `{{PROJECT_NAME}}` 치환을 적용하고, Step 6 git commit 에 포함된다.

```markdown
# DESIGN.md — 디자인/UI 공통 룰

이 문서는 `{{PROJECT_NAME}}` 모노레포의 **모든 프론트엔드 앱에 공통으로 적용**되는 디자인/UI 원칙을 정의한다.

| 앱 | UI surface | 사용 UI 패키지 |
|----|-----------|----------------|
| `apps/web` | 엔드유저 앱 | `@{{PROJECT_NAME}}/ui-organisms` → `ui-molecules` → `ui-atomics` |
| `apps/admin` | 관리자/백오피스 | `@{{PROJECT_NAME}}/ui-organisms` → `ui-molecules` → `ui-atomics` |
| `apps/backend` | — | UI 없음 (Nest.js API) |

모든 앱은 `@{{PROJECT_NAME}}/tokens` 의 design token(`var(--*)`)을 단일 출처로 사용한다. UI 구현은 **Atomic Design 4 계층**(`apps/*` 소비자 → `ui-organisms` → `ui-molecules` → `ui-atomics` 원자)으로 나뉘며 계층마다 규칙이 다르다 — **§0 디자인 의존 파이프라인을 먼저 읽는다.** 핵심: **raw HTML·CSS·inline style 은 `ui-atomics` 에서만**, 그 위는 전부 **조립(composition)**. admin/web 의 시각 차이는 organism 의 variant props 또는 앱별 token 테마로 표현하며 별도 surface 패키지를 만들지 않는다. 운영·아키텍처·금지사항·git 등 디자인 외 룰은 루트 `CLAUDE.md` 참조. DESIGN.md 의 원칙과 충돌하면 DESIGN.md 가 우선한다.

---

## 0. 디자인 의존 파이프라인 (Atomic Design 계층 경계)

코드의 의존 흐름(`apps/* → ui-organisms → ui-molecules → ui-atomics → tokens`)은 **디자인(UI/UX)에도 그대로 적용된다.** UI 는 네 계층으로 나뉘고, **raw HTML·CSS·inline style 을 쓸 수 있는 계층은 `ui-atomics`(원자) 하나뿐**이다. 그 위 계층은 전부 하위 컴포넌트를 **조립**만 한다.

| 계층 | 역할 | raw HTML·inline style·자체 CSS | 사용 가능한 도구 |
|------|------|:---:|------------------|
| **`ui-atomics`** (원자) | native 요소를 감싼 기본 빌딩블록 | ✅ **허용 (유일)** | raw HTML + token 기반 `.css`/CSS Modules + inline `style={{…}}` (themeable 값은 `var(--*)` 우선, 동적 계산값만 raw) |
| **`ui-molecules`** (분자) | atomics 를 묶은 재사용 단위 (예: Field) | ❌ 금지 | `ui-atomics` 컴포넌트 + props |
| **`ui-organisms`** (유기체) | molecules+atomics 로 만든 화면 섹션 (예: LoginForm) | ❌ 금지 | `ui-molecules`·`ui-atomics` 컴포넌트 + props |
| **`apps/*`** (소비자) | 화면을 ui-* 조립으로 구성 | ❌ 금지 (페이지 semantic wrapper 제외) | `ui-*`(주로 organisms) 컴포넌트 + props |

**역방향·동위 금지:** 각 계층은 **자신보다 엄격히 하위인 계층만** import 한다(`atomics ← molecules ← organisms ← apps`). token·design-system 은 어느 ui 계층도 모른다.

### ui-atomics 계층 (원자) — Do / Don't

✅ **Do**
- native 요소(`<button>`/`<input>`/`<label>`/`<form>`/`<div>` 등)를 감싼 atom 을 만들고, **여기서만** raw HTML·`.css`/CSS Modules·inline `style={{…}}` 을 쓴다.
- inline style·CSS 의 themeable 값(color·spacing·radius·typography·shadow)은 `@{{PROJECT_NAME}}/tokens` 의 **token(`var(--*)`)** 을 우선 사용한다. 변형은 컴포넌트 props(`variant`/`size`/`tone` 등)로 노출한다.
- 상위 계층이 raw HTML 없이 조립할 수 있도록 **레이아웃 atom(`Box`/`Stack` 등)** 을 제공한다 — 간격·정렬은 이 atom 의 props 로.

❌ **Don't**
- raw px / hex / rgb 를 themeable 값에 직접 박지 않는다 → token. 단, **동적 계산값**(progress width, 차트 좌표 등)은 inline style 에 raw 값 허용.
- CSS-in-JS / Sass / SCSS 금지(전 계층 공통). design-system 문서에 없는 임의 변형을 즉석에서 만들지 않는다 → 문서 먼저 갱신(SSoT).

### ui-molecules / ui-organisms 계층 — Do / Don't

✅ **Do**
- 화면 조각을 **하위 계층 컴포넌트 조립만**으로 구현한다(molecules=atomics, organisms=molecules+atomics). 변형은 하위 컴포넌트 **props** 로만 준다.
- 필요한 atom·molecule 이 없으면 **여기서 때우지 말고** 하위 계층 패키지에 추가/확장한 뒤 가져다 쓴다.

❌ **Don't**
- raw HTML(`<div>`/`<button>`/`<form>` …)·inline `style={{…}}`·자체 `.css` **금지(하드)**. 레이아웃이 필요하면 `Box`/`Stack` 같은 **레이아웃 atom** 을 조립한다.
- 하위 컴포넌트에 inline `style`·`className` 을 넘겨 색·간격·layout 을 override 하지 않는다 → 하위 계층에서 prop 확장.

### apps/* 계층 (소비자) — Do / Don't

✅ **Do**
- 화면은 `@{{PROJECT_NAME}}/ui-*`(주로 **organisms**) 컴포넌트의 **조립만**으로 구현하고, 변형은 **props** 로만 준다.
- 구조·의미 마크업(`<main>`, `<section>`, `<header>` 등 페이지 레벨 semantic wrapper)은 그대로 써도 된다 — 이건 "raw HTML" 이 아니다. 콘텐츠·인터랙션은 ui-* atom/organism 으로.
- `ui-*` 만으로 화면을 구성할 수 **없으면** 구현을 멈추고 **사용자에게 알린다.** → 해당 계층(atomics/molecules/organisms)에 추가한 뒤 사용.

❌ **Don't**
- `<button>`/`<input>`/`<select>`/`<textarea>`/`<table>`/`<dialog>` 등 form·interactive 요소를 raw HTML 로 직접 쓰지 않는다 → **반드시** `ui-*` 컴포넌트. **(하드 금지)**
- layout·visual 용 inline `style={{…}}` 금지 **(하드 금지)**. raw CSS·`className` 은 페이지 레벨 레이아웃에 한해 최소한만.
- apps 안에서 ad-hoc 비주얼 컴포넌트를 만들거나 raw HTML/inline style 로 ui-* 의 공백을 우회하지 않는다 → 해당 ui 계층으로 올린다.

> **한 줄 요약:** **원자(`ui-atomics`)만 raw HTML·inline style**, molecules·organisms·apps 는 **조립만**. 안 되면 만들지 말고 **알린다.**

---

## 1. 디자인시스템 우선

- 각 앱은 **UI 패키지의 컴포넌트만**(주로 `ui-organisms`) 사용해 화면을 구성한다.
- `ui-atomics` 밖에서 raw HTML 금지 — `<button>` / `<input>` / `<select>` / `<textarea>` / `<table>` 등 form·interactive 요소는 **반드시** atom 으로 만든 뒤 조립한다.
- 앱·molecule·organism 내부에 ad-hoc 비주얼 컴포넌트(raw HTML+inline style)를 만들지 않는다. 새 원시 표현이 필요하면 `ui-atomics` 에 atom 을 추가한 뒤 사용.
- 두 곳 이상에서 쓰이는 컴포넌트는 추상화 수준에 맞는 계층으로 이동 — 원시 빌딩블록이면 `ui-atomics`, atom 조합이면 `ui-molecules`, 화면 섹션이면 `ui-organisms`. **새 `packages/` 폴더 생성 금지** — 이 세 패키지에만 추가.

## 2. layout 은 레이아웃 atom 으로

- molecules·organisms·apps 에서는 **layout 용 inline style·raw `<div>` 전면 금지**: `display`, `flex*`, `grid*`, `gap`, `padding`, `margin`, `alignItems`, `justifyContent` 를 직접 짜지 않는다.
- 대신 `ui-atomics` 의 **레이아웃 atom(`Box`/`Stack`, 필요 시 `Grid`/`Section` 추가)** 을 조립하고, 간격·정렬은 그 atom 의 props 로 준다 — gap 값은 token(`var(--spacing-*)`).
- 레이아웃 atom 내부(`ui-atomics`)에서는 inline style 로 flex/grid 를 표현해도 된다(원자 한정 허용). themeable 값은 token 우선.
- 인접 sibling 간격은 child 의 `marginLeft/Top` 이 아닌 **부모 `Stack` 의 `gap`** 으로 해결.

## 3. design token 만 사용

- color·spacing·radius·typography·shadow 모두 `@{{PROJECT_NAME}}/tokens` 의 **design token** 만 사용. raw px / hex / rgb 직접 지정 금지.
  - color → `var(--color-*)`, spacing/padding/gap → `var(--spacing-*)`, radius → `var(--radius-*)`, typography → `var(--font-size-*)` · `var(--font-weight-*)` · `var(--font-family-*)`, shadow → `var(--shadow-*)`.
- `padding: 8px` / `gap: 12px` 같은 raw 값 금지 → `var(--spacing-sm)` · `var(--spacing-md)`.
- font-size·line-height·font-weight 도 token.

## 4. 시각 효과 inline style — 원자(`ui-atomics`)만 허용

- molecules·organisms·apps 에서 색·border·radius·shadow·opacity 등 visual inline style **금지** → `ui-atomics` atom 의 variant props 로 표현.
- `ui-atomics` 원자는 inline style 로 visual 을 표현해도 된다 — 단 themeable 값은 token(`var(--*)`) 우선.
- raw 값 inline 은 **동적 계산값**(progress bar width, 차트 좌표 등)에 한해, 그것도 원자 안에서만.

## 5. UI 컴포넌트는 props 로 변형

- `ui-atomics` / `ui-molecules` / `ui-organisms` 컴포넌트의 시각 변형은 컴포넌트 props (`variant`, `size`, `tone`, `surface`, `density` 등) 로 표현한다.
- 사용 측(상위 계층)에서 컴포넌트에 inline `style={…}` 을 넘겨 색·간격·layout 을 override 하지 않는다.
- `className` 합성은 **`ui-atomics` 원자 내부 구현**의 몫이다(§0) — atom 이 `variant`/`size` 를 token 기반 클래스로 합성한다. **상위 계층에서 컴포넌트에 `className` 을 넘겨 색·간격·layout 을 override 하지 않는다.** 필요한 변형이 없으면 임의 클래스로 때우지 말고 해당 계층에서 prop 을 확장한다. (스캐폴드 `Button` atom 은 `variant`/`size` props + token 클래스 합성, `Box`/`Stack` atom 은 props + token inline style 방식을 따른다. 새 컴포넌트도 동일 패턴 유지.)

## 6. 폼 정렬 일관성

- 한 화면의 모든 form row 는 **동일 labelWidth** 사용 — 컴포넌트 상단에 상수로 선언.
- form 컨트롤 폭은 token 또는 `width:100%` — raw px (`width: 320`) 지정 금지.
- multi-column 폼은 **grid 기반** 만 사용. row 들이 column 경계에서 정확히 정렬되어야 한다.
- multi-line 컨트롤(Textarea 등) 의 label 은 control 첫 줄 baseline 에 정렬.

## 7. 입력 컨트롤 상태 표현 통일

- `disabled` / `readOnly` / `error` / `focus` 등 상태는 UI 패키지가 제공하는 변형(variant·tone)으로 표현. 사용 측에서 색·border 를 직접 override 하지 않는다.
- 상태별 색/배경은 token(`var(--color-*)`)으로 정의하며, 정책이 바뀌면 UI 패키지 컴포넌트에서 일괄 수정한다.

## 8. 접근성·반응형

- 모든 interactive 요소는 키보드로 도달·조작 가능해야 한다.
- 의미 전달용 이미지·아이콘은 `alt` / `aria-label` 필수. 장식용은 `aria-hidden`.
- breakpoint 는 공통 token/유틸로 정의한 값만 사용 — 앱마다 제각각인 임의 media query 금지.

## 9. SSoT 우선

- 화면·컴포넌트는 `.u-maker/docs/` 의 설계 문서(SRS / ERD / API-Contract / Screen) 가 구현 기준.
- 구현이 문서와 어긋나면 **문서를 먼저 갱신**한 뒤 코드를 맞춘다.

---

## 자가 점검 체크리스트

PR 올리기 전 한 번 훑어본다:

- [ ] **raw HTML·inline style 은 `ui-atomics` 안에만 있다.** molecules·organisms·apps 에는 raw `<div>`/form 요소·`style={{…}}`·자체 `.css` 가 없다.
- [ ] (molecules/organisms/apps) 하위 계층 컴포넌트 **조립 + props** 로만 구성했다. 레이아웃은 `Box`/`Stack` atom 으로 했다.
- [ ] (apps/*) 화면을 `ui-*`(주로 organisms) 조립으로 구성했고, raw CSS·`className` 사용을 최소화했다.
- [ ] 표현 불가한 UI 는 raw HTML/inline style 로 우회하지 않고, 사용자에게 알린 뒤 해당 계층(atomics/molecules/organisms)을 확장했다.
- [ ] (ui-atomics) inline style·CSS 의 themeable 값은 `@{{PROJECT_NAME}}/tokens` 의 token 을 썼다(동적 계산값만 raw).
- [ ] 상위 계층에서 컴포넌트에 색·간격·layout 을 inline `style`·`className` 으로 override 하지 않았다.
- [ ] UI 계층 의존이 단방향이다(`atomics ← molecules ← organisms ← apps`, 역방향·동위 import 없음).
- [ ] form 의 labelWidth · 컨트롤 폭이 row 마다 일치한다.
- [ ] 새 패턴은 추상화 수준에 맞는 계층(atomics/molecules/organisms)에 추가했다.
- [ ] 화면이 설계 문서와 일치하거나, 문서를 함께 갱신했다.
```

### AGENTS.md

프로젝트 루트에 생성하는 **`CLAUDE.md` 로의 심볼릭 링크**. Codex CLI 등 `AGENTS.md` 를 정본으로 자동 로드하는 에이전트가 `CLAUDE.md` 와 **동일한 가이드**를 읽도록 한다 (Codex 는 `CLAUDE.md` 를 읽지 않는다).

PROJECT_DIR 에서 CLAUDE.md · DESIGN.md 를 먼저 생성한 뒤 실행:

```bash
ln -s CLAUDE.md AGENTS.md
```

동작 방식 / 주의:

- **Claude Code** — `CLAUDE.md` 를 자동 로드하고, 그 안의 `@DESIGN.md` import 로 `DESIGN.md` 전체를 컨텍스트에 인라인한다.
- **Codex** — `AGENTS.md`(→ `CLAUDE.md`) 를 자동 로드한다. Codex 에는 import 문법이 없어 `@DESIGN.md` 는 확장되지 않지만, 가이드의 "화면·컴포넌트 작업 전 `DESIGN.md` 반드시 참조" 지시에 따라 `DESIGN.md` 를 **on-demand** 로 읽는다.
- git 은 심볼릭 링크를 그대로 추적하므로 Step 6 `git add -A` 에 포함된다. (Windows 체크아웃은 `core.symlinks=true` 필요 — 미지원 환경에선 `AGENTS.md` 가 일반 텍스트 파일로 풀릴 수 있다.)

---

## §8. SSoT Document Templates

### .u-maker/docs/SRS.md

```markdown
---
Owner: TBD
Status: Draft
Version: 0.1.0
Last Updated: {{ISO_DATE}}
App: {{PROJECT_NAME}}
---

# Software Requirements Specification

## 1. Overview

### 1.1 Purpose

### 1.2 Scope

### 1.3 Definitions & Acronyms

## 2. Functional Requirements

| ID | Category | Requirement | Priority | Status |
|----|----------|-------------|----------|--------|

## 3. Non-Functional Requirements

| ID | Category | Requirement | Priority |
|----|----------|-------------|----------|

## 4. User Stories

| ID | As a... | I want to... | So that... | Linked FR |
|----|---------|-------------|------------|-----------|

## 5. Features (Implementation Units)

| ID | Feature Name | Description | Linked US | Complexity |
|----|-------------|-------------|-----------|------------|
```

### .u-maker/docs/ERD.md

```markdown
---
Owner: TBD
Status: Draft
Version: 0.1.0
Last Updated: {{ISO_DATE}}
App: {{PROJECT_NAME}}
---

# Entity-Relationship Diagram

## Overview

```mermaid
erDiagram
    USER {
        string id PK
        string email UK
        string name
        string role
        datetime createdAt
        datetime updatedAt
    }
```

## Entities

| ID | Entity | Description | Key Fields |
|----|--------|-------------|------------|

## Relationships

| ID | From | To | Type | Description |
|----|------|----|------|-------------|
```

### .u-maker/docs/API-Contract.md

```markdown
---
Owner: TBD
Status: Draft
Version: 0.1.0
Last Updated: {{ISO_DATE}}
App: {{PROJECT_NAME}}
---

# API Contract

## Base URL

`http://localhost:2920/v1`

## Endpoints

| ID | Method | Path | Description | Request Body | Response |
|----|--------|------|-------------|-------------|----------|
| API-010 | GET | /users | List all users | — | User[] |
| API-020 | GET | /users/:id | Get user by ID | — | User |

## Error Responses

| Status | Description |
|--------|-------------|
| 400 | Bad Request |
| 401 | Unauthorized |
| 404 | Not Found |
| 500 | Internal Server Error |
```

### .u-maker/docs/Screen.md

```markdown
---
Owner: TBD
Status: Draft
Version: 0.1.0
Last Updated: {{ISO_DATE}}
App: {{PROJECT_NAME}}
---

# Screen Specification

## Screen List

| ID | Screen Name | Route | Type | Description | Linked US |
|----|------------|-------|------|-------------|-----------|

## Screen Details

### SC-010: (TBD)

**Route:** /
**Type:** dashboard
**Components:**
**Interactions:**
**Validation Rules:**
```

---

## §9. Naming Convention

| 대상 | 규칙 | 예시 |
|------|------|------|
| 변수/함수 | camelCase | `fetchUser`, `userName` |
| 타입/인터페이스 | PascalCase | `UserRepository` |
| 상수 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 파일 (일반) | kebab-case.ts | `user-repository.ts` |
| 파일 (컴포넌트) | PascalCase.tsx | `UserCard.tsx` |

---

## §10. 금지 사항

- class 컴포넌트 / 클래스 (Nest.js 제외)
- 별도 usecase 레이어
- CSS-in-JS / Sass / SCSS (전 계층)
- raw HTML·inline style·자체 CSS 를 `ui-atomics` 밖(`ui-molecules`·`ui-organisms`·`apps/*`)에서 사용 — 이들은 하위 컴포넌트 조립만 (DESIGN.md §0)
- eslint-plugin-header
- npm / yarn / pnpm 관련 설정
- Next.js API Route / Route Handler
- apps에서 API 직접 호출 (반드시 domain → data → hooks 경유)
- 역방향 의존 (domain이 data/hooks를 import / UI 계층의 역방향·동위 import 등)
- packages/ 아래 명세에 없는 새 폴더
