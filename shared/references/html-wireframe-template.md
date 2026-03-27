# HTML Wireframe Template

> 화면 와이어프레임 HTML 생성 표준. **UI 레이아웃은 HTML/CSS div 기반 app-frame**으로 렌더링한다.
> 좌측 sidebar 네비게이션 + 우측 main 영역(pg-hdr + pg-body)으로 실제 앱 화면을 재현하고,
> **우측 Annotation Panel**에 번호 어노테이션 + 비즈니스 룰을 표시한다.
> 각 어노테이션은 **Design 탭**과 **Dev 탭** 2-탭 구조로 디자인 설명과 개발 스펙을 아코디언 카드로 제공한다.
> 하단에 **컴포넌트 명세 테이블**과 **Condition Flow Chart, Sequential Diagram, UML Diagram** 등 다이어그램을 포함한다.
> 와이어프레임 디렉토리에 `index.html`(Grid/List 뷰 + 검색 + 도메인별 그룹핑)을 생성하여 전체 화면을 탐색할 수 있도록 한다.

---

## 1. 적용 규칙

| 조건 | 규칙 |
|------|------|
| **적용 대상** | 화면별 와이어프레임 HTML (`S-NNNN.html`) + 인덱스 (`index.html`) |
| **파일 경로** | `.u-maker/docs/{app}/02-design/2_Screen_Wireframes/` |
| **생성 시점** | `/u-skill-wireframe` 실행 시 |
| **문서 언어** | `u-maker.config.json`의 `documentLanguage` 값에 따라 결정 |
| **단일 파일** | 각 HTML은 외부 의존성 없이 단일 파일로 완결 (Pretendard CDN만 허용) |
| **외부 링크** | 와이어프레임 내부 링크(`S-NNNN.html`, `index.html`)를 제외한 모든 외부 URL은 `target="_blank" rel="noopener noreferrer"` 필수 |

### 링크 규칙

| 링크 유형 | 예시 | 처리 |
|----------|------|------|
| **내부 화면 이동** | `S-0020.html`, `index.html` | 동일 탭에서 이동 (기본) |
| **외부 URL** | `https://...`, `http://...`, 프로젝트 외부 리소스 | `target="_blank" rel="noopener noreferrer"` 추가 — 새 브라우저 탭에서 열림 |
| **앵커 링크** | `#section-id` | 동일 페이지 내 스크롤 (기본) |

```html
<!-- 내부 링크: 동일 탭 -->
<a href="S-0020.html">S-0020 회원가입</a>
<a href="index.html" class="back-link">← All Screens</a>

<!-- 외부 링크: 새 탭에서 열림 -->
<a href="https://example.com/docs" target="_blank" rel="noopener noreferrer">API 문서 ↗</a>
```

### 파일 구조

```
.u-maker/docs/{app}/02-design/2_Screen_Wireframes/
├── index.html          ← Navigation Page (Grid/List 뷰 + 검색 + 도메인별 그룹핑)
├── index.json          ← 동명 JSON
├── S-0010.html         ← 개별 화면 와이어프레임 (app-frame + anno-panel + 다이어그램)
├── S-0010.json         ← 동명 JSON
├── S-0100.html         ← 부모 화면 (Tab 네비게이션 포함)
├── S-0100-T1.html      ← 탭 1 화면
├── S-0100-T2.html      ← 탭 2 화면
├── S-0100.json
├── S-0100-T1.json
├── S-0100-T2.json
└── ...
```

---

## 2. 어노테이션 시스템

### 2.1 숫자 마커 (Annotation Marker) — 원형 숫자 배지

**거의 모든 UI 요소**에 숫자 마커를 부착한다. 마커는 해당 요소의 우상단에 원형 배지(① ② ③)로 배치한다.

#### 마커 부착 대상 기준

| 부착 대상 (필수) | 예시 |
|-----------------|------|
| **모든 인터랙티브 요소** | Button, Input, Select, Textarea, Checkbox, Radio, Toggle, Link, Tab, Stepper, File Upload, Search |
| **모든 데이터 표시 요소** | Card, Badge, Tag, Table, List, Chart, Graph, Stat, Progress Bar, Avatar |
| **모든 네비게이션 요소** | Header, Nav, Sidebar, Breadcrumb, Pagination, Footer, Menu |
| **모든 피드백 요소** | Toast, Alert, Modal, Dialog, Confirm, Tooltip, Empty State, Loading |
| **모든 컨텐츠 영역** | Form (전체), Section (의미 있는), Banner, Hero, Panel |
| **정책/비즈니스 룰 관련 영역** | 권한 분기, 상태 분기, 조건부 표시/숨김 영역 |

| 부착 제외 (선택) | 예시 |
|-----------------|------|
| 순수 레이아웃 컨테이너 | 빈 wrapper div, spacer, grid/flex 컨테이너 |
| 반복 항목의 개별 인스턴스 | 리스트의 개별 row (리스트 자체에는 부착) |

> **원칙: 누락보다 과잉이 낫다.** 어노테이션이 충분하지 않으면 개발 시 누락이 발생한다.
> 화면 내 모든 의미 있는 요소에 Description을 작성하는 것을 기본으로 한다.

```html
<!-- 어노테이션 마커: UI 요소 내에 인라인 배치 -->
<div class="filter-card" style="position:relative">
  <div class="ptab active">월별</div>
  <div class="ptab">분기별</div>
  <!-- 어노테이션 마커: 요소 우상단에 원형 배지 -->
  <span class="an" style="position:absolute;top:-6px;right:-6px" data-target="annotation-1">①</span>
</div>
```

마커는 원형 숫자 배지(①②③...)로 렌더링한다. `.an` 클래스를 사용하며 숫자가 20을 초과해도 제한 없이 표시 가능하다.
app-frame 내 UI 요소의 우상단에 `position:absolute`로 배치하거나, 인라인으로 요소 옆에 배치한다.

```html
<!-- 마커 예시: 다양한 번호 -->
<span class="an" data-target="annotation-1">①</span>
<span class="an" data-target="annotation-15">⑮</span>
<span class="an" data-target="annotation-42">42</span>  <!-- 20 초과 시 숫자로 -->
```

### 2.2 어노테이션 시스템 — anno-panel + 아코디언 카드

**우측 Annotation Panel**(280px)에 해당 화면의 **전체 어노테이션**을 나열한다.
stage 영역의 CSS grid(`1fr 280px`)로 app-frame과 나란히 배치된다.

- anno-panel 상단에 제목("Annotations") + 마커 번호(①②③) + 설명 나열
- 하단에 비즈니스 룰 섹션(br-section) 배치
- 각 어노테이션은 **아코디언 카드**로 나열되며, 클릭하면 확장(expand)
- 확장된 카드 내부에 **Design 탭**과 **Dev 탭** 2개 탭
- **Design 탭**: 설명(Description), 요구사항, 비즈니스 룰/정책, 상태, 연결 화면 (기획/디자인 관점)
- **Dev 탭**: 동작방식, 흐름도, 옵션값, Validation, API, 이벤트, 데이터 바인딩 (개발 관점)
- 마커 클릭 시 해당 카드로 스크롤 + 자동 확장
- **Expand All / Collapse All** 버튼 제공

#### Description 작성 포맷

Description은 스크린샷 예시처럼 **`[컴포넌트타입]` + 항목 이름** 형태의 헤더와 **들여쓰기된 조건/정책** 목록으로 구성한다.

| 번호 | 포맷 | 예시 |
|------|------|------|
| 공통 | `[정책]` + 비즈니스 룰 목록 | 삭제 정책, 유효기간, 작성 개수 제한 |
| 번호 | `[Button]` / `[Card]` / `[Badge]` / `[Confirm]` / `[Input]` / `[Select]` / `[List]` 등 + 상세 | 상태, 조건, 노출 문구 |

```
Description 작성 규칙:
- 항목별로 bullet(•)을 사용하고, 하위 조건은 > 로 들여쓴다
- 정책/비즈니스 룰은 빨간 강조 텍스트로 표시 (.desc-policy)
- 노출 문구는 따옴표로 감싼다: '해당 부고는 발인 되었습니다.'
- 비고(Note) 컬럼이 있으면 하단에 표시
```

```html
<!-- ===== Annotation Sidebar: body 하단, 전체 어노테이션을 아코디언 카드로 나열 ===== -->
<aside class="annotation-sidebar" id="annotationSidebar">
  <div class="sidebar-header">
    <h3 class="sidebar-title">Annotations</h3>
    <div class="sidebar-actions">
      <button class="sidebar-btn" onclick="expandAllCards()" title="Expand All">&#9660; All</button>
      <button class="sidebar-btn" onclick="collapseAllCards()" title="Collapse All">&#9650; All</button>
      <button class="sidebar-close" onclick="toggleSidebar()" title="Close Sidebar">&times;</button>
    </div>
  </div>
  <div class="sidebar-body" id="sidebarBody">

    <!-- ===== Annotation Card #1 ===== -->
    <div class="annotation-card" id="annotation-1" data-annotation="1">
      <div class="card-header" onclick="toggleCard(this)">
        <span class="card-number">1</span>
        <span class="card-title">이메일 입력 필드</span>
        <span class="card-chevron">&#9660;</span>
      </div>
      <div class="card-body">
        <!-- Tab Navigation -->
        <div class="card-tabs">
          <button class="card-tab active" onclick="switchTab(this,'design')">Design</button>
          <button class="card-tab" onclick="switchTab(this,'dev')">Dev</button>
        </div>

        <!-- ===== Design Tab ===== -->
        <div class="card-tab-content tab-content active" data-tab="design">
          <!-- Description (공통 정책) -->
          <div class="desc-block">
            <div class="desc-header">[정책]</div>
            <ul class="desc-list">
              <li>사용자는 부고장 삭제 가능
                <ul class="desc-sub">
                  <li>사용자 생성 부고장 삭제 가능</li>
                  <li>대표 부고장 삭제 가능(삭제 시 경고 알림)</li>
                </ul>
              </li>
              <li>1인당 작성 개수
                <ul class="desc-sub">
                  <li>사용자는 부고장 10개까지 생성 가능</li>
                  <li>1인당 작성 개수 초과 시, 기존 부고장 삭제 후 추가 생성</li>
                </ul>
              </li>
            </ul>
          </div>

          <!-- 관련 요구사항 -->
          <div class="card-section">
            <h5>요구사항</h5>
            <ul class="card-tags">
              <li><span class="card-tag tag-fr">FR-0010</span> 사용자 인증</li>
              <li><span class="card-tag tag-ft">FT-0010</span> 이메일 로그인</li>
            </ul>
          </div>

          <!-- 연결 화면 -->
          <div class="card-section">
            <h5>연결 화면</h5>
            <ul class="card-links">
              <li><a href="S-0020.html">S-0020 회원가입</a> — "회원가입" 링크 클릭 시</li>
            </ul>
          </div>
        </div>

        <!-- ===== Dev Tab ===== -->
        <div class="card-tab-content tab-content" data-tab="dev">
          <!-- 동작방식 -->
          <div class="card-section">
            <h5>동작방식</h5>
            <table class="card-table">
              <tr><td class="state-label">Type</td><td><code>input[type="email"]</code></td></tr>
              <tr><td class="state-label">Component</td><td><code>EmailInput</code> (atoms/input)</td></tr>
              <tr><td class="state-label">Debounce</td><td>300ms (중복 검사 시)</td></tr>
            </table>
          </div>

          <!-- Validation -->
          <div class="card-section">
            <h5>Validation</h5>
            <table class="dev-validation-table">
              <thead><tr><th>Rule</th><th>조건</th><th>에러 메시지</th></tr></thead>
              <tbody>
                <tr>
                  <td><span class="dev-badge badge-required">required</span></td>
                  <td>빈 값</td>
                  <td><code>"이메일을 입력해주세요"</code></td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- 흐름도 -->
          <div class="card-section">
            <h5>흐름도</h5>
            <div class="dev-flow-diagram">
              <div class="dev-flow-row">
                <span class="dev-flow-node">사용자 입력</span>
                <span class="dev-flow-arrow">→</span>
                <span class="dev-flow-node">onChange: 실시간 형식 검증</span>
              </div>
              <div class="dev-flow-row"><span class="dev-flow-arrow">↓</span></div>
              <div class="dev-flow-row">
                <span class="dev-flow-node dev-flow-decision">Valid?</span>
                <span class="dev-flow-arrow">Yes →</span>
                <span class="dev-flow-node dev-flow-success">에러 해제</span>
              </div>
            </div>
          </div>

          <!-- API -->
          <div class="card-section">
            <h5>API</h5>
            <div class="dev-api-card">
              <span class="dev-method method-post">POST</span>
              <code class="dev-endpoint">/api/v1/auth/login</code>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- ===== /Annotation Card #1 ===== -->

    <!-- ===== Annotation Card #2 (반복) ===== -->
    <div class="annotation-card" id="annotation-2" data-annotation="2">
      <div class="card-header" onclick="toggleCard(this)">
        <span class="card-number">2</span>
        <span class="card-title">비밀번호 입력 필드</span>
        <span class="card-chevron">&#9660;</span>
      </div>
      <div class="card-body">
        <!-- ... Design/Dev 탭 동일 구조 반복 ... -->
      </div>
    </div>
    <!-- 이하 모든 어노테이션 카드 반복 -->

  </div>
</aside>
```

