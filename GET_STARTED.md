# u-maker 시작하기 (Get Started)

u-maker를 처음 사용하시나요? 이 가이드는 핵심 개념부터 역할별 활용법, 실전 시나리오까지 단계별로 안내합니다.

> 전체 레퍼런스는 [README.md](README.md)를 참고하세요.

---

## Part 1. u-maker란?

### 한 줄 요약

u-maker는 **4개의 AI 에이전트**와 **3-Layer 파이프라인**으로 소프트웨어 개발의 전 과정(기획 → 설계 → 구현 → 검증 → 개선)을 자동화하는 **Claude Code 플러그인**입니다.

### 기존 개발 방식과 뭐가 다른가요?

| | 기존 방식 | u-maker 방식 |
|---|----------|-------------|
| **문서** | 코드 먼저, 문서는 나중에 (혹은 안 씀) | 문서 먼저, 코드는 문서를 기반으로 생성 (Docs-First) |
| **데이터 분석** | RFP 200페이지를 한 번에 분석 → 앞부분 loss | 3-Layer 파이프라인으로 chunk 분석 → 정보 손실 없음 |
| **요구사항 추적** | 스프레드시트에 따로 관리, 코드와 연결 안 됨 | 4-Tier ID(USR→FR→US→FT)로 요구사항~코드~테스트 전 구간 자동 추적 |
| **품질 관리** | 개발 완료 후 QA팀에 전달, 수동 테스트 | 매 Phase마다 Gate 조건 자동 검증 |
| **설계 변경** | SRS 수정하면 ERD, Screen, TC를 수동 갱신 | `_links.json` 의존성 그래프로 Auto-Cascade 전파 |
| **AI 판단** | AI가 뭔가 결정해도 블랙박스 | Assumptions Log로 모든 판단 기록 + 사후 리뷰 |
| **협업** | 각 역할자가 개별 도구로 작업 | 4개 AI 에이전트가 하나의 SSoT 문서 체계에서 협업 |

### 핵심 개념 5가지

#### 1. SSoT (Single Source of Truth) — "문서가 곧 진실"

u-maker에서는 **모든 결정이 문서에 기록**됩니다. 요구사항, 설계, 구현, 테스트 결과가 모두 `.u-maker/` 아래 관리됩니다.

- 코드를 먼저 작성하려 하면 **Docs-First Guard**가 막고, 문서를 먼저 쓰라고 안내합니다
- 문서는 `.md`(사람이 읽는 원본) + `.json`(기계가 파싱하는 데이터) 2종이 항상 함께 생성됩니다

#### 2. 3-Layer 파이프라인 — "Raw → 정제 → 산출물"

```
_input/          →      _classified/        →      docs/
(RFP, 회의록,         (requirements,              (srs.md, erd.md,
 AS-IS 분석, ...)      pain-points,                api.md, screen.md, ...)
                        domain-terms, ...)
```

| Layer | 위치 | 역할 |
|-------|------|------|
| **Layer 1: Raw** | `_input/` | 원본 데이터 (RFP, 회의록, AS-IS 분석, 스크린샷 등) |
| **Layer 2: Classified** | `_classified/` | 원본에서 추출·정제된 구조화 데이터 (10개 카테고리) |
| **Layer 3: Docs** | `docs/` | 최종 산출물 (SRS, ERD, API, Screen, TestCase 등) |

10개 분류 카테고리:
`requirements` · `pain-points` · `domain-terms` · `stakeholders` · `workflows` · `screens` · `data-models` · `constraints` · `decisions` · `questions`

#### 3. PDCA 5-Phase — "계획→설계→구현→검증→개선 반복"

```
Plan (기획) → Design (설계) → Do (구현) → Check (검증) → Act (개선)
                                                              ↓
                                                     다음 Iteration으로
```

소프트웨어를 한 번에 완벽하게 만드는 것이 아니라, **반복적으로 개선**합니다.
각 Phase를 넘어가려면 **Gate 조건**을 충족해야 합니다:

| Phase 전환 | 통과 조건 |
|------------|-----------|
| Plan → Design | SRS + IA + Roadmap = Final |
| Design → Do | ERD + RTM + Screen + API = Final |
| Do → Check | Code 문서 Final |
| Check → Act | Test Cases + Test Report = Final |

> 4-Phase 옵션도 지원합니다. `u-maker.config.json`에서 `designPhase: "merged"`로 설정하면 Design이 Do에 통합됩니다.

