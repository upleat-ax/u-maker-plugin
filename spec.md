# u-maker: PDCA-based SSoT Plugin for Claude Code

> 이 문서는 Claude Code plugin "u-maker"를 구축하기 위한 설계 명세이다.
> Claude는 이 문서를 읽고 `.u-maker/` 폴더 구조, agents, skills, commands, templates를 생성해야 한다.

---

## 1. Overview

u-maker는 엔터프라이즈급 소프트웨어 프로젝트를 PDCA(Plan-Design-Do-Check-Act) 방법론으로 관리하는 Claude Code plugin이다.

### 핵심 설계 원칙

| 원칙 | 설명 |
|------|------|
| **Intent-driven** | FDE(Full-stack Design Engineer)는 `/u-plan retail` 한 번으로 SRS + IA + Roadmap이 연쇄 생성된다. "무슨 문서?"가 아니라 "뭘 하고 싶어?" |
| **3-layer pipeline** | `_input/`(raw) → `_classified/`(정제) → `docs/`(산출물). raw→산출물 직행 시 LLM context window 한계로 데이터 loss 방지 |
| **Auto-cascade** | SRS가 바뀌면 RTM/Screen/TestCase에 impact flag 자동 전파 |
| **4 Agents** | Orchestrator(두뇌) + Planner(분석+설계) + Builder(구현) + Gatekeeper(검증). FDE가 기억할 건 orchestrator 뿐 |
| **Engine skills** | 문서별 skill 대신 횡단 엔진: doc-engine, dep-engine, diff-engine, code-engine |
| **Auto-phase** | 산출물 상태(Draft/Review/Final)로 현재 phase 자동 판정. Gate도 자동 트리거 |
| **Monorepo mirroring** | monorepo의 apps/ 구조를 `.u-maker/apps/`가 1:1 미러링. 앱별 독립 PDCA |
| **Inherit + override** | 공통 정책(common/)을 앱이 상속. 앱별 override 가능 |
| **Scope-first** | Claude는 `--app` 스코프 내 `_index.json`만 먼저 읽고, 필요한 파일만 개별 로드. context window 절약 |
| **Theme-consistent HTML** | 생성되는 모든 HTML은 light/dark 모드와 공통 theme persistence를 지원 |
| **Context-budgeted execution** | HTML은 최후순위 입력, JSON/index 우선, delta-read와 `--only` 기본 적용 |

---

## 2. PDCA 5-Phase Process

```
Plan → Design → Do → Check → Act
  ↑                              |
  └──────── iteration ───────────┘
```

### Phase 정의

#### 01 Plan — 발산 + 수렴

**발산 (Diverge)**
- Problems: 질의록 수집, RFP 분석, Pain Points, AS-IS 시스템/워크플로/DB/화면/문서 분석
- Solutions: 해결 과제 도출, 솔루션 협의

**수렴 (Converge)**
- 사용자 정의, 도메인 정의, 요구사항 정의, IA 설계

**산출물:** SRS, FR/NR, US/FT, IA, Roadmap, Wireframe
**담당:** u-agent-orchestrator → u-agent-planner → u-agent-gatekeeper(auto-validate)

#### 02 Design

- UX design: UX Guide, Screen 설계, Screen Flow, Design Token, UI Components
- System design: ERD, API Contract, RTM(추적 매트릭스)

**산출물:** UXGuide, Screen, ScreenFlow, DesignToken, ERD, API, RTM
**담당:** u-agent-planner, u-agent-gatekeeper(consistency)

#### 03 Do (Dev)

- Frontend: Component 개발, Storybook, Design Token 적용
- Backend: API Route, DB 연동, 비즈니스 로직

**산출물:** Code, UIComponents, Screen(구현)
**담당:** u-agent-builder

#### 04 Check

- QA 검증: TestCase 설계, 테스트 실행, 결함 분석, 리포트 생성

**산출물:** TestCase, TestReport
**종료조건:** Critical/Major 결함 0건, 모든 FR 구현 완료, build success
**담당:** u-agent-gatekeeper

#### 05 Act

- 배포 + 회고: CI/CD 파이프라인, Iteration Log, Retrospective, Daily Report
- 분기: Pass → Complete / Fail → Plan으로 회귀 (다음 iteration)

**산출물:** IterationLog, Retrospective, DailyReport
**담당:** u-agent-orchestrator, u-agent-gatekeeper

### Phase Gates

