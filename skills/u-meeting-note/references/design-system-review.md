# Mode B — 리뷰 회의록 디자인 시스템

Minutes Writer 에이전트가 **화면 리뷰 회의록** (수정사항 리포트, "쉬운 설명판") HTML 생성 시 참조하는 디자인 시스템.
반드시 `assets/template-review.html` 의 CSS 와 일치하는 스타일만 사용한다.

## 이 문서의 목적

리뷰 회의(개발자·기획자가 화면을 넘기며 수정사항을 짚는 회의)의 결과를 **개발자가 그대로 작업 목록으로 쓰고, 비개발자도 그대로 검수 기준으로 쓰는** 문서로 만든다. 참고 형태: graphene-share 공유본 "그리고라이프 수정사항 (쉬운 설명판)".

## Design Principles

- **라이트 본문 + 우측 글랜스 레일** — 본문은 단일 컬럼(좌 사이드바 없음) + 상단 sticky nav(섹션 점프·유형 필터), **우측에 `.glance` 한눈 요약 레일**(요약·먼저!·유형별·약속). 바쁜 독자는 레일만 봐도 리뷰 전체 파악
- **본문 폭 1440px ↔ 1920px 토글** + 글랜스 레일 접기 토글 (프로젝트 HTML 리포트 규칙)
- **강조는 전체 border + 옅은 배경** — 한쪽 border accent 금지
- **자체완결 단일 HTML** — 캡쳐 이미지는 전부 base64 인라인. 외부 참조는 Pretendard·Font Awesome CDN 만(아이콘용), 그 외 리소스는 인라인
- **아이콘 = Font Awesome (이모티콘 금지)** — UI 아이콘은 `<i class="fa-solid fa-…">` (FA6, currentColor 상속). 이모지(📌🔥🏷🤝 등) 사용 금지
- **쉬운 언어** — 전문용어는 괄호로 풀거나 일상어로 (예: "연동" → "서버에서 실제 데이터를 받아오도록 연결")

## CSS 변수 (template-review.html `:root` 와 동일)

```css
:root {
  --bg:#f4f5f8; --surface:#fff; --ink:#1c2333; --sub:#5b6474; --line:#e2e5ec;
  --accent:#175cd3; --accent-bg:#eff6ff;
  --bug:#d92d20;    --bug-bg:#fef3f2;    --bug-line:#f9c3bd;    /* 버그 */
  --fix:#dc6803;    --fix-bg:#fffaeb;    --fix-line:#fedf89;    /* 수정 */
  --link:#175cd3;   --link-bg:#eff6ff;   --link-line:#b2ccff;   /* 연동 */
  --policy:#6941c6; --policy-bg:#f5f3ff; --policy-line:#d9d6fe; /* 정책 */
  --first:#1c2333;  --first-bg:#eceef2;  --first-line:#c9cdd6;  /* 먼저! */
  --ok:#079455;     --ok-bg:#ecfdf3;     --ok-line:#a6f4c5;     /* 약속/완료 */
  --radius:14px; --radius-sm:9px; --maxw:1440px;  /* body.wide → 1920px */
  --glance-w:320px;  /* 우측 글랜스 레일 폭 */
}
```

## 문서 구조 (순서 고정)

```
[우측 고정] glance 레일 — 요약 · 먼저!(→#p0) · 유형별 집계 · 약속(→#s1)  ※아이콘=Font Awesome
[본문]
1. hero          — 제목 + 메타 그리드 (일시/대상/항목수/목표/근거 영상)
2. legend (#s0)  — 읽는 법 30초: 지금/할 일/확인 3단 설명 + 뱃지 범례
3. sticky-nav    — 섹션 링크 + 유형 필터 버튼
4. p0 (#p0)      — "먼저! 아예 안 되는 것부터" 최우선 목록 (상세 앵커 링크)
5. toc           — 목차 그리드 (섹션명 + 건수)
6. sec (#s1..#sN) — 약속·규칙 섹션 1개 + 영역별 수정 항목 섹션들
7. sec (#sum)    — 전체 항목 요약 테이블
8. foot          — 생성 정보
```

## 뱃지 체계 (의미 판정 기준)

| 뱃지 | 클래스 | 판정 기준 |
|------|--------|-----------|
| 버그 | `b-bug` | 기능이 **아예 작동하지 않음** (안 눌림, 에러, 빈 화면) |
| 수정 | `b-fix` | 작동은 하나 화면·문구·동작을 **고쳐야** 함 |
| 연동 | `b-link` | UI는 있으나 **서버·실데이터 연결**이 필요함 (mock 상태 포함) |
| 정책 | `b-policy` | 코드보다 **규칙·기준 결정**이 먼저 필요함 (노출 기준, 개수 정책 등) |
| 먼저! | `b-first` | 유형과 별개의 **최우선 플래그** — 다른 뱃지와 병기 |
| 약속 | `b-ok` | 회의에서 합의된 **팀 규칙** (수정 항목 아님, 약속·규칙 섹션 전용) |

