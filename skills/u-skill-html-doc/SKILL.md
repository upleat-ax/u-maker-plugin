---
name: u-skill-html-doc
description: |
  SSoT 문서(.md + .json)를 인터랙티브 HTML 뷰어 또는 보고서로 변환한다.
  Plan/Design/Dev/Check/Act 전 Phase의 모든 문서 유형을 지원한다.
  SRS, IA, ERD, API, Screen, ScreenFlow, UXGuide, RTM, Code, UIComponents, DesignToken,
  TestCase, QAReport, IterationLog 등 14가지 doc-type 또는 `all`로 전체 변환.
  원본 .md와 동일한 경로에 .html 파일을 생성한다.
  Args: `[doc-type] [app]` — 문서 유형과 앱 이름
  Triggers: /u-skill-html-doc, HTML 문서, 문서 뷰어, document viewer, HTML 변환, html 보고서, 문서 html, html로 변환
model: sonnet
user-invocable: true
argument-hint: "[doc-type] [app]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/html-doc-template.md
  - ${PLUGIN_ROOT}/_refer/html-report-standard.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
---

# u-skill-html-doc

SSoT 문서(.md + .json)를 인터랙티브 HTML 뷰어/보고서로 변환한다.
PDCA 전 Phase의 모든 문서 유형을 지원하며, `all`로 전체 문서를 한 번에 변환한다.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `doc-type` | No | 변환 대상 문서 유형. 생략 시 전체 문서 변환 (`all`) |
| `app` | No | 멀티앱 프로젝트 시 앱 이름 |

## Doc-Type 전체 목록

### Phase 01 — Plan

| doc-type | Source File | Template Style | Output |
|----------|------------|----------------|--------|
| `srs` | `{app}/01-plan/1_SRS_RA.md` | Sidebar Viewer | `1_SRS_RA.html` |
| `ia` | `{app}/01-plan/1_IA_RA.md` | Sidebar Viewer | `1_IA_RA.html` |
| `common` | `common/01-plan/1_Common_RA.md` | Sidebar Viewer | `1_Common_RA.html` |
| `roadmap` | `common/01-plan/1_Roadmap_RA.md` | Sidebar Viewer | `1_Roadmap_RA.html` |

### Phase 02 — Design

| doc-type | Source File | Template Style | Output |
|----------|------------|----------------|--------|
| `erd` | `{app}/02-design/2_ERD_SA.md` | Sidebar Viewer | `2_ERD_SA.html` |
| `api` | `{app}/02-design/2_API_SA.md` | Sidebar Viewer | `2_API_SA.html` |
| `screen` | `{app}/02-design/2_Screen_UX.md` | Sidebar Viewer | `2_Screen_UX.html` |
| `screenflow` | `{app}/02-design/2_ScreenFlow_UX.md` | Sidebar Viewer | `2_ScreenFlow_UX.html` |
| `uxguide` | `{app}/02-design/2_UXGuide_UX.md` | Sidebar Viewer | `2_UXGuide_UX.html` |
| `rtm` | `{app}/02-design/2_RTM_RA.md` | Sidebar Viewer | `2_RTM_RA.html` |

### Phase 03 — Dev

| doc-type | Source File | Template Style | Output |
|----------|------------|----------------|--------|
| `code` | `{app}/03-dev/3_Code_DV.md` | Report (Dark) | `3_Code_DV.html` |
| `uicomponents` | `common/03-dev/3_UIComponents_UX.md` | Sidebar Viewer | `3_UIComponents_UX.html` |
| `designtoken` | `common/03-dev/3_DesignToken_UX.md` | Sidebar Viewer | `3_DesignToken_UX.html` |

### Phase 04 — Check

| doc-type | Source File | Template Style | Output |
|----------|------------|----------------|--------|
| `testcase` | `{app}/04-check/4_Case_QA.md` | Report (Dark) | `4_Case_QA.html` |
| `qareport` | `{app}/04-check/4_Report_QA.md` | Report (Dark) | `4_Report_QA.html` |

### Phase 05 — Act

| doc-type | Source File | Template Style | Output |
|----------|------------|----------------|--------|
| `iteration` | `common/05-act/5_IterationLog_RA.md` | Report (Dark) | `5_IterationLog_RA.html` |
| `report` | `common/05-act/5_Report_PM_*.md` (최신 1건) | Report (Dark) | `5_Report_PM_*.html` |

### 전체 변환

| doc-type | 동작 |
|----------|------|
| `all` | 위 모든 doc-type을 순서대로 변환 (파일이 없으면 해당 항목 Skip) |

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Template Style 구분

| Style | 적용 문서 | CSS 테마 | 레이아웃 |
|-------|----------|---------|---------|
| **Sidebar Viewer** | Plan, Design phase 문서 | Light-first (`html-doc-template.md`) | Fixed sidebar(280px) + 스크롤 main |
| **Report (Dark)** | Dev, Check, Act phase 문서 | Dark-first (`html-report-standard.md`) | 단일 컬럼, KPI Cards, Section Banner |

## Execution Flow

