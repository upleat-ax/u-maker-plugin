# u-Agent SSoT

> PDCA 사이클 기반의 SSoT(Single Source of Truth) 소프트웨어 개발 협업 자동화 Claude Code Plugin

**문서가 프로세스를 강제하고, 에이전트가 이를 실행한다.**

---

## Overview

u-Agent SSoT는 9개 전문 에이전트가 PDCA(Plan-Design-Do-Check-Act) 사이클을 따라 소프트웨어 개발을 자동화하는 Claude Code Plugin이다. 모든 결정과 산출물은 `u-docs/` SSoT 문서 체계에 기록되며, 종료 조건 충족까지 자동 반복한다.

### 핵심 원칙

- **문서 중심**: 모든 결정과 산출물은 `u-docs/` SSoT 문서에 기록
- **Phase Gate**: 각 Phase 전환은 Gate 조건 충족 필수
- **자동 반복**: CHECK 실패 시 ACT → 다음 Iteration 자동 전환
- **역할 분리**: 9개 전문 에이전트가 명확한 역할 분담
- **기술 스택 강제**: 10가지 기술 스택 규칙 위반 시 거부

---

## Installation

```bash
# Claude Code Plugin 디렉토리에 복사
cp -r u-ssot/ ~/.claude/plugins/u-ssot/
```

또는 프로젝트 로컬 플러그인으로 사용:

```bash
# 프로젝트 루트에 배치
cp -r u-ssot/ .claude/plugins/u-ssot/
```

---

## Quick Start

```bash
# 1. 새 프로젝트 생성
/u-create-project my-app

# 2. PLAN Phase (로드맵 → SRS → IA → 인덱스)
/u-plan

# 3. DESIGN Phase (화면설계 → ERD → API)
/u-design

# 4. DO Phase (Frontend + Backend 병렬 개발)
/u-dev

# 5. CHECK Phase (테스트 케이스 → 실행 → 결함분석)
/u-check

# 6. 종료 조건 충족까지 자동 반복
/u-loop
```

---

## 9 Agents

| Agent | Role | Phase | 담당 문서 |
|-------|------|-------|----------|
| `u-pm` | Project Manager | PLAN, ACT | 1PM_Roadmap, 5ACT_Retrospective |
| `u-m` | Master (SSoT Guardian) | ALL | 1M_Index, 5ACT_Iteration_Log |
| `u-a` | Architect | PLAN, DESIGN | 1A_SRS, 2A_ERD, 2A_API |
| `u-cx` | CX/UX Designer | PLAN, DESIGN | 1CX_IA, 2CX_Screen |
| `u-dv-fe` | Frontend Developer | DO | 코드 생성 (Next.js + react-query) |
| `u-dv-be` | Backend Developer | DO | 코드 생성 (API Routes + ORM) |
| `u-qa-a` | QA Analyst | CHECK | 4QA_Case |
| `u-qa-t` | QA Tester | CHECK | 4QA_Report |
| `u-qa-n` | QA Defect Analyst | CHECK, ACT | 5ACT_Backlog |

---

## PDCA Workflow

```
PLAN → DESIGN → DO → CHECK → ACT → (다음 Iteration)
                              ↓
                          COMPLETE (종료 조건 충족 시)
```

### Phase Gate 조건

| Transition | 조건 |
|------------|------|
| PLAN → DESIGN | Roadmap + SRS + IA 모두 Final |
| DESIGN → DO | ERD + API + Screen 모두 Final + u-M 검수 |
| DO → CHECK | 코드 구현 완료 + `bun run build` 성공 |
| CHECK → Complete | Critical/Major 0건 + 백로그 0건 + 전체 FR 구현 |
| CHECK → ACT | 위 조건 미충족 시 자동 전환 |

### 종료 조건 (Exit Criteria)

4가지 모두 충족 시 루프 종료:

1. `5ACT_Backlog.md`의 모든 항목 Done
2. Critical/Major 결함 0건
3. SRS의 모든 FR 구현 완료
4. `bun run build` 성공

---

## Slash Commands

### Lifecycle

| Command | Description |
|---------|-------------|
| `/u-create-project` | 새 프로젝트 초기화 (Turborepo + u-docs) |
| `/u-plan` | PLAN Phase 실행 |
| `/u-design` | DESIGN Phase 실행 |
| `/u-dev` | DO Phase 실행 (FE/BE 병렬) |
| `/u-check` | CHECK Phase 실행 |
| `/u-act` | ACT Phase 실행 |

### Loop

| Command | Description |
|---------|-------------|
| `/u-loop` | 종료 조건까지 PDCA 자동 반복 |
| `/u-loop-from [phase]` | 지정 Phase부터 루프 시작 |
| `/u-stop` | 루프 중단 |
| `/u-resume` | 루프 재개 |

### Document Management

| Command | Description |
|---------|-------------|
| `/u-status` | 현재 상태 보고 |
| `/u-docs` | 문서 목록 조회 |
| `/u-validate` | SSoT 무결성 검증 |
| `/u-backlog` | 백로그 조회 |
| `/u-index` | 문서 인덱스 갱신 |

### Individual Agent

