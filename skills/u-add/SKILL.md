---
name: u-add
description: "SSoT 항목 추가. FR, NR, US, FT, Screen, TC 등 개별 항목을 문서에 추가하고, 백로그 자동 등록 및 인덱스 갱신을 수행한다."
triggers:
  - "/u-add"
  - "add item"
  - "항목 추가"
  - "FR 추가"
  - "US 추가"
---

# u-add -- Add SSoT Item

`/u-add [scope] [type] "title"` 명령으로 FR, NR, US, Screen, bug, improvement, tech-debt 항목을 적절한 위치에 추가하고, 백로그 자동 등록 및 인덱스 갱신을 수행한다.

**Primary Agent:** u-agent-planner (FR/NR/US), u-agent-ux (Screen), u-agent-guardian (bug)

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 단일 앱 자동 선택 / 다중 앱 시 질문 |
| `type` | Required | 항목 유형: `fr`, `nr`, `us`, `screen`, `bug`, `improvement`, `tech-debt` |
| `"title"` | Required | 항목 제목 (따옴표로 감싸기 권장) |

## Flags

| Flag | Description |
|------|-------------|
| `--priority X` | 우선순위 지정 (must/should/could/wont). 기본값: should |
| `--parent ID` | 상위 항목 ID 지정 (US는 FR, FT는 US 필요) |
| `--description "text"` | 상세 설명 추가 |
| `--labels "a,b"` | 라벨 추가 (쉼표 구분) |

---

## Execution Flow

### Step 1: Parse Arguments

1. `type` 인자 파싱 → 유효한 유형인지 검증
2. `"title"` 추출 → 따옴표 또는 마지막 인자로 처리
3. `scope` 해석 → `u-maker.config.json` 읽어 대상 앱 결정
4. 인자 부족 시 사용자에게 질문 (type, title 모두 필수)

### Step 2: Resolve Target Location

유형별 생성 위치 및 대상 문서:

| Type | Target Document | Target Path |
|------|----------------|-------------|
| `fr` | SRS (Functional Requirements 섹션) | `docs/{app}/01-plan/srs.md` |
| `nr` | SRS (Non-Functional Requirements 섹션) | `docs/{app}/01-plan/srs.md` |
| `us` | SRS (User Stories 섹션) | `docs/{app}/01-plan/srs.md` |
| `screen` | Screen 설계 문서 | `docs/{app}/02-design/screens.md` |
| `bug` | Backlog 직접 등록 | `_backlog/` |
| `improvement` | Backlog 직접 등록 | `_backlog/` |
| `tech-debt` | Backlog 직접 등록 | `_backlog/` |

### Step 3: Generate ID

1. 대상 문서 (또는 `_backlog/_index.json`) 읽기
2. 기존 최대 ID 조회 → +1 (zero-padded 4자리)
3. ID 체계:

| Type | ID Pattern | Example |
|------|-----------|---------|
| `fr` | FR-XXXX | FR-0042 |
| `nr` | NR-XXXX | NR-0008 |
| `us` | US-XXXX | US-0103 |
| `screen` | SCR-XXX | SCR-045 |
| `bug` | BL-XXX | BL-087 |
| `improvement` | BL-XXX | BL-088 |
| `tech-debt` | BL-XXX | BL-089 |

4. ID 중복 불가 (퇴역 ID 재사용 금지)

### Step 4: Create Item Record

**FR/NR 항목 구조:**

```markdown
### FR-{XXXX}: {title}

- **Description:** {description 또는 "TBD"}
- **Priority:** {Must/Should/Could/Won't}
- **Source:** manual-add
- **Related USR:** {--parent 값 또는 TBD}
- **Status:** Draft
- **Added:** {ISO 8601}
```

**US 항목 구조:**

```markdown
### US-{XXXX}: "As a {USR}, I want to {title} so that {benefit}"

- **Parent FR:** {--parent 값, 필수}
- **Acceptance Criteria:**
  1. {TBD - 사용자가 추후 보완}
- **Priority:** {Must/Should/Could/Won't}
- **Status:** Draft
- **Added:** {ISO 8601}
```

- US 추가 시 `--parent FR-XXXX` 필수. 미지정 시 사용자에게 질문

**Screen 항목 구조:**

