# SVG Chart Specification

Weekly 리포트의 인라인 SVG 차트 생성 규칙. Daily 리포트에도 동일 규칙이 적용된다.

## 공통 규칙

### SVG 기본 속성
```html
<svg viewBox="0 0 {width} {height}" width="100%" class="chart"
     role="img" aria-label="{chart description}">
  <title>{chart title}</title>
  <!-- chart content -->
</svg>
```

- `viewBox` 기반 반응형. 고정 width/height 금지
- `role="img"` + `aria-label` 접근성
- ASCII art 금지
- Mermaid 사용 금지 (차트는 전부 inline SVG)

### 색상 팔레트

| 용도 | Light Mode | Dark Mode | CSS 변수 |
|------|-----------|-----------|----------|
| Primary (FR, commits) | `#3b82f6` | `#60a5fa` | `--chart-blue` |
| Success (implemented, passed) | `#10b981` | `#34d399` | `--chart-green` |
| Warning (unresolved) | `#f59e0b` | `#fbbf24` | `--chart-amber` |
| Danger (failed) | `#ef4444` | `#f87171` | `--chart-red` |
| Info (meetings, US) | `#8b5cf6` | `#a78bfa` | `--chart-purple` |
| FT line | `#06b6d4` | `#22d3ee` | `--chart-cyan` |
| TC line | `#f97316` | `#fb923c` | `--chart-orange` |
| Grid / axis | `#e2e8f0` | `#334155` | `--chart-grid` |
| Axis text | `#64748b` | `#94a3b8` | `--chart-label` |
| Background | `#ffffff` | `#1e293b` | `--chart-bg` |

### CSS 변수 선언 (HTML `<style>`)
```css
:root {
  --chart-blue: #3b82f6; --chart-green: #10b981;
  --chart-amber: #f59e0b; --chart-red: #ef4444;
  --chart-purple: #8b5cf6; --chart-cyan: #06b6d4;
  --chart-orange: #f97316; --chart-grid: #e2e8f0;
  --chart-label: #64748b; --chart-bg: #ffffff;
}
.dark {
  --chart-blue: #60a5fa; --chart-green: #34d399;
  --chart-amber: #fbbf24; --chart-red: #f87171;
  --chart-purple: #a78bfa; --chart-cyan: #22d3ee;
  --chart-orange: #fb923c; --chart-grid: #334155;
  --chart-label: #94a3b8; --chart-bg: #1e293b;
}
```

### 축 (Axis)

**X축 (날짜):**
- 라벨: `MM/DD` 형식
- 12px, `font-family: system-ui`
- 그리드 라인: 세로 점선 (`stroke-dasharray: 4,4`)

**Y축 (수치):**
- 자동 스케일: max값의 120%까지
- 5단계 눈금 (0, 25%, 50%, 75%, 100% of max)
- 그리드 라인: 가로 점선

### 범례 (Legend)

차트 상단 우측에 수평 배치:
```html
<g class="legend" transform="translate({x}, 12)">
  <circle r="4" fill="var(--chart-blue)"/>
  <text x="10" font-size="11" fill="var(--chart-label)">Designed</text>
  <circle cx="80" r="4" fill="var(--chart-green)"/>
  <text x="90" font-size="11" fill="var(--chart-label)">Implemented</text>
</g>
```

### 툴팁 (CSS only)

```html
<g class="data-point" tabindex="0">
  <circle r="4" fill="var(--chart-blue)"/>
  <g class="tooltip" opacity="0">
    <rect rx="4" fill="#1e293b" opacity=".9"/>
    <text fill="#fff" font-size="11">04/10: 15</text>
  </g>
</g>
```

CSS:
```css
.data-point:hover .tooltip,
.data-point:focus .tooltip { opacity: 1; }
```

## Chart Types

### 1. Line Chart (설계 vs 구현)

```
viewBox: 0 0 600 300
padding: top 30, right 20, bottom 40, left 50
```

- 데이터 포인트: `<circle r="4">`
- 선: `<path>` with Bezier curves (`C` command)
  - 제어점: 인접 점 사이 1/3 지점에서 수평 접선
- Gap fill: 두 선 사이 `<path>` with `fill-opacity="0.08"`
- 포인트에 CSS 호버 효과

**Bezier 라인 생성 공식:**
```
M x0,y0
C (x0+dx/3),y0, (x1-dx/3),y1, x1,y1
C (x1+dx/3),y1, (x2-dx/3),y2, x2,y2
...
```
여기서 `dx = x[i+1] - x[i]`

### 2. Grouped Bar Chart (일별 활동)

```
viewBox: 0 0 600 280
bar width: 16px per group member
bar gap: 4px within group
group gap: 24px between groups
```

- 바: `<rect rx="3">` with rounded top
- 값 라벨: 바 상단에 표시 (font-size 10px)
- 하단 X축: 날짜 라벨

### 3. Stacked Area Chart (이슈 추적)

```
viewBox: 0 0 600 280
```

- 각 영역: `<path>` with fill-opacity 0.3 (hover 시 0.5)
- 경계선: 동일 색상, opacity 1, stroke-width 2
- 아래에서 위로 쌓기: decisions → unresolved → failed

### 4. Multi-line Chart (SSoT 항목 성장)

```
viewBox: 0 0 600 300
```

- FR, US, FT, TC 각각 다른 색상 라인
- 범례 포함 (4개 항목)
- Y축: 0부터 max값까지 자동 스케일

### 5. Donut Chart (테스트 결과)

```
viewBox: 0 0 200 200
center: 100, 100
outer radius: 80
inner radius: 50
```

- `<path>` arc 세그먼트 (d="M... A... L... A... Z")
- 중앙 텍스트: pass rate % (큰 폰트)
- 세그먼트: passed(green), failed(red), skipped(gray)

### 6. Horizontal Bar Chart (TOP 5 주제)

```
viewBox: 0 0 500 {25 * count + 20}
bar height: 18px
bar gap: 7px
```

- 바: `<rect rx="3">` (왼→오)
- 좌측: 주제명 텍스트
- 우측: 수치 라벨
- 정렬: 값 내림차순

### 7. Heatmap Grid (일별 커밋 강도)

```
viewBox: 0 0 {7 * 36} {36}
cell size: 28px
cell gap: 4px
```

- 7칸 가로 그리드 (월~일)
- 색상 강도: commits 수 → 5단계 opacity
  - 0: `#f1f5f9`, 1-3: 20%, 4-6: 40%, 7-10: 60%, 11+: 100% of `--chart-blue`
- 호버 시 tooltip (날짜 + 커밋 수)

### 8. Progress Bar (진행률)

```html
<svg viewBox="0 0 200 16" width="100%">
  <rect width="200" height="16" rx="8" fill="var(--chart-grid)"/>
  <rect width="{pct * 2}" height="16" rx="8" fill="var(--chart-green)"/>
  <text x="100" y="12" text-anchor="middle" font-size="10" fill="#fff">{pct}%</text>
</svg>
```

## Responsive Breakpoints

차트 컨테이너 너비에 따른 조정:
- `max-width: 800px` → 차트 전체 폭
- `min-width: 640px` → 차트 2열 그리드
- `< 640px` → 차트 1열 스택

```html
<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
  <div class="bg-white dark:bg-gray-900 rounded-xl p-6 border border-gray-200 dark:border-gray-800">
    <h3 class="text-sm font-semibold mb-4">설계 vs 구현 화면</h3>
    <svg viewBox="0 0 600 300" width="100%">...</svg>
  </div>
  <!-- more charts -->
</div>
```
