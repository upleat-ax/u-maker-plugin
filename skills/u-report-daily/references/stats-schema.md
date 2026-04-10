# Stats Snapshot Schema

통계 스냅샷은 daily/weekly 리포트 간 공유되는 데이터 포맷이다.
매일 1회 저장되며 추이 차트의 데이터 소스로 사용된다.

## 저장 경로

```
.u-maker/.state/stats/{YYYY-MM-DD}.json
```

## Full Schema

```json
{
  "date": "2026-04-10",
  "generatedAt": "2026-04-10T18:30:00+09:00",
  "version": "1.0",

  "apps": {
    "{appName}": {
      "fr":  { "total": 12, "added": 2 },
      "us":  { "total": 45, "added": 5 },
      "ft":  { "total": 30, "added": 3 },
      "tc":  { "total": 20, "added": 2 },
      "sc":  {
        "total": 15,
        "added": 1,
        "designed": 15,
        "implemented": 8
      },
      "wireframe": { "total": 10, "added": 1 }
    }
  },

  "meetings": {
    "count": 3,
    "topics_discussed": 5,
    "decisions_made": 4,
    "unresolved_issues": 2,
    "top_unresolved": [
      { "topic": "발주 자동화 범위", "app": "fsms", "related_fr": ["FR-005"] },
      { "topic": "권한 상속 규칙", "app": "fsms", "related_fr": ["FR-003"] }
    ],
    "top_decided": [
      { "topic": "3단 코드 구조 채택", "app": "fsms", "related_fr": ["FR-001"] },
      { "topic": "RBAC 권한 전환", "app": "fsms", "related_fr": ["FR-003"] }
    ]
  },

  "tests": {
    "total": 20,
    "passed": 18,
    "failed": 2,
    "skipped": 0,
    "top_failures": [
      { "id": "TC-012", "name": "권한 검증", "fr": "FR-003", "app": "fsms" },
      { "id": "TC-015", "name": "옵션 조합", "fr": "FR-007", "app": "fsms" }
    ]
  },

  "git": {
    "commits": 15,
    "files_changed": 30,
    "insertions": 450,
    "deletions": 120,
    "contributors": ["thinoo", "dev2"],
    "doc_changes": 8,
    "plugin_changes": 3,
    "output_changes": 5
  },

  "screenshots": {
    "count": 5,
    "files": [
      ".u-maker/.state/screenshots/2026-04-10/fsms-dashboard.png",
      ".u-maker/.state/screenshots/2026-04-10/fsms-order-list.png"
    ]
  }
}
```

## Field Descriptions

### apps.{appName}

| Field | Type | Description |
|-------|------|-------------|
| `fr.total` | int | 전체 Feature 수 (srs.json `features` 배열 길이) |
| `fr.added` | int | 당일/기간 내 신규 추가된 FR 수 |
| `us.total` | int | 전체 User Story 수 |
| `us.added` | int | 신규 US 수 |
| `ft.total` | int | 전체 Functionality 수 |
| `ft.added` | int | 신규 FT 수 |
| `tc.total` | int | 전체 Test Case 수 (testcases.json) |
| `tc.added` | int | 신규 TC 수 |
| `sc.total` | int | 전체 Screen 수 (screens.json) |
| `sc.added` | int | 신규 SC 수 |
| `sc.designed` | int | 설계 완료 화면 수 (screens.json에 정의된 수) |
| `sc.implemented` | int | 구현 완료 화면 수 (실제 접근 가능한 화면 또는 `implemented: true` 플래그) |
| `wireframe.total` | int | 생성된 와이어프레임 HTML 수 |
| `wireframe.added` | int | 신규 와이어프레임 수 |

### Total/Added 산출 방법

- **total**: JSON companion 파일의 현재 배열 길이
- **added**: 전일 stats와 비교하여 `today.total - yesterday.total`. 전일 stats 없으면 `0`

```bash
# 전일 stats 로드
PREV_STATS=".u-maker/.state/stats/$(date -v-1d +%Y-%m-%d).json"
if [ -f "$PREV_STATS" ]; then
  # diff 계산
fi
```

### meetings

| Field | Type | Description |
|-------|------|-------------|
| `count` | int | 당일 회의 수 |
| `topics_discussed` | int | 논의된 주제 수 |
| `decisions_made` | int | 결정된 이슈 수 |
| `unresolved_issues` | int | 미해결 이슈 수 |
| `top_unresolved` | array | 미해결 이슈 목록 (topic, app, related_fr) |
| `top_decided` | array | 결정된 이슈 목록 (topic, app, related_fr) |

### tests

| Field | Type | Description |
|-------|------|-------------|
| `total` | int | 전체 TC 실행 수 |
| `passed` | int | 통과 수 |
| `failed` | int | 실패 수 |
| `skipped` | int | 스킵 수 |
| `top_failures` | array | 실패 TC 목록 (id, name, fr, app) |

### git

| Field | Type | Description |
|-------|------|-------------|
| `commits` | int | 커밋 수 |
| `files_changed` | int | 변경 파일 수 |
| `insertions` | int | 추가 라인 수 |
| `deletions` | int | 삭제 라인 수 |
| `contributors` | string[] | 기여자 목록 |
| `doc_changes` | int | `.u-maker/docs/` 하위 변경 수 |
| `plugin_changes` | int | `skills/`, `agents/`, `hooks/` 변경 수 |
| `output_changes` | int | `.u-maker/out/` 하위 변경 수 |

## Chart Data Derivation

추이 차트를 그릴 때 여러 날짜의 stats 파일을 로드한다.

```bash
# 최근 7일 stats 파일 목록
ls .u-maker/.state/stats/*.json | tail -7
```

### Line Chart: 설계 vs 구현 화면

```
X축: date (7일)
Y축 (line 1): apps.{app}.sc.designed (파란 실선)
Y축 (line 2): apps.{app}.sc.implemented (녹색 실선)
```

### Bar Chart: 일별 활동량

```
X축: date (7일)
Y축 (bar 1): git.commits (파란 바)
Y축 (bar 2): git.doc_changes (녹색 바)
```

### Stacked Bar: 이슈 현황

```
X축: date (7일)
Y축 (stack 1): meetings.unresolved_issues (빨간)
Y축 (stack 2): meetings.decisions_made (녹색)
Y축 (stack 3): tests.failed (노란)
```

### Donut Chart: 테스트 결과 분포

```
passed (녹색), failed (빨간), skipped (회색)
```
