# Changelog

All notable changes to u-maker-plugin.

## [4.0.0-alpha.35] — 2026-08-08

**모든 생성 문서(.md/.html)에 "쉬운 글쓰기 (Plain Language) — 중학생 이해 수준" 하드 룰을 도입했다.** 지금까지 산출물의 설명 문장이 명사화·만연체·풀이 없는 약어로 어려워지는 것을 막을 중앙 규칙이 없었다. 이제 설명 문장은 중학생이 처음 읽어도 이해할 수 있어야 하고, 게이트 검사로 강제된다.

### Added

- **`doc-engine.md` § 8 "Writing Style — 쉬운 글쓰기 (Plain Language, HARD RULE)" 신설 — 규칙 원문(SSoT).** 여섯 가지 규칙: ① 짧은 문장(한 문장 한 내용, 약 50자) ② 쉬운 낱말(기재한다→적는다, 산정한다→계산한다) ③ 전문용어·약어는 첫 등장에서 괄호 한 줄 풀이 ④ 추상 개념에 비유·생활 예시 한 줄 ⑤ ID·코드·스키마·수치는 그대로 — 상세함(GK-01 완전성)은 유지하고 **표현만** 쉽게 ⑥ "중학생이 이 문단만 읽고 무엇을 왜 하는지 말할 수 있나" 자기 검사. 낱말 바꿔 쓰기 표(§ 8.2)·용어 풀이 예시(§ 8.3)·"글이 어렵다는 신호" 체크리스트(§ 8.4) 포함. 렌더링 절차에 검증 단계 추가.
- **`html-engine.md` § 0.6 신설** — 같은 규칙의 HTML 적용 범위 정의: 본문 문단·`.sub`·`.thesis`·`.section-hint`·표 셀·다이어그램 라벨·어노테이션·글랜스 요약까지 전부.
- **GK-06 (Content Composition) 에 `plain-language-middle-school` 체크 추가** — `gate-rules.json` + `u-agent-gatekeeper.md`. 세 줄 초과 문장, 풀이 없는 약어 2개 이상/문단, 비유 없는 추상 개념 서술을 감점. 쉬운 표현 때문에 내용이 빠지면 GK-06 가점이 아니라 GK-01 감점.

### Changed

- **문서를 생성하는 전 스킬·에이전트에 규칙 연결** — u-plan·u-design·u-output·u-report-html·u-report-daily·u-report-weekly·u-reports-roadmap·u-meeting-note·u-wireframe·u-qa·u-deploy·u-reverse·u-doc·u-gatekeeping·u-analyze·u-tools-figma·u-discuss SKILL.md 와 u-agent-plan·u-agent-design·u-agent-report·u-agent-qa·u-agent-deploy 에 SSoT 포인터 삽입.
- **품질 루프 채점 기준 강화** — `u-report-html/references/scoring-criteria.md` 와 `u-meeting-note/references/scoring-criteria.md` 의 글쓰기 항목을 "중학생 이해 수준" 기준으로 상향(항목 수 10개 유지).
- **digest 상세함 보존 명시** — u-analyze·u-tools-figma 의 digest 서술 문장에도 규칙이 적용되지만, 12개 카테고리 구조화 상세(비즈니스 로직·도메인 규칙 등)는 축소하지 않는다.

## [4.0.0-alpha.34] — 2026-08-06

**`the-html-report` 개인 스킬을 플러그인으로 흡수하고, HTML 테마를 공통 CSS 한 벌로 묶었다.** 그동안 `~/.claude/skills/the-html-report` 는 Pretendard + `#4f8cff` 블루·퍼플 그라데이션 + 라이트 전용이라 u-maker 산출물과 다른 문서처럼 보였다. 이제 **스타일은 한 벌(gray + pale blue · 시스템 서체 · 라이트/다크/색각 3모드), 템플릿은 여러 개**로 정리한다.

### Added

- **`_meta/theme/u-doc-theme.css` 신설 — 공통 테마 CSS 원본(SSoT 구현체).** 레이어 구조로 나눠 템플릿이 필요한 부분만 인라인 복사한다: `L0` tokens(light/dark/colorblind + 사이드바 + 명도 램프) · `L1` base+prose(hero/thesis/qword/section-hint/panel/card/table/toc/footer) · `L2a` 단일 컬럼 shell · `L2b` 3열 리포트 shell(사이드바 + 글랜스 레일) · `L3` components · `L4` chrome(fab-stack·진행률 바·반응형·인쇄).
- **`skills/u-report-html/` 신설** (구 `the-html-report` 흡수·대체) — Report Writer + Report Reviewer 2-Agent 품질 루프로 10개 기준 평균 95점까지 반복 보완하는 HTML 문서 생성 스킬. `SKILL.md` · `references/design-system.md` · `references/scoring-criteria.md` · 템플릿 2종.
  - `assets/template-report.html` — 3열(좌 목차 사이드바 + 본문 + 우 글랜스 레일), 기본값
  - `assets/template-doc.html` — 단일 컬럼 `.doc-container`, 짧은 문서·인쇄용
  - 두 템플릿은 색·서체·컴포넌트 CSS 가 완전히 동일하고 shell 만 다르다. **새 템플릿은 `L0`·`L1`·`L4` 를 그대로 두고 `L2` 만 새로 짜는 방식으로 얼마든지 추가**할 수 있다(design-system.md "새 템플릿 추가").
- **`html-engine.md` § 0.5 우측 글랜스 레일** — the-html-report 에만 있던 `.glance` 요약 레일을 테마의 공식 선택 컴포넌트로 편입. 핵심 요약 3~5줄 + 섹션 앵커 블록, `.gb-count` 색은 `.ok`/`.warn`/`.bad`/`.neutral`, `#glance-toggle` + `localStorage.glanceOff`, 1200px 이하·인쇄 시 자동 숨김.

### Changed

- **the-html-report 테마 전면 교체** — Pretendard CDN → 시스템 서체 스택(14.5px/1.8), accent `#4f8cff` → `#3d6fa5`, `#4f8cff→#6366f1` 그라데이션 헤더 카드 → `hero` + 1px 밑줄, 흰 사이드바 → 잉크 네이비(`--sb-bg:#162033`→`#111827`), 본문 폭 840↔1100 → `--content-w` 1080/1440/1920 순환.
- **라이트 전용 → 라이트/다크/색각 보정 3모드** — `.fab-stack` 테마 순환 버튼 + `localStorage.theme` 복원 + `.colorblind :focus-visible` 3px 고대비 outline. 기존 `.float-tools`(요약/폭/맨위)는 u-maker 표준 `.fab-stack`(테마/폭/요약/맨위)으로 통합.
- **색 variant 재정의** — `.green`/`.yellow`/`.purple` 유채색 계열 폐기. 캐논 이름은 `.accent`/`.ok`/`.warn`/`.bad`/`.neutral` 이며, 구버전 클래스명은 별칭으로 남겨 기존 산출물이 깨지지 않는다(`.feature-card`·`.badge-*`·`.gb-count`·`.flow-node` 공통).
- **GK-07 정합** — 섹션 제목의 `border-bottom: 2px solid var(--accent)` 밑줄을 `.qword` 하이라이트 칩으로 대체, 사이드바 active 의 컬러 테두리 제거(배경 채움 + 굵기만), `.decision-list` 를 항목별 카드 + shadow 에서 `.simple-list` 계열 구분선형으로 전환.
- **평가 기준 2번을 "디자인 시스템 준수" → "테마 준수"로 재작성** — 금지 색 목록(lime/amber/green/teal/violet/pink/cyan/vivid blue), 웹폰트 CDN 금지, 3모드 동작, GK-07 단면 border, 반복 목록 카드화 여부를 명시적 감점 항목으로 추가. 1·6·8·9번도 새 구조(fab-stack·`.blk[id]`·미디어 쿼리 1200/900/760·타이포 스케일)에 맞춰 갱신.
- **`html-engine.md` § 0 머리말** — 테마 구현체 표(공통 CSS + 템플릿 12종 + u-report-html 템플릿 2종)와 "스타일은 한 벌, 템플릿은 여럿" 원칙, 새 템플릿 작성 규칙을 명문화.
- **사이드바 면을 다크 블루로** — `--sb-bg:#162033`→`#143050`, `--sb-deep:#111827`→`#0e2138`(다크 `#0f2337`→`#091724`). `output-index`·`output-split-page` 템플릿에도 같은 값 적용.
- **컨트롤 위치를 사이드바 하단으로** — 테마·본문 폭·요약 레일·맨 위로 버튼이 본문 위에 떠 있던 `.fab-stack` 대신, 사이드바 맨 아래 면에 임베딩된 아이콘 줄(`.sidebar-tools` > `.sb-tool`)로 들어간다. 사이드바가 없는 단일 컬럼 템플릿만 기존 `.fab-stack` 을 유지한다. 900px 이하에서 사이드바가 사라지면 같은 줄이 우하단 알약 그룹으로 떨어지고, 사이드바에는 `padding-bottom:51px` 을 줘 `.sidebar-footer` 가 가려지지 않게 했다.
- **형광펜(highlighter) 강조** — 제목·본문 핵심어를 배경 칩이 아니라 글자 아래 62%만 덮는 마커 자국(`linear-gradient` + `box-decoration-break:clone`)으로 그린다. 자리는 제목 `.highlight`, 섹션 제목 `.qword`, 본문 인라인 `<mark>`(= `.hl`) 세 곳. html-engine § 0.2 에 규격을 추가했다.
- **인쇄 규칙 명문화** — `@media print` 에서 좌 사이드바·우 글랜스 레일·컨트롤·진행률 바를 모두 감추고 본문만 전체 폭으로 남긴다(§ 0.4).

### Fixed

40-에이전트 교차 감사에서 확정된 결함을 반영했다.

