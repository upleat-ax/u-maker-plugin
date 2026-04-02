---
name: u-browse
description: "SSoT 문서를 분석·교차참조·다이어그램 포함한 리치 HTML로 변환. 와이어프레임에는 어노테이션·화면흐름·비즈니스로직·버튼액션을 포함한다. index.html sidebar navigation 제공."
triggers:
  - "/u-browse"
  - "browse"
  - "문서 뷰어"
  - "docs html"
  - "문서 브라우징"
  - "개별 HTML"
  - "doc viewer"
---

# u-browse -- Enriched SSoT Document Browser

`/u-browse [scope] [--only path] [--open]` — `.u-maker/docs/` SSoT 문서를 **분석·교차참조·다이어그램 포함 리치 HTML**로 변환하고 **index.html** sidebar로 브라우징.

**Primary Agent:** u-agent-orchestrator

> **단순 변환이 아니다.** 다른 문서를 교차 참조하고, JSON 데이터를 분석하여 다이어그램·통계·어노테이션을 자동 생성한 **리치 HTML**을 만든다.

> **전역 HTML 규칙:** 모든 HTML에 `Light | Dark` toggle + `localStorage['u-maker-theme']` 테마 저장 지원.

---

## Arguments & Flags

| Argument/Flag | Required | Description |
|---------------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 전체 앱 |
| `--only path` | - | 특정 경로만 변환 (예: `--only hjw/02-design`) |
| `--open` | - | 생성 후 브라우저 자동 열기 |
| `--clean` | - | 기존 `out/browse/` 삭제 후 재생성 |
| `--loop` | - | Content+Style Quality Loop (QV-01~QV-10 평가, 평균 95점 초과까지 반복) |

---

## Output Structure

```
.u-maker/out/browse/
├── index.html                    # 메인 뷰어 (sidebar + iframe)
├── {app}/01-plan/
│   ├── srs.html, ia.html, roadmap.html
├── {app}/02-design/
│   ├── erd.html, api.html, screens.html, screen-flow.html
│   ├── rtm.html, design-token.html, ui-components.html
│   └── wireframes/SCR-NNN.html   # 와이어프레임 + 어노테이션
├── {app}/03-dev/, 04-check/
```

---

## Execution Flow

### Step 0: Load ALL Context (CRITICAL)

scope 내 **모든 `.md`와 `.json`** 파일을 Read로 먼저 적재. contextMap과 교차 참조 인덱스를 구성.

**contextMap 키:** srs, ia, erd, api, screens, screenFlow, rtm, designToken
**교차 참조 인덱스:** ftToScreens, screenToApis, screenToFts, entityToApis, screenFlows, ftToTcs

> 상세 구조 → **REFERENCE.md § Step 0**

### Step 1: Discover Files & Create Directories

`out/browse/{scope}/{app}/01-plan/`, `02-design/wireframes/`, `03-dev/`, `04-check/` 생성.

### Step 2: Generate Enriched HTML per Document Type

각 문서 `.md` + `.json`을 contextMap 교차 참조하여 리치 HTML 생성:

| 문서 | HTML | 핵심 생성물 |
|------|------|------------|
| SRS | srs.html | 계층 시각화, Use Case 다이어그램, 커버리지 바 |
| IA | ia.html | **인라인 SVG Sitemap**, 화면 계층, User Flow |
| ERD | erd.html | erDiagram, Entity Card, API/Screen 바인딩 |
| API | api.html | 메서드 배지, Sequence 다이어그램, Screen 매핑 |
| Screens | screens.html | 컴포넌트 상세, stateDiagram, API/데이터 연결 |
| Screen Flow | screen-flow.html | 네비게이션 flowchart, 전이 규칙 |
| RTM | rtm.html | 커버리지 히트맵, Gap 분석 |
| Design Token | design-token.html | 컬러 스워치, 타이포 스케일 |
| UI Components | ui-components.html | 컴포넌트 카탈로그, Usage Matrix |

> 각 문서별 상세 명세 → **REFERENCE.md § Step 2**

### Step 3: Generate Wireframe HTML (가장 중요)

**각 SCR-NNN은 풀 앱 프레임 + 인라인 어노테이션 + 컴포넌트 명세 + 로직 다이어그램이 포함된 종합 설계 문서.**

**3개 블록 구조:**
1. **doc-header** — 화면ID, 화면명, route, FT/FR, theme toggle, index 복귀
2. **stage** — 좌: IA 기반 앱 내비 + wireframe + 인라인 마커 / 우: Design·Develop·기타 annotation panel
3. **detail-tabs** — 7개 고정 탭: Overlays, Event Actions, Data Models, Screen Flow, Sequence Diagram, Component Spec, Global Rules

**와이어프레임 생성 13단계:**
1. Screen Meta 수집 → 2. Theme Frame → 3. Left Stage(IA 내비 + 컴포넌트 + ERD 필드) → 4. Inline Annotation → 5. Right Annotation Panel(Design/Develop/기타) → 6. Overlay Tab(실제 UI mockup) → 7. Event Actions Tab → 8. Data Models Tab → 9. Screen Flow Tab → 10. Sequence Diagram Tab → 11. Component Spec Tab → 12. Global Rules Tab → 13. 반응형 검증

