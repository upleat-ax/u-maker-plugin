# u-maker 시작하기 (Get Started)

u-maker를 처음 사용하시나요? 이 가이드는 u-maker의 핵심 개념부터 역할별 활용법까지 단계별로 안내합니다.

---

## Part 1. u-maker란?

### 한 줄 요약

u-maker는 **8명의 AI 전문가 팀**이 소프트웨어 개발의 전 과정(기획 → 설계 → 구현 → 테스트 → 개선)을 자동화하는 **Claude Code 플러그인**입니다.

### 기존 개발 방식과 뭐가 다른가요?

| | 기존 방식 | u-maker 방식 |
|---|----------|-------------|
| **문서** | 코드 먼저, 문서는 나중에 (혹은 안 씀) | 문서 먼저, 코드는 문서를 기반으로 생성 (Docs-First) |
| **요구사항 추적** | 스프레드시트나 Jira에 따로 관리, 코드와 연결 안 됨 | ID 체계(USR→FR→US→FT)로 요구사항~코드~테스트 전 구간 자동 추적 |
| **품질 관리** | 개발 완료 후 QA팀에 전달, 수동 테스트 | 매 사이클마다 자동 테스트 + 설계-구현 Gap 분석 |
| **설계-구현 불일치** | "설계서와 코드가 달라요" 문제 빈번 | Match Rate 자동 측정, 90% 미만이면 자동 보완 |
| **반복 작업** | 수동으로 Plan-Do-Check 반복 | PDCA Loop 자동화 (종료 조건 충족까지 자동 반복) |
| **협업** | 각 역할자가 개별 도구로 작업 | 8개 AI 에이전트가 하나의 SSoT 문서 체계에서 협업 |
| **기술 스택 통일** | 코드 리뷰에서 사후 발견 | Hook이 기술 규칙 위반을 실시간 차단 |

### 핵심 개념 3가지

#### 1. SSoT (Single Source of Truth) — "문서가 곧 진실"

u-maker에서는 **모든 결정이 문서에 기록**됩니다. 요구사항, 설계, 구현 기록, 테스트 결과가 모두 `.u-maker/docs/` 아래 관리됩니다.

- 코드를 먼저 작성하려 하면 **Docs-First Guard**가 막고, 문서를 먼저 쓰라고 안내합니다
- 문서는 `.md`(사람이 읽는 원본) + `.json`(기계가 파싱하는 데이터) 2종이 항상 함께 생성됩니다
- 리포트 문서는 `.html`(브라우저에서 바로 열 수 있는 뷰어)도 추가로 생성됩니다

#### 2. PDCA 사이클 — "계획-실행-검증-개선 반복"

```
Plan (기획) → Design (설계) → Do (구현) → Check (검증) → Act (개선)
                                                              ↓
                                                     다음 Iteration으로
```

소프트웨어를 한 번에 완벽하게 만드는 것이 아니라, **반복적으로 개선**합니다.
각 Phase를 넘어가려면 **Gate 조건**을 충족해야 합니다:

| Phase 전환 | 통과 조건 |
|------------|-----------|
| Plan → Design | Roadmap + SRS + IA 문서가 Final 상태 |
| Design → Do | ERD + RTM + UXGuide + API + Screen + ScreenFlow = Final |
| Do → Check | 빌드 성공 + 설계-구현 Match Rate >= 90% |
| Check → Complete | Critical/Major 결함 0건, 모든 FT 구현, 빌드 성공 |

#### 3. 4-Tier ID 체계 — "왜 이 코드가 존재하는지 추적"

```
USR-0001 (사용자 유형: 예) 관리자, 일반 사용자)
  └── FR-0001 (기능 요구사항: 예) 회원가입 기능)
        └── US-0001 (유저 스토리: 예) 이메일로 회원가입하고 싶다)
              └── FT-0001 (Feature = 구현 단위: 예) 이메일 인증 구현)
```

