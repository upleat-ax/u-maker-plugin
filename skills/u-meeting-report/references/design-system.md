# 회의록 디자인 시스템

Minutes Writer 에이전트가 HTML 회의록 생성 시 참조하는 디자인 시스템 상세 문서.
반드시 `assets/template.html`의 CSS와 일치하는 스타일만 사용한다.

## Design Principles

- **다크 사이드바 + 라이트 본문**: 사이드바 `#1e2432` 배경, 본문 `#f6f7f9` 배경
- **Pretendard 폰트** 기본, 코드/약어/타임스탬프는 모노스페이스
- **스크롤 추적**: 사이드바 네비게이션이 스크롤 위치에 따라 활성 항목 자동 전환
- 구조화된 리포트 형태 (메모가 아닌 분석 회의록)

## CSS 변수

```css
:root {
  --bg: #f6f7f9;
  --surface: #ffffff;
  --sidebar-bg: #1e2432;
  --sidebar-text: #b0b8c9;
  --sidebar-active: #ffffff;
  --sidebar-accent: #4f8cff;
  --text: #1e2432;
  --text-secondary: #5a6376;
  --border: #e2e5ea;
  --accent: #4f8cff;
  --accent-light: #eaf1ff;
  --green: #22c55e;  --green-light: #ecfdf5;
  --red: #ef4444;    --red-light: #fef2f2;
  --yellow: #f59e0b; --yellow-light: #fffbeb;
  --purple: #8b5cf6; --purple-light: #f5f3ff;
  --gray: #6b7280;   --gray-light: #f3f4f6;
  --radius: 12px;    --radius-sm: 8px;
}
```

## 컴포넌트 카탈로그

### 1. 사이드바 (필수 — 다크 테마)

모든 회의록에 반드시 포함. `.layout` > `.sidebar` + `.main-content` 구조.

```html
<aside class="sidebar">
  <div class="sidebar-header">
    <h2>회의 제목 (짧게)</h2>
    <p>회의 유형 설명</p>
  </div>
  <ul class="sidebar-nav">
    <li><a href="#overview"><span class="nav-icon">01</span>개요</a></li>
    <li><a href="#attendees"><span class="nav-icon">02</span>참석자 &amp; 안건</a></li>
    <li><a href="#discussion"><span class="nav-icon">03</span>논의 내용</a></li>
    <li><a href="#decisions"><span class="nav-icon">04</span>결정 사항</a></li>
    <li><a href="#actions"><span class="nav-icon">05</span>액션 아이템</a></li>
    <li><a href="#ai-comments"><span class="nav-icon">06</span>AI 커멘트</a></li>
    <li><a href="#diagrams"><span class="nav-icon">07</span>다이어그램</a></li>
  </ul>
  <div class="sidebar-footer">텍스트 트랜스크립트 기반 자동 생성</div>
</aside>
```

### 2. 회의 메타정보 카드

```html
<div class="meeting-info">
  <h1>회의 제목</h1>
  <div class="meeting-info-grid">
    <div class="info-item">
      <span class="label">일시</span>
      <span class="value">2026년 4월 1일 (수) 오후 1:14</span>
    </div>
    <div class="info-item">
      <span class="label">소요 시간</span>
      <span class="value">56분 22초</span>
    </div>
    <div class="info-item">
      <span class="label">참석 인원</span>
      <span class="value">10명</span>
    </div>
  </div>
</div>
```

### 3. 섹션 구분

```html
<div class="section-divider" id="overview"><h2>01. 개요</h2></div>
```

- `id`는 사이드바 `<a href="#sectionId">`와 반드시 일치

### 4. 하이라이트 박스 (개요 핵심 요약)

```html
<div class="highlight-box">
  <strong>핵심 요약.</strong> 회의 전체를 1~2문장으로 요약.
  <ul>
    <li>핵심 결론 1</li>
    <li>핵심 결론 2</li>
  </ul>
</div>
```