#### 번호별 Description 예시 (스크린샷 참고)

```html
<!-- #1 [Button] 부고장 공유 -->
<div class="desc-block">
  <div class="desc-header">[Button] 부고장 공유</div>
  <ul class="desc-list">
    <li>상태 : 비활성</li>
    <li>부고장 유효기간 만료 시 버튼 비활성
      <ul class="desc-sub">
        <li>발인 당일에 발인 시간 초과 시 유효기간 종료</li>
      </ul>
    </li>
  </ul>
  <div class="desc-note">비고</div>
</div>

<!-- #2 [Card] 부고장 -->
<div class="desc-block">
  <div class="desc-header">[Card] 부고장</div>
  <ul class="desc-list">
    <li>고객센터에서 생성한 부고장</li>
    <li class="desc-policy">정책 : 고객센터에서 생성한 부고장은 부고장 보유 개수 정책의 영향을 받지 않음</li>
  </ul>
  <div class="desc-note">비고</div>
</div>

<!-- #3 [Badge] 고객센터 생성 -->
<div class="desc-block">
  <div class="desc-header">[Badge] 고객센터 생성</div>
  <ul class="desc-list">
    <li>고객센터에서 생성한 부고장에 Badge 부여</li>
  </ul>
  <div class="desc-note">비고</div>
</div>

<!-- #4 [Badge] 대표 -->
<div class="desc-block">
  <div class="desc-header">[Badge] 대표</div>
  <ul class="desc-list">
    <li>FSMS 통해 대표 부고장 선정 됨</li>
    <li>'대표' 선정 가능한 부고장 종류
      <ul class="desc-sub">
        <li>사용자 생성 부고장</li>
        <li>고객센터 생성 부고장</li>
      </ul>
    </li>
  </ul>
  <div class="desc-note">비고</div>
</div>

<!-- #5 [Confirm] 삭제 확인 -->
<div class="desc-block">
  <div class="desc-header">[Confirm]</div>
  <ul class="desc-list">
    <li>대표 부고장 삭제 시도시 호출</li>
    <li>버튼 정의
      <ul class="desc-sub">
        <li>(취소) Confirm 창 닫힘</li>
        <li>(확인) 부고장 삭제</li>
      </ul>
    </li>
  </ul>
  <div class="desc-note">비고</div>
</div>
```

#### Select/Dropdown 요소 예시 (Dev 탭 — 옵션값 포함)

```html
<!-- Dev 탭 내: Select 옵션값 섹션 -->
<div class="card-section">
  <h5>옵션값</h5>
  <table class="dev-options-table">
    <thead><tr><th>Value</th><th>Label</th><th>조건</th></tr></thead>
    <tbody>
      <tr><td><code>""</code></td><td class="opt-placeholder">선택하세요</td><td>기본값 (disabled)</td></tr>
      <tr><td><code>"admin"</code></td><td>관리자</td><td>superAdmin 권한 필요</td></tr>
      <tr><td><code>"manager"</code></td><td>매니저</td><td>—</td></tr>
      <tr><td><code>"user"</code></td><td>일반 사용자</td><td>—</td></tr>
      <tr><td><code>"viewer"</code></td><td>뷰어 (읽기 전용)</td><td>—</td></tr>
    </tbody>
  </table>
  <div class="dev-note">
    <strong>Data Source:</strong> <code>GET /api/v1/roles</code> — 서버에서 동적 로드. 위 목록은 기본값이며 서버 응답으로 대체된다.
  </div>
</div>

<!-- Dev 탭 내: Select 동작방식 -->
<div class="card-section">
  <h5>동작방식</h5>
  <table class="card-table">
    <tr><td class="state-label">Component</td><td><code>RoleSelect</code> (molecules/select)</td></tr>
    <tr><td class="state-label">Multi-select</td><td>No (단일 선택)</td></tr>
    <tr><td class="state-label">Searchable</td><td>Yes (5개 이상 시 검색 활성화)</td></tr>
    <tr><td class="state-label">Default</td><td><code>"user"</code></td></tr>
    <tr><td class="state-label">Disabled 조건</td><td>본인 권한 변경 불가</td></tr>
  </table>
</div>

<!-- Dev 탭 내: Select Validation -->
<div class="card-section">
  <h5>Validation</h5>
  <table class="dev-validation-table">
    <thead><tr><th>Rule</th><th>조건</th><th>에러 메시지</th></tr></thead>
    <tbody>
      <tr>
        <td><span class="dev-badge badge-required">required</span></td>
        <td>미선택 (빈 값)</td>
        <td><code>"권한을 선택해주세요"</code></td>
      </tr>
      <tr>
        <td><span class="dev-badge badge-permission">permission</span></td>
        <td>admin 선택 시 superAdmin 권한 없음</td>
        <td><code>"관리자 권한 부여 권한이 없습니다"</code></td>
      </tr>
    </tbody>
  </table>
</div>
```

#### 버튼/액션 요소 예시 (Dev 탭 — 흐름도 중심)

```html
<!-- Dev 탭 내: 버튼 동작방식 -->
<div class="card-section">
  <h5>동작방식</h5>
  <table class="card-table">
    <tr><td class="state-label">Component</td><td><code>SubmitButton</code> (atoms/button)</td></tr>
    <tr><td class="state-label">Type</td><td><code>button[type="submit"]</code></td></tr>
    <tr><td class="state-label">Disabled 조건</td><td>form invalid 또는 isSubmitting=true</td></tr>
    <tr><td class="state-label">Loading 표시</td><td>Spinner 아이콘 + "로그인 중..." 텍스트 교체</td></tr>
    <tr><td class="state-label">중복 클릭 방지</td><td>isSubmitting 상태로 즉시 disable</td></tr>
  </table>
</div>

<!-- Dev 탭 내: Submit 흐름도 -->
<div class="card-section">
  <h5>흐름도</h5>
  <div class="dev-flow-diagram">
    <div class="dev-flow-row">
      <span class="dev-flow-node">Click: 로그인 버튼</span>
    </div>
    <div class="dev-flow-row"><span class="dev-flow-arrow">↓</span></div>
    <div class="dev-flow-row">
      <span class="dev-flow-node">클라이언트 Validation 전체 실행</span>
    </div>
    <div class="dev-flow-row"><span class="dev-flow-arrow">↓</span></div>
    <div class="dev-flow-row">
      <span class="dev-flow-node dev-flow-decision">All valid?</span>
    </div>
    <div class="dev-flow-row">
      <span class="dev-flow-arrow">No →</span>
      <span class="dev-flow-node dev-flow-error">첫 번째 에러 필드에 focus</span>
    </div>
    <div class="dev-flow-row"><span class="dev-flow-arrow">Yes ↓</span></div>
    <div class="dev-flow-row">
      <span class="dev-flow-node">isSubmitting = true, 버튼 Loading</span>
    </div>
    <div class="dev-flow-row"><span class="dev-flow-arrow">↓</span></div>
    <div class="dev-flow-row">
      <div class="dev-api-card-inline">
        <span class="dev-method method-post">POST</span>
        <code>/api/v1/auth/login</code>
      </div>
    </div>
    <div class="dev-flow-row"><span class="dev-flow-arrow">↓</span></div>
    <div class="dev-flow-row">
      <span class="dev-flow-node dev-flow-decision">Response?</span>
    </div>
    <div class="dev-flow-row">
      <span class="dev-flow-arrow">200 →</span>
      <span class="dev-flow-node dev-flow-success">토큰 저장 → S-0040 대시보드 이동</span>
    </div>
    <div class="dev-flow-row">
      <span class="dev-flow-arrow">401 →</span>
      <span class="dev-flow-node dev-flow-error">Toast: "이메일 또는 비밀번호가 틀립니다"</span>
    </div>
    <div class="dev-flow-row">
      <span class="dev-flow-arrow">429 →</span>
      <span class="dev-flow-node dev-flow-error">Toast: "잠시 후 다시 시도해주세요" + 30초 쿨다운</span>
    </div>
    <div class="dev-flow-row"><span class="dev-flow-arrow">↓ finally</span></div>
    <div class="dev-flow-row">
      <span class="dev-flow-node">isSubmitting = false</span>
    </div>
  </div>
</div>
```

#### 테이블/리스트 요소 예시 (Dev 탭 — 데이터 로딩 + 페이지네이션)

