# HTML Report Standard

> 모든 리포트 문서(.md)는 동일한 내용의 `.html` 파일을 같은 경로에 함께 생성한다.
> HTML은 단일 파일로 완결되며, 외부 의존성 없이 브라우저에서 독립 표시 가능해야 한다.

---

## 1. 적용 규칙

| 조건 | 규칙 |
|------|------|
| **적용 대상** | 리포트 문서: `5_Report_PM` |
| **파일 경로** | 마크다운 파일과 **동일한 경로**, 확장자만 `.html`로 변경 |
| **생성 시점** | `.md` 파일 생성/갱신과 동시에 |
| **내용 동기화** | `.md`와 `.html`은 같은 데이터, 같은 버전 |

### 경로 예시

```
.u-maker/docs/common/05-act/5_Report_PM_202603081200.md
.u-maker/docs/common/05-act/5_Report_PM_202603081200.html
```

---

## 2. HTML 템플릿 구조

모든 리포트 HTML은 아래 골격을 따른다:

```html
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{PROJECT_NAME}} — {{REPORT_TITLE}}</title>
<style>
  /* Light Mode (default) */
  :root {
    --bg: #f8f9fb;
    --card: #ffffff;
    --border: #e2e6ea;
    --text: #1a1d21;
    --text2: #5a6170;
    --primary: #2563eb;
    --primary-bg: #eff4ff;
    --success: #16a34a;
    --success-bg: #ecfdf3;
    --warning: #d97706;
    --warning-bg: #fffbeb;
    --danger: #dc2626;
    --danger-bg: #fef2f2;
    --info: #7c3aed;
    --info-bg: #f5f0ff;
    --accent: #0891b2;
    --accent-bg: #ecfeff;
    --th-bg: #f1f3f6;
    --row-hover: #fafbfc;
    --row-border: #f1f3f6;
    --header-gradient-start: #1e293b;
    --header-gradient-end: #0f172a;
    --donut-text-fill: #1a1d21;
  }

  /* Dark Mode */
  [data-theme="dark"] {
    --bg: #0f1117;
    --card: #1a1d27;
    --border: #2d3348;
    --text: #e4e6eb;
    --text2: #9ca3b4;
    --primary: #60a5fa;
    --primary-bg: #1e2a4a;
    --success: #4ade80;
    --success-bg: #14291e;
    --warning: #fbbf24;
    --warning-bg: #2a2210;
    --danger: #f87171;
    --danger-bg: #2d1518;
    --info: #a78bfa;
    --info-bg: #1f1835;
    --accent: #22d3ee;
    --accent-bg: #0f2830;
    --th-bg: #1f2233;
    --row-hover: #1f2233;
    --row-border: #252939;
    --header-gradient-start: #0a0c14;
    --header-gradient-end: #060810;
    --donut-text-fill: #e4e6eb;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.6;
  }

  /* Theme Toggle */
  .theme-toggle {
    position: fixed;
    top: 16px;
    right: 16px;
    z-index: 1000;
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 13px;
    font-weight: 600;
    color: var(--text2);
    box-shadow: 0 2px 8px rgba(0,0,0,.1);
    transition: background .2s, color .2s, border-color .2s;
  }
  .theme-toggle:hover { background: var(--primary-bg); color: var(--primary); }
  .theme-toggle .icon { font-size: 18px; line-height: 1; }

  /* Header */
  .header {
    background: linear-gradient(135deg, var(--header-gradient-start) 0%, var(--header-gradient-end) 100%);
    color: #fff;
    padding: 48px 0 40px;
  }
  .header-inner {
    max-width: 1120px;
    margin: 0 auto;
    padding: 0 24px;
  }
  .header-badge {
    display: inline-block;
    background: rgba(255,255,255,.12);
    border: 1px solid rgba(255,255,255,.18);
    border-radius: 20px;
    padding: 4px 14px;
    font-size: 12px;
    font-weight: 600;
    letter-spacing: .5px;
    margin-bottom: 16px;
    backdrop-filter: blur(4px);
  }
  .header h1 {
    font-size: 32px;
    font-weight: 800;
    margin-bottom: 8px;
    letter-spacing: -.5px;
  }
  .header p { color: rgba(255,255,255,.65); font-size: 15px; }
  .header-meta {
    display: flex;
    gap: 24px;
    margin-top: 20px;
    flex-wrap: wrap;
  }
  .header-meta span {
    font-size: 13px;
    color: rgba(255,255,255,.5);
  }
  .header-meta strong { color: rgba(255,255,255,.9); }

  /* Container */
  .container {
    max-width: 1120px;
    margin: 0 auto;
    padding: 32px 24px 64px;
  }

  /* Section */
  .section { margin-bottom: 36px; }
  .section-title {
    font-size: 20px;
    font-weight: 700;
    margin-bottom: 16px;
    padding-bottom: 10px;
    border-bottom: 2px solid var(--primary);
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .section-title .num {
    background: var(--primary);
    color: #fff;
    width: 28px;
    height: 28px;
    border-radius: 8px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    font-weight: 700;
  }

  /* KPI Cards */
  .kpi-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 16px;
    margin-bottom: 32px;
  }
  .kpi-card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 14px;
    padding: 20px 24px;
    text-align: center;
    transition: box-shadow .15s;
  }
  .kpi-card:hover { box-shadow: 0 4px 16px rgba(0,0,0,.06); }
  .kpi-label { font-size: 13px; color: var(--text2); font-weight: 500; margin-bottom: 6px; }
  .kpi-value { font-size: 36px; font-weight: 800; letter-spacing: -1px; }
  .kpi-sub { font-size: 12px; color: var(--text2); margin-top: 4px; }
  .kpi-card.success .kpi-value { color: var(--success); }
  .kpi-card.primary .kpi-value { color: var(--primary); }
  .kpi-card.info .kpi-value { color: var(--info); }
  .kpi-card.accent .kpi-value { color: var(--accent); }
  .kpi-card.warning .kpi-value { color: var(--warning); }

  /* Gate Banner */
  .gate-banner {
    border-radius: 14px;
    padding: 24px 32px;
    margin-bottom: 36px;
    display: flex;
    align-items: center;
    gap: 16px;
  }
  .gate-banner.complete {
    background: var(--success-bg);
    border: 2px solid var(--success);
  }
  .gate-banner.in-progress {
    background: var(--warning-bg);
    border: 2px solid var(--warning);
  }
  .gate-icon { font-size: 40px; }
  .gate-text h3 { font-size: 18px; font-weight: 700; }
  .gate-banner.complete .gate-text h3 { color: var(--success); }
  .gate-banner.in-progress .gate-text h3 { color: var(--warning); }
  .gate-text p { font-size: 14px; color: var(--text2); margin-top: 2px; }

  /* Table */
  .table-wrap {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 14px;
    overflow: hidden;
    margin-bottom: 20px;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 14px;
  }
  thead th {
    background: var(--th-bg);
    padding: 12px 16px;
    text-align: left;
    font-weight: 600;
    font-size: 13px;
    color: var(--text2);
    white-space: nowrap;
    border-bottom: 1px solid var(--border);
  }
  tbody td {
    padding: 11px 16px;
    border-bottom: 1px solid var(--row-border);
    vertical-align: middle;
  }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: var(--row-hover); }
  tbody tr.total-row { background: var(--th-bg); font-weight: 700; }
  tbody tr.highlight-row { background: var(--primary-bg); }
  tbody tr.new-row { background: var(--warning-bg); }
  tbody tr.fixed-row { background: var(--success-bg); }

  /* Badges */
  .badge {
    display: inline-block;
    padding: 3px 10px;
    border-radius: 6px;
    font-size: 12px;
    font-weight: 600;
    white-space: nowrap;
  }
  .badge-success { background: var(--success-bg); color: var(--success); }
  .badge-primary { background: var(--primary-bg); color: var(--primary); }
  .badge-warning { background: var(--warning-bg); color: var(--warning); }
  .badge-danger { background: var(--danger-bg); color: var(--danger); }
  .badge-info { background: var(--info-bg); color: var(--info); }
  .badge-accent { background: var(--accent-bg); color: var(--accent); }
  .badge-gray { background: var(--th-bg); color: var(--text2); }

  /* Progress Bar */
  .progress-bar {
    background: var(--border);
    border-radius: 8px;
    height: 10px;
    overflow: hidden;
    width: 100%;
  }
  .progress-fill {
    height: 100%;
    border-radius: 8px;
    background: linear-gradient(90deg, var(--success), #22c55e);
    transition: width .4s ease;
  }

  /* Chart */
  .chart-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    margin-bottom: 20px;
  }
  @media (max-width: 700px) { .chart-row { grid-template-columns: 1fr; } }
  .chart-card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 14px;
    padding: 24px;
  }
  .chart-card h4 { font-size: 15px; font-weight: 600; margin-bottom: 16px; }

  /* Bar chart */
  .bar-chart { display: flex; flex-direction: column; gap: 10px; }
  .bar-row { display: flex; align-items: center; gap: 10px; }
  .bar-label { width: 100px; font-size: 12px; font-weight: 500; text-align: right; color: var(--text2); flex-shrink: 0; }
  .bar-track { flex: 1; background: var(--th-bg); border-radius: 6px; height: 22px; position: relative; overflow: hidden; }
  .bar-fill { height: 100%; border-radius: 6px; display: flex; align-items: center; padding-left: 8px; font-size: 11px; font-weight: 700; color: #fff; min-width: 32px; }
  .bar-fill.green { background: linear-gradient(90deg, #16a34a, #22c55e); }
  .bar-fill.blue { background: linear-gradient(90deg, #2563eb, #60a5fa); }
  .bar-fill.purple { background: linear-gradient(90deg, #7c3aed, #a78bfa); }
  .bar-fill.teal { background: linear-gradient(90deg, #0891b2, #22d3ee); }
  .bar-fill.orange { background: linear-gradient(90deg, #d97706, #fbbf24); }

  /* Donut */
  .donut-wrap { display: flex; align-items: center; justify-content: center; gap: 32px; }
  .donut-svg { width: 140px; height: 140px; }
  .donut-legend { font-size: 13px; }
  .donut-legend li { list-style: none; padding: 4px 0; display: flex; align-items: center; gap: 8px; }
  .donut-legend .dot { width: 10px; height: 10px; border-radius: 3px; display: inline-block; flex-shrink: 0; }

  /* Timeline */
  .timeline { position: relative; padding-left: 28px; }
  .timeline::before {
    content: '';
    position: absolute;
    left: 9px;
    top: 4px;
    bottom: 4px;
    width: 2px;
    background: var(--border);
  }
  .tl-item { position: relative; padding-bottom: 20px; }
  .tl-item:last-child { padding-bottom: 0; }
  .tl-dot {
    position: absolute;
    left: -24px;
    top: 4px;
    width: 14px;
    height: 14px;
    border-radius: 50%;
    border: 3px solid var(--primary);
    background: var(--card);
  }
  .tl-item.done .tl-dot { background: var(--success); border-color: var(--success); }
  .tl-label { font-size: 12px; color: var(--text2); }
  .tl-title { font-size: 14px; font-weight: 600; }
  .tl-desc { font-size: 13px; color: var(--text2); margin-top: 2px; }

  /* FT Detail Cards */
  .ft-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; margin-bottom: 20px; }
  .ft-card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 20px;
    transition: box-shadow .15s;
  }
  .ft-card:hover { box-shadow: 0 4px 16px rgba(0,0,0,.06); }
  .ft-card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 10px; }
  .ft-card h5 { font-size: 15px; font-weight: 700; }
  .ft-card ul { margin: 0; padding-left: 18px; font-size: 13px; color: var(--text2); }
  .ft-card li { padding: 2px 0; }

  /* Compare / Trend */
  .compare-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    margin-bottom: 20px;
  }
  @media (max-width: 700px) { .compare-row { grid-template-columns: 1fr; } }
  .trend-bar-group {
    display: flex;
    align-items: flex-end;
    gap: 4px;
  }
  .trend-bar {
    border-radius: 4px 4px 0 0;
    min-width: 28px;
    display: flex;
    align-items: flex-end;
    justify-content: center;
    font-size: 10px;
    font-weight: 700;
    color: #fff;
    padding-bottom: 4px;
  }
  .trend-bar.prev { background: var(--border); color: var(--text2); }
  .trend-bar.curr.green { background: linear-gradient(180deg, #16a34a, #22c55e); }
  .trend-bar.curr.blue { background: linear-gradient(180deg, #2563eb, #60a5fa); }
  .trend-bar.curr.purple { background: linear-gradient(180deg, #7c3aed, #a78bfa); }
  .trend-bar.curr.teal { background: linear-gradient(180deg, #0891b2, #22d3ee); }
  .trend-chart {
    display: flex;
    align-items: flex-end;
    gap: 24px;
    justify-content: center;
    padding: 20px 0 8px;
    min-height: 160px;
  }
  .trend-chart-label {
    text-align: center;
    font-size: 11px;
    font-weight: 600;
    color: var(--text2);
    margin-top: 6px;
  }
  .trend-legend {
    display: flex;
    gap: 20px;
    justify-content: center;
    font-size: 12px;
    color: var(--text2);
    margin-bottom: 12px;
  }
  .trend-legend span { display: flex; align-items: center; gap: 6px; }
  .trend-legend .dot-prev { width: 12px; height: 12px; border-radius: 3px; background: var(--border); }
  .trend-legend .dot-curr { width: 12px; height: 12px; border-radius: 3px; background: var(--primary); }
  .delta-up { color: var(--success); font-weight: 700; }
  .delta-down { color: var(--danger); font-weight: 700; }
  .delta-same { color: var(--text2); }

  /* Git Activity */
  .git-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 12px;
    margin-bottom: 20px;
  }
  .git-stat-card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 16px;
    text-align: center;
  }
  .git-stat-card .stat-value { font-size: 28px; font-weight: 800; color: var(--primary); }
  .git-stat-card .stat-label { font-size: 12px; color: var(--text2); margin-top: 4px; }

  /* Section Count Badge */
  .section-count {
    display: inline-flex;
    gap: 12px;
    margin-bottom: 12px;
    flex-wrap: wrap;
  }
  .section-count .count-item {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 6px 14px;
    font-size: 13px;
    font-weight: 600;
  }
  .section-count .count-item strong { color: var(--primary); }

  /* Summary Box */
  .summary-box {
    background: linear-gradient(135deg, var(--header-gradient-start) 0%, var(--header-gradient-end) 100%);
    color: #fff;
    border-radius: 14px;
    padding: 28px 32px;
    margin-top: 36px;
  }
  .summary-box h3 { font-size: 16px; font-weight: 700; margin-bottom: 16px; color: rgba(255,255,255,.9); border-bottom: 1px solid rgba(255,255,255,.15); padding-bottom: 10px; }
  .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; }
  .summary-item { font-size: 13px; }
  .summary-item .s-label { color: rgba(255,255,255,.5); font-size: 12px; margin-bottom: 4px; }
  .summary-item .s-value { color: rgba(255,255,255,.9); font-weight: 600; }
  .summary-item .s-value.green { color: #4ade80; }
  .summary-item .s-value.blue { color: #60a5fa; }
  .summary-item .s-value.yellow { color: #fbbf24; }

  /* Footer */
  .footer {
    text-align: center;
    padding: 24px;
    font-size: 12px;
    color: var(--text2);
    border-top: 1px solid var(--border);
    margin-top: 40px;
  }

  /* Print */
  @media print {
    body { background: #fff; }
    .header { padding: 24px 0; }
    .kpi-card, .chart-card, .ft-card, .table-wrap { break-inside: avoid; }
    .theme-toggle { display: none; }
  }

  /* Responsive */
  @media (max-width: 768px) {
    .header-inner { padding: 0 16px; }
    .header h1 { font-size: 24px; }
    .container { padding: 16px; }
    .kpi-grid { grid-template-columns: repeat(2, 1fr); }
    .ft-grid { grid-template-columns: 1fr; }
    .header-meta { flex-direction: column; gap: 8px; }
    table { font-size: 12px; }
    thead th, tbody td { padding: 8px 10px; }
    .summary-grid { grid-template-columns: repeat(2, 1fr); }
  }
</style>
</head>
<body>

<!-- THEME TOGGLE -->
<button class="theme-toggle" onclick="toggleTheme()" aria-label="Toggle dark mode">
  <span class="icon" id="theme-icon">&#9789;</span>
</button>

<!-- HEADER -->
<div class="header">
  <div class="header-inner">
    <span class="header-badge">PDCA Iteration {{ITERATION}} &middot; {{STATUS}}</span>
    <h1>{{PROJECT_NAME}} — 종합 보고서</h1>
    <p>{{SUMMARY_LINE}}</p>
    <div class="header-meta">
      <span>기준일 <strong>{{DATE}}</strong></span>
      <!-- ... KPI meta items ... -->
    </div>
  </div>
</div>

<div class="container">

  <!-- GATE BANNER -->
  <div class="gate-banner {{complete|in-progress}}">
    <div class="gate-icon">{{icon}}</div>
    <div class="gate-text">
      <h3>Gate 판정: {{STATUS}}</h3>
      <p>{{GATE_DESCRIPTION}}</p>
    </div>
  </div>

  <!-- KPI CARDS -->
  <div class="kpi-grid">
    <!-- .kpi-card 반복 -->
  </div>

  <!-- SECTIONS 1~10 -->
  <div class="section">
    <h2 class="section-title"><span class="num">N</span> Section Title</h2>
    <!-- section content -->
  </div>

  <!-- SUMMARY BOX -->
  <div class="summary-box">
    <h3>Post-Execution Summary</h3>
    <div class="summary-grid">
      <!-- .summary-item 반복 -->
    </div>
  </div>

</div>

<div class="footer">
  {{PROJECT_NAME}} — Iteration {{ITERATION}} 종합 보고서 &middot; {{DATE}} &middot; u-agent-pm
</div>

<script>
function toggleTheme() {
  var html = document.documentElement;
  var icon = document.getElementById('theme-icon');
  if (html.getAttribute('data-theme') === 'dark') {
    html.removeAttribute('data-theme');
    icon.innerHTML = '&#9789;';
    localStorage.setItem('theme', 'light');
  } else {
    html.setAttribute('data-theme', 'dark');
    icon.innerHTML = '&#9788;';
    localStorage.setItem('theme', 'dark');
  }
}
(function() {
  var saved = localStorage.getItem('theme');
  if (saved === 'dark' || (!saved && matchMedia('(prefers-color-scheme:dark)').matches)) {
    document.documentElement.setAttribute('data-theme', 'dark');
    document.getElementById('theme-icon').innerHTML = '&#9788;';
  }
})();
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
| max-width | `1120px` | 가독성 |
| 테마 | Light(기본) + Dark (`[data-theme="dark"]`) | 사용자 선호 대응 |
| 테마 감지 | `prefers-color-scheme` 자동 감지 + `localStorage` 저장 | OS 설정 연동 |
| 색상 | 모든 색상은 CSS 변수(`--bg`, `--card` 등) 사용, 하드코딩 금지 | 테마 전환 대응 |
| JS | 테마 토글 인라인 스크립트만 허용 (외부 JS 라이브러리 금지) | 단일 파일 완결성 |
| 반응형 | `@media (max-width: 768px)` 최소 대응 | 모바일 접근 |
| 차트 | HTML/CSS + SVG만 사용 | 단일 파일 완결성 |
| 인쇄 | `@media print` 최소 대응 + 토글 숨김 | 인쇄 시 깨짐 방지 |

---

## 4. 컴포넌트 레퍼런스

### 4.1 Theme Toggle

```html
<!-- body 최상단에 배치 -->
<button class="theme-toggle" onclick="toggleTheme()" aria-label="Toggle dark mode">
  <span class="icon" id="theme-icon">&#9789;</span>
