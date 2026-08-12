# html-engine Reference

The html-engine converts SSoT markdown documents into polished, self-contained HTML pages. It handles markdown parsing, inline SVG diagram generation (primary), Mermaid fallback for UML diagrams, base64 image embedding, Tailwind CSS styling, Font Awesome icon fonts, light/dark/color-vision-accessible theme switching, sidebar navigation, and Table of Contents generation. **SVG is the preferred diagram format** — self-contained, offline-capable, instantly rendered without CDN dependencies.

## 0. Document Theme (SSoT) — 서체 · 색 · 문단 구조

모든 HTML 산출물(문서·인덱스·리포트·와이어프레임·디자인시스템·로드맵·`/u-report-html` 문서)은 아래 테마를 **공통 기준**으로 삼는다.
엔진이 새로 만드는 HTML도 같은 토큰·타이포·문단 구조를 쓴다. 이 절을 고칠 일이 생기면 아래 구현체를 **함께** 고친다.

**스타일은 한 벌, 템플릿은 여럿.** 색·서체·문단 리듬·플로팅 컨트롤은 이 절이 정하고, 레이아웃은 문서 성격에 따라 달라도 된다.

| 구현체 | 역할 |
|---|---|
| `_meta/theme/u-doc-theme.css` | **공통 테마 CSS 원본.** 템플릿이 여기서 인라인 복사한다. 레이어: `L0` tokens · `L1` base+prose · `L2a` 단일 컬럼 shell · `L2b` 3열 리포트 shell · `L3` components · `L4` chrome |
| `_meta/templates/*.html` (9종) | 엔진이 쓰는 문서·인덱스·리포트·디자인시스템 템플릿 |
| `skills/u-report-html/assets/template-report.html` | 3열 리포트(좌 목차 + 본문 + 우 글랜스 레일) |
| `skills/u-report-html/assets/template-doc.html` | 단일 컬럼 문서 |
| `skills/u-wireframe/references/wireframe-*.template.html` | 와이어프레임(상단 sticky header 예외) |
| `skills/u-reports-roadmap/assets/roadmap-template.html` | 간트 로드맵 |

새 템플릿을 만들 때는 `L0`·`L1`·`L4` 를 값 그대로 인라인하고 `L2`(shell)만 새로 짠다.
새 색·새 서체·새 문단 클래스가 필요해지면 그건 템플릿이 아니라 **테마 변경**이므로 이 절과 `u-doc-theme.css`, 기존 템플릿을 함께 갱신한다.

### 0.1 Color tokens — gray + pale blue default + colorblind override (HARD RULE)

**전체 색 테마는 회색(gray)과 연한 파랑(pale blue) 두 계열뿐이다.**
연두(lime)·노랑(yellow/amber)은 물론 **teal·violet·pink·cyan 같은 유채색 계열도 쓰지 않는다.**
면과 글자는 중립 회색, 강조·링크·하이라이트는 pale blue, 단계 구분은 **색상(hue)이 아니라 명도(depth)** 로 한다.
(기존 `#D7FF5A` lime, `#f59e0b` amber, `#10b981`·`#22c55e` green, `#0d9488` teal, `#7c3aed` violet,
`#db2777` pink, `#2563eb` vivid blue 는 모두 폐기)

기본 라이트/다크 테마의 예외는 **상태 두 가지뿐이다** — 경고 orange `#c2410c`, 실패 red `#dc2626`. 배지·경고문에만 최소로 쓴다.
`colorblind` 테마는 색각 다양성 대응을 위한 명시적 예외이며, 아래의 고대비 blue/orange/magenta 조합만 허용한다. 상태 텍스트·아이콘·레이블은 제거하지 않는다.

```css
:root{
  /* surface — neutral gray */
  --bg:#fff;--panel:#f2f5f8;--soft:#f8fafc;--surface:#fff;
  --fg:#111827;--muted:#4b5563;--dim:#6b7280;--border:#e2e8f0;
  /* accent — pale steel blue */
  --accent:#3d6fa5;--accent-strong:#2c5580;--accent-soft:#a8c4e0;
  --accent-bg:#eef3f9;--accent-line:#b8cee4;--hi:#dbe7f5;   /* --hi = 형광펜 하이라이트 */
  /* status */
  --ok-bg:#eef3f9;--ok-fg:#2c5580;--bad-bg:#f9f0ef;--bad-fg:#b91c1c;
  --warn-bg:#f7f0ea;--warn-fg:#c2410c;
  /* PBGD phase */
  --plan:#2c5580;--build:#3d6fa5;--gate:#64748b;--deploy:#334155;
  --shadow:0 1px 2px rgba(17,17,17,.05);
  --content-w:1080px;
}
.dark{
  --bg:#0f1319;--panel:#161c24;--soft:#131920;--surface:#131920;
  --fg:#e6edf3;--muted:#9aa7b6;--dim:#7d8998;--border:#242c37;
  --accent:#8ab4e0;--accent-strong:#a8c4e0;--accent-soft:#a8c4e0;
  --accent-bg:#172230;--accent-line:#2c435c;--hi:#20344c;
  --ok-bg:#172230;--ok-fg:#a8c4e0;--bad-bg:#261a18;--bad-fg:#fca5a5;
  --warn-bg:#26201a;--warn-fg:#d9b48c;
  --plan:#6d9dcb;--build:#8ab4e0;--gate:#94a3b8;--deploy:#cbd5e1;
  --shadow:0 1px 2px rgba(0,0,0,.45);
}
.colorblind{
  color-scheme:light;
  --bg:#fff;--panel:#f1f5f7;--soft:#f7fafb;--surface:#fff;
  --fg:#1a1a1a;--muted:#3f4a54;--dim:#56616a;--border:#7c8993;
  --accent:#0072b2;--accent-strong:#005a8d;--accent-soft:#56b4e9;
  --accent-bg:#e6f3f8;--accent-line:#56b4e9;--hi:#d7eef7;
  --ok-bg:#e6f3f8;--ok-fg:#005a8d;--bad-bg:#fff0e8;--bad-fg:#9f4500;
  --warn-bg:#fff4d6;--warn-fg:#704700;
  --plan:#0072b2;--build:#8a5700;--gate:#8f4a80;--deploy:#1a1a1a;
  --shadow:0 1px 3px rgba(26,26,26,.12);
}
.colorblind :focus-visible{outline:3px solid #8a5700;outline-offset:3px}
```

사이드바(문서 목차·앱 내비게이션)는 **다크 블루** 면을 쓴다: 위 `--sb-bg:#143050`에서 아래 `--sb-deep:#0e2138`로 이어지는 미세한 세로 gradient다(다크 테마는 `#0f2337` → `#091724`).
텍스트는 `--sb-fg:#f8fafc`, `--sb-muted:#c6d0df`, `--sb-dim:#8fa0b8`, accent는 `--sb-accent:#a8c4e0`을 사용한다. 구분선은 `rgba(168,196,224,.14)`.
hover는 `rgba(168,196,224,.08)`, active는 `rgba(168,196,224,.16)` 면 채움 + 굵기로만 표시한다(단면 border 금지). 번호·카운트 칩은 흰 배경을 금지하고 `rgba(168,196,224,.12)` 면 + `#a8c4e0` 텍스트를 쓴다.

| 의미 | 색 | 이름 | 쓰는 곳 |
|---|---|---|---|
| Accent / 링크 | `#3d6fa5` | steel blue | 링크, 기본 강조, 아이콘 |
| Highlight(형광펜) | `#dbe7f5` | pale blue | `h1`·`h2` 안의 키워드, `.qword` 칩 |
| Plan | `#2c5580` | deep steel | Plan phase, 1단계 |
| Build / Design / 성공 | `#3d6fa5` | steel blue | Design phase, pass 배지 |
| Gatekeeping / Check | `#64748b` | slate | Check phase, gate 리포트 |
| Deploy / Loop | `#334155` | charcoal | Deploy phase, loop 리포트 |
| 경고 | `#c2410c` | orange | 재작업 필요, 80~94점 |
| 실패 | `#dc2626` (채움) / `#b91c1c` (글자) | red | 차단, 80점 미만 |

단계·계열을 더 나눠야 하면 hue를 늘리지 말고 아래 **명도 램프**에서 고른다(차트 계열도 동일):

`#2c5580` → `#3d6fa5` → `#5b8db8` → `#8fb3d0` → `#b8cee4` (blue) · `#334155` → `#64748b` → `#94a3b8` → `#cbd5e1` (gray)

### 0.2 Typography

```css
body{
  font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,
              "Apple SD Gothic Neo","Malgun Gothic","Noto Sans KR",sans-serif;
  font-size:14.5px; line-height:1.8; letter-spacing:-0.005em;
  -webkit-font-smoothing:antialiased; color:var(--fg);
}
```

| 요소 | 크기 / 굵기 | 비고 |
|---|---|---|
| `h1` | 27px / 700 / `letter-spacing:-0.5px` / `line-height:1.35` | 문서 제목. hero 안에 둔다 |
| `h2` | 17px / 700 | 섹션 제목. 앞에 `.qword` 형광펜 칩 |
| `h3` | 14.5px / 800 | 하위 제목 |
| `h4` | 13px / 700 | 카드·표 내부 제목 |
| 본문 `p` | 14.5px / 1.8 | 기본 |
| 보조 설명 | 13.5px / 1.85 (`.section-hint`) | 섹션 리드 문단 |
| 캡션·메타·범례 | 11.5~12px / 1.7 | `figcaption`, `.note`, 배지 |
| 표 | 12.5px / 1.7 | |
| mono | `ui-monospace,'JetBrains Mono','Fira Code',monospace` | ID·경로·코드 |

Inter / Pretendard 등 웹폰트 CDN은 쓰지 않는다 — **시스템 서체 스택만** 쓴다(오프라인에서도 동일하게 보인다).

**형광펜(highlighter).** 핵심어는 색 글자가 아니라 **형광펜으로 그은 자국**으로 강조한다 — 글자 아랫부분 62%만 `--hi` 로 덮는
`linear-gradient(to top,var(--hi) 0,var(--hi) 62%,transparent 62%)` 이며, 줄바꿈에서도 끊기지 않도록 `box-decoration-break:clone` 을 준다.
쓰는 자리는 세 곳이다 — **제목(h1)** 안의 핵심어 `.highlight`, **섹션 제목(h2)** 앞의 `.qword`, **본문** 안의 인라인 키워드 `<mark>`(= `.hl`).
한 문단에 형광펜은 하나면 충분하다. 남용하면 강조가 죽는다.

### 0.3 문단 구조 (Prose rhythm)

문서는 아래 순서와 클래스를 그대로 따른다.

