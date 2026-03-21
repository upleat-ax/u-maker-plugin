---
name: u-skill-html-doc
description: |
  SSoT 문서(.md + .json)를 인터랙티브 HTML 뷰어 또는 보고서로 변환한다.
  Plan/Design/Dev/Check/Act 전 Phase의 모든 문서 유형을 지원한다.
  SRS, IA, Glossary, Workflow, ERD, API, Screen, ScreenFlow, UXGuide, RTM, Code, UIComponents, DesignToken,
  TestCase, QAReport, IterationLog 등 16가지 doc-type 또는 `all`로 전체 변환.
  원본 .md와 동일한 경로에 .html 파일을 생성한다.
  Args: `[doc-type] [app]` — 문서 유형과 앱 이름
  Triggers: /u-skill-html-doc, HTML 문서, 문서 뷰어, document viewer, HTML 변환, html 보고서, 문서 html, html로 변환, SSoT HTML, 문서 변환, convert to html, interactive document, html report, 인터랙티브 문서
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
  - ${PLUGIN_ROOT}/skills/u-skill-html-doc/references/ascii-art-rules.md
  - ${PLUGIN_ROOT}/skills/u-skill-html-doc/references/doc-type-components.md
  - ${PLUGIN_ROOT}/skills/u-skill-html-doc/references/svg-rules.md
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
| `glossary` | `{app}/01-plan/1_Glossary_RA.md` | Sidebar Viewer | `1_Glossary_RA.html` |
| `workflow` | `{app}/01-plan/1_Workflow_RA.md` | Sidebar Viewer | `1_Workflow_RA.html` |

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
| **Sidebar Viewer** | Plan, Design phase 문서 | Light-first + Dark 토글 (`html-doc-template.md`) | Fixed sidebar(280px) + 스크롤 main |
| **Report** | Dev, Check, Act phase 문서 | Dark-first + Light 토글 (`html-report-standard.md`) | 단일 컬럼, KPI Cards, Section Banner |

### 공통 테마 규칙

- 모든 HTML 파일에 **Light/Dark 테마 토글 버튼** 포함
- Sidebar Viewer: Light-first (`:root` = 라이트, `[data-theme="dark"]` = 다크)
- Report: Dark-first (`:root` = 다크, `[data-theme="light"]` = 라이트)
- OS `prefers-color-scheme` 자동 감지 + `localStorage` 저장
- 모든 색상은 CSS 변수 사용 (하드코딩 금지)
- SVG 다이어그램은 CSS 변수로 테마 자동 전환 (JS 재렌더링 불필요)

## 약어 표기 규칙

> CRITICAL: HTML 변환 시 약어를 풀어쓸 때 아래를 반드시 준수한다:
> - FT = Feature (구현 단위). ~~Functional Test~~ 절대 아님.
> - FR = Functional Requirement, US = User Story, TC = Test Case, NFR = Non-Functional Requirement

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
- **Theme**: Light-first + Dark 토글 (`:root` = 라이트, `[data-theme="dark"]` = 다크)
- **Language**: `<html lang="{{LANG}}">` — `documentLanguage` config 값
- **Header**: Blue gradient background + 문서 제목 + 버전 뱃지
- **Stats**: `.stats-row` + `.stat-card` 주요 카운트 표시
- **Sections**: `.section` 카드 스타일 (white bg, rounded, shadow)
- **Navigation**: Smooth scroll + scroll spy + search filter
- **Theme Toggle**: Fixed 버튼 (우상단) — Light/Dark 전환 + localStorage 저장
- **Diagram**: 인라인 SVG (UML Sequence/Class Diagram만 Mermaid CDN 허용)
- **Single file**: 단일 HTML, 외부 JS 완전 금지

문서 유형별 추가 컴포넌트, Sidebar Icon 매핑은 `references/doc-type-components.md` 참조.

## Report 생성 규칙

`html-report-standard.md`의 dark-first purple-accent 스타일을 따른다:

