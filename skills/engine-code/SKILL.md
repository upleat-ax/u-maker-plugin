---
name: engine-code
description: |
  설계 명세(Screen, API, ERD, DesignToken)로부터 코드를 생성하고,
  코드-명세 동기화 검증 및 기술 스택 규칙을 적용하는 코드 생성 엔진.
version: 2.0.0
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
imports:
  - ${PLUGIN_ROOT}/_refer/tech-stack-rules.md
---

# Engine: Code Generator

> 설계 명세로부터 코드를 생성하고, 명세와 코드의 동기화 상태를 검증한다.

## 역할

- 설계 문서 기반 코드 생성 (FE, BE, DB, Design Token)
- Storybook 스토리 자동 생성
- 코드 ↔ 명세 동기화 검증
- 기술 스택 규칙 적용 (config 기반)
- 생성 코드 품질 기본 검증

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | 설계 문서 (Screen, API, ERD, DesignToken), 기술 스택 config |
| **Output** | 소스 코드 파일, Storybook 스토리, 동기화 검증 리포트 |

## 코드 생성 매핑

| 설계 문서 | 생성 대상 | 출력 경로 |
|----------|----------|----------|
| Screen 명세 | React 컴포넌트 | `src/components/`, `src/pages/` |
| API Contract | Route 핸들러 | `src/app/api/`, `src/routes/` |
| ERD | DB 스키마/마이그레이션 | `prisma/schema.prisma`, `drizzle/` |
| Design Token | CSS 변수/Tailwind 설정 | `src/styles/tokens.css`, `tailwind.config` |

## 실행 절차

### Step 1. 기술 스택 확인

1. `.u-maker/u-maker.config.json`에서 `techStack` 로드
2. `tech-stack-rules.md` 기반 프레임워크/라이브러리 규칙 확인
3. 프로젝트 루트의 `package.json`, `tsconfig.json` 등에서 실제 설정 확인

### Step 2. Screen → FE 컴포넌트

1. Screen 명세에서 구성요소 목록 추출
2. 컴포넌트 계층 구조 설계 (Page → Layout → Feature → UI)
3. 각 컴포넌트 파일 생성:
   - TypeScript interface (Props)
   - 컴포넌트 구현 (JSX/TSX)
   - 스타일 (Tailwind 클래스 또는 CSS Module)
4. FT ID를 주석으로 매핑: `// FT-0010: 로그인 폼`

### Step 3. API Contract → Route 핸들러

1. API 문서에서 엔드포인트 목록 추출
2. 각 엔드포인트에 대해:
   - Request/Response 타입 정의
   - 핸들러 함수 스캐폴딩
   - 입력 유효성 검증 (Zod 등)
   - 에러 응답 처리
3. FR/FT ID 매핑 주석

### Step 4. ERD → DB 스키마

1. ERD에서 엔티티/관계 추출
2. ORM 스키마 생성 (Prisma/Drizzle)
3. 마이그레이션 파일 생성
4. Seed 데이터 스캐폴딩 (선택)

### Step 5. Storybook 스토리 생성

각 생성된 컴포넌트에 대해:
1. `.stories.tsx` 파일 생성
2. Default, Variant, Interactive 스토리 포함
3. Args/Controls 설정

### Step 6. 코드 ↔ 명세 동기화 검증

1. 모든 FT가 코드에 매핑되어 있는지 확인 (주석 기반)
2. Screen의 모든 구성요소가 컴포넌트로 존재하는지 확인
3. API의 모든 엔드포인트가 핸들러로 존재하는지 확인
4. 미매핑 항목 리포트 생성

## 오류 처리

| 상황 | 처리 |
|------|------|
| 설계 문서 미존재 | Design Phase 선행 필요 안내 |
| 기술 스택 미설정 | 기본 스택 (Next.js + Tailwind) 적용 + 경고 |
| 기존 코드 충돌 | diff 출력 + 수동 머지 가이드 |
| 빌드 실패 | 에러 로그 분석 + 수정 제안 |
| 타입 불일치 | 명세와 코드의 타입 차이 리포트 |

## 연동

- **호출원**: `u-skill-dev`, `u-agent-dv-fe`, `u-agent-dv-be`, `u-skill-storybook`
- **호출 대상**: engine-doc (코드 생성 로그 문서화)
- **참조 엔진**: engine-designer (설계 문서), engine-validator (생성 후 검증)
