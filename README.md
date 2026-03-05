# u-maker v2.0.0

> PDCA 사이클 기반의 SSoT(Single Source of Truth) 소프트웨어 개발 협업 자동화 AI 에이전트 생태계
> (Claude Code / Gemini CLI 전용 플러그인)

**문서가 프로세스를 강제하고, 에이전트가 이를 실행한다.**

---

## Overview

u-maker는 7개 전문 에이전트가 PDCA(Plan-Design-Do-Check-Act) 사이클을 따라 소프트웨어 개발 전 과정을 자동화하는 시스템입니다. 모든 결정과 산출물은 `u-docs/` SSoT 문서 체계에 기록되며, 종료 조건(Exit Criteria)을 충족할 때까지 이터레이션을 반복합니다.

### 핵심 원칙

- **문서 중심 (SSoT)**: 모든 결정과 산출물은 `u-docs/` 내 지정된 SSoT 문서에만 기록
- **Phase Gate**: 각 단계 전환 시 Gate 조건(Final 상태, 모순 검수 등) 충족 필수
- **추적성 (Traceability)**: 요구사항(US/FR)부터 설계(API/ERD/Screen/ScreenFlow), 코드, 테스트까지 연쇄 추적
- **유저 스토리 기반 (User Story)**: 추상적 요구사항을 유저 스토리로 구체화하여 기능 요구사항(FR)으로 도출
- **자동 반복 (PDCA Loop)**: CHECK 단계 실패 시 ACT를 거쳐 다음 Iteration으로 자동 전환
- **기술 스택 강제**: 10가지 핵심 기술 스택 규칙 위반 시 도구 실행 차단
- **다이어그램 필수**: 모든 SSoT 문서에 최소 1개 이상의 Mermaid 다이어그램 포함
- **JSON 내보내기**: 마크다운 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성

---

## Quick Start

```bash
# 1. 새 프로젝트 초기화 (Turborepo + u-docs 구조)
/uc-create-project my-app

# 2. PLAN Phase (로드맵 → SRS(US+FR) → IA → 인덱스)
/uc-plan

# 3. DESIGN Phase (UXGuide → Screen → ScreenFlow → Wireframe → Design → ERD + API → 모순검수)
/uc-design

# 4. DO Phase (Frontend + Backend 병렬 구현)
/uc-dev

# 5. CHECK Phase (테스트 케이스 설계 → 실행 → 결함 분석)
/uc-check

# 6. 종료 조건 충족까지 PDCA 자동 반복
/uc-loop
```

---

## 산출문서 파이프라인

문서는 아래 순서로 생산됩니다. 테이블에 작성되는 목록 데이터는 동명의 `.json` 파일로 별도 생성합니다.

```mermaid
flowchart LR
    SRS[SRS\n요구사항명세서] --> IA[IA\n정보구조도]
    IA --> UXG[UXGuide\nUX표준가이드\n+디자인시스템]
    UXG --> SCR[Screen\n화면설계서]
    SCR --> SF[ScreenFlow\n화면흐름도]
    SF --> WF[Wireframe\n와이어프레임]
    WF --> VD[Design\n화면디자인\n.pen]
    VD --> ERD[ERD]
    ERD --> API[API Contract]
    API --> DEV[Dev\n개발]
    DEV --> TEST[Test\n테스트케이스]
```

| # | 산출문서 | 파일명 | 담당 에이전트 |
|---|---------|--------|-------------|
| 1 | 요구사항명세서 | `1_SRS_RA.md` | ua-sa |
| 2 | 정보구조도 (IA) | `1_IA_RA.md` | ua-ux |
| 3 | UX표준가이드 (디자인시스템 포함) | `2_UXGuide_UX.md` | ua-ux |
| 4 | 화면설계서 | `2_Screen_UX.md` | ua-ux |
| 5 | 화면간의 흐름도 | `2_ScreenFlow_UX.md` | ua-ux |
| 6 | 와이어프레임 | `2_Screen_Wireframes/*.html` | ua-ux |
| 7 | 화면디자인 | `.pen` 파일 (pencil.dev) | ua-ux-ds |
| 8 | ERD | `2_ERD_SA.md` | ua-sa |
| 9 | API Contract | `2_API_SA.md` | ua-sa |
| 10 | 개발 | `3_Code_DV.md` + 코드 | ua-dv-fe, ua-dv-be |
| 11 | 테스트케이스 | `4_Case_QA.md` | ua-qa |

---

## Command Workflows by Scenario

