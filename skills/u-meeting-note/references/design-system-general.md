# Mode A — 일반 회의록 디자인 시스템

Minutes Writer 에이전트가 **일반 회의록** HTML 생성 시 참조하는 디자인 시스템.
반드시 `assets/template-general.html` 의 CSS 와 일치하는 스타일만 사용한다.

## Design Principles

- **그래파이트 사이드바 + 라이트 본문**: 사이드바 `#232932`, 본문 `#f2f5f8` (gray + pale blue 테마)
- **시스템 서체 스택**(`-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Apple SD Gothic Neo', 'Noto Sans KR'`) 기본 — 웹폰트 CDN 금지, 타임스탬프·코드성 텍스트는 모노스페이스
- **스크롤 추적**: 사이드바 네비게이션이 스크롤 위치 따라 활성 전환 + 상단 진행률 바
- **좌 네비 + 우 글랜스 레일 (3열)**: 좌측 다크 사이드바(목차) + 중앙 본문 + **우측 `.glance` 레일**(요약·결정·미결·액션 한눈). 바쁜 독자는 우측 레일만 봐도 회의 결과 파악
- **간결·평이체가 원칙 (하드 룰)**: 본문은 논문투 금지. 개조식(bullet) 우선, 한 항목 1~2줄, 쉬운 말. "정제된 문어체"라도 짧게 — 길고 현학적인 산문은 이 스킬의 실패 모드
- **아이콘 = Font Awesome (이모티콘 금지)**: UI 아이콘은 `<i class="fa-solid fa-…">` (FA6, currentColor 상속). 이모지(📌✅⏳📋 등) 사용 금지 — head 에 `@fortawesome/fontawesome-free@6` CDN `<link>` 로드
- 구조화된 분석 리포트 (메모가 아닌 회의록)
- **강조는 전체 border + 옅은 배경 (한쪽 border accent 금지)**: `border-left: 4px …` 식 한쪽 강조 배제. 색상 구분은 `border: 1px solid var(--색상)` + `var(--색상-light)` 배경. 대상: `feature-card`(+variant)·`highlight-box`·`ai-comment-card`(+variant)·`annotation`·`quote`·`stat`. (예외 — 섹션 제목 `border-bottom` 밑줄, 사이드바 active 인디케이터, 테이블 행 구분선)

## CSS 변수 (template-general.html `:root` 와 동일)

```css
:root {
  --bg: #f2f5f8;  --surface: #ffffff;
  --sidebar-bg: #232932;  --sidebar-text: #98a2ae;  --sidebar-accent: #3d6fa5;
  --text: #232932;  --text-secondary: #4b5563;  --border: #e2e8f0;
  --accent: #3d6fa5;  --accent-light: #eef3f9;
  --ok: #3d6fa5;  --ok-light: #eef3f9;
  --red: #dc2626;    --red-light: #f9f0ef;
  --warn: #c2410c; --warn-light: #f7f0ea;
  --slate: #64748b; --slate-light: #f1f5f9;
  --gray: #6b7280;   --gray-light: #eef2f6;
  --radius: 12px;    --radius-sm: 8px;
  --article-w: 780px;   /* body.wide → 1100px */
  --glance-w: 320px;    /* 우측 글랜스 레일 폭 */
}
```

## 컴포넌트 카탈로그

### 1. 사이드바 (필수)

```html
<aside class="sidebar">
  <div class="sidebar-header">
    <h2>회의 제목 (짧게)</h2>
    <p>회의 유형 · YYYY-MM-DD</p>
  </div>
  <ul class="sidebar-nav">
    <li><a href="#overview"><span class="nav-icon">01</span>개요</a></li>
    <li><a href="#attendees"><span class="nav-icon">02</span>참석자 &amp; 안건</a></li>
    <li><a href="#discussion"><span class="nav-icon">03</span>논의 내용<span class="nav-count">6</span></a></li>
    <li><a href="#decisions"><span class="nav-icon">04</span>결정 사항<span class="nav-count">4</span></a></li>
    <li><a href="#open-issues"><span class="nav-icon">05</span>미결 사항<span class="nav-count">2</span></a></li>
    <li><a href="#actions"><span class="nav-icon">06</span>액션 아이템<span class="nav-count">7</span></a></li>
    <li><a href="#ai-comments"><span class="nav-icon">07</span>AI 커멘트</a></li>
  </ul>
  <div class="sidebar-footer">Google Meet 녹화 기반 · u-meeting-note 자동 생성</div>
</aside>
```

- `.nav-count`: 그 섹션의 항목 수 (논의 카드 수·결정 수·액션 수). 개수 셀 항목이 없는 섹션(개요 등)은 생략.

### 1-b. 우측 글랜스 레일 (필수)