```html
<div class="doc-container">        <!-- max-width:var(--content-w); padding:36px 24px 110px -->

  <header class="hero">            <!-- border-bottom:1px solid var(--fg); pb:20px; mb:28px -->
    <h1>문서 제목 <span class="highlight">핵심어</span></h1>
    <div class="sub">한 줄 요약 · 메타 (13px / 1.9 / --muted)</div>
  </header>

  <div class="meta-bar"><span>App</span><span>Status</span><span>v1.0</span></div>

  <div class="thesis">             <!-- 짙은 면(--fg) 위 흰 글씨, radius 14px, 16px/2.0 -->
    <span class="k">KICKER</span>  <!-- 11.5px, uppercase, letter-spacing 1.2px -->
    이 문서가 주장하는 <b>한 문장</b>.   <!-- b = var(--accent-soft) -->
  </div>

  <nav class="toc">…</nav>          <!-- --panel 면, radius 14px -->

  <section class="blk">            <!-- margin-bottom:54px -->
    <h2><span class="qword">무엇을</span>다루는가</h2>
    <p class="section-hint">섹션이 답하는 질문을 <b>한두 문장</b>으로 먼저 말한다.</p>
    <div class="panel">…</div>      <!-- 컨테이너: --panel 면, border 없음 -->
    <p class="note">각주·전제·한계는 점선 윗줄 아래에.</p>
  </section>

  <div class="footer">Copyright(c) 2026 U PLEAT</div>
</div>
```

규칙:

1. **hero** — 모든 페이지는 `h1` + `.sub` + `1px solid var(--fg)` 아랫줄로 시작한다.
2. **thesis** — 문서/섹션의 결론을 짙은 면 블록으로 먼저 보여 준다(선택이지만 index·리포트에는 권장).
3. **section-hint** — `h2` 바로 뒤에 그 섹션이 답하는 질문을 서술한다. 본문으로 바로 들어가지 않는다.
4. **section 간격 54px** — 섹션 사이는 넉넉히 띄우고, 섹션 내부 요소는 12~18px로 촘촘히 둔다.
5. **면 처리(surface)** — 컨테이너(`.panel`)는 `--panel` 채움 + `border:none`, 그 안의 독립 카드(`.card`)는
   흰 면 + `box-shadow:0 1px 2px rgba(17,17,17,.05)`. 요약 지표·차트·독립 탐색 항목처럼 하나의 객체인 경우에만 카드를 쓴다.
6. **반복 목록** — 출처·파일·액션·권고·체크포인트·마일스톤·변경사항처럼 텍스트 행이 반복되면 `.simple-list`를 쓴다. 항목별 배경·4변 border·radius·shadow·gap을 제거하고 `border-bottom:1px solid var(--border)` 구분선만 둔다.
7. **표** — 4변 테두리 없이 `border-bottom:1px solid var(--border)` 행 구분선만 쓴다.
8. **각주/전제** — `.note`, `.flowfoot` 은 `border-top:1px dashed var(--border)` 위에 11.5~12px로 적는다.
9. **footer** — `1px solid var(--border)` 윗줄 + 12px/1.95 중립 텍스트.
10. **한쪽 border 강조 금지** — § 6 Border / Accent Style Rules (GK-07) 를 그대로 따른다.

### 0.3.1 Simple repeated lists

목록 항목 하나마다 bordered rounded box를 만들지 않는다. 기본형·번호형·3열형 모두 같은 행 구분선 문법을 사용한다.

```html
<ul class="simple-list simple-list--numbered">
  <li><span><b>과제명:</b> 해야 할 일을 한 문장으로 쓴다.</span></li>
</ul>

<div class="simple-list">
  <div class="simple-list-row is-current">
    <strong class="list-label">M0 팀 잠금</strong>
    <span class="list-detail">담당자와 의사결정권자를 확정</span>
    <time class="list-meta">08-07</time>
  </div>
</div>
```

```css
.simple-list{list-style:none;margin:10px 0 16px;padding:0}
.simple-list>li,.simple-list-row{margin:0;padding:12px 8px;border:0;border-bottom:1px solid var(--border);border-radius:0;background:transparent;box-shadow:none}
.simple-list>li:last-child,.simple-list-row:last-child{border-bottom:0}
.simple-list>.is-current{background:var(--accent-bg);font-weight:700}
```

- 번호는 작은 mono 텍스트나 CSS counter로 표시한다. 번호 자체에 배경·border를 추가하지 않는다.
- 현재/중요 행은 `background:var(--accent-bg)` + `font-weight`만 사용한다. 별도 테두리나 rounded box를 만들지 않는다.
- 링크·`code`·상태 배지는 행 안의 인라인 요소로 유지할 수 있다.
- 카드가 허용되는 경우: 요약 KPI, 차트, 독립 탐색 타일, 접기/펼치기처럼 항목 자체가 상호작용 컨테이너인 경우.

### 0.4 Controls (테마 · 본문 폭 · 맨 위로)

조작 버튼의 자리는 **페이지에 사이드바가 있느냐**로 갈린다.

| 페이지 | 자리 | 클래스 |
|---|---|---|
| **좌측 사이드바가 있는 페이지** (3열 리포트, split 문서, app index) | 사이드바 **하단에 임베딩**한다 — 본문 위에 떠 있지 않고 사이드바 면에 얹힌 조용한 아이콘 줄 | `.sidebar-tools` > `.sb-tool` (`position:fixed; left:0; bottom:0; width:var(--sb-w)`) |
| **사이드바가 없는 페이지** (단일 컬럼 문서·리포트) | 우하단 알약 스택 | `.fab-stack` > `.fab` (`right:22px; bottom:26px`) |

임베딩할 때 사이드바에는 컨트롤 줄 높이만큼 `padding-bottom:51px` 을 줘서 `.sidebar-footer` 가 가려지지 않게 한다.
버튼은 아이콘만 두고 `aria-label` + `title` 로 이름을 준다(눈에 띄지 않게). 900px 이하에서 사이드바가 사라지면 같은 줄이 우하단 알약 그룹으로 떨어진다.
접기/펼치기 버튼(요약 레일 등)에는 `aria-expanded` + `aria-controls` 를 붙이고 상태에 따라 갱신한다.

아래 표는 두 자리에 공통으로 적용된다.

| 버튼 | 동작 | 스타일 |
|---|---|---|
| 라이트/다크/색각 보정 모드 | `html.dark` / `html.colorblind` 순환 + `localStorage.theme` | 사이드바: `--sb-chip` 아이콘 칩 · 플로팅: 흰 알약 |
| 본문 폭 | `--content-w` 를 1080 → 1440 → 1920 순환, `localStorage.docWidth` | 위와 동일 |
| 맨 위로 | `window.scrollTo({top:0,behavior:…})` — `prefers-reduced-motion` 이면 `'auto'` | 사이드바: 같은 칩 · 플로팅: 46px 원형 `--accent` |

**세 버튼은 스크롤되는 모든 문서 페이지에 반드시 함께 넣는다** — 문서·split 문서·index·root index·reports index·
daily/weekly 리포트·디자인시스템. 예외는 둘뿐이다:
`output/{app}/index.html` 처럼 `body{overflow:hidden}` 인 고정 셸은 테마 순환 버튼만 두고(본문 폭·맨 위로가 동작할 스크롤 영역이 없다),
와이어프레임은 앱 화면 자체를 흉내 내는 목업이므로 상단 sticky `doc-header` 를 쓴다.
폭 값은 페이지 성격에 맞춘다 — 문서/인덱스 `1080 → 1440 → 1920`, 리포트 `960 → 1280 → 1600`, 디자인시스템 `1280 → 1600 → 1920`.
요약 패널을 접는 페이지라면 같은 줄에 "요약 숨김/보임" 버튼을 추가한다.
**인쇄 시에는 좌·우 사이드바와 컨트롤을 모두 감춘다** — `.sidebar,.glance,.sidebar-tools,.fab-stack,.progress-bar{display:none !important}` 로 본문만 전체 폭으로 남긴다.

### 0.5 우측 글랜스 레일 (`.glance`) — 선택 컴포넌트

읽는 사람이 본문을 다 읽지 않아도 요지를 파악하도록, 본문 오른쪽에 고정 요약 패널을 둘 수 있다.
`/u-report-html` 의 3열 템플릿이 기본으로 쓰고, 엔진 산출물 중 **분량이 길고 결론이 중요한 페이지**(split index, 리포트)에도 붙일 수 있다.
CSS 는 `u-doc-theme.css` `L2b` 에 있다.

```html
<aside class="glance">
  <div class="glance-head"><span class="g-dot"></span><span class="glance-title">한눈에 보기</span></div>

  <section class="glance-block">
    <h3><i class="gb-ico fa-solid fa-thumbtack" aria-hidden="true"></i> 핵심 요약</h3>
    <ul class="glance-summary"><li>문서 핵심 결론 한 줄</li></ul>
  </section>

  <section class="glance-block">
    <h3><a href="#s1"><i class="gb-ico fa-solid fa-list-ul" aria-hidden="true"></i> 주요 항목 <span class="gb-count">N</span></a></h3>
    <ul class="glance-list"><li>항목 한 줄</li></ul>
  </section>
</aside>
```

규칙:

1. **핵심 요약은 3~5줄**, 각 줄은 문장이 아니라 요점. 블록 제목은 본문 섹션 `#id` 앵커로 건다.
2. `.gb-count` 는 본문 실제 개수와 일치해야 한다. 색은 `.ok` `.warn` `.bad` `.neutral` 네 가지(기본 중립). 빈 블록은 `<li class="glance-empty">없음</li>`.
3. 아이콘은 Font Awesome `fa-solid`(`.gb-ico`). 이모지 금지.
4. `.fab-stack` 에 `#glance-toggle` 을 추가하고 `body.glance-off` 로 접는다(`localStorage.glanceOff`). 접히면 본문이 전체 폭으로 확장된다.
5. 1200px 이하와 인쇄 시 자동으로 숨긴다. 레일 왼쪽 경계선은 **중립 1px** 만 쓴다(accent 단면 금지 — § 6 GK-07).

### 0.6 쉬운 글쓰기 (Plain Language) — 중학생 이해 수준 (HARD RULE · 게이트 검사)

**모든 산출물의 설명 문장은 중학생이 처음 읽어도 이해할 수 있게 쓴다.**
**규칙 원문(SSoT)은 `doc-engine.md` § 8** 이다 — 여섯 규칙 전문, 낱말 바꿔 쓰기 표, 용어 풀이 예시,
"글이 어렵다는 신호" 체크리스트가 모두 거기에 있다. 이 절은 **HTML 쪽 적용 범위**만 정한다.

적용 범위: 모든 HTML 산출물(문서·인덱스·리포트·와이어프레임·회의록·로드맵·디자인시스템)의
본문 문단 · `.sub` · `.thesis` · `.section-hint` · 표 셀 · 다이어그램 라벨 · 어노테이션 · 글랜스 요약.

여섯 규칙 요약(원문은 doc-engine.md § 8):
① 짧은 문장(한 문장 한 내용, 약 50자) ② 쉬운 낱말 먼저 ③ 전문용어·약어는 첫 등장에서 괄호 한 줄 풀이
④ 추상 개념에 비유·생활 예시 한 줄 ⑤ ID·코드·스키마·수치는 그대로 — 상세함(GK-01)은 유지, 표현만 쉽게
⑥ "중학생이 이 문단만 읽고 무엇을 왜 하는지 말할 수 있나" 자기 검사.

