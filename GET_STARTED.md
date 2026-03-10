# u-maker 시작하기 (Get Started)

u-maker를 처음 사용하시나요? 이 가이드를 따라하면 10분 안에 첫 프로젝트를 시작할 수 있습니다.

---

## u-maker가 뭔가요?

u-maker는 **Claude Code 플러그인**으로, 소프트웨어 개발의 전 과정을 자동화해주는 도구입니다.

쉽게 말하면, **7명의 AI 전문가 팀**이 여러분의 프로젝트를 함께 만들어줍니다:

| 팀원 | 역할 | 하는 일 |
|------|------|---------|
| PM (Product Manager) | 프로젝트 관리자 | 로드맵 작성, 보고서 생성, 회고 |
| RA (Requirements Analyst) | 요구사항 분석가 | 프로젝트 기획, 문서 관리, 백로그 |
| SA (Software Architect) | 소프트웨어 설계자 | SRS 작성, DB 설계(ERD), API 설계 |
| UX (UX Designer) | UX 디자이너 | 화면 구조, 화면 설계, 와이어프레임 |
| DV-FE (Frontend Dev) | 프론트엔드 개발자 | Next.js 기반 화면 구현 |
| DV-BE (Backend Dev) | 백엔드 개발자 | API 서버 구현, DB 연동 |
| QA (QA Engineer) | 품질 관리자 | 테스트 설계, 실행, 결함 분석 |

이 팀이 **Plan → Design → Do → Check → Act** 사이클(PDCA)을 돌면서 프로젝트를 완성합니다.

---

## 1단계: 설치하기

### 필요한 것들

- **Claude Code** (필수) — u-maker가 동작하는 기반 도구
- **Node.js** — 내부 스크립트 실행용
- **bun** — 프로젝트 빌드/실행용

### 설치 방법

터미널에서 u-maker-plugin 폴더로 이동한 후 배포 스크립트를 실행합니다:

```bash
cd /path/to/u-maker-plugin
./deploy_local.sh
```

이 스크립트가 자동으로:
- Claude Code 플러그인 디렉토리에 등록
- 스킬과 에이전트 파일을 연결 (심볼릭 링크)

설치가 잘 되었는지 확인하려면:

```bash
./deploy_local.sh --check
```

설치 후 **Claude Code를 재시작**해주세요.

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

- 문서를 작성하고 (Plan)
- 화면과 DB, API를 설계하고 (Design)
- 코드를 구현하고 (Do)
- 테스트하고 (Check)
- 결과를 정리합니다 (Act)

품질 기준을 충족할 때까지 자동으로 반복하며, 완료되면 종합 보고서가 생성됩니다.

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
/u-skill-status       # 현재 진행 상태 보기
/u-skill-docs         # 문서 목록과 상태 보기
/u-skill-summary      # 프로젝트 요약 보기
```

### 기능 추가하기

새로운 기능을 추가하고 싶을 때:

```bash
/u-skill-us-add                 # 유저 스토리 추가
/u-skill-fr-add web             # 기능 요구사항 추가
/u-skill-tc-add web FT-0001     # 테스트 케이스 추가
```

### 에이전트에게 직접 말하기

특정 에이전트에게 자유롭게 요청할 수도 있습니다:

```bash
/u-agent-sa "User 테이블에 프로필 이미지 컬럼을 추가해줘"
/u-agent-ux "로그인 화면에 소셜 로그인 버튼을 넣어줘"
/u-agent-qa "인증 관련 테스트를 보강해줘"
```

### 루프 제어

```bash
/u-skill-stop         # 진행 중인 루프 중단
/u-skill-resume       # 중단된 루프 재개
/u-skill-loop-from design   # 특정 Phase부터 루프 시작
```

### 보고서

```bash
/u-skill-report       # 프로젝트 종합 보고서 (.md + .html)
/u-skill-gap-detector # 설계 vs 구현 일치율 분석
```

### 도움말

```bash
/u-skill-help         # 전체 명령어 목록 보기
```

---

## 핵심 개념 이해하기

### SSoT (Single Source of Truth)

u-maker는 **"문서가 곧 진실"** 원칙으로 동작합니다.

- 모든 요구사항, 설계, 구현 기록이 `.u-maker/docs/` 에 문서로 관리됩니다
- 문서를 먼저 작성하고, 그 문서를 기반으로 코드를 생성합니다
- 코드만 먼저 작성하려 하면 **Docs-First Guard**가 막고, 문서를 먼저 쓰라고 안내합니다

### PDCA 사이클

```
Plan (기획) → Design (설계) → Do (구현) → Check (검증) → Act (개선)
                                                              ↓
                                                     다음 Iteration으로
```

각 Phase를 넘어가려면 **Gate 조건**을 충족해야 합니다. 예를 들어 Plan의 문서가 Final 상태가 되어야 Design으로 넘어갈 수 있습니다.

### 4-Tier ID 체계

요구사항부터 구현까지 추적할 수 있는 ID 체계입니다:

```
USR-0001 (사용자 유형)
  └── FR-0001 (기능 요구사항)
        └── US-0001 (유저 스토리)
              └── FT-0001 (구현 단위 = Feature)
```

"이 코드가 왜 존재하는지"를 항상 추적할 수 있습니다.

---

## 문서 구조 한눈에 보기

```
.u-maker/docs/
├── common/               # 프로젝트 전체 공용
│   ├── 01-plan/          # 로드맵, 인덱스
│   ├── 02-design/        # ERD, UX 가이드, 추적표
│   ├── 03-dev/           # UI 컴포넌트, 디자인 토큰
│   └── 05-act/           # 회고, 보고서, 백로그
├── {app}/                # 앱별 문서 (예: web, admin)
│   ├── 01-plan/          # SRS (요구사항 명세), IA (정보 구조도)
│   ├── 02-design/        # API 설계, 화면 설계, 와이어프레임
│   ├── 03-dev/           # 구현 기록
│   └── 04-check/         # 테스트 케이스, QA 리포트
└── iterations/           # 지난 Iteration 아카이브
```

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

### Q: 멀티앱 프로젝트는 어떻게 하나요?

앱 이름을 인자로 전달하면 됩니다:

```bash
/u-skill-plan web          # web 앱에 대한 Plan
/u-skill-design admin      # admin 앱에 대한 Design
/u-skill-dev web           # web 앱 개발
```

### Q: 자연어로도 요청할 수 있나요?

네! 슬래시 명령어 대신 자연어로 말해도 u-maker가 알아서 적절한 에이전트로 라우팅합니다:

```
"로그인 기능을 추가하고 싶어"     → RA/SA 에이전트가 문서 작성
"ERD를 PostgreSQL로 최적화해줘"  → SA 에이전트가 ERD 수정
"테스트 케이스를 보강해줘"        → QA 에이전트가 TC 추가
```

---

## 다음 단계

기본적인 사용법을 익혔다면, 이제 더 깊이 활용해보세요:

- `/u-skill-help` — 전체 명령어 상세 도움말
- `/u-skill-report` — 프로젝트 현황을 한눈에 보는 종합 보고서
- `/u-skill-ux-figma` — pencil.dev로 시각적 화면 디자인
- `/u-skill-gap-detector` — 설계와 구현의 일치율 분석
- `/u-skill-git-pr` — 변경사항을 feature별로 정리해서 GitHub PR 생성

궁금한 점이 있으면 언제든 자연어로 물어보세요. u-maker가 적절한 에이전트에게 전달해드립니다.