```html
<!-- Dev 탭 내: 테이블 동작방식 -->
<div class="card-section">
  <h5>동작방식</h5>
  <table class="card-table">
    <tr><td class="state-label">Component</td><td><code>DataTable</code> (organisms/table)</td></tr>
    <tr><td class="state-label">Pagination</td><td>서버 사이드, 20건/페이지</td></tr>
    <tr><td class="state-label">Sorting</td><td>컬럼 헤더 클릭 시 ASC/DESC 토글</td></tr>
    <tr><td class="state-label">Selection</td><td>체크박스 다중 선택, 헤더 전체선택</td></tr>
    <tr><td class="state-label">Empty</td><td>데이터 없음 일러스트 + "등록된 항목이 없습니다"</td></tr>
    <tr><td class="state-label">Loading</td><td>Skeleton row 5개 표시</td></tr>
  </table>
</div>

<!-- Dev 탭 내: 테이블 컬럼 정의 -->
<div class="card-section">
  <h5>컬럼 정의</h5>
  <table class="dev-columns-table">
    <thead><tr><th>Field</th><th>Label</th><th>Type</th><th>Sortable</th><th>Width</th></tr></thead>
    <tbody>
      <tr><td><code>name</code></td><td>이름</td><td>text</td><td>Yes</td><td>200px</td></tr>
      <tr><td><code>email</code></td><td>이메일</td><td>text</td><td>Yes</td><td>flex</td></tr>
      <tr><td><code>role</code></td><td>권한</td><td>badge</td><td>Yes</td><td>100px</td></tr>
      <tr><td><code>createdAt</code></td><td>가입일</td><td>date (YYYY.MM.DD)</td><td>Yes</td><td>120px</td></tr>
      <tr><td><code>actions</code></td><td></td><td>action-menu</td><td>No</td><td>60px</td></tr>
    </tbody>
  </table>
</div>

<!-- Dev 탭 내: API + Query Params -->
<div class="card-section">
  <h5>API</h5>
  <div class="dev-api-card">
    <span class="dev-method method-get">GET</span>
    <code class="dev-endpoint">/api/v1/users</code>
  </div>
  <table class="card-table">
    <tr><td class="state-label">page</td><td><code>query.page</code> (default: 1)</td></tr>
    <tr><td class="state-label">limit</td><td><code>query.limit</code> (default: 20)</td></tr>
    <tr><td class="state-label">sort</td><td><code>query.sort</code> (e.g. "createdAt:desc")</td></tr>
    <tr><td class="state-label">search</td><td><code>query.q</code> (이름/이메일 검색)</td></tr>
  </table>
</div>
```

### 2.3 Sidebar Card 내용 구성 규칙

각 어노테이션 카드는 아코디언으로 접혀 있으며, 확장 시 **Design 탭**과 **Dev 탭** 2개 탭으로 구성한다.

#### Design 탭 (기획/디자인 관점)

| 섹션 | 필수 | 내용 |
|------|------|------|
| **Description** | ✅ | `[컴포넌트타입] 이름` 헤더 + bullet 목록으로 정책/비즈니스 룰/조건/노출 문구 기술. `.desc-block` 사용 |
| **요구사항** | ✅ | 관련 FR, US, FT ID + 제목 (`2_Screen_UX.md` FT Mapping 기반) |
| **연결 화면** | 해당 시 | 클릭/동작 시 이동하는 화면 + 조건 (다른 와이어프레임 링크) |
| **권한** | 해당 시 | Role Visibility (어떤 권한에서 표시/숨김) |

##### Description 작성 규칙

1. **헤더**: `[컴포넌트타입] 이름` — 타입은 `[정책]`, `[Button]`, `[Card]`, `[Badge]`, `[Confirm]`, `[Input]`, `[Select]`, `[List]`, `[Table]`, `[Modal]`, `[Tab]`, `[Form]` 등 사용
2. **항목**: `•` bullet로 주요 설명 기술, 하위 조건은 `>` 들여쓰기
3. **정책/경고**: `.desc-policy` 클래스로 빨간 강조 텍스트 처리
4. **노출 문구**: `.desc-quote`로 감싸기 — `'해당 부고는 발인 되었습니다.'`
5. **비고**: `.desc-note`로 하단 표시
6. **공통 정책**: 화면 전체에 적용되는 정책은 `공통` 번호로 별도 Description 블록 작성

#### Dev 탭 (개발 관점)

| 섹션 | 필수 | 적용 요소 | 내용 |
|------|------|----------|------|
| **동작방식** | ✅ | 전체 | HTML type, 컴포넌트명, debounce, auto-focus, disabled 조건, loading 표시 등 구현에 필요한 동작 명세 |
| **이벤트** | 해당 시 | Input, Button, Link 등 | 이벤트명 + 핸들러명 + 구체적 동작 설명 테이블 |
| **Validation** | ✅ (입력 요소) | Input, Select, Textarea, Form | Rule type(required/format/length/async/custom) + 조건 + **에러 메시지 원문** |
| **흐름도** | ✅ (인터랙션 요소) | Button, Form, Link, 복합 동작 | 사용자 동작 → 검증 → API → 분기(성공/에러별) → 후속 동작의 **단계별 흐름** |
| **옵션값** | ✅ (선택 요소) | Select, Radio, Checkbox Group, Tab | value + label + 표시 조건 + data source(정적/API) |
| **컬럼 정의** | ✅ (테이블 요소) | DataTable, List | field + label + type + sortable + width |
| **API** | ✅ (데이터 요소) | 전체 (API 연동 시) | HTTP method + endpoint + request field + query params |
| **데이터 바인딩** | 해당 시 | 전체 | state 경로, error 경로, 관련 store/context |

#### 요소 유형별 Dev 탭 필수 섹션 매트릭스

| 요소 유형 | 동작방식 | 이벤트 | Validation | 흐름도 | 옵션값 | 컬럼 정의 | API | 데이터 바인딩 |
|----------|---------|--------|-----------|--------|--------|----------|-----|-------------|
| **Input** (text, email, password, number) | ✅ | ✅ | ✅ | — | — | — | 해당 시 | ✅ |
| **Textarea** | ✅ | ✅ | ✅ | — | — | — | 해당 시 | ✅ |
| **Select / Dropdown** | ✅ | ✅ | ✅ | — | ✅ | — | 해당 시 | ✅ |
| **Radio / Checkbox Group** | ✅ | ✅ | ✅ | — | ✅ | — | 해당 시 | ✅ |
| **Button (Submit)** | ✅ | ✅ | — | ✅ | — | — | ✅ | — |
| **Button (Action)** | ✅ | ✅ | — | ✅ | — | — | 해당 시 | — |
| **Link / Navigation** | ✅ | — | — | 해당 시 | — | — | — | — |
| **DataTable** | ✅ | 해당 시 | — | — | — | ✅ | ✅ | ✅ |
| **List** | ✅ | 해당 시 | — | — | — | ✅ | ✅ | ✅ |
| **Tab / Stepper** | ✅ | ✅ | — | ✅ | ✅ | — | — | ✅ |
| **Modal / Dialog** | ✅ | ✅ | — | ✅ | — | — | 해당 시 | — |
| **Form (전체)** | ✅ | ✅ | — | ✅ | — | — | ✅ | ✅ |
| **Header / Footer / Nav** | ✅ | — | — | — | — | — | — | — |
| **Card / Section** | ✅ | — | — | — | — | — | 해당 시 | 해당 시 |
| **Chart / Graph** | ✅ | 해당 시 | — | — | — | — | ✅ | ✅ |
| **File Upload** | ✅ | ✅ | ✅ | ✅ | — | — | ✅ | ✅ |
| **Search** | ✅ | ✅ | ✅ | ✅ | — | — | ✅ | ✅ |
| **Toast / Alert** | ✅ | — | — | — | — | — | — | — |

#### Validation Rule Types

| Type | Badge Class | 용도 |
|------|------------|------|
| `required` | `.badge-required` | 필수 입력 |
| `format` | `.badge-format` | 정규식/형식 검증 (email, phone, URL 등) |
| `maxLength` / `minLength` | `.badge-length` | 글자수 제한 |
| `min` / `max` | `.badge-range` | 숫자 범위 |
| `pattern` | `.badge-pattern` | 커스텀 정규식 |
| `async` | `.badge-async` | 서버 검증 (중복 확인, 존재 확인 등) |
| `custom` | `.badge-custom` | 커스텀 검증 로직 |
| `match` | `.badge-match` | 다른 필드와 일치 (비밀번호 확인 등) |
| `permission` | `.badge-permission` | 권한 기반 검증 |

---

## 3. 와이어프레임 HTML 템플릿

