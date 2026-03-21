---
name: u-skill-tc-refine
description: |
  테스트 케이스(TC)를 세분화한다. 하나의 큰 TC를 분석하여 더 작고 구체적인 하위 TC로 분해하고 4_Case_QA.md를 갱신한다.
  Args: `<TC-NNNN> [app]` — 세분화할 TC ID + 앱 이름 (필수)
  Triggers: /u-skill-tc-refine, TC 세분화, TC 분해, test case refine, split TC, decompose TC, 테스트케이스 세분화, 케이스 분해, TC 쪼개기, refine test case, break down TC, 테스트 분해
user-invocable: true
argument-hint: "<TC-NNNN> [app]"
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

# Test Case Refine (Decompose)

> 하나의 큰 TC를 분석하여 더 작고 구체적인 하위 TC로 세분화한다.

## Syntax

```
/u-skill-tc-refine <TC-NNNN> [app]
```

- `TC-NNNN`: 세분화할 테스트 케이스 ID (필수)
- `[app]`: 멀티앱 프로젝트 시 앱 이름 (생략 시 자동 선택 또는 AskUserQuestion)

## When to Use

- 하나의 TC에 여러 독립적인 시나리오가 혼합되어 있을 때
- TC 스텝이 너무 많아(10+) 실패 원인 추적이 어려울 때
- Positive/Negative/Boundary 케이스가 하나의 TC에 섞여 있을 때
- Unit과 E2E 레벨이 하나의 TC에 혼합되어 있을 때
- QA 리뷰에서 "이 TC를 더 쪼개야 한다"는 피드백이 나왔을 때

## Flow

```
1. App Context 결정 (단일앱 자동선택 / 멀티앱 인자 또는 AskUserQuestion)
2. 4_Case_QA.md 읽기 → 대상 TC 항목의 현재 내용 추출
3. TC가 존재하지 않으면 에러 메시지 후 종료
4. 세분화 분석 → 하위 TC 초안 생성
5. 사용자 확인 (AskUserQuestion) → 승인/수정
6. 4_Case_QA.md 갱신 (테이블 + Detail 블록)
7. coverageMatrix 갱신 (원본 TC-ID → 하위 TC-ID들로 교체)
8. 동명의 .json 파일 동기화
9. _links.json qa 필드 갱신
10. Change Log 갱신
```

## Decomposition Criteria

하위 TC 분해 시 아래 기준을 적용한다:

| 기준 | 설명 |
|------|------|
| **시나리오 독립성** | 서로 다른 사용자 시나리오가 혼합되어 있는가? |
| **Type 분리** | Positive/Negative/Boundary가 하나의 TC에 섞여 있는가? |
| **Level 분리** | Unit과 E2E가 하나의 TC에 혼합되어 있는가? |
| **스텝 복잡도** | 스텝이 10개 이상이거나 여러 화면을 넘나드는가? |
| **입력 데이터 분기** | 같은 동작에 대해 서로 다른 입력값/결과가 나열되어 있는가? |
| **독립 실행 가능** | 분리된 TC가 단독으로 실행/검증 가능한가? |

## ID Numbering

중간 번호 삽입 규칙 적용 (u-skill-refine과 동일):

- 원본 TC-0010 → 하위 TC-0011, TC-0012, TC-0013, ...
- 원본 TC는 그대로 유지하되, Title에 "*(세분화됨)*" 주석 추가

## Document Update

### 테이블 갱신

| TC-ID | FT | US | Level | Type | Priority | Title | Result |
|-------|----|----|-------|------|----------|-------|--------|
| TC-0010 | FT-0010 | US-0010 | Unit | Positive | Major | 로그인 검증 *(세분화됨)* | → 하위 TC 참조 |
| TC-0011 | FT-0010 | US-0010 | Unit | Positive | Major | 정상 이메일+비밀번호 로그인 | Pending |
| TC-0012 | FT-0010 | US-0010 | Unit | Negative | Major | 잘못된 비밀번호 로그인 실패 | Pending |
| TC-0013 | FT-0010 | US-0010 | Unit | Boundary | Minor | 비밀번호 5회 실패 시 계정 잠금 | Pending |

