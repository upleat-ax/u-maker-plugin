# SVG Diagram 변환 규칙

`.md` 파일의 ` ```mermaid ... ``` ` 코드 블록 또는 문서 데이터를 인라인 SVG로 직접 변환한다.
외부 JS 라이브러리(Mermaid 포함)는 사용하지 않는다. 모든 다이어그램은 순수 `<svg>` 태그로 작성한다.

## 변환 형식

```
INPUT  (.md):
  ```mermaid
  flowchart TD
      A[시작] --> B[종료]
  ```

OUTPUT (.html):
  <div class="diagram-wrap">
    <svg viewBox="0 0 400 200" xmlns="http://www.w3.org/2000/svg">
      <rect x="150" y="20" width="100" height="40" rx="8" fill="var(--diagram-node-bg)" stroke="var(--diagram-node-border)"/>
      <text x="200" y="45" text-anchor="middle" fill="var(--diagram-text)" font-size="14">시작</text>
      <line x1="200" y1="60" x2="200" y2="120" stroke="var(--diagram-line)" stroke-width="2" marker-end="url(#arrow)"/>
      <rect x="150" y="120" width="100" height="40" rx="8" fill="var(--diagram-node-bg)" stroke="var(--diagram-node-border)"/>
      <text x="200" y="145" text-anchor="middle" fill="var(--diagram-text)" font-size="14">종료</text>
    </svg>
  </div>
```

## SVG 규칙

| 항목 | 규칙 |
|------|------|
| 렌더링 | 순수 인라인 `<svg>` — UML Sequence/Class Diagram만 Mermaid CDN 허용, 그 외 외부 JS 금지 |
| 색상 | 모든 `fill`, `stroke`, `color`는 CSS 변수 사용 (`var(--diagram-*)`) |
| 테마 연동 | CSS 변수가 light/dark 테마에 따라 자동 전환됨 (JS 재렌더링 불필요) |
| viewBox | 콘텐츠에 맞게 적절히 설정, `width="100%"` + `max-width` 제한 |
| 반응형 | `<svg>` 는 `.diagram-wrap` 내 배치, `max-width:100%; height:auto` |
| 화살표 | `<defs><marker id="arrow">` 공통 정의 후 `marker-end="url(#arrow)"` 참조 |
| 텍스트 | `<text>` 태그, `font-family` 는 body와 동일, `fill: var(--diagram-text)` |
| 노드 박스 | `<rect rx="8">` 또는 `<rect rx="20">` (둥근 모서리), 배경 `var(--diagram-node-bg)` |
| 강조 노드 | `fill: var(--diagram-accent-bg)`, `stroke: var(--diagram-accent)` |
| 연결선 | `<line>` 또는 `<path>` (곡선), `stroke: var(--diagram-line)`, `stroke-width: 2` |
| 점선 | `stroke-dasharray="6 4"` |
| 레이블 | 연결선 위 `<text>` — `font-size: 11px`, `fill: var(--diagram-text-sub)` |

## SVG CSS 변수 (Light/Dark 공통)

```css
/* Light theme (Sidebar Viewer :root 또는 Report [data-theme="light"]) */
--diagram-node-bg: #ffffff;
--diagram-node-border: #d1d5db;
--diagram-accent-bg: #1e293b;
--diagram-accent-text: #ffffff;
--diagram-accent: #1e293b;
--diagram-line: #9ca3af;
--diagram-text: #1e293b;
--diagram-text-sub: #6b7280;
--diagram-label-bg: #f3f4f6;

/* Dark theme (Report :root 또는 Sidebar [data-theme="dark"]) */
--diagram-node-bg: #1e1e2e;
--diagram-node-border: #3a3a4e;
--diagram-accent-bg: #7c6af6;
--diagram-accent-text: #ffffff;
--diagram-accent: #7c6af6;
--diagram-line: #4a4a5e;
--diagram-text: #e4e4ed;
--diagram-text-sub: #8b8ba0;
--diagram-label-bg: #2a2a3a;
```

## 문서 유형별 SVG 다이어그램 매핑

각 문서 유형에 맞는 다이어그램을 인라인 SVG로 생성한다:

| doc-type | 포함할 SVG 다이어그램 |
|----------|---------------------|
| `srs` | Flowchart (FR→US→FT 매핑), Donut/Pie (FR 우선순위 분포) |
| `ia` | Tree Diagram (메뉴 트리), Flow (유저 여정) |
| `erd` | ER Diagram (엔티티 관계 — 박스 + 연결선), Class Diagram (도메인 모델) |
| `api` | Architecture Diagram (시스템 구성), Sequence Diagram (API 인터랙션 — 수직 타임라인) |
| `screen` | State Diagram (화면 상태 전이), Flowchart (화면 전환) |
| `screenflow` | Horizontal Flowchart (스크린 플로우, LR 방향) |
| `uxguide` | Hierarchy Diagram (디자인 시스템 구조) |
| `rtm` | Horizontal Flowchart (FR→US→FT→TC 추적), Donut (Coverage 분포) |
| `code` | Flowchart (프로세스 플로우), Module Diagram (모듈 구조) |
| `testcase` | Flowchart (테스트 시나리오), Donut (케이스 분포) |
| `qareport` | Donut (Pass/Fail/Skip 비율), Bar Chart (추이) |
| `iteration` | Bar Chart (진행률), Timeline (일정) |

소스 `.md`에 Mermaid 블록이 있으면 의미를 해석하여 SVG로 변환. 없으면 문서 데이터 기반으로 자동 생성.

## SVG 공통 Defs 블록

모든 다이어그램 SVG에 아래 `<defs>`를 포함한다:

```html
<defs>
  <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5"
    markerWidth="6" markerHeight="6" orient="auto-start-reverse">
    <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--diagram-line)"/>
  </marker>
  <marker id="arrow-accent" viewBox="0 0 10 10" refX="9" refY="5"
    markerWidth="6" markerHeight="6" orient="auto-start-reverse">
    <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--diagram-accent)"/>
  </marker>
</defs>
```
