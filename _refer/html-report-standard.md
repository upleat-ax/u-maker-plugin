# HTML Report Standard

> 모든 리포트 문서(.md)는 동일한 내용의 `.html` 파일을 같은 경로에 함께 생성한다.
> HTML은 단일 파일로 완결되며, 외부 의존성 없이 브라우저에서 독립 표시 가능해야 한다.

---

## 1. 적용 규칙

| 조건 | 규칙 |
|------|------|
| **적용 대상** | 리포트 문서: `5_DailyReport_PM`, `4_Report_QA`, `5_LoopReport_PM` |
| **파일 경로** | 마크다운 파일과 **동일한 경로**, 확장자만 `.html`로 변경 |
| **생성 시점** | `.md` 파일 생성/갱신과 동시에 |
| **내용 동기화** | `.md`와 `.html`은 같은 데이터, 같은 버전 |

### 경로 예시

```
.u-maker/docs/common/05-act/5_DailyReport_PM_202603071200.md
.u-maker/docs/common/05-act/5_DailyReport_PM_202603071200.json
.u-maker/docs/common/05-act/5_DailyReport_PM_202603071200.html   ← NEW

.u-maker/docs/web/04-check/4_Report_QA.md
.u-maker/docs/web/04-check/4_Report_QA.json
.u-maker/docs/web/04-check/4_Report_QA.html                      ← NEW

.u-maker/docs/common/05-act/5_LoopReport_PM_202603071200.md
.u-maker/docs/common/05-act/5_LoopReport_PM_202603071200.json
.u-maker/docs/common/05-act/5_LoopReport_PM_202603071200.html    ← NEW
```

---

## 2. HTML 템플릿 구조

