---
name: u-skill-wireframe
description: |
  화면 와이어프레임을 HTML로 생성하거나 갱신한다. u-agent-ux 에이전트가 담당한다.
  IA, Screen 문서를 참고하여 **HTML/CSS div 기반 app-frame 레이아웃**으로 시각화한다.
  우측 Annotation Panel에 번호 어노테이션 + 비즈니스 룰을, 하단에 컴포넌트 명세와
  **Condition Flow Chart, Sequential Diagram, UML Diagram** 등 다이어그램을 SVG/HTML로 포함한다.
  전체 화면 Navigation Page(index.html)를 Grid/List 뷰로 함께 생성한다.
  Args: `[app] <all|screen-id>` — 앱 이름 + 대상 화면 (all=전체)
  Triggers: /u-skill-wireframe, HTML 와이어프레임, wireframe generate, 와이어프레임, wireframe, 화면 와이어프레임, 목업, mockup, 와이어프레임 생성, create wireframe, 화면 프로토타입, screen prototype
model: sonnet
user-invocable: true
argument-hint: "[app] <all|screen-id>"
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
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/_refer/html-wireframe-template.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  u-agent-ux: u-maker:u-agent-ux
---

# u-skill-wireframe

`u-agent-ux` 에이전트를 호출하여 HTML 와이어프레임을 생성/갱신한다.

## Output

`.u-maker/docs/{app}/02-design/2_Screen_Wireframes/`

| 파일 | 설명 |
|------|------|
| `S-NNNN.html` + `.json` | 개별 화면 와이어프레임 (app-frame UI + Annotation Panel + 컴포넌트 명세 + 다이어그램) |
| `S-NNNN-T*.html` + `.json` | Tab별 와이어프레임 (Tab UI가 있는 화면) |
| **`index.html`** + `.json` | **Navigation Page** — 전체 화면 썸네일 Grid/List 뷰 + 검색 + 도메인별 그룹핑 |

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Wireframe Layout

HTML/CSS div 기반 **app-frame 레이아웃**을 사용한다 (SVG 기반 아님).

```
┌─ doc-header (sticky dark bar: Screen ID, 화면명, Path, FT, 날짜) ──┐
├─ stage (grid: 1fr 280px) ──────────────────────────────────────────┤
│  ┌─ app-frame ───────────────┐  ┌─ anno-panel ──────────────────┐ │
│  │ sidebar │ main content    │  │ 1 번호 어노테이션             │ │
│  │ (nav)   │ (pg-hdr+pg-body)│  │ 2 ...                        │ │
│  │         │                 │  │ Business Rules                │ │
│  └─────────┴─────────────────┘  └───────────────────────────────┘ │
├─ spec-wrap (컴포넌트 명세 테이블) ──────────────────────────────────┤
├─ diagrams-section ─────────────────────────────────────────────────┤
│  ├─ Condition Flow Chart (SVG/HTML)                                │
│  ├─ Sequential Diagram (SVG/HTML)                                  │
│  └─ UML Diagram (SVG/HTML)                                        │
└────────────────────────────────────────────────────────────────────┘
```

- **doc-header**: Screen ID 배지, 화면명, URL Path, FT ID, 날짜 등 메타 정보
- **app-frame**: 좌측 sidebar 네비게이션 + 우측 main 영역(pg-hdr + pg-body)으로 실제 앱 화면을 HTML로 재현
- **anno-panel**: 원안에 번호 마커(1,2,3) + 설명 + 비즈니스 룰 섹션
- **spec-wrap**: 컴포넌트별 타입, 기본값, 비고를 테이블로 정리
- **diagrams-section**: 화면의 조건 분기, 시퀀스 흐름, 상태/클래스 관계를 시각화

## Diagrams Section

와이어프레임 하단에 해당 화면의 **다이어그램을 SVG 또는 HTML**로 포함한다.

| 다이어그램 | 설명 | 포함 조건 |
|-----------|------|----------|
| **Condition Flow Chart** | 조건 분기 로직 (권한별, 상태별, 데이터 유무별 UI 분기) | 조건 분기가 있는 화면 (필수) |
| **Sequential Diagram** | 사용자↔시스템 인터랙션 시퀀스 (이벤트→API→응답→UI 갱신) | 인터랙션이 있는 화면 (필수) |
| **UML Diagram** | 상태 다이어그램, 클래스 관계도, 데이터 흐름도 등 | 해당 시 (선택) |

- SVG `<svg>` 태그로 직접 렌더링하거나 HTML div 기반으로 구현
- 각 다이어그램에 제목(`diagram-title`) + 범례(`diagram-legend`) 포함
- Condition Flow: 노드(조건/액션) + 분기 화살표(Yes/No) 구조
- Sequential Diagram: Actor 컬럼 + 시간축(위→아래) + 메시지 화살표 구조
- 다이어그램 내 색상은 CSS 변수 사용 (dark/light 테마 대응)

## Navigation Page (index.html)

