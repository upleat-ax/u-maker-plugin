---
name: u-skill-code-engine
description: "설계 명세(Screen, API, ERD, DesignToken)로부터 코드를 생성하고, Scaffold + Spec-Sync 검증을 수행하는 내부 코드 생성 엔진."
---

# u-skill-code-engine -- Code Generation & Spec-Sync Engine

Screen 설계에서 FE 컴포넌트를, API Contract에서 BE Route Handler를, ERD에서 DB Schema를 생성하고, 생성된 코드가 설계 명세와 일치하는지 Spec-Sync 검증을 수행하는 내부 엔진이다.

**Owner Agent:** u-agent-builder

---

## 1. Operations

### generateFE(screenSpec, techStack)

Screen 설계서에서 Frontend 코드를 생성한다.

**입력:**
- `screens.json` -- 화면 상세 설계
- `design-token.json` -- 디자인 토큰
- `common/ux/ui-components.md` -- 공통 UI 컴포넌트 규격
- `app.config.json` → techStack

**Tech Stack (기본):**

```json
{
  "framework": "Next.js 15 (App Router)",
  "language": "TypeScript",
  "styling": "Tailwind CSS",
  "stateManagement": "zustand",
  "apiClient": "react-query (TanStack Query)",
  "componentLibrary": "shadcn/ui",
  "runtime": "Bun"
}
```

**화면별 코드 생성:**

1. Screen 설계 읽기 → 레이아웃, 컴포넌트, 데이터 요구사항 파악
2. Design Token → Tailwind config 매핑
3. 컴포넌트 단위 분해:
   - Page 컴포넌트 (`page.tsx`)
   - Layout 컴포넌트 (`layout.tsx`, 필요 시)
   - 개별 UI 컴포넌트 (`{Component}.tsx`)
   - API Hooks (`use{Resource}.ts`)
   - State Stores (`{feature}.store.ts`)
   - TypeScript Types (`{resource}.types.ts`)
4. Storybook story 필수 생성

**출력 구조:**

```
{app-root}/src/
  app/
    {screen-route}/
      page.tsx            # Next.js App Router page
      layout.tsx          # Layout (필요 시)
      loading.tsx         # Loading state
  components/
    {screen-name}/
      {Component}.tsx           # 개별 컴포넌트
      {Component}.stories.tsx   # Storybook story
      index.ts                  # Barrel export
  hooks/
    use{Resource}.ts      # react-query hooks
  stores/
    {feature}.store.ts    # Zustand stores
  types/
    {resource}.types.ts   # TypeScript interfaces
```

**코드 규칙:**
- TypeScript strict mode (`any` 금지, `@ts-ignore` 금지)
- Tailwind CSS 유틸리티 클래스 사용 (하드코딩 색상/간격 금지)
- Design Token 참조 필수
- 모든 컴포넌트에 Props interface 정의
- 에러 경계(Error Boundary) 포함
- Loading/Empty/Error 상태 처리

### generateBE(apiContract, techStack)

API Contract에서 Backend 코드를 생성한다.

**입력:**
- `api.json` -- API 엔드포인트 스펙
- `erd.json` -- 엔티티 정의 (response 스키마 참조)
- `common/architecture/api-common.md` -- 공통 API 패턴
- `app.config.json` → techStack

**엔드포인트별 코드 생성:**

1. API 스펙 읽기 → method, path, request/response 스키마
2. 엔드포인트별 생성:
   - Route Handler (`route.ts`) -- Next.js App Router
   - Service Layer (`{resource}.service.ts`) -- 비즈니스 로직
   - Validator (`{resource}.validator.ts`) -- Zod 스키마
   - Types (`{resource}.types.ts`) -- 공유 타입
3. 공통 미들웨어 포함 (auth, error handling, file upload)

**출력 구조:**

```
{app-root}/src/
  app/api/
    {resource}/
      route.ts                  # Next.js Route Handler
    {resource}/[id]/
      route.ts                  # 단일 리소스 핸들러
  lib/
    services/
      {resource}.service.ts     # Business logic
    validators/
      {resource}.validator.ts   # Zod schema validation
    middleware/
      auth.ts                   # Auth middleware
      error-handler.ts          # Global error handler
```

**코드 규칙:**
- Zod validation 필수 (모든 request body/params)
- Error response 표준화 (`{ error: string, code: string, details?: any }`)
- Auth 체크 필수 (public 엔드포인트 제외)
- Secret/credential 하드코딩 금지 → 환경 변수 사용
- 트랜잭션 처리 (복합 DB 작업)

### generateDB(erd, techStack)

ERD에서 Database Schema를 생성한다.

**입력:**
- `erd.json` -- 엔티티 정의, 컬럼, 관계
- `common/architecture/erd-common.md` -- 공통 테이블
- `app.config.json` → techStack.orm, techStack.database

**프로세스:**

1. ERD 엔티티 읽기
2. ORM 스키마 생성 (Prisma 또는 Drizzle):
   - 엔티티 → 모델/테이블
   - 컬럼 → 필드 (타입, 제약조건)
   - 관계 → relation 정의
3. Migration 파일 생성
4. Seed data 템플릿 생성

**출력 구조 (Prisma):**

