---
name: u-skill-doc-engine
description: "모든 SSoT 문서의 CRUD, 템플릿 렌더링, JSON 병행 내보내기, 버전 관리, 상태 추적, _index.json 자동 갱신을 수행하는 중앙 문서 관리 엔진."
---

# u-skill-doc-engine -- Central Document CRUD Engine

모든 SSoT 문서의 생성/조회/수정/삭제를 관리하는 중앙 엔진. 모든 문서 조작은 이 엔진을 통해 수행되며, 템플릿 렌더링, JSON 동반 내보내기, 버전 관리, `_index.json` 자동 갱신을 보장한다.

**Owner Agent:** All agents (공용 엔진)

---

## 1. Document Header Standard

모든 SSoT 문서는 YAML frontmatter 헤더를 포함한다.

```markdown
---
Owner: u-agent-planner
Status: Draft
Version: 1.0
Last Updated: 2026-03-27
Related Docs: [srs.md, erd.md]
---
```

### Header Fields

| Field | Required | Description |
|-------|----------|-------------|
| `Owner` | YES | 담당 에이전트 이름 |
| `Status` | YES | Draft, Review, Final |
| `Version` | YES | Major.Minor (수정 시 자동 증가) |
| `Last Updated` | YES | ISO 8601 날짜 |
| `Related Docs` | YES | 관련 문서 목록 |

---

## 2. Language Setting

문서 생성 시 `u-maker.config.json`의 `language.documents` 값을 참조하여 해당 언어로 문서를 작성한다.

### Language Resolution

```
function resolveLanguage():
  config = loadConfig("u-maker.config.json")
  lang = config.language?.documents ?? "ko"   // 기본값: ko
  return lang
```

### Language Behavior

| `language.documents` | 문서 본문 언어 | 섹션 제목 | 설명/Description | ID/코드 |
|---------------------|--------------|----------|-----------------|---------|
| `ko` | 한국어 | 한국어 | 한국어 | 영문 유지 (FR-0001, POST /api/...) |
| `en` | English | English | English | 영문 유지 |
| `ja` | 日本語 | 日本語 | 日本語 | 영문 유지 |
| `zh` | 中文 | 中文 | 中文 | 영문 유지 |

**규칙:**
- ID, 코드 스니펫, 기술 용어(API path, entity name, HTTP method 등)는 언어 설정과 무관하게 **항상 영문**
- Mermaid 다이어그램의 노드 라벨은 `language.documents` 언어로 작성
- JSON companion 파일의 `description`, `title` 필드는 `language.documents` 언어로 작성
- 모든 문서 생성 스킬(`/u-plan`, `/u-design`, `/u-dev`, `/u-check`, `/u-reverse` 등)은 이 설정을 따름

---

## 3. CRUD Operations

### create(type, scope, data)

새 문서를 생성한다.

**프로세스:**

1. **언어 설정 로드:**
   - `u-maker.config.json` → `language.documents` 읽기
   - 문서 본문, 제목, 설명을 해당 언어로 작성

2. **템플릿 로드:**
   - `_meta/templates/{type}.template.md` 파일 읽기
   - 템플릿이 없으면 기본 구조 사용

3. **템플릿 렌더링:**
   - Mustache-style `{{variable}}` 치환
   - 중첩 변수 지원: `{{data.title}}`, `{{items.length}}`
   - 반복 블록: `{{#items}}...{{/items}}`
   - 조건 블록: `{{#hasData}}...{{/hasData}}`
   - `{{lang}}` → 현재 언어 코드 자동 주입

4. **헤더 설정:**
   ```yaml
   Owner: {agent}
   Status: Draft
   Version: 1.0
   Last Updated: {today}
   Related Docs: {auto-detect from type}
   ```

4. **파일 생성:**
   - `.md` 파일 생성
   - `.json` 동반 파일 생성
   - 경로: `docs/{scope}/{phase-dir}/{type}.md`

5. **인덱스 갱신:**
   - `_index.json`에 문서 등록

**출력:**

```json
{
  "status": "created",
  "files": {
    "md": "docs/retail/01-plan/srs.md",
    "json": "docs/retail/01-plan/srs.json"
  },
  "version": "1.0",
  "indexUpdated": true
}
```

### read(scope, doc)

문서를 조회한다.

