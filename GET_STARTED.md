# u-maker 시작하기 (Get Started)

u-maker를 처음 사용하시나요? 이 가이드는 핵심 개념부터 전체 명령어, 실전 시나리오까지 단계별로 안내합니다.

> 전체 레퍼런스는 [README.md](README.md)를 참고하세요.

---

## Part 1. u-maker란?

### 한 줄 요약

u-maker는 **4개의 AI 에이전트**와 **3-Layer 파이프라인**으로 소프트웨어 개발의 전 과정(기획 → 설계 → 구현 → 검증 → 개선)을 자동화하는 **Claude Code 플러그인**입니다.

### 기존 개발 방식과 뭐가 다른가요?

| | 기존 방식 | u-maker 방식 |
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

`_input/raw/`에 파일을 넣으면 `/u-ingest` 실행 시 자동으로 `rfp/`, `as-is/` 등으로 분류합니다.

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
| **Guardian** | Gate 검증, TC 설계/실행, 일관성 검증 | sonnet |

---

## Part 2. 설치

### 원클릭 설치

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.bat -OutFile install.bat; .\install.bat; Remove-Item install.bat
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

# 2. _input/raw/에 RFP, 회의록, AS-IS 자료 드롭
#    → /u-ingest가 자동으로 rfp/, as-is/, meeting-notes/ 등으로 분류

# 3. 데이터 분석
/u-ingest retail

# 4. 전체 파이프라인 실행
/u-plan retail            # SRS + IA + Roadmap
/u-gate retail            # Gate 검증 → Design 전환
/u-design retail          # ERD + API + Screen + Flow + RTM
/u-gate retail            # Gate 검증 → Do 전환
/u-dev retail             # FE + BE + DB 코드 생성
/u-gate retail            # Gate 검증 → Check 전환
/u-qa retail           # TC + 테스트 + 리포트
/u-ship retail            # 최종 검증 + 회고
```

### 3.2 Reverse Engineering — 기존 프로젝트

이미 코드가 있지만 SSoT 문서가 없는 프로젝트:

```bash
# 1. 프로젝트 초기화
/u-init my-existing-app

# 2. 소스 코드 → SSoT 역공학
/u-reverse retail                    # ERD, API, Screen, IA, SRS 전체 역추출
/u-reverse retail --only erd         # ERD만 추출
/u-reverse retail --only api         # API Contract만 추출

