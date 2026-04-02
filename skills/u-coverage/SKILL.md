---
name: u-coverage
description: "classified 데이터 대비 산출물 커버리지 리포트 생성. 원시 자료 → 분류 → 문서 반영까지의 추적성 체인과 채택률을 보고한다."
triggers:
  - "/u-coverage"
  - "coverage"
  - "커버리지"
  - "채택률"
---

# u-coverage -- Classified-to-Deliverable Coverage Report

`/u-coverage [scope] [--category X] [--gaps-only]` 명령으로 classified 데이터가 산출물(SRS, ERD, API 등)에 얼마나 반영되었는지 커버리지를 보고한다.

**Primary Agent:** u-agent-gatekeeper (engine-validator, engine-dep 사용)

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 자동 선택 |

## Flags

| Flag | Description |
|------|-------------|
| `--category X` | 특정 카테고리만 (requirements, pain-points, workflows 등) |
| `--gaps-only` | 미채택(gap) 항목만 표시 |
| `--verbose` | 항목별 상세 표시 |
| `--format html` | HTML 리포트 생성 |

---

## Execution Flow

### Step 1: Load Classified Data

1. `data/classified/_summary.json` 읽기 → 전체 분류 현황
2. 각 카테고리의 `_index.json` 읽기:
   - `requirements/` (FR, NR)
   - `pain-points/`
   - `domain-terms/`
   - `stakeholders/`
   - `workflows/`
   - `screens/`
   - `data-models/`
   - `constraints/`
   - `decisions/`
   - `questions/`
3. 각 항목의 status 확인: `extracted`, `validated`, `adopted`, `rejected`

### Step 2: Load Deliverable Documents

1. `docs/{app}/_index.json` 읽기 → 산출물 목록
2. 각 산출물의 `.json` 파일 로드:
   - `srs.json` → FR, NR, USR, US, FT
   - `ia.json` → Screens, Navigation
   - `erd.json` → Entities, Relations
   - `api.json` → Endpoints
   - `screens.json` → Screen definitions
   - `rtm.json` → Traceability matrix
   - `glossary.json` → Terms
3. 산출물 내 항목에서 `source` 역참조 추출

### Step 3: Calculate Coverage per Category

각 카테고리별로:

1. **Total:** 전체 classified 항목 수
2. **Validated:** status = validated + adopted
3. **Adopted:** status = adopted (산출물에 반영 완료)
4. **Rejected:** status = rejected
5. **Gap:** status = validated BUT adopted 아님 (반영 가능하나 미반영)
6. **Coverage %:** (Adopted / (Total - Rejected)) * 100

### Step 4: Trace Chains

각 카테고리별 추적 체인 확인:

| Category | Raw Source | Classified | Deliverable |
|----------|-----------|------------|-------------|
| requirements | `data/input/rfp/` p.15 | `data/classified/requirements/FR-0001` | `srs.md` FR-0001 |
| pain-points | `data/input/meeting-notes/` | `data/classified/pain-points/PP-003` | `srs.md` NR-0002 (via) |
| domain-terms | `data/input/rfp/` p.3 | `data/classified/domain-terms/DT-012` | `glossary.md` |
| stakeholders | `data/input/rfp/` p.8 | `data/classified/stakeholders/SH-001` | `srs.md` USR-0001 |
| workflows | `data/input/as-is/` | `data/classified/workflows/WF-005` | `ia.md` + `screen-flow.md` |
| screens | `data/input/as-is/` | `data/classified/screens/SC-010` | `screens.md` SCR-010 |
| data-models | `data/input/as-is/` | `data/classified/data-models/DM-003` | `erd.md` |
| constraints | `data/input/rfp/` p.52 | `data/classified/constraints/CN-007` | `srs.md` NR + `api.md` |
| decisions | `.state/sessions/` | `data/classified/decisions/DC-002` | 해당 문서 반영 |
| questions | analysis | `data/classified/questions/QS-015` | 답변 → 문서 반영 |

### Step 5: Identify Gaps

Gap 항목 = validated 상태이나 어떤 산출물에도 adopted로 반영되지 않은 항목.

Gap 분류:

| Gap Type | Description | Priority |
|----------|-------------|----------|
| **Critical Gap** | validated requirements 미반영 | High |
| **Design Gap** | workflows/screens 미반영 | Medium |
| **Knowledge Gap** | domain-terms/decisions 미반영 | Low |
| **Data Gap** | data-models 미반영 | Medium |

---

## Coverage Report Output

