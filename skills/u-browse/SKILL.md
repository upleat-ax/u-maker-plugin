---
name: u-browse
description: "SSoT 문서를 분석·교차참조·다이어그램 포함한 리치 HTML로 변환. 와이어프레임에는 어노테이션·화면흐름·비즈니스로직·버튼액션을 포함한다. index.html sidebar navigation 제공."
triggers:
  - "/u-browse"
  - "browse"
  - "문서 뷰어"
  - "docs html"
  - "문서 브라우징"
  - "개별 HTML"
  - "doc viewer"
---

# u-browse -- Enriched SSoT Document Browser

`/u-browse [scope] [--only path] [--open]` 명령으로 `.u-maker/docs/` 하위의 SSoT 문서를 **분석·교차 참조·다이어그램이 포함된 리치 HTML**로 변환하고, **index.html** sidebar navigation으로 브라우징한다.

**Primary Agent:** u-agent-orchestrator

> **단순 변환이 아니다.** `.md`/`.json`을 그대로 렌더링하는 것이 아니라, 다른 문서를 교차 참조하고, JSON 데이터를 분석하여 다이어그램·통계·어노테이션을 자동 생성한 **리치 HTML**을 만든다.

---

## Arguments & Flags

| Argument/Flag | Required | Description |
|---------------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 전체 앱 |
| `--only path` | - | 특정 경로만 변환 (예: `--only hjw/02-design`) |
| `--open` | - | 생성 후 `open` 명령으로 브라우저 자동 열기 |
| `--clean` | - | 기존 `_browse/` 삭제 후 재생성 |

---

## Output Structure

```
.u-maker/_browse/
├── index.html                          # 메인 뷰어 (sidebar + iframe)
├── hjw/
│   ├── 01-plan/
│   │   ├── srs.html                   # SRS 리치 HTML (계층 시각화, Use Case 다이어그램)
│   │   ├── ia.html                    # IA 리치 HTML (SVG Sitemap, 화면 계층)
│   │   └── roadmap.html               # Roadmap 리치 HTML (Gantt chart)
│   ├── 02-design/
│   │   ├── erd.html                   # ERD 리치 HTML (ER 다이어그램, 엔티티 카드)
│   │   ├── api.html                   # API 리치 HTML (메서드 배지, Sequence 다이어그램)
│   │   ├── screens.html               # Screens 리치 HTML (컴포넌트 상세, 상태 다이어그램)
│   │   ├── screen-flow.html           # Screen Flow 리치 HTML (네비게이션 플로우차트)
│   │   ├── rtm.html                   # RTM 리치 HTML (커버리지 히트맵)
│   │   ├── design-token.html          # Design Token 리치 HTML (컬러 스워치, 타이포)
│   │   └── wireframes/
│   │       ├── index.html             # 와이어프레임 뷰어 인덱스
│   │       ├── SCR-001.html           # 와이어프레임 + 어노테이션 + 비즈니스 로직
│   │       ├── SCR-002.html
│   │       └── ...
│   ├── 03-dev/
│   │   └── ...
│   └── 04-check/
│       └── ...
└── ...
```

---

## ★ Execution Flow (MUST FOLLOW EXACTLY)

### Step 0: Load ALL Context (CRITICAL)

**모든 HTML 생성 전에, scope 내의 모든 문서를 먼저 읽어 메모리에 적재한다.**

1. `.u-maker/docs/{scope}/` 하위의 **모든 `.md`와 `.json`** 파일을 Read로 읽는다.
2. 특히 아래 핵심 JSON 파일들의 `data` 필드를 파싱하여 교차 참조 맵을 구성한다:

```
contextMap = {
  srs: { requirements: [...], userStories: [...], features: [...] },
  ia:  { siteMap: [...], screenHierarchy: [...], userFlows: [...] },
  erd: { entities: [...], relations: [...] },
  api: { endpoints: [...], errorCodes: [...] },
  screens: { screens: [...] },                    // 각 화면의 components, interactions, states
  screenFlow: { navigationMap: [...], journeyFlows: [...], transitionRules: [...] },
  rtm: { traceabilityRows: [...], frCoverage: [...], gaps: [...] },
  designToken: { brandColors: [...], semanticColors: [...], typographyScale: [...] }
}
```

3. **교차 참조 인덱스**를 구성한다:

```
// Feature → Screen 매핑
ftToScreens = { "FT-0010": ["SCR-001", "SCR-003"], ... }

// Screen → API 매핑 (screens.json의 interactions에서 API 호출 추출)
screenToApis = { "SCR-001": ["POST /api/auth/login", "GET /api/user/profile"], ... }

// Screen → Feature 매핑
screenToFts = { "SCR-001": ["FT-0010", "FT-0011"], ... }

// Entity → API 매핑 (API response schema에서 엔티티 추출)
entityToApis = { "User": ["GET /api/users", "POST /api/users"], ... }

// Screen → Screen Flow (from/to 전이 규칙)
screenFlows = { "SCR-001": { next: ["SCR-002", "SCR-003"], prev: ["SCR-010"] }, ... }

// Feature → Test Case 매핑
ftToTcs = { "FT-0010": ["TC-0001", "TC-0002"], ... }
```

이 컨텍스트는 이후 모든 Step에서 참조된다.

### Step 1: Discover Files & Create Directories

```bash
find .u-maker/docs/{scope} -type f \( -name "*.md" -o -name "*.json" -o -name "*.html" \) | sort
mkdir -p .u-maker/_browse/{scope}/{app}/01-plan
mkdir -p .u-maker/_browse/{scope}/{app}/02-design/wireframes
mkdir -p .u-maker/_browse/{scope}/{app}/03-dev
mkdir -p .u-maker/_browse/{scope}/{app}/04-check
```

