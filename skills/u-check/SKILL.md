---
name: u-check
description: "CHECK Phase. TC 설계 + 테스트 실행 + Report + exit criteria 판정. SRS Feature(FT) 기반 TestCase 자동 생성, Vitest/Playwright 실행, 결함 분류, 백로그 자동 등록까지 수행한다."
triggers:
  - "/u-check"
  - "check phase"
  - "QA"
  - "테스트"
  - "검증"
---

# u-check -- Check Phase QA Verification

`/u-check [scope] [-i] [--step]` 명령으로 Do phase 산출물을 검증한다. TestCase 설계, 테스트 실행, 결함 분석, exit criteria 판정을 수행한다.

**Primary Agent:** u-agent-guardian (engine-validator, engine-test 사용)

---

## Flags

| Flag | Description |
|------|-------------|
| `-i` | 분기점에서 사용자 확인 |
| `--step` | 매 단계 결과 표시 후 승인 대기 |

---

## Execution Flow

### Step 0: Verify Do Phase Gate

1. `_index.json` 읽어 Do phase 상태 확인
2. **필수 조건:**
   - 모든 FT 항목이 code-complete (code.json 확인)
   - `bun run build` 성공 (exit code 0)
3. Gate 미통과 시:
   - 미완성 FT 목록 표시
   - 빌드 에러 표시
   - "/u-build를 먼저 완료하세요" 안내

### Step 1: Auto-Generate TestCases from SRS Features

**입력:** `srs.json` (FT 목록), `screens.json`, `api.json`

**FT 특성별 TC 생성 규칙:**

| FT 특성 | 생성되는 TC 유형 |
|---------|-----------------|
| UI 컴포넌트 | E2E (렌더링, 인터랙션, 반응형) |
| 폼 입력 | Positive (유효), Negative (무효, 빈값, XSS), Boundary (최대 길이, 특수문자) |
| API 엔드포인트 | Integration (성공, 인증 실패, 유효성 에러, 404, 500) |
| 데이터 처리 | Unit (CRUD), Boundary (동시성, 중복, null) |
| 비즈니스 로직 | Unit (계산, 상태 전환), Boundary (경계값) |
| 내비게이션 | E2E (라우트 접근, 리다이렉트, 뒤로가기, 딥링크) |

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
- TC-U-{nnnn}: Unit test
- TC-I-{nnnn}: Integration test
- TC-E-{nnnn}: E2E test
- 앱 스코프 내 전역 고유

**산출물:** `docs/{app}/04-check/test-cases.md` + `test-cases.json`

### Step 2: Execute Tests

테스트 프레임워크 확인: `app.config.json` → `techStack.testing`

**실행 순서:**

1. **Unit Tests:**
   ```bash
   vitest run
   ```
   - 로직, 유틸리티, 훅 검증

2. **Integration Tests:**
   ```bash
   vitest run --config vitest.integration.config.ts
   ```
   - API route, DB operation 검증

3. **E2E Tests:**
   ```bash
   playwright test
   ```
   - 전체 사용자 흐름 검증

4. **결과 수집:**
   - 테스트 러너 출력 파싱 (pass/fail/skip 카운트, 실패 상세)

### Step 3: Classify Defects

테스트 실패를 자동 분류:

| Severity | Criteria | Impact |
|----------|----------|--------|
| **Critical** | 시스템 크래시, 데이터 손실, 보안 위반, 핵심 기능 불능 | 릴리스 차단. exit criteria 차단. |
| **Major** | 기능 오작동, 잘못된 결과, 심각한 UX 저하 | 릴리스 차단. exit criteria 차단. |
| **Minor** | 외관 이슈, 경미한 UX 불일치, 에지 케이스 실패 | 수정 권장, 릴리스 비차단 |
| **Trivial** | 오타, 1-2px 정렬 오차, 문서 오류 | 최저 우선순위 |

**결함 레코드:**

```json
{
  "id": "DEF-{NNNN}",
  "title": "간략 설명",
  "severity": "Critical|Major|Minor|Trivial",
  "status": "Open",
  "relatedTC": "TC-{type}-{NNNN}",
  "relatedFT": "FT-{NNNN}",
  "foundIn": "iteration-{n}",
  "assignedTo": "u-agent-builder",
  "description": "상세 설명",
  "stepsToReproduce": ["step 1", "step 2"],
  "expectedBehavior": "...",
  "actualBehavior": "..."
}
```

### Step 4: Auto-Register Bugs to Backlog

모든 결함을 자동으로:
1. `docs/{app}/04-check/defects/` 에 결함 레코드 저장
2. `_backlog/_index.json`에 등록 (severity → priority 매핑)
3. `u-agent-builder`에 수정 할당
4. 원 TC 및 FT에 역링크

### Step 5: Generate Test Report

**산출물:** `test-report.md` + `test-report.json` + `test-report.html` (3종 동시)

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

### Failed Tests
| TC ID | Test Name | Type | Error | Severity | Related FT |
|-------|-----------|------|-------|----------|------------|
| TC-U-0023 | calculateDiscount | Unit | Expected 0, got NaN | Major | FT-0034 |

### Defects Registered
- DEF-0001: {title} (Critical)
- DEF-0002: {title} (Major)
```

### Step 6: Evaluate Exit Criteria

**Primary Exit Criteria (ALL must pass):**

| # | Criterion | Threshold | Check |
|---|-----------|-----------|-------|
| E-01 | Critical defects | 0 open | DEF severity=Critical AND status in (Open, In Progress) = 0 |
| E-02 | Major defects | 0 open | DEF severity=Major AND status in (Open, In Progress) = 0 |
| E-03 | All FR implemented | 100% | RTM: 모든 FR status = "Implemented + Tested" |
| E-04 | Build success | Pass | 프로덕션 빌드 통과 |
| E-05 | Test pass rate | >= 95% | (Total passed) / (Total executed) >= 0.95 |

**Secondary Criteria (advisory, 비차단):**

| # | Criterion | Threshold |
|---|-----------|-----------|
| S-01 | Minor defects | < 10 open |
| S-02 | Test coverage | >= 80% (TC count vs FT count) |
| S-03 | Storybook coverage | >= 90% |

### Step 7: Determine Next Action

**Exit criteria 전체 PASS:**
- "Ship 준비 완료. /u-ship을 실행하세요." 안내
- RTM 최종 갱신

**Exit criteria FAIL:**
- 실패 항목 상세 보고
- 차단 이슈 목록 제시
- 수정 예상 공수 표시
- "결함 수정 후 /u-check를 다시 실행하세요." 안내
- 심각한 실패 시: "/u-ship은 Act(회고) 경로로 전환됩니다." 고지

---

## RTM Update

테스트 완료 후 RTM 자동 갱신:
- TC IDs 컬럼 채움
- Test Status 컬럼 갱신 (Pass/Fail)
- Implementation 컬럼 갱신 (Complete/In Progress)
- `rtm.md` + `rtm.json` 재생성

---

## Safety Rules

1. Do phase gate 미통과 시 진행 불가 (code complete + build success 필수)
2. Phase gate 실패 시 자동 진행 불가 (Always-Pause)
3. Critical/Major 결함의 severity 하향 조정 금지
4. 테스트 결과는 불변 (수정 금지, 재실행 시 신규 리포트 생성)
5. 결함 등록은 자동 (모든 실패 = 결함 레코드, 예외 없음)
6. `.json` + `.html` 동반 파일 생성 필수 (test report는 3종)
7. `_index.json` 갱신 필수
8. 회고 없는 retrospective 생성 금지 (실제 iteration 데이터 필수)