#### 4. 4-Tier ID 체계 — "왜 이 코드가 존재하는지 추적"

```
USR-0001 (사용자 유형: 예) 관리자, 일반 사용자)
  └── FR-0001 (기능 요구사항: 예) 회원가입 기능)
        └── US-0001 (유저 스토리: 예) 이메일로 회원가입하고 싶다)
              └── FT-0001 (Feature = 구현 단위: 예) 이메일 인증 구현)
```

> FT는 **Feature**(구현 단위)의 약어입니다. ~~Functional Test~~가 아닙니다.

"이 코드가 왜 존재하는지"를 FT → US → FR → USR로 항상 추적할 수 있습니다.

#### 5. Assumptions Log — "AI가 판단한 이유를 기록"

u-maker의 에이전트가 정보가 부족할 때 **추정(assumption)**을 기록합니다.

```
A-001: "결제 수단은 신용카드만 지원한다고 가정" (confidence: 0.7)
  → approve: 가정 확정
  → reject: 가정 철회 + 영향받은 문서 cascade 수정
```

- `/u-status --assumptions`로 미리뷰 가능
- `/u-assume approve A-001`로 승인, `/u-assume reject A-001`로 거부
- `maxAssumptions` (기본 20) 초과 시 자동으로 interactive 모드 전환

### AI 팀 구성 (4개 에이전트)

v2에서는 8개 전문 에이전트를 4개로 통합하여 더 효율적으로 협업합니다.

| 에이전트 | 역할 | 하는 일 | 모델 |
|----------|------|---------|------|
| **Orchestrator** | 지휘자 | 라우팅, 스코프 해석, 워크플로우 조율, 상태 관리 | opus |
| **Planner** | 설계자 | SRS, IA, ERD, API, Screen, 문서 CRUD, 분석, 추정 | sonnet |
| **Builder** | 개발자 | FE+BE 코드 생성, 스캐폴딩, 빌드 | sonnet |
| **Guardian** | 검증자 | Gate 검증, TC 설계/실행, 일관성 검증, 리포트 | sonnet |

---

## Part 2. 설치 & 첫 실행

### 필요한 것들

| 도구 | 용도 | 필수 |
|------|------|------|
| **Claude Code** | u-maker가 동작하는 기반 도구 | Yes |
| **Node.js** | 내부 스크립트(Hook, Guard 등) 실행 | Yes |

### 설치

#### 방법 A: 원클릭 설치 (권장)

터미널에서 한 줄만 실행하면 최신 버전이 자동으로 설치됩니다.

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.bat -OutFile install.bat; .\install.bat; Remove-Item install.bat
```

이 스크립트가 자동으로:
- 기존 u-maker 설치가 있으면 완전 삭제합니다 (캐시, symlink, 레지스트리)
- GitHub에서 최신 릴리스 zip을 다운로드합니다
- 플러그인을 새로 설치합니다 (deploy_local.sh 실행)
- 임시 파일을 정리합니다

```bash
# 특정 버전 설치
./install.sh --version 2.0.0

# 제거
./install.sh --uninstall
```

> 설치 후 반드시 **Claude Code를 재시작**해주세요.

### 업데이트

이미 설치된 u-maker를 최신 버전으로 업데이트합니다.

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/update.sh | bash

# 특정 버전으로 업데이트
./update.sh --version 2.1.0

# 현재 vs 최신 버전 확인
./update.sh --check
```

> 업데이트 시 삭제되는 것: 플러그인 캐시, symlink, 레지스트리 (u-maker만 해당)
> 영향 없는 것: 프로젝트의 `.u-maker/` SSoT 문서

> 업데이트 후 반드시 **Claude Code를 재시작**해주세요.

#### 방법 B: 소스코드에서 로컬 설치

소스코드를 직접 클론해서 로컬에 설치하는 방법입니다. (개발자용)

```bash
cd /path/to/u-maker-plugin
./deploy_local.sh
```

```bash
./deploy_local.sh --check   # 설치 상태 확인
./deploy_local.sh --clean   # 완전 제거
```

> 설치 후 반드시 **Claude Code를 재시작**해주세요.

---

## Part 3. 프로젝트 시작하기

### 3.1 새 프로젝트 초기화

```bash
/u-init my-project
```

