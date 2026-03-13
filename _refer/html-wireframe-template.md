# HTML Wireframe Template

> 화면 와이어프레임 HTML 생성 표준. 각 UI 요소에 원 숫자(①②③...) 어노테이션 마커를 부착하고,
> 클릭 시 팝업으로 상세 설명(요구사항, 흐름도, 비즈니스 룰 등)을 표시한다.
> 와이어프레임 디렉토리에 `index.html`을 생성하여 전체 화면 목록을 탐색할 수 있도록 한다.

---

## 1. 적용 규칙

| 조건 | 규칙 |
|------|------|
| **적용 대상** | 화면별 와이어프레임 HTML (`S-NNNN.html`) + 인덱스 (`index.html`) |
| **파일 경로** | `.u-maker/docs/{app}/02-design/2_Screen_Wireframes/` |
| **생성 시점** | `/u-skill-wireframe` 실행 시 |
| **문서 언어** | `u-maker.config.json`의 `documentLanguage` 값에 따라 결정 |
| **단일 파일** | 각 HTML은 외부 의존성 없이 단일 파일로 완결 (Pretendard CDN만 허용) |

### 파일 구조

```
.u-maker/docs/{app}/02-design/2_Screen_Wireframes/
├── index.html          ← 전체 화면 목록 + 네비게이션
├── S-0010.html         ← 개별 화면 와이어프레임
├── S-0010.json         ← 동명 JSON
├── S-0020.html
├── S-0020.json
└── ...
```

---

## 2. 어노테이션 시스템

### 2.1 원 숫자 마커 (Annotation Marker)

각 와이어프레임의 주요 UI 요소에 원 숫자 마커를 부착한다. 마커는 해당 요소의 우상단에 absolute 배치한다.

```html
<!-- 어노테이션 마커: 요소를 감싸는 wrapper에 부착 -->
<div class="wf-element" data-annotation="1">
  <span class="annotation-marker" data-target="annotation-1">&#9312;</span>
  <!-- 실제 UI 요소 -->
  <div class="wf-input">이메일 입력</div>
</div>
```

#### 원 숫자 문자 매핑

| 번호 | HTML Entity | 문자 |
|------|-------------|------|
| 1 | `&#9312;` | ① |
| 2 | `&#9313;` | ② |
| 3 | `&#9314;` | ③ |
| 4 | `&#9315;` | ④ |
| 5 | `&#9316;` | ⑤ |
| 6 | `&#9317;` | ⑥ |
| 7 | `&#9318;` | ⑦ |
| 8 | `&#9319;` | ⑧ |
| 9 | `&#9320;` | ⑨ |
| 10 | `&#9321;` | ⑩ |
| 11~20 | `&#9322;`~`&#9331;` | ⑪~⑳ |

### 2.2 어노테이션 팝업 (Annotation Popup)

마커 클릭 시 팝업을 표시한다. 팝업에는 해당 요소의 상세 정보를 포함한다.

