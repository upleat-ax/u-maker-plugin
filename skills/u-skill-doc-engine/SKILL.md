---
name: u-skill-doc-engine
description: "모든 SSoT 문서의 CRUD, 템플릿 렌더링, JSON 병행 내보내기, 버전 관리, 상태 추적, _index.json 자동 갱신을 수행하는 중앙 문서 관리 엔진."
---

# u-skill-doc-engine -- Central Document CRUD Engine

모든 SSoT 문서의 생성/조회/수정/삭제를 관리하는 중앙 엔진. 템플릿 렌더링, JSON 동반 내보내기, 버전 관리, `_index.json` 자동 갱신을 보장한다.

**Owner Agent:** All agents (공용 엔진)

---

## 1. Document Header Standard

모든 SSoT 문서는 YAML frontmatter 헤더를 포함한다.

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
config.language?.documents ?? "ko"
```

**규칙:**
- ID, 코드 스니펫, 기술 용어는 언어 설정과 무관하게 **항상 영문**
- Mermaid 노드 라벨은 `language.documents` 언어로 작성
- JSON companion `description`, `title` 필드는 `language.documents` 언어로 작성

> 상세 → **REFERENCE.md § Language Behavior Matrix**

### License & Copyright Resolution

HTML footer에 `u-maker.config.json`의 `license` 설정을 자동 삽입한다.
- 삽입 형식: `{license.type} · © {license.owner}`
- `.md` footer: `License: {license.type} | Copyright (c) {year} {license.owner}`
- `{{license}}` 템플릿 변수로 접근 가능

> 상세 → **REFERENCE.md § License Resolution**

### HTML Theme Policy

u-maker가 생성하는 **모든 HTML 문서**는 light/dark 모드를 지원해야 한다.

필수 규칙:
1. `<html data-theme="light|dark">` 기반 CSS 변수 구조
2. 기본 테마는 `u-maker.config.json.theme` (없으면 `light`)
3. `theme`은 `light | dark` 두 값만 허용
4. 사용자 선택은 `localStorage['u-maker-theme']`에 저장
5. 저장값 없으면 `config.theme ?? "light"` 사용. `prefers-color-scheme`는 참고용
6. header/toolbar에 `Light | Dark` toggle 제공
7. 코드 블록, 테이블, 배지, SVG 대비는 두 테마 모두 유지
8. iframe 내부 문서도 독립적 토글 동작

> 상세 → **REFERENCE.md § Theme Resolution & Config Schema**

---

## 2.5 Context Budget Policy

u-maker는 문서 수가 많아질수록 토큰 소비가 급증할 수 있으므로, 모든 agent/skill은 아래 정책을 따른다.

1. **HTML은 최후순위 입력이다.** 생성물 검토나 브라우징이 목적이 아닐 때는 `.html`을 읽지 않는다.
2. **JSON 우선, Markdown 보조.** 구조화 판단은 `.json`, 서술 보강만 `.md`를 읽는다.
3. **Index-first는 강제다.** `_index.json`, `_summary.json`, category index를 먼저 읽고 원문은 필요한 파일만 연다.
4. **Delta-read 우선.** 이미 Final/Review 문서가 있으면 전체 문서를 재독하지 말고 영향받는 섹션과 관련 companion JSON만 읽는다.
5. **`--only` 기본 사용.** 가능한 모든 생성/검증 명령은 전체 phase 대신 문서 단위 타깃을 우선 선택한다.
6. **중간 HTML 재생성 금지.** `/u-plan`, `/u-design`, `/u-dev`, `/u-qa` 실행 중에는 최종 산출 직전까지 HTML을 만들지 않는다.
7. **요약 재사용.** `_classified/_summary.json`, `_assumptions/`, `_backlog/`의 요약 데이터를 재사용하고 같은 raw source를 반복 파싱하지 않는다.
8. **대용량 입력은 chunk + merge.** 원문 전체를 다시 읽지 말고 기존 chunk 결과를 증분 병합한다.
9. **Cross-app 금지 기본.** 요청 스코프 밖 앱 문서는 읽지 않는다. 공통 정책이 필요할 때만 `common/`을 읽는다.
10. **Prompt payload 최소화.** 하위 agent로 전달할 때는 전체 본문 대신 IDs, paths, changed sections, 요약만 넘긴다.

---

## 3. UML Diagram Policy

모든 SSoT 문서에 관련 UML/다이어그램을 **최대한 포함**한다.

### 문서별 필수/권장 다이어그램

| 문서 | 필수 다이어그램 | 권장 다이어그램 |
|------|--------------|--------------|
| **SRS** | Use Case Diagram (USR-FR 관계) | Activity Diagram (주요 워크플로우) |
| **IA** | Tree/Mindmap (화면 계층) | - |
| **ERD** | ER Diagram (엔티티-관계) | - |
| **API** | Sequence Diagram (주요 API 흐름) | State Diagram (리소스 상태 전이) |
| **Screens** | Component Diagram (레이아웃 구조) | Wireframe (ASCII or HTML) |
| **Screen Flow** | Flowchart (화면 간 내비게이션) | - |
| **RTM** | - | Traceability Matrix Heatmap |
| **Test Cases** | - | State Diagram (테스트 시나리오 흐름) |
| **Code** | Class Diagram (주요 모듈 구조) | Package Diagram (디렉토리 구조) |

**스타일 규칙:**
- Mermaid 곡선 커넥터 사용 (`curve: basis`), 직선 화살표 금지
- 노드 라벨은 `language.documents` 설정 언어, ID/기술 용어는 항상 영문
- 다이어그램 위에 제목, 아래에 범례 포함

> 상세 → **REFERENCE.md § Mermaid Syntax & SVG Rendering**

---

## 4. CRUD Operations

### create(type, scope, data)

새 문서를 생성한다. 언어 설정 로드 → 템플릿 로드/렌더링 → 헤더 설정 → `.md` + `.json` 생성 → `_index.json` 갱신.

> 상세 → **REFERENCE.md § create Pseudocode**

### read(scope, doc)

문서를 조회한다. `_index.json`에서 entry 검색 → `.md` + `.json` 로드 → 반환.

> 상세 → **REFERENCE.md § read Pseudocode**

### update(scope, doc, changes)

문서를 수정한다. 기존 문서 로드 → changes 적용 → 버전 증가 → `.md` + `.json` 동시 갱신 → `_index.json` 갱신.

**Status 전환 규칙:**

| Current | Allowed Next | Trigger |
|---------|-------------|---------|
| Draft | Review | 사용자 또는 에이전트 요청 |
| Draft | Final | 직접 확정 (소규모 문서) |
| Review | Final | 사용자 승인 |
| Review | Draft | 수정 필요 (사용자 반려) |
| Final | Draft | 재작업 (사용자 확인 필수, Always-Pause) |

> 상세 → **REFERENCE.md § update Pseudocode**

### delete(scope, doc)

문서와 관련 파일을 제거한다. `.md` + `.json` + `_index.json` entry + `_links.json` entry 제거.

> 상세 → **REFERENCE.md § delete Pseudocode**

---

## 5. Template Rendering

템플릿 위치: `.u-maker/templates/{type}.template.md`

Mustache-style `{{variable}}` 치환. 지원 패턴: 단순 치환, 중첩 접근(`{{data.field}}`), 반복 블록(`{{#items}}...{{/items}}`), 조건/역조건 블록. 자동 주입 변수: `{{date}}`, `{{scope}}`, `{{lang}}`, `{{license}}`, `{{copyright}}`, `{{licenseOwner}}`.

> 상세 → **REFERENCE.md § Template Rendering Details**

---

## 6. JSON Export

모든 `.md` 파일은 동일 경로에 `.json` 동반 생성. 필드: `documentId`, `type`, `version`, `status`, `lastUpdated`, `owner`, `data`, `metadata{scope,phase,language,relatedDocs,sourceClassified}`.

**MD-JSON Sync Rules:** `.md` CRUD 시 `.json` 반드시 동반. `.json` 단독 존재 불가. version/status/lastUpdated 항상 동기.

> 상세 → **REFERENCE.md § JSON Export Schema**

---

## 7. _index.json Management

### Auto-Update Rules

모든 CRUD 작업 후 `_index.json`을 즉시 갱신한다.

| Operation | Index Action |
|-----------|-------------|
| create | 새 entry 추가 |
| update | 기존 entry의 status, version, lastUpdated 갱신 |
| delete | entry 제거 |

> 상세 → **REFERENCE.md § _index.json Schema**

---

## 8. Document Path Convention

경로: `docs/{scope}/{phase-dir}/{type}.md` + `.json`

| Phase | Dir | Types |
|-------|-----|-------|
| Plan | `01-plan/` | srs, ia, roadmap |
| Do | `02-do/` | erd, api, screens, screen-flow, ux-override, design-token, rtm, code |
| Check | `04-check/` | test-cases, test-report |
| Act | `05-act/` | iteration-log, retrospective |
| Common | `common/` | glossary, coding-convention, ux-guide, design-token |

---

## 9. Wireframe & Document Viewer (index.html)

와이어프레임 및 전체 SSoT 문서를 브라우저에서 탐색할 수 있는 `index.html`을 자동 생성한다. 출력 경로: `docs/{scope}/02-design/wireframes/index.html`

**핵심 기능:**
- Sidebar: Phase별 문서 인덱스 + 도메인별 와이어프레임 목록 + 검색/토글
- Main Content: `.html` 직접 렌더링 / `.md` Markdown+Mermaid SVG 변환 렌더링
- 단일 HTML SPA, 외부 의존성 없음 (Mermaid CDN만 허용)
- Light/Dark toggle, 반응형 (768px 미만 sidebar 접기)

**자동 재생성 트리거:** `screens.md` 생성/수정, `wireframes/` 파일 추가/삭제, `/u-design --only screens`, `/u-dev` FE 코드 생성 후

> 상세 → **REFERENCE.md § Wireframe Viewer Implementation**

---

## 10. Version Tracking

### Version Format: `Major.Minor`

| Change Type | Version Bump | Example |
|-------------|-------------|---------|
| 내용 수정 (항목 추가/수정) | Minor +1 | 1.0 → 1.1 |
| 구조 변경 (섹션 추가/제거) | Major +1, Minor = 0 | 1.3 → 2.0 |
| Status 변경만 | 버전 유지 | 1.1 → 1.1 |

버전 변경 이력은 JSON metadata의 `versionHistory` 배열에 기록한다.

> 상세 → **REFERENCE.md § Version History Schema**

---

## 11. Safety Rules

1. 모든 문서 조작은 이 엔진을 통해 수행 (직접 파일 쓰기 금지)
2. `.md` 생성/수정/삭제 시 `.json` 반드시 동반
3. `_index.json` 갱신 필수 (CRUD 후 즉시)
4. Final 상태 문서 수정 시 Always-Pause (사용자 확인)
5. 삭제된 문서의 ID를 재사용하지 않음
6. 헤더 필드 누락 금지 (5개 필수 필드)
7. version은 자동 관리 (수동 설정 무시)
8. 동일 scope에서 같은 type의 문서는 1개만 존재 (중복 생성 거부)
9. 문서 본문은 `language.documents` 설정 언어로 작성 (ID/코드는 항상 영문)
10. 모든 문서에 관련 UML 다이어그램을 최대한 포함 (Section 3 테이블 참조)
11. HTML 생성 시 Mermaid 다이어그램은 반드시 인라인 SVG로 렌더링 (외부 이미지 파일 금지)