- 항목당 유형 뱃지는 **1개** (가장 지배적인 성격), `먼저!` 는 해당 시 추가 병기
- `먼저!` 판정: 버그 중 사용자 흐름이 막히는 것, 또는 회의에서 명시적으로 "이거 먼저" 라고 한 것

## 항목 카드 (핵심 컴포넌트)

```html
<article class="fix-item" id="i05" data-type="bug" data-first="1">
  <div class="fix-head">
    <span class="item-no">05</span>
    <span class="badge b-first">먼저!</span>
    <span class="badge b-bug">버그</span>
    <h3>이벤트 "참여" 버튼이 안 눌림</h3>
    <span class="ts">&#9201; 1:23:45</span>
  </div>
  <div class="fix-rows">
    <div class="row now"><span class="row-chip">지금</span><p>참여 버튼을 눌러도 아무 반응이 없습니다.</p></div>
    <div class="row todo"><span class="row-chip">할 일</span><p>버튼을 누르면 참여 접수가 되도록 연결합니다.</p></div>
    <div class="row done"><span class="row-chip">확인</span><p>버튼을 눌렀을 때 "참여 완료" 안내가 뜨면 됩니다.</p></div>
  </div>
  <div class="fix-note"><strong>참고:</strong> 배경·논의 맥락 (없으면 블록 생략)</div>
  <figure class="shot">
    <img src="data:image/jpeg;base64,…" alt="이벤트 상세 화면">
    <figcaption><b>a05</b> 이벤트 상세 — 참여 버튼 <span class="ts">&#9201; 1:23:45</span></figcaption>
  </figure>
</article>
```

**규칙:**
- `id="iNN"` — 문서 전체 통번호 2자리 (P0 목록·요약 테이블에서 앵커로 참조)
- `data-type` = `bug|fix|link|policy` (필터용), 최우선이면 `data-first="1"` — **뱃지와 반드시 일치**
- 캡쳐 2장 이상이면 `<div class="shot-grid">` 로 figure 들을 감싼다
- 캡쳐가 없는 항목은 figure 생략 (빈 이미지 금지)

## 지금 / 할 일 / 확인 작성 규칙

| 행 | 내용 | 작성 기준 |
|----|------|-----------|
| **지금** (`.row.now`) | 현재 보이는 문제 현상 | 화면에서 관찰되는 사실만, 1~2문장. "~합니다/됩니다" 체 |
| **할 일** (`.row.todo`) | 무엇을 어떻게 고칠지 | 실행 가능한 작업 지시. 구현 방법 세부는 쓰지 않되 방향은 명확히 |
| **확인** (`.row.done`) | 이렇게 되면 완료 | **검증 가능한 문장** — 누가 봐도 O/X 판정 가능해야 함. "~하면 됩니다/뜨면 완료" |

- 나쁜 예 (확인): "정상 동작하면 됩니다" ← 판정 불가
- 좋은 예 (확인): "목록에서 10개가 먼저 보이고, '더보기'를 누르면 다음 10개가 이어서 나오면 됩니다"
- 회의에서 완료 기준이 언급 안 됐으면 현상·할 일로부터 합리적으로 도출 (추측 표시 불필요 — 검수 기준 역할이 우선)

## 타임스탬프 (`.ts`)

- 형식: `⏱ H:MM:SS` (1시간 미만이면 `MM:SS`) — **Gemini 스크립트 시각** = 회의 영상 위치
- 항목의 타임스탬프 = 그 논의가 **시작된 발화** 시각
- 캡쳐 figcaption 의 타임스탬프 = 실제 프레임 추출 시각 (항목 시각과 다를 수 있음)

## 화면 캡쳐

- **base64 JPEG 인라인** (`data:image/jpeg;base64,`) — 자체완결 필수
- 캡쳐 라벨은 ASCII (`a01`, `b03` …) — figcaption 에 `<b>라벨</b> 화면 설명` 형식
- 원본 프레임은 `scripts/extract-frames.sh` 산출물 (q:v 3). 문서가 과대해지면 (캡쳐 30장+) `ffmpeg -vf scale=800:-2` 로 축소 후 인코딩
- 모든 항목에 캡쳐가 필요한 건 아니다 — **화면을 봐야 이해되는 항목** 위주로 (P0 전건 + 시각적 수정 항목)

## 약속·규칙 섹션

수정 항목이 아닌 **팀 합의사항** (예: "개발 서버를 하나로 맞춘다", "리스트는 10개 단위로 통일")은 첫 섹션에 분리:

