---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
App: {{app}}
Companion: screens.json
---

# Screen Specification

> JSON companion: `screens.json`
> ID Rule: SC-010, SC-020, ...

## 1. Screen Inventory

| ID | Screen Name | Path | Category | Related IA | Related FR |
|----|------------|------|----------|-----------|-----------|
| SC-010 | {{screenName}} | {{path}} | {{category}} | IA-010 | FR-010 |

## 2. Screen Details

### SC-010: {{screenName}}

**Route:** `{{path}}`
**Related:** FT-{{ftId}} · FR-{{frId}} · Priority: {{priority}}

#### 2.1 Wireframe & Annotations

> HTML 생성 시 이 섹션은 2-column grid layout으로 렌더링:
> 좌측 = SVG wireframe (app-frame), 우측 = annotation panel

**Layout:**
- Sidebar: {{sidebarMenuItems}}
- Header: {{headerDescription}} (breadcrumb + page title)
- Body: {{bodyDescription}}
- Footer: {{footerDescription}}

**Annotations:**

| # | Component | Description |
|---|-----------|-------------|
| 1 | {{componentName}} | {{annotationDescription}} |

**Business Rules:**

| ID | Rule |
|----|------|
| BR-{{screenId}}-01 | {{ruleDescription}} |

#### 2.2 Components & Data Binding

| # | Component | Type | Props / Validation | Bound Data | API |
|---|-----------|------|--------------------|-----------|-----|
| 1 | {{name}} | Button/Input/Card/Table/Select/Upload/Display/Form/Action | {{props}} | {{boundField}} (예: `order.customerName`, `formState.status`) | {{apiEndpoint}} or `-` |

> **Bound Data**: 해당 컴포넌트에 바인딩되는 실제 데이터 필드명을 기재. API 응답 필드, 로컬 state, computed 값 등을 명시.
> 일반적인 바인딩(예: `loading`, `error`)은 생략하고 도메인 특화 바인딩만 기재.

#### 2.3 Select Options & Possible Values

> 화면 내 Select, Radio, Checkbox Group, MultiSelect, Enum 필드의 선택지를 명시.
> 일반적인 항목(예: 성별 남/여)은 생략. 도메인 특화 항목만 기재.

| Field | Component | Options | Source | Default |
|-------|-----------|---------|--------|---------|
| {{fieldName}} | {{componentRef}} | {{option1}}, {{option2}}, {{option3}}, ... | static / API-{{id}} / enum:{{tableName}}.{{column}} | {{defaultValue}} or `-` |

> **Source**: `static` = 코드 하드코딩, `API-xxx` = API에서 동적 조회, `enum:tableName.column` = DB enum/코드 테이블

#### 2.4 Overlay Components

> 화면에서 사용하는 Modal, BottomSheet, Popup, Drawer, Toast 컴포넌트 상세.
> 오버레이가 없으면 이 섹션 생략.

**{{overlayName}}** (`{{overlayType}}`)
- **Trigger:** {{triggerAction}} (예: "삭제 버튼 클릭", "행 더블클릭")
- **Purpose:** {{purpose}}
- **Components:**

| # | Component | Type | Props | Bound Data |
|---|-----------|------|-------|-----------|
| 1 | {{name}} | {{type}} | {{props}} | {{boundField}} |

- **Actions:**
  - Confirm → {{confirmAction}} (예: `DELETE /api/orders/{id}` → 목록 갱신 → Toast "삭제 완료")
  - Cancel → {{cancelAction}} (예: 모달 닫기)
- **Related:** FR-{{frId}}, BR-{{screenId}}-{{nn}}

#### 2.5 API Calls

| Trigger | API | Method | Request | Response | Purpose |
|---------|-----|--------|---------|----------|---------|
| onLoad | API-010 | GET | - | {{responseShape}} | {{purpose}} |
| onClick ({{button}}) | API-020 | POST | {{requestBody}} | {{responseShape}} | {{purpose}} |

#### 2.6 User Action Handling Map

> 사용자 액션별 시스템 응답을 도식화. 일반적 액션(페이지 로드, 뒤로가기 등)은 생략.
> 도메인 특화 액션과 복합 핸들링만 기재. Wireframe의 프로세스 흐름도 소스가 된다.

| # | User Action | Handler | System Response | Next State / Navigation | Related Rule |
|---|------------|---------|----------------|------------------------|-------------|
| 1 | {{action}} (예: 일괄배정 버튼 클릭) | {{handler}} (예: handleBatchAssign) | {{response}} (예: 선택된 행 validation → API-030 POST → 배정 상태 변경) | {{nextState}} (예: 테이블 갱신, Toast "N건 배정 완료") | BR-{{screenId}}-{{nn}} |
| 2 | {{action}} (예: 행 더블클릭) | {{handler}} | {{response}} (예: Modal 오픈 → 상세 정보 로드) | {{nextState}} (예: 상세 모달 표시) | - |

