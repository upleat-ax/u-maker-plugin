# Tech Stack Validation Rules

## 1. Supported Frameworks

### Frontend
| Framework | Versions | Status |
|-----------|----------|--------|
| React | 18.x, 19.x | Supported |
| Next.js | 14.x, 15.x | Supported (App Router preferred) |
| React Native | 0.73+ | Supported |
| Vue | 3.x | Supported |
| Nuxt | 3.x | Supported |
| Svelte | 4.x, 5.x | Supported |
| SvelteKit | 2.x | Supported |

### Backend
| Framework | Versions | Status |
|-----------|----------|--------|
| Next.js API Routes | 14.x, 15.x | Supported |
| Express | 4.x, 5.x | Supported |
| Fastify | 4.x | Supported |
| NestJS | 10.x | Supported |
| Hono | 4.x | Supported |

### Database / ORM
| Tool | Versions | Status |
|------|----------|--------|
| Prisma | 5.x, 6.x | Supported |
| Drizzle ORM | 0.30+ | Supported |
| Supabase | Latest | Supported |
| PostgreSQL | 14+ | Supported |
| MySQL | 8.x | Supported |
| SQLite | 3.x | Supported |
| MongoDB | 7.x | Supported |

## 2. Required Project Structure

### Next.js (App Router)
```
src/
  app/
    layout.tsx
    page.tsx
    (routes)/
      [route]/
        page.tsx
        layout.tsx
  components/
    ui/           # Shared UI components
    features/     # Feature-specific components
  lib/            # Utilities, helpers
  hooks/          # Custom React hooks
  types/          # TypeScript type definitions
  styles/         # Global styles
  services/       # API service layer
  stores/         # State management
```

### React Native
```
src/
  screens/        # Screen components
  components/
    ui/           # Shared UI components
    features/     # Feature-specific components
  navigation/     # Navigation configuration
  hooks/          # Custom hooks
  services/       # API services
  stores/         # State management
  types/          # TypeScript types
  utils/          # Utilities
  assets/         # Images, fonts
```

### Backend (Express/Fastify/NestJS)
```
src/
  routes/         # Route handlers (or controllers/)
  services/       # Business logic
  models/         # Database models
  middleware/     # Express/Fastify middleware
  utils/          # Utilities
  types/          # TypeScript types
  config/         # Configuration
  prisma/         # Prisma schema & migrations (if using Prisma)
```

## 3. Naming Conventions

### Files & Directories
| Type | Convention | Example |
|------|-----------|---------|
| Components | PascalCase | `UserProfile.tsx` |
| Pages/Routes | kebab-case | `user-profile/page.tsx` |
| Hooks | camelCase with `use` prefix | `useAuth.ts` |
| Utilities | camelCase | `formatDate.ts` |
| Types | PascalCase | `UserTypes.ts` |
| Constants | UPPER_SNAKE_CASE (file: kebab-case) | `api-constants.ts` → `export const API_BASE_URL` |
| Styles | kebab-case | `global-styles.css` |
| Tests | same as source + `.test` | `UserProfile.test.tsx` |
| Directories | kebab-case | `user-profile/` |

### Code
| Type | Convention | Example |
|------|-----------|---------|
| Components | PascalCase | `function UserProfile()` |
| Functions | camelCase | `function getUserById()` |
| Variables | camelCase | `const userName = ...` |
| Constants | UPPER_SNAKE_CASE | `const MAX_RETRY_COUNT = 3` |
| Types/Interfaces | PascalCase | `interface UserProfile {}` |
| Enums | PascalCase (members: UPPER_SNAKE_CASE) | `enum UserRole { ADMIN, USER }` |
| CSS classes | kebab-case (or Tailwind utilities) | `user-profile-card` |

## 4. Package Management Rules

### Package Manager
- **bun** — Preferred (fastest, default for new projects)
- **pnpm** — Acceptable (especially for monorepos)
- **npm** — Acceptable (legacy projects)
- **yarn** — Acceptable (if already in use)
- **Rule:** One package manager per project. Do not mix.

### Dependency Rules
1. **Lock files must be committed** — `bun.lockb`, `pnpm-lock.yaml`, `package-lock.json`, or `yarn.lock`
2. **Exact versions in production** — Use exact versions for critical dependencies
3. **Audit before adding** — Check bundle size, maintenance status, license
4. **No duplicate functionality** — One library per concern (e.g., one date library, one HTTP client)
5. **Peer dependency compliance** — Always resolve peer dependency warnings

### Prohibited Patterns
- `*` version ranges in dependencies
- Installing packages globally for project use
- Committing `node_modules/`
- Using deprecated packages without migration plan