```html
<div class="rule-list">
  <article class="rule-card">
    <h3><span class="badge b-ok">약속</span> 리스트는 10개 단위로 통일</h3>
    <p>모든 목록 화면은 10개씩 먼저 보여주고 더보기로 이어서 로드한다. <span class="ts">&#9201; 45:12</span></p>
  </article>
</div>
```

## 섹션 구성

- 섹션 = **서비스 영역/메뉴 단위** (예: 회원가입·계약·멤버십 / 장례 서비스 / FAQ·검색 / 마이페이지 …), 회의 진행 순서 반영
- `id="sN"` 순번, `sec-head` 에 번호 + 제목 + `건수`
- 마지막 섹션은 반드시 **전체 항목 요약 테이블** (`#sum`): # / 영역 / 유형(뱃지) / 제목(앵커) / 영상 위치

## sticky nav + 필터

- `sec-links`: `#p0` + 각 섹션 + `#sum` 링크
- `filters`: 전체/버그/수정/연동/정책/먼저! 버튼 + **실제 건수** (`<b>N</b>`) — data-type 집계와 일치해야 함
- 필터·폭 토글·스크롤 탑 JS 는 template-review.html 하단 스크립트 그대로 포함

## 우측 글랜스 레일 (필수)

바쁜 독자가 본문을 안 읽어도 리뷰 결과를 파악하는 우측 고정 패널. sticky-nav(섹션·필터)와 **중복하지 않는** 요약 정보를 담는다.

```html
<aside class="glance">
  <div class="glance-head"><span class="g-dot"></span><span class="glance-title">한눈에 보기</span></div>

  <section class="glance-block">
    <h3><i class="gb-ico fa-solid fa-thumbtack" aria-hidden="true"></i> 요약</h3>
    <ul class="glance-summary">
      <li>총 N건 · 먼저! K건 · 화면 M개</li>
      <li>목표: 예) 주내 완료</li>
    </ul>
  </section>

  <section class="glance-block">
    <h3><a href="#p0"><i class="gb-ico fa-solid fa-fire" aria-hidden="true"></i> 먼저! (P0) <span class="gb-count">K</span></a></h3>
    <ul class="glance-p0"><li><i class="fa-solid fa-fire" aria-hidden="true"></i> <a href="#i01">P0 항목 제목 한 줄</a></li></ul>
  </section>

  <section class="glance-block">
    <h3><i class="gb-ico fa-solid fa-tags" aria-hidden="true"></i> 유형별</h3>
    <div class="glance-types">
      <span class="gt bug">버그 N</span><span class="gt fix">수정 N</span>
      <span class="gt link">연동 N</span><span class="gt policy">정책 N</span>
    </div>
  </section>

  <section class="glance-block">
    <h3><a href="#s1"><i class="gb-ico fa-solid fa-handshake" aria-hidden="true"></i> 약속·규칙 <span class="gb-count">N</span></a></h3>
    <ul class="glance-list"><li>팀 규칙 한 줄</li></ul>
  </section>
</aside>
```

- **요약**: 총건수·먼저!·화면수·목표를 2~3줄. **먼저!**: P0 항목 제목 한 줄씩 + `#iNN` 앵커. **유형별**: `.gt` 색 칩으로 버그/수정/연동/정책 집계(필터 건수와 일치). **약속**: 팀 규칙 한 줄씩 + `#s1` 앵커
- `.gb-count`·유형 집계는 본문 실제 수와 일치. 빈 블록은 `<li class="glance-empty">없음</li>`
- 레일은 `#glanceToggle` 로 접기, 1200px 이하·인쇄 시 자동 숨김. 본문은 `body` 우측 패딩으로 레일 폭 확보 (겹침 방지)

## 작성 원칙

- `assets/template-review.html` 의 CSS 를 **인라인 복사**해 단일 HTML (Pretendard + Font Awesome CDN 예외). 아이콘은 이모지 대신 `fa-solid`
- **우측 글랜스 레일 먼저 채운다**: 요약(총건수·먼저!·화면수) + P0 목록 + 유형 집계 + 약속 → 본문은 그 상세
- **간결·쉬운 말이 원칙**: 지금/할 일/확인은 각 1~2문장, 제목은 현상 중심 한 줄. 논문투·장문 금지
- 전사에 나온 수정 지시는 **하나도 빠짐없이** 항목화 — 사소해 보여도 누락 금지 (사소한 것은 `수정` 뱃지로)
- 같은 문제의 중복 언급은 1개 항목으로 합치고 타임스탬프는 첫 언급 시각
- 항목 제목은 **현상 중심 한 줄** ("~가 안 됨", "~로 보임") — 해결책을 제목에 쓰지 않음
- 히어로 메타의 항목수 = P0 건수 + 필터 건수 = 요약 테이블 행수 — **세 곳 숫자 일치**
- 화자 실명 미표기 (필요 시 "개발팀", "기획팀" 수준)
- placeholder(`{{…}}`) 잔존 금지, 근거 없는 항목 창작 금지