</button>
```

```html
<!-- </body> 직전에 배치 -->
<script>
function toggleTheme() {
  var html = document.documentElement;
  var icon = document.getElementById('theme-icon');
  if (html.getAttribute('data-theme') === 'dark') {
    html.removeAttribute('data-theme');
    icon.innerHTML = '&#9789;';
    localStorage.setItem('theme', 'light');
  } else {
    html.setAttribute('data-theme', 'dark');
    icon.innerHTML = '&#9788;';
    localStorage.setItem('theme', 'dark');
  }
}
(function() {
  var saved = localStorage.getItem('theme');
  if (saved === 'dark' || (!saved && matchMedia('(prefers-color-scheme:dark)').matches)) {
    document.documentElement.setAttribute('data-theme', 'dark');
    document.getElementById('theme-icon').innerHTML = '&#9788;';
  }
})();
</script>
```

동작: OS 다크모드 설정 자동 감지 → 토글 클릭 시 전환 → `localStorage`에 저장 → 재방문 시 유지.

아이콘: Light 모드일 때 `☽` (9789), Dark 모드일 때 `☀` (9788).

### 4.2 Header

```html
<div class="header">
  <div class="header-inner">
    <span class="header-badge">PDCA Iteration N &middot; STATUS</span>
    <h1>프로젝트명 — 종합 보고서</h1>
    <p>요약 한 줄</p>
    <div class="header-meta">
      <span>기준일 <strong>2026-03-08</strong></span>
      <span>빌드 <strong>64 routes</strong></span>
      <!-- ... -->
    </div>
  </div>