- **인라인 SVG 다크 모드** — 하드코딩 hex(`fill="#111827"`)로 그린 다이어그램이 다크 배경에 묻히던 문제. 테마 SVG 클래스(`.svg-ink` `.svg-muted` `.svg-surface` `.svg-panel` `.svg-accent-bg` `.svg-accent` `.svg-border` `.svg-line` `.svg-stroke-accent` `.svg-marker` `.svg-warn` `.svg-bad`)를 추가하고, html-engine § 2 Rule 7 과 design-system 을 이 방식으로 갱신했다.
- **대비 미달 2건** — `.empty`(`--gray-4`, 라이트 1.48:1)와 `.standard-arrow`(`--gray-3`, 라이트 2.56:1)를 `--dim` 으로 올려 3모드 모두 AA 를 넘긴다.
- **`.dark` 에 `color-scheme:dark` 누락** — 스크롤바·폼 컨트롤이 다크에서 라이트 위젯으로 렌더되던 문제.
- **모션 감축 미지원** — `@media (prefers-reduced-motion: reduce)` 에서 `scroll-behavior:auto` + 전환/애니메이션을 차단하고, "맨 위로"도 `behavior:'auto'` 로 떨어지게 했다.
- **접근성 라벨** — 폭 토글의 `aria-label`("본문 폭 전환")이 보이는 라벨("본문 넓게")을 포함하지 않아 음성 제어가 실패하던 WCAG 2.5.3 위반을 수정(아이콘 전용 + 상태를 반영하는 `aria-label`/`title`). 글랜스 레일 토글에 `aria-expanded` + `aria-controls="glance"` 추가.
- **`.mermaid`/`.mermaid-wrapper` 누락** — 두 템플릿의 L1 블록에 빠져 있어, 승인된 UML fallback 을 쓰면 라이트 고정 Mermaid 가 다크 배경 위에 그려지던 문제.

### Notes

- 개인 스킬 `~/.claude/skills/the-html-report` 는 중복 등록을 막기 위해 `~/.claude/skills-archive/` 로 옮겼다(삭제 아님). 새 위치는 플러그인 네임스페이스의 `u-maker:u-report-html`.
- `/u-meeting-note` 의 템플릿 2종은 이번 범위 밖이다 — 이미 alpha.33 에서 팔레트·서체를 옮겼고 라이트 전용으로 남아 있다. 3모드·공통 CSS 편입은 후속 작업.

## [4.0.0-alpha.33] — 2026-08-04

**HTML 산출물 전체 색 테마를 gray + pale blue 한 벌로 축소.** alpha.32 에서 연두·노랑만 걷어냈다면, 이번에는 teal·violet·pink·cyan 같은 남은 유채색 계열까지 없애고 **면·글자는 중립 회색, 강조는 페일 블루** 로 통일한다. 단계·계열 구분은 색상(hue)이 아니라 **명도(depth)** 로 한다.

### Changed

- **팔레트 전면 교체** — accent `#2563eb` → `#3d6fa5`(steel blue), 하이라이트 `#dbe7ff` → `#dbe7f5`(pale blue), 면 `#f5f6f7` → `#f2f5f8`, 테두리 `#e5e7eb` → `#e2e8f0`, 잉크 `#111` → `#111827`.
- **PBGD 단계색을 명도 램프로** — Plan `#2c5580`(deep steel) → Build `#3d6fa5`(steel) → Gatekeeping `#64748b`(slate) → Deploy `#334155`(charcoal). 기존 teal `#0d9488` · violet `#7c3aed` · pink `#db2777` 폐기.
- **사이드바 네이비 → 그래파이트** `#1b2230` → `#232932`(dark `#171b22`), active 는 `rgba(168,196,224,.16)` 면 채움.
- **차트 팔레트 재정의** — `--chart-blue/teal/violet/cyan/pink` → `--chart-1…6` 명도 램프 + `--chart-warn`/`--chart-red`. 인접 계열은 선 굵기·점 모양으로도 구분하도록 규칙 추가.
- **로드맵 track 팔레트** — pale blue / cool gray / warm gray 3개 램프 × 4단계로 재구성(기존 `green*`/`amber*` 키 별칭 유지).
- **`/u-meeting-note` 템플릿 2종 편입** — 그동안 빠져 있던 `template-general.html` · `template-review.html` 의 Pretendard CDN 제거(시스템 서체) 및 노랑·초록·보라 뱃지 팔레트 교체, 화자 구분 점 8종을 명도 램프로 전환.
- **플로팅 컨트롤 3종을 전 템플릿에 통일** — daily-report · reports-index · root-index · output-root-index 에 없던 **본문 폭 토글 + 맨 위로** 버튼 추가, design-system 에 본문 폭 토글 추가. 고정 셸인 `output/{app}/index.html` 만 다크모드 버튼 단독.
- **색각 보정 테마 추가** — 공통 HTML 템플릿 9종의 테마 버튼을 `light → dark → colorblind` 3단 순환으로 확장했다. Okabe-Ito 기반 blue/orange/magenta 의미색, 더 강한 중립 테두리, 3px 고대비 focus outline을 적용하고 `localStorage`에 선택값을 유지한다.
- **`html-engine.md` § 0.1 재작성** — "연두·노랑 금지" → "gray + pale blue only" HARD RULE, 색 이름 표에 램프 추가, § 0.4 에 세 버튼 필수 규정, 자기검증 체크리스트 갱신.

### Notes

- 기본 light/dark의 유채색 예외는 **경고 orange `#c2410c` · 실패 red `#dc2626`(글자 `#b91c1c`)** 둘뿐이다. `colorblind` 모드에는 색각 다양성 대응용 고대비 팔레트를 별도 예외로 사용한다.
- `u-design`/`u-tools-figma-ds`/`u-createproject` 의 `#3b82f6` 등은 **사용자 프로젝트의 디자인 토큰 예시**라 그대로 둔다(u-maker 문서 테마가 아니다).

## [4.0.0-alpha.32] — 2026-08-04

**HTML 산출물 공통 테마 통일 — 시스템 서체 · blue accent(연두/노랑 제거) · 레퍼런스 문단 구조.** 아울러 `um-*` 스텁(fetch) 전환을 되돌려 **스킬 본문을 플러그인 안에 로컬로 유지**한다.

### Changed

- **컬러 테마에서 연두(lime)·노랑(yellow/amber) 계열 전면 제거.** 하이라이트 `#D7FF5A` → `#dbe7ff`, accent/Plan `#3b82f6` → `#2563eb`, Design·성공 `#10b981` → `#0d9488`(teal), Check·Gate `#f59e0b` → `#7c3aed`(violet), Deploy·Loop `#8b5cf6` → `#db2777`(pink), 경고 티어 amber → `#c2410c`(orange). 로드맵 track 팔레트 `green*`/`amber*` → `teal*`/`orange*`(기존 키는 별칭 유지).
- **서체** — Inter/Pretendard CDN 제거, 시스템 서체 스택만 사용. 본문 `14.5px / line-height 1.8 / letter-spacing -0.005em`, h1 27px·h2 17px·h3 14.5px.
- **문단 구조** — `hero`(h1+sub+1px 밑줄) → `meta-bar` → `thesis`(짙은 면) → `section.blk`(54px) = `h2 > .qword` + `.section-hint` + `.panel`/`.card` → `.note` → `footer`. 컨테이너는 채움 면(테두리 없음), 카드는 흰 면 + 미세 그림자, 표는 1px 중립 행 구분선만(GK-07 준수).
- **플로팅 컨트롤** — 우하단 알약 스택(다크모드 · 본문 폭 1080/1440/1920 · 맨 위로).
- **`skills/u-engine/references/html-engine.md`에 § 0 Document Theme (SSoT) 신설** — 토큰·타이포·문단구조·플로팅 컨트롤 규격 + 생성 후 자기검증 체크리스트. § 7을 플로팅 컨트롤로 교체, § 9 사이드바·§ 10 TOC·§ 11 footer 갱신. 리포트 배지를 Tailwind 클래스 문자열 → 시맨틱 클래스(`type-*`/`score-*`)로 전환.
- 템플릿 12종(`_meta/templates/*.html` 9 + wireframe 2 + roadmap 1)과 ERD/차트/와이어프레임/디자인시스템 스펙 팔레트 정정.

### Reverted

- **`u-*` → `um-*` 스텁(fetch) 마이그레이션 되돌림.** 스킬 본문은 플러그인 안에 그대로 두고(`skills/u-*/SKILL.md` + `references/`/`assets/`), `_meta/` 템플릿·스키마도 복원한다. 커맨드는 `/u-*`, 에이전트는 `u-agent-*`, 플러그인 이름은 `u-maker`. 스킬 서버에서 본문을 받아오는 방식은 `feat/stub-skills-fetch` 브랜치에 보존.

## [4.0.0-alpha.30] — 2026-06-28

**`/u-createproject` now scaffolds an Atomic Design UI package hierarchy — `ui-atomics` → `ui-molecules` → `ui-organisms` — where raw HTML, CSS, and inline style live ONLY in `ui-atomics` (atoms), and every higher layer composes lower-layer components only.**

Per the user request — *"atomic component들은 raw html + css + inline style + style로 구성하는데, 이외의 component를 구현할때는 이 atomic component들만 조합해서 사용하도록 … plugin을 수정해줘"* and the follow-up *"packages/ui-atomics / packages/ui-molecules / packages/ui-organisms 로 나눠서 구성해줘"* — the surface-based UI packages (`ui-common` / `ui-backoffice` / `ui-app`) are **replaced** by an Atomic Design package chain. The atom layer is the single boundary where native elements, `.css`/CSS Modules, and inline `style={{…}}` are allowed; molecules, organisms, and `apps/*` are pure composition. admin/web differences move to organism variant props or per-app token themes (no separate surface package).

### Changed

