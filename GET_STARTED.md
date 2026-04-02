# U-MAKER 시작하기 (Get Started)

U-MAKER를 처음 사용하시나요? 이 가이드는 핵심 개념부터 전체 명령어, 실전 시나리오까지 단계별로 안내합니다.

> 전체 레퍼런스는 [README.md](README.md)를 참고하세요.

---

## Part 1. U-MAKER란?

### 한 줄 요약

U-MAKER는 **4개의 AI 에이전트**와 **3-Layer 파이프라인**으로 소프트웨어 개발의 전 과정(기획 → 설계 → 구현 → 검증 → 개선)을 자동화하는 **Claude Code 플러그인**입니다.

### 기존 개발 방식과 뭐가 다른가요?

| | 기존 방식 | U-MAKER 방식 |
|---|----------|-------------|
| **문서** | 코드 먼저, 문서는 나중에 | 문서 먼저, 코드는 문서 기반 생성 (Docs-First) |
| **기존 프로젝트** | 문서 없이 코드만 존재 | `/u-reverse`로 코드에서 SSoT 역공학 |
| **데이터 분석** | 200페이지 RFP를 한 번에 분석 → loss | 3-Layer 파이프라인으로 chunk 분석 → 손실 없음 |
| **요구사항 추적** | 스프레드시트 수동 관리 | 4-Tier ID(USR→FR→US→FT)로 자동 추적 |
| **설계 변경** | SRS 수정 시 ERD/Screen/TC 수동 갱신 | Auto-Cascade 자동 전파 |
| **품질 관리** | 개발 후 수동 QA | Phase Gate 자동 검증 |
| **AI 판단** | 블랙박스 | Assumptions Log로 모든 판단 기록 |
| **문서 언어** | 고정 | `language.documents` 설정 (ko/en/ja/zh) |

### 핵심 개념 5가지

#### 1. SSoT (Single Source of Truth)

모든 결정이 `.u-maker/` 아래 문서에 기록됩니다. `.md`(사람용) + `.json`(기계용) 2종이 항상 함께 생성됩니다.

#### 2. 3-Layer 파이프라인

```
_input/          →      _classified/        →      docs/
(RFP, 회의록,         (requirements,              (srs.md, erd.md,
 AS-IS 분석, ...)      pain-points, ...)           api.md, screen.md, ...)
```

`.u-maker/_dropzone/`에 파일을 넣으면 `/u-ingest` 실행 시 자동으로 `rfp/`, `as-is/` 등으로 분류합니다. (`_input/raw/`도 fallback으로 지원)

#### 3. PDCA 5-Phase

```
Plan → Design → Do → Check → Act → 다음 Iteration
```

| Phase 전환 | Gate 조건 |
|------------|-----------|
| Plan → Design | SRS + IA + Roadmap = Final |
| Design → Do | ERD + RTM + Screen + API = Final |
| Do → Check | Code 문서 Final |
| Check → Act | Test Cases + Test Report = Final |

#### 4. 4-Tier ID 체계

```
USR-0001 (사용자 유형)
  └── FR-0001 (기능 요구사항)
        └── US-0001 (유저 스토리)
              └── FT-0001 (Feature = 구현 단위)
```

#### 5. Assumptions Log

AI가 정보 부족 시 추정한 내용을 기록. `/u-assume approve/reject`로 리뷰.

### AI 팀 구성 (4개 에이전트)

| 에이전트 | 역할 | 모델 |
|----------|------|------|
| **Orchestrator** | 라우팅, 워크플로우 조율, 상태 관리 | opus |
| **Planner** | SRS, IA, ERD, API, Screen, 분석 | sonnet |
| **Builder** | FE+BE 코드 생성, 빌드 | sonnet |
| **Gatekeeper** | Gate 검증, TC 설계/실행, 일관성 검증 | sonnet |

---

## Part 2. 설치

### 원클릭 설치

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.sh | bash
```

**Windows (CMD / PowerShell):**
```cmd
curl -fsSL --ssl-no-revoke https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.bat -o install.bat && install.bat && del install.bat
```

### 업데이트

```bash
curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/update.sh | bash
```

> 설치/업데이트 후 반드시 **Claude Code를 재시작**해주세요.

---

## Part 3. 프로젝트 시작하기

### 3.1 Forward Engineering — 새 프로젝트

```bash
# 1. 프로젝트 초기화
/u-init my-saas

# 2. .u-maker/_dropzone/에 RFP, 회의록, AS-IS 자료 드롭
#    → /u-ingest가 자동으로 분류하여 .u-maker/_input/rfp/, as-is/, meeting-notes/ 등으로 이동