```html
<!DOCTYPE html>
<html lang="{{LANG}}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{SCREEN_ID}} {{SCREEN_NAME}} — Wireframe</title>
<style>
/* ===== Theme Variables ===== */
:root {
  --primary: #2563eb;
  --primary-light: #dbeafe;
  --bg: #f5f7fa;
  --surface: #ffffff;
  --border: #e2e8f0;
  --sb: #1e293b;
  --sb-text: #94a3b8;
  --hdr: #1e40af;
  --section: #f8fafc;
  --text: #1e293b;
  --text2: #64748b;
  --text3: #94a3b8;
  --accent: #3b82f6;
  --anno: #3b82f6;
  --card-bg: #ffffff;
  --code-bg: #f1f5f9;
  --code-color: #7c3aed;
  --marker-bg: #2563eb;
  --marker-text: #ffffff;
  --tag-fr: #dc2626;
  --tag-ft: #2563eb;
  --tag-us: #059669;
  --overlay: rgba(0,0,0,0.3);
  --hover-bg: #f1f5f9;
}
[data-theme="dark"] {
  --primary: #60a5fa;
  --primary-light: #1e3a5f;
  --bg: #0f172a;
  --surface: #1e293b;
  --border: #334155;
  --sb: #0f172a;
  --sb-text: #64748b;
  --hdr: #1e3a5f;
  --section: #1e293b;
  --text: #e2e8f0;
  --text2: #94a3b8;
  --text3: #64748b;
  --accent: #60a5fa;
  --anno: #3b82f6;
  --card-bg: #1e293b;
  --code-bg: #0f172a;
  --code-color: #a78bfa;
  --marker-bg: #3b82f6;
  --marker-text: #ffffff;
  --tag-fr: #f87171;
  --tag-ft: #60a5fa;
  --tag-us: #34d399;
  --overlay: rgba(0,0,0,0.5);
  --hover-bg: #334155;
}

* { margin:0; padding:0; box-sizing:border-box; }
html { scroll-behavior:smooth; }
body {
  font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: var(--bg); color: var(--text); line-height:1.6;
  transition: background 0.3s, color 0.3s;
}

/* ===== Doc Header (sticky dark bar) ===== */
.doc-header{background:#0f172a;color:#fff;padding:10px 20px;display:flex;justify-content:space-between;align-items:center;position:sticky;top:0;z-index:100;gap:12px}
.dh-left{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.dh-back{color:#94a3b8;text-decoration:none;font-size:16px;font-weight:700;padding:2px 8px;border-radius:4px;background:#1e293b}
.dh-back:hover{background:#334155;color:#fff}
.sid{background:#10b981;color:#fff;padding:2px 10px;border-radius:4px;font-size:11px;font-weight:700;font-family:monospace}
.dh-name{font-size:14px;font-weight:700}
.dh-path{font-family:monospace;font-size:11px;color:#94a3b8;background:#1e293b;padding:2px 8px;border-radius:4px}
.dh-right{display:flex;gap:8px;flex-shrink:0}
.dh-right span{font-size:11px;color:#94a3b8;background:#1e293b;padding:2px 8px;border-radius:4px}

/* ===== Stage (Wireframe + Annotations grid) ===== */
.stage{display:grid;grid-template-columns:1fr 280px;gap:16px;padding:16px;align-items:start}

/* ===== App Frame ===== */
.app-frame{background:#fff;border:2px solid var(--border);border-radius:8px;overflow:hidden;display:flex;height:720px;box-shadow:0 4px 16px rgba(0,0,0,.12)}
.sidebar{width:196px;background:var(--sb);flex-shrink:0;display:flex;flex-direction:column}
.sb-brand{padding:14px 16px;border-bottom:1px solid rgba(255,255,255,.08)}
.sb-brand .app-nm{font-size:12px;font-weight:700;color:#fff}
.sb-brand .app-sub{font-size:10px;color:var(--sb-text)}
.sb-list{list-style:none;padding:6px 0;flex:1;overflow-y:auto}
.sbi{padding:8px 14px;font-size:12px;color:var(--sb-text);cursor:pointer;display:flex;align-items:center;gap:8px;border-left:3px solid transparent}
.sbi.active{background:rgba(59,130,246,.18);color:#fff;border-left-color:#3b82f6}
.sbi.sub{padding:6px 14px 6px 36px;font-size:11px}
.sbi.sub.active{color:#93c5fd}
.app-main{flex:1;display:flex;flex-direction:column;overflow:hidden}
.pg-hdr{background:var(--hdr);color:#fff;padding:12px 18px;flex-shrink:0}
.pg-bc{font-size:10px;opacity:.65;margin-bottom:3px}
.pg-title{font-size:15px;font-weight:700}
.pg-body{flex:1;overflow-y:auto;padding:14px 16px;background:var(--section)}

/* ===== App Frame UI Components ===== */
.filter-card{background:#fff;border:1px solid var(--border);border-radius:8px;padding:10px 14px;margin-bottom:12px;display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.ptab{padding:5px 14px;border-radius:6px;font-size:12px;cursor:pointer;border:1px solid var(--border);background:#fff;color:var(--text2);font-weight:500}
.ptab.active{background:#3b82f6;color:#fff;border-color:#3b82f6;font-weight:700}
.month-sel{border:1px solid var(--border);border-radius:6px;padding:5px 10px;font-size:12px;color:var(--text2);background:#f8fafc;cursor:pointer}
.kpi-row{display:flex;gap:10px;margin-bottom:14px}
.kpi-card{flex:1;background:#fff;border:1px solid var(--border);border-radius:10px;padding:12px 14px}
.kpi-lbl{font-size:11px;color:var(--text3);margin-bottom:6px}
.kpi-val{font-size:20px;font-weight:700;line-height:1}
.kpi-sub{font-size:10px;color:var(--text3);margin-top:3px}
.kpi-card.blue .kpi-val{color:#2563eb}
.kpi-card.green .kpi-val{color:#059669}
.kpi-card.purple .kpi-val{color:#7c3aed}
table{width:100%;border-collapse:collapse;background:#fff;border:1px solid var(--border);border-radius:8px;overflow:hidden;margin-bottom:10px;font-size:12px}
th{background:#f1f5f9;padding:8px 10px;text-align:left;font-size:11px;font-weight:700;color:var(--text2);border-bottom:2px solid var(--border);white-space:nowrap}
td{padding:8px 10px;border-bottom:1px solid #f1f5f9;vertical-align:middle}
tr:last-child td{border-bottom:none}
tr:hover td{background:#f8fafc}
.num{text-align:right;font-family:monospace}
.bdg{display:inline-flex;align-items:center;padding:2px 8px;border-radius:10px;font-size:10px;font-weight:700;white-space:nowrap}
.cp{background:#dcfce7;color:#166534}
.summary-row{background:#f8fafc;border-top:2px solid var(--border)}
.summary-row td{font-weight:700;font-size:12px}
.pager{display:flex;justify-content:center;align-items:center;gap:4px;padding:6px 0}
.pg-btn{width:26px;height:26px;border-radius:5px;border:1px solid var(--border);background:#fff;font-size:11px;color:var(--text2);cursor:pointer;display:inline-flex;align-items:center;justify-content:center}
.pg-btn.active{background:#3b82f6;color:#fff;border-color:#3b82f6;font-weight:700}
.ico-btn{width:26px;height:26px;border-radius:6px;border:1px solid var(--border);background:#fff;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;font-size:12px}
.modal-overlay{position:absolute;inset:0;background:rgba(15,23,42,.5);display:flex;align-items:center;justify-content:center;z-index:50;border-radius:6px}
.modal-box{background:#fff;border-radius:10px;padding:20px;width:380px;box-shadow:0 20px 40px rgba(0,0,0,.2)}

/* ===== Annotation Panel (우측 280px) ===== */
.anno-panel{background:#fff;border:1px solid var(--border);border-radius:10px;padding:16px}
.anno-title{font-size:12px;font-weight:700;color:var(--text);margin-bottom:12px;padding-bottom:8px;border-bottom:1px solid var(--border)}
.anno-item{display:flex;gap:8px;align-items:flex-start;margin-bottom:10px}
.an{display:inline-flex;align-items:center;justify-content:center;width:18px;height:18px;background:var(--anno);color:#fff;border-radius:50%;font-size:10px;font-weight:700;flex-shrink:0;margin-top:1px}
.ad{font-size:11px;color:var(--text2);line-height:1.5}
.br-section{margin-top:14px;padding-top:12px;border-top:1px solid var(--border)}
.br-title{font-size:11px;font-weight:700;color:var(--text);margin-bottom:8px}
.br-item{font-size:11px;color:var(--text2);margin-bottom:6px;padding-left:12px;position:relative;line-height:1.4}
.br-item::before{content:'•';position:absolute;left:2px;color:var(--accent)}

/* ===== Spec Table ===== */
.spec-wrap{padding:16px;background:#fff;border-top:2px solid var(--border)}
.spec-title{font-size:13px;font-weight:700;margin-bottom:10px;color:var(--text)}
.spec-tbl{width:100%;border-collapse:collapse;font-size:12px}
.spec-tbl th{background:#f1f5f9;padding:7px 10px;text-align:left;font-size:11px;font-weight:700;color:var(--text2);border-bottom:1px solid var(--border)}
.spec-tbl td{padding:7px 10px;border-bottom:1px solid #f5f7fa;color:var(--text);vertical-align:top}
code{font-family:monospace;background:#f1f5f9;padding:1px 5px;border-radius:3px;font-size:11px;color:#e11d48}

/* ===== Diagrams Section ===== */
.diagrams-section{padding:16px;background:var(--bg)}
.diagram-block{background:#fff;border:1px solid var(--border);border-radius:10px;padding:20px;margin-bottom:16px}
.diagram-title{font-size:14px;font-weight:700;color:var(--text);margin-bottom:4px}
.diagram-desc{font-size:12px;color:var(--text2);margin-bottom:16px}
.diagram-svg{width:100%;height:auto;display:block}
.diagram-legend{display:flex;gap:16px;margin-top:12px;padding-top:10px;border-top:1px solid var(--border);flex-wrap:wrap}
.dg-legend-item{display:flex;align-items:center;gap:6px;font-size:11px;color:var(--text2)}
.dg-legend-swatch{width:14px;height:14px;border-radius:4px;border:1px solid var(--border)}
/* Flow Chart nodes */
.dg-start{fill:#dbeafe;stroke:#2563eb;stroke-width:2}
.dg-condition{fill:#fef3c7;stroke:#f59e0b;stroke-width:2}
.dg-action{fill:#f0fdf4;stroke:#22c55e;stroke-width:1.5}
.dg-error{fill:#fef2f2;stroke:#ef4444;stroke-width:1.5}
.dg-text{fill:var(--text);font-size:12px;font-weight:600}
.dg-arrow{stroke:var(--text3);stroke-width:1.5;marker-end:url(#flow-arrow)}
.dg-label-text{fill:var(--text2);font-size:11px;font-weight:600}
.dg-legend-swatch.dg-start{background:#dbeafe;border-color:#2563eb}
.dg-legend-swatch.dg-condition{background:#fef3c7;border-color:#f59e0b}
.dg-legend-swatch.dg-action{background:#f0fdf4;border-color:#22c55e}
.dg-legend-swatch.dg-error{background:#fef2f2;border-color:#ef4444}
/* Sequential Diagram */
.seq-actor{fill:#e0e7ff;stroke:#4f46e5;stroke-width:1.5}
.seq-text{fill:var(--text);font-size:12px;font-weight:600}
.seq-lifeline{stroke:var(--text3);stroke-width:1;stroke-dasharray:6 4}
.seq-msg{stroke:var(--text);stroke-width:1.5}
.seq-msg-reply{stroke:var(--text3);stroke-width:1.5;stroke-dasharray:6 4}
.seq-msg-text{fill:var(--text2);font-size:11px}
.seq-arrowhead{fill:var(--text)}

/* ===== Annotation Card (Accordion) ===== */
.annotation-card {
  background:var(--card-bg); border:1px solid var(--border); border-radius:8px;
  margin-bottom:8px; overflow:hidden; transition:border-color 0.2s;
}
.annotation-card.highlight { border-color:var(--primary); box-shadow:0 0 0 2px var(--primary-light); }
.annotation-card:last-child { margin-bottom:0; }

/* Card Header (always visible, clickable) */
.card-header {
  display:flex; align-items:center; gap:10px;
  padding:10px 14px; cursor:pointer; user-select:none;
  transition:background 0.2s;
}
.card-header:hover { background:var(--hover-bg); }
.card-number {
  min-width:22px; height:22px; padding:0 4px; border-radius:50%; flex-shrink:0;
  background:var(--marker-bg); color:var(--marker-text);
  font-size:11px; font-weight:700; line-height:22px; text-align:center;
  font-family:'Fira Code',monospace;
  box-shadow:0 1px 4px rgba(37,99,235,0.3);
}
.card-title { flex:1; font-size:13px; font-weight:600; color:var(--text); }
.card-chevron {
  font-size:10px; color:var(--text-muted); transition:transform 0.2s;
}
.annotation-card.expanded .card-chevron { transform:rotate(180deg); }

/* Card Body (collapsible) */
.card-body {
  display:none; border-top:1px solid var(--border);
}
.annotation-card.expanded .card-body { display:block; }

/* Card Tabs */
.card-tabs {
  display:flex; border-bottom:2px solid var(--border); background:var(--card-bg);
}
.card-tab {
  flex:1; padding:8px 12px; border:none; background:none;
  font-size:12px; font-weight:600; color:var(--text-secondary);
  cursor:pointer; transition:all 0.2s; border-bottom:2px solid transparent;
  margin-bottom:-2px;
}
.card-tab:hover { color:var(--text); background:var(--hover-bg); }
.card-tab.active { color:var(--primary); border-bottom-color:var(--primary); }
.tab-content { display:none; }
.tab-content.active { display:block; }

/* Card Tab Content */
.card-tab-content { padding:14px; }

/* Card Sections */
.card-section { margin-bottom:14px; }
.card-section:last-child { margin-bottom:0; }
.card-section h5 {
  font-size:11px; text-transform:uppercase; letter-spacing:0.5px;
  color:var(--text-secondary); margin-bottom:6px; font-weight:600;
}
.card-section p { font-size:13px; line-height:1.7; }
.card-section ul { list-style:none; padding:0; }
.card-section li { font-size:12px; padding:3px 0; }

/* Card Table */
.card-table { width:100%; font-size:12px; border-collapse:collapse; }
.card-table td { padding:5px 8px; border-bottom:1px solid var(--border); }
.card-table code { background:var(--code-bg); padding:1px 5px; border-radius:3px; font-size:11px; font-family:'Fira Code',monospace; color:var(--code-color); }
.state-label { font-weight:600; color:var(--primary); white-space:nowrap; width:80px; }

/* Card Tags */
.card-tags li { display:flex; align-items:center; gap:8px; }
.card-tag {
  display:inline-block; padding:2px 8px; border-radius:4px;
  font-size:11px; font-weight:700; font-family:'Fira Code',monospace;
}
.tag-fr { background:rgba(220,38,38,0.1); color:var(--tag-fr); }
.tag-ft { background:rgba(37,99,235,0.1); color:var(--tag-ft); }
.tag-us { background:rgba(5,150,105,0.1); color:var(--tag-us); }

/* Card Links */
.card-links li { padding:3px 0; }
.card-links a { color:var(--primary); text-decoration:none; font-weight:600; font-size:12px; }
.card-links a:hover { text-decoration:underline; }

/* ===== Description Block (스크린샷 스타일) ===== */
.desc-block {
  background:var(--card-bg); border:1px solid var(--border); border-radius:8px;
  padding:14px 16px; margin-bottom:12px;
}
.desc-header {
  font-size:14px; font-weight:700; color:var(--text); margin-bottom:8px;
  padding-bottom:6px; border-bottom:1px solid var(--border);
}
.desc-list {
  list-style:none; padding:0; margin:0;
}
.desc-list > li {
  font-size:13px; line-height:1.7; padding:3px 0 3px 16px;
  position:relative;
}
.desc-list > li::before {
  content:'•'; position:absolute; left:0; color:var(--text-secondary); font-weight:700;
}
.desc-sub {
  list-style:none; padding:0; margin:2px 0 2px 4px;
}
.desc-sub > li {
  font-size:12px; line-height:1.6; padding:1px 0 1px 16px;
  position:relative; color:var(--text-secondary);
}
.desc-sub > li::before {
  content:'>'; position:absolute; left:0; color:var(--text-muted); font-weight:600;
}
.desc-policy {
  color:var(--tag-fr) !important; font-weight:700;
}
.desc-quote {
  background:rgba(245,158,11,0.1); padding:1px 6px; border-radius:3px;
  font-style:italic; color:var(--text);
}
.desc-note {
  margin-top:8px; padding-top:6px; border-top:1px solid var(--border);
  font-size:11px; color:var(--text-muted); font-weight:600;
  text-transform:uppercase; letter-spacing:0.5px;
}

/* ===== Dev Tab Styles ===== */

/* Dev Tables (Events, Validation, Options, Columns) */
.dev-event-table, .dev-validation-table, .dev-options-table, .dev-columns-table {
  width:100%; font-size:12px; border-collapse:collapse; margin:8px 0;
}
.dev-event-table th, .dev-validation-table th, .dev-options-table th, .dev-columns-table th {
  background:var(--code-bg); color:var(--text-secondary); font-weight:600;
  padding:8px 10px; text-align:left; font-size:11px; text-transform:uppercase;
  letter-spacing:0.5px; border-bottom:2px solid var(--border);
}
.dev-event-table td, .dev-validation-table td, .dev-options-table td, .dev-columns-table td {
  padding:7px 10px; border-bottom:1px solid var(--border); vertical-align:top;
}
.dev-event-table code, .dev-validation-table code, .dev-options-table code, .dev-columns-table code {
  background:var(--code-bg); padding:1px 5px; border-radius:3px;
  font-size:11px; font-family:'Fira Code',monospace; color:var(--code-color);
}
.opt-placeholder { color:var(--text-muted); font-style:italic; }

/* Dev Badges */
.dev-badge {
  display:inline-block; padding:2px 8px; border-radius:4px;
  font-size:10px; font-weight:700; text-transform:uppercase; letter-spacing:0.3px;
}
.badge-required { background:rgba(220,38,38,0.1); color:var(--tag-fr); }
.badge-format { background:rgba(124,58,237,0.1); color:var(--code-color); }
.badge-length, .badge-range { background:rgba(245,158,11,0.1); color:#f59e0b; }
.badge-pattern { background:rgba(6,182,212,0.1); color:#06b6d4; }
.badge-async { background:rgba(37,99,235,0.1); color:var(--tag-ft); }
.badge-custom { background:rgba(107,114,128,0.1); color:var(--text-secondary); }
.badge-match { background:rgba(5,150,105,0.1); color:var(--tag-us); }
.badge-permission { background:rgba(249,115,22,0.1); color:#f97316; }

/* Dev Flow Diagram */
.dev-flow-diagram {
  background:var(--code-bg); border:1px solid var(--border); border-radius:8px;
  padding:16px; margin:8px 0;
}
.dev-flow-row { display:flex; align-items:center; gap:8px; margin:4px 0; flex-wrap:wrap; }
.dev-flow-node {
  background:var(--card-bg); border:1px solid var(--border);
  padding:6px 12px; border-radius:6px; font-size:12px; font-weight:500;
}
.dev-flow-decision {
  background:var(--primary-light); color:var(--primary); font-weight:700;
  border-radius:16px; border-color:var(--primary);
}
.dev-flow-success { background:rgba(5,150,105,0.1); color:var(--tag-us); border-color:var(--tag-us); }
.dev-flow-error { background:rgba(220,38,38,0.1); color:var(--tag-fr); border-color:var(--tag-fr); }
.dev-flow-arrow { color:var(--text-muted); font-size:13px; font-weight:600; font-family:'Fira Code',monospace; white-space:nowrap; }

/* Dev API Card */
.dev-api-card, .dev-api-card-inline {
  display:inline-flex; align-items:center; gap:8px;
  padding:6px 12px; border-radius:6px; margin:4px 0;
  background:var(--code-bg); border:1px solid var(--border);
}
.dev-method {
  padding:2px 6px; border-radius:3px; font-size:10px; font-weight:700;
  font-family:'Fira Code',monospace; letter-spacing:0.5px;
}
.method-get { background:rgba(37,99,235,0.15); color:var(--tag-ft); }
.method-post { background:rgba(5,150,105,0.15); color:var(--tag-us); }
.method-put { background:rgba(245,158,11,0.15); color:#f59e0b; }
.method-patch { background:rgba(124,58,237,0.15); color:var(--code-color); }
.method-delete { background:rgba(220,38,38,0.15); color:var(--tag-fr); }
.dev-endpoint { font-size:12px; font-family:'Fira Code',monospace; color:var(--text); }

/* Dev Note */
.dev-note {
  background:var(--primary-light); border-left:3px solid var(--primary);
  padding:8px 12px; margin:8px 0; border-radius:0 6px 6px 0;
  font-size:12px; color:var(--text-secondary);
}
.dev-note code { background:var(--code-bg); padding:1px 4px; border-radius:3px; font-size:11px; }

/* ===== Annotation Legend ===== */
.annotation-legend {
  background:var(--card-bg); border:1px solid var(--border); border-radius:12px;
  padding:20px 24px; margin:20px 24px;
}
.annotation-legend h2 { font-size:15px; color:var(--primary); margin-bottom:12px; }
.legend-list { list-style:none; padding:0; columns:2; column-gap:24px; }
.legend-item {
  display:flex; align-items:center; gap:10px; padding:6px 0;
  font-size:13px; cursor:pointer; break-inside:avoid;
}
.legend-item:hover { color:var(--primary); }
.legend-num {
  min-width:22px; height:22px; padding:0 4px; border-radius:50%;
  background:var(--marker-bg); color:var(--marker-text);
  font-size:11px; font-weight:700; line-height:22px; text-align:center;
  flex-shrink:0; font-family:'Fira Code',monospace;
  box-shadow:0 1px 4px rgba(37,99,235,0.3);
}

/* ===== Mobile ===== */
@media (max-width:768px) {
  .doc-header { flex-wrap:wrap; gap:6px; }
  .stage { grid-template-columns:1fr; }
  .app-frame { height:auto; flex-direction:column; }
  .sidebar { width:100%; height:auto; }
  .anno-panel { order:2; }
  .legend-list { columns:1; }
  .diagrams-section { padding:10px; }
}

/* ===== Print ===== */
@media print {
  .doc-header { position:static; }
  .an { print-color-adjust:exact; -webkit-print-color-adjust:exact; }
  .anno-panel { break-inside:avoid; }
  .diagrams-section { break-before:page; }
}
</style>
</head>
<body>

<!-- Doc Header (sticky dark bar) -->
<div class="doc-header">
  <div class="dh-left">
    <a href="index.html" class="dh-back" title="All Screens">←</a>
    <span class="sid">{{SCREEN_ID}}</span>
    <span class="dh-name">{{SCREEN_NAME}}</span>
    <span class="dh-path">{{URL_PATH}}</span>
  </div>
  <div class="dh-right">
    <span>{{FT_IDS}}</span>
    <span>{{ACCESS_ROLE}}</span>
    <span>{{DATE}}</span>
  </div>
</div>

<!-- Stage: Wireframe + Annotations -->
<div class="stage">
  <div>
    <!-- App Frame -->
    <div class="app-frame">
      <nav class="sidebar">
        <div class="sb-brand"><div class="app-nm">{{APP_NAME}}</div><div class="app-sub">{{APP_DESC}}</div></div>
        <ul class="sb-list">
          <!-- Screen 문서의 IA 기반 네비게이션 -->
          <li class="sbi active">{{CURRENT_MENU}}</li>
          <li class="sbi sub active">{{CURRENT_SUBMENU}}</li>
        </ul>
      </nav>
      <div class="app-main">
        <div class="pg-hdr">
          <div class="pg-bc">{{BREADCRUMB}}</div>
          <div class="pg-title">{{SCREEN_NAME}}</div>
        </div>
        <div class="pg-body">
          <!--
            화면 콘텐츠를 HTML/CSS div 기반으로 렌더링:
            - filter-card, kpi-row, table, form, modal 등 실제 UI 컴포넌트
            - 각 UI 요소에 ① ② ③ 원형 숫자 마커 표시
            - CSS 변수 사용 (dark/light 테마 대응)
          -->
          <!-- 예: ① 필터 영역 -->
          <div class="filter-card">
            <div class="ptab active">① 월별</div>
            <div class="ptab">분기별</div>
            <select class="month-sel"><option>2026년 3월</option></select>
          </div>
          <!-- 예: ② KPI 카드 -->
          <div class="kpi-row">
            <div class="kpi-card blue"><div class="kpi-lbl">총 건수</div><div class="kpi-val">12</div></div>
            <div class="kpi-card green"><div class="kpi-lbl">총 금액</div><div class="kpi-val">2,400,000</div></div>
          </div>
          <!-- 예: ③ 데이터 테이블 -->
          <table>
            <thead><tr><th>항목</th><th>값</th><th>상태</th></tr></thead>
            <tbody>
              <tr><td>데이터</td><td class="num">100,000</td><td><span class="bdg cp">완료</span></td></tr>
            </tbody>
          </table>
          <!-- 예: ④ 페이지네이션 -->
          <div class="pager">
            <button class="pg-btn active">1</button><button class="pg-btn">2</button>
          </div>
        </div>
      </div>
    </div>
    <!-- 모달/팝업 참고용 (app-frame 외부에 별도 명세) -->
  </div>

  <!-- Annotation Panel (우측 280px) -->
  <div class="anno-panel">
    <div class="anno-title">Annotations</div>
    <div class="anno-item">
      <span class="an">①</span>
      <div class="ad"><strong>{{ELEMENT_NAME}}</strong> — {{DESCRIPTION}}</div>
    </div>
    <div class="anno-item">
      <span class="an">②</span>
      <div class="ad"><strong>{{ELEMENT_NAME}}</strong> — {{DESCRIPTION}}</div>
    </div>
    <!-- 각 UI 요소별 어노테이션 반복 -->

    <!-- 뱃지 범례 (해당 시) -->
    <div class="br-section">
      <div class="br-title">상태 뱃지</div>
      <div style="display:flex;flex-direction:column;gap:6px;margin-bottom:10px">
        <div style="display:flex;align-items:center;gap:8px">
          <span class="bdg cp">완료</span>
          <span style="font-size:11px;color:var(--text3)">처리 완료 상태</span>
        </div>
      </div>
      <div class="br-title">비즈니스 규칙</div>
      <div class="br-item">{{RULE_1}}</div>
      <div class="br-item">{{RULE_2}}</div>
    </div>
  </div>
</div>

<!-- 모달/팝업 명세 (해당 시) -->
<div class="spec-wrap">
  <div style="font-size:13px;font-weight:700;margin-bottom:12px;color:var(--text)">{{MODAL_TITLE}} 명세</div>
  <div style="display:flex;gap:20px;flex-wrap:wrap;align-items:flex-start">
    <!-- 팝업 UI 미리보기 + 필드 목록 -->
  </div>
</div>

<!-- Component Spec Table -->
<div class="spec-wrap">
  <div class="spec-title">컴포넌트 명세</div>
  <table class="spec-tbl">
    <thead><tr><th>컴포넌트</th><th>타입</th><th>기본값</th><th>비고</th></tr></thead>
    <tbody>
      <tr><td>{{COMPONENT}}</td><td>{{TYPE}}</td><td>{{DEFAULT}}</td><td>{{NOTE}}</td></tr>
    </tbody>
  </table>
</div>

<!-- ===== Diagrams Section ===== -->
<div class="diagrams-section">

  <!-- Condition Flow Chart (조건 분기가 있는 화면: 필수) -->
  <div class="diagram-block">
    <div class="diagram-title">Condition Flow Chart</div>
    <div class="diagram-desc">{{화면의 조건 분기 로직 설명}}</div>
    <svg class="diagram-svg" viewBox="0 0 800 400" xmlns="http://www.w3.org/2000/svg">
      <!--
        조건 분기: 시작 → 조건 → Yes/No 분기 → 액션
        - dg-start: 시작/종료 노드 (둥근 사각형 rx=20)
        - dg-condition: 조건 분기 노드 (rx=8, 구분 배경색)
        - dg-action: 액션 노드 (직사각형)
        - dg-error: 에러/거부 노드
        - dg-arrow: 연결 화살표 (line)
        - dg-label-text: Yes/No 라벨 (text)
      -->
      <rect class="dg-start" x="320" y="20" width="160" height="40" rx="20"/>
      <text class="dg-text" x="400" y="44" text-anchor="middle">페이지 진입</text>
      <line class="dg-arrow" x1="400" y1="60" x2="400" y2="100"/>
      <rect class="dg-condition" x="330" y="100" width="140" height="44" rx="8"/>
      <text class="dg-text" x="400" y="126" text-anchor="middle">권한 확인</text>
      <line class="dg-arrow" x1="330" y1="122" x2="200" y2="122"/>
      <text class="dg-label-text" x="265" y="115">No</text>
      <rect class="dg-action dg-error" x="100" y="102" width="100" height="40" rx="6"/>
      <text class="dg-text" x="150" y="126" text-anchor="middle">접근 거부</text>
      <line class="dg-arrow" x1="400" y1="144" x2="400" y2="190"/>
      <text class="dg-label-text" x="415" y="170">Yes</text>
      <rect class="dg-action" x="320" y="190" width="160" height="40" rx="6"/>
      <text class="dg-text" x="400" y="214" text-anchor="middle">데이터 로드</text>
    </svg>
    <div class="diagram-legend">
      <span class="dg-legend-item"><span class="dg-legend-swatch dg-start"></span> 시작/종료</span>
      <span class="dg-legend-item"><span class="dg-legend-swatch dg-condition"></span> 조건</span>
      <span class="dg-legend-item"><span class="dg-legend-swatch dg-action"></span> 액션</span>
      <span class="dg-legend-item"><span class="dg-legend-swatch dg-error"></span> 에러</span>
    </div>
  </div>

  <!-- Sequential Diagram (인터랙션이 있는 화면: 필수) -->
  <div class="diagram-block">
    <div class="diagram-title">Sequential Diagram</div>
    <div class="diagram-desc">{{사용자↔시스템 인터랙션 시퀀스}}</div>
    <svg class="diagram-svg" viewBox="0 0 800 300" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <marker id="seq-arrow" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
          <polygon class="seq-arrowhead" points="0 0, 8 3, 0 6"/>
        </marker>
      </defs>
      <!--
        시퀀스: Actor 컬럼 + 시간축(위→아래) + 메시지 화살표
        - seq-actor: 상단 박스
        - seq-lifeline: 점선 세로선
        - seq-msg: 요청 (실선 →), marker-end="url(#seq-arrow)"
        - seq-msg-reply: 응답 (점선 ←)
      -->
      <rect class="seq-actor" x="60" y="20" width="100" height="36" rx="6"/>
      <text class="seq-text" x="110" y="42" text-anchor="middle">사용자</text>
      <line class="seq-lifeline" x1="110" y1="56" x2="110" y2="290"/>
      <rect class="seq-actor" x="300" y="20" width="100" height="36" rx="6"/>
      <text class="seq-text" x="350" y="42" text-anchor="middle">Frontend</text>
      <line class="seq-lifeline" x1="350" y1="56" x2="350" y2="290"/>
      <rect class="seq-actor" x="560" y="20" width="100" height="36" rx="6"/>
      <text class="seq-text" x="610" y="42" text-anchor="middle">API Server</text>
      <line class="seq-lifeline" x1="610" y1="56" x2="610" y2="290"/>
      <line class="seq-msg" x1="110" y1="90" x2="345" y2="90" marker-end="url(#seq-arrow)"/>
      <text class="seq-msg-text" x="228" y="84" text-anchor="middle">버튼 클릭</text>
      <line class="seq-msg" x1="350" y1="130" x2="605" y2="130" marker-end="url(#seq-arrow)"/>
      <text class="seq-msg-text" x="478" y="124" text-anchor="middle">GET /api/v1/data</text>
      <line class="seq-msg-reply" x1="610" y1="170" x2="355" y2="170" marker-end="url(#seq-arrow)"/>
      <text class="seq-msg-text" x="478" y="164" text-anchor="middle">200 OK + data[]</text>
      <line class="seq-msg" x1="350" y1="210" x2="115" y2="210" marker-end="url(#seq-arrow)"/>
      <text class="seq-msg-text" x="228" y="204" text-anchor="middle">UI 갱신</text>
    </svg>
  </div>

  <!-- UML Diagram (해당 시에만 포함 — 상태 다이어그램, 클래스 관계도 등) -->
  <!--
  <div class="diagram-block">
    <div class="diagram-title">State Diagram</div>
    <svg class="diagram-svg" viewBox="0 0 800 300" xmlns="http://www.w3.org/2000/svg">
      상태 전이, 클래스 관계도 등
    </svg>
  </div>
  -->

</div>

<script>
// doc-header는 항상 dark이므로 별도 theme toggle 불필요
// 필요 시 본문에 theme toggle 추가 가능
</script>
</body>
</html>
```