| Gate | 조건 | Validator |
|------|------|-----------|
| plan → design | SRS Final + IA Final + Roadmap approved | u-agent-gatekeeper |
| design → do | ERD + RTM + Screen + API Final & consistency review | u-agent-gatekeeper |
| do → check | Code complete + build success | u-agent-gatekeeper |
| check → complete | Critical/Major 0건, all FR implemented, build success | u-agent-gatekeeper |
| check → act | check-to-complete 실패 시 | u-agent-orchestrator |
| act → plan | Retrospective complete + archive complete | u-agent-orchestrator |

---

## 3. 3-Layer Data Pipeline

### 왜 3-layer인가

raw data(RFP 200페이지)를 Claude가 한 번에 읽고 산출물을 만들면 context window 넘어서 앞부분이 loss된다. 중간 정제 레이어(_classified)를 두면:
- chunk 단위로 분석 → classified에 누적 → 전체 context 없이도 이전 분석 참조 가능
- 모든 항목에 `source: {file, page, section}` 메타데이터 → 역추적 가능
- classified 기반 산출물 생성은 멱등(같은 input → 같은 output)
- 새 회의록 추가 시 incremental 분석만 → 처음부터 재생성 불필요

### Layer 1: _input/ (raw data)

사람이 넣는 원본. 수정하지 않음.
- RFP 원문 (PDF, DOCX, MD)
- AS-IS 시스템/화면/DB/워크플로 자료
- 질의록, 회의록, 인터뷰 노트
- Pain Points 수집 결과
- 벤치마킹, 외부 참고 링크

### Layer 2: _classified/ (정제 데이터)

Claude(analyzer)가 raw를 chunk 단위로 분석하여 아래 카테고리로 분류/태깅, JSON으로 적재:

| 카테고리 | 파일패턴 | 핵심 필드 | 입력 소스 |
|----------|----------|-----------|-----------|
| requirements/ | FR-nnn.json, NR-nnn.json | id, type, title, description, priority, source, related, status, tags | RFP, 회의록 |
| pain-points/ | PP-nnn.json | id, description, severity, affected_users, current_workaround, source | 인터뷰, Pain Points |
| domain-terms/ | DT-nnn.json | id, term, definition, synonyms, context, source | RFP, 회의록, AS-IS |
| stakeholders/ | SH-nnn.json | id, name, role, department, needs, pain_points, source | RFP, 회의록 |
| workflows/ | WF-nnn.json | id, name, actors, steps[], systems[], pain_points[], source | AS-IS workflows |
| screens/ | SC-nnn.json | id, name, url, functions[], issues[], screenshot_path, source | AS-IS screens |
| data-models/ | DM-nnn.json | id, table_name, columns[], relations[], issues[], source | AS-IS DB |
| constraints/ | CN-nnn.json | id, type(tech\|policy\|legal), description, impact, source | RFP, 법규, 기술검토 |
| decisions/ | DC-nnn.json | id, date, participants[], decision, rationale, source | 회의록, /u-discuss |
| questions/ | QS-nnn.json | id, question, context, status(open\|resolved), answer, source | 분석 중 발생 |

**각 카테고리 폴더에 `_index.json`**: 전체 항목의 id/title/status/tags 목록. doc-engine이 산출물 생성 시 index만 읽어서 필요한 항목 선택적 로드 → context window 절약.

**항목 lifecycle:** `extracted` → `validated` → `adopted` / `rejected`
- extracted: analyzer가 raw에서 자동 추출. 사람 검증 안 됨.
- validated: FDE가 확인/수정 완료. 산출물 생성에 사용 가능.
- adopted: 실제 산출물(SRS 등)에 반영 완료. 역참조 링크 생성됨.
- rejected: 검토 후 제외. 사유 기록.

### Layer 3: docs/ (산출물)

classified 데이터를 조합하여 생성. 각 항목에 출처 링크 보존.
- SRS ← requirements/ + constraints/ + stakeholders/
- IA ← workflows/ + screens/ + domain-terms/
- Roadmap ← requirements/ + estimator 결과
- ERD ← data-models/ + requirements/
- Screen ← screens/ + workflows/ + pain-points/

---

## 4. Agents (4개)

### u-agent-orchestrator

**역할:** Command router + Phase controller + State machine

- 모든 `/u-*` 커맨드의 진입점 (single entry)
- 현재 phase 자동 판정 (산출물 status 기반)
- 커맨드 의도 해석 → 적합한 agent로 라우팅
- multi-step workflow 오케스트레이션
- phase gate 자동 트리거
- _links.json 의존성 그래프 관리
- 변경 cascade 전파 및 impact 알림
- /u-discuss 세션 퍼실리테이션

**소유 Skills:** engine-router, engine-phase-detector, engine-dep, engine-workflow-runner, engine-facilitator

**활동 Phase:** All

### u-agent-planner

**역할:** Analysis + Design (분석 + 설계 통합)

