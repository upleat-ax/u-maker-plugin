# HTML Document Viewer Template

> SSoT 문서(.md + .json)를 사이드바 네비게이션 기반의 인터랙티브 HTML 뷰어로 변환할 때 사용하는 템플릿 표준.
> Light-first 테마 + Dark 모드 토글 지원. 다이어그램은 인라인 SVG로 작성 (Mermaid CDN 사용 금지).

---

## 1. 적용 규칙

| 조건 | 규칙 |
|------|------|
| **적용 대상** | SSoT 문서: SRS, ERD, API, Screen, IA, UXGuide, ScreenFlow, RTM 등 |
| **파일 경로** | 원본 .md 파일과 **동일한 경로**, 확장자만 `.html`로 변경 |
| **생성 시점** | `/u-skill-html-doc` 실행 시 |
| **내용 동기화** | `.md`/`.json`과 `.html`은 같은 데이터, 같은 버전 |
| **문서 언어** | `u-maker.config.json`의 `documentLanguage` 값에 따라 `<html lang>` 속성 및 모든 텍스트 언어 결정 |

### 경로 예시

```
.u-maker/docs/web/01-plan/1_SRS_RA.md
.u-maker/docs/web/01-plan/1_SRS_RA.json
.u-maker/docs/web/01-plan/1_SRS_RA.html   ← 생성 대상
```

---

## 2. HTML 템플릿 구조

모든 문서 뷰어 HTML은 아래 골격을 따른다:

