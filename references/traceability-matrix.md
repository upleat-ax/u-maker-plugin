# Traceability Matrix

> u-maker SSoT 문서 간의 추적성 매트릭스를 정의한다.
> 모든 문서는 수직적/수평적 추적성을 유지해야 한다.

---

## 1. Vertical Traceability Chain

Roadmap(why) → SRS(US+what) → MN/IA(navigate) → Screen(design) → ERD(how) → Code(execute) 순서의 수직적 추적성.

| Level | Document | Role | Traces From | Traces To |
|-------|----------|------|-------------|-----------|
| L1 (Why) | `1_Roadmap_PM.md` | 프로젝트 목적, 마일스톤 | (최상위) | `1_SRS_RA.md` |
| L2 (What) | `1_SRS_RA.md` | 유저 스토리, 기능/비기능 요구사항 정의 | `1_Roadmap_PM.md` | `1_IA_RA.md`, `2_ERD_SA.md`, `2_API_SA.md` |
| L2.5 (Navigate) | `1_IA_RA.md` | 메뉴 구조, 화면 계층 (MN-{DOMAIN}-{NNNN}) | `1_SRS_RA.md` | `2_Screen_UX.md`, `2_ScreenFlow_UX.md` |
| L3 (Flow) | `2_ScreenFlow_UX.md` | 화면 간 전환 흐름, 딥링크 | `2_Screen_UX.md`, `1_IA_RA.md` | `2_API_SA.md`, `4_Case_QA.md` |
| L3 (How) | `2_ERD_SA.md` | 데이터 모델, Entity 관계 | `1_SRS_RA.md` | `3_Code_DV.md` |
| L3 (How) | `2_API_SA.md` | API Contract, 인터페이스 | `1_SRS_RA.md` | `3_Code_DV.md` |
| L4 (Execute) | `3_Code_DV.md` | 구현 기록, 파일 매핑 | `2_ERD_SA.md`, `2_API_SA.md` | `4_Case_QA.md` |

### Vertical Chain Diagram

```mermaid
flowchart TD
    ROADMAP["1_Roadmap_PM.md\n(Why)"]
    SRS["1_SRS_RA.md\n(What)"]
    IA["1_IA_RA.md\n(Navigate - MN IDs)"]
    SCREEN["2_Screen_UX.md\n(Design)"]
    ERD["2_ERD_SA.md\n(How - Data)"]
    API["2_API_SA.md\n(How - Interface)"]
    CODE["3_Code_DV.md\n(Execute)"]

    ROADMAP -->|Goals → US+FR| SRS
    SRS -->|FR → Menu Items| IA
    IA -->|MN → Screens| SCREEN
    SRS -->|FR → Entities| ERD
    SRS -->|FR → Endpoints| API
    ERD -->|Schema → Models| CODE
    API -->|Contract → Routes| CODE
```

### Tracing Rules (Vertical)

1. `1_SRS_RA.md`의 모든 User Story(Section 2)는 FR(Section 3)과 매핑되어야 한다 (PLAN Gate 검증 시점에 적용. 작성 중 `TBD` 허용)
2. `1_SRS_RA.md`의 모든 FR은 `2_ERD_SA.md` 또는 `2_API_SA.md`에서 구체화되어야 한다
3. `2_ERD_SA.md`의 모든 Entity는 `3_Code_DV.md`의 모델 파일과 매핑되어야 한다
4. `2_API_SA.md`의 모든 Endpoint는 `3_Code_DV.md`의 라우트 파일과 매핑되어야 한다
5. Technical FR (US 없는 FR)은 US Mapping이 `-`로 표시 가능

---

## 2. Horizontal Traceability Chain

Screen(UI) ↔ API(data) ↔ QA Case(verify) 순서의 수평적 추적성.

| Document | Role | Horizontal Links |
|----------|------|-----------------|
| `2_Screen_UX.md` | UI 화면 설계 | ↔ `2_API_SA.md` (화면이 호출하는 API) |
| `2_API_SA.md` | API 인터페이스 | ↔ `2_Screen_UX.md` (API를 사용하는 화면), ↔ `4_Case_QA.md` (API 테스트) |
| `4_Case_QA.md` | 테스트 케이스 | ↔ `2_API_SA.md` (테스트 대상 API), ↔ `2_Screen_UX.md` (테스트 대상 화면) |

### Horizontal Chain Diagram

```mermaid
flowchart LR
    SCREEN["2_Screen_UX.md\n(UI)"]
    API["2_API_SA.md\n(Data)"]
    QA["4_Case_QA.md\n(Verify)"]

    SCREEN <-->|화면 → API 호출| API
    API <-->|API → 테스트 케이스| QA
    SCREEN <-->|화면 → UI 테스트| QA
```

### Tracing Rules (Horizontal)

