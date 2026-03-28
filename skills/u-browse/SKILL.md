---
name: u-browse
description: "SSoT 문서(.md/.json)를 개별 HTML 파일로 1:1 변환하고, index.html에서 sidebar navigation + iframe으로 브라우징할 수 있는 문서 뷰어를 생성한다."
triggers:
  - "/u-browse"
  - "browse"
  - "문서 뷰어"
  - "docs html"
  - "문서 브라우징"
  - "개별 HTML"
  - "doc viewer"
---

# u-browse -- SSoT Document Browser Generator

`/u-browse [scope] [--only path] [--open]` 명령으로 `.u-maker/docs/` 하위의 모든 `.md` / `.json` 파일을 **개별 HTML**로 1:1 변환하고, **index.html**에서 sidebar navigation으로 전체 문서를 브라우징할 수 있는 뷰어를 생성한다.

**Primary Agent:** u-agent-orchestrator

> **u-report와의 차이:** `/u-report`는 Phase별 aggregate 리포트(통계, 차트, 교차 검증)를 생성한다. `/u-browse`는 각 소스 문서를 **있는 그대로** 개별 HTML로 변환하여 원본 문서를 편리하게 열람하는 데 목적이 있다.

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
│   │   ├── srs.html                   # srs.md → HTML
│   │   ├── srs.data.html             # srs.json → formatted JSON viewer
│   │   ├── ia.html
│   │   └── ia.data.html
│   ├── 02-design/
│   │   ├── api.html
│   │   ├── api.data.html
│   │   ├── erd.html
│   │   ├── erd.data.html
│   │   └── ...
│   └── ...
└── ...
```

**명명 규칙:** `.md` → `{name}.html` | `.json` → `{name}.data.html` | 기존 `.html` → 그대로 복사

---

## ★ Execution Flow (MUST FOLLOW EXACTLY)

### Step 1: Discover Files

1. `.u-maker/docs/` 경로를 확인한다. 없으면 에러 출력 후 종료.
2. Bash로 대상 파일 목록을 수집한다:

```bash
find .u-maker/docs -type f \( -name "*.md" -o -name "*.json" \) | sort
```

3. `--only` 플래그가 있으면 해당 경로 하위만 필터링.
4. `_browse/` 출력 디렉토리를 생성한다:

```bash
mkdir -p .u-maker/_browse
```

5. 수집된 파일 목록을 **fileList** 로 기억한다. 예:
```
.u-maker/docs/hjw/01-plan/srs.md
.u-maker/docs/hjw/01-plan/srs.json
.u-maker/docs/hjw/01-plan/ia.md
.u-maker/docs/hjw/01-plan/ia.json
.u-maker/docs/hjw/02-design/api.md
.u-maker/docs/hjw/02-design/api.json
...
```

### Step 2: Generate HTML for Each File

**fileList의 모든 파일에 대해 순회하며 HTML을 생성한다.**

#### 2-A. `.md` 파일 → `{name}.html`

각 `.md` 파일에 대해:

1. **Read** 도구로 소스 `.md` 파일 내용을 읽는다.
2. 읽은 markdown 내용에서 `<`, `>`, `&` 등 HTML 특수문자를 이스케이프하지 않는다 (marked.js가 처리).
3. 단, `</script>` 문자열이 있으면 `<\/script>`로 이스케이프한다.
4. 아래 **MD_TEMPLATE**의 `{{MD_CONTENT}}` 에 원본 내용을 삽입하고, 나머지 플레이스홀더를 치환한다.
5. **Write** 도구로 `.u-maker/_browse/{relative-path}/{name}.html` 에 저장한다.

**MD_TEMPLATE:**

```html
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{TITLE}} — u-maker</title>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #1e293b; background: #ffffff; line-height: 1.7; }
  .doc-header { position: sticky; top: 0; background: #f8fafc; border-bottom: 1px solid #e2e8f0; padding: 8px 24px; display: flex; justify-content: space-between; align-items: center; z-index: 10; }
  .breadcrumb { font-size: 13px; color: #64748b; }
  .breadcrumb span { color: #2563eb; font-weight: 600; }
  .doc-actions a, .doc-actions button { background: #e2e8f0; border: none; padding: 4px 12px; border-radius: 4px; cursor: pointer; font-size: 12px; color: #475569; text-decoration: none; margin-left: 4px; }
  .doc-actions a:hover, .doc-actions button:hover { background: #cbd5e1; }
  .doc-content { max-width: 960px; margin: 0 auto; padding: 32px 24px; }
  .doc-content h1 { font-size: 28px; font-weight: 700; color: #0f172a; margin: 32px 0 16px; padding-bottom: 8px; border-bottom: 2px solid #e2e8f0; }
  .doc-content h2 { font-size: 22px; font-weight: 600; color: #0f172a; margin: 28px 0 12px; padding-bottom: 6px; border-bottom: 1px solid #e2e8f0; }
  .doc-content h3 { font-size: 18px; font-weight: 600; color: #1e293b; margin: 24px 0 8px; }
  .doc-content h4, .doc-content h5, .doc-content h6 { font-size: 15px; font-weight: 600; margin: 16px 0 8px; }
  .doc-content p { margin: 8px 0 12px; }
  .doc-content ul, .doc-content ol { margin: 8px 0 12px 24px; }
  .doc-content li { margin: 4px 0; }
  .doc-content table { width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 14px; }
  .doc-content th { background: #f1f5f9; font-weight: 600; text-align: left; padding: 10px 12px; border: 1px solid #e2e8f0; }
  .doc-content td { padding: 8px 12px; border: 1px solid #e2e8f0; }
  .doc-content tr:nth-child(even) td { background: #f8fafc; }
  .doc-content pre { background: #1e293b; color: #e2e8f0; padding: 16px; border-radius: 8px; overflow-x: auto; margin: 12px 0; font-size: 13px; }
  .doc-content code { font-family: 'SF Mono', Consolas, monospace; font-size: 13px; }
  .doc-content :not(pre) > code { background: #f1f5f9; color: #e11d48; padding: 2px 6px; border-radius: 3px; }
  .doc-content blockquote { border-left: 4px solid #3b82f6; background: #eff6ff; padding: 12px 16px; margin: 12px 0; border-radius: 0 8px 8px 0; }
  .doc-content a { color: #2563eb; text-decoration: none; }
  .doc-content a:hover { text-decoration: underline; }
  .doc-content img { max-width: 100%; border-radius: 8px; }
  .doc-content hr { border: none; border-top: 1px solid #e2e8f0; margin: 24px 0; }
  .doc-content input[type="checkbox"] { margin-right: 6px; }
  .doc-meta { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 24px; padding: 12px 16px; background: #f8fafc; border-radius: 8px; border: 1px solid #e2e8f0; }
  .badge { display: inline-block; padding: 2px 10px; border-radius: 9999px; font-size: 11px; font-weight: 600; text-transform: uppercase; }
  .badge.draft { background: #64748b; color: #fff; }
  .badge.review { background: #f59e0b; color: #fff; }
  .badge.final { background: #22c55e; color: #fff; }
  .meta-item { font-size: 12px; color: #64748b; display: flex; align-items: center; gap: 4px; }
  .doc-footer { text-align: center; padding: 24px; font-size: 12px; color: #94a3b8; border-top: 1px solid #f1f5f9; margin-top: 48px; }
  .mermaid { background: #fff; text-align: center; margin: 16px 0; }
  @media print { .doc-header, .doc-footer { display: none; } .doc-content { max-width: 100%; padding: 0; } }
</style>
</head>
<body>
<header class="doc-header">
  <nav class="breadcrumb">{{BREADCRUMB}}</nav>
  <div class="doc-actions">
    <button onclick="history.back()">← Back</button>
    <a href="{{INDEX_PATH}}" target="_top">☰ Index</a>
  </div>
</header>
<main class="doc-content" id="content"></main>
<footer class="doc-footer">Generated by u-browse</footer>
<script id="md-source" type="text/markdown">
{{MD_CONTENT}}
</script>
<script>
document.addEventListener('DOMContentLoaded', function() {
  mermaid.initialize({ startOnLoad: false, theme: 'default' });
  const md = document.getElementById('md-source').textContent;

  // Parse YAML frontmatter
  const fmMatch = md.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
  let body = md, meta = null;
  if (fmMatch) {
    const fmLines = fmMatch[1].split('\n');
    meta = {};
    fmLines.forEach(l => {
      const m = l.match(/^(\w[\w\s]*?):\s*(.+)/);
      if (m) meta[m[1].trim()] = m[2].trim();
    });
    body = fmMatch[2];
  }

  // Render meta card
  let metaHtml = '';
  if (meta) {
    const statusClass = (meta.Status || 'draft').toLowerCase();
    metaHtml = '<div class="doc-meta">';
    if (meta.Status) metaHtml += '<span class="badge ' + statusClass + '">' + meta.Status + '</span>';
    ['Owner','Version','Last Updated'].forEach(k => {
      if (meta[k]) metaHtml += '<span class="meta-item"><strong>' + k + ':</strong> ' + meta[k] + '</span>';
    });
    metaHtml += '</div>';
  }

  // Configure marked
  marked.setOptions({ gfm: true, breaks: true });

  // Custom renderer for mermaid code blocks and .md link rewriting
  const renderer = new marked.Renderer();
  const origCode = renderer.code ? renderer.code.bind(renderer) : null;
  renderer.code = function(obj) {
    const text = typeof obj === 'object' ? obj.text : obj;
    const lang = typeof obj === 'object' ? obj.lang : arguments[1];
    if (lang === 'mermaid') {
      return '<div class="mermaid">' + text + '</div>';
    }
    if (origCode) return origCode(obj);
    return '<pre><code>' + text.replace(/</g,'&lt;') + '</code></pre>';
  };
  const origLink = renderer.link ? renderer.link.bind(renderer) : null;
  renderer.link = function(obj) {
    let href = typeof obj === 'object' ? obj.href : obj;
    const title = typeof obj === 'object' ? obj.title : arguments[1];
    const text = typeof obj === 'object' ? obj.text : arguments[2];
    if (href && href.endsWith('.md')) href = href.replace(/\.md$/, '.html');
    if (href && href.endsWith('.json')) href = href.replace(/\.json$/, '.data.html');
    return '<a href="' + href + '"' + (title ? ' title="' + title + '"' : '') + '>' + (text || href) + '</a>';
  };
  marked.setOptions({ renderer: renderer });

  // Render
  const html = metaHtml + marked.parse(body);
  document.getElementById('content').innerHTML = html;

  // Render mermaid diagrams
  mermaid.run({ nodes: document.querySelectorAll('.mermaid') }).catch(function(){});
});
</script>
</body>
</html>
```

**플레이스홀더 치환 규칙:**

| 플레이스홀더 | 치환값 | 예시 |
|---|---|---|
| `{{TITLE}}` | 파일명 (확장자 제외) | `srs` |
| `{{BREADCRUMB}}` | `앱 / phase / <span>파일명</span>` | `hjw / 01-plan / <span>srs</span>` |
| `{{INDEX_PATH}}` | index.html까지의 상대 경로 | `../../index.html` |
| `{{MD_CONTENT}}` | `.md` 파일의 원본 내용 전체 (이스케이프 없이 그대로) | (파일 내용) |

#### 2-B. `.json` 파일 → `{name}.data.html`

각 `.json` 파일에 대해:

1. **Read** 도구로 소스 `.json` 파일 내용을 읽는다.
2. JSON 내용에서 `</script>` 문자열이 있으면 `<\/script>`로 이스케이프한다.
3. 아래 **JSON_TEMPLATE**의 `{{JSON_CONTENT}}`에 원본 내용을 삽입하고, 나머지 플레이스홀더를 치환한다.
4. **Write** 도구로 `.u-maker/_browse/{relative-path}/{name}.data.html` 에 저장한다.

**JSON_TEMPLATE:**

```html
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{TITLE}} (JSON) — u-maker</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #1e293b; background: #ffffff; }
  .doc-header { position: sticky; top: 0; background: #f8fafc; border-bottom: 1px solid #e2e8f0; padding: 8px 24px; display: flex; justify-content: space-between; align-items: center; z-index: 10; }
  .breadcrumb { font-size: 13px; color: #64748b; }
  .breadcrumb span { color: #2563eb; font-weight: 600; }
  .doc-actions a, .doc-actions button { background: #e2e8f0; border: none; padding: 4px 12px; border-radius: 4px; cursor: pointer; font-size: 12px; color: #475569; text-decoration: none; margin-left: 4px; }
  .doc-actions a:hover, .doc-actions button:hover { background: #cbd5e1; }
  .view-toggle { display: flex; gap: 4px; margin-left: 8px; }
  .view-toggle button { background: #e2e8f0; border: none; padding: 4px 12px; border-radius: 4px; cursor: pointer; font-size: 12px; }
  .view-toggle button.active { background: #2563eb; color: #fff; }
  .doc-content { max-width: 1100px; margin: 0 auto; padding: 24px; }
  .json-view { font-family: 'SF Mono', Consolas, monospace; font-size: 13px; line-height: 1.6; white-space: pre-wrap; word-break: break-word; }
  .json-key { color: #2563eb; }
  .json-string { color: #16a34a; }
  .json-number { color: #ea580c; }
  .json-boolean { color: #9333ea; }
  .json-null { color: #64748b; }
  .json-bracket { color: #475569; font-weight: 600; }
  .json-toggle { cursor: pointer; user-select: none; }
  .json-toggle::before { content: '▼ '; font-size: 10px; color: #94a3b8; }
  .json-toggle.collapsed::before { content: '▶ '; }
  .json-toggle.collapsed + .json-block { display: none; }
  .json-summary { color: #94a3b8; font-size: 12px; font-style: italic; }
  .table-view { display: none; overflow-x: auto; }
  .table-view table { width: 100%; border-collapse: collapse; font-size: 13px; }
  .table-view th { background: #f1f5f9; font-weight: 600; text-align: left; padding: 10px 12px; border: 1px solid #e2e8f0; white-space: nowrap; }
  .table-view td { padding: 8px 12px; border: 1px solid #e2e8f0; max-width: 300px; overflow: hidden; text-overflow: ellipsis; }
  .table-view tr:nth-child(even) td { background: #f8fafc; }
  .doc-footer { text-align: center; padding: 24px; font-size: 12px; color: #94a3b8; border-top: 1px solid #f1f5f9; margin-top: 48px; }
  @media print { .doc-header, .doc-footer, .view-toggle { display: none; } }
</style>
</head>
<body>
<header class="doc-header">
  <div style="display:flex;align-items:center;">
    <nav class="breadcrumb">{{BREADCRUMB}}</nav>
    <div class="view-toggle" id="viewToggle" style="display:none;">
      <button class="active" onclick="showView('json')">JSON</button>
      <button onclick="showView('table')">Table</button>
    </div>
  </div>
  <div class="doc-actions">
    <button onclick="history.back()">← Back</button>
    <a href="{{INDEX_PATH}}" target="_top">☰ Index</a>
  </div>
</header>
<main class="doc-content">
  <div class="json-view" id="jsonView"></div>
  <div class="table-view" id="tableView"></div>
</main>
<footer class="doc-footer">Generated by u-browse</footer>
<script id="json-source" type="application/json">
{{JSON_CONTENT}}
</script>
<script>
document.addEventListener('DOMContentLoaded', function() {
  const raw = document.getElementById('json-source').textContent;
  let data;
  try { data = JSON.parse(raw); } catch(e) {
    document.getElementById('jsonView').textContent = 'Invalid JSON:\n' + e.message + '\n\n' + raw;
    return;
  }

  // JSON syntax-highlighted view
  function renderJson(obj, indent) {
    indent = indent || 0;
    const sp = '  '.repeat(indent);
    if (obj === null) return '<span class="json-null">null</span>';
    if (typeof obj === 'boolean') return '<span class="json-boolean">' + obj + '</span>';
    if (typeof obj === 'number') return '<span class="json-number">' + obj + '</span>';
    if (typeof obj === 'string') return '<span class="json-string">"' + obj.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/"/g,'&quot;') + '"</span>';
    if (Array.isArray(obj)) {
      if (obj.length === 0) return '<span class="json-bracket">[]</span>';
      let html = '<span class="json-toggle json-bracket" onclick="this.classList.toggle(\'collapsed\')">[</span>';
      html += '<span class="json-summary"> ' + obj.length + ' items</span>';
      html += '<span class="json-block">\n';
      obj.forEach(function(item, i) {
        html += sp + '  ' + renderJson(item, indent + 1);
        if (i < obj.length - 1) html += ',';
        html += '\n';
      });
      html += sp + '</span><span class="json-bracket">]</span>';
      return html;
    }
    if (typeof obj === 'object') {
      const keys = Object.keys(obj);
      if (keys.length === 0) return '<span class="json-bracket">{}</span>';
      let html = '<span class="json-toggle json-bracket" onclick="this.classList.toggle(\'collapsed\')">{</span>';
      html += '<span class="json-summary"> ' + keys.length + ' keys</span>';
      html += '<span class="json-block">\n';
      keys.forEach(function(key, i) {
        html += sp + '  <span class="json-key">"' + key.replace(/</g,'&lt;') + '"</span>: ' + renderJson(obj[key], indent + 1);
        if (i < keys.length - 1) html += ',';
        html += '\n';
      });
      html += sp + '</span><span class="json-bracket">}</span>';
      return html;
    }
    return String(obj);
  }

  document.getElementById('jsonView').innerHTML = renderJson(data);

  // Table view for arrays of objects
  const arr = Array.isArray(data) ? data : (data && typeof data === 'object' ? Object.values(data).find(v => Array.isArray(v) && v.length > 0 && typeof v[0] === 'object') : null);
  if (arr && arr.length > 0 && typeof arr[0] === 'object') {
    document.getElementById('viewToggle').style.display = 'flex';
    const allKeys = [];
    arr.forEach(function(row) { Object.keys(row).forEach(function(k) { if (allKeys.indexOf(k) < 0) allKeys.push(k); }); });
    let html = '<table><thead><tr>';
    allKeys.forEach(function(k) { html += '<th>' + k + '</th>'; });
    html += '</tr></thead><tbody>';
    arr.forEach(function(row) {
      html += '<tr>';
      allKeys.forEach(function(k) {
        const v = row[k];
        const display = (v === null || v === undefined) ? '' : (typeof v === 'object' ? JSON.stringify(v) : String(v));
        html += '<td>' + display.replace(/</g,'&lt;').substring(0, 200) + '</td>';
      });
      html += '</tr>';
    });
    html += '</tbody></table>';
    document.getElementById('tableView').innerHTML = html;
  }
});

function showView(view) {
  document.getElementById('jsonView').style.display = view === 'json' ? '' : 'none';
  document.getElementById('tableView').style.display = view === 'table' ? '' : 'none';
  document.querySelectorAll('.view-toggle button').forEach(function(b) {
    b.classList.toggle('active', b.textContent.toLowerCase() === view);
  });
}
</script>
</body>
</html>
```

**플레이스홀더 치환:** `{{TITLE}}`, `{{BREADCRUMB}}`, `{{INDEX_PATH}}` 는 2-A와 동일. `{{JSON_CONTENT}}`에 `.json` 원본 내용을 그대로 삽입.

#### 2-C. 기존 `.html` 파일 (wireframes 등)

1. **Read** 도구로 원본 `.html` 읽기.
2. **Write** 도구로 `.u-maker/_browse/` 같은 상대 경로에 그대로 복사.

### Step 3: Generate index.html

모든 파일 변환이 끝난 후, **fileList**를 기반으로 sidebar 파일 트리를 구성하여 `index.html`을 생성한다.

**구체적 알고리즘:**

1. fileList에서 변환된 HTML 파일 목록을 **sidebar tree data** (JSON 배열)로 구성한다:

```javascript
// 예시 — 이 배열을 index.html 내에 인라인한다
const FILES = [
  { path: "hjw/01-plan/srs.html", type: "md", name: "srs", dir: "hjw/01-plan" },
  { path: "hjw/01-plan/srs.data.html", type: "json", name: "srs", dir: "hjw/01-plan" },
  { path: "hjw/01-plan/ia.html", type: "md", name: "ia", dir: "hjw/01-plan" },
  { path: "hjw/01-plan/ia.data.html", type: "json", name: "ia", dir: "hjw/01-plan" },
  { path: "hjw/02-design/api.html", type: "md", name: "api", dir: "hjw/02-design" },
  { path: "hjw/02-design/api.data.html", type: "json", name: "api", dir: "hjw/02-design" },
  // ... 모든 생성된 파일
];
```

2. 아래 **INDEX_TEMPLATE**의 `{{FILES_JSON}}`에 위 배열을, `{{GENERATED_DATE}}`에 현재 날짜를, `{{TOTAL_COUNT}}`에 파일 수를 삽입한다.
3. **Write** 도구로 `.u-maker/_browse/index.html`에 저장한다.

**INDEX_TEMPLATE:**

```html
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Document Browser — u-maker</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; height: 100vh; overflow: hidden; }

  /* Sidebar */
  .sidebar { width: 280px; min-width: 280px; background: #1e293b; color: #e2e8f0; display: flex; flex-direction: column; overflow: hidden; }
  .sidebar-header { padding: 16px; border-bottom: 1px solid #334155; }
  .sidebar-header h1 { font-size: 15px; font-weight: 700; color: #f1f5f9; }
  .sidebar-header .meta { font-size: 11px; color: #94a3b8; margin-top: 4px; }
  .sidebar-search { padding: 8px 12px; }
  .sidebar-search input { width: 100%; padding: 6px 10px; background: #0f172a; border: 1px solid #334155; border-radius: 6px; color: #e2e8f0; font-size: 13px; outline: none; }
  .sidebar-search input::placeholder { color: #64748b; }
  .sidebar-search input:focus { border-color: #38bdf8; }
  .sidebar-tree { flex: 1; overflow-y: auto; padding: 8px 0; }

  /* Tree nodes */
  .tree-folder { user-select: none; }
  .tree-folder-label { display: flex; align-items: center; padding: 4px 12px; cursor: pointer; font-size: 13px; font-weight: 600; color: #cbd5e1; gap: 6px; }
  .tree-folder-label:hover { background: #334155; }
  .tree-folder-label .arrow { font-size: 10px; color: #64748b; transition: transform 0.15s; width: 12px; text-align: center; }
  .tree-folder.collapsed > .tree-children { display: none; }
  .tree-folder.collapsed > .tree-folder-label .arrow { transform: rotate(-90deg); }
  .tree-children { padding-left: 12px; }

  .tree-group { padding-left: 12px; }
  .tree-group-label { display: flex; align-items: center; padding: 2px 12px; font-size: 13px; color: #94a3b8; font-weight: 500; gap: 6px; }

  .tree-file { display: flex; align-items: center; padding: 3px 12px 3px 24px; cursor: pointer; font-size: 12px; color: #94a3b8; gap: 6px; text-decoration: none; border-left: 3px solid transparent; }
  .tree-file:hover { background: #334155; color: #e2e8f0; }
  .tree-file.active { background: #334155; color: #38bdf8; border-left-color: #38bdf8; }
  .tree-file .icon { font-size: 14px; }

  /* Content */
  .content { flex: 1; display: flex; flex-direction: column; background: #f1f5f9; }
  .content iframe { flex: 1; border: none; background: #ffffff; }
  .welcome { flex: 1; display: flex; align-items: center; justify-content: center; }
  .welcome-inner { text-align: center; color: #64748b; }
  .welcome-inner h2 { font-size: 24px; color: #1e293b; margin-bottom: 8px; }
  .welcome-inner p { font-size: 14px; margin-bottom: 16px; }
  .welcome-inner .stat { display: inline-block; background: #e2e8f0; padding: 6px 16px; border-radius: 8px; margin: 4px; font-size: 13px; }

  /* Mobile */
  .hamburger { display: none; position: fixed; top: 8px; left: 8px; z-index: 100; background: #1e293b; color: #e2e8f0; border: none; padding: 8px 12px; border-radius: 6px; cursor: pointer; font-size: 16px; }
  @media (max-width: 768px) {
    .sidebar { position: fixed; left: -280px; top: 0; bottom: 0; z-index: 50; transition: left 0.2s; }
    .sidebar.open { left: 0; }
    .hamburger { display: block; }
    .overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.3); z-index: 40; }
    .sidebar.open ~ .overlay { display: block; }
  }
</style>
</head>
<body>
<button class="hamburger" onclick="toggleSidebar()">☰</button>
<nav class="sidebar" id="sidebar">
  <div class="sidebar-header">
    <h1>📚 Document Browser</h1>
    <div class="meta">{{TOTAL_COUNT}} files · Generated {{GENERATED_DATE}}</div>
  </div>
  <div class="sidebar-search">
    <input type="text" id="search" placeholder="Search files..." oninput="filterTree(this.value)">
  </div>
  <div class="sidebar-tree" id="tree"></div>
</nav>
<div class="overlay" onclick="toggleSidebar()"></div>
<main class="content" id="main">
  <div class="welcome" id="welcome">
    <div class="welcome-inner">
      <h2>📚 u-maker Document Browser</h2>
      <p>Select a document from the sidebar to view.</p>
      <div><span class="stat">{{TOTAL_COUNT}} files</span></div>
    </div>
  </div>
</main>
<script>
const FILES = {{FILES_JSON}};

// Build tree
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

function renderTree(node, container, depth) {
  const dirs = Object.keys(node).filter(k => k !== '__files').sort();
  dirs.forEach(dir => {
    const folder = document.createElement('div');
    folder.className = 'tree-folder' + (depth > 1 ? ' collapsed' : '');
    folder.dataset.name = dir.toLowerCase();
    const label = document.createElement('div');
    label.className = 'tree-folder-label';
    label.style.paddingLeft = (12 + depth * 8) + 'px';
    label.innerHTML = '<span class="arrow">▼</span> 📁 ' + dir;
    label.onclick = () => folder.classList.toggle('collapsed');
    folder.appendChild(label);
    const children = document.createElement('div');
    children.className = 'tree-children';

    // Group files by name
    const files = node[dir].__files || [];
    const groups = {};
    files.forEach(f => { if (!groups[f.name]) groups[f.name] = []; groups[f.name].push(f); });
    Object.keys(groups).sort().forEach(name => {
      groups[name].forEach(f => {
        const a = document.createElement('a');
        a.className = 'tree-file';
        a.style.paddingLeft = (24 + (depth + 1) * 8) + 'px';
        a.dataset.path = f.path;
        a.dataset.name = f.name.toLowerCase();
        const icon = f.type === 'md' ? '📄' : f.type === 'json' ? '📊' : '🖼️';
        const label = f.type === 'json' ? name + '.json' : f.type === 'md' ? name + '.md' : f.name;
        a.innerHTML = '<span class="icon">' + icon + '</span> ' + label;
        a.onclick = (e) => { e.preventDefault(); loadDoc(f.path); };
        children.appendChild(a);
      });
    });

    renderTree(node[dir], children, depth + 1);
    folder.appendChild(children);
    container.appendChild(folder);
  });
}

function loadDoc(path) {
  document.getElementById('welcome')?.remove();
  let iframe = document.querySelector('#main iframe');
  if (!iframe) {
    iframe = document.createElement('iframe');
    document.getElementById('main').appendChild(iframe);
  }
  iframe.src = path;
  location.hash = path;
  document.querySelectorAll('.tree-file').forEach(el => {
    el.classList.toggle('active', el.dataset.path === path);
  });
  if (window.innerWidth < 769) document.getElementById('sidebar').classList.remove('open');
}

function filterTree(query) {
  const q = query.toLowerCase();
  document.querySelectorAll('.tree-file').forEach(el => {
    el.style.display = !q || el.dataset.name.includes(q) || el.dataset.path.toLowerCase().includes(q) ? '' : 'none';
  });
  document.querySelectorAll('.tree-folder').forEach(el => {
    const hasVisible = el.querySelectorAll('.tree-file:not([style*="display: none"])').length > 0;
    el.style.display = hasVisible ? '' : 'none';
    if (q && hasVisible) el.classList.remove('collapsed');
  });
}

function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('open');
}

// Init
try {
  const treeData = buildTree();
  console.log('[u-browse] tree:', JSON.stringify(Object.keys(treeData)));
  renderTree(treeData, document.getElementById('tree'), 0);
} catch(e) {
  console.error('[u-browse] buildTree error:', e);
  document.getElementById('tree').innerHTML = '<div style="color:#f87171;padding:12px;font-size:12px;">Error building tree: ' + e.message + '</div>';
}

// Hash navigation
if (location.hash) { loadDoc(location.hash.substring(1)); }
window.addEventListener('hashchange', () => { if (location.hash) loadDoc(location.hash.substring(1)); });
</script>
</body>
</html>
```

**플레이스홀더 치환:**

| 플레이스홀더 | 치환값 |
|---|---|
| `{{FILES_JSON}}` | Step 3-1에서 구성한 파일 목록 JSON 배열 |
| `{{GENERATED_DATE}}` | 오늘 날짜 (YYYY-MM-DD) |
| `{{TOTAL_COUNT}}` | 생성된 HTML 파일 총 수 |

### Step 4: Verify & Open

1. 생성된 파일 수를 카운트:
```bash
find .u-maker/_browse -name "*.html" | wc -l
```

2. `--open` 플래그가 있으면:
```bash
open .u-maker/_browse/index.html
```

3. 완료 메시지 출력:

```
## u-browse Complete

**Files:** {n} HTML files generated
**Location:** .u-maker/_browse/

Open in browser:
  open .u-maker/_browse/index.html
```

---

## ★ CRITICAL IMPLEMENTATION RULES

1. **반드시 파일을 생성해야 한다.** 분석이나 설명만으로 끝내지 않는다. `Write` 도구로 실제 `.html` 파일을 생성하는 것이 이 스킬의 핵심이다.
2. **모든 .md 파일 → 각각 .html 파일** 생성. 하나도 빠뜨리지 않는다.
3. **모든 .json 파일 → 각각 .data.html 파일** 생성. 하나도 빠뜨리지 않는다.
4. **index.html은 반드시 마지막에 생성.** 파일 목록이 확정된 후 생성한다.
5. **병렬 처리:** 독립적인 파일 변환은 여러 Write 호출을 동시에 수행하여 속도를 높인다.
6. **디렉토리 생성:** Write 전에 `mkdir -p`로 출력 디렉토리를 먼저 생성한다.
7. **소스 문서는 READ-ONLY.** 절대로 원본 `.md`/`.json`을 수정하지 않는다.
8. **`_browse/` 디렉토리에만 쓰기.** 다른 경로에 파일을 생성하지 않는다.
9. **인라인 리소스:** CDN (marked.js, mermaid.js) 외에 외부 의존성 없는 단일 HTML.

---

## Safety Rules

1. **소스 문서 무수정:** `.md` / `.json` / `.html` 파일은 읽기만 수행 (READ-ONLY)
2. **`_browse/` 디렉토리만 쓰기:** 생성 파일은 `.u-maker/_browse/` 하위에만 생성
3. **인라인 리소스:** 외부 의존성 없는 단일 HTML (marked.js + mermaid.js CDN만 예외)
4. **민감 정보 제외:** `.env` 값, 하드코딩 시크릿은 변환에 포함하지 않음
5. **기존 파일 덮어쓰기:** 기존 `_browse/`는 경고 없이 덮어쓰기 (스냅샷 개념)
6. **원본 구조 보존:** 디렉토리 계층은 소스와 동일하게 유지
7. **독립 실행 가능:** 각 개별 HTML은 index.html 없이도 단독으로 열람 가능해야 함
