# erd-rendering — ERD Domain Page Full Rendering Spec

> **CRITICAL:** Each ERD domain page MUST include ALL four sections below. DO NOT generate pages with only text or entity lists. ERD pages without inline SVG diagrams and relationship cards are **incomplete output**.

## ERD Domain Page Content (per entity group, in order)

### 1. Inline SVG ERD (필수) (`erd.json` → `entities` + `relationships`)

- **Entity boxes:** rounded rectangle per entity
  - Header row: colored (`#2563eb` blue-600), entity name bold
  - Column rows: column name + type + 배지 (PK: `#7c3aed` violet / FK: `#0d9488` teal / UK: `#0ea5e9` sky) — amber/green 금지
  - PK/FK/UK 배지는 절대 동일 컬럼에 중복 표시 금지 (각 제약조건은 독립 행)
- **Relationship connectors:** 엔티티 간 **curved `<path>` (C Bezier)** 로 연결. `<line>` / `<polyline>` 사용 금지
  - 커넥터 양 끝: 카디널리티 텍스트 (`1`, `N`, `0..1`, `0..N`)
  - 커넥터 중앙: 관계 설명 라벨 (예: "has many", "belongs to")
- **Domain grouping:** 같은 도메인 엔티티를 배경 `<rect>` (light fill)으로 그룹핑
- **Layout:** 엔티티 간 겹침 없도록 배치. 엔티티 30개 초과 시 도메인별 분할
- `viewBox` 기반 반응형 (`width="100%"`)

### 2. Relationship Description Cards (필수)

SVG 다이어그램 바로 아래 HTML 카드. 각 relationship마다 카드 1개:

| 필드 | 내용 |
|------|------|
| From → To | `EntityA` → `EntityB` |
| Type | `1:1` / `1:N` / `N:M` |
| FK Column | `entityB.entityAId` |
| 비즈니스 의미 | 자연어 prose (예: "하나의 주문은 여러 주문항목을 가진다") |
| 참조 무결성 | `CASCADE` / `SET NULL` / `RESTRICT` 등 |

### 3. Entity Detail Tables

각 엔티티의 컬럼 상세:

| Column | Type | PK | FK | Nullable | Default | Description |
|--------|------|----|----|----------|---------|-------------|

### 4. Common Table References

이 도메인 엔티티를 참조하는 다른 도메인 목록 (있는 경우).

## ERD Index Page

`output/{app}/design/erd/index.html` includes:
- Full ER overview SVG (모든 도메인 entity boxes + curved connectors + cardinality labels)
- Entity count / relationship count 요약 메트릭
- Relationship summary table (From, To, Type, FK)
- Domain cards grid (link to each domain page)
