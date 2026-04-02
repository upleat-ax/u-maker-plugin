---
name: u-status
description: "프로젝트 대시보드. Phase, 진행률, 미완료 항목, impact flags 표시. 백로그 요약, 가정 현황, 토론 세션, gate 준비도를 한눈에 보여준다."
triggers:
  - "/u-status"
  - "status"
  - "상태"
  - "dashboard"
  - "대시보드"
---

# u-status -- Project Dashboard

`/u-status [scope] [--detail]` 명령으로 프로젝트 전체 현황을 대시보드 형식으로 표시한다.

**Primary Agent:** u-agent-orchestrator (engine-phase-detector 사용)

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 전체 앱 요약 / 앱 1개면 자동 선택 |

## Flags

| Flag | Description |
|------|-------------|
| `--detail` | 각 섹션 상세 표시 (기본은 요약) |
| `--json` | JSON 형식 출력 |

---

## Execution Flow

### Step 1: Gather Data

1. `u-maker.config.json` 읽기 → 프로젝트 정보, iteration, 앱 목록
2. 각 앱의 `app.config.json` → phase 정보
3. 각 앱의 `_index.json` → 문서 상태 집계
4. `data/backlog/_index.json` → 백로그 항목 집계
5. `data/assumptions/_index.json` → 가정 현황
6. `.state/sessions/` → 활성 토론 세션
7. `.u-maker/data/links.json` → impact flags 추출

### Step 2: Compile Dashboard

---

## Dashboard Output Format

```markdown
## u-maker Dashboard

**Project:** {project-name}
**Iteration:** {n}
**Date:** {ISO 8601}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 1. Phase Status

| App | Phase | Progress | Since |
|-----|-------|----------|-------|
| {app-1} | DO | ██████░░░░ 60% | 2026-03-22 |
| {app-2} | PLAN | ████████░░ 80% | 2026-03-25 |

Phase progress 계산:
- PLAN: (Draft + Review + Final 문서 수) / 예상 문서 수 (srs, ia, roadmap)
- DO: (Final 설계 문서 수 + code-complete FT 수) / 전체 DO 산출물
- CHECK: (실행 TC 수) / 전체 TC 수
- ACT: (retrospective + archive + carry-over) / 3 단계

### 2. Document Completion

| App | Draft | Review | Final | Total | Completion |
|-----|-------|--------|-------|-------|------------|
| {app-1} | 2 | 1 | 5 | 8 | 62.5% |
| {app-2} | 3 | 2 | 1 | 6 | 16.7% |

Completion = Final / Total * 100

**--detail 시 문서별 표시:**

| Phase | Document | Status | Version | Updated | Owner |
|-------|----------|--------|---------|---------|-------|
| 01-plan | srs | Final | 1.2.0 | 03-25 | planner |
| 01-plan | ia | Review | 1.1.0 | 03-24 | planner |
| 01-plan | roadmap | Final | 1.0.0 | 03-20 | planner |
| 02-design | erd | Final | 1.0.0 | 03-23 | sa |
| 02-design | api | Final | 1.0.0 | 03-23 | sa |
| 02-design | screens | Draft | 0.1.0 | 03-22 | ux |
| 03-dev | code | Draft | 0.1.0 | 03-26 | builder |
| 04-check | test-cases | -- | -- | -- | gatekeeper |

### 3. Impact Flags

문서 간 cascade 미반영 또는 검토 필요 항목:

| Document | Source | Issue | Flagged |
|----------|--------|-------|---------|
| erd.md | srs.md | FR-0042 추가로 데이터 모델 검토 필요 | 03-26 |
| screens.md | ia.md | IA 변경으로 Screen 매핑 재검토 필요 | 03-25 |

Impact flags 없으면:
```
No impact flags. Documents are in sync.
```

### 4. Backlog Summary

**Per-Iteration 집계:**

| Iteration | Backlog | Todo | In Progress | Review | Done | Blocked | SP Total |
|-----------|---------|------|-------------|--------|------|---------|----------|
| {current} | 5 | 8 | 3 | 1 | 12 | 1 | 30 |
| Unassigned | 7 | -- | -- | -- | -- | -- | -- |

**Per-Type 집계:**

| Type | Open | Done | Total |
|------|------|------|-------|
| Feature | 12 | 8 | 20 |
| Bug | 3 | 5 | 8 |
| Improvement | 2 | 1 | 3 |
| Tech-debt | 4 | 0 | 4 |

**Blocked 항목 (있으면):**

| ID | Title | Blocked Since | Reason |
|----|-------|-------------|--------|
| BL-023 | 결제 연동 | 03-24 | 외부 API 미제공 |

### 5. Assumptions

최근 가정 현황:

| Status | Count |
|--------|-------|
| Pending Review | {n} |
| Approved | {n} |
| Rejected | {n} |

**Pending Review 항목 (최근 5건):**

| ID | Agent | Context | Question | Confidence |
|----|-------|---------|----------|------------|
| A-003 | planner | FR-0012 | 부분 취소 포함? | medium |
| A-005 | sa | ERD | 이력 테이블 필요? | low |

### 6. Active Sessions

진행 중인 `/u-discuss` 세션:

| Session | Type | Topic | Started | Status |
|---------|------|-------|---------|--------|
| DS-003 | workshop | Sprint 2 Planning | 03-26 14:00 | phase-2 (grouping) |

세션 없으면:
```
No active discussion sessions.
```

### 7. Gate Readiness

다음 Phase gate 사전 진단:

| Condition | Status | Detail |
|-----------|--------|--------|
| G-01: SRS = Final | ✅ Ready | v1.2.0, Final |
| G-02: IA = Final | ❌ Not Ready | v1.1.0, Review |
| G-04: FR→US mapping | ✅ Ready | 100% mapped |
| G-05: US→FT mapping | ⚠ Partial | 95% mapped (2 orphans) |

**Gate Readiness:** {n}/{total} conditions met ({pct}%)

```
Run /u-gate {scope} for full gate evaluation.
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Quick Actions

