# u-report-html 품질 평가 기준 (10개 항목)

Report Reviewer 에이전트가 생성된 HTML 문서를 평가할 때 쓰는 상세 채점 기준.
각 항목을 0~100점으로 채점하고, 10개 항목의 **산술 평균이 95점 이상**이면 합격.

테마 규격은 `skills/u-engine/references/html-engine.md` § 0 과 `_meta/theme/u-doc-theme.css` 가 기준이다.

---

## 1. 구조 완전성 (Structure Completeness)

필수 HTML 구조 요소가 빠짐없이 있는지 평가. 사용한 템플릿에 맞춰 체크한다.

**공통 필수:**
- `<!DOCTYPE html>`, `<html lang="ko">`, `<meta charset>`, `<meta name="viewport">`
- **Font Awesome 6 CDN `<link>`** (`@fortawesome/fontawesome-free@6`) — 유일하게 허용되는 외부 참조
- 테마 CSS 전체가 `<style>` 에 인라인
- `header.hero`(h1 + `.sub`) → `.meta-bar` → (`.thesis`) → 본문 섹션 → `.footer` 순서
- 1개 이상의 `section.blk[id]` 콘텐츠 섹션
- 상단 진행률 바 `#progressBar`
- **컨트롤 4종**: `#theme-toggle` + `#width-toggle` + `#to-top` (3열 템플릿은 `#glance-toggle` 추가). 3열 템플릿은 사이드바 하단 `.sidebar-tools` 안에, 단일 컬럼 템플릿은 우하단 `.fab-stack` 안에 있어야 한다 — 3열인데 본문 위에 떠 있으면 감점
- 테마/폭/맨위/진행률/(글랜스)/사이드바 추적 JavaScript

**3열 템플릿(`template-report.html`) 추가 필수:**
- `.layout` > `.sidebar` + `.main-content`(> `.article-wrap`) + `.glance`
- 좌 사이드바: `.sidebar-header`, `.sidebar-nav`, `.sidebar-footer`
- 우 글랜스 레일: `.glance-head` + `.glance-block`(핵심 요약 / 주요 항목 / 핵심 포인트)

**단일 컬럼 템플릿(`template-doc.html`) 추가 필수:**
- `.doc-container`, 섹션이 2개 이상이면 `nav.toc`

| 점수 | 조건 |
|------|------|
| 100 | 모든 필수 요소 포함, 순서와 계층 정확 |
| 95 | 필수 요소 모두 있으나 사소한 순서 문제 |
| 90 | 1개 부수 요소 누락 (예: `.sidebar-footer`, `.meta-bar`) |
| 80 | 1개 핵심 요소 누락 (사이드바, 글랜스 레일, hero, 컨트롤 줄 중 하나) |
| 60 이하 | 2개 이상 핵심 요소 누락 |

---

## 2. 테마 준수 (Theme Compliance)

공통 테마의 토큰·서체·모드·규칙을 정확히 지켰는지 평가. **이 항목은 감점 사유를 항상 구체적 라인으로 지적한다.**