```markdown
## Coverage Report - {app}

**Date:** {ISO 8601}
**Scope:** {app}
**Iteration:** {n}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Overall Coverage

| Metric | Value |
|--------|-------|
| Total Classified Items | {n} |
| Adopted (in deliverables) | {n} |
| Validated (pending adoption) | {n} |
| Rejected | {n} |
| **Overall Coverage** | **{pct}%** |

### Coverage by Category

| Category | Total | Validated | Adopted | Rejected | Gap | Coverage |
|----------|-------|-----------|---------|----------|-----|----------|
| requirements | 42 | 5 | 35 | 2 | 5 | 87.5% |
| pain-points | 18 | 3 | 12 | 3 | 3 | 80.0% |
| domain-terms | 25 | 2 | 22 | 1 | 2 | 91.7% |
| stakeholders | 5 | 0 | 5 | 0 | 0 | 100.0% |
| workflows | 12 | 4 | 6 | 2 | 4 | 60.0% |
| screens | 15 | 3 | 10 | 2 | 3 | 76.9% |
| data-models | 8 | 1 | 6 | 1 | 1 | 85.7% |
| constraints | 10 | 2 | 7 | 1 | 2 | 77.8% |
| decisions | 6 | 0 | 6 | 0 | 0 | 100.0% |
| questions | 15 | 5 | 8 | 2 | 5 | 61.5% |
| **Total** | **156** | **25** | **117** | **14** | **25** | **82.4%** |

### Traceability Chains

```
Raw (data/input/)          Classified (data/classified/)      Deliverables (docs/)
━━━━━━━━━━━━           ━━━━━━━━━━━━━━━━━━━━━           ━━━━━━━━━━━━━━━━━━
{n} files     ──→      {n} items extracted    ──→      {n} items adopted
               │        {n} validated                   in {n} documents
               │        {n} rejected
               └→       {n} gaps (not yet adopted)
```

### Gap Analysis

#### Critical Gaps (requirements not yet in deliverables)

| ID | Title | Priority | Source | Validated Since | Target Doc |
|----|-------|----------|--------|----------------|------------|
| FR-0042 | 부분 취소 기능 | Must | rfp.pdf p.47 | 03-20 | srs.md |
| NR-0008 | 응답 시간 2초 이내 | Must | rfp.pdf p.52 | 03-21 | srs.md |

#### Design Gaps (workflows/screens not reflected)

| ID | Title | Source | Target Doc |
|----|-------|--------|------------|
| WF-005 | 결제 취소 워크플로 | as-is/payment.md | ia.md, screen-flow.md |
| SC-010 | 관리자 결제 현황 | as-is/admin.md | screens.md |

#### Data Gaps (data-models not in ERD)

| ID | Title | Source | Target Doc |
|----|-------|--------|------------|
| DM-003 | 결제 이력 테이블 | as-is/db-schema.md | erd.md |

### Recommendations

1. **Critical:** {count} requirements gaps → `/u-plan {scope} --only srs` 재생성 또는 `/u-add`
2. **Design:** {count} design gaps → `/u-design {scope}` 재실행
3. **Data:** {count} data gaps → `/u-doc {scope} erd edit`
4. **Knowledge:** {count} knowledge gaps → `/u-doc {scope} glossary edit`
```

---

## --gaps-only Output

```markdown
## Gap Items - {app}

### Critical ({count})
| ID | Title | Category | Source | Waiting Since |
|----|-------|----------|--------|-------------|
| FR-0042 | 부분 취소 기능 | requirements | rfp.pdf p.47 | 7 days |

### Medium ({count})
...

### Low ({count})
...

**Total Gaps:** {n} items
**Action:** /u-plan {scope} to adopt, or /u-assume reject {id} to dismiss
```

---

## --format html Output

HTML 리포트 생성:
- 파일: `docs/{app}/coverage-report.html`
- Tailwind CSS 사용
- Light/Dark 모드 토글
- 카테고리별 진행 바 (progress-bar 컴포넌트)
- Gap 항목 하이라이트
- 추적 체인 시각화 (인라인 SVG 또는 Mermaid)

---

## Safety Rules

1. 읽기 전용 명령 (파일 수정 없음, --format html 제외)
2. classified 데이터가 없으면 "/u-ingest를 먼저 실행하세요" 안내
3. 산출물이 없으면 coverage = 0% 표시 (에러 아님)
4. rejected 항목은 분모에서 제외 (Coverage 계산)
5. Gap 항목의 source 역추적 필수 (원시 자료 → classified → 미반영 지점)
6. JSON 파일 파싱 실패 시 해당 카테고리 SKIP + 경고
7. Coverage 100% 가 아니어도 Phase gate 차단은 아님 (u-gate에서 별도 판단)
8. HTML 리포트 생성 시 html-report-standard 준수
