# u-maker-plugin v4.0 Remodel Design

> Date: 2026-04-03
> Approach: Big Bang (전면 재구축)
> Status: Draft

---

## 1. Overview

u-maker-plugin v3.1 → v4.0 전면 재구축.
- 39개 skill → 7개로 통합
- 4개 agent → 7개로 재편
- `.u-maker/` 런타임 폴더 구조 단순화
- Gatekeeper 11항목 점수 기반 검증 + loop
- HTML engine 추가 (SVG 다이어그램, base64 이미지, Mermaid CDN)
- README.ko.html, README.en.html, GET_STARTED.html 재작성

---

## 2. Runtime Folder Structure (`.u-maker/`)

`/u-init`이 생성하는 프로젝트 런타임 구조.

```
.u-maker/
├── u-maker.config.json
│
├── data/
│   ├── dropzone/                  # 원시 자료 (사용자 트리구조 그대로)
│   │   ├── rfp/
│   │   ├── meetings/
│   │   ├── as-is/
│   │   └── ...
│   ├── digest/                    # 정제 분석 데이터 (dropzone 미러링)
│   │   ├── _index.json            # digest 목록, hash, 상태, 분석일시
│   │   └── {mirror-tree}/
│   │       └── {filename}.digest.json
│   └── links.json                 # digest ↔ docs 의존성 그래프
│
├── docs/                          # SSoT 문서 (app별 + PDCA 단계별)
│   └── {app}/
│       ├── plan/
│       │   ├── srs.md + srs.json
│       │   └── ia.md + ia.json
│       ├── design/
│       │   ├── erd.md + erd.json
│       │   ├── api.md + api.json
│       │   ├── screens.md + screens.json
│       │   └── design-system.md + design-system.json
│       └── check/
│           ├── testcases.md + testcases.json
│           └── test-results.md + test-results.json
│
├── output/                        # HTML 산출물 (docs 미러링)
│   └── {app}/
│       ├── index.html             # 사이드바 네비게이션
│       ├── plan/
│       │   ├── srs.html
│       │   └── ia.html
│       ├── design/
│       │   ├── erd.html
│       │   ├── api.html
│       │   ├── screens.html
│       │   └── design-system.html
│       └── check/
│           ├── testcases.html
│           └── test-results.html
│
├── reports/
│   └── {YYYY-MM-DD}/
│       └── daily-report.html      # u-report --daily 결과
│
└── .state/
    └── loop-state.json            # 런타임 상태
```

### Data Pipeline

```
data/dropzone/ (원시) → data/digest/ (정제 JSON) → docs/ (SSoT 문서 .md+.json) → output/ (HTML)
```

### Digest 설계

- dropzone 트리구조를 미러링하여 1:1 매핑
- `_index.json`: 파일명, source hash, 분석일시, 상태(pending/done)
- `.digest.json`: 요약, 핵심 요구사항, 키워드, 제약조건, 도메인 용어 구조화
- 원본 변경 시 hash 비교로 해당 digest만 재생성 (토큰 절약)

### JSON Companion

모든 `.md` 문서에 `.json` companion 파일 동반 생성.

| 역할 | 설명 |
|------|------|
| 항목 ID 추적 | FR-010, US-020, FT-030 (10단위 증가) |
| 상태 관리 | `status: "draft" / "approved"` |
| 교차참조 | FR-010 → US-020 → FT-030 → TC-010 |
| links.json 연동 | 의존성 그래프 노드 |
| Gatekeeper 검증 | JSON 기반 정량 분석 |

### ID 체계

- 10단위 증가: FR-010, FR-020, FR-030...
- 중간 삽입 가능: FR-015 (기존 010과 020 사이)
- 형식: `{TYPE}-{NNN}` (TYPE: FR, NFR, US, FT, SC, TC, ENT, API)

---

## 3. Plugin Source Structure