# 3. 데이터 분석
/u-ingest [app]

# 4. 전체 파이프라인 실행
/u-plan [app]            # SRS + IA + Roadmap
/u-gate [app]            # Gate 검증 → Design 전환
/u-design [app]          # ERD + API + Screen + Flow + RTM
/u-gate [app]            # Gate 검증 → Do 전환
/u-dev [app]             # FE + BE + DB 코드 생성
/u-gate [app]            # Gate 검증 → Check 전환
/u-qa [app]              # TC + 테스트 + 리포트
/u-ship [app]            # 최종 검증 + 회고
```

### 3.2 Reverse Engineering — 기존 프로젝트

이미 코드가 있지만 SSoT 문서가 없는 프로젝트:

```bash
# 1. 프로젝트 초기화
/u-init my-existing-app

# 2. 소스 코드 → SSoT 역공학
/u-reverse [app]                    # ERD, API, Screen, IA, SRS 전체 역추출
/u-reverse [app] --only erd         # ERD만 추출
/u-reverse [app] --only api         # API Contract만 추출

# 3. 역공학 결과 검증 + 보완
/u-sync [app]                       # 문서 간 정합성 검증
/u-doc [app] srs --edit             # SRS에 비즈니스 의도 보완
```

### 3.3 자연어로도 가능

```
"[app] 앱의 SRS를 만들어줘"     → /u-plan [app] --only srs
"ERD를 PostgreSQL로 최적화해줘" → planner에게 직접 전달
"테스트 케이스 만들어줘"         → /u-qa [app]
```

---

## Part 4. Interaction Mode

### auto (기본)

```bash
/u-plan [app]           # 플래그 없으면 auto
```
빠르게 진행. 판단은 Assumptions Log에 기록.

### interactive (-i)

```bash
/u-plan [app] -i        # 분기점에서 질문
```
정확하지만 느림. 중요한 설계 결정이 있을 때 사용.

### step (--step)

```bash
/u-plan [app] --step    # 매 단계 확인
```
가장 세밀한 제어. 학습 목적이나 품질 확인 시 사용.

---

## Part 5. 역할별 활용

### 기획자 (PM)

```bash
/u-ingest [app]                          # 자료 분석
/u-ingest [app] --review                 # 분석 결과 리뷰
/u-plan [app] -i                         # Plan 전체 (interactive)
/u-plan [app] --only srs                 # SRS만 생성
/u-add [app] fr "비밀번호 재설정"          # FR 추가
/u-add [app] us "비밀번호 재설정하고 싶다"   # US 추가
/u-status [app]                          # 프로젝트 상태 확인
/u-ask ERD에서 soft delete를 쓰는 이유?     # 가벼운 질문
/u-discuss [app] brainstorm "결제 UX"     # 브레인스토밍
```

### 디자이너 (UX)

```bash
/u-design [app]                          # Design 전체
/u-design [app] --only screens           # Screen만
/u-design [app] --only erd               # ERD만
/u-discuss [app] workshop "메인 IA"       # IA 워크숍
/u-sync [app]                            # 일관성 검증
```

### 개발자 (Dev)

```bash
/u-dev [app]                             # FE + BE 코드 생성
/u-dev [app] --only fe                   # Frontend만
/u-dev [app] --only be                   # Backend만
/u-dev [app] --only db                   # DB schema만
/u-reverse [app]                         # 기존 코드 → SSoT 역공학
/u-git-pr                                # PR 자동 생성
/u-git-pr --draft                        # Draft PR
/u-git-pr main --split                   # 커밋 그룹별 분할 PR
```

### QA (테스터)

```bash
/u-qa [app]                              # TC + 테스트 + 리포트
/u-qa [app] -i                           # interactive로 결과 확인
/u-coverage [app]                        # 커버리지 확인
/u-trace [app] FR-015                    # 추적 체인
```

---

## Part 6. 명령어 치트시트 (전체 23개)

### Lifecycle Commands (9)

#### `/u-init` — 프로젝트 초기화

프로젝트의 `.u-maker/` 디렉토리 전체 구조를 생성하고 초기 설정을 수행합니다. `u-maker.config.json` 파일을 생성하며, 모노레포 환경을 자동 감지하고 앱을 등록합니다. 모든 U-MAKER 워크플로우의 시작점입니다.

**생성 파일:** `.u-maker/` 디렉토리 구조, `u-maker.config.json`, `_links.json`, `_input/`, `_classified/`, `docs/` 하위 폴더

```bash
/u-init my-project                      # 새 프로젝트 초기화
/u-init .                               # 현재 디렉토리를 프로젝트로 초기화
/u-init my-platform --monorepo          # 모노레포 프로젝트 초기화
/u-init my-saas --apps web,admin        # 멀티 앱으로 초기화
```

---

#### `/u-reverse` — 소스 코드 역공학

기존 소스 코드를 분석하여 SSoT 문서를 역추출합니다. 코드베이스의 DB 스키마, API 엔드포인트, 화면 구조, 정보 아키텍처, 요구사항을 자동으로 파악하여 ERD, API, Screen, IA, SRS 문서를 생성합니다. 문서 없이 코드만 존재하는 레거시 프로젝트에 SSoT를 도입할 때 필수적입니다.

**생성 파일:** `srs.md/.json`, `ia.md/.json`, `erd.md/.json`, `api.md/.json`, `screens.md/.json` (선택한 범위에 따라)

```bash
/u-reverse [app]                        # ERD, API, Screen, IA, SRS 전체 역추출
/u-reverse [app] --only erd             # ERD만 추출
/u-reverse [app] --only api             # API Contract만 추출
/u-reverse [app] --dry-run              # 실제 생성 없이 분석 결과만 미리보기
```

---

#### `/u-ingest` — 원시 데이터 분석 및 분류

`.u-maker/_dropzone/`에 드롭된 원시 파일(RFP, 회의록, AS-IS 분석서 등)을 자동으로 파싱하여 10개 카테고리(requirements, pain-points, constraints, user-flows, data-models, integrations, non-functional, assumptions, glossary, out-of-scope)로 분류합니다. 파일은 `.u-maker/_input/{category}/`로 이동되고, 처리 후 `.u-maker/_dropzone/`는 비워집니다. 청크 기반 분석으로 대용량 문서도 손실 없이 처리하며, 분류 결과는 `_classified/`에 구조화된 JSON으로 적재됩니다. (`_input/raw/`도 fallback으로 지원)

**생성 파일:** `_classified/*.json` (카테고리별), `_input/_manifest.json`, 자동 분류된 `_input/rfp/`, `_input/as-is/`, `_input/meeting-notes/` 등

```bash
/u-ingest [app]                         # raw 데이터 전체 분석 + 분류
/u-ingest [app] --review                # 분류 결과 리뷰 (수정 가능)
/u-ingest [app] --incremental           # 신규 파일만 추가 분석
/u-ingest [app] -i                      # interactive 모드로 분류 확인
```

---

#### `/u-plan` — SRS + IA + Roadmap 생성

classified 데이터를 기반으로 Plan Phase의 핵심 문서 3종(SRS, IA, Roadmap)을 순서대로 생성합니다. SRS에서 4-Tier ID 계층(USR→FR→US→FT)을 수립하고, IA로 정보 아키텍처를 정의하며, Roadmap으로 일정과 마일스톤을 계획합니다. `--only` 플래그로 특정 문서만 개별 생성할 수 있습니다.

**생성 파일:** `01-plan/srs.md/.json`, `01-plan/ia.md/.json`, `01-plan/roadmap.md/.json`

```bash
/u-plan [app]                           # SRS + IA + Roadmap 전체 생성
/u-plan [app] -i                        # interactive 모드 (분기점에서 질문)
/u-plan [app] --only srs                # SRS만 생성
/u-plan [app] --step                    # 매 단계 확인하며 진행
```

---

#### `/u-design` — 설계 문서 통합 생성

SRS와 IA를 기반으로 Design Phase의 핵심 산출물을 연쇄 생성합니다. ERD(데이터 모델), API Contract(엔드포인트 명세), Screen(화면 정의), ScreenFlow(화면 전환), RTM(요구사항 추적 매트릭스)을 생성하며, wireframes/index.html 뷰어도 함께 만들어집니다. `--only` 플래그로 특정 문서만 생성하거나, 여러 앱을 콤마로 구분하여 동시에 설계할 수 있습니다.

**생성 파일:** `02-design/erd.md/.json`, `02-design/api.md/.json`, `02-design/screens.md/.json`, `02-design/screen-flow.md/.json`, `02-design/rtm.md/.json`, `02-design/wireframes/index.html`, `02-design/wireframes/SCR-*.html`

```bash
/u-design [app]                         # ERD + API + Screen + Flow + RTM 전체
/u-design [app] --only screens          # Screen 문서만 생성
/u-design [app] --only erd              # ERD만 생성
/u-design [app],admin -i                # 2개 앱 동시 설계 (interactive)
```

---

#### `/u-dev` — FE + BE + DB 코드 생성

설계 문서(Screen, API Contract, ERD)를 기반으로 실제 코드를 생성합니다. Screen 문서에서 프론트엔드 컴포넌트를, API Contract에서 백엔드 라우트 핸들러를, ERD에서 DB 스키마와 마이그레이션을 각각 생성하며, spec-sync 검증으로 명세와 코드의 일치를 보장합니다. Design Token이 있으면 스타일 변수도 자동 반영됩니다.

**생성 파일:** `03-dev/code.md/.json`, 프론트엔드 컴포넌트 파일, 백엔드 라우트/컨트롤러, DB 스키마/마이그레이션 파일

```bash
/u-dev [app]                            # FE + BE + DB 전체 코드 생성
/u-dev [app] --only fe                  # Frontend만 생성
/u-dev [app] --only be                  # Backend만 생성
/u-dev [app] --only db                  # DB schema만 생성
```

---

#### `/u-qa` — TC 설계 + 테스트 실행 + 리포트

SRS의 Feature(FT) 항목을 기반으로 Test Case를 자동 설계하고, Vitest/Playwright로 테스트를 실행한 후 결과 리포트를 생성합니다. 결함 발견 시 자동으로 분류(Critical/Major/Minor)하고 백로그에 등록합니다. Exit Criteria를 평가하여 Check Phase 통과 여부를 판정합니다.

**생성 파일:** `04-check/test-cases.md/.json`, `04-check/test-report.md/.json`, 백로그 결함 항목 (발견 시)

```bash
/u-qa [app]                             # TC 설계 + 테스트 실행 + 리포트
/u-qa [app] -i                          # interactive로 결과 확인하며 진행
/u-qa [app] --only design               # TC 설계만 (실행 없이)
/u-qa [app] --step                      # 매 단계 확인
```

---

#### `/u-ship` — 최종 검증 + 회고

Act Phase를 수행합니다. 전체 Phase의 Exit Criteria를 최종 평가하여 PASS이면 iteration을 아카이브하고, FAIL이면 미완료 항목을 다음 iteration으로 이월합니다. Iteration Log와 Retrospective(회고)를 생성하여 프로젝트 히스토리를 기록합니다.

**생성 파일:** iteration-log.md/.json, retrospective.md/.json, 아카이브 스냅샷

```bash
/u-ship [app]                           # 최종 검증 + 회고
/u-ship [app] --step                    # 단계별 확인하며 진행
/u-ship [app] -i                        # interactive 모드
/u-ship [app] --force                   # 미완료 항목 강제 이월 후 종료
```

---

#### `/u-loop` (`/u-pleat`) — 무인 파이프라인 실행

ingest부터 qa까지의 파이프라인을 무인(unattended)으로 연속 실행합니다. 각 Phase 종료 시 자동으로 Gate 검증을 수행하고, 통과하면 다음 Phase로 전환합니다. ship은 사용자 확인이 필요하므로 제외됩니다. 대량의 초기 자료가 준비된 상태에서 한 번에 전체 파이프라인을 돌릴 때 유용합니다.

**생성 파일:** Plan, Design, Dev, Check Phase의 전체 산출물 (각 Phase의 모든 문서)

```bash
/u-loop [app]                           # ingest → plan → design → dev → qa 전체
/u-loop [app] --from design             # design Phase부터 시작
/u-loop [app] --to plan                 # plan Phase까지만 실행
/u-loop [app] -i                        # 각 Phase 전환 시 확인
```

---

### Operations Commands (5)

#### `/u-add` — SSoT 항목 추가

FR(기능 요구사항), NR(비기능 요구사항), US(유저 스토리), FT(Feature), Screen, TC(테스트 케이스) 등 개별 항목을 SSoT 문서에 추가합니다. 추가된 항목은 4-Tier ID가 자동 부여되고, 백로그에 자동 등록되며, `_index.json`이 갱신됩니다. 기존 문서의 구조를 유지하면서 새 항목만 삽입합니다.

**수정 파일:** 대상 문서(srs.md/.json, screens.md/.json 등), `_index.json`, `_backlog/` 항목

```bash
/u-add [app] fr "비밀번호 재설정"          # FR(기능 요구사항) 추가
/u-add [app] us "비밀번호 재설정하고 싶다"   # US(유저 스토리) 추가
/u-add [app] nr "응답시간 2초 이내"        # NR(비기능 요구사항) 추가
/u-add [app] screen "마이페이지"           # Screen 추가
```

---

#### `/u-update` — 문서 수정 + Cascade 전파

SSoT 문서를 수정하고, `--cascade` 옵션으로 의존 문서에 변경사항을 자동 전파합니다. `_links.json` 기반으로 영향받는 하위 문서에 MUST-UPDATE / REVIEW-NEEDED 플래그를 설정하며, 버전과 타임스탬프를 갱신하고 companion JSON도 재생성합니다.

**수정 파일:** 대상 문서(.md/.json), 의존 문서의 impact flag, `_links.json`, `_index.json`

```bash
/u-update [app] srs                     # SRS 문서 수정
/u-update [app] srs --cascade           # SRS 수정 + 하위 문서 자동 cascade
/u-update [app] erd --cascade           # ERD 수정 + 관련 문서 전파
/u-update [app] screens FR-003          # 특정 FR 관련 Screen만 수정
```

---

#### `/u-doc` — 문서 조회/편집/재생성

특정 SSoT 문서의 내용을 조회하거나, `--edit` 플래그로 편집 모드에 진입하거나, `--regenerate`로 해당 문서를 재생성합니다. 문서 메타데이터(상태, 버전, 최종 수정일)와 함께 내용을 표시하여 문서 현황을 빠르게 파악할 수 있습니다.

**대상 파일:** 지정된 SSoT 문서(.md/.json), 재생성 시 companion JSON

```bash
/u-doc [app] screens                    # Screen 문서 조회
/u-doc [app] erd                        # ERD 문서 조회
/u-doc [app] srs --edit                 # SRS 편집 모드 진입
/u-doc [app] api --regenerate           # API 문서 재생성
```

---

#### `/u-sync` — 문서 간 일관성 검증

13개 교차 검증 규칙으로 전체 SSoT 문서 간 정합성을 확인합니다. SRS의 FR이 ERD에 반영되었는지, Screen이 IA와 일치하는지, API가 ERD와 정합한지 등을 검사하여 불일치 항목을 리포트하고 자동 수정 제안을 제공합니다. `all`을 지정하면 모든 앱을 한 번에 검증합니다.

**생성 파일:** sync-report (콘솔 출력), 불일치 항목 리스트, 자동 수정 제안

```bash
/u-sync [app]                           # [app] 앱 문서 일관성 검증
/u-sync all                             # 전체 앱 문서 일관성 검증
/u-sync [app] --fix                     # 불일치 자동 수정 적용
/u-sync [app] --only erd,api            # ERD-API 간 정합성만 검증
```

---

#### `/u-gate` — Phase Gate 검증 + 전환

현재 Phase의 Exit Criteria를 평가하여 PASS/FAIL을 판정합니다. 모든 필수 문서가 Final 상태인지 확인하고, PASS이면 다음 Phase로 자동 전환합니다. FAIL이면 미충족 조건 목록을 표시하여 보완이 필요한 항목을 안내합니다.

**수정 파일:** `_index.json` (Phase 상태 갱신), gate-report (콘솔 출력)

```bash
/u-gate [app]                           # 현재 Phase gate 검증
/u-gate [app] --dry-run                 # 검증만 수행 (전환 없이)
/u-gate [app] --force                   # 경고 무시하고 강제 전환
/u-gate all                             # 전체 앱 gate 검증
```

---

### Observability Commands (4)

#### `/u-status` — 프로젝트 대시보드

현재 Phase, 문서별 진행률, 미완료 항목, impact flag를 한눈에 보여주는 대시보드를 표시합니다. 백로그 요약, 가정(Assumptions) 현황, 활성 토론 세션, Gate 준비도까지 포함하여 프로젝트 전체 상태를 빠르게 파악할 수 있습니다. 앱을 지정하지 않으면 전체 프로젝트 요약을 표시합니다.

**출력:** 콘솔 대시보드 (Phase, 진행률 바, 미완료 카운트, impact flags, 백로그 요약)

```bash
/u-status                               # 전체 프로젝트 대시보드
/u-status [app]                         # [app] 앱 상세 대시보드
/u-status [app] --verbose               # 문서별 상세 상태 포함
/u-status all                           # 모든 앱 비교 대시보드
```

---

#### `/u-coverage` — 커버리지 리포트

classified 데이터 대비 산출물의 커버리지를 분석합니다. 원시 자료 → 분류 → 문서 반영까지의 추적성 체인과 채택률을 보고하여, 분류된 요구사항 중 몇 퍼센트가 실제 문서에 반영되었는지 확인할 수 있습니다. 누락된 항목을 식별하여 보완 방향을 제시합니다.

**생성 파일:** coverage-report (콘솔 출력), 카테고리별 채택률, 누락 항목 리스트

```bash
/u-coverage [app]                       # [app] 앱 커버리지 리포트
/u-coverage all                         # 전체 앱 커버리지 비교
/u-coverage [app] --detail              # 항목별 상세 매핑 표시
/u-coverage [app] --export              # 리포트를 파일로 내보내기
```

---

#### `/u-trace` — 추적 체인 조회

특정 ID(FR, US, FT, Screen 등)를 기준으로 raw → classified → docs 전체 추적 체인을 표시합니다. 상위(source) 및 하위(derived) 항목의 완전한 추적성 트리를 시각적으로 보여주어, 하나의 요구사항이 어디에서 시작되어 어떤 문서들에 반영되었는지 한눈에 확인할 수 있습니다.

**출력:** 추적성 트리 (콘솔 출력), 상위/하위 ID 매핑, 문서 참조 경로

```bash
/u-trace [app] FR-015                   # FR-015의 전체 추적 체인
/u-trace [app] US-003                   # US-003의 상위/하위 추적
/u-trace [app] FT-042                   # FT-042의 원시자료 → 문서 경로
/u-trace [app] SCR-007                  # Screen SCR-007의 추적 체인
```

---

#### `/u-report` — SSoT HTML 리포트 생성

SSoT 전체 문서를 기반으로 사이드바 네비게이션이 포함된 HTML 리포트를 생성합니다. SVG 다이어그램(ERD, ScreenFlow, IA 트리 등)을 포함하여 브라우저에서 바로 열 수 있는 독립형 리포트를 만듭니다. `--only daily`로 IA 일정 조율 Daily Report를 생성하면 각 화면이 PDCA 5단계(분류→기획→설계→개발→검증)를 거치는 진행 상황을 한눈에 확인할 수 있습니다. 외부 의존성 없이 오프라인에서 동작하며, 팀 공유나 문서 제출용으로 활용할 수 있습니다.

**생성 파일:** `_reports/{scope}/{date}/` 하위 HTML 파일, `daily-report-{YYYY-MM-DD}.html` (Daily Report)

```bash
/u-report [app]                         # [app] 앱 전체 HTML 리포트 생성
/u-report [app] --only daily            # IA 일정 조율 Daily Report 생성
/u-report [app] --only plan             # Plan 리포트만 생성
/u-report [app] --open                  # 생성 후 브라우저에서 바로 열기
```

---

### Collaboration Commands (5)

#### `/u-ask` — 경량 Q&A

U-MAKER에 대한 가벼운 질문, 제안, 영향 분석을 수행합니다. 명령어 사용법, 문서 구조, 설계 결정의 이유 등을 자유롭게 물어볼 수 있으며, 구조 변경 제안 시에는 장단점 분석과 영향 파일 목록을 함께 제시합니다. 별도의 세션 없이 즉시 답변을 받을 수 있습니다.

**출력:** 즉시 응답 (콘솔), 필요 시 영향 분석 리포트

```bash
/u-ask ERD에서 soft delete를 쓰는 이유?      # 설계 결정 질문
/u-ask /u-plan과 /u-design의 경계가 뭐야?    # 명령어 사용법 질문
/u-ask u-dev를 u-impl로 바꾸면 영향?          # 변경 영향 분석
/u-ask screens.json 구조를 바꾸면 영향 범위?    # 구조 변경 영향 분석
```

---

#### `/u-discuss` — 구조화된 토론 세션

brainstorm(아이디어 발산), review(산출물 검토), decision(기술/비즈니스 의사결정), workshop(다단계 작업), retro(회고) 5가지 유형의 구조화된 협업 세션을 운영합니다. 세션 중 micro-command로 아이디어 태깅, 결정 기록, 액션 아이템 지정이 가능하며, `/wrap`으로 종료 시 결과가 SSoT에 자동 반영됩니다.

**생성 파일:** `_sessions/` 세션 기록(.md/.json), 결정사항/액션 아이템이 해당 문서에 반영

```bash
/u-discuss [app] brainstorm "결제 UX"        # 결제 UX 브레인스토밍
/u-discuss common decision "DB 선택"          # 공통 기술 의사결정
/u-discuss [app] retro                       # iteration 회고
/u-discuss [app] workshop "메인 화면 설계"     # 메인 화면 설계 워크숍
```

---

#### `/u-assume` — Assumptions 리뷰

AI가 정보 부족 시 추정한 가정(Assumption)을 approve/reject로 리뷰합니다. 승인(approve)하면 가정이 확정되어 관련 문서에 반영되고, 기각(reject)하면 올바른 정보를 제공하여 영향받는 문서에 cascade re-evaluation이 트리거됩니다. 미리뷰 가정이 임계치를 초과하면 auto 모드가 interactive로 자동 전환됩니다.

**수정 파일:** `_assumptions/` 로그, 영향받는 SSoT 문서 (reject 시 cascade)

```bash
/u-assume [app]                              # 미리뷰 가정 목록 조회
/u-assume [app] approve A-001               # A-001 가정 승인
/u-assume [app] reject A-001 "전체취소만"     # A-001 기각 + 올바른 정보 제공
/u-assume [app] approve all                  # 전체 가정 일괄 승인
```

---

#### `/u-backlog` — 백로그 관리

백로그 항목의 조회, 추가, 스프린트 할당, 우선순위 정렬, 상태 변경, 번다운 차트를 지원합니다. 그루밍 모드에서 항목별 우선순위와 스토리 포인트를 조정할 수 있으며, 스프린트 속도를 기반으로 완료 예측을 제공합니다.

**생성/수정 파일:** `_backlog/` 항목(.json), 스프린트 할당 기록, 번다운 데이터

```bash
/u-backlog [app]                             # 백로그 전체 조회
/u-backlog [app] add "결제 수단 추가"          # 항목 추가
/u-backlog [app] sprint assign S-002         # 스프린트 할당
/u-backlog [app] burndown                    # 번다운 차트 표시
```

---

#### `/u-git-pr` — PR/MR 자동 생성

현재 브랜치의 변경사항을 분석하여 자동 커밋, push, 구조화된 PR(GitHub) 또는 MR(GitLab)을 생성합니다. 커밋 그루핑을 분석하여 기능별로 분할 PR을 만들거나 통합 PR을 선택할 수 있으며, 리뷰 가이드와 체크리스트가 포함된 팀 친화적인 PR body를 자동 작성합니다. uncommitted changes도 자동으로 커밋하여 포함합니다.

**출력:** Git commit, push, PR/MR 생성 (GitHub/GitLab)

```bash
/u-git-pr                                    # 자동 커밋 + push + PR 생성
/u-git-pr --draft                            # Draft PR로 생성
/u-git-pr main --split                       # 커밋 그룹별 분할 PR
/u-git-pr --reviewer user1,user2             # 리뷰어 지정하여 PR 생성
```

---

## Part 7. /u-discuss 협업 세션

### 세션 타입

| 타입 | 용도 | 예시 |
|------|------|------|
| brainstorm | 아이디어 발산 | `/u-discuss [app] brainstorm "결제 UX"` |
| review | 산출물 검토 | `/u-discuss [app] review` |
| decision | 기술/비즈니스 의사결정 | `/u-discuss common decision "DB 선택"` |
| workshop | 다단계 작업 | `/u-discuss [app] workshop "메인 화면 설계"` |
| retro | Iteration 회고 | `/u-discuss [app] retro` |

### 세션 중 micro-commands

| 명령어 | 설명 |
|--------|------|
| `@planner` / `@builder` / `@gatekeeper` | 특정 에이전트에게 질문 |
| `@all` | 모든 에이전트에게 의견 요청 |
| `/idea [text]` | 아이디어 태깅 |
| `/decide [text]` | 결정사항 기록 |
| `/concern [text]` | 우려/리스크 기록 |
| `/action [who] [text]` | 액션 아이템 기록 |
| `/wrap` | 세션 종료 + 적재 |

---

## Part 8. 실전 시나리오

### Scenario 1: 새 프로젝트 — 처음부터 끝까지

```bash
/u-init my-saas
# → .u-maker/_dropzone/에 RFP, 회의록 드롭
/u-ingest [app]                          # 분석
/u-plan [app] -i                         # 기획 (interactive)
/u-gate [app]                            # → Design
/u-design [app]                          # 설계
/u-gate [app]                            # → Do
/u-dev [app]                             # 구현
/u-gate [app]                            # → Check
/u-qa [app]                              # 검증
/u-ship [app]                            # 배포 + 회고
```

### Scenario 2: 기존 프로젝트에 SSoT 도입

```bash
/u-init my-legacy-app
/u-reverse [app]                         # 코드 → SSoT 역공학
/u-sync [app]                            # 정합성 검증
/u-doc [app] srs --edit                  # 비즈니스 의도 보완
/u-qa [app]                              # TC 생성 + 테스트
```

### Scenario 3: 요구사항 변경

```bash
/u-add [app] fr "비밀번호 재설정"
/u-add [app] us "비밀번호 재설정하고 싶다"
/u-update [app] srs --cascade            # SRS 수정 → 하위 문서 auto-cascade
/u-status [app]                          # impact flags 확인
```

### Scenario 4: 네이밍/구조 제안

```bash
/u-ask screens.json 구조를 바꾸면 영향 범위가 어떻게 돼?
# → 장단점 + 영향 파일 목록 분석
# → "진행하시겠습니까?" 확인 후 변경 수행
```

### Scenario 5: PR 생성

```bash
/u-git-pr
# → uncommitted changes 자동 커밋
# → 자동 push
# → 커밋 그루핑 분석
# → 구조화된 PR body 작성 + 생성
```

### Scenario 6: Phase Gate 미통과

```bash
/u-gate [app]
# → "Plan Gate FAILED: srs (Final), ia (Draft), roadmap (missing)"

/u-plan [app] --only ia                  # IA 생성
/u-plan [app] --only roadmap             # Roadmap 생성
/u-gate [app]                            # 재검증 → PASS
```

### Scenario 7: 멀티 앱 프로젝트

```bash
/u-init my-platform
# config에서 apps: ["web", "admin"]

/u-plan common                            # 공통 정책
/u-plan [app]                            # [app] 기획
/u-plan admin                             # admin 기획
/u-design [app],admin -i                 # 2앱 동시 설계
/u-sync all                               # 전체 정합성 검증
```

---

## Part 9. 폴더 구조

```
.u-maker/
├── u-maker.config.json              # 전역 설정 (language, designTool 등)
├── _links.json                       # 의존성 그래프
│
├── docs/
│   ├── common/                       # 프로젝트 공통 (모든 앱 상속)
│   │   ├── policy/, ux/, dev/, architecture/, project/
│   │
│   └── {app}/                        # 앱별 문서
│       ├── _index.json, app.config.json
│       ├── 01-plan/                  # srs.md, ia.md, roadmap.md
│       ├── 02-design/               # erd.md, api.md, screens.md, rtm.md
│       │   └── wireframes/          # index.html (뷰어) + SCR-*.html/md
│       ├── 03-dev/                  # code.md
│       └── 04-check/               # test-cases.md, test-report.md
│
├── _input/                           # Raw data
│   ├── raw/                          # 미분류 파일 드롭존 (자동 분류)
│   ├── rfp/, as-is/, meeting-notes/, benchmarks/, links/
│   └── _manifest.json
│
├── _classified/                      # 10개 카테고리
├── _sessions/                        # 토론 기록
├── _assumptions/                     # 가정 로그
└── _backlog/                         # 백로그
```

---

## Part 10. Auto-Cascade

SRS 변경 시 `_links.json` 기반으로 하위 문서에 자동 전파:

```
SRS 변경 → ERD [MUST-UPDATE]
         → Screen [MUST-UPDATE]
         → Test Cases [REVIEW-NEEDED]
```

| 레벨 | 의미 | 조치 |
|------|------|------|
| MUST-UPDATE | 반드시 갱신 | `/u-update --cascade` |
| REVIEW-NEEDED | 확인 필요 | `/u-sync`로 검증 |
| INFO | 참고 | 필요 시 수동 확인 |

---

## Part 11. Wireframe Viewer

`/u-design`으로 Screen을 생성하면 `wireframes/index.html`이 자동 생성됩니다. 브라우저에서 열면:

- **사이드바**: IA 기반 그룹별 화면 목록 + 클릭 네비게이션
- **메인 영역**: `.html` 와이어프레임 직접 렌더링, `.md` 파일은 Markdown → HTML 변환 (Mermaid 지원)
- 외부 의존성 없는 단일 HTML (오프라인 동작)

---

## Part 12. FAQ

### Q: 명령어가 인식되지 않아요
A: Claude Code를 재시작해보세요.

### Q: 어떤 명령어를 써야 할지 모르겠어요
A: 자연어로 말하세요. 또는 `/u-ask`로 물어보세요.

### Q: 기존 프로젝트에 적용하려면?
A: `/u-init` → `/u-reverse`로 코드에서 SSoT를 역공학하세요.

### Q: 문서 언어를 바꾸고 싶어요
A: `u-maker.config.json`의 `language.documents`를 `"en"`, `"ja"`, `"zh"` 등으로 변경하세요.

### Q: 기본 테마를 dark로 시작하고 싶어요
A: `u-maker.config.json`에 `"theme": "dark"`를 넣으세요. 허용값은 `light | dark`이고, 미지정 시 기본값은 `light`입니다.

### Q: auto 모드에서 자꾸 interactive로 전환돼요
A: `maxAssumptions` 초과. `/u-assume`로 리뷰하세요.

### Q: PR을 빠르게 만들고 싶어요
A: `/u-git-pr` — uncommitted changes 자동 커밋 + push + PR body 자동 작성.

---

## Part 13. 다음 단계

1. **README.md**: 전체 아키텍처, 엔진 스킬 상세 레퍼런스
2. `/u-ask`: U-MAKER에 대한 궁금한 점을 자유롭게 질문하세요
3. `/u-status`: 현재 프로젝트 상태를 언제든 확인하세요

---

## License

GPL-3.0

Copyright (c) 2026 U PLEAT. All rights reserved.