- **`skills/u-createproject/references/scaffolding-spec.md` — UI layer fully re-specified.** §2 folder tree, §3 dependency flow (`apps/* → ui-organisms → ui-molecules → ui-atomics → tokens` + per-package dependency table), §4 styling/tech rows, §5 core rules. §6.7 (was the single parametrized `ui-common`) is split into **§6.7 `ui-atomics`** (atoms `Button`/`Input`/`Label`/`Text`/`Form` + layout atoms `Box`/`Stack`, showing raw HTML + token-based CSS + inline style), **§6.8 `ui-molecules`** (`Field` composing atoms only), **§6.9 `ui-organisms`** (`LoginForm` composing molecules + atoms only); apps renumbered to §6.10/§6.11 with updated `dependencies`, `transpilePackages`, and an atom-composed `page.tsx`.
- **Generated `DESIGN.md` template — §0 rewritten to a 4-layer pipeline** with a per-layer capability table (only `ui-atomics` may use raw HTML/inline style; molecules/organisms/apps compose only) and per-layer Do/Don't, plus updated rules (layout via `Box`/`Stack` atoms, inline-style is atom-only and token-first, props-based variation) and a rewritten self-check checklist.
- **Generated `CLAUDE.md` template — 디자인시스템·아키텍처·코딩 컨벤션·금지사항 sections** updated to the atomic pipeline and the "raw HTML/inline style only in `ui-atomics`" boundary.
- **`skills/u-createproject/SKILL.md`** — folder tree, Step 2 (CLAUDE/DESIGN descriptions), Step 3 package generation order (atomics → molecules → organisms), Step 4/§6 cross-refs, Dependency Flow, Constraints table, Step 6 commit message, Step 10 summary; `version` 1.3.0 → 1.4.0.
- **`skills/u-dev/SKILL.md` rule #7** re-aligned to the Atomic Design pipeline — raw HTML/CSS/inline style only in `ui-atomics`, higher layers compose only, gap-surfacing extends the appropriate tier; Storybook hint `--filter=ui-common` → `--filter=ui-atomics`.
- **`skills/u-tools-browser/SKILL.md`** — Storybook start hint `--filter=ui-common` → `--filter=ui-atomics`.

### Migration

- Existing scaffolded projects keep working — the change only affects **newly created** projects. To adopt the new structure in an existing project, rename/split `ui-common`/`ui-backoffice`/`ui-app` into `ui-atomics`/`ui-molecules`/`ui-organisms` and move raw-HTML/inline-style code down into atoms.

## [4.0.0-alpha.28] — 2026-06-27

**The side-effect gate is now OFF by default, and its mode is settable three ways — env `U_MAKER_EDIT_GATE`, the new `/u-dev`·`/u-build --sideeffect {off|on|strict}` skill param, or the project state file — with `on` as a friendly alias of `auto`.**

Since `4.0.0-alpha.24` the gate defaulted to `auto`, so a behavior-modifying fix to shared, already-implemented code always forced a native approval prompt. Per the user requests — *"sideeffect check/guard를 on/off 할 수 있도록 해줘. default는 off"* and *"skill의 param으로 설정할 수 있도록"* — the gate is now **disabled by default** and runs only when explicitly enabled, and the mode can be set from a skill param (persisted per project) in addition to the environment. `on` = `auto` makes it a simple on/off switch; `auto` and `strict` keep working unchanged for back-compat.

### Added

- **`/u-dev`·`/u-build --sideeffect {off|on|strict}` skill param + a project state file.** Passing the param persists the mode to `.u-maker/.state/edit-gate-mode` (a raw token, or `{"mode":…}`), so the gate is toggled without touching the environment. `/u-build` writes it once in Step 0 — before its design/dev sub-phases — so it applies to **every** edit in the build; `/u-dev` does the same for a standalone run. `on` = `auto`.

### Changed

- **`hooks/on-edit-guard.js` — default flipped `auto` → `off`, `on` added as an alias of `auto`, and the mode is now resolved PER PROJECT.** Precedence (highest first): env `U_MAKER_EDIT_GATE` > state file `.u-maker/.state/edit-gate-mode` > default `off`. Each source maps `on` / `auto` → the 3-signal low-noise policy (already-implemented · depended-upon · behavior-modifying), `strict` → every add+modify to every existing file, and `off` / unset / unrecognized → abstain (fall through to the next source; final default `off`). The gate logic is otherwise unchanged (`on` normalizes to `auto`), so once enabled the behavior is identical to before. **With no source enabling it, no side-effect approval prompt ever fires** — forward construction and fixes alike proceed uninterrupted.
- **Docs synced to the new default + param** — `hooks/hooks.json` description; `skills/u-dev/SKILL.md` (usage + Step 0.5 persist action) and `skills/u-build/SKILL.md` (usage, args table, Step 0 persist action, gate note); `skills/u-dev/references/change-safety.md` (Gate-mode header lists the three sources, `off (default)` + `on (= auto)` table rows) and `code-gen-rules.md`; `agents/u-agent-dev.md` and `agents/u-agent-build.md` (gate OFF by default, opt-in via `--sideeffect` / env).
- **To restore the previous protection**, set `U_MAKER_EDIT_GATE=on` (or run `/u-dev --sideeffect on`), or `=strict` for maximum caution. The agent-side Step 0.5 change-safety analysis remains available as guidance regardless of gate mode.

## [4.0.0-alpha.27] — 2026-06-26

**Single-side accent border ban is now gate-ENFORCED, not just documented: GK-07 gains a `no-single-side-accent-border` check, and the rule is wired into every HTML generator + the report agent.**

The "한쪽 border만 강조 금지" rule has existed in `html-engine.md` since `4.0.0-alpha.23` and the shipped templates already comply — but it was a generation-time guideline with **no verification step**, so a decorative single-side border could still slip into HTML output (e.g. an agent injecting `border-left: 4px solid {accent}` or a color-bar `active` state) without being caught. This release gives the ban teeth and closes the coverage gaps the user asked to exclude.

### Changed

- **`_meta/schemas/gate-rules.json` — GK-07 (Visual Adequacy) gains the `no-single-side-accent-border` check** and an expanded description: emphasis must use a full 4-side `border` + background tint + `font-weight`; decorative single-side `border-left/right/top/bottom` bars and color-bar active states are a violation. Neutral 1px dividers, focus rings, and chart/timeline data markers remain allowed. Violations now cost GK-07 score → can drop a doc below the pass (95) / deploy (98) thresholds.
- **`skills/u-engine/references/html-engine.md` §Border/Accent — promoted to a HARD RULE** explicitly scoped to **all** HTML output (document output, wireframe, design system, reports, roadmap) and cross-linked to the GK-07 enforcement check (violation ⇒ 감점/FAIL).
- **Generation-time reinforcement at the two riskiest free-form HTML paths** — `skills/u-output/SKILL.md` Step 3 and `agents/u-agent-report.md` Step 4 now call out the single-side accent border ban inline (with the 4-side border + bg-tint + weight alternative), so the agent applies it while emitting markup rather than relying solely on reading the full engine reference.
- **`skills/u-gatekeeping/references/doc-scoring.md` — GK-07 row** updated to name the single-side accent border ban.
- **No template changes needed** — an audit of all `_meta/templates/*.html` + skill templates (output, split, daily-report, design-system, wireframe, roadmap) confirmed every existing single-side border is a **neutral** divider or an **allowed** Gantt/chart data-marker; none are decorative accent bars. The change is enforcement + visibility, not a template fix.

## [4.0.0-alpha.26] — 2026-06-26

**Side-effect gate de-noised a THIRD time + an emphasized impact banner: in `auto` it now fires ONLY on a behavior-MODIFYING fix to shared, implemented code — purely additive edits pass silently — and every prompt leads with `⚠️ SIDE-EFFECT IMPACT — 사이드이펙트 영향도 있음`.**

The `4.0.0-alpha.25` gate required two signals — *already-implemented* (git-tracked + clean) **AND** *depended-upon* (imported by another file). But in a settled repo almost every meaningful file is **both** tracked+clean **and** imported somewhere, so the gate still fired on the first touch of nearly every shared file. This release adds the missing discriminator the user asked for — *"fix하는 경우에만 … 사이드이펙트가 있을 수 있는 경우에만 물어본다"* — distinguishing a **fix that changes existing behavior** from **forward construction that merely adds code**: a third signal **(C) MODIFYING** gates only when the edit rewrites/deletes existing lines, while **purely additive** insertions to a shared file (which leave every existing line dependents rely on intact) now pass freely. It also makes the impact **unmistakable**: every approval prompt leads with an emphasized side-effect banner.

### Changed

- **`hooks/on-edit-guard.js` — `auto` mode now requires THREE signals, not two.** A file is gated only when it is **(A) already-implemented** (git-tracked AND clean vs HEAD) **AND (B) has dependents** (≥1 other source file imports/references it) **AND (C) the edit MODIFIES existing code** rather than purely adding to it. (C) is computed from the tool input: **Edit/MultiEdit** are additive iff every `new_string` contains its `old_string` verbatim (an insertion around untouched code); **Write** is additive iff the new content contains the entire existing file verbatim (append/prepend/wrap); **Bash** mutations (`sed -i` / redirect / `rm` / `mv` / interpreter writes) are inherently modifying. **Purely additive** edits to shared, implemented files now pass freely — forward construction in an existing file no longer prompts. Only a genuine behavior-changing fix to depended-upon code is gated.
- **Emphasized impact banner on every prompt.** The native approval prompt (`permissionDecisionReason`) and the injected `systemMessage` now **lead with** `⚠️  SIDE-EFFECT IMPACT — 사이드이펙트 영향도 있음  ⚠️`, then name the affected dependents — so it is immediately clear the change can ripple into other features/UI (사용자 지시: *"사이드이펙트 영향도가 있다는 강조된 표현을 꼭 보여주도록"*).
- **`strict` mode unchanged in spirit** — still gates EVERY change (add *or* modify) to EVERY existing file (no implemented/dependent/additive checks; `git apply`/`patch` also gated), for git-less projects or maximum caution. **`off` unchanged.**
- **Known boundary (new, documented, by design):** **Boundary 3 — the additive/modifying split is structural.** An insertion that still alters runtime behavior for existing callers (e.g. an early `return` / guard clause spliced into a function) reads as *additive* and passes silently. That residual **behavior-delta** remains the agent's responsibility under the `/u-dev` Step 0.5 impact analysis. (Boundary 2 stands: HTTP API routes / DB schema / env contracts are cross-feature surfaces the import-graph heuristic does not detect.)
- **Docs realigned to the NEW / IN-PROGRESS / IMPLEMENTED·LEAF / IMPLEMENTED·SHARED·(ADDITIVE|MODIFYING) model** — `skills/u-dev/references/change-safety.md` (purpose, gate-mode table, §1 ADDITIVE/MODIFYING split + Boundary 3, §2/§4 scoped to MODIFYING + banner), `skills/u-dev/SKILL.md` Step 0.5, `agents/u-agent-dev.md`, `skills/u-build/SKILL.md`, `agents/u-agent-build.md`, `skills/u-dev/references/code-gen-rules.md`, and the `hooks/hooks.json` description.

