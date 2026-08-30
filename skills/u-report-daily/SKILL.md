---
name: u-report-daily
description: "This skill should be used when the user asks to '/u-report-daily', 'daily report', 'generate daily report', '일일 리포트', '데일리 리포트', or '오늘 보고서'. Generates a daily HTML report summarizing git history, meeting notes, document changes, and project statistics with trend charts."
version: 1.0.0
---

# u-report-daily — Daily Project Report

`/u-report-daily [--app {name}] [--date {YYYY-MM-DD}]`

하루 동안의 git 커밋, 회의록 논의 내용, SSoT 문서 변경 사항, Playwright 화면 캡처를 취합하여 **단일 HTML 리포트**를 생성한다. 통계 스냅샷을 저장하여 추이 차트에 활용한다.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--app {name}` | all | 특정 앱만 리포트 (생략 시 전체) |
| `--date {YYYY-MM-DD}` | today | 리포트 대상 날짜 |
| `--no-screenshot` | OFF | Playwright 캡처 건너뛰기 |

## Workflow

### Step 1: SSoT 문서 스캔

`.u-maker/docs/{app}/` 디렉토리에서 현재 문서 현황을 수집한다.

```bash
# 앱 목록 확인
ls .u-maker/docs/

# 각 앱별 문서 파일 목록
ls .u-maker/docs/{app}/plan/    # srs.md+json, ia.md+json
ls .u-maker/docs/{app}/design/  # erd.md+json, api.md+json, screens.md+json, design-system.md+json
ls .u-maker/docs/{app}/gatekeeping/   # testcases.md+json, test-results.md+json
```

**JSON companion에서 추출할 항목:**

| 문서 | JSON key | 카운트 대상 |
|------|----------|------------|
| srs.json | `features` 배열 | FR (Feature) 수 |
| srs.json | `features[].userStories` | US (User Story) 수 |
| srs.json | `features[].userStories[].functionalities` | FT (Functionality) 수 |
| testcases.json | `testCases` 배열 | TC (Test Case) 수 |
| screens.json | `screens` 배열 | SC (Screen) 수 |
| test-results.json | `results` 배열 | Pass/Fail 수 |

**와이어프레임 카운트:**

```bash
# 생성된 와이어프레임 HTML 수
ls .u-maker/output/{app}/design/wireframes/*.html 2>/dev/null | wc -l
```

**구현된 화면 카운트:** Playwright로 접근 가능한 실제 화면 수. `screens.json`의 `implemented: true` 플래그 또는 `out/screenshots/` 디렉토리의 파일 수로 판단.

### Step 2: Git 히스토리 수집

대상 날짜의 커밋 내역을 수집한다.

```bash
# 당일 커밋 목록
git log --since="{date} 00:00" --until="{date} 23:59" --format="%H|%an|%s|%ai" --no-merges

# 변경된 파일 목록
git log --since="{date} 00:00" --until="{date} 23:59" --name-only --format="" --no-merges | sort -u

# 변경 통계
git log --since="{date} 00:00" --until="{date} 23:59" --shortstat --no-merges
```

**분류 기준:**
- `.u-maker/docs/` 변경 → 문서 변경
- `.u-maker/output/` 변경 → HTML 산출물 변경
- `skills/`, `agents/`, `hooks/` 변경 → 플러그인 변경
- 그 외 → 기타 변경

### Step 3: 회의록 수집

위키에서 당일 회의록을 가져온다.

```
URL: https://hj-wiki.upleat.ai/69cd33f60b6f1e9c6e7398f1?tab=meeting
```

**WebFetch로 회의 목록 스크래핑:**
1. 메인 페이지에서 당일 날짜(`YYYY.MM.DD`)에 해당하는 회의 링크 추출
2. 각 회의 상세 페이지 WebFetch → 제목, 참석자, 핵심 논의, 결정 사항, 미해결 이슈 추출
3. 논의 주제별로 분류: `discussed_topics`, `decisions`, `unresolved_issues`

**추출 구조:**

```json
{
  "meetings": [
    {
      "title": "품목코드·발주 프로세스",
      "datetime": "2026-04-09 18:00",
      "topics": ["A코드 구조", "발주 프로세스"],
      "decisions": ["3단 코드 구조 채택"],
      "unresolved": ["발주 자동화 범위 미정"]
    }
  ]
}
```

### Step 4: Playwright 화면 캡처 (선택)

`--no-screenshot` 미지정 시, Playwright MCP로 주요 화면을 캡처한다.

**캡처 대상:**
1. `.u-maker/output/{app}/` 의 최근 변경된 HTML 페이지 (최대 5개)
2. 실제 구현된 앱 화면 (dev server URL이 있는 경우)

**Playwright 워크플로우:**
1. `browser_navigate` → HTML 파일 또는 dev URL
2. `browser_take_screenshot` → PNG 저장
3. 캡처된 이미지를 base64로 인코딩하여 HTML에 인라인 삽입

```
캡처 저장: .u-maker/.state/screenshots/{date}/{app}-{page}.png
```

### Step 5: 통계 스냅샷 저장

수집된 데이터를 JSON 스냅샷으로 저장한다. **이 파일은 weekly 리포트와 추이 차트에 재사용된다.**

```
저장 경로: .u-maker/.state/stats/{YYYY-MM-DD}.json
```

**Stats JSON Schema** — `references/stats-schema.md` 참조.

```json
{
  "date": "2026-04-10",
  "apps": {
    "{appName}": {
      "fr": { "total": 12, "added": 2 },
      "us": { "total": 45, "added": 5 },
      "ft": { "total": 30, "added": 3 },
      "tc": { "total": 20, "added": 2 },
      "sc": { "total": 15, "added": 1, "designed": 15, "implemented": 8 },
      "wireframe": { "total": 10, "added": 1 }
    }
  },
  "meetings": {
    "count": 3,
    "topics_discussed": 5,
    "decisions_made": 4,
    "unresolved_issues": 2,
    "top_unresolved": ["발주 자동화 범위", "권한 상속 규칙"],
    "top_decided": ["3단 코드 구조", "RBAC 전환"]
  },
  "tests": {
    "total": 20,
    "passed": 18,
    "failed": 2,
    "top_failures": ["TC-012 권한 검증", "TC-015 옵션 조합"]
  },
  "git": {
    "commits": 15,
    "files_changed": 30,
    "insertions": 450,
    "deletions": 120,
    "contributors": ["thinoo", "dev2"]
  }
}
```

### Step 6: HTML 리포트 생성

단일 HTML 파일로 리포트를 생성한다.

```
출력: .u-maker/reports/{YYYY-MM-DD}-daily.html
```

#### HTML 구성 요소

**HTML 필수 요소:**
- Tailwind CDN (`https://cdn.tailwindcss.com`)
- Font Awesome CDN (`https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/css/all.min.css`) — UI 아이콘용 `fa-*` 클래스 (currentColor 상속 → 다크/라이트 자동 적응)
- 라이트/다크/색각 보정 순환 · 본문 폭 · 맨 위로 컨트롤 — 사이드바 하단 `.sidebar-tools` 임베딩 (html-engine § 0.4; 900px 이하에서는 우하단 `.fab-stack` 으로 전환)
- 잉크 네이비 사이드바 (`#162033` → `#111827` 세로 gradient) + 라이트 본문 (`#f8fafc`); 색·hover·active·번호/카운트 칩은 `u-report-weekly`의 사이드바 규칙과 동일
- 사이드바 스크롤 추적 네비게이션
- 반복 텍스트 목록은 `html-engine`의 `.simple-list`를 사용: 항목별 bordered rounded box·shadow·gap 금지, 행 사이 1px 중립 구분선만 허용
- 설명 문장(요약·회의록 요약·변경 상세 등)은 **중학생 이해 수준 쉬운 글쓰기**로 쓴다 — 짧은 문장, 쉬운 낱말, 전문용어·약어는 첫 등장에서 괄호 한 줄 풀이. 수치·ID·커밋 해시는 그대로 둔다. 규칙 원문: `skills/u-engine/references/html-engine.md` § 0.6 / `doc-engine.md` § 8 (Gatekeeping GK-06 `plain-language-middle-school` 검사로 강제)
- Copyright(c) 2026 U PLEAT 푸터

#### 리포트 섹션 (순서)

**1. 헤더 + 날짜 배지**
- 프로젝트명, 리포트 날짜, 앱 목록

**2. 요약 메트릭 카드 (4열 그리드)**

| 카드 | 값 | 색상 |
|------|----|------|
| 오늘 커밋 | `git.commits` | blue |
| 문서 변경 | docs changes count | pale blue |
| 회의 논의 | `meetings.topics_discussed` | slate |
| 미해결 이슈 | `meetings.unresolved_issues` | red |

**3. SSoT 문서 현황 테이블 (앱별)**

| 앱 | FR | US | FT | TC | SC | WF | 설계 | 구현 |
|----|----|----|----|----|----|----|------|------|
| 각 앱 행 | 수치 | +신규 | | | | | | |

**4. 추이 차트 (inline SVG)**

최근 7일간 `.u-maker/.state/stats/` 에서 데이터를 로드하여:
- **Line chart**: 설계 화면 vs 구현 화면 추이
- **Bar chart**: 일별 커밋 수 + 문서 변경 수
- **Stacked bar**: 미해결 이슈 vs 결정된 이슈 vs 테스트 실패

SVG 차트 규칙:
- `viewBox` 기반 반응형 (`width="100%"`)
- 곡선 커넥터 (Bezier `C` path)
- 색상: § 0.1 명도 램프 — `#2c5580` · `#3d6fa5` · `#5b8db8` · `#8fb3d0` · `#64748b` (+ 경고 `#c2410c`, 실패 `#dc2626`) — gray + pale blue 외 금지
- 호버 시 tooltip (CSS only)
- light/dark/colorblind 테마 전환 지원 (CSS 변수 + `localStorage.theme`)

**5. Git 커밋 목록**
- 시간순 타임라인 (세로 라인 + 원형 dot, 항목별 카드 금지)
- 커밋 해시 (축약), 작성자, 메시지, 변경 파일 접기/펼치기

**6. 회의록 요약**
- 회의별 카드: 제목, 일시, 핵심 논의, 결정 사항, 미해결 이슈
- 결정 사항은 체크 아이콘, 미해결은 경고 아이콘

**7. Playwright 캡처 갤러리** (캡처 있을 때만)
- 2열 그리드, 이미지 + 캡션
- base64 인라인 또는 상대 경로

**8. 금일 변경 상세**
- 문서별 변경 내역: 추가된 항목, 수정된 항목
- diff 하이라이트 (추가: pale blue `#eef3f9`/`#2c5580`, 삭제: red)

#### 반복 목록 스타일 (전체 섹션 공통)

변경 파일, 커밋, 액션·권고, 출처/근거 목록은 `.simple-list`로 렌더링한다. 각 행은 투명 배경 + 1px 중립 하단 구분선만 사용하며 `border-radius`, 4변 border, shadow, 행 간 gap을 두지 않는다. 현재/중요 행은 `background:var(--accent-bg)` + `font-weight`로만 강조한다. 요약 KPI·차트·캡처·회의 접기/펼치기처럼 독립 콘텐츠인 경우에만 카드 스타일을 유지한다.

### Step 7: 인덱스 갱신

리포트 생성 후 인덱스를 업데이트한다.

1. `.u-maker/reports/index.html` — 리포트 목록에 새 항목 추가
2. `.u-maker/index.html` — 루트 허브의 최근 리포트 링크 갱신

## Output Summary

```
u-report-daily complete.
  Date:        2026-04-10
  App(s):      app1, portal
  Stats saved: .u-maker/.state/stats/2026-04-10.json
  Report:      .u-maker/reports/2026-04-10-daily.html
  Screenshots: 5 captured
  
  Metrics:
    Commits: 15 | Docs changed: 8
    Meetings: 3 (topics: 5, decisions: 4, unresolved: 2)
    Tests: 18/20 passed (2 failed)
    Screens: 15 designed, 8 implemented
```

## References

- `references/stats-schema.md` — 통계 JSON 스키마 상세 정의
- `_meta/templates/daily-report.template.html` — 기본 템플릿 (레거시, 참고용)
- `_meta/templates/reports-index.template.html` — 리포트 인덱스 템플릿
- `skills/u-engine/references/html-engine.md` — HTML 엔진 공통 규칙 (SVG, Tailwind, light/dark/colorblind theme switch)