사용자 시나리오별 권장 명령어 흐름입니다.

### 시나리오 1: 신규 프로젝트 시작 (Zero to One)
1. `/uc-create-project <name>` : 프로젝트 구조 생성
2. `/uc-us-add "핵심 아이디어"` : 유저 스토리 등록
3. `/uc-loop` : 요구사항 상세화(PLAN)부터 코드 구현, 테스트까지 자동 실행

### 시나리오 2: 기존 프로젝트 분석 및 SSoT 도입
1. `/uc-init` : 기존 코드를 분석하여 설계 문서(SSoT) 역공학 생성
2. `/uc-status` : 생성된 문서 상태 확인 및 미비점 파악
3. `/uc-loop` : 부족한 설계를 보완하고 다음 개발 사이클 진행

### 시나리오 3: 새로운 기능 추가 (Feature Addition)
1. `/uc-us-add` : 유저 스토리(사용자 요구사항) 추가
2. `/uc-fr-add` : 기능 요구사항(시스템 상세 명세) 추가
3. `/uc-loop` : 추가된 요구사항에 맞춰 설계 변경 및 코드 구현 자동화

### 시나리오 4: 유지보수 및 버그 수정 (Maintenance)
1. `/uc-backlog-add` : 개선 항목이나 발견된 이슈 등록
2. `/uc-loop-from design` : 설계 변경이 필요한 경우 DESIGN 단계부터 루프 실행
3. `/uc-bug-report` : 테스트 중 발견된 결함에 대한 상세 분석 및 수정 가이드 생성

### 시나리오 5: 품질 검증 및 협업 (Quality & Collaboration)
1. `/uc-validate` : 모든 SSoT 문서의 무결성과 추적성 검증
2. `/uc-gap-detector` : 설계(SSoT)와 실제 구현 코드 간의 불일치 분석
3. `/uc-build` : 최종 빌드 성공 여부 확인
4. `/uc-git-pr` : 변경 사항을 그룹핑하여 커밋하고 GitHub PR 생성

---

## 7 Specialized Agents

| Agent | Role | Phase | 주요 담당 범위 |
|-------|------|-------|--------------|
| `ua-ra` | Requirements Analyst | ALL | 로드맵, 인덱스, 이터레이션 로그(백로그 포함), 회고, SSoT 검증 |
| `ua-sa` | Solution Architect | PLAN, DESIGN | SRS(요구사항 명세), ERD(데이터 모델), API Contract(OpenAPI) |
| `ua-ux` | UX Designer | PLAN, DESIGN, DO | IA(메뉴구조), UXGuide(UX표준가이드+디자인시스템), 화면 설계, 화면 흐름도, HTML 와이어프레임, UI 컴포넌트, 디자인 토큰 |
| `ua-ux-ds` | Pencil Designer | DESIGN, DO | pencil.dev MCP 기반 시각적 디자인 (.pen 파일) 생성 및 업데이트 |
| `ua-dv-fe` | Frontend Developer | DO | Next.js App Router + react-query 기반 프론트엔드 코드 구현 |
| `ua-dv-be` | Backend Developer | DO | API Routes + Prisma/Drizzle ORM 기반 백엔드 로직 구현 |
| `ua-qa` | QA Engineer | CHECK | 테스트 케이스 설계 및 실행, 결함 분석 리포트, 설계-구현 Gap 분석 |

---

## PDCA Workflow & Gates

### Workflow
```mermaid
stateDiagram-v2
    [*] --> PLAN
    PLAN --> DESIGN : Gate 1 (Final Docs)
    DESIGN --> DO : Gate 2 (Consistency Check)
    DO --> CHECK : Gate 3 (Build Success)
    CHECK --> COMPLETE : Exit Criteria Met
    CHECK --> ACT : Exit Criteria Failed
    ACT --> PLAN : Next Iteration
    COMPLETE --> [*]
```

### Phase Gates (전환 조건)

| Transition | 조건 (Gate Criteria) | 검수자 |
|------------|---------------------|-------|
| PLAN → DESIGN | Roadmap + SRS + IA 상태가 'Final'이며 모든 US→FR 매핑 완료 | `ua-ra` |
| DESIGN → DO | ERD + UXGuide + API + Screen + ScreenFlow 상태가 'Final'이며 모순 검수 통과 | `ua-ra` |
| DO → CHECK | 모든 코드 구현 완료 및 `bun run build` 성공 | 시스템 |
| CHECK → COMPLETE | Critical/Major 결함 0건 + 모든 FR 구현 완료 + 백로그 0건 | `ua-qa` |
| CHECK → ACT | 위 조건 미충족 시 자동으로 ACT 단계로 진입 | 시스템 |

