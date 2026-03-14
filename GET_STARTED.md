# u-maker 시작하기 (Get Started)

u-maker를 처음 사용하시나요? 이 가이드를 따라하면 10분 안에 첫 프로젝트를 시작할 수 있습니다.

---

## u-maker가 뭔가요?

u-maker는 **Claude Code 플러그인**으로, 소프트웨어 개발의 전 과정을 자동화해주는 도구입니다.

쉽게 말하면, **8명의 AI 전문가 팀**이 여러분의 프로젝트를 함께 만들어줍니다:

| 팀원 | 역할 | 하는 일 |
|------|------|---------|
| PM (Product Manager) | 프로젝트 관리자 | 로드맵 작성, 보고서 생성, 회고 |
| RA (Requirements Analyst) | 요구사항 분석가 | 프로젝트 기획, 문서 관리, 백로그 |
| SA (Software Architect) | 소프트웨어 설계자 | SRS 작성, DB 설계(ERD), API 설계 |
| UX (UX Designer) | UX 디자이너 | 화면 구조, 화면 설계, 와이어프레임 |
| UX-DS (Pencil Designer) | 시각 디자이너 | pencil.dev로 .pen 파일 시각 디자인 |
| DV-FE (Frontend Dev) | 프론트엔드 개발자 | Next.js 기반 화면 구현 |
| DV-BE (Backend Dev) | 백엔드 개발자 | API 서버 구현, DB 연동 |
| QA (QA Engineer) | 품질 관리자 | 테스트 설계, 실행, 결함 분석 |

이 팀이 **Plan → Design → Do → Check → Act** 사이클(PDCA)을 돌면서 프로젝트를 완성합니다.

---

## 1단계: 설치하기

### 필요한 것들

| 도구 | 용도 | 필수 여부 |
|------|------|-----------|
| **Claude Code** | u-maker가 동작하는 기반 도구 | 필수 |
| **Node.js** | 내부 스크립트(Hook, Guard 등) 실행 | 필수 |
| **Python 3** | 문서 검증, 종료 조건 판정 스크립트 | 필수 |
| **bun** | 프로젝트 빌드/실행 | 필수 |
| Codex CLI / Gemini CLI | 멀티 환경 지원 | 선택 |

### 설치 방법

터미널에서 u-maker-plugin 폴더로 이동한 후 배포 스크립트를 실행합니다:

```bash
cd /path/to/u-maker-plugin
./deploy_local.sh
```

이 스크립트가 자동으로:
- Claude Code 플러그인 디렉토리에 등록합니다
- 스킬과 에이전트 파일을 연결합니다 (심볼릭 링크)
- Codex/Gemini가 설치되어 있으면 공유 링크도 설정합니다

설치가 잘 되었는지 확인하려면:

```bash
./deploy_local.sh --check
```

> 설치 후 **Claude Code를 재시작**해주세요.

더 이상 쓰지 않을 때 완전히 제거하려면:

```bash
./deploy_local.sh --clean
```

---

## 2단계: 프로젝트 시작하기

두 가지 방법이 있습니다. 상황에 맞는 것을 선택하세요.

### A. 새 프로젝트를 처음부터 만들기

```bash
/u-skill-create-project my-app
```

이 명령어 하나로:
- Turborepo 모노레포 프로젝트 구조가 생성되고
- `.u-maker/docs/` 아래에 SSoT 문서 구조가 만들어집니다

### B. 이미 있는 프로젝트에 u-maker 적용하기

기존 프로젝트 폴더에서:

```bash
/u-skill-init .
```

u-maker가 여러분의 코드를 분석해서:
- package.json, 소스코드, DB 스키마 등을 읽고
- 이에 맞는 SSoT 문서를 자동으로 생성합니다 (역공학)

---

## 3단계: 개발 시작하기

### 가장 쉬운 방법 — 자동 루프

프로젝트가 준비되었으면, 이 한 줄이면 됩니다:

```bash
/u-skill-loop
```

u-maker가 알아서 **Plan → Design → Do → Check → Act** 전체 사이클을 돌립니다.

1. **Plan**: 요구사항 문서(SRS), 로드맵, 정보 구조도 작성
2. **Design**: 화면 설계, DB 설계(ERD), API 설계, 와이어프레임 생성
3. **Do**: 프론트엔드/백엔드 코드 구현
4. **Check**: 테스트 케이스 설계 및 실행, 결함 분석
5. **Act**: 결과 정리, 회고, 백로그 관리

품질 기준(Critical/Major 결함 0건, 모든 기능 구현 완료, 빌드 성공)을 충족할 때까지 자동으로 반복하며, 완료되면 종합 보고서가 생성됩니다.

