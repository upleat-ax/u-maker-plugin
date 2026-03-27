# u-maker Plugin

PDCA 기반 SSoT(Single Source of Truth) 협업 오케스트레이터.
4개 전문 에이전트와 3-Layer 파이프라인으로 소프트웨어 개발 전 과정을 자동화하는 Claude Code 플러그인.

- Plugin version: `2.0.0`
- SSoT config version: `3.0.0`
- Skills: `36` (12 engine + 19 command + 4 agent-direct + 1 router) | Agents: `4` | Templates: `72` | References: `18` | Schemas: `7`
- [시작 가이드 (초보자용)](GET_STARTED.md)

---

## TL;DR

```bash
# 1. 설치 (macOS/Linux)
curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.sh | bash

# 2. Claude Code 재시작 후 프로젝트에서 실행
/u-skill-create-project my-app    # 새 프로젝트
/u-skill-init .                   # 기존 프로젝트 역공학

# 3. 데이터 수집 → 분석 → 계획
/u-ingest retail          # raw data → classified 분석
/u-plan retail            # SRS + IA + Roadmap 자동 생성

# 4. 설계 → 구현 → 검증
/u-design retail          # ERD + API + Screen + Flow
/u-build retail           # FE + BE 코드 생성
/u-check retail           # TC 설계 + 테스트 + 리포트

# 5. 자동 PDCA 루프
/u-skill-loop             # Plan→Do→Check→Act 자동 반복

# 또는 자연어로
"retail 앱의 SRS를 만들어줘"   # u-maker 라우터가 자동 분배
```

---

## Table of Contents