- _input/ 자료 분석 (RFP, AS-IS, Pain Points)
- SRS 작성 (FR/NR 포함)
- IA 설계, Screen 설계, Screen Flow
- ERD, API Contract 설계
- UX Guide, Design Token 정의
- Roadmap/마일스톤 수립
- User Story/Feature 분해
- Wireframe 생성

**소유 Skills:** engine-doc, engine-analyzer, engine-designer, engine-estimator

**활동 Phase:** Plan, Design

### u-agent-builder

**역할:** Implementation (FE + BE 구현 통합)

- Screen 명세 → 컴포넌트 코드 생성
- API Contract → Route/Controller 생성
- ERD → DB schema/migration 생성
- Design Token → CSS/스타일 적용
- Storybook 스토리 자동 생성
- 코드 ↔ 명세 일치 검증

**소유 Skills:** engine-code

**활동 Phase:** Do

### u-agent-gatekeeper

**역할:** Validation + QA + Delivery (검증 통합)

- Phase gate 검증 실행
- 문서 간 일관성 검증 (cross-doc)
- SRS 기반 TestCase 자동 설계
- 테스트 실행 및 결과 리포트
- 결함 분석 및 분류
- RTM 자동 생성/갱신
- Exit criteria 판정
- Iteration log + Retrospective

**소유 Skills:** engine-validator, engine-test

**활동 Phase:** Design, Do, Check, Act

---

## 5. Skills (12개 횡단 엔진)

### Core Engines (orchestrator 소속)

| Skill | 역할 |
|-------|------|
| engine-router | intent 분류, agent dispatch, fallback 처리 |
| engine-phase-detector | 문서 status 집계 → phase 자동 판정 |
| engine-dep | _links.json 기반 의존성 그래프 관리, cascade 전파 |
| engine-workflow-runner | multi-step 실행, 중간 실패 rollback, progress tracking |
| engine-facilitator | /u-discuss 세션 퍼실리테이션, 태깅 분류, context 직렬화/복원 |

### Domain Engines (planner 소속)

| Skill | 역할 |
|-------|------|
| engine-doc | 모든 문서의 CRUD. 템플릿 렌더링, JSON export, 버전 관리. 문서 종류는 templates/에서 동적 로드 |
| engine-analyzer | _input/ 자료 파싱, 요약, 구조화, gap 분석. chunk 단위로 raw → classified 적재 |
| engine-designer | IA/Screen/Flow/ERD/API 통합 설계. engine-doc의 쓰기 호출 |
| engine-estimator | SRS 항목 수 + 복잡도 → 일정/공수 자동 산정 |

### Execution Engines (builder + gatekeeper 소속)

| Skill | 역할 |
|-------|------|
| engine-code | 명세 → 코드 생성 (FE/BE 통합), scaffold, spec-sync |
| engine-validator | gate check, cross-doc consistency, exit criteria 판정 |
| engine-test | SRS/Screen → TC 자동 생성, 실행, 리포트 |

---

## 6. CLI Command Grammar

### 문법

```
/u-{command} [scope] [target] [flags]
```

- **scope** = 앱 이름 | `common` | `all` | 생략
- **target** = 문서/항목 이름 (command에 따라 선택적)
- **flags** = `-i` | `--step` | `--only X` | `--cascade` | ...

### Scope 해석 규칙 (router가 처리)

1. config에 등록된 앱 이름이면 → 해당 앱 스코프
2. `common`이면 → common/ 스코프
3. `all`이면 → 전체 앱
4. 생략이면 → 앱 1개: 자동 / 2개+: 선택 요청
5. 등록된 앱도 예약어도 아니면 → target으로 해석
6. 콤마로 복수 앱 지정 가능: `retail,corporate`

### 예약어 (앱 이름 사용 금지)

- Built-in scopes: `common`, `all`
- Built-in targets: `srs`, `ia`, `erd`, `api`, `screens`, `screen-flow`, `roadmap`, `rtm`, `ux-guide`, `design-token`, `test-cases`, `test-report`, `code`
- Built-in types: `brainstorm`, `review`, `decision`, `workshop`, `retro`, `approve`, `reject`

### 전체 Command 목록 (19개)

#### Lifecycle (7)

| Command | Signature | 설명 |
|---------|-----------|------|
| /u-init | `/u-init [project-name]` | .u-maker/ 구조 생성, config 초기화, 앱 등록 |
| /u-ingest | `/u-ingest [scope]` | raw → classified 분석 적재 |
| /u-plan | `/u-plan [scope]` | classified → SRS + IA + Roadmap 연쇄 생성 |
| /u-design | `/u-design [scope]` | SRS/IA 기반 → ERD + API + Screen + Flow + UXGuide |
| /u-dev | `/u-dev [scope]` | 명세 기반 코드 생성 (FE + BE + DB) |
| /u-qa | `/u-qa [scope]` | TC 설계 + 테스트 + Report + exit criteria 판정 |
| /u-ship | `/u-ship [scope]` | 최종 검증 + iteration log + retrospective |

