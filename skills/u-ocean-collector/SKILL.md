---
name: u-ocean-collector
description: |
  Figma 링크를 받아 MCP로 디자인 데이터를 수집·분석하고, Mermaid 다이어그램이 포함된 분석 보고서를 생성한다.
  This skill should be used when the user asks to "Figma 분석", "Figma 디자인 수집",
  "Figma 링크로 보고서 작성", "figma collect", "figma analyze", "디자인 데이터 수집",
  "Figma 캡쳐", "Figma 리뷰", "ocean collector", "디자인 분석 보고서", "figma report",
  "Figma 보고서", "디자인 리뷰", or provides a Figma URL (figma.com/design/...) for analysis.
  Args: `<figma-url> [--depth deep|shallow] [--output md|html]`
model: sonnet
user-invocable: true
argument-hint: "<figma-url> [--depth deep|shallow] [--output md|html]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
  - mcp__claude_ai_Figma__get_design_context
  - mcp__claude_ai_Figma__get_screenshot
  - mcp__claude_ai_Figma__get_metadata
  - mcp__claude_ai_Figma__get_figjam
---

# u-ocean-collector

Figma 링크를 받아 MCP 도구로 디자인 데이터를 수집하고, 구조·컴포넌트·UX 흐름을 분석하여 Mermaid 다이어그램이 포함된 보고서를 생성한다.

## Syntax

```
/u-ocean-collector <figma-url>                          # 기본 분석 (deep)
/u-ocean-collector <figma-url> --depth shallow          # 최상위 프레임만 분석
/u-ocean-collector <figma-url> --depth deep             # 하위 노드까지 심층 분석 (기본값)
/u-ocean-collector <figma-url> --output html            # HTML 보고서로 출력
/u-ocean-collector <figma-url> --output md              # Markdown 보고서 (기본값)
```

## Figma URL Parsing

Figma URL에서 `fileKey`와 `nodeId`를 추출한다:

| URL Pattern | Extraction |
|---|---|
| `figma.com/design/:fileKey/:fileName` | fileKey 직접 추출 |
| `figma.com/design/:fileKey/:fileName?node-id=:nodeId` | nodeId의 `-`를 `:`로 변환 |
| `figma.com/design/:fileKey/branch/:branchKey/:fileName` | branchKey를 fileKey로 사용 |
| `figma.com/board/:fileKey/:fileName` | FigJam 파일 → `get_figjam` 사용 |

## Workflow

### Step 1: URL 파싱 및 초기 정보 수집

```
1. $ARGUMENTS에서 Figma URL 추출
2. URL이 없으면 AskUserQuestion으로 Figma URL 요청
3. fileKey, nodeId 파싱
4. --depth (기본 deep), --output (기본 md) 옵션 파싱
5. 저장 경로 준비: data/source/figma/
```

### Step 2: Figma MCP 데이터 수집

순서대로 MCP 도구를 호출하여 디자인 데이터를 수집한다:

```
1. get_metadata(fileKey)
   → 파일명, 마지막 수정일, 페이지 목록, 컴포넌트 목록 수집
   → data/source/figma/{YYYYMMDD}-{파일명}-metadata.json 저장

2. get_design_context(fileKey, nodeId?)
   → 디자인 코드, 컴포넌트 구조, 디자인 토큰, 어노테이션 수집
   → data/source/figma/{YYYYMMDD}-{파일명}-context.md 저장

3. get_screenshot(fileKey, nodeId?)
   → 전체 또는 특정 노드의 스크린샷 캡처
   → 스크린샷 URL을 보고서에 임베드

4. depth=deep일 때 추가 수집:
   → 주요 프레임별 get_design_context 개별 호출
   → 프레임별 get_screenshot 개별 캡처
```

**FigJam 파일인 경우:** `get_figjam(fileKey)` 호출 → 다이어그램, 스티키 노트, 커넥터 데이터를 수집한다.

### Step 3: 디자인 분석

수집된 데이터를 기반으로 6개 분석 영역을 평가한다:

| 분석 영역 | 분석 내용 |
|---|---|
| **구조 분석** | 페이지/프레임 계층 구조, 네이밍 패턴, 그룹핑 |
| **컴포넌트 분석** | 컴포넌트 목록, 재사용률, 변형(variant), 인스턴스 |
| **스타일 분석** | 컬러 팔레트, 타이포그래피, 간격/여백 패턴 |
| **UX 흐름 분석** | 화면 간 연결, 사용자 흐름, 네비게이션 패턴 |
| **일관성 분석** | 스타일 통일성, 컴포넌트 오용, 명명 규칙 준수 |
| **접근성 분석** | 명도 대비, 터치 타겟 크기, 텍스트 가독성 |