---

## SSoT Document Structure

`u-docs/` 폴더 내의 문서는 **Shared(공유)**와 **App-Specific(앱 전용)**으로 구분됩니다.

### Shared Documents (공유 영역)
- `u-docs/shared/01-plan/`: 1_Roadmap_PM, 1_Index_PM
- `u-docs/shared/02-design/`: 2_ERD_SA, 2_UXGuide_UX
- `u-docs/shared/03-dev/`: 3_UIComponents_UX, 3_DesignToken_UX
- `u-docs/shared/05-act/`: 5_IterationLog_RA, 5_Retrospective_PM

### App-Specific Documents (앱 개별 영역)
- `u-docs/{app}/01-plan/`: 1_SRS_RA, 1_IA_RA
- `u-docs/{app}/02-design/`: 2_API_SA, 2_Screen_UX, 2_ScreenFlow_UX, 2_Screen_Wireframes/
- `u-docs/{app}/03-dev/`: 3_Code_DV, 3_Screen_UX (Dev ver.)
- `u-docs/{app}/04-check/`: 4_Case_QA, 4_Report_QA

### Plugin Reference Documents (플러그인 표준 문서)
- `u-docs/db/`: ssot-standard, json-export, pdca-workflow, tech-stack-rules, traceability-matrix, mermaid-guide 등

---

## Tech Stack Rules (TS-01 ~ TS-10)

코드 생성 시 아래 10가지 규칙이 엄격히 강제됩니다. 위반 시 실행이 차단될 수 있습니다.

1. **Clean Architecture**: 명확한 관심사 분리(Domain, Infrastructure, Data 등) 폴더 구조
2. **React Query**: 데이터 페칭은 반드시 `react-query` 사용 (Usecase 패턴 금지)
3. **Plain CSS**: CSS-in-JS(Styled-components 등) 대신 `.css` 파일 직접 사용
4. **Next.js App Router**: Pages Router 사용 금지
5. **No Header Plugin**: `eslint-plugin-header` 등 자동 헤더 삽입 플러그인 금지
6. **Turborepo**: 반드시 Monorepo 구조로 프로젝트 관리
7. **Functional Components**: Class 컴포넌트 사용 금지
8. **Storybook**: 모든 UI 컴포넌트는 Storybook 문서화 필수
9. **Design Tokens**: 색상, 폰트 등은 하드코딩 대신 디자인 토큰 기반 스타일링
10. **Bun PM**: 패키지 매니저는 반드시 `bun` 사용 (`npm`/`yarn`/`pnpm` 금지)

---

## Slash Commands (상세 가이드)

모든 커맨드는 슬래시(`/`)로 시작하며, 각 단계별 자동화 및 문서 관리를 담당합니다.

### 1. Lifecycle & Auto-Loop (라이프사이클 및 자동화)

| Command | Syntax | Description | Prerequisites |
|---------|--------|-------------|---------------|
| `/uc-create-project` | `/uc-create-project <name>` | 새 프로젝트 생성 및 u-docs 구조 초기화 | 없음 |
| `/uc-init` | `/uc-init [path]` | 기존 프로젝트 분석 및 SSoT 역공학 생성 | 프로젝트 파일 존재 |
| `/uc-plan` | `/uc-plan [app]` | PLAN 단계 실행 (Roadmap, SRS, IA 생성) | u-docs 존재 |
| `/uc-design` | `/uc-design [app]` | DESIGN 단계 실행 (UXGuide, Screen, ScreenFlow, Wireframe, Design, ERD, API) | PLAN Gate 통과 |
| `/uc-dev` | `/uc-dev [app]` | DO 단계 실행 (FE/BE 병렬 구현) | DESIGN Gate 통과 |
| `/uc-check` | `/uc-check [app]` | CHECK 단계 실행 (테스트 및 결함 분석) | DO Gate 통과 |
| `/uc-act` | `/uc-act` | ACT 단계 실행 (백로그 정리, 회고) | CHECK 완료 |
| `/uc-loop` | `/uc-loop` | 종료 조건 충족까지 PDCA 전체 자동 반복 | 프로젝트 초기화 완료 |
| `/uc-loop-from` | `/uc-loop-from <phase>` | 특정 단계(plan/design 등)부터 루프 시작 | 선행 문서 Final 상태 |
| `/uc-stop` / `/uc-resume` | - | 실행 중인 루프 중단 또는 재개 | 루프 실행/중단 중 |