### Step 2: Generate Enriched HTML per Document Type

**각 문서 타입별로 `.md` + `.json`을 함께 읽고, contextMap을 교차 참조하여 리치 HTML을 생성한다.**

---

#### 2-1. SRS → `srs.html`

**입력:** `srs.md` + `srs.json`
**교차 참조:** IA(화면 매핑), API(엔드포인트 매핑), Screens(FT 매핑)

**생성할 HTML 섹션:**

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Overview** | 프로젝트명, 설명, 대상 사용자, 플랫폼 | - |
| **Stakeholders** | 이해관계자 역할 매트릭스 | - |
| **Requirements** | FR 테이블 (ID, Title, Priority 배지, Status 배지, 관련 US/FT 수) | Priority 분포 `pie` chart |
| **NF Requirements** | NR 테이블 (category, title, metric) | - |
| **User Stories** | US 카드 (actor, action, benefit, acceptance criteria 체크리스트) | - |
| **Features** | FT 테이블 + 각 FT에 연결된 Screen, API, TC 링크 | Use Case `flowchart` |
| **Hierarchy** | USR → FR → US → FT 트리 시각화 | `flowchart TD` |
| **Coverage** | FR별 US/FT/Screen/TC 커버리지 바 | 커버리지 bar chart |

**다이어그램 생성 알고리즘 (Feature Hierarchy):**

```mermaid
flowchart TD
    USR-0010["👤 USR-0010: 일반 사용자"]
    FR-0001["📋 FR-0001: 로그인"]
    US-0001["📝 US-0001: 이메일 로그인"]
    FT-0010["⚙️ FT-0010: 이메일/비밀번호 인증"]
    FT-0011["⚙️ FT-0011: 소셜 로그인"]
    USR-0010 --> FR-0001
    FR-0001 --> US-0001
    US-0001 --> FT-0010
    US-0001 --> FT-0011
```

JSON의 `requirements`, `userStories`, `features` 배열에서 `tracedFrom` 필드를 추적하여 자동 생성.

---

#### 2-2. IA → `ia.html`

**입력:** `ia.md` + `ia.json`
**교차 참조:** Screens(컴포넌트 수), SRS(FT 매핑)

**생성할 HTML 섹션:**

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Visual Sitemap** | 화면 계층을 **인라인 SVG**로 시각화 | SVG sitemap (아래 참고) |
| **Screen Hierarchy** | Level별 화면 테이블 + 와이어프레임 링크 | - |
| **Navigation Patterns** | 패턴별 적용 화면 매트릭스 | - |
| **User Flows** | 각 플로우의 단계별 화면 전이 | SVG flowchart |

**★ Visual Sitemap SVG 생성 (핵심)**

Mermaid mindmap이 아닌, **인라인 SVG**로 직접 사이트맵을 그린다. 아래 레퍼런스 스타일을 따른다.

**SVG Sitemap 구성 요소:**

1. **페이지 카드** — 각 화면을 사각형 카드로 표현
   - 상단: 화면명 (bold, 배경색으로 Level 구분)
   - 하단: 간략 와이어프레임 아이콘 (회색 라인으로 헤더/콘텐츠/사이드바 표현)
   - 카드 크기: `width="120" height="90"` (대략)

2. **Level 색상 코딩:**
   | Level | 배경색 | 설명 |
   |-------|--------|------|
   | L1 (최상위) | `#0891b2` (청록) 흰 텍스트 | Home, 메인 랜딩 |
   | L2 (메인 내비) | `#dbeafe` (연파랑) | 주요 메뉴 항목 |
   | L3 (서브 내비) | `#ffffff` border `#d1d9e0` | 서브 페이지 |
   | L4 (상세) | `#fef9c3` (연노랑) | 상세/편집 화면 |

3. **연결선** — 부모→자식 화면 연결
   - 수직/수평 직각 연결선 (stroke: `#9ca3af`, width: 1.5)
   - 화살촉 마커 (삼각형)

4. **어노테이션 마커** — 빨간 원형 번호 배지
   - 각 주요 화면 옆에 `<circle fill="#ef4444">` + 흰 숫자
   - 주요 포인트가 있는 화면에 callout 텍스트 연결

5. **어노테이션 callout** — 빨간 점선으로 연결된 텍스트 블록
   - "Main points for {화면명}:"
   - 핵심 UX 포인트 bullet 목록

**SVG 레이아웃 알고리즘:**

```
Level 1:     [  Homepage  ]
              |    |    |
Level 2:   [Cat] [About] [Forum] [Login] [SignUp]
              |           |    |
Level 3:   children    [Category] [Profile]
                          |         |
Level 4:              [Thread]  [EditProfile]
```

- L1은 중앙 상단에 1개
- L2는 L1 아래에 수평 배열 (간격: 140px)
- L3은 각 L2 아래에 수직 또는 수평 배열
- L4은 L3 아래에 수직 배열
- SVG viewBox는 전체 트리 크기에 맞게 동적 계산

**SVG 생성 코드 패턴:**