#### Operations (5)

| Command | Signature | 설명 |
|---------|-----------|------|
| /u-add | `/u-add [scope] [type] "title"` | 항목 추가 (FR/NR/US/Screen 등) |
| /u-update | `/u-update [scope] [doc]` | 문서 수정 + 변경 cascade 자동 전파 |
| /u-doc | `/u-doc [scope] [doc]` | 특정 문서 조회/편집/재생성 |
| /u-sync | `/u-sync [scope]` | 전체 문서 일관성 검증 + 불일치 자동 수정 제안 |
| /u-gate | `/u-gate [scope]` | 현재 phase gate 충족 여부 검사 + 다음 phase 전환 |

#### Observability (3)

| Command | Signature | 설명 |
|---------|-----------|------|
| /u-status | `/u-status [scope]` | 대시보드 (phase, 진행률, 미완료 항목, impact flags) |
| /u-coverage | `/u-coverage [scope]` | classified → 산출물 커버리지 리포트 |
| /u-trace | `/u-trace [scope] [id]` | raw → classified → docs 전체 추적 체인 |

#### Collaboration (1)

| Command | Signature | 설명 |
|---------|-----------|------|
| /u-discuss | `/u-discuss [scope] [type] "topic"` | 구조화된 협업 세션 (brainstorm/review/decision/workshop/retro) |

#### Review (1)

| Command | Signature | 설명 |
|---------|-----------|------|
| /u-assume | `/u-assume [scope] [action] [id]` | assumptions 리뷰(approve/reject) |

### Global Flags (모든 lifecycle command에 적용)

| Flag | 설명 |
|------|------|
| (없음) | config default (auto) |
| `-i` | interactive — 판단 분기에서만 pause |
| `--step` | step — 매 단계마다 확인 |
| `--only X` | 특정 산출물만 (srs, erd, fe, be...) |
| `--cascade` | 변경 시 의존 문서 자동 갱신 |
| `--verbose` | 상세 출력 |
| `--dry-run` | 실행 안 하고 계획만 표시 |
| `--json` | JSON 형식 출력 |
| `--review` | (/u-ingest) classified 항목 중 extracted를 FDE에게 리뷰 |
| `--incremental` | (/u-ingest) 신규분만 처리 |

---

## 7. Interaction Modes

### 3가지 Mode

| Mode | 동작 | 언제 |
|------|------|------|
| **auto** (default) | 질문 없이 끝까지 실행. 애매한 판단은 best-guess. 모든 판단을 assumptions log에 기록. | 일반 작업, 야간 배치 |
| **interactive** (`-i`) | 판단 분기에서만 pause. 단순 실행은 auto 속도. 중간에 "나머지 auto로" 전환 가능. | 중요한 의사결정, 아키텍처 설계 |
| **step** (`--step`) | 매 단계에서 pause. 결과 보여주고 승인 받음. | 최초 세팅, 학습, 디버깅 |

### Mode별 pause 매트릭스

| Situation | auto | interactive | step |
|-----------|------|-------------|------|
| 단순 문서 생성 | skip | skip | pause |
| 2개 이상 선택지 | best-guess + log | pause + ask | pause + ask |
| classified에 없는 정보 | skip + log gap | pause + ask | pause + ask |
| 기존 산출물과 충돌 | log conflict | pause + ask | pause + ask |
| 우선순위 판단 | 기존 규칙 적용 + log | pause + ask | pause + ask |
| **Phase gate 실패** | **pause (항상)** | **pause (항상)** | **pause (항상)** |
| **파괴적 변경** | **pause (항상)** | **pause (항상)** | **pause (항상)** |

### Assumptions Log

auto 모드의 핵심 안전장치. agent가 "질문 대신 판단"할 때마다 기록.

```json
{
  "id": "A-001",
  "agent": "planner",
  "context": "FR-012 결제 취소 범위",
  "question": "부분취소 포함 여부",
  "decided": "부분취소 포함",
  "rationale": "업계 관행상 부분취소가 일반적",
  "confidence": "medium",
  "impact": ["FR-012", "api.md", "test-cases.md"],
  "status": "pending-review"
}
```

Config:
```json
{
  "interaction": {
    "defaultMode": "auto",
    "alwaysPause": ["gate-failure", "destructive-change", "scope-change"],
    "assumptionsLog": true,
    "maxAssumptions": 20
  }
}
```

