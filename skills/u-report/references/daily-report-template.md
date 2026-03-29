# Daily Report HTML Template Reference

`daily-report-{YYYY-MM-DD}.html` 생성 시 적용하는 레이아웃, 스타일, 컴포넌트 상세 명세. 파일명에 생성 날짜가 포함된다 (예: `daily-report-2026-03-29.html`).

> 이 문서의 스타일링은 프로젝트의 `html-report-standard.md`를 기반으로 하며, Daily Report 고유 컴포넌트를 추가 정의한다.

---

## 1. 전체 레이아웃

```
┌─ .daily-report ─────────────────────────────────────────────────────┐
│                                                                      │
│  ┌─ .header ──────────────────────────────────────────────────────┐  │
│  │  Title + Subtitle + KPI Badges + Pipeline + Progress Bar       │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─ .filter-bar ──────────────────────────────────────────────────┐  │
│  │  파이프라인 필터: [완료] [진행중] [대기] [리뷰검증]             │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─ .progress-table-section ──────────────────────────────────────┐  │
│  │  IA 일정 조율 현황  {완료수}개 항목 · {도메인수}개 도메인        │  │
│  │  ┌─ table.progress-table ───────────────────────────────────┐  │  │
│  │  │  Domain group rows + Menu item rows                       │  │  │
│  │  └──────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─ .roadmap-section ────────────────────────────────────────────┐  │
│  │  기술 혁신 로드맵  IN PROGRESS                                  │  │
│  │  KPI Cards + Roadmap Table                                     │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─ .footer ──────────────────────────────────────────────────────┐  │
│  │  License · © Owner · Generated {date}                          │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

- 사이드바 없음 (full-width single-page report)
- 최대 너비: `1400px`, 중앙 정렬
- 패딩: `24px 32px`
- 인쇄 시 전체 너비, 페이지 나눔 `.roadmap-section` 앞에서

---

## 2. Header 컴포넌트

### 2.1 Title Bar

```html
<header class="header">
  <div class="header-top">
    <div class="title-group">
      <h1 class="title">{ProjectName} IA 일정 조율</h1>
      <p class="subtitle">{year}년 {month}월 개발 마일스톤 - {start} ~ {end}</p>
    </div>
    <div class="kpi-badges">
      <div class="kpi-badge kpi-total">
        <span class="kpi-value">{total}</span>
        <span class="kpi-label">전체</span>
      </div>
      <div class="kpi-badge kpi-done">
        <span class="kpi-value">{done}</span>
        <span class="kpi-label">완료</span>
      </div>
      <div class="kpi-badge kpi-progress">
        <span class="kpi-value">{inProgress}</span>
        <span class="kpi-label">진행중</span>
      </div>
      <div class="kpi-badge kpi-dday">
        <span class="kpi-value">{dday}</span>
        <span class="kpi-label">D-day</span>
      </div>
    </div>
  </div>
</header>
```

**KPI Badge 스타일:**

| Badge | 배경색 | 텍스트색 | 크기 |
|-------|--------|---------|------|
| 전체 | `#1e293b` | `#f8fafc` | 80×72px |
| 완료 | `#22c55e` | `#ffffff` | 80×72px |
| 진행중 | `#3b82f6` | `#ffffff` | 80×72px |
| D-day | `#ef4444` | `#ffffff` | 80×72px |

- `.kpi-value`: `font-size: 28px; font-weight: 700`
- `.kpi-label`: `font-size: 12px; font-weight: 400; opacity: 0.9`

### 2.2 Pipeline Bar

```html
<div class="pipeline">
  <div class="pipeline-item">
    <span class="pipeline-label">완료 {n}</span>
    <span class="pipeline-dot done"></span>
  </div>
  <span class="pipeline-arrow">›</span>
  <div class="pipeline-item">
    <span class="pipeline-label">QA진행 {n}</span>
    <span class="pipeline-dot qa"></span>
  </div>
  <span class="pipeline-arrow">›</span>
  <div class="pipeline-item">
    <span class="pipeline-label">개발중 {n}</span>
    <span class="pipeline-dot dev"></span>
  </div>
  <span class="pipeline-arrow">›</span>
  <div class="pipeline-item">
    <span class="pipeline-label">설계중 {n}</span>
    <span class="pipeline-dot design"></span>
  </div>
  <span class="pipeline-arrow">›</span>
  <div class="pipeline-item">
    <span class="pipeline-label">기획중 {n}</span>
    <span class="pipeline-dot plan"></span>
  </div>
  <span class="pipeline-arrow">›</span>
  <div class="pipeline-item">
    <span class="pipeline-label">대기 {n}</span>
    <span class="pipeline-dot waiting"></span>
  </div>
</div>
```