# 3. 역공학 결과 검증 + 보완
/u-sync retail                       # 문서 간 정합성 검증
/u-doc retail srs --edit             # SRS에 비즈니스 의도 보완
```

### 3.3 자연어로도 가능

```
"retail 앱의 SRS를 만들어줘"     → /u-plan retail --only srs
"ERD를 PostgreSQL로 최적화해줘" → planner에게 직접 전달
"테스트 케이스 만들어줘"         → /u-qa retail
```

---

## Part 4. Interaction Mode

### auto (기본)

```bash
/u-plan retail           # 플래그 없으면 auto
```
빠르게 진행. 판단은 Assumptions Log에 기록.

### interactive (-i)

```bash
/u-plan retail -i        # 분기점에서 질문
```
정확하지만 느림. 중요한 설계 결정이 있을 때 사용.

### step (--step)

```bash
/u-plan retail --step    # 매 단계 확인
```
가장 세밀한 제어. 학습 목적이나 품질 확인 시 사용.

---

## Part 5. 역할별 활용

### 기획자 (PM)

```bash
/u-ingest retail                          # 자료 분석
/u-ingest retail --review                 # 분석 결과 리뷰
/u-plan retail -i                         # Plan 전체 (interactive)
/u-plan retail --only srs                 # SRS만 생성
/u-add retail fr "비밀번호 재설정"          # FR 추가
/u-add retail us "비밀번호 재설정하고 싶다"   # US 추가
/u-status retail                          # 프로젝트 상태 확인
/u-ask ERD에서 soft delete를 쓰는 이유?     # 가벼운 질문
/u-discuss retail brainstorm "결제 UX"     # 브레인스토밍
```

### 디자이너 (UX)

```bash
/u-design retail                          # Design 전체
/u-design retail --only screens           # Screen만
/u-design retail --only erd               # ERD만
/u-discuss retail workshop "메인 IA"       # IA 워크숍
/u-sync retail                            # 일관성 검증
```

### 개발자 (Dev)

```bash
/u-dev retail                             # FE + BE 코드 생성
/u-dev retail --only fe                   # Frontend만
/u-dev retail --only be                   # Backend만
/u-dev retail --only db                   # DB schema만
/u-reverse retail                         # 기존 코드 → SSoT 역공학
/u-git-pr                                 # PR 자동 생성
/u-git-pr --draft                         # Draft PR
/u-git-pr main --split                    # 커밋 그룹별 분할 PR
```

### QA (테스터)

```bash
/u-qa retail                           # TC + 테스트 + 리포트
/u-qa retail -i                        # interactive로 결과 확인
/u-coverage retail                        # 커버리지 확인
/u-trace retail FR-015                    # 추적 체인
```

---

## Part 6. 명령어 치트시트 (전체 21개)

### Lifecycle Commands (8)

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/u-init` | 프로젝트 초기화 | `/u-init my-project` |
| | | `/u-init .` |
| `/u-reverse` | 소스 코드 → SSoT 역공학 | `/u-reverse retail` |
| | | `/u-reverse retail --only erd` |
| | | `/u-reverse retail --only api` |
| | | `/u-reverse retail --dry-run` |
| `/u-ingest` | Raw → Classified 분석 적재 | `/u-ingest retail` |
| | | `/u-ingest retail --review` |
| | | `/u-ingest retail --incremental` |
| `/u-plan` | SRS + IA + Roadmap 생성 | `/u-plan retail` |
| | | `/u-plan retail -i` |
| | | `/u-plan retail --only srs` |
| | | `/u-plan retail --step` |
| `/u-design` | ERD + API + Screen + Flow + RTM | `/u-design retail` |
| | | `/u-design retail --only screens` |
| | | `/u-design retail --only erd` |
| | | `/u-design retail,admin -i` |
| `/u-dev` | FE + BE + DB 코드 생성 | `/u-dev retail` |
| | | `/u-dev retail --only fe` |
| | | `/u-dev retail --only be` |
| | | `/u-dev retail --only db` |
| `/u-qa` | TC 설계 + 테스트 + 리포트 | `/u-qa retail` |
| | | `/u-qa retail -i` |
| `/u-ship` | 최종 검증 + 회고 | `/u-ship retail` |
| | | `/u-ship retail --step` |

### Operations Commands (5)

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/u-add` | 항목 추가 | `/u-add retail fr "비밀번호 재설정"` |
| | | `/u-add retail us "비밀번호 재설정하고 싶다"` |
| | | `/u-add retail nr "응답시간 2초 이내"` |
| `/u-update` | 문서 수정 + cascade | `/u-update retail srs` |
| | | `/u-update retail srs --cascade` |
| `/u-doc` | 문서 조회/편집 | `/u-doc retail screens` |
| | | `/u-doc retail erd` |
| | | `/u-doc retail srs --edit` |
| `/u-sync` | 일관성 검증 | `/u-sync retail` |
| | | `/u-sync all` |
| `/u-gate` | Phase gate 검증 | `/u-gate retail` |

### Observability Commands (3)

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/u-status` | 대시보드 | `/u-status` |
| | | `/u-status retail` |
| `/u-coverage` | 커버리지 리포트 | `/u-coverage retail` |
| | | `/u-coverage all` |
| `/u-trace` | 추적 체인 | `/u-trace retail FR-015` |
| | | `/u-trace retail US-003` |