바쁜 독자가 본문을 안 읽어도 회의 결과를 파악하는 우측 고정 패널. 요약(한 줄들) + 결정/미결/액션(본문 앵커 링크).

```html
<aside class="glance">
  <div class="glance-head"><span class="g-dot"></span><span class="glance-title">한눈에 보기</span></div>

  <section class="glance-block">
    <h3><i class="gb-ico fa-solid fa-thumbtack" aria-hidden="true"></i> 요약</h3>
    <ul class="glance-summary">
      <li>회의 핵심 결론 한 줄</li>
      <li>또 하나의 핵심 한 줄</li>
    </ul>
  </section>

  <section class="glance-block">
    <h3><a href="#decisions"><i class="gb-ico fa-solid fa-circle-check" aria-hidden="true"></i> 결정사항 <span class="gb-count green">4</span></a></h3>
    <ul class="glance-list"><li>결정 한 줄</li></ul>
  </section>

  <section class="glance-block">
    <h3><a href="#open-issues"><i class="gb-ico fa-solid fa-hourglass-half" aria-hidden="true"></i> 미결사항 <span class="gb-count red">2</span></a></h3>
    <ul class="glance-list"><li>미결 한 줄</li></ul>
  </section>

  <section class="glance-block">
    <h3><a href="#actions"><i class="gb-ico fa-solid fa-list-check" aria-hidden="true"></i> 액션 아이템 <span class="gb-count">3</span></a></h3>
    <ul class="glance-actions"><li><span class="ga-who sp s1">참여자1</span> 액션 한 줄 (기한)</li></ul>
  </section>
</aside>
```

- **요약**: 회의 전체를 3~5줄, 각 한 줄(문장 아닌 요점). **결정/미결/액션**: 본문 항목을 한 줄로 압축, 블록 제목은 `#decisions`/`#open-issues`/`#actions` 앵커 링크
- `.gb-count` 는 본문 실제 수와 일치 (색: 결정=`green`, 미결=`red`, 액션=기본). 빈 블록은 `<li class="glance-empty">없음</li>`
- 레일은 `#glanceToggle` 로 접기/펼치기, 1200px 이하·인쇄 시 자동 숨김

### 2. 회의 메타정보 카드 + 통계 칩

```html
<div class="meeting-info">
  <h1>회의 제목</h1>
  <div class="meeting-info-grid">
    <div class="info-item"><span class="label">일시</span><span class="value">2026년 7월 1일 (수) 오전 9:12</span></div>
    <div class="info-item"><span class="label">소요 시간</span><span class="value">57분 50초</span></div>
    <div class="info-item"><span class="label">참석 인원</span><span class="value">3명</span></div>
    <div class="info-item"><span class="label">회의 방식</span><span class="value">Google Meet</span></div>
  </div>
  <div class="stat-row">
    <div class="stat"><span class="num">6</span><span class="cap">논의 주제</span></div>
    <div class="stat green"><span class="num">4</span><span class="cap">결정 사항</span></div>
    <div class="stat yellow"><span class="num">7</span><span class="cap">액션 아이템</span></div>
    <div class="stat red"><span class="num">2</span><span class="cap">미결 이슈</span></div>
  </div>
</div>
```

- `.stat-row` 는 **필수** — 회의 산출물을 숫자로 한눈에. variant: `.green` `.red` `.purple` `.yellow`

### 3. 섹션 구분

```html
<div class="section-divider" id="overview"><h2>01. 개요</h2></div>
```

`id` 는 사이드바 `<a href="#...">` 와 반드시 일치.

### 4. 하이라이트 박스 (개요 핵심 요약)

```html
<div class="highlight-box">
  <strong>핵심 요약.</strong> 회의 전체를 1~2문장으로.
  <ul><li>핵심 결론 1</li><li>핵심 결론 2</li></ul>
</div>
```

### 5. 화자 칩 + 화자 추론 테이블

본문에서 화자를 언급할 때는 색상 칩을 쓴다 (참여자 번호별 색 고정):

```html
<span class="sp s1">참여자1</span> <span class="sp s2">참여자2</span> … <span class="sp s8">참여자8</span>
```

화자 추론 테이블 (근거 컬럼 없이 3컬럼):

```html
<h3>화자 추론</h3>
<div class="data-table-wrap">
  <table class="data-table">
    <thead><tr><th>화자</th><th>추론 이름/역할</th><th>확신도</th></tr></thead>
    <tbody>
      <tr>
        <td><span class="sp s1">참여자1</span></td>
        <td>개발 리드 (기술 설명 주도)</td>
        <td><span class="badge badge-green">확인</span></td>
      </tr>
      <tr>
        <td><span class="sp s2">참여자2</span></td>
        <td>기획 담당</td>
        <td><span class="badge badge-purple">추정</span></td>
      </tr>
    </tbody>
  </table>
</div>
```