## [4.0.0-alpha.25] — 2026-06-26

**Side-effect gate de-noised again: it now fires only on fixes to already-implemented code THAT OTHER CODE DEPENDS ON — not on every committed file.**

The `4.0.0-alpha.24` gate scoped to *already-implemented* (git-tracked + clean) files. But in a settled repo **almost every file is tracked + clean**, so "already-implemented" effectively meant "everything" and the gate fired on nearly every edit. This release adds the missing discriminator the user asked for — *"fix하는 경우에만 다른 기능이나 UI/UX에 사이드이펙트가 있을지 검토하고, 사이드이펙트가 있을 수 있는 경우에만 물어본다"*: a fix is only gated when the file is **depended upon** (imported/referenced by another source file), so changing it can actually ripple into other features. Self-contained **leaf** files (standalone pages, framework entries, tests, modules nothing imports) now pass freely.

### Changed

- **`hooks/on-edit-guard.js` — `auto` mode now requires TWO signals, not one.** A file is gated only when it is **(A) already-implemented** (git-tracked AND clean vs HEAD) **AND (B) has dependents** (≥1 other source file imports/references it). (B) is a reverse-dependency scan via `git grep` over a quoted module-specifier whose last path segment matches the file's module name (basename without extension; parent-dir name for `index.*`; framework entries like `page`/`route`/`layout`/`middleware`/`_app` are treated as leaves since they are loaded by convention, not imported). **Leaf** implemented files (no importers) now pass freely — a fix there cannot side-effect other features. The native approval prompt now **names the affected dependents** (e.g. *"2 other file(s) import/reference it: src/App.tsx, …"*) so approval is informed.
- **`strict` mode unchanged** — still gates every existing file (incl. `git apply`/`patch`), for git-less projects or maximum caution. **`off` unchanged.**
- **`auto` no longer gates `git apply` / `patch`** — their targets live in the patch body, so the blast radius is unknowable; gating them was pure noise. They remain gated in `strict`. (`sed -i` / `perl -i` / redirects / `rm` / `mv` / `cp`·`tee`·`dd` destinations / `git rm`·`checkout --`·`restore` / interpreter inline writes are still resolved to concrete targets and gated only when the target is implemented·shared.)
- **Known boundary (documented, by design):** the dependent check is an **import-graph heuristic**. Cross-feature contracts not expressed as imports — **HTTP API routes, DB schema/migrations, env contracts** — do NOT trip the guard; they remain the agent's responsibility under the `/u-dev` Step 0.5 change-safety protocol.
- **Docs realigned to the NEW / IN-PROGRESS / IMPLEMENTED·LEAF / IMPLEMENTED·SHARED model** — `skills/u-dev/references/change-safety.md` (purpose, gate-mode table, §1 LEAF/SHARED classification + Boundary 2, §2/§4 scoped to SHARED), `skills/u-dev/SKILL.md` Step 0.5, `agents/u-agent-dev.md` (Step 0.5 + Side-Effect Safety FAIL), `skills/u-build/SKILL.md`, `agents/u-agent-build.md`, `skills/u-dev/references/code-gen-rules.md`, and the `hooks/hooks.json` description.

## [4.0.0-alpha.24] — 2026-06-25

**Side-effect gate de-noised: it now fires only on FIXES to already-implemented code, not on every edit.**

The `4.0.0-alpha.23` side-effect gate asked for approval before modifying **any** existing file, so during normal development it fired on almost everything. It now scopes to the user's actual intent — *"버그나 이미 구현된 기능이나 UI/UX를 fix하는 경우에만"* — by detecting "already-implemented" automatically via git.

### Changed

- **`hooks/on-edit-guard.js` — gate scope narrowed to ALREADY-IMPLEMENTED code.** A file is gated only when it is git-**tracked AND clean vs HEAD** (committed/shipped). **NEW (untracked)** and **IN-PROGRESS (dirty/uncommitted)** files now pass freely — so forward construction and iterating on a file you just created are no longer interrupted. Touching committed code (a bug fix / change to a shipped feature or UI) still gates. No-git / not-a-repo → not gated (favor low friction; use `strict` for git-less projects).
- **New `U_MAKER_EDIT_GATE` env switch** — `auto` (default, fix-only), `strict` (every existing file = the alpha.23 behavior), `off` (disabled).
- **Bash false-positives fixed** — `install` removed from the in-place verb set (it matched package managers: `pip install -r requirements.txt`, `npm/cargo install …`); `cp` / `tee` / `dd` now gate only their **write destination**, not read-only sources/stdin (`cp shipped.ts /tmp/x` no longer fires on `shipped.ts`). Redirects, `rm` / `mv` / `sed -i` / `perl -i` / `git rm|checkout --|restore`, `git apply` / `patch`, and interpreter inline writes remain covered.
- **Docs realigned to the NEW / IN-PROGRESS / IMPLEMENTED model** — `skills/u-dev/references/change-safety.md` (classification + gate-mode table + boundary note), `skills/u-dev/SKILL.md` Step 0.5, `agents/u-agent-dev.md`, `skills/u-build/SKILL.md`, `agents/u-agent-build.md`, `skills/u-dev/references/code-gen-rules.md`, and the `hooks/hooks.json` description.

## [4.0.0-alpha.23] — 2026-06-22

**Three gatekeeping hardenings: (1) HTML 산출물에서 '한쪽 border만 강조' 장식 스타일 전면 금지, (2) 개발 시 기존 코드 수정에 대한 strict·adversarial 사이드이펙트 게이트(사용자 승인 필수, especially 버그 수정), (3) Figma/참고자료 ↔ 구현 pixel-perfect 일치성 게이트(GK-12).**

### Added

- **Side-effect gatekeeping (GOAL 2) — `hooks/on-edit-guard.js` (NEW, PreToolUse) + `skills/u-dev/references/change-safety.md` (NEW)** — a strict, default-deny gate that forces explicit **user approval** before any modification of **existing** code in a u-maker project (Edit/Write/MultiEdit and mutating Bash: `sed -i` / redirects / `rm` / `mv` …). The guard is wired **directly** in `hooks/hooks.json` as a new `PreToolUse` entry (matcher `Write|Edit|MultiEdit|Bash`), NOT through `_dispatch.js` (whose contract is "never block"). It emits `permissionDecision: "ask"` (native user confirmation) unless a fresh per-file approval marker exists under `.u-maker/.state/edit-approvals/{sha1(path)}.json` (session-TTL allowlist, `U_MAKER_EDIT_APPROVAL_TTL_MIN`, default 480m). NEW files, `.u-maker/**`, non-u-maker projects, and read-only Bash are out of scope. `change-safety.md` defines the agent-side protocol: NEW-vs-EXISTING classification → blast-radius/impact analysis → adversarial self-review → mandatory `AskUserQuestion` → approval marker → scope-lock. Applies especially to **bug fixes**.
- **Design Conformance gate (GOAL 3) — GK-12 in `_meta/schemas/gate-rules.json`** — a 12th gatekeeper criterion ("Design Conformance / 디자인 일치성") asserting the implemented UI is **pixel-perfect** to the Figma source of truth + ingested reference materials (token/layout/variant/text parity, reference-rule coverage, zero drift). Pixel-perfect GATE thresholds **SSIM ≥ 0.99 / pixel ≤ 1% / bounds ± 1px** (stricter than the Build-phase 0.95/5%/±2px). Added to `gates.gatekeeping-to-deploy.required` (`design-conformance-pass`); N/A-auto-pass only when no Figma/reference provenance exists.
- **`skills/u-tools-browser` Step 6g (screen/route ↔ Figma frame parity)** with its new reference **`skills/u-tools-browser/references/visual-verify-screens.md`**, and **`skills/u-gatekeeping` Step 2.5 (Design Conformance)** which delegates screen parity to that step — closes the screen-level parity gap (only DS-level 6e + component-level 6f existed) and makes Gatekeeping (not just transient Build-phase state) the durable owner of conformance via `.u-maker/.state/design-conformance.json`.

### Changed

