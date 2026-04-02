---
name: u-skill-test
description: "SRS Feature(FT) 기반 테스트 케이스 생성, 테스트 실행(Vitest/Playwright), 결함 분류, 테스트 리포트 생성, 백로그 자동 등록을 수행하는 내부 테스트 엔진."
---

# u-skill-test -- Test Generation & Execution Engine

SRS Feature(FT) + Screen 기반 TC 자동 생성 → Vitest/Playwright 실행 → 결함 분류 → 리포트 생성 → 백로그 등록.

**Owner Agent:** u-agent-gatekeeper

---

## 1. Operations

### generateTestCases(srsFeatures, screens)

**입력:** `srs.json` (FT 목록), `screens.json`, `api.json`

**FT 특성별 TC 생성:**

| FT Characteristic | Generated TC Types |
|-------------------|-------------------|
| UI Component | E2E: 렌더링, 인터랙션, 반응형 |
| Form Input | Positive(유효) / Negative(무효,빈값,XSS) / Boundary(최대길이,특수문자) |
| API Endpoint | Integration: 성공, 인증실패, 유효성에러, 404, 500 |
| Data Processing | Unit: CRUD / Boundary: 동시성, 중복, null |
| Business Logic | Unit: 계산, 상태전환 / Boundary: 경계값 |
| Navigation | E2E: 라우트, 리다이렉트, 뒤로가기, 딥링크 |

**TC 비율:** Happy Path 40% / Negative 35% / Boundary 25%

**TC 구조:** `TC-{TYPE}-{NNNN}` (TC-U: Unit, TC-I: Integration, TC-E: E2E) -- Related FT, Category, Priority, Type, Preconditions, Test Steps, Expected/Actual Result, Status(Not Run/Pass/Fail/Blocked)

**프로세스:** FT별 특성 분석 → Happy/Negative/Boundary TC 생성 → `docs/{app}/04-check/test-cases.md` + `.json`

### executeTests(scope, type)

| Type | Runner | Command |
|------|--------|---------|
| Unit | Vitest | `vitest run` |
| Integration | Vitest | `vitest run --config vitest.integration.config.ts` |
| E2E | Playwright | `playwright test` |

실행 순서: Unit → Integration → E2E. 결과: `{ type, runner, executedAt, duration, total, passed, failed, skipped, passRate, failures[] }`

### classifyDefects(testResults)

| Severity | Criteria | Release |
|----------|----------|---------|
| Critical | 크래시, 데이터 손실, 보안 위반, 핵심 기능 불능 | 차단 |
| Major | 기능 오작동, 잘못된 결과, 심각한 UX 저하 | 차단 |
| Minor | 외관, 경미한 UX 불일치, 에지케이스 | 비차단 |
| Trivial | 오타, 1-2px 정렬, 문서 오류 | 비차단 |

**자동 분류:** crash/segfault/ENOMEM → Critical, security/auth/data-loss TC → Critical, Must FT happy-path 실패 → Critical, happy-path 실패 → Major, boundary → Minor, style/layout → Minor, 나머지 → Trivial

**결함 레코드:** `DEF-{NNNN}` -- severity, relatedTC, relatedFT, stepsToReproduce, expected/actual, file, line

### generateTestReport(results)

3종 동시 생성 (.md + .json + .html): Summary(Type별 Total/Passed/Failed/PassRate), Defect Summary(Severity별), Failed Tests, Exit Criteria Evaluation(E-01~E-05)

### registerBugs(defects)

| Severity | Target | Priority | Immediate |
|----------|--------|----------|-----------|
| Critical/Major | Current iteration | must | Yes |
| Minor | General backlog | should | No |
| Trivial | General backlog | could | No |

등록 후 원 TC에 defect ID 역링크.

---

## 2. RTM Update

테스트 후 RTM 갱신: TC IDs, Test Status(Pass/Fail), Implementation Status, Defect IDs

---

## 3. Safety Rules

1. 테스트 결과 불변 (재실행 시 신규 리포트), 결함 등록 자동 (모든 실패=결함)
2. Critical/Major severity 하향 조정 금지
3. 리포트 3종 동시, TC에 FT 역참조 필수 (고아 TC 금지)
4. E2E는 빌드 성공 후에만, 결함에 재현 절차 필수
5. `_index.json` 갱신 필수, 모든 결함은 FT+TC 역추적 가능
