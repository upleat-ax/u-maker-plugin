---
name: us-wireframe
description: |
  화면 와이어프레임을 HTML로 생성하거나 갱신한다. ua-ux 에이전트가 담당한다.
  IA, Screen 문서를 참고하여 HTML/CSS로 레이아웃을 시각화한다.
  각 화면 요소에는 floating 어노테이션 패널이 포함된다 —
  관련 요구사항(FR), 플로우(SC/User Flow), 조건(Business Rule), 요소 설명을 표시한다.
  Triggers: /uc-wireframe, HTML 와이어프레임, wireframe generate
user-invocable: true
argument-hint: "[app] <all|screen-id>"
---

# u-wireframe Skill

`ua-ux` 에이전트가 담당하는 HTML 와이어프레임 생성 스킬.
SSoT 문서(IA, Screen, SRS)를 참고하여 각 화면을 HTML 파일로 시각화한다.

---

## Syntax

```
/uc-wireframe [app] [all|<ScreenID>]
```

- `[app]`: 앱 이름 (생략 시 단일 앱 자동 선택 또는 AskUserQuestion)
- `all` (기본값): 모든 화면 생성
- `<ScreenID>`: 특정 화면만 생성 (예: `S-0010`)

---

## Reference Documents

| 문서 | 경로 | 참조 내용 |
|------|------|----------|
| IA | `u-docs/{app}/01-plan/1_IA_RA.md` | 화면 계층, 메뉴 구조, Screen ID |
| Screen Design | `u-docs/{app}/02-design/2_Screen_UX.md` | 레이아웃, Elements, Interactions |
| SRS | `u-docs/{app}/01-plan/1_SRS_RA.md` | FR 목록, Business Rules, Conditions |
| SRS (US) | `u-docs/{app}/01-plan/1_SRS_RA.md` | User Stories, User Flows |

---

## Output

```
u-docs/{app}/02-design/2_Screen_Wireframes/
  {ScreenID}.html   ← 화면별 1개 HTML 파일
  _shared.css       ← 공통 스타일 (floating 패널 포함)
  index.html        ← 전체 화면 네비게이션
```

---

## Floating Annotation Panel (핵심 기능)

모든 와이어프레임 HTML에는 **floating 어노테이션 패널**이 포함된다.
화면의 각 주요 요소(컴포넌트/섹션)에 어노테이션 마커(`ⓘ`)가 표시되며,
마커를 클릭하면 해당 요소의 관련 정보를 담은 floating 패널이 열린다.

### 패널 표시 항목

| 섹션 | 내용 | 출처 문서 |
|------|------|----------|
| **요구사항** | 관련 FR-ID + 요약 | `1_SRS_RA.md` |
| **플로우** | 관련 User Story + 사용자 플로우 | `1_SRS_RA.md` (US) |
| **조건** | Business Rules, Validation 조건 | `1_SRS_RA.md` (FR Details) |
| **요소 설명** | 이 UI 요소의 역할/목적 설명 | `2_Screen_UX.md` (Elements) |

### Annotation 데이터 구조

각 어노테이션은 `data-annotation` 속성에 JSON 형식으로 정의한다:

```html
<div class="wf-element" data-annotation='{
  "elementId": "E-0010",
  "label": "로그인 폼",
  "requirements": [
    { "id": "FR-0010", "summary": "이메일/비밀번호 로그인" },
    { "id": "FR-0020", "summary": "소셜 로그인 지원" }
  ],
  "flows": [
    { "us": "US-0010", "desc": "사용자가 이메일과 비밀번호를 입력한다" },
    { "us": "US-0010", "desc": "로그인 버튼을 클릭한다" }
  ],
  "conditions": [
    "이메일 형식 유효성 검증 필수",
    "비밀번호 8자 이상",
    "5회 실패 시 계정 잠금"
  ],
  "description": "사용자 인증을 위한 로그인 폼. 이메일/비밀번호와 소셜 로그인 옵션 제공."
}'>
  <!-- 실제 UI 요소 -->
</div>
```