```
function read(scope, doc):
  // type name으로 검색
  index = loadIndex(scope)
  entry = index.documents.find(d => d.id === doc || d.type === doc)

  if not entry:
    return { status: "not-found", message: "{doc}을 찾을 수 없습니다." }

  mdContent = readFile(entry.path)
  jsonContent = readFile(entry.path.replace(".md", ".json"))

  return {
    status: "found",
    md: mdContent,
    json: jsonContent,
    metadata: entry
  }
```

### update(scope, doc, changes)

문서를 수정한다.

**프로세스:**

1. 기존 문서 로드
2. `changes` 적용:
   - 섹션별 부분 업데이트 지원
   - 항목 추가/수정/삭제
3. 버전 증가:
   - 내용 변경 → Minor 증가 (1.0 → 1.1)
   - 구조 변경 → Major 증가 (1.1 → 2.0)
4. `Last Updated` 갱신
5. `.md` + `.json` 동시 갱신
6. `_index.json` 갱신

**Status 전환 규칙:**

| Current | Allowed Next | Trigger |
|---------|-------------|---------|
| Draft | Review | 사용자 또는 에이전트 요청 |
| Draft | Final | 직접 확정 (소규모 문서) |
| Review | Final | 사용자 승인 |
| Review | Draft | 수정 필요 (사용자 반려) |
| Final | Draft | 재작업 (사용자 확인 필수, Always-Pause) |

**Final 문서 수정 시:**
- 반드시 사용자 확인 필요 (Always-Pause)
- 확인 후 Status → Draft로 전환
- 변경 사유 기록

### delete(scope, doc)

문서와 관련 파일을 제거한다.

```
function delete(scope, doc):
  // .md + .json + _index.json 엔트리 제거
  entry = findDocument(scope, doc)
  removeFile(entry.path)                    // .md
  removeFile(entry.path.replace(".md", ".json"))  // .json
  removeFromIndex(scope, entry.id)          // _index.json
  removeFromLinks(entry.id)                 // _links.json

  return { status: "deleted", files: [entry.path, jsonPath] }
```

---

## 4. Template Rendering

### Template Location

```
.u-maker/templates/{type}.template.md
```

### Mustache-Style Substitution

| Pattern | Description | Example |
|---------|-------------|---------|
| `{{variable}}` | 단순 치환 | `{{title}}` → "Login System" |
| `{{data.field}}` | 중첩 접근 | `{{project.name}}` → "Retail App" |
| `{{#section}}...{{/section}}` | 반복 블록 | 배열 항목 반복 |
| `{{#flag}}...{{/flag}}` | 조건 블록 | flag가 truthy일 때만 |
| `{{^flag}}...{{/flag}}` | 역조건 블록 | flag가 falsy일 때만 |
| `{{date}}` | 현재 날짜 (자동) | 2026-03-28 |
| `{{scope}}` | 현재 스코프 (자동) | retail |
| `{{lang}}` | 문서 언어 코드 (자동) | ko |

### Template Example

```markdown
---
Owner: {{owner}}
Status: Draft
Version: 1.0
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
---

# {{title}}

## 1. Overview

{{description}}

{{#sections}}
## {{sectionNumber}}. {{sectionTitle}}

{{sectionContent}}
{{/sections}}
```

---

## 5. JSON Export

모든 `.md` 파일은 동일 경로에 `.json` 동반 생성.

### JSON Structure

```json
{
  "documentId": "{scope}/{type}",
  "type": "{type}",
  "version": "1.0",
  "status": "Draft",
  "lastUpdated": "{ISO 8601}",
  "owner": "{agent}",
  "data": {
    /* 문서 유형별 구조화된 데이터 */
  },
  "metadata": {
    "scope": "{scope}",
    "phase": "{phase}",
    "language": "{lang}",
    "relatedDocs": [],
    "sourceClassified": []
  }
}
```

### MD → JSON Sync Rules

- `.md` 생성 시 `.json` 반드시 함께 생성
- `.md` 수정 시 `.json` 반드시 함께 갱신
- `.md` 삭제 시 `.json` 반드시 함께 삭제
- `.json`만 단독 존재 불가 (반드시 `.md` 동반)
- `.md`와 `.json`의 version, status, lastUpdated는 항상 동기

---

## 6. _index.json Management

### _index.json Structure

