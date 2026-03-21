---
name: u-skill-tc-add
description: |
  새로운 테스트 케이스(TC)를 추가한다. {app}/04-check/4_Case_QA.md에 TC 항목을 생성하고 Change Log를 갱신한다.
  특정 앱 또는 모든 앱에 대해 개별 TC를 증분 추가할 수 있다.
  Args: `[app] [FT-NNNN] [description]` — 앱 이름 + 대상 FT + TC 설명 (생략 시 대화형 입력)
  Triggers: /u-skill-tc-add, 테스트케이스 추가, TC 추가, test case add, new TC, add test case, TC 신규, 케이스 추가, append TC, 테스트 추가, 새 테스트케이스, new test case
user-invocable: true
argument-hint: "[app] [FT-NNNN] [description]"
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  u-agent-qa: u-maker:u-agent-qa
---

# Test Case Add

> 새로운 TC를 4_Case_QA.md의 testCases 섹션에 추가한다.

## Syntax

```
/u-skill-tc-add [app] [FT-NNNN] [description]
```

- `[app]`: 멀티앱 프로젝트 시 앱 이름 (e.g., `web`). `all`이면 모든 앱에 추가
- `[FT-NNNN]`: 매핑할 Feature ID (생략 시 대화형 입력)
- `[description]`: TC 설명 (생략 시 대화형 입력)

## Flow

```
1. App Context 결정 (단일앱 자동선택 / 멀티앱 인자 또는 AskUserQuestion)
2. app=all이면 모든 앱 목록 수집 → 각 앱에 대해 3~9 반복
3. 4_Case_QA.md 존재 확인 (없으면 템플릿 자동 생성)
4. 기존 TC-ID 최대값 → 다음 TC-ID 채번 (10단위 올림)
5. FT-NNNN 유효성 검증 (1_SRS_RA.md에 존재 확인)
6. FT에서 US 매핑 자동 추출
7. TC 항목 정보 수집 (대화형 또는 인자)
8. testCases 테이블에 TC 행 추가 + coverageMatrix 갱신
9. 동명의 .json 파일 동기화
10. _links.json qa 필드 갱신
11. Change Log 갱신
```

## Input Fields

| Field | Required | Default | Values |
|-------|----------|---------|--------|
| FT Mapping | Y | - | FT-NNNN |
| Title | Y | - | TC 제목 |
| Level | Y | Unit | Unit, E2E |
| Type | N | Positive | Positive, Negative, Boundary |
| Priority | N | Major | Critical, Major, Minor, Trivial |
| Actor | N | 일반 사용자 | 테스트 수행자 역할 |
| Precondition | N | - | PRE-NNNN (쉼표 구분) |
| AutomationTarget | N | Vitest (Unit) / Playwright (E2E) | Vitest, Playwright |
| Steps | Y | - | 최소 1개 스텝 (screen/element/action/input/expected) |

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app | Auto-select |
| Multiple apps + `all` argument | 모든 앱에 동일 TC 추가 |
| Multiple apps + specific app argument | Use specified app |
| Multiple apps + no argument | AskUserQuestion |

## Step Format (6W)

각 테스트 스텝은 6W 구조를 따른다:

| Field | Description | Example |
|-------|-------------|---------|
| step | 스텝 번호 | 1 |
| screen | 화면 이름 | 로그인 페이지 |
| element | UI 요소 | 이메일 입력 필드 |
| action | 수행 동작 | 입력 |
| input | 입력 데이터 | test@example.com |
| expected | 기대 결과 | 입력값이 필드에 표시됨 |

## Template (4_Case_QA.md 신규 생성 시)

4_Case_QA.md가 존재하지 않으면 아래 골격으로 자동 생성한다:

```markdown
# Test Cases — {app}

| Field | Value |
|-------|-------|
| Owner | u-agent-qa |
| Status | Draft |
| Version | v0.1.0 |
| Last Updated | YYYY-MM-DD |

## 1. Background

### 1.1 Purpose
SRS Feature(FT) 기반 테스트 케이스 설계

### 1.2 Test Strategy
- **Test Types**: Unit, E2E
- **Coverage Target**: 80%+
- **Tools**: Vitest (Unit), Playwright (E2E)
- **Environment**: Local + CI

## 2. Test Conditions

### 2.1 Prerequisites
| PRE-ID | Condition | Description |
|--------|-----------|-------------|

### 2.2 Test Data
| DataSet | Description | Records |
|---------|-------------|---------|

## 3. Test Cases

| TC-ID | FT | US | Level | Type | Priority | Title | Result |
|-------|----|----|-------|------|----------|-------|--------|

### TC Detail

(여기에 TC 상세 블록 추가)

## 4. Coverage Matrix

| FT | Feature | Unit Cases | E2E Cases | Coverage |
|----|---------|------------|-----------|----------|

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| v0.1.0 | YYYY-MM-DD | u-agent-qa | Initial creation |
```

## TC Detail Block Format

```markdown
### TC-NNNN {title}

- **FT**: FT-NNNN
- **US**: US-NNNN
- **Level**: Unit / E2E
- **Type**: Positive / Negative / Boundary
- **Priority**: Critical / Major / Minor / Trivial
- **Actor**: {actor}
- **Precondition**: {precondition}
- **Automation**: {automationTarget}

| Step | Screen | Element | Action | Input | Expected |
|------|--------|---------|--------|-------|----------|
| 1 | ... | ... | ... | ... | ... |
```

## Rules

- u-agent-qa 에이전트가 담당
- TC-ID: 4자리 10단위 자동 채번 (TC-0010, TC-0020, ...)
- FT Mapping은 필수 — 1_SRS_RA.md에 존재하는 FT-NNNN만 허용
- US Mapping은 FT에서 자동 추출 (SRS 또는 _links.json 참조)
- Result 상태는 항상 `Pending`으로 생성
- Steps는 최소 1개 필수 (6W 구조: step/screen/element/action/input/expected)
- coverageMatrix에 해당 FT 행이 없으면 신규 추가, 있으면 TC-ID 목록에 append
- `app=all`이면 config의 apps 목록을 순회하며 각 앱의 4_Case_QA.md에 동일 TC 추가 (TC-ID는 앱별 독립 채번)
- Version은 Minor 증가
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- `_links.json`의 해당 FT 매핑에 `qa` 필드 갱신
- Post-Execution Summary Box 출력 필수