와이어프레임 생성/갱신 시 **항상** `index.html` + `index.json`을 함께 생성/갱신한다.
전체 화면을 한눈에 탐색하고 원하는 화면으로 빠르게 이동할 수 있는 네비게이션 허브.

- **Grid View (기본)**: 각 화면의 축소 썸네일 프리뷰(iframe scale 0.25) + Screen ID + 화면명을 카드 그리드로 표시
- **List View**: Screen ID, 화면명, Goal, Access Role을 리스트로 표시
- **Grid/List 토글 버튼**: localStorage에 선호 뷰 저장
- **도메인별 그룹핑**: IA 도메인별 섹션 분리
- **검색**: 화면 ID, 이름, 키워드로 실시간 필터링
- **통계**: 전체 화면 수, 도메인별 화면 수
- **Light/Dark 테마 토글**
- 생성된 **모든** 와이어프레임 HTML(`S-NNNN.html`, `S-NNNN-T*.html`)로의 링크 포함
- Tab 화면은 부모 화면 하위에 sub-card로 들여쓰기 표시

## Rules

- **`html-wireframe-template.md` 표준을 엄격히 준수** — UI 레이아웃은 HTML/CSS div 기반 app-frame으로 렌더링
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- **Tab 화면 분리 필수**: 화면 내에 Tab UI가 있는 경우, **각 탭을 별도 와이어프레임 HTML로 생성**해야 한다
  - 부모 화면(`S-NNNN.html`): 전체 레이아웃 + Tab 네비게이션 포함, 기본 탭 활성 상태
  - 탭별 화면(`S-NNNN-T1.html`, `S-NNNN-T2.html`, ...): 각 탭의 고유 콘텐츠를 별도 HTML로 생성
  - 부모 화면의 Tab 요소에서 각 탭 HTML로 링크, 각 탭 HTML에서 부모 화면으로 돌아가기 링크 포함
  - 각 탭 화면에도 **탭별 고유 UI 요소 전체에 어노테이션 마커 + Sidebar 카드** 작성
  - index.html에 탭별 화면도 포함 (부모 화면 하위에 들여쓰기로 표시)
- **조건별 화면 상태 어노테이션 필수**: 권한, 데이터 유무, 상태값 등 **조건에 따라 화면이 달라지는 모든 케이스**를 어노테이션으로 명확히 기술 (Empty State, Loading, Error, 권한별 분기, 데이터 조건별 분기 등)
- **어노테이션 마커 필수**: **거의 모든 UI 요소**에 숫자 마커(1, 2, 3...) 를 부착한다. 단순 레이아웃 컨테이너(빈 div, spacer)를 제외한 **모든 인터랙티브 요소, 표시 요소, 정책/비즈니스 룰 관련 영역**에 마커를 생성하고 Description을 작성해야 한다
- **우측 Sidebar**: 전체 어노테이션을 아코디언 카드로 나열, **토글 버튼**으로 열기/닫기, Expand All/Collapse All 지원
- **마커 클릭**: Sidebar 열림 + 해당 카드 확장 + 스크롤 + 하이라이트
- **Design 탭**: `[컴포넌트타입] 이름` 형식 Description 블록 + 요구사항(FR/US/FT), 연결 화면, 권한
- **Dev 탭**: 요소 유형별 필수 섹션 매트릭스에 따라 아래 포함:
  - **동작방식**: HTML type, 컴포넌트명, debounce, auto-focus, disabled 조건 등
  - **이벤트**: 이벤트명 + 핸들러명 + 동작 설명
  - **Validation**: Rule type + 조건 + **에러 메시지 원문** (입력 요소 필수)
  - **흐름도**: 사용자 동작 → 검증 → API → 성공/에러 분기 (인터랙션 요소 필수)
  - **옵션값**: value + label + 조건 + data source (Select/Radio/Checkbox 필수)
  - **컬럼 정의**: field + label + type + sortable + width (테이블 요소 필수)
  - **API**: HTTP method + endpoint + request params
  - **데이터 바인딩**: state/error 경로
- **외부 링크**: 내부 링크(`S-NNNN.html`, `index.html`) 외 모든 외부 URL은 `target="_blank" rel="noopener noreferrer"` 적용
- **Description 포맷**: `[정책]`, `[Button]`, `[Card]`, `[Badge]`, `[Confirm]` 등 컴포넌트타입 헤더 + bullet/sub 목록, 정책 빨간 강조, 노출 문구 따옴표
- **Annotation Legend**: 각 와이어프레임 하단에 마커 범례 섹션 포함 (클릭 시 Sidebar 해당 카드로 스크롤)
- **Diagrams 필수**: 와이어프레임 하단에 Condition Flow Chart(필수), Sequential Diagram(필수), UML(해당 시) 포함
- **화면 → index.html 버튼**: 모든 와이어프레임 화면 HTML doc-header에 `index.html`로 돌아가는 버튼 포함
- Post-Execution Summary Box 출력 필수
