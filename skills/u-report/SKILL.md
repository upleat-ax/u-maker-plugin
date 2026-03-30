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

> **테마 규칙:** `/u-report`가 생성하는 모든 HTML(`index.html`, `*-report.html`, `daily-report-*.html`)은 공통 `Light | Dark` toggle, `localStorage['u-maker-theme']`, `u-maker.config.json.theme` 기본값(`default: light`)을 지원해야 한다.

---

## Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--only X` | - | 특정 리포트만 생성 (ingest, plan, design, dev, qa, daily, dashboard) |
| `--open` | - | 생성 후 브라우저에서 자동 열기 |
| `--clean` | - | 오늘 날짜의 `_reports/{scope}/{date}/` 삭제 후 재생성. `--clean all` 시 전체 이력 삭제 |
| `--milestone` | - | Daily Report에서 마일스톤 기간 직접 지정 (예: `--milestone "03.01~03.31"`) |

---

## Output Structure

```
.u-maker/_reports/{scope}/
├── latest -> 2026-03-29         # 최신 리포트 심볼릭 링크
├── 2026-03-29/
│   ├── index.html               # 대시보드 (전체 문서 인덱스 + 통계)
│   ├── ingest-report.html       # classified 항목 요약
│   ├── plan-report.html         # SRS + IA + Roadmap
│   ├── design-report.html       # ERD + API + Screen + ScreenFlow + RTM
│   ├── dev-report.html          # Code + Spec-Sync + Build 결과
│   ├── qa-report.html           # TestCase + TestReport + 커버리지
│   ├── daily-report-2026-03-29.html  # IA 일정 조율 (날짜별 Daily Report)
│   └── wireframes/              # 와이어프레임 뷰어
├── 2026-03-28/
│   └── ...                      # 이전 날짜 리포트 (이력 보존)
└── ...
```

> **날짜 기반 스냅샷:** 리포트는 `YYYY-MM-DD` 날짜 디렉토리에 생성된다. 같은 날짜에 재생성 시 해당 날짜 디렉토리를 덮어쓴다. `latest` 심볼릭 링크는 항상 최신 날짜를 가리킨다.

---

## Execution Flow

### Step 1: Resolve Scope & Scan Documents

1. `u-maker.config.json` → scope 해석
2. `_index.json` → 문서 목록 + 상태 로드
3. `_classified/_summary.json` → 분류 통계 로드
4. `--only` 플래그 → 대상 리포트 결정. 생략 시 전체 생성
5. 오늘 날짜(`YYYY-MM-DD`)를 구하고 `_reports/{scope}/{date}/` 디렉토리 생성
6. `_reports/{scope}/latest` 심볼릭 링크를 오늘 날짜 디렉토리로 갱신:
   ```bash
   DATE=$(date +%Y-%m-%d)
   mkdir -p .u-maker/_reports/{scope}/${DATE}
   ln -sfn ${DATE} .u-maker/_reports/{scope}/latest
   ```

### Step 2: Generate Per-Phase Reports

각 Phase별 `.md` + `.json`을 읽어 HTML로 변환한다.

#### 공통: 각 리포트의 Progress Summary 섹션

모든 phase별 리포트에는 상단에 **Progress Summary** 블록을 포함한다:

```
┌─────────────────────────────────────────────────────┐
│  ✅ Done (12)    │  ⏳ Remaining (5)   │  💡 Improve (3)  │
├─────────────────┼────────────────────┼─────────────────┤
│ FR-0001 Login   │ FR-0015 알림       │ FR-0003 결제     │
│ FR-0002 회원가입 │ FR-0016 통계       │   → API 응답 최적화│
│ ...              │ ...                │ ...              │
└─────────────────┴────────────────────┴─────────────────┘
```

| 섹션 | 아이콘 | 내용 | 소스 |
|------|--------|------|------|
| **Done** | ✅ | 완료된 항목 (status: Final, validated, passed) | `_index.json` status, test results |
| **Remaining** | ⏳ | 미완료 항목 (status: Draft, extracted, todo) | `_index.json`, `_backlog/` |
| **Improve** | 💡 | 개선 필요 항목 (리뷰 코멘트, 실패 테스트, tech debt, assumptions) | test-report, spec-sync, `_assumptions/`, `_backlog/` |

