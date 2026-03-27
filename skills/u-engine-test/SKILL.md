---
name: engine-test
description: |
  SRS Feature(FT) 기반 테스트 케이스 생성, 테스트 실행(Vitest/Playwright),
  결과 집계, 결함 분류를 수행하는 테스트 엔진.
version: 2.0.0
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
---

# Engine: Test

> FT 기반 테스트 케이스를 생성하고, 실행 결과를 집계하여 리포트를 생성한다.

## 역할

- SRS Feature(FT) 기반 테스트 케이스 자동 생성
- FT당 최소 Unit 2개 + E2E 2개 (Positive, Negative, Boundary)
- Vitest(Unit) / Playwright(E2E) 테스트 실행
- 실행 결과 집계 및 리포트 생성
- 커버리지 분석 (파이 차트 데이터)
- 결함 분류 (Critical/Major/Minor/Info)

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | SRS FT 목록, 기존 테스트 코드, config (테스트 설정) |
| **Output** | TC 문서 (.md + .json), 테스트 코드, 실행 리포트, 커버리지 데이터 |

## 테스트 케이스 생성 규칙

### FT당 최소 TC 수

| 테스트 유형 | 최소 수 | 시나리오 유형 |
|------------|--------|-------------|
| Unit Test | 2개 | Positive + Negative |
| E2E Test | 2개 | Happy Path + Error Path |
| Boundary Test | 1개 (권장) | 경계값 검증 |

### TC ID 규칙

- 형식: `TC-XXXX` (4자리, 10단위 증분)
- FT 매핑 필수: 각 TC에 `ftMapping: FT-XXXX` 기록
- 고유성: 전체 프로젝트에서 TC ID 중복 불허

### TC 구조

```markdown
| TC ID | FT Mapping | Type | Scenario | Steps | Expected | Priority |
|-------|-----------|------|----------|-------|----------|----------|
| TC-0010 | FT-0010 | Unit | 정상 로그인 | 1. 유효 이메일/비밀번호 입력 2. 로그인 API 호출 | 200 OK + JWT 토큰 반환 | High |
```

## 실행 절차

### Step 1. FT 목록 수집

1. SRS 문서에서 전체 FT 목록 추출
2. 기존 TC와 FT 매핑 현황 확인
3. TC 미존재 FT 식별 (갭 분석)

### Step 2. 테스트 케이스 생성

각 FT에 대해:
1. FT 설명에서 테스트 시나리오 도출
2. 시나리오 유형 배정 (Positive, Negative, Boundary)
3. TC 문서 작성 (engine-doc 위임)
4. 테스트 코드 스캐폴딩:

**Unit Test (Vitest)**:
```typescript
// __tests__/unit/FT-0010.test.ts
describe('FT-0010: 로그인', () => {
  it('TC-0010: 유효한 자격증명으로 로그인 성공', async () => { ... });
  it('TC-0020: 잘못된 비밀번호로 로그인 실패', async () => { ... });
});
```

**E2E Test (Playwright)**:
```typescript
// __tests__/e2e/FT-0010.spec.ts
test('TC-0030: 로그인 페이지 정상 플로우', async ({ page }) => { ... });
test('TC-0040: 로그인 실패 에러 메시지 표시', async ({ page }) => { ... });
```

### Step 3. 테스트 실행

1. Unit: `npx vitest run --reporter=json`
2. E2E: `npx playwright test --reporter=json`
3. 실행 결과 JSON 파싱

### Step 4. 결과 집계

실행 결과에서:
- Pass/Fail/Skip 건수 집계
- 실패 TC에 대한 결함 분류:

| 등급 | 기준 |
|------|------|
| **Critical** | 핵심 기능 불가, 데이터 손실, 보안 취약 |
| **Major** | 주요 기능 오류, 성능 심각 저하 |
| **Minor** | UI 불일치, 사소한 기능 오류 |
| **Info** | 개선 권장, 문서 불일치 |

### Step 5. 리포트 생성

- TC 실행 결과 문서: `{app}/04-check/4_TestReport_QA.md` + `.json`
- 커버리지 데이터: FT별 TC 커버리지 비율
- 결함 목록: 등급별 정렬 + FT 매핑

```json
{
  "summary": { "total": 40, "pass": 35, "fail": 4, "skip": 1 },
  "coverage": { "ftTotal": 20, "ftCovered": 18, "percent": 90 },
  "defects": {
    "critical": 0, "major": 1, "minor": 2, "info": 1
  }
}
```

## 오류 처리

| 상황 | 처리 |
|------|------|
| FT 0건 | SRS 선행 필요 안내 |
| Vitest/Playwright 미설치 | 설치 가이드 안내 |
| 테스트 실행 타임아웃 | 개별 TC 타임아웃 기록 + 나머지 계속 실행 |
| 환경 의존 실패 | 환경 설정 체크리스트 출력 |
| 커버리지 기준 미달 | 미커버 FT 목록 + TC 추가 제안 |

## 연동

- **호출원**: `u-skill-testcase`, `u-skill-qa`, `u-agent-qa`
- **호출 대상**: engine-doc (TC 문서/리포트 쓰기)
- **참조 엔진**: engine-validator (Check Gate 검증), engine-code (코드 참조)
