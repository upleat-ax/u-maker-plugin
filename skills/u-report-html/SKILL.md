---
name: u-report-html
description: This skill should be used when the user asks to '/u-report-html', 'HTML 리포트', 'HTML 문서 생성', '문서 HTML로', '용어사전', '가이드 문서', '정리 문서', 'HTML 리포트 만들어줘', 'make an HTML report', 'convert to HTML document', or wants to turn markdown/spreadsheet/text material into a structured, self-contained HTML document. 좌측 목차 + 우측 글랜스 레일 3열 리포트(또는 단일 컬럼 문서) 템플릿으로 생성하고, Report Writer + Report Reviewer 2-Agent 품질 루프로 10개 기준 평균 95점 이상까지 반복 보완한다. (구 `the-html-report` 개인 스킬 흡수·대체.)
---

# HTML Report Generator (2-Agent Quality Loop)

마크다운·스프레드시트·텍스트 등 다양한 입력을 **구조화된 단일 HTML 문서**로 변환하는 스킬.
**Report Writer**와 **Report Reviewer** 2개 에이전트가 역할을 나눠, 10개 품질 기준의 평균 점수가 **95점 이상**이 될 때까지 반복 보완한다.

이 스킬이 만드는 HTML은 u-maker의 다른 산출물(문서 출력·리포트·와이어프레임·디자인시스템)과 **같은 테마**를 쓴다.
색·서체·문단 리듬·플로팅 컨트롤은 `skills/u-engine/references/html-engine.md` § 0 Document Theme 이 SSoT이고,
그 구현체가 `_meta/theme/u-doc-theme.css` 다. **레이아웃(템플릿)은 자유롭게 달라도 되지만, 스타일은 이 한 벌을 벗어나지 않는다.**

## Architecture: 2-Agent Quality Loop

```
Orchestrator (Main Claude)
 1. 입력 분석 → 템플릿 선택 → Writer 에게 생성 지시
 2. 생성 완료 → Reviewer 에게 평가 지시
 3. 평균 < 95 → 피드백을 Writer 에게 전달 (반복, 최대 5회)
 4. 평균 >= 95 → 완료 선언 + 점수표 보고

 Report Writer (Agent 1)  ◄─────►  Report Reviewer (Agent 2)
 HTML 생성/수정 전담                10개 기준 평가 · 점수+피드백 산출
```

## Workflow

### Step 1: 입력 분석 + 템플릿 선택 (Orchestrator)

입력 소스를 읽고 구조·섹션·데이터 유형을 파악한다. 출력 경로는 입력 소스와 **같은 디렉토리**, 확장자만 `.html`.

템플릿은 문서 성격에 맞게 고른다 (둘 다 색·서체·컴포넌트가 동일하고 레이아웃만 다르다):

| 템플릿 | 레이아웃 | 쓰는 경우 |
|---|---|---|
| `assets/template-report.html` (기본) | 좌 목차 사이드바 + 본문 + 우 글랜스 레일 (3열) | 섹션이 3개 이상인 리포트·용어사전·가이드·정리 문서 — **기본값** |
| `assets/template-doc.html` | 단일 컬럼 `.doc-container` | 섹션 1~2개의 짧은 메모·부록·인쇄 우선 문서, 또는 다른 페이지에 임베드되는 문서 |

둘 다 맞지 않으면 **새 템플릿을 만들어도 된다.** 조건은 하나 — `_meta/theme/u-doc-theme.css` 의 L0(tokens)·L1(prose)·L4(chrome)를 그대로 인라인하고, L2(shell)만 새로 짜는 것. 자세한 절차는 `references/design-system.md` "새 템플릿 추가" 참조.

### Step 2: Report Writer Agent 실행

Agent 도구로 **report-writer** 에이전트를 생성한다. 프롬프트에 반드시 포함할 정보:

- 입력 소스 파일 경로와 내용 요약
- 출력 HTML 파일 경로
- **선택한 템플릿 경로** + 그 CSS 전체를 인라인 복사하여 단일 HTML 파일로 만들라는 지시
- `references/design-system.md` 를 읽어 디자인 시스템 규칙을 준수하라는 지시
- 아래 "작성 원칙"

**재작성 시**(반복 루프): Reviewer 의 피드백과 감점 사유를 프롬프트에 포함하고, 기존 HTML 을 읽어 **해당 부분만** 고치게 한다.

### Step 3: Report Reviewer Agent 실행

Writer 가 만든 HTML 을 **report-reviewer** 에이전트가 평가한다. 프롬프트에 포함할 정보:

- 생성된 HTML 파일 경로 + 원본 입력 소스 경로(콘텐츠 정확성 비교용)
- `references/scoring-criteria.md` 를 읽어 10개 기준을 적용하라는 지시
- 아래 출력 형식 준수 지시

**Reviewer 출력 형식:**

```
## 평가 결과

| # | 기준 | 점수 | 비고 |
|---|------|------|------|
| 1 | 구조 완전성 | 98 | ... |
| 2 | 테마 준수 | 95 | ... |

**평균 점수: XX.X / 100**

## 개선 피드백 (점수 < 95인 항목만)

### [기준명] (현재 XX점 → 목표 95+)
- 구체적 개선 사항 + 해당 HTML 라인/섹션 지적
```

### Step 4: 반복 판단 (Orchestrator)

- **평균 >= 95** — 완료. 최종 점수표와 파일 경로를 보고한다.
- **평균 < 95** — 피드백을 Writer 에게 전달해 재작성. Step 3 으로 복귀.
- **최대 5회** — 5회 후에도 미달이면 현재 상태로 마무리하고 미달 항목을 사용자에게 보고한다.

## 작성 원칙

Report Writer 에이전트에 전달할 핵심 규칙:

- 선택한 템플릿의 CSS 를 **인라인 복사**해 단일 HTML 로 만든다. 외부 CSS/JS 참조 없음 — **Font Awesome CDN `<link>` 만 예외**(head 에 유지). **웹폰트 CDN(Pretendard/Inter 등)은 금지**, 시스템 서체 스택만 쓴다.
- **색은 gray + pale blue 한 벌만.** lime·amber·green·teal·violet·pink·cyan 금지. 유채색 예외는 경고 orange `#c2410c`·실패 red `#dc2626` 둘뿐이고, `.colorblind` 테마의 지정 팔레트만 추가 예외다.
- **라이트/다크/색각 보정 3모드**를 반드시 살린다 — 테마 버튼 + `localStorage.theme` 복원. 임의 색을 하드코딩해 다크에서 깨뜨리지 않는다(항상 CSS 변수 사용).
- **조작 버튼은 사이드바 하단에 임베딩한다** — 3열 템플릿은 `.sidebar-tools`(테마·본문 폭·요약 레일·맨 위로 아이콘 줄), 단일 컬럼 템플릿만 우하단 `.fab-stack`. 본문 위에 크게 떠 있는 버튼을 만들지 않는다.
- **강조는 형광펜으로** — 제목 핵심어 `.highlight`, 섹션 제목 `.qword`, 본문 인라인 `<mark>`. 색 글자로 강조하지 않는다. 한 문단에 하나면 충분하다.
- **인쇄 시 좌·우 사이드바와 컨트롤을 모두 감춘다** — `@media print` 에서 `.sidebar,.glance,.sidebar-tools,.fab-stack,.progress-bar{display:none !important}`, 본문은 전체 폭.
- **좌측 사이드바(목차)는 3열 템플릿의 필수 요소** (짧은 문서도 예외 없음). 단일 컬럼 템플릿에서는 `.toc` 가 그 역할을 한다.
- **우측 글랜스 레일(`.glance`)도 필수**(3열 템플릿): 핵심 요약 3~5줄 + 주요 항목/핵심 포인트(본문 앵커 링크)를 `{{GLANCE}}` 자리에 채운다. 바쁜 독자가 레일만 봐도 요지를 파악하게. 상세는 `references/design-system.md` "우측 글랜스 레일".
- **문단 구조**는 `hero`(h1 + `.sub`) → `meta-bar` → `thesis`(선택) → `section.blk`(= `h2 > .qword` + `.section-hint` + 본문) → `.note` → `footer` 순서를 따른다.
- **쉬운 글쓰기(중학생 이해 수준)** — 설명 문장은 중학생이 처음 읽어도 이해되게 쓴다. 짧은 문장(한 문장 한 내용, 약 50자), 쉬운 낱말, 전문용어·약어는 첫 등장에서 괄호 한 줄 풀이, 추상 개념에는 생활 예시 한 줄. ID·코드·수치는 그대로 두고 표현만 쉽게 한다. 규칙 원문: `skills/u-engine/references/html-engine.md` § 0.6 / `skills/u-engine/references/doc-engine.md` § 8 — Gatekeeping GK-06 `plain-language-middle-school` 검사로 강제된다.
- **아이콘은 Font Awesome `fa-solid` (이모지 금지)**. 단 **다이어그램은 인라인 SVG** — FA 로 대체하지 않는다.
- **한쪽 border 강조 금지 (GK-07).** `border-left: 4px solid …` 류 accent bar, 제목 컬러 밑줄, active 를 한쪽 컬러 바로 표시하는 스타일 전부 금지. 강조는 배경 채움 + `font-weight`, 경계가 필요하면 4변 `border`. 중립 1px 구분선·focus outline·차트/타임라인 마커는 허용.
- **반복 목록은 `.simple-list`/`.decision-list`** 구분선형으로. 항목마다 bordered rounded box + shadow 를 쌓지 않는다.
- 빈 값은 `&mdash;` + `.empty` 클래스. 표준어/핵심 용어에는 `.badge.badge-accent` 뱃지.
- HTML 엔티티 정확히 이스케이프(`&amp;`, `&lt;` 등). 문서 유형에 맞게 섹션 구조를 유연하게 구성(고정 순서 없음).
- **다이어그램 우선**: 프로세스·흐름·단계·구조·계층·관계·순환은 텍스트/표 대신 다이어그램으로. 순차 흐름은 `.flow-diagram`, 구조·관계도는 **인라인 SVG**. 외부 다이어그램 라이브러리는 쓰지 않는다(UML 이 꼭 필요하면 Mermaid 를 fallback 으로만).