이 명령어가 하는 일:
1. `.u-maker/` 디렉토리 생성 (config, common/, apps/)
2. `u-maker.config.json` 초기화 (프로젝트명, 기술 스택, 앱 목록)
3. 첫 번째 앱 등록 (예: `retail`)
4. 3-Layer 파이프라인 구조 생성 (`_input/`, `_classified/`, `docs/`)
5. `_index.json`, `_links.json` 초기화

### 3.2 기존 자료가 있는 경우 — 데이터 수집

RFP, 회의록, AS-IS 분석 자료 등이 있다면:

```bash
# 1. _input/ 폴더에 원본 파일을 복사합니다
#    .u-maker/apps/retail/_input/rfp/
#    .u-maker/apps/retail/_input/meeting-notes/
#    .u-maker/apps/retail/_input/as-is/

# 2. 분석 적재 (Raw → Classified)
/u-ingest retail
```

`/u-ingest`가 원본을 chunk 단위로 분석해서 10개 카테고리로 정제합니다:

```
_input/rfp/proposal.pdf
  → _classified/requirements/REQ-001.json   (기능 요구사항)
  → _classified/pain-points/PP-001.json     (고객 불만)
  → _classified/domain-terms/DT-001.json    (도메인 용어)
  → _classified/stakeholders/SH-001.json    (이해관계자)
  → ...
```

### 3.3 기획 → 산출물 생성

```bash
/u-plan retail           # Plan Phase 전체: SRS + IA + Roadmap 자동 생성
```

### 3.4 전체 자동 실행 (가장 쉬운 시작)

```bash
/u-plan retail           # 기획
/u-design retail         # 설계
/u-build retail          # 구현
/u-check retail          # 검증
/u-ship retail           # 배포 + 회고
```

또는 자연어로:

```
"retail 앱의 SRS를 만들어줘"           → /u-plan retail --only srs
"ERD를 PostgreSQL로 최적화해줘"       → /u-agent-planner ...
"테스트 케이스 만들어줘"               → /u-check retail
```

---

## Part 4. Interaction Mode — 작업 방식 선택

u-maker는 3가지 작업 모드를 제공합니다. 상황에 맞게 선택하세요.

### auto 모드 (기본)

```bash
/u-plan retail           # 아무 플래그 없으면 auto
```

- 에이전트가 **최선의 추측(best-guess)**으로 자동 진행
- 판단이 필요하면 **Assumptions Log**에 기록하고 넘어감
- 빠르지만, 나중에 `/u-assume`으로 가정을 리뷰해야 함

**이런 때 사용하세요:**
- 빠르게 초안을 뽑고 싶을 때
- 전체 흐름을 한번 돌려보고 싶을 때
- 잘 알려진 도메인(쇼핑몰, 게시판 등)을 만들 때

### interactive 모드 (-i)

```bash
/u-plan retail -i        # interactive 모드
```

- 주요 분기점(요구사항 우선순위, 기술 선택 등)에서 **사용자에게 질문**
- 가정(assumption)을 만들지 않음
- 느리지만 정확함

**이런 때 사용하세요:**
- 도메인 지식이 특수해서 AI가 추정하면 안 될 때
- 최초 프로젝트 세팅 시
- 중요한 설계 결정이 포함된 Phase

### step 모드 (--step)

```bash
/u-plan retail --step    # step 모드
```

- **매 문서 생성 전/후**에 확인 요청
- 가장 느리지만 가장 세밀한 제어

**이런 때 사용하세요:**
- 학습 목적으로 u-maker의 과정을 이해하고 싶을 때
- 특정 문서만 생성을 건너뛰고 싶을 때
- 각 산출물의 품질을 하나씩 확인하고 싶을 때

---

## Part 5. 역할별 활용 가이드

### 기획자 (PM / 요구사항 분석가)

프로젝트를 기획하고 요구사항을 정의하는 역할입니다.

#### 주요 시나리오

**데이터 수집 & 분석:**
```bash
# _input/에 RFP, 회의록 등을 넣고
/u-ingest retail                          # Raw → Classified 분석 적재
/u-ingest retail --review                 # 분석 결과 리뷰
/u-ingest retail --incremental            # 신규분만 추가 분석
```

**Plan Phase 실행:**
```bash
/u-plan retail                            # Plan Phase 전체 (SRS + IA + Roadmap)
/u-plan retail --only srs                 # SRS만 생성
/u-plan retail -i                         # interactive 모드로 같이 보면서 진행
/u-plan common                            # 공통 정책 문서 생성
```