1. [What This Plugin Solves](#1-what-this-plugin-solves)
2. [Architecture Overview](#2-architecture-overview)
3. [PDCA 5-Phase Process](#3-pdca-5-phase-process)
4. [3-Layer Data Pipeline](#4-3-layer-data-pipeline)
5. [Agents (4개)](#5-agents)
6. [Commands (19개)](#6-commands)
7. [Engine Skills (12개)](#7-engine-skills)
8. [Interaction Modes](#8-interaction-modes)
9. [4-Tier ID Hierarchy](#9-4-tier-id-hierarchy)
10. [Folder Structure (.u-maker/)](#10-folder-structure)
11. [Document Output Rules](#11-document-output-rules)
12. [Plugin Repository Layout](#12-plugin-repository-layout)
13. [Hooks & Guardrails](#13-hooks--guardrails)
14. [Scenario Guide — 언제 어떤 명령어를?](#14-scenario-guide)
15. [Prerequisites & Install](#15-prerequisites--install)
16. [Troubleshooting](#16-troubleshooting)
17. [License](#17-license)

---

## 1. What This Plugin Solves

u-maker는 **Intent-driven 문서 중심 개발(SSoT)**을 구현하는 협업 오케스트레이터이다.

### 기존 방식 vs u-maker v2

| 기존 방식 | u-maker v2 방식 |
|----------|----------------|
| 코드 먼저, 문서는 나중에 | 문서 먼저, 코드는 문서 기반 생성 (Docs-First) |
| RFP 200페이지를 한 번에 분석 → 앞부분 loss | 3-Layer 파이프라인으로 chunk 분석 → 정보 손실 없음 |
| "무슨 문서를 만들어야 하지?" | `/u-plan retail` 한 번이면 SRS+IA+Roadmap 연쇄 생성 |
| 요구사항 추적 불가 | 4-Tier ID(USR→FR→US→FT)로 전 구간 추적 |
| SRS 수정 시 ERD/Screen/TC 수동 갱신 | `_links.json` 의존성 그래프로 Auto-Cascade |
| 단계 건너뛰기로 품질 저하 | Phase Gate 자동 검증 후에만 다음 Phase 진행 |
| 문서와 코드 버전 불일치 | `.md` + `.json` 동시 생성 |
| 앱마다 다른 규칙 | common/ 정책 상속 + 앱별 override |
| AI 판단이 블랙박스 | Assumptions Log로 모든 판단 기록 + 사후 리뷰 |

---

## 2. Architecture Overview

```
USER INPUT
    │
    ├── /u-{cmd} [scope] [target] [flags]     ← slash command
    │       └─→ u-{cmd}/SKILL.md
    │               ├─→ engine-router (scope 해석)
    │               ├─→ engine-* (필요한 엔진)
    │               └─→ u-agent-* (에이전트 dispatch)
    │
    ├── /u-agent-{name} "자유 형식 요청"       ← agent direct
    │       └─→ 에이전트 직접 호출
    │
    └── 자연어 요청                             ← natural language
            └─→ u-maker (NL router) → /u-* command 변환
```

### 3-Tier Skill Naming

| Prefix | 용도 | user-invocable | 수 |
|--------|------|----------------|-----|
| `u-*` | Command (slash command) | Yes | 19 |
| `engine-*` | Internal engine | No | 12 |
| `u-agent-*` | Agent direct invocation | Yes | 4 |
| `u-maker` | NL router + help | Yes | 1 |

---

## 3. PDCA 5-Phase Process

```
Plan → Design → Do → Check → Act
  ↑                              |
  └──────── iteration ───────────┘
```

> Config에서 4-Phase(Design을 Do에 통합) 선택 가능: `designPhase: "merged"`

### Phase 정의

| Phase | 산출물 | 담당 Agent | Gate 조건 |
|-------|--------|------------|-----------|
| **01 Plan** | SRS, IA, Roadmap, Wireframe | orchestrator→planner→guardian | SRS+IA+Roadmap = Final |
| **02 Design** | ERD, API, Screen, ScreenFlow, UXGuide, RTM | planner→guardian | ERD+RTM+Screen+API = Final |
| **03 Do** | Code, UIComponents, Screen(impl) | builder | Code complete + build success |
| **04 Check** | TestCase, TestReport | guardian | Critical/Major=0, all FR impl |
| **05 Act** | IterationLog, Retrospective | orchestrator→guardian | Retro + archive 완료 |

---

## 4. 3-Layer Data Pipeline

raw data를 한 번에 처리하면 context window 한계로 앞부분이 loss된다. 중간 정제 레이어를 두어 해결:

```
_input/ (Raw)  →  _classified/ (Structured JSON)  →  docs/ (Deliverables)
  RFP, 회의록        requirements/, workflows/          SRS, ERD, Screen
  AS-IS 자료         pain-points/, screens/             API, TestCase
  인터뷰 노트        decisions/, constraints/           Roadmap, RTM
```

### _classified 10개 카테고리

| 카테고리 | ID 패턴 | 입력 소스 |
|----------|---------|-----------|
| requirements/ | FR-nnn, NR-nnn | RFP, 회의록 |
| pain-points/ | PP-nnn | 인터뷰 |
| domain-terms/ | DT-nnn | RFP, AS-IS |
| stakeholders/ | SH-nnn | RFP |
| workflows/ | WF-nnn | AS-IS workflows |
| screens/ | SC-nnn | AS-IS screens |
| data-models/ | DM-nnn | AS-IS DB |
| constraints/ | CN-nnn | RFP, 법규 |
| decisions/ | DC-nnn | 회의록, /u-discuss |
| questions/ | QS-nnn | 분석 중 발생 |

### 항목 Lifecycle

`extracted` → `validated` → `adopted` / `rejected`

---

## 5. Agents

4개 전문 에이전트가 Phase별 역할을 분담한다.

| Agent | Model | Role | Phase |
|-------|-------|------|-------|
| `u-agent-orchestrator` | opus | Command router, Phase controller, State machine, _links.json 관리 | ALL |
| `u-agent-planner` | sonnet | 분석 + 설계 (SRS, IA, ERD, API, Screen, UX) | Plan, Design |
| `u-agent-builder` | sonnet | FE + BE 통합 구현 | Do |
| `u-agent-guardian` | sonnet | Gate 검증, TestCase, 일관성 검증, RTM | Design, Do, Check, Act |

### Agent 호출 방법

```bash
# 1. Command를 통한 정형화된 호출
/u-plan retail                # orchestrator → planner가 SRS+IA+Roadmap 생성

# 2. Agent Direct 호출 (자유 형식)
/u-agent-planner "ERD를 PostgreSQL 기준으로 최적화해줘"
/u-agent-builder "로그인 폼 유효성 검사 추가해줘"
/u-agent-guardian "인증 관련 TC를 보강해줘"
```

---

## 6. Commands

### Grammar

```
/u-{command} [scope] [target] [flags]
```

- **scope**: 앱 이름 | `common` | `all` | 생략 (자동 선택)
- **target**: 문서/항목 이름
- **flags**: `-i` (interactive) | `--step` | `--only X` | `--cascade` | `--dry-run` | `--json`

### 6.1 Lifecycle (7)

| Command | Description |
|---------|-------------|
| `/u-init [project-name]` | .u-maker/ 구조 생성, config 초기화, 앱 등록 |
| `/u-ingest [scope]` | _input/ raw data → _classified/ 분석 적재 |
| `/u-plan [scope]` | classified → SRS + IA + Roadmap 연쇄 생성 |
| `/u-design [scope]` | SRS/IA → ERD + API + Screen + Flow + UXGuide |
| `/u-build [scope]` | 명세 기반 코드 생성 (FE + BE + DB) |
| `/u-check [scope]` | TC 설계 + 테스트 실행 + Report + exit criteria |
| `/u-ship [scope]` | 최종 검증 + iteration log + retrospective |

### 6.2 Operations (5)

| Command | Description |
|---------|-------------|
| `/u-add [scope] [type] "title"` | 항목 추가 (FR/NR/US/Screen 등) |
| `/u-update [scope] [doc]` | 문서 수정 + cascade 자동 전파 |
| `/u-doc [scope] [doc]` | 특정 문서 조회/편집/재생성 |
| `/u-sync [scope]` | 전체 문서 일관성 검증 + 수정 제안 |
| `/u-gate [scope]` | Phase gate 검사 + 전환 |

### 6.3 Observability (3)

| Command | Description |
|---------|-------------|
| `/u-status [scope]` | 대시보드 (phase, 진행률, impact flags) |
| `/u-coverage [scope]` | classified → 산출물 커버리지 리포트 |
| `/u-trace [scope] [id]` | raw → classified → docs 추적 체인 |

### 6.4 Collaboration (1) + Review (1)

| Command | Description |
|---------|-------------|
| `/u-discuss [scope] [type] "topic"` | 구조화된 협업 세션 (brainstorm/review/decision/workshop/retro) |
| `/u-assume [scope] [action] [id]` | assumptions 리뷰 (approve/reject) |

### Global Flags

| Flag | 설명 |
|------|------|
| `-i` | interactive mode — 판단 분기에서만 pause |
| `--step` | step mode — 매 단계마다 확인 |
| `--only X` | 특정 산출물만 (srs, erd, fe, be...) |
| `--cascade` | 변경 시 의존 문서 자동 갱신 |
| `--dry-run` | 실행 안 하고 계획만 표시 |
| `--json` | JSON 형식 출력 |
| `--incremental` | (/u-ingest) 신규분만 처리 |
| `--review` | (/u-ingest) extracted 항목 리뷰 |

---

## 7. Engine Skills

12개 횡단 엔진. user-invocable이 아니며, command skill이 내부적으로 호출한다.

### Core Engines (orchestrator 소속)

| Engine | 역할 |
|--------|------|
| engine-router | Intent 분류, scope 해석, agent dispatch |
| engine-phase-detector | 문서 status 집계 → phase 자동 판정 |
| engine-dep | `_links.json` 의존성 그래프, cascade 전파 |
| engine-workflow-runner | Multi-step 실행, rollback, progress |
| engine-facilitator | /u-discuss 세션 퍼실리테이션 |

### Domain Engines (planner 소속)

| Engine | 역할 |
|--------|------|
| engine-doc | 모든 문서 CRUD, 템플릿 렌더링, JSON export |
| engine-analyzer | Raw 파싱, chunk 분석, classified 적재 |
| engine-designer | IA/Screen/ERD/API 통합 설계 |
| engine-estimator | SRS 기반 일정/공수 산정 |

### Execution Engines (builder+guardian 소속)

| Engine | 역할 |
|--------|------|
| engine-code | 명세 → 코드 생성 (FE+BE), scaffold |
| engine-validator | Gate check, cross-doc 일관성 |
| engine-test | TC 자동 생성, 실행, 리포트 |

---

## 8. Interaction Modes

| Mode | Flag | 동작 |
|------|------|------|
| **auto** | (default) | 질문 없이 실행. 판단은 Assumptions Log에 기록 |
| **interactive** | `-i` | 판단 분기에서만 pause. 나머지는 auto 속도 |
| **step** | `--step` | 매 단계에서 pause + 승인 |

### Assumptions Log

auto 모드에서 agent가 "질문 대신 판단"할 때마다 기록하는 안전장치.

```bash
/u-status retail --assumptions    # 미리뷰 assumptions 확인
/u-assume retail approve A-001    # 승인
/u-assume retail reject A-001 "전체취소만"  # 거부 → cascade 수정
```

`maxAssumptions` (default: 20) 초과 시 자동으로 interactive 전환.

---

## 9. 4-Tier ID Hierarchy

```
USR-0001 (User Type: 관리자, 일반 사용자)
  └── FR-0001 (Functional Req: 회원가입 기능)
        └── US-0001 (User Story: 이메일로 회원가입하고 싶다)
              └── FT-0001 (Feature = 구현 단위: 이메일 인증 구현)
```

> FT = **Feature** (구현 단위). ~~Functional Test~~ 절대 아님.

---

## 10. Folder Structure

### .u-maker/ (프로젝트)

```
.u-maker/
├── u-maker.config.json              # 전역 설정
├── _links.json                       # 의존성 그래프
│
├── common/                           # 프로젝트 전체 공통
│   ├── _index.json
│   ├── policy/                       # 서비스/보안/개인정보/에러코드/용어
│   ├── ux/                           # UX Guide, Design Token, UI Components
│   ├── dev/                          # Coding Convention, Git Strategy, Testing
│   ├── architecture/                 # System Overview, ERD, API, Infra
│   └── project/                      # Roadmap, Stakeholders, Iteration Log
│
├── apps/{app-name}/                  # 앱별 독립 파이프라인
│   ├── _index.json                   # 앱 문서 목차 + 상태
│   ├── app.config.json               # 앱별 설정
│   ├── _input/                       # Layer 1: Raw data
│   ├── _classified/                  # Layer 2: 정제 데이터 (10 categories)
│   ├── _sessions/                    # 토론 세션 아카이브
│   ├── _assumptions/                 # 가정 로그
│   ├── docs/                         # Layer 3: 산출물
│   │   ├── 01-plan/                  # srs.md, ia.md, roadmap.md
│   │   ├── 02-design/               # erd.md, api.md, screen.md, screen-flow.md
│   │   ├── 03-dev/                  # code.md
│   │   └── 04-check/               # test-cases.md, test-report.md
│   └── rtm.md                       # 추적 매트릭스
│
├── _input/                           # 프로젝트 공통 raw data
├── _classified/                      # 공통 classified
├── _sessions/                        # cross-app 토론
└── _assumptions/                     # cross-app assumptions
```

### Scope-First Navigation

Claude는 파일을 직접 열지 않고 `_index.json`만 먼저 읽어서 필요한 파일만 선택적 로드 → context window 절약.

---

## 11. Document Output Rules

| Extension | Purpose | 생성 조건 |
|-----------|---------|----------|
| `.md` | 사람이 읽는 마크다운 (SSoT 원본) | 모든 문서 |
| `.json` | 기계가 파싱하는 구조화 데이터 | 모든 문서와 동시 생성 |

### Document Status Lifecycle

```
Draft → Review → Final
```

### Auto-Cascade

SRS 변경 시 `_links.json` 기반으로 ERD, Screen, TestCase에 impact flag 자동 전파.
`/u-update --cascade`로 의존 문서 자동 갱신.

---

## 12. Plugin Repository Layout

```
u-maker-plugin/
├── .claude-plugin/plugin.json        # v2.0.0
├── agents/                           # 4 agent definitions
│   ├── u-agent-orchestrator.md
│   ├── u-agent-planner.md
│   ├── u-agent-builder.md
│   └── u-agent-guardian.md
├── skills/
│   ├── engine-*/SKILL.md             # 12 internal engines
│   ├── u-*/SKILL.md                  # 19 command skills (user-invocable)
│   ├── u-agent-*/SKILL.md            # 4 agent-direct skills
│   └── u-maker/SKILL.md              # NL router
├── shared/references/                # 18 reference documents
├── schemas/                          # 7 JSON schemas
├── templates/
│   ├── 01-plan/ ~ 05-act/           # 22 phase templates
│   ├── classified/                   # 10 classified item schemas
│   ├── config/                       # 4 config templates
│   ├── session/                      # 5 session templates
│   └── common/                       # 9 common policy templates
├── hooks/                            # Event hooks
│   ├── hooks.json
│   ├── session-start.js
│   ├── on-input-added.js
│   ├── on-doc-change.js
│   ├── on-gate-pass.js
│   └── on-session-wrap.js
└── scripts/                          # Guard scripts
    ├── prompt-docs-first-guard.js
    ├── pre-write-guard.js
    ├── post-write-index.js
    └── stop-state-save.js
```

---

## 13. Hooks & Guardrails

| Event | Script | 동작 |
|-------|--------|------|
| **SessionStart** | `session-start.js` | .u-maker/ 구조 자동 생성/복구 |
| **UserPromptSubmit** | `prompt-docs-first-guard.js` | 새 기능 감지 → 문서 먼저 수정 요구 |
| **PreToolUse(Write\|Edit)** | `pre-write-guard.js` | SSoT 문서 경로 + tech stack 위반 검증 |
| **PostToolUse(Write)** | `post-write-index.js` | 문서 쓰기 후 _index.json 갱신 알림 |
| **PostToolUse(Write)** | `on-input-added.js` | _input/ 파일 감지 → /u-ingest 제안 |
| **PostToolUse(Write\|Edit)** | `on-doc-change.js` | _links.json 기반 cascade impact 알림 |
| **PostToolUse(Write)** | `on-gate-pass.js` | Gate 조건 충족 → phase 전환 제안 |
| **PostToolUse(Write)** | `on-session-wrap.js` | 세션 완료 → _classified 적재 알림 |
| **Stop** | `stop-state-save.js` | 세션 상태 저장 + assumptions 카운트 |

---

## 14. Scenario Guide — 언제 어떤 명령어를?

### 프로젝트 시작

| 상황 | 명령어 |
|------|--------|
| 완전히 새로운 프로젝트 시작 | `/u-init my-project` |
| 기존 RFP/회의록 자료가 있음 | `/u-init` → `_input/`에 파일 복사 → `/u-ingest retail` |
| 분석된 데이터 리뷰하고 싶음 | `/u-ingest retail --review` |
| 신규분만 추가 분석 | `/u-ingest retail --incremental` |

### 기획 (Plan Phase)

| 상황 | 명령어 |
|------|--------|
| Plan Phase 전체 실행 | `/u-plan retail` |
| SRS만 생성 | `/u-plan retail --only srs` |
| 같이 보면서 만들고 싶음 | `/u-plan retail -i` |
| 매 단계 확인하면서 진행 | `/u-plan retail --step` |
| 공통 정책 문서 생성 | `/u-plan common` |
| 기능 요구사항 추가 | `/u-add retail fr "비밀번호 재설정"` |
| 유저 스토리 추가 | `/u-add retail us "비밀번호 재설정하고 싶다"` |
| 브레인스토밍 | `/u-discuss retail brainstorm "결제 UX"` |
| Plan→Design gate 검증 | `/u-gate retail` |

### 설계 (Design Phase)

| 상황 | 명령어 |
|------|--------|
| Design Phase 전체 실행 | `/u-design retail` |
| Screen만 생성 | `/u-design retail --only screens` |
| 2개 앱 interactive | `/u-design retail,corporate -i` |
| IA 워크숍 | `/u-discuss retail workshop "메인 IA"` |
| 공통 인증 방식 결정 | `/u-discuss common decision "인증 방식"` |
| 일관성 검증 | `/u-sync retail` |

### 구현 (Do Phase)

| 상황 | 명령어 |
|------|--------|
| FE+BE 코드 생성 | `/u-build retail` |
| FE만 생성 | `/u-build retail --only fe` |
| 에이전트에게 직접 요청 | `/u-agent-builder "로그인 폼 유효성 검사 추가"` |

### 검증 (Check Phase)

| 상황 | 명령어 |
|------|--------|
| TC 설계 + 테스트 | `/u-check retail` |
| interactive로 결과 확인 | `/u-check retail -i` |

### 배포 + 회고 (Act Phase)

| 상황 | 명령어 |
|------|--------|
| 최종 검증 + 배포 + 회고 | `/u-ship retail` |
| 회고 세션 | `/u-discuss retail retro` |

### 일상 운영

| 상황 | 명령어 |
|------|--------|
| 전체 프로젝트 대시보드 | `/u-status` |
| 특정 앱 상태 | `/u-status retail` |
| 미리뷰된 assumptions 확인 | `/u-status retail --assumptions` |
| assumption 승인 | `/u-assume retail approve A-001` |
| assumption 거부 (cascade) | `/u-assume retail reject A-001 "전체취소만"` |
| SRS 수정 + 하위 문서 갱신 | `/u-update retail srs --cascade` |
| 특정 문서 조회 | `/u-doc retail screens` |
| FR-015 전체 추적 | `/u-trace retail FR-015` |
| 전체 커버리지 | `/u-coverage all` |
| 전체 일관성 검증 | `/u-sync all` |

### /u-discuss 세션

| 상황 | 명령어 |
|------|--------|
| 아이디어 발산 | `/u-discuss retail brainstorm "결제 UX"` |
| 산출물 리뷰 | `/u-discuss retail review` |
| 기술 결정 | `/u-discuss common decision "DB 선택"` |
| 다단계 워크숍 | `/u-discuss retail workshop "메인 화면 설계"` |
| Iteration 회고 | `/u-discuss retail retro` |

세션 중 사용 가능한 micro-commands:

| Command | 설명 |
|---------|------|
| `@planner` / `@builder` / `@guardian` | 특정 에이전트에게 질문 |
| `@all` | 모든 에이전트에게 의견 요청 |
| `/idea [text]` | 아이디어 태깅 |
| `/decide [text]` | 결정사항 기록 |
| `/concern [text]` | 우려/리스크 기록 |
| `/action [who] [text]` | 액션 아이템 기록 |
| `/wrap` | 세션 종료 + _classified 적재 |

### 자연어로도 가능

명령어를 모르겠으면 자연어로 말해도 된다:

```
"retail 앱의 SRS를 만들어줘"           → /u-plan retail --only srs
"ERD를 PostgreSQL로 최적화해줘"       → /u-agent-planner ...
"테스트 케이스 만들어줘"               → /u-check retail
"지금 프로젝트 상태가 어때?"           → /u-status
```

---

## 15. Prerequisites & Install

| 도구 | 용도 | 필수 |
|------|------|------|
| **Claude Code** | u-maker 기반 환경 | Yes |
| **Node.js** | Hook, Guard 스크립트 실행 | Yes |

### 설치

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.sh | bash

# 업데이트
curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/update.sh | bash

# 로컬 개발
cd /path/to/u-maker-plugin && ./deploy_local.sh
```

> 설치/업데이트 후 반드시 **Claude Code를 재시작**하세요.

---

## 16. Troubleshooting

| 증상 | 해결 |
|------|------|
| `/u-plan`이 인식 안 됨 | Claude Code 재시작 후 재시도 |
| Hook이 매번 차단함 | 문서를 먼저 수정하세요 (Docs-First 원칙) |
| scope 해석이 틀림 | `u-maker.config.json`의 `apps[]`에 앱이 등록되었는지 확인 |
| auto 모드에서 자꾸 interactive로 전환됨 | `maxAssumptions` 초과. `/u-assume`로 리뷰하세요 |
| cascade 알림이 많음 | `/u-sync`로 한 번에 정리하거나 `/u-update --cascade`로 자동 갱신 |

---

## 17. License

MIT