## 10개 품질 평가 기준 (요약)

| # | 기준 | 핵심 체크 포인트 |
|---|------|------------------|
| 1 | 구조 완전성 | 사이드바/TOC, 글랜스 레일, hero, 섹션, footer, 컨트롤 4종(테마·폭·요약·맨위), 진행률 바 |
| 2 | 테마 준수 | gray+pale blue 팔레트, 시스템 서체 14.5/1.8, 3모드 동작, CSS 변수 사용, GK-07 단면 border 없음, FA 아이콘(이모지 금지) |
| 3 | 콘텐츠 정확성 | 원본 데이터 누락·왜곡 없이 정확 반영 |
| 4 | 시각적 계층 구조 | hero → h2(.qword) → h3, 뱃지·하이라이트의 적절한 비중 |
| 5 | 컴포넌트 적합성 | 데이터 유형에 맞는 컴포넌트, 흐름·구조는 다이어그램 |
| 6 | 네비게이션 기능성 | 사이드바/글랜스 앵커·카운트 정확, 스크롤 추적 동작 |
| 7 | 코드 품질 | HTML 유효성, 엔티티 이스케이프, 정리된 코드 |
| 8 | 반응형/접근성 | 미디어 쿼리(1200/900/760), 인쇄 시 양쪽 사이드바 제거, 모션 감축, 시맨틱 태그, aria |
| 9 | 가독성/타이포그래피 | 테마 타이포 스케일 준수, 대비, 여백 |
| 10 | 완성도 | 빈 섹션·TODO·플레이스홀더 없음, 일관된 문체, 중학생 이해 수준 쉬운 글쓰기(html-engine.md § 0.6) |

상세 채점 기준은 `references/scoring-criteria.md`.

## Additional Resources

| 파일 | 내용 |
|---|---|
| `references/design-system.md` | 테마 토큰·타이포·컴포넌트 카탈로그·글랜스 레일·다이어그램 규칙·새 템플릿 추가 절차 |
| `references/scoring-criteria.md` | 10개 기준의 상세 정의·채점 루브릭·감점 사례 |
| `assets/template-report.html` | 3열 리포트 템플릿 (기본) |
| `assets/template-doc.html` | 단일 컬럼 문서 템플릿 |
| `_meta/theme/u-doc-theme.css` | **공통 테마 CSS 원본** — 모든 템플릿이 여기서 인라인 복사 |
| `skills/u-engine/references/html-engine.md` § 0 | 테마 규격 SSoT (색·서체·문단 구조·플로팅 컨트롤) |

## Agent Prompt Templates

### Report Writer

```
역할: HTML Report Writer
목표: 입력 데이터를 구조화된 HTML 리포트로 생성/수정

[입력 소스 파일 경로 및 내용]
[출력 HTML 파일 경로]
[선택한 템플릿 경로 + 전체 CSS]
[디자인 시스템 규칙 — references/design-system.md]
[작성 원칙]

(재작성 시) [이전 Reviewer 피드백 전문]
(재작성 시) [기존 HTML 을 읽어 피드백 해당 부분만 수정]
```

### Report Reviewer

```
역할: HTML Report Reviewer
목표: 생성된 HTML 리포트를 10개 기준으로 평가하고 점수+피드백 산출

[생성된 HTML 파일 경로]
[원본 입력 소스 파일 경로]
[10개 평가 기준 상세 — references/scoring-criteria.md]

출력 형식:
1. 10개 기준별 점수(0-100) 테이블
2. 평균 점수
3. 95점 미만 항목의 구체적 개선 피드백
```
