# u-report-html 디자인 시스템

Report Writer 에이전트가 HTML 문서를 생성할 때 참조하는 디자인 시스템.

**스타일 SSoT는 이 문서가 아니다.** 색·서체·문단 리듬·플로팅 컨트롤의 규격은
`skills/u-engine/references/html-engine.md` § 0 Document Theme 이 정하고, 그 CSS 구현체가
`_meta/theme/u-doc-theme.css` 다. 이 문서는 그 테마를 **리포트 문서에 어떻게 쓰는지**를 설명한다.

> **원칙 한 줄:** 스타일(색·서체·컴포넌트)은 한 벌로 통일하고, 레이아웃(템플릿)은 문서 성격에 따라 다양하게 간다.

## Design Principles

- **라이트/다크/색각 보정 3모드** — `html` 에 `dark`/`colorblind` 클래스가 붙고, 모든 색은 CSS 변수로 갈린다. 색을 하드코딩하면 다크에서 깨진다.
- **팔레트는 gray + pale blue 두 계열뿐** — 면과 글자는 중립 회색, 강조·링크·하이라이트는 pale steel blue(`--accent:#3d6fa5`). 단계 구분은 hue 가 아니라 **명도(depth ramp)**. 기본 테마의 유채색 예외는 경고 orange `#c2410c`·실패 red `#dc2626` 둘뿐.
- **시스템 서체 스택만** — 웹폰트 CDN(Pretendard/Inter) 금지. 본문 14.5px / line-height 1.8 / letter-spacing -0.005em.
- **3열 레이아웃(기본 템플릿)** — 좌측 **다크 블루** 목차 사이드바(`--sb-bg:#143050` → `--sb-deep:#0e2138`) + 중앙 본문 + 우측 `.glance` 레일. 바쁜 독자는 우측 레일만 봐도 요지를 파악한다.
- **조작 버튼은 사이드바 하단에 임베딩** — 테마·본문 폭·요약 레일·맨 위로 버튼은 본문 위에 떠 있지 않고 사이드바 맨 아래 면에 얹힌 조용한 아이콘 줄(`.sidebar-tools`)로 둔다. 사이드바가 없는 단일 컬럼 템플릿에서만 우하단 `.fab-stack` 을 쓴다.
- **형광펜으로 강조** — 핵심어는 색 글자가 아니라 마커로 그은 자국으로 강조한다. 제목 안 `.highlight`, 섹션 제목 앞 `.qword`, 본문 인라인 `<mark>`.
- **문단 리듬** — `hero` → `meta-bar` → `thesis`(선택) → `section.blk`(`h2 > .qword` + `.section-hint`) → `.note` → `footer`. 섹션 간 54px, 섹션 내부는 12~18px.
- **면 처리** — 컨테이너(`.panel`)는 채움 면 + 테두리 없음, 독립 카드(`.card`/`.feature-card`)는 흰 면 + 미세 그림자. 반복되는 텍스트 행은 카드가 아니라 `.simple-list` 구분선형.
- **한쪽 border 강조 금지 (GK-07)** — `border-left: 4px solid …` 류 accent bar, 제목 컬러 밑줄, active 를 컬러 바로 표시하는 스타일 전면 금지. 강조는 배경 채움 + `font-weight`, 경계가 필요하면 4변 `border`. 허용되는 단면선은 **중립 1px 구분선**(사이드바/헤더/푸터 경계, 표 행 구분), focus outline, 차트·타임라인 데이터 마커뿐.
- **아이콘 = Font Awesome (이모지 금지)** — UI 아이콘은 `<i class="fa-solid fa-…">`, 색은 `currentColor` 상속. **다이어그램은 인라인 SVG** 로 그린다.
- **다이어그램 우선** — 프로세스·흐름·단계·구조·계층·관계처럼 시각화가 효과적인 내용은 텍스트/표 대신 `.flow-diagram` 또는 인라인 SVG.
- **스크롤 추적 + 진행률 바** — 사이드바 활성 항목 자동 전환 + 상단 `.progress-bar`.

## 템플릿 카탈로그

