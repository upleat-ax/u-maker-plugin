---
name: u-skill-refine
description: |
  FR, US, FT 항목을 세분화한다. 하나의 큰 항목을 분석하여 구체적인 하위 항목으로 분해하고 SRS를 갱신한다.
  Args: `<FR-NNNN|US-NNNN|FT-NNNN> [app]` — 세분화할 항목 ID + 앱 이름 (필수)
  Triggers: /u-skill-refine, 세분화, 분해, decompose, split, break down, refine, 쪼개기, 항목 분해, FR 세분화, US 세분화, FT 세분화, 요구사항 분해, requirement split
model: sonnet
user-invocable: true
argument-hint: "<FR-NNNN|US-NNNN|FT-NNNN> [app]"
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
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  - u-maker:u-agent-sa
---

# Refine (Decompose) FR / US / FT

> 하나의 큰 FR, US, 또는 FT 항목을 분석하여 더 작고 구체적인 하위 항목들로 세분화한다.

## Syntax

```
/u-skill-refine <ID> [app]
```

- `ID`: 세분화할 항목 ID (FR-NNNN, US-NNNN, FT-NNNN 중 하나)
- `[app]`: 멀티앱 프로젝트 시 앱 이름 (생략 시 자동 선택 또는 AskUserQuestion)

## When to Use

- FR이 너무 포괄적이어서 구현 범위가 불명확할 때
- US가 여러 독립적인 사용자 행동을 포함하고 있을 때
- FT가 복합적이어서 하나의 테스트 단위로 관리하기 어려울 때
- 기획 리뷰에서 "이 항목을 더 쪼개야 한다"는 피드백이 나왔을 때

## Flow

```
1. 대상 ID 파싱 → 타입 판별 (FR / US / FT)
2. 1_SRS_RA.md 읽기 → 대상 항목의 현재 내용 추출
3. 연관 항목 수집 (FR↔US↔FT 매핑 관계)
4. 세분화 분석 → 하위 항목 초안 생성
5. 사용자 확인 (AskUserQuestion) → 승인/수정
6. SRS 문서 갱신 (테이블 + Detail 블록)
7. 연관 문서 매핑 갱신 (_links.json)
8. Change Log 갱신
```

## Decomposition by Type

### FR Decomposition (기능 요구사항 세분화)

하나의 FR을 여러 하위 FR로 분해한다.

**분석 기준**:
- 독립적으로 구현/테스트 가능한 단위인가?
- 하나의 API endpoint 또는 하나의 비즈니스 규칙에 대응하는가?
- Input/Output이 명확히 구분되는가?

**ID 채번**: 중간 번호 사용. 원본 FR-0010 → 하위 FR-0011, FR-0012, FR-0013, ...
- 원본 FR은 그대로 유지하되, Description에 "(세분화됨 → FR-0011~0013)" 주석 추가
- 원본 FR의 Implemented 상태를 하위 FR들의 상태로 대체

**Detail 블록 갱신**:
```markdown
### FR-0010 사용자 인증 처리 *(세분화됨)*

> 아래 하위 FR로 분해됨. 구현 추적은 하위 FR 기준.

| Sub-FR | 내용 |
|--------|------|
| FR-0011 | 이메일+비밀번호 로그인 |
| FR-0012 | 소셜 로그인 (Google/Kakao) |
| FR-0013 | 비밀번호 재설정 |

---

### FR-0011 이메일+비밀번호 로그인

- **Input**: email (string), password (string)
- **Output**: JWT access token + refresh token
- **Business Rule**: 비밀번호 5회 실패 시 계정 잠금
- **Exception**: 미인증 이메일 → "이메일 인증 필요" 에러
```

**테이블 갱신**:

| FR-ID | Requirement | USR Mapping | Priority | Implemented |
|-------|-------------|------------|----------|-------------|
| FR-0010 | 사용자 인증 처리 *(세분화됨)* | USR-0010 | Must | → 하위 FR 참조 |
| FR-0011 | 이메일+비밀번호 로그인 | USR-0010 | Must | [ ] Not Started |
| FR-0012 | 소셜 로그인 (Google/Kakao) | USR-0010 | Should | [ ] Not Started |
| FR-0013 | 비밀번호 재설정 | USR-0020 | Must | [ ] Not Started |

### US Decomposition (유저 스토리 세분화)