- **HTML: no single-side accent borders (GOAL 1)** — `skills/u-engine` (4.0.0 → 4.1.0): `references/html-engine.md` §6 gains a **"Border / Accent Style Rules"** section banning decorative/active single-side colored borders (좌측 액센트 바, nav/tab active 컬러 바, 컬러 heading 밑줄); 강조는 전체 4변 border + 배경 틴트 + `font-weight`로. Only **1px 중립 divider / focus ring / 차트·타임라인 마커** keep a single side. Mirrored in `SKILL.md` invariants, `u-design/references/design-system-rules.md` §0 (#16), and `u-dev/references/fe-rules.md` §0 (#16). Output templates brought into compliance: `_meta/templates/output-index.template.html`, `output-page.template.html`, `output-split-page.template.html`, and `skills/u-wireframe` (4.0.0 → 4.1.0) `references/wireframe-page.template.html` (nav-active bars → bg-fill+weight, colored h2 underline → 1px neutral, tab indicator → bg-fill). Repo docs `GET_STARTED.html` / `README.ko.html` / `README.en.html` fixed (callout/feature-card left-accent bars, nav-active bars, colored heading underlines).
- **`skills/u-dev` (4.1.0 → 4.2.0)** — new **Step 0.5: Side-Effect Gatekeeping** (mandatory hard gate before editing existing code) in `SKILL.md` + `agents/u-agent-dev.md` (§3 Step 0.5 + §4 Side-Effect Safety FAIL rules); `references/code-gen-rules.md` §7.1/§7.2 tightened so `--force` / "manual confirmation" defer to the mandatory approval gate.
- **`skills/u-build` (4.0.0 → 4.1.0)** + `agents/u-agent-build.md` — `--auto` explicitly does NOT bypass the side-effect gate; an unapproved side-effect is a first-class halt.
- **`skills/u-gatekeeping` (4.0.0 → 4.1.0)** + `agents/u-agent-gatekeeper.md` — adds GK-12 to the criteria table, scorecard, and per-criterion details (default 5, **max 12**; GK-12 always gates Deploy regardless of `--loop N`); `deploy-readiness.json` now carries `designConformance` and requires it `∈ {pass, na}` for `deployReady: true`. `agents/u-agent-qa.md` adds a 7th TC type **Design-Conformance** so parity is traceable through FR→US→FT→TC.
- **`skills/u-tools-browser` (1.0.0 → 1.1.0)** — Step 6g + consumer-table row; `references/visual-verify-ds.md` / `visual-verify-components.md` silent-skip tightened (Figma provenance present but un-round-tripped → `figmaSourceUnlinked` = GK-12 fail, not a silent pass).
- **`.claude-plugin/plugin.json`** — version `4.0.0-alpha.22 → 4.0.0-alpha.23`.

## [4.0.0-alpha.22] — 2026-06-06

**Changed: project-scaffolded `DESIGN.md` now leads with a 디자인 의존 파이프라인 (`apps/* → ui-* → tokens`) — a 2-tier apps↔ui-* boundary with explicit Do/Don't, and `/u-dev` surfaces unbuildable-with-`ui-*` UI as a gap instead of emitting raw HTML.**

### Changed

- **`skills/u-createproject` (1.2.0 → 1.3.0) — DESIGN.md template (`references/scaffolding-spec.md` §7)** — new headline section **`## 0. 디자인 의존 파이프라인 (apps ↔ ui-* 경계)`** establishes that the code dependency flow applies to design too, as a two-tier model with **explicit Do ✅ / Don't ❌ blocks per tier**:
  - **`apps/*` (소비자)** — compose `ui-*` components only; variations via **props**; minimize raw HTML/CSS/inline style/`className`; semantic structural HTML (`<main>`/`<h1>`/`<p>`) is allowed and is *not* "raw HTML"; form·interactive elements and layout/visual inline `style` stay **hard-banned**. When `ui-*` **can't** express a screen, **stop and tell the user** + extend `ui-*` — never paper over the gap in `apps/*`.
  - **`packages/ui-*` (생산자)** — owns all visual styling; must comply with **both** design tokens (`var(--*)`) *and* the design-system doc; **CSS Modules (`*.module.css`) explicitly allowed in `ui-*`** (still pure CSS) alongside global `.css`.
- **Internal-consistency reconciliation (same file + `SKILL.md`)** — the soft "minimize" wording is preserved (not escalated to a ban); §5 `className` rule now scopes class composition as a **`ui-*`-internal** concern (apps don't pass `className` to override); the self-check checklist gains apps/*- and ui-*-tier items; the starter `apps/web/src/app/page.tsx` is annotated as an **intentional minimal placeholder**; CLAUDE.md summary, §3 의존 흐름, §4 기술 스택, §5 핵심 규칙, §10 금지사항 all updated to carry the pipeline + `ui-*`-only CSS-Modules allowance so no two lines contradict.
- **`skills/u-dev` (4.0.0 → 4.1.0)** — FE Step 1 gains rule #7: honor the `apps/* → ui-* → tokens` pipeline (project `DESIGN.md` §0 is the SSoT when present); when a screen needs UI `ui-*` can't express, extend `ui-*` or emit a `.state/build-gap-report.json` entry and **surface it to the user** for `/u-build` ping-pong — never silently emit raw HTML/inline style in `apps/*`.
- **`.claude-plugin/plugin.json`** — version `4.0.0-alpha.21 → 4.0.0-alpha.22`.

## [4.0.0-alpha.20] — 2026-06-06

**Changed: `/u-createproject` now scaffolds a project-level `DESIGN.md` (디자인/UI 공통 룰), auto-loaded by both Claude Code (`@DESIGN.md` import) and Codex (`AGENTS.md` symlink).**

### Changed

- **`skills/u-createproject/SKILL.md` (1.1.0 → 1.2.0) + `references/scaffolding-spec.md`** — project scaffolding now generates a root **`DESIGN.md`** documenting the design/UI rules shared by every frontend app (`web`, `admin`). The template (§7, `{{PROJECT_NAME}}` substituted) is **adapted to the actually-scaffolded packages** — the source rules (written for a different `@hyunjin/ui-*` 3-app-group repo) were remapped to this scaffold's surfaces: `admin → @{{PROJECT_NAME}}/ui-backoffice (+ ui-common)`, `web → @{{PROJECT_NAME}}/ui-app (+ ui-common)`, `backend` UI-less; token references point at the real `@{{PROJECT_NAME}}/tokens` names (`var(--color-*|--spacing-*|--radius-*|--font-*|--shadow-*)`). Per the existing scaffold philosophy ("실제 스캐폴드된 구조만 기술 — 없는 컴포넌트를 강제하지 않음"), rules that would contradict the scaffold were reconciled rather than copied verbatim: the "no `className`/`style` prop" rule became "variations via `variant`/`size`/`tone` props; `className` only for token-based class composition" (matching the scaffolded `Button`); layout primitives (Container/Stack/Grid) are framed as "extract into `ui-common` when a pattern repeats" rather than mandated; `SSoT 우선` points at the flat `.u-maker/docs/` location. Wired into Step 1 (dir tree), Step 2 (root files #6/#7), and Step 10 (completion summary) so it lands in the first git commit (Step 6 `git add -A`).
- **Cross-agent auto-load wiring** — a standalone `DESIGN.md` is auto-discovered by *neither* Claude Code nor Codex, so it's now reliably reachable from both:
  - **Claude Code** — the CLAUDE.md template's 디자인시스템 section ends with a literal **`@DESIGN.md`** import line (Claude Code import syntax, max 4 hops), pulling DESIGN.md fully into context whenever the auto-loaded CLAUDE.md loads.
  - **Codex** — scaffolding now also creates **`AGENTS.md` as a symlink to `CLAUDE.md`** (`ln -s CLAUDE.md AGENTS.md`, after CLAUDE.md/DESIGN.md exist), since Codex auto-discovers `AGENTS.md` and does **not** read `CLAUDE.md`. Codex has no import syntax, so it reads DESIGN.md **on-demand** following the guide's "작업 전 DESIGN.md 반드시 참조" instruction. git tracks the symlink (Step 6 `git add -A`); Windows checkout needs `core.symlinks=true` (noted in §7 AGENTS.md).
- **`references/scaffolding-spec.md` — CLAUDE.md template** — the CLAUDE.md 디자인시스템 section is trimmed to a **pointer** to `DESIGN.md` (single source of truth), keeping a one-line summary; `DESIGN.md` in turn points back to `CLAUDE.md` for non-design rules. Avoids the two docs drifting. New `### AGENTS.md` subsection documents the symlink + cross-agent load behavior.
- **`.claude-plugin/plugin.json`** — version `4.0.0-alpha.19 → 4.0.0-alpha.20`.

## [4.0.0-alpha.19] — 2026-06-05

**Added: `/u-reports-roadmap`. Removed: `/u-tools-jenkins-deploy` and `/u-meeting-report` skills.** Skill count 30 → 28 → 29.

### Added

- **`skills/u-reports-roadmap/`** — code-grounded interactive Gantt roadmap generator. Scans source code + git directly to scope the work (routes/screens, mock vs implemented, BE dependencies, branch/MR mining, churn), estimates a schedule from **measured git velocity modulated by team size** (dev/planner/designer counts — git-estimated then user-confirmed via `AskUserQuestion`), runs per-track **risk analysis**, and renders an **editable interactive Gantt HTML** in the reference roadmap style (vanilla CSS, light-only, draggable phase bars, milestone timeline, per-track positioning/highlights/risk notes, width switcher, localStorage autosave). Ships `assets/roadmap-template.html` (the reusable engine — copied then only its data block is edited; all calendar values derive from start+deadline via `buildTimeline()`) plus 4 references (scope-analysis, estimation-model, risk-analysis, html-template). Output: `.u-maker/reports/<date>/roadmap-<slug>-<deadline>.html` + sidecar `.data.json` for `--rerender`. Registered in `router.md`, `agents/u-agent-pm.md`, and `plugin.json` (dispatches to `u-agent-report`; prereq = source+git present).

### Removed

- **`skills/u-tools-jenkins-deploy/`** — Jenkins CI/CD setup skill removed. The `_meta/templates/u-maker-env.template` is slimmed accordingly: all Jenkins / Docker Hub / Git PAT / deploy-target SSH credential keys (consumed only by this skill) are dropped, leaving the `.u-maker/.env` scaffold header for future integrations. `/u-prepare-foldertree` still bootstraps `.u-maker/.env(.example)` from the (now-minimal) template.
- **`skills/u-meeting-report/`** — audio/text → meeting-minutes HTML skill removed.
- **References cleaned up** — removed routing entries from `skills/u-engine/references/router.md` (dispatch table, intent classification, skill map, prerequisites) and `agents/u-agent-pm.md`; updated `plugin.json` description (28 skills); removed command rows from `README.md` and the published HTML docs (`README.ko.html`, `README.en.html`, `GET_STARTED.html`). The deleted commands' history remains in earlier changelog entries (alpha.12).

## [4.0.0-alpha.18] — 2026-06-03

**Added: `/u-doc` (alias `/u-ssot`) — SSoT ingest + document reorganization. Changed: `/u-createproject` now scaffolds a project-specific `CLAUDE.md`.**

A new cross-cutting skill plus a scaffolding enhancement. Skill count 28 → 30.

### Added

- **`skills/u-doc/SKILL.md` (+ `references/ingest-rules.md`, `references/reorg-rules.md`)** — new two-mode SSoT helper.
  - **Ingest** — normalizes an arbitrary input (file / image / link / text) into `data/dropzone/`, reuses the `/u-analyze` digest pipeline (digest-engine), and **suggests** which app / SSoT doc / section it belongs to. Does **not** edit SSoT docs directly; actual document reflection stays with `/u-plan` · `/u-design` (chosen non-destructive policy). Figma sources auto-delegate to `/u-tools-figma`.
  - **Reorganize** — tidies `.u-maker/docs · output · reports` to the standard structure. Tree-aware: `docs/` (tracked SSoT) → `git mv` + `links.json` path sync; `output/` · `reports/` (gitignored, generated) → regenerate via `/u-output` · `/u-report` (no hand-move of artifacts). Always dry-run + confirm; never deletes.
  - Provides the previously-absent user entry point that `doc-engine.md` referenced as `/u-add` · `/u-update` (input side only — collection + placement suggestion).
- **`skills/u-ssot/SKILL.md`** — thin alias of `/u-doc` (mirrors the `/u-init` · `/u-check` · `/u-qa` stub pattern).

### Changed

- **`agents/u-agent-pm.md`** — registered `/u-doc` + `/u-ssot` in alias resolution (§1), the command routing table (§2), and global alias forwarding (§7, `/u-ssot → /u-doc`).
- **`skills/u-createproject/SKILL.md` (1.0.0 → 1.1.0) + `references/scaffolding-spec.md`** — project scaffolding now generates a project-specific **`CLAUDE.md`** agent guide (§7 template, `{{PROJECT_NAME}}` substituted), wired into Step 2 so it lands in the first git commit. The guide documents only the actually-scaffolded structure (web:3000 / admin:3001 / backend:2920, ui-common/ui-backoffice/ui-app, Clean Architecture, conventions, prohibitions). Also fixed the starter `page.tsx` inline-style padding (`.page-main` class) so the scaffold obeys the layout rule its own generated CLAUDE.md mandates.
- **`.claude-plugin/plugin.json`** — version `4.0.0-alpha.17 → 4.0.0-alpha.18`; description skill count 28 → 30, `/u-doc` + `/u-ssot` listed.

### Notes

- `/u-doc` Ingest is intentionally non-destructive (digest + placement suggestion only); it overlaps `/u-analyze` for digest generation and reuses that logic rather than reimplementing it.
- Reorganize `output/` ↔ `out/` root: `doc-engine.md` uses a legacy `out/` path for design-system while the standard is `output/`. The drift-detector treats both roots as valid and confirms before moving, to avoid false positives. Reconciling the source inconsistency is tracked separately.
- The `/u-doc` skill and the `/u-createproject` CLAUDE.md change are independent features and may ship as separate PRs.

## [4.0.0-alpha.17] — 2026-06-02

**Fixed: `deploy_local` — Windows install + duplicate skill symlinks.**

Maintenance release. No new commands or plugin-wide functional changes.

### Fixed

- **`deploy_local.bat`** — repaired Windows install: a `PATH` clobber and a `cmd` parenthesis parse error that broke the installer.
- **`deploy_local.sh`** — removed legacy `u-maker__*` skill symlinks that duplicated the plugin's own skill entries (see PR [#90](https://github.com/thinoo-v2/u-maker-plugin/pull/90)).

## [4.0.0-alpha.16] — 2026-05-24

**Changed: `/u-tools-git-pr` v5.1 — guaranteed clean working tree + table-based confirmation UI.**

Two refinements to the standalone PR generator skill. No new commands, no plugin-wide functional changes.

### Changed

- **`skills/u-tools-git-pr/SKILL.md` (v5.0.0 → v5.1.0)** — adds **Completeness Policy** at the top: the skill must terminate with `git status --porcelain` empty. `.gitignore`'d files are excluded automatically (git default — `--ignored` flag explicitly forbidden); `git add -A` / `git add .` forbidden in favor of per-group explicit file lists.
- **New Step 5.5: Verify Working Tree (safety net)** inserted between the group loop (Step 5) and the summary (Step 6). After the user-selected groups are processed, `git status --porcelain` is re-checked regardless of branch state. If files remain (e.g., partial `[3]` selection, unclassified paths on a feature branch with uncommitted local changes), a structured multiline-box prompt asks the user `[1] commit leftovers as misc PR (recommended)` or `[2] terminate with files retained`. The `misc` path creates a `chore/misc-leftover-{ts}` branch and re-verifies after commit. `--dry-run` shows the leftover count without executing.
- **Step 6 summary** now prints `Working tree clean ✓` when post-5.5 status is empty, or `Working tree has {N} uncommitted files (user-skipped)` when the user chose `[2]`.
- **`skills/u-tools-git-pr/references/confirmation-ux.md`** — full rewrite from ASCII-box prompts to a **table-based UI**. Groups now use `A`/`B`/`C` letter labels (consistent with the `3 A,B` partial-selection grammar). Stats line uses `M`/`A`/`D` shorthand; recommended strategy is surfaced inline. Adds an explicit **Edge cases** section (lone `Y` no longer auto-accepts; undefined labels re-prompt; single-group `3 ...` input re-confirms) and a `Dry-run summary` trace block aligned with the new Step 4 → Step 5 → Step 5.5 flow.

### Notes

- Partial-selection `[3] A,C` behavior changed: previously the unselected files were left in the working tree; now they are routed to Step 5.5 for misc-commit confirmation. Default policy is "no leftover files."
- Skill-level version bump only (`5.0.0 → 5.1.0` in skill frontmatter); plugin version follows the standard alpha increment.
- Feature-branch users with both committed-since-divergence changes **and** uncommitted local edits will now see the Step 5.5 sweep run unconditionally — surfacing the uncommitted files instead of silently leaving them.

## [4.0.0-alpha.15] — 2026-05-24

**Bugfix: plugin hook loader.** Restores reactive hooks that were silently failing to load since the Claude Code plugin hook schema migration. No user-facing functional changes; this only re-enables the four PostToolUse hooks that maintain `.u-maker/data/digest/_index.json`, doc↔JSON sync flags, loop-state thresholds, and deploy-staleness manifest.

### Fixed

- **`hooks/hooks.json`** — migrated from the legacy custom array format (`[{event, tool[], pattern, script, timeout(ms)}]`) to Claude Code's current plugin hook schema (event-keyed record with `matcher` + `command` shape). Single `PostToolUse` / `Write|Edit|MultiEdit` matcher routes all four hooks; timeouts converted ms → s. The plugin loader had been erroring at session start (`expected record, received array`), suppressing every hook.

### Added

- **`hooks/_dispatch.js`** — new shim that bridges Claude Code's stdin-JSON subprocess contract to the existing CommonJS hook modules (`on-dropzone-added.js`, `on-doc-change.js`, `on-gate-result.js`, `on-deploy-state.js`). Reads `tool_input.file_path` and `CLAUDE_PROJECT_DIR` from the hook payload, requires the legacy module, and invokes it with `({filePath, projectRoot})`. Always exits 0 — reactive hooks never block the agent. Per-hook path filtering inside each `on-*.js` is preserved unchanged.

### Notes

- Tested end-to-end via dispatcher: `on-dropzone-added` produces the expected `_index.json` (sha256 + status:pending) for a sample dropzone write. Mismatched path / empty stdin / non-matching tool name all exit 0 silently.
- No script bodies were modified — this release is purely a wiring fix.
- See PR [#89](https://github.com/thinoo-v2/u-maker-plugin/pull/89) for full diff and root-cause writeup.

## [4.0.0-alpha.14] — 2026-05-24

**Internal: CI/CD automation — Release + Vercel deploy GitHub Actions workflows.**

No user-facing plugin changes. Adds GitHub Actions to automate the release flow that previously required running `deploy_github.sh` + `deploy_vercel.sh` by hand. This is the first release executed end-to-end through the new pipeline.

### Added

- **`.github/workflows/release.yml`** — on `git push origin v*` (tag push): build `u-maker-plugin-${TAG}.zip` → GitHub Release on this repo (via `softprops/action-gh-release`) → force-sync README + HTML + install scripts to `upleat-ax/u-maker-plugin` → GitHub Release on the public repo with the same zip.
- **`.github/workflows/vercel-deploy.yml`** — on `main` push touching `README*.html` / `GET_STARTED.html` / `.claude-plugin/plugin.json` / the workflow file itself, plus manual `workflow_dispatch`: copy the 3 HTML docs + project link → `vercel pull` → `vercel deploy --prod` → curl-verify each public URL on `umaker.upleat.ai`.
- **`.github/AUTOMATION.md`** — maintainer guide covering both workflows, required secrets (`UPLEAT_PUBLISH_TOKEN`, `VERCEL_TOKEN`), the standard release flow after automation, the local fallback scripts, and what is still manual (CHANGELOG narrative, catalog table rows, SVG layer breakdown).

### Removed

- **`.github/workflows/publish.yml`** — superseded by `release.yml`. The old workflow only mirrored README + install scripts on tag push without building a zip or creating a Release.

### Notes

- Required secret `VERCEL_TOKEN` was added to repo settings; existing `UPLEAT_PUBLISH_TOKEN` is reused for the public-repo sync.
- Local scripts `deploy_github.sh` / `deploy_vercel.sh` remain as authoritative fallbacks; the workflows mirror their logic rather than extend it. Keep them in sync if you change the publishable file set.
- Post-automation standard release flow (see AUTOMATION.md):
  1. Edit `CHANGELOG.md` + bump `plugin.json` + sync README/HTML version strings.
  2. Open a PR, merge to main — `vercel-deploy.yml` refreshes `umaker.upleat.ai` automatically.
  3. `git tag -a vX.Y.Z` + `git push origin vX.Y.Z` — `release.yml` handles zip + both Releases + public-repo sync automatically.

## [4.0.0-alpha.13] — 2026-05-24

**Changed: 28-skill quality review fixes — sanitize, trigger hardening, progressive disclosure, Korean coverage, official-schema compliance.**

Comprehensive cleanup pass on all 28 skills following a multi-agent (5 reviewer) quality review. Touches every `skills/*/SKILL.md`, sanitizes `u-meeting-report/AGENTS.md`, and introduces 14 new `references/*.md` files for progressive disclosure. Plugin remains backward-compatible — no command renames, no behaviour changes; only documentation, frontmatter, and split-file organization.

### Fixed (Critical)

- **`skills/u-meeting-report/`** — frontmatter `name` was incorrectly `the-voice-meeting` (a separate system skill) → corrected to `u-meeting-report`. All 9 internal references to `~/.claude/skills/the-voice-meeting/...` (scripts, assets, `.env`) replaced with `${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-report/...`. Removed `/Users/thinoo/...` absolute path leak from `AGENTS.md`. The plugin's bundled `scripts/`, `assets/`, and `references/` for this skill are now actually consumed; the plugin is standalone-portable.
- **`skills/u-wireframe/SKILL.md`** — frontmatter `version: 3.2.0` → `4.0.0` (matches all peer phase skills).

### Changed (High)

- **Generic trigger hijack mitigation (6 skills)** — replaced overly-broad triggers that intercepted unrelated input with `u-maker`/`Turborepo` prefix qualifiers:
  - `u-qa`: `"QA"` → `"u-maker QA"`, `"u-qa runtime QA"`
  - `u-init`: `"initialize"` → `"u-maker init"`, `"u-maker initialize project"`
  - `u-check`: `"check phase"` → `"u-maker check"`, `"u-maker gatekeeping check"`
  - `u-createproject`: Korean generic `"프로젝트 생성"`/`"새 프로젝트"`/`"모노레포 생성"` → `"u-maker 프로젝트 생성"`/`"Turborepo 모노레포 스캐폴드"` etc.
  - `u-loop`: `"auto loop"`/`"full pipeline"` → `"u-maker auto loop"`/`"u-maker full pipeline"`
  - `u-tools-browser`: added missing `"playwright"`, `"agent-browser"`, `"screenshot"`, `"visual regression"`, `"a11y audit"`, `"figma parity"` so DS verify / capture flows match correctly.
- **`skills/u-engine/SKILL.md`** — description rewritten as internal-only (`INTERNAL INFRASTRUCTURE — not directly invoked by users`) to prevent LLM auto-invocation. 50-line `HTML Generation Protocol` body collapsed into pointer to existing `references/html-engine.md`. 110 → 68 lines.
- **Progressive disclosure refactor (6 large skills → 14 new `references/*.md`)** — total 2,050 → 1,339 lines (-35%):

  | Skill | Before | After | Δ | new refs |
  |---|---:|---:|---:|---:|
  | `u-tools-browser` | 501 | 305 | -39% | 4 (`backend-detection`, `visual-verify-ds`, `visual-verify-components`, `failure-handling`) |
  | `u-prepare-foldertree` | 285 | 126 | -56% | 2 (`foldertree-layout`, `migration-rules`) |
  | `u-output` | 286 | 175 | -39% | 2 (`screens-rendering`, `erd-rendering`) — folder newly created |
  | `u-tools-jenkins-deploy` | 365 | 309 | -15% | 3 (`credentials`, `nginx-tls`, `jenkins-gotchas`) |
  | `u-tools-git-pr` | 301 | 189 | -37% | 2 (`classification-rules`, `confirmation-ux`) |
  | `u-wireframe` | 312 | 235 | -25% | 1 (`wireframe-rendering-rules`) |

### Added

- **Korean trigger coverage** — 22 skills enriched. 26/28 skills are now Korean-searchable in addition to English (e.g., `"u-maker 기획"`, `"와이어프레임 생성"`, `"u-maker 배포"`, `"피그마 분석"`). `u-engine` is internal-only by design; `u-meeting-report` is covered via description-only Korean keywords.

### Changed (Frontmatter standardization)

- **All 26 skills** with a non-standard `triggers:` array migrated to the **official Claude Code schema** (`name`/`description`/`version` only). Every trigger keyword (English + Korean) was preserved by integrating them into `description` as quoted strings, matching the convention of all 5 official `plugin-dev/*` skills. Max resulting description length: 637 chars (`u-tools-browser`). This guarantees skill matching works even if the runtime ignores the non-spec `triggers:` field. `u-engine` and `u-meeting-report` were already description-only.

### Notes

- File stats: 43 files changed in PR #85, +1,118 / −1,019.
- Smoke test (manual, post-merge): in a fresh Claude Code session, type `/u-` to confirm all 28 skills autocomplete without duplicates, and try Korean phrases (`"u-maker 기획"`, `"와이어프레임 생성"`, `"회의록 작성"`) to confirm description-only matching.
- No migration required for existing projects — only documentation/frontmatter changed; no command renames or behavior changes.

## [4.0.0-alpha.12] — 2026-05-23

**Added: `.u-maker/.env` credential file + `/u-tools-jenkins-deploy` skill.**

Introduces a project-local credential file at `.u-maker/.env` (gitignored) for skills that need to authenticate to external systems, and ports the `u-tools-jenkins-deploy` skill into the plugin as the inaugural consumer.

### Added

- **`_meta/templates/u-maker-env.template`** — `.env.example` content. Enumerates credential keys consumed by skills: Jenkins (`JENKINS_URL`/`JENKINS_USER`/`JENKINS_TOKEN`, plus optional `JENKINS_SSH_*`), Docker Hub (`DOCKERHUB_NAMESPACE`/`DOCKERHUB_USER`/`DOCKERHUB_TOKEN`), Git host PAT (`GIT_HOST_USER`/`GIT_HOST_PAT`), and deploy-target SSH (`DEPLOY_TARGET_HOST`/`DEPLOY_TARGET_USER`/`DEPLOY_TARGET_PASS`/`DEPLOY_TARGET_PORT`). Empty values mean "ask interactively when needed."
- **`/u-prepare-foldertree` Step 1.5.1** — On fresh init, writes `.u-maker/.env.example` and bootstraps `.u-maker/.env` from the template (never overwrites an existing `.env`). Migration path (Step 2.3) does the same for legacy projects.
- **`/u-prepare-foldertree` Step 1.7** — Adds `.u-maker/.env` to the project `.gitignore` so secrets never land in git. `.env.example` is committed.
- **`skills/u-tools-jenkins-deploy/`** (new) — Jenkins CI/CD setup skill ported from `~/.claude/skills/u-maker__u-tools-jenkins-deploy/`. Same Phase 1–8 pipeline (Jenkinsfile generation → credential registration → job creation → nginx + TLS → webhook/polling → first build) plus a new **Phase 0** that loads `.u-maker/.env` and resolves Jenkins/Docker Hub/Git/target-SSH credentials before prompting. Precedence: CLI flag → `.u-maker/.env` → interactive prompt. Templates (`Jenkinsfile`, `Dockerfile`, `Dockerfile.dockerignore`, `nginx-server-block`) ship under `templates/`.

### Why

Without `.u-maker/.env`, every Jenkins / Docker Hub / SSH setup forced the user to paste tokens and passwords directly into chat — captured in transcripts, easily leaked, and re-asked on every session. A project-local, gitignored env file lets users set credentials once and have skills consume them on demand. The `/u-tools-jenkins-deploy` skill is the first consumer; subsequent skills can extend the same file rather than each inventing their own location.

### Notes

- `.u-maker/.env.example` is committed verbatim from `_meta/templates/u-maker-env.template`. Adding a new key for another skill = edit the template; future `/u-prepare-foldertree` runs propagate it to new projects.
- Existing projects pick up the file on the next `/u-prepare-foldertree --migrate` (or any rerun — Step 2.3 is idempotent).

## [4.0.0-alpha.5] — 2026-04-19

**Changed: Figma parity is now a mandatory hard gate.**

When a Design System originated from Figma (extracted via `/u-tools-figma-ds` or registered with `dsFileKey` in `data/figma/manifest.json`) and is implemented as HTML/CSS, the browser MUST verify identity with Figma. Previously this was an opt-in pixel diff; now it is a non-skippable parity check that blocks `/u-design` and `/u-dev` from completing on failure.

### Changed

- `/u-tools-browser` Step 6e (DS HTML Verification) — added sub-step **6e.8 Figma parity check (mandatory)**:
  - Pulls Figma reference screenshots via `mcp__plugin_figma_figma__get_screenshot` and Variable defs via `get_variable_defs`.
  - Token parity: every Figma Variable mapped to a CSS variable must match (color ΔE < 1 in OKLCH; dimensions ±0.5 px).
  - Per-frame screenshot diff: SSIM ≥ 0.95 AND pixel diff ≤ 5 %.
  - Coverage parity: every Figma component ↔ every `CMP-{nnn}` in the HTML.
  - Unauthenticated Figma session → HALT (never silent skip). Override with `--no-figma-parity` (logged).
  - `result` rules tightened: any parity failure forces top-level `result == "fail"` (cannot be downgraded to `partial`).
- `/u-tools-browser` Step 6f (Component Verification) — Figma diff promoted from "optional" to **mandatory** when `components[*].figmaKey` is set:
  - Per-variant / per-state pixel diff (SSIM ≥ 0.95, pixel diff ≤ 5 %, bounds ±2 px).
  - Token resolution parity against Figma Variable bindings.
  - Same HALT-on-unauthenticated rule as Step 6e.
- `/u-tools-browser` Options — added `--no-figma-parity`, `--figma-diff-threshold {pct}` (default 5), `--figma-ssim-threshold {0..1}` (default 0.95).
- `/u-tools-browser` Anti-patterns — explicit prohibitions: silently skipping parity, downgrading parity failure to `partial`, try/catch-ing the parity check away.
- `/u-design` Step 4a.10 — promoted to **hard gate**. On parity `fail`, re-runs Steps 4a.3–9 (max 3 retries); never proceeds to Step 4b without parity pass. `partial` allowed only for non-parity issues.
- `/u-dev` Step 1.5 — promoted to **hard gate**. On parity `fail`, re-runs Step 1 for failing components only (max 3 retries); never proceeds to Step 2 (BE) without parity pass.

### Rationale

When the user describes the workflow as "extract DS from Figma → implement in HTML/CSS → verify identical", the browser is the only authority that can confirm "identical". Anything weaker (token-only diff, manual review) misses CSS specificity, browser rendering quirks, and unbound hardcoded values. Making the gate mandatory ensures the implemented DS cannot ship with silent visual drift from its Figma source.

### Added

- `--no-figma-parity` flag for explicit, audited overrides (e.g., when intentionally diverging).
- Per-component diff PNG triplets (figma / impl / diff) under `.u-maker/.state/visual-verify/diffs/`.

## [4.0.0-alpha.4] — 2026-04-19

**Added: Browser-driven visual verification for HTML-first DS and implemented components.**

After `/u-design` Step 4a writes `out/{app}/design/design-system.html` and after `/u-dev` Step 1 generates FE components, the browser now verifies them automatically — no manual "open the file and look" loop.

### Added

- `/u-tools-browser` Step 6e — **Design System HTML Verification**. Opens the static `design-system.html` via `file://`, samples every `:root` CSS variable, asserts every `CMP-{nnn}` showcase + variant + state selector is present, toggles `[data-theme="dark"]`, runs a Lighthouse / axe-core a11y audit, and captures full-page light + dark screenshots. Result persisted at `.u-maker/.state/visual-verify/{app}-design-system.json`.
- `/u-tools-browser` Step 6f — **Component Implementation Verification**. Renders each `CMP-{nnn}` in Storybook (preferred) or the app, samples computed styles, asserts variant/state selectors, optionally pixel-diffs against the linked Figma component (when `figmaKey` is set), runs per-subtree a11y audit. Result at `.u-maker/.state/visual-verify/{app}-components.json`.

### Wired

- `/u-design` Step 4a.10 — auto-delegates to `/u-tools-browser` Step 6e after `design-system.html` is written. On `result == "fail"` (missing tokens, broken dark mode, WCAG-AA contrast violation), re-runs Steps 4a.3–9 with the diff as improvement list (max 3 retries).
- `/u-dev` Step 1.5 — auto-delegates to `/u-tools-browser` Step 6f after FE components are generated. On `result == "fail"`, re-runs Step 1 for failing components only (max 3 retries). Skipped when `--only be|db` or zero FE files changed.
- `/u-tools-browser` Consumer Integration Table — two new rows for the 6e / 6f entries.

### Notes

- Both verifications are **mandatory** under default mode (`--auto` runs them headless). The `--no-screenshot` flag suppresses captures but still runs the assertions.
- The Figma diff sub-step in 6f is **opt-in** — only runs when `mcp__plugin_figma_figma__get_screenshot` is reachable AND `components[*].figmaKey` is populated by `/u-tools-figma-ds`.

## [4.0.0-alpha.3] — 2026-04-19

**Added: Figma writer skills.**

Adds two new write-side skills under the `u-tools-*` namespace, complementing the existing read-only `/u-tools-figma` analyzer. Both delegate Figma mutations to the `figma` plugin (`figma:figma-generate-design`, `figma:figma-generate-library`) so u-maker stays as the orchestration layer.

### Added

- `/u-tools-figma-screen` — Screen-spec writer. Inputs: (Figma URL │ `screens.{md,json}`) + (Figma DS URL │ `design-system.{md,json,tsx,css}`). Outputs: Figma frames, `screens.md+json`, or both. Source-resolution matrix, conflict log under `.u-maker/.state/figma-screen-conflicts.json`, idempotent `--rerun` via persisted bundles. References: `source-resolution.md`, `conflict-resolution.md`, `delegation-bundle.md`.
- `/u-tools-figma-ds` — Code → Figma design-system writer. Input: `.tsx + .json + .css` (W3C tokens / Style Dictionary / CSS custom properties / Tailwind config). Output: Figma Variables (3 layers, light/dark modes, 10 scales) + master components + variants. References: `token-extraction.md`, `component-extraction.md`, `delegation-bundle.md`.

### Wired

- `/u-plan` Step 2.5 — auto-delegates to `/u-tools-figma-screen --output md` when both a screen-plan source and a design-system source are detected after IA generation. Pre-populates `screens.{md,json}` so `/u-design` Step 3 verifies-and-finalises instead of generating from scratch.
- `/u-analyze` Step 2.4 — auto-delegates to `/u-tools-figma-ds` when DS-applied source code (token files, `packages/tokens`, `packages/ui-*`) is detected in dropzone. Falls back to `--dry-run` when Figma is unauthenticated; bundle persisted for later replay.
- `/u-design` Step 4.5 — opt-in outbound sync to Figma for both screens (`/u-tools-figma-screen --output figma --prefer md`) and DS (`/u-tools-figma-ds`). Doc completion never blocks on Figma availability.

### Changed

- `.claude-plugin/plugin.json` — version `4.0.0-alpha.2` → `4.0.0-alpha.3`; skill count 25 → 27; description updated to mention the writer skills.
- README.md, README.ko.html, README.en.html, GET_STARTED.html — `u-tools-*` tables expanded with the two new entries.

### Removed

- `u-maker__u-ocean-wireframe2figma` — separately-installed legacy skill removed from `~/.claude/skills/` (the new u-tools-figma-screen replaces it).

## [4.0.0-alpha.1] — 2026-04-18

**Breaking change: PDCA → PBGD workflow migration.**

The plugin has been restructured from a 5-phase PDCA pipeline (Plan / Design / Dev / Check / Ship) to a 4-phase PBGD pipeline (Plan / Build / Gatekeeping / Deploy). This is a breaking change; follow the migration steps below when upgrading a v3.x project.

### Phase restructuring

| v3.x (PDCA) | v4.0 (PBGD) | Notes |
|-------------|-------------|-------|
| Plan (Steps 1–2: dropzone + digest) | `Plan.Prepare` (new) | Extracted into `/u-prepare` umbrella and `/u-analyze` skill |
| Plan (Steps 3–5: SRS + IA) | `Plan.Plan` | `/u-plan` scope narrowed to SRS/IA generation |
| (implicit) Wireframe | `Build.UIDesign` companion | `/u-wireframe` now prompted explicitly post-Plan (time-consuming) |
| Design | `Build.UIDesign` | Same doc outputs; new phase metadata |
| Dev | `Build.Development` | Same code outputs; new phase metadata |
| (implicit) Ping-pong | `Build` (umbrella) | New `/u-build` orchestrator with design↔dev ping-pong |
| Check | `Gatekeeping` | Renamed; now explicitly covers doc scoring + runtime QA |
| Ship | `Deploy` (new, expanded) | New `/u-deploy` with interactive target + artifact selection |

### Added

- `/u-prepare` — Preparation umbrella (foldertree + dropzone + analyze/reverse + 요구사항 협의).
- `/u-analyze` — Discrete dropzone → digest analysis skill (extracted from `/u-plan` Steps 1–2).
- `/u-build` — Build-phase orchestrator (design ↔ dev ping-pong).
- `/u-deploy` — Deploy-phase skill (interactive target + artifact selection, ≥ 98 gate, continuous regeneration).
- `/u-tools-figma` — Comprehensive Figma analyzer skill (pages + variants + assets + components + comments, semantic extraction). Auto-delegated from `/u-prepare`, `/u-analyze`, `/u-reverse`, `/u-design` on Figma sources. **Note:** v4.0.0-alpha.1 ships the reduced extraction path; full 6-phase pipeline (schema-strict manifest + 4-source variant detection) scheduled for the first post-GA release. Downstream consumers must tolerate `source.pipeline == "reduced"` digests (see `agents/u-agent-figma.md` §10).
- `u-agent-build` — Build-phase orchestrator agent.
- `u-agent-deploy` — Deploy-phase agent.
- `u-agent-figma` — Figma analyzer agent (reduced path in alpha).
- `_meta/schemas/deploy-manifest.schema.json` — Deploy manifest authoritative schema.
- `_meta/templates/{deploy-runbook,ci-github-actions,ci-vercel,ci-docker,env,release-notes,smoke-test}` — Deploy-phase templates.
- `hooks/on-deploy-state.js` — Continuous regeneration: marks deploy artifacts stale on SSoT drift.
- `.state/deploy-readiness.json` — Written by Gatekeeping after every run; read by Deploy as gate input.
- Schema additions: `workflow.phases` in config, `deployThreshold: 98` in gate-rules, phase/sub-phase enums in doc-companion and links.

### Renamed

- `skills/u-init/` → `skills/u-prepare-foldertree/` (granular `.u-maker` scaffolding only).
- `skills/u-check/` → `skills/u-gatekeeping/` (covers doc scoring + runtime QA).
- Output path: `docs/{app}/check/` → `docs/{app}/gatekeeping/` (migration handled by `/u-prepare-foldertree --migrate`).

### Alias layer (backward-compat)

- `/u-init` is now an **alias** of `/u-prepare` (the umbrella).
- `/u-check` is now an **alias** of `/u-gatekeeping`.
- `/u-qa` is now an **alias** of `/u-gatekeeping --only qa`.

Alias SKILL.md files print a one-line forwarding notice and route to the canonical command.

### Changed

- `/u-plan` scope narrowed: dropzone scanning + digest generation moved to `/u-analyze`. `/u-plan` now requires `data/digest/` to be populated.
- `u-agent-plan` now owns both Preparation sub-phase (via `/u-prepare`) and Plan sub-phase (via `/u-plan`).
- `u-agent-qa` renamed scope: Runtime QA sub-phase of Gatekeeping (formerly Check phase).
- `u-agent-gatekeeper` now emits `.state/deploy-readiness.json` after every run with both `passThreshold` (95) and `deployThreshold` (98) status.
- `u-agent-pm` rewritten with PBGD state machine + transition guards + alias resolution table.
- `u-loop` rewritten for PBGD sequence (Prepare → Plan → Build → Gatekeeping → Deploy) with `--skip-deploy` option.
- `hooks/on-gate-result.js` emits deploy-readiness regardless of loopActive state.
- `.claude-plugin/plugin.json`: version bumped; description and keywords updated for PBGD.

### Removed / Deprecated

- `skills/u-plan/references/ingest-flow.md` deleted — content moved to `skills/u-analyze/references/digest-extraction.md` and `analysis-rules.md`.
- `x-deprecated-pdca` block in `gate-rules.json` documents the retired PDCA gate names (no runtime effect).

### Migration checklist for v3.x projects

1. Back up `.u-maker/` (automatic via `/u-prepare-foldertree --migrate`).
2. Run `/u-prepare-foldertree --migrate` on the project root to rename `docs/{app}/check/` → `docs/{app}/gatekeeping/` and update `u-maker.config.json` to v4.0 schema.
3. Re-run `/u-analyze` if your dropzone state was mid-analysis before the upgrade.
4. Any custom scripts referencing `/u-init`, `/u-check`, `/u-qa` continue to work (aliases). Update to canonical names at your leisure.
5. Any custom tooling referencing `docs/{app}/check/` must be updated to `docs/{app}/gatekeeping/`.

---

## [3.4.10] — 2026-04-18

Final PDCA release. See git history for details.
