---
name: u-reverse
description: "소스 코드 역공학. 기존 코드베이스를 분석하여 ERD, API Contract, Screen, IA 등 SSoT 설계 문서를 자동 생성한다. Forward engineering 없이 기존 프로젝트에서 SSoT를 구성할 때 사용한다."
triggers:
  - "/u-reverse"
  - "reverse engineering"
  - "코드 분석"
  - "코드에서 문서"
  - "소스 분석"
  - "역공학"
  - "코드 역공학"
  - "SSoT 구성"
---

# u-reverse -- Source Code to SSoT Reverse Engineering

`/u-reverse [scope] [--only X] [-i] [--step]` 명령으로 기존 코드베이스를 분석하여 SSoT 설계 문서를 역생성한다.

**Primary Agent:** u-agent-planner (코드 분석 + 문서 생성)

> **용도:** 이미 개발된 프로젝트에 u-maker를 도입할 때, 코드에서 SSoT를 구성한다.
> Forward engineering(`/u-plan → /u-design → /u-build`)의 역방향이다.

---

## Flags

| Flag | Description |
|------|-------------|
| `--only X` | 지정 문서만 생성 (erd, api, screens, ia, srs, design-token) |
| `-i` | 각 단계 결과 사용자 확인 후 진행 |
| `--step` | 매 단계 결과 표시 후 승인 대기 |
| `--dry-run` | 분석만 수행하고 문서 생성하지 않음 (분석 리포트만 출력) |

---

## Execution Flow

### Step 0: Verify Prerequisites

1. `.u-maker/` 디렉토리 존재 확인 → 없으면 "/u-init을 먼저 실행하세요" 안내
2. `u-maker.config.json` 읽어 앱 목록 조회
3. scope 해석 → 대상 앱의 소스 코드 경로 결정
4. scope 생략 + 앱 1개: 자동 선택 / 앱 2개+: 사용자에게 질문
5. 대상 앱의 `app.config.json` → `techStack` 확인. 비어 있으면 Step 1에서 자동 감지

### Step 1: Detect Tech Stack

소스 코드에서 기술 스택을 자동 감지한다.

**감지 대상:**

```
파일/패턴                            감지 항목
────────────────────────────────────  ──────────────
package.json (dependencies)          framework, language, styling, stateManagement, apiClient, orm, componentLibrary
tsconfig.json / jsconfig.json        language (TypeScript / JavaScript)
next.config.* / nuxt.config.*        framework (Next.js / Nuxt)
tailwind.config.*                    styling (Tailwind)
prisma/schema.prisma                 orm (Prisma), database
drizzle.config.*                     orm (Drizzle)
docker-compose.yml                   database, infrastructure
.env / .env.example                  환경변수 목록 (값 제외)
requirements.txt / pyproject.toml    Python framework 감지
go.mod                               Go framework 감지
Gemfile                              Ruby framework 감지
```

**프로세스:**
1. 앱 루트에서 설정 파일 스캔
2. `package.json` dependencies 분석 → framework, UI lib, state management, API client 식별
3. ORM 설정 파일 → database type 추론
4. 감지 결과를 `app.config.json`의 `techStack`에 반영
5. 사용자에게 감지 결과 확인 표시:
   ```
   ## Tech Stack Detected
   - Framework: Next.js 14 (App Router)
   - Language: TypeScript
   - Styling: Tailwind CSS
   - State: Zustand
   - API Client: fetch (built-in)
   - ORM: Prisma
   - Database: PostgreSQL
   - Component Library: shadcn/ui
   ```

### Step 2: Extract ERD (Database Schema)

**스캔 대상:**
- `prisma/schema.prisma` (Prisma)
- `drizzle/schema.ts`, `src/db/schema.ts` (Drizzle)
- `**/entities/*.ts`, `**/models/*.ts` (TypeORM / MikroORM)
- `**/migrations/*.sql` (raw SQL migrations)
- `**/models/*.py` (Django / SQLAlchemy)
- `**/models/*.rb` (ActiveRecord)

**프로세스:**
1. ORM 스키마 파일 파싱 → 엔티티, 컬럼, 타입, 관계 추출
2. Migration 파일 → 스키마 진화 히스토리 참조 (최신 상태 기준)
3. 엔티티 간 관계 도출 (1:N, M:N, 1:1)
4. Mermaid ER 다이어그램 생성
5. 각 엔티티에 source 경로 부착
6. `erd.md` + `erd.json` 생성

