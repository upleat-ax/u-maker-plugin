---
name: u-report
description: "SSoT 문서를 HTML 리포트로 변환. sidebar navigation + UML 다이어그램 SVG + 통계 차트를 포함한 브라우저 열람용 리포트를 생성한다. /u-loop 완료 시 자동 호출된다."
triggers:
  - "/u-report"
  - "report"
  - "리포트"
  - "HTML 생성"
  - "리포트 생성"
  - "html report"
  - "daily report"
  - "일일 리포트"
  - "데일리 리포트"
  - "IA 일정"
---

# u-report -- SSoT to HTML Report Generator

`/u-report [scope] [--only X]` 명령으로 SSoT 문서(.md + .json)를 브라우저에서 열람할 수 있는 HTML 리포트로 변환한다.

**Primary Agent:** u-agent-orchestrator (engine-doc 사용)

> **역할 분담:** `.md` + `.json`은 작업 중 항상 생성되는 SSoT 원본이고, `.html`은 리뷰/공유용 시각화 산출물이다. `/u-report`는 후자만 담당한다.

> **테마 규칙:** 모든 HTML은 `Light | Dark` toggle, `localStorage['u-maker-theme']`, `u-maker.config.json.theme` 기본값(`default: light`)을 지원한다.

---

## Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--only X` | - | 특정 리포트만 생성 (ingest, plan, design, dev, qa, daily, dashboard) |
| `--open` | - | 생성 후 브라우저 자동 열기 |
| `--clean` | - | 오늘 `out/reports/{scope}/{date}/` 삭제 후 재생성. `--clean all` 전체 이력 삭제 |
| `--milestone` | - | Daily Report 마일스톤 기간 직접 지정 (예: `--milestone "03.01~03.31"`) |
| `--loop` | - | Content+Style Quality Loop (QV-01~QV-10 평가, 평균 95점 초과까지 반복) |

---

## Output Structure

```
.u-maker/out/reports/{scope}/
├── latest -> 2026-03-29         # 최신 심볼릭 링크
├── 2026-03-29/
│   ├── index.html               # 대시보드 (전체 인덱스 + 통계)
│   ├── ingest-report.html       # classified 항목 요약
│   ├── plan-report.html         # SRS + IA + Roadmap
│   ├── design-report.html       # ERD + API + Screen + ScreenFlow + RTM
│   ├── dev-report.html          # Code + Spec-Sync + Build 결과
│   ├── qa-report.html           # TestCase + TestReport + 커버리지
│   ├── daily-report-YYYY-MM-DD.html  # IA 일정 조율 Daily Report
│   └── wireframes/              # 와이어프레임 뷰어
└── ...
```

날짜별 스냅샷. 같은 날짜 재생성 시 덮어쓰기. `latest` 심볼릭 링크는 항상 최신을 가리킨다.

---

## Execution Flow

### Step 1: Resolve Scope & Scan Documents

1. `u-maker.config.json` → scope 해석
2. `_index.json` → 문서 목록 + 상태 로드
3. `data/classified/_summary.json` → 분류 통계 로드
4. `--only` 플래그 → 대상 리포트 결정 (생략 시 전체)
5. `out/reports/{scope}/{YYYY-MM-DD}/` 디렉토리 생성 + `latest` 심볼릭 링크 갱신

### Step 2: Generate Per-Phase Reports

각 Phase별 `.md` + `.json`을 읽어 HTML로 변환한다. 모든 리포트 상단에 **Progress Summary** 블록(Done / Remaining / Improve 3열)을 포함한다.

> 상세 → **REFERENCE.md § Progress Summary 공통 블록**

#### 2-1. ingest-report.html

`data/classified/_summary.json` + `data/classified/*/_index.json` 기반. 처리 파일 수, 항목 수, Status 분포, 카테고리별 테이블(Screens, Requirements, Pain Points, Workflows, Domain Terms, Stakeholders, Constraints, Decisions, Questions) 생성.

> 상세 → **REFERENCE.md § ingest-report 섹션 명세**

#### 2-2. plan-report.html

`01-plan/srs.md`, `ia.md`, `roadmap.md` + `.json` 기반. SRS 계층 통계, FR/US/FT 테이블, IA Sitemap SVG, Gantt chart, classified→SRS 매핑률 heatmap 생성.

> 상세 → **REFERENCE.md § plan-report 섹션 명세**

#### 2-3. design-report.html

`02-design/*.md` + `.json` 기반. ERD 다이어그램, API 엔드포인트, Screen 구성, Screen Flow, RTM 매트릭스, UX/Token, ERD↔API↔Screen 교차 검증 결과 생성.

> 상세 → **REFERENCE.md § design-report 섹션 명세**

#### 2-4. dev-report.html

`03-dev/code.md`, `spec-sync-report.md` + `.json` 기반. FE/BE/DB 파일 목록, Spec-Sync 검증 테이블, Build pass/fail, Tech Debt, FT→File 매핑 생성.

> 상세 → **REFERENCE.md § dev-report 섹션 명세**

#### 2-5. qa-report.html

`04-check/test-cases.md`, `test-report.md` + `.json` 기반. TC 커버리지, pass/fail/skip 분포, 결함 목록, FT→TC 매핑률 heatmap 생성.

> 상세 → **REFERENCE.md § qa-report 섹션 명세**

#### 2-6. daily-report-{YYYY-MM-DD}.html