**Gatekeeping GK-06(Content Composition)의 `plain-language-middle-school` 체크로 강제**된다 — 위반 시 감점.
`/u-report-html` · `/u-meeting-note` 의 품질 루프 채점 기준에도 같은 항목이 들어 있다.

## 1. MD to HTML Conversion Pipeline

The full conversion pipeline processes a single `.md` document into a standalone `.html` file:

```
Step 1: Read .md source
Step 2: Parse YAML frontmatter → extract metadata
Step 3: Resolve --diagram mode (svg | mermaid | all; default: svg)
Step 4: Convert markdown body → HTML fragments
Step 5: Generate diagrams per mode:
        svg     → all diagrams as inline SVG from .json data
        mermaid → all diagrams as <pre class="mermaid"> blocks
        all     → SVG primary + Mermaid for UML (erDiagram, classDiagram, sequenceDiagram)
Step 6: Scan for image references → encode as base64
Step 7: Generate Table of Contents from headings
Step 8: Apply output-page.template.html wrapper
Step 9: Inject light/dark/colorblind theme switch, Tailwind; load Mermaid CDN only if mode=mermaid|all
Step 10: Write to output/{app}/{phase}/{docName}.html
Step 11: Update output/{app}/index.html sidebar navigation
Step 12: Update root index files (output/index.html, reports/index.html, index.html)
```

### Input / Output Paths

| Input | Output | Mode |
|-------|--------|------|
| `docs/{app}/plan/srs.md` | `output/{app}/plan/srs/index.html` + `srs/{fr-slug}.html` | **Split** |
| `docs/{app}/plan/ia.md` | `output/{app}/plan/ia.html` | Single |
| `docs/{app}/design/erd.md` | `output/{app}/design/erd/index.html` + `erd/{domain-slug}.html` | **Split** |
| `docs/{app}/design/api.md` | `output/{app}/design/api/index.html` + `api/{group-slug}.html` | **Split** |
| `docs/{app}/design/screens.md` | `output/{app}/design/screens/index.html` + `screens/{group-slug}.html` | **Split** |
| `docs/{app}/design/design-system.md` | `output/{app}/design/design-system.html` | **HTML-first** (see below) |
| `docs/{app}/gatekeeping/testcases.md` | `output/{app}/gatekeeping/testcases/index.html` + `testcases/{group-slug}.html` | **Split** |
| `docs/{app}/gatekeeping/test-results.md` | `output/{app}/gatekeeping/test-results.html` | Single |

See § 12 "Domain Split Pipeline" for split mode details.

### Markdown Conversion Rules

- **Headings** (`# H1` through `###### H6`): Convert to `<h1>` through `<h6>` with auto-generated `id` attributes for TOC anchoring. The `id` is derived from the heading text: lowercase, spaces replaced with hyphens, special characters removed.
- **Tables**: Convert to `<table>` with Tailwind classes: `class="w-full border-collapse text-sm"`. Header row uses `<thead>` with `class="bg-gray-100 dark:bg-gray-800"`. Body rows alternate with `even:bg-gray-50 dark:even:bg-gray-900`.
- **Code blocks**: Wrap in `<pre><code>` with `class="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 overflow-x-auto text-sm font-mono"`. Language-specific syntax highlighting via class `language-{lang}`.
- **Lists**: Convert `- item` to `<ul>` and `1. item` to `<ol>`. 일반 bullet은 기본 들여쓰기만 쓰고 항목별 background/border/radius/shadow를 추가하지 않는다. 출처·액션·마일스톤처럼 구조화된 반복 행은 § 0.3.1 `.simple-list`를 쓴다.
- **Bold / Italic**: `**bold**` → `<strong>`, `*italic*` → `<em>`.
- **Links**: `[text](url)` → `<a href="url" class="text-blue-600 dark:text-blue-400 underline">text</a>`.

## 2. Mandatory Diagram Requirements

Every HTML document MUST include diagrams appropriate to its document type. Diagrams are not optional — they are a core part of the HTML output that distinguishes it from the raw markdown. When converting `.md` to `.html`, the engine MUST ensure the following diagrams exist. Generate them from the companion `.json` data if not present in source `.md`.

### Diagram Rendering Mode (`--diagram`)

The `--diagram` parameter controls how all diagrams are rendered. Defaults to `svg`.

| Mode | Behavior | Mermaid CDN |
|------|----------|-------------|
| **`svg`** (default) | **All** diagrams as inline SVG — including ERD, class, sequence | Not loaded |
| `mermaid` | **All** diagrams via Mermaid CDN (always `theme: 'default'` light) | Loaded |
| `all` | SVG primary + Mermaid fallback for UML (`erDiagram`, `classDiagram`, `sequenceDiagram`) | Loaded |

When `--diagram svg` (default):
- ERD entity-relationship → SVG with entity boxes, curved connectors, cardinality labels
- Class diagrams → SVG with class boxes, method lists, inheritance/composition arrows
- Sequence diagrams → SVG with lifelines, arrows, activation bars
- All other diagrams → SVG (same as before)

When `--diagram mermaid`:
- All diagrams rendered as Mermaid code blocks (`<pre class="mermaid">`)
- Mermaid CDN loaded with `theme: 'default'` (always light mode)
- Wrapped in `.mermaid-wrapper` (white background)

When `--diagram all`:
- Non-UML diagrams → inline SVG (flowcharts, trees, charts, matrices)
- UML diagrams → Mermaid (`erDiagram`, `classDiagram`, `sequenceDiagram`)

### Diagram Requirements per Document

The "Default" column shows the rendering engine when `--diagram svg` (default). With `--diagram mermaid`, all become Mermaid. With `--diagram all`, the "Fallback" column shows the alternative.

| Document | Required Diagrams | Default (svg) | Fallback (all) |
|----------|-------------------|---------------|----------------|
| **SRS** | FR→US→FT traceability tree | SVG | SVG |
| **SRS** | MoSCoW priority distribution (donut/bar chart) | SVG | SVG |
| **SRS** | Stakeholder-FR responsibility matrix | SVG | SVG |
| **IA** | Site map hierarchy | SVG | SVG |
| **IA** | User flows (per major US) | SVG | SVG |
| **IA** | Navigation structure | SVG | SVG |
| **ERD** | Full entity-relationship diagram (entity boxes + curved connectors + cardinality) | SVG | Mermaid `erDiagram` |
| **ERD** | Entity grouping by domain | SVG | SVG |
| **ERD** | Relationship description cards (per relationship — from/to, type, FK, prose description) | SVG | SVG |
| **ERD** | Sample data tables per entity (3~5 records with FK highlight) | HTML | HTML |
| **ERD** | Sample data relation diagram (record cards + FK curved connectors + scenario) | SVG | SVG |
| **API** | Data model class diagram | SVG | Mermaid `classDiagram` |
| **API** | Request/response sequence per endpoint group | SVG | Mermaid `sequenceDiagram` |
| **API** | Endpoint-to-FR traceability | SVG | SVG |
| **Screens** | Screen flow / navigation map (index page) | SVG | SVG |
| **Screens** | SVG wireframe per screen (app-frame: sidebar + header + body with actual UI elements) | SVG | SVG |
| **Screens** | Annotation panel per screen (numbered markers mapped to wireframe elements) | HTML | HTML |
| **Screens** | Component spec table per screen (component, type, props/validation, API) | HTML | HTML |
| **Screens** | Business logic diagram per screen (condition flow chart SVG) | SVG | SVG |
| **Screens** | Sequential diagram per screen (actor-system interaction SVG) | SVG | SVG |
| **Screens** | Data flow diagram per screen (data stores, processes, external entities SVG) | SVG | SVG |
| **Screens** | Used ERD section per screen (related entities from erd.json) | SVG | SVG |
| **Design System** | **HTML-first: not generated by html-engine.** The design-system.html is the primary artifact created directly from `_meta/templates/design-system.template.html` during the Design phase (Step 4a). It already contains live CSS variables, component showcases, color swatches, typography scale, and spacing visualizations. The html-engine does NOT convert design-system.md → HTML; instead MD/JSON are derived from the HTML. | — | — |
| **Test Cases** | FT→TC coverage map | SVG | SVG |
| **Test Cases** | TC distribution by type (donut chart) | SVG | SVG |
| **Test Results** | FR→US→FT→TC→Result full traceability | SVG | SVG |
| **Test Results** | Pass/Fail summary (donut chart) | SVG | SVG |

### SVG Diagram Generation Rules

0. **No ASCII art (folder tree 제외):** ASCII art (`+--`, `|`, box-drawing characters in `<pre>` blocks)는 folder tree 구조(`├──`, `└──`)에서만 허용. 그 외 모든 다이어그램(레이아웃, ERD, 클래스, 시퀀스, 플로우, 노드맵, 타임라인 등)은 반드시 inline `<svg>`로 렌더링. SVG mode에서는 Mermaid 문법/스타일에 구애받지 않고 자유로운 시각적 표현(UML 박스, 카드형 노드, 타임라인 컬럼, 커넥터 등)을 사용.
1. **Placement:** Insert each diagram immediately after the relevant section heading.
2. **Responsive:** Use `viewBox` + `width="100%"` on all `<svg>` elements. Never use fixed pixel widths.
3. **Curved connectors:** All arrows/lines MUST use `<path>` with cubic Bezier curves (`C` or `Q`). NEVER use `<line>` or straight `<polyline>`.
4. **Arrowhead markers:** Define reusable `<marker id="arrowhead">` inside `<defs>`. Use `marker-end="url(#arrowhead)"` on paths.
5. **Node labels:** Every node must display a human-readable label. Use `<text>` inside `<g>` groups with the node shape.
6. **Color coding (PBGD)** — § 0.1 토큰과 동일해야 한다. **gray + pale blue 만:**
   - Plan phase: `#2c5580` (deep steel)
   - Build phase: `#3d6fa5` (steel blue)
   - Gatekeeping phase: `#64748b` (slate)
   - Deploy phase: `#334155` (charcoal)
   - Failed/blocked: `#dc2626` (red-600)
   - Neutral/border: `#334155` (slate-700)
   - Background: `#f2f5f8` (panel)
7. **Dark mode:** 인라인 SVG 는 문서 CSS 를 그대로 받으므로, 색을 하드코딩하지 말고 `u-doc-theme.css` L3 의 **테마 SVG 클래스**로 지정한다 — 라이트/다크/색각 3모드가 자동으로 따라온다.
   ```svg
   <rect class="svg-surface svg-border" ... />          <!-- 면 --surface / 테두리 --border -->
   <rect class="svg-accent-bg svg-stroke-accent" ... /> <!-- 강조 면 + 강조 테두리 -->
   <text class="svg-ink" ... />                          <!-- 텍스트 --fg (보조는 .svg-muted) -->
   <path class="svg-line" marker-end="url(#ah)" ... />   <!-- 커넥터 --gray-2, fill:none -->
   <polygon class="svg-marker" ... />                    <!-- 화살촉 -->
   ```
   전체 목록: `.svg-ink` `.svg-muted` `.svg-surface` `.svg-panel` `.svg-accent-bg` `.svg-accent` `.svg-border` `.svg-line` `.svg-stroke-accent` `.svg-marker` `.svg-warn` `.svg-bad`.
   Tailwind 를 로드하는 엔진 산출물에서는 `class="fill-white dark:fill-gray-800"` 형태도 쓸 수 있으나, **테마 클래스를 우선**한다. 명도 램프 hex 를 직접 써야 할 때는 `.svg-surface` 면 위에 올려 다크에서도 읽히게 한다.