### HTML 구현 패턴

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>[ScreenID] [화면명] — Wireframe</title>
  <link rel="stylesheet" href="../_shared.css">
</head>
<body>
  <!-- 와이어프레임 헤더 -->
  <header class="wf-header">
    <span class="wf-screen-id">S-0010</span>
    <span class="wf-screen-name">로그인</span>
    <span class="wf-fr-refs">FR-0010, FR-0020, FR-0030</span>
    <span class="wf-us-refs">US-0010</span>
  </header>

  <!-- 화면 레이아웃 -->
  <main class="wf-canvas">
    <section class="wf-element" data-annotation='{...}'>
      <div class="wf-annotation-marker">ⓘ</div>
      <!-- 요소 내용 -->
    </section>
  </main>

  <!-- Floating 패널 (JavaScript로 제어) -->
  <div id="annotation-panel" class="wf-annotation-panel" hidden>
    <div class="panel-header">
      <span class="panel-element-label"></span>
      <button class="panel-close">✕</button>
    </div>
    <div class="panel-section panel-requirements">
      <h4>요구사항</h4>
      <ul class="req-list"></ul>
    </div>
    <div class="panel-section panel-flows">
      <h4>플로우</h4>
      <ol class="flow-list"></ol>
    </div>
    <div class="panel-section panel-conditions">
      <h4>조건</h4>
      <ul class="cond-list"></ul>
    </div>
    <div class="panel-section panel-description">
      <h4>요소 설명</h4>
      <p class="desc-text"></p>
    </div>
  </div>

  <script src="../_wireframe.js"></script>
