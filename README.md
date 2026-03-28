# U-MAKER Plugin

PDCA 기반 SSoT(Single Source of Truth) 협업 오케스트레이터.
4개 전문 에이전트와 3-Layer 파이프라인으로 소프트웨어 개발 전 과정을 자동화하는 Claude Code 플러그인.

- Plugin version: `3.0.20`
- Skills: `38` (13 engine + 24 command + 1 NL router) | Agents: `4`
- [시작 가이드 (초보자용)](GET_STARTED.md) | [한국어 HTML](README.ko.html) | [English HTML](README.en.html)

---

## TL;DR

### Forward Engineering (새 프로젝트)

```bash
# 1. 설치 (macOS/Linux)
curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.sh | bash

# 2. Claude Code 재시작 후 프로젝트에서 실행
/u-init my-app                # .u-maker/ 구조 생성 + 앱 등록

# 3. 데이터 수집 → 분석 → 계획
# → _input/raw/에 RFP, 회의록, AS-IS 자료 드롭 (자동 분류)
/u-ingest [app]              # raw → classified 분석
/u-plan [app]                # SRS + IA + Roadmap 자동 생성

# 4. 설계 → 구현 → 검증
/u-design [app]              # ERD + API + Screen + Flow + RTM + wireframes
/u-dev [app]                 # FE + BE + DB 코드 생성
/u-qa [app]               # TC 설계 + 테스트 + 리포트

# 5. 배포 + 회고
/u-ship [app]                # 최종 검증 + iteration log + retrospective
```

### Reverse Engineering (기존 프로젝트)

```bash
/u-init my-app                # 프로젝트 초기화
/u-reverse [app]             # 소스 코드 → SSoT 역공학 (ERD, API, Screen, SRS 등)
/u-sync [app]                # 문서 간 정합성 검증
```

### 자연어로도 가능

```bash
"[app] 앱의 SRS를 만들어줘"      # U-MAKER 라우터가 자동 분배
```

---

## Table of Contents

