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
- 모든 문서 생성 스킬(`/u-plan`, `/u-design`, `/u-build`, `/u-check`, `/u-reverse` 등)은 이 설정을 따름

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

## 8. Version Tracking

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

## 9. Safety Rules

1. 모든 문서 조작은 이 엔진을 통해 수행 (직접 파일 쓰기 금지)
2. `.md` 생성/수정/삭제 시 `.json` 반드시 동반
3. `_index.json` 갱신 필수 (CRUD 후 즉시)
4. Final 상태 문서 수정 시 Always-Pause (사용자 확인)
5. 삭제된 문서의 ID를 재사용하지 않음
6. 헤더 필드 누락 금지 (5개 필수 필드)
7. version은 자동 관리 (수동 설정 무시)
8. 동일 scope에서 같은 type의 문서는 1개만 존재 (중복 생성 거부)
9. 문서 본문은 `language.documents` 설정 언어로 작성 (ID/코드는 항상 영문)