**No-Clipping 필수:** `page-canvas`, `tab-panels`, `overlay-preview` 등은 `height:auto; max-height:none; overflow:visible`. 전체 콘텐츠 펼친 상태로 렌더링.

**마커 규칙:** 유니코드 원숫자(①) 금지. ASCII 숫자를 `.mk` 원형 badge에 렌더링.

> HTML 구조, CSS, 마커 CSS, overlay 상세 → **REFERENCE.md § Step 3**

### Step 3.5: Page-level Side Navigation

모든 개별 문서 HTML에 **페이지 내 섹션 네비게이션** 추가. `page-layout` grid + `page-nav` sticky sidebar + scroll spy.

> HTML/CSS/JS 구현 + 문서별 섹션 목록 → **REFERENCE.md § Step 3.5**

### Step 4: Generate index.html (Main Viewer)

sidebar 파일 트리를 구성하여 메인 뷰어 생성.

**sidebar 핵심 규칙:**
- 고정 섹션 순서: Plan → Design → Wireframes → Reports
- 2-depth까지만 노출, wireframe은 도메인 그룹으로 묶기
- 도메인명 정규화 (유사 이름 병합)
- 화면 1개 도메인은 `기타` 흡수
- 검색: 도메인/ID/화면명/route 지원, 결과는 flat list

> FILES 배열, buildTree, groupWireframesByDomain, sidebar HTML → **REFERENCE.md § Step 4**

### Step 5: Verify & Open

```bash
find .u-maker/out/browse -name "*.html" | wc -l
```

`--open`: `open .u-maker/out/browse/index.html`

---

## CRITICAL IMPLEMENTATION RULES

1. **반드시 모든 컨텍스트를 먼저 로드.** Step 0에서 scope의 모든 .md/.json을 읽은 후에야 HTML 생성 시작.
2. **교차 참조 필수.** 각 문서 HTML에는 다른 문서의 관련 정보가 반드시 포함.
3. **다이어그램 자동 생성.** JSON 분석 → Mermaid 코드 자동 생성. 원본 .md 다이어그램 복사 금지.
4. **와이어프레임은 리치 문서.** 어노테이션·액션·흐름·로직·팝업·엔티티 포함 종합 문서.
5. **Write 도구로 실제 파일 생성.** 분석/설명만으로 끝내지 않음.
6. **병렬 처리.** 독립적인 파일 변환은 여러 Write 호출 동시 수행.
7. **소스 문서 READ-ONLY.** 원본 .md/.json 절대 수정 금지.
8. **`out/browse/` 디렉토리만 쓰기.**

---

## --loop Quality Loop (Content + Style)

`/u-browse --loop` 실행 시, 생성된 HTML 산출물을 gatekeeper가 **Content+Style 10대 기준(QV-01~QV-10)**으로 평가.

### 평가 대상

| 산출물 | Content 검증 | Style 검증 |
|--------|-------------|-----------|
| index.html | sidebar 파일 트리 완전성, 검색 동작 | sidebar 레이아웃, 반응형, 테마 |
| srs.html~rtm.html | 원본 JSON↔HTML 데이터 일치, 교차 참조 링크, 다이어그램 정확성 | 시각적 계층, 테이블 스타일, 배지, 색상 |
| wireframes/SCR-NNN.html | 7개 탭 콘텐츠 충실도, 어노테이션 마커, Event Actions, Sequence Diagram | 3블록 레이아웃, No-Clipping, 마커 CSS, Dark/Light |
| 다이어그램 (Mermaid/SVG) | 노드·관계 정확, 레이블 일치 | 가독성, 레이아웃 밀도, 곡선 커넥터 |

### Loop 동작

```
/u-browse retail --loop
  → orchestrator가 u-browse 실행 (전체 HTML 생성)
  → gatekeeper: QV-01~QV-10 평가
  → 평균 ≤ 95? → Content/Style 분리 Enhancement Directive
    → orchestrator가 u-browse 재실행 (directive 기반 증분 수정)
  → 평균 > 95 또는 max 도달 → 종료
```

**재수행 시:** 전체 재생성이 아니라 **미달 항목만 증분 수정**. 예: QV-07 미달 → 해당 HTML의 CSS만 수정, QV-03 미달 → 누락된 교차 참조 링크만 추가.

---

## Safety Rules

1. **소스 문서 무수정:** `.md`/`.json`/`.html` 읽기만 수행
2. **`out/browse/` 디렉토리만 쓰기**
3. **인라인 리소스:** 외부 의존성 없는 단일 HTML (Mermaid.js CDN만 예외)
4. **민감 정보 제외:** `.env` 값, 시크릿 포함 금지
5. **기존 파일 덮어쓰기:** 스냅샷 개념
6. **독립 실행 가능:** 각 HTML은 index.html 없이도 단독 열람 가능