</div>
```

### 4.3 Gate Banner

```html
<!-- COMPLETE -->
<div class="gate-banner complete">
  <div class="gate-icon">&#10003;</div>
  <div class="gate-text">
    <h3>Gate 판정: COMPLETE</h3>
    <p>판정 근거 설명</p>
  </div>
</div>

<!-- IN PROGRESS -->
<div class="gate-banner in-progress">
  <div class="gate-icon">&#9888;</div>
  <div class="gate-text">
    <h3>Gate 판정: IN PROGRESS</h3>
    <p>미충족 조건 설명</p>
  </div>
</div>
```

### 4.4 KPI Card

```html
<div class="kpi-card success">
  <div class="kpi-label">FR 구현률</div>
  <div class="kpi-value">100%</div>
  <div class="kpi-sub">15 / 15 FR</div>
</div>
```

Colors: `success` (green), `primary` (blue), `info` (purple), `accent` (teal), `warning` (orange).

### 4.5 Section Title

```html
<h2 class="section-title"><span class="num">1</span> Section Name</h2>
```

### 4.6 Table

```html
<div class="table-wrap">
  <table>
    <thead><tr><th>Col</th></tr></thead>
    <tbody>
      <tr><td>Data</td></tr>
      <tr class="new-row"><td>신규 항목</td></tr>
      <tr class="fixed-row"><td>해결된 항목</td></tr>
      <tr class="total-row"><td>합계</td></tr>
    </tbody>
  </table>
