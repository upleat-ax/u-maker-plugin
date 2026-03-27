---
name: u-skill-test
description: "SRS Feature(FT) 기반 테스트 케이스 생성, 테스트 실행(Vitest/Playwright), 결함 분류, 테스트 리포트 생성, 백로그 자동 등록을 수행하는 내부 테스트 엔진."
---

# u-skill-test -- Test Generation & Execution Engine

SRS Feature(FT)와 Screen 설계를 기반으로 테스트 케이스를 자동 생성하고, Vitest(Unit/Integration) 및 Playwright(E2E)로 테스트를 실행하며, 결함을 분류하여 테스트 리포트를 생성하고, 결함을 백로그에 자동 등록하는 내부 엔진이다.

**Owner Agent:** u-agent-guardian

---

## 1. Operations

### generateTestCases(srsFeatures, screens)

SRS Feature(FT) 기반으로 테스트 케이스를 자동 생성한다.

**입력:**
- `srs.json` → features 배열 (FT 목록)
- `screens.json` → 화면 상세 설계
- `api.json` → API 엔드포인트 스펙

**FT 특성별 TC 생성 규칙:**

| FT Characteristic | Generated TC Types |
|-------------------|-------------------|
| UI Component | E2E: 렌더링, 인터랙션, 반응형 |
| Form Input | Positive: 유효 입력 / Negative: 무효, 빈값, XSS / Boundary: 최대 길이, 특수문자 |
| API Endpoint | Integration: 성공, 인증 실패, 유효성 에러, 404, 500 |
| Data Processing | Unit: CRUD / Boundary: 동시성, 중복, null |
| Business Logic | Unit: 계산, 상태 전환 / Boundary: 경계값 |
| Navigation | E2E: 라우트 접근, 리다이렉트, 뒤로가기, 딥링크 |

**TC 카테고리별 생성 비율 (권장):**

| Category | Description | Ratio |
|----------|-------------|-------|
| Happy Path | 정상 사용 흐름 | 40% |
| Negative | 비정상 입력, 인증 실패, 권한 부족 | 35% |
| Boundary | 경계값, 빈 상태, 최대 한도 | 25% |

**TC 구조:**

```markdown
## TC-{TYPE}-{NNNN}: {Title}

| Field | Value |
|-------|-------|
| **Related FT** | FT-{NNNN} |
| **Category** | Positive / Negative / Boundary |
| **Priority** | Critical / High / Medium / Low |
| **Type** | Unit / Integration / E2E |
| **Preconditions** | {테스트 전 필요 상태} |
| **Test Steps** | 1. {step} 2. {step} ... |
| **Expected Result** | {기대 결과} |
| **Actual Result** | {실행 후 기입} |
| **Status** | Not Run / Pass / Fail / Blocked |
```

**TC 번호 체계:**

| Prefix | Type | Example |
|--------|------|---------|
| TC-U-{nnnn} | Unit Test | TC-U-0001 |
| TC-I-{nnnn} | Integration Test | TC-I-0001 |
| TC-E-{nnnn} | E2E Test | TC-E-0001 |

**프로세스:**

```
function generateTestCases(features, screens):
  testCases = []

  for ft in features:
    characteristics = analyzeFTCharacteristics(ft, screens)

    // Happy path
    testCases.push(generateHappyPath(ft, characteristics))

    // Negative cases
    for negCase in generateNegativeCases(ft, characteristics):
      testCases.push(negCase)

    // Boundary cases
    for boundaryCase in generateBoundaryCases(ft, characteristics):
      testCases.push(boundaryCase)

  // 산출물 생성
  docEngine.create("test-cases", scope, testCases)
  return { totalGenerated: testCases.length, byType: groupCount(testCases, "type") }
```

**출력:** `docs/{app}/04-check/test-cases.md` + `test-cases.json`

### executeTests(scope, type)

테스트를 실행한다.

**지원 테스트 러너:**

| Type | Runner | Config | Command |
|------|--------|--------|---------|
| Unit | Vitest | `vitest.config.ts` | `vitest run` |
| Integration | Vitest | `vitest.integration.config.ts` | `vitest run --config vitest.integration.config.ts` |
| E2E | Playwright | `playwright.config.ts` | `playwright test` |

**실행 순서:**

1. **Unit Tests**: 로직, 유틸리티, 훅 검증
2. **Integration Tests**: API route, DB operation 검증
3. **E2E Tests**: 전체 사용자 흐름 검증

**결과 수집:**

```json
{
  "type": "unit",
  "runner": "vitest",
  "executedAt": "{ISO 8601}",
  "duration": 12500,
  "total": 120,
  "passed": 115,
  "failed": 3,
  "skipped": 2,
  "passRate": 0.958,
  "failures": [
    {
      "testName": "calculateDiscount should return 0 for negative amount",
      "file": "src/lib/utils/discount.test.ts",
      "line": 42,
      "error": "Expected 0, received NaN",
      "type": "AssertionError"
    }
  ]
}
```

### classifyDefects(testResults)

테스트 실패를 심각도에 따라 분류한다.

**분류 기준:**

| Severity | Criteria | Impact | Release |
|----------|----------|--------|---------|
| **Critical** | 시스템 크래시, 데이터 손실, 보안 위반, 핵심 기능 불능 | 서비스 불가 | 차단 |
| **Major** | 기능 오작동, 잘못된 결과, 심각한 UX 저하 | 기능 사용 불가 | 차단 |
| **Minor** | 외관 이슈, 경미한 UX 불일치, 에지 케이스 실패 | 기능 사용 가능 | 비차단 |
| **Trivial** | 오타, 1-2px 정렬 오차, 문서 오류 | 거의 없음 | 비차단 |

