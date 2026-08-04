# Screen Specification Reference

> Detailed rules for generating the Screen Specification document, including component taxonomy, state management patterns, API call mapping, validation rules, responsive considerations, and JSON companion structure.

## 1. Overview

The Screen Specification defines every screen in the application at a component level. It translates the IA page inventory into detailed layouts specifying which UI components appear on each screen, what data they display, which API endpoints they call, what state they manage, and what validation rules they enforce. The Screen Specification is the primary input for frontend development.

The Screen Specification is produced as a pair: `screens.md` (human-readable) and `screens.json` (machine-readable companion conforming to `_meta/schemas/doc-companion.schema.json`). Every screen must trace back to an IA page and at least one FR from the SRS.

## 2. Component Taxonomy

The Screen Specification uses a standardized component taxonomy. Every UI element on a screen must be classified into one of these component types. This taxonomy aligns with the Design System document and ensures consistent naming across all project artifacts.

### 2.1 Core Components

**Button**

| Variant | Usage | Example |
|---------|-------|---------|
| Primary | Main action on a screen | "Save", "Submit", "Create" |
| Secondary | Supporting action | "Cancel", "Back", "Reset" |
| Danger | Destructive action | "Delete", "Remove", "Revoke" |
| Ghost | Low-emphasis action | "Learn more", "Skip" |
| Icon | Icon-only action | Edit icon, Close icon |
| Link | Navigation-style action | "View all", "See details" |

**Input**

| Variant | Usage | Example |
|---------|-------|---------|
| Text | Single-line text entry | Name, email, search query |
| Textarea | Multi-line text entry | Description, comments, notes |
| Number | Numeric entry | Quantity, price, age |
| Password | Masked text entry | Password, PIN |
| Email | Email-formatted entry | Email address |
| Phone | Phone-formatted entry | Phone number |
| Date | Date selection | Birth date, deadline |
| DateTime | Date + time selection | Event start, schedule |
| File | File upload | Document, image upload |
| Select | Dropdown selection | Category, status, role |
| MultiSelect | Multi-value dropdown | Tags, categories |
| Checkbox | Boolean toggle | Agree to terms, enable feature |
| Radio | Single selection from group | Gender, plan type |
| Toggle | On/off switch | Enable notifications, dark mode |

**Card**

| Variant | Usage | Example |
|---------|-------|---------|
| Content | Display entity summary | Product card, user card |
| Stat | Display a metric | Revenue card, count card |
| Action | Card with CTA buttons | Onboarding step, feature card |
| Media | Card with image/video | Gallery item, media preview |

**Table**

| Variant | Usage | Example |
|---------|-------|---------|
| Data | Paginated data display | Product list, user list |
| Sortable | Columns with sort capability | Any list with header clicks |
| Selectable | Rows with checkboxes | Bulk action lists |
| Expandable | Rows with collapsible detail | Order list with line items |

**Modal**

| Variant | Usage | Example |
|---------|-------|---------|
| Confirm | Yes/No decision | Delete confirmation |
| Form | Data entry overlay | Quick create, edit form |
| Info | Information display | Help text, details preview |
| Alert | Critical notification | Error message, warning |

**List**

| Variant | Usage | Example |
|---------|-------|---------|
| Simple | Text list | Navigation items, menu |
| Descriptive | Title + description | Notification list, activity log |
| Avatar | With user avatar | User list, comment thread |
| Action | With action buttons | Task list, approval queue |

**Form**

| Variant | Usage | Example |
|---------|-------|---------|
| Vertical | Stacked label + input | Standard data entry |
| Horizontal | Side-by-side label + input | Compact settings |
| Inline | No labels, placeholder only | Search bar, quick add |
| Wizard | Multi-step form | Registration, checkout |

**Nav**

| Variant | Usage | Example |
|---------|-------|---------|
| Header | Top navigation bar | GNB |
| Sidebar | Side navigation | LNB |
| Tabs | Tab navigation | Section tabs within a page |
| Breadcrumb | Location trail | Page hierarchy indicator |
| Pagination | Page navigation | Table pagination controls |