---

## 4. index.html 템플릿

와이어프레임 디렉토리에 `index.html`을 생성하여 전체 화면을 Grid/List 뷰로 탐색할 수 있도록 한다.

- **Grid View (기본)**: 각 화면의 축소 썸네일 프리뷰(`<iframe>` scale 0.25) + Screen ID + 화면명을 카드 그리드로 표시
- **List View**: Screen ID, 화면명, Goal, Access Role을 리스트로 표시
- **Grid/List 토글 버튼**: localStorage에 선호 뷰 저장
- **도메인별 그룹핑**: IA 도메인별 섹션 분리
- **검색**: 화면 ID, 이름, 키워드로 실시간 필터링
- **통계**: 전체 화면 수, 도메인별 화면 수
- **Light/Dark 테마 토글**
- Tab 화면은 부모 화면 하위에 sub-card로 들여쓰기 표시

```html
<!DOCTYPE html>
<html lang="{{LANG}}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{PROJECT_NAME}} — Wireframe Index</title>
<style>
:root {
  --primary: #2563eb;
  --primary-light: #dbeafe;
  --bg: #f5f7fa;
  --surface: #ffffff;
  --border: #e2e8f0;
  --text: #1e293b;
  --text2: #64748b;
  --text3: #94a3b8;
  --hover-bg: #f1f5f9;
}
[data-theme="dark"] {
  --primary: #60a5fa;
  --primary-light: #1e3a5f;
  --bg: #0f172a;
  --surface: #1e293b;
  --border: #334155;
  --text: #e2e8f0;
  --text2: #94a3b8;
  --text3: #64748b;
  --hover-bg: #334155;
}
* { margin:0; padding:0; box-sizing:border-box; }
body {
  font-family:'Pretendard',-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
  background:var(--bg); color:var(--text); line-height:1.6;
}

/* Header */
.page-header {
  background:linear-gradient(135deg,#1e40af,#3b82f6); color:#fff;
  padding:48px 40px; text-align:center;
}
.page-header h1 { font-size:28px; margin-bottom:8px; }
.page-header p { font-size:14px; opacity:0.85; }
.page-header .badge { display:inline-block; background:rgba(255,255,255,0.2); padding:4px 14px; border-radius:20px; font-size:12px; margin-top:12px; }

/* Controls */
.controls {
  max-width:1200px; margin:24px auto; padding:0 24px;
  display:flex; gap:12px; align-items:center;
}
.search-input {
  flex:1; padding:10px 16px; border:1px solid var(--border);
  border-radius:8px; font-size:14px; background:var(--surface);
  color:var(--text); outline:none;
}
.search-input:focus { border-color:var(--primary); }
.view-toggle {
  display:flex; border:1px solid var(--border); border-radius:8px; overflow:hidden;
}
.view-btn {
  padding:8px 14px; border:none; background:var(--surface);
  cursor:pointer; font-size:14px; color:var(--text2); transition:all 0.2s;
}
.view-btn.active { background:var(--primary); color:#fff; }
.view-btn:hover:not(.active) { background:var(--hover-bg); }
.theme-toggle {
  width:40px; height:40px; border-radius:50%;
  background:var(--surface); border:1px solid var(--border);
  cursor:pointer; display:flex; align-items:center; justify-content:center;
  font-size:18px; transition:all 0.3s;
}
.theme-toggle:hover { border-color:var(--primary); }

/* Stats */
.stats { max-width:1200px; margin:0 auto 24px; padding:0 24px; display:flex; gap:16px; flex-wrap:wrap; }
.stat-card {
  background:var(--surface); border:1px solid var(--border); border-radius:10px;
  padding:16px 20px; text-align:center; flex:1; min-width:120px;
}
.stat-num { font-size:28px; font-weight:700; color:var(--primary); }
.stat-label { font-size:12px; color:var(--text2); margin-top:2px; }

/* Screen Container */
.screen-container { max-width:1200px; margin:0 auto; padding:0 24px 40px; }
.screen-group { margin-bottom:24px; }
.screen-group-title {
  font-size:12px; text-transform:uppercase; letter-spacing:1px;
  color:var(--text2); padding:8px 0; border-bottom:1px solid var(--border);
  margin-bottom:12px; font-weight:600;
}

/* ===== Grid View ===== */
.grid-view .screen-grid {
  display:grid; grid-template-columns:repeat(auto-fill, minmax(280px, 1fr)); gap:16px;
}
.grid-card {
  background:var(--surface); border:1px solid var(--border); border-radius:10px;
  overflow:hidden; text-decoration:none; color:var(--text); transition:all 0.2s;
  display:block;
}
.grid-card:hover { border-color:var(--primary); box-shadow:0 4px 16px rgba(0,0,0,0.1); transform:translateY(-2px); }
.grid-thumb {
  width:100%; height:200px; overflow:hidden; position:relative;
  background:var(--bg); border-bottom:1px solid var(--border);
}
.grid-thumb iframe {
  width:400%; height:400%; border:none;
  transform:scale(0.25); transform-origin:top left;
  pointer-events:none;
}
.grid-info { padding:12px 14px; }
.grid-info .s-id {
  font-family:'Fira Code',monospace; font-size:11px; font-weight:700;
  color:var(--primary); background:var(--primary-light);
  padding:2px 8px; border-radius:4px; display:inline-block; margin-bottom:4px;
}
.grid-info .s-name { font-size:14px; font-weight:600; display:block; }
.grid-info .s-role {
  font-size:10px; font-weight:600; color:var(--text2);
  background:var(--hover-bg); padding:2px 8px; border-radius:10px;
  display:inline-block; margin-top:4px;
}
/* Tab sub-card: 부모 하위 들여쓰기 */
.grid-card.sub-card { border-left:3px solid var(--primary); }
.grid-card.sub-card .grid-info .s-id { font-size:10px; }

/* ===== List View ===== */
.list-view .screen-grid { display:flex; flex-direction:column; gap:8px; }
.list-card {
  display:flex; align-items:center; gap:16px;
  background:var(--surface); border:1px solid var(--border); border-radius:10px;
  padding:16px 20px; text-decoration:none; color:var(--text); transition:all 0.2s;
}
.list-card:hover { border-color:var(--primary); background:var(--hover-bg); transform:translateX(4px); }
.list-card .s-id {
  font-family:'Fira Code',monospace; font-size:13px; font-weight:700;
  color:var(--primary); background:var(--primary-light);
  padding:4px 10px; border-radius:6px; white-space:nowrap;
}
.list-card .s-name { flex:1; font-size:15px; font-weight:600; }
.list-card .s-goal { font-size:12px; color:var(--text2); flex:2; }
.list-card .s-role {
  font-size:11px; font-weight:600; padding:3px 10px;
  border-radius:12px; background:var(--hover-bg); color:var(--text2); white-space:nowrap;
}
.list-card .s-arrow { color:var(--text3); font-size:16px; }
/* Tab sub-card: 리스트 들여쓰기 */
.list-card.sub-card { margin-left:32px; border-left:3px solid var(--primary); }

/* No Results */
.no-results { text-align:center; padding:40px; color:var(--text3); font-size:14px; display:none; }

@media (max-width:768px) {
  .grid-view .screen-grid { grid-template-columns:1fr; }
  .list-card { flex-wrap:wrap; }
  .list-card .s-goal { flex-basis:100%; order:3; margin-top:4px; }
  .stats { flex-wrap:wrap; }
}
@media print {
  .controls { display:none; }
  .grid-thumb iframe { display:none; }
}
</style>
</head>
<body>

<div class="page-header">
  <h1>{{APP_NAME}} Wireframes</h1>
  <p>{{PROJECT_NAME}} — Screen Wireframe Index</p>
  <span class="badge">{{TOTAL_SCREENS}} Screens · {{DATE}}</span>
</div>

<div class="controls">
  <input type="text" class="search-input" id="searchInput" placeholder="Search screens..." oninput="filterScreens(this.value)">
  <div class="view-toggle">
    <button class="view-btn active" data-view="grid" onclick="setView('grid')" title="Grid View">▦</button>
    <button class="view-btn" data-view="list" onclick="setView('list')" title="List View">☰</button>
  </div>
  <button class="theme-toggle" onclick="toggleTheme()" aria-label="Toggle theme">
    <span id="theme-icon">&#9789;</span>
  </button>
</div>

<div class="stats">
  <div class="stat-card"><div class="stat-num">{{TOTAL_SCREENS}}</div><div class="stat-label">Total Screens</div></div>
  <!-- 도메인별 stat-card 반복 -->
  <div class="stat-card"><div class="stat-num">{{DOMAIN_COUNT}}</div><div class="stat-label">{{DOMAIN_NAME}}</div></div>
</div>

<div class="screen-container grid-view" id="screenContainer">
  <!-- 도메인별 그룹핑 -->
  <div class="screen-group" data-group="{{DOMAIN_KEY}}">
    <div class="screen-group-title">{{DOMAIN_KEY}} — {{DOMAIN_LABEL}}</div>
    <div class="screen-grid">

      <!-- Grid View Card (기본) -->
      <a href="S-0010.html" class="grid-card" data-search="s-0010 로그인 login">
        <div class="grid-thumb"><iframe src="S-0010.html" loading="lazy" sandbox></iframe></div>
        <div class="grid-info">
          <span class="s-id">S-0010</span>
          <span class="s-name">로그인</span>
          <span class="s-role">Public</span>
        </div>
      </a>

      <!-- Tab Sub-card (부모 하위 들여쓰기) -->
      <a href="S-0100-T1.html" class="grid-card sub-card" data-search="s-0100-t1 대시보드 개요 탭">
        <div class="grid-thumb"><iframe src="S-0100-T1.html" loading="lazy" sandbox></iframe></div>
        <div class="grid-info">
          <span class="s-id">S-0100-T1</span>
          <span class="s-name">대시보드 &gt; 개요 탭</span>
          <span class="s-role">Admin</span>
        </div>
      </a>

      <!-- List View Card (list-view 모드 시 표시) -->
      <a href="S-0010.html" class="list-card" data-search="s-0010 로그인 login">
        <span class="s-id">S-0010</span>
        <span class="s-name">로그인</span>
        <span class="s-goal">이메일/비밀번호로 인증하여 서비스에 진입</span>
        <span class="s-role">Public</span>
        <span class="s-arrow">→</span>
      </a>

    </div>
  </div>
</div>

<div class="no-results" id="noResults">No screens found</div>

<script>
/* Theme */
function toggleTheme(){
  var h=document.documentElement,i=document.getElementById('theme-icon');
  if(h.getAttribute('data-theme')==='dark'){h.removeAttribute('data-theme');i.innerHTML='&#9789;';localStorage.setItem('wf-theme','light');}
  else{h.setAttribute('data-theme','dark');i.innerHTML='&#9788;';localStorage.setItem('wf-theme','dark');}
}
(function(){
  var s=localStorage.getItem('wf-theme');
  if(s==='dark'||(!s&&matchMedia('(prefers-color-scheme:dark)').matches)){
    document.documentElement.setAttribute('data-theme','dark');
    document.getElementById('theme-icon').innerHTML='&#9788;';
  }
})();

/* View Toggle (Grid / List) */
function setView(mode){
  var c=document.getElementById('screenContainer');
  c.classList.remove('grid-view','list-view');
  c.classList.add(mode+'-view');
  document.querySelectorAll('.view-btn').forEach(function(b){
    b.classList.toggle('active',b.getAttribute('data-view')===mode);
  });
  // Grid 카드 / List 카드 표시 전환
  document.querySelectorAll('.grid-card').forEach(function(el){ el.style.display=mode==='grid'?'':'none'; });
  document.querySelectorAll('.list-card').forEach(function(el){ el.style.display=mode==='list'?'':'none'; });
  localStorage.setItem('wf-view',mode);
}
(function(){
  var v=localStorage.getItem('wf-view')||'grid';
  setView(v);
})();

/* Search */
function filterScreens(q){
  q=q.toLowerCase();
  var cards=document.querySelectorAll('.grid-card,.list-card'),
      groups=document.querySelectorAll('.screen-group'),
      found=0;
  cards.forEach(function(c){
    var match=c.getAttribute('data-search').toLowerCase().indexOf(q)!==-1;
    var isHidden=c.style.display==='none'; // view toggle로 숨긴 카드 제외
    if(!isHidden || match) c.style.display=match?'':'none';
    if(match)found++;
  });
  groups.forEach(function(g){
    var visible=g.querySelectorAll('.grid-card:not([style*="none"]),.list-card:not([style*="none"])');
    g.style.display=visible.length?'':'none';
  });
  document.getElementById('noResults').style.display=found?'none':'block';
}
</script>
</body>
</html>
```