```html
<!-- 팝업 컨테이너: body 하단에 모아둔다 -->
<div class="annotation-popup" id="annotation-1">
  <div class="popup-header">
    <span class="popup-number">&#9312;</span>
    <h4 class="popup-title">이메일 입력 필드</h4>
    <button class="popup-close" onclick="closePopup('annotation-1')">&times;</button>
  </div>
  <div class="popup-body">
    <!-- 설명 -->
    <div class="popup-section">
      <h5>설명</h5>
      <p>사용자의 이메일 주소를 입력받는 필드. 로그인 및 회원가입 시 사용된다.</p>
    </div>

    <!-- 관련 요구사항 -->
    <div class="popup-section">
      <h5>요구사항</h5>
      <ul class="popup-tags">
        <li><span class="popup-tag tag-fr">FR-0010</span> 사용자 인증</li>
        <li><span class="popup-tag tag-ft">FT-0010</span> 이메일 로그인</li>
        <li><span class="popup-tag tag-us">US-0010</span> 로그인 사용자 스토리</li>
      </ul>
    </div>

    <!-- 비즈니스 룰 -->
    <div class="popup-section">
      <h5>비즈니스 룰</h5>
      <ul class="popup-rules">
        <li>이메일 형식 검증 (RFC 5322)</li>
        <li>최대 254자 제한</li>
        <li>빈 값 제출 시 인라인 에러 표시</li>
      </ul>
    </div>

    <!-- 흐름 (선택) -->
    <div class="popup-section">
      <h5>흐름</h5>
      <div class="popup-flow">
        <span class="flow-step">입력</span>
        <span class="flow-arrow">→</span>
        <span class="flow-step">유효성 검증</span>
        <span class="flow-arrow">→</span>
        <span class="flow-step">API 호출</span>
        <span class="flow-arrow">→</span>
        <span class="flow-step">성공/실패</span>
      </div>
    </div>

    <!-- 상태 (선택) -->
    <div class="popup-section">
      <h5>상태</h5>
      <table class="popup-table">
        <tr><td class="state-label">Default</td><td>빈 입력 필드 + placeholder</td></tr>
        <tr><td class="state-label">Focus</td><td>테두리 강조 + label 상단 이동</td></tr>
        <tr><td class="state-label">Error</td><td>빨간 테두리 + 에러 메시지</td></tr>
        <tr><td class="state-label">Disabled</td><td>회색 배경 + 입력 불가</td></tr>
      </table>
    </div>

    <!-- 연결 화면 (선택) -->
    <div class="popup-section">
      <h5>연결 화면</h5>
      <ul class="popup-links">
        <li><a href="S-0020.html">S-0020 회원가입</a> — "회원가입" 링크 클릭 시</li>
        <li><a href="S-0030.html">S-0030 비밀번호 찾기</a> — "비밀번호 찾기" 클릭 시</li>
      </ul>
    </div>
  </div>
</div>
```

### 2.3 팝업 내용 구성 규칙

각 어노테이션 팝업에 포함할 섹션:

| 섹션 | 필수 | 내용 |
|------|------|------|
| **설명** | ✅ | 요소의 역할, 동작, 제약사항 (`2_Screen_UX.md` Elements Description 기반) |
| **요구사항** | ✅ | 관련 FR, US, FT ID + 제목 (`2_Screen_UX.md` FT Mapping 기반) |
| **비즈니스 룰** | 해당 시 | 유효성 검증, 조건, 제한사항 |
| **흐름** | 해당 시 | 해당 요소의 인터랙션 흐름 (step 형태) |
| **상태** | 해당 시 | 요소의 상태별 표시 방식 (Default, Hover, Focus, Error 등) |
| **연결 화면** | 해당 시 | 클릭/동작 시 이동하는 화면 + 조건 (다른 와이어프레임 링크) |
| **API** | 해당 시 | 바인딩된 API 엔드포인트 (메서드 + 경로) |
| **권한** | 해당 시 | Role Visibility (어떤 권한에서 표시/숨김) |

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
  --bg: #f8fafc;
  --card-bg: #ffffff;
  --border: #e2e8f0;
  --text: #1e293b;
  --text-secondary: #64748b;
  --text-muted: #94a3b8;
  --code-bg: #f1f5f9;
  --code-color: #7c3aed;
  --wf-bg: #f1f5f9;
  --wf-border: #cbd5e1;
  --wf-element-bg: #ffffff;
  --marker-bg: #2563eb;
  --marker-text: #ffffff;
  --popup-bg: #ffffff;
  --popup-border: #e2e8f0;
  --popup-shadow: rgba(0,0,0,0.15);
  --tag-fr: #dc2626;
  --tag-ft: #2563eb;
  --tag-us: #059669;
  --overlay: rgba(0,0,0,0.3);
}
[data-theme="dark"] {
  --primary: #60a5fa;
  --primary-light: #1e3a5f;
  --bg: #0f172a;
  --card-bg: #1e293b;
  --border: #334155;
  --text: #e2e8f0;
  --text-secondary: #94a3b8;
  --text-muted: #64748b;
  --code-bg: #0f172a;
  --code-color: #a78bfa;
  --wf-bg: #1e293b;
  --wf-border: #475569;
  --wf-element-bg: #334155;
  --marker-bg: #3b82f6;
  --marker-text: #ffffff;
  --popup-bg: #1e293b;
  --popup-border: #475569;
  --popup-shadow: rgba(0,0,0,0.4);
  --tag-fr: #f87171;
  --tag-ft: #60a5fa;
  --tag-us: #34d399;
  --overlay: rgba(0,0,0,0.5);
}