- **Theme**: Dark-first + Light 토글 (`:root` = 다크, `[data-theme="light"]` = 라이트)
- **Header**: purple accent-glow gradient + 문서 제목 + 버전
- **KPI Cards**: `.kpi-grid` + `.kpi-card` (주요 카운트)
- **Section Title**: 숫자 뱃지(`.num`) + 파란 보더
- **Tables**: `.table-wrap` + `.total-row` / `.new-row` / `.fixed-row`
- **Badges**: `.badge-success` / `.badge-primary` / `.badge-warning` / `.badge-danger`
- **Summary Box**: `.summary-box` (dark background)
- **Diagram**: 인라인 SVG (UML Sequence/Class Diagram만 Mermaid CDN 허용)

문서 유형별 KPI Cards는 `references/doc-type-components.md` 참조.

## Markdown → HTML 섹션 파싱

- `##` 헤더 → `.section` + `<h2>` (사이드바 nav 항목 생성)
- `###` 헤더 → `<h3>` (사이드바 미포함)
- `####` 헤더 → `<h4>`
- Markdown 테이블 → `<div class="table-wrap"><table>...</table></div>`
- `- 항목` 리스트 → `<ul>` 또는 `.br-list`
- ` ```mermaid ... ``` ` → **인라인 SVG 다이어그램** (아래 규칙 참조)
- ASCII art 레이아웃/다이어그램 → **인라인 SVG** (아래 "ASCII Art → SVG 변환 규칙" 참조, 단 예외 항목 제외)
- ` ```코드블록``` ` → `<pre><code>`
- `**굵게**` → `<strong>`
- `[링크](url)` → `<a href>`
- `ID 패턴` (FR-XXXX, US-XXXX, FT-XXXX 등) → `.tag` 스타일 인라인 뱃지

## SVG Diagram Rules

Mermaid 코드 블록과 문서 데이터를 인라인 SVG로 변환한다. 외부 JS 라이브러리(Mermaid 포함) 금지 — UML Sequence/Class Diagram만 예외. 모든 색상은 `var(--diagram-*)` CSS 변수 사용. 상세 규칙은 `references/svg-rules.md` 참조.

## ASCII Art → SVG 변환 Rules

ASCII art 레이아웃/다이어그램을 감지하여 인라인 SVG로 변환한다. `<pre>` 태그로 그대로 출력 금지 (소스 코드, 폴더 트리, CLI 출력은 예외). 상세 규칙 및 변환 예시는 `references/ascii-art-rules.md` 참조.

## Doc-Type 컴포넌트 및 Stats

각 문서 유형별 추가 컴포넌트(Sidebar Icon 매핑, Report KPI Cards, Stats Row)는 `references/doc-type-components.md` 참조.

## Rules

- 원본 .md 파일이 존재하지 않으면 해당 문서는 Skip (에러 아님, 로그에 기록)
- `.html` 파일명은 원본 `.md` 파일명과 동일 (확장자만 `.html`)
- 단일 HTML 파일로 완결 (UML Sequence/Class Diagram만 Mermaid CDN 허용, 그 외 외부 JS 금지)
- 다이어그램은 인라인 SVG로 작성 (CSS 변수 사용, 테마 자동 전환)
- 모든 HTML 파일에 Light/Dark 테마 토글 버튼 포함
- `<html lang>` 속성은 `u-maker.config.json`의 `documentLanguage` 값
- 모든 레이블/섹션 제목은 `documentLanguage` 설정 언어로 작성
- Change Log 섹션은 반드시 포함
- `version-badge`는 원본 문서의 version frontmatter 값 사용
- 데이터가 없는 섹션은 "해당 없음" 표시 (섹션 자체는 유지)
- `all` 모드 실행 후 성공/Skip 목록을 Post-Execution Summary에 명시
- Post-Execution Summary Box 출력 필수

## References

| 파일 | 내용 |
|------|------|
| `references/svg-rules.md` | SVG Diagram 변환 규칙, CSS 변수, 문서 유형별 다이어그램 매핑, 공통 Defs 블록 |
| `references/ascii-art-rules.md` | ASCII Art → SVG 변환 규칙, 감지 기준, 변환 예시, 문서 유형별 처리 |
| `references/doc-type-components.md` | Sidebar 문서 유형별 추가 컴포넌트, Icon 매핑, Report KPI Cards, Stats Row |