### 2.2 Component Specification Format

Each component on a screen is documented in a table:

| # | Component | Type | Props/Data | Interaction |
|---|-----------|------|-----------|-------------|
| 1 | Search Bar | Input.Text | placeholder="Search..." | onInput → filter list |
| 2 | Product Table | Table.Sortable | columns: name, price, status | onClick row → navigate to detail |
| 3 | Create Button | Button.Primary | label="Create Product" | onClick → navigate to create page |
| 4 | Delete Modal | Modal.Confirm | title="Confirm Delete" | onConfirm → call DELETE API |

The `Type` column uses dot notation: `{ComponentType}.{Variant}`. The `Props/Data` column specifies the data binding or static properties. The `Interaction` column describes the user interaction and its effect.

## 3. State Management Patterns

Each screen specifies its local state and how it connects to API data.

### 3.1 State Table Format

| State | Type | Default | Description |
|-------|------|---------|-------------|
| items | Product[] | [] | List of products from API |
| loading | boolean | true | Data fetch in progress |
| error | string \| null | null | Error message from API |
| selectedId | number \| null | null | Currently selected product ID |
| filters | object | { q: "", status: "all" } | Active filter values |
| page | number | 1 | Current pagination page |
| sortBy | string | "createdAt" | Active sort column |
| sortOrder | "asc" \| "desc" | "desc" | Sort direction |

### 3.2 State Categories

**Server State:** Data fetched from APIs. Managed via data fetching hooks or state management. Examples: `items`, `itemDetail`, `userProfile`.

**UI State:** Local interaction state not persisted to the server. Examples: `loading`, `error`, `selectedId`, `isModalOpen`, `activeTab`.

**Form State:** Input values bound to form fields. Examples: `formData`, `validationErrors`, `isDirty`, `isSubmitting`.

**Navigation State:** Derived from URL parameters. Examples: `page`, `filters`, `sortBy`, `searchQuery`.

### 3.3 State Flow Pattern

```
Page Mount
  → Set loading = true
  → Call API (GET /entities)
  → On success: Set items = response.data, loading = false
  → On error: Set error = response.error.message, loading = false

User Action (filter/sort/paginate)
  → Update filters/sort/page state
  → Re-call API with new params
  → Update items state

Form Submit
  → Set isSubmitting = true
  → Validate form locally
  → If invalid: Set validationErrors, isSubmitting = false
  → If valid: Call API (POST/PUT)
  → On success: Navigate or refresh list
  → On error: Set error, isSubmitting = false
```

## 4. API Call Mapping

Each screen specifies exactly which API endpoints it calls and when.

### 4.1 API Call Table Format

| Trigger | API | Method | Purpose |
|---------|-----|--------|---------|
| onMount | API-010 | GET | Load product list |
| onSearch | API-010 | GET | Search products with query |
| onSort | API-010 | GET | Re-fetch with sort params |
| onPageChange | API-010 | GET | Load page N |
| onCreateSubmit | API-030 | POST | Create new product |
| onDeleteConfirm | API-050 | DELETE | Delete selected product |

### 4.2 Trigger Types

| Trigger | When It Fires |
|---------|--------------|
| `onMount` | Component/page is first loaded |
| `onSubmit` | Form is submitted |
| `onClick` | Button or element is clicked |
| `onChange` | Input value changes |
| `onSearch` | Search input is submitted or debounced |
| `onSort` | Table column header is clicked |
| `onPageChange` | Pagination control is used |
| `onFilter` | Filter value is changed |
| `onConfirm` | Modal confirm action is triggered |
| `onScroll` | Infinite scroll threshold is reached |

### 4.3 Loading and Error States

Every API call must define how the screen handles:
1. **Loading:** Show skeleton loader, spinner, or disable interactive elements
2. **Empty:** Show empty state message with optional CTA ("No products found. Create one?")
3. **Error:** Show error message with retry option
4. **Optimistic update:** For mutations, optionally update UI before server confirms