</div>
```

### 4.7 FT Card

```html
<div class="ft-grid">
  <div class="ft-card">
    <div class="ft-card-header">
      <h5>FR-0910 상조상품관리</h5>
      <span class="badge badge-primary">신규 TC 6건</span>
    </div>
    <ul>
      <li>항목 1</li>
      <li>항목 2</li>
    </ul>
  </div>
</div>
```

### 4.8 Donut Chart (SVG)

```html
<div class="donut-wrap">
  <svg class="donut-svg" viewBox="0 0 42 42">
    <circle cx="21" cy="21" r="15.9" fill="transparent" stroke="var(--border)" stroke-width="4"/>
    <circle cx="21" cy="21" r="15.9" fill="transparent" stroke="var(--primary)" stroke-width="4"
            stroke-dasharray="79.5 20.5" stroke-dashoffset="25" stroke-linecap="round"/>
    <text x="21" y="22.5" text-anchor="middle" font-size="6" font-weight="800" fill="var(--donut-text-fill)">156</text>
  </svg>
  <ul class="donut-legend">
    <li><span class="dot" style="background:#2563eb"></span> Unit Test — <strong>124</strong>건</li>
  </ul>
</div>
```

### 4.9 Bar Chart

```html
<div class="bar-chart">
  <div class="bar-row">
    <div class="bar-label">Label</div>
    <div class="bar-track"><div class="bar-fill green" style="width:80%">80건</div></div>
  </div>
