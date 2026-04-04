# stack-detection Reference

Rules for automatically detecting the project's technology stack from file system artifacts. Used by `/u-reverse` Step 1.

## 1. Detection Priority

When `--src`, `--db`, `--api`, or `--pages` are provided, they override auto-detection for their respective category. Auto-detection still runs for categories without explicit overrides.

## 2. Language & Package Manager Detection

Scan project root (and one level deep) for these indicators:

| File | Language | Package Manager |
|------|----------|----------------|
| `package.json` | JavaScript/TypeScript | npm/yarn/pnpm |
| `tsconfig.json` | TypeScript | (confirms TS) |
| `requirements.txt` | Python | pip |
| `pyproject.toml` | Python | poetry/pip |
| `setup.py` | Python | pip |
| `go.mod` | Go | go modules |
| `Cargo.toml` | Rust | cargo |
| `Gemfile` | Ruby | bundler |
| `composer.json` | PHP | composer |
| `pom.xml` | Java | maven |
| `build.gradle` / `build.gradle.kts` | Java/Kotlin | gradle |
| `mix.exs` | Elixir | mix |
| `pubspec.yaml` | Dart | pub |

If multiple indicators are found (e.g., monorepo), report all and use `--src` to narrow scope.

## 3. Framework Detection

After identifying the language, detect the framework from dependencies.

### Node.js / TypeScript

Read `package.json` → `dependencies` + `devDependencies`:

| Dependency | Framework | Notes |
|------------|-----------|-------|
| `next` | Next.js | Check version for App Router (>=13) vs Pages Router |
| `@remix-run/node` | Remix | |
| `nuxt` | Nuxt | Vue ecosystem |
| `@sveltejs/kit` | SvelteKit | |
| `@angular/core` | Angular | |
| `express` | Express | Often combined with React/Vue frontend |
| `@nestjs/core` | NestJS | |
| `hono` | Hono | |
| `fastify` | Fastify | |
| `koa` | Koa | |

### Python

Read `requirements.txt` or `pyproject.toml` dependencies:

| Dependency | Framework |
|------------|-----------|
| `django` | Django |
| `fastapi` | FastAPI |
| `flask` | Flask |
| `starlette` | Starlette |

### Ruby

Read `Gemfile`:

| Gem | Framework |
|-----|-----------|
| `rails` | Ruby on Rails |
| `sinatra` | Sinatra |

### PHP

Read `composer.json` → `require`:

| Package | Framework |
|---------|-----------|
| `laravel/framework` | Laravel |
| `symfony/framework-bundle` | Symfony |

### Go

Read `go.mod` → `require`:

| Module | Framework |
|--------|-----------|
| `github.com/gin-gonic/gin` | Gin |
| `github.com/gofiber/fiber` | Fiber |
| `github.com/labstack/echo` | Echo |

## 4. ORM / Database Detection

| Indicator | ORM | DB Schema Location |
|-----------|-----|-------------------|
| `prisma/schema.prisma` | Prisma | `prisma/` directory |
| `@prisma/client` in deps | Prisma | Find `*.prisma` files |
| `typeorm` in deps | TypeORM | Scan for `@Entity()` decorators |
| `sequelize` in deps | Sequelize | Scan for `define()` / `init()` calls |
| `drizzle-orm` in deps | Drizzle | Find `drizzle/schema.ts` or `*.schema.ts` |
| `mongoose` in deps | Mongoose | Scan for `Schema()` / `model()` calls |
| `django.db` imports | Django ORM | Scan `models.py` files |
| `sqlalchemy` in deps | SQLAlchemy | Scan for `Base` / `declarative_base()` |
| `activerecord` | ActiveRecord | `app/models/` directory |
| `*.sql` in `migrations/` | Raw SQL | Migration directory |
| `knex` in deps | Knex | Migration files |

**Path resolution priority:**
1. Explicit `--db` path
2. ORM-specific default paths (e.g., `prisma/` for Prisma)
3. Common migration directories: `migrations/`, `db/migrate/`, `alembic/`
4. Model directories: `models/`, `entities/`, `app/models/`

## 5. UI / Page Detection

| Indicator | UI Framework | Page Location |
|-----------|-------------|---------------|
| `next` + `app/` directory | Next.js App Router | `app/**/page.tsx` |
| `next` + `pages/` directory | Next.js Pages Router | `pages/**/*.tsx` |
| `react-router-dom` in deps | React Router | Check route config file |
| `vue-router` in deps | Vue Router | `views/` or `pages/` |
| `@sveltejs/kit` | SvelteKit | `src/routes/` |
| `@angular/router` | Angular | Routed component directories |
| No SPA framework | Server-rendered | Template directories (`templates/`, `views/`) |

**Path resolution priority:**
1. Explicit `--pages` path
2. Framework-specific defaults (e.g., `app/` for Next.js App Router)
3. Common directories: `src/pages/`, `src/views/`, `src/screens/`, `src/app/`

## 6. API Route Detection

| Framework | Route Pattern | Location |
|-----------|--------------|----------|
| Next.js App Router | `export async function GET/POST/PUT/DELETE` | `app/**/route.ts` |
| Next.js Pages | `export default function handler` | `pages/api/**/*.ts` |
| Express | `router.get/post/put/delete()` | Scan `*.ts`/`*.js` for router patterns |
| NestJS | `@Controller()` + `@Get()/@Post()` decorators | `*.controller.ts` |
| FastAPI | `@app.get/post()` decorators | Scan `*.py` |
| Django | `urlpatterns = [path(...)]` | `urls.py` files |
| Rails | `Rails.application.routes.draw` | `config/routes.rb` |
| Laravel | `Route::get/post()` | `routes/api.php`, `routes/web.php` |
| Go (Gin/Fiber/Echo) | `r.GET/POST()` or `app.Get/Post()` | Scan `*.go` |

**Path resolution priority:**
1. Explicit `--api` path
2. Framework-specific defaults
3. Common directories: `routes/`, `controllers/`, `handlers/`, `api/`

## 7. Design Token Detection

| Indicator | Token Source |
|-----------|-------------|
| `tailwind.config.js/ts/mjs` | Tailwind CSS (colors, spacing, fonts, breakpoints) |
| `globals.css` / `variables.css` with `:root` | CSS Custom Properties |
| `theme.ts` / `theme.js` / `tokens.*` | Custom theme files |
| `components.json` (shadcn) | shadcn/ui configuration |
| `@mui/material` in deps | MUI theme provider |
| `chakra-ui` in deps | Chakra UI theme |

## 8. Output Format

Step 1 produces an internal scan-result (not persisted as SSoT doc):

```json
{
  "language": "TypeScript",
  "packageManager": "pnpm",
  "framework": "Next.js",
  "frameworkVersion": "14.2.0",
  "routerType": "App Router",
  "orm": "Prisma",
  "uiFramework": "React",
  "cssFramework": "Tailwind CSS",
  "paths": {
    "src": "src/",
    "db": "prisma/",
    "api": "src/app/api/",
    "pages": "src/app/",
    "overrides": {
      "db": null,
      "api": null,
      "pages": null,
      "src": null
    }
  },
  "detectedFiles": {
    "schemas": ["prisma/schema.prisma"],
    "routes": ["src/app/api/users/route.ts", "..."],
    "pages": ["src/app/page.tsx", "src/app/dashboard/page.tsx", "..."],
    "models": [],
    "themes": ["tailwind.config.ts"],
    "components": ["src/components/ui/button.tsx", "..."]
  }
}
```
