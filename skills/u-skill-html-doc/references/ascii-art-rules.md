# ASCII Art → SVG 변환 규칙

`.md` 파일에 포함된 ASCII art 레이아웃/다이어그램을 감지하여 인라인 SVG로 변환한다.
ASCII art를 `<pre>` 태그로 그대로 출력하는 것은 금지한다 (예외 항목 제외).

## 예외 — `<pre><code>` 허용 항목

아래 유형은 ASCII art로 판정하지 않으며, `<pre><code>`로 그대로 렌더링한다:

| 유형 | 예시 | 판정 기준 |
|------|------|----------|
| **소스 코드** | ` ```js`, ` ```python`, ` ```sql` 등 언어 태그가 있는 코드 블록 | 코드 펜스에 언어 식별자가 명시됨 |
| **폴더/디렉토리 트리** | `├── src/`, `└── package.json`, `│   ├── components/` | `├`, `└`, `│` + 파일명/경로 패턴 (`/`, `.ext`) |
| **CLI 출력** | `$ npm run build`, `> Building...` | 프롬프트(`$`, `>`) + 명령어 패턴 |

## 감지 기준

위 예외에 해당하지 않으면서, 아래 패턴 중 하나라도 포함된 코드 블록 또는 텍스트 영역은 ASCII art로 판정:

| 패턴 | 예시 |
|------|------|
| Box-drawing 문자 | `┌ ┐ └ ┘ │ ─ ├ ┤ ┬ ┴ ┼` |
| Pipe + dash 레이아웃 | `\| --- \| --- \|`, `+---+---+` |
| 화살표 | `-->`, `→`, `←`, `↓`, `↑` |
| 중첩 박스 구조 | 들여쓰기 + `\|` + 텍스트 반복 패턴 |

## 변환 방법

1. ASCII art의 **의미(시맨틱)**를 파악한다 (레이아웃 구조, 계층, 흐름 등)
2. 의미에 맞는 **인라인 SVG**로 변환한다
3. SVG는 기존 다이어그램 규칙과 동일한 CSS 변수를 사용한다 (`var(--diagram-*)`)

## 변환 형식 예시

```
INPUT (.md):
  ┌─────────────────────────────────────────┐
  │ [Logo] App  [Search] [Notifications]    │
  ├─────────┬───────────────────────────────┤
  │ Sidebar │ Main Content Area             │
  │         │                               │
  │ Menu1   │ Breadcrumb: Home > Page       │
  │ Menu2   │ ┌───────────────────────────┐ │
  │ Menu3   │ │ Page Content              │ │
  │ Menu4   │ │                           │ │
  │ Menu5   │ └───────────────────────────┘ │
  └─────────┴───────────────────────────────┘

OUTPUT (.html):
  <div class="diagram-wrap">
    <svg viewBox="0 0 600 320" xmlns="http://www.w3.org/2000/svg">
      <defs>...</defs>
      <!-- Header bar -->
      <rect x="0" y="0" width="600" height="48" rx="8" ry="8"
        fill="var(--diagram-accent-bg)" stroke="var(--diagram-node-border)"/>
      <text x="20" y="30" fill="var(--diagram-accent-text)" font-size="14" font-weight="600">Logo  App</text>
      <text x="400" y="30" fill="var(--diagram-accent-text)" font-size="12">Search  Notifications</text>
      <!-- Sidebar -->
      <rect x="0" y="48" width="140" height="272" rx="0"
        fill="var(--diagram-node-bg)" stroke="var(--diagram-node-border)"/>
      <text x="16" y="80" fill="var(--diagram-text)" font-size="13">Menu1</text>
      <text x="16" y="104" fill="var(--diagram-text)" font-size="13">Menu2</text>
      <!-- ... -->
      <!-- Main content area -->
      <rect x="140" y="48" width="460" height="272" rx="0"
        fill="var(--diagram-label-bg)" stroke="var(--diagram-node-border)"/>
      <text x="160" y="80" fill="var(--diagram-text-sub)" font-size="12">Breadcrumb: Home > Page</text>
      <!-- Inner content box -->
      <rect x="160" y="96" width="420" height="200" rx="6"
        fill="var(--diagram-node-bg)" stroke="var(--diagram-node-border)" stroke-dasharray="4 2"/>
      <text x="180" y="130" fill="var(--diagram-text)" font-size="14">Page Content</text>
    </svg>
  </div>
```

## 문서 유형별 ASCII Art 처리

| doc-type | 주요 ASCII Art | SVG 변환 형태 |
|----------|---------------|--------------|
| `ia` | 네비게이션 레이아웃, 사이트맵 트리 | Layout Diagram (Header + Sidebar + Main 구조) |
| `screen` | 화면 와이어프레임, 레이아웃 스케치 | Wireframe SVG (영역 박스 + 라벨) |
| `screenflow` | 화면 전환 흐름도 | Flow Diagram (화면 박스 + 화살표) |
| `srs` | 상태 전이도, 프로세스 흐름 | State/Flow Diagram |
| `uxguide` | 컴포넌트 레이아웃, 그리드 구조 | Layout Diagram |

## ASCII Art SVG 규칙

| 항목 | 규칙 |
|------|------|
| `<pre>` 금지 | ASCII art를 `<pre><code>` 로 그대로 출력하지 않는다 (소스 코드, 폴더 트리, CLI 출력은 예외) |
| 의미 해석 | 박스, 화살표, 텍스트의 **의미**를 파악하여 SVG 구성 |
| 색상 | 모든 `fill`, `stroke`는 CSS 변수 (`var(--diagram-*)`) |
| 레이아웃 박스 | `<rect>` + `<text>` 조합, `rx="6"` 이상 둥근 모서리 |
| 계층 구조 | 중첩 영역은 배경색 차이(`--diagram-node-bg` vs `--diagram-label-bg`)로 구분 |
| 강조 영역 | 헤더/GNB 등 주요 영역은 `--diagram-accent-bg` 사용 |
| 텍스트 | 원본 ASCII art의 텍스트 라벨을 `<text>` 태그로 보존 |
| 반응형 | `viewBox` 설정 + `max-width:100%; height:auto` |
| 테마 연동 | CSS 변수 사용으로 Light/Dark 테마 자동 전환 |