**출력:** `docs/{app}/02-design/erd.md` + `erd.json`

**ERD 엔티티 구조:**

```json
{
  "entities": [
    {
      "name": "User",
      "description": "(코드 주석 또는 추론)",
      "source": "prisma/schema.prisma:12",
      "columns": [
        { "name": "id", "type": "String", "pk": true, "nullable": false },
        { "name": "email", "type": "String", "unique": true, "nullable": false }
      ],
      "relations": [
        { "target": "Order", "type": "1:N", "foreignKey": "userId" }
      ]
    }
  ]
}
```

### Step 3: Extract API Contract

**스캔 대상:**
- `src/app/api/**/route.ts` (Next.js App Router)
- `src/pages/api/**/*.ts` (Next.js Pages Router)
- `src/routes/**/*.ts` (Express / Fastify)
- `src/**/*.controller.ts` (NestJS)
- `**/urls.py` + `**/views.py` (Django)
- `**/routes/*.rb` (Rails)
- OpenAPI/Swagger 파일 (`openapi.yaml`, `swagger.json`)

**프로세스:**
1. 라우트 파일 스캔 → HTTP method + path 추출
2. Request body 타입/스키마 추출 (Zod, class-validator, TypeScript interface 등)
3. Response 타입 추출 (return type, response helper 분석)
4. Middleware/Guard → 인증 방식 식별
5. 기존 OpenAPI 스펙이 있으면 우선 참조
6. 각 엔드포인트에 source 경로 부착
7. `api.md` + `api.json` 생성

**출력:** `docs/{app}/02-design/api.md` + `api.json`

**API 엔드포인트 구조:**

```json
{
  "endpoints": [
    {
      "method": "POST",
      "path": "/api/v1/auth/login",
      "source": "src/app/api/auth/login/route.ts:15",
      "auth": "None",
      "requestBody": { "email": "string", "password": "string" },
      "responses": {
        "200": { "token": "string", "user": "UserDTO" },
        "401": { "error": "string" }
      },
      "relatedEntity": "User"
    }
  ]
}
```

### Step 4: Extract Screen Structure (IA + Screens)

**스캔 대상:**
- `src/app/**/page.tsx` (Next.js App Router)
- `src/pages/**/*.tsx` (Next.js Pages Router / Nuxt)
- `src/views/**/*.vue` (Vue)
- `src/routes/**/*.svelte` (SvelteKit)
- `src/screens/**/*.tsx` (React Native)

**프로세스:**

#### 4-1. IA (Information Architecture) 추출

1. 라우트 파일 시스템 → URL 계층 구조 도출
2. Layout 파일 (`layout.tsx`) → 레이아웃 그룹 식별
3. Navigation 컴포넌트 → 메뉴 구조 추출
4. Route guard / middleware → 접근 제어 구분 (public / auth-required / admin)
5. `ia.md` + `ia.json` 생성

**출력:** `docs/{app}/01-plan/ia.md` + `ia.json`

**IA 구조:**

```json
{
  "pages": [
    {
      "id": "SCR-001",
      "name": "Login",
      "path": "/login",
      "source": "src/app/login/page.tsx",
      "layout": "AuthLayout",
      "access": "public",
      "children": []
    },
    {
      "id": "SCR-002",
      "name": "Dashboard",
      "path": "/dashboard",
      "source": "src/app/dashboard/page.tsx",
      "layout": "MainLayout",
      "access": "auth-required",
      "children": [
        { "id": "SCR-003", "name": "Analytics", "path": "/dashboard/analytics" }
      ]
    }
  ]
}
```

#### 4-2. Screen 상세 추출

각 페이지 컴포넌트를 분석하여:

1. Import된 컴포넌트 목록 → UI 구성 요소
2. State / Hook 사용 → 인터랙션 패턴
3. API 호출 (fetch, axios, tanstack-query) → 데이터 소스 매핑
4. Form 구조 → 입력 필드 목록
5. 조건부 렌더링 → 화면 상태 (loading, error, empty)
6. `screens.md` + `screens.json` 생성

**출력:** `docs/{app}/02-design/screens.md` + `screens.json`

**Screen 구조:**