</div>
```

Colors: `green`, `blue`, `purple`, `teal`, `orange`.

### 4.10 Timeline

```html
<div class="timeline">
  <div class="tl-item done">
    <div class="tl-dot"></div>
    <div class="tl-label">Iteration 1 / 2026-03-07</div>
    <div class="tl-title">제목</div>
    <div class="tl-desc">설명</div>
  </div>
</div>
```

### 4.11 Summary Box

```html
<div class="summary-box">
  <h3>Post-Execution Summary</h3>
  <div class="summary-grid">
    <div class="summary-item">
      <div class="s-label">Iteration</div>
      <div class="s-value blue">7 (COMPLETE)</div>
    </div>
  </div>
</div>
```

Value colors: `green`, `blue`, `yellow`.

### 4.12 Trend Compare Chart

```html
<div class="chart-card">
  <h4>이전 vs 현재 비교</h4>
  <div class="trend-legend">
    <span><span class="dot-prev"></span> 이전</span>
    <span><span class="dot-curr"></span> 현재</span>
  </div>
  <div class="trend-chart">
    <div>
      <div class="trend-bar-group">
        <div class="trend-bar prev" style="height:60px">9</div>
        <div class="trend-bar curr blue" style="height:80px">12</div>
      </div>
      <div class="trend-chart-label">FR</div>
    </div>
    <div>
      <div class="trend-bar-group">
        <div class="trend-bar prev" style="height:40px">3</div>
        <div class="trend-bar curr purple" style="height:50px">5</div>
      </div>
      <div class="trend-chart-label">NFR</div>
    </div>
    <!-- US, FT, TC 반복 -->
  </div>