`maxAssumptions` 초과 시 자동으로 interactive 전환 (input 부족/모호 상태에서 억지로 밀어붙이기 방지).

---

## 8. /u-discuss — 구조화된 협업 세션

FDE의 암묵지 + Agent의 분석력을 세션 안에서 결합. 세션 결과는 자동으로 _classified/에 적재.

### 5가지 세션 타입

| Type | 목적 | 진행 방식 | Output |
|------|------|-----------|--------|
| **brainstorm** | 발산. 아이디어 수집. | 비판 금지. 모든 아이디어 기록. Agent가 연관 아이디어 확장. | ideas[] → _classified/requirements/ (extracted) |
| **review** | 수렴. 산출물 검토. | agent가 분석 결과 제시. FDE가 approve/revise/reject. | review comments + decisions |
| **decision** | 트레이드오프 결정. | agent가 선택지별 pros/cons/impact 분석. FDE가 최종 결정. 근거 필수. | decision record → _classified/decisions/ |
| **workshop** | 다단계 협업. brainstorm+decision 결합. | 발산 → 그룹핑 → 우선순위 → 결정. orchestrator가 단계 전환. | 복합 (ideas + decisions + requirements) |
| **retro** | 회고. iteration 종료 시. | Keep/Problem/Try. agent가 데이터 기반 분석. | retrospective record → docs/common/project/ |

### 세션 중 micro-commands

| Command | 설명 |
|---------|------|
| `@planner` | planner에게 직접 질문/의견 요청 |
| `@builder` | builder에게 기술적 판단 요청 |
| `@gatekeeper` | gatekeeper에게 검증/리스크 의견 요청 |
| `@all` | 모든 agent에게 의견 요청 (라운드 로빈) |
| `/idea [text]` | 아이디어 태깅 |
| `/decide [text]` | 결정사항 기록. 근거 필수. |
| `/concern [text]` | 우려/리스크 기록 |
| `/action [who] [text]` | 액션 아이템 기록 |
| `/next-phase` | 워크숍 다음 단계로 전환 |
| `/pause` | 세션 일시정지 |
| `/resume [session-id]` | 중단된 세션 재개 |

### 세션 결과 → pipeline 연결

`/u-discuss --wrap` 시:
- /idea 태그 → _classified/requirements/ (status: extracted)
- /decide 태그 → _classified/decisions/ (source: session)
- /concern 태그 → _classified/constraints/ 또는 questions/
- /action 태그 → 해당 문서에 TODO 플래그
- 전체 transcript → _sessions/ 아카이브

---

## 9. Folder Structure

### 설계 원칙

1. **Mirror principle**: monorepo의 apps/ 구조를 .u-maker/apps/가 1:1 미러링
2. **Inherit + override**: common/ 정책을 앱이 상속. 앱별 *-override.md로 선언적 덮어쓰기
3. **Scope-first navigation**: 모든 폴더에 _index.json. Claude가 파일 직접 열지 않고 index만 읽어서 판단

### Full Tree