```json
{
  "scope": "retail",
  "lastUpdated": "{ISO 8601}",
  "documents": [
    {
      "id": "srs",
      "type": "srs",
      "path": "01-plan/srs.md",
      "status": "Final",
      "version": "1.2",
      "lastUpdated": "{ISO 8601}",
      "owner": "u-agent-planner",
      "phase": "plan"
    }
  ]
}
```

### Auto-Update Rules

모든 CRUD 작업 후 `_index.json`을 즉시 갱신한다.

| Operation | Index Action |
|-----------|-------------|
| create | 새 entry 추가 |
| update | 기존 entry의 status, version, lastUpdated 갱신 |
| delete | entry 제거 |

---

## 7. Document Path Convention

```
docs/{scope}/{phase-dir}/{type}.md
docs/{scope}/{phase-dir}/{type}.json
```

### Phase Directories

| Phase | Directory | Document Types |
|-------|-----------|---------------|
| Plan | `01-plan/` | srs, ia, roadmap |
| Do | `02-do/` | erd, api, screens, screen-flow, ux-override, design-token, rtm, code |
| Check | `04-check/` | test-cases, test-report |
| Act | `05-act/` | iteration-log, retrospective |
| Common | `common/` | glossary, coding-convention, ux-guide, design-token |

---

## 8. Wireframe Viewer (index.html)

와이어프레임 및 SSoT 문서를 브라우저에서 탐색할 수 있는 `index.html`을 자동 생성한다.

### 생성 시점

아래 문서가 생성/수정될 때 `index.html`을 자동 재생성한다:
- `screens.md` / `screens.json` (화면 설계)
- `screen-flow.md` (화면 흐름)
- `wireframes/` 디렉토리 내 `.html` 또는 `.md` 파일

### 출력 경로

```
docs/{scope}/02-design/wireframes/index.html
```

### index.html 구조

단일 HTML 파일(SPA)로 외부 의존성 없이 동작한다.

```
┌─────────────────────────────────────────────────────┐
│  {ProjectName} Wireframes v{version}                │
│  {appName} — 화면 기획서                              │
├──────────────┬──────────────────────────────────────┤
│  Sidebar     │  Main Content                        │
│              │                                      │
│  ─ {Group1}  │  (선택된 와이어프레임 렌더링)            │
│    SCR-001   │                                      │
│    SCR-002   │  .html → iframe 또는 innerHTML        │
│    SCR-003   │  .md   → Markdown → HTML 렌더링       │
│              │                                      │
│  ─ {Group2}  │                                      │
│    SCR-004   │                                      │
│    SCR-005   │                                      │
│              │                                      │
└──────────────┴──────────────────────────────────────┘
```

### 핵심 기능

#### Sidebar Navigation
- `screens.json`의 화면 목록을 그룹별로 표시
- 그룹핑 기준: IA의 Level 1 화면 (Parent가 없는 화면) 하위로 묶음
- 각 그룹 옆에 화면 개수 배지 표시
- 화면 ID + 이름 표시 (예: `0901 벌초 접수 내역`)
- 클릭 시 오른쪽 Main Content에 해당 와이어프레임 로드
- 그룹 접기/펴기(collapse/expand) 지원

#### Main Content Area
- **`.html` 파일:** `<iframe>` 또는 `innerHTML`로 직접 렌더링
- **`.md` 파일:** 내장 Markdown 파서로 HTML 변환 후 렌더링
  - 지원: headings, paragraphs, lists, tables, code blocks, bold/italic, links, images
  - Mermaid 코드 블록 → Mermaid.js CDN으로 다이어그램 렌더링
- 와이어프레임 미선택 시 안내 메시지 표시:
  ```
  와이어프레임을 선택하세요
  왼쪽 사이드바에서 화면을 클릭하면 여기에 표시됩니다 (총 {n}개 화면)
  ```

#### 파일 매핑 규칙

와이어프레임 파일은 `wireframes/` 디렉토리에 화면 ID 기반으로 배치한다:

```
docs/{scope}/02-design/wireframes/
├── index.html              ← 자동 생성 (뷰어)
├── SCR-001.html            ← HTML 와이어프레임
├── SCR-002.md              ← Markdown 와이어프레임
├── SCR-003.html
└── ...
```

파일명 매핑 우선순위:
1. `{SCR-ID}.html` (최우선)
2. `{SCR-ID}.md`
3. 매핑 파일 없음 → Main Content에 "와이어프레임 미작성" 표시