## 5. Validation Rules

Each form screen specifies validation rules for every input field.

### 5.1 Validation Rule Table

| Field | Rule | Message |
|-------|------|---------|
| name | required | "Name is required" |
| name | maxLength(255) | "Name must be 255 characters or fewer" |
| email | required | "Email is required" |
| email | pattern(email) | "Enter a valid email address" |
| price | required | "Price is required" |
| price | min(0) | "Price must be zero or greater" |
| password | required | "Password is required" |
| password | minLength(8) | "Password must be at least 8 characters" |
| password | pattern(strongPassword) | "Password must include uppercase, lowercase, number, and symbol" |

### 5.2 Standard Validation Rules

| Rule | Description | Example |
|------|-----------|---------|
| `required` | Field must not be empty | — |
| `minLength(n)` | Minimum character count | `minLength(8)` |
| `maxLength(n)` | Maximum character count | `maxLength(255)` |
| `min(n)` | Minimum numeric value | `min(0)` |
| `max(n)` | Maximum numeric value | `max(999999)` |
| `pattern(name)` | Regex pattern (named) | `pattern(email)`, `pattern(phone)` |
| `oneOf(values)` | Must be one of listed values | `oneOf(active,inactive)` |
| `unique` | Must be unique (server validation) | — |
| `match(field)` | Must match another field | `match(password)` |
| `fileType(types)` | Accepted file extensions | `fileType(jpg,png,pdf)` |
| `fileSize(max)` | Maximum file size | `fileSize(5MB)` |

### 5.3 Validation Timing

- **onChange:** Validate individual field as user types (debounced 300ms). Show inline error.
- **onBlur:** Validate field when user leaves it. Show inline error.
- **onSubmit:** Validate all fields before submission. Show all errors simultaneously.
- **Server-side:** API returns 400 VALIDATION_ERROR with field-level details. Map to inline errors.

## 6. Responsive Considerations

Each screen specification includes responsive behavior notes.

### 6.1 Breakpoint Reference

| Name | Width | Layout Notes |
|------|-------|-------------|
| Mobile | < 640px | Single column, stacked layout, hamburger nav |
| Tablet | 640px - 1024px | Two columns, collapsible sidebar |
| Desktop | > 1024px | Full layout, persistent sidebar |

### 6.2 Responsive Patterns

**Table → Card:** Data tables collapse to card lists on mobile. Each row becomes a card with key fields visible and secondary fields in expandable detail.

**Sidebar → Drawer:** Desktop sidebar navigation becomes a hamburger-triggered drawer on mobile.

**Multi-column → Stack:** Multi-column layouts stack vertically on mobile.

**Modal → Full screen:** Modals become full-screen overlays on mobile.

**Horizontal form → Vertical:** Side-by-side label + input switches to stacked on mobile.

### 6.3 Screen-Level Responsive Notes

Each screen detail section includes a "Responsive" subsection:

```markdown
**Responsive:**
- Mobile: Table converts to card list; Create button moves to floating action button
- Tablet: Two-column layout with collapsed sidebar; Table maintains column headers
- Desktop: Full sidebar + content area; All table columns visible
```

## 7. JSON Companion Structure (screens.json)

The `screens.json` file conforms to `_meta/schemas/doc-companion.schema.json`:

```json
{
  "docType": "screens",
  "app": "my-app",
  "status": "Draft",
  "version": "1.0.0",
  "lastUpdated": "2026-04-03T11:30:00Z",
  "items": [
    {
      "id": "SC-010",
      "type": "screen",
      "title": "Login",
      "description": "User authentication screen with email/password and social login",
      "status": "Draft",
      "priority": "Must",
      "tracedFrom": ["IA-020", "FR-010"],
      "tracedTo": [],
      "figmaUrl": "https://www.figma.com/design/{file_key}/{file_name}?node-id=1234:5678",
      "path": "/auth/login",
      "category": "Auth",
      "components": [
        { "name": "Email Input", "type": "Input.Email", "props": "required", "boundData": "formState.email" },
        { "name": "Password Input", "type": "Input.Password", "props": "required, minLength(8)", "boundData": "formState.password" },
        { "name": "Login Button", "type": "Button.Primary", "props": "label=Login", "boundData": null },
        { "name": "Social Login", "type": "Button.Secondary", "props": "providers: Google, GitHub", "boundData": null }
      ],
      "apiCalls": ["API-080"],
      "states": ["email", "password", "loading", "error"],
      "selectOptions": [],
      "overlays": [],
      "actionHandlers": [
        {
          "action": "Login 버튼 클릭",
          "handler": "handleLogin",
          "steps": ["email/password 유효성 검증", "API-080 POST /auth/login", "성공 → Dashboard 이동", "실패 → 에러 Toast"],
          "relatedRule": null
        }
      ],
      "mainFlows": [
        {
          "name": "이메일 로그인",
          "steps": ["이메일/비밀번호 입력", "Login 클릭", "API 인증", "Dashboard 이동"],
          "decisions": []
        }
      ],
      "classRefs": [],
      "srsRefs": ["FR-010"],
      "ftRefs": ["FT-010"],
      "commonRuleRefs": [],
      "layout": {
        "direction": "vertical",
        "areas": [
          { "name": "Header", "height": "auto", "children": ["Logo", "App Title"] },
          { "name": "Body", "height": "flex", "direction": "vertical", "children": ["Email Input", "Password Input", "Login Button", "Social Login"] },
          { "name": "Footer", "height": "auto", "children": ["Forgot Password Link", "Sign Up Link"] }
        ]
      }
    }
  ],
  "crossRefs": [
    {
      "from": "SC-010",
      "to": "IA-020",
      "relation": "implements"
    },
    {
      "from": "SC-010",
      "to": "FR-010",
      "relation": "implements"
    },
    {
      "from": "SC-010",
      "to": "API-080",
      "relation": "references"
    }
  ]
}
```

### 7.1 Item Type Values for Screens

| type | Used For |
|------|---------|
| `screen` | Full page screen definitions |
| `modal` | Modal/dialog definitions (may be shared across screens) |
| `partial` | Reusable partial components (e.g., header, footer) |

### 7.2 Extended Fields

Screen items include additional fields beyond the base schema:

| Field | Type | Description |
|-------|------|-----------|
| `path` | string | URL path |
| `category` | string | Auth/Dashboard/CRUD/etc. |
| `components` | array | Component specifications with `name`, `type`, `props`, `boundData` |
| `apiCalls` | string[] | Array of API IDs |
| `states` | string[] | State variable names |
| `layout` | object | Screen layout structure for SVG rendering |
| `selectOptions` | array | Select/Radio/Enum 필드의 선택지 목록. 각 항목: `{ field, component, options: [{value, label}], source, default }` |
| `overlays` | array | 오버레이 컴포넌트 목록. 각 항목: `{ id, type, trigger, purpose, components, actions }` |
| `actionHandlers` | array | 사용자 액션 핸들링 맵. 각 항목: `{ action, handler, steps, relatedRule }` |
| `mainFlows` | array | 주요 사용자 흐름. 각 항목: `{ name, steps, decisions }` |
| `classRefs` | array | Class diagram 참조 클래스명 목록 |
| `srsRefs` | string[] | 관련 FR ID 목록 (Screen Inventory 외 추가 참조) |
| `ftRefs` | string[] | 관련 FT ID 목록 |
| `commonRuleRefs` | string[] | 적용되는 공통 규칙 CR ID 목록 |
| `figmaUrl` | string \| null | Figma 소스 deep link (`?node-id=...`). Figma에서 파생된 화면인 경우 필수 |

These enable downstream tools to scaffold frontend code, generate wireframe diagrams, and maintain traceability automatically.

### 7.3 Layout Field Structure

The `layout` field describes the screen's spatial structure for inline SVG diagram generation:

```json
{
  "layout": {
    "direction": "horizontal|vertical",
    "areas": [
      {
        "name": "Area name (e.g., Sidebar, Header, Main Content)",
        "width": "fixed(px)|flex|auto",
        "height": "fixed(px)|flex|auto",
        "direction": "horizontal|vertical",
        "children": ["Component or sub-area names"]
      }
    ]
  }
}
```

- **`direction`**: Top-level layout flow (`horizontal` for side-by-side, `vertical` for stacked)
- **`areas`**: Ordered list of layout regions. Each area can have nested `children` (component names or sub-area labels)
- **`width`/`height`**: `"200px"` (fixed), `"flex"` (fill remaining), `"auto"` (content-sized)
- Areas are rendered as labeled rectangles in the SVG with proportional sizing

## 8. Non-Generic Content Policy (CRITICAL)

Screen Specification의 모든 섹션은 **해당 화면에 특화된 내용만** 기재한다. 일반적이거나 자명한 내용은 반드시 생략한다.

### 8.1 생략 기준

| Category | 생략 대상 (기재 금지) | 기재 대상 |
|----------|---------------------|----------|
| **Select Options** | 성별(남/여), 사용여부(Y/N), 정렬순서(오름차순/내림차순) | 도메인 특화 선택지 (배정유형, 상담유형, 계약구분 등) |
| **Action Handling** | 페이지 로드, 뒤로가기, 단순 navigate, 단순 모달 열기/닫기 | 복합 비즈니스 로직 (일괄처리, 조건부 상태전이, 연쇄 API 호출) |
| **State** | `loading`, `error`, `isModalOpen` (UI 공통 state) | 도메인 state (`assignmentStatus`, `calculatedAmount`, `vocList`) |
| **Validation** | `required` on 단독 필드 (자명한 필수값) | 복합 validation (교차 필드, 조건부 필수, 비즈니스 계산 검증) |
| **Sequential Diagram** | 단일 CRUD API 호출 (GET→응답→표시) | 복수 API 연쇄, 조건 분기, 외부 시스템 연동 |
| **Class Diagram** | 단순 DTO (필드 나열만) | 비즈니스 로직 포함 클래스, 복합 관계 |
| **Main Flows** | 단순 CRUD (목록→상세→수정→저장) | 복합 업무 흐름 (심사→승인→배정→완료 등 다단계) |
| **SRS/FT References** | 단순 1:1 매핑 (화면=FR) | 특별한 규칙 적용, 복수 FR 관련, 공통규칙 영향 |

### 8.2 판단 기준

> "개발자가 이 항목을 안 읽어도 구현에 문제가 없다면 → 생략"
> "이 항목이 없으면 개발자가 잘못 구현할 수 있다면 → 반드시 기재"

## 9. Select Options & Possible Values

화면 내 모든 Select, Radio, Checkbox Group, MultiSelect, Enum 타입 필드는 선택 가능한 값 목록을 명시해야 한다.

### 9.1 Source Types

| Source | Description | Example |
|--------|-----------|---------|
| `static` | 코드에 하드코딩된 선택지 | `static: ["일반", "긴급", "VIP"]` |
| `API-xxx` | API 호출로 동적 조회 | `API-045 GET /codes?group=consultType` |
| `enum:table.column` | DB 코드 테이블에서 조회 | `enum:common_code.consult_type` |

### 9.2 기재 규칙

1. **모든 도메인 특화 선택지의 값을 나열** — 코드값 + 표시명 모두 기재
2. **기본값(Default)** 명시 — 없으면 `-`
3. **조건부 옵션**: 다른 필드 값에 따라 옵션이 변하는 경우 조건 명시
4. **의존 관계**: 상위 Select 변경 시 하위 Select 옵션이 변하는 cascade 관계 명시

## 10. Overlay Component Specifications

화면에서 사용하는 모든 Overlay UI(Modal, BottomSheet, Popup, Drawer, Toast)를 독립 세부 항목으로 기술한다.

### 10.1 Overlay 기재 항목