> FT는 **Feature**(구현 단위)의 약어입니다. ~~Functional Test~~가 아닙니다.

"이 코드가 왜 존재하는지"를 FT → US → FR → USR로 항상 추적할 수 있습니다.

### AI 팀 구성 (8명의 전문가)

| 팀원 | 역할 | 하는 일 | 활동 Phase |
|------|------|---------|-----------|
| **PM** | Product Manager | 로드맵, 보고서, 회고, 인덱스 | PLAN, ACT |
| **RA** | Requirements Analyst | 프로젝트 기획, 문서 관리, 백로그, 추적표 | ALL |
| **SA** | Software Architect | SRS 작성, DB 설계(ERD), API 설계 | PLAN, DESIGN |
| **UX** | UX Designer | 정보 구조도, 화면 설계, 와이어프레임, 화면 흐름도 | PLAN, DESIGN, DO |
| **UX-DS** | Visual Designer | 디자인 도구(pencil/figma/stitch)로 시각 디자인 | DESIGN, DO |
| **DV-FE** | Frontend Dev | Next.js App Router + react-query + Storybook | DO |
| **DV-BE** | Backend Dev | API Routes + Prisma/Drizzle ORM | DO |
| **QA** | QA Engineer | 테스트 설계(Unit+E2E), 실행, 결함 분석 | CHECK |

---

## Part 2. 설치 & 첫 실행

### 필요한 것들

| 도구 | 용도 | 필수 |
|------|------|------|
| **Claude Code** | u-maker가 동작하는 기반 도구 | Yes |
| **Node.js** | 내부 스크립트(Hook, Guard 등) 실행 | Yes |
| **Python 3** | 문서 검증, 종료 조건 판정 스크립트 | Yes |
| **bun** | 프로젝트 빌드/실행 | Yes |
| Codex CLI / Gemini CLI | 멀티 환경 지원 | No |

### 설치

#### 방법 A: GitHub에서 설치 (권장)

GitHub에 배포된 공개 레포에서 바로 설치할 수 있습니다.

```bash
# 1. GitHub 레포를 마켓플레이스로 등록
claude plugin marketplace add github:thinoo-v2/u-maker-production

# 2. 플러그인 설치
claude plugin install u-maker
```

> 설치 후 반드시 **Claude Code를 재시작**해주세요.

#### 방법 B: 소스코드에서 로컬 설치

소스코드를 직접 클론해서 로컬에 설치하는 방법입니다.

```bash
cd /path/to/u-maker-plugin
./deploy_local.sh
```

이 스크립트가 자동으로:
- Claude Code 플러그인 디렉토리에 등록합니다
- 스킬과 에이전트 파일을 연결합니다 (심볼릭 링크)
- Codex/Gemini가 설치되어 있으면 공유 링크도 설정합니다

```bash
./deploy_local.sh --check   # 설치 상태 확인
./deploy_local.sh --clean   # 완전 제거
```

> 설치 후 반드시 **Claude Code를 재시작**해주세요.

### 프로젝트 시작하기

**새 프로젝트를 처음부터 만들기:**

```bash
/u-skill-create-project my-app
```

**이미 있는 프로젝트에 u-maker 적용하기:**

```bash
/u-skill-init .
```

기존 코드(package.json, 소스코드, DB 스키마 등)를 분석해서 SSoT 문서를 자동 역공학 생성합니다.

### 가장 쉬운 시작 — 자동 루프

프로젝트가 준비되었으면, 이 한 줄이면 됩니다:

```bash
/u-skill-loop
```

u-maker가 Plan → Design → Do → Check → Act 전체 사이클을 자동으로 돌립니다.
품질 기준(Critical/Major 결함 0건, 모든 FT 구현 완료, 빌드 성공)을 충족할 때까지 반복하며, 완료 시 종합 보고서가 자동 생성됩니다.

---

## Part 3. 역할별 활용 가이드

### 기획자 (PM / RA)

프로젝트를 기획하고 요구사항을 정의하는 역할입니다.