```
u-maker-plugin/
├── .claude-plugin/
│   └── plugin.json                      # v4.0.0
│
├── agents/ (7)
│   ├── u-agent-pm.md                    # PM — 커맨드 라우팅, 진행 관리, 상태 머신
│   ├── u-agent-plan.md                  # Plan — dropzone→digest→SRS/IA 생성
│   ├── u-agent-design.md                # Design — ERD/API/Screen/Design System 생성
│   ├── u-agent-dev.md                   # Dev — 명세→FE+BE+DB 코드 생성
│   ├── u-agent-qa.md                    # QA — TC 설계, 테스트 실행, 결과 기록
│   ├── u-agent-gatekeeper.md            # 검증 — 11항목 점수, avg<95→loop
│   └── u-agent-report.md               # Report — daily HTML 리포트
│
├── skills/ (7)
│   ├── u-plan/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── ingest-flow.md
│   │       ├── srs-spec.md
│   │       └── ia-spec.md
│   ├── u-design/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── erd-spec.md
│   │       ├── api-spec.md
│   │       ├── screen-spec.md
│   │       └── design-system-spec.md
│   ├── u-dev/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── code-gen-rules.md
│   │       └── tech-rules.md
│   ├── u-check/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── testcase-spec.md
│   │       └── test-execution.md
│   ├── u-engine/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── doc-engine.md
│   │       ├── html-engine.md
│   │       ├── dep-engine.md
│   │       ├── digest-engine.md
│   │       └── router.md
│   ├── u-discuss/
│   │   ├── SKILL.md
│   │   └── references/
│   └── u-git-pr/
│       └── SKILL.md
│
├── hooks/ (3 + registry)
│   ├── on-dropzone-added.js
│   ├── on-doc-change.js
│   ├── on-gate-result.js
│   └── hooks.json
│
├── _meta/
│   ├── templates/ (12)
│   │   ├── srs.template.md
│   │   ├── ia.template.md
│   │   ├── erd.template.md
│   │   ├── api.template.md
│   │   ├── screens.template.md
│   │   ├── design-system.template.md
│   │   ├── testcase.template.md
│   │   ├── test-results.template.md
│   │   ├── daily-report.template.html
│   │   ├── output-page.template.html
│   │   ├── output-index.template.html
│   │   └── pr.template.md
│   ├── schemas/ (5)
│   │   ├── digest.schema.json
│   │   ├── doc-companion.schema.json
│   │   ├── links.schema.json
│   │   ├── gate-rules.json
│   │   └── config.schema.json
│   └── tech-rules.md
│
├── install.sh / install.bat / install.ps1
├── deploy_local.sh / deploy_local.bat
├── README.ko.html                       # 재작성
├── README.en.html                       # 재작성
├── GET_STARTED.html                     # 재작성
└── spec.md
```

---

## 4. Agents Detail

### 4.1 u-agent-pm (Project Manager)

- 모든 `/u-*` 커맨드의 진입점 + 라우팅
- PDCA 상태 머신 관리 (Plan → Design → Dev → Check)
- `--auto` (기본) / `--loop` (off 기본) 옵션 처리
- `--app {name}` 대상 앱 라우팅
- 적절한 agent에 작업 위임

### 4.2 u-agent-plan

- `data/dropzone/` 원시자료 → `data/digest/` 정제
- `digest/` → `docs/{app}/plan/srs.md+json`, `ia.md+json` 생성
- ID 10단위 규칙 적용
- `links.json` 갱신

### 4.3 u-agent-design

- `docs/{app}/plan/` 기반 → `docs/{app}/design/` 문서 생성
- ERD (Mermaid erDiagram), API Contract, Screen Spec, Design System
- .md + .json companion 동시 생성
- `links.json` 갱신 (plan ↔ design 연결)

### 4.4 u-agent-dev

- `docs/{app}/design/` 명세 → FE+BE+DB 코드 생성
- tech-rules.md 기반 스택 적용
- 명세-코드 간 spec-sync 검증

### 4.5 u-agent-qa

- `docs/{app}/plan/srs.json`의 FT 기반 → TC 설계
- `docs/{app}/check/testcases.md+json` 생성
- 테스트 실행 → `test-results.md+json` 기록
- 6종 TC: unit, integration, e2e, accessibility, performance, security

### 4.6 u-agent-gatekeeper

- 각 phase 결과물에 대해 11개 검증항목 점수 산정
- 검증항목별 100점 만점, 평균 95점 이상 → PASS
- FAIL 시 개선사항 목록 생성 → 해당 agent 재실행
- 최대 3회 반복, 이후 사용자 수동 개입 요청

#### 11개 검증항목