8. **Node shapes by type:**
   - Rectangles with rounded corners (`rx="8"`) for entities/screens/features
   - Circles for status indicators
   - Diamonds (`<polygon>`) for decision points
   - Pill shapes (`rx="16"`) for start/end nodes
9. **Maximum nodes:** If a diagram exceeds 30 nodes, split into sub-diagrams by logical grouping.
10. **Chart types (SVG):**
    - **Donut chart:** `<circle>` with `stroke-dasharray` for segments. Include center label with count/percentage.
    - **Bar chart:** `<rect>` elements with labels. Horizontal bars for comparison.
    - **Tree/hierarchy:** Top-down layout with curved parent→child connectors.
    - **Matrix:** Grid of `<rect>` cells with fill color intensity indicating coverage.
11. **Free-form SVG design:** SVG mode에서는 Mermaid 문법/스타일에 구애받지 않는다. 데이터 특성에 맞는 최적의 시각 표현을 자유롭게 설계:
    - **UML class/entity boxes:** Header(colored) + attribute rows, 관계선에 cardinality 라벨
    - **Card-style nodes:** 제목, 메타데이터, 상태 배지, 미니 차트를 포함하는 카드형 노드
    - **Timeline/Roadmap:** 컬럼별 phase, 세로 축 위에 pill-shape 항목, 점선 연결
    - **Node-link maps:** 노드 카드 + 라벨 달린 링크 커넥터, 그룹별 배경 영역
    - 데이터에 맞는 다른 시각 표현도 자유롭게 사용 가능
12. **ERD SVG diagram (필수):** ERD 문서의 각 도메인 페이지에 반드시 inline SVG ERD를 생성한다. `erd.json`의 entities + relationships 데이터로부터 생성:
    - **Entity boxes:** 각 엔티티를 rounded rectangle로 렌더링. 헤더 영역(colored, 엔티티명) + column rows (name, type, PK/FK/UK 배지)
    - **Relationship connectors:** 엔티티 간 curved path (`C` Bezier)로 연결. 직선(`<line>`) 금지
    - **Cardinality labels:** 커넥터 양 끝에 `1`, `N`, `0..1`, `0..N` 등 카디널리티 텍스트 표시
    - **Relationship labels:** 커넥터 중앙에 관계 설명 텍스트 (예: "has many", "belongs to")
    - **Color scheme:** Entity header: `#2c5580` (deep steel), PK badge: `#334155` (charcoal), FK badge: `#3d6fa5` (steel blue), UK badge: `#8fb3d0` (pale blue) — gray + pale blue 외 금지
    - **Domain grouping:** 같은 도메인 엔티티를 배경 영역(`<rect>` with light fill)으로 그룹핑
    - **Layout:** 엔티티 30개 초과 시 도메인별로 분할. 엔티티 간 겹침 없도록 자동 배치
13. **ERD relationship description section (필수):** ERD 도메인 페이지에 SVG 다이어그램 아래 관계 설명 카드를 HTML로 생성:
    - 각 relationship을 카드 형태로 표시: From Entity → To Entity, Type (1:1/1:N/N:M), FK Column, 상세 설명(prose)
    - 관계의 비즈니스 의미를 자연어로 서술 (예: "하나의 주문(Order)은 여러 개의 주문항목(OrderItem)을 가진다")
    - 참조 무결성 규칙 명시 (CASCADE/SET NULL/RESTRICT 등)
14. **ERD sample data section (필수):** ERD 도메인 페이지에 관계 설명 카드 아래, 샘플 데이터 섹션을 생성한다. `erd.json`의 각 entity `sampleData` 배열로부터:
    - **샘플 데이터 테이블:** 엔티티별 샘플 레코드를 `<table>`로 렌더링. PK 컬럼은 `font-weight: bold`, FK 컬럼은 `#eef3f9`(accent-bg) 배경 하이라이트
    - **Sample Data Relation Diagram (inline SVG, 필수):** 샘플 데이터 간의 실제 FK 연결을 시각화하는 inline SVG 다이어그램:
      - **노드:** 각 샘플 레코드를 rounded rectangle 카드로 표현. 카드 내용 = 엔티티명 + PK 값 + 대표 컬럼값 (이름, 제목 등)
      - **커넥터:** FK 관계에 따라 부모 레코드 → 자식 레코드를 curved path (`C` Bezier)로 연결. 직선 금지
      - **레이블:** 커넥터 위에 FK 컬럼명 표시 (예: `userId`, `orderId`)
      - **그룹핑:** 같은 엔티티의 레코드를 수평으로 나열하고, 엔티티 그룹을 수직으로 배치. 각 엔티티 그룹에 라벨 헤더
      - **Color scheme:** 엔티티 그룹별 헤더 색상 구분 (`#3d6fa5` → `#3d6fa5` → `#64748b` → `#334155` 순환). 카드 배경: white/`#f2f5f8`. 커넥터: slate-700
      - **비즈니스 시나리오:** 다이어그램 하단에 샘플 데이터가 표현하는 비즈니스 시나리오를 1~2문장으로 서술하는 `<p>` 텍스트 추가
      - **Dark mode:** 카드/텍스트에 `dark:` 클래스 적용
    - **관계 매핑 테이블:** 각 REL별로 부모 PK, 부모 대표값, 자식 PK, 자식 대표값, FK 컬럼을 정리하는 요약 테이블
16. **Screen wireframe (SVG — 대체 기존 screen layout diagram):** 기존 layout 박스 대신, 실제 UI를 묘사하는 고충실도 SVG wireframe을 생성한다. `screens.json`의 `layout` + `components` + `state` 필드로부터:
    - **App-frame 구조:** 2-column layout — 좌측 sidebar (앱 내비게이션) + 우측 main area (page header + body + footer)
    - **Sidebar:** 앱 이름/로고, 메뉴 항목 목록. 현재 화면 active 상태 표시
    - **Page header:** breadcrumb + page title + action buttons
    - **Page body:** 실제 UI 요소를 SVG로 렌더링:
      - Input fields: labeled `<rect>` with placeholder text
      - Select/Dropdown: `<rect>` with dropdown arrow indicator
      - Buttons: rounded `<rect>` with label (primary: filled, outline: bordered)
      - Tables: header row + body rows with cell borders
      - Cards: rounded `<rect>` with title + content area
      - File dropzone: dashed border `<rect>` with upload icon
      - Form groups: label + input stacked vertically
    - **Annotation markers:** 각 주요 UI 요소에 numbered circle marker (`<circle>` + `<text>`) 배치. 마커 번호는 annotation panel과 1:1 매핑
    - **Color scheme:** sidebar bg: `#162033`→`#111827`, header bg: `#162033`, body bg: `#f2f5f8`, marker: `#3d6fa5`
    - **Sizing:** `viewBox` 기반 반응형. sidebar 약 200px, main area 나머지
    - State Transition 다이어그램은 생성하지 않는다
17. **Screen annotation panel (HTML):** wireframe 오른쪽에 배치되는 어노테이션 패널:
    - 각 numbered marker에 대응하는 설명 항목: marker number + component name (bold) + 상세 설명
    - 설명에는 component type, validation rules, related BR(Business Rule) ID 포함
    - 하단에 **비즈니스 규칙** 섹션: `BR-{screenId}-XX` 형식의 규칙 목록
    - 어노테이션 범례(legend)는 생성하지 않는다
18. **Screen component spec table (HTML):** wireframe + annotation 아래 배치:
    - 테이블 컬럼: `#` (marker 번호), `컴포넌트`, `타입` (Input/Select/Button/Upload/Display/Form/Action...), `Props / 유효성`, `API`
    - `screens.json`의 `components` 배열로부터 생성
    - API 컬럼: 해당 컴포넌트가 트리거하는 API endpoint (없으면 `-`)
19. **Screen business logic diagram (SVG):** 해당 화면의 유효성 검사 / 조건 분기 흐름을 condition flow chart로 생성:
    - **Start node:** pill shape (화면 진입)
    - **Action nodes:** rounded rect (사용자 입력, API 호출 등)
    - **Decision diamonds:** `<polygon>` diamond shape (조건 분기: 유효성 검사, 상태 체크)
    - **Error nodes:** red-tinted rect (`#f9f0ef` / `#b91c1c`)
    - **Success node:** pale-blue-tinted rect (`#eef3f9` / `#3d6fa5`) — green/lime/teal 금지
    - **Connectors:** curved path with Yes/No labels
    - `screens.json`의 `validationRules` + `businessRules` 데이터로부터 생성
20. **Screen sequential diagram (SVG):** 해당 화면의 사용자-시스템 상호작용 시퀀스:
    - **Actors:** 사용자(User), Frontend, Backend API, DB/External 등 — 각각 colored box + dashed lifeline
    - **Messages:** solid arrow (request) + dashed arrow (response) with numbered step labels
    - **Activation bars:** Frontend/Backend 처리 구간을 thin rect로 표시
    - **Self-calls:** Frontend 내부 처리 (유효성 검사 등) — loop-back arrow
    - `screens.json`의 `apiCalls` + `components` 데이터로부터 흐름 추론
21. **Screen data flow diagram (SVG):** 해당 화면의 데이터 흐름:
    - **External entity:** `<rect>` (사용자, 외부 시스템)
    - **Process:** `<circle>` or `<ellipse>` (화면 Page, API endpoint)
    - **Data store:** open-top `<rect>` (state store, DB table)
    - **Data flows:** labeled curved arrows showing data movement
    - 화면에서 사용하는 state, API request/response, DB 읽기/쓰기를 시각화
22. **Screen used ERD section (SVG):** 해당 화면이 사용하는 엔티티만 추출하여 mini ERD를 inline SVG로 생성:
    - `screens.json`의 `relatedEntities` 또는 API endpoint에서 참조하는 entity를 `erd.json`에서 조회
    - 해당 엔티티 + 엔티티 간 관계만 포함하는 축소된 ERD SVG
    - 전체 ERD와 동일한 스타일 (entity box + curved connector + cardinality)
23. **Fallback:** If source data is insufficient, insert a placeholder `<div class="text-center text-gray-400 py-8">` with note: `"Diagram will be generated when {dependency} data is available."`

## 3. Mermaid Rendering Configuration

Mermaid is activated when `--diagram mermaid` or `--diagram all` is specified. When `--diagram svg` (default), Mermaid CDN is **not loaded** and all diagrams are inline SVG.

- `--diagram mermaid`: All diagrams rendered via Mermaid
- `--diagram all`: Mermaid used only for UML (`erDiagram`, `classDiagram`, `sequenceDiagram`); all others inline SVG