**체크 포인트:**
- `:root` / `.dark` / `.colorblind` 토큰 블록이 `_meta/theme/u-doc-theme.css` L0 과 일치
- **팔레트**: gray + pale blue 외 색이 없어야 한다. lime `#D7FF5A`, amber `#f59e0b`, green `#22c55e`/`#10b981`, teal `#0d9488`, violet `#8b5cf6`/`#7c3aed`, pink `#db2777`, cyan `#06b6d4`, vivid blue `#4f8cff`/`#2563eb` 가 **한 곳도** 없어야 한다. 예외는 경고 `#c2410c`·실패 `#dc2626`/`#b91c1c` 와 `.colorblind` 팔레트(`#0072b2` `#56b4e9` `#8a5700` `#8f4a80`)뿐
- **서체**: 시스템 스택만. Pretendard/Inter 등 웹폰트 `@import`·`<link>` 가 있으면 감점. 본문 14.5px / line-height 1.8
- **3모드 동작**: 테마 버튼이 `light → dark → colorblind` 를 순환하고 `localStorage.theme` 을 복원. 색을 하드코딩해 다크에서 깨지는 요소가 없어야 함(색은 항상 CSS 변수)
- **그라데이션 헤더 카드 금지** — hero + 1px 밑줄 구조를 쓴다
- **형광펜 강조**: 제목 핵심어는 `.highlight`/`.qword`, 본문 키워드는 `<mark>`(= `.hl`). 색 글자(`color:var(--accent)`)로 핵심어를 강조하면 감점. 한 문단에 형광펜이 3개 이상이면 남용으로 감점
- **GK-07 단면 border 금지**: `border-left/right/top/bottom` 에 accent 색을 넣은 장식, 제목 컬러 밑줄, active 를 컬러 바로 표시하는 스타일이 없어야 한다. 허용은 중립 1px 구분선·focus outline·차트/타임라인 마커
- **반복 목록**: 출처·액션·체크포인트 같은 반복 행이 항목별 bordered rounded box + shadow 가 아니라 `.simple-list`/`.decision-list` 구분선형
- **면 처리**: 컨테이너 `.panel` 은 채움 면 + 테두리 없음, 독립 카드만 흰 면 + 미세 그림자
- **아이콘**: UI 아이콘은 `fa-solid`. 이모지(📌✅⏳ 등) 사용 시 감점. 다이어그램은 인라인 SVG 유지
- **인라인 SVG 색**: `fill="#111827"` 같은 하드코딩 대신 테마 클래스(`.svg-ink`·`.svg-surface`·`.svg-border`·`.svg-line`·`.svg-accent-bg`·`.svg-marker` 등)를 써야 한다. 하드코딩된 SVG 는 다크 모드에서 배경에 묻히므로 감점
- 정의되지 않은 인라인 스타일 최소화

| 점수 | 조건 |
|------|------|
| 100 | 토큰·서체·3모드·GK-07 모두 일치, 금지 색 0건 |
| 95 | 여백/패딩 수준의 사소한 불일치 1-2곳 |
| 90 | 정의 밖 인라인 스타일 3개 이상, 또는 단면 accent border 1곳, 또는 반복 목록 카드화 1곳 |
| 80 | 금지 색 사용, 웹폰트 CDN 사용, 또는 단면 border 다수 |
| 70 이하 | CSS 변수 미사용/하드코딩 다수, 다크 모드에서 읽을 수 없는 영역 존재 |

---

## 3. 콘텐츠 정확성 (Content Accuracy)

원본 입력의 데이터가 HTML 에 정확히 반영됐는지 평가.

**체크 포인트:**
- 원본의 모든 데이터 항목이 포함(누락 없음)
- 숫자·날짜·이름 등 팩트가 정확
- 약어·용어가 원본과 일치
- 분류/그룹핑이 원본 의도를 반영
- 원본에 없는 내용을 임의로 추가하지 않음

| 점수 | 조건 |
|------|------|
| 100 | 원본 100% 정확 반영, 누락 없음 |
| 95 | 1-2건 사소한 표기 차이 |
| 90 | 3-5건 누락 또는 부정확 |
| 80 | 주요 섹션 1개 이상 누락 |
| 60 이하 | 다수 오류 또는 왜곡 |

---

## 4. 시각적 계층 구조 (Visual Hierarchy)

**체크 포인트:**
- `hero h1` → `h2`(앞에 `.qword`) → `h3` 계층 일관성
- 각 `h2` 뒤에 `.section-hint` 가 있어 섹션이 답하는 질문을 먼저 말함
- 핵심 정보에 `.badge`/`.highlight-box`/`.thesis`, 부수 정보에 `.note` 로 비중 배분
- 과잉 강조(모든 것이 bold/badge)도 감점

| 점수 | 조건 |
|------|------|
| 100 | 계층이 명확하고 직관적 |
| 95 | 1-2곳 계층 불일치 |
| 90 | `.section-hint` 누락 섹션 2개 이상 |
| 80 | 전반적으로 평면적 |
| 70 이하 | 계층 없이 나열식 |

---

## 5. 컴포넌트 적합성 (Component Appropriateness)

| 데이터 유형 | 적합 컴포넌트 |
|---|---|
| 테이블형 데이터 | `.data-table` |
| 카드형 설명 | `.feature-card` |
| 강조 정보 | `.highlight-box` |
| 반복 텍스트 행 | `.simple-list` |
| 체크리스트·확정 사항 | `.decision-list` |
| 시간순 이력 | `.timeline` |
| 프로세스·흐름·단계 | `.flow-diagram` |
| 구조·계층·관계·순환 | 인라인 SVG |
| 매핑/규칙/변환 | `.standard-card` |
| 부수적 설명 | `.note` |