```html
<!DOCTYPE html>
<html lang="{{LANG}}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{PROJECT_NAME}} {{DOC_TITLE}}</title>
<style>
/* Light Mode (default) */
:root {
  --primary: #2563eb;
  --primary-light: #dbeafe;
  --bg: #f8fafc;
  --sidebar-bg: #1e293b;
  --sidebar-text: #cbd5e1;
  --sidebar-active: #3b82f6;
  --card-bg: #ffffff;
  --border: #e2e8f0;
  --text: #1e293b;
  --text-secondary: #64748b;
  --must: #dc2626;
  --should: #f59e0b;
  --could: #22c55e;
  --tag-bg: #f1f5f9;
  --code-bg: #f1f5f9;
  --code-color: #7c3aed;
  --th-bg: #f1f5f9;
  --th-color: #475569;
  --hover-bg: #f8fafc;
  --detail-bg: #f8fafc;
  --detail-color: #334155;
  --br-bg: #fffbeb;
  --br-border: #f59e0b;
  --br-confirmed-bg: #f0fdf4;
  --br-confirmed-border: #22c55e;
  --br-confirmed-color: #15803d;
  /* SVG Diagram */
  --diagram-bg: #f8fafc;
  --diagram-node-bg: #ffffff;
  --diagram-node-border: #d1d5db;
  --diagram-accent-bg: #1e293b;
  --diagram-accent-text: #ffffff;
  --diagram-accent: #1e293b;
  --diagram-line: #9ca3af;
  --diagram-text: #1e293b;
  --diagram-text-sub: #6b7280;
  --diagram-label-bg: #f3f4f6;
}

/* Dark Mode */
[data-theme="dark"] {
  --primary: #60a5fa;
  --primary-light: #1e3a5f;
  --bg: #0f172a;
  --sidebar-bg: #020617;
  --sidebar-text: #94a3b8;
  --sidebar-active: #60a5fa;
  --card-bg: #1e293b;
  --border: #334155;
  --text: #e2e8f0;
  --text-secondary: #94a3b8;
  --must: #f87171;
  --should: #fbbf24;
  --could: #4ade80;
  --tag-bg: #334155;
  --code-bg: #0f172a;
  --code-color: #a78bfa;
  --th-bg: #0f172a;
  --th-color: #94a3b8;
  --hover-bg: #1e293b;
  --detail-bg: #1e293b;
  --detail-color: #cbd5e1;
  --br-bg: rgba(245,158,11,0.1);
  --br-border: #f59e0b;
  --br-confirmed-bg: rgba(34,197,94,0.1);
  --br-confirmed-border: #22c55e;
  --br-confirmed-color: #4ade80;
  /* SVG Diagram */
  --diagram-bg: #1e293b;
  --diagram-node-bg: #1e1e2e;
  --diagram-node-border: #3a3a4e;
  --diagram-accent-bg: #3b82f6;
  --diagram-accent-text: #ffffff;
  --diagram-accent: #3b82f6;
  --diagram-line: #4a4a5e;
  --diagram-text: #e4e4ed;
  --diagram-text-sub: #8b8ba0;
  --diagram-label-bg: #2a2a3a;
}

* { margin:0; padding:0; box-sizing:border-box; }
html { scroll-behavior:smooth; }
body { font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: var(--bg); color: var(--text); line-height:1.6; transition: background 0.3s, color 0.3s; }

/* Theme Toggle */
.theme-toggle {
  position:fixed; top:20px; right:20px; z-index:200;
  width:44px; height:44px; border-radius:50%;
  background:var(--card-bg); border:1px solid var(--border);
  cursor:pointer; display:flex; align-items:center; justify-content:center;
  font-size:20px; transition:all 0.3s;
  box-shadow:0 2px 12px rgba(0,0,0,0.15);
}
.theme-toggle:hover { border-color:var(--primary); transform:scale(1.1); }
.theme-toggle .icon { line-height:1; }

/* Sidebar */
.sidebar {
  position: fixed; top:0; left:0; width:280px; height:100vh;
  background: var(--sidebar-bg); color: var(--sidebar-text);
  overflow-y: auto; z-index:100; padding: 24px 0;
  transition: transform 0.3s;
}
.sidebar h2 { color:#fff; font-size:16px; padding:0 20px 16px; border-bottom:1px solid #334155; margin-bottom:12px; }
.sidebar .nav-group { margin-bottom:8px; }
.sidebar .nav-group-title { font-size:11px; text-transform:uppercase; letter-spacing:1px; color:#94a3b8; padding:8px 20px 4px; font-weight:600; }
.sidebar a { display:block; padding:6px 20px 6px 28px; color:var(--sidebar-text); text-decoration:none; font-size:13px; border-left:3px solid transparent; transition:all 0.2s; }
.sidebar a:hover { color:#fff; background:rgba(255,255,255,0.05); border-left-color:var(--sidebar-active); }
.sidebar a.active { color:#fff; background:rgba(59,130,246,0.15); border-left-color:var(--sidebar-active); }

/* Main */
.main { margin-left:280px; padding:32px 40px; max-width:1200px; }

/* Header */
.page-header { background:linear-gradient(135deg, #1e40af, #3b82f6); color:#fff; padding:40px; border-radius:16px; margin-bottom:32px; }
.page-header h1 { font-size:28px; margin-bottom:8px; }
.page-header .subtitle { font-size:14px; opacity:0.85; line-height:1.8; }
.page-header .version-badge { display:inline-block; background:rgba(255,255,255,0.2); padding:4px 12px; border-radius:20px; font-size:12px; margin-top:12px; }

/* Stats */
.stats-row { display:grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap:16px; margin-bottom:32px; }
.stat-card { background:var(--card-bg); border-radius:12px; padding:20px; box-shadow:0 1px 3px rgba(0,0,0,0.06); border:1px solid var(--border); text-align:center; transition:all 0.3s; }
.stat-card .stat-num { font-size:32px; font-weight:700; color:var(--primary); }
.stat-card .stat-label { font-size:13px; color:var(--text-secondary); margin-top:4px; }

/* Section */
.section { background:var(--card-bg); border-radius:12px; padding:28px; margin-bottom:24px; box-shadow:0 1px 3px rgba(0,0,0,0.06); border:1px solid var(--border); transition:all 0.3s; }
.section h2 { font-size:20px; color:var(--primary); margin-bottom:16px; padding-bottom:12px; border-bottom:2px solid var(--primary-light); }
.section h3 { font-size:16px; margin:20px 0 12px; color:var(--detail-color); }
.section h4 { font-size:14px; margin:16px 0 8px; color:var(--text-secondary); }

/* Table */
table { width:100%; border-collapse:collapse; font-size:13px; margin:12px 0; }
table th { background:var(--th-bg); color:var(--th-color); font-weight:600; padding:10px 12px; text-align:left; border-bottom:2px solid var(--border); white-space:nowrap; }
table td { padding:10px 12px; border-bottom:1px solid var(--border); vertical-align:top; }
table tr:hover td { background:var(--hover-bg); }
table code, .code { background:var(--code-bg); padding:2px 6px; border-radius:4px; font-size:12px; font-family:'Fira Code', monospace; color:var(--code-color); }

/* Priority badges */
.badge { display:inline-block; padding:2px 10px; border-radius:12px; font-size:11px; font-weight:600; }
.badge-must { background:rgba(220,38,38,0.1); color:var(--must); border:1px solid rgba(220,38,38,0.3); }
.badge-should { background:rgba(245,158,11,0.1); color:var(--should); border:1px solid rgba(245,158,11,0.3); }
.badge-could { background:rgba(34,197,94,0.1); color:var(--could); border:1px solid rgba(34,197,94,0.3); }

/* Collapsible */
details { margin:8px 0; }
details summary { cursor:pointer; padding:12px 16px; background:var(--detail-bg); border-radius:8px; font-weight:600; font-size:14px; color:var(--detail-color); border:1px solid var(--border); user-select:none; list-style:none; }
details summary::before { content:'▶'; display:inline-block; margin-right:8px; font-size:11px; transition:transform 0.2s; }
details[open] summary::before { transform:rotate(90deg); }
details summary:hover { background:var(--hover-bg); }
details .detail-content { padding:16px; border:1px solid var(--border); border-top:none; border-radius:0 0 8px 8px; background:var(--card-bg); }

/* Tags */
.tag { display:inline-block; background:var(--tag-bg); color:var(--text-secondary); padding:2px 8px; border-radius:4px; font-size:11px; margin:2px; }

/* Business rules */
.br-list { margin:12px 0; padding-left:0; list-style:none; }
.br-list li { padding:8px 12px; margin:4px 0; background:var(--br-bg); border-left:3px solid var(--br-border); border-radius:0 6px 6px 0; font-size:13px; }
.br-list li.confirmed { background:var(--br-confirmed-bg); border-left-color:var(--br-confirmed-border); }
.br-list li.confirmed::after { content:" ✓ confirmed"; font-size:11px; color:var(--br-confirmed-color); font-weight:600; }

/* Status flow */
.flow { display:flex; align-items:center; gap:8px; flex-wrap:wrap; margin:12px 0; }
.flow .step { background:var(--primary-light); color:var(--primary); padding:6px 14px; border-radius:20px; font-size:12px; font-weight:600; }
.flow .arrow { color:var(--text-secondary); font-size:16px; }

/* Mobile */
.menu-toggle { display:none; position:fixed; top:12px; left:12px; z-index:200; background:var(--primary); color:#fff; border:none; padding:8px 14px; border-radius:8px; cursor:pointer; font-size:14px; }
@media (max-width:900px) {
  .sidebar { transform:translateX(-100%); }
  .sidebar.open { transform:translateX(0); }
  .main { margin-left:0; padding:20px; }
  .menu-toggle { display:block; }
  .theme-toggle { top:12px; right:12px; width:36px; height:36px; font-size:16px; }
}

/* Scope chip */
.scope-confirmed { display:inline-block; background:rgba(37,99,235,0.1); color:var(--primary); padding:4px 12px; border-radius:6px; font-size:12px; font-weight:600; margin:2px; }
.scope-hold { display:inline-block; background:rgba(245,158,11,0.1); color:var(--should); padding:4px 12px; border-radius:6px; font-size:12px; font-weight:600; margin:2px; }
.scope-external { display:inline-block; background:rgba(124,58,237,0.1); color:var(--code-color); padding:4px 12px; border-radius:6px; font-size:12px; font-weight:600; margin:2px; }

/* Search */
.search-box { padding:8px 20px; margin-bottom:12px; }
.search-box input { width:100%; padding:8px 12px; background:#334155; border:1px solid #475569; border-radius:6px; color:#fff; font-size:13px; outline:none; }
.search-box input::placeholder { color:#94a3b8; }
.search-box input:focus { border-color:var(--sidebar-active); }

/* ID Links */
.id-link, .id-ref {
  color:var(--primary);
  text-decoration:none;
  font-family:'Fira Code', monospace;
  font-size:12px;
  font-weight:600;
  transition:color 0.2s;
}
.id-link:hover, .id-ref:hover { color:var(--primary); text-decoration:underline; }
tr:target { background:rgba(37,99,235,0.08); outline:2px solid var(--primary); outline-offset:-2px; }

/* ERD specific */
.entity-card { background:var(--card-bg); border:1px solid var(--border); border-radius:12px; padding:20px; margin-bottom:16px; transition:all 0.3s; }
.entity-card h3 { color:var(--primary); border-bottom:2px solid var(--primary-light); padding-bottom:8px; margin-bottom:12px; }
.field-type { font-family:'Fira Code', monospace; font-size:11px; background:var(--code-bg); padding:2px 6px; border-radius:4px; color:var(--code-color); }
.constraint-pk { color:var(--must); font-weight:700; }
.constraint-fk { color:var(--primary); font-weight:600; }
.constraint-unique { color:var(--code-color); font-weight:600; }
.constraint-idx { color:#059669; font-weight:600; }

/* API specific */
.method-get { background:rgba(37,99,235,0.1); color:var(--primary); padding:2px 8px; border-radius:4px; font-size:11px; font-weight:700; }
.method-post { background:rgba(34,197,94,0.1); color:var(--could); padding:2px 8px; border-radius:4px; font-size:11px; font-weight:700; }
.method-put { background:rgba(245,158,11,0.1); color:var(--should); padding:2px 8px; border-radius:4px; font-size:11px; font-weight:700; }
.method-patch { background:rgba(124,58,237,0.1); color:var(--code-color); padding:2px 8px; border-radius:4px; font-size:11px; font-weight:700; }
.method-delete { background:rgba(220,38,38,0.1); color:var(--must); padding:2px 8px; border-radius:4px; font-size:11px; font-weight:700; }
.endpoint-path { font-family:'Fira Code', monospace; font-size:13px; color:var(--text); }

/* Progress bar */
.progress-bar { background:var(--border); border-radius:8px; height:8px; overflow:hidden; margin:8px 0; }
.progress-fill { height:100%; border-radius:8px; background:linear-gradient(90deg, #2563eb, #3b82f6); transition:width .4s ease; }

/* SVG Diagram */
.diagram-wrap {
  background:var(--diagram-bg);
  border:1px solid var(--border);
  border-radius:12px;
  padding:24px;
  margin:16px 0;
  overflow-x:auto;
  text-align:center;
}
.diagram-wrap svg { max-width:100%; height:auto; }

/* Print */
@media print {
  .sidebar { display:none; }
  .main { margin-left:0; }
  .menu-toggle { display:none; }
  .theme-toggle { display:none; }
  .page-header { break-inside:avoid; }
  .section { break-inside:avoid; }
  body { background:#fff; color:#000; }
}
</style>
</head>
<body>
<button class="theme-toggle" id="themeToggle" onclick="toggleTheme()" aria-label="Toggle theme">
  <span class="icon" id="theme-icon">&#9789;</span>
</button>
<button class="menu-toggle" onclick="document.querySelector('.sidebar').classList.toggle('open')">☰ Menu</button>

<nav class="sidebar" id="sidebar">
  <h2>{{SIDEBAR_ICON}} {{DOC_TITLE}} {{VERSION}}</h2>
  <div class="search-box"><input type="text" id="navSearch" placeholder="Search..." oninput="filterNav(this.value)"></div>
  <!-- NAV GROUPS: 문서 구조에 따라 동적 생성 -->
</nav>

<main class="main">
  <!-- PAGE HEADER -->
  <div class="page-header" id="overview">
    <h1>{{DOC_TITLE}}</h1>
    <div class="subtitle">{{DOC_SUBTITLE}}</div>
    <span class="version-badge">{{VERSION}} · {{DATE}}</span>
  </div>

  <!-- STATS ROW (optional) -->
  <div class="stats-row">
    <!-- .stat-card 반복 -->
  </div>

  <!-- SECTIONS -->
  <div class="section" id="{{SECTION_ID}}">
    <h2>{{SECTION_TITLE}}</h2>
    <!-- section content: tables, br-list, flow, details, inline SVG diagrams 등 -->

    <!-- ID Linkable Table Row Example -->
    <!--
    <tr id="fr-0010">
      <td><a href="#fr-0010" class="id-link">FR-0010</a></td>
      <td>기능 설명</td>
      <td><a href="#us-0010" class="id-ref">US-0010</a></td>
    </tr>
    -->
  </div>

</main>

<script>
// Theme toggle
function toggleTheme() {
  var html = document.documentElement;
  var icon = document.getElementById('theme-icon');
  if (html.getAttribute('data-theme') === 'dark') {
    html.removeAttribute('data-theme');
    icon.innerHTML = '&#9789;';
    localStorage.setItem('doc-theme', 'light');
  } else {
    html.setAttribute('data-theme', 'dark');
    icon.innerHTML = '&#9788;';
    localStorage.setItem('doc-theme', 'dark');
  }
}
(function() {
  var saved = localStorage.getItem('doc-theme');
  if (saved === 'dark' || (!saved && matchMedia('(prefers-color-scheme:dark)').matches)) {
    document.documentElement.setAttribute('data-theme', 'dark');
    document.getElementById('theme-icon').innerHTML = '&#9788;';
  }
})();

// Smooth scroll
document.querySelectorAll('.sidebar a').forEach(function(a) {
  a.addEventListener('click', function(e) {
    e.preventDefault();
    var target = document.querySelector(this.getAttribute('href'));
    if (target) target.scrollIntoView({ behavior:'smooth', block:'start' });
    document.querySelector('.sidebar').classList.remove('open');
    document.querySelectorAll('.sidebar a').forEach(function(x) { x.classList.remove('active'); });
    this.classList.add('active');
  });
});

// Search filter
function filterNav(query) {
  var q = query.toLowerCase();
  document.querySelectorAll('.sidebar a').forEach(function(a) {
    a.style.display = a.textContent.toLowerCase().indexOf(q) !== -1 ? '' : 'none';
  });
}

// Scroll spy
var sections = document.querySelectorAll('.section, .page-header');
var navLinks = document.querySelectorAll('.sidebar a');
window.addEventListener('scroll', function() {
  var current = '';
  sections.forEach(function(s) {
    if (s.getBoundingClientRect().top < 150) current = s.id;
  });
  navLinks.forEach(function(a) {
    a.classList.remove('active');
    if (a.getAttribute('href') === '#' + current) a.classList.add('active');
  });
});
</script>
</body>
</html>
```