> **복합 핸들링 상세** (해당 시 — 단순 navigate/toggle은 생략):
> - {{action}} 시:
>   1. 선행 조건: {{precondition}} (예: 1건 이상 선택 필수)
>   2. 유효성 검증: {{validation}} (예: 배정 상태가 '대기'인 행만)
>   3. API 호출: {{apiCall}}
>   4. 성공 시: {{onSuccess}}
>   5. 실패 시: {{onFailure}} (예: Error Toast + 실패 행 하이라이트)

#### 2.7 State

| State | Type | Default | Description |
|-------|------|---------|-------------|
| {{name}} | {{type}} | {{default}} | {{description}} |

#### 2.8 Validation Rules

| Field | Rule | Message |
|-------|------|---------|
| {{field}} | required/minLength/pattern/... | {{message}} |

#### 2.9 Main User Flows

> 해당 화면의 주요 사용자 흐름(Happy Path + 주요 분기)을 기술.
> 단순 CRUD 흐름은 생략. 복합 비즈니스 로직이 있는 경우만 기재.

**Flow 1: {{flowName}}** (예: 사전상담 등록 → 심사 요청)
1. {{step1}} (예: VOC 검색 → 기존 VOC 선택 또는 신규 등록)
2. {{step2}} (예: 상담 유형 선택 → 연관 필드 자동 표시)
3. {{step3}} (예: 필수 항목 입력 → 실시간 유효성 검증)
4. Decision: {{condition}} → Yes: {{yesPath}} / No: {{noPath}}
5. {{outcome}} (예: 저장 → 상태 '접수완료' → 심사화면 이동)

> **흐름 간 연관:** Flow 1의 결과가 Flow 2의 선행조건이 되는 경우 명시.

#### 2.10 Sequential Diagram

> HTML 생성 시 시퀀스 다이어그램을 inline SVG로 렌더링.
> Actor(사용자) — Frontend — Backend API — DB/External 간 상호작용.
> 단순 단일 API 호출은 생략. 복수 API 연쇄 호출, 조건 분기, 병렬 호출이 있는 경우 기재.

Actors: {{actor1}}, {{actor2}}, {{actor3}}, {{actor4}}

Sequence:
1. {{actor1}} → {{actor2}}: {{action}}
2. {{actor2}} → {{actor3}}: {{apiCall}}
3. {{actor3}} → {{actor4}}: {{dbOperation}}
4. {{actor4}} -->> {{actor3}}: {{response}}
5. {{actor3}} -->> {{actor2}}: {{apiResponse}}
6. {{actor2}}: {{uiUpdate}}

#### 2.11 Class Diagram

> HTML 생성 시 해당 화면의 주요 도메인 클래스/인터페이스를 inline SVG로 렌더링.
> 화면이 다루는 핵심 엔티티의 속성, 메서드, 관계를 시각화.
> 단순 DTO(필드만 나열)는 생략. 비즈니스 로직이 포함된 클래스만 기재.

Classes:
- **{{className}}** (예: ConsultationService)
  - Properties: {{prop1}}: {{type}}, {{prop2}}: {{type}}
  - Methods: {{method1}}({{params}}): {{returnType}}, {{method2}}()
- **{{className2}}** (예: VOCEntity)
  - Properties: {{prop1}}: {{type}}, {{prop2}}: {{type}}

Relationships:
- {{class1}} → {{class2}}: {{relation}} (예: ConsultationService → VOCEntity: uses)
- {{class1}} ◇→ {{class2}}: {{relation}} (예: Consultation ◇→ VOC: aggregation)

#### 2.12 Used ERD

> HTML 생성 시 해당 화면이 참조하는 엔티티만 추출하여 mini ERD SVG를 생성.
> erd.json에서 관련 엔티티 + 관계를 조회하여 축소된 ERD 다이어그램 렌더링.

Related Entities: {{entityList}} (예: ENT-010 Order, ENT-020 OrderItem, ENT-030 Quote)

#### 2.13 SRS · FT · Common Rules References

> 해당 화면에 적용되는 SRS 요구사항, Feature(FT), 공통 비즈니스 규칙의 추적 참조.
> 단순 CRUD 매핑은 생략. 특별한 규칙/조건이 적용되는 항목만 기재.

| Ref ID | Type | Title | Relevance to This Screen |
|--------|------|-------|-------------------------|
| FR-{{id}} | Functional Req | {{title}} | {{howItApplies}} (예: "VOC 검색 시 최근 6개월 이내만 표시 — 이 화면의 검색 필터에 기간 제한 적용") |
| FT-{{id}} | Feature | {{title}} | {{howItApplies}} (예: "사전상담 등록 기능 — 이 화면이 해당 FT의 메인 구현 화면") |
| CR-{{id}} | Common Rule | {{title}} | {{howItApplies}} (예: "금액 표시 규칙 — 모든 금액 필드에 천단위 콤마 + 원 단위 표시") |

> **Common Rules**: 프로젝트 전역 공통 규칙 중 이 화면에 특별히 영향을 미치는 항목.
> 예: 권한 규칙, 금액 계산 규칙, 코드 자동 생성 규칙, 상태 전이 규칙 등.
