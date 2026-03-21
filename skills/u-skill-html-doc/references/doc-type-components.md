# Doc-Type 컴포넌트 상세

## Sidebar 문서 유형별 추가 컴포넌트

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
| `glossary` | 용어 테이블, 약어 테이블, 카테고리 필터 |
| `workflow` | 워크플로우 다이어그램 (Flowchart SVG), 스텝 테이블, 예외 흐름 |

## Sidebar Icon 매핑

| doc-type | Icon |
|----------|------|
| `srs` | 📋 |
| `ia` | 🗺️ |
| `common` | 📚 |
| `roadmap` | 🗓️ |
| `glossary` | 📖 |
| `workflow` | 🔄 |
| `erd` | 🗃️ |
| `api` | 🔌 |
| `screen` | 🖥️ |
| `screenflow` | 🔀 |
| `uxguide` | 🎨 |
| `rtm` | 🔗 |
| `uicomponents` | 🧩 |
| `designtoken` | 🎨 |

## Report 문서 유형별 KPI Cards

| doc-type | KPI Cards |
|----------|----------|
| `code` | 구현된 FR 수, 구현된 FT 수, API 엔드포인트 수, 빌드 상태 |
| `testcase` | 전체 TC 수, Unit TC 수, E2E TC 수, 커버리지 FT 수 |
| `qareport` | Pass, Fail, Skip, 결함 Open 수 |
| `iteration` | 현재 Iteration, Open 백로그 수, 완료 항목 수, 부채 수 |
| `report` | FR 구현률, TC Pass율, 결함 수, Gate 판정 |

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
| `glossary` | 도메인 용어 수, 약어 수, 기술 용어 수 |
| `workflow` | 워크플로우 수, Core 수, Support 수, 예외 흐름 수 |
| `iteration` | Open 수, Closed 수, 부채 수 |
