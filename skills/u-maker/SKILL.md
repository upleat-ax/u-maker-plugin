---
name: u-maker
description: "PDCA 기반 SSoT 협업 오케스트레이터. 자연어 요청을 분석하여 적절한 /u-* 커맨드로 라우팅하고, 프로젝트 전체 lifecycle을 관리한다."
triggers:
  - "/u-maker"
  - "u-maker"
  - "project management"
  - "PDCA"
  - "프로젝트 관리"
---

# u-maker -- PDCA Orchestrator Router

모든 `/u-*` 커맨드의 진입점. 사용자의 자연어 요청 또는 명시적 커맨드를 파싱하여 적절한 command skill로 라우팅한다.

---

## Command Grammar

```
/u-{command} [scope] [target] [flags]
```

- **command**: 실행할 명령 (init, ingest, plan, design, build, check, ship, ...)
- **scope**: 앱 이름 | `common` | `all` | 생략 (자동 탐지)
- **target**: 문서/항목 이름 (command에 따라 선택적)
- **flags**: `-i` | `--step` | `--only X` | `--cascade` | `--review` | `--incremental`

---

## Full Command Table

### Lifecycle Commands (9)

| Command | Signature | Phase | Description |
|---------|-----------|-------|-------------|
| `/u-init` | `/u-init [project-name]` | -- | `.u-maker/` 구조 생성, config 초기화, 앱 등록 |
| `/u-reverse` | `/u-reverse [scope] [--only X] [-i] [--step]` | Design | 소스 코드 → SSoT 역공학 (ERD, API, Screen, SRS 등) |
| `/u-ingest` | `/u-ingest [scope] [--review] [--incremental]` | Plan | raw → classified 분석 적재 |
| `/u-plan` | `/u-plan [scope] [--only X] [-i] [--step]` | Plan | classified → SRS + IA + Roadmap 연쇄 생성 |
| `/u-design` | `/u-design [scope] [--only X] [-i] [--step]` | Design | SRS/IA → ERD + API + Screen + Flow + RTM |
| `/u-dev` | `/u-dev [scope] [--only X] [-i] [--step]` | Do | 명세 → FE + BE + DB 코드 생성 |
| `/u-qa` | `/u-qa [scope] [-i] [--step]` | Check | TC 설계 + 테스트 실행 + Report + exit criteria |
| `/u-ship` | `/u-ship [scope] [-i] [--step]` | Act | 최종 검증 + iteration log + retrospective |
| `/u-loop` | `/u-loop [scope] [--from X] [--to Y] [--resume]` | ALL | 무인 자동 실행 (밤새 돌려놓기) |

### Operations Commands (5)

| Command | Signature | Description |
|---------|-----------|-------------|
| `/u-add` | `/u-add [scope] [type] "title"` | 항목 추가 (FR/NR/US/FT/Screen/TC) |
| `/u-update` | `/u-update [scope] [doc]` | 문서 수정 + 변경 cascade 전파 |
| `/u-doc` | `/u-doc [scope] [doc]` | 특정 문서 조회/편집/재생성 |
| `/u-sync` | `/u-sync [scope]` | 문서 일관성 검증 + 불일치 수정 제안 |
| `/u-gate` | `/u-gate [scope]` | Phase gate 검증 + 전환 |

### Observability Commands (4)

| Command | Signature | Description |
|---------|-----------|-------------|
| `/u-status` | `/u-status [scope]` | 대시보드: phase, 진행률, blockers, impact flags |
| `/u-coverage` | `/u-coverage [scope]` | classified → docs 커버리지 리포트 |
| `/u-trace` | `/u-trace [scope] [item-id]` | raw → classified → docs 추적 체인 |
| `/u-report` | `/u-report [scope] [--only X]` | SSoT → HTML 리포트 생성 (sidebar nav + SVG 다이어그램) |

### Collaboration Commands (4)

| Command | Signature | Description |
|---------|-----------|-------------|
| `/u-ask` | `/u-ask {질문}` | 가벼운 Q&A — 질문, 제안, 의견에 맥락 있는 답변 |
| `/u-discuss` | `/u-discuss [type] [topic]` | 구조화된 토론 세션 (brainstorm/review/decision/retro) |
| `/u-assume` | `/u-assume [approve\|reject] [id]` | 가정 검토/채택/기각 |
| `/u-backlog` | `/u-backlog [scope]` | 백로그 조회/관리 |

---

## Scope Resolution Rules