하나의 US를 여러 하위 US로 분해한다.

**분석 기준**:
- 하나의 US에 여러 독립적인 사용자 의도(I want to)가 있는가?
- 수락 기준(Acceptance Criteria)이 서로 다른 시나리오를 포함하는가?
- 서로 다른 화면/페이지에서 발생하는 행동인가?

**ID 채번**: 중간 번호 사용. 원본 US-0010 → 하위 US-0011, US-0012, ...
- 원본 US에 "(세분화됨)" 표시
- 하위 US 각각에 독립적인 As a / I want to / So that 작성

**세분화 예시**:

원본:
```
US-0010: As a 사용자, I want to 계정을 관리, So that 내 정보를 최신으로 유지
```

세분화:
```
US-0011: As a 사용자, I want to 프로필 사진을 변경, So that 다른 사용자가 나를 식별
US-0012: As a 사용자, I want to 비밀번호를 변경, So that 계정 보안을 유지
US-0013: As a 사용자, I want to 알림 설정을 관리, So that 원하는 알림만 수신
```

**수락 기준**: 하위 US 각각에 독립적인 Acceptance Criteria를 작성한다.

### FT Decomposition (기능 세분화)

하나의 FT를 여러 하위 FT로 분해한다.

**분석 기준**:
- 하나의 FT에 프론트엔드 + 백엔드 + DB 변경이 모두 포함되어 있는가?
- 하나의 FT 안에 여러 화면/페이지가 포함되어 있는가?
- 독립적으로 테스트 가능한 단위인가?
- CRUD 중 여러 연산이 묶여 있는가?

**ID 채번**: 중간 번호 사용. 원본 FT-0010 → 하위 FT-0011, FT-0012, ...
- 원본 FT에 "(세분화됨)" 표시
- 하위 FT 각각에 US Mapping 유지

**세분화 예시**:

원본:
```
FT-0010: 상품 관리 (CRUD + 검색 + 정렬)
```

세분화:
```
FT-0011: 상품 등록 (Create)
FT-0012: 상품 목록 조회 + 검색 + 정렬 (Read)
FT-0013: 상품 상세 수정 (Update)
FT-0014: 상품 삭제 + 복구 (Delete)
```

## Cascading Update

세분화 시 연관 문서에 미치는 영향을 자동 처리한다.

| 대상 타입 | 연쇄 갱신 |
|----------|----------|
| FR 세분화 | US 테이블의 FR Mapping 갱신 (US는 FR에서 파생) |
| US 세분화 | FT 테이블의 US Mapping 갱신 (FT는 US에서 파생) |
| FT 세분화 | RTM에 하위 FT 행 추가, US 테이블의 FT Mapping 갱신 |

**_links.json 갱신**: 하위 항목 각각에 대해 매핑 행을 추가한다.

## User Confirmation

세분화 초안을 생성한 후 반드시 사용자에게 확인을 받는다:

```
📋 FR-0010 "사용자 인증 처리" 세분화 제안:

| # | Sub-ID  | 내용                        | Priority |
|---|---------|-----------------------------|----------|
| 1 | FR-0011 | 이메일+비밀번호 로그인        | Must     |
| 2 | FR-0012 | 소셜 로그인 (Google/Kakao)   | Should   |
| 3 | FR-0013 | 비밀번호 재설정               | Must     |

위 세분화를 적용하시겠습니까?
- 수정이 필요하면 변경 사항을 알려주세요.
- 승인하시면 SRS 문서를 갱신합니다.
```

## Rules

- u-agent-sa 에이전트가 담당
- 대상 ID가 SRS에 존재하지 않으면 에러 메시지 후 종료
- 이미 세분화된 항목(*(세분화됨)* 표시)은 재세분화 시 경고 후 사용자 확인
- 하위 항목 수: 최소 2개, 최대 7개 (7개 초과 시 2단계 세분화 권장)
- 원본 항목은 삭제하지 않고 "(세분화됨)" 표시로 보존
- 하위 항목의 Priority는 원본과 동일하게 시작하되, 사용자가 개별 조정 가능
- ID는 중간 번호 삽입 규칙 적용 (10단위 사이에 1단위 삽입)
- Version은 Minor 증가
- Change Log에 세분화 이력 기록: `FR-0010 → FR-0011~0013 세분화`
- Post-Execution Summary Box 출력 필수
