---
name: u-skill-validator
description: "Phase Gate 검증, 문서 간 교차 정합성 검사(13개 규칙), Exit Criteria 판정, 문서 비교 및 검증 리포트를 생성하는 내부 검증 엔진."
---

# u-skill-validator -- Validation & Consistency Engine

Phase Gate 충족 여부 검증, 문서 간 교차 정합성 검사(13개 규칙), Exit Criteria 판정, 문서 버전 비교, 검증 리포트 생성을 수행하는 내부 엔진이다.

**Owner Agent:** u-agent-guardian

---

## 1. Operations

### validateGate(currentPhase, scope)

Phase 전환을 위한 Gate 조건을 검증한다.

**Gate 정의:**

#### Plan → Do Gate

| # | Criterion | Required | Check Method |
|---|-----------|----------|-------------|
| G-P01 | SRS status = Final | MUST | _index.json → srs.status |
| G-P02 | IA status = Final | MUST | _index.json → ia.status |
| G-P03 | Roadmap exists | SHOULD | _index.json → roadmap 존재 |
| G-P04 | 모든 FR에 >= 1 US | MUST | srs.json → FR-US 매핑 |
| G-P05 | 모든 US에 >= 1 FT | MUST | srs.json → US-FT 매핑 |
| G-P06 | 고아 항목 없음 | SHOULD | FT without US, US without FR |

#### Do → Check Gate

| # | Criterion | Required | Check Method |
|---|-----------|----------|-------------|
| G-D01 | ERD status = Final | MUST | _index.json |
| G-D02 | API Contract = Final | MUST | _index.json |
| G-D03 | Screens = Final | MUST | _index.json |
| G-D04 | RTM exists | MUST | _index.json |
| G-D05 | code.md exists | MUST | _index.json |
| G-D06 | 모든 FT code-complete | MUST | code.json → FT 매핑 |
| G-D07 | `bun run build` success | MUST | 빌드 실행 결과 |

#### Check → Act Gate

| # | Criterion | Required | Check Method |
|---|-----------|----------|-------------|
| G-C01 | test-cases.md exists | MUST | _index.json |
| G-C02 | test-report.md exists | MUST | _index.json |
| G-C03 | Critical defects = 0 | MUST | test-report.json → defects |
| G-C04 | Major defects = 0 | MUST | test-report.json → defects |
| G-C05 | All FR implemented & tested | MUST | RTM 완성도 |
| G-C06 | Build success | MUST | 빌드 실행 결과 |
| G-C07 | Test pass rate >= 95% | MUST | test-report.json → passRate |

**출력:**

```json
{
  "gate": "do→check",
  "scope": "retail",
  "passed": false,
  "mustCriteria": {
    "total": 7,
    "passed": 5,
    "failed": 2
  },
  "shouldCriteria": {
    "total": 0,
    "passed": 0,
    "failed": 0
  },
  "details": [
    { "id": "G-D01", "description": "ERD status = Final", "required": "MUST", "status": "pass" },
    { "id": "G-D06", "description": "모든 FT code-complete", "required": "MUST", "status": "fail", "detail": "3/15 FT incomplete: FT-0012, FT-0014, FT-0015" }
  ],
  "blockers": ["G-D06", "G-D07"],
  "recommendation": "3개 FT 구현 완료 + 빌드 수정 후 /u-gate를 다시 실행하세요."
}
```

### validateConsistency(scope)

13개 교차 문서 정합성 규칙을 검증한다.

#### 13 Consistency Rules

| # | Rule | Source | Target | Severity | Check |
|---|------|--------|--------|----------|-------|
| C-01 | FR → >=1 US | srs.json FR | srs.json US | Critical | 모든 FR에 최소 1개 US 매핑 |
| C-02 | US → >=1 FT | srs.json US | srs.json FT | Critical | 모든 US에 최소 1개 FT 매핑 |
| C-03 | FT → Screen mapping | srs.json FT | screens.json | Major | UI 관련 FT가 Screen에 매핑 |
| C-04 | Screen → API endpoints | screens.json | api.json | Major | 데이터 화면이 API와 연결 |
| C-05 | API → ERD entities | api.json | erd.json | Major | API response가 ERD 엔티티 기반 |
| C-06 | RTM completeness | rtm.json | srs+screens+api | Critical | 모든 FR이 RTM에 포함 |
| C-07 | _index.json accuracy | _index.json | 실제 파일 | Critical | 인덱스 엔트리와 파일 1:1 매칭 |
| C-08 | _links.json validity | _links.json | 실제 노드 | Major | 모든 edge의 from/to 노드 존재 |
| C-09 | .md/.json pair | docs/ | docs/ | Major | 모든 .md에 .json 동반 |
| C-10 | Header field presence | 각 .md | -- | Major | 5개 필수 헤더 필드 존재 |
| C-11 | Status value validity | 각 .md | -- | Minor | Status가 Draft/Review/Final 중 하나 |
| C-12 | No orphaned classified | _classified/ | srs.json | Warning | adopted 항목이 SRS에 매핑 |
| C-13 | Backlog source validity | _backlog/ | source ref | Warning | 백로그 source 참조 유효 |

**프로세스:**