#### 주요 시나리오

**프로젝트 로드맵 수립:**
```bash
/u-skill-plan web                    # Plan Phase 전체 실행 (Roadmap → SRS → IA → Index)
```

**요구사항 추가/관리:**
```bash
/u-skill-us-add                      # 유저 스토리 추가 (대화형)
/u-skill-fr-add web "회원가입 기능"   # 기능 요구사항 추가
/u-skill-refine FR-0001 web          # 큰 요구사항을 하위 항목으로 세분화
/u-skill-refine US-0001              # 유저 스토리 세분화
```

**프로젝트 상태 파악:**
```bash
/u-skill-status                      # Iteration, Phase, 완료율, 문서 상태
/u-skill-summary                     # 프로젝트 요약 (터미널 출력)
/u-skill-docs                        # 전체 문서 목록과 상태
/u-skill-report                      # 종합 보고서 (.md + .html)
```

**백로그 관리:**
```bash
/u-skill-backlog                     # 현재 Open 백로그 조회
/u-skill-backlog-add "성능 최적화"    # 백로그 항목 추가
/u-skill-history                     # Iteration 이력 조회
```

**문서 품질 관리:**
```bash
/u-skill-validate                    # 문서 무결성 검증 (헤더, 추적성, 구조)
/u-skill-index                       # 문서 인덱스 갱신
/u-skill-glossary web                # 도메인 용어 정의
/u-skill-workflow web                # 비즈니스 워크플로우 정의
```

**에이전트에게 직접 요청:**
```bash
/u-agent-pm "이번 주 데일리 리포트를 생성해줘"
/u-agent-ra "마일스톤 3의 진행 상황을 정리해줘"
```

#### 기획자가 꼭 알아야 할 것

- u-maker는 **Docs-First** 원칙을 따릅니다. 새 기능을 코드로 바로 구현하려 하면 Hook이 차단합니다
- `/u-skill-us-add` → `/u-skill-fr-add` 순서로 문서를 먼저 추가한 후 구현을 진행하세요
- 요구사항이 너무 클 때는 `/u-skill-refine`으로 세분화하세요

---

### 디자이너 (UX)

화면 구조 설계, 와이어프레임, 시각 디자인을 담당합니다.

#### 주요 시나리오

**설계 Phase 전체 실행:**
```bash
/u-skill-design web                  # Design Phase (UXGuide → Screen → ScreenFlow → ERD → API → RTM)
```

**개별 설계 작업:**
```bash
/u-skill-screen web                  # 화면 상세 설계서 작성
/u-skill-wireframe web               # 와이어프레임 HTML 생성 (SVG 기반 레이아웃)
/u-skill-ux-figma web                # 디자인 도구(pencil/figma/stitch)로 화면 디자인
/u-skill-ux-designsystem web         # 디자인 도구 기반 디자인 시스템/컴포넌트 시각 구성
```

**설계 문서 확인:**
```bash
/u-skill-html-doc screen             # 화면 설계서를 HTML 뷰어로 변환
/u-skill-html-doc screenflow         # 화면 흐름도를 HTML로 변환
/u-skill-html-doc uxguide            # UX 가이드를 HTML로 변환
```

**에이전트에게 직접 요청:**
```bash
/u-agent-ux "로그인 화면에 소셜 로그인 버튼을 넣어줘"
/u-agent-ux "대시보드 화면의 레이아웃을 2컬럼으로 변경해줘"
```

#### 디자이너가 꼭 알아야 할 것

- 화면 설계는 `IA(정보 구조도) → Screen(화면 설계) → ScreenFlow(흐름도) → Wireframe(HTML) → 시각 디자인` 순서로 진행됩니다
- 와이어프레임은 HTML 파일로 생성되며, UI 레이아웃 영역은 SVG로 시각화됩니다
- 시각 디자인 도구는 `u-maker.config.json`의 `designTool` 설정에 따라 pencil.dev, Figma, Stitch 중 선택됩니다

