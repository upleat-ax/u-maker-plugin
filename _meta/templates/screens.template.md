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

#### 2.2 Components

| # | Component | Type | Props / Validation | API |
|---|-----------|------|--------------------|-----|
| 1 | {{name}} | Button/Input/Card/Table/Select/Upload/Display/Form/Action | {{props}} | {{apiEndpoint}} or `-` |

#### 2.3 API Calls

| Trigger | API | Method | Request | Response | Purpose |
|---------|-----|--------|---------|----------|---------|
| onLoad | API-010 | GET | - | {{responseShape}} | {{purpose}} |
| onClick ({{button}}) | API-020 | POST | {{requestBody}} | {{responseShape}} | {{purpose}} |

#### 2.4 State

| State | Type | Default | Description |
|-------|------|---------|-------------|
| {{name}} | {{type}} | {{default}} | {{description}} |

#### 2.5 Validation Rules

| Field | Rule | Message |
|-------|------|---------|
| {{field}} | required/minLength/pattern/... | {{message}} |

#### 2.6 Business Logic Diagram

> HTML 생성 시 condition flow chart를 inline SVG로 렌더링.
> 화면의 유효성 검사 흐름 + 조건 분기 + 최종 성공/실패 상태를 시각화.

Flow:
1. {{startAction}} (예: 폼 표시)
2. {{userInput}} (예: 필드 입력)
3. {{triggerAction}} (예: 저장 버튼 클릭)
4. Decision: {{condition1}} → Yes/No
5. Decision: {{condition2}} → Yes/No
6. {{successOutcome}} (예: API 호출 → 상태 변경 → 화면 이동)

#### 2.7 Sequential Diagram

> HTML 생성 시 시퀀스 다이어그램을 inline SVG로 렌더링.
> Actor(사용자) — Frontend — Backend API — DB/External 간 상호작용.

Actors: {{actor1}}, {{actor2}}, {{actor3}}, {{actor4}}

Sequence:
1. {{actor1}} → {{actor2}}: {{action}}
2. {{actor2}} → {{actor3}}: {{apiCall}}
3. {{actor3}} → {{actor4}}: {{dbOperation}}
4. {{actor4}} -->> {{actor3}}: {{response}}
5. {{actor3}} -->> {{actor2}}: {{apiResponse}}
6. {{actor2}}: {{uiUpdate}}

#### 2.8 Data Flow Diagram

> HTML 생성 시 DFD를 inline SVG로 렌더링.
> 외부 엔티티, 프로세스, 데이터 저장소 간 데이터 흐름.

External Entities: {{entityList}} (예: 담당자)
Processes: {{processList}} (예: QuoteForm Page, Backend API)
Data Stores: {{storeList}} (예: Zustand formState, TanStack Mutation, DB)

Flows:
- {{source}} → {{target}}: {{dataDescription}}

#### 2.9 Used ERD

> HTML 생성 시 해당 화면이 참조하는 엔티티만 추출하여 mini ERD SVG를 생성.
> erd.json에서 관련 엔티티 + 관계를 조회하여 축소된 ERD 다이어그램 렌더링.

Related Entities: {{entityList}} (예: ENT-010 Order, ENT-020 OrderItem, ENT-030 Quote)