**Pipeline 색상 (u-maker PDCA 단계별):**

| 단계 | 색상 | 설명 |
|------|------|------|
| 완료 | `#22c55e` | 5단계 모두 통과 |
| QA진행 | `#8b5cf6` | ④개발 완료 → ⑤검증 중 |
| 개발중 | `#3b82f6` | ③설계 완료 → ④개발 중 |
| 설계중 | `#f59e0b` | ②기획 완료 → ③설계 중 |
| 기획중 | `#f97316` | ①분류 완료 → ②기획 중 |
| 대기 | `#64748b` | 아직 시작 전 |

### 2.3 Progress Bar

```html
<div class="overall-progress">
  <span class="progress-label">전체 진행률</span>
  <div class="progress-track">
    <div class="progress-fill" style="width: {percent}%"></div>
  </div>
  <span class="progress-value">{percent}%</span>
</div>
```

- `.progress-track`: `height: 12px; border-radius: 6px; background: #334155`
- `.progress-fill`: `background: linear-gradient(90deg, #22c55e, #16a34a); border-radius: 6px`
- `.progress-value`: `font-size: 16px; font-weight: 700; color: #22c55e`

---

## 3. Filter Bar

```html
<div class="filter-bar">
  <span class="filter-label">파이프라인</span>
  <label class="filter-chip active">
    <input type="checkbox" checked> ✓ 완료
    <span class="chip-badge done">{n}</span>
  </label>
  <label class="filter-chip">
    <input type="checkbox"> QA진행
    <span class="chip-badge qa">{n}</span>
  </label>
  <label class="filter-chip">
    <input type="checkbox"> 개발중
    <span class="chip-badge dev">{n}</span>
  </label>
  <label class="filter-chip">
    <input type="checkbox"> 설계중
    <span class="chip-badge design">{n}</span>
  </label>
  <label class="filter-chip">
    <input type="checkbox"> 기획중
    <span class="chip-badge plan">{n}</span>
  </label>
  <label class="filter-chip">
    <input type="checkbox"> 대기
    <span class="chip-badge waiting">{n}</span>
  </label>
</div>
```

- JavaScript로 체크 시 테이블 행 필터링 (data-status 속성 기준)
- `filter-bar`: `background: #f1f5f9; border-radius: 8px; padding: 8px 16px`

---

## 4. Progress Table

### 4.1 테이블 구조

