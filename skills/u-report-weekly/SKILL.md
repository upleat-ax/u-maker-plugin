---
name: u-report-weekly
description: "This skill should be used when the user asks to '/u-report-weekly', 'weekly report', 'generate weekly report', '주간 리포트', '위클리 리포트', or '주간 보고서'. Generates a weekly HTML report with per-app FR/US/FT/TC/SC stats, trend charts, meeting summaries, and Playwright screenshots."
version: 1.0.0
---

# u-report-weekly — Weekly Project Report

`/u-report-weekly [--app {name}] [--from {YYYY-MM-DD}] [--to {YYYY-MM-DD}]`

1주일간의 git 히스토리, 회의록 논의, SSoT 문서 변경을 **앱별로** 취합하여 FR/US/FT/TC/SC/Wireframe 수치와 추이 그래프를 포함한 **단일 HTML 리포트**를 생성한다.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--app {name}` | all | 특정 앱만 (생략 시 전체) |
| `--from {date}` | 7일 전 | 시작일 |
| `--to {date}` | today | 종료일 |
| `--no-screenshot` | OFF | Playwright 캡처 건너뛰기 |

## Workflow

### Step 1: Daily Stats 로드

`.u-maker/.state/stats/` 에서 기간 내 daily stats JSON을 모두 로드한다.

```bash
# 기간 내 stats 파일
ls .u-maker/.state/stats/*.json | while read f; do
  d=$(basename "$f" .json)
  if [[ "$d" >= "$FROM" && "$d" <= "$TO" ]]; then
    echo "$f"
  fi
done
```

**stats 파일이 없는 날짜:** 해당 일자는 차트에서 빈 값(gap)으로 처리. 경고 메시지 출력.

> Stats 파일은 `/u-report-daily` 실행 시 자동 생성된다. weekly 전에 daily를 먼저 실행하는 것을 권장.

### Step 2: SSoT 문서 스캔 (현재 시점)

`/u-report-daily` Step 1과 동일한 방식으로 현재 문서 현황을 수집한다.

```
docs/{app}/plan/srs.json     → FR, US, FT
docs/{app}/design/screens.json → SC (designed)
docs/{app}/gatekeeping/testcases.json → TC
docs/{app}/gatekeeping/test-results.json → test pass/fail
output/{app}/design/wireframes/*.html  → Wireframe count
```

### Step 3: Git 히스토리 수집 (1주일)

```bash
# 1주일 커밋 목록
git log --since="{from} 00:00" --until="{to} 23:59" \
  --format="%H|%an|%s|%ai" --no-merges

# 일별 커밋 수
git log --since="{from}" --until="{to}" \
  --format="%ad" --date=short --no-merges | sort | uniq -c

# 변경 파일 분류 (docs, out, skills)
git log --since="{from}" --until="{to}" \
  --name-only --format="" --no-merges | sort -u
```

### Step 4: 회의록 수집 (1주일)

```
URL: https://hj-wiki.upleat.ai/69cd33f60b6f1e9c6e7398f1?tab=meeting
```

WebFetch로 회의 목록 페이지를 읽고, 기간 내 날짜의 회의를 모두 수집한다.
- 페이지네이션이 있으면 `?tab=meeting&page=2` 등 추가 페이지도 조회
- 각 회의 상세 페이지에서: 제목, 날짜, 논의 주제, 결정 사항, 미해결 이슈 추출

**주간 집계:**

| 항목 | 설명 |
|------|------|
| `total_meetings` | 기간 내 전체 회의 수 |
| `total_topics` | 논의된 총 주제 수 |
| `total_decisions` | 결정된 총 이슈 수 |
| `total_unresolved` | 미해결 총 이슈 수 |
| `most_discussed_topics` | 가장 많이 논의된 주제 TOP 5 |
| `most_unresolved_topics` | 미해결이 많은 주제 TOP 5 |
| `most_decided_topics` | 결정이 많은 주제 TOP 5 |

### Step 5: 화면 캡처 (선택) — via `u-tools-browser`

`--no-screenshot` 미지정 시, **반드시 `u-tools-browser` 엔진을 통해** 앱별 주요 화면을 캡처한다. `browser_navigate` / `browser_take_screenshot` 등 MCP 브라우저 도구를 이 스킬에서 직접 호출하지 않는다.

**캡처 대상 (u-tools-browser Step 6b — Screen Capture):**
1. `.u-maker/output/{app}/design/screens/` — 화면 설계서 HTML (앱별 최대 3개)
2. `.u-maker/output/{app}/design/wireframes/` — 와이어프레임 (앱별 최대 3개)
3. 실제 구현 화면 (dev server URL 있는 경우)

**위임 호출:**
- `u-tools-browser` 로드
- `--auto --headless --app {app}` 옵션으로 Step 1→9 실행
- 엔진이 반환하는 요약(Summary Output)을 Step 7에서 HTML 리포트에 삽입

```
저장 경로 (엔진이 관리): .u-maker/.state/screenshots/{date}/{app}-{page}.png
base64 인코딩 → HTML 인라인 삽입은 이 스킬이 담당
```

### Step 6: Weekly Stats 저장

주간 집계 데이터를 별도 파일로 저장한다.

```
저장: .u-maker/.state/stats/{from}--{to}-weekly.json
```

```json
{
  "type": "weekly",
  "from": "2026-04-04",
  "to": "2026-04-10",
  "generatedAt": "2026-04-10T18:30:00+09:00",
  "apps": {
    "{appName}": {
      "fr":  { "start": 10, "end": 12, "delta": 2 },
      "us":  { "start": 40, "end": 45, "delta": 5 },
      "ft":  { "start": 27, "end": 30, "delta": 3 },
      "tc":  { "start": 18, "end": 20, "delta": 2 },
      "sc":  { "start": 14, "end": 15, "delta": 1, "designed_start": 14, "designed_end": 15, "implemented_start": 6, "implemented_end": 8 },
      "wireframe": { "start": 9, "end": 10, "delta": 1 }
    }
  },
  "meetings_summary": {
    "total_meetings": 8,
    "total_topics": 15,
    "total_decisions": 12,
    "total_unresolved": 5,
    "most_discussed": ["권한 설계", "품목코드", "발주 프로세스"],
    "most_unresolved": ["발주 자동화 범위"],
    "most_decided": ["RBAC 전환", "3단 코드 구조"]
  },
  "tests_summary": {
    "avg_pass_rate": 90.0,
    "total_failures_accumulated": 8,
    "most_failed_areas": ["권한 검증", "옵션 조합"]
  },
  "git_summary": {
    "total_commits": 45,
    "total_files_changed": 120,
    "total_insertions": 2300,
    "total_deletions": 800,
    "contributors": ["thinoo", "dev2", "dev3"],
    "daily_commits": [5, 8, 7, 6, 9, 5, 5]
  }
}
```

### Step 7: HTML 리포트 생성

```
출력: .u-maker/reports/{to}-weekly.html
```

#### HTML 필수 요소

- Tailwind CDN (`https://cdn.tailwindcss.com`)
- Font Awesome CDN (`https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/css/all.min.css`) — UI 아이콘용 `fa-*` 클래스 (currentColor 상속 → 다크/라이트 자동 적응)
- 라이트/다크/색각 보정 순환 · 본문 폭 · 맨 위로 컨트롤 — 사이드바 하단 `.sidebar-tools` 임베딩 (html-engine § 0.4; 900px 이하에서는 우하단 `.fab-stack` 으로 전환)
- 잉크 네이비 사이드바 (`#162033` → `#111827` 세로 gradient) + 라이트 본문 (`#f8fafc`)
- 사이드바 스크롤 추적 네비게이션
- 반복 텍스트 목록은 `html-engine`의 `.simple-list`를 사용: 항목별 bordered rounded box·shadow·gap 금지, 행 사이 1px 중립 구분선만 허용
- 설명 문장(섹션 리드, 회의 요약, 다음 주 과제 등)은 **쉬운 글쓰기(중학생 이해 수준)** 규칙을 따른다 — 짧은 문장·쉬운 낱말, 전문용어는 첫 등장에서 괄호 한 줄 풀이. 수치·ID·차트 데이터는 그대로 둔다. 규칙 원문: `skills/u-engine/references/html-engine.md` § 0.6 / `doc-engine.md` § 8, GK-06 `plain-language-middle-school` 검사로 강제
- Copyright(c) 2026 U PLEAT 푸터

#### 사이드바 컬러 및 상태 (필수)

```css
:root{
  --sidebar-bg:#162033;--sidebar-deep:#111827;
  --sidebar-fg:#f8fafc;--sidebar-muted:#c6d0df;--sidebar-dim:#8fa0b8;
  --sidebar-accent:#a8c4e0;--sidebar-line:rgba(168,196,224,.14);
  --sidebar-hover:rgba(168,196,224,.08);--sidebar-active:rgba(168,196,224,.16);
  --sidebar-chip:rgba(168,196,224,.12);
}
.report-sidebar{background:linear-gradient(180deg,var(--sidebar-bg),var(--sidebar-deep));color:var(--sidebar-fg)}
.report-sidebar .nav-item{color:var(--sidebar-muted)}
.report-sidebar .nav-item:hover{background:var(--sidebar-hover);color:var(--sidebar-fg)}
.report-sidebar .nav-item.active{background:var(--sidebar-active);color:var(--sidebar-fg);font-weight:700}
.report-sidebar .nav-icon,.report-sidebar .nav-count{border:0;background:var(--sidebar-chip);color:var(--sidebar-accent);box-shadow:none}
```

- 제목은 `#f8fafc`, 기간은 `#a8b6ca`로 표시하여 정보 위계를 분명히 한다.
- 섹션명 기본색은 `#c6d0df`; hover/active에서만 흰색으로 올린다.
- 번호 칩(`01`~`09`)과 카운트 배지는 흰색 배경을 금지한다. 반투명 페일 블루 면을 사용한다.
- 사이드바 전체를 중간 회색(`#242932` 계열) 단색으로 채우거나, 본문 텍스트를 저대비 회색으로 표시하지 않는다.

#### 리포트 섹션 (순서)

**1. 헤더**
- 프로젝트명, 기간 (`YYYY-MM-DD ~ YYYY-MM-DD`), 앱 목록

**2. Executive Summary 카드 (4열)**

| 카드 | 값 | 색상 |
|------|----|------|
| 총 커밋 | `git_summary.total_commits` | blue |
| 신규 항목 | FR+US+FT+TC 합산 delta | pale blue |
| 회의 횟수 | `meetings_summary.total_meetings` | slate |
| 미해결 이슈 | `meetings_summary.total_unresolved` | red |

**3. 앱별 SSoT 현황 테이블**

각 앱에 대해 아래 테이블을 생성:

| 항목 | 주초 | 주말 | 증감 | 진행률 |
|------|------|------|------|--------|
| FR | 10 | 12 | +2 | - |
| US | 40 | 45 | +5 | - |
| FT | 27 | 30 | +3 | - |
| TC | 18 | 20 | +2 | 66.7% (20/30 FT) |
| SC (설계) | 14 | 15 | +1 | - |
| SC (구현) | 6 | 8 | +2 | 53.3% (8/15 SC) |
| Wireframe | 9 | 10 | +1 | 66.7% (10/15 SC) |

진행률 바: inline SVG로 수평 progress bar 렌더링.

**4. 추이 차트 (inline SVG) — 핵심 섹션**

daily stats 배열로 아래 차트를 생성한다:

**4-A. 설계 vs 구현 화면 추이 (Line Chart)**
```
X축: 날짜 (7일)
Line 1: sc.designed (파란 실선, 원형 dot)
Line 2: sc.implemented (녹색 실선, 원형 dot)
Gap 영역: designed - implemented (연한 파란 fill)
```

**4-B. 일별 활동량 (Grouped Bar Chart)**
```
X축: 날짜 (7일)
Bar 1: git.commits (파란)
Bar 2: git.doc_changes (녹색)
Bar 3: meetings.count (보라)
```

**4-C. 이슈 추적 (Stacked Area Chart)**
```
X축: 날짜 (7일)
Area 1: meetings.decisions_made 누적 (녹색)
Area 2: meetings.unresolved_issues 누적 (빨간)
Area 3: tests.failed (노란)
```

**4-D. SSoT 항목 성장률 (Multi-line Chart)**
```
X축: 날짜 (7일)
Lines: FR, US, FT, TC 각각 다른 색상
```

**4-E. 테스트 결과 추이 (Donut + Line)**
```
Donut: 최종일 기준 passed/failed/skipped 비율
Line: 일별 pass rate % 변화
```

SVG 차트 규칙:
- `viewBox` 반응형 (`width="100%"`)
- 곡선 커넥터 (Bezier `C` path)
- 축 라벨, 범례(legend), 그리드 라인 포함
- 색상: § 0.1 명도 램프 — `#2c5580` · `#3d6fa5` · `#5b8db8` · `#8fb3d0` · `#64748b` (+ 경고 `#c2410c`, 실패 `#dc2626`) — gray + pale blue 외 금지
- light/dark/colorblind 테마 호환 (CSS 변수 사용)
- ASCII art 금지

**5. 회의록 주간 요약**
- 일자별 회의 타임라인 (세로)
- 가장 많이 논의된 주제 TOP 5 (수평 바 차트 SVG)
- 미해결 이슈가 많은 주제 TOP 5 (빨간 배지)
- 결정된 이슈가 많은 주제 TOP 5 (녹색 배지)
- 각 회의 접기/펼치기 카드 (제목, 결정, 미해결)

**6. Git 활동 요약**
- 일별 커밋 히트맵 (SVG 7칸 grid, 진하기로 강도 표현)
- 기여자별 커밋 수 (수평 바)
- 주요 변경 사항 목록 — `.simple-list`, 항목별 카드 금지

**7. Playwright 캡처 갤러리** (캡처 있을 때만)
- 앱별 그룹핑
- 3열 그리드, 이미지 + 캡션 + 화면 ID

**8. 다음 주 주요 과제**
- 미해결 이슈 기반 자동 도출
- 테스트 실패 항목 재검증 목록
- 설계 대비 구현 gap이 큰 영역
- 번호형 `.simple-list.simple-list--numbered`로 렌더링하고, 번호는 배경 없는 mono 텍스트로 표시

#### 반복 목록 스타일 (전체 섹션 공통)

출처/근거 파일, 주요 변경, 액션·권고, 다음 주 과제, 체크포인트·마일스톤은 카드 컬렉션이 아니라 단순 행 목록으로 렌더링한다.

- 각 항목: `background:transparent; border:0; border-radius:0; box-shadow:none; margin:0`
- 행 사이: `border-bottom:1px solid var(--border)`; 마지막 행은 구분선 없음
- 현재/중요 행: `background:var(--accent-bg)` + `font-weight:700`; 테두리·radius 추가 금지
- 3열 마일스톤: `이름 | 설명 | 날짜` grid를 유지하되 같은 행 구분선 스타일 적용
- 요약 KPI·차트·캡처 갤러리·접기/펼치기 회의 카드는 독립 콘텐츠이므로 카드 스타일 유지

### Step 8: 인덱스 갱신

1. `.u-maker/reports/index.html` — weekly 항목 추가
2. `.u-maker/index.html` — 루트 허브 갱신

## Output Summary

```
u-report-weekly complete.
  Period:      2026-04-04 ~ 2026-04-10
  App(s):      app1, portal
  Stats used:  7 daily snapshots
  Weekly saved: .u-maker/.state/stats/2026-04-04--2026-04-10-weekly.json
  Report:      .u-maker/reports/2026-04-10-weekly.html
  Screenshots: 12 captured
  
  Summary:
    Commits: 45 | Docs changed: 35
    Meetings: 8 (topics: 15, decisions: 12, unresolved: 5)
    FR: +2, US: +5, FT: +3, TC: +2, SC: +1
    Design→Impl gap: 15 designed, 8 implemented (53%)
    Test pass rate: 90% (avg)
```

## References

- `references/chart-spec.md` — SVG 차트 상세 스펙 (축, 범례, 색상, 레이아웃)
- `skills/u-report-daily/references/stats-schema.md` — 통계 JSON 스키마 (daily와 공유)
- `_meta/templates/reports-index.template.html` — 리포트 인덱스 템플릿
- `skills/u-engine/references/html-engine.md` — HTML 엔진 공통 규칙