---

## 3. CSS 필수 규칙

| 항목 | 값 | 이유 |
|------|-----|------|
| 폰트 | `'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif` | 한국어 최적화 + 폴백 |
| CSS 위치 | `<style>` 블록 내 인라인 | 단일 파일 완결성 |
| max-width | `1200px` (main) | 가독성 |
| 사이드바 | Fixed 280px, dark bg (#1e293b) | 문서 네비게이션 |
| 테마 | Light-first + Dark 토글 (`:root` = 라이트, `[data-theme="dark"]` = 다크) | 문서 가독성 우선 + 다크 모드 대응 |
| 테마 감지 | `prefers-color-scheme:dark` 자동 감지 + `localStorage` 저장 | OS 설정 연동 |
| 언어 | `<html lang="{{LANG}}">` — `documentLanguage` 설정값 | 다국어 문서 지원 |
| 색상 | 모든 색상은 CSS 변수 사용 (`--primary`, `--bg` 등), 하드코딩 금지 | 테마 전환 대응 |
| JS | 테마 토글 + 네비게이션 + 검색 인라인만 (외부 JS 완전 금지) | 단일 파일 완결성 |
| 다이어그램 | 인라인 SVG (CSS 변수 사용, `--diagram-*`), Mermaid CDN 사용 금지 | 단일 파일 완결 + 테마 자동 전환 |
| ASCII art | ASCII art 레이아웃/다이어그램 → 인라인 SVG 변환 (`<pre>` 출력 금지, 소스 코드·폴더 트리·CLI 출력은 예외) | 시각적 품질 + 테마 대응 |
| 반응형 | `@media (max-width: 900px)` 사이드바 숨김 + 햄버거 메뉴 | 모바일 |
| 차트 | HTML/CSS + SVG만 사용 | 단일 파일 완결성 |
| 인쇄 | `@media print` 사이드바 숨김 | 인쇄 대응 |

---

## 4. 문서 유형별 매핑

### 4.1 SRS (1_SRS_RA)

| 구성 요소 | HTML 컴포넌트 |
|----------|--------------|
| 문서 개요 | `.page-header` |
| FR/NFR/US/FT 카운트 | `.stats-row` + `.stat-card` |
| 기준 소스 | `.section` + `table` |
| 범위 선언 | `.scope-confirmed`, `.scope-hold`, `.scope-external` |
| 사용자 유형 (USR) | `.section` + `table` + `.badge-must/should/could` |
| FR 요약 매트릭스 | `.section` + `table` |
| FR 상세 | `.section` + `table` + `.br-list` |
| 하위 FR | `table` 내 sub-table |
| Business Rules | `.br-list` (`.confirmed` for 확정 항목) |
| 상태 흐름 | `.flow` + `.step` + `.arrow` |
| NFR | `.section` + `table` |
| US 목록 | `.section` + `table` (세분화 행은 `opacity:0.5;font-style:italic`) |
| FT 목록 | `.section` + `table` (세분화 행은 `opacity:0.5;font-style:italic`) |
| 보류 범위 | `.section` + `table` + `.badge-must` (긴급) |
| Change Log | `.section` + `table` |

### 사이드바 네비게이션 구조 (SRS)

```html
<div class="nav-group">
  <div class="nav-group-title">Overview</div>
  <a href="#overview">Document Overview</a>
  <a href="#scope">Scope</a>
  <a href="#users">User Types</a>
  <a href="#schedule">Schedule</a>
</div>
<div class="nav-group">
  <div class="nav-group-title">FR</div>
  <a href="#fr-summary">FR Summary</a>
  <a href="#fr-0010">FR-0010 ...</a>
  <!-- FR별 반복 -->
</div>
<div class="nav-group">
  <div class="nav-group-title">Appendix</div>
  <a href="#nfr">NFR</a>
  <a href="#us">User Stories</a>
  <a href="#ft">Features</a>
  <a href="#hold">Hold Scope</a>
  <a href="#changelog">Change Log</a>
</div>
```

### 4.2 ERD (2_ERD_SA)

| 구성 요소 | HTML 컴포넌트 |
|----------|--------------|
| Entity 목록 | `.stats-row` 카운트 + `table` |
| Entity 상세 | `.entity-card` + 필드 `table` |
| 필드 타입 | `.field-type` |
| 제약조건 | `.constraint-pk`, `.constraint-fk`, `.constraint-unique`, `.constraint-idx` |
| 관계도 | `.flow` (Entity → Entity) |

### 4.3 API Contract (2_API_SA)

| 구성 요소 | HTML 컴포넌트 |
|----------|--------------|
| Endpoint 목록 | `.stats-row` 카운트 + `table` |
| HTTP Method | `.method-get/post/put/patch/delete` |
| Path | `.endpoint-path` |
| Request/Response | `details` (collapsible) + `code` 블록 |
| 에러 코드 | `table` |

### 4.4 Screen Design (2_Screen_UX)

| 구성 요소 | HTML 컴포넌트 |
|----------|--------------|
| 화면 목록 | `table` |
| 화면 상세 | `.section` + 구성요소 `table` |
| 인터랙션 | `.br-list` |
| 화면 흐름 | `.flow` |

### 4.5 IA (1_IA_RA)

| 구성 요소 | HTML 컴포넌트 |
|----------|--------------|
| 메뉴 구조 | nested `details` (collapsible tree) |
| 화면 매핑 | `table` |

### 4.6 RTM (2_RTM_RA)

| 구성 요소 | HTML 컴포넌트 |
|----------|--------------|
| 추적 매트릭스 | full-width `table` with cross-references |
| 커버리지 | `.progress-bar` + `.stat-card` |

---

## 5. 컴포넌트 레퍼런스

### 5.1 Stat Card

```html
<div class="stat-card">
  <div class="stat-num">33</div>
  <div class="stat-label">Functional Requirements</div>
</div>
```

### 5.2 Section with Table

```html
<div class="section" id="section-id">
  <h2>Section Title</h2>
  <table>
    <thead><tr><th>Col1</th><th>Col2</th></tr></thead>
    <tbody>
      <tr><td>Data</td><td>Data</td></tr>
    </tbody>
  </table>
</div>
```

### 5.3 Business Rules List

```html
<ul class="br-list">
  <li>Standard business rule</li>
  <li class="confirmed">Confirmed rule (with checkmark)</li>
</ul>
```

### 5.4 Priority Badge

```html
<span class="badge badge-must">Must</span>
<span class="badge badge-should">Should</span>
<span class="badge badge-could">Could</span>
```

### 5.5 Status Flow

```html
<div class="flow">
  <span class="step">Step 1</span>
  <span class="arrow">→</span>
  <span class="step">Step 2</span>
  <span class="arrow">→</span>
  <span class="step">Step 3</span>
</div>
```

### 5.6 Scope Chips

```html
<span class="scope-confirmed">Confirmed Scope</span>
<span class="scope-hold">On Hold</span>
<span class="scope-external">External</span>
```

### 5.7 Collapsible Details

```html
<details>
  <summary>Collapsible Section Title</summary>
  <div class="detail-content">
    <!-- content -->
  </div>
</details>
```

### 5.8 Tag

```html
<span class="tag">US-0010-01</span>
<span class="tag">FT-0010-01~04</span>
```

### 5.9 Entity Card (ERD)

```html
<div class="entity-card">
  <h3>Entity Name</h3>
  <table>
    <thead><tr><th>Field</th><th>Type</th><th>Constraint</th><th>Description</th></tr></thead>
    <tbody>
      <tr>
        <td><code>id</code></td>
        <td><span class="field-type">UUID</span></td>
        <td><span class="constraint-pk">PK</span></td>
        <td>Primary key</td>
      </tr>
      <tr>
        <td><code>user_id</code></td>
        <td><span class="field-type">UUID</span></td>
        <td><span class="constraint-fk">FK → User.id</span></td>
        <td>User reference</td>
      </tr>
    </tbody>
  </table>
</div>
```

### 5.10 API Endpoint (API Contract)

```html
<div class="section" id="api-endpoint-id">
  <h2><span class="method-get">GET</span> <span class="endpoint-path">/api/v1/contracts</span></h2>
  <table>
    <tbody>
      <tr><th style="width:120px">Description</th><td>Get list of contracts</td></tr>
      <tr><th>Auth</th><td>Bearer Token</td></tr>
      <tr><th>FT</th><td><span class="tag">FT-0220-03</span></td></tr>
    </tbody>
  </table>
  <details>
    <summary>Request Parameters</summary>
    <div class="detail-content">
      <table>
        <thead><tr><th>Param</th><th>Type</th><th>Required</th><th>Description</th></tr></thead>
        <tbody>
          <tr><td><code>page</code></td><td><span class="field-type">number</span></td><td>No</td><td>Page number</td></tr>
        </tbody>
      </table>
    </div>
  </details>
  <details>
    <summary>Response (200)</summary>
    <div class="detail-content">
      <pre><code>{ "data": [...], "meta": { "total": 100 } }</code></pre>
    </div>
  </details>
</div>
```

### 5.11 Deprecated/Refined Row

```html
<!-- 세분화된 항목 (opacity + italic) -->
<tr style="opacity:0.5;font-style:italic">
  <td><code>US-0210-01</code></td>
  <td>*(Refined → US-0210-04~05)*</td>
  <td>→ See child items</td>
</tr>
```

### 5.12 ID Linkable Table Row

ID가 부여된 항목(FR, US, FT, TC, NFR 등)의 테이블 행에 앵커 링크를 추가한다.

```html
<!-- 정의 위치: tr에 id, 첫 번째 셀에 self-link -->
<tr id="fr-0010">
  <td><a href="#fr-0010" class="id-link">FR-0010</a></td>
  <td>사용자 인증 처리</td>
  <td><span class="badge badge-must">Must</span></td>
</tr>

<!-- Mapping 컬럼: 다른 ID 참조 -->
<tr id="ft-0010">
  <td><a href="#ft-0010" class="id-link">FT-0010</a></td>
  <td>Login</td>
  <td><a href="#us-0010" class="id-ref">US-0010</a></td>
</tr>

<!-- 다른 문서 ID 참조 -->
<td><a href="2_RTM_RA.html#fr-0010" class="id-ref">FR-0010</a></td>
```

앵커 ID 규칙: prefix와 숫자를 소문자로 변환 (`FR-0010` → `fr-0010`). `tr:target` CSS로 URL 해시 이동 시 해당 행을 하이라이트한다.

### 5.13 Progress Bar

```html
<div class="progress-bar">
  <div class="progress-fill" style="width:75%"></div>
</div>
```

---

## 6. 체크리스트

### HTML 생성 시
- [ ] Pretendard 폰트 폴백 포함
- [ ] 모든 CSS는 `<style>` 블록 내
- [ ] 외부 JS 완전 미사용 (Mermaid CDN 포함 금지, 테마 토글 + 네비게이션/검색 인라인만)
- [ ] Light/Dark 테마 토글 버튼 포함 (원형 `button.theme-toggle`)
- [ ] Light-first: `:root` = 라이트, `[data-theme="dark"]` = 다크
- [ ] OS 설정 자동 감지 (`prefers-color-scheme:dark`) + `localStorage` 저장
- [ ] 하드코딩 색상 금지 — 모든 배경/테두리/텍스트는 CSS 변수 사용
- [ ] 다이어그램은 인라인 SVG (`<div class="diagram-wrap"><svg>...</svg></div>`)
- [ ] SVG 내 모든 색상은 CSS 변수 사용 (`var(--diagram-*)`) — 테마 자동 전환
- [ ] `.md`의 ` ```mermaid ``` ` 블록 → 의미 해석 후 인라인 SVG로 변환
- [ ] ASCII art (box-drawing 문자, pipe+dash 레이아웃) → 의미 해석 후 인라인 SVG로 변환 (`<pre>` 출력 금지, 소스 코드·폴더 트리·CLI 출력은 `<pre><code>` 허용)
- [ ] 반응형 대응 (`@media (max-width: 900px)`)
- [ ] 인쇄 대응 (`@media print` + 사이드바/토글 숨김)
- [ ] 단일 HTML 파일로 완결
- [ ] `.md`/`.json`과 동일한 데이터
- [ ] 사이드바 네비게이션에 전체 섹션 링크 포함
- [ ] 사이드바 검색 기능 동작
- [ ] 스크롤 스파이 동작 (현재 섹션 하이라이트)
- [ ] 모바일 햄버거 메뉴 동작
- [ ] `<html lang="{{LANG}}">` 설정
- [ ] 모든 레이블/제목은 `documentLanguage` 언어로 작성
- [ ] 문서 유형에 맞는 컴포넌트 사용 (SRS: br-list, ERD: entity-card, API: method badge 등)
- [ ] ID 항목(FR, US, FT, TC 등) 테이블 행에 `id` 속성 + `.id-link` self-link 포함
- [ ] Mapping 컬럼의 다른 ID 참조에 `.id-ref` 링크 포함 (같은 문서 `#id`, 다른 문서 `파일.html#id`)
- [ ] 원본 .md의 Change Log 섹션 포함
- [ ] version-badge에 올바른 버전 표시