```json
{
  "screens": [
    {
      "id": "SCR-001",
      "name": "Login",
      "path": "/login",
      "source": "src/app/login/page.tsx",
      "components": ["LoginForm", "SocialLoginButtons", "Logo"],
      "apiCalls": ["POST /api/auth/login"],
      "stateManagement": ["useAuthStore"],
      "forms": [
        { "name": "loginForm", "fields": ["email", "password"], "validation": "zod" }
      ],
      "states": ["default", "loading", "error"]
    }
  ]
}
```

### Step 5: Extract Screen Flow

**입력:** IA + Screens (Step 4 결과)

**프로세스:**
1. 페이지 간 `<Link>`, `router.push`, `redirect` 추출
2. Form submit 후 이동 경로 추적
3. 조건부 리다이렉트 (auth guard 등) 포함
4. Mermaid flowchart 다이어그램 생성
5. 모든 페이지에 incoming/outgoing 연결 확인
6. `screen-flow.md` + `screen-flow.json` 생성

**출력:** `docs/{app}/02-design/screen-flow.md` + `screen-flow.json`

### Step 6: Extract Design Token

**스캔 대상:**
- `tailwind.config.ts` → theme extend (colors, spacing, fonts)
- `src/styles/globals.css` → CSS custom properties (`--color-*`)
- `src/lib/theme.ts` → theme object
- `*.module.css` / `*.scss` → 공통 변수

**프로세스:**
1. Tailwind config → color palette, spacing, typography, breakpoints 추출
2. CSS variables → 토큰 매핑
3. 공통 컴포넌트 스타일링 → 패턴 도출
4. `design-token.md` + `design-token.json` 생성

**출력:** `docs/{app}/02-design/design-token.md` + `design-token.json`

### Step 7: Generate SRS Skeleton

**입력:** 전체 분석 결과 (ERD, API, Screens)

코드에서 역추론한 기능 요구사항 뼈대를 생성한다:

**프로세스:**
1. API 엔드포인트 → Feature (FT) 목록 도출
2. Screen + API 매핑 → User Story (US) 추론
3. 관련 US 그루핑 → Functional Requirement (FR) 도출
4. 각 항목에 `status: "reverse-engineered"` 표시 (사용자 검증 필요 표기)
5. `srs.md` + `srs.json` 생성

**출력:** `docs/{app}/01-plan/srs.md` + `srs.json`

**SRS 항목 구조:**

```json
{
  "requirements": [
    {
      "id": "FR-0001",
      "title": "사용자 인증",
      "status": "reverse-engineered",
      "source": "코드 분석으로 역추론",
      "userStories": [
        {
          "id": "US-0001",
          "story": "사용자는 이메일과 비밀번호로 로그인할 수 있다",
          "features": [
            {
              "id": "FT-0001",
              "description": "POST /api/auth/login 엔드포인트",
              "screen": "SCR-001",
              "api": "POST /api/v1/auth/login",
              "source": "src/app/api/auth/login/route.ts"
            }
          ]
        }
      ]
    }
  ]
}
```

> **주의:** 역추론된 SRS는 코드 동작 기반이므로, 원래 비즈니스 의도와 다를 수 있다.
> 사용자가 `/u-ingest --review`로 검증하거나 직접 수정해야 한다.

### Step 8: Generate RTM (Traceability Matrix)

**입력:** SRS skeleton + ERD + API + Screens

**프로세스:**
1. FR → US → FT 계층 구성
2. FT → Screen 매핑
3. FT → API endpoint 매핑
4. API → ERD entity 매핑
5. 매핑 누락 항목 "unmapped" 표시
6. `rtm.md` + `rtm.json` 생성

**출력:** `docs/{app}/02-design/rtm.md` + `rtm.json`

### Step 9: Update Indexes and Links

1. `_index.json` 갱신: 생성된 모든 문서 등록
   - 각 문서 `status: "Draft"` (역공학 결과이므로 검증 필요)
2. `_links.json` 갱신:
   ```json
   {"from": "{app}/erd", "to": "{app}/api", "type": "derives"},
   {"from": "{app}/ia", "to": "{app}/screens", "type": "derives"},
   {"from": "{app}/screens", "to": "{app}/screen-flow", "type": "derives"},
   {"from": "{app}/srs", "to": "{app}/rtm", "type": "traces"},
   {"from": "{app}/api", "to": "{app}/srs", "type": "traces"}
   ```
