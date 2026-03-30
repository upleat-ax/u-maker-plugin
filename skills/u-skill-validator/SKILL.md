---
name: u-skill-validator
description: "Phase Gate 검증, 문서 간 교차 정합성 검사(13개 규칙), Exit Criteria 판정, 문서 비교 및 검증 리포트를 생성하는 내부 검증 엔진."
---

# u-skill-validator -- Validation & Consistency Engine

Phase Gate 검증, 13개 교차 정합성 규칙, Exit Criteria 판정, 문서 diff, 검증 리포트 생성.

**Owner Agent:** u-agent-guardian

---

## 1. Operations

### validateGate(currentPhase, scope)

#### Plan → Do Gate

| # | Criterion | Required |
|---|-----------|----------|
| G-P01 | SRS status = Final | MUST |
| G-P02 | IA status = Final | MUST |
| G-P03 | Roadmap exists | SHOULD |
| G-P04 | 모든 FR에 >=1 US | MUST |
| G-P05 | 모든 US에 >=1 FT | MUST |
| G-P06 | 고아 항목 없음 | SHOULD |

#### Do → Check Gate

| # | Criterion | Required |
|---|-----------|----------|
| G-D01 | ERD = Final | MUST |
| G-D02 | API Contract = Final | MUST |
| G-D03 | Screens = Final | MUST |
| G-D04 | RTM exists | MUST |
| G-D05 | code.md exists | MUST |
| G-D06 | 모든 FT code-complete | MUST |
| G-D07 | build success | MUST |

#### Check → Act Gate

| # | Criterion | Required |
|---|-----------|----------|
| G-C01 | test-cases.md exists | MUST |
| G-C02 | test-report.md exists | MUST |
| G-C03 | Critical defects = 0 | MUST |
| G-C04 | Major defects = 0 | MUST |
| G-C05 | All FR implemented & tested | MUST |
| G-C06 | Build success | MUST |
| G-C07 | Test pass rate >= 95% | MUST |

**출력:** `{ gate, scope, passed, mustCriteria(total/passed/failed), details[], blockers[], recommendation }`

### validateConsistency(scope) -- 13 Rules

| # | Rule | Source → Target | Severity |
|---|------|----------------|----------|
| C-01 | FR → >=1 US | srs FR → srs US | Critical |
| C-02 | US → >=1 FT | srs US → srs FT | Critical |
| C-03 | FT → Screen | srs FT → screens | Major |
| C-04 | Screen → API | screens → api | Major |
| C-05 | API → ERD entity | api → erd | Major |
| C-06 | RTM completeness | rtm → srs+screens+api | Critical |
| C-07 | _index.json accuracy | index → 실제 파일 | Critical |
| C-08 | _links.json validity | links → 실제 노드 | Major |
| C-09 | .md/.json pair | docs/ | Major |
| C-10 | Header field presence | 각 .md (5개 필수) | Major |
| C-11 | Status value validity | Draft/Review/Final | Minor |
| C-12 | No orphaned classified | _classified → srs | Warning |
| C-13 | Backlog source validity | _backlog → source ref | Warning |

**출력:** `{ totalRules: 13, passed, failed, bySeverity, details[] }`

### validateIndex(scope) -- C-07

Phantom entries(인덱스O 파일X), Missing entries(파일O 인덱스X), Status/Version/Path mismatch 검증.

### validateLinks(scope) -- C-08

Dangling nodes/edges, Circular refs, Stale flags(7일+), Missing standard relations 검증.

### diffDocuments(docA, docB)

두 버전 비교: `{ added, modified, removed, headerChanges, summary }`

### generateReport(validationResults)

Severity별 Summary 테이블 + Failed Rules + Recommendations 포함 리포트.

### exitCriteria(scope)

**Primary (ALL must pass):**

| # | Criterion | Threshold |
|---|-----------|-----------|
| E-01 | Critical defects = 0 | 0 |
| E-02 | Major defects = 0 | 0 |
| E-03 | All FR implemented | RTM 100% |
| E-04 | Build success | exit 0 |
| E-05 | Test pass rate | >= 95% |

**Secondary (advisory):** Minor <10 open, TC coverage >=80%, Storybook >=90%

---

## 2. Safety Rules

1. Gate 실패 시 자동 Phase 전환 불가 (Always-Pause)
2. Critical/Major severity 하향 금지, 검증 결과 불변 (재검증 시 신규)
3. Exit Criteria primary 예외 불가, consistency 검증은 READ-ONLY
4. diff 양방향 비교, 리포트에 날짜+scope 명시 필수
5. 자동 수정 제안은 advisory (사용자 승인 후 적용)