각 항목에는:
- ID + Title
- 현재 Status 배지
- Improve인 경우: 개선 사유 1줄 설명 (예: "→ API 응답 시간 2초 초과", "→ ERD와 API 타입 불일치")

---

#### 2-1. ingest-report.html

**입력:** `_classified/_summary.json`, `_classified/*/​_index.json`

| 섹션 | 내용 |
|------|------|
| **Progress** | Done: validated 항목 / Remaining: extracted 항목 / Improve: rejected 사유 + 미분류(raw/) 파일 |
| Summary | 처리 파일 수, 총 항목 수, Status 분포 pie chart (SVG) |
| Screens | Design System 컴포넌트 테이블 + 화면 그룹별 목록 (소계) |
| Requirements | FR 테이블 (ID, Title, Priority, Status) + NR 테이블. Priority 분포 bar chart |
| Pain Points | severity별 분류 테이블 |
| Workflows | 워크플로우 목록 + 단계 수 |
| Domain Terms | 용어 사전 테이블 (term, definition, synonyms) |
| Stakeholders | 이해관계자 역할 매트릭스 |
| Constraints | 제약사항 목록 (type: tech/policy/legal) |
| Decisions | 결정사항 타임라인 |
| Questions | 미해결 질문 목록 (open/resolved) |

#### 2-2. plan-report.html