모든 리포트 HTML은 아래 골격을 따른다:

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{REPORT_TITLE}}</title>
  <link rel="preconnect" href="https://cdn.jsdelivr.net">
  <link href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css" rel="stylesheet">
  <style>
    /* ── Reset ─────────────────────────── */
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

    /* ── Base ──────────────────────────── */
    body {
      font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f8f9fa;
      color: #1a1a2e;
      line-height: 1.7;
      -webkit-font-smoothing: antialiased;
    }

    /* ── Layout ────────────────────────── */
    .report-container {
      max-width: 1100px;
      margin: 0 auto;
      padding: 48px 32px 80px;
    }

    /* ── Header ────────────────────────── */
    .report-header {
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
      color: #fff;
      padding: 48px 40px;
      border-radius: 16px;
      margin-bottom: 32px;
    }
    .report-header h1 {
      font-size: 28px;
      font-weight: 700;
      margin-bottom: 8px;
      letter-spacing: -0.5px;
    }
    .report-header .subtitle {
      font-size: 14px;
      color: rgba(255,255,255,0.7);
      font-weight: 400;
    }
    .report-meta {
      display: flex;
      gap: 24px;
      margin-top: 20px;
      flex-wrap: wrap;
    }
    .report-meta .meta-item {
      font-size: 13px;
      color: rgba(255,255,255,0.6);
    }
    .report-meta .meta-item strong {
      color: rgba(255,255,255,0.9);
      font-weight: 600;
    }

    /* ── Section ───────────────────────── */
    .section {
      background: #fff;
      border-radius: 12px;
      padding: 32px;
      margin-bottom: 24px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.06);
      border: 1px solid #e9ecef;
    }
    .section h2 {
      font-size: 18px;
      font-weight: 700;
      color: #1a1a2e;
      margin-bottom: 20px;
      padding-bottom: 12px;
      border-bottom: 2px solid #e9ecef;
    }
    .section h3 {
      font-size: 15px;
      font-weight: 600;
      color: #495057;
      margin: 16px 0 12px;
    }

    /* ── KPI Cards ─────────────────────── */
    .kpi-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }
    .kpi-card {
      background: #f8f9fa;
      border-radius: 10px;
      padding: 20px;
      text-align: center;
      border: 1px solid #e9ecef;
    }
    .kpi-card .kpi-value {
      font-size: 32px;
      font-weight: 800;
      color: #1a1a2e;
      line-height: 1.2;
    }
    .kpi-card .kpi-label {
      font-size: 12px;
      color: #868e96;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-top: 4px;
    }
    .kpi-card.success .kpi-value { color: #2b8a3e; }
    .kpi-card.warning .kpi-value { color: #e67700; }
    .kpi-card.danger .kpi-value { color: #c92a2a; }
    .kpi-card.info .kpi-value { color: #1864ab; }

    /* ── Table ─────────────────────────── */
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
      margin: 12px 0;
    }
    thead th {
      background: #f1f3f5;
      color: #495057;
      font-weight: 600;
      text-align: left;
      padding: 10px 14px;
      border-bottom: 2px solid #dee2e6;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.3px;
    }
    tbody td {
      padding: 10px 14px;
      border-bottom: 1px solid #f1f3f5;
      color: #495057;
    }
    tbody tr:hover { background: #f8f9fa; }

    /* ── Status Badges ─────────────────── */
    .badge {
      display: inline-block;
      padding: 3px 10px;
      border-radius: 12px;
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.3px;
    }
    .badge-pass { background: #d3f9d8; color: #2b8a3e; }
    .badge-fail { background: #ffe3e3; color: #c92a2a; }
    .badge-skip { background: #fff3bf; color: #e67700; }
    .badge-done { background: #d3f9d8; color: #2b8a3e; }
    .badge-wip { background: #d0ebff; color: #1864ab; }
    .badge-todo { background: #f1f3f5; color: #868e96; }
    .badge-critical { background: #c92a2a; color: #fff; }
    .badge-major { background: #e67700; color: #fff; }
    .badge-minor { background: #fff3bf; color: #e67700; }
    .badge-must { background: #1864ab; color: #fff; }
    .badge-should { background: #1971c2; color: #fff; }
    .badge-could { background: #d0ebff; color: #1864ab; }

    /* ── Progress Bar ──────────────────── */
    .progress-bar {
      width: 100%;
      height: 8px;
      background: #e9ecef;
      border-radius: 4px;
      overflow: hidden;
      margin: 8px 0;
    }
    .progress-bar .fill {
      height: 100%;
      border-radius: 4px;
      transition: width 0.3s ease;
    }
    .fill-green { background: #2b8a3e; }
    .fill-blue { background: #1864ab; }
    .fill-orange { background: #e67700; }
    .fill-red { background: #c92a2a; }

    /* ── List ──────────────────────────── */
    .item-list {
      list-style: none;
      padding: 0;
    }
    .item-list li {
      padding: 10px 0;
      border-bottom: 1px solid #f1f3f5;
      font-size: 14px;
      color: #495057;
    }
    .item-list li:last-child { border-bottom: none; }

    /* ── Footer ────────────────────────── */
    .report-footer {
      text-align: center;
      padding: 24px;
      font-size: 12px;
      color: #adb5bd;
      border-top: 1px solid #e9ecef;
      margin-top: 40px;
    }

    /* ── Responsive ────────────────────── */
    @media (max-width: 768px) {
      .report-container { padding: 16px; }
      .report-header { padding: 32px 24px; }
      .report-header h1 { font-size: 22px; }
      .section { padding: 20px; }
      .kpi-grid { grid-template-columns: repeat(2, 1fr); }
      .report-meta { flex-direction: column; gap: 8px; }
      table { font-size: 12px; }
      thead th, tbody td { padding: 8px 10px; }
    }
  </style>
</head>
<body>
  <div class="report-container">
    <div class="report-header">
      <h1>{{REPORT_TITLE}}</h1>
      <div class="subtitle">{{SUBTITLE}}</div>
      <div class="report-meta">
        <div class="meta-item">Project <strong>{{PROJECT_NAME}}</strong></div>
        <div class="meta-item">Iteration <strong>{{ITERATION}}</strong></div>
        <div class="meta-item">Date <strong>{{DATE}}</strong></div>
        <div class="meta-item">Author <strong>{{AUTHOR}}</strong></div>
      </div>
    </div>

    <!-- 리포트 타입별 섹션 -->

    <div class="report-footer">
      Generated by u-maker PDCA Orchestrator &middot; {{DATE}}
    </div>
  </div>
</body>
</html>
```

---

## 3. CSS 필수 규칙

| 항목 | 값 | 이유 |
|------|-----|------|
| 폰트 | `'Pretendard', -apple-system, BlinkMacSystemFont, sans-serif` | 한국어 최적화 + 폴백 |
| CSS 위치 | `<style>` 블록 내 인라인 | 단일 파일 완결성 |
| max-width | `1100px` | 가독성 |
| 반응형 | `@media (max-width: 768px)` 최소 대응 | 모바일 접근 |
| 차트 | HTML/CSS만 사용 (외부 JS 라이브러리 금지) | 단일 파일 완결성 |

---

## 4. 리포트별 섹션 구성

### 4.1 Loop Report (`5_LoopReport_PM`)

| 순서 | 섹션 | 데이터 소스 |
|------|------|------------|
| 1 | KPI Dashboard | config + 문서 통계 |
| 2 | Requirements Summary | `1_SRS_RA.md` |
| 3 | User Stories | `1_SRS_RA.md` US 섹션 |
| 4 | Features (FT) | `1_SRS_RA.md` FT 섹션 |
| 5 | Implementation | `3_Code_DV.md` + git log |
| 6 | Test Cases | `4_Case_QA.md` |
| 7 | Test Results | `4_Report_QA.md` |
| 8 | Technical Debt | `5_IterationLog_RA.md` + 코드 분석 |
| 9 | Traceability Matrix | `2_RTM_RA.md` |

### 4.2 Daily Report (`5_DailyReport_PM`)

| 순서 | 섹션 | 데이터 소스 |
|------|------|------------|
| 1 | Today Summary | 당일 작업 요약 |
| 2 | Progress Snapshot | Phase별 진행률 |
| 3 | Risks / Blockers | 리스크 목록 |
| 4 | Next Actions | 24시간 내 액션 |

### 4.3 QA Report (`4_Report_QA`)

| 순서 | 섹션 | 데이터 소스 |
|------|------|------------|
| 1 | Test Execution Summary | 테스트 실행 결과 |
| 2 | Results by FT | FT별 Pass/Fail |
| 3 | Defect Report | 결함 상세 |
| 4 | Exit Criteria | 종료 조건 판정 |

---

## 5. 생성 순서

리포트 생성 시 아래 순서를 반드시 준수한다:

```
1. SSoT 데이터 수집 (문서 읽기)
2. .md 파일 생성/갱신
3. .json 파일 생성/갱신 (json-export 규칙)
4. .html 파일 생성/갱신 (이 문서의 규칙)
```

---

## 6. 체크리스트

### HTML 생성 시
- [ ] Pretendard 폰트 CDN + 폴백
- [ ] 모든 CSS는 `<style>` 블록 내
- [ ] 외부 JS 라이브러리 미사용
- [ ] 반응형 최소 대응
- [ ] 단일 HTML 파일로 완결
- [ ] `.md`와 동일한 데이터
- [ ] 테이블/차트는 HTML/CSS로 구현