1. `2_Screen_UX.md`의 모든 화면은 사용하는 API endpoint를 명시해야 한다
2. `2_API_SA.md`의 모든 endpoint는 호출하는 화면을 참조해야 한다
3. `4_Case_QA.md`의 테스트 케이스는 대상 API 또는 화면을 명시해야 한다

---

## 3. Full Dependency Graph

```mermaid
flowchart TD
    subgraph PLAN["01-plan"]
        ROADMAP[1_Roadmap_PM.md]
        SRS[1_SRS_RA.md]
        IA[1_IA_RA.md]
        INDEX[1_Index_PM.md]
    end

    subgraph DESIGN["02-design"]
        SCREEN[2_Screen_UX.md]
        SFLOW[2_ScreenFlow_UX.md]
        DSYS[2_UXGuide_UX.md]
        ERD[2_ERD_SA.md]
        API[2_API_SA.md]
    end

    subgraph DEV["03-dev"]
        SCR_UX[3_Screen_UX.md]
        UICOMP[3_UIComponents_UX.md]
        DTOKEN[3_DesignToken_UX.md]
        CODE[3_Code_DV.md]
    end

    subgraph CHECK_PHASE["04-check"]
        CASE[4_Case_QA.md]
        REPORT[4_Report_QA.md]
    end

    subgraph ACT_PHASE["05-act"]
        ITER_LOG[5_IterationLog_RA.md]
        RETRO[5_Retrospective_PM.md]
    end

    subgraph ROOT_DOCS["u-docs/ root"]
        LINKS[_links.json]
    end

    %% Vertical dependencies
    ROADMAP --> SRS
    SRS --> IA
    SRS --> ERD
    SRS --> API
    IA -->|MN → S| SCREEN
    SCREEN --> SFLOW
    IA --> DSYS
    DSYS --> SCR_UX
    DSYS --> UICOMP
    DSYS --> DTOKEN
    ERD --> CODE
    API --> CODE
    SCREEN --> SCR_UX
    CODE --> CASE

    %% Horizontal dependencies
    SCREEN <--> API
    API <--> CASE
    SCREEN <--> CASE

    %% Check → Act flow
    CASE --> REPORT
    REPORT --> ITER_LOG
    ITER_LOG --> RETRO

    %% Index tracks all
    INDEX -.->|tracks| ROADMAP
    INDEX -.->|tracks| SRS
    INDEX -.->|tracks| IA
    INDEX -.->|tracks| SCREEN
    INDEX -.->|tracks| SFLOW
    INDEX -.->|tracks| DSYS
    INDEX -.->|tracks| ERD
    INDEX -.->|tracks| API
    INDEX -.->|tracks| SCR_UX
    INDEX -.->|tracks| UICOMP
    INDEX -.->|tracks| DTOKEN
    INDEX -.->|tracks| CODE
    INDEX -.->|tracks| CASE
    INDEX -.->|tracks| REPORT
```

---

## 4. Cross-Reference Validation Rules

### 4.1 Validation Checklist

| # | Validation Rule | Source | Target | Severity |
|---|----------------|--------|--------|----------|
| V-001 | 모든 User Story(SRS Section 2)는 FR과 매핑 (PLAN Gate 검증 시점에 적용. 작성 중 `TBD` 허용) | `1_SRS_RA.md` | `1_SRS_RA.md` | Critical |
| V-002 | 모든 FR은 ERD 또는 API에서 구체화 | `1_SRS_RA.md` | `2_ERD_SA.md`, `2_API_SA.md` | Critical |
| V-003 | 모든 IA 항목은 Screen에서 설계 | `1_IA_RA.md` | `2_Screen_UX.md` | Major |
| V-004 | 모든 Screen은 사용 API를 명시 | `2_Screen_UX.md` | `2_API_SA.md` | Major |
| V-004a | 모든 Screen은 ScreenFlow에서 전환 흐름이 정의 | `2_Screen_UX.md` | `2_ScreenFlow_UX.md` | Major |
| V-005 | 모든 API endpoint는 테스트 케이스 존재 | `2_API_SA.md` | `4_Case_QA.md` | Major |
| V-006 | 모든 Entity는 코드 모델과 매핑 | `2_ERD_SA.md` | `3_Code_DV.md` | Critical |
| V-007 | 모든 API endpoint는 코드 라우트와 매핑 | `2_API_SA.md` | `3_Code_DV.md` | Critical |
| V-008 | Index가 모든 문서를 추적 | `1_Index_PM.md` | All docs | Major |
| V-009 | 결함 리포트는 Iteration Log에 기록 | `4_Report_QA.md` | `5_IterationLog_RA.md` | Major |
| V-010 | related_docs에 양방향 참조 존재 | All docs | All docs | Minor |
| V-011 | Technical FR (US 없는 FR)은 US Mapping이 `-`로 표시 가능 | `1_SRS_RA.md` | - | Minor |