1. [What This Plugin Solves](#1-what-this-plugin-solves)
2. [Architecture Overview](#2-architecture-overview)
3. [PDCA 5-Phase Process](#3-pdca-5-phase-process)
4. [3-Layer Data Pipeline](#4-3-layer-data-pipeline)
5. [Agents (4개)](#5-agents)
6. [Commands (22개)](#6-commands)
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

U-MAKER는 **Intent-driven 문서 중심 개발(SSoT)**을 구현하는 협업 오케스트레이터이다.

### 기존 방식 vs U-MAKER v3

| 기존 방식 | U-MAKER v3 방식 |
|----------|----------------|
| 코드 먼저, 문서는 나중에 | 문서 먼저, 코드는 문서 기반 생성 (Docs-First) |
| 기존 프로젝트에 문서가 없음 | `/u-reverse`로 소스 코드 → SSoT 자동 역공학 |
| RFP 200페이지를 한 번에 분석 → 앞부분 loss | 3-Layer 파이프라인으로 chunk 분석 → 정보 손실 없음 |
| "무슨 문서를 만들어야 하지?" | `/u-plan [app]` 한 번이면 SRS+IA+Roadmap 연쇄 생성 |
| 요구사항 추적 불가 | 4-Tier ID(USR→FR→US→FT)로 전 구간 추적 |
| SRS 수정 시 ERD/Screen/TC 수동 갱신 | `_links.json` 의존성 그래프로 Auto-Cascade |
| 단계 건너뛰기로 품질 저하 | Phase Gate 자동 검증 후에만 다음 Phase 진행 |
| 파일 분류가 번거로움 | `_input/raw/`에 드롭하면 자동 분류 (rfp/, as-is/ 등) |
| 문서와 코드 버전 불일치 | `.md` + `.json` 동시 생성 |
| 앱마다 다른 규칙 | common/ 정책 상속 + 앱별 override |
| AI 판단이 블랙박스 | Assumptions Log로 모든 판단 기록 + 사후 리뷰 |
| 문서 언어가 고정 | `language.documents` 설정으로 ko/en/ja/zh 지원 |
| 설계 산출물 시각화 어려움 | `wireframes/index.html` SPA 뷰어 자동 생성 |
| PR/MR 작성이 반복 노동 | `/u-git-pr`로 구조화된 PR/MR 자동 생성 |
| 궁금한 점을 어디에 물어봐야 할지 모름 | `/u-ask`로 가볍게 Q&A |

---

## 2. Architecture Overview

```
USER INPUT
    │
    ├── /u-{cmd} [scope] [target] [flags]     ← slash command
    │       └─→ u-{cmd}/SKILL.md
    │               ├─→ u-skill-router (scope 해석)
    │               ├─→ u-skill-* (필요한 엔진)
    │               └─→ u-agent-* (에이전트 dispatch)
    │
    └── 자연어 요청                             ← natural language
            └─→ u-maker (NL router) → /u-* command 변환
```

### Skill Naming Convention

| Prefix | 용도 | User-invocable | 수 |
|--------|------|----------------|-----|
| `u-*` | Command (slash command) | Yes | 22 |
| `u-skill-*` | Internal engine | No | 12 |
| `u-skill-router` | Intent router | No | 1 |
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
| **01 Plan** | SRS, IA, Roadmap | orchestrator→planner→guardian | SRS+IA+Roadmap = Final |
| **02 Design** | ERD, API, Screen, ScreenFlow, UXGuide, RTM, wireframes/index.html | planner→guardian | ERD+RTM+Screen+API = Final |
| **03 Do** | Code, UIComponents, Screen(impl) | builder | Code complete + build success |
| **04 Check** | TestCase, TestReport | guardian | Critical/Major=0, all FR impl |
| **05 Act** | IterationLog, Retrospective | orchestrator→guardian | Retro + archive 완료 |

---

## 4. 3-Layer Data Pipeline

raw data를 한 번에 처리하면 context window 한계로 앞부분이 loss된다. 중간 정제 레이어를 두어 해결:

```
_input/ (Raw)  →  _classified/ (Structured JSON)  →  docs/ (Deliverables)
  raw/               requirements/, workflows/          SRS, ERD, Screen
  rfp/               pain-points/, screens/             API, TestCase
  as-is/             decisions/, constraints/           Roadmap, RTM
  interviews/        domain-terms/, stakeholders/       wireframes/index.html
```

### _input/raw/ 자동 분류

`_input/raw/`에 파일을 드롭하면 `/u-ingest` 실행 시 파일명/내용을 분석하여 `rfp/`, `as-is/`, `meeting-notes/` 등 적절한 하위 폴더로 자동 분류한다.

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

---

## 6. Commands

### Grammar

```
/u-{command} [scope] [target] [flags]
```

- **scope**: 앱 이름 | `common` | `all` | 생략 (자동 선택)
- **target**: 문서/항목 이름
- **flags**: `-i` (interactive) | `--step` | `--only X` | `--cascade` | `--dry-run` | `--json`

### 6.1 Lifecycle (9)

| Command | Description | Example |
|---------|-------------|---------|
| `/u-init [project-name]` | .u-maker/ 구조 생성, config 초기화, 앱 등록 | `/u-init my-project` |
| `/u-reverse [scope] [--only X]` | 소스 코드 → SSoT 역공학 (ERD, API, Screen, SRS 등) | `/u-reverse [app] --only erd` |
| `/u-ingest [scope] [--review] [--incremental]` | raw → classified 분석 적재. `_input/raw/` 자동 분류 지원 | `/u-ingest [app] --review` |
| `/u-plan [scope] [--only X] [-i] [--step]` | classified → SRS + IA + Roadmap 연쇄 생성 | `/u-plan [app] -i` |
| `/u-design [scope] [--only X] [-i] [--step]` | SRS/IA → ERD + API + Screen + Flow + RTM + wireframes/index.html | `/u-design [app] --only screens` |
| `/u-dev [scope] [--only X] [-i] [--step]` | 명세 → FE + BE + DB 코드 생성 | `/u-dev [app] --only fe` |
| `/u-qa [scope] [-i] [--step]` | TC 설계 + 테스트 실행 + Report + exit criteria | `/u-qa [app]` |
| `/u-ship [scope] [-i] [--step]` | 최종 검증 + iteration log + retrospective | `/u-ship [app]` |
| `/u-loop [scope] [--from X] [--to Y]` | PDCA 파이프라인 무인 자동 실행 | `/u-loop [app] --from plan --to qa` |

### 6.2 Operations (5)

| Command | Description | Example |
|---------|-------------|---------|
| `/u-add [scope] [type] "title"` | 항목 추가 (FR/NR/US/FT/Screen/TC 등) | `/u-add [app] fr "비밀번호 재설정"` |
| `/u-update [scope] [doc]` | 문서 수정 + cascade 자동 전파 | `/u-update [app] srs --cascade` |
| `/u-doc [scope] [doc]` | 특정 문서 조회/편집/재생성 | `/u-doc [app] screens` |
| `/u-sync [scope]` | 전체 문서 일관성 검증 + 수정 제안 | `/u-sync [app]` |
| `/u-gate [scope]` | Phase gate 검사 + 전환 | `/u-gate [app]` |

### 6.3 Observability (5)

| Command | Description | Example |
|---------|-------------|---------|
| `/u-status [scope]` | 대시보드 (phase, 진행률, impact flags) | `/u-status [app]` |
| `/u-coverage [scope]` | classified → 산출물 커버리지 리포트 | `/u-coverage all` |
| `/u-trace [scope] [id]` | raw → classified → docs 추적 체인 | `/u-trace [app] FR-015` |
| `/u-browse [scope] [--only path] [--open]` | SSoT 문서를 분석·교차참조하여 리치 HTML 뷰어 생성. 와이어프레임에 어노테이션·화면흐름·비즈니스로직 포함 | `/u-browse [app] --open` |
| `/u-report [scope] [--only X]` | Phase별 HTML 리포트 생성 (Done/Remaining/Improve 추적) | `/u-report [app]` |

### 6.4 Collaboration (5)

| Command | Description | Example |
|---------|-------------|---------|
| `/u-ask {질문}` | Q&A — 질문, 제안, 의견에 맥락 있는 답변 | `/u-ask ERD에서 soft delete를 쓰는 이유가 뭐야?` |
| `/u-discuss [type] [topic]` | 구조화된 토론 세션 (brainstorm/review/decision/workshop/retro) | `/u-discuss brainstorm "결제 UX"` |
| `/u-assume [approve\|reject] [id]` | 가정 검토 (approve/reject) | `/u-assume approve A-001` |
| `/u-backlog [scope]` | 백로그 관리 (조회, 추가, 스프린트 할당, 우선순위, 번다운) | `/u-backlog [app]` |
| `/u-git-pr [base] [flags]` | PR/MR 자동 생성 (커밋 분석, 분할/통합, 리뷰 가이드) | `/u-git-pr main --draft` |

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
| u-skill-router | Intent 분류, scope 해석, agent dispatch |
| u-skill-phase-detector | 문서 status 집계 → phase 자동 판정 |
| u-skill-dep-engine | `_links.json` 의존성 그래프, cascade 전파 |
| u-skill-workflow-runner | Multi-step 실행, rollback, progress |
| u-skill-facilitator | /u-discuss 세션 퍼실리테이션 |

### Domain Engines (planner 소속)

| Engine | 역할 |
|--------|------|
| u-skill-doc-engine | 모든 문서 CRUD, 템플릿 렌더링, JSON export, wireframe viewer 생성, 언어 설정 반영 |
| u-skill-analyzer | Raw 파싱, chunk 분석, classified 적재 |
| u-skill-designer | IA/Screen/ERD/API 통합 설계 |
| u-skill-estimator | SRS 기반 일정/공수 산정 |

### Execution Engines (builder+guardian 소속)

| Engine | 역할 |
|--------|------|
| u-skill-code-engine | 명세 → 코드 생성 (FE+BE), scaffold |
| u-skill-validator | Gate check, cross-doc 일관성 |
| u-skill-test | TC 자동 생성, 실행, 리포트 |
| u-skill-backlog | 백로그 CRUD, 우선순위, 스프린트, 번다운 |

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
/u-status [app] --assumptions    # 미리뷰 assumptions 확인
/u-assume approve A-001           # 승인
/u-assume reject A-001 "전체취소만"  # 거부 → cascade 수정
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
├── u-maker.config.json              # 전역 설정 (language, designTool, iteration 등)
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
│   │   ├── raw/                      # 자동 분류 대기 (드롭 폴더)
│   │   ├── rfp/                      # RFP, 제안서
│   │   ├── as-is/                    # AS-IS 분석 자료
│   │   ├── meeting-notes/            # 회의록
│   │   ├── interviews/               # 인터뷰 노트
│   │   └── _manifest.json            # 입력 파일 매니페스트
│   ├── _classified/                  # Layer 2: 정제 데이터 (10 categories)
│   │   ├── requirements/             # FR-nnn, NR-nnn
│   │   ├── pain-points/             # PP-nnn
│   │   ├── domain-terms/            # DT-nnn
│   │   ├── stakeholders/            # SH-nnn
│   │   ├── workflows/               # WF-nnn
│   │   ├── screens/                 # SC-nnn
│   │   ├── data-models/             # DM-nnn
│   │   ├── constraints/             # CN-nnn
│   │   ├── decisions/               # DC-nnn
│   │   ├── questions/               # QS-nnn
│   │   └── _summary.json            # 분류 요약
│   ├── _sessions/                    # 토론 세션 아카이브
│   ├── _assumptions/                 # 가정 로그
│   ├── _backlog/                     # 백로그
│   ├── docs/                         # Layer 3: 산출물
│   │   ├── 01-plan/                  # srs.md, ia.md, roadmap.md
│   │   ├── 02-design/               # erd.md, api.md, screen.md, screen-flow.md
│   │   │   └── wireframes/          # index.html (SPA 뷰어) + SCR-*.html/md
│   │   ├── 03-dev/                  # code.md, spec-sync-report.md
│   │   └── 04-check/               # test-cases.md, test-report.md
│   └── rtm.md                       # 추적 매트릭스
│
├── _input/                           # 프로젝트 공통 raw data
│   └── raw/                          # 공통 자동 분류 대기 폴더
├── _classified/                      # 공통 classified
├── _sessions/                        # cross-app 토론
└── _assumptions/                     # cross-app assumptions
```

### Config 설정

```json
{
  "language": {
    "documents": "ko",
    "supported": ["ko", "en", "ja", "zh"]
  }
}
```

`language.documents`로 산출물 문서 언어를 설정한다. ko(한국어), en(영어), ja(일본어), zh(중국어)를 지원한다. ID와 코드는 항상 영문.

### wireframes/index.html

`/u-design` 실행 시 자동 생성되는 SPA 뷰어. 사이드바 네비게이션으로 Screen 문서를 탐색하고, MD 렌더링으로 와이어프레임을 시각화한다.

### Scope-First Navigation

Claude는 파일을 직접 열지 않고 `_index.json`만 먼저 읽어서 필요한 파일만 선택적 로드 → context window 절약.

---

## 11. Document Output Rules

| Extension | Purpose | 생성 조건 |
|-----------|---------|----------|
| `.md` | 사람이 읽는 마크다운 (SSoT 원본) | 모든 문서 |
| `.json` | 기계가 파싱하는 구조화 데이터 | 모든 문서와 동시 생성 |
| `.html` | 시각화 뷰어 (wireframes/index.html) | /u-design 실행 시 |

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
├── .claude-plugin/plugin.json        # v3.0.5
├── agents/                           # 4 agent definitions
│   ├── u-agent-orchestrator.md
│   ├── u-agent-planner.md
│   ├── u-agent-builder.md
│   └── u-agent-guardian.md
├── skills/
│   ├── u-skill-*/SKILL.md            # 12 internal engines
│   ├── u-*/SKILL.md                  # 22 command skills (user-invocable)
│   └── u-maker/SKILL.md              # NL router
├── hooks/                            # Event hooks
│   ├── hooks.json
│   ├── on-input-added.js
│   ├── on-doc-change.js
│   ├── on-classified-validated.js
│   ├── on-session-wrap.js
│   ├── on-build-complete.js
│   ├── on-check-fail.js
│   ├── on-gate-pass.js
│   └── on-ship-incomplete.js
└── shared/references/                # 참조 문서
```

---

## 13. Hooks & Guardrails

모든 Hook은 `PostToolUse(Write)` 이벤트에 바인딩되어, 파일 쓰기 후 자동으로 실행된다.

| Script | 동작 |
|--------|------|
| `on-input-added.js` | _input/ 파일 감지 → /u-ingest 제안 |
| `on-doc-change.js` | _links.json 기반 cascade impact 알림 |
| `on-classified-validated.js` | _classified/ 항목 validated → 다음 단계 제안 |
| `on-session-wrap.js` | 세션 완료 → _classified 적재 알림 |
| `on-build-complete.js` | 빌드 완료 감지 → /u-qa 제안 |
| `on-check-fail.js` | 테스트 실패 감지 → 백로그 등록 제안 |
| `on-gate-pass.js` | Gate 조건 충족 → phase 전환 제안 |
| `on-ship-incomplete.js` | Ship 미완료 항목 → 다음 iteration 이월 제안 |

---

## 14. Scenario Guide — 언제 어떤 명령어를?

### 프로젝트 시작 (Forward Engineering)

| 상황 | 명령어 |
|------|--------|
| 완전히 새로운 프로젝트 시작 | `/u-init my-project` |
| 기존 RFP/회의록 자료가 있음 | `/u-init` → `_input/raw/`에 파일 드롭 → `/u-ingest [app]` |
| 분석된 데이터 리뷰하고 싶음 | `/u-ingest [app] --review` |
| 신규분만 추가 분석 | `/u-ingest [app] --incremental` |

### 프로젝트 시작 (Reverse Engineering)

| 상황 | 명령어 |
|------|--------|
| 기존 소스 코드 → SSoT 전체 역공학 | `/u-reverse [app]` |
| ERD만 역공학 | `/u-reverse [app] --only erd` |
| API만 역공학 | `/u-reverse [app] --only api` |
| Screen만 역공학 | `/u-reverse [app] --only screen` |
| SRS만 역공학 | `/u-reverse [app] --only srs` |

### 기획 (Plan Phase)

| 상황 | 명령어 |
|------|--------|
| Plan Phase 전체 실행 | `/u-plan [app]` |
| SRS만 생성 | `/u-plan [app] --only srs` |
| 같이 보면서 만들고 싶음 | `/u-plan [app] -i` |
| 매 단계 확인하면서 진행 | `/u-plan [app] --step` |
| 공통 정책 문서 생성 | `/u-plan common` |
| 기능 요구사항 추가 | `/u-add [app] fr "비밀번호 재설정"` |
| 유저 스토리 추가 | `/u-add [app] us "비밀번호 재설정하고 싶다"` |
| 브레인스토밍 | `/u-discuss brainstorm "결제 UX"` |
| Plan→Design gate 검증 | `/u-gate [app]` |

### 설계 (Design Phase)

| 상황 | 명령어 |
|------|--------|
| Design Phase 전체 실행 | `/u-design [app]` |
| Screen만 생성 | `/u-design [app] --only screens` |
| ERD만 생성 | `/u-design [app] --only erd` |
| 2개 앱 interactive | `/u-design [app],corporate -i` |
| IA 워크숍 | `/u-discuss workshop "메인 IA"` |
| 공통 인증 방식 결정 | `/u-discuss decision "인증 방식"` |
| 일관성 검증 | `/u-sync [app]` |

### 구현 (Do Phase)

| 상황 | 명령어 |
|------|--------|
| FE+BE+DB 코드 생성 | `/u-dev [app]` |
| FE만 생성 | `/u-dev [app] --only fe` |
| BE만 생성 | `/u-dev [app] --only be` |

### 검증 (Check Phase)

| 상황 | 명령어 |
|------|--------|
| TC 설계 + 테스트 | `/u-qa [app]` |
| interactive로 결과 확인 | `/u-qa [app] -i` |

### 배포 + 회고 (Act Phase)

| 상황 | 명령어 |
|------|--------|
| 최종 검증 + 배포 + 회고 | `/u-ship [app]` |
| 회고 세션 | `/u-discuss retro` |

### 일상 운영

| 상황 | 명령어 |
|------|--------|
| 전체 프로젝트 대시보드 | `/u-status` |
| 특정 앱 상태 | `/u-status [app]` |
| 미리뷰된 assumptions 확인 | `/u-status [app] --assumptions` |
| assumption 승인 | `/u-assume approve A-001` |
| assumption 거부 (cascade) | `/u-assume reject A-001 "전체취소만"` |
| SRS 수정 + 하위 문서 갱신 | `/u-update [app] srs --cascade` |
| 특정 문서 조회 | `/u-doc [app] screens` |
| FR-015 전체 추적 | `/u-trace [app] FR-015` |
| 전체 커버리지 | `/u-coverage all` |
| 전체 일관성 검증 | `/u-sync all` |

### Q&A & 토론

| 상황 | 명령어 |
|------|--------|
| 가벼운 질문/제안 | `/u-ask screens.json 구조를 바꾸면 영향이?` |
| u-maker 사용법 질문 | `/u-ask u-maker에서 reverse는 어떻게 동작하나요?` |
| 아이디어 발산 | `/u-discuss brainstorm "결제 UX"` |
| 산출물 리뷰 | `/u-discuss review` |
| 기술 결정 | `/u-discuss decision "DB 선택"` |
| 다단계 워크숍 | `/u-discuss workshop "메인 화면 설계"` |
| Iteration 회고 | `/u-discuss retro` |

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

### 백로그 & PR

| 상황 | 명령어 |
|------|--------|
| 백로그 조회 | `/u-backlog [app]` |
| 백로그 항목 추가 | `/u-backlog [app] add "로그인 개선"` |
| 스프린트 할당 | `/u-backlog [app] assign S-001 sprint-2` |
| PR 자동 생성 | `/u-git-pr main` |
| PR (draft) | `/u-git-pr main --draft` |
| PR 분할 생성 | `/u-git-pr main --split` |

### 자연어로도 가능

명령어를 모르겠으면 자연어로 말해도 된다:

```
"[app] 앱의 SRS를 만들어줘"           → /u-plan [app] --only srs
"ERD를 PostgreSQL로 최적화해줘"       → /u-design [app] --only erd
"테스트 케이스 만들어줘"               → /u-qa [app]
"지금 프로젝트 상태가 어때?"           → /u-status
"기존 소스에서 API 문서 뽑아줘"        → /u-reverse [app] --only api
"PR 만들어줘"                         → /u-git-pr main
```

---

## 15. Prerequisites & Install

| 도구 | 용도 | 필수 |
|------|------|------|
| **Claude Code** | u-maker 기반 환경 | Yes |
| **Node.js** | Hook 스크립트 실행 | Yes |

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
| scope 해석이 틀림 | `u-maker.config.json`의 `apps[]`에 앱이 등록되었는지 확인 |
| auto 모드에서 자꾸 interactive로 전환됨 | `maxAssumptions` 초과. `/u-assume`로 리뷰하세요 |
| cascade 알림이 많음 | `/u-sync`로 한 번에 정리하거나 `/u-update --cascade`로 자동 갱신 |
| `_input/raw/` 파일이 분류 안 됨 | `/u-ingest [scope]` 실행하여 자동 분류 트리거 |
| wireframes/index.html이 없음 | `/u-design [scope]`를 실행하면 자동 생성됨 |
| 문서 언어를 변경하고 싶음 | `u-maker.config.json`의 `language.documents`를 ko/en/ja/zh로 변경 |
| `/u-reverse` 결과가 불완전 | `--only` 플래그로 범위를 좁혀서 재실행 |
| Hook이 동작하지 않음 | `hooks/hooks.json`의 매칭 설정 확인 + Node.js 설치 확인 |

---

## 17. License

GPL-3.0

Copyright (c) 2026 U PLEAT. All rights reserved.