Mermaid code blocks are preserved as `<pre class="mermaid">` elements wrapped in `<div class="mermaid-wrapper">` for client-side rendering.

### CDN Script Inclusion

```html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js';
  mermaid.initialize({
    startOnLoad: true,
    theme: 'default',
    flowchart: {
      curve: 'basis',
      useMaxWidth: true,
      htmlLabels: true
    },
    er: {
      useMaxWidth: true
    },
    sequence: {
      useMaxWidth: true,
      mirrorActors: false
    },
    themeVariables: {
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", "Apple SD Gothic Neo", "Noto Sans KR", sans-serif',
      fontSize: '13px',
      primaryColor: '#eef3f9',
      primaryBorderColor: '#3d6fa5',
      lineColor: '#6b7280'
    }
  });
</script>
```

### Key Configuration Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `theme` | `'default'` | Use Mermaid default theme (light-friendly) |
| `flowchart.curve` | `'basis'` | Curved connectors instead of straight-line arrows |
| `startOnLoad` | `true` | Auto-render all `.mermaid` blocks on page load |
| `useMaxWidth` | `true` | Responsive diagram sizing |

### Mermaid Diagram Types

| Mermaid Type | u-maker Usage | Document |
|--------------|---------------|----------|
| `erDiagram` | Entity-Relationship diagrams | ERD |
| `classDiagram` | API model diagrams | API |
| `flowchart` | Navigation flows, workflows | IA, Screens |
| `sequenceDiagram` | API interaction sequences | API, Screens |
| ~~`stateDiagram-v2`~~ | ~~State transitions~~ | ~~Screens~~ (removed — use SVG screen layout instead) |

### erDiagram Constraint Rules

In Mermaid `erDiagram`, PK, FK, and UK constraints MUST NEVER be combined on a single attribute. Each constraint occupies its own annotation:

```
CORRECT:
  entity {
    string id PK
    string email UK
    string org_id FK
  }

INCORRECT (never do this):
  entity {
    string id PK,FK
    string email PK,UK
  }
```

### Mermaid Theme: Always Light Mode

Mermaid diagrams MUST always render in **light mode** (`theme: 'default'`). When the page toggles to dark mode, Mermaid diagrams remain in light theme — do NOT re-initialize Mermaid with `theme: 'dark'`. Instead, wrap Mermaid containers in a light-background wrapper:

```html
<div class="mermaid-wrapper bg-white rounded-lg p-4 my-4">
  <pre class="mermaid">
    erDiagram ...
  </pre>
</div>
```

This ensures Mermaid diagrams are always readable regardless of page theme.

### Mermaid Syntax Error Prevention (Critical)

Mermaid syntax errors break the entire diagram. Follow these rules strictly:

**erDiagram rules:**
1. Entity names: `PascalCase`, no spaces, no hyphens → `OrderItem` not `Order-Item`
2. Column constraints: **ONE per column** — never combine `PK FK` or `PK UK`
3. Column format: `{type} {name} {constraint}` — e.g. `bigint id PK`
4. Relationship labels: always in double quotes → `"has many"` not `has many`
5. No trailing commas inside entity blocks
6. No empty entity blocks — must have at least one column
7. Comment with `%%` not `//`

**classDiagram rules:**
1. Class names: `PascalCase`, no spaces
2. Methods: `+methodName(param: Type): ReturnType`
3. Access modifiers: `+` public, `-` private, `#` protected
4. Relationships: `<|--` inheritance, `*--` composition, `o--` aggregation

**sequenceDiagram rules:**
1. Participant names: no special characters, use `participant X as "Display Name"` for aliases
2. Arrow types: `->>` async, `-->>` async reply, `->` sync, `-->` sync reply
3. No unclosed `alt`/`opt`/`loop`/`par` blocks

**Pre-render validation:** Before writing Mermaid code blocks, mentally walk through the syntax to verify no parser errors exist.

## 4. SVG Inline Generation

For diagrams that are not Mermaid-based (custom flow diagrams, architecture diagrams, wireframes), html-engine generates inline SVG directly in the HTML output.

### SVG Rules

1. **Curved connectors**: All connectors (arrows, lines) MUST use curved paths (`<path>` with cubic Bezier curves), never straight lines (`<line>`).

```svg
<!-- CORRECT: Curved connector -->
<path d="M 50,100 C 100,100 100,200 150,200"
      stroke="#334155" stroke-width="2" fill="none"
      marker-end="url(#arrowhead)" />

<!-- INCORRECT: Straight line -->
<line x1="50" y1="100" x2="150" y2="200" stroke="#334155" />
```

2. **Arrowhead marker definition**: Include a reusable arrowhead marker in each SVG:

```svg
<defs>
  <marker id="arrowhead" markerWidth="10" markerHeight="7"
          refX="10" refY="3.5" orient="auto">
    <polygon points="0 0, 10 3.5, 0 7" fill="#334155" />
  </marker>
</defs>
```

3. **Responsive sizing**: Use `viewBox` attribute and `width="100%"` for responsive SVGs:

```svg
<svg viewBox="0 0 800 600" width="100%" xmlns="http://www.w3.org/2000/svg">
```

4. **Color palette**: § 0.1 토큰과 동일하게 쓴다 (**gray + pale blue 외 금지**):
   - Backgrounds: `#f2f5f8` (panel), `#eceef0` (chip)
   - Borders/lines: `#334155` (slate-700), 중립 divider `#e2e8f0`
   - Primary accent: `#3d6fa5` (blue-600)
   - Success: `#3d6fa5` (steel blue)
   - Warning: `#c2410c` (orange-700)
   - Error: `#dc2626` (red-600)
   - 보조 계열은 hue를 늘리지 말고 § 0.1 명도 램프에서 고른다: `#5b8db8` · `#8fb3d0` · `#b8cee4` · `#64748b` · `#94a3b8`

5. **Text styling**: Use `font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif"` and appropriate font sizes (11.5-16px). 라벨 11.5px, 노드 제목 12.5~13px, 다이어그램 제목 14.5px.

## 5. Base64 Image Encoding

All images referenced in the markdown source MUST be embedded as base64 data URIs in the output HTML. This ensures the HTML file is completely self-contained.

### Encoding Procedure

1. Scan the rendered HTML for `<img src="...">` tags
2. For each image with a local file path (not an external URL):
   a. Read the image file as binary
   b. Detect MIME type from file extension
   c. Encode as base64
   d. Replace `src` attribute with `data:{mime};base64,{encoded}`

### Supported Image Formats

| Extension | MIME Type |
|-----------|-----------|
| `.png` | `image/png` |
| `.jpg`, `.jpeg` | `image/jpeg` |
| `.gif` | `image/gif` |
| `.svg` | `image/svg+xml` |
| `.webp` | `image/webp` |

### Example Transformation

```html
<!-- Before -->
<img src="assets/logo.png" alt="Logo" />

<!-- After -->
<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUg..." alt="Logo" />
```

### External Images

External images (URLs starting with `http://` or `https://`) are left as-is. They are NOT converted to base64.

## 6. Tailwind CSS Integration

All generated HTML uses Tailwind CSS utility classes for styling. Tailwind is loaded via CDN to keep output files self-contained.

### CDN Inclusion

```html
<script src="https://cdn.tailwindcss.com"></script>
<script>
  tailwind.config = {
    darkMode: 'class',
    theme: {
      extend: {
        fontFamily: {
          // 웹폰트 CDN 없이 시스템 스택만 사용 (§ 0.2)
          sans: ['-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Helvetica',
                 'Apple SD Gothic Neo', 'Malgun Gothic', 'Noto Sans KR', 'sans-serif'],
          mono: ['ui-monospace', 'JetBrains Mono', 'Fira Code', 'monospace']
        }
      }
    }
  };
</script>
```

Tailwind 유틸리티는 레이아웃(grid/flex/spacing)에 쓰고, **색·서체·문단 리듬은 § 0 테마 토큰과 클래스
(`.hero` · `.thesis` · `.section-hint` · `.panel` · `.card` · `.tag` · `.fab`)를 쓴다.** 두 방식이 충돌하면 테마가 이긴다.

### Font Awesome Icon Integration

Font Awesome (Free) provides the icon font for all UI chrome. Load it via CDN **immediately after the Tailwind script** so `fa-*` classes are available on every page:

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/css/all.min.css">
```

**Scope — UI chrome only:** Use Font Awesome for interface icons — sidebar/nav items, buttons, metadata badges, section/heading markers, callout and status indicators, empty-state glyphs, and inline text icons. Font Awesome does **NOT** replace the mandatory inline-SVG diagrams in § 2 — ERD/class/sequence/flow/wireframe diagrams remain hand-authored inline `<svg>`. Icons decorate; SVG diagrams communicate structure.

**Usage:**

```html
<i class="fa-solid fa-circle-check"></i>          <!-- solid (default UI style) -->
<i class="fa-regular fa-file-lines"></i>          <!-- regular (outline) -->
<i class="fa-brands fa-github"></i>               <!-- brands (logos) -->
<span style="color:var(--build)"><i class="fa-solid fa-check"></i> Passed</span>
```

**Rules:**
1. **Dark/light adaptive:** glyphs inherit `currentColor`, so they follow the page theme automatically. Set color with Tailwind text classes (`text-blue-500 dark:text-blue-400`) or CSS `color` — never hardcode a fill that breaks in dark mode.
2. **Sizing:** use Font Awesome size classes (`fa-sm`, `fa-lg`, `fa-xl`, `fa-2x`) or Tailwind `text-*` sizes. Keep icon size in step with adjacent text.
3. **Style consistency:** prefer `fa-solid` for functional UI; reserve `fa-brands` for real brand logos and `fa-regular` for lighter accents. Don't mix styles arbitrarily within one component.
4. **Accessibility:** decorative icons get `aria-hidden="true"`; an icon that carries meaning on its own needs an `aria-label` (or visible adjacent text).
5. **No border decoration:** icons are inline glyphs — they must not be used to fake single-side accent borders/bars (see § 6 Border / Accent Style Rules · GK-07). Place them inside the badge/callout, never as an edge stripe.
6. **CDN dependency:** like the Tailwind and Mermaid CDNs, Font Awesome loads from `cdn.jsdelivr.net` (online). If a glyph fails to load, the layout must still read correctly — always keep a text label next to meaningful icons.

### Base Layout Classes

```html
<body>
  <!-- 목차 사이드바: 잉크 네이비 면(--sb-bg → --sb-deep), 고정 폭 268px, 테두리 없음 -->
  <aside class="split-sidebar">
    <div class="sb-header">…</div>
    <nav class="sb-body">
      <a class="sb-item active"><span class="item-id">01</span>
         <span class="item-name">개요</span><span class="item-cnt">6</span></a>
    </nav>
    <div class="sb-footer">Copyright(c) 2026 U PLEAT</div>
  </aside>

  <!-- 본문 -->
  <div class="split-main">
    <div class="split-content">   <!-- max-width:var(--content-w); padding:36px 32px 110px -->
      <header class="hero">…</header>
      <section class="blk">…</section>
      <div class="footer">Copyright(c) 2026 U PLEAT</div>
    </div>
  </div>

  <!-- 우하단 플로팅 컨트롤 (§ 0.4) -->
  <div class="fab-stack">…</div>