```
Input             Resolution
────────────────  ──────────────────────────────────
"retail"          등록된 앱 이름 → apps/retail/
"common"          공통 스코프 → common/
"all"             모든 등록 앱 (순차 실행)
"retail,corp"     복수 앱 (각각 실행)
(생략)            앱 1개 → 자동 선택
                  앱 2개+ → 사용자에게 선택 요청
(unknown word)    앱/예약어 아님 → [target]으로 해석
```

**Steps:**
1. `u-maker.config.json`에서 `apps[]` 목록 조회
2. scope 인자가 `apps[].name`과 일치하는지 확인
3. 예약 스코프(`common`, `all`)인지 확인
4. 일치하지 않으면 → [target]으로 재해석
5. `all` 또는 콤마 구분 → 순차 실행 (기본) 또는 `--parallel`

---

## Global Flags

| Flag | Mode | Behavior |
|------|------|----------|
| (none) | auto | 끝까지 실행. 결정 사항은 `data/assumptions/`에 기록 |
| `-i` | interactive | 분기점(2개+ 선택지, 누락 정보, 충돌)에서만 중단 |
| `--step` | step | 매 단계 결과 표시 후 승인 대기 |
| `--only X` | -- | 지정 문서만 생성 (e.g., `--only srs`, `--only erd`) |
| `--cascade` | -- | 변경 시 하위 문서 자동 갱신 |
| `--review` | -- | 추출 항목을 사용자 검증 후 반영 |
| `--incremental` | -- | 변경된 파일만 처리 |

---

## Routing Logic

### Step 1: Parse Command

```
User input → extract command, scope, target, flags
```

### Step 2: Resolve Scope

u-maker.config.json에서 앱 목록 조회 후 scope 해석.

### Step 3: Route to Command Skill

| Command | Route To |
|---------|----------|
| `init` | `skills/u-init/` |
| `reverse` | `skills/u-reverse/` |
| `ingest` | `skills/u-ingest/` |
| `plan` | `skills/u-plan/` |
| `design` | `skills/u-design/` |
| `build` | `skills/u-dev/` |
| `check` | `skills/u-qa/` |
| `ship` | `skills/u-ship/` |
| `add` | `skills/u-add/` |
| `status` | `skills/u-status/` |
| `discuss` | `skills/u-discuss/` |
| `sync` | `skills/u-sync/` |
| `gate` | `skills/u-gate/` |
| (others) | 해당 `skills/u-{command}/` |

### Step 4: Natural Language Fallback

명시적 커맨드가 아닌 경우:
1. 의도 분류 (engine-router)
2. 신뢰도 >= 0.7 → 매칭된 커맨드로 라우팅 (확인 요청)
3. 신뢰도 < 0.7 → 상위 3개 후보 제시, 사용자 선택
4. u-maker 커맨드가 아닌 경우 → 도움말 안내

---

## Quick-Start Guide

```bash
# ── Forward Engineering (새 프로젝트) ──
# 1. 프로젝트 초기화
/u-init my-project

# 2. .u-maker/data/dropzone/에 RFP, 회의록, AS-IS 자료 드롭 → 원시 자료 분석
/u-ingest retail

# 3. Plan 문서 생성 (SRS + IA + Roadmap)
/u-plan retail

# 4. Design 문서 생성 (ERD + API + Screen + RTM)
/u-design retail

# 5. 코드 생성
/u-dev retail

# 6. QA 검증
/u-qa retail

# 7. 최종 검증 + 배포
/u-ship retail

# ── 또는 한 줄로 밤새 돌리기 ──
/u-loop retail                    # ingest → plan → design → dev → qa → ship 무인 실행

# ── Reverse Engineering (기존 프로젝트) ──
# 1. 프로젝트 초기화
/u-init my-project

# 2. 소스 코드 → SSoT 역공학
/u-reverse retail

# 3. 역공학 결과 검증 + 보완
/u-sync retail
```

---

## Always-Pause Situations

다음 상황은 모드(auto/interactive/step)에 무관하게 반드시 사용자 확인:

1. **Phase gate 실패** -- 실패한 gate는 절대 자동 진행하지 않음
2. **파괴적 변경** -- Final 문서 덮어쓰기, 항목 삭제, 스코프 변경
3. **스코프 변경** -- 예상과 다른 앱에 영향
4. **maxAssumptions 초과** -- 자동 결정이 너무 많아 모호한 입력으로 판단

---

## Output Format

모든 커맨드 실행 후 구조화된 요약 제공:

```
## Result: /u-{command} {scope}

**Phase:** {current} -> {next if changed}
**Mode:** {auto|interactive|step}

### Actions Taken
1. {action}

### Documents Modified
- {path} ({status change})

### Impact Flags Set
- {path} (reason)

### Assumptions Made
- A-{NNN}: {description}

### Next Steps
- {recommendation}
```