**요구사항 추가/관리:**
```bash
/u-add retail fr "비밀번호 재설정"          # 기능 요구사항 추가
/u-add retail us "비밀번호 재설정하고 싶다"   # 유저 스토리 추가
```

**프로젝트 상태 파악:**
```bash
/u-status                                 # 전체 프로젝트 대시보드
/u-status retail                          # 특정 앱 상태
/u-status retail --assumptions            # 미리뷰 assumptions 확인
/u-doc retail srs                         # 특정 문서 조회
```

**브레인스토밍 & 협업:**
```bash
/u-discuss retail brainstorm "결제 UX"     # 아이디어 발산 세션
/u-discuss common decision "인증 방식"      # 기술 결정 세션
```

**에이전트에게 직접 요청:**
```bash
/u-agent-planner "마일스톤 3의 진행 상황을 정리해줘"
/u-agent-orchestrator "retail 앱의 전체 현황을 요약해줘"
```

#### 기획자가 꼭 알아야 할 것

- u-maker는 **Docs-First** 원칙입니다. 새 기능을 코드로 바로 구현하려 하면 Hook이 차단합니다
- `/u-add`로 문서를 먼저 추가한 후 구현을 진행하세요
- Plan Phase의 Gate 조건: SRS + IA + Roadmap이 모두 **Final** 상태여야 Design으로 넘어감
- auto 모드 사용 시 반드시 `/u-assume`로 assumptions를 리뷰하세요

---

### 디자이너 (UX / 화면 설계)

화면 구조 설계, ERD, API 설계를 담당합니다.

#### 주요 시나리오

**Design Phase 전체 실행:**
```bash
/u-design retail                          # ERD + API + Screen + Flow 전체
/u-design retail --only screens           # Screen 관련만 생성
/u-design retail -i                       # interactive 모드
```

**개별 설계 작업:**
```bash
/u-design retail --only erd               # ERD만 생성
/u-design retail --only api               # API Contract만 생성
```

**IA 워크숍:**
```bash
/u-discuss retail workshop "메인 IA"       # 다단계 IA 워크숍
```

**일관성 검증:**
```bash
/u-sync retail                            # SRS ↔ Screen ↔ ERD ↔ API 일관성 검증
```

**에이전트에게 직접 요청:**
```bash
/u-agent-planner "로그인 화면에 소셜 로그인 버튼을 넣어줘"
/u-agent-planner "대시보드 화면의 레이아웃을 2컬럼으로 변경해줘"
```

#### 생성되는 문서

| 문서 | 위치 | 설명 |
|------|------|------|
| ERD | `apps/{app}/docs/02-design/erd.md` | 데이터 모델 설계 |
| API Contract | `apps/{app}/docs/02-design/api.md` | OpenAPI 3.0 기반 API 설계 |
| Screen | `apps/{app}/docs/02-design/screen.md` | 화면별 상세 설계 |
| Screen Flow | `apps/{app}/docs/02-design/screen-flow.md` | 화면 간 흐름도 |
| UX Guide | `common/ux/ux-guide.md` | UX 표준 가이드 (common에서 상속) |
| RTM | `apps/{app}/rtm.md` | 요구사항 추적 매트릭스 |

#### 디자이너가 꼭 알아야 할 것

- 화면 설계는 `IA → Screen → Screen Flow` 순서로 진행됩니다
- 시각 디자인 도구는 `u-maker.config.json`의 `designTool` 설정에 따라 pencil.dev, Figma, Stitch 중 선택됩니다
- Design Phase Gate 조건: ERD + RTM + Screen + API = Final

---

### 개발자 (Frontend / Backend)

설계 문서를 기반으로 코드를 구현합니다.

#### 주요 시나리오

**코드 생성:**
```bash
/u-build retail                           # FE + BE 코드 동시 생성
/u-build retail --only fe                 # Frontend만 생성
/u-build retail --only be                 # Backend만 생성
```

**에이전트에게 직접 요청:**
```bash
/u-agent-builder "로그인 페이지의 폼 유효성 검사를 추가해줘"
/u-agent-builder "User API에 프로필 이미지 업로드 엔드포인트를 추가해줘"
```

**문서 수정 + 코드 반영:**
```bash
/u-update retail srs --cascade            # SRS 수정 + 하위 문서(ERD, Screen, TC) 자동 갱신
```

