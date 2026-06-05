---
name: u-createproject
description: "This skill should be used when the user asks to '/u-createproject', 'u-createproject', 'createproject', 'u-maker 프로젝트 생성', 'u-maker 새 프로젝트', 'Turborepo 모노레포 스캐폴드', 'u-maker monorepo scaffold', or 'u-maker scaffold project'. Generates a new Turborepo + Bun monorepo project with the standard Clean Architecture layer structure, including project-specific CLAUDE.md and DESIGN.md agent guides."
version: 1.2.0
---

# u-createproject — Turborepo + Bun Monorepo Project Scaffolding

`/u-createproject <project-name> [directory]`

Turborepo + Bun 기반 모노레포 프로젝트를 처음부터 스캐폴딩한다. 생성 완료 후 `/u-init`을 자동 실행하고, dropzone 사용법을 안내한다.

**Primary Agent:** u-agent-pm
**Engine Dependencies:** (none — bootstrap command)

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `project-name` | Yes | 영문 프로젝트명 (kebab-case). @namespace로 사용. |
| `directory` | No | 프로젝트를 생성할 디렉토리 경로. 미지정 시 사용자에게 질문. |

## Validation Rules

- `project-name`은 kebab-case (소문자, 하이픈만 허용)
- 생성 대상 디렉토리가 이미 존재하고 비어있지 않으면 에러
- 디렉토리명은 사용자 지정 (기본 제안: `{project-name}`)

## Execution Flow

### Step 0: Collect Project Info

1. `project-name` 미제공 시 AskUserQuestion으로 질문:
   > "프로젝트 영문명을 입력해 주세요 (kebab-case, 예: my-app):"