### 4.2 Traceability Matrix Table

실제 프로젝트에서 작성되는 추적성 매트릭스 테이블 형식:

```markdown
| FR-ID | Description | SRS | Menu | ERD | API | Screen | Code | QA Case | Status |
|-------|-------------|-----|------|-----|-----|--------|------|---------|--------|
| FR-0010 | 사용자 로그인 | 1SA:FR-0010 | MN-AUTH-0010 | 2SA:USER | 2SA:POST /auth | 2UX:S-0010 | auth.ts | 4QA:TC-0010 | Implemented |
| FR-0020 | 대시보드 조회 | 1SA:FR-0020 | MN-DASH-0010 | 2SA:DASHBOARD | 2SA:GET /dashboard | 2UX:S-0020 | dashboard.ts | 4QA:TC-0020 | In Progress |
```

### 4.3 Validation Process

1. **자동 검증**: `scripts/validate-ssot.py`가 문서 파싱 후 추적성 검증
2. **u-RA 검수**: Phase 전환 Gate에서 `u-RA`가 문서 간 모순 검사
3. **수동 검토**: `/uc-validate` 커맨드로 사용자가 직접 검증 요청 가능

```mermaid
flowchart LR
    DOC[SSoT Documents] --> SCRIPT[validate-ssot.py]
    DOC --> RA[u-RA Agent]
    SCRIPT --> RESULT{Validation Result}
    RA --> RESULT
    RESULT -->|Pass| GATE[Gate Transition]
    RESULT -->|Fail| FIX[Fix Required]
    FIX --> DOC
```

---

## 5. Cascading Update Rule (연쇄 문서 갱신)

> **Reference-Only 원칙**: 문서 간 참조 시 ID만 기재하고, 타 문서의 상세 내용을 복사하지 않는다.
> 상세 규칙은 `ssot-standard.md` Section 8을 참조한다.

### 5.1 Impact Propagation Map

| 변경 대상 | 영향받는 문서 |
|-----------|-------------|
| US (1_SRS_RA) | → FR (1_SRS_RA, 같은 문서 내) → IA (1_IA_RA) |
| FR (1_SRS_RA) | → IA → Screen → API → ERD → Code → QA Case |
| MN/IA (1_IA_RA) | → Screen (2_Screen_UX) → ScreenFlow (2_ScreenFlow_UX) |
| Screen (2_Screen_UX) | → ScreenFlow (2_ScreenFlow_UX) → API (2_API_SA) → QA Case (4_Case_QA) |
| ScreenFlow (2_ScreenFlow_UX) | → API (2_API_SA) → QA Case (4_Case_QA) |
| API (2_API_SA) | → Screen → ERD → Code → QA Case |
| ERD (2_ERD_SA) | → API → Code (3_Code_DV) |

### 5.2 Deferred Cascading Update (지연 연쇄 갱신)

문서 변경 시 관련 문서를 **즉시 갱신하지 않는다**. `_links.json` 기반으로 비동기 갱신한다:

```
1. 원본 문서 수정 (예: SRS에 FR-0030 추가)
2. _links.json에 매핑 행 추가/갱신 (미정 필드는 null)
3. 각 문서 담당자가 자기 문서를 비동기로 갱신
4. /uc-validate로 _links.json 기준 누락 항목 탐지
```

### 5.3 Rules

- Reference-Only: 타 문서 내용 복제 금지, ID 참조만 허용
- 항목 추가/변경 시 `_links.json` 매핑을 반드시 함께 갱신
- Final 문서 변경 시 Status → Draft
- `/uc-validate` 검증 시 `_links.json` 기준으로 누락 탐지
- **즉시 갱신 예외**: 항목 삭제 시 (삭제된 ID 참조 제거), 구조 변경 시 (Phase Gate 전 동기화)

---

## 6. Reference ID Format

문서 간 상호 참조 시 사용하는 ID 형식:

| Document | ID Format | Example |
|----------|-----------|---------|
| SRS User Story | `US-{NNNN}` | US-0010 |
| SRS Feature | `FR-{NNNN}` | FR-0010 |
| SRS Non-Functional | `NFR-{NNNN}` | NFR-0010 |
| IA Menu Navigation | `MN-{DOMAIN}-{NNNN}` | MN-AUTH-0010 |
| ERD Entity | `Entity: {NAME}` | Entity: USER |
| API Endpoint | `{METHOD} {path}` | POST /auth/login |
| Screen | `S-{NNNN}` | S-0010 |
| QA Test Case | `TC-{NNNN}` | TC-0010 |
| Backlog Item | `BL-{NNNN}` | BL-0010 |
| Defect | `DEF-{NNNN}` | DEF-0010 |