#### 생성되는 문서

| 문서 | 위치 | 설명 |
|------|------|------|
| IA (정보 구조도) | `{app}/01-plan/1_IA_RA.md` | 전체 화면 구조와 네비게이션 |
| UX Guide | `common/02-design/2_UXGuide_UX.md` | UX 표준 가이드 + 디자인 시스템 |
| Screen | `{app}/02-design/2_Screen_UX.md` | 화면별 상세 설계 |
| ScreenFlow | `{app}/02-design/2_ScreenFlow_UX.md` | 화면 간 흐름도 |
| Wireframe | `{app}/02-design/2_Screen_Wireframes/*.html` | 와이어프레임 HTML |
| Design Token | `common/03-dev/3_DesignToken_UX.md` | 색상, 타이포, 간격 등 디자인 토큰 |
| UI Components | `common/03-dev/3_UIComponents_UX.md` | UI 컴포넌트 명세 |

---

### 개발자 (Frontend / Backend)

설계 문서를 기반으로 코드를 구현합니다.

#### 주요 시나리오

**개발 Phase 전체 실행:**
```bash
/u-skill-dev web                     # DO Phase (UX/FE/BE 병렬 개발)
```

**개별 작업:**
```bash
/u-skill-build                       # 빌드 실행 (bun run build)
/u-skill-storybook                   # Storybook 실행/생성
/u-skill-fix web "로그인 토큰 만료 버그"  # 버그 수정 + QA가 자동 TC 보강
```

**설계-구현 일치 확인:**
```bash
/u-skill-gap-detector                # SRS/ERD/API/Screen vs 실제 코드 비교
```

**에이전트에게 직접 요청:**
```bash
/u-agent-dv-fe "로그인 페이지의 폼 유효성 검사를 추가해줘"
/u-agent-dv-be "User API에 프로필 이미지 업로드 엔드포인트를 추가해줘"
/u-agent-sa "User 엔티티에 프로필 이미지 필드를 추가해줘"
```

**Git & PR:**
```bash
/u-skill-git-pr                      # feature별 git commit + GitHub PR
/u-skill-git-pr feat/user-auth       # 특정 feature 이름 지정
```

#### 개발자가 꼭 알아야 할 것

- u-maker는 **기술 스택 규칙**을 강제합니다. 위반 시 Hook이 코드를 차단합니다:

| 규칙 | 위반 시 |
|------|---------|
| Next.js **App Router** only | `pages/` 디렉토리 거부 |
| `react-query` only | usecase 패턴 거부 |
| Plain `.css` only | CSS-in-JS (styled-components/emotion) 거부 |
| `bun` only | npm/yarn/pnpm 거부 |
| Functional Components only | Class 컴포넌트 거부 |
| Storybook 필수 | `.stories.tsx` 없이 PR 거부 |
| Design Token 기반 스타일링 | 하드코딩 색상/크기 거부 |

- 코드를 작성하기 전에 **문서(SRS, API Contract, ERD)가 Final 상태**여야 합니다
- `/u-skill-fix`를 사용하면 코드 수정 후 QA 에이전트가 **자동으로 테스트 케이스를 보강**합니다
- DO Phase 완료 후 `gap-detector`가 설계-구현 Match Rate를 측정합니다. 90% 미만이면 Gap FT별로 보완합니다

---

### QA (테스터)

테스트 케이스를 설계하고 실행하여 품질을 보장합니다.

#### 주요 시나리오

**테스트 설계:**
```bash
/u-skill-testcase web                # SRS FT 기반 Unit+E2E 테스트 케이스 일괄 설계
/u-skill-tc-add web FT-0001 "로그인 성공" # 개별 TC 추가
/u-skill-tc-add all FT-0001 "로그인 TC"  # 모든 앱에 동일 TC 일괄 추가
/u-skill-tc-refine TC-0001 web       # TC를 하위 TC로 세분화
```