2. kebab-case 형식 검증 (정규식: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`)
3. `directory` 미제공 시 AskUserQuestion으로 질문:
   > "프로젝트를 생성할 디렉토리 경로를 입력해 주세요 (기본: ./{project-name}):"
   - 사용자가 빈 값 또는 엔터만 입력 시 기본값 `{cwd}/{project-name}` 사용
   - 상대 경로 입력 시 현재 작업 디렉토리 기준으로 resolve
   - 절대 경로 입력 시 그대로 사용
4. 대상 디렉토리가 이미 존재하고 비어있지 않으면 에러:
   > "디렉토리 `{directory}`가 이미 존재하고 비어있지 않습니다. 다른 경로를 지정해 주세요."
5. 변수 설정:
   - `PROJECT_DIR` = 사용자가 지정한 디렉토리 (resolved absolute path)
   - `NS` = `@{project-name}`
   - 이후 모든 `{{PROJECT_NAME}}`을 `project-name`으로 치환

### Step 1: Create Directory Structure

`references/scaffolding-spec.md` §2의 폴더 구조를 전부 생성한다.

```
{PROJECT_DIR}/
├── apps/
│   ├── web/src/app/
│   ├── web/src/features/
│   ├── web/src/lib/
│   ├── admin/src/app/
│   ├── admin/src/features/
│   ├── admin/src/lib/
│   └── backend/src/users/
├── packages/
│   ├── config/eslint/
│   ├── config/tsconfig/
│   ├── tokens/src/
│   ├── domain/src/{models,repositories,services,constants,validators}/
│   ├── data/src/{repositories,mappers,query-keys,routes,utils}/
│   ├── infrastructure/src/{api,auth,storage}/
│   ├── hooks/src/{queries,mutations}/
│   ├── ui-common/src/components/Button/
│   ├── ui-common/.storybook/
│   ├── ui-backoffice/src/components/Button/
│   ├── ui-backoffice/.storybook/
│   ├── ui-app/src/components/Button/
│   └── ui-app/.storybook/
├── .u-maker/docs/
├── CLAUDE.md
├── DESIGN.md
└── AGENTS.md → CLAUDE.md   (symlink, Codex 등 AGENTS.md 기반 에이전트 호환)
```

### Step 2: Generate Root Configuration Files

`references/scaffolding-spec.md` §7 참조. 순서:

1. `package.json` — workspaces: `["apps/*", "packages/*"]`
2. `turbo.json` — task pipeline (build, dev, lint, storybook, test)
3. `tsconfig.json` — root references
4. `.gitignore` — node_modules, .next, dist, .turbo, bun.lockb, .env*.local, .u-maker/.state/, .u-maker/output/, .u-maker/reports/
5. `CLAUDE.md` — 프로젝트 AI 에이전트 가이드(정본) (개요·디자인시스템·명령어·앱·아키텍처·SSoT·코딩 컨벤션·금지사항·Git). `references/scaffolding-spec.md` §7 의 CLAUDE.md 템플릿을 `{{PROJECT_NAME}}` 치환하여 생성한다. **실제 스캐폴드된 구조만** 기술하고(스캐폴드에 없는 컴포넌트를 강제하지 않음), 디자인시스템 섹션은 `DESIGN.md` 를 단일 출처로 가리키며 끝에 `@DESIGN.md` import 한 줄을 둬 Claude Code 가 DESIGN.md 전체를 컨텍스트로 로드하게 한다. Step 6 git commit 에 포함된다.
6. `DESIGN.md` — 디자인/UI 공통 룰 (디자인시스템 우선·layout·design token·시각효과·props 변형·폼 정렬·상태 표현·접근성·SSoT + 자가 점검 체크리스트). `references/scaffolding-spec.md` §7 의 DESIGN.md 템플릿을 `{{PROJECT_NAME}}` 치환하여 생성한다. 실제 스캐폴드된 UI 패키지(`ui-common`/`ui-backoffice`/`ui-app`)와 token 구조에 맞춰 기술하며, Step 6 git commit 에 포함된다.
7. `AGENTS.md` — `CLAUDE.md` 로의 심볼릭 링크. CLAUDE.md · DESIGN.md 생성 후 PROJECT_DIR 에서 `ln -s CLAUDE.md AGENTS.md` 실행. Codex CLI 등 AGENTS.md 기반 에이전트가 동일 가이드를 자동 로드하도록 한다 (Codex 는 CLAUDE.md 를 읽지 않고 AGENTS.md 만 읽으며, import 문법이 없어 DESIGN.md 는 가이드 지시에 따라 on-demand 로 읽는다). `references/scaffolding-spec.md` §7 AGENTS.md 참조. Step 6 git commit 에 포함된다.

### Step 3: Generate packages/* (의존 순서 준수)

반드시 아래 순서로 생성 (의존 방향 상→하):

1. **packages/config** — tsconfig/base.json, tsconfig/nextjs.json, tsconfig/library.json, eslint 설정
2. **packages/tokens** — CSS Custom Properties (colors, typography, spacing, shadows)
3. **packages/domain** — 타입, 인터페이스, Zod 스키마 (외부 의존 없음)
4. **packages/infrastructure** — apiClient, storage (→ domain)
5. **packages/data** — Repository 구현, Mapper, queryKeys, routes (→ domain)
6. **packages/hooks** — TanStack Query 훅 (→ data, domain)
7. **packages/ui-common** — Button 컴포넌트 + Storybook (→ tokens)
8. **packages/ui-backoffice** — Button 컴포넌트 + Storybook (→ tokens)
9. **packages/ui-app** — Button 컴포넌트 + Storybook (→ tokens)

각 패키지 상세: `references/scaffolding-spec.md` §6 참조.

### Step 4: Generate apps/*

1. **apps/web** — Next.js 15 App Router (port 3000)
2. **apps/admin** — Next.js 15 App Router (port 3001, 관리자 대시보드)
3. **apps/backend** — Nest.js API (port 2920, prefix /v1, Swagger)

각 앱 상세: `references/scaffolding-spec.md` §6.8, §6.9 참조.

### Step 5: Generate SSoT Document Templates

`.u-maker/docs/`에 빈 템플릿 생성:
- `SRS.md` — Software Requirements Specification 골격
- `ERD.md` — Entity-Relationship Diagram + mermaid 블록
- `API-Contract.md` — API Contract + 엔드포인트 테이블
- `Screen.md` — Screen Specification + 화면 목록 테이블

### Step 6: Initialize Git Repository

```bash
cd {PROJECT_DIR}
git init
git add -A
git commit -m "chore: scaffold {project-name}-monorepo

Turborepo + Bun monorepo with Clean Architecture layers.
Apps: web, admin, backend
Packages: domain, data, hooks, infrastructure, ui-common, ui-backoffice, ui-app, tokens, config"
```

### Step 7: Install Dependencies

```bash
cd {PROJECT_DIR}
bun install
```

설치 실패 시 에러 원인 분석 후 package.json 수정 → 재시도.

### Step 8: Run u-init

프로젝트 디렉토리에서 `/u-init {project-name}` 실행하여 `.u-maker/` 구조 초기화.
(Step 5에서 이미 `.u-maker/docs/`는 생성했으므로, u-init이 나머지 구조를 보강)

### Step 9: Build & Lint Verification

```bash
cd {PROJECT_DIR}
bun run build
bun run lint
```

실패 시 에러 수정 후 재시도. 빌드·린트 모두 통과할 때까지 반복.

### Step 10: Print Completion Summary & Dropzone Guide

```
✅ Project "{project-name}" created at {PROJECT_DIR}

📁 Structure:
  apps/     — web, admin, backend
  packages/ — domain, data, hooks, infrastructure, ui-common, ui-backoffice, ui-app, tokens, config
  CLAUDE.md — AI 에이전트 가이드 정본 (프로젝트 규칙·아키텍처·금지사항, @DESIGN.md import)
  DESIGN.md — 디자인/UI 공통 룰 (디자인시스템·token·layout·접근성·체크리스트)
  AGENTS.md — CLAUDE.md 심볼릭 링크 (Codex 등 AGENTS.md 기반 에이전트 호환)

🚀 Next Steps:
  1. cd {PROJECT_DIR}
  2. 아래 자료를 .u-maker/data/dropzone/ 에 복사하세요:
     ─ 기획서, 요구사항 정의서, 화면 설계서
     ─ 기존 API 문서, ERD 자료
     ─ 회의록, 인터뷰 메모, 비즈니스 규칙 문서
     ─ 참고 디자인 (Figma URL을 .md 파일로 기록)
     ─ 기존 코드/DB 스키마 (역공학 시)
  3. /u-plan --app {project-name} 실행하여 SRS/IA 자동 생성

💡 dropzone 지원 형식:
  텍스트: .md, .txt, .docx, .pdf
  스프레드시트: .xlsx, .csv
  이미지: .png, .jpg (화면 캡처, 와이어프레임)
  Figma: URL을 .md 파일에 기록하여 드롭
```

## Dependency Flow (반드시 준수)

```
apps/* → hooks → data → domain ← infrastructure
apps/* → ui-*  → tokens
```

- `domain`: 의존 없음 (순수 타입/상수)
- `tokens`: 의존 없음 (순수 CSS)
- `config`: 의존 없음 (설정 프리셋)
- `data`: → domain
- `infrastructure`: → domain
- `hooks`: → data, domain
- `ui-*`: → tokens
- `apps/*`: → hooks, ui-*, infrastructure, domain

**역방향 의존 절대 금지.**

## Constraints (코드 생성 시 필수 적용)

| 규칙 | 설명 |
|------|------|
| 함수형 Only | class 사용 금지 (Nest.js 제외) |
| 순수 CSS | CSS-in-JS, Sass, SCSS, inline style 금지 |
| Design Tokens | `var(--*)` 참조만 허용 |
| Named export | default export 금지 (Next.js page/layout 제외) |
| TypeScript strict | 모든 패키지 strict 모드 |
| ESLint 9 Flat Config | eslint-plugin-header 사용 금지 |
| Bun Only | npm/yarn/pnpm 관련 설정 금지 |
| Import alias | `@/` → `src/` (앱 내부), `@{NS}/` → packages/* |
| Server Component 기본 | `'use client'`는 필요 시에만 |
| No API Route in apps | apps에서 API 직접 호출 금지 (domain → data → hooks 경유) |

## Naming Convention

| 대상 | 규칙 | 예시 |
|------|------|------|
| 변수/함수 | camelCase | `fetchUser`, `userName` |
| 타입/인터페이스 | PascalCase | `UserRepository` |
| 상수 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 파일 (일반) | kebab-case.ts | `user-repository.ts` |
| 파일 (컴포넌트) | PascalCase.tsx | `UserCard.tsx` |

## Git Convention

커밋 포맷: `type(scope): message`
- type: feat, fix, refactor, chore, docs, style, test
- scope: 패키지명 (web, admin, domain, data, hooks, ui-common, infra 등)

## Error Handling

| Condition | Action |
|-----------|--------|
| 디렉토리가 비어있지 않음 | Error: "디렉토리 `{directory}`가 이미 존재하고 비어있지 않습니다. 다른 경로를 지정해 주세요." → 재질문 |
| bun 미설치 | Error: "Bun is not installed. Install from https://bun.sh" |
| bun install 실패 | 에러 분석 → package.json 수정 → 재시도 |
| build 실패 | 에러 분석 → 소스 수정 → 재시도 (최대 3회) |
| lint 실패 | 에러 분석 → 소스/설정 수정 → 재시도 (최대 3회) |

## Reference Files

- **`references/scaffolding-spec.md`** — 패키지별 파일 내용, 의존성, 기술 스택 상세 명세