| 템플릿 | 레이아웃 | 인라인 레이어 | 쓰는 경우 |
|---|---|---|---|
| `assets/template-report.html` | 3열 (사이드바 + 본문 + 글랜스) | L0 · L1 · **L2b** · L3 · L4 | 기본값. 섹션 3개 이상 문서 |
| `assets/template-doc.html` | 단일 컬럼 `.doc-container` | L0 · L1 · **L2a** · L3 · L4 | 짧은 메모·부록·인쇄 우선 |

두 템플릿은 **색·서체·컴포넌트 CSS 가 완전히 동일**하고 L2(shell)만 다르다.

### 새 템플릿 추가

1. `_meta/theme/u-doc-theme.css` 에서 **L0(tokens) · L1(base+prose) · L3(components) · L4(chrome)** 를 그대로 인라인 복사한다. 값은 고치지 않는다.
2. **L2(shell)만 새로 짠다** — 컬럼 구성, 고정 패널, 그리드 등 레이아웃은 자유.
3. 컨트롤(테마 순환 · 본문 폭 · 맨 위로)은 반드시 넣는다. **사이드바가 있으면 사이드바 하단에 `.sidebar-tools` 로 임베딩**하고, 없으면 우하단 `.fab-stack` 을 쓴다. 접히는 패널이 있으면 같은 자리에 토글 버튼을 추가한다(`aria-expanded` + `aria-controls`).
4. `<head>` 는 Font Awesome CDN `<link>` 하나만 외부 참조로 둔다.
5. `assets/` 에 `template-{성격}.html` 로 저장하고 SKILL.md 의 템플릿 표에 한 줄 추가한다.

새 색·새 서체·새 문단 클래스를 만들 필요가 생기면 그건 템플릿이 아니라 **테마 변경**이다 — 먼저 html-engine.md § 0 과 `u-doc-theme.css` 를 고치고, 기존 템플릿까지 함께 갱신한다.

## CSS 변수 (요약)

전체 정의는 `_meta/theme/u-doc-theme.css` L0 참조. 자주 쓰는 것만:

```css
--bg --panel --soft --surface        /* 면: 배경 / 채움 컨테이너 / 옅은 면 / 카드 */
--fg --muted --dim --border          /* 글자: 본문 / 보조 / 흐린 / 구분선 */
--accent --accent-strong --accent-soft
--accent-bg --accent-line --hi       /* 강조 면 / 강조 테두리 / 형광펜 */
--ok-bg --ok-fg                      /* 확정·성공 (pale blue 계열) */
--warn-bg --warn-fg                  /* 경고 (orange) */
--bad-bg --bad-fg                    /* 실패 (red) */
--depth-1..5                         /* 계열 구분은 hue 가 아니라 명도 램프로 */
--gray-1..4
--sb-bg --sb-deep --sb-fg --sb-muted --sb-accent --sb-chip   /* 사이드바 */
--content-w --glance-w --radius --shadow
```

`.dark` / `.colorblind` 가 같은 변수 이름을 덮어쓴다. **컴포넌트 CSS 는 변수만 참조**하면 3모드가 자동으로 따라온다.

## 컴포넌트 카탈로그

### 1. 사이드바 (3열 템플릿 필수)

`.layout` > `.sidebar` + `.main-content` + `.glance` 구조. 다크 블루 면, active 는 **배경 채움 + 굵기**로만 표시한다.

```html
<aside class="sidebar">
  <div class="sidebar-header">
    <h2>문서 제목 (짧게)</h2>
    <p>문서 유형 설명</p>
  </div>
  <ul class="sidebar-nav">
    <li><a href="#section1"><span class="nav-icon">01</span><span class="label">섹션 제목</span><span class="sidebar-count">N</span></a></li>
    <li><a href="#section2"><span class="nav-icon">02</span><span class="label">섹션 제목</span></a></li>
  </ul>
  <div class="sidebar-footer">Copyright(c) 2026 U PLEAT</div>
</aside>
```