* { margin:0; padding:0; box-sizing:border-box; }
html { scroll-behavior:smooth; }
body {
  font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: var(--bg); color: var(--text); line-height:1.6;
  transition: background 0.3s, color 0.3s;
}

/* ===== Top Bar ===== */
.topbar {
  position:sticky; top:0; z-index:50;
  background:var(--card-bg); border-bottom:1px solid var(--border);
  padding:12px 24px; display:flex; align-items:center; gap:16px;
  box-shadow:0 1px 3px rgba(0,0,0,0.06);
}
.topbar .back-link { color:var(--primary); text-decoration:none; font-size:14px; font-weight:600; }
.topbar .back-link:hover { text-decoration:underline; }
.topbar h1 { font-size:18px; flex:1; }
.topbar .screen-id { font-family:'Fira Code',monospace; font-size:13px; color:var(--text-secondary); background:var(--code-bg); padding:2px 8px; border-radius:4px; }

/* ===== Theme Toggle ===== */
.theme-toggle {
  width:36px; height:36px; border-radius:50%;
  background:var(--card-bg); border:1px solid var(--border);
  cursor:pointer; display:flex; align-items:center; justify-content:center;
  font-size:18px; transition:all 0.3s;
}
.theme-toggle:hover { border-color:var(--primary); transform:scale(1.1); }

/* ===== Info Panel ===== */
.info-panel {
  background:var(--card-bg); border:1px solid var(--border); border-radius:12px;
  padding:20px 24px; margin:20px 24px;
}
.info-panel h2 { font-size:15px; color:var(--primary); margin-bottom:12px; }
.info-grid { display:grid; grid-template-columns:repeat(auto-fit, minmax(200px, 1fr)); gap:12px; }
.info-item { font-size:13px; }
.info-item .info-label { font-weight:600; color:var(--text-secondary); font-size:11px; text-transform:uppercase; letter-spacing:0.5px; }
.info-item .info-value { margin-top:2px; }

/* ===== Wireframe Canvas ===== */
.wf-canvas {
  background:var(--wf-bg); border:2px dashed var(--wf-border); border-radius:12px;
  margin:20px 24px; padding:24px; min-height:500px; position:relative;
}