```
.u-maker/
├── u-maker.config.json              # 전역 설정 (apps 목록, agents, modes, gates)
├── _links.json                       # cross-app 의존성 포함 전역 그래프
│
│ ## ── COMMON: 프로젝트 전체 공통 정책/자산 ──
│
├── common/
│   ├── _index.json                   # common 문서 목차 + 상태
│   │
│   ├── policy/                       # 서비스 정책
│   │   ├── service-policy.md         # 공통 서비스 운영 정책
│   │   ├── security-policy.md        # 보안 기준, 인증 정책
│   │   ├── privacy-policy.md         # 개인정보 처리 기준
│   │   ├── error-codes.md            # 공통 에러코드 체계
│   │   └── glossary.md               # 도메인 용어사전
│   │
│   ├── ux/                           # 공통 UX/UI 정책
│   │   ├── ux-guide.md               # UX 원칙, 접근성 기준
│   │   ├── design-token.md           # Color, Typography, Spacing, Radius
│   │   ├── design-token.json         # 토큰 JSON (코드에서 import)
│   │   ├── ui-components.md          # 공통 컴포넌트 명세
│   │   ├── icon-system.md            # 아이콘 규칙
│   │   └── responsive-grid.md        # 반응형 그리드 체계
│   │
│   ├── dev/                          # 공통 코딩 컨벤션
│   │   ├── coding-convention.md      # 네이밍, 폴더 구조, lint
│   │   ├── git-strategy.md           # 브랜치 전략, 커밋 규칙
│   │   ├── testing-strategy.md       # 테스트 레벨, 커버리지 기준
│   │   ├── ci-cd.md                  # 배포 파이프라인 정의
│   │   └── package-rules.md          # 공통 패키지 사용 규칙
│   │
│   ├── architecture/                 # 공통 아키텍처
│   │   ├── system-overview.md        # 전체 시스템 구성도
│   │   ├── erd-common.md             # 공통 테이블 (User, Auth, Audit...)
│   │   ├── api-common.md             # 공통 API 스펙 (인증, 파일업로드...)
│   │   └── infra.md                  # 인프라 구성
│   │
│   └── project/                      # 프로젝트 관리
│       ├── roadmap.md                # 마스터 로드맵
│       ├── roadmap.json
│       ├── stakeholders.md           # 이해관계자 맵
│       ├── iteration-log.md          # 전체 반복 이력
│       └── retrospective.md          # 회고
│
│ ## ── APPS: 앱별 독립 파이프라인 ──
│
├── apps/
│   ├── {app-name}/                   # 예: retail, corporate, backoffice, landing
│   │   ├── _index.json               # 이 앱의 문서 목차 + 상태 + 담당자
│   │   ├── app.config.json           # 앱별 설정 (담당자, override, techStack, phase)
│   │   │
│   │   ├── _input/                   # 이 앱 전용 raw data
│   │   │   ├── rfp/
│   │   │   ├── as-is/
│   │   │   ├── meeting-notes/
│   │   │   └── _manifest.json
│   │   │
│   │   ├── _classified/             # 이 앱 전용 정제 데이터
│   │   │   ├── requirements/
│   │   │   │   ├── _index.json
│   │   │   │   └── FR-001.json
│   │   │   ├── pain-points/
│   │   │   ├── workflows/
│   │   │   ├── screens/
│   │   │   ├── data-models/
│   │   │   ├── decisions/
│   │   │   ├── questions/
│   │   │   └── _summary.json
│   │   │
│   │   ├── _sessions/               # 이 앱 관련 토론
│   │   │   └── _index.json
│   │   │
│   │   ├── _assumptions/            # 이 앱의 assumptions
│   │   │   └── _index.json
│   │   │
│   │   ├── docs/                    # 이 앱의 산출물
│   │   │   ├── 01-plan/
│   │   │   │   ├── srs.md
│   │   │   │   ├── srs.json
│   │   │   │   ├── ia.md
│   │   │   │   └── roadmap.md       # 앱별 마일스톤
│   │   │   ├── 02-design/
│   │   │   │   ├── erd.md            # 앱 전용 테이블 (common ERD 참조)
│   │   │   │   ├── api.md            # 앱 BFF API
│   │   │   │   ├── screens.md
│   │   │   │   ├── screen-flow.md
│   │   │   │   └── ux-override.md   # 공통 UX에서 이 앱만 다른 것
│   │   │   ├── 03-dev/
│   │   │   │   ├── code.md
│   │   │   │   └── dev-override.md  # 앱별 코딩 예외
│   │   │   └── 04-check/
│   │   │       ├── test-cases.md
│   │   │       └── test-report.md
│   │   │
│   │   └── rtm.md                   # 이 앱의 추적 매트릭스
│   │
│   └── ... (다른 앱들도 동일 구조)
│
│ ## ── SHARED: 프로젝트 전체 공통 데이터 ──
│
├── _input/                           # 프로젝트 전체 공통 input
│   ├── rfp/                          # 통합 RFP (앱 공통 부분)
│   ├── benchmarks/
│   ├── links/
│   └── _manifest.json
│
├── _classified/                      # 공통/cross-app 정제 데이터
│   ├── requirements/                 # cross-app 요구사항 (SSO, 통합검색)
│   ├── domain-terms/                 # 프로젝트 전체 용어사전
│   ├── stakeholders/                 # 전체 이해관계자
│   ├── constraints/                  # 전체 제약사항 (법규, 보안)
│   ├── decisions/                    # cross-app 결정사항
│   └── _summary.json
│
├── _sessions/                        # cross-app 토론
│   └── _index.json
│
├── _assumptions/                     # cross-app assumptions
│   └── _index.json
│
│ ## ── INFRA: skills, agents, hooks, templates ──
│
├── _refer/
│   ├── templates/                    # 문서 템플릿
│   │   ├── srs.template.md
│   │   ├── ia.template.md
│   │   ├── screen.template.md
│   │   ├── erd.template.md
│   │   ├── api.template.md
│   │   ├── testcase.template.md
│   │   └── ...
│   ├── schemas/                      # JSON 스키마
│   │   ├── json-export.schema.json
│   │   ├── classified.schema.json
│   │   ├── session.schema.json
│   │   └── gate-rules.json
│   ├── session-protocols/            # 세션 타입별 진행 규칙
│   │   ├── brainstorm.md
│   │   ├── review.md
│   │   ├── decision.md
│   │   ├── workshop.md
│   │   └── retro.md
│   └── tech-rules.md
│
├── skills/                           # 12 engine skills
│   ├── engine-router/SKILL.md
│   ├── engine-phase-detector/SKILL.md
│   ├── engine-dep/SKILL.md
│   ├── engine-workflow-runner/SKILL.md
│   ├── engine-facilitator/SKILL.md
│   ├── engine-doc/SKILL.md
│   ├── engine-analyzer/SKILL.md
│   ├── engine-designer/SKILL.md
│   ├── engine-estimator/SKILL.md
│   ├── engine-code/SKILL.md
│   ├── engine-validator/SKILL.md
│   └── engine-test/SKILL.md
│
├── agents/                           # 4 agents
│   ├── u-agent-orchestrator/AGENT.md
│   ├── u-agent-planner/AGENT.md
│   ├── u-agent-builder/AGENT.md
│   └── u-agent-gatekeeper/AGENT.md
│
└── hooks/                            # 이벤트 훅
    ├── on-input-added.sh             # _input 파일 추가 → ingest 제안
    ├── on-doc-change.sh              # 문서 변경 → dep-engine cascade
    ├── on-gate-pass.sh               # gate 통과 → phase 전환
    ├── on-build-complete.sh          # build 완료 → auto-check 트리거
    └── on-session-wrap.sh            # 세션 종료 → classified 적재
```

