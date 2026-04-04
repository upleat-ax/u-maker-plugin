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
      "path": "/auth/login",
      "category": "Auth",
      "components": [
        { "name": "Email Input", "type": "Input.Email", "props": "required" },
        { "name": "Password Input", "type": "Input.Password", "props": "required, minLength(8)" },
        { "name": "Login Button", "type": "Button.Primary", "props": "label=Login" },
        { "name": "Social Login", "type": "Button.Secondary", "props": "providers: Google, GitHub" }
      ],
      "apiCalls": ["API-080"],
      "states": ["email", "password", "loading", "error"],
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

Screen items include additional fields: `path` (URL path), `category` (Auth/Dashboard/CRUD/etc.), `components` (array of component specifications), `apiCalls` (array of API IDs), `states` (array of state variable names), and `layout` (screen layout structure for SVG rendering). These enable downstream tools to scaffold frontend code and generate visual layout diagrams automatically.

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

## 8. Screen Sections Mapping to Template

The `_meta/templates/screens.template.md` defines the canonical section structure:

| Section | Content |
|---------|---------|
| 1. Screen Inventory | Table of all screens with ID, name, path, category, related IA, related FR |
| 2. Screen Details | One subsection per screen with layout, components, API calls, state, validation |

Each Screen Detail subsection includes:
- **Layout:** Screen layout structure description (영역 구분, 배치, 크기 비율). JSON companion의 `layout` 필드에도 구조화하여 HTML 생성 시 inline SVG 레이아웃 다이어그램으로 렌더링.
- **Components:** Component table with type, props, interaction
- **API Calls:** Trigger-API mapping table
- **State:** State variable table with types and defaults
- **Validation Rules:** Field validation table (for form screens)
- **Responsive:** Breakpoint behavior notes

## 9. Validation Checks

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