/* ===== Wireframe Elements ===== */
.wf-element {
  position:relative; margin-bottom:12px;
}
.wf-header, .wf-section, .wf-input, .wf-button, .wf-list, .wf-card,
.wf-nav, .wf-footer, .wf-sidebar, .wf-modal, .wf-table, .wf-form {
  background:var(--wf-element-bg); border:1px solid var(--wf-border);
  border-radius:6px; padding:12px 16px; font-size:13px; color:var(--text-secondary);
}
.wf-header { background:var(--card-bg); border-bottom:2px solid var(--primary); font-weight:600; color:var(--text); }
.wf-button { background:var(--primary); color:#fff; border:none; border-radius:6px; padding:8px 16px; display:inline-block; font-weight:600; font-size:13px; }
.wf-button.secondary { background:transparent; border:1px solid var(--border); color:var(--text-secondary); }
.wf-placeholder { background:var(--wf-bg); border:1px dashed var(--wf-border); border-radius:6px; padding:20px; text-align:center; color:var(--text-muted); font-size:12px; }

/* ===== Grid Layout Helpers ===== */
.wf-row { display:flex; gap:12px; margin-bottom:12px; }
.wf-col { flex:1; }
.wf-col-2 { flex:2; }
.wf-col-3 { flex:3; }

/* ===== Annotation Marker ===== */
.annotation-marker {
  position:absolute; top:-8px; right:-8px; z-index:10;
  width:26px; height:26px; border-radius:50%;
  background:var(--marker-bg); color:var(--marker-text);
  font-size:14px; font-weight:700; line-height:26px; text-align:center;
  cursor:pointer; transition:all 0.2s;
  box-shadow:0 2px 6px rgba(37,99,235,0.3);
  user-select:none;
}
.annotation-marker:hover {
  transform:scale(1.15);
  box-shadow:0 3px 10px rgba(37,99,235,0.4);
}

/* ===== Annotation Popup ===== */
.popup-overlay {
  display:none; position:fixed; top:0; left:0; right:0; bottom:0;
  background:var(--overlay); z-index:100;
}
.popup-overlay.active { display:block; }

.annotation-popup {
  display:none; position:fixed; z-index:101;
  top:50%; left:50%; transform:translate(-50%,-50%);
  width:520px; max-width:90vw; max-height:80vh;
  background:var(--popup-bg); border:1px solid var(--popup-border);
  border-radius:16px; overflow:hidden;
  box-shadow:0 20px 60px var(--popup-shadow);
}
.annotation-popup.active { display:block; }

.popup-header {
  display:flex; align-items:center; gap:12px;
  padding:16px 20px; border-bottom:1px solid var(--border);
  background:var(--primary); color:#fff;
}
.popup-number { font-size:20px; font-weight:700; }
.popup-title { flex:1; font-size:16px; font-weight:600; margin:0; }
.popup-close {
  width:32px; height:32px; border-radius:50%; border:none;
  background:rgba(255,255,255,0.2); color:#fff; font-size:18px;
  cursor:pointer; display:flex; align-items:center; justify-content:center;
  transition:background 0.2s;
}
.popup-close:hover { background:rgba(255,255,255,0.3); }

.popup-body { padding:20px; overflow-y:auto; max-height:calc(80vh - 60px); }
.popup-section { margin-bottom:16px; }
.popup-section:last-child { margin-bottom:0; }
.popup-section h5 {
  font-size:12px; text-transform:uppercase; letter-spacing:0.5px;
  color:var(--text-secondary); margin-bottom:8px; font-weight:600;
}
.popup-section p { font-size:14px; line-height:1.7; }
.popup-section ul { list-style:none; padding:0; }
.popup-section li { font-size:13px; padding:4px 0; }

/* Popup Tags */
.popup-tags li { display:flex; align-items:center; gap:8px; }
.popup-tag {
  display:inline-block; padding:2px 8px; border-radius:4px;
  font-size:11px; font-weight:700; font-family:'Fira Code',monospace;
}
.tag-fr { background:rgba(220,38,38,0.1); color:var(--tag-fr); }
.tag-ft { background:rgba(37,99,235,0.1); color:var(--tag-ft); }
.tag-us { background:rgba(5,150,105,0.1); color:var(--tag-us); }

/* Popup Rules */
.popup-rules li { padding:6px 0; padding-left:16px; position:relative; }
.popup-rules li::before { content:'•'; position:absolute; left:0; color:var(--primary); font-weight:700; }

/* Popup Flow */
.popup-flow { display:flex; align-items:center; gap:6px; flex-wrap:wrap; }
.flow-step { background:var(--primary-light); color:var(--primary); padding:4px 12px; border-radius:16px; font-size:12px; font-weight:600; }
.flow-arrow { color:var(--text-muted); font-size:14px; }

/* Popup Table */
.popup-table { width:100%; font-size:13px; border-collapse:collapse; }
.popup-table td { padding:6px 10px; border-bottom:1px solid var(--border); }
.state-label { font-weight:600; color:var(--primary); white-space:nowrap; width:80px; }

/* Popup Links */
.popup-links li { padding:4px 0; }
.popup-links a { color:var(--primary); text-decoration:none; font-weight:600; font-size:13px; }
.popup-links a:hover { text-decoration:underline; }

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
  width:24px; height:24px; border-radius:50%;
  background:var(--marker-bg); color:var(--marker-text);
  font-size:12px; font-weight:700; line-height:24px; text-align:center;
  flex-shrink:0;
}