#### 개발자가 꼭 알아야 할 것

- u-maker는 **기술 스택 규칙**을 강제합니다. `pre-write-guard.js`가 위반을 실시간 검증합니다
- 코드를 작성하기 전에 **SRS, API Contract, ERD가 Final 상태**여야 합니다
- Do Phase Gate 조건: Code 문서 Final

---

### QA (테스터)

테스트 케이스를 설계하고 실행하여 품질을 보장합니다.

#### 주요 시나리오

**Check Phase 전체 실행:**
```bash
/u-check retail                           # TC 설계 + 테스트 실행 + 결함 분석 + 리포트
/u-check retail -i                        # interactive 모드로 결과 확인
```

**에이전트에게 직접 요청:**
```bash
/u-agent-guardian "인증 관련 테스트 케이스를 보강해줘"
/u-agent-guardian "경계값 테스트를 추가해줘"
```

**커버리지 확인:**
```bash
/u-coverage retail                        # classified → 산출물 커버리지 분석
/u-trace retail FR-015                    # FR-015의 전체 추적 체인
```

#### QA가 꼭 알아야 할 것

- 테스트 케이스는 SRS의 **FT(Feature) 단위**로 설계됩니다
- Check Phase Gate 조건: Test Cases + Test Report = Final
- `/u-trace`로 "이 요구사항이 테스트까지 빠짐없이 연결되었는지" 확인하세요

---

## Part 6. 명령어 치트시트

### CLI 문법

```
/u-{command} [scope] [target] [flags]
```

- **scope**: 앱 이름 (`retail`, `corporate`, `all`, `common`)
- **target**: 문서/항목 (`srs`, `erd`, `fr`, `us`, `FR-001` 등)
- **flags**: 동작 변경 (`-i`, `--step`, `--only`, `--cascade`, `--incremental`)

### Lifecycle Commands (7개) — Phase별 실행

| 명령어 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/u-init` | 프로젝트 초기화, .u-maker/ 생성 | `/u-init my-project` |
| `/u-ingest` | Raw 데이터 → Classified 분석 적재 | `/u-ingest retail` |
| `/u-plan` | Plan Phase: SRS + IA + Roadmap | `/u-plan retail -i` |
| `/u-design` | Design Phase: ERD + API + Screen + Flow | `/u-design retail --only erd` |
| `/u-build` | Do Phase: FE + BE 코드 생성 | `/u-build retail --only fe` |
| `/u-check` | Check Phase: TC 설계 + 테스트 + 리포트 | `/u-check retail` |
| `/u-ship` | Act Phase: 최종 검증 + 회고 | `/u-ship retail` |

### Operations Commands (5개) — 일상 작업

| 명령어 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/u-add` | 항목 추가 (FR/US/Screen 등) | `/u-add retail fr "회원가입"` |
| `/u-update` | 문서 수정 + cascade 전파 | `/u-update retail srs --cascade` |
| `/u-doc` | 문서 조회/편집/재생성 | `/u-doc retail screens` |
| `/u-sync` | 전체 문서 일관성 검증 + 수정 제안 | `/u-sync retail` |
| `/u-gate` | Phase Gate 검사 + 전환 | `/u-gate retail` |

### Observability Commands (3개) — 현황 파악

| 명령어 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/u-status` | 대시보드 (phase, 진행률, impact flags) | `/u-status retail` |
| `/u-coverage` | classified → 산출물 커버리지 | `/u-coverage all` |
| `/u-trace` | raw → classified → docs 추적 체인 | `/u-trace retail FR-015` |

### Collaboration & Review (2개)

| 명령어 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/u-discuss` | 구조화된 협업 세션 | `/u-discuss retail brainstorm "결제 UX"` |
| `/u-assume` | Assumptions 리뷰 (approve/reject) | `/u-assume retail approve A-001` |

### Agent Direct (4개) — 에이전트 직접 호출

| 명령어 | 에이전트 | 사용 예시 |
|--------|----------|-----------|
| `/u-agent-orchestrator` | Orchestrator | `/u-agent-orchestrator "전체 현황 요약"` |
| `/u-agent-planner` | Planner | `/u-agent-planner "ERD에 프로필 이미지 필드 추가"` |
| `/u-agent-builder` | Builder | `/u-agent-builder "로그인 폼 유효성 검사"` |
| `/u-agent-guardian` | Guardian | `/u-agent-guardian "경계값 TC 보강"` |