| # | 항목 | 설명 |
|---|------|------|
| 1 | 완전성(Completeness) | 모든 필수 섹션/항목 존재 |
| 2 | 정확성(Accuracy) | digest/상위 문서와 내용 일치 |
| 3 | 일관성(Consistency) | 문서 간 ID, 용어, 수치 무모순 |
| 4 | 추적성(Traceability) | FR→US→FT→TC 체인 완전 |
| 5 | TOC 적정성(TOC Quality) | 목차 논리성, 상세 depth, 항목 완전 |
| 6 | 내용 구성(Content Composition) | 논리적 구성, 흐름, 정보 배치 |
| 7 | 시각 표현 적정성(Visual Adequacy) | 별점/카드/테이블/리스트 적합성 |
| 8 | 다이어그램 적정성(Diagram Fitness) | 다이어그램 유형 적합, SVG 렌더링 정상 |
| 9 | Mermaid 무결성(Mermaid Integrity) | 문법 오류 없음, 렌더링 가능, 노드/엣지 완전 |
| 10 | JSON 동기화(JSON Sync) | .md↔.json 동기화, ID 10단위 규칙 |
| 11 | 교차참조(Cross-ref) | links.json ↔ 실제 참조 일치 |

### 4.7 u-agent-report

- `--daily` 옵션으로 daily report HTML 생성
- `reports/{YYYY-MM-DD}/daily-report.html`에 저장
- 프로젝트 진행 현황, 변경 이력, 점수 요약 포함

---

## 5. Skills Detail

### 5.1 u-plan (Plan Phase 통합)

통합 대상: `u-ingest`, `u-plan`, `u-add` (기존 command) + `u-skill-analyzer`, `u-skill-estimator` (기존 engine)

**워크플로우:**
1. dropzone 스캔 → 신규/변경 파일 감지
2. 원시자료 → digest 정제 (hash 비교로 변경분만)
3. digest 기반 → SRS 생성 (FR/NFR/US/FT, ID 10단위)
4. digest 기반 → IA 생성
5. .md + .json companion 동시 생성
6. links.json 갱신
7. `--loop` 시 gatekeeper 검증

**옵션:** `--auto` (기본), `--loop` (off 기본), `--app {name}`

### 5.2 u-design (Design Phase 통합)

통합 대상: `u-design`, `u-browse` (기존 command) + `u-skill-designer` (기존 engine)

**워크플로우:**
1. `docs/{app}/plan/` 문서 로드
2. ERD 생성 (Mermaid erDiagram)
3. API Contract 생성 (OpenAPI 3.0)
4. Screen Spec 생성
5. Design System 생성 (Design Tokens + UI Components)
6. .md + .json companion 동시 생성
7. links.json 갱신 (plan ↔ design)

### 5.3 u-dev (Dev Phase 통합)

통합 대상: `u-dev`, `u-codereview` (기존 command) + `u-skill-code-engine` (기존 engine)

**워크플로우:**
1. `docs/{app}/design/` 명세 로드
2. FE 코드 생성 (Screen → Components)
3. BE 코드 생성 (API → Routes/Controllers)
4. DB 코드 생성 (ERD → Migration/Schema)
5. spec-sync 검증

### 5.4 u-check (Check Phase 통합)

통합 대상: `u-qa`, `u-coverage`, `u-trace`, `u-sync` (기존 command) + `u-skill-test`, `u-skill-validator` (기존 engine)

**워크플로우:**
1. SRS FT 기반 TestCase 설계
2. `docs/{app}/check/testcases.md+json` 생성
3. 테스트 실행
4. `test-results.md+json` 기록
5. coverage 분석 (digest→docs 커버리지)
6. 추적성 체인 검증 (FR→US→FT→TC)

### 5.5 u-engine (공통 Engine 번들)

통합 대상: `u-skill-doc-engine`, `u-skill-dep-engine`, `u-skill-phase-detector`, `u-skill-workflow-runner`, `u-skill-router`

**references 구성:**
- `doc-engine.md` — 문서 CRUD, 템플릿 렌더링, JSON companion 생성
- `html-engine.md` — MD→HTML 변환, SVG 다이어그램, base64 이미지, Mermaid CDN, 사이드바 네비게이션
- `dep-engine.md` — links.json 의존성 그래프 관리, cascade propagation
- `digest-engine.md` — dropzone→digest 정제, hash 비교, _index.json 관리
- `router.md` — 의도 분류, 커맨드 파싱, agent 디스패치