### Detail 블록 갱신

```markdown
### TC-0010 로그인 검증 *(세분화됨)*

> 아래 하위 TC로 분해됨. 테스트 추적은 하위 TC 기준.

| Sub-TC | 내용 | Type |
|--------|------|------|
| TC-0011 | 정상 이메일+비밀번호 로그인 | Positive |
| TC-0012 | 잘못된 비밀번호 로그인 실패 | Negative |
| TC-0013 | 비밀번호 5회 실패 시 계정 잠금 | Boundary |

---

### TC-0011 정상 이메일+비밀번호 로그인

- **FT**: FT-0010
- **US**: US-0010
- **Level**: Unit
- **Type**: Positive
- **Priority**: Major
- **Actor**: 일반 사용자
- **Precondition**: PRE-0010
- **Automation**: Vitest

| Step | Screen | Element | Action | Input | Expected |
|------|--------|---------|--------|-------|----------|
| 1 | 로그인 페이지 | 이메일 입력 필드 | 입력 | test@example.com | 입력값 표시 |
| 2 | 로그인 페이지 | 비밀번호 입력 필드 | 입력 | ValidPass123! | 마스킹 표시 |
| 3 | 로그인 페이지 | 로그인 버튼 | 클릭 | - | JWT 토큰 반환, 대시보드로 이동 |
```

### coverageMatrix 갱신

원본 TC-ID를 하위 TC-ID들로 교체한다:

```markdown
| FT | Feature | Unit Cases | E2E Cases | Coverage |
|----|---------|------------|-----------|----------|
| FT-0010 | 로그인 | TC-0011, TC-0012, TC-0013 | TC-0030 | Covered |
```

## User Confirmation

세분화 초안을 생성한 후 반드시 사용자에게 확인을 받는다:

```
TC-0010 "로그인 검증" 세분화 제안:

| # | Sub-ID  | Title                          | Level | Type     | Priority |
|---|---------|--------------------------------|-------|----------|----------|
| 1 | TC-0011 | 정상 이메일+비밀번호 로그인       | Unit  | Positive | Major    |
| 2 | TC-0012 | 잘못된 비밀번호 로그인 실패       | Unit  | Negative | Major    |
| 3 | TC-0013 | 비밀번호 5회 실패 시 계정 잠금    | Unit  | Boundary | Minor    |

위 세분화를 적용하시겠습니까?
- 수정이 필요하면 변경 사항을 알려주세요.
- 승인하시면 4_Case_QA.md를 갱신합니다.
```

## Rules

- u-agent-qa 에이전트가 담당
- 대상 TC-ID가 4_Case_QA.md에 존재하지 않으면 에러 메시지 후 종료
- 이미 세분화된 TC(*(세분화됨)* 표시)는 재세분화 시 경고 후 사용자 확인
- 하위 TC 수: 최소 2개, 최대 7개 (7개 초과 시 2단계 세분화 권장)
- 원본 TC는 삭제하지 않고 "*(세분화됨)*" 표시로 보존
- 하위 TC의 FT/US Mapping은 원본과 동일하게 유지
- 하위 TC의 Priority는 원본과 동일하게 시작하되, 사용자가 개별 조정 가능
- 하위 TC의 Result 상태는 항상 `Pending`으로 생성
- 각 하위 TC에 독립적인 Steps(6W 구조) 작성 필수
- ID는 중간 번호 삽입 규칙 적용 (10단위 사이에 1단위 삽입)
- Version은 Minor 증가
- Change Log에 세분화 이력 기록: `TC-0010 → TC-0011~0013 세분화`
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- `_links.json`의 해당 FT 매핑에 `qa` 필드 갱신 (하위 TC 중 대표 1개 또는 첫 번째 TC-ID)
- Post-Execution Summary Box 출력 필수