### 자연어 라우터

명령어를 모르겠으면 자연어로 말해도 됩니다. `u-maker` 라우터가 자동으로 적절한 명령어로 변환합니다.

```
"retail 앱의 SRS를 만들어줘"           → /u-plan retail --only srs
"ERD를 PostgreSQL로 최적화해줘"       → /u-agent-planner ...
"테스트 케이스 만들어줘"               → /u-check retail
"지금 프로젝트 상태가 어때?"           → /u-status
```

---

## Part 7. /u-discuss 협업 세션

### 세션 타입 5가지

| 타입 | 용도 | 명령어 |
|------|------|--------|
| **brainstorm** | 아이디어 발산, 자유 토론 | `/u-discuss retail brainstorm "결제 UX"` |
| **review** | 산출물 검토 | `/u-discuss retail review` |
| **decision** | 기술/비즈니스 의사결정 | `/u-discuss common decision "DB 선택"` |
| **workshop** | 다단계 작업 (설계 워크숍 등) | `/u-discuss retail workshop "메인 화면 설계"` |
| **retro** | Iteration 회고 | `/u-discuss retail retro` |

### 세션 중 micro-commands

세션 진행 중 다음 명령어를 사용할 수 있습니다:

| 명령어 | 설명 |
|--------|------|
| `@planner` / `@builder` / `@guardian` | 특정 에이전트에게 질문 |
| `@all` | 모든 에이전트에게 의견 요청 |
| `/idea [text]` | 아이디어 태깅 (→ `_classified/` 적재) |
| `/decide [text]` | 결정사항 기록 (→ `_classified/decisions/`) |
| `/concern [text]` | 우려/리스크 기록 (→ `_classified/constraints/`) |
| `/action [who] [text]` | 액션 아이템 기록 |
| `/wrap` | 세션 종료 + 태그된 항목 자동 분류 적재 |

### 예시: 결제 UX 브레인스토밍

```
/u-discuss retail brainstorm "결제 UX"

> @planner 현재 결제 플로우에서 이탈률이 높은 구간은?
> /idea 원스텝 결제 (장바구니 → 바로 결제)
> /idea 게스트 결제 (비회원 결제 허용)
> @guardian 게스트 결제의 보안 리스크는?
> /concern PCI-DSS 컴플라이언스 확인 필요
> /decide 1단계에서는 회원 결제만, 2단계에서 게스트 결제 추가
> /wrap
```

세션 종료 후:
- `/idea`로 태그된 항목 → `_classified/requirements/`
- `/decide`로 태그된 항목 → `_classified/decisions/`
- `/concern`으로 태그된 항목 → `_classified/constraints/`

---

## Part 8. 실전 시나리오 모음

### Scenario 1: 새 프로젝트를 처음부터 끝까지

```bash
/u-init my-saas                           # 1. 프로젝트 초기화
# → _input/에 RFP, 회의록 파일 복사
/u-ingest retail                          # 2. 데이터 분석 적재
/u-plan retail -i                         # 3. 기획 (interactive로 같이 진행)
/u-gate retail                            # 4. Gate 검증 → Design 전환
/u-design retail                          # 5. 설계
/u-gate retail                            # 6. Gate 검증 → Do 전환
/u-build retail                           # 7. 코드 생성
/u-gate retail                            # 8. Gate 검증 → Check 전환
/u-check retail                           # 9. 테스트
/u-ship retail                            # 10. 배포 + 회고
```

### Scenario 2: 기존 프로젝트에 u-maker 적용

```bash
/u-init .                                 # 기존 프로젝트 인식
# → _input/에 기존 문서/코드 분석 자료 배치
/u-ingest retail                          # 기존 자료 분석
/u-status                                 # 생성된 문서 상태 확인
/u-sync retail                            # 일관성 검증
```

### Scenario 3: 요구사항 변경이 왔을 때

```bash
# 고객이 "비밀번호 재설정 기능"을 추가 요청
/u-add retail fr "비밀번호 재설정"          # 1. FR 추가
/u-add retail us "비밀번호 재설정하고 싶다"   # 2. US 추가
/u-update retail srs --cascade            # 3. SRS 수정 → ERD/Screen/TC auto-cascade
/u-status retail                          # 4. impact flags 확인
```

### Scenario 4: SRS 수정 후 영향 파악

