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

**Primary Agent:** u-agent-planner | **용도:** 이미 개발된 프로젝트에 u-maker 도입 시 코드에서 SSoT 구성

---

## Flags

| Flag | Description |
|------|-------------|
| `--only X` | 지정 문서만 생성 (erd, api, screens, ia, srs, design-token) |
| `-i` | 각 단계 결과 사용자 확인 후 진행 |
| `--step` | 매 단계 결과 표시 후 승인 대기 |
| `--dry-run` | 분석만 수행, 문서 미생성 (리포트만 출력) |

---

## Execution Flow

### Step 0: Verify Prerequisites

1. `.u-maker/` 존재 확인 → 없으면 "/u-init 먼저" 안내
2. `u-maker.config.json` → 앱 목록 조회 → scope 해석 → 소스 코드 경로 결정
3. scope 생략 시: 앱 1개 자동선택 / 2개+ 사용자 질문
4. `app.config.json` → `techStack` 확인 (비어 있으면 Step 1에서 자동 감지)

### Step 1: Detect Tech Stack

소스 코드에서 기술 스택 자동 감지 → `app.config.json`의 `techStack` 반영

**감지 파일:**
- `package.json` → framework, language, styling, stateManagement, apiClient, orm, componentLibrary
- `tsconfig.json` / `jsconfig.json` → language
- `next.config.*` / `nuxt.config.*` → framework
- `tailwind.config.*` → styling
- `prisma/schema.prisma` / `drizzle.config.*` → orm, database
- `docker-compose.yml` → database, infrastructure
- `requirements.txt` / `pyproject.toml` / `go.mod` / `Gemfile` → 각 언어 framework

### Step 2: Extract ERD (Database Schema)

**스캔:** Prisma, Drizzle, TypeORM/MikroORM entities, SQL migrations, Django/Rails models

**프로세스:** ORM 스키마 파싱 → 엔티티/컬럼/타입/관계 추출 → Mermaid ER 생성 → source 경로 부착

**출력:** `docs/{app}/02-design/erd.md` + `erd.json`

**엔티티 구조:** `{ name, description, source, columns: [{ name, type, pk, nullable }], relations: [{ target, type, foreignKey }] }`

### Step 3: Extract API Contract

**스캔:** Next.js App/Pages Router routes, Express/Fastify/NestJS controllers, Django/Rails routes, OpenAPI spec

**프로세스:** 라우트 스캔 → HTTP method+path 추출 → Request/Response 타입 추출 → 인증 방식 식별 → source 경로 부착

**출력:** `docs/{app}/02-design/api.md` + `api.json`

**엔드포인트 구조:** `{ method, path, source, auth, requestBody, responses, relatedEntity }`

### Step 4: Extract Screen Structure (IA + Screens)

**스캔:** Next.js pages, Vue views, SvelteKit routes, React Native screens

#### 4-1. IA 추출
라우트 파일 시스템 → URL 계층 도출 → Layout 그룹 식별 → Navigation 메뉴 구조 → 접근 제어 구분 (public/auth-required/admin)

**출력:** `docs/{app}/01-plan/ia.md` + `ia.json` -- `{ pages: [{ id, name, path, source, layout, access, children }] }`

#### 4-2. Screen 상세 추출
각 페이지 컴포넌트 분석: Import 컴포넌트 → State/Hook → API 호출 → Form 구조 → 조건부 렌더링(화면 상태)

**출력:** `docs/{app}/02-design/screens.md` + `screens.json` -- `{ screens: [{ id, name, path, source, components, apiCalls, stateManagement, forms, states }] }`

### Step 5: Extract Screen Flow

IA + Screens 기반으로 페이지 간 이동 추출: `<Link>`, `router.push`, `redirect`, Form submit 후 이동, 조건부 리다이렉트 → Mermaid flowchart 생성

**출력:** `docs/{app}/02-design/screen-flow.md` + `screen-flow.json`

### Step 6: Extract Design Token

**스캔:** `tailwind.config.ts`, `globals.css` CSS variables, theme objects, 공통 스타일

**프로세스:** color palette, spacing, typography, breakpoints 추출 → 토큰 매핑

**출력:** `docs/{app}/02-design/design-token.md` + `design-token.json`

### Step 7: Generate SRS Skeleton

코드에서 역추론한 기능 요구사항 뼈대 생성:
- API endpoint → Feature(FT) 도출
- Screen+API 매핑 → User Story(US) 추론
- 관련 US 그루핑 → FR 도출
- 모든 항목에 `status: "reverse-engineered"` 표시

**출력:** `docs/{app}/01-plan/srs.md` + `srs.json`

> 역추론된 SRS는 코드 동작 기반이므로 원래 비즈니스 의도와 다를 수 있다. `/u-ingest --review`로 검증 권장.

### Step 8: Generate RTM

FR → US → FT 계층 + FT → Screen + FT → API + API → ERD 매핑. 누락 항목 "unmapped" 표시.

**출력:** `docs/{app}/02-design/rtm.md` + `rtm.json`

### Step 9: Update Indexes and Links

1. `_index.json` 갱신 (모든 문서 `status: "Draft"`)
2. `data/links.json` 갱신 (erd→api, ia→screens, screens→screen-flow, srs→rtm, api→srs)
3. `app.config.json` → `phase: "design"`

### Step 10: Display Summary

생성 문서 목록, 항목 수, Coverage(API→Screen, ERD→API, Screen→API 매핑률), Unmapped 항목, Next Steps 표시.

---

## --only Flag

| Value | Description |
|-------|-------------|
| `erd` | DB 스키마 파일만 분석 |
| `api` | 라우트/컨트롤러만 분석 |
| `screens` | IA + Screens 추출 |
| `ia` | 라우트 구조만 분석 |
| `srs` | SRS skeleton 생성 (ERD+API+Screens 필요, 없으면 먼저 추출) |
| `design-token` | Tailwind/CSS만 분석 |

---

## Scan Strategy

- `app.config.json` → `path` 기준 앱 루트 결정
- 우선 스캔: `src/app/`, `src/pages/`, `src/components/`, `src/lib/`, `src/hooks/`, `src/stores/`, `src/styles/`, `prisma/`
- `.gitignore` 준수 (`node_modules/`, `dist/`, `.next/` 등 제외)
- 파일 500개+: 디렉토리 단위 청크 분할 / 단일 파일 50KB+: 섹션 분할

---

## Safety Rules

1. 소스 코드 무수정 (READ-ONLY), `.u-maker/` 대상 디렉토리만 쓰기
2. 기존 SSoT 존재 시 덮어쓰기 전 반드시 사용자 확인
3. 모든 산출물에 `status: "reverse-engineered"/"Draft"` + source 경로(파일+라인) 필수 부착
4. `.env` 값, 하드코딩 API 키/시크릿 추출 금지
5. `.json` 동반 파일 + `_index.json`/`data/links.json` 갱신 필수
6. 대용량은 청크 분할, 불확실한 분석은 `data/assumptions/`에 기록