### Step 4: 다이어그램 생성

분석 결과를 Mermaid 다이어그램으로 시각화한다. 모든 다이어그램은 보고서에 Mermaid 코드블록으로 삽입한다.

**필수 다이어그램:**

1. **페이지/프레임 구조도** — 파일의 전체 페이지·프레임 계층 (graph TD)
2. **화면 흐름도** — 화면 간 네비게이션 흐름 (flowchart LR)
3. **컴포넌트 계층도** — 컴포넌트 구성과 변형 (graph TD)
4. **컬러 시스템 맵** — 테이블 형식 + 컬러칩

**선택 다이어그램 (depth=deep일 때):**

5. **상태 다이어그램** — 인터랙션 상태 변화 (stateDiagram-v2)
6. **컴포넌트 의존성 그래프**

Mermaid 코드 패턴과 예시는 `references/figma-analysis-guide.md`를 따른다.

### Step 5: 보고서 생성

`references/report-template.md` 구조를 따라 분석 보고서를 생성한다.

**보고서 저장 위치:**

| 출력 형식 | 저장 경로 |
|---|---|
| Markdown | `data/analyzed/design-review/{YYYYMMDD}-{파일명}-analysis.md` |
| HTML | `/tmp/ocean-collector-{YYYYMMDD}-{파일명}.html` |

**보고서 JSON 메타데이터도 함께 생성:**
```json
{
  "type": "design-review",
  "title": "Figma 디자인 분석 — {파일명}",
  "figmaUrl": "https://figma.com/design/...",
  "fileKey": "...",
  "createdAt": "2026-03-24T10:00:00+09:00",
  "depth": "deep",
  "output": "md",
  "stats": {
    "pages": 0,
    "frames": 0,
    "components": 0,
    "styles": 0,
    "screenshots": 0
  },
  "diagrams": ["structure", "flow", "components", "colors"],
  "sources": ["figma/{YYYYMMDD}-{파일명}-metadata.json", "figma/{YYYYMMDD}-{파일명}-context.md"]
}
```

### Step 6: HTML 변환 (--output html)

HTML 출력 시 Mermaid 코드블록을 `<pre class="mermaid">` 블록으로 변환한다.
HTML 스타일, Mermaid 렌더링 스크립트, CSS 상세는 `references/report-template.md`의 HTML 변환 섹션을 따른다.
기본 규칙은 u-ocean-report와 동일 (Pretendard 폰트, max-width 1100px, `<html lang="ko">`, CSS 인라인).

## Diagram Rules

- 모든 다이어그램은 **Mermaid 코드블록**으로 작성한다 (```mermaid)
- HTML 출력 시 Mermaid.js CDN으로 클라이언트 렌더링한다
- 노드 라벨에 한글을 사용한다 (Figma 원본 텍스트 반영)
- 다이어그램이 10개 이상의 노드를 가질 경우 서브그래프로 분리한다
- 컬러 시스템은 Mermaid로 표현이 어려우므로 HTML 테이블 + 컬러칩으로 표시한다

## Completion Output

```
Figma 디자인 분석 완료!

Figma: {figma-url}
파일명: {file-name}
분석: data/analyzed/design-review/{filename}.md
메타: data/analyzed/design-review/{filename}.json
스크린샷: {screenshot-count}장
다이어그램: {diagram-count}개

수정이 필요하면 말씀해주세요.
```

## Rules

- Figma MCP 호출 실패 시 에러 원인을 AskUserQuestion으로 보고하고 재시도 여부를 확인한다
- 수집 데이터는 항상 `data/source/figma/`에 원본 보존한다
- 분석 보고서는 `data/analyzed/design-review/`에 저장한다
- 다이어그램은 반드시 Mermaid 형식으로 작성한다 (이미지 변환 없이 코드블록 유지)
- JSON 메타데이터 파일은 `.md` 파일과 동일 경로에 동일 파일명으로 생성한다
- FigJam 파일은 `get_figjam`으로 수집하고 다이어그램/스티키노트를 분석한다
- 스크린샷 URL은 Figma MCP 반환값을 그대로 사용한다 (다운로드 불필요)

## References

| File | Content |
|---|---|
| `references/figma-analysis-guide.md` | 분석 영역별 상세 기준, 평가 매트릭스, Mermaid 다이어그램 패턴 |
| `references/report-template.md` | 보고서 전체 템플릿, HTML 변환 규칙, CSS 스타일 |