</body>
```

사이드바 항목은 `01` 형태의 mono ID + 제목 + 개수 배지 3단 구성이다. **active 는 배경 채움 + `font-weight:700`**
으로만 표시한다(한쪽 컬러 바 금지 — § 6 GK-07).

### Typography Scale

§ 0.2 의 스케일을 CSS로 직접 지정한다 (Tailwind `text-*` 로 크기를 덮어쓰지 않는다).

| Element | 규칙 |
|---------|------|
| `<h1>` | `27px / 700 / -0.5px / 1.35` — `.hero` 안, 아래 `1px solid var(--fg)` |
| `<h2>` | `17px / 700`, 앞에 `<span class="qword">키워드</span>` |
| `<h3>` | `14.5px / 800`, `margin:22px 0 6px` |
| `<h4>` | `13px / 700`, `margin:16px 0 4px` |
| `<p>` | `14.5px / 1.8`, `margin:0 0 12px` |
| `.section-hint` | `13.5px / 1.85`, `color:var(--muted)` — `h2` 바로 다음 |
| `<table>` | `12.5px / 1.7`, 행 구분선만 |
| `<code>` inline | `background:var(--panel); padding:2px 6px; border-radius:4px; 12px mono` |

### Border / Accent Style Rules (CSS) — 한쪽 border 강조 금지 (HARD RULE · 게이트 검사)

**한쪽(단면) border만 색으로 강조하는 장식 스타일을 전면 금지한다 (No single-side accent borders).** 카드·콜아웃·하이라이트 박스·배너를 한 변에만 색을 입힌 막대(`border-left: 4px solid …` 류)로 꾸미지 않는다. active/선택 상태도 한쪽 컬러 border로 표시하지 않는다. 강조는 **배경 채움(background tint) + `font-weight`**를 기본으로 하고, 경계가 기능적으로 필요할 때만 전체 4변 `border`를 쓴다. 이 규칙은 **모든 HTML 산출물**(문서 출력·와이어프레임·디자인시스템·리포트·로드맵)에 적용되며, **Gatekeeping GK-07(Visual Adequacy)의 `no-single-side-accent-border` 체크로 강제**된다 — 위반 시 감점/FAIL.

| Prohibited (금지 — 장식/강조용 단면 border) | Use instead (대체) |
|---|---|
| `border-left: 4px solid {accent}` accent bar on a card/callout/banner | tinted `background` + `font-weight`; 경계가 필요할 때만 `border:1px solid {color}` |
| nav/list/tab **active** 상태를 `border-left-color` / `border-bottom-color` 컬러 바로 표시 | `background: rgba(accent,.12)` + `font-weight:600~700` (막대 없음) |
| 제목 `h1~h6` 컬러 밑줄 `border-bottom: 2px solid {accent}` | 밑줄 제거, 또는 `border-bottom: 1px solid {neutral-border}` (1px 중립선만) |
| Tailwind `border-l-4`/`border-t-4`/`border-s-2` 등을 카드 액센트로 사용 | `border` + `bg-*` tint |
| 반복 목록의 각 행에 `border rounded-xl shadow` 적용 | `.simple-list` + `border-bottom:1px solid var(--border)`; 마지막 행은 선 제거 |

**Allowed (구조·기능 요소 — 장식 아님, 허용):**
- **1px 중립색 구분선**: 테이블 행/셀, 섹션·푸터 divider, 사이드바 header/footer separator (`border-bottom`/`border-top: 1px solid {neutral}`). 색은 accent가 아닌 중립 border 토큰.
- **접근성 focus ring/outline** (`outline: 2px solid …`) — 단면 강조가 아니라 4변 outline.
- **차트·타임라인 데이터 마커**: Gantt 마감 핀, 축선 등 데이터 시각화 요소(SVG/CSS line). 콘텐츠 데이터이므로 단면선 허용.
- **전체 4변 `border`** (`border: 1px solid …`).

**판단 기준:** "박스/요소를 한쪽 색 막대로 **꾸미거나**, active를 한쪽 컬러 바로 **표시**"하면 → **금지**. "내용을 **가르는** 중립 구분선 · focus · 차트 마커"면 → 허용. 애매하면 **색**으로 판단한다: **accent색** 단면이면 금지(굵기 무관), **중립색** 단면은 구분선으로 허용(1px 권장, 구조용 section/footer/table 구분선은 2px도 허용).

## 7. Floating Controls (Light/Dark/Colorblind · 본문 폭 · 맨 위로)

Every generated HTML page carries the floating control stack described in § 0.4 — 우측 **하단**에 알약 버튼을
쌓는다(예전처럼 우측 상단 사각 버튼이 아니다). 최소 구성은 **라이트/다크/색각 보정 순환 · 본문 폭 전환 · 맨 위로** 3개다.

### Default Mode

Light mode is the default. The `<html>` element starts without `dark` or `colorblind`; a saved choice takes precedence, then the OS dark preference is used as fallback.

### Implementation

```html
<div class="fab-stack">
  <button class="fab" id="theme-toggle" aria-label="다크 모드로 전환" title="현재 테마: 라이트">
    <i class="fa-solid fa-moon" id="theme-icon" aria-hidden="true"></i> <span id="theme-label">다크 모드</span>
  </button>
  <button class="fab" id="width-toggle" aria-label="Toggle content width">
    <span id="width-label">본문 넓게</span>
  </button>
  <button class="fab fab-round" id="to-top" aria-label="Scroll to top">
    <i class="fa-solid fa-arrow-up" aria-hidden="true"></i>
  </button>
</div>

<script>
// 1) theme
const html = document.documentElement,
      tBtn = document.getElementById('theme-toggle'),
      tLab = document.getElementById('theme-label'),
      tIcon = document.getElementById('theme-icon');