```html
<div class="diag-container" style="max-height:400px;overflow:hidden;position:relative">
  <button class="diag-zoom" onclick="openDiagModal(this)" title="확대">🔍</button>
  <svg class="diag" viewBox="0 0 {{WIDTH}} {{HEIGHT}}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <marker id="arrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
        <polygon points="0 0, 10 3.5, 0 7" fill="#9ca3af"/>
      </marker>
    </defs>

    <!-- L1: Homepage card -->
    <rect x="350" y="20" width="120" height="90" rx="4" fill="#0891b2" stroke="#0891b2"/>
    <text x="410" y="42" text-anchor="middle" fill="#fff" font-size="11" font-weight="700">HOMEPAGE</text>
    <!-- wireframe icon inside card -->
    <rect x="370" y="50" width="80" height="4" rx="1" fill="rgba(255,255,255,.3)"/>
    <rect x="370" y="58" width="50" height="3" rx="1" fill="rgba(255,255,255,.2)"/>
    <rect x="370" y="64" width="80" height="30" rx="2" fill="rgba(255,255,255,.15)"/>

    <!-- Annotation marker -->
    <circle cx="475" cy="25" r="10" fill="#ef4444"/>
    <text x="475" y="29" text-anchor="middle" fill="#fff" font-size="9" font-weight="700">1</text>

    <!-- Annotation callout -->
    <line x1="485" y1="25" x2="520" y2="25" stroke="#ef4444" stroke-dasharray="3"/>
    <text x="525" y="22" fill="#374151" font-size="10" font-weight="700">Main points for homepage:</text>
    <text x="525" y="34" fill="#6b7280" font-size="9">- 카테고리별 콘텐츠 강조</text>
    <text x="525" y="44" fill="#6b7280" font-size="9">- 사용자 인터랙션 증가</text>

    <!-- Connection line to L2 -->
    <line x1="410" y1="110" x2="410" y2="140" stroke="#9ca3af" stroke-width="1.5" marker-end="url(#arrow)"/>

    <!-- L2: Categories card -->
    <rect x="80" y="150" width="120" height="80" rx="4" fill="#dbeafe" stroke="#93c5fd"/>
    <text x="140" y="170" text-anchor="middle" fill="#1e40af" font-size="10" font-weight="700">CATEGORIES</text>
    <!-- ... 더 많은 카드 -->

    <!-- L3: Sub-pages as smaller text items -->
    <text x="100" y="260" fill="#6b7280" font-size="9">→ Clients</text>
    <text x="100" y="275" fill="#6b7280" font-size="9">→ Portfolios</text>
    <!-- ... -->
  </svg>
</div>
```

JSON의 `siteMap` 배열에서 `children` 재귀 순회하여 위 패턴으로 SVG를 생성한다. 화면 수가 많으면 L3 이하는 텍스트 목록으로 간략화한다.

**축소 표시 + 확대:** `max-height: 400px; overflow: hidden` + 🔍 확대 버튼 (모달로 전체 SVG 표시)

---

#### 2-3. ERD → `erd.html`

**입력:** `erd.md` + `erd.json`
**교차 참조:** API(엔티티 사용 엔드포인트), Screens(데이터 바인딩)

**생성할 HTML 섹션:**

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **ER Diagram** | 전체 엔티티 관계 시각화 | `erDiagram` |
| **Entity Cards** | 엔티티별 카드 (컬럼 목록, PK/FK 배지, 타입) | - |
| **Relationships** | 관계 테이블 (1:1, 1:N, M:N 배지) | - |
| **API Usage** | 각 엔티티가 사용되는 API 엔드포인트 목록 | - |
| **Screen Binding** | 각 엔티티가 바인딩된 화면 목록 | - |

**다이어그램 생성 (erDiagram):**

JSON의 `entities`와 `relations`에서 자동 생성:
```mermaid
erDiagram
    User {
        int id PK
        string email UK
        string name
        datetime createdAt
    }
    Order {
        int id PK
        int userId FK
        string status
        decimal totalAmount
    }
    User ||--o{ Order : "places"
```

---

#### 2-4. API → `api.html`

**입력:** `api.md` + `api.json`
**교차 참조:** ERD(응답 스키마 엔티티), Screens(호출 화면), SRS(FT 매핑)

**생성할 HTML 섹션:**

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Overview** | Base URL, Auth 방식, 버전 | - |
| **Endpoints** | 메서드 배지(GET🟢/POST🔵/PUT🟠/DELETE🔴) + path + 요약 | - |
| **Endpoint Detail** | 각 엔드포인트별: Request params, Body schema, Response schema, 호출 화면, 관련 FT | Sequence `sequenceDiagram` (주요 흐름) |
| **Error Codes** | 에러 코드 테이블 | - |
| **Screen Mapping** | 어떤 화면에서 어떤 API를 호출하는지 매트릭스 | - |

**메서드 배지 스타일:**

```html
<span class="method get">GET</span>
<span class="method post">POST</span>
<span class="method put">PUT</span>
<span class="method delete">DELETE</span>
```

CSS: `.method.get { background: #22c55e; }` `.method.post { background: #3b82f6; }` `.method.put { background: #f59e0b; }` `.method.delete { background: #ef4444; }`

**Sequence Diagram (주요 API 흐름):**

```mermaid
sequenceDiagram
    participant C as Client (SCR-001)
    participant S as Server
    participant DB as Database
    C->>S: POST /api/auth/login
    S->>DB: SELECT * FROM users WHERE email=?
    DB-->>S: User record
    S-->>C: 200 { token, user }
```

---

#### 2-5. Screens → `screens.html`

**입력:** `screens.md` + `screens.json`
**교차 참조:** IA(계층), API(호출 엔드포인트), SRS(FT), Screen Flow(전이), ERD(데이터)

**생성할 HTML 섹션:**

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Screen List** | 전체 화면 목록 (ID, 이름, 라우트, FT 링크, 와이어프레임 링크) | - |
| **Screen Cards** | 화면별 상세 카드: | |
| ↳ Components | 컴포넌트 테이블 (name, type 배지, interaction 설명) | - |
| ↳ Interactions | 트리거 → 엘리먼트 → 액션 (API 호출 포함) | - |
| ↳ States | 화면 상태 목록 (조건 → 표시 방식) | `stateDiagram-v2` |
| ↳ Related APIs | 이 화면에서 호출하는 API 엔드포인트 목록 | - |
| ↳ Related Data | 이 화면에 바인딩된 ERD 엔티티 | - |
| ↳ Navigation | 이 화면으로의 진입/이탈 경로 (Screen Flow 참조) | - |
| **Responsive** | 브레이크포인트별 레이아웃 변화 | - |