</div>
```

바 높이 계산: `max(20px, (값 / 최대값) * 120px)`. 최대값은 모든 항목 중 가장 큰 수.

### 4.13 Compare Table (Delta)

```html
<div class="table-wrap">
  <table>
    <thead><tr><th>항목</th><th>이전</th><th>현재</th><th>변화</th></tr></thead>
    <tbody>
      <tr>
        <td>FR (구현/전체)</td>
        <td>9/12</td>
        <td>12/15</td>
        <td><span class="delta-up">+3/+3 ▲</span></td>
      </tr>
      <tr>
        <td>결함 Open</td>
        <td>5</td>
        <td>2</td>
        <td><span class="delta-up">-3 ▼</span></td>
      </tr>
    </tbody>
  </table>
</div>
```

Delta 규칙: 개선이면 `.delta-up`, 악화면 `.delta-down`, 동일하면 `.delta-same`.

### 4.14 Section Count Badge

```html
<div class="section-count">
  <span class="count-item">전체 <strong>15</strong>건</span>
  <span class="count-item">구현 완료 <strong>12</strong>건</span>
  <span class="count-item">미구현 <strong>3</strong>건</span>
</div>
```

각 섹션(FR/NFR/US/FT/TC) 테이블 상단에 배치.

### 4.15 Git Stats Cards

```html
<div class="git-stats">
  <div class="git-stat-card">
    <div class="stat-value">47</div>
    <div class="stat-label">총 커밋</div>
  </div>
  <div class="git-stat-card">
    <div class="stat-value">23</div>
    <div class="stat-label">변경 파일</div>
  </div>
  <div class="git-stat-card">
    <div class="stat-value">+1,245</div>
    <div class="stat-label">추가 라인</div>
  </div>
  <div class="git-stat-card">
    <div class="stat-value">-312</div>
    <div class="stat-label">삭제 라인</div>
  </div>