**테스트 실행:**
```bash
/u-skill-qa web                      # Vitest(Unit) + Playwright(E2E) 실행
/u-skill-check web                   # CHECK Phase 전체 (설계 → 실행 → 결함 분석)
```

**품질 분석:**
```bash
/u-skill-gap-detector                # 설계-구현 Gap 분석
/u-skill-validate                    # 문서 무결성 검증
/u-skill-report                      # 종합 보고서 (TC 결과 포함)
```

**에이전트에게 직접 요청:**
```bash
/u-agent-qa "인증 관련 테스트 케이스를 보강해줘"
/u-agent-qa "경계값 테스트를 추가해줘"
```

#### QA가 꼭 알아야 할 것

- 테스트 케이스는 SRS의 **FT(Feature) 단위**로 설계됩니다
- 각 TC는 **6W 스텝 구조**: Step / Screen / Element / Action / Input / Expected
- TC 타입: **Positive**(정상), **Negative**(비정상), **Boundary**(경계값)
- TC 레벨: **Unit**(Vitest) + **E2E**(Playwright) 모두 포함해야 합니다
- `/u-skill-fix`로 버그 수정 시 QA 에이전트가 **백그라운드에서 자동으로 TC를 보강**합니다

#### 종료 조건 (Exit Criteria)

루프 종료를 위해 **모든** 조건을 충족해야 합니다:

| 조건 | 확인 방법 |
|------|----------|
| Critical/Major 결함 0건 | `4_Report_QA.md` 파싱 |
| SRS의 모든 FT 구현 완료 | `1_SRS_RA.md` 상태 확인 |
| 빌드 성공 | `bun run build` 실행 |

---

### PM (프로젝트 매니저)

프로젝트 전반을 관리하고 보고서를 생성합니다.

#### 주요 시나리오

**프로젝트 현황 파악:**
```bash
/u-skill-status                      # Iteration, Phase, 완료율
/u-skill-summary                     # 프로젝트 요약 출력
/u-skill-docs                        # 전체 문서 상태 (Draft/Review/Final)
```

**보고서 생성:**
```bash
/u-skill-report                      # 종합 보고서 (.md + .html 동시 생성)
/u-skill-report web                  # 특정 앱 보고서
```

보고서에 포함되는 내용:
- FR/NFR/US/FT/TC 전체 카운트 대시보드
- 이전 보고서와 비교 Delta 테이블 + 트렌드 차트
- US 상세 카드 (As a / I want to / So that)
- TC FT별 그룹 뷰 (Pass/Fail 뱃지)
- 3종 부채 현황 (기획/디자인/기술)
- 기여자별 작업 내역 + Git 활동 요약
- Dark/Light 모드 토글

**문서 HTML 변환:**
```bash
/u-skill-html-doc                    # 모든 SSoT 문서를 HTML 뷰어로 변환
/u-skill-html-doc srs                # SRS만 변환
/u-skill-html-doc all                # 전체 변환
```

**Iteration 관리:**
```bash
/u-skill-act                         # ACT Phase (백로그 정리 → 회고 → 아카이브)
/u-skill-archive                     # 현재 Iteration 아카이브
/u-skill-history                     # Iteration 이력 조회
```

**에이전트에게 직접 요청:**
```bash
/u-agent-pm "이번 스프린트 회고를 작성해줘"
/u-agent-pm "로드맵을 Q2 기준으로 갱신해줘"
```

#### PM이 꼭 알아야 할 것

- 보고서는 `.md` + `.html` 2종 동시 생성됩니다 (HTML은 브라우저에서 바로 열 수 있음)
- `/u-skill-loop` 완료 시 **Loop Report**가 자동 생성됩니다
- `/u-skill-validate`로 문서 무결성을 주기적으로 검증하세요

---

## Part 4. 실전 시나리오 모음

### Scenario 1: 새 프로젝트를 처음부터 끝까지

```bash
/u-skill-create-project my-saas      # 프로젝트 생성
/u-skill-loop                        # 전체 PDCA 자동 실행
```