| Command | Description |
|---------|-------------|
| `/u-srs` | SRS 문서 생성/갱신 |
| `/u-erd` | ERD 생성/갱신 |
| `/u-api` | API Contract 생성/갱신 |
| `/u-screen` | 화면 설계 생성/갱신 |
| `/u-fe` | Frontend 개발 실행 |
| `/u-be` | Backend 개발 실행 |
| `/u-test` | 테스트 케이스 설계/실행 |
| `/u-bug-report` | 결함 분석 리포트 |
| `/u-gap-detector` | 설계-구현 Gap 분석 |

### Utility

| Command | Description |
|---------|-------------|
| `/u-help` | 전체 명령어 도움말 |
| `/u-history` | Iteration 이력 조회 |
| `/u-archive` | 현재 Iteration 아카이브 |
| `/u-storybook` | Storybook 실행 |
| `/u-build` | 프로젝트 빌드 |

---

## SSoT Document Structure

```
u-docs/
├── 01-plan/
│   ├── 1PM_Roadmap.md          # u-pm
│   ├── 1A_SRS.md               # u-a
│   ├── 1CX_IA.md               # u-cx
│   └── 1M_Index.md             # u-m
├── 02-design/
│   ├── 2A_ERD.md               # u-a
│   ├── 2A_API.md               # u-a
│   └── 2CX_Screen.md           # u-cx
├── 03-dev/
│   └── 3DV_Code.md             # u-dv-fe / u-dv-be
├── 04-check/
│   ├── 4QA_Case.md             # u-qa-a
│   └── 4QA_Report.md           # u-qa-t
├── 05-act/
│   ├── 5ACT_Backlog.md         # u-qa-n
│   ├── 5ACT_Iteration_Log.md   # u-m
│   └── 5ACT_Retrospective.md   # u-pm
├── assets/
└── iterations/
    └── iter-N/
```

모든 문서는 공통 SSoT 헤더를 포함한다:

```yaml
---
Owner: [agent-id]
Status: Draft | Review | Final
Version: 1.0.0
Last Updated: YYYY-MM-DD
Related Docs:
  - [relative path]
---
```

---

## Tech Stack Rules

코드 생성 시 아래 10가지 규칙을 강제한다. 위반 시 `PreToolUse` hook이 차단한다.

| # | Rule | 위반 예시 |
|---|------|----------|
| 1 | Clean Architecture 폴더 구조 | `src/` 직하에 비즈니스 로직 |
| 2 | react-query 사용 (usecase 금지) | usecase/ 패턴 |
| 3 | .css 직접 사용 (CSS-in-JS 금지) | styled-components, emotion |
| 4 | Next.js App Router | Pages Router |
| 5 | eslint-plugin-header 사용 금지 | eslint config에 header 플러그인 |
| 6 | Turborepo monorepo | 단일 패키지 구조 |
| 7 | 함수형 컴포넌트만 | class 컴포넌트 |
| 8 | Storybook 적용 | .stories 파일 미생성 |
| 9 | Design Token 기반 | 하드코딩된 색상/폰트 |
| 10 | bun 패키지 매니저 | npm install, yarn add |

---

## Plugin Structure

```
u-ssot/
├── .claude-plugin/
│   └── plugin.json              # Plugin 메타데이터
├── skills/u-ssot/
│   └── SKILL.md                 # 메인 오케스트레이터
├── agents/                      # 9 에이전트 정의
├── references/                  # 7 참조 문서
├── templates/                   # 13 SSoT 템플릿
├── scripts/                     # 자동화 스크립트 (6)
├── hooks/                       # Hook 시스템 (2)
├── lib/                         # 유틸리티 라이브러리 (3)
├── evals/                       # 테스트 케이스
└── u-ssot.config.json     # 설정 파일
```

**Total: 44 files**

---

## Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `scripts/init-project.sh` | Turborepo + bun + Next.js + u-docs 초기화 | `bash scripts/init-project.sh <name>` |
| `scripts/validate-ssot.py` | SSoT 헤더/구조/추적성 검증 | `python3 scripts/validate-ssot.py` |
| `scripts/check-exit-criteria.py` | 종료 조건 4가지 자동 판정 | `python3 scripts/check-exit-criteria.py` |

---

## Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `SessionStart` | 플러그인 초기화 | u-docs/ 구조 검증/생성 |
| `PreToolUse(Write\|Edit)` | 파일 작성 시 | u-docs/ 경로 강제 + 기술 스택 위반 탐지 |
| `PostToolUse(Write)` | 문서 생성 후 | 자동 인덱스 갱신 알림 |
| `Stop` | 세션 종료 | Phase/Iteration/Loop 상태 저장 |

---

## Configuration

`u-ssot.config.json`에서 다음을 설정할 수 있다:

```jsonc
{
  "pdca": {
    "maxIterations": 10,    // 최대 반복 횟수
    "autoIterate": true     // 자동 반복 여부
  },
  "techStack": {
    "rules": [...]          // 기술 스택 규칙 on/off
  },
  "agents": {
    "routing": {            // 에이전트별 Phase/Trigger 설정
      "u-pm": { "phases": ["plan", "act"], ... }
    }
  }
}
```

---

## License

Private - Internal use only.