**자동 분류 로직:**

```
function classifyDefect(failure, ft):
  // Critical 판정
  if failure.error contains "crash|segfault|ENOMEM":
    return "Critical"
  if failure.testName contains "security|auth|data-loss":
    return "Critical"
  if ft.priority === "Must" and failure.category === "happy-path":
    return "Critical"

  // Major 판정
  if failure.category === "happy-path":
    return "Major"
  if ft.priority === "Must":
    return "Major"

  // Minor 판정
  if failure.category === "boundary":
    return "Minor"
  if failure.error contains "style|layout|alignment":
    return "Minor"

  // Trivial
  return "Trivial"
```

**결함 레코드:**

```json
{
  "id": "DEF-{NNNN}",
  "title": "calculateDiscount returns NaN for negative amount",
  "severity": "Major",
  "status": "Open",
  "relatedTC": "TC-U-0023",
  "relatedFT": "FT-0034",
  "foundIn": "iteration-1",
  "assignedTo": "u-agent-builder",
  "description": "할인 계산 함수가 음수 금액에 대해 NaN을 반환함",
  "stepsToReproduce": ["1. calculateDiscount(-100) 호출", "2. 반환값 확인"],
  "expectedBehavior": "0을 반환",
  "actualBehavior": "NaN을 반환",
  "file": "src/lib/utils/discount.ts",
  "line": 15
}
```

### generateTestReport(results)

테스트 결과를 종합 리포트로 생성한다 (3종: .md + .json + .html).

**리포트 구조:**

```markdown
## Test Report

**App:** {app}
**Iteration:** {n}
**Date:** {ISO 8601}
**Executor:** u-agent-guardian

### Summary

| Type | Total | Passed | Failed | Skipped | Pass Rate |
|------|-------|--------|--------|---------|-----------|
| Unit | 120 | 115 | 3 | 2 | 95.8% |
| Integration | 45 | 43 | 2 | 0 | 95.6% |
| E2E | 30 | 28 | 1 | 1 | 93.3% |
| **Total** | **195** | **186** | **6** | **3** | **95.4%** |

### Defect Summary

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 0 | -- |
| Major | 2 | Open |
| Minor | 3 | Open |
| Trivial | 1 | Open |

### Failed Tests

| TC ID | Test Name | Type | Error | Severity | Related FT |
|-------|-----------|------|-------|----------|------------|
| TC-U-0023 | calculateDiscount | Unit | Expected 0, got NaN | Major | FT-0034 |

### Exit Criteria Evaluation

| # | Criterion | Threshold | Actual | Status |
|---|-----------|-----------|--------|--------|
| E-01 | Critical defects | 0 | 0 | PASS |
| E-02 | Major defects | 0 | 2 | FAIL |
| E-03 | All FR implemented | 100% | 95% | FAIL |
| E-04 | Build success | Pass | Pass | PASS |
| E-05 | Test pass rate | >= 95% | 95.4% | PASS |
```

### registerBugs(defects)

결함을 백로그에 자동 등록한다.

**등록 규칙:**

| Severity | Target | Priority | Immediate |
|----------|--------|----------|-----------|
| Critical | Current iteration backlog | must | Yes (즉시 수정) |
| Major | Current iteration backlog | must | Yes (즉시 수정) |
| Minor | General backlog | should | No (다음 iteration) |
| Trivial | General backlog | could | No (리소스 여유 시) |

**프로세스:**

```
function registerBugs(defects):
  registered = []

  for defect in defects:
    backlogItem = {
      title: defect.title,
      type: "bug",
      severity: defect.severity,
      priority: severityToPriority(defect.severity),
      status: "todo",
      iteration: isBlocking(defect) ? currentIteration : null,
      assignedTo: "u-agent-builder",
      source: { type: "check", ref: defect.id },
      relatedItems: {
        ft: defect.relatedFT,
        tc: defect.relatedTC,
        defect: defect.id
      },
      description: defect.description
    }

    result = backlogEngine.create(backlogItem)
    registered.push(result)

    // 원 TC에 결함 ID 역링크
    updateTC(defect.relatedTC, { defectId: defect.id })

  return {
    totalRegistered: registered.length,
    blocking: registered.filter(r => r.priority === "must").length,
    nonBlocking: registered.filter(r => r.priority !== "must").length
  }
```

---

## 2. RTM Update After Testing

테스트 완료 후 RTM을 자동 갱신한다.

| RTM Column | Update Source |
|------------|-------------|
| TC IDs | 생성된 TC ID 목록 |
| Test Status | Pass / Fail |
| Implementation Status | Complete / In Progress |
| Defect IDs | 등록된 DEF ID |

---

## 3. Safety Rules

1. 테스트 결과는 불변 (수정 금지, 재실행 시 신규 리포트)
2. 결함 등록은 자동 (모든 실패 = 결함 레코드, 예외 없음)
3. Critical/Major 결함의 severity 하향 조정 금지
4. 테스트 리포트는 3종 동시 생성 (.md + .json + .html)
5. TC 생성 시 FT 역참조 필수 (고아 TC 금지)
6. E2E 테스트는 빌드 성공 후에만 실행
7. 테스트 환경 설정은 `app.config.json` → techStack.testing 참조
8. `_index.json` 갱신 필수
9. 결함 레코드에 재현 절차(stepsToReproduce) 필수 포함
10. 모든 결함은 FT + TC 역추적 가능해야 함