---

#### 2-6. Screen Flow → `screen-flow.html`

**입력:** `screen-flow.md` + `screen-flow.json`
**교차 참조:** Screens(화면 상세), IA(계층)

**생성할 HTML 섹션:**

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Navigation Map** | 전체 화면 전이 | `flowchart TD` |
| **Journey Flows** | 사용자 여정별 상세 플로우 | `flowchart LR` (per journey) |
| **Transition Rules** | From → To 테이블 (trigger, guard condition, side effect) | - |

---

#### 2-7. RTM → `rtm.html`

**입력:** `rtm.md` + `rtm.json`
**교차 참조:** 전체 (SRS, IA, ERD, API, Screens, TC)

**생성할 HTML 섹션:**

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Traceability Matrix** | FR → US → FT → Screen → API → TC 전체 매핑 테이블 | - |
| **Coverage Dashboard** | FR별 커버리지 % (색상 코딩: 100%=🟢, 50-99%=🟡, <50%=🔴) | `pie` chart |
| **Gaps** | 미매핑 항목 경고 리스트 (severity 배지) | - |
| **Statistics** | 총 FR/US/FT/Screen/TC 수, 커버리지 요약 | bar chart |

---

#### 2-8. Design Token → `design-token.html`

**입력:** `design-token.md` + `design-token.json`

**생성할 HTML 섹션:**