- `.nav-icon`: `01`, `02` 순차 번호(mono). `.sidebar-count`: 해당 섹션 항목 수(선택, 쓰면 정확해야 함)
- `href` 는 본문 `section.blk` 의 `id` 와 1:1 일치
- 사이드바 맨 아래에는 템플릿이 제공하는 `.sidebar-tools` 아이콘 줄(테마·본문 폭·요약 레일·맨 위로)이 고정으로 붙는다. `{{SIDEBAR}}` 안에 직접 넣지 않는다 — 템플릿 바깥에 이미 있다. 사이드바에는 그만큼 `padding-bottom` 이 잡혀 있어 `.sidebar-footer` 가 가려지지 않는다.

### 2. 우측 글랜스 레일 (3열 템플릿 필수)

본문을 안 읽어도 요지를 파악하는 우측 고정 패널. `{{GLANCE}}` 자리에 넣는다.

```html
<aside class="glance" id="glance">
  <div class="glance-head"><span class="g-dot"></span><span class="glance-title">한눈에 보기</span></div>

  <section class="glance-block">
    <h3><i class="gb-ico fa-solid fa-thumbtack" aria-hidden="true"></i> 핵심 요약</h3>
    <ul class="glance-summary">
      <li>문서 핵심 결론 한 줄</li>
      <li>또 하나의 핵심 한 줄</li>
    </ul>
  </section>

  <section class="glance-block">
    <h3><a href="#section1"><i class="gb-ico fa-solid fa-list-ul" aria-hidden="true"></i> 주요 항목 <span class="gb-count">N</span></a></h3>
    <ul class="glance-list"><li>항목 한 줄</li></ul>
  </section>

  <section class="glance-block">
    <h3><a href="#section2"><i class="gb-ico fa-solid fa-circle-check" aria-hidden="true"></i> 핵심 포인트 <span class="gb-count ok">N</span></a></h3>
    <ul class="glance-list"><li>포인트 한 줄</li></ul>
  </section>
</aside>
```

- **핵심 요약**: 문서 전체를 3~5줄, 각 한 줄(문장이 아니라 요점). **주요 항목/핵심 포인트**: 본문 섹션을 한 줄로 압축, 블록 제목은 해당 섹션 `#id` 앵커
- 블록 구성은 문서 성격에 맞춘다(용어사전=핵심 용어/분류, 가이드=주요 단계/주의점, 리포트=결론/지표). 안 맞는 블록은 생략
- `.gb-count` 는 본문 실제 수와 일치. 색: `.ok` `.warn` `.bad` `.neutral` (기본 중립). 빈 블록은 `<li class="glance-empty">없음</li>`
- 레일은 `#glance-toggle` 로 접기/펼치기(`localStorage.glanceOff`), 1200px 이하·인쇄 시 자동 숨김. 접히면 본문이 전체 폭으로 확장

### 3. 문서 머리 (hero + meta-bar + thesis)

그라데이션 헤더 카드는 쓰지 않는다. hero 는 `1px solid var(--fg)` 아랫줄로 끝난다.

```html
<header class="hero">
  <h1>문서 제목 <span class="highlight">핵심어</span></h1>
  <div class="sub">한 줄 요약 · 작성일 · 출처</div>
</header>

<div class="meta-bar"><span>유형 가이드</span><span>작성 2026-08-06</span><span>v1.0</span></div>

<div class="thesis">
  <span class="k">SUMMARY</span>
  이 문서가 주장하는 <b>한 문장</b>.
</div>
```

`.thesis` 는 선택이지만 리포트·인덱스 성격의 문서에는 권장한다.

**형광펜(highlighter).** 핵심어는 글자 아랫부분만 덮는 마커 자국으로 강조한다. 세 자리에 쓴다:

```html
<h1>문서 제목 <span class="highlight">핵심어</span></h1>          <!-- 제목 -->
<h2><span class="qword">무엇을</span>다루는가</h2>                 <!-- 섹션 제목 -->
<p>본문에서 이 <mark>핵심 키워드</mark>만 눈에 걸리게 한다.</p>     <!-- 본문 인라인 (= .hl) -->
```

한 문단에 하나면 충분하다. 색 글자(`color:accent`)로 강조하지 않는다 — 형광펜이 이 테마의 강조 수단이다.

### 4. 섹션

