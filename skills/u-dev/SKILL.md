---
name: u-dev
description: "DEV Phase. 명세 기반 FE + BE + DB 코드 생성. Screen → 컴포넌트, API Contract → Route Handler, ERD → DB Schema를 각각 생성하고 spec-sync 검증을 수행한다."
triggers:
  - "/u-dev"
  - "dev phase"
  - "코드 생성"
  - "개발"
---

# u-dev -- Dev Phase Code Generation

`/u-dev [scope] [--only X] [-i] [--step]` 명령으로 Design 명세를 기반으로 FE + BE + DB 코드를 생성한다.

**Primary Agent:** u-agent-builder (engine-code 사용)

---

## Flags

| Flag | Description |
|------|-------------|
| `--only X` | 지정 영역만 생성 (fe, be, db) |
| `-i` | 분기점에서 사용자 확인 |
| `--step` | 매 단계 결과 표시 후 승인 대기 |

---

## Execution Flow

### Step 0: Verify Design Phase Gate

1. `_index.json` 읽어 Design 문서 상태 확인
2. **필수 조건:**
   - ERD = Final
   - API Contract = Final
   - Screens = Final
   - RTM = Final
3. Gate 미통과 시:
   - 누락/미완 문서 목록 표시
   - "/u-design 또는 /u-gate를 먼저 실행하세요" 안내

### Step 1: Read Tech Stack Configuration

1. `u-maker.config.json` → 프로젝트 전역 설정
2. `app.config.json` → 앱별 techStack:
   ```json
   {
     "techStack": {
       "framework": "Next.js 15 (App Router)",
       "language": "TypeScript",
       "styling": "Tailwind CSS",
       "stateManagement": "zustand",
       "apiClient": "react-query (TanStack Query)",
       "orm": "Prisma | Drizzle",
       "database": "PostgreSQL",
       "testing": "Vitest + Playwright",
       "componentLibrary": "shadcn/ui",
       "runtime": "Bun"
     }
   }
   ```
3. `common/dev/coding-convention.md` → 네이밍 규칙, 구조 규칙
4. 앱별 `dev-override.md` 확인 → 있으면 common과 병합

### Step 2: Generate Frontend (Screen → Components)

**입력:** `screens.json`, `design-token.json`, `common/ux/ui-components.md`

**화면별 코드 생성:**
1. `screens.json` → 화면 목록 + 컴포넌트 구성
2. 화면별 식별:
   - 레이아웃 구조 (grid, flex)
   - 컴포넌트 인벤토리 (buttons, inputs, cards, tables, modals)
   - 데이터 요구사항 (어떤 API 엔드포인트 연결)
   - 인터랙션 패턴 (click, form submit, navigation)
   - 반응형 브레이크포인트
3. Design Token → Tailwind config 매핑
4. UX override 적용

**출력 구조:**
```
{app-root}/src/
  app/
    {screen-route}/
      page.tsx          # Page (Next.js App Router)
      layout.tsx        # Layout (필요 시)
      loading.tsx       # Loading state
  components/
    {screen-name}/
      {Component}.tsx          # 개별 컴포넌트
      {Component}.stories.tsx  # Storybook story
      index.ts                 # Barrel export
  hooks/
    use{Resource}.ts    # API hooks (react-query)
  stores/
    {feature}.store.ts  # Zustand stores
  types/
    {resource}.types.ts # TypeScript types
```

### Step 3: Generate Backend (API Contract → Routes)

**입력:** `api.json`, `erd.json`, `common/architecture/api-common.md`

**엔드포인트별 코드 생성:**
1. `api.json` → 엔드포인트 목록
2. 엔드포인트별:
   - HTTP method + path
   - Request body schema (ERD 기반)
   - Response schema
   - Auth 요구사항
   - Validation 규칙
   - Error codes
3. 공통 미들웨어(auth, file upload) 포함

**출력 구조:**
```
{app-root}/src/
  app/api/
    {resource}/
      route.ts              # Next.js Route Handler
  lib/
    services/
      {resource}.service.ts   # Business logic
    validators/
      {resource}.validator.ts # Zod schema validation
```

### Step 4: Generate Database (ERD → Schema)