```html
<section class="progress-table-section">
  <div class="section-header">
    <h2>IA 일정 조율 현황</h2>
    <span class="section-meta">{totalScreens}개 항목 · {domainCount}개 도메인</span>
  </div>

  <table class="progress-table">
    <thead>
      <tr>
        <th class="col-num">#</th>
        <th class="col-domain">도메인</th>
        <th class="col-menu">메뉴</th>
        <th class="col-stage">①<br>분류</th>
        <th class="col-stage">②<br>기획</th>
        <th class="col-stage">③<br>설계</th>
        <th class="col-stage">④<br>개발</th>
        <th class="col-stage">⑤<br>검증</th>
        <th class="col-progress">진행률</th>
        <th class="col-status">상태</th>
        <th class="col-assignee">담당</th>
        <th class="col-date">완료(예정)일</th>
        <th class="col-note">비고</th>
      </tr>
    </thead>
    <tbody>
      <!-- Domain Group Row -->
      <tr class="domain-group-row" data-domain="{domainId}">
        <td></td>
        <td class="domain-name" colspan="2">
          <strong>{domainName}</strong>
          <span class="domain-count">{doneCount}/{totalCount}</span>
        </td>
        <td colspan="5">
          <div class="domain-progress-bar">
            <div class="domain-progress-fill" style="width:{percent}%"></div>
          </div>
        </td>
        <td class="domain-percent">{percent}%</td>
        <td colspan="4"></td>
      </tr>

      <!-- Menu Item Row -->
      <tr class="menu-item-row" data-status="{status}" data-domain="{domainId}">
        <td class="col-num">{rowNum}</td>
        <td class="col-domain"></td>
        <td class="col-menu">{menuName}</td>
        <td class="col-stage stage-cell {stageClass}">{stageIcon}</td>
        <td class="col-stage stage-cell {stageClass}">{stageIcon}</td>
        <td class="col-stage stage-cell {stageClass}">{stageIcon}</td>
        <td class="col-stage stage-cell {stageClass}">{stageIcon}</td>
        <td class="col-stage stage-cell {stageClass}">{stageIcon}</td>
        <td class="col-progress">
          <div class="item-progress">
            <div class="item-progress-fill" style="width:{percent}%"></div>
            <span>{percent}%</span>
          </div>
        </td>
        <td class="col-status"><span class="status-badge {statusClass}">{status}</span></td>
        <td class="col-assignee">{assignee}</td>
        <td class="col-date">{date}</td>
        <td class="col-note">{note}</td>
      </tr>
    </tbody>
  </table>
</section>
```

### 4.2 열 너비

| 열 | 너비 | 정렬 |
|----|------|------|
| # | `40px` | center |
| 도메인 | `160px` | left |
| 메뉴 | `140px` | left |
| ①~⑤ 각 | `52px` | center |
| 진행률 | `80px` | center |
| 상태 | `72px` | center |
| 담당 | `64px` | center |
| 완료(예정)일 | `96px` | center |
| 비고 | `auto` (나머지) | left |

### 4.3 Stage Cell 스타일

```css
.stage-cell {
  width: 52px;
  height: 40px;
  text-align: center;
  vertical-align: middle;
}

/* 완료 */
.stage-done {
  background: #1e293b;
  color: #ffffff;
}
.stage-done::after {
  content: "✓";
  font-size: 16px;
  font-weight: 700;
}

/* 진행중 */
.stage-in-progress {
  background: #3b82f6;
}

/* 이슈 */
.stage-issue {
  background: #ef4444;
}

/* 미도달 */
.stage-pending {
  background: #334155;
}

/* 미해당 */
.stage-na {
  background: transparent;
  color: #64748b;
}
.stage-na::after {
  content: "—";
}
```

### 4.4 Domain Group Row 스타일

```css
.domain-group-row {
  background: #0f172a;
  border-left: 4px solid #fbbf24;
}

.domain-group-row .domain-name {
  font-weight: 700;
  font-size: 14px;
  color: #f8fafc;
}

.domain-group-row .domain-count {
  margin-left: 8px;
  font-size: 12px;
  color: #94a3b8;
  font-weight: 400;
}

.domain-progress-bar {
  height: 6px;
  background: #334155;
  border-radius: 3px;
  overflow: hidden;
}

.domain-progress-fill {
  height: 100%;
  background: #fbbf24;
  border-radius: 3px;
  transition: width 0.3s ease;
}

.domain-percent {
  font-weight: 700;
  color: #fbbf24;
  font-size: 13px;
}
```

### 4.5 Status Badge

```css
.status-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
}

.status-done {
  background: #22c55e;
  color: #ffffff;
}

.status-in-progress {
  background: #3b82f6;
  color: #ffffff;
}

.status-waiting {
  background: #64748b;
  color: #ffffff;
}

.status-research {
  background: #f59e0b;
  color: #1e293b;
}

.status-issue {
  background: #ef4444;
  color: #ffffff;
}
```

### 4.6 Item Progress Bar

```css
.item-progress {
  display: flex;
  align-items: center;
  gap: 6px;
}

.item-progress-fill {
  height: 6px;
  border-radius: 3px;
  flex: 1;
  background: #334155;
  position: relative;
  overflow: hidden;
}

.item-progress-fill::after {
  content: "";
  position: absolute;
  left: 0;
  top: 0;
  height: 100%;
  width: var(--progress);
  background: #22c55e;
  border-radius: 3px;
}

.item-progress span {
  font-size: 12px;
  font-weight: 600;
  color: #94a3b8;
  min-width: 36px;
  text-align: right;
}
```

