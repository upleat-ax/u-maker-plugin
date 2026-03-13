---
name: u-skill-wireframe
description: |
  화면 와이어프레임을 HTML로 생성하거나 갱신한다. u-agent-ux 에이전트가 담당한다.
  IA, Screen 문서를 참고하여 HTML/CSS로 레이아웃을 시각화한다.
  우측 Sidebar에 전체 어노테이션을 아코디언 카드로 표시하며,
  각 카드에는 관련 요구사항(FR), 플로우(SC/User Flow), 조건(Business Rule), 요소 설명이 포함된다.
  Args: `[app] <all|screen-id>` — 앱 이름 + 대상 화면 (all=전체)
  Triggers: /u-skill-wireframe, HTML 와이어프레임, wireframe generate
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
  - u-maker:u-agent-ux
---

# u-agent-wireframe

`u-agent-ux` 에이전트를 호출하여 HTML 와이어프레임을 생성/갱신한다.

## Output

`.u-maker/docs/{app}/02-design/2_Screen_Wireframes/`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- **`html-wireframe-template.md` 표준을 엄격히 준수**
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
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
- **index.html 필수**: 와이어프레임 생성/갱신 시 `index.html` + `index.json`도 항상 함께 생성/갱신
- index.html은 전체 화면 목록을 도메인별 그룹핑으로 표시하고 검색 기능 제공
- Post-Execution Summary Box 출력 필수