</body>
</html>
```

### 공유 CSS (`_shared.css`) 핵심 스타일

```css
/* Wireframe 기본 */
.wf-canvas { position: relative; }
.wf-element { position: relative; border: 1px dashed #aaa; padding: 8px; margin: 4px; }

/* 어노테이션 마커 */
.wf-annotation-marker {
  position: absolute; top: 4px; right: 4px;
  width: 20px; height: 20px;
  background: #0057ff; color: white;
  border-radius: 50%; font-size: 12px;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; z-index: 10;
}
.wf-element:has(.wf-annotation-marker:hover) { outline: 2px solid #0057ff; }

/* Floating 패널 */
.wf-annotation-panel {
  position: fixed;
  width: 320px; max-height: 80vh;
  background: white; border: 1px solid #ddd;
  border-radius: 8px; box-shadow: 0 4px 24px rgba(0,0,0,0.15);
  overflow-y: auto; z-index: 1000;
  padding: 16px;
  transition: opacity 0.15s;
}
.wf-annotation-panel[hidden] { display: none; }
.panel-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.panel-element-label { font-weight: 700; font-size: 14px; }
.panel-close { border: none; background: none; cursor: pointer; font-size: 16px; }
.panel-section { margin-top: 12px; border-top: 1px solid #eee; padding-top: 10px; }
.panel-section h4 { font-size: 11px; font-weight: 600; text-transform: uppercase;
  color: #666; margin: 0 0 6px; }
.req-list li .req-id { font-family: monospace; color: #0057ff; font-weight: 600; }
.flow-list li .sc-ref { font-size: 10px; color: #888; }
.cond-list li { font-size: 13px; }
.desc-text { font-size: 13px; color: #333; }

/* 화면 헤더 */
.wf-header {
  padding: 8px 16px; background: #f5f5f5;
  border-bottom: 1px solid #ddd; display: flex; gap: 12px; align-items: center;
  font-size: 13px;
}
.wf-screen-id { font-family: monospace; font-weight: 700; color: #0057ff; }
.wf-fr-refs, .wf-sc-refs { font-size: 11px; color: #888; }
```

### 공유 JS (`_wireframe.js`) 핵심 로직

```javascript
document.querySelectorAll('.wf-annotation-marker').forEach(marker => {
  marker.addEventListener('click', (e) => {
    e.stopPropagation();
    const element = marker.closest('.wf-element');
    const data = JSON.parse(element.dataset.annotation);
    showAnnotationPanel(data, marker.getBoundingClientRect());
  });
});

function showAnnotationPanel(data, rect) {
  const panel = document.getElementById('annotation-panel');
  panel.querySelector('.panel-element-label').textContent = data.label;

  // 요구사항
  panel.querySelector('.req-list').innerHTML = data.requirements
    .map(r => `<li><span class="req-id">${r.id}</span> ${r.summary}</li>`).join('');

  // 플로우
  panel.querySelector('.flow-list').innerHTML = data.flows
    .map(f => `<li><span class="sc-ref">${f.sc} Step ${f.step}</span> ${f.desc}</li>`).join('');

  // 조건
  panel.querySelector('.cond-list').innerHTML = data.conditions
    .map(c => `<li>${c}</li>`).join('');

  // 요소 설명
  panel.querySelector('.desc-text').textContent = data.description;

  // 위치 결정 (화면 가장자리 처리)
  const panelW = 320;
  let left = rect.right + 8;
  if (left + panelW > window.innerWidth) left = rect.left - panelW - 8;
  panel.style.left = `${Math.max(8, left)}px`;
  panel.style.top = `${Math.min(rect.top, window.innerHeight - 100)}px`;
  panel.hidden = false;
}

document.addEventListener('click', () => {
  document.getElementById('annotation-panel').hidden = true;
});
```

---

## Execution Flow

```
1. 참조 문서 파싱
   ├── 1_IA_RA.md → Screen 목록 + Screen ID 추출
   ├── 2_Screen_UX.md → Elements 목록 + 레이아웃 추출
   ├── 1_SRS_RA.md → FR 목록 + Business Rules 추출
   └── 1_Roadmap_PM.md → SC 목록 + User Flow Steps 추출

2. 각 화면(ScreenID)별 어노테이션 데이터 생성
   ├── 화면 요소 → FR 매핑 (Screen Elements의 FR Mapping 필드 참조)
   ├── 화면 요소 → SC Step 매핑 (SC에서 해당 화면 관련 단계 추출)
   ├── 화면 요소 → 조건 추출 (FR Details의 Business Rule + Exception)
   └── 화면 요소 → 설명 추출 (Screen Elements의 Description 필드)

3. HTML 파일 생성
   ├── 각 ScreenID.html: 레이아웃 + 어노테이션 마커 포함
   ├── _shared.css: 공통 스타일 (floating 패널 포함)
   ├── _wireframe.js: 패널 동작 로직
   └── index.html: 전체 화면 네비게이션

4. 생성 결과 리포트 출력
```

---

## Annotation Mapping Rules

Screen 문서의 각 Element를 어노테이션 데이터로 변환하는 규칙:

| Screen Element 필드 | 어노테이션 패널 항목 | 변환 규칙 |
|--------------------|---------------------|----------|
| `FR Mapping` | **요구사항** | FR-ID로 SRS에서 Feature + 요약 조회 |
| `US Mapping` / 화면 ID | **플로우** | US에서 해당 화면과 연관된 플로우 추출 |
| FR Details > `Business Rule` + `Exception` | **조건** | 해당 FR의 비즈니스 규칙 + 예외 나열 |
| `Description` (Element) | **요소 설명** | Screen 문서의 요소 설명 직접 사용 |

---

## Rules

- `ua-ux` 에이전트가 담당
- 출력 경로: `u-docs/{app}/02-design/2_Screen_Wireframes/`
- `u_design` 또는 `u-design` 폴더 사용 금지
- 모든 텍스트는 `u-maker.config.json`의 `documentLanguage` 설정 언어로 작성
- 어노테이션 데이터가 없는 요소도 마커(`ⓘ`)는 렌더링하되 내용을 "정보 없음"으로 표시
- `_shared.css`, `_wireframe.js`는 모든 화면이 공유하는 단일 파일로 생성
- 기존 파일이 있으면 덮어쓰기 (최신 SSoT 반영)