### 2. Document & Requirements Management (문서 및 요구사항 관리)

| Command | Syntax | Description | Output |
|---------|--------|-------------|--------|
| `/uc-status` | `/uc-status` | 현재 Iteration/Phase 진행률 및 상태 보고 | 상태 요약 배너 |
| `/uc-docs` | `/uc-docs` | 전체 SSoT 문서 목록 및 상태 조회 | 문서 현황 테이블 |
| `/uc-validate` | `/uc-validate` | SSoT 문서 무결성 및 추적성 검증 | 검증 결과 보고서 |
| `/uc-us-add` | `/uc-us-add [desc]` | 새로운 유저 스토리 추가 | `1_SRS_RA.md` |
| `/uc-fr-add` | `/uc-fr-add [app] [desc]` | 새로운 기능 요구사항(FR) 추가 | `1_SRS_RA.md` |
| `/uc-backlog-add` | `/uc-backlog-add [desc]` | 새로운 백로그(버그/개선) 항목 추가 | `5_IterationLog_RA.md` |
| `/uc-gap-detector` | `/uc-gap-detector` | 설계 문서와 실제 구현 코드 간 일치도 분석 | Match Rate 보고서 |
| `/uc-summary` | `/uc-summary` | 프로젝트 개요 및 현재 상태 요약 출력 | 콘솔 출력 |

### 3. Individual Agent Call (에이전트 개별 호출)

- **Design**: `/uc-srs [app]` (요구사항 명세), `/uc-erd` (데이터 모델), `/uc-api [app]` (API 설계), `/uc-screen [app]` (화면 설계), `/uc-wireframe [app]` (HTML 와이어프레임)
- **Visual Design**: `/us-ux-design` (Pencil.dev 기반 시각 디자인 생성 및 업데이트)
- **Implementation**: `/uc-fe [app]` (프론트엔드), `/uc-be [app]` (백엔드), `/uc-storybook` (Storybook 생성)
- **Quality**: `/uc-test [app]` (테스트 케이스), `/uc-bug-report [app]` (결함 분석)

### 4. Utility (유틸리티)
- `/uc-build`: 프로젝트 빌드 실행 (`bun run build`) 및 결과 확인
- `/uc-git-pr`: 변경된 파일을 feature 단위로 그룹핑하여 커밋 및 GitHub PR 생성
- `/uc-history`: 전체 Iteration 수행 이력 조회
- `/uc-archive`: 현재 Iteration 문서를 `iterations/` 폴더로 아카이브
- `/uc-help`: 모든 커맨드 상세 설명 및 사용법 표시

---

## Plugin Structure

```
u-maker-plugin/
├── skills/us-*/SKILL.md      # 스킬 정의 (us- prefix)
├── agents/ua-*.md             # 에이전트 정의 (ua- prefix)
├── commands/uc-*.md           # 슬래시 명령어 (uc- prefix)
├── templates/                 # SSoT 문서 템플릿
│   ├── 01-plan/
│   ├── 02-design/
│   ├── 03-dev/
│   ├── 04-check/
│   └── 05-act/
├── u-docs/
│   ├── db/                    # 플러그인 표준 문서 (구 references/)
│   └── README.md
├── lib/                       # 공유 라이브러리 (state, doc-tracker, gate)
├── scripts/                   # 자동화 스크립트
├── hooks/                     # Claude Code hooks
├── evals/                     # 평가 테스트
└── u-maker.config.json        # 프로젝트 설정 (단일 진실 공급원)
```

---

## Mermaid Diagram Requirements

모든 문서는 정보의 가시성을 위해 아래와 같은 다이어그램을 포함해야 합니다.

| Diagram Type | 주요 용도 |
|-------------|----------|
| `flowchart` | IA 메뉴 트리 구조, 로직 흐름, 문서 의존성, 네비게이션 플로우 |
| `journey` | 사용자 경험 흐름 |
| `mindmap` | 일반 계층 구조 시각화 (IA 메뉴 트리에는 사용하지 않음) |
| `erDiagram` | DB 엔티티 관계 (ERD) |
| `sequenceDiagram` | API 호출 흐름, 인증 흐름, 테스트 시나리오 |
| `stateDiagram-v2` | 상태 전이 (결함 상태, 문서 상태 등) |
| `xychart-beta` | 이터레이션별 진척도 및 품질 추이 |

---

## License

Private - Internal use only.