- Gemini 스크립트 헤더의 실명 나열은 `Attendees N` 순서와 대응이 보장되지 않는다 — 발화 내용으로 추론하고 확신도를 정직하게.

### 6. 회의 타임라인

```html
<div class="timeline">
  <div class="timeline-item">
    <span class="timestamp">00:00 ~ 12:30</span>
    <p>통합 테스트 환경 구성 논의</p>
  </div>
</div>
```

### 7. 논의 내용 (Feature Cards)

```html
<div class="feature-cards">
  <div class="feature-card">
    <h3><span class="badge badge-blue">테스트</span> 통합 테스트 환경 구성</h3>
    <p>주제 요약 1~2문장.</p>
    <ul>
      <li><span class="sp s1">참여자1</span> 구DB 복제 + 테스트 ERP 연결 방식 제안</li>
      <li><span class="sp s2">참여자2</span> 기존 고객사 코드 사용 시 재고 영향 우려 제기</li>
    </ul>
    <div class="quote">
      "통상적으로 구현진 내의 데이터베이스를 복제하고, 테스트 앱을 만들어 연결한다."
      <span class="quote-who">— 참여자1, 01:26</span>
    </div>
    <div class="topic-meta">
      <span class="timestamp">00:00 ~ 08:40</span>
      <span class="sp s1">참여자1</span><span class="sp s2">참여자2</span>
    </div>
    <span class="annotation"><strong>배경:</strong> 이 논의가 필요했던 맥락</span>
  </div>

  <div class="feature-card green"><h3><span class="badge badge-green">일정</span> …</h3>…</div>
</div>
```

- variant: `.green` `.purple` `.yellow` `.red` — 전체 테두리 + 옅은 배경으로 색 표현
- `.quote` 는 **핵심 발언에만** (카드당 최대 1개, 전체 3~6개) — 원문 뉘앙스가 중요한 결정적 발언
- `.topic-meta` 로 카드 하단에 논의 구간 타임스탬프 + 참여 화자 표기

### 8. 결정 사항

```html
<ul class="decision-list">
  <li>
    <span class="decision-check">&#10003;</span>
    <div class="decision-body">
      결정 내용 서술. <span class="decision-tag agree">합의</span>
      <span class="annotation"><strong>맥락:</strong> 결정 배경, 고려한 대안</span>
    </div>
  </li>
</ul>
```

- `.decision-tag`: `agree`(합의) / `hold`(보류) / `cond`(조건부) — 결정의 성격 표기

### 8-b. 미결 사항 (`#open-issues` — issue-list)

아직 결정 못 한 것·다음으로 미룬 것. 결정 사항과 **반드시 분리**한다.

```html
<div class="issue-list">
  <div class="issue-card">
    <div class="issue-icon warn"><i class="fa-solid fa-hourglass-half" aria-hidden="true"></i></div>
    <div>
      <h4>재고 수량 동기화</h4>
      <p>복제 후 재고를 어떻게 맞출지 방식 미정. 7/4 데모 후 재논의.</p>
    </div>
  </div>
</div>
```

- `.issue-icon` variant: `warn`(노랑) / `error`(빨강) / `info`(파랑). 미결=보통 `warn`, 블로킹성이면 `error`
- 글랜스 레일 미결사항 블록과 개수·내용 일치

### 9. 액션 아이템 테이블

```html
<div class="data-table-wrap">
  <table class="data-table">
    <thead><tr><th>#</th><th>항목</th><th>담당</th><th>기한</th><th>상태</th></tr></thead>
    <tbody>
      <tr>
        <td>1</td>
        <td>테스트용 DB 복제 환경 구성<span class="annotation">구DB 스냅샷 + 연락처 마스킹 선행</span></td>
        <td><span class="sp s1">참여자1</span></td>
        <td>7/4 (금)</td>
        <td><span class="badge badge-yellow">진행</span></td>
      </tr>
    </tbody>
  </table>
</div>
```

- **기한 컬럼 포함** — 회의에서 언급됐으면 구체 날짜, 없으면 `&mdash;`
- 상태 뱃지: `badge-yellow`(진행) / `badge-green`(완료) / `badge-gray`(대기) / `badge-red`(블로킹)

### 10. AI 커멘트

```html
<div class="ai-comment-list">
  <div class="ai-comment-card warning">
    <h4><span class="ai-label">AI 분석</span> 논의 누락 포인트</h4>
    <p>분석 내용</p>
    <span class="annotation">근거 발언·맥락</span>
  </div>
  <div class="ai-comment-card suggestion"><h4><span class="ai-label">AI 제안</span> …</h4>…</div>
  <div class="ai-comment-card risk"><h4><span class="ai-label">AI 리스크</span> …</h4>…</div>
</div>
```