### app.config.json 예시

```json
{
  "app": "retail",
  "displayName": "KB Star 개인뱅킹",
  "type": "mobile-app",
  "team": {
    "planner": "김기획",
    "designer": "이디자인",
    "fe": ["박프론트", "최프론트"],
    "be": ["정백엔드"],
    "qa": "한큐에이"
  },
  "inherits": "common",
  "overrides": {
    "ux": "docs/02-design/ux-override.md",
    "dev": "docs/03-dev/dev-override.md"
  },
  "techStack": {
    "framework": "React Native",
    "stateManagement": "zustand",
    "apiClient": "react-query"
  },
  "phase": "design",
  "iteration": 2
}
```

### Claude 탐색 경로 (scope-first)

`/u-plan retail` 일 때 Claude가 읽는 순서:
1. `u-maker.config.json` → apps 목록, 현재 mode 확인
2. `apps/retail/app.config.json` → 앱 설정, 담당자, phase
3. `apps/retail/_index.json` → 이 앱의 문서 목차 + 상태
4. `common/_index.json` → 공통 정책 목차 (필요한 것만 선택 로드)
5. `apps/retail/_classified/_summary.json` → 정제 데이터 통계
6. 필요한 파일만 개별 로드

---

## 10. u-maker.config.json 전역 설정

```json
{
  "version": "3.0.0",
  "project": {
    "name": "",
    "description": "",
    "type": "monorepo"
  },
  "theme": "light",
  "apps": [],
  "pdca": {
    "phases": ["plan", "design", "do", "check", "act"],
    "autoIterate": true,
    "maxIterations": 10,
    "gapThreshold": 90
  },
  "interaction": {
    "defaultMode": "auto",
    "alwaysPause": ["gate-failure", "destructive-change", "scope-change"],
    "assumptionsLog": true,
    "maxAssumptions": 20
  },
  "conventions": {
    "naming": {
      "components": "PascalCase",
      "functions": "camelCase",
      "constants": "UPPER_SNAKE_CASE",
      "files": "kebab-case"
    },
    "documentHeader": {
      "required": ["Owner", "Status", "Version", "Last Updated", "Related Docs"]
    },
    "statusValues": ["Draft", "Review", "Final"]
  },
  "jsonExport": {
    "enabled": true,
    "description": "마크다운 문서 생성/갱신 시 동명의 .json 파일을 함께 생성"
  },
  "reservedWords": {
    "scopes": ["common", "all"],
    "targets": ["srs", "ia", "erd", "api", "screens", "screen-flow", "roadmap", "rtm", "ux-guide", "design-token", "test-cases", "test-report", "code"],
    "types": ["brainstorm", "review", "decision", "workshop", "retro", "approve", "reject"]
  }
}
```

`theme`은 `light | dark` 두 값만 허용하며, u-maker가 생성하는 모든 HTML 산출물의 기본 테마로 사용한다. 지정하지 않으면 기본값은 `light`다.

---

## 11. 실전 커맨드 예시