```html
<section class="blk" id="section1">
  <h2><span class="qword">무엇을</span>다루는가</h2>
  <p class="section-hint">이 섹션이 답하는 질문을 <b>한두 문장</b>으로 먼저 말한다.</p>
  …본문…
  <p class="note">각주·전제·한계</p>
</section>
```

- `id` 는 사이드바/글랜스 앵커와 반드시 일치
- 제목 밑줄(`border-bottom: 2px solid accent`)은 GK-07 위반 — `.qword` 하이라이트 칩으로 대신한다

### 5. 데이터 테이블

```html
<div class="data-table-wrap">
  <table class="data-table">
    <thead><tr><th>컬럼1</th><th>컬럼2</th></tr></thead>
    <tbody>
      <tr><td class="col-term">주요 값</td><td class="col-desc">설명</td></tr>
    </tbody>
  </table>
</div>
```

흰 카드 위에 1px 행 구분선만. 헤더는 옅은 면 + 대문자 라벨(다크 헤더 금지).

| 클래스 | 용도 |
|---|---|
| `.col-term` | 주요 용어/키 (bold) |
| `.col-eng` | 영어 텍스트 (보조색) |
| `.col-abbr` | 약어 (mono + accent) |
| `.col-alias` | 유사어/별칭 (흐린색) |
| `.col-desc` | 설명 (보조색) |
| `.empty` | 값 없음 — `&mdash;` 표시 |

본문 산문 속 일반 표는 `.data-table` 없이 그냥 `<table>` 을 써도 된다(테마가 행 구분선 스타일을 준다).

### 6. 피처 카드

```html
<div class="feature-cards cols-2">
  <div class="feature-card ok">
    <h3><i class="fa-solid fa-lightbulb" aria-hidden="true"></i> 카드 제목</h3>
    <p>설명</p>
  </div>
</div>
```

기본 카드는 흰 면 + 4변 중립 테두리. 색 variant 는 **전체 테두리 색 + 옅은 배경 틴트**로만 표현한다.

| 캐논 | 별칭(구버전 호환) | 의미 |
|---|---|---|
| `.accent` | `.blue` | 강조·기본 |
| `.ok` | `.green` | 확정·성공 (pale blue) |
| `.warn` | `.yellow` | 주의 (orange) |
| `.bad` | `.red` | 실패·위험 |
| `.neutral` | `.purple` | 중립·부가 (gray) |

`.badge-*`, `.gb-count.*`, `.flow-node.*` 도 같은 캐논/별칭 쌍을 쓴다. **새 문서는 캐논 이름을 쓴다.**

### 7. 하이라이트 박스 / 주석

```html
<div class="highlight-box">
  <strong>핵심 포인트:</strong> 강조할 내용
  <ul><li>세부 항목</li></ul>
</div>

<p class="note"><b>참고:</b> 부수적 설명 — 점선 윗줄 아래 작은 글씨</p>
```

`.annotation` 은 `.note` 와 같은 스타일의 별칭이다.

### 8. 뱃지

```html
<span class="badge badge-accent">태그명</span>
<span class="badge badge-ok"><i class="fa-solid fa-check" aria-hidden="true"></i> 완료</span>
```

### 9. 반복 목록 (simple-list / decision-list)

항목마다 카드를 쌓지 않는다. 반복 텍스트 행은 구분선형으로.

```html
<ul class="simple-list simple-list--numbered">
  <li><span><b>과제명:</b> 해야 할 일을 한 문장으로</span></li>
</ul>

<div class="simple-list">
  <div class="simple-list-row is-current">
    <strong class="list-label">M0 팀 잠금</strong>
    <span class="list-detail">담당자와 의사결정권자를 확정</span>
    <time class="list-meta">08-07</time>
  </div>
</div>

<ul class="decision-list">
  <li><span class="decision-check"><i class="fa-solid fa-check" aria-hidden="true"></i></span>
      <div class="decision-body">확정된 내용</div></li>
</ul>
```

현재/중요 행은 `background: var(--accent-bg)` + `font-weight` 만 쓴다(테두리·rounded box 추가 금지).

### 10. 타임라인