### 5. 화자 추론 테이블

근거 컬럼 없이 3컬럼만 사용:

```html
<h3>화자 추론</h3>
<div class="data-table-wrap">
  <table class="data-table">
    <thead>
      <tr><th>화자</th><th>추론 이름/역할</th><th>확신도</th></tr>
    </thead>
    <tbody>
      <tr>
        <td><span class="badge badge-blue">참여자1</span></td>
        <td>설계 담당 (메인 발표자)</td>
        <td><span class="badge badge-green">확인</span></td>
      </tr>
      <tr>
        <td><span class="badge badge-blue">참여자2</span></td>
        <td>실장급 의사결정자</td>
        <td><span class="badge badge-purple">추정</span></td>
      </tr>
    </tbody>
  </table>
</div>
```

### 6. 회의 타임라인

```html
<h3>회의 타임라인</h3>
<div class="timeline">
  <div class="timeline-item">
    <span class="timestamp">00:00 ~ 04:00</span>
    <p>안건 설명</p>
  </div>
</div>
```

### 7. 논의 내용 (Feature Cards)

```html
<div class="feature-cards">
  <div class="feature-card">
    <h3><span class="badge badge-blue">카테고리</span> 주제명</h3>
    <p>주제 요약 설명</p>
    <ul>
      <li><strong>참여자1</strong>: 주장/설명 내용</li>
      <li><strong>참여자2</strong>: 질문/반론 내용</li>
    </ul>
    <span class="annotation">
      <strong>배경:</strong> 이 논의가 필요했던 맥락
    </span>
  </div>

  <div class="feature-card green">
    <h3><span class="badge badge-green">AI 기능</span> 주제명</h3>
    <p>설명...</p>
  </div>
</div>
```

**색상 variant:** `.green`, `.purple`, `.yellow`, `.red` (border-left)

### 8. 결정 사항

```html
<ul class="decision-list">
  <li>
    <span class="decision-check">&#10003;</span>
    <div class="decision-body">
      결정 내용을 명확하게 서술.
      <span class="annotation">
        <strong>맥락:</strong> 결정 배경, 대안 고려 사항
      </span>
    </div>
  </li>
</ul>
```

### 9. 액션 아이템 테이블

```html
<div class="data-table-wrap">
  <table class="data-table">
    <thead>
      <tr><th>#</th><th>항목</th><th>담당</th><th>상태</th></tr>
    </thead>
    <tbody>
      <tr>
        <td>1</td>
        <td>
          액션 아이템 내용
          <span class="annotation">선행 조건이나 참고 사항</span>
        </td>
        <td>참여자1</td>
        <td><span class="badge badge-yellow">진행</span></td>
      </tr>
    </tbody>
  </table>
</div>
```

### 10. AI 커멘트

```html
<div class="ai-comment-list">
  <div class="ai-comment-card warning">
    <h4><span class="ai-label">AI 분석</span> 커멘트 제목</h4>
    <p>분석 내용</p>
    <ul><li>보완 포인트</li></ul>
    <span class="annotation">근거 발언이나 맥락</span>
  </div>

  <div class="ai-comment-card suggestion">
    <h4><span class="ai-label">AI 제안</span> 제안 제목</h4>
    <p>개선 방향</p>
  </div>

  <div class="ai-comment-card risk">
    <h4><span class="ai-label">AI 리스크</span> 리스크 제목</h4>
    <p>잠재적 리스크 분석</p>
  </div>
</div>
```

**유형:** `.warning` (주의), `.suggestion` (제안), `.risk` (리스크)

### 11. 다이어그램

```html
<div class="diagram-card">
  <h4>다이어그램 제목</h4>
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400">
    <defs><!-- 고유 prefix 사용: id="g1-arrow" 등 --></defs>
    <!-- SVG 본체 -->
  </svg>
</div>
```