### 5.6 u-discuss (유지)

구조화된 토론 세션. brainstorm, review, decision, workshop, retro 타입 지원.

### 5.7 u-git-pr (유지)

Git PR/MR 자동 생성.

**PR 템플릿 구성:**
- 작업 주제
- 작업 내용 (커밋별 설명)
- 주요 변경 파일 목록
- 구현 화면/기능 구성
- 체크리스트 (base/compare, 빌드, 타입체크, console.log, .env.example)
- 리뷰 가이드 (P1 Request Changes / P2 Comment / P3 Approve)

---

## 6. Hooks

| Hook | 트리거 | 동작 |
|------|--------|------|
| `on-dropzone-added.js` | data/dropzone/ 파일 추가 | digest 생성 트리거 |
| `on-doc-change.js` | docs/ 문서 변경 | JSON companion 동기화 + links.json 갱신 |
| `on-gate-result.js` | gatekeeper 검증 완료 | loop 모드 시 재실행 판단 |

---

## 7. HTML Output Rules

### 템플릿 기반

- Light 모드 기본
- 사이드바 네비게이션 (dark sidebar: `#0f172a`, group별 color indicator)
- 키보드 네비게이션 (Arrow Up/Down/Left/Right)
- Footer: `Copyright(c) 2026 U PLEAT`
- Tailwind CSS 유틸리티 클래스
- Dark/Light 토글 스위처 포함

### 다이어그램

- SVG 인라인 (곡선 커넥터 curved connector)
- Mermaid CDN으로 UML 렌더링 (Class, ERD, Sequence)
- 이미지 base64 인코딩 (외부 파일 의존 없는 단일 파일)

### index.html

- `output/{app}/index.html`에 전체 문서 네비게이션
- plan/design/check 그룹별 카테고리
- iframe 기반 문서 미리보기
- 이전/다음 네비게이션 버튼

---

## 8. Command Options

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--auto` | **ON** | 질문 없이 자동 진행 |
| `--loop` | **OFF** | gatekeeper 연동 반복 (avg<95 → 재실행, 최대 3회) |
| `--app {name}` | — | 대상 앱 지정 |
| `--daily` | — | u-report 전용: daily report 생성 |

---

## 9. Deleted Items (v3.1 → v4.0)

### 삭제 문서
- Roadmap, Screen Flow, RTM, Iteration Log, Retrospective

### 삭제 폴더 (`.u-maker/`)
- `data/input/`, `data/classified/`, `data/assumptions/`, `data/backlog/`

### 삭제 Skills (32개)
- 기존 25개 command skill → 7개로 통합 (18개 제거)
- 기존 13개 engine skill → 1개(u-engine)로 통합 (12개 제거)
- `u-ship`, `u-status`, `u-loop`, `u-gate`, `u-sync`, `u-trace`, `u-coverage`, `u-update`, `u-doc`, `u-ask`, `u-assume`, `u-backlog`, `u-browse`, `u-reverse`, `u-codereview`, `u-report`, `u-maker`, `u-init` 삭제
- 기능은 해당 phase skill의 references/로 이관

### 삭제 Templates
- `roadmap.template.md`, `screen-flow.template.md`, `rtm.template.md`
- `iteration-log.template.md`, `retrospective.template.md`, `code-review-rules.template.md`

### 삭제 Schemas
- `assumption.schema.json`, `backlog.schema.json`, `classified.schema.json`, `session.schema.json`, `json-export.schema.json`

### 삭제 Hooks (5개)
- `on-input-added.js`, `on-classified-validated.js`, `on-session-wrap.js`
- `on-build-complete.js`, `on-check-fail.js`, `on-gate-pass.js`, `on-ship-incomplete.js`

### 삭제 Session Protocols
- `brainstorm.md`, `decision.md`, `review.md`, `workshop.md`, `retro.md`
  (u-discuss가 자체 관리)

---

## 10. Migration Notes

- v3.1 → v4.0은 비호환 (breaking change)
- `install.sh`에서 기존 `.u-maker/` 감지 시 경고 메시지 출력
- 기존 `data/classified/` 데이터는 수동 마이그레이션 불필요 (digest로 재생성)
- plugin.json version: `4.0.0`