**입력:** `erd.json`, `common/architecture/erd-common.md`

**프로세스:**
1. `erd.json` → 엔티티 정의, 컬럼, 관계
2. 공통 테이블(User, Auth, Audit) 포함
3. ORM schema 파일 생성 (Prisma 또는 Drizzle)
4. Migration 파일 생성
5. Seed data 템플릿 생성

**출력 구조:**
```
{app-root}/
  prisma/
    schema.prisma
    migrations/
      {timestamp}_init/migration.sql
  src/lib/db/
    seed.ts
```

### Step 5: Generate Storybook Stories

모든 생성된 컴포넌트에 대해 Storybook story 필수 생성:

| Story Variant | 조건 |
|--------------|------|
| Default | 항상 (일반 데이터) |
| Loading | 비동기 데이터 있으면 |
| Error | 에러 핸들링 있으면 |
| Empty | 컬렉션 표시하면 |
| Interactive | 사용자 인터랙션 있으면 |
| Responsive | 레이아웃 변경 있으면 |

### Step 6: Spec-Sync Validation

코드 생성 후 명세 일치 검증:

| Rule | Check | Severity |
|------|-------|----------|
| Screen coverage | screens.json의 모든 화면에 page 컴포넌트 존재 | Critical |
| API coverage | api.json의 모든 엔드포인트에 route handler 존재 | Critical |
| ERD coverage | erd.json의 모든 엔티티에 schema 정의 존재 | Critical |
| Component coverage | 화면 스펙의 모든 컴포넌트가 파일로 존재 | Major |
| FT traceability | 모든 생성 파일이 FT에 역추적 가능 | Major |
| Design token usage | 하드코딩 색상/간격 없음 | Minor |
| Type safety | API response 타입 = ERD 엔티티 타입 | Major |
| Route matching | FE API 호출 경로 = BE route 경로 정확 일치 | Critical |

**Spec-Sync Report 생성** → `docs/{app}/03-dev/spec-sync-report.md`

### Step 7: Build Verification

1. TypeScript: `tsc --noEmit` → 타입 에러 확인
2. Lint: `eslint .` → 코드 스타일 확인
3. Build: `bun run build` → 프로덕션 빌드 확인
4. Storybook: `storybook build` → 스토리 컴파일 확인

**빌드 실패 시:**
1. 에러 메시지 파싱 → 실패 파일/에러 유형 식별
2. 일반적 이슈 자동 수정 시도 (missing imports, type mismatches)
3. 자동 수정 성공 → 재빌드
4. 자동 수정 실패 → 에러 리포트 + 백로그 등록

### Step 8: Update Documentation

1. `docs/{app}/03-dev/code.md` + `code.json` 생성:
   - 생성된 파일 목록
   - FT → 파일 매핑
   - 빌드 결과
   - spec-sync 결과
2. `_index.json` 갱신
3. `_links.json` 갱신

### Step 9: Tech Debt Auto-Registration

코드 생성 중 발견된 기술 부채:
1. `_backlog/_index.json`에 등록
2. type = "tech-debt"
3. 예: 하드코딩 값, TODO 주석, 미구현 에러 핸들링

---

## --only Flag 동작

| Value | Action | Prerequisite |
|-------|--------|-------------|
| `--only fe` | FE 코드만 생성 | Screens + Design Token Final |
| `--only be` | BE 코드만 생성 | API Contract Final |
| `--only db` | DB schema만 생성 | ERD Final |

---

## Safety Rules

1. Design phase gate 미통과 시 진행 불가
2. 스펙 없이 코드 생성 금지 (모든 파일 → Screen/API/ERD 역추적 필수)
3. secret/credential 하드코딩 금지 → 환경 변수 사용
4. TypeScript strict mode 필수 (`any` 금지, `@ts-ignore` 금지)
5. 앱 소스 디렉토리 외부에 코드 생성 금지
6. Storybook story 필수 생성
7. Design Token 적용 필수 (하드코딩 색상/간격 금지)
8. 빌드 실패 코드는 출하하지 않음
9. `app.config.json` techStack 확인 후 프레임워크/라이브러리 결정
10. auto mode 가정은 `_assumptions/`에 기록