**다이어그램 CSS (추가 필요 시):**
```css
.diagram-card {
  background: var(--surface);
  border-radius: var(--radius);
  padding: 24px;
  box-shadow: var(--shadow);
  margin: 20px 0;
  overflow-x: auto;
}
.diagram-card svg {
  width: 100%;
  height: auto;
  display: block;
}
```

**SVG 규칙:**
- 인라인 SVG (별도 파일 아님)
- `viewBox` 속성으로 반응형, `width`/`height` 직접 지정 없음
- 색상: `#4f8cff`, `#22c55e`, `#ef4444`, `#f59e0b`, `#8b5cf6`, `#1e293b`, `#f8fafc`
- 폰트: `Pretendard, -apple-system, sans-serif`
- 배경: 투명
- 고유 ID prefix로 충돌 방지 (예: `g1-`, `qa-`)
- 주요 요소에 `<title>` 태그 포함

### 12. Annotation (부수적 정보)

```html
<span class="annotation">
  <strong>참고:</strong> 부수적 설명 내용
</span>
```

모든 주요 항목(논의 카드, 결정 사항, 액션 아이템, AI 커멘트)에 첨부 가능.

### 13. 뱃지

```html
<span class="badge badge-blue">태그명</span>
```

**색상:** `badge-blue`, `badge-green`, `badge-red`, `badge-yellow`, `badge-purple`, `badge-gray`

### 14. 타임스탬프

```html
<span class="timestamp">00:00 ~ 04:00</span>
```

모노스페이스, accent 배경.

## 회의록 기본 섹션 순서

```
01. 개요          (#overview)     — highlight-box
02. 참석자 & 안건  (#attendees)    — 화자 추론 테이블 + 타임라인
03. 논의 내용      (#discussion)   — feature-cards
04. 결정 사항      (#decisions)    — decision-list
05. 액션 아이템    (#actions)      — data-table
06. AI 커멘트      (#ai-comments)  — ai-comment-list
07. 다이어그램     (#diagrams)     — diagram-card (해당 시)
```

## 필수 포함 JavaScript

```html
<button class="scroll-top" id="scrollTopBtn" onclick="window.scrollTo({top:0,behavior:'smooth'})">&uarr;</button>

<script>
  const scrollBtn = document.getElementById('scrollTopBtn');
  window.addEventListener('scroll', () => {
    scrollBtn.classList.toggle('visible', window.scrollY > 400);
  });

  const sections = document.querySelectorAll('.section-divider[id]');
  const navLinks = document.querySelectorAll('.sidebar-nav a');

  function updateActiveNav() {
    let current = '';
    sections.forEach(section => {
      if (section.getBoundingClientRect().top <= 120) current = section.id;
    });
    navLinks.forEach(link => {
      link.classList.remove('active');
      if (link.getAttribute('href') === '#' + current) link.classList.add('active');
    });
  }

  window.addEventListener('scroll', updateActiveNav);
  window.addEventListener('load', updateActiveNav);
</script>
```

## 작성 원칙

- `assets/template.html`의 CSS를 **인라인으로 복사**하여 단일 HTML 파일 생성 (Pretendard CDN만 예외)
- 트랜스크립트의 구어체를 정제된 문어체로 변환
- 인명은 트랜스크립트에 나오는 그대로 사용 (음성 인식 오류 가능성 주의)
- **화자 라벨은 항상 `참여자1`, `참여자2`, ... `참여자N` 형식**
- 본문에서 실명 직접 사용 금지 (참여자N만)
- 같은 화자의 연속 발화를 하나의 문맥 단위 turn으로 통합
- 결정 사항은 합의/확정된 내용만, 액션 아이템과 혼재 금지
- AI 커멘트는 일반론 금지, 회의 내용 기반 구체적 분석
- 전체 원문 트랜스크립트는 HTML에 포함하지 않음
- 근거 없는 내용은 추정 금지, 정보 부족 시 AI 커멘트에서 지적
- 파일명: m4a/txt 파일과 동일 이름, `.html` 확장자