| 항목 | 필수 | Description |
|------|------|-----------|
| Trigger | ✅ | 어떤 사용자 액션으로 오버레이가 열리는지 |
| Purpose | ✅ | 오버레이의 목적 (확인, 데이터 입력, 정보 표시 등) |
| Components | ✅ | 오버레이 내부 컴포넌트 목록 (Type, Props, Bound Data) |
| Actions | ✅ | Confirm/Cancel/기타 버튼별 동작 상세 |
| Size | ○ | 오버레이 크기 (sm/md/lg/xl/fullscreen) |
| Closable | ○ | 외부 클릭/ESC로 닫기 가능 여부 |
| Related | ✅ | 관련 FR, BR 참조 |

### 10.2 Overlay → JSON Companion 매핑

`screens.json`의 `items` 배열에서 `type: "modal"` 또는 `type: "overlay"` 항목으로 기록:

```json
{
  "id": "SC-010-OV-01",
  "type": "modal",
  "title": "삭제 확인",
  "parentScreen": "SC-010",
  "overlayType": "confirm",
  "trigger": "삭제 버튼 클릭",
  "components": [...],
  "tracedFrom": ["FR-025"]
}
```

## 11. User Action Handling Map

각 화면의 사용자 액션별 시스템 응답을 구조화하여 기술한다. 이 데이터는 Wireframe의 프로세스 흐름도(Business Process Flow) 생성의 소스가 된다.

### 11.1 기재 대상 액션

| 기재 대상 | 생략 대상 |
|----------|----------|
| 복수 API 연쇄 호출 | 단일 API 호출 (단순 CRUD) |
| 조건부 로직 분기 | 단순 navigate |
| 상태 전이 (예: 대기→배정→완료) | 단순 모달 열기/닫기 |
| 일괄 처리 (bulk action) | 단순 필터/정렬 |
| 계산 로직 (자동 계산, 합계 등) | 단순 입력 → 저장 |

### 11.2 복합 핸들링 상세 구조

복합 액션은 단계별로 기술:

```
1. 선행 조건 (Precondition): 액션 수행 전 충족해야 하는 조건
2. 유효성 검증 (Validation): 데이터 검증 규칙
3. API 호출 (API Call): 순서대로 호출하는 API 목록
4. 성공 시 (On Success): UI 갱신, Toast, 화면 이동 등
5. 실패 시 (On Failure): 에러 처리, 롤백, 재시도 등
```

## 12. Main User Flows

각 화면의 주요 사용자 시나리오를 단계별로 기술한다. 단순 CRUD 흐름은 생략하고, 복합 비즈니스 로직이 관련된 흐름만 기재한다.

### 12.1 흐름 기술 형식

1. **Flow Name**: 흐름의 목적을 나타내는 이름
2. **Steps**: 번호가 매겨진 단계 (사용자 액션 + 시스템 응답 교대)
3. **Decision Points**: 조건 분기가 있는 지점에서 Yes/No 경로 명시
4. **Related Flows**: 이 흐름의 결과가 다른 흐름의 선행조건이 되는 경우

### 12.2 흐름 간 연관

여러 흐름이 연결되는 경우:
- Flow A 완료 → Flow B 시작 조건 충족
- Flow A 도중 분기 → Flow C로 이동
- Flow A와 Flow B가 동일 데이터를 참조 (경합 조건 주의)

## 13. Class Diagram Specification

화면이 다루는 핵심 도메인 클래스/인터페이스의 속성, 메서드, 관계를 기술한다.

### 13.1 기재 대상

| 기재 대상 | 생략 대상 |
|----------|----------|
| 비즈니스 로직이 포함된 Service/Entity 클래스 | 단순 DTO (필드만 나열) |
| 복합 관계 (aggregation, composition, inheritance) | 단순 참조 관계 |
| 상태 패턴, 전략 패턴 등 디자인 패턴 적용 | 일반적인 CRUD Repository |

### 13.2 관계 표기