```markdown
### SCR-{XXX}: {title}

- **Level:** {TBD}
- **Parent Screen:** {--parent 값 또는 --}
- **Related FT:** {TBD}
- **Priority:** {Must/Should/Could/Won't}
- **Status:** Draft
- **Added:** {ISO 8601}
```

**Bug/Improvement/Tech-debt 구조:**

```json
{
  "id": "BL-{NNN}",
  "type": "{bug|improvement|tech-debt}",
  "title": "{title}",
  "description": "{description 또는 ''}",
  "priority": "{must|should|could|wont}",
  "storyPoints": null,
  "iteration": null,
  "status": "backlog",
  "assignee": null,
  "source": { "type": "manual-add", "ref": null },
  "labels": [],
  "dependencies": [],
  "created": "{ISO 8601}",
  "updated": "{ISO 8601}"
}
```

### Step 5: Append to Target Document

1. 대상 .md 파일 읽기
2. 적절한 섹션 끝에 새 항목 삽입:
   - FR → `## 3. Functional Requirements (FR)` 섹션 끝
   - NR → `## 4. Non-Functional Requirements (NR)` 섹션 끝
   - US → `## 5. User Stories (US)` 섹션 끝
   - Screen → `## Screen Hierarchy` 또는 마지막 Screen 항목 뒤
3. 문서 헤더의 `Version` minor 증가, `Last Updated` 갱신
4. 동반 `.json` 파일 재생성

### Step 6: Register to Backlog

FR/NR/US/Screen은 자동으로 백로그에도 등록:

1. `_backlog/_index.json` 읽기
2. 새 백로그 항목 추가:
   ```json
   {
     "id": "BL-{NNN}",
     "type": "feature",
     "title": "{type} {id}: {title}",
     "priority": "{priority}",
     "status": "backlog",
     "source": { "type": "{fr|nr|us|screen}", "ref": "{item-id}" },
     "created": "{ISO 8601}",
     "updated": "{ISO 8601}"
   }
   ```
3. bug/improvement/tech-debt는 Step 4에서 직접 등록 완료

### Step 7: Update Indexes and Links

1. `docs/{app}/_index.json` 갱신:
   - 대상 문서의 `lastUpdated` 갱신
   - 항목 카운트 증가
2. `.u-maker/_links.json` 갱신:
   - `--parent` 관계 등록 (US→FR, FT→US 등)
3. `_classified/` 해당 카테고리에도 등록 (requirements/, screens/):
   - status = `validated` (수동 추가이므로 자동 검증 간주)

### Step 8: Display Confirmation

```
## Item Added

**Type:** {type}
**ID:** {id}
**Title:** {title}
**Location:** {file-path}
**Backlog:** BL-{NNN}
**Parent:** {parent-id 또는 N/A}

### Next Steps
- Edit details: /u-doc {scope} {document}
- View backlog: /u-backlog {scope}
- Trace chain: /u-trace {scope} {id}
```

---

## Batch Add

여러 항목을 한 번에 추가할 수 있다:

```
/u-add {scope} fr "사용자 인증" --priority must
/u-add {scope} fr "비밀번호 재설정" --priority must
/u-add {scope} us "로그인 시 이메일+비밀번호로 인증한다" --parent FR-0001
```

각 항목은 독립적으로 처리하되, 인덱스 갱신은 마지막에 일괄 수행.

---

## Traceability Enforcement

| Type | Required Parent | Validation |
|------|----------------|------------|
| FR | USR (권장) | 경고만 (orphan FR 허용) |
| NR | -- | 독립 허용 |
| US | FR (필수) | `--parent` 미지정 시 사용자에게 질문 |
| Screen | -- | 독립 허용 |
| bug | -- | 독립 허용 (TC/FT 참조 권장) |
| improvement | -- | 독립 허용 |
| tech-debt | -- | 독립 허용 |

---

## Safety Rules

1. 대상 문서가 존재하지 않으면 생성 불가 → `/u-plan`으로 먼저 SRS 생성 안내
2. ID 중복 및 재사용 금지
3. US 추가 시 parent FR 미지정이면 진행 불가 (사용자에게 반드시 질문)
4. Final 상태 문서에 항목 추가 시 사용자 확인 필수 (Always-Pause)
5. `.json` 동반 파일 재생성 필수
6. `_index.json` 갱신 필수
7. 백로그 자동 등록 필수 (skip 불가)
8. source metadata 필수 (manual-add + timestamp)