```html
<div class="timeline">
  <div class="timeline-item">
    <div class="timestamp">2024-01</div>
    <p>이벤트 설명</p>
  </div>
</div>
```

축선과 점은 데이터 마커라 GK-07 예외로 허용된다.

### 11. 표준/매핑 카드

```html
<div class="standard-card">
  <div class="standard-card-header"><h3>카드 제목</h3></div>
  <div class="standard-list">
    <div class="standard-item">
      <span class="standard-term">기준 용어</span>
      <span class="standard-arrow">&rarr;</span>
      <div class="standard-aliases"><span class="alias-tag">대체 용어1</span></div>
    </div>
  </div>
</div>
```

### 12. 다이어그램

외부 라이브러리 없이 **CSS flow 또는 인라인 SVG** 로만 만든다. `.diagram` 컨테이너로 감싸고 필요하면 `.diagram-caption` 을 단다.

**12-1. Flow 다이어그램** — 순서가 있는 단계.

```html
<div class="diagram">
  <div class="flow-diagram">
    <div class="flow-node">입력<span class="flow-sub">원본 데이터</span></div>
    <span class="flow-arrow">&rarr;</span>
    <div class="flow-node accent">처리<span class="flow-sub">변환·검증</span></div>
    <span class="flow-arrow">&rarr;</span>
    <div class="flow-node ok">출력<span class="flow-sub">HTML 리포트</span></div>
  </div>
  <div class="diagram-caption">그림 1. 문서 생성 파이프라인</div>
</div>
```

단계가 많거나 화면이 좁으면 `.flow-diagram.vertical` + `&darr;`.

**12-2. 인라인 SVG** — 구조·계층·관계·아키텍처·순환.

```html
<div class="diagram">
  <svg viewBox="0 0 400 200" role="img" aria-label="계층 구조도">
    <defs><marker id="ah" markerWidth="10" markerHeight="7" refX="10" refY="3.5" orient="auto">
      <polygon points="0 0, 10 3.5, 0 7" class="svg-marker"/></marker></defs>
    <rect x="150" y="16" width="100" height="44" rx="8" class="svg-accent-bg svg-stroke-accent"/>
    <text x="200" y="42" text-anchor="middle" font-size="13" font-weight="700" class="svg-ink">상위</text>
    <path d="M200,60 C200,75 110,75 110,120" class="svg-line" marker-end="url(#ah)"/>
    <path d="M200,60 C200,75 290,75 290,120" class="svg-line" marker-end="url(#ah)"/>
    <rect x="60" y="120" width="100" height="44" rx="8" class="svg-surface svg-border"/>
    <text x="110" y="146" text-anchor="middle" font-size="13" class="svg-ink">하위 A</text>
    <rect x="240" y="120" width="100" height="44" rx="8" class="svg-surface svg-border"/>
    <text x="290" y="146" text-anchor="middle" font-size="13" class="svg-ink">하위 B</text>
  </svg>
  <div class="diagram-caption">그림 2. 구성 계층</div>
</div>
```

**SVG 작성 규칙:**

- `viewBox` 필수, `width/height` 는 생략(반응형). `.diagram svg` 가 `max-width:100%` 로 스케일한다.
- **연결선은 곡선 커넥터(`<path>` + Bezier)** 를 쓴다. 직선 `<line>` 은 쓰지 않는다. 화살촉은 `<defs><marker>` 재사용.
- **색은 하드코딩 hex 가 아니라 테마 SVG 클래스로 지정한다.** 인라인 SVG 는 문서 CSS 를 그대로 받으므로, 아래 클래스를 쓰면 라이트/다크/색각 3모드에 자동으로 따라온다. `fill="#111827"` 같은 하드코딩은 다크 모드에서 배경에 묻혀 사라진다.

  | 클래스 | 대상 | 값 |
  |---|---|---|
  | `.svg-ink` / `.svg-muted` | 텍스트 | `--fg` / `--muted` |
  | `.svg-surface` / `.svg-panel` | 박스 면 | `--surface` / `--panel` |
  | `.svg-accent-bg` / `.svg-accent` | 강조 면 / 강조 채움 | `--accent-bg` / `--accent` |
  | `.svg-border` / `.svg-line` | 박스 테두리 / 커넥터 (stroke, `fill:none`) | `--border` / `--gray-2` |
  | `.svg-stroke-accent` | 강조 테두리 (stroke, `fill:none`) | `--accent` |
  | `.svg-marker` | 화살촉 `<polygon>` | `--gray-2` |
  | `.svg-warn` / `.svg-bad` | 경고 / 실패 | `--warn-fg` / `--bad-fg` |