const THEMES = ['light','dark','colorblind'];
const THEME_NAMES = {light:'라이트',dark:'다크',colorblind:'색각 보정'};
const THEME_ICONS = {light:'fa-sun',dark:'fa-moon',colorblind:'fa-eye'};
function currentTheme(){
  return html.classList.contains('dark') ? 'dark' : html.classList.contains('colorblind') ? 'colorblind' : 'light';
}
function syncTheme(){
  const current = currentTheme(), next = THEMES[(THEMES.indexOf(current) + 1) % THEMES.length];
  tLab.textContent = THEME_NAMES[next] + ' 모드';
  tBtn.setAttribute('aria-label', THEME_NAMES[next] + ' 모드로 전환');
  tBtn.title = '현재 테마: ' + THEME_NAMES[current];
  tIcon.className = 'fa-solid ' + THEME_ICONS[next];
}
function applyTheme(theme, persist = true){
  html.classList.remove('dark','colorblind');
  if (theme !== 'light') html.classList.add(theme);
  html.dataset.theme = theme;
  if (persist) localStorage.setItem('theme', theme);
  syncTheme();
}
const savedTheme = localStorage.getItem('theme');
applyTheme(THEMES.includes(savedTheme) ? savedTheme : window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light', false);
tBtn.addEventListener('click', () => {
  const current = currentTheme();
  applyTheme(THEMES[(THEMES.indexOf(current) + 1) % THEMES.length]);
  // NOTE: Mermaid stays in light mode ('default' theme) regardless of page theme.
});

// 2) content width — 1080 / 1440 / 1920 순환
const WIDTHS = ['1080px','1440px','1920px'], LABELS = ['본문 넓게','본문 더 넓게','본문 좁게'];
let wIdx = Math.max(0, WIDTHS.indexOf(localStorage.getItem('docWidth') || '1080px'));
const wBtn = document.getElementById('width-toggle'), wLab = document.getElementById('width-label');
function applyWidth(){
  html.style.setProperty('--content-w', WIDTHS[wIdx]);
  wLab.textContent = LABELS[wIdx];
  localStorage.setItem('docWidth', WIDTHS[wIdx]);
}
applyWidth();
wBtn.addEventListener('click', () => { wIdx = (wIdx + 1) % WIDTHS.length; applyWidth(); });

// 3) scroll to top
document.getElementById('to-top').addEventListener('click', () => window.scrollTo({top:0, behavior:'smooth'}));
</script>
```

### Persistence

`localStorage.theme` (light|dark) 와 `localStorage.docWidth` (1080px|1440px|1920px) 에 저장한다.
페이지 로드 시 저장값 → 시스템 설정 순으로 확인한다. 인쇄 시 `.fab-stack` 은 숨긴다.

## 8. Root Index Navigation System

The u-maker project maintains a 3-tier index navigation hierarchy. **All three index files MUST be updated whenever any HTML document or report is generated.**

### Index Hierarchy

```
.u-maker/
├── index.html                    ← Root hub (links to output/ and reports/)
├── output/
│   ├── index.html                ← Output root (lists all apps)
│   └── {app}/
│       └── index.html            ← Per-app portal (sidebar + iframe)
└── reports/
    └── index.html                ← Reports listing (chronological table)
```

### Templates

| Index File | Template | Placeholders |
|------------|----------|-------------|
| `.u-maker/index.html` | `_meta/templates/root-index.template.html` | `projectName`, `projectDescription`, `apps[]`, `planCount`, `designCount`, `checkCount`, `reportCount` |
| `.u-maker/output/index.html` | `_meta/templates/output-root-index.template.html` | `projectName`, `apps[]` (with `name`, `initial`, `description`, `planCount/Docs`, `designCount/Docs`, `checkCount/Docs`) |
| `.u-maker/reports/index.html` | `_meta/templates/reports-index.template.html` | `projectName`, `reportCount`, `reports[]` (with `file`, `title`, `type`, `typeClass`, `app`, `date`, `score`, `scoreClass`) |
| `.u-maker/output/{app}/index.html` | `_meta/templates/output-index.template.html` | `appName`, `appDescription`, `planItems[]`, `designItems[]`, `checkItems[]`, counts |

### Root Index Update Protocol

Whenever **any** of these events occur, ALL relevant index files MUST be regenerated:

| Event | Index Files to Update |
|-------|----------------------|
| HTML document generated (`output/{app}/{phase}/*.html`) | `output/{app}/index.html` + `output/index.html` + `index.html` |
| Report generated (`reports/*.html`) | `reports/index.html` + `index.html` |
| New app initialized | `output/index.html` + `index.html` |

### Update Algorithm

1. **Scan** the filesystem for existing HTML files:
   - `output/*/plan/*.html`, `output/*/design/*.html`, `output/*/check/*.html`
   - `reports/*.html`
2. **Collect** metadata: file paths, document titles (from `<title>` or filename), app names, phases, dates
3. **Render** each template with collected data
4. **Write** all affected index files

### Report Type Classification

`reports-index.template.html` 이 정의한 **시맨틱 클래스명**을 넘긴다 (Tailwind 색 클래스 문자열이 아니다).

| Report filename pattern | Type | `typeClass` | 색 |
|------------------------|------|-------------|----|
| `daily-*.html` | Daily | `type-daily` | steel blue `#3d6fa5` |
| `gate-*.html` | Gate | `type-gate` | slate `#64748b` |
| `summary-*.html` | Summary | `type-summary` | deep steel `#2c5580` |
| `loop-*.html` | Loop | `type-loop` | charcoal `#334155` |

### Score Badge Classification

| Score Range | `scoreClass` | 색 |
|-------------|-------------|----|
| >= 95 | `score-pass` | pale blue `--ok-bg` + `--ok-fg` |
| 80–94 | `score-warn` | orange `--warn-bg` + `--warn-fg` (amber 금지) |
| < 80 | `score-fail` | red `--bad-bg` + `--bad-fg` |

### HTML Link Rule (CRITICAL)

**모든 `<a href>` 링크는 반드시 파일명까지 명시해야 한다.** 폴더 경로만 사용하면 `file://` 프로토콜에서 작동하지 않는다.

| Pattern | Bad (금지) | Good (필수) |
|---------|-----------|------------|
| 폴더 index | `href="output/"` | `href="output/index.html"` |
| 폴더 index | `href="reports/"` | `href="reports/index.html"` |
| 앱 폴더 | `href="myapp/"` | `href="myapp/index.html"` |
| Split doc 폴더 | `href="plan/srs/"` | `href="plan/srs/index.html"` |
| 단일 파일 | `href="plan/ia"` | `href="plan/ia.html"` |

**규칙:**
1. 디렉토리 링크 → 항상 `index.html` 포함: `{dir}/index.html`
2. 단일 파일 링크 → 항상 `.html` 확장자 포함: `{file}.html`
3. `../` 상대 경로도 동일 적용: `href="../index.html"` (not `href="../"`)
4. 이 규칙은 sidebar, breadcrumb, back link, card link 등 **모든 `<a href>`에 적용**

## 9. Per-App Sidebar Navigation (output/{app}/index.html)

The `output/{app}/index.html` file serves as the project's documentation portal with a sidebar navigation listing all generated HTML documents.

### Sidebar Structure

`output-index.template.html` 과 동일한 잉크 네이비 사이드바를 쓴다 — 폭 284px, 배경 `--sb-bg:#162033` → `--sb-deep:#111827`,
테두리 없음, 그룹 제목 앞에 밝은 단계 색 점(Plan pale steel · Design steel blue · Check slate).

```html
<nav class="nav-sidebar">
  <div class="nav-header">
    <h1>{App Name}</h1>
    <p>{App Description}</p>
  </div>

  <div class="nav-body">
    <div class="nav-group plan">
      <div class="nav-group-title">Plan <span class="nav-count">2</span></div>
      <div class="nav-item" data-src="plan/srs/index.html">
        <span class="label">SRS</span><span class="nav-count">5</span>
      </div>
      <div class="nav-item" data-src="plan/ia.html"><span class="label">IA</span></div>
    </div>

    <div class="nav-group design">
      <div class="nav-group-title">Design <span class="nav-count">4</span></div>
      <div class="nav-item" data-src="design/erd/index.html"><span class="label">ERD</span></div>
      <div class="nav-item" data-src="design/api/index.html"><span class="label">API</span></div>
      <div class="nav-item" data-src="design/screens/index.html"><span class="label">Screens</span></div>
      <div class="nav-item" data-src="design/design-system.html"><span class="label">Design System</span></div>
    </div>

    <div class="nav-group check">
      <div class="nav-group-title">Check <span class="nav-count">2</span></div>
      <div class="nav-item" data-src="check/testcases/index.html"><span class="label">Test Cases</span></div>
      <div class="nav-item" data-src="check/test-results.html"><span class="label">Test Results</span></div>
    </div>
  </div>

  <div class="nav-footer">Copyright(c) 2026 U PLEAT</div>
</nav>
```

### Dynamic Sidebar Update

When a new HTML document is generated, the sidebar navigation in `output/{app}/index.html` MUST be updated:

1. Read existing `index.html`
2. Parse the `<nav>` sidebar section
3. Determine which phase group the new document belongs to (Plan, Design, Check)
4. Add a new `<li><a>` entry if it does not already exist
5. Sort entries within each phase group alphabetically
6. Write updated `index.html`

### Active Page Highlighting

When viewing a specific document page, the corresponding sidebar entry is highlighted:

```html
<!-- 배경 채움 + 굵기로만 표시한다. 한쪽 컬러 바(border-left 등)는 금지 — § 6 GK-07 -->
<div class="nav-item active"><span class="label">SRS</span></div>
```

```css
.nav-item.active{ background:rgba(255,255,255,.08); color:#fff; font-weight:700; }
```

## 10. TOC Auto-Generation

Every document HTML page includes an auto-generated Table of Contents derived from the document's headings.

### TOC Generation Algorithm

1. Scan the HTML body for all heading elements (`<h2>` through `<h4>` — skip `<h1>` as it is the document title)
2. Build a nested list structure based on heading levels
3. Each TOC entry links to the heading's `id` attribute via anchor
4. Insert the TOC after the document title (`<h1>`) and before the first `<h2>`

### TOC HTML Structure

```html
<!-- --panel 채움 면, 테두리 없음, radius 14px -->
<nav class="toc">
  <h4>Table of Contents</h4>      <!-- 11.5px / 700 / uppercase / letter-spacing .9px / --dim -->
  <ul>
    <li><a href="#functional-requirements">Functional Requirements</a>
      <ul>
        <li><a href="#user-registration">User Registration</a></li>
      </ul>
    </li>
  </ul>
</nav>
```

```css
.toc{background:var(--panel);border-radius:14px;padding:18px 22px;margin:0 0 40px}
.toc ul{list-style:none;padding-left:0;margin:0}
.toc li{font-size:12.5px;padding:2px 0;line-height:1.7}
.toc ul ul{padding-left:14px}
```

### Heading ID Generation

Heading `id` attributes are derived from the heading text:

1. Convert to lowercase
2. Replace spaces with hyphens
3. Remove special characters (except hyphens and underscores)
4. Remove consecutive hyphens
5. Trim leading/trailing hyphens

Example: `## 3. Functional Requirements` → `id="3-functional-requirements"`

## 11. Footer Template

Every generated HTML page includes a standard footer at the bottom of the main content area.

### Footer HTML

```html
<div class="footer">Copyright(c) 2026 U PLEAT</div>
```

```css
.footer{padding-top:16px;margin-top:40px;border-top:1px solid var(--border);
        font-size:12px;color:var(--muted);line-height:1.95;text-align:center}
```

### Footer Rules

1. The copyright notice is always `Copyright(c) 2026 U PLEAT` — no variation.
2. The version shown matches the u-maker plugin version from `SKILL.md` frontmatter.
3. The footer appears inside `<main>`, after all document content and before the closing `</main>` tag.
4. The footer border separates it visually from the document content.

## 12. Domain Split Pipeline

For documents with many items, the engine splits output into multiple HTML pages grouped by domain. This keeps individual pages fast-loading, focused, and navigable.

### 12.1 Split vs Single Decision

| Document | Mode | Split Key | Reason |
|----------|------|-----------|--------|
| **SRS** | **Split** | FR ID | Each FR + its traced US/FT chain = 1 domain page |
| **ERD** | **Split** | Entity domain group | Entities grouped by domain = 1 page per domain |
| **API** | **Split** | Endpoint group (by related FR) | Endpoints sharing the same FR = 1 page |
| **Screens** | **Split** | Screen group / navigation section | Screens in the same flow = 1 page |
| **Test Cases** | **Split** | FR/FT group | TCs grouped by parent FT's FR = 1 page |
| **IA** | Single | — | Typically small |
| **Design System** | Single | — | Typically small |
| **Test Results** | Single | — | Summary page |

### 12.2 Split Output Directory Structure

Split documents produce a directory instead of a single file:

```
output/{app}/{phase}/{doc}/
├── index.html                    ← Split index (dashboard overview)
├── {domain-1-slug}.html         ← Domain page 1
├── {domain-2-slug}.html         ← Domain page 2
└── ...
```

Non-split documents remain as single files: `output/{app}/{phase}/{doc}.html`

### 12.3 Split Pipeline Steps

When a document qualifies for splitting, replace Steps 8–10 of the single-file pipeline with:

```
Step 8a: Read companion .json → determine domain groups
Step 8b: Extract index-level content (overview sections, summary tables, overview diagrams)
Step 8c: For each domain group, extract domain-specific content + diagrams
Step 8d: Create output directory: output/{app}/{phase}/{doc}/
Step 8e: Render index page from output-split-index.template.html → index.html
Step 8f: For each domain, render page from output-split-page.template.html → {slug}.html
Step 8g: Inject cross-page navigation (prev/next links, sidebar domain list)
```

Steps 11–12 (index updates) continue as before, but sidebar links point to `{phase}/{doc}/index.html` instead of `{phase}/{doc}.html`.

### 12.4 Domain Grouping Rules

#### SRS Domain Grouping

Read `srs.json` companion:

- **Index page** includes: Project Overview (§1), Stakeholders (§2), NFR summary table (§4), Constraints (§7), Glossary (§8), and overview-level diagrams (full FR→US→FT traceability tree, MoSCoW priority donut chart, Stakeholder-FR matrix)
- **Domain page per FR**: Each FR item + all US items where `tracedFrom` includes this FR + all FT items where `tracedFrom` includes those USs
- **Slug**: FR ID + slugified title (e.g., `fr-010-user-management.html`)
- **Stats**: Total FR count, US count, FT count, NFR count

#### ERD Domain Grouping

Read `erd.json` companion:

- **Index page** includes: Full ER overview diagram (inline SVG — entity boxes with columns, curved connectors with cardinality labels), entity count summary, relationship summary table
- **Domain page per entity group**: Entities sharing the same `domain` field + relationships involving those entities:
  1. **Inline SVG ERD (필수):** 해당 도메인의 entity boxes + relationship connectors를 SVG로 렌더링 (§ 2 Rule 12 참조). Mermaid가 아닌 inline SVG로 생성해야 `--diagram svg` 모드에서 정상 표시됨
  2. **Relationship descriptions (필수):** 각 관계를 카드 형태로 설명 — From → To, Type (1:1/1:N/N:M), FK Column, 비즈니스 의미 prose, 참조 무결성 규칙 (§ 2 Rule 13 참조)
  3. **Entity detail tables:** 각 엔티티의 column 상세 테이블 (Column, Type, PK, FK, Nullable, Default, Description)
  4. **Sample data tables (필수):** 각 엔티티의 샘플 데이터를 `<table>`로 렌더링. PK 컬럼 bold, FK 컬럼 `#eef3f9` 하이라이트 (§ 2 Rule 14 참조)
  5. **Sample data relation diagram (필수):** 도메인 내 샘플 데이터 간 FK 연결을 inline SVG로 시각화. 레코드 카드 + curved connector + FK 라벨 + 비즈니스 시나리오 설명 (§ 2 Rule 14 참조)
  6. **Common table references:** 다른 도메인에서 참조하는 테이블 목록
- **Slug**: Domain name slugified (e.g., `auth-domain.html`)
- **Stats**: Entity count, relationship count, domain count

#### API Domain Grouping

Read `api.json` companion:

- **Index page** includes: API summary table (all endpoints), Authentication & Authorization (§3), Common Models (§4), overview diagrams (endpoint→FR traceability SVG)
- **Domain page per endpoint group**: Endpoints sharing the same `relatedFR` (or grouped by resource path prefix) + full request/response details + sequence diagrams
- **Slug**: Group name slugified (e.g., `user-management-apis.html`)
- **Stats**: Total endpoint count, group count, method distribution

#### Screens Domain Grouping

Read `screens.json` companion:

- **Index page** includes: Screen inventory table (ID, Name, Path, Category, Related IA/FR), screen flow navigation map (SVG), screen group summary
- **Domain page per screen group**: Screens sharing the same `group` or navigation section. 각 화면(screen)마다 아래 섹션을 순서대로 생성:

  **Screen Page Layout (2-column stage):**
  ```
  ┌─────────────────────────────────────────────────────┬───────────────┐
  │  doc-header (screen ID, name, path, FT/FR/P/date)   │               │
  ├──────────────────────────────────┬──────────────────┤               │
  │  SVG Wireframe (app-frame)       │  Annotation Panel│               │
  │  ├─ sidebar (app nav)            │  ├─ markers 1~N  │               │
  │  └─ main (header+body+footer)    │  ├─ descriptions │               │
  │     with actual UI elements      │  └─ biz rules    │               │
  ├──────────────────────────────────┴──────────────────┤               │
  │  Component Spec Table (#, Component, Type, Props, API)              │
  ├─────────────────────────────────────────────────────┤               │
  │  Diagrams Section                                    │               │
  │  ├─ A. Business Logic Diagram (condition flow SVG)   │               │
  │  ├─ B. Sequential Diagram (actor-system SVG)         │               │
  │  ├─ C. Data Flow Diagram (DFD SVG)                   │               │
  │  └─ D. Used ERD (mini ERD SVG for related entities)  │               │
  └─────────────────────────────────────────────────────┘               │
  ```

  1. **Doc-header:** sticky top bar — screen ID badge (`SC-XXX`), screen name, route path (`/path/to`), related FT/FR IDs, priority, date
  2. **SVG Wireframe + Annotation (2-column grid):**
     - 좌측: SVG wireframe (§ 2 Rule 14 — app-frame with sidebar, page header, form elements, tables, buttons, annotation markers)
     - 우측: Annotation panel (§ 2 Rule 15 — numbered descriptions + business rules). 어노테이션 범례는 생성하지 않는다
  3. **Component spec table:** § 2 Rule 16 — `#`, 컴포넌트, 타입, Props/유효성, API
  4. **Diagrams section:** 4개 다이어그램 순서대로:
     - A. Business Logic Diagram — condition flow chart SVG (§ 2 Rule 17)
     - B. Sequential Diagram — actor-system interaction SVG (§ 2 Rule 18)
     - C. Data Flow Diagram — DFD SVG (§ 2 Rule 19)
     - D. Used ERD — mini ERD SVG for this screen's related entities (§ 2 Rule 20)

- **Slug**: Group name slugified (e.g., `auth-screens.html`)
- **Stats**: Screen count, component count, group count

#### Test Cases Domain Grouping

Read `testcases.json` companion:

- **Index page** includes: Coverage matrix (FR→US→FT→TC), TC distribution by type donut chart (SVG), summary statistics
- **Domain page per FR group**: TCs whose parent FT traces back to the same FR + preconditions, steps, expected results
- **Slug**: FR-based group name slugified (e.g., `fr-010-test-cases.html`)
- **Stats**: TC count by type, total TC count, pass/fail summary (if available)

### 12.5 Split Index Page Template

**Template:** `_meta/templates/output-split-index.template.html`

**Placeholders:**

| Placeholder | Description |
|-------------|-------------|
| `{{docTitle}}` | Full document title (e.g., "Software Requirements Specification") |
| `{{docType}}` | Short name (e.g., "SRS") |
| `{{appName}}` | Application name |
| `{{status}}`, `{{version}}`, `{{lastUpdated}}` | Metadata |
| `{{#stats}}` | Array: `{{value}}`, `{{label}}`, `{{colorClass}}` (`plan` \| `build` \| `gate` \| `deploy` \| 빈 값=중립) |
| `{{#domains}}` | Array: `{{id}}`, `{{name}}`, `{{description}}`, `{{file}}`, `{{itemCount}}` |
| `{{overviewContent}}` | HTML of non-domain overview sections |
| `{{diagrams}}` | Overview-level SVG/Mermaid diagrams |

**Layout:** hero(제목 + 한 줄 요약) → meta-bar → 요약 stat 카드(`--panel` 면) → 도메인 카드 그리드(`.figindex`,
흰 카드 + 미세 그림자) → overview/diagram 패널 순. 각 섹션은 `h2 > .qword` + `.section-hint` 로 연다 (§ 0.3).

### 12.6 Split Domain Page Template

**Template:** `_meta/templates/output-split-page.template.html`

**Placeholders:**

| Placeholder | Description |
|-------------|-------------|
| `{{docTitle}}` | Parent document title |
| `{{docType}}` | Parent short name |
| `{{appName}}` | Application name |
| `{{domainName}}` | Current domain name (e.g., "FR-010: User Management") |
| `{{domainId}}` | Domain ID (e.g., "FR-010") |
| `{{itemCount}}` | Item count label (e.g., "3 US · 8 FT") |
| `{{#domains}}` | All domain pages: `{{id}}`, `{{name}}`, `{{file}}`, `{{active}}` (boolean) |
| `{{content}}` | Domain HTML content |
| `{{toc}}` | Domain-specific table of contents |
| `{{prevFile}}`, `{{prevName}}` | Previous domain page (if exists) |
| `{{nextFile}}`, `{{nextName}}` | Next domain page (if exists) |

**Layout:** 좌측 고정 잉크 네이비 사이드바(268px) — `01` mono ID + 도메인명 + 개수 배지, active 는 배경 채움 + 굵기.
본문은 breadcrumb → `.hero` → `.toc` → 내용 → 하단 prev/next(알약 버튼) → footer. 900px 이하에서 사이드바는
햄버거로 접히고, 좌/우 방향키로 이전·다음 도메인 이동. 컨트롤(테마 · 본문 폭 · 맨 위로)은 § 0.4 에 따라
사이드바 하단 `.sidebar-tools` 에 임베딩한다 — 900px 이하에서 사이드바가 접히면 우하단 `.fab-stack` 으로 떨어진다.

### 12.7 Slug Generation

Domain page filenames use slugified identifiers:

1. Start with the domain ID if available (e.g., `fr-010`)
2. Append slugified domain title: lowercase, spaces → hyphens, remove special chars
3. Truncate to 60 characters max
4. Examples: `fr-010-user-management.html`, `auth-domain.html`, `payment-apis.html`

### 12.8 App-Level Index Sidebar Update

When split documents exist, the `output/{app}/index.html` sidebar links MUST point to the directory index:

```
<!-- Single file (non-split) -->
<div class="nav-item" data-src="design/design-system.html">
  <span class="label">Design System</span>
</div>

<!-- Split document (directory) -->
<div class="nav-item" data-src="plan/srs/index.html">
  <span class="label">SRS</span>
  <span class="nav-count">5 domains</span>
</div>
```

## 13. Complete HTML Page Structure

The final assembled HTML page follows this structure (§ 0 테마를 그대로 담은 형태):

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{Document Title} — {App Name}</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>/* Tailwind config — 시스템 서체 스택 (§ 6) */</script>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/css/all.min.css">
  <script>/* Mermaid init — mode=mermaid|all 일 때만 */</script>
  <style>/* § 0 Document Theme: tokens + typography + prose classes */</style>
</head>
<body>

  <!-- 우하단 플로팅 컨트롤 (§ 0.4) -->
  <div class="fab-stack">
    <button class="fab" id="theme-toggle" aria-label="다크 모드로 전환"><i class="fa-solid fa-moon" id="theme-icon"></i> <span id="theme-label">다크 모드</span></button>
    <button class="fab" id="width-toggle">본문 넓게</button>
    <button class="fab fab-round" id="to-top"><i class="fa-solid fa-arrow-up"></i></button>
  </div>

  <!-- 좌측 잉크 네이비 사이드바 (split/index 페이지) -->
  <aside class="split-sidebar">...</aside>

  <div class="split-main">
    <div class="split-content">      <!-- 또는 단일 페이지의 .doc-container -->

      <nav class="crumb">…</nav>

      <header class="hero">
        <h1>{Document Title}</h1>
        <div class="sub">{한 줄 요약 · 메타}</div>
      </header>

      <div class="meta-bar">
        <span>App {app}</span><span>Status {status}</span><span>v{version}</span>
      </div>

      <div class="thesis">           <!-- 선택: 문서의 결론 한 문장 -->
        <span class="k">SUMMARY</span> … <b>핵심</b> …
      </div>

      <nav class="toc">…</nav>

      <section class="blk">
        <h2><span class="qword">무엇을</span>다루는가</h2>
        <p class="section-hint">…</p>
        {converted HTML content}
        <p class="note">…</p>
      </section>

      <div class="bottom-nav">…</div>   <!-- split page 한정 -->
      <div class="footer">Copyright(c) 2026 U PLEAT</div>
    </div>
  </div>

  <script>/* theme · width · to-top (§ 7) */</script>
</body>
</html>
```

### 체크리스트 (생성 후 자기검증)

- [ ] 서체가 시스템 스택인가 (Inter/Pretendard CDN 없음), 본문 14.5px / line-height 1.8 인가
- [ ] 기본 light/dark 색이 gray + pale blue 계열뿐인가 — lime `#D7FF5A`, amber `#f59e0b`, green `#10b981`, teal `#0d9488`, violet `#7c3aed`, pink `#db2777`, cyan `#0ea5e9` 가 **한 곳도** 없는가 (경고 orange `#c2410c` · 실패 red `#dc2626`, `.colorblind`의 지정 팔레트만 예외)
- [ ] 색각 보정 테마가 `light → dark → colorblind` 순환, `localStorage.theme` 복원, 3px 고대비 focus outline을 모두 제공하는가
- [ ] 모든 섹션이 `h2 > .qword` + `.section-hint` 로 시작하는가, 섹션 간격 54px 인가
- [ ] 컨테이너는 채움 면 + 테두리 없음, 카드는 흰 면 + 미세 그림자인가
- [ ] 출처·파일·액션·마일스톤 등 반복 텍스트 행이 `.simple-list` 구분선형이며, 항목별 bordered rounded box·shadow·gap이 없는가
- [ ] 표에 4변 테두리가 없고 1px 행 구분선만 있는가
- [ ] 한쪽 컬러 border 강조가 없는가 (§ 6 GK-07)
- [ ] 우하단 `.fab-stack` 에 다크모드·본문 폭·맨 위로 버튼이 있는가
- [ ] footer 가 `1px solid var(--border)` 윗줄 + `Copyright(c) 2026 U PLEAT` 인가