/* ===== Mobile ===== */
@media (max-width:768px) {
  .topbar { flex-wrap:wrap; }
  .info-grid { grid-template-columns:1fr; }
  .annotation-popup { width:95vw; }
  .legend-list { columns:1; }
  .wf-row { flex-direction:column; }
}

/* ===== Print ===== */
@media print {
  .topbar { position:static; box-shadow:none; }
  .theme-toggle { display:none; }
  .annotation-marker { print-color-adjust:exact; -webkit-print-color-adjust:exact; }
  .annotation-popup, .popup-overlay { display:none !important; }
}
</style>
</head>
<body>

<!-- Top Bar -->
<div class="topbar">
  <a href="index.html" class="back-link">← All Screens</a>
  <span class="screen-id">{{SCREEN_ID}}</span>
  <h1>{{SCREEN_NAME}}</h1>
  <button class="theme-toggle" onclick="toggleTheme()" aria-label="Toggle theme">
    <span id="theme-icon">&#9789;</span>
  </button>
</div>

<!-- Info Panel -->
<div class="info-panel">
  <h2>Screen Info</h2>
  <div class="info-grid">
    <div class="info-item">
      <div class="info-label">Goal</div>
      <div class="info-value">{{GOAL}}</div>
    </div>
    <div class="info-item">
      <div class="info-label">Access Role</div>
      <div class="info-value">{{ACCESS_ROLE}}</div>
    </div>
    <div class="info-item">
      <div class="info-label">Menu</div>
      <div class="info-value">{{MENU_ID}}</div>
    </div>
    <div class="info-item">
      <div class="info-label">FT Mapping</div>
      <div class="info-value">{{FT_IDS}}</div>
    </div>
  </div>
</div>

<!-- Wireframe Canvas -->
<div class="wf-canvas">
  <!-- 와이어프레임 레이아웃 + 어노테이션 마커 배치 -->
</div>

<!-- Annotation Legend -->
<div class="annotation-legend">
  <h2>Annotations</h2>
  <ul class="legend-list">
    <!-- 범례: 클릭 시 해당 팝업 오픈 -->
    <li class="legend-item" onclick="openPopup('annotation-1')">
      <span class="legend-num">&#9312;</span>
      <span>이메일 입력 필드</span>
    </li>
    <!-- ... 반복 -->
  </ul>
</div>

<!-- Popup Overlay -->
<div class="popup-overlay" id="popupOverlay" onclick="closeAllPopups()"></div>

<!-- Annotation Popups -->
<!-- 각 어노테이션의 팝업을 여기에 배치 -->