---

## 5. 생성 규칙

### 5.1 와이어프레임별 규칙 (S-NNNN.html)

1. `2_Screen_UX.md`의 해당 화면 설계를 기반으로 **HTML/CSS div 기반 app-frame** 레이아웃 구성
2. **거의 모든 UI 요소**에 숫자 마커 부착 (순서: 상단→하단, 좌→우). 단순 레이아웃 컨테이너를 제외한 인터랙티브/표시/네비게이션/피드백/컨텐츠/정책 관련 요소 전부 대상
3. **우측 Annotation Panel**(280px)에 번호 어노테이션 + 비즈니스 룰 표시
4. 카드 내용은 `2_Screen_UX.md`의 Description, FT Mapping, Navigation, Interactions, States 정보를 종합
5. **Annotation Legend** 섹션에 전체 마커 목록을 범례로 표시 (클릭 시 해당 카드로 이동)
6. **doc-header**에 Screen ID, 화면명, URL Path, FT ID, 날짜 + `index.html` 뒤로가기 버튼 포함
7. **하단 spec-wrap**에 컴포넌트 명세 테이블 배치
8. **하단 diagrams-section**에 Condition Flow Chart(필수) + Sequential Diagram(필수) + UML(해당 시) 포함
9. 인접 화면으로의 링크 포함 (Connected Screens 기반)