3. `app.config.json` → `phase: "design"` 으로 갱신
4. 사용자에게 최종 요약 표시

### Step 10: Display Summary

```
## u-reverse Complete

**App:** {app-name}
**Tech Stack:** {framework} + {language} + {orm} + {database}
**Source scanned:** {files-count} files

### Generated Documents
| Document | Path | Items | Status |
|----------|------|-------|--------|
| ERD | docs/{app}/02-design/erd.md | {n} entities | Draft |
| API | docs/{app}/02-design/api.md | {n} endpoints | Draft |
| IA | docs/{app}/01-plan/ia.md | {n} pages | Draft |
| Screens | docs/{app}/02-design/screens.md | {n} screens | Draft |
| Screen Flow | docs/{app}/02-design/screen-flow.md | {n} flows | Draft |
| Design Token | docs/{app}/02-design/design-token.md | {n} tokens | Draft |
| SRS | docs/{app}/01-plan/srs.md | {n} FR, {n} US, {n} FT | Draft |
| RTM | docs/{app}/02-design/rtm.md | {n} mappings | Draft |

### Coverage
- API endpoints → Screen 매핑률: {n}%
- ERD entities → API 매핑률: {n}%
- Screen → API 호출 매핑률: {n}%

### Unmapped Items
- {list of items that couldn't be traced}

### Next Steps
1. `/u-doc {app} srs --edit` — SRS 검토 및 비즈니스 의도 보완
2. `/u-sync {app}` — 문서 간 정합성 검증
3. `/u-check {app}` — 테스트 케이스 생성
```

---

## --only Flag 동작

| Value | Action | Description |
|-------|--------|-------------|
| `--only erd` | ERD만 추출 | DB 스키마 파일 분석 |
| `--only api` | API Contract만 추출 | 라우트/컨트롤러 분석 |
| `--only screens` | IA + Screens 추출 | 페이지 컴포넌트 분석 |
| `--only ia` | IA만 추출 | 라우트 구조만 분석 |
| `--only srs` | SRS skeleton 생성 | ERD + API + Screens 필요 (없으면 먼저 추출) |
| `--only design-token` | Design Token만 추출 | Tailwind/CSS 분석 |

---

## Scan Strategy

### File Discovery

1. `app.config.json` → `path` 기준으로 앱 루트 결정
2. 앱 루트에서 아래 디렉토리를 우선 스캔:
   ```
   src/app/          (Next.js App Router)
   src/pages/        (Pages Router)
   src/components/   (공통 컴포넌트)
   src/lib/          (유틸리티)
   src/hooks/        (커스텀 훅)
   src/stores/       (상태 관리)
   src/styles/       (스타일)
   prisma/           (Prisma 스키마)
   ```
3. `.gitignore` 패턴 준수 → `node_modules/`, `dist/`, `.next/` 등 제외

### Large Codebase 처리

- 파일 수 > 500개: 디렉토리 단위로 청크 분할 분석
- 단일 파일 > 50KB: 섹션 경계에서 분할
- 분석 진행률을 사용자에게 표시:
  ```
  Scanning... [████████░░] 80% (240/300 files)
  ```

---

## Safety Rules

1. **소스 코드 무수정:** 분석 대상 소스 코드는 절대 수정하지 않음 (READ-ONLY)
2. **기존 SSoT 보존:** 이미 존재하는 SSoT 문서가 있으면 덮어쓰기 전 반드시 사용자 확인
3. **역추론 표시 필수:** 모든 역공학 산출물에 `status: "reverse-engineered"` 또는 `status: "Draft"` 부착
4. **source 경로 필수:** 모든 추출 항목에 소스 파일 경로 + 라인 번호 부착
5. **민감 정보 제외:** `.env` 값, 하드코딩된 API 키/시크릿은 추출하지 않음
6. **`.json` 동반 파일 생성 필수:** 모든 `.md` 문서에 companion `.json` 생성
7. **`_index.json`, `_links.json` 갱신 필수**
8. **context window 보호:** 대용량 코드베이스는 반드시 청크 분할 분석
9. **auto mode 가정은 `_assumptions/`에 기록:** 타입 추론, 관계 추론 등 불확실한 분석은 가정으로 기록
10. **`.gitignore` 준수:** 빌드 산출물, 의존성 등 제외 디렉토리는 스캔하지 않음
