---
name: u-skill-code-engine
description: "설계 명세(Screen, API, ERD, DesignToken)로부터 코드를 생성하고, Scaffold + Spec-Sync 검증을 수행하는 내부 코드 생성 엔진."
---

# u-skill-code-engine -- Code Generation & Spec-Sync Engine

Screen → FE, API Contract → BE Route Handler, ERD → DB Schema 생성 + Spec-Sync 검증.

**Owner Agent:** u-agent-builder

---

## 1. Operations

### generateFE(screenSpec, techStack)

**입력:** `screens.json`, `design-token.json`, `common/ux/ui-components.md`, `app.config.json` → techStack

**화면별 생성:**
1. Screen 설계 → 레이아웃/컴포넌트/데이터 요구 파악
2. Design Token → Tailwind config 매핑
3. 컴포넌트 분해: Page(`page.tsx`), Layout, 개별 UI 컴포넌트, API Hooks(`use{Resource}.ts`), Stores(`{feature}.store.ts`), Types
4. Storybook story 필수

**출력:** `src/app/{route}/page.tsx`, `src/components/{screen}/`, `src/hooks/`, `src/stores/`, `src/types/`

**FE 코드 규칙:** TypeScript strict(`any`/`@ts-ignore` 금지), Tailwind(하드코딩 금지), Design Token 참조, Props interface, Error Boundary, Loading/Empty/Error 상태 처리

### generateBE(apiContract, techStack)

**입력:** `api.json`, `erd.json`, `common/architecture/api-common.md`, techStack

**엔드포인트별 생성:** Route Handler(`route.ts`), Service Layer, Validator(Zod), Types + 공통 미들웨어(auth, error handling)

**출력:** `src/app/api/{resource}/route.ts`, `src/lib/services/`, `src/lib/validators/`, `src/lib/middleware/`

**BE 코드 규칙:** Zod validation 필수, Error response 표준화, Auth 체크 필수, Secret 하드코딩 금지(환경변수), 트랜잭션 처리

### generateDB(erd, techStack)

**입력:** `erd.json`, `common/architecture/erd-common.md`, techStack.orm/database

**프로세스:** ERD → ORM 스키마(Prisma/Drizzle) + Migration + Seed template + DB client singleton

### scaffold(appConfig)

프로젝트 boilerplate: 프레임워크 구조, 설정 파일(tsconfig/tailwind/eslint), ORM, 테스트(vitest/playwright), Storybook, `.env.example`, `package.json`

### specSync(scope)

생성 코드 ↔ 설계 명세 일치 검증:

| # | Rule | Source → Target | Severity |
|---|------|----------------|----------|
| 1 | Screen → Component | screens → page.tsx | Critical |
| 2 | API → Route Handler | api → route.ts | Critical |
| 3 | ERD → Model | erd → schema | Critical |
| 4 | FT → Implementation | srs → source code | Major |
| 5 | Component → File | screens components → files | Major |
| 6 | Design Token → Usage | token → Tailwind+source | Minor |
| 7 | Type Safety | api response → TS types | Major |
| 8 | Route Matching | FE API call → BE route | Critical |

Report: Rule별 Total/Matched/Missing/Coverage + Missing Items 목록

### applyDesignToken(tokenJson)

Design Token → `tailwind.config.ts` theme.extend + `globals.css` CSS 변수 + Token→Tailwind class 매핑 문서

---

## 2. Storybook Stories

모든 생성 컴포넌트에 필수: Default(항상), Loading(비동기), Error(에러핸들링), Empty(컬렉션), Interactive(인터랙션), Responsive(반응형)

---

## 3. Safety Rules

1. 모든 파일은 Screen/API/ERD 명세에 역추적 가능
2. TypeScript strict, Secret 하드코딩 금지, Zod validation 필수
3. 앱 소스 디렉토리 외부 코드 생성 금지
4. Storybook + Design Token 참조 필수
5. Spec-Sync 검증 후 출하, 빌드 실패 시 자동 수정 → 실패면 백로그 등록