### 단계별로 직접 하고 싶다면

각 Phase를 하나씩 실행할 수도 있습니다:

```bash
# 1. 기획 (Plan)
/u-skill-plan

# 2. 설계 (Design)
/u-skill-design

# 3. 개발 (Do)
/u-skill-dev

# 4. 테스트 (Check)
/u-skill-check

# 5. 정리 및 회고 (Act)
/u-skill-act
```

---

## 자주 쓰는 명령어 모음

### 상태 확인

```bash
/u-skill-status       # 현재 Iteration, Phase, 완료율 보기
/u-skill-docs         # 문서 목록과 상태(Draft/Review/Final) 보기
/u-skill-summary      # 프로젝트 요약 보기 (터미널 출력만)
/u-skill-help         # 전체 명령어 목록 보기
```

### 기능 추가하기

새로운 기능을 추가하고 싶을 때:

```bash
/u-skill-us-add                 # 유저 스토리 추가
/u-skill-fr-add web             # 기능 요구사항 추가
/u-skill-tc-add web FT-0001     # 테스트 케이스 추가
```

> u-maker는 **"문서 먼저(Docs-First)"** 원칙을 따릅니다.
> 새 기능을 코드로 바로 구현하려 하면, Hook이 자동으로 감지하여 "먼저 문서를 업데이트하세요"라고 안내합니다.
> `/u-skill-us-add`나 `/u-skill-fr-add`로 문서를 먼저 추가한 후 구현을 진행하세요.

### 항목 세분화

요구사항이나 기능이 너무 크면 작은 단위로 나눌 수 있습니다:

```bash
/u-skill-refine FR-0010 web     # FR을 하위 FR로 분해
/u-skill-refine US-0010         # US를 하위 US로 분해
/u-skill-refine FT-0010 web     # FT를 하위 FT로 분해
/u-skill-tc-refine TC-0010 web  # TC를 하위 TC로 세분화
```

### 에이전트에게 직접 말하기

특정 에이전트에게 자유롭게 요청할 수도 있습니다:

```bash
/u-agent-sa "User 테이블에 프로필 이미지 컬럼을 추가해줘"
/u-agent-ux "로그인 화면에 소셜 로그인 버튼을 넣어줘"
/u-agent-qa "인증 관련 테스트를 보강해줘"
/u-agent-pm "이번 주 데일리 리포트를 생성해줘"
```

자연어로 말해도 됩니다 — u-maker가 알아서 적절한 에이전트에게 전달합니다:

```
"로그인 기능을 추가하고 싶어"     → RA/SA 에이전트가 문서 작성
"ERD를 PostgreSQL로 최적화해줘"  → SA 에이전트가 ERD 수정
"테스트 케이스를 보강해줘"        → QA 에이전트가 TC 추가
```

### 루프 제어

```bash
/u-skill-stop                  # 진행 중인 루프 중단 (상태 저장됨)
/u-skill-resume                # 중단된 루프 재개
/u-skill-loop-from design      # 특정 Phase부터 루프 시작
```

### 보고서 & 분석

```bash
/u-skill-report                # 프로젝트 종합 보고서 (.md + .html)
/u-skill-gap-detector          # 설계 vs 구현 일치율 분석
/u-skill-validate              # 문서 무결성 검증
```

### 버그 수정

```bash
/u-skill-fix [app] [설명]      # 코드 수정 + QA가 자동으로 TC 보강
```

### 문서를 HTML로 보기

```bash
/u-skill-html-doc              # 모든 SSoT 문서를 HTML 뷰어로 변환
/u-skill-html-doc srs          # 특정 문서만 변환
```

### Git & PR

```bash
/u-skill-git-pr                # feature별 git commit + GitHub PR 생성
/u-skill-git-pr feat/login     # 특정 feature 이름 지정
```

---

## 핵심 개념 이해하기

### SSoT (Single Source of Truth)

u-maker는 **"문서가 곧 진실"** 원칙으로 동작합니다.

- 모든 요구사항, 설계, 구현 기록이 `.u-maker/docs/` 에 문서로 관리됩니다
- 문서를 먼저 작성하고, 그 문서를 기반으로 코드를 생성합니다
- 코드만 먼저 작성하려 하면 **Docs-First Guard**가 막고, 문서를 먼저 쓰라고 안내합니다
- 문서는 `.md`(사람이 읽는 원본) + `.json`(기계가 파싱하는 데이터) 2종이 항상 함께 생성됩니다

### PDCA 사이클

```
Plan (기획) → Design (설계) → Do (구현) → Check (검증) → Act (개선)
                                                              ↓
                                                     다음 Iteration으로
```