### Collaboration Commands (5)

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/u-ask` | Q&A (질문, 제안, 의견) | `/u-ask u-dev를 u-impl로 바꾸면 영향?` |
| | | `/u-ask ERD에서 soft delete를 쓰는 이유?` |
| | | `/u-ask /u-plan과 /u-design의 경계가 뭐야?` |
| `/u-discuss` | 구조화된 토론 세션 | `/u-discuss retail brainstorm "결제 UX"` |
| | | `/u-discuss common decision "DB 선택"` |
| | | `/u-discuss retail retro` |
| | | `/u-discuss retail workshop "메인 IA"` |
| `/u-assume` | Assumptions 리뷰 | `/u-assume retail approve A-001` |
| | | `/u-assume retail reject A-001 "전체취소만"` |
| `/u-backlog` | 백로그 관리 | `/u-backlog retail` |
| `/u-git-pr` | PR/MR 자동 생성 | `/u-git-pr` |
| | | `/u-git-pr --draft` |
| | | `/u-git-pr main --split` |
| | | `/u-git-pr --reviewer user1,user2` |

---

## Part 7. /u-discuss 협업 세션

### 세션 타입

| 타입 | 용도 | 예시 |
|------|------|------|
| brainstorm | 아이디어 발산 | `/u-discuss retail brainstorm "결제 UX"` |
| review | 산출물 검토 | `/u-discuss retail review` |
| decision | 기술/비즈니스 의사결정 | `/u-discuss common decision "DB 선택"` |
| workshop | 다단계 작업 | `/u-discuss retail workshop "메인 화면 설계"` |
| retro | Iteration 회고 | `/u-discuss retail retro` |

### 세션 중 micro-commands

| 명령어 | 설명 |
|--------|------|
| `@planner` / `@builder` / `@guardian` | 특정 에이전트에게 질문 |
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
# → _input/raw/에 RFP, 회의록 드롭
/u-ingest retail                          # 분석
/u-plan retail -i                         # 기획 (interactive)
/u-gate retail                            # → Design
/u-design retail                          # 설계
/u-gate retail                            # → Do
/u-dev retail                             # 구현
/u-gate retail                            # → Check
/u-qa retail                           # 검증
/u-ship retail                            # 배포 + 회고
```

### Scenario 2: 기존 프로젝트에 SSoT 도입

```bash
/u-init my-legacy-app
/u-reverse retail                         # 코드 → SSoT 역공학
/u-sync retail                            # 정합성 검증
/u-doc retail srs --edit                  # 비즈니스 의도 보완
/u-qa retail                           # TC 생성 + 테스트
```

### Scenario 3: 요구사항 변경

```bash
/u-add retail fr "비밀번호 재설정"
/u-add retail us "비밀번호 재설정하고 싶다"
/u-update retail srs --cascade            # SRS 수정 → 하위 문서 auto-cascade
/u-status retail                          # impact flags 확인
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
/u-gate retail
# → "Plan Gate FAILED: srs (Final), ia (Draft), roadmap (missing)"

/u-plan retail --only ia                  # IA 생성
/u-plan retail --only roadmap             # Roadmap 생성
/u-gate retail                            # 재검증 → PASS
```

### Scenario 7: 멀티 앱 프로젝트

```bash
/u-init my-platform
# config에서 apps: ["retail", "admin"]

/u-plan common                            # 공통 정책
/u-plan retail                            # retail 기획
/u-plan admin                             # admin 기획
/u-design retail,admin -i                 # 2앱 동시 설계
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

### Q: auto 모드에서 자꾸 interactive로 전환돼요
A: `maxAssumptions` 초과. `/u-assume`로 리뷰하세요.

### Q: PR을 빠르게 만들고 싶어요
A: `/u-git-pr` — uncommitted changes 자동 커밋 + push + PR body 자동 작성.

---

## Part 13. 다음 단계

1. **README.md**: 전체 아키텍처, 엔진 스킬 상세 레퍼런스
2. `/u-ask`: u-maker에 대한 궁금한 점을 자유롭게 질문하세요
3. `/u-status`: 현재 프로젝트 상태를 언제든 확인하세요

---

## License

MIT