### 5.1.1 Tab 화면 분리 규칙

화면 내에 **Tab UI**가 있는 경우, 각 탭을 별도 와이어프레임 HTML로 생성한다.

| 파일 | 내용 |
|------|------|
| `S-NNNN.html` | 부모 화면: 전체 레이아웃 + Tab 네비게이션 구조, 기본(첫 번째) 탭 활성 상태 |
| `S-NNNN-T1.html` | 탭 1: 해당 탭의 고유 콘텐츠 + 전체 어노테이션 |
| `S-NNNN-T2.html` | 탭 2: 해당 탭의 고유 콘텐츠 + 전체 어노테이션 |
| ... | 탭 수만큼 반복 |

1. **부모 화면**의 Tab 요소에서 각 탭 HTML(`S-NNNN-T1.html`, ...)로 링크
2. **각 탭 화면**에서 부모 화면(`S-NNNN.html`)으로의 돌아가기 링크 포함
3. 각 탭 화면에도 **탭별 고유 UI 요소 전체에 어노테이션 마커 + Sidebar 카드** 빠짐없이 작성
4. 탭 화면의 doc-header에 현재 탭 이름 표시 (e.g., `S-0100 대시보드 > 통계 탭`)
5. **index.html**에 탭별 화면도 포함 — 부모 화면 카드 하위에 들여쓰기로 표시