### Scenario 2: 기존 프로젝트에 SSoT 적용

```bash
/u-skill-init .                      # 기존 코드 분석 → SSoT 문서 역공학 생성
/u-skill-status                      # 생성된 문서 상태 확인
/u-skill-validate                    # 문서 무결성 검증
/u-skill-loop                        # PDCA 루프 시작
```

### Scenario 3: 단계별 수동 실행

```bash
/u-skill-plan web                    # 1. 기획
/u-skill-design web                  # 2. 설계
/u-skill-dev web                     # 3. 개발
/u-skill-check web                   # 4. 테스트
/u-skill-act                         # 5. 정리 및 회고
```

### Scenario 4: 새 기능 추가

```bash
/u-skill-us-add                      # 1. 유저 스토리 추가
/u-skill-fr-add web                  # 2. 기능 요구사항 추가
/u-skill-refine FR-0010 web          # 3. 너무 크면 세분화
/u-skill-design web                  # 4. 설계부터 재실행
/u-skill-dev web                     # 5. 개발
/u-skill-check web                   # 6. 테스트
```

### Scenario 5: 버그 수정

```bash
/u-skill-fix web "로그인 시 토큰 만료 처리 버그"  # 코드 수정 + 자동 TC 보강
```

### Scenario 6: 루프 중단 & 재개

```bash
/u-skill-stop                        # 루프 중단 (상태 저장)
/u-skill-status                      # 상태 확인
/u-skill-resume                      # 재개
```

### Scenario 7: 특정 Phase부터 루프 시작

```bash
/u-skill-loop-from design            # Design Phase부터 루프
```

### Scenario 8: 외부 소스 임포트

```bash
/u-skill-import figma https://figma.com/...   # Figma 디자인을 SSoT 문서로 변환
/u-skill-import url https://example.com       # URL 콘텐츠를 SSoT 문서로 변환
/u-skill-import                               # _sources.json 기반 일괄 임포트
```

### Scenario 9: 자연어로 요청하기

슬래시 커맨드 대신 자연어로 말해도 됩니다. u-maker가 알아서 적절한 에이전트에게 전달합니다:

```
"로그인 기능을 추가하고 싶어"         → RA/SA가 문서 작성
"ERD를 PostgreSQL로 최적화해줘"      → SA가 ERD 수정
"대시보드 화면을 추가해줘"            → UX가 화면 설계
"테스트 케이스를 보강해줘"            → QA가 TC 추가
"이번 주 보고서를 만들어줘"           → PM이 보고서 생성
```

---

## Part 5. 문서 구조 한눈에 보기

```
.u-maker/docs/
├── common/                     # 프로젝트 전체 공용
│   ├── 01-plan/
│   │   ├── 1_Roadmap_PM.md     # 로드맵
│   │   ├── 1_Index_PM.md       # 문서 인덱스
│   │   └── 1_Common_RA.md      # 공통 정의
│   ├── 02-design/
│   │   ├── 2_ERD_SA.md         # DB 설계 (Entity Relationship)
│   │   ├── 2_RTM_RA.md         # 요구사항 추적표
│   │   └── 2_UXGuide_UX.md     # UX 표준 가이드 + 디자인 시스템
│   ├── 03-dev/
│   │   ├── 3_UIComponents_UX.md # UI 컴포넌트 명세
│   │   └── 3_DesignToken_UX.md  # 디자인 토큰
│   └── 05-act/
│       ├── 5_IterationLog_RA.md # 백로그 + Iteration 이력
│       ├── 5_Retrospective_PM.md # 회고
│       └── 5_*Report_PM_*.md/html # 보고서
├── {app}/                      # 앱별 문서 (예: web, admin)
│   ├── 01-plan/
│   │   ├── 1_SRS_RA.md         # 요구사항 명세 (FR→US→FT)
│   │   ├── 1_IA_RA.md          # 정보 구조도
│   │   ├── 1_Glossary_RA.md    # 용어 정의
│   │   └── 1_Workflow_RA.md    # 워크플로우 정의
│   ├── 02-design/
│   │   ├── 2_API_SA.md         # API Contract (OpenAPI 3.0)
│   │   ├── 2_Screen_UX.md      # 화면 상세 설계
│   │   ├── 2_ScreenFlow_UX.md  # 화면 흐름도
│   │   └── 2_Screen_Wireframes/ # 와이어프레임 HTML
│   ├── 03-dev/
│   │   ├── 3_Code_DV.md        # 구현 기록
│   │   └── 3_Screen_UX.md      # 화면 구현 명세
│   └── 04-check/
│       ├── 4_Case_QA.md        # 테스트 케이스
│       └── 4_Report_QA.md/html  # QA 리포트
└── iterations/                  # Iteration 아카이브
    └── iter-N/
```