**다이어그램 체크:** 원본에 흐름·구조·관계·순환(예: "A → B → C", 상하위 관계, 피드백 루프)이 있는데 문장/표로만 나열했다면 감점. 반대로 내용에 없는 다이어그램을 억지로 넣어도 감점.

| 점수 | 조건 |
|------|------|
| 100 | 모든 데이터에 최적 컴포넌트, 시각화가 필요한 내용은 다이어그램 |
| 95 | 1-2곳 차선 선택 |
| 90 | 한 컴포넌트만 반복, 또는 다이어그램이 적합한 내용 1곳을 텍스트로 처리 |
| 80 | 3곳 이상 부적합, 또는 흐름·구조를 다이어그램 없이 나열 |
| 70 이하 | 컴포넌트 미사용, 단순 텍스트 나열 |

---

## 6. 네비게이션 기능성 (Navigation Functionality)

**체크 포인트:**
- 사이드바 `<a href="#id">` ↔ 본문 `section.blk[id]` 일치, 모든 섹션에 고유 `id`
- 사이드바 항목 수 = 본문 섹션 수
- `.sidebar-count` / `.gb-count` 값이 실제 항목 수와 일치
- 글랜스 레일 블록 제목 앵커가 본문 섹션 `id` 와 일치
- `.nav-icon` 번호가 순차적(`01`, `02`, …)
- 스크롤 추적 JS 가 `.blk[id]` / `.section-divider[id]` 와 `.sidebar-nav a` 를 올바르게 참조
- `#theme-toggle`·`#width-toggle`·`#glance-toggle`·`#to-top` 이 각각 동작 (`html.dark`/`html.colorblind`, `--content-w`, `body.glance-off` 전환)

| 점수 | 조건 |
|------|------|
| 100 | 모든 링크 정확, 스크롤 추적·토글 완벽 |
| 95 | 1개 링크 id 불일치 |
| 90 | 카운트 뱃지 2개 이상 부정확 |
| 80 | 사이드바 항목과 본문 섹션 수 불일치 |
| 70 이하 | 네비게이션 깨짐 또는 JS 누락 |

---

## 7. 코드 품질 (Code Quality)

**체크 포인트:**
- 태그가 올바르게 열리고 닫힘
- HTML 엔티티 정확히 이스케이프 (`&amp;`, `&lt;`, `&gt;`, `&mdash;`)
- 일관된 들여쓰기, 불필요한 중복 코드 없음
- `class` 값 오타 없음 (정의되지 않은 클래스 참조 금지)
- `<script>` 가 `</body>` 직전
- SVG 에 `viewBox` 존재, 고정 `width/height` 없음

| 점수 | 조건 |
|------|------|
| 100 | 코드 완벽, 이스케이프 정확 |
| 95 | 1-2곳 들여쓰기 불일치 |
| 90 | 3-5곳 이스케이프 누락 또는 미정의 클래스 참조 |
| 80 | 닫히지 않은 태그 1개 이상 |
| 60 이하 | 다수 태그 오류 |

---

## 8. 반응형/접근성 (Responsiveness & Accessibility)

**체크 포인트:**
- `@media (max-width:1200px)` 글랜스 레일 숨김 + 본문 우측 여백 제거 (3열 템플릿)
- `@media (max-width:900px)` 사이드바 숨김 (3열 템플릿)
- `@media (max-width:760px)` 본문 패딩/제목 축소
- `@media print` **좌·우 사이드바를 모두 제거**(`.sidebar`,`.glance`) + 컨트롤(`.sidebar-tools`/`.fab-stack`)·진행률 바 제거, 본문 전체 폭, `page-break-inside:avoid`
- `@media (prefers-reduced-motion: reduce)` 에서 `scroll-behavior:auto` + 전환/애니메이션 차단, 맨 위로 버튼도 `behavior:'auto'`
- 접기 버튼에 `aria-expanded` + `aria-controls`(글랜스 레일은 `id="glance"`), 아이콘 전용 버튼에 `aria-label`
- 시맨틱 태그: `<aside>`(사이드바·글랜스), `<section>`, `<header>`, `<nav>`
- 장식용 아이콘에 `aria-hidden="true"`, 의미를 가진 버튼에 `aria-label`
- `.colorblind :focus-visible` 3px 고대비 outline 유지
- 표에 `<thead>`/`<tbody>` 구분, 빈 값은 `.empty` + `&mdash;`