```
1. Read .u-maker/u-maker.config.json → projectName, documentLanguage, apps
2. Determine app context
3. Determine doc-type (argument or default 'all')
4. For each target document:
   a. Resolve file path (app-scoped or common path)
   b. Read source .md file
   c. Read source .json file (if exists, merge data)
   d. Select template style (Sidebar Viewer or Report)
   e. Parse document structure
   f. Generate HTML
   g. Write .html file to same directory as source .md
5. Output Post-Execution Summary
```

## Data Source Priority

| Priority | Source | 용도 |
|---------|--------|------|
| 1 | `.json` | 구조화된 데이터 (ID, 카운트, 관계, 상태값) |
| 2 | `.md` | 비구조화 텍스트 (설명, Business Rules, 비고) |

`.json`이 존재하면 구조화 데이터는 JSON에서 추출. `.json`이 없으면 `.md`만으로 파싱.

## Sidebar Viewer 생성 규칙

`html-doc-template.md`의 light-first 사이드바 스타일을 따른다:

- **Layout**: Fixed sidebar (280px) + scrollable main content
- **Theme**: Light-first (blue accent `#2563eb`)
- **Language**: `<html lang="{{LANG}}">` — `documentLanguage` config 값
- **Header**: Blue gradient background + 문서 제목 + 버전 뱃지
- **Stats**: `.stats-row` + `.stat-card` 주요 카운트 표시
- **Sections**: `.section` 카드 스타일 (white bg, rounded, shadow)
- **Navigation**: Smooth scroll + scroll spy + search filter
- **Single file**: Pretendard CDN만 허용, 외부 JS 금지

### Sidebar 문서 유형별 추가 컴포넌트

| doc-type | 추가 컴포넌트 |
|----------|--------------|
| `srs` | `.br-list`, `.scope-*`, `.flow`, 세분화 행(opacity:0.5) |
| `ia` | Nested `<details>` 메뉴 트리 |
| `erd` | `.entity-card`, `.field-type`, `.constraint-*` |
| `api` | `.method-*`, `.endpoint-path`, `<details>` Request/Response |
| `screen` | 화면 구성요소 테이블, 인터랙션 `.br-list` |
| `screenflow` | 화면 전환 흐름 다이어그램 (CSS Arrow) |
| `uxguide` | 디자인 토큰 컬러 스와치, 타이포그래피 샘플 |
| `rtm` | `.progress-bar`, 커버리지 카운트 |
| `uicomponents` | 컴포넌트 카드, Props 테이블 |
| `designtoken` | 컬러 팔레트, 스페이싱 스케일 시각화 |
| `common` | 공통 용어 테이블, 제약사항 목록 |
| `roadmap` | 마일스톤 타임라인 |

### Sidebar Icon 매핑

| doc-type | Icon |
|----------|------|
| `srs` | 📋 |
| `ia` | 🗺️ |
| `common` | 📚 |
| `roadmap` | 🗓️ |
| `erd` | 🗃️ |
| `api` | 🔌 |
| `screen` | 🖥️ |
| `screenflow` | 🔀 |
| `uxguide` | 🎨 |
| `rtm` | 🔗 |
| `uicomponents` | 🧩 |
| `designtoken` | 🎨 |

## Report (Dark) 생성 규칙

`html-report-standard.md`의 dark-first purple-accent 스타일을 따른다:

- **Theme**: Dark-first (`:root` = 다크, `[data-theme="light"]` = 라이트)
- **Header**: purple accent-glow gradient + 문서 제목 + 버전
- **KPI Cards**: `.kpi-grid` + `.kpi-card` (주요 카운트)
- **Section Title**: 숫자 뱃지(`.num`) + 파란 보더
- **Tables**: `.table-wrap` + `.total-row` / `.new-row` / `.fixed-row`
- **Badges**: `.badge-success` / `.badge-primary` / `.badge-warning` / `.badge-danger`
- **Summary Box**: `.summary-box` (dark background)

### Report 문서 유형별 KPI Cards

| doc-type | KPI Cards |
|----------|----------|
| `code` | 구현된 FR 수, 구현된 FT 수, API 엔드포인트 수, 빌드 상태 |
| `testcase` | 전체 TC 수, Unit TC 수, E2E TC 수, 커버리지 FT 수 |
| `qareport` | Pass, Fail, Skip, 결함 Open 수 |
| `iteration` | 현재 Iteration, Open 백로그 수, 완료 항목 수, 부채 수 |
| `report` | FR 구현률, TC Pass율, 결함 수, Gate 판정 |

## Markdown → HTML 섹션 파싱

- `##` 헤더 → `.section` + `<h2>` (사이드바 nav 항목 생성)
- `###` 헤더 → `<h3>` (사이드바 미포함)
- `####` 헤더 → `<h4>`
- Markdown 테이블 → `<div class="table-wrap"><table>...</table></div>`
- `- 항목` 리스트 → `<ul>` 또는 `.br-list`
- ` ```mermaid ... ``` ` → **Mermaid Diagram** (아래 규칙 참조)
- ` ```코드블록``` ` → `<pre><code>`
- `**굵게**` → `<strong>`
- `[링크](url)` → `<a href>`
- `ID 패턴` (FR-XXXX, US-XXXX, FT-XXXX 등) → `.tag` 스타일 인라인 뱃지