| 기호 | 관계 | 예시 |
|------|------|------|
| `→` | 의존 (uses/depends on) | `Service → Repository` |
| `◇→` | 집합 (aggregation) | `Order ◇→ OrderItem` |
| `◆→` | 합성 (composition) | `Invoice ◆→ InvoiceLine` |
| `▷` | 상속 (extends) | `VIPConsultation ▷ Consultation` |
| `..▷` | 구현 (implements) | `ConsultationServiceImpl ..▷ ConsultationService` |

## 14. SRS · FT · Common Rules Traceability

화면별로 적용되는 SRS 요구사항, Feature(FT), 공통 비즈니스 규칙의 추적 참조를 기재한다.

### 14.1 Reference Types

| Type | ID Pattern | Description |
|------|-----------|-----------|
| FR (Functional Req) | `FR-xxx` | SRS의 기능 요구사항 |
| FT (Feature) | `FT-xxx` | 구현 단위 Feature |
| CR (Common Rule) | `CR-xxx` | 프로젝트 전역 공통 규칙 |
| BR (Business Rule) | `BR-SC-xxx-nn` | 화면별 비즈니스 규칙 |

### 14.2 기재 규칙

1. **단순 1:1 매핑은 생략** — 화면 = FR인 경우 이미 Screen Inventory에서 추적됨
2. **특별한 규칙 적용 시 기재** — 이 화면에 영향을 미치는 공통규칙, 복수 FR 관련 사항
3. **Relevance 컬럼 필수** — 해당 규칙이 이 화면에 어떻게 적용되는지 구체적으로 설명

## 15. Screen Sections Mapping to Template

The `_meta/templates/screens.template.md` defines the canonical section structure:

| Section | Content |
|---------|---------|
| 1. Screen Inventory | Table of all screens with ID, name, path, category, related IA, related FR |
| 2. Screen Details | One subsection per screen (아래 상세) |

Each Screen Detail subsection includes:

| # | Section | Required | Skip When |
|---|---------|----------|-----------|
| 2.1 | Wireframe & Annotations | ✅ Always | — |
| 2.2 | Components & Data Binding | ✅ Always | — |
| 2.3 | Select Options & Possible Values | Conditional | 도메인 특화 선택지가 없을 때 |
| 2.4 | Overlay Components | Conditional | 오버레이가 없을 때 |
| 2.5 | API Calls | ✅ Always | — |
| 2.6 | User Action Handling Map | Conditional | 복합 핸들링이 없을 때 (단순 CRUD만) |
| 2.7 | State | ✅ Always | — |
| 2.8 | Validation Rules | Conditional | 폼이 없을 때 |
| 2.9 | Main User Flows | Conditional | 단순 CRUD만일 때 |
| 2.10 | Sequential Diagram | Conditional | 단일 API 호출만일 때 |
| 2.11 | Class Diagram | Conditional | 비즈니스 로직 클래스가 없을 때 |
| 2.12 | Used ERD | ✅ Always | — |
| 2.13 | SRS · FT · Common Rules | Conditional | 특별한 규칙 적용이 없을 때 |

**Layout:** Screen layout structure description (영역 구분, 배치, 크기 비율). JSON companion의 `layout` 필드에도 구조화하여 HTML 생성 시 inline SVG 레이아웃 다이어그램으로 렌더링.

## 16. Validation Checks

After Screen Specification generation, the following validations are performed:

1. **ID uniqueness:** No duplicate SC IDs.
2. **ID format:** All IDs match `^SC-\d{3}$`.
3. **IA traceability:** Every screen traces to an IA page.
4. **FR traceability:** Every screen traces to at least one FR.
5. **API consistency:** All API IDs referenced in apiCalls exist in the API Contract.
6. **Component taxonomy:** All component types use the standard taxonomy notation.
7. **Validation completeness:** Every form screen has validation rules for required fields.
8. **State completeness:** Every screen with API calls has loading and error states.
9. **Path uniqueness:** No two screens share the same URL path.
10. **JSON-Markdown sync:** Every item in `screens.json` has a corresponding entry in `screens.md`.
11. **Link graph update:** `data/links.json` contains nodes and edges for all screen items.