| 점수 | 조건 |
|------|------|
| 100 | 미디어 쿼리 완비, 시맨틱·aria 적절, 인쇄 지원 |
| 95 | 1개 미디어 쿼리 또는 aria 누락 |
| 90 | viewport/lang 속성 누락 |
| 80 | 미디어 쿼리 2개 이상 누락 |
| 70 이하 | 반응형 미지원 |

---

## 9. 가독성/타이포그래피 (Readability & Typography)

**체크 포인트:**
- 시스템 서체 스택 적용(웹폰트 CDN 없음), 본문 `14.5px / 1.8 / -0.005em`
- `h1` 27px·`h2` 17px·`h3` 14.5px·`h4` 13px, 표 12.5px, 캡션 11.5~12px
- 코드·ID·약어에 mono 스택(`ui-monospace,'JetBrains Mono',…`)
- 섹션 간 54px, 섹션 내부 12~18px 리듬
- 라이트/다크/색각 3모드 모두에서 텍스트 대비가 충분
- 11px 미만 폰트 사용 금지

| 점수 | 조건 |
|------|------|
| 100 | 타이포 스케일 정확, 여백·행간·대비 적절 |
| 95 | 1-2곳 크기/여백 부자연스러움 |
| 90 | 본문 크기·행간이 테마 값과 다름 |
| 80 | 특정 모드에서 대비 부족한 영역 다수 |
| 70 이하 | 전반적으로 가독성 낮음 |

---

## 10. 완성도 (Completeness & Polish)

**체크 포인트:**
- `TODO`, `FIXME`, `{{placeholder}}`, `Lorem ipsum` 없음
- 빈 `<td>`/`<li>`/빈 섹션 없음 (빈 값은 `&mdash;`)
- 뱃지 색이 의미적으로 적절 (확정=`badge-ok`, 주의=`badge-warn`, 실패=`badge-bad`)
- `.sidebar-count`/`.gb-count` 가 숫자이며 정확
- 일관된 문체(존댓말/평어 통일)
- **중학생 이해 수준 쉬운 글쓰기**: 설명 문장이 짧고(한 문장 한 내용, 약 50자) 쉬운 낱말을 쓴다. 전문용어·약어는 첫 등장에서 괄호 한 줄 풀이 — 풀이 없는 약어가 한 문단에 2개 이상이면 감점 (규칙 원문: `html-engine.md` § 0.6 / `doc-engine.md` § 8, GK-06 `plain-language-middle-school` 검사와 동일 기준)
- 푸터 `Copyright(c) 2026 U PLEAT` 유지

| 점수 | 조건 |
|------|------|
| 100 | 완벽한 마감, TODO/빈 섹션 없음 |
| 95 | 1-2건 사소한 미완성 |
| 90 | 빈 셀 3-5개 `&mdash;` 미처리 |
| 80 | TODO 또는 플레이스홀더 존재 |
| 60 이하 | 다수 미완성 |

---

## Reviewer 출력 형식 (필수)

```markdown
## 평가 결과

| # | 기준 | 점수 | 비고 |
|---|------|------|------|
| 1 | 구조 완전성 | XX | 간단한 평가 코멘트 |
| 2 | 테마 준수 | XX | ... |
| 3 | 콘텐츠 정확성 | XX | ... |
| 4 | 시각적 계층 구조 | XX | ... |
| 5 | 컴포넌트 적합성 | XX | ... |
| 6 | 네비게이션 기능성 | XX | ... |
| 7 | 코드 품질 | XX | ... |
| 8 | 반응형/접근성 | XX | ... |
| 9 | 가독성/타이포그래피 | XX | ... |
| 10 | 완성도 | XX | ... |

**평균 점수: XX.X / 100**
**합격 여부: PASS / FAIL**

## 개선 피드백 (95점 미만 항목)

### [기준명] (현재 XX점 → 목표 95+)
- 문제 1: [구체적 위치와 내용]
- 개선 방안: [어떻게 수정할지]
```

**주의사항:**
- 점수는 정수, 평균은 소수점 첫째 자리까지
- 95점 이상 항목에는 개선 피드백을 쓰지 않음
- 감점 사유는 구체적으로(몇 번째 섹션의 어떤 요소인지 명시)
- "좋음"/"부족함" 같은 모호한 평가 금지
