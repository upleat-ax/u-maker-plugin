---
name: u-reports-roadmap
description: "This skill should be used when the user asks to '/u-reports-roadmap', 'roadmap', 'generate roadmap', 'gantt roadmap', 'project roadmap', 'estimate timeline', '로드맵', '로드맵 생성', '개발 로드맵', '프로젝트 로드맵', '일정 산정', '간트 로드맵', or '로드맵 짜줘'. Analyzes source code + git to scope the work, estimates a team-capacity-based schedule (asks or estimates dev/planner/designer counts), runs per-track risk analysis, and renders an interactive editable Gantt roadmap HTML in the reference style."
version: 1.0.0
---

# u-reports-roadmap — Code-grounded Interactive Roadmap

`/u-reports-roadmap [--start YYYY-MM-DD] [--deadline YYYY-MM-DD] [--devs N] [--planners N] [--designers N] [--slug name] [--rerender]`

소스코드와 git 이력을 분석해 작업 범위를 산정하고, **팀 인원수(개발/기획/디자인) 기반 capacity**로 일정을 추정하며, 트랙별 **위험도 분석**을 거쳐 **편집 가능한 인터랙티브 간트 로드맵 HTML**(참조 스타일)을 생성한다.

산출물은 **확정 일정이 아니라 편집 가능한 1차 추정 초안**이다 — 모든 막대는 드래그/클릭으로 조정되고, 막대 위치·릴리즈 날짜는 git 진행상황 기반 추정이다. 불확실한 항목은 `(TBD)`·`추정`으로 명시한다.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--start {date}` | 오늘(주 시작) | W1 시작일 (계획 윈도우 "현재") |
| `--deadline {date}` | 물어봄 | 하드 마감일 → D-day + FINAL 컬럼 |
| `--devs / --planners / --designers N` | 추산→확인 | 팀 인원수. 미지정 시 git에서 추산 후 사용자 확인 |
| `--slug {name}` | repo명 | 산출물 파일명·localStorage 키 |
| `--rerender` | OFF | 재분석 없이 사이드카 `.data.json`에서 HTML만 재생성 |

`--rerender` 인 경우 Step 1–4 를 건너뛰고 사이드카 데이터로 Step 5 만 수행한다.

## Workflow

### Step 1 — Scope analysis (always code + git)

`.u-maker` SSoT에 의존하지 않고 **항상 소스코드+git을 직접 스캔**한다. `references/scope-analysis.md`의 grep/git 패턴으로:

- **Repo shape 판별** → 트랙 granularity 결정 (monorepo=앱별/피처별, 단일앱=피처영역별). 항상 cross-cutting **`common` 트랙**(BE 의존·SSoT·통합 QA) 추가.
- **트랙별 스코프 신호**: 라우트/화면 수, mock·`TODO(backend)`·stub 밀도, 실 API 호출 유무, feature-module 성숙도 → "완료 vs 잔여" 판정.
- **모멘텀 신호**: 최근 6–8주 주간 throughput, 완료 커밋, in-flight 브랜치/MR 번호, churn 상위 파일, parked 브랜치.
- **dated target**: 코드/문서에 이미 있는 실측 속도·ETA(예: `srs.md` "주간 +19.5화면") — 있으면 최우선 anchor로 인용.

산출: 트랙별 `{scope, status(done/inFlight/remaining), signals, datedTargets}` 레코드.

### Step 2 — Team capacity (추산 후 확인)

`references/estimation-model.md` 절차로:

1. **추산**: `git shortlog -sne --since='8 weeks ago'`로 활성 기여자 도출, CODEOWNERS/경로로 역할 추론(`ui-*`·`*.figma*`→디자이너, `docs/`·`srs`→기획자, 그 외→개발). 초안 `{devs, planners, designers}` 작성.
2. **확인**: `AskUserQuestion`으로 추산치를 기본값으로 제시하고 사용자가 보정. `--devs/--planners/--designers` 인자가 오면 그 값을 우선하고 미지정분만 물어본다. 확정 인원수는 리포트(subtitle/framing)에 명시해 추정 근거를 투명화.

### Step 3 — Estimation → Gantt phases

측정 속도에 anchor하고 팀 규모로 modulate한다(textbook 상수 금지):

- `observedVelocity`(git) → `perDevVelocity` → `projectedCapacity = perDevVelocity × devs × focusFactor`(0.6–0.8, 값 명시).
- **디자이너/기획자는 upstream 게이트**(스펙·DS·화면 준비)로 모델링 — 구현 throughput에 더하지 않고 트랙 **시작 제약**으로 반영.
- `projectedCapacity < 잔여/마감주` 면 **capacity-short** → 위험 플래그 + 가시적 overrun(막대를 마감 너머로) 또는 스코프 축소. 무음 압축 금지.
- 트랙당 2–4 페이즈로 분해(완료/진행/대기/지속/통합QA). 빌드 페이즈 길이 = `ceil(스코프/capacity)` 버킷. 불확실분은 `meta`에 `(TBD)`/`추정`. 크로스레포 BE 대기는 muted "도착 대기" 막대 + `(도착분부터)` 배선 막대.

### Step 4 — Risk analysis

`references/risk-analysis.md`의 taxonomy(크로스레포 BE 의존·mock drift·churn·stale spec·denominator 모호·capacity 부족·기술부채·parked 브랜치)로 트랙별 위험을 식별하고 `severity = likelihood × impact`로 정렬한다. 트랙별 `notes`(진척·공수·리스크·회귀주의)에 **구체 산출물(MR/엔드포인트/파일/날짜) 기준**으로 기술하고, 최상위 1–3개는 headline/framing/warn 카드로 끌어올린다. 메타 리스크("마감 = 전기능 완성이 아니라 안정화 체크포인트", BE 종속) 명시.

### Step 5 — Render (cp 템플릿 → 데이터만 Edit)

`references/html-template.md` 절차를 엄수한다:

1. `cp skills/u-reports-roadmap/assets/roadmap-template.html` → `.u-maker/reports/<date>/roadmap-<slug>-<deadline>.html`
2. 복사본의 **두 영역만** 편집: JS `ROADMAP DATA` 블록(`CONFIG`/`UPCOMING`/`DEFAULT_TRACKS`/`DEFAULT_PHASES`/`DEFAULT_DEADLINES`/`DEFAULT_MILESTONES`/`DEFAULT_DETAILS`) + `<!-- GEN:* -->` 마커(title/hero/subtitle/headline/dday-hint/tracks-hint/framing/footer-path).
3. **엔진(`Do not edit below this line` 이하)은 절대 수정 금지.** 날짜는 `CONFIG.startDate`/`deadline`에만 넣고 `buildTimeline()`이 12컬럼·D-day를 파생한다(엔진에 날짜 하드코딩 금지). 트랙 color는 그룹별 hue 패밀리로 배정.

생성 후 검증: FINAL 컬럼이 실제 마감일, snapshot D-day 정확, 모든 트랙 id가 `DEFAULT_PHASES`·`DEFAULT_DETAILS`에 존재.

**쉬운 글쓰기 (HARD RULE):** subtitle·framing·headline·트랙 `notes` 같은 설명 문장은 중학생이 처음 읽어도 이해할 수 있게 쓴다 — 짧은 문장, 쉬운 낱말, 전문용어(velocity·capacity 등)는 첫 등장에서 괄호 한 줄 풀이. 수치·MR·날짜·`(TBD)` 표기는 그대로 둔다. 규칙 원문: `skills/u-engine/references/html-engine.md` § 0.6 / `doc-engine.md` § 8 — GK-06 `plain-language-middle-school` 검사로 강제.

### Step 6 — Sidecar + index + summary

- 사이드카 `roadmap-<slug>-<deadline>.data.json`에 **생성된** state 저장(→ `--rerender`용). 사용자의 브라우저 드래그/편집은 localStorage에만 단방향 저장되며 HTML/사이드카로 write-back 안 됨을 문서화.
- `.u-maker/reports/index.html` + 루트 `.u-maker/index.html` 갱신(html-engine).
- Output summary 출력.

## Output Summary

```
u-reports-roadmap complete.
  Repo shape:  monorepo (4 apps) → 9 tracks (+1 common)
  Window:      2026-06-01 → 2026-08-11 (D-?? · 10 buckets/weekly)
  Team:        devs 3 · planners 1 · designers 1 (git-estimated, user-confirmed)
  Velocity:    ~12 screens/wk observed · focusFactor 0.7
  Top risks:   cross-repo BE dependency (회계·개장묘), mock drift (372 vs 41)
  Report:      .u-maker/reports/2026-06-04/roadmap-myproj-0811.html
  Sidecar:     .u-maker/reports/2026-06-04/roadmap-myproj-0811.data.json
```

## References

- `references/scope-analysis.md` — 코드+git 스코프 신호 taxonomy (grep/git 패턴)
- `references/estimation-model.md` — 측정 속도 anchor + 팀 capacity modulate + 불확실성 표기
- `references/risk-analysis.md` — 위험 taxonomy·스코어링·notes 작성
- `references/html-template.md` — 데이터 스키마 + cp→Edit 절차 + 캘린더 anchoring + 팔레트
- `assets/roadmap-template.html` — 인터랙티브 간트 로드맵 엔진(편집 금지) + 데이터 블록(생성 시 교체)
- `skills/u-engine/references/html-engine.md` — HTML 엔진 공통(인덱스 갱신) 규칙