IA 화면 계층 기반 프로젝트 관리 뷰. PDCA 5단계(분류→기획→설계→개발→검증) 진행 추적. Header KPI 배지, Main Table(도메인별 메뉴 × 5단계 매트릭스), Bottom 기술 혁신 로드맵으로 구성.

> 상세 → **REFERENCE.md § daily-report 상세 구현**

### Step 3: Generate Dashboard (index.html)

전체 리포트를 묶는 대시보드. Sidebar(Phase별 문서 + Wireframes + 검색) + Main Content(전체 Progress, Phase별 카드, Remaining/Improve 테이블, Assumptions, Backlog, Next Steps).

> 상세 → **REFERENCE.md § Dashboard 구현 가이드**

### Step 4: Render Diagrams to SVG

Mermaid 코드 블록을 인라인 SVG로 변환. `erDiagram`, `sequenceDiagram`, `flowchart`, `classDiagram`, `stateDiagram`, `pie`, `gantt` 지원. 클릭 시 확대 모달. IA는 inline SVG sitemap (Mermaid mindmap 사용 금지).

### Step 5: Apply Common Style

> 상세 → **REFERENCE.md § Common Style 명세**

핵심: Sidebar `#1e293b`/`280px`, zebra striping 테이블, SVG 인라인 다이어그램, 768px 미만 sidebar 접기, `@media print` 지원, Footer `{license.type} · (C) {license.owner}`.

### Step 6: Notify Completion

생성 결과 요약 출력: scope, 날짜, 파일 수, 위치, 파일별 크기/섹션 수. `open .u-maker/out/reports/{scope}/latest/index.html` 안내.

---

## --only Flag & /u-loop 연동

| Value | 생성 파일 |
|-------|----------|
| `--only ingest` | `ingest-report.html` |
| `--only plan` | `plan-report.html` |
| `--only design` | `design-report.html` |
| `--only dev` | `dev-report.html` |
| `--only qa` | `qa-report.html` |
| `--only daily` | `daily-report-{YYYY-MM-DD}.html` |
| `--only dashboard` | `index.html` |
| (생략) | 전체 생성 |

`/u-loop` 각 단계 완료 후 해당 `--only` 리포트 자동 생성. 루프 종료 시 daily + dashboard. 루프 리포트는 `out/reports/loop-{loopId}/{date}/`에 저장.

> 상세 → **REFERENCE.md § /u-loop 연동 상세**

---

## --loop Quality Loop (Content + Style)

`/u-report --loop` 실행 시, 생성된 HTML 리포트를 gatekeeper가 **Content+Style 10대 기준(QV-01~QV-10)**으로 평가.

### 평가 대상

| 산출물 | Content 검증 | Style 검증 |
|--------|-------------|-----------|
| index.html (Dashboard) | KPI 수치 정확, Phase별 카드 데이터 일치, Remaining/Improve 완전 | Sidebar 레이아웃, 카드 grid, 반응형, 테마 |
| ingest-report.html | _summary.json 수치 일치, 카테고리별 테이블 완전 | zebra striping, 통계 카드, Status 배지 |
| plan-report.html | SRS 계층 통계 정확, IA SVG Sitemap, Gantt 일정 | SVG 인라인, 히트맵 색상, 차트 가독성 |
| design-report.html | ERD/API/Screen 교차 검증 결과, RTM 매트릭스 | 다이어그램 렌더링, 테이블 포맷, 링크 작동 |
| dev-report.html | FT→File 매핑 정확, Build pass/fail, Tech Debt | 코드 블록 스타일, Spec-Sync 검증 테이블 |
| qa-report.html | TC 커버리지 수치, pass/fail/skip 분포, 결함 목록 | 히트맵, 배지, 결함 severity 색상 코딩 |
| daily-report.html | Header KPI 배지, 도메인×5단계 매트릭스, 기술 로드맵 | 테이블 정렬, 마일스톤 구간 표시, 인쇄 대응 |

### Loop 동작

```
/u-report retail --loop
  → orchestrator가 전체 리포트 생성
  → gatekeeper: QV-01~QV-10 평가
  → 평균 ≤ 95? → Content/Style 분리 Enhancement Directive
    → orchestrator가 미달 리포트만 증분 수정
  → 평균 > 95 또는 max 도달 → 종료
```

**재수행 시:** 전체 재생성이 아니라 **미달 리포트만 증분 수정**. 예: QV-02 미달(qa-report 수치 오류) → qa-report.html만 재생성. QV-08 미달(Dark 모드 색상 불일치) → 해당 HTML의 CSS 테마 섹션만 수정.

---

## Safety Rules

1. **소스 문서 무수정:** `.md` / `.json` 읽기만 수행 (READ-ONLY)
2. **`out/reports/` 디렉토리만 쓰기:** HTML은 `out/reports/` 하위에만 생성
3. **인라인 리소스:** 외부 의존성 없는 단일 HTML (Mermaid.js CDN만 예외)
4. **민감 정보 제외:** `.env`, 하드코딩 시크릿 포함 금지
5. **같은 날짜 덮어쓰기:** 같은 날짜 리포트는 경고 없이 덮어쓴다. 다른 날짜는 보존
6. **SVG 인라인 필수:** 다이어그램은 인라인 SVG로 렌더링
7. **`language.documents` 반영:** 리포트 본문 언어는 config 설정을 따름