각 Phase를 넘어가려면 **Gate 조건**을 충족해야 합니다:

| Phase 전환 | Gate 조건 |
|------------|-----------|
| Plan → Design | Roadmap + SRS + IA 문서가 Final |
| Design → Do | ERD + RTM + UXGuide + API + Screen + ScreenFlow = Final |
| Do → Check | 빌드 성공 + Match Rate >= 90% |
| Check → Complete | Critical/Major 결함 0건, 모든 FT 구현, 빌드 성공 |

### 4-Tier ID 체계

요구사항부터 구현까지 추적할 수 있는 ID 체계입니다:

```
USR-0001 (사용자 유형: 예) 관리자, 일반 사용자)
  └── FR-0001 (기능 요구사항: 예) 회원가입 기능)
        └── US-0001 (유저 스토리: 예) 이메일로 회원가입하고 싶다)
              └── FT-0001 (Feature = 구현 단위: 예) 이메일 인증 구현)
```

> FT는 **Feature**(구현 단위)의 약어입니다. Functional Test가 아닙니다.

"이 코드가 왜 존재하는지"를 FT → US → FR → USR로 항상 추적할 수 있습니다.

---

## 문서 구조 한눈에 보기

```
.u-maker/docs/
├── common/               # 프로젝트 전체 공용
│   ├── 01-plan/          # 로드맵, 인덱스, 공통 규칙
│   ├── 02-design/        # ERD, UX 가이드, 추적표(RTM)
│   ├── 03-dev/           # UI 컴포넌트, 디자인 토큰
│   └── 05-act/           # 회고, 보고서, Iteration 로그
├── {app}/                # 앱별 문서 (예: web, admin)
│   ├── 01-plan/          # SRS (요구사항 명세), IA (정보 구조도)
│   ├── 02-design/        # API 설계, 화면 설계, 화면 흐름도, 와이어프레임
│   ├── 03-dev/           # 구현 기록
│   └── 04-check/         # 테스트 케이스, QA 리포트
└── iterations/           # 지난 Iteration 아카이브
```

### 문서별 파일 형식

| 확장자 | 용도 |
|--------|------|
| `.md` | 사람이 읽는 마크다운 문서 (SSoT 원본) |
| `.json` | 기계가 파싱하는 구조화 데이터 |
| `.html` | 브라우저에서 바로 볼 수 있는 인터랙티브 뷰어/리포트 |

---

## 자주 묻는 질문

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

기본적으로 최대 10회까지 반복되며, 이후 자동 종료됩니다.
바로 멈추고 싶으면 `/u-skill-stop`을 사용하세요.
`.u-maker/u-maker.config.json`의 `pdca.maxIterations` 값을 조정할 수도 있습니다.

### Q: 멀티앱 프로젝트는 어떻게 하나요?

앱 이름을 인자로 전달하면 됩니다:

```bash
/u-skill-plan web          # web 앱에 대한 Plan
/u-skill-design admin      # admin 앱에 대한 Design
/u-skill-dev web           # web 앱 개발
```

### Q: 설정 파일은 어디에 있나요?

`.u-maker/u-maker.config.json`이 프로젝트의 핵심 설정 파일입니다.
여기서 현재 Phase, Iteration, 앱 목록, 기술 스택 규칙 등을 관리합니다.

### Q: 이전에 `u-ssot.config.json`을 사용하고 있었어요

설정 파일명이 변경되었습니다. 1회 마이그레이션이 필요합니다:

```bash
mv .u-maker/u-ssot.config.json .u-maker/u-maker.config.json
```

---

## 다음 단계

기본적인 사용법을 익혔다면, 이제 더 깊이 활용해보세요:

| 명령어 | 설명 |
|--------|------|
| `/u-skill-help` | 전체 52개 명령어 상세 도움말 |
| `/u-skill-report` | 프로젝트 현황 종합 보고서 (Dark/Light 모드 HTML) |
| `/u-skill-ux-figma` | pencil.dev로 시각적 화면 디자인 |
| `/u-skill-html-doc` | SSoT 문서를 인터랙티브 HTML 뷰어로 변환 |
| `/u-skill-gap-detector` | 설계와 구현의 일치율 분석 |
| `/u-skill-git-pr` | 변경사항을 feature별로 정리해서 GitHub PR 생성 |
| `/u-skill-glossary` | 프로젝트 도메인 용어 정의 |
| `/u-skill-workflow` | 비즈니스 워크플로우 정의 |

궁금한 점이 있으면 언제든 자연어로 물어보세요. u-maker가 적절한 에이전트에게 전달해드립니다.