- 계열을 더 나눠야 하면 hue 를 늘리지 말고 명도 램프 hex 를 직접 쓴다: `#2c5580` → `#3d6fa5` → `#5b8db8` → `#8fb3d0` → `#b8cee4`. (이 경우 다크에서도 읽히도록 `.svg-surface` 면 위에 올린다.)
- 접근성: `role="img"` + `aria-label`(또는 `<title>`). 텍스트가 잘리지 않게 박스 크기를 넉넉히.
- ASCII art 금지(폴더 트리 제외).

## 컴포넌트 선택 가이드

| 내용 유형 | 추천 컴포넌트 |
|---|---|
| 테이블형 데이터 (용어, 목록) | `.data-table` |
| 카드형 설명 (기능, 주제별) | `.feature-card` |
| 강조 정보, 핵심 규칙 | `.highlight-box` |
| 반복되는 텍스트 행 (출처·액션·마일스톤) | `.simple-list` |
| 체크리스트, 확정 사항 | `.decision-list` |
| 시간순 연혁/이력 | `.timeline` |
| 프로세스·처리 흐름·단계 | `.flow-diagram` |
| 구조·계층·관계·아키텍처·순환 | 인라인 SVG |
| 매핑/규칙/변환 | `.standard-card` |
| 부수적 배경 설명 | `.note` / `.annotation` |

> **다이어그램 판단 기준:** "A → B → C", "~로 구성된다", 상·하위 관계, 순환/피드백 루프처럼 **관계·순서·구조**가 핵심이면 문장/표보다 다이어그램이 낫다.

## 필수 JavaScript

템플릿 하단 스크립트를 **그대로** 포함한다:

1. **테마 순환** — `light → dark → colorblind`, `localStorage.theme` 복원, 아이콘 + `aria-label`/`title` 동기화
2. **본문 폭** — `--content-w` 를 1080 → 1440 → 1920 순환, `localStorage.docWidth`
3. **글랜스 레일 토글**(3열 템플릿) — `body.glance-off`, `localStorage.glanceOff`, 버튼의 `aria-expanded` 갱신(`aria-controls="glance"` → `<aside class="glance" id="glance">`)
4. **맨 위로** — `window.scrollTo({top:0,behavior:REDUCED_MOTION?'auto':'smooth'})`
5. **읽기 진행률** — `#progressBar`
6. **사이드바 활성 추적** — `.blk[id]` / `.section-divider[id]` 스캔 후 `.sidebar-nav a.active` 전환

버튼 id 는 `#theme-toggle` · `#width-toggle` · `#glance-toggle` · `#to-top` 로 고정이다. 3열 템플릿에서는 이 넷이 `.sidebar-tools` 안에, 단일 컬럼 템플릿에서는 `.fab-stack` 안에 있다.

**인쇄**: `@media print` 에서 좌 사이드바·우 글랜스 레일·컨트롤·진행률 바를 모두 감추고 본문만 전체 폭으로 남긴다. 카드·표·다이어그램에는 `page-break-inside:avoid` 를 준다.
**모션 감축**: `@media (prefers-reduced-motion: reduce)` 에서 `scroll-behavior:auto` + 전환 애니메이션을 끈다.

## 파일 저장 규칙

- 입력 소스와 **같은 디렉토리**에 `.html` 로 저장, 파일명은 소스명 유지
- 단일 HTML 파일(외부 CSS/JS 참조 없음). **예외는 Font Awesome CDN `<link>` 하나뿐** — 웹폰트 CDN 은 금지
- CSS 는 선택한 템플릿에서 전체 복사해 `<style>` 에 인라인