```bash
## ── 프로젝트 시작 ──
/u-init kb-banking

## ── Plan phase ──
/u-ingest retail                          # retail raw data 분석
/u-ingest retail --review                 # 분석 결과 리뷰
/u-plan retail                            # SRS + IA + Roadmap 자동 생성
/u-plan retail -i                         # interactive로 같이 보면서
/u-plan retail --only srs                 # SRS만
/u-plan common                            # 공통 정책 문서 생성
/u-add retail fr "비밀번호 재설정"          # FR 추가
/u-discuss retail brainstorm "결제 UX"     # 브레인스토밍
/u-gate retail                            # plan → design gate 검증

## ── Design phase ──
/u-design retail                          # ERD + API + Screen + Flow
/u-design retail --only screens           # Screen만
/u-design retail,corporate -i             # 2개 앱 interactive
/u-discuss retail workshop "메인 IA"       # IA 워크숍
/u-discuss common decision "인증 방식"     # 공통 아키텍처 결정
/u-sync retail                            # 일관성 검증

## ── Build phase ──
/u-dev retail                           # FE + BE 코드 생성
/u-dev retail --only fe                 # FE만
/u-dev landing                          # landing은 auto

## ── Check phase ──
/u-qa retail                           # TC 생성 + 테스트
/u-qa retail -i                        # 결과 같이 보면서

## ── Ship phase ──
/u-ship retail                            # 최종 검증 + 배포 + 회고
/u-discuss retail retro                   # 회고 세션

## ── 일상 작업 ──
/u-status                                 # 전체 대시보드
/u-status retail                          # retail 상태
/u-status retail --assumptions            # 미리뷰 assumptions
/u-assume retail approve A-001            # assumption 승인
/u-assume retail reject A-001 "전체취소만" # assumption 거부 → cascade
/u-update retail srs --cascade            # SRS 수정 + 의존 문서 갱신
/u-doc retail screens                     # Screen 문서 조회
/u-trace retail FR-015                    # FR-015 전체 추적
/u-coverage all                           # 전체 앱 커버리지
/u-sync all                               # 전체 일관성 검증
```

---

## 12. 구현 지시사항

### Claude Code Plugin으로 구현 시 해야 할 것

1. **CLAUDE.md 생성**: 프로젝트 루트에 CLAUDE.md 작성. 이 문서의 핵심 내용을 포함하여 Claude가 `/u-*` 커맨드를 인식하도록 한다.

2. **폴더 구조 초기화 로직**: `/u-init` 실행 시 위 folder tree를 자동 생성하는 스크립트.

3. **Agent AGENT.md 작성**: 각 agent 폴더에 역할, 소유 skill, 라우팅 규칙, 활동 phase를 정의.

4. **Skill SKILL.md 작성**: 각 skill 폴더에 skill의 입출력, 실행 절차, 의존성, 에러 처리를 정의.

5. **Template 작성**: `_refer/templates/`에 각 문서 타입의 마크다운 템플릿. doc-engine이 렌더링.

6. **Schema 작성**: `_refer/schemas/`에 classified 항목, session, gate-rules 등의 JSON 스키마.

7. **Session Protocol 작성**: `_refer/session-protocols/`에 5가지 세션 타입의 진행 규칙.

8. **Config 생성**: `u-maker.config.json` 기본 템플릿. `/u-init` 시 프로젝트 정보 입력받아 생성.

9. **_index.json 자동 갱신**: doc-engine이 파일 CRUD할 때마다 해당 폴더의 _index.json 자동 업데이트.

10. **_links.json 관리**: dep-engine이 문서 간 참조 관계를 추적하는 전역 의존성 그래프. 문서 생성/수정 시 자동 갱신.

### 우선순위

1단계 (MVP): `/u-init`, `/u-ingest`, `/u-plan`, `/u-status`, `/u-doc` + orchestrator + planner + doc-engine + analyzer
2단계: `/u-design`, `/u-dev`, `/u-gate`, `/u-sync` + builder + gatekeeper + validator + code-engine
3단계: `/u-discuss`, `/u-qa`, `/u-ship`, `/u-assume` + facilitator + test-engine + workflow-runner
4단계: `/u-coverage`, `/u-trace`, `/u-add`, `/u-update` + dep-engine + diff-engine + estimator

### 핵심 제약

- 모든 산출물은 `.u-maker/` 하위에만 저장
- 모든 마크다운 문서는 동명의 .json 파일을 함께 생성 (다른 agent가 프로그래밍적으로 참조)
- classified 항목에는 반드시 `source: {file, page, section}` 메타데이터 포함
- _index.json은 파일 CRUD 시 자동 갱신
- auto 모드에서 판단한 내용은 반드시 assumptions log에 기록
- phase gate 실패와 파괴적 변경은 mode 무관하게 항상 pause
- 앱 이름 등록 시 예약어 충돌 검증 필수