- /u-gate {scope} — Phase gate 검사
- /u-sync {scope} — 일관성 검증
- /u-backlog {scope} — 백로그 상세
- /u-assume {scope} — 가정 검토
- /u-doc {scope} {flagged-doc} — Impact flag 문서 확인
```

---

## Multi-App Summary

scope 생략 + 앱 2개 이상:

```markdown
## u-maker Dashboard (Multi-App)

| App | Phase | Docs | Completion | Backlog Open | Impact Flags |
|-----|-------|------|------------|-------------|-------------|
| web | DO | 8 | 62.5% | 16 | 2 |
| admin | PLAN | 3 | 33.3% | 5 | 0 |
| api | DO | 6 | 50.0% | 10 | 1 |

Select app for detail: /u-status {app}
```

---

## JSON Output (--json)

```json
{
  "project": "{name}",
  "iteration": {n},
  "timestamp": "{ISO 8601}",
  "apps": [
    {
      "name": "{app}",
      "phase": "{phase}",
      "phaseProgress": 0.6,
      "documents": {
        "draft": 2, "review": 1, "final": 5, "total": 8,
        "completion": 0.625
      },
      "impactFlags": [],
      "backlog": {
        "backlog": 5, "todo": 8, "inProgress": 3,
        "review": 1, "done": 12, "blocked": 1
      }
    }
  ],
  "assumptions": { "pending": 2, "approved": 15, "rejected": 3 },
  "activeSessions": [],
  "gateReadiness": { "met": 5, "total": 7, "percentage": 0.714 }
}
```

---

## Safety Rules

1. 읽기 전용 명령 (파일 수정 없음)
2. 존재하지 않는 파일/데이터는 `--` 또는 `N/A`로 표시 (에러 아님)
3. 대량 데이터는 요약만 표시 (--detail로 상세 전환)
4. JSON 파일 파싱 실패 시 해당 섹션 SKIP + 경고 표시
5. 모든 수치는 실시간 계산 (캐시 사용 안 함)
6. 민감 정보(credential, token) 표시 금지
7. multi-app 모드에서 앱별 독립 집계
8. Phase progress 계산은 engine-phase-detector 기준