```bash
# SRS를 수정하면 hook이 자동으로 cascade 알림:
# [u-maker] CASCADE: srs.md was modified. Impacted documents:
#   - erd [MUST-UPDATE] (derives)
#   - screen [MUST-UPDATE] (derives)
#   - test-cases [REVIEW-NEEDED] (validates)

/u-sync retail                            # 일관성 검증 + 수정 제안
# 또는
/u-update retail --cascade                # 의존 문서 자동 갱신
```

### Scenario 5: Phase Gate가 통과 안 될 때

```bash
/u-gate retail
# → "Plan Gate FAILED: srs (Final), ia (Draft), roadmap (missing)"

/u-plan retail --only ia                  # IA만 생성
/u-doc retail ia                          # IA 문서 확인/편집
/u-gate retail                            # 다시 검증
```

### Scenario 6: Assumptions 리뷰

```bash
/u-status retail --assumptions
# A-001: "결제 수단은 신용카드만 지원" (confidence: 0.7)
# A-002: "회원가입은 이메일만" (confidence: 0.9)

/u-assume retail approve A-002            # 이메일만 → 확정
/u-assume retail reject A-001 "전체취소만"  # 신용카드만 → 거부 (cascade 수정)
```

### Scenario 7: 멀티 앱 프로젝트

```bash
/u-init my-platform                       # 프로젝트 초기화
# u-maker.config.json에서 apps: ["retail", "admin", "api"] 설정

/u-plan common                            # 공통 정책 먼저 생성
/u-plan retail                            # retail 앱 기획
/u-plan admin                             # admin 앱 기획
/u-design retail,admin -i                 # 2개 앱 동시 설계 (interactive)
/u-sync all                               # 전체 앱 일관성 검증
/u-coverage all                           # 전체 커버리지 확인
```

---

## Part 9. 폴더 구조 이해하기

### .u-maker/ 프로젝트 구조

```
.u-maker/
├── u-maker.config.json              # 전역 설정
├── _links.json                       # 의존성 그래프
│
├── common/                           # 프로젝트 공통 (모든 앱이 상속)
│   ├── _index.json
│   ├── policy/                       # 서비스/보안/개인정보/에러코드/용어
│   ├── ux/                           # UX Guide, Design Token, UI Components
│   ├── dev/                          # Coding Convention, Git Strategy
│   ├── architecture/                 # System Overview, ERD, API
│   └── project/                      # Roadmap, Stakeholders
│
├── apps/{app-name}/                  # 앱별 독립 파이프라인
│   ├── _index.json                   # 문서 목차 + 상태
│   ├── app.config.json               # 앱별 설정 (inherit + override)
│   ├── _input/                       # Layer 1: Raw data
│   │   ├── rfp/
│   │   ├── as-is/
│   │   └── meeting-notes/
│   ├── _classified/                  # Layer 2: 정제 데이터
│   │   ├── requirements/
│   │   ├── pain-points/
│   │   ├── domain-terms/
│   │   └── ... (10개 카테고리)
│   ├── _sessions/                    # 토론 세션 아카이브
│   ├── _assumptions/                 # 가정 로그
│   └── docs/                         # Layer 3: 산출물
│       ├── 01-plan/                  # srs.md, ia.md, roadmap.md
│       ├── 02-design/               # erd.md, api.md, screen.md
│       ├── 03-dev/                  # code.md
│       └── 04-check/               # test-cases.md, test-report.md
│
├── _input/                           # 프로젝트 공통 raw data
├── _classified/                      # 공통 classified
├── _sessions/                        # cross-app 토론
└── _assumptions/                     # cross-app assumptions
```

### Scope-First Navigation

Claude는 파일을 직접 열지 않고 **`_index.json`만 먼저 읽어서** 필요한 파일만 선택적 로드합니다. 이렇게 하면 context window를 절약할 수 있습니다.

---

## Part 10. Auto-Cascade — 문서 변경 자동 전파

u-maker의 핵심 기능 중 하나입니다. 문서 간 의존 관계가 `_links.json`에 기록되어 있어, 상위 문서가 변경되면 하위 문서에 자동으로 영향을 알립니다.

### 의존성 예시

```
SRS 변경 → ERD [MUST-UPDATE]
         → Screen [MUST-UPDATE]
         → Test Cases [REVIEW-NEEDED]
         → Roadmap [INFO]
```

### 영향도 레벨