</div>
```

### 4.16 Badge

```html
<span class="badge badge-success">Complete</span>
<span class="badge badge-primary">Iter 7 신규</span>
<span class="badge badge-warning">Should</span>
<span class="badge badge-danger">Must</span>
<span class="badge badge-info">Backend</span>
<span class="badge badge-accent">Mock Stable</span>
<span class="badge badge-gray">Could</span>
```

---

## 5. 생성 순서

리포트 생성 시 아래 순서를 반드시 준수한다:

```
1. SSoT 데이터 수집 (문서 읽기 + git log)
2. .md 파일 생성/갱신
3. .html 파일 생성/갱신 (이 문서의 규칙)
```

---

## 6. 체크리스트

### HTML 생성 시
- [ ] Pretendard 폰트 폴백 (`'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`)
- [ ] 모든 CSS는 `<style>` 블록 내
- [ ] 외부 JS 라이브러리 미사용 (테마 토글 인라인 JS만 허용)
- [ ] 반응형 최소 대응 (`@media (max-width: 768px)`)
- [ ] 인쇄 대응 (`@media print` + 토글 숨김)
- [ ] 단일 HTML 파일로 완결
- [ ] `.md`와 동일한 데이터
- [ ] 테이블/차트는 HTML/CSS/SVG로 구현
- [ ] Dark/Light 테마 토글 버튼 (`button.theme-toggle`) 포함
- [ ] `[data-theme="dark"]` CSS 변수 오버라이드 포함
- [ ] OS 설정 자동 감지 (`prefers-color-scheme`) + `localStorage` 저장
- [ ] 하드코딩 색상 금지 — 모든 배경/테두리/텍스트는 CSS 변수 사용
- [ ] SVG 내 텍스트 `fill`은 `var(--donut-text-fill)` 또는 CSS `currentColor` 사용
- [ ] Gate Banner 표시 (complete / in-progress)
- [ ] KPI Cards에 FR/NFR/US/FT/TC/결함/빌드 전체 카운트 표시
- [ ] 이전 보고서 비교 — 트렌드 차트 + 비교 테이블 (이전 없으면 "첫 번째 보고서" 표시)
- [ ] 각 섹션 테이블 상단에 `.section-count` 전체 카운트 뱃지
- [ ] Git 활동 요약 — 커밋 분류 도넛 + 기여자 테이블 + 변경 통계
- [ ] Post-Execution Summary Box 포함 (이전 대비 변화량 표시)
- [ ] Footer에 프로젝트명 + 날짜