### 11. 다이어그램 (본문 인라인 — 별도 섹션 금지)

> 관련 **논의 카드 바로 아래** 또는 결정 사항 옆에 인라인 배치. 프로세스·구조·관계·플로우·상태전이·계층이 논의됐으면 **필수**, 전혀 없을 때만 생략.

```html
<div class="diagram-card">
  <h4>다이어그램 제목</h4>
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400">
    <defs><!-- 고유 prefix: id="g1-arrow" 등 --></defs>
  </svg>
</div>
```

SVG 규칙: 인라인, `viewBox` 반응형(고정 width/height 금지), 색상은 `#3d6fa5 #3d6fa5 #dc2626 #c2410c #64748b #1e293b #f8fafc`, 폰트 `-apple-system, BlinkMacSystemFont, 'Apple SD Gothic Neo', sans-serif`, 고유 ID prefix, 주요 요소 `<title>`. **Mermaid 사용 금지 — 항상 직접 SVG.**

### 12. 녹화 화면 캡쳐 (선택)

녹화에서 화면 공유 장면이 논의 이해에 중요하면 캡쳐를 base64 인라인으로 첨부:

```html
<figure class="media-figure">
  <img src="data:image/jpeg;base64,…" alt="공유 화면 설명">
  <figcaption>테스트 시나리오 공유 화면 <span class="timestamp">32:10</span></figcaption>
</figure>
```

### 13. 부가 논의 접기 (선택)

본질과 거리가 있는 곁가지 논의는 `details.collapse` 로 접는다 (누락 방지 + 본문 간결):

```html
<details class="collapse">
  <summary>곁가지 논의 — 사무실 이전 잡담 (3건)</summary>
  <div class="collapse-body"><ul><li>…</li></ul></div>
</details>
```

### 14. 다음 회의 / 미결 항목

```html
<div class="next-meeting">
  <h3>다음 회의까지</h3>
  <ul><li>…</li></ul>
</div>
```

### 15. 뱃지 / 타임스탬프

```html
<span class="badge badge-blue">태그</span>   <!-- blue green red yellow purple gray -->
<span class="timestamp">00:00 ~ 04:00</span>
```

## 회의록 기본 섹션 순서

```
좌: sidebar(목차 7항목)   |   중앙: 본문   |   우: glance(요약·결정·미결·액션)
meeting-info (메타 그리드 + stat-row)
01. 개요          (#overview)     — highlight-box
02. 참석자 & 안건  (#attendees)    — 화자 추론 테이블 + 타임라인
03. 논의 내용      (#discussion)   — feature-cards (+quote/topic-meta/다이어그램 인라인)
04. 결정 사항      (#decisions)    — decision-list (+decision-tag)
05. 미결 사항      (#open-issues)  — issue-list (결정과 분리)
06. 액션 아이템    (#actions)      — data-table (기한 컬럼 포함)
07. AI 커멘트      (#ai-comments)  — ai-comment-list
(next-meeting 카드는 06/07 뒤 선택 배치. glance 레일은 04·05·06 을 한 줄씩 요약)
```

## 필수 JavaScript

`template-general.html` 하단 스크립트를 그대로 포함: 진행률 바(`#progressBar`) + 스크롤 탑(`#scrollTopBtn`) + 본문 폭 토글(`#widthToggle`, 780↔1100) + **글랜스 레일 토글(`#glanceToggle`)** + 사이드바 활성 추적.

## 작성 원칙

- `assets/template-general.html` 의 CSS 를 **인라인 복사**해 단일 HTML (Font Awesome CDN 만 예외). 아이콘은 이모지 대신 `fa-solid` — head 의 FA CDN `<link>` 유지
- **간결·평이체 (최우선)**: 구어체 → 짧은 문어체. 개조식 우선, 한 항목 1~2줄, 쉬운 말. 논문투·장문·현학적 표현 금지 (독자가 "논문 같다"고 느끼지 않게)
- **우 글랜스 레일 먼저 채운다**: 요약 3~5줄 + 결정/미결/액션 한 줄 요약 → 본문은 그 근거를 간결히 부연
- **화자 라벨은 `참여자1..N` 만** — 본문 실명 직접 사용 금지 (실명은 화자 추론 테이블에서만)
- 같은 화자의 연속 발화는 하나의 turn 으로 통합
- **결정 / 미결 / 액션 3분리**: 결정=합의·확정, 미결=아직 안 정함(`#open-issues`), 액션=할 일. 혼재 금지
- AI 커멘트는 일반론 금지 — 회의 내용 기반 구체 분석
- 원문 트랜스크립트 전문은 HTML 미포함, 근거 없는 추정 금지
- whisper 전사 사용 시 환각 반복 블록은 내용에서 제외했는지 확인