### index.html 생성 프로세스

```
function generateWireframeViewer(scope):
  config = loadConfig()
  screensJson = read("docs/{scope}/02-design/screens.json")
  iaJson = read("docs/{scope}/01-plan/ia.json")

  // 1. 화면 목록 + 그룹핑 데이터 구성
  groups = groupScreensByIA(screensJson, iaJson)

  // 2. wireframes/ 디렉토리 스캔 → 파일 매핑
  files = scanDir("docs/{scope}/02-design/wireframes/")
  mapping = mapScreensToFiles(screensJson, files)

  // 3. index.html 생성 (인라인 CSS + JS, 외부 의존성 없음)
  html = renderViewerTemplate({
    projectName: config.projectName,
    appName: scope,
    version: screensJson.version,
    groups: groups,
    mapping: mapping,
    totalScreens: screensJson.screens.length,
    language: config.language?.documents ?? "ko"
  })

  // 4. 파일 쓰기
  write("docs/{scope}/02-design/wireframes/index.html", html)
```

### 스타일 사양

| 요소 | 사양 |
|------|------|
| Sidebar 배경 | `#1e293b` (dark slate) |
| Sidebar 텍스트 | `#e2e8f0` (light gray) |
| Sidebar 너비 | `320px` (고정) |
| 그룹 제목 | bold, 좌측에 색상 dot indicator |
| 화면 ID 배지 | `#334155` 배경, `#94a3b8` 텍스트, border-radius 4px |
| Main Content 배경 | `#f1f5f9` (light blue-gray) |
| 선택된 항목 | `#334155` 배경 하이라이트 |
| 안내 메시지 | 중앙 정렬, `#64748b` 텍스트 |
| 반응형 | 768px 미만에서 sidebar 접기 + 햄버거 메뉴 |

### Markdown 렌더링 사양

index.html에 인라인으로 경량 Markdown 파서를 포함한다:

```
지원 문법:
- # ~ ###### headings
- **bold**, *italic*, ~~strikethrough~~
- - / * / 1. lists (nested)
- | table | header | (GFM tables)
- ``` code blocks ``` (syntax highlighting 없이 monospace)
- [link](url), ![image](url)
- > blockquote
- --- horizontal rule
- ```mermaid 블록 → <div class="mermaid"> 변환 (Mermaid.js CDN 로드)
```

### 자동 재생성 트리거

| 이벤트 | 동작 |
|--------|------|
| `screens.md` 생성/수정 | index.html 재생성 |
| `wireframes/` 내 파일 추가/삭제 | index.html 재생성 |
| `/u-design --only screens` 실행 | index.html 재생성 |
| `/u-dev` FE 코드 생성 후 | index.html 재생성 (wireframe 파일이 있을 때) |

---

## 9. Version Tracking


### Version Format

`Major.Minor`

| Change Type | Version Bump | Example |
|-------------|-------------|---------|
| 내용 수정 (항목 추가/수정) | Minor +1 | 1.0 → 1.1 |
| 구조 변경 (섹션 추가/제거) | Major +1, Minor = 0 | 1.3 → 2.0 |
| Status 변경만 | 버전 유지 | 1.1 → 1.1 |

### Version History

문서 내 버전 변경 이력 추적 (json의 metadata에 기록):

```json
{
  "versionHistory": [
    { "version": "1.0", "date": "2026-03-25", "author": "u-agent-planner", "changes": "Initial creation" },
    { "version": "1.1", "date": "2026-03-27", "author": "u-agent-planner", "changes": "Added FR-0015, FR-0016" }
  ]
}
```

---

## 10. Safety Rules

1. 모든 문서 조작은 이 엔진을 통해 수행 (직접 파일 쓰기 금지)
2. `.md` 생성/수정/삭제 시 `.json` 반드시 동반
3. `_index.json` 갱신 필수 (CRUD 후 즉시)
4. Final 상태 문서 수정 시 Always-Pause (사용자 확인)
5. 삭제된 문서의 ID를 재사용하지 않음
6. 헤더 필드 누락 금지 (5개 필수 필드)
7. version은 자동 관리 (수동 설정 무시)
8. 동일 scope에서 같은 type의 문서는 1개만 존재 (중복 생성 거부)
9. 문서 본문은 `language.documents` 설정 언어로 작성 (ID/코드는 항상 영문)