---

## Part 6. 자주 묻는 질문

### Q: 명령어가 안 보여요

1. `./deploy_local.sh --check`로 설치 상태를 확인하세요
2. Claude Code를 재시작하세요
3. `/u-skill-help`를 입력해 명령어 목록이 나오는지 확인하세요

### Q: "문서를 먼저 업데이트하세요"라는 메시지가 뜹니다

u-maker의 Docs-First 원칙 때문입니다. 새 기능을 코드로 바로 구현하려 하면 이 메시지가 나옵니다.

```bash
# 먼저 문서를 추가한 후
/u-skill-us-add
/u-skill-fr-add web

# 그 다음에 구현을 진행하세요
/u-skill-dev web
```

### Q: 루프가 계속 돌아요

기본 최대 10회까지 반복되며, 이후 자동 종료됩니다. 바로 멈추고 싶으면 `/u-skill-stop`.
`.u-maker/u-maker.config.json`의 `pdca.maxIterations` 값을 조정할 수 있습니다.

### Q: Gap Loop가 수렴하지 않아요

Inner Gap Loop는 최대 `maxGapRetries`(기본 3회) 재시도 후 강제 진행됩니다.
`.u-maker/u-maker.config.json`의 `pdca.gapThreshold`(기본 90%)와 `pdca.maxGapRetries`를 조정할 수 있습니다.

### Q: 멀티앱 프로젝트는 어떻게 하나요?

앱 이름을 인자로 전달합니다:

```bash
/u-skill-plan web
/u-skill-design admin
/u-skill-dev web
```

### Q: 설정 파일은 어디에 있나요?

`.u-maker/u-maker.config.json`이 프로젝트의 핵심 설정 파일입니다.
현재 Phase, Iteration, 앱 목록, 기술 스택 규칙 등을 관리합니다.

### Q: 이전에 `u-ssot.config.json`을 쓰고 있었어요

설정 파일명이 변경되었습니다:

```bash
mv .u-maker/u-ssot.config.json .u-maker/u-maker.config.json
```

---

## Part 7. 다음 단계

기본 사용법을 익혔다면, 더 깊이 활용해보세요:

| 활용 | 명령어 |
|------|--------|
| 전체 53개 명령어 상세 도움말 | `/u-skill-help` |
| 종합 보고서 (Dark/Light HTML) | `/u-skill-report` |
| SSoT 문서를 HTML 뷰어로 변환 | `/u-skill-html-doc` |
| 디자인 도구로 시각적 화면 디자인 | `/u-skill-ux-figma` |
| 외부 소스를 SSoT 문서로 변환 | `/u-skill-import` |
| 설계와 구현의 일치율 분석 | `/u-skill-gap-detector` |
| Git PR 생성 | `/u-skill-git-pr` |
| 도메인 용어 정의 | `/u-skill-glossary` |
| 비즈니스 워크플로우 정의 | `/u-skill-workflow` |

궁금한 점이 있으면 언제든 자연어로 물어보세요. u-maker가 적절한 에이전트에게 전달해드립니다.
