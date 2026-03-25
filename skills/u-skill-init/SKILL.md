---
name: u-skill-init
description: |
  기존 프로젝트를 분석하여 SSoT 문서를 자동 생성한다.
  프로젝트 폴더 내 리소스(package.json, 소스코드, DB 스키마, README 등)를 읽고
  분석하여 가능한 모든 SSoT 문서를 사전 작성(pre-fill)한다.
  Args: `[project-path]` — 분석할 프로젝트 경로 (생략 시 현재 디렉토리)
  Triggers: /u-skill-init, 프로젝트 초기화, 기존 프로젝트 분석, init project, reverse engineer, 리버스 엔지니어링, 문서 자동 생성, auto generate docs, 코드 분석, analyze codebase, SSoT 초기화, onboarding, 기존 코드 문서화
user-invocable: true
argument-hint: "[project-path] [--lang ko|en|ja|zh]"
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
agents:
  u-agent-pm: u-maker:u-agent-pm
  u-agent-ra: u-maker:u-agent-ra
  u-agent-sa: u-maker:u-agent-sa
  u-agent-ux: u-maker:u-agent-ux
---

# Project Init from Existing Codebase

> 기존 프로젝트의 리소스를 스캔하여 SSoT 문서를 역공학(reverse-engineer)으로 자동 생성한다.

## Syntax

/u-skill-init [project-path] [--lang ko|en|ja|zh]

- `[project-path]`: 분석할 프로젝트 경로 (기본값: 현재 작업 디렉토리)
- `--lang`: 문서 작성 언어 (기본값: `ko`)
  - 설정값은 `.u-maker/u-maker.config.json`의 `documentLanguage`에 저장

## Init Flow

0. 문서 언어 설정 (--lang 옵션 또는 AskUserQuestion)
1. 프로젝트 루트 탐색 및 기본 정보 수집 (package.json, README.md, tsconfig.json 등)
2. 소스코드 구조 분석 (페이지/라우트, 컴포넌트, API 라우트, 미들웨어)
3. 데이터베이스 스키마 분석 (Prisma, Drizzle, SQL 마이그레이션)
4. .u-maker/docs/ 디렉토리 구조 생성
5. SSoT 문서 생성 (분석 결과 기반)
   - Phase 1 PLAN: Roadmap, Index, SRS, IA
   - Phase 2 DESIGN: ERD, UXGuide, API, Screen (해당 리소스 존재 시)
   - Phase 3 DEV: UIComponents, DesignToken, Code, Screen (코드 존재 시)
6. Phase 상태 결정 (PLAN/DESIGN/DO)
7. .u-maker/u-maker.config.json 업데이트
8. 결과 리포트 출력

## Scan Targets

| Scan Target | File Patterns | Output Document |
|-------------|---------------|-----------------|
| 프로젝트 메타 | package.json, README.md | 1_Roadmap_PM |
| 소스코드 기능 | src/**/*.{ts,tsx}, app/** | 1_SRS_RA |
| 페이지/라우트 | app/**/page.tsx, pages/** | 1_IA_RA |
| DB 스키마 | prisma/schema.prisma, drizzle/** | 2_ERD_SA |
| API 라우트 | app/api/**/route.ts, pages/api/** | 2_API_SA |
| UI 컴포넌트 | components/**, app/**/page.tsx | 2_Screen_UX |

## Agent Sequence

u-agent-ra → u-agent-sa → u-agent-ux → u-agent-pm (로드맵/인덱스 + 결과 리포트)

## Rules

- 모든 생성 문서의 Status는 Draft로 설정
- 분석 불가능한 항목은 {{TODO: 수동 입력 필요}} 플레이스홀더
- 기존 .u-maker/docs/ 문서가 있으면 덮어쓰지 않음 (사용자 확인 후 진행)
- 문서는 .u-maker/u-maker.config.json의 documentLanguage 설정 언어로 작성
- 문서 헤더는 영문 유지, 본문만 해당 언어로 작성