## Mermaid Diagram 파싱 규칙

`.md` 파일의 ` ```mermaid ... ``` ` 코드 블록을 HTML로 변환한다.

### 변환 형식

```
INPUT  (.md):
  ```mermaid
  flowchart TD
      A[시작] --> B[종료]
  ```

OUTPUT (.html):
  <div class="diagram-wrap" data-diagram="flowchart TD&#10;    A[시작] --&gt; B[종료]">
    <pre class="mermaid">flowchart TD
      A[시작] --> B[종료]</pre>
  </div>
```

### 변환 규칙

| 항목 | 규칙 |
|------|------|
| `data-diagram` | 원본 소스를 HTML 엔티티 인코딩 (`&amp;`, `&lt;`, `&gt;`, 개행 → `&#10;`) |
| `<pre class="mermaid">` | 원본 소스 그대로 (인코딩 없이) |
| CDN 위치 | `<head>` 내 `<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>` |
| 초기화 | `mermaid.initialize({ startOnLoad: true, theme: getMermaidTheme(), securityLevel: 'loose' })` |
| 테마 연동 | Report(Dark): `getMermaidTheme()` 함수 사용, Sidebar(Light): `theme: 'default'` 고정 |
| 테마 전환 | `toggleTheme()` 또는 테마 변경 시 `rerenderMermaid()` 호출 |
| 다이어그램 없는 문서 | CDN과 초기화 스크립트는 항상 포함 (다이어그램이 없어도 오류 없음) |

### 문서 유형별 Mermaid 다이어그램 매핑

`mermaid-guide.md`의 Mandatory Diagram Matrix에 따라 각 문서 유형에 맞는 다이어그램을 포함한다:

| doc-type | 포함할 Mermaid 다이어그램 |
|----------|------------------------|
| `srs` | `flowchart TD` (FR→US→FT 매핑), `pie` (FR 우선순위 분포) |
| `ia` | `flowchart TD` (메뉴 트리), `journey` (유저 여정) |
| `erd` | `erDiagram` (엔티티 관계), `classDiagram` (도메인 모델) |
| `api` | `C4Context` (시스템 아키텍처), `sequenceDiagram` (API 인터랙션) |
| `screen` | `stateDiagram-v2` (화면 상태 전이), `flowchart` (화면 전환) |
| `screenflow` | `flowchart LR` (스크린 플로우) |
| `uxguide` | `flowchart` (디자인 시스템 구조) |
| `rtm` | `flowchart LR` (FR→US→FT→TC 추적 흐름), `pie` (Coverage 분포) |
| `code` | `flowchart` (프로세스 플로우), `classDiagram` (모듈 구조) |
| `testcase` | `flowchart` (테스트 시나리오 플로우), `pie` (케이스 분포) |
| `qareport` | `pie` (Pass/Fail/Skip 비율), `xychart-beta` (추이) |
| `iteration` | `xychart-beta` (진행률), `gantt` (실제 일정) |

소스 `.md`에 이미 Mermaid 블록이 있으면 그대로 변환. 없으면 문서 유형에 맞게 자동 생성.

## Stats Row 자동 생성

각 문서 유형에 맞는 주요 카운트를 헤더 아래 `.stats-row`로 표시:

| doc-type | Stats |
|----------|-------|
| `srs` | USR 수, FR 수, US 수, FT 수, NFR 수 |
| `ia` | 화면 수, 메뉴 수, 뎁스 |
| `erd` | Entity 수, Relationship 수 |
| `api` | Endpoint 수, Resource 수, API 버전 |
| `screen` | Screen 수, Popup 수 |
| `rtm` | FT 수, TC 수, 커버리지 비율 |
| `code` | 구현 FT 수, API 수, 빌드 상태 |
| `testcase` | 전체 TC 수, Unit 수, E2E 수 |
| `qareport` | Pass 수, Fail 수, Skip 수 |
| `iteration` | Open 수, Closed 수, 부채 수 |

## Rules

- 원본 .md 파일이 존재하지 않으면 해당 문서는 Skip (에러 아님, 로그에 기록)
- `.html` 파일명은 원본 `.md` 파일명과 동일 (확장자만 `.html`)
- 단일 HTML 파일로 완결 (Pretendard CDN만 허용, 외부 JS 금지)
- `<html lang>` 속성은 `u-maker.config.json`의 `documentLanguage` 값
- 모든 레이블/섹션 제목은 `documentLanguage` 설정 언어로 작성
- Change Log 섹션은 반드시 포함
- `version-badge`는 원본 문서의 version frontmatter 값 사용
- 데이터가 없는 섹션은 "해당 없음" 표시 (섹션 자체는 유지)
- `all` 모드 실행 후 성공/Skip 목록을 Post-Execution Summary에 명시
- Post-Execution Summary Box 출력 필수