```
function validateConsistency(scope):
  results = []

  // C-01: FR → US
  srs = loadJSON(scope, "srs.json")
  for fr in srs.functionalRequirements:
    linkedUS = srs.userStories.filter(us => us.parentFR === fr.id)
    results.push({
      rule: "C-01", item: fr.id,
      passed: linkedUS.length >= 1,
      detail: linkedUS.length === 0 ? "No US linked" : null
    })

  // C-02 through C-13... (각 규칙 순차 검증)

  return {
    scope: scope,
    totalRules: 13,
    passed: results.filter(r => r.passed).length,
    failed: results.filter(r => !r.passed).length,
    bySeverity: {
      critical: results.filter(r => !r.passed && r.severity === "Critical"),
      major: results.filter(r => !r.passed && r.severity === "Major"),
      minor: results.filter(r => !r.passed && r.severity === "Minor"),
      warning: results.filter(r => !r.passed && r.severity === "Warning")
    },
    details: results
  }
```

### validateIndex(scope)

`_index.json`이 실제 파일과 일치하는지 검증한다 (Rule C-07).

**검증 항목:**

| Check | Description |
|-------|-------------|
| Phantom entries | 인덱스에 있지만 파일이 없는 엔트리 |
| Missing entries | 파일은 있지만 인덱스에 없는 문서 |
| Status mismatch | 인덱스 status와 파일 헤더 status 불일치 |
| Version mismatch | 인덱스 version과 파일 헤더 version 불일치 |
| Path mismatch | 인덱스 path와 실제 파일 위치 불일치 |

### validateLinks(scope)

`_links.json` 참조가 유효한지 검증한다 (Rule C-08).

**검증 항목:**

| Check | Description |
|-------|-------------|
| Dangling nodes | 노드가 참조하는 파일이 존재하지 않음 |
| Dangling edges | edge의 from 또는 to 노드가 존재하지 않음 |
| Circular refs | 순환 참조 탐지 |
| Stale flags | 7일 이상 경과한 미해결 impact flag |
| Missing standard | 표준 의존 관계 누락 (SRS→ERD 등) |

### diffDocuments(docA, docB)

두 문서 버전을 비교하여 변경 사항을 식별한다.

**출력:**

```json
{
  "docA": { "path": "srs.md", "version": "1.0" },
  "docB": { "path": "srs.md", "version": "1.2" },
  "changes": {
    "added": [
      { "section": "Functional Requirements", "item": "FR-0015", "content": "..." }
    ],
    "modified": [
      { "section": "User Stories", "item": "US-0003", "field": "description", "from": "...", "to": "..." }
    ],
    "removed": [],
    "headerChanges": {
      "version": { "from": "1.0", "to": "1.2" },
      "status": { "from": "Draft", "to": "Review" }
    }
  },
  "summary": "2 items added, 1 item modified, 0 items removed"
}
```

### generateReport(validationResults)

검증 결과를 구조화된 리포트로 출력한다.

**리포트 형식:**

```markdown
## Validation Report

**Scope:** retail
**Date:** 2026-03-27
**Validator:** u-agent-guardian

### Summary

| Severity | Total | Passed | Failed |
|----------|-------|--------|--------|
| Critical | 4 | 3 | 1 |
| Major | 5 | 4 | 1 |
| Minor | 2 | 2 | 0 |
| Warning | 2 | 1 | 1 |
| **Total** | **13** | **10** | **3** |

### Failed Rules

| Rule | Severity | Item | Detail |
|------|----------|------|--------|
| C-01 | Critical | FR-0008 | No US linked to this FR |
| C-04 | Major | SCR-012 | Settings screen has no API endpoint |
| C-12 | Warning | PP-005 | Classified item not adopted in any document |

### Recommendations
1. FR-0008에 User Story를 추가하세요 (/u-add retail us "FR-0008 story")
2. SCR-012 Settings 화면의 API 엔드포인트를 설계하세요
```

### exitCriteria(scope)

Exit Criteria를 평가한다 (Check Phase 완료 판정용).

**Primary Criteria (ALL must pass):**

| # | Criterion | Threshold |
|---|-----------|-----------|
| E-01 | Critical defects = 0 open | 0 |
| E-02 | Major defects = 0 open | 0 |
| E-03 | All FR implemented | RTM 100% |
| E-04 | Build success | exit 0 |
| E-05 | Test pass rate | >= 95% |

**Secondary Criteria (advisory):**

| # | Criterion | Threshold |
|---|-----------|-----------|
| S-01 | Minor defects | < 10 open |
| S-02 | Test coverage | >= 80% (TC vs FT) |
| S-03 | Storybook coverage | >= 90% |

---

## 2. Safety Rules

1. Gate 검증 실패 시 자동 Phase 전환 불가 (Always-Pause)
2. Critical/Major severity 결함의 severity 하향 조정 금지
3. 검증 결과는 불변 (수정 금지, 재검증 시 새 리포트)
4. Exit Criteria primary 항목은 예외 허용 불가 (모두 pass 필수)
5. consistency 검증은 READ-ONLY (문서를 수정하지 않고 보고만)
6. diff는 양방향 비교 (A→B 변경 + B→A 변경 모두 표시)
7. 검증 리포트에 검증 날짜와 scope 명시 필수
8. 자동 수정 제안은 advisory (직접 수정은 사용자 승인 후)