### 4.7 진행률에 따른 이슈 카운트 표시

진행률이 100% 미만이고 특정 단계에서 이슈가 있는 경우, 진행률 옆에 이슈 카운트를 표시:

```html
<td class="col-progress">
  <div class="item-progress">
    <span>50%</span>
    <span class="issue-count">2</span>  <!-- 이슈 수 -->
  </div>
</td>
```

```css
.issue-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #fbbf24;
  color: #1e293b;
  font-size: 11px;
  font-weight: 700;
}
```

---

## 5. Roadmap Section

### 5.1 헤더

```html
<section class="roadmap-section">
  <div class="roadmap-header">
    <h2>2026 기술 혁신 로드맵</h2>
    <span class="roadmap-badge in-progress">IN PROGRESS</span>
    <span class="roadmap-meta">도메인 메뉴수: 완료 {done} · 진행 {inProgress}</span>
  </div>
```

### 5.2 KPI Alert Block

```html
  <div class="roadmap-alert">
    <div class="alert-icon">⚠</div>
    <div class="alert-text">체크리스트 반복 점검 — 핵심 개선 과제</div>
  </div>

  <div class="roadmap-kpi-cards">
    <div class="roadmap-kpi red">
      <span class="roadmap-kpi-value">{value1}</span>
      <span class="roadmap-kpi-label">{label1}</span>
      <span class="roadmap-kpi-sub">{sub1}</span>
    </div>
    <div class="roadmap-kpi blue">
      <span class="roadmap-kpi-value">{value2}</span>
      <span class="roadmap-kpi-label">{label2}</span>
      <span class="roadmap-kpi-sub">{sub2}</span>
    </div>
    <div class="roadmap-kpi green">
      <span class="roadmap-kpi-value">{value3}</span>
      <span class="roadmap-kpi-label">{label3}</span>
      <span class="roadmap-kpi-sub">{sub3}</span>
    </div>
  </div>
```

**KPI Card 스타일:**

| Card | 배경 | 테두리 |
|------|------|--------|
| red | `rgba(239, 68, 68, 0.1)` | `1px solid rgba(239, 68, 68, 0.3)` |
| blue | `rgba(59, 130, 246, 0.1)` | `1px solid rgba(59, 130, 246, 0.3)` |
| green | `rgba(34, 197, 94, 0.1)` | `1px solid rgba(34, 197, 94, 0.3)` |

- `.roadmap-kpi-value`: `font-size: 36px; font-weight: 800`
- `.roadmap-kpi-label`: `font-size: 13px; font-weight: 500`
- `.roadmap-kpi-sub`: `font-size: 11px; color: #94a3b8`

### 5.3 Roadmap Table

```html
  <table class="roadmap-table">
    <thead>
      <tr>
        <th>#</th>
        <th>메뉴</th>
        <th>제목</th>
        <th>긴급</th>
        <th>시기</th>
        <th>시작일</th>
        <th>상태</th>
        <th>비고</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>{num}</td>
        <td><strong>{menuName}</strong></td>
        <td>{title}</td>
        <td class="urgency urgency-{level}">🔺 {level}</td>
        <td>{duration}</td>
        <td>{startDate}</td>
        <td><span class="status-badge {statusClass}">{status}</span></td>
        <td>{note}</td>
      </tr>
    </tbody>
  </table>
</section>
```

**Urgency 색상:**

| Level | 색상 |
|-------|------|
| 1 (최긴급) | `#ef4444` |
| 2 | `#f59e0b` |
| 3 | `#64748b` |

---

## 6. 테마 지원

Dark mode(기본) / Light mode 토글 지원. CSS 변수 기반:

```css
:root {
  /* Dark (default) */
  --bg: #0f172a;
  --card: #1e293b;
  --border: #334155;
  --text: #f8fafc;
  --text-secondary: #94a3b8;
  --table-header: #1e293b;
  --table-row-odd: #0f172a;
  --table-row-even: #1e293b;
  --table-row-hover: #334155;
  --stage-done-bg: #1e293b;
  --stage-pending-bg: #334155;
  --progress-track: #334155;
}

[data-theme="light"] {
  --bg: #ffffff;
  --card: #f8fafc;
  --border: #e2e8f0;
  --text: #0f172a;
  --text-secondary: #64748b;
  --table-header: #f1f5f9;
  --table-row-odd: #ffffff;
  --table-row-even: #f8fafc;
  --table-row-hover: #f1f5f9;
  --stage-done-bg: #e2e8f0;
  --stage-pending-bg: #f1f5f9;
  --progress-track: #e2e8f0;
}
```

---

## 7. 반응형

```css
@media (max-width: 1200px) {
  .col-note { display: none; }
  .progress-table { font-size: 12px; }
}

@media (max-width: 768px) {
  .kpi-badges { flex-wrap: wrap; }
  .col-assignee, .col-date { display: none; }
  .col-stage { width: 36px; font-size: 10px; }
  .pipeline { overflow-x: auto; }
}

@media print {
  .filter-bar { display: none; }
  .theme-toggle { display: none; }
  .progress-table { page-break-inside: auto; }
  .roadmap-section { page-break-before: always; }
  body { background: white; color: black; }
}
```

---

## 8. JavaScript (인라인)

```javascript
// 1. 테마 토글
document.querySelector('.theme-toggle').addEventListener('click', () => {
  const html = document.documentElement;
  const current = html.getAttribute('data-theme');
  html.setAttribute('data-theme', current === 'light' ? 'dark' : 'light');
  localStorage.setItem('theme', html.getAttribute('data-theme'));
});

// 2. 필터
document.querySelectorAll('.filter-chip input').forEach(cb => {
  cb.addEventListener('change', () => {
    const active = [...document.querySelectorAll('.filter-chip input:checked')]
      .map(el => el.closest('.filter-chip').dataset.status);
    document.querySelectorAll('.menu-item-row').forEach(row => {
      row.style.display = active.includes(row.dataset.status) ? '' : 'none';
    });
    // 도메인 그룹 행: 하위 메뉴가 모두 숨겨지면 도메인도 숨김
    document.querySelectorAll('.domain-group-row').forEach(domRow => {
      const domain = domRow.dataset.domain;
      const visible = document.querySelectorAll(
        `.menu-item-row[data-domain="${domain}"]:not([style*="display: none"])`
      );
      domRow.style.display = visible.length > 0 ? '' : 'none';
    });
  });
});

// 3. 테마 초기화 (OS 설정 감지 + localStorage)
(function() {
  const saved = localStorage.getItem('theme');
  if (saved) {
    document.documentElement.setAttribute('data-theme', saved);
  } else if (window.matchMedia('(prefers-color-scheme: light)').matches) {
    document.documentElement.setAttribute('data-theme', 'light');
  }
})();
```

---

## 9. 체크리스트

생성 시 아래 항목을 모두 만족하는지 확인:

- [ ] Font: Pretendard + system fallback
- [ ] 모든 색상 CSS 변수 사용 (하드코딩 금지)
- [ ] Dark/Light 테마 토글 동작
- [ ] KPI 뱃지 4개 (전체/완료/진행중/D-day) 정확한 수치
- [ ] 파이프라인 바 상태별 카운트 정확
- [ ] 전체 진행률 = (완료 화면 / 전체 화면) × 100
- [ ] IA L1 → 도메인 그룹 행, L2/L3 → 메뉴 아이템 행 매핑
- [ ] PDCA 5단계 (분류→기획→설계→개발→검증) 체크마크 정확 (✓ / 빈칸 / — 구분)
- [ ] 파이프라인 상태: 완료/QA진행/개발중/설계중/기획중/대기 정확 매핑
- [ ] 파일명에 날짜 포함 (`daily-report-YYYY-MM-DD.html`)
- [ ] 도메인별 소계 (완료/전체) 정확
- [ ] 필터 동작 (JavaScript)
- [ ] 로드맵 섹션 데이터 바인딩
- [ ] 반응형 (1200px, 768px 브레이크포인트)
- [ ] 인쇄 지원 (@media print)
- [ ] 외부 의존성 없음 (단일 HTML 파일)
- [ ] Footer: license + copyright