| 레벨 | 의미 | 조치 |
|------|------|------|
| **MUST-UPDATE** | 강한 의존, 반드시 갱신 필요 | `/u-update --cascade`로 자동 갱신 |
| **REVIEW-NEEDED** | 확인 필요 | `/u-sync`로 검증 후 판단 |
| **INFO** | 참고 사항 | 필요 시 수동 확인 |

SRS를 수정하면 `on-doc-change.js` hook이 자동으로:
```
[u-maker] CASCADE: srs.md was modified. Impacted documents:
  - erd [MUST-UPDATE] (derives)
  - screen [MUST-UPDATE] (derives)
  - test-cases [REVIEW-NEEDED] (validates)
```

---

## Part 11. Hook & Guard 시스템

u-maker는 Hook을 통해 작업 품질을 자동으로 보장합니다.

| Hook | 동작 | 당신에게 미치는 영향 |
|------|------|---------------------|
| **Docs-First Guard** | 새 기능 감지 시 문서 수정 먼저 요구 | "코드 작성하려면 `/u-add`로 문서 먼저 추가하세요" |
| **Pre-Write Guard** | SSoT 문서 경로 + tech stack 위반 검증 | 잘못된 경로/기술 사용 시 차단 |
| **Post-Write Index** | 문서 작성 후 `_index.json` 갱신 알림 | 자동 처리됨 |
| **Input Added** | `_input/` 파일 감지 → `/u-ingest` 제안 | "새 파일이 감지되었습니다. `/u-ingest`를 실행하세요" |
| **Doc Change** | 문서 변경 → cascade impact 알림 | "SRS가 변경됨 → ERD, Screen 갱신 필요" |
| **Gate Pass** | Gate 조건 충족 시 phase 전환 제안 | "모든 조건 충족! `/u-gate`로 전환하세요" |
| **Session Wrap** | 세션 완료 → classified 적재 알림 | "태그된 항목을 분류하세요" |
| **Stop State** | 세션 종료 시 상태 저장 | 자동 처리됨 |

> Hook은 **사용자를 돕기 위한 가이드**입니다. 차단이 아니라 올바른 방향을 안내합니다.

---

## Part 12. 자주 묻는 질문 (FAQ)

### Q: 명령어가 인식되지 않아요

A: Claude Code를 재시작해보세요. 재시작 후에도 안 되면 `./deploy_local.sh --check`로 설치 상태를 확인하세요.

### Q: 어떤 명령어를 써야 할지 모르겠어요

A: 자연어로 말해보세요. "retail 앱의 SRS를 만들어줘"처럼 자연어를 입력하면 u-maker 라우터가 적절한 명령어로 변환합니다.

### Q: Hook이 계속 차단해요

A: Docs-First 원칙입니다. 코드를 작성하기 전에 `/u-add`로 요구사항 문서를 먼저 추가하세요.

### Q: auto 모드에서 자꾸 interactive로 전환돼요

A: `maxAssumptions` (기본 20)이 초과되었습니다. `/u-assume`로 쌓인 assumptions를 리뷰(approve/reject)하면 다시 auto 모드로 돌아갑니다.

### Q: cascade 알림이 너무 많아요

A: `/u-sync`로 한 번에 정리하거나, `/u-update --cascade`로 의존 문서를 자동 갱신하세요.

### Q: scope를 잘못 지정했어요

A: `u-maker.config.json`의 `apps[]` 배열에 앱이 등록되어 있는지 확인하세요. 등록되지 않은 앱 이름은 인식되지 않습니다.

### Q: v1에서 v2로 마이그레이션하려면?

A: v2는 새로운 폴더 구조(`.u-maker/apps/`)와 문서 이름(예: `srs.md`)을 사용합니다. v1 프로젝트는 `/u-init`으로 새로 초기화한 후 기존 문서를 `_input/`에 넣고 `/u-ingest`로 분석하는 것을 권장합니다.

---

## Part 13. 다음 단계

u-maker에 익숙해졌다면:

1. **README.md**: 전체 아키텍처, 엔진 스킬, 스키마 등 상세 레퍼런스
2. **`shared/references/`**: 18개 참조 문서 (PDCA 워크플로우, cascade 규칙, interaction modes 등)
3. **`templates/`**: 72개 문서 템플릿 (phase별, classified, config, session, common)
4. **`schemas/`**: 7개 JSON Schema (문서 구조 정의)

---

## License

MIT
