---
name: u-plan
description: "PLAN Phase 문서 연쇄 생성. classified 데이터 기반 SRS + IA + Roadmap을 순서대로 생성하고, 4-Tier ID 계층(USR-FR-US-FT)을 수립한다."
triggers:
  - "/u-plan"
  - "plan phase"
  - "SRS 생성"
  - "기획 문서"
---

# u-plan -- Plan Phase Document Generation

`/u-plan [scope] [--only X] [-i] [--step]` 명령으로 classified 데이터를 기반으로 Plan 문서를 연쇄 생성한다.

**Primary Agent:** u-agent-planner (engine-doc, engine-estimator 사용)

---

## Flags

| Flag | Description |
|------|-------------|
| `--only X` | 지정 문서만 생성 (srs, ia, roadmap) |
| `-i` | 분기점에서 사용자 확인 |
| `--step` | 매 단계 결과 표시 후 승인 대기 |

---

## Execution Flow

### Step 1: Verify Data Availability

1. `_classified/_summary.json` 읽기
2. 필수 데이터 확인:
   - `requirements/`: FR/NR 항목 >= 1
   - `stakeholders/`: 사용자 유형 >= 1
   - `standards/`: 존재 시 SRS NR/constraints에 반영 (선택, 없어도 진행 가능)
3. 데이터 부족 시:
   - auto: 가정 기록 + 진행
   - interactive/step: "/u-ingest를 먼저 실행하세요" 안내

### Step 2: Generate SRS

**입력:** `_classified/requirements/`, `_classified/constraints/`, `_classified/stakeholders/`, `_classified/standards/`

> **Standards 반영 규칙:** `standards/_index.json`에서 `appliesTo`에 `"srs"`를 포함하는 STD 항목을 읽어, NR(Non-Functional Requirements) 또는 constraints로 자동 반영한다. enforcement가 `must`인 항목은 NR에 직접 등록하고, `should`인 항목은 constraints 참조로 기록한다.

**SRS 구조:**

```markdown
---
Owner: u-agent-planner
Status: Draft
Version: 1.0.0
Last Updated: {date}
Related Docs: [IA, Roadmap, ERD, RTM]
---

# Software Requirements Specification

## 1. Project Overview
- Purpose, Scope, Stakeholders, Glossary references

## 2. User Types (USR)
- USR-0001: {role} - {characteristics}

## 3. Functional Requirements (FR)
- FR-0001: {title}
  - Description, Priority (Must/Should/Could/Won't)
  - Source reference, Related USR

## 4. Non-Functional Requirements (NR)
- NR-0001: {title}
  - Category: Performance/Security/Accessibility/Scalability/Compliance

## 5. User Stories (US)
- US-0001: "As a {USR}, I want to {action} so that {benefit}"
  - Parent FR(s), Acceptance Criteria

## 6. Features (FT)
- FT-0001: {title}
  - Description, Complexity (S/M/L/XL), Parent US
  - Acceptance Criteria
```

**4-Tier ID Hierarchy:**

```
USR-XXXX → FR-XXXX → US-XXXX → FT-XXXX
(User Type)  (Requirement)  (Story)    (Feature = 구현 단위)
```

- 모든 FT는 US로, US는 FR로, FR은 USR로 역추적 가능해야 함
- 고아 항목(orphan) = 오류 → 플래그 표시
- ID는 4자리 zero-padded: FR-0001, US-0042, FT-0137
- ID는 앱 스코프 내 전역 고유 (퇴역 ID 재사용 금지)

**프로세스:**
1. `requirements/_index.json` 읽기 → validated/extracted 항목 필터
2. `stakeholders/_index.json` → USR 정의
3. `standards/_index.json` 읽기 → `appliesTo` 포함 `"srs"` 항목 필터 → NR/constraints로 병합
4. FR/NR 구조화 → priority 배정 (standards 기반 NR 포함)
5. FR → US 분해 (1 FR = 1~N US)
6. US → FT 분해 (1 US = 1~N FT)
7. `srs.md` + `srs.json` 생성
8. `_index.json` 갱신
9. classified 항목 status → `adopted` + `usedIn` 필드 추가 (standards 항목 포함)

### Step 3: Generate IA (Information Architecture)

**입력:** `_classified/workflows/`, `_classified/screens/`, `_classified/domain-terms/`, SRS

**IA 구조:**