<script>
// Theme
function toggleTheme(){
  var h=document.documentElement, i=document.getElementById('theme-icon');
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

// Popup
function openPopup(id){
  closeAllPopups();
  document.getElementById('popupOverlay').classList.add('active');
  var p=document.getElementById(id);
  if(p)p.classList.add('active');
}
function closePopup(id){
  document.getElementById('popupOverlay').classList.remove('active');
  var p=document.getElementById(id);
  if(p)p.classList.remove('active');
}
function closeAllPopups(){
  document.getElementById('popupOverlay').classList.remove('active');
  document.querySelectorAll('.annotation-popup').forEach(function(p){p.classList.remove('active');});
}

// Marker click
document.querySelectorAll('.annotation-marker').forEach(function(m){
  m.addEventListener('click',function(e){
    e.stopPropagation();
    openPopup(this.getAttribute('data-target'));
  });
});

// ESC to close
document.addEventListener('keydown',function(e){
  if(e.key==='Escape')closeAllPopups();
});
</script>
</body>
</html>
```

---

## 4. index.html 템플릿

와이어프레임 디렉토리에 `index.html`을 생성하여 전체 화면 목록을 제공한다.

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
  --bg: #f8fafc;
  --card-bg: #ffffff;
  --border: #e2e8f0;
  --text: #1e293b;
  --text-secondary: #64748b;
  --text-muted: #94a3b8;
  --hover-bg: #f1f5f9;
}
[data-theme="dark"] {
  --primary: #60a5fa;
  --primary-light: #1e3a5f;
  --bg: #0f172a;
  --card-bg: #1e293b;
  --border: #334155;
  --text: #e2e8f0;
  --text-secondary: #94a3b8;
  --text-muted: #64748b;
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
  max-width:1000px; margin:24px auto; padding:0 24px;
  display:flex; gap:12px; align-items:center;
}
.search-input {
  flex:1; padding:10px 16px; border:1px solid var(--border);
  border-radius:8px; font-size:14px; background:var(--card-bg);
  color:var(--text); outline:none;
}
.search-input:focus { border-color:var(--primary); }
.theme-toggle {
  width:40px; height:40px; border-radius:50%;
  background:var(--card-bg); border:1px solid var(--border);
  cursor:pointer; display:flex; align-items:center; justify-content:center;
  font-size:18px; transition:all 0.3s;
}
.theme-toggle:hover { border-color:var(--primary); }

/* Stats */
.stats { max-width:1000px; margin:0 auto 24px; padding:0 24px; display:flex; gap:16px; }
.stat-card {
  background:var(--card-bg); border:1px solid var(--border); border-radius:10px;
  padding:16px 20px; text-align:center; flex:1;
}
.stat-num { font-size:28px; font-weight:700; color:var(--primary); }
.stat-label { font-size:12px; color:var(--text-secondary); margin-top:2px; }

/* Screen List */
.screen-list { max-width:1000px; margin:0 auto; padding:0 24px 40px; }
.screen-group { margin-bottom:24px; }
.screen-group-title {
  font-size:12px; text-transform:uppercase; letter-spacing:1px;
  color:var(--text-secondary); padding:8px 0; border-bottom:1px solid var(--border);
  margin-bottom:8px; font-weight:600;
}

.screen-card {
  display:flex; align-items:center; gap:16px;
  background:var(--card-bg); border:1px solid var(--border); border-radius:10px;
  padding:16px 20px; margin-bottom:8px;
  text-decoration:none; color:var(--text); transition:all 0.2s;
}
.screen-card:hover { border-color:var(--primary); background:var(--hover-bg); transform:translateX(4px); }
.screen-card .s-id {
  font-family:'Fira Code',monospace; font-size:13px; font-weight:700;
  color:var(--primary); background:var(--primary-light);
  padding:4px 10px; border-radius:6px; white-space:nowrap;
}
.screen-card .s-name { flex:1; font-size:15px; font-weight:600; }
.screen-card .s-goal { font-size:12px; color:var(--text-secondary); flex:2; }
.screen-card .s-role {
  font-size:11px; font-weight:600; padding:3px 10px;
  border-radius:12px; background:var(--hover-bg); color:var(--text-secondary);
  white-space:nowrap;
}
.screen-card .s-arrow { color:var(--text-muted); font-size:16px; }

/* No Results */
.no-results { text-align:center; padding:40px; color:var(--text-muted); font-size:14px; display:none; }

@media (max-width:768px) {
  .screen-card { flex-wrap:wrap; }
  .screen-card .s-goal { flex-basis:100%; order:3; margin-top:4px; }
  .stats { flex-wrap:wrap; }
  .stat-card { min-width:120px; }
}
@media print {
  .controls { display:none; }
  .theme-toggle { display:none; }
  .screen-card:hover { transform:none; }
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
  <button class="theme-toggle" onclick="toggleTheme()" aria-label="Toggle theme">
    <span id="theme-icon">&#9789;</span>
  </button>
</div>

<div class="stats">
  <!-- stat-card: 도메인별 또는 역할별 화면 수 -->
</div>

<div class="screen-list" id="screenList">
  <!-- 도메인별 그룹핑 -->
  <div class="screen-group" data-group="auth">
    <div class="screen-group-title">AUTH — 인증</div>
    <a href="S-0010.html" class="screen-card" data-search="s-0010 로그인 login">
      <span class="s-id">S-0010</span>
      <span class="s-name">로그인</span>
      <span class="s-goal">이메일/비밀번호로 인증하여 서비스에 진입</span>
      <span class="s-role">Public</span>
      <span class="s-arrow">→</span>
    </a>
    <!-- ... 반복 -->
  </div>
</div>

<div class="no-results" id="noResults">No screens found</div>

<script>
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
function filterScreens(q){
  q=q.toLowerCase();
  var cards=document.querySelectorAll('.screen-card'),
      groups=document.querySelectorAll('.screen-group'),
      found=0;
  cards.forEach(function(c){
    var match=c.getAttribute('data-search').toLowerCase().indexOf(q)!==-1;
    c.style.display=match?'':'none';
    if(match)found++;
  });
  groups.forEach(function(g){
    var visible=g.querySelectorAll('.screen-card[style=""],.screen-card:not([style])');
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

1. `2_Screen_UX.md`의 해당 화면 설계를 기반으로 레이아웃 구성
2. **모든 Elements 테이블 항목**에 원 숫자 마커 부착 (순서: 상단→하단, 좌→우)
3. 각 마커에 대응하는 팝업을 body 하단에 생성
4. 팝업 내용은 `2_Screen_UX.md`의 Description, FT Mapping, Navigation, Interactions, States 정보를 종합
5. **Annotation Legend** 섹션에 전체 마커 목록을 범례로 표시
6. `index.html`로의 뒤로가기 링크 포함
7. 인접 화면으로의 링크 포함 (Connected Screens 기반)

### 5.2 index.html 규칙

1. **`/u-skill-wireframe` 실행 시 항상 index.html도 함께 생성/갱신**
2. `2_Screen_UX.md`의 전체 화면 목록을 반영
3. IA의 도메인(AUTH, DASH 등)별로 그룹핑
4. 각 화면 카드에 Screen ID, Name, Goal, Access Role 표시
5. 검색 기능으로 화면 필터링 지원
6. 상단에 통계 표시 (전체 화면 수, 도메인별 수)
7. `data-search` 속성에 Screen ID + 이름 + 키워드를 포함하여 검색 범위 확장

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
      "description": "사용자의 이메일 주소를 입력받는 필드",
      "requirements": ["FR-0010", "FT-0010", "US-0010"],
      "businessRules": ["이메일 형식 검증", "최대 254자"],
      "flow": ["입력", "유효성 검증", "API 호출", "성공/실패"],
      "states": ["Default", "Focus", "Error", "Disabled"],
      "connectedScreens": ["S-0020", "S-0030"]
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
- [ ] 단일 HTML 파일 완결 (외부 JS/CSS 없음, Pretendard CDN만 허용)
- [ ] Light/Dark 테마 토글 동작
- [ ] OS 테마 자동 감지 + localStorage 저장
- [ ] 모든 색상 CSS 변수 사용 (하드코딩 금지)
- [ ] 모든 Elements에 원 숫자 마커 부착
- [ ] 각 마커에 팝업 연결 (클릭 시 오픈)
- [ ] 팝업에 설명, 요구사항, 비즈니스 룰 포함 (해당 시 흐름, 상태, 연결 화면, API, 권한도 포함)
- [ ] Annotation Legend 섹션 포함 (범례 클릭 시 팝업 오픈)
- [ ] ESC 키로 팝업 닫기
- [ ] 오버레이 클릭으로 팝업 닫기
- [ ] index.html로의 뒤로가기 링크 포함
- [ ] Info Panel에 Screen 메타 정보 표시
- [ ] 반응형 대응 (@media max-width:768px)
- [ ] 인쇄 대응 (@media print)
- [ ] `<html lang="{{LANG}}">` 설정
- [ ] 동명의 `.json` 파일 생성

### index.html 생성 시
- [ ] 전체 화면 목록 반영 (2_Screen_UX.md 기준)
- [ ] 도메인별 그룹핑
- [ ] 검색 기능 동작
- [ ] 화면 카드에 ID, Name, Goal, Role 표시
- [ ] 통계 카드 표시
- [ ] Light/Dark 테마 토글 동작
- [ ] 반응형 대응
- [ ] 동명의 `index.json` 생성