```
.u-maker/docs/{app}/02-design/2_Screen_Wireframes/
├── S-0100.html         ← 부모: 대시보드 (Tab 네비게이션 포함)
├── S-0100-T1.html      ← 탭 1: 개요
├── S-0100-T2.html      ← 탭 2: 통계
├── S-0100-T3.html      ← 탭 3: 설정
├── S-0100.json
├── S-0100-T1.json
├── S-0100-T2.json
├── S-0100-T3.json
└── ...
```

### 5.1.2 조건별 화면 상태 규칙

권한, 데이터 유무, 상태값 등 **조건에 따라 화면이 달라지는 모든 케이스**를 어노테이션으로 명확히 기술한다.

| 조건 유형 | 어노테이션에 명시할 내용 |
|-----------|------------------------|
| **Empty State** | 데이터 없을 때 표시할 UI, 안내 문구, CTA 버튼 |
| **Loading State** | 스켈레톤/스피너 위치, 로딩 중 인터랙션 비활성화 범위 |
| **Error State** | 에러 메시지 원문, 재시도 버튼, fallback UI |
| **권한별 분기** | 역할(Admin/User/Guest)에 따라 표시/숨김/비활성화 되는 요소 |
| **데이터 조건별 분기** | 값 유무, 범위, 상태값에 따라 달라지는 UI (e.g., 결제 완료/미완료) |
| **첫 방문 vs 재방문** | 온보딩 가이드, 튜토리얼 오버레이 표시 조건 |

- 각 조건별 분기를 어노테이션 카드의 **Design 탭 States** 섹션과 **Dev 탭 동작방식**에 구체적으로 기술
- 조건부 요소는 마커 Description에 `[조건]` prefix로 명시 (e.g., `[권한:Admin] 사용자 삭제 버튼`)

### 5.2 index.html 규칙

1. **`/u-skill-wireframe` 실행 시 항상 index.html + index.json도 함께 생성/갱신**
2. `2_Screen_UX.md`의 전체 화면 목록을 반영
3. IA의 도메인(AUTH, DASH 등)별로 그룹핑
4. **Grid View (기본)**: 각 화면의 축소 썸네일 프리뷰(`<iframe>` scale 0.25) + Screen ID + 화면명을 카드 그리드로 표시
5. **List View**: Screen ID, 화면명, Goal, Access Role을 리스트로 표시
6. **Grid/List 토글 버튼**: localStorage에 선호 뷰 저장
7. 검색 기능으로 화면 필터링 지원
8. 상단에 통계 표시 (전체 화면 수, 도메인별 수)
9. `data-search` 속성에 Screen ID + 이름 + 키워드를 포함하여 검색 범위 확장
10. **생성된 모든 와이어프레임 HTML(`S-NNNN.html`, `S-NNNN-T*.html`)로의 링크를 반드시 포함** — 새 와이어프레임 추가/삭제 시 index.html의 화면 카드 목록도 동기화
11. Tab 화면은 부모 화면 하위에 `.sub-card` 클래스로 들여쓰기 표시

### 5.3 JSON Export

각 와이어프레임 HTML과 동명의 `.json` 파일을 생성한다.

```json
{
  "document": "wireframe",
  "meta": {
    "screenId": "S-0010",
    "screenName": "로그인",
    "app": "web",
    "lastUpdated": "YYYY-MM-DD"
  },
  "annotations": [
    {
      "number": 1,
      "elementName": "이메일 입력 필드",
      "elementType": "input",
      "design": {
        "description": "사용자의 이메일 주소를 입력받는 필드",
        "requirements": ["FR-0010", "FT-0010", "US-0010"],
        "businessRules": ["이메일 형식 검증 (RFC 5322)", "최대 254자"],
        "states": ["Default", "Focus", "Error", "Disabled"],
        "connectedScreens": ["S-0020", "S-0030"],
        "role": "Public"
      },
      "dev": {
        "behavior": {
          "htmlType": "input[type=\"email\"]",
          "component": "EmailInput",
          "debounce": "300ms",
          "autoFocus": true,
          "autocomplete": "email"
        },
        "events": [
          { "event": "onChange", "handler": "handleEmailChange", "action": "입력값 state 업데이트 + 실시간 형식 검증" },
          { "event": "onBlur", "handler": "handleEmailBlur", "action": "전체 유효성 검증 실행 + 에러 표시" }
        ],
        "validation": [
          { "rule": "required", "condition": "빈 값", "message": "이메일을 입력해주세요" },
          { "rule": "format", "condition": "/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/", "message": "올바른 이메일 형식이 아닙니다" },
          { "rule": "maxLength", "condition": "254자 초과", "message": "이메일은 254자 이내로 입력해주세요" }
        ],
        "flow": ["사용자 입력", "onChange: 실시간 검증", "Valid? → 에러 해제 / 에러 표시", "onBlur: 최종 검증"],
        "api": { "method": "POST", "endpoint": "/api/v1/auth/login", "field": "body.email" },
        "dataBinding": { "state": "formState.email", "error": "formErrors.email" }
      }
    }
  ]
}
```

index.html의 JSON (`index.json`):

```json
{
  "document": "wireframe-index",
  "meta": {
    "app": "web",
    "totalScreens": 12,
    "lastUpdated": "YYYY-MM-DD"
  },
  "screens": [
    {
      "id": "S-0010",
      "name": "로그인",
      "goal": "이메일/비밀번호로 인증",
      "accessRole": "Public",
      "domain": "AUTH",
      "file": "S-0010.html"
    }
  ]
}
```

---

## 6. 체크리스트

### 와이어프레임 HTML 생성 시

**레이아웃**
- [ ] 단일 HTML 파일 완결 (외부 JS/CSS 없음, Pretendard CDN만 허용)
- [ ] **HTML/CSS div 기반 app-frame 레이아웃** — doc-header → stage(grid 1fr 280px) → spec-wrap → diagrams-section
- [ ] **doc-header**: sticky dark bar + Screen ID 배지, 화면명, URL Path, FT ID, 날짜, `index.html` 뒤로가기 버튼
- [ ] **app-frame**: 좌측 sidebar(196px) + 우측 app-main(pg-hdr + pg-body)
- [ ] **anno-panel**: 우측 280px Annotation Panel — 번호 어노테이션 + 비즈니스 룰
- [ ] Light/Dark 테마 토글 동작
- [ ] OS 테마 자동 감지 + localStorage 저장
- [ ] 모든 색상 CSS 변수 사용 (하드코딩 금지)

**어노테이션**
- [ ] **거의 모든 UI 요소**에 숫자 마커 부착 (순수 레이아웃 컨테이너만 제외, 누락보다 과잉 원칙)
- [ ] anno-panel에 번호 어노테이션(①②③) + 설명 나열
- [ ] 각 카드에 2-탭(Design/Dev) 구조 포함
- [ ] **Design 탭**: `[컴포넌트타입] 이름` 형식 Description 블록 + 요구사항, 연결 화면, 권한
- [ ] **Dev 탭**: 요소 유형별 필수 섹션 매트릭스에 따라 동작방식, 이벤트, Validation, 흐름도, 옵션값, 컬럼 정의, API, 데이터 바인딩 포함
- [ ] **Validation**: 입력 요소에 Rule type + 조건 + 에러 메시지 원문 포함
- [ ] **흐름도**: 인터랙션 요소(버튼, 폼, 모달 등)에 단계별 흐름 + 성공/에러 분기 포함
- [ ] **옵션값**: Select/Radio/Checkbox에 value + label + 조건 + data source 포함
- [ ] **Description 포맷**: `[컴포넌트타입]` 헤더 + bullet/sub 목록, 정책은 빨간 강조, 노출 문구는 따옴표
- [ ] Annotation Legend 섹션 포함 (범례 클릭 시 해당 카드로 스크롤)
- [ ] 마커 클릭 시 해당 카드 확장 + 스크롤 + 하이라이트

**명세 & 다이어그램**
- [ ] **spec-wrap**: 컴포넌트 명세 테이블 (컴포넌트, 타입, 기본값, 비고)
- [ ] **Condition Flow Chart** (필수): 조건 분기 로직을 SVG 또는 HTML로 시각화 — dg-start, dg-condition, dg-action, dg-error 노드 + dg-arrow 화살표
- [ ] **Sequential Diagram** (필수): 사용자↔시스템 인터랙션 시퀀스 — seq-actor, seq-lifeline, seq-msg, seq-msg-reply
- [ ] **UML Diagram** (해당 시): 상태 다이어그램, 클래스 관계도 등
- [ ] 각 다이어그램에 제목(diagram-title) + 범례(diagram-legend) 포함

**기타**
- [ ] 외부 URL에 `target="_blank" rel="noopener noreferrer"` 적용 (내부 `S-NNNN.html`/`index.html` 링크 제외)
- [ ] 반응형 대응 (@media max-width:768px)
- [ ] 인쇄 대응 (@media print)
- [ ] `<html lang="{{LANG}}">` 설정
- [ ] 동명의 `.json` 파일 생성 (dev 스펙 포함)
- [ ] **Tab UI가 있는 화면**: 각 탭별 HTML(`S-NNNN-T1.html`, ...)을 별도 생성
- [ ] **Tab 화면 상호 링크**: 부모↔탭 간 링크, 탭 화면 doc-header에 현재 탭 이름 표시
- [ ] **조건별 화면 상태**: Empty/Loading/Error/권한별/데이터 조건별 분기를 어노테이션에 명시
- [ ] **조건부 요소**: `[조건]` prefix로 마커 Description 기술

### index.html 생성 시
- [ ] 전체 화면 목록 반영 (2_Screen_UX.md 기준)
- [ ] 도메인별 그룹핑
- [ ] **Grid View**: iframe 축소 썸네일(scale 0.25) + Screen ID + 화면명 카드 그리드
- [ ] **List View**: Screen ID, 화면명, Goal, Access Role 리스트
- [ ] **Grid/List 토글 버튼** + localStorage 선호 뷰 저장
- [ ] 검색 기능 동작
- [ ] 통계 카드 표시 (전체 화면 수, 도메인별 수)
- [ ] Light/Dark 테마 토글 동작
- [ ] 반응형 대응
- [ ] 생성된 모든 와이어프레임 HTML(`S-NNNN.html`, `S-NNNN-T*.html` 포함)로의 링크 카드가 index.html에 포함됨
- [ ] 탭 화면은 부모 화면 하위에 `.sub-card` 들여쓰기로 표시
- [ ] 동명의 `index.json` 생성