```
{app-root}/
  prisma/
    schema.prisma
    migrations/
      {timestamp}_init/
        migration.sql
  src/lib/db/
    seed.ts
    client.ts           # PrismaClient singleton
```

**출력 구조 (Drizzle):**

```
{app-root}/
  drizzle/
    schema.ts
    migrations/
      {timestamp}_init.sql
  src/lib/db/
    index.ts            # DB client
    seed.ts
```

### scaffold(appConfig)

프로젝트 boilerplate를 생성한다.

**입력:** `app.config.json` -- 앱별 기술 스택 설정

**생성 항목:**
- 프레임워크 기본 구조 (Next.js App Router)
- 설정 파일 (`tsconfig.json`, `tailwind.config.ts`, `eslint.config.js`)
- ORM 설정 (`prisma/schema.prisma` 또는 `drizzle.config.ts`)
- 테스트 설정 (`vitest.config.ts`, `playwright.config.ts`)
- Storybook 설정 (`.storybook/`)
- 환경 변수 템플릿 (`.env.example`)
- 패키지 설정 (`package.json`)

### specSync(scope)

생성된 코드가 설계 명세와 일치하는지 검증한다.

**검증 규칙:**

| # | Rule | Source | Target | Severity |
|---|------|--------|--------|----------|
| 1 | Screen → Component | screens.json | `app/{route}/page.tsx` | Critical |
| 2 | API → Route Handler | api.json | `app/api/{resource}/route.ts` | Critical |
| 3 | ERD Entity → Model | erd.json | `prisma/schema.prisma` | Critical |
| 4 | FT → Implementation | srs.json | 소스 코드 | Major |
| 5 | Component → File | screens.json 컴포넌트 목록 | `components/{name}/` | Major |
| 6 | Design Token → Usage | design-token.json | Tailwind config + 소스 | Minor |
| 7 | Type Safety | api.json response | TypeScript types | Major |
| 8 | Route Matching | FE API 호출 경로 | BE route 경로 | Critical |

**프로세스:**

```
function specSync(scope):
  results = []

  // Rule 1: Screen coverage
  screens = loadJSON("screens.json")
  for screen in screens:
    route = deriveRoute(screen)
    fileExists = checkFile("app/" + route + "/page.tsx")
    results.push({ rule: 1, screen: screen.id, met: fileExists })

  // Rule 2: API coverage
  api = loadJSON("api.json")
  for endpoint in api.endpoints:
    routePath = deriveRoutePath(endpoint)
    fileExists = checkFile("app/api/" + routePath + "/route.ts")
    results.push({ rule: 2, endpoint: endpoint.path, met: fileExists })

  // Rule 3: ERD coverage
  erd = loadJSON("erd.json")
  for entity in erd.entities:
    modelExists = checkModel(entity.name)
    results.push({ rule: 3, entity: entity.name, met: modelExists })

  // ... rules 4-8

  return generateSpecSyncReport(results)
```

**Spec-Sync Report 출력:**

```markdown
## Spec-Sync Report

| Rule | Description | Total | Matched | Missing | Coverage |
|------|-------------|-------|---------|---------|----------|
| 1 | Screen → Component | 15 | 14 | 1 | 93.3% |
| 2 | API → Route Handler | 23 | 23 | 0 | 100% |
| 3 | ERD → Model | 8 | 8 | 0 | 100% |
| 4 | FT → Implementation | 45 | 40 | 5 | 88.9% |

### Missing Items
- SCR-012 (Settings): Missing `app/settings/page.tsx`
- FT-0032: No implementation found
```

### applyDesignToken(tokenJson)

Design Token 정의에서 Tailwind/CSS 설정을 생성한다.

**입력:** `design-token.json`

**출력:**
- `tailwind.config.ts` 내 `theme.extend` 섹션 갱신
- CSS 변수 정의 (`globals.css`)
- Token → Tailwind class 매핑 문서

---

## 2. Storybook Story Generation

모든 생성 컴포넌트에 대해 Storybook story를 필수 생성한다.

| Variant | Condition |
|---------|-----------|
| Default | 항상 |
| Loading | 비동기 데이터가 있으면 |
| Error | 에러 핸들링이 있으면 |
| Empty | 컬렉션/리스트를 표시하면 |
| Interactive | 사용자 인터랙션이 있으면 |
| Responsive | 반응형 레이아웃 변경이 있으면 |

---

## 3. Safety Rules

1. 모든 생성 파일은 Screen/API/ERD 명세에 역추적 가능해야 함
2. TypeScript strict mode 필수 (`any`, `@ts-ignore` 금지)
3. Secret/credential 하드코딩 금지 (환경 변수 사용)
4. 앱 소스 디렉토리 외부에 코드 생성 금지
5. Storybook story 필수 생성
6. Design Token 참조 필수 (하드코딩 색상/간격 금지)
7. `app.config.json` techStack 확인 후 프레임워크/라이브러리 결정
8. Spec-Sync 검증은 코드 생성 후 반드시 수행
9. 빌드 실패 코드는 출하하지 않음 (자동 수정 시도 → 실패 시 백로그 등록)
10. Zod validation 필수 (모든 API request body/params)