| 섹션 | 내용 |
|------|------|
| **Color Palette** | 컬러 스워치 (hex 미리보기 박스 + 이름 + 용도) |
| **Typography** | 타이포 스케일 (실제 폰트 크기/두께로 렌더링) |
| **Spacing** | 스페이싱 시스템 (실제 크기 박스 시각화) |
| **Design Principles** | 원칙 카드 (Do / Don't) |

---

### ★ Step 3: Generate Wireframe HTML (가장 중요)

**각 SCR-NNN 와이어프레임은 단순 UI 목업이 아니라, 풀 앱 프레임 + 인라인 어노테이션 + 컴포넌트 명세 + 로직 다이어그램이 포함된 종합 설계 문서이다.**

**입력 소스 (교차 참조):**
- `screens.json` → 해당 화면의 components, interactions, states
- `screen-flow.json` → 해당 화면의 진입/이탈 경로, 전이 규칙
- `api.json` → 해당 화면에서 호출하는 API 엔드포인트
- `srs.json` → 해당 화면에 매핑된 Feature(FT)의 비즈니스 로직
- `erd.json` → 해당 화면에 바인딩된 데이터 엔티티
- `ia.json` → 사이드바 메뉴 구조, 화면 계층

---

#### 와이어프레임 HTML 구조 (5개 섹션)

와이어프레임 HTML은 다음 5개 섹션으로 구성된다. **이 순서와 구조를 반드시 따른다.**

**섹션 1: doc-header (상단 고정 바)**

```html
<div class="doc-header">
  <div class="dh-left">
    <span class="sid">S-APP-NNNN</span>          <!-- Screen ID 배지 -->
    <span class="dh-name">화면 제목</span>        <!-- 화면명 -->
    <span class="dh-path">/route/path</span>      <!-- 라우트 경로 -->
  </div>
  <div class="dh-right">
    <a href="index.html">전체 목록</a>            <!-- 인덱스 링크 -->
    <span>FT-XXXX</span>                          <!-- 관련 Feature -->
    <span>FR-XXXX</span>                          <!-- 관련 Requirement -->
    <span>YYYY-MM-DD</span>                       <!-- 생성일 -->
  </div>
</div>
```

**섹션 2: stage (앱 프레임 + 어노테이션 패널)**

```
┌─────────────────────────────────────────┬──────────────────────┐
│  App Frame (실제 앱 UI 모습)              │  어노테이션 패널       │
│  ┌──────────┬─────────────────────┐     │                      │
│  │ Sidebar  │  Page Header        │     │  ① PageTitle         │
│  │ (메뉴)   │  ────────────────   │     │  설명 텍스트...       │
│  │          │  Tabs ③             │     │                      │
│  │          │  Filters ④⑤⑥⑦      │     │  ② CountBadge        │
│  │          │  ────────────────   │     │  설명 텍스트...       │
│  │          │  Table ⑧⑨⑩⑪       │     │                      │
│  │          │  ────────────────   │     │  ③ StatusTab         │
│  │          │  Pagination         │     │  설명 텍스트...       │
│  │          │                     │     │  ...                  │
│  └──────────┴─────────────────────┘     │                      │
│                                          │                      │
└─────────────────────────────────────────┴──────────────────────┘
```

**핵심 규칙:**

1. **App Frame은 실제 앱처럼 렌더링.** IA의 사이드바 메뉴, 페이지 헤더, 탭, 필터, 테이블, 페이지네이션 등 실제 데이터가 포함된 풀 UI를 구성한다.
2. **와이어프레임의 테이블/폼에는 ERD 엔티티의 실제 데이터 필드를 모두 표시한다.** 예: 테이블 컬럼은 `접수번호(id)`, `고객명(customer_name)`, `상태(status)` 등 실제 필드명을 반영. 폼 입력도 `email`, `password`, `name` 등 실제 필드에 대응.
3. **어노테이션 마커 `<span class="mk">N</span>`** 를 UI 요소 옆에 인라인으로 배치한다. 마커 번호는 우측 어노테이션 패널의 설명과 1:1 대응한다.
4. **어노테이션 패널은 Design과 Develop 두 섹션으로 구분한다:**

```html
<div class="anno-panel">
  <div class="anno-title">화면 어노테이션</div>

  <!-- Design 관점 (기획/UX) -->
  <div class="anno-section">
    <div class="anno-section-title" style="color:#8b5cf6">🎨 Design</div>
    <div class="anno-item"><div class="an">1</div><div class="ad">
      <b>PageTitle</b>
      "묘역관리 접수 내역" — 사이드바 활성 항목과 연동. 브레드크럼 표시.
    </div></div>
    <div class="anno-item"><div class="an">3</div><div class="ad">
      <b>StatusTabFilter</b>
      전체/접수완료/견적완료/주문완료/작업완료/진행완료.
      탭 전환 시 필터 값 유지. Empty state: "해당 상태의 접수가 없습니다."
    </div></div>
    <!-- ... 각 마커별 UX/기획 관점 설명 -->
  </div>

  <!-- Develop 관점 (개발) -->
  <div class="anno-section">
    <div class="anno-section-title" style="color:#0891b2">🔧 Develop</div>
    <div class="anno-item"><div class="an">3</div><div class="ad">
      <b>StatusTabFilter</b>
      <code>query param: status</code> | enum: received, quoted, ordered, work_completed, completed
      상태 변경 시 <code>GET /v1/orders?status={value}</code> 재호출. Debounce 불필요 (탭 클릭).
    </div></div>
    <div class="anno-item"><div class="an">7</div><div class="ad">
      <b>SearchButton</b>
      <code>GET /v1/cemetery-care/orders?status=&workType=&q=&startDate=&endDate=&page=1&size=20</code>
      Response: <code>{ data: Order[], total: number, page: number }</code>
      Error 처리: 네트워크 에러 → 토스트, 빈 결과 → Empty state 컴포넌트.
    </div></div>
    <!-- ... 각 마커별 개발 관점 설명 (API 상세, 데이터 타입, 에러 처리, 상태 관리) -->
  </div>

  <!-- 비즈니스 규칙 (해당 시에만) -->
  <div class="br-section">
    <div class="br-title">비즈니스 규칙</div>
    <div class="br-item">상태 탭 전환 시 기간/검색어 필터 값 유지</div>
  </div>
</div>
```

**Design 섹션에 포함할 내용:**
- 화면 목적, 사용자 시나리오
- 컴포넌트 동작 설명 (사용자 관점)
- UX 규칙 (빈 상태, 로딩, 에러 표시 방식)
- 접근성 요구사항
- 반응형 동작

**Develop 섹션에 포함할 내용:**
- API 엔드포인트 + 파라미터 + 응답 스키마
- 데이터 타입, enum 값
- 상태 관리 방식 (Zustand/Redux store key)
- 에러 처리 로직 (HTTP status별)
- 캐싱 전략 (TanStack Query key)
- DB 쿼리 힌트 (인덱스, 정렬)

**Grid Layout:** `grid-template-columns: 1fr 300px`

**섹션 3: 컴포넌트 명세 테이블 (spec-wrap)**

```html
<div class="spec-wrap">
  <div class="spec-title">컴포넌트 명세</div>
  <table class="spec-tbl">
    <thead><tr><th>#</th><th>컴포넌트</th><th>타입</th><th>Props / 설명</th><th>Validation</th><th>API</th></tr></thead>
    <tbody>
      <tr><td>1</td><td>PageTitle</td><td>Layout</td><td>title="화면제목"</td><td>-</td><td>-</td></tr>
      <tr><td>2</td><td>EmailInput</td><td>Input</td><td>placeholder="이메일" | required</td><td>email 형식 | 최대 255자</td><td>-</td></tr>
      <tr><td>3</td><td>PasswordInput</td><td>Input</td><td>type=password | required</td><td>최소 8자 | 영문+숫자+특수문자</td><td>-</td></tr>
      <tr><td>4</td><td>LoginButton</td><td>Action</td><td>variant=primary | disabled: form invalid</td><td>전체 form valid 시 활성화</td><td>POST /v1/auth/login</td></tr>
    </tbody>
  </table>
</div>
```

각 컴포넌트에 대해:
- `#`: 어노테이션 마커 번호
- `컴포넌트`: 컴포넌트명 (PascalCase)
- `타입`: Layout / Display / Input / Filter / Action / Navigation 중 택 1
- `Props / 설명`: 주요 props, placeholder, 기본값, 동작 설명
- `Validation`: Input/Filter 타입의 유효성 검증 규칙. 형식, 최소/최대 길이, 필수 여부, 정규식 패턴 등. 해당 없으면 `-`
- `API`: 이 컴포넌트가 트리거하는 API 엔드포인트 (없으면 `-`)

**섹션 3-2: 버튼 액션 상세 테이블**

```html
<div class="spec-wrap">
  <div class="spec-title">버튼 액션 상세</div>
  <table class="spec-tbl">
    <thead><tr><th>버튼</th><th>트리거</th><th>API 호출</th><th>성공 시</th><th>실패 시</th></tr></thead>
    <tbody>
      <tr>
        <td>로그인</td><td>click</td>
        <td><code>POST /v1/auth/login</code></td>
        <td>→ SCR-002 Dashboard 이동, 토큰 저장</td>
        <td>→ 에러 토스트 표시 ("이메일 또는 비밀번호 확인")</td>
      </tr>
      <tr>
        <td>소셜 로그인 (Google)</td><td>click</td>
        <td><code>GET /v1/auth/google</code></td>
        <td>→ OAuth 팝업 → 콜백 → SCR-002</td>
        <td>→ 에러 모달 표시</td>
      </tr>
    </tbody>
  </table>
</div>
```

**섹션 3-3: 팝업 & 모달 와이어프레임**

팝업과 모달은 테이블이 아닌 **실제 와이어프레임 목업**으로 작성한다. 각 팝업/모달에 대해 메인 화면과 동일한 수준의 UI를 구성한다.

```html
<div class="spec-wrap">
  <div class="spec-title">팝업 & 모달</div>

  <!-- 모달 1: 로그인 실패 -->
  <div style="margin:16px 0;padding:16px;border:2px solid #e2e8f0;border-radius:12px;background:#fff">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
      <strong style="font-size:13px">⚠️ 로그인 실패 모달</strong>
      <span style="font-size:10px;color:#64748b;background:#f1f5f9;padding:2px 8px;border-radius:4px">트리거: 401 응답</span>
    </div>
    <!-- 모달 와이어프레임 -->
    <div style="max-width:360px;margin:0 auto;background:#fff;border:1px solid #d1d9e0;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,.15);overflow:hidden">
      <div style="padding:20px 24px;text-align:center">
        <div style="font-size:32px;margin-bottom:8px">⚠️</div>
        <div style="font-weight:700;font-size:15px;margin-bottom:6px">로그인 실패</div>
        <div style="font-size:13px;color:#64748b">이메일 또는 비밀번호가 올바르지 않습니다.</div>
      </div>
      <div style="padding:12px 24px 20px;text-align:center">
        <span style="display:inline-block;padding:8px 32px;background:#0891b2;color:#fff;border-radius:6px;font-size:13px;font-weight:700">확인</span>
      </div>
    </div>
    <!-- 어노테이션 -->
    <div style="margin-top:12px;font-size:11px;color:#64748b;display:grid;grid-template-columns:1fr 1fr;gap:8px">
      <div><b style="color:#8b5cf6">🎨 Design:</b> [확인] 클릭 시 이메일 입력에 포커스. 흔들림 애니메이션 추가 권장.</div>
      <div><b style="color:#0891b2">🔧 Develop:</b> HTTP 401 응답 시 표시. 5회 연속 실패 시 → 계정 잠금 모달로 전환 (429).</div>
    </div>
  </div>

  <!-- 모달 2: 확인 다이얼로그, 로딩 오버레이 등도 동일 패턴 -->
</div>
```

**팝업/모달 와이어프레임 규칙:**
1. 각 팝업/모달을 **실제 UI 모습**으로 렌더링 (border + shadow + 내용 + 버튼)
2. 트리거 조건 배지를 우상단에 표시
3. 와이어프레임 아래에 **Design/Develop 어노테이션**을 그리드로 표시
4. 폼이 포함된 모달은 **ERD 필드와 매핑된 입력 필드**를 모두 표시
5. 확인/취소 버튼의 후속 동작을 명시

**섹션 3-1: 유사 화면 대비 차이점 테이블 (선택 — 비슷한 화면이 있을 때만)**

```html
<div class="spec-wrap">
  <div class="spec-title">{유사화면 ID} 대비 차이점</div>
  <table class="spec-tbl">
    <thead><tr><th>컴포넌트</th><th>차이 내용</th><th>API</th></tr></thead>
    <tbody>
      <tr><td>WorkTypeSelect</td><td>추가 필터: 봉분정비/석물보수/...</td><td>query param: workType</td></tr>
    </tbody>
  </table>
</div>
```

**섹션 4: 로직 흐름 다이어그램 (diagrams-section)**

SVG 다이어그램으로 화면의 로직 흐름을 시각화한다. **Mermaid가 아닌 인라인 SVG로 직접 그린다.**

**다이어그램 표시 규칙:**
- **축소 상태가 기본.** 각 다이어그램은 `max-height: 280px; overflow: hidden`으로 축소 표시한다.
- **확대 버튼 🔍** 을 다이어그램 우상단에 배치. 클릭 시 모달 오버레이로 전체 크기 표시.
- 모달은 `position: fixed; inset: 0; background: rgba(0,0,0,.6); z-index: 200`으로 배경 딤 처리.
- 모달 내 SVG는 `max-width: 95vw; max-height: 90vh`로 제한, 닫기 버튼(✕) 우상단.

```html
<!-- 다이어그램 블록 패턴 -->
<div class="diag-block">
  <h3>A. Condition Flow Chart</h3>
  <div class="diag-container" style="max-height:280px;overflow:hidden;position:relative">
    <button class="diag-zoom" onclick="openDiagModal(this)" title="확대">🔍</button>
    <svg class="diag" viewBox="0 0 820 460"><!-- ... --></svg>
  </div>
</div>

<style>
.diag-container { position: relative; border: 1px solid #e2e8f0; border-radius: 8px; background: #f8fafc; }
.diag-zoom { position: absolute; top: 8px; right: 8px; z-index: 5; background: #fff; border: 1px solid #d1d9e0; border-radius: 6px; width: 32px; height: 32px; cursor: pointer; font-size: 16px; display: flex; align-items: center; justify-content: center; }
.diag-zoom:hover { background: #f1f5f9; }
.diag-modal { position: fixed; inset: 0; background: rgba(0,0,0,.6); z-index: 200; display: flex; align-items: center; justify-content: center; }
.diag-modal svg { max-width: 95vw; max-height: 90vh; background: #fff; border-radius: 12px; padding: 16px; }
.diag-modal-close { position: fixed; top: 16px; right: 24px; z-index: 210; background: #fff; border: none; width: 36px; height: 36px; border-radius: 50%; font-size: 18px; cursor: pointer; }
</style>

<script>
function openDiagModal(btn) {
  const svg = btn.parentElement.querySelector('svg').cloneNode(true);
  svg.style.maxWidth = '95vw'; svg.style.maxHeight = '90vh';
  const modal = document.createElement('div');
  modal.className = 'diag-modal';
  modal.onclick = () => modal.remove();
  const close = document.createElement('button');
  close.className = 'diag-modal-close'; close.textContent = '✕';
  close.onclick = () => modal.remove();
  modal.appendChild(close);
  modal.appendChild(svg);
  document.body.appendChild(modal);
}
</script>
```

3가지 다이어그램을 생성한다:

**A. Condition Flow Chart — 조건 분기 흐름**

화면 진입부터 데이터 표시까지의 조건 분기를 시각화:
- 시작(둥근 사각형, 청록) → 기본 파라미터 설정(사각형, 하늘) → API 호출(사각형, 초록) → 결과 분기(마름모, 노랑) → 렌더링/Empty State
- 필터 변경 시 API 재호출 루프

**SVG 스타일 규칙:**
| 요소 | 색상 | 용도 |
|---|---|---|
| 시작/종료 노드 | `#0891b2` (청록) | 진입/종료점 |
| 프로세스 노드 | `#e0f2fe` stroke `#38bdf8` | 기본 처리 단계 |
| API 호출 노드 | `#10b981` (초록) | API 요청 |
| 분기 다이아몬드 | `#f59e0b` (노랑) | 조건 판단 |
| 에러/Empty | `#fee2e2` stroke `#f87171` | 실패/빈 상태 |
| 화살표 | `#6b7280` | 흐름 연결 |

**B. Sequential Diagram — 시퀀스 다이어그램**

사용자 → 프론트엔드 → Backend API → DB 간의 상호작용 시퀀스:
- 4개 actor 라이프라인: 사용자(보라) / 프론트엔드(파랑) / Backend(초록) / DB(노랑)
- 화면 진입 → 기본 조회 → 응답 → 렌더링 → 필터 변경 → 재조회 흐름
- 실선 화살표(요청), 점선 화살표(응답)

**C. Data Flow Diagram — 데이터 흐름**

화면의 상태 관리와 데이터 흐름을 시각화:
- 외부 엔티티(사각형): 사용자, DB
- 프로세스(원): 페이지 컴포넌트, Backend API
- 데이터 스토어(양쪽 열린 사각형): 상태 관리(Zustand/Redux), API 캐시(TanStack Query)
- 화살표로 데이터 흐름 방향 표시

**섹션 5: 데이터 모델 (data-model-section)**

이 화면에서 사용하는 ERD 엔티티의 상세 필드 정보를 표시한다.

```html
<div class="spec-wrap">
  <div class="spec-title">데이터 모델 — {EntityName}</div>
  <table class="spec-tbl">
    <thead><tr><th>필드명</th><th>타입</th><th>제약조건</th><th>UI 매핑</th><th>설명</th></tr></thead>
    <tbody>
      <tr><td><code>id</code></td><td>int</td><td>PK, AUTO_INCREMENT</td><td>-</td><td>고유 식별자</td></tr>
      <tr><td><code>email</code></td><td>varchar(255)</td><td>UK, NOT NULL</td><td>① EmailInput</td><td>로그인 이메일</td></tr>
      <tr><td><code>password</code></td><td>varchar(255)</td><td>NOT NULL</td><td>② PasswordInput</td><td>bcrypt 해시</td></tr>
      <tr><td><code>name</code></td><td>varchar(100)</td><td>NOT NULL</td><td>프로필 표시</td><td>사용자 이름</td></tr>
      <tr><td><code>status</code></td><td>enum</td><td>DEFAULT 'active'</td><td>⑩ StatusBadge</td><td>active/inactive/locked</td></tr>
      <tr><td><code>created_at</code></td><td>datetime</td><td>DEFAULT NOW()</td><td>테이블 컬럼</td><td>가입일시</td></tr>
    </tbody>
  </table>
</div>
```

각 엔티티에 대해:
- `필드명`: ERD의 column name
- `타입`: DB 타입 (varchar, int, datetime, enum 등)
- `제약조건`: PK, FK, UK, NOT NULL, DEFAULT 등
- `UI 매핑`: 이 필드가 와이어프레임의 어떤 컴포넌트(마커 번호)에 표시되는지
- `설명`: 필드 용도

**여러 엔티티가 사용되는 경우** 각 엔티티별로 테이블을 반복한다. 엔티티 간 FK 관계도 표시.

---

#### 와이어프레임 생성 알고리즘

각 `SCR-NNN`에 대해:

1. **Screen Info** — `screens.json`에서 id, name, route, description, tracedFrom 추출
2. **Data Fields 수집** — `erd.json`에서 이 화면이 사용하는 엔티티의 **모든 필드**를 추출. 테이블 컬럼, 폼 입력, 상세 표시에 사용할 필드 목록을 확정.
3. **App Sidebar** — `ia.json`의 `siteMap`에서 사이드바 메뉴 구조 생성. 현재 화면에 `.active` 클래스 적용
4. **Page Body** — `screens.json`의 `components` 배열 + ERD 필드를 조합하여 실제 UI 요소 생성:
   - type=table → `<table>` — **ERD 엔티티의 모든 표시 가능 필드를 컬럼으로 포함** (3~5행의 샘플 데이터). 컬럼 헤더에 `필드 라벨 (field_name)` 형식 표시.
   - type=input → `<input>` — **ERD 필드의 타입/제약조건 반영** (varchar→text, enum→select, date→datepicker). placeholder에 필드명 표시.
   - type=button → `<button>`
   - type=card → `<div>` 카드 — 카드 내 ERD 필드들을 라벨+값으로 나열
   - 각 요소 옆에 `<span class="mk">N</span>` 어노테이션 마커 배치
5. **Annotation Panel (Design / Develop 분리):**
   - **🎨 Design 섹션**: 각 마커별 UX/기획 관점 (화면 목적, 사용자 시나리오, Empty/Loading/Error 상태, 접근성)
   - **🔧 Develop 섹션**: 각 마커별 개발 관점 (API endpoint + params + response, enum 값, 상태 관리, 에러 처리, 캐싱)
   - **비즈니스 규칙** (해당 시에만)
6. **Component Spec Table** — 모든 컴포넌트를 마커 번호 순서대로 테이블 작성. **Validation 컬럼 포함**
7. **Button Action Table** — Action/Navigation 타입 컴포넌트의 트리거, API 호출, 성공/실패 시 동작 상세
8. **Popup & Modal 와이어프레임** — 화면에서 발생하는 모든 팝업/모달을 **실제 UI 와이어프레임 목업**으로 작성. 각 팝업 아래에 Design/Develop 어노테이션 포함. 폼 모달은 ERD 필드 매핑 입력 포함.
9. **Data Model Table** — 이 화면이 사용하는 ERD 엔티티별로 (필드명, 타입, 제약조건, UI 매핑 마커, 설명) 테이블 작성
10. **Diagrams** — 3가지 SVG 다이어그램 (축소 + 🔍 확대 모달)

**어노테이션 마커 CSS:**

```css
.mk { display:inline-flex; align-items:center; justify-content:center;
      width:17px; height:17px; background:#2563eb; color:#fff;
      border-radius:50%; font-size:9px; font-weight:700; }
```

---

### Step 4: Generate index.html (Main Viewer)

모든 파일 변환이 끝난 후, sidebar 파일 트리를 구성하여 index.html을 생성한다.

**FILES 배열 구성:**

```javascript
const FILES = [
  { path: "hjw/01-plan/srs.html", type: "doc", name: "SRS", dir: "hjw/01-plan", icon: "📋", docType: "srs" },
  { path: "hjw/01-plan/ia.html", type: "doc", name: "IA", dir: "hjw/01-plan", icon: "🗺️", docType: "ia" },
  { path: "hjw/02-design/erd.html", type: "doc", name: "ERD", dir: "hjw/02-design", icon: "🗃️", docType: "erd" },
  { path: "hjw/02-design/api.html", type: "doc", name: "API", dir: "hjw/02-design", icon: "🔌", docType: "api" },
  { path: "hjw/02-design/screens.html", type: "doc", name: "Screens", dir: "hjw/02-design", icon: "📱", docType: "screens" },
  { path: "hjw/02-design/screen-flow.html", type: "doc", name: "Screen Flow", dir: "hjw/02-design", icon: "🔀", docType: "screen-flow" },
  { path: "hjw/02-design/rtm.html", type: "doc", name: "RTM", dir: "hjw/02-design", icon: "📊", docType: "rtm" },
  { path: "hjw/02-design/wireframes/SCR-001.html", type: "wireframe", name: "SCR-001: 로그인", dir: "hjw/02-design/wireframes", icon: "🖼️" },
  { path: "hjw/02-design/wireframes/SCR-002.html", type: "wireframe", name: "SCR-002: 대시보드", dir: "hjw/02-design/wireframes", icon: "🖼️" },
  // ...
];
```

**INDEX_TEMPLATE:**

index.html은 이전 버전과 동일한 구조이되, `buildTree` 함수를 아래처럼 수정:

```javascript
// Build tree — 반드시 이 로직 사용
function buildTree() {
  const tree = { __files: [] };
  FILES.forEach(f => {
    const parts = f.dir.split('/').filter(Boolean);
    let node = tree;
    parts.forEach(p => {
      if (!node[p]) node[p] = { __files: [] };
      node = node[p];
    });
    node.__files.push(f);
  });
  return tree;
}
```

sidebar 파일 항목에 `icon` 필드를 반영하고, wireframe 항목은 🖼️ 아이콘으로 구분:

```javascript
const a = document.createElement('a');
a.className = 'tree-file';
a.innerHTML = '<span class="icon">' + f.icon + '</span> ' + f.name;
```

### Step 5: Verify & Open

```bash
find .u-maker/_browse -name "*.html" | wc -l
```

`--open` 플래그:
```bash
open .u-maker/_browse/index.html
```

---

## ★ CRITICAL IMPLEMENTATION RULES

1. **반드시 모든 컨텍스트를 먼저 로드.** Step 0에서 scope의 모든 .md/.json을 읽은 후에야 HTML 생성을 시작한다.
2. **교차 참조 필수.** 각 문서 HTML에는 다른 문서의 관련 정보가 반드시 포함되어야 한다.
3. **다이어그램 자동 생성.** JSON 데이터를 분석하여 Mermaid 코드를 자동 생성한다. 원본 .md의 다이어그램을 복사하는 것이 아니다.
4. **와이어프레임은 리치 문서.** 단순 UI 목업이 아니라, 어노테이션·액션·흐름·로직·팝업·엔티티가 포함된 종합 문서를 생성한다.
5. **Write 도구로 실제 파일 생성.** 분석이나 설명만으로 끝내지 않는다.
6. **병렬 처리.** 독립적인 파일 변환은 여러 Write 호출을 동시에 수행한다.
7. **소스 문서 READ-ONLY.** 원본 .md/.json을 절대 수정하지 않는다.
8. **`_browse/` 디렉토리만 쓰기.** 다른 경로에 파일을 생성하지 않는다.

---

## Safety Rules

1. **소스 문서 무수정:** `.md` / `.json` / `.html` 파일은 읽기만 수행 (READ-ONLY)
2. **`_browse/` 디렉토리만 쓰기:** 생성 파일은 `.u-maker/_browse/` 하위에만 생성
3. **인라인 리소스:** 외부 의존성 없는 단일 HTML (Mermaid.js CDN만 예외)
4. **민감 정보 제외:** `.env` 값, 하드코딩 시크릿은 변환에 포함하지 않음
5. **기존 파일 덮어쓰기:** 기존 `_browse/`는 경고 없이 덮어쓰기 (스냅샷 개념)
6. **독립 실행 가능:** 각 개별 HTML은 index.html 없이도 단독으로 열람 가능해야 함