```markdown
---
Owner: u-agent-planner
Status: Draft
Version: 1.0.0
Related Docs: [SRS, Screens, ScreenFlow]
---

# Information Architecture

## Screen Hierarchy

| Screen ID | Name | Level | Parent | Related FT | Priority |
|-----------|------|-------|--------|-----------|----------|
| SCR-001 | Home | 1 | -- | FT-0001 | Must |
| SCR-002 | Login | 1 | -- | FT-0010 | Must |
| SCR-003 | Dashboard | 2 | SCR-001 | FT-0015 | Must |
```

**프로세스:**
1. `workflows/_index.json` → 사용자 태스크 흐름 추출
2. `screens/_index.json` → AS-IS 화면 → TO-BE 화면 매핑
3. SRS USR 정의 → 사용자 유형별 내비게이션 구성
4. 계층 정의:
   - Level 0: 앱 진입점
   - Level 1: 메인 내비게이션 탭/섹션
   - Level 2: 하위 페이지
   - Level 3+: 상세, 모달, 드로어
5. Mermaid 다이어그램 생성 (tree 또는 mindmap)
6. 교차 검증: IA의 모든 화면 → SRS FT와 1:1 매핑 확인
7. `ia.md` + `ia.json` 생성

### Step 4: Generate Roadmap

**입력:** SRS (FR/US/FT), engine-estimator

**프로세스:**
1. FT 목록 + complexity(S/M/L/XL) 읽기
2. engine-estimator로 공수 산정:
   - S: 0.5일, M: 1-2일, L: 3-5일, XL: 5-10일
   - 버퍼: 미지 20% + 통합 10%
3. priority 기반 마일스톤 그룹핑
4. Mermaid Gantt 또는 테이블 형식 타임라인 생성
5. `roadmap.md` + `roadmap.json` 생성

**Roadmap 구조:**

```markdown
## Milestones

| Milestone | Features | Est. Days | Target Date | Priority |
|-----------|----------|-----------|-------------|----------|
| M1: Auth | FT-0010~FT-0015 | 12 | 2026-04-10 | Must |
| M2: Dashboard | FT-0020~FT-0035 | 18 | 2026-04-28 | Must |
| M3: Reports | FT-0050~FT-0060 | 8 | 2026-05-06 | Should |
```

### Step 5: Update Indexes and Links

1. `_index.json` 갱신: 새로 생성된 SRS, IA, Roadmap 등록
2. `_links.json` 갱신: 문서 간 관계 등록
   ```json
   {
     "from": "{app}/srs",
     "to": "{app}/ia",
     "type": "derives"
   }
   ```
3. classified 항목의 `adopted` + `usedIn` 필드 갱신

---

## --only Flag 동작

| Value | Action |
|-------|--------|
| `--only srs` | SRS만 생성 (Step 2만 실행) |
| `--only ia` | IA만 생성 (SRS 존재 필수, Step 3만 실행) |
| `--only roadmap` | Roadmap만 생성 (SRS 존재 필수, Step 4만 실행) |

---

## JSON Export

모든 .md 파일은 동일 경로에 .json 동반 생성:

```
docs/{app}/01-plan/srs.md     → docs/{app}/01-plan/srs.json
docs/{app}/01-plan/ia.md      → docs/{app}/01-plan/ia.json
docs/{app}/01-plan/roadmap.md → docs/{app}/01-plan/roadmap.json
```

JSON 구조:
```json
{
  "documentId": "{app}/srs",
  "type": "srs",
  "version": "1.0.0",
  "status": "Draft",
  "lastUpdated": "{ISO 8601}",
  "owner": "u-agent-planner",
  "data": {
    "userTypes": [...],
    "functionalRequirements": [...],
    "nonFunctionalRequirements": [...],
    "userStories": [...],
    "features": [...]
  },
  "metadata": {
    "sourceClassified": ["FR-0001", "FR-0002"],
    "relatedDocs": ["ia", "roadmap"]
  }
}
```

---

## Safety Rules

1. classified 데이터가 부족하면 `/u-ingest` 먼저 실행 안내
2. 기존 Final 문서 덮어쓰기 시 반드시 사용자 확인 (Always-Pause)
3. 모든 항목에 source 역추적 보존 (classified item → raw input)
4. 고아 항목(FT without US, US without FR) 탐지 시 경고
5. ID 재사용 금지, 기존 ID 보존
6. `.json` 동반 파일 생성 필수
7. `_index.json` 갱신 필수
8. auto mode 가정은 `_assumptions/`에 기록