**입력:** `01-plan/srs.md`, `01-plan/ia.md`, `01-plan/roadmap.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Progress** | Done: Final 문서 / Remaining: Draft 문서, 미작성 문서 / Improve: 누락 FR↔classified 매핑, 미해결 questions | - |
| SRS Overview | USR → FR → US → FT 계층 통계 | Use Case Diagram (SVG) |
| FR 목록 | 전체 FR 테이블 (ID, Title, Priority, US 수, FT 수) | Priority 분포 pie chart |
| US 목록 | 전체 US 테이블 (관련 FR, FT 수) | - |
| FT 목록 | 전체 FT 테이블 (관련 US, Screen, API) | - |
| IA | 화면 계층 구조 | 인라인 SVG Sitemap (페이지 카드 + 와이어프레임 썸네일) |
| Roadmap | 마일스톤 타임라인 | Gantt chart (SVG) |
| Coverage | classified → SRS 매핑률 | 매핑 매트릭스 heatmap |

#### 2-3. design-report.html

**입력:** `02-design/*.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Progress** | Done: Final 설계 문서 / Remaining: Draft 문서, 미생성 RTM / Improve: ERD↔API 타입 불일치, Screen↔FT 미매핑, 고아 엔드포인트 | - |
| ERD | 엔티티 목록 + 컬럼 상세 | ER Diagram (SVG) |
| API | 엔드포인트 목록 (method, path, auth, related FT) | Sequence Diagram (주요 흐름, SVG) |
| Screens | 화면별 컴포넌트 구성, API 연결, 상태 | Component Diagram (SVG) |
| Screen Flow | 화면 간 내비게이션 경로 | Flowchart (SVG) |
| RTM | FR → US → FT → Screen → API → ERD 매핑 매트릭스 | Traceability heatmap |
| UX/Token | Design Token 목록 (있으면) | - |
| 정합성 | ERD↔API↔Screen 교차 검증 결과 | 누락 항목 경고 표시 |

#### 2-4. dev-report.html

**입력:** `03-dev/code.md`, `03-dev/spec-sync-report.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Progress** | Done: 생성 완료 + build pass 파일 / Remaining: 미생성 Screen/API 코드 / Improve: spec-sync 위반, build 에러, tech debt 목록 | - |
| Generated Files | FE/BE/DB 분류별 파일 목록 | Package Diagram (SVG) |
| Spec-Sync | 검증 결과 테이블 (Rule, Check, Severity, Status) | 커버리지 bar chart |
| Build Result | TypeScript/Lint/Build 통과 여부 | pass/fail 배지 |
| Tech Debt | 자동 등록된 기술 부채 목록 | - |
| FT → File | FT별 생성 파일 매핑 | - |

#### 2-5. qa-report.html

**입력:** `04-check/test-cases.md`, `04-check/test-report.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Progress** | Done: passed TC / Remaining: 미작성 TC (FT 대비), skip된 TC / Improve: failed TC + 결함 목록 + 커버리지 미달 FT | - |
| TC Overview | 총 TC 수, FT별 TC 수, 커버리지 | 커버리지 pie chart (SVG) |
| TC 목록 | 전체 TC 테이블 (ID, FT, Description, Type, Status) | - |
| Test Results | pass/fail/skip 분포 | bar chart (SVG) |
| Defects | 결함 목록 (severity: Critical/Major/Minor) | severity 분포 pie chart |
| FT Coverage | FT → TC 매핑률 (100% = 완전 커버) | heatmap |

#### 2-6. daily-report-{YYYY-MM-DD}.html (IA 일정 조율 — Daily Progress Report)

**파일명 규칙:** `daily-report-{YYYY-MM-DD}.html` (예: `daily-report-2026-03-29.html`). 생성 시점의 날짜가 자동 포함되며, 같은 날짜에 재생성 시 덮어쓴다.

**입력:** `01-plan/ia.md` + `.json`, `01-plan/srs.md` + `.json`, `01-plan/roadmap.md` + `.json`, `_index.json`, `_classified/_summary.json`, `_backlog/`, `02-design/screens.md` + `.json`, `03-dev/code.md` + `.json`, `04-check/test-cases.md` + `.json`

IA 화면 계층 기반으로 전체 개발 진행 상황을 추적하는 **프로젝트 관리 뷰**. 각 메뉴/화면이 u-maker PDCA 5단계(Ingest→Plan→Design→Dev→QA)를 거치는 과정을 한 눈에 보여준다.

> **참고:** 상세 HTML 구조와 스타일링은 `skills/u-report/references/daily-report-template.md`를 참조한다.

---

##### u-maker PDCA 5단계

| 단계 | 표시명 | Phase | 설명 | 대응 커맨드 |
|------|--------|-------|------|------------|
| ① | 분류 | Ingest | 원시 자료 분석 → 화면 분류 완료 | `/u-ingest` |
| ② | 기획 | Plan | SRS FR→US→FT 매핑 + IA 정의 완료 | `/u-plan` |
| ③ | 설계 | Design | Screen 설계 + ERD/API 연결 완료 | `/u-design` |
| ④ | 개발 | Dev | FE 컴포넌트 + BE API 코드 생성 완료 | `/u-dev` |
| ⑤ | 검증 | QA | TC 생성 + 테스트 실행 통과 | `/u-qa` |

---

##### ① Header 영역

```
┌──────────────────────────────────────────────────────────────────────┐
│  {ProjectName} IA 일정 조율                                          │
│  {year}년 {month}월 개발 마일스톤 - {start} ~ {end}                    │
│                                                                      │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                                │
│  │  46  │ │  37  │ │  4   │ │  2   │                                │
│  │ 전체 │ │ 완료 │ │진행중│ │ D-day│                                │
│  └──────┘ └──────┘ └──────┘ └──────┘                                │
│                                                                      │
│  완료 37 ─ QA진행 2 ─ 개발중 4 ─ 설계중 1 ─ 기획중 1 ─ 대기 1        │
│  전체 진행률 ████████████████████░░░░ 85%                             │
└──────────────────────────────────────────────────────────────────────┘
```

| 요소 | 내용 | 소스 |
|------|------|------|
| 타이틀 | `{ProjectName} IA 일정 조율` | `u-maker.config.json` → `name` |
| 기간 | `{year}년 {month}월 개발 마일스톤 - {start} ~ {end}` | `roadmap.json` 현재 Iteration 또는 `--milestone` 플래그 |
| KPI 뱃지 4개 | **전체** (IA 화면 수) / **완료** (5단계 모두 완료) / **진행중** (1~4단계 진행) / **D-day** (마감 임박 항목) | IA 화면 수 + 각 상태 집계 |
| 파이프라인 바 | `완료 {n}` → `QA진행 {n}` → `개발중 {n}` → `설계중 {n}` → `기획중 {n}` → `대기 {n}` | PDCA 5단계 기준 상태 분류 |
| 전체 진행률 | 프로그레스 바 + 퍼센트 | (완료 화면 수 / 전체 화면 수) × 100 |

**파이프라인 상태 정의:**

| 상태 | 조건 | 뱃지 색상 |
|------|------|----------|
| 완료 | 5단계(분류~검증) 모두 ✓ | `#22c55e` (green) |
| QA진행 | ④개발 완료, ⑤검증 진행중 | `#8b5cf6` (violet) |
| 개발중 | ③설계 완료, ④개발 진행중 | `#3b82f6` (blue) |
| 설계중 | ②기획 완료, ③설계 진행중 | `#f59e0b` (amber) |
| 기획중 | ①분류 완료, ②기획 진행중 | `#f97316` (orange) |
| 대기 | 아직 시작하지 않은 항목 | `#64748b` (slate) |

---

##### ② Main Table — IA 진행 현황

IA L1(도메인) 그룹별로 L2/L3(메뉴) 항목을 나열하고, 각 항목의 PDCA 5단계 진행 상태를 추적한다.

```
┌────┬──────────────────┬────────────┬────┬────┬────┬────┬────┬──────┬──────┬────┬──────────┬────────────────┐
│ #  │ 도메인           │ 메뉴       │ ①  │ ②  │ ③  │ ④  │ ⑤  │진행률│ 상태 │담당│완료(예정)│ 비고           │
│    │                  │            │분류│기획│설계│개발│검증│      │      │    │일        │                │
├────┼──────────────────┼────────────┼────┼────┼────┼────┼────┼──────┼──────┼────┼──────────┼────────────────┤
│    │ 현장별 메인 1/1  │            │    │    │    │    │    │ 100% │      │    │          │                │
│ 1  │                  │ 대시보드   │ ✓  │ ✓  │ ✓  │ ✓  │ ✓  │ 100% │ 완료 │ —  │ 완료     │ —              │
├────┼──────────────────┼────────────┼────┼────┼────┼────┼────┼──────┼──────┼────┼──────────┼────────────────┤
│    │ 안전보건경영 2/6 │            │    │    │    │    │    │  60% │      │    │          │                │
│ 2  │                  │ 안전보건 …│ ✓  │ ✓  │ ✓  │ ✓  │ ✓  │ 100% │ 완료 │조호순│ 완료   │                │
│ 3  │                  │ 안전보건조…│ ✓  │ ✓  │ ✓  │ ✓  │ ✓  │ 100% │ 완료 │조호순│ 완료   │                │
│ 4  │                  │ 법령 준수…│ ✓  │ ✓  │    │    │    │  40% │설계중│    │          │                │
│ 5  │                  │ 산업안전…  │ ✓  │ ✓  │    │    │    │  40% │설계중│조호순│        │                │
│…   │                  │            │    │    │    │    │    │      │      │    │          │                │
└────┴──────────────────┴────────────┴────┴────┴────┴────┴────┴──────┴──────┴────┴──────────┴────────────────┘
```

**테이블 열 상세:**

| 열 | 설명 | 소스 매핑 |
|----|------|----------|
| **#** | 순번 (행 번호) | 자동 생성 |
| **도메인** | IA L1 그룹명 + `(완료/전체)` 카운트 | `ia.json` → L1 screens. 도메인 그룹 행은 노란 배경으로 시각 구분 |
| **메뉴** | IA L2/L3 화면명 | `ia.json` → L2/L3 screens |
| **① 분류** | Ingest: 해당 화면 분류 완료 여부 | `_classified/screens/` 존재 + `_index.json` status ∈ {validated, extracted} |
| **② 기획** | Plan: SRS에 해당 화면의 FT 매핑 존재 여부 | `srs.json` → features[].screen이 해당 화면 ID 참조 |
| **③ 설계** | Design: Screen 설계 + ERD/API 연결 완료 여부 | `screens.json` → 해당 화면 ID 정의 존재 AND status ∈ {Draft, Review, Final} |
| **④ 개발** | Dev: 코드 생성 완료 여부 | `code.json` → generatedFiles[]에 해당 화면 FE 컴포넌트 존재 |
| **⑤ 검증** | QA: 테스트 케이스 생성 + 실행 통과 여부 | `test-cases.json` → 해당 화면 관련 FT의 TC 존재 AND result = passed |
| **진행률** | 완료 단계 수 / 5 (%) | 5단계 중 ✓ 체크 수 × 20% |
| **상태** | 파이프라인 상태 배지 | 최신 완료 단계 기준 판정 (완료/QA진행/개발중/설계중/기획중/대기) |
| **담당** | 할당된 담당자명 | `_backlog/` → assignee 또는 `srs.json` → owner |
| **완료(예정)일** | 완료일(실제) 또는 예정일 | `_backlog/` → dueDate, completedDate |
| **비고** | 특이사항, 지연 사유, 참고 정보 | `_backlog/` → notes, `_index.json` → impact flags, 미완료 사유 |

**5단계 셀 표시 규칙:**

| 표시 | 의미 | 셀 스타일 |
|------|------|----------|
| ✓ (체크마크) | 해당 단계 완료 | 배경 `#1e293b`, 체크 아이콘 white |
| 🔵 (파란 블록) | 해당 단계 현재 진행 중 | 배경 `#3b82f6` |
| 🔴 (빨간 블록) | 해당 단계 이슈/블로커 | 배경 `#ef4444` |
| 빈칸 | 아직 미도달 | 배경 `#334155` (dark gray) |
| — (대시) | 해당 단계 미해당/스킵 | 배경 transparent |

**도메인 그룹 행:**
- L1 도메인명 + `(완료수/전체수)` 카운트
- 도메인별 전체 진행률 퍼센트 바
- 배경색: `#fbbf24` (amber-400) 텍스트로 시각적 그룹 구분
- 해당 도메인 소속 메뉴의 진행률 평균

**진행률 프로그레스 바:**
- 배경: `#334155` (진행률 트랙)
- 채움: `#22c55e` (green-500, 100%) / `#3b82f6` (blue-500, 진행중) / `#f59e0b` (amber-500, 저조)
- 텍스트: 퍼센트 수치를 바 우측에 표시

---

##### ③ Bottom — 기술 혁신 로드맵

Roadmap 문서에서 기술 혁신/개선 관련 항목을 별도 섹션으로 표시한다.

```
┌──────────────────────────────────────────────────────────────────────┐
│  2026 기술 혁신 로드맵   IN PROGRESS    도메인 메뉴수: 완료 0 · 진행 1│
│                                                                      │
│  ⚠ 체크리스트 반복 점검 — 핵심 개선 과제                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │    384       │  │    163       │  │     0        │                  │
│  │ 위험요인 항목│  │ 필터 적용    │  │ 반복에서     │                  │
│  │(1차 검토 표시)│ │해제 누적 항목│  │ 가능         │                  │
│  └─────────────┘  └─────────────┘  └─────────────┘                  │
│                                                                      │
│  ┌────┬──────────┬─────────────────────┬────┬──────┬──────┬────┬────┐│
│  │ #  │ 메뉴     │ 제목               │긴급│ 시기 │시작일│상태│비고││
│  ├────┼──────────┼─────────────────────┼────┼──────┼──────┼────┼────┤│
│  │ 1  │ 체크리스트│체크리스트 반복 점검…│ 1 │ 4일 │      │    │    ││
│  │ 2  │ AI 고도화│위험성평가 AI 고도화…│ 1 │4.5일│      │    │    ││
│  │ 3  │ AI 챗봇  │AI 안전관리 챗봇 …  │ 1 │4.5일│      │    │    ││
│  │ 4  │ 안전보건…│안전보건교육 노사협…│    │3.4일│      │    │    ││
│  │ 5  │ 보고서   │월간 안전보고서 자동…│    │ 5일 │      │    │    ││
│  └────┴──────────┴─────────────────────┴────┴──────┴──────┴────┴────┘│
└──────────────────────────────────────────────────────────────────────┘
```

**로드맵 테이블 열:**

| 열 | 설명 | 소스 |
|----|------|------|
| **#** | 순번 | 자동 생성 |
| **메뉴** | 로드맵 항목명 (기능/모듈) | `roadmap.json` → milestones 또는 features |
| **제목** | 세부 설명 | `roadmap.json` → description |
| **긴급** | 긴급도 레벨 (🔺 1~3, 숫자가 낮을수록 급함) | `roadmap.json` → priority 또는 `_backlog/` → priority |
| **시기** | 예상 소요 기간 (일) | `roadmap.json` → estimation |
| **시작일** | 시작 예정일 | `roadmap.json` → startDate |
| **상태** | 상태 배지 (미시작/진행중/완료) | `roadmap.json` → status |
| **비고** | 세부 참고사항 | `roadmap.json` → notes |

**체크리스트 반복 점검 블록:**
- 핵심 개선 과제 관련 KPI 카드 3개 표시
- 각 KPI: 큰 숫자 + 설명 텍스트
- 소스: `_classified/` 항목 수 집계 또는 `roadmap.json` → metrics

---

##### ④ 데이터 매핑 — PDCA 5단계 완료 판정 로직

```
Stage 1 (분류 — Ingest):
  _classified/screens/_index.json에서 해당 화면 ID 존재
  AND status ∈ {validated, extracted}
  → ✓

Stage 2 (기획 — Plan):
  srs.json → features[] 중
  screen 필드가 해당 화면 ID를 참조하는 FT 1개 이상 존재
  AND 해당 FT의 status ≠ "draft"
  → ✓

Stage 3 (설계 — Design):
  screens.json → screens[] 중
  해당 화면 ID의 layout/component 정의 존재
  AND status ∈ {Draft, Review, Final}
  AND (해당 화면 관련 API endpoint가 api.json에 정의됨 OR API 불필요 화면)
  → ✓

Stage 4 (개발 — Dev):
  code.json → generatedFiles[] 중
  해당 화면 관련 FE 컴포넌트 파일 존재
  AND buildStatus ≠ "error"
  → ✓

Stage 5 (검증 — QA):
  test-cases.json → testCases[] 중
  해당 화면 관련 FT에 대한 TC 존재
  AND test-report.json → 해당 TC의 result = "passed"
  → ✓
```

**예외 처리:**
- IA에 화면이 있지만 `_classified/`에 없는 경우: 분류 미완료 (빈칸)
- SRS에 FT가 없는 화면: 기획 미완료 (빈칸)
- 전체 5단계 중 해당 없는 단계는 `—` 표시 (예: 정적 페이지는 QA 불필요)
- `_backlog/`에 해당 화면 관련 항목이 있으면 담당/일정/비고를 backlog에서 가져옴

---

### Step 3: Generate Dashboard (index.html)

전체 리포트를 묶는 대시보드.

**구조:**

```
┌──────────────────────────────────────────────────────────┐
│  {ProjectName} — {scope} Report                          │
│  Generated: {date} | Phase: {current} | v{version}       │
├──────────────┬───────────────────────────────────────────┤
│  Sidebar     │  Main Content                             │
│              │                                           │
│  ─ Dashboard │  ┌─────────────────────────────────┐     │
│              │  │  Phase: Plan ███░░ Design ██░░░  │     │
│  01 Plan     │  │  Docs: 12  Screens: 57  TC: 24  │     │
│    SRS       │  │  FR: 25  US: 40  FT: 80         │     │
│    IA        │  └─────────────────────────────────┘     │
│    Roadmap   │                                           │
│              │  Phase별 요약 카드                          │
│  02 Design   │  ┌──────┐ ┌──────┐ ┌──────┐             │
│    ERD       │  │Ingest│ │ Plan │ │Design│ ...          │
│    API       │  │42항목 │ │12문서│ │5문서 │              │
│    Screens   │  └──────┘ └──────┘ └──────┘             │
│    RTM       │                                           │
│              │  Quick Stats                              │
│  03 Dev      │  - Requirements: 25 FR + 5 NR            │
│    Code      │  - Screens: 57 (12 groups)               │
│    Spec-Sync │  - API: 32 endpoints                     │
│              │  - ERD: 15 entities                       │
│  04 Check    │  - Tests: 20/24 passed                   │
│    TestCases │                                           │
│    TestReport│  Assumptions: 16건 (미리뷰)               │
│              │  Backlog: 8건                              │
│  Wireframes  │                                           │
│    SCR-001   │                                           │
│    SCR-002   │                                           │
│    ...       │                                           │
│              │                                           │
└──────────────┴───────────────────────────────────────────┘
```

**Sidebar 구성:**

1. **Dashboard** — 전체 요약 (기본 선택)
2. **Phase별 문서** — `_index.json` 기반, 문서 클릭 시 `.md` → HTML 렌더링
3. **Wireframes** — IA 그룹별 화면 목록, 클릭 시 와이어프레임 로드
4. 각 항목에 Status 배지 (Draft/Review/Final)
5. 검색 필터 (문서명/ID 키워드)
6. Phase별 리포트 링크 (→ `plan-report.html` 등)

**Main Content — Dashboard:**

1. **전체 Progress Summary** (최상단):
   ```
   ✅ Done: 45건  |  ⏳ Remaining: 12건  |  💡 Improve: 8건
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 69% Complete
   ```
   - Done: 전체 Phase에서 Final/passed/validated 항목 합계
   - Remaining: Draft/extracted/todo/미생성 항목 합계
   - Improve: failed TC, spec-sync 위반, tech debt, 미리뷰 assumptions 합계
   - Progress bar (전체 완료율)

2. **Phase별 요약 카드** (클릭 → 상세 리포트)
3. **Remaining Items** 테이블: 미완료 항목 전체 목록 (Phase, ID, Title, Status, 담당)
4. **Improve Items** 테이블: 개선 필요 항목 전체 목록 (Phase, ID, 사유, Severity, 제안 액션)
5. **Assumptions** 미리뷰 목록 (ID, 내용, confidence)
6. **Backlog** 요약 (todo/in-progress/done 분포)
7. **Next Steps** 체크리스트:
   - [ ] Remaining {n}건 완료
   - [ ] Improve {n}건 수정
   - [ ] Assumptions {n}건 리뷰 (`/u-assume`)
   - [ ] 결과 확인 후 배포 (`/u-ship`)

**Main Content — 문서/와이어프레임:**
- 문서 선택 시: `.md` → HTML 렌더링 (Mermaid → 인라인 SVG)
- 와이어프레임 선택 시: `.html` 직접 렌더링 / `.md` → HTML 변환

### Step 4: Render Diagrams to SVG

모든 HTML 리포트에서 Mermaid 코드 블록을 인라인 SVG로 변환한다.

```
function renderMermaidToSVG(htmlContent):
  // 1. ```mermaid 블록 감지
  // 2. Mermaid.js로 SVG 문자열 생성
  // 3. <div class="diagram"> 안에 SVG 인라인 삽입
  // 4. viewBox 설정 → 반응형 스케일링
  // 5. 클릭 시 확대 모달 (zoom)
  return htmlWithSVG
```

지원 다이어그램:
- `erDiagram` → ERD
- `sequenceDiagram` → API 흐름
- `flowchart` / `graph` → Screen Flow, 워크플로우
- `classDiagram` → 코드 구조
- `stateDiagram` → 상태 전이
- inline SVG sitemap → IA 계층 (Mermaid mindmap 사용 금지)
- `pie` → 통계 분포
- `gantt` → Roadmap 타임라인

### Step 5: Apply Common Style

모든 리포트에 공통 스타일을 적용한다.

| 요소 | 사양 |
|------|------|
| Sidebar 배경 | `#1e293b` (dark slate) |
| Sidebar 텍스트 | `#e2e8f0` (light gray) |
| Sidebar 너비 | `280px` (고정) |
| Main Content 배경 | `#f1f5f9` (light blue-gray) |
| Status 배지 | Draft(`#64748b`), Review(`#f59e0b`), Final(`#22c55e`) |
| 테이블 | zebra striping, border-collapse |
| 코드 블록 | `#1e293b` 배경, monospace |
| 다이어그램 | SVG 인라인, 클릭 zoom |
| 반응형 | 768px 미만에서 sidebar 접기 + 햄버거 메뉴 |
| 인쇄 | `@media print` 지원 (sidebar 숨김, 전체 너비) |
| Footer | `{license.type} · © {license.owner}` (`u-maker.config.json`의 `license` 설정 참조) |

### Step 6: Notify Completion

```
## u-report Complete

**Scope:** {scope}
**Date:** {YYYY-MM-DD}
**Reports:** {n} HTML files generated
**Location:** .u-maker/_reports/{scope}/{date}/

### Generated Files
| File | Size | Sections |
|------|------|----------|
| index.html | 45KB | Dashboard + 12 docs + 57 wireframes |
| ingest-report.html | 28KB | 10 categories, 156 items |
| plan-report.html | 35KB | SRS + IA + Roadmap |
| design-report.html | 52KB | ERD + API + Screen + RTM |
| dev-report.html | 22KB | Code + Spec-Sync |
| qa-report.html | 18KB | 24 TC, 20 passed |
| daily-report-{date}.html | 40KB | IA 일정 조율 + 로드맵 |

Open in browser:
  open .u-maker/_reports/{scope}/latest/index.html
```

---

## --only Flag

| Value | 생성 파일 |
|-------|----------|
| `--only ingest` | `ingest-report.html` |
| `--only plan` | `plan-report.html` |
| `--only design` | `design-report.html` |
| `--only dev` | `dev-report.html` |
| `--only qa` | `qa-report.html` |
| `--only daily` | `daily-report-{YYYY-MM-DD}.html` (IA 일정 조율 Daily Report) |
| `--only dashboard` | `index.html` (대시보드만) |
| (생략) | 전체 생성 |

---

## /u-loop 연동

`/u-loop` 실행 시 각 단계 완료 후 해당 리포트를 자동 생성한다:

```
[ingest 완료] → /u-report {scope} --only ingest
[plan 완료]   → /u-report {scope} --only plan
[design 완료] → /u-report {scope} --only design
[dev 완료]    → /u-report {scope} --only dev
[qa 완료]     → /u-report {scope} --only qa
[루프 종료]   → /u-report {scope} --only daily
[루프 종료]   → /u-report {scope} --only dashboard
```

루프용 리포트는 `.u-maker/_reports/loop-{loopId}/{date}/`에 저장되며, 루프 메타데이터(소요 시간, 에러, 가정)가 추가로 포함된다. `latest` 심볼릭 링크도 동일하게 생성된다.

---

## Safety Rules

1. **소스 문서 무수정:** `.md` / `.json` 파일은 읽기만 수행 (READ-ONLY)
2. **`_reports/` 디렉토리만 쓰기:** HTML 파일은 `_reports/` 하위에만 생성
3. **인라인 리소스:** 외부 의존성 없는 단일 HTML (Mermaid.js CDN만 예외)
4. **민감 정보 제외:** `.env` 값, 하드코딩 시크릿은 리포트에 포함하지 않음
5. **같은 날짜 덮어쓰기:** 같은 날짜 디렉토리의 리포트는 경고 없이 덮어쓴다. 다른 날짜의 리포트는 보존된다 (이력 관리).
6. **SVG 인라인 필수:** 다이어그램은 외부 이미지 파일이 아닌 인라인 SVG로 렌더링
7. **`language.documents` 반영:** 리포트 본문 언어는 config 설정을 따름
