# Meeting Minutes Generator

m4a 음성 녹음 파일이나 이미 존재하는 텍스트 트랜스크립트를 LLM이 직접 읽고, 내용을 분석하여 구조화된 HTML 회의록을 생성하는 워크플로우.

> **Trigger**: 사용자가 "회의록 작성", "회의록 만들어", "m4a 트랜스크립션", "음성 파일 분석", "녹음 파일 정리", "meeting minutes", "transcribe audio" 등을 요청하거나, m4a 파일이 포함된 회의 관련 맥락에서 사용.

## Skill assets

이 스킬의 리소스는 아래 경로에 있다:

- Template: `${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-report/assets/template.html`

## Processing policy

이 스킬은 macOS 내장 Apple Speech Recognition을 활용한 전사를 기본으로 한다.

- **1순위**: `scripts/transcribe-apple.swift`로 Apple Speech 전사 실행 (macOS 내장, 추가 설치 불필요)
- **2순위**: 이미 `.txt`, `.md`, `.srt`, `.vtt` 텍스트 트랜스크립트가 있으면 그것을 우선 사용
- **3순위**: LLM이 오디오를 직접 읽을 수 있는 환경이면 직접 처리
- `whisper`, `mlx-whisper`, `ffmpeg`, diarization 등 외부 패키지 설치를 전제로 하지 않는다
- 화자 식별이 애매하면 실명을 추정하지 말고 `화자 A`, `화자 B`, `SPEAKER_01`처럼 중립 라벨을 유지한다

## Workflow

### Step 1: 입력 파일 탐색

대상 폴더에서 오디오 파일 또는 텍스트 트랜스크립트 파일을 확인한다. `Recording`으로 시작하는 파일은 미처리 상태이므로 우선 처리 대상.

```bash
ls <folder>/*.m4a
ls <folder>/*.{txt,md,srt,vtt}
```

### Step 2: Apple Speech 전사

m4a 파일을 macOS 내장 Apple Speech Recognition으로 전사한다. 추가 패키지 설치가 필요 없다.

```bash
# 한국어 (기본)
swift ${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-report/scripts/transcribe-apple.swift "<m4a파일경로>"

# JSON 출력 (타임스탬프 + 세그먼트 포함)
swift ${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-report/scripts/transcribe-apple.swift "<m4a파일경로>" ko-KR --json

# 영어 회의
swift ${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-report/scripts/transcribe-apple.swift "<m4a파일경로>" en-US
```

- 텍스트 트랜스크립트(`.txt`, `.md`, `.srt`, `.vtt`)가 이미 있으면 전사를 건너뛰고 해당 파일을 우선 사용
- 전사 결과는 stdout으로 출력되며, 중간 파일로 별도 보존하지 않는다
- 화자 분리(diarization)는 미지원. 화자 구분은 문맥으로 추론하되 불확실하면 중립 라벨 유지
- 분석 결과는 최종 HTML 회의록으로만 남긴다 (전체 트랜스크립트는 포함하지 않는다)

### Step 3: 파일명 지정

`Recording YYYYMMDDHHMMSS.m4a` 형식의 파일은 트랜스크립트 내용을 분석하여 주제를 파악한 뒤 `{MMDD}-{주제}.m4a`로 이름 변경.

네이밍 규칙:
- 날짜 prefix: `MMDD` (예: `0401`)
- 주제: 핵심 키워드 2~3개를 하이픈으로 연결 (예: `QA프로세스-WBS상세화`)
- 예시: `0401-인력배치-기획자투입.m4a`

### Step 4: HTML 회의록 생성

입력 파일의 전체 내용을 분석하여 아래 구조의 HTML 회의록을 작성한다. `${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-report/assets/template.html`의 스타일을 사용한다.

화자 정보가 있으면 분석 기본 단위는 개별 문장이 아니라 화자의 연속 발화 turn이다. 즉, 요약도 화자별 발화 맥락 기준으로 정리해야 한다.

#### 디자인 시스템

라이트 테마, 사이드바 네비게이션, Pretendard 폰트 기반의 깔끔한 문서 스타일. `assets/template.html`의 CSS를 그대로 사용한다.

#### 핵심 CSS 클래스

| 클래스 | 용도 |
|--------|------|
| `.meeting-info` + `.meeting-info-grid` | 회의 메타정보 카드 (일자, 참석자, 소요시간 등) |
| `.highlight-box` | 배경 강조 박스 (맥락 설명, 주요 참고사항) |
| `.decision` | 결정 사항 카드 (좌측 초록색 보더) |
| `.action-item` | 액션 아이템 카드 (좌측 파란색 보더) |
| `.topic-section` | 주제별 그룹 섹션 (배경색 포함 카드) |
| `.data-table` + `.data-table-wrap` | 데이터 테이블 |
| `.badge` `.badge-blue` | 태그/뱃지 |
| `.timestamp` | 타임스탬프 표시 (모노스페이스) |
| `.section-divider` | 섹션 구분선 (`<hr>`) |

#### 레이아웃 구조

```html
<!-- 사이드바: 논의 주제가 3개 이상이면 생성 -->
<nav class="sidebar">
  <ul class="sidebar-nav">
    <li class="sidebar-label">회의 내용</li>
    <li><a href="#overview"><span class="nav-num">01.</span> 회의 개요</a></li>
    <li><a href="#topic1"><span class="nav-num">02.</span> 주제1</a></li>
    ...
    <li class="sidebar-label">정리</li>
    <li><a href="#decisions"><span class="nav-num">N.</span> 결정 사항</a></li>
    <li><a href="#actions"><span class="nav-num">N.</span> 액션 아이템</a></li>
  </ul>
</nav>
```

#### 회의록 구조

```html
<!-- 회의 메타정보 -->
<div class="meeting-info">
  <div class="meeting-info-grid">
    <span class="meeting-info-label">일자</span>
    <span class="meeting-info-value">2026년 4월 1일 (화)</span>
    <span class="meeting-info-label">소요시간</span>
    <span class="meeting-info-value">약 20분</span>
    <!-- 필요 시 참석자, 논의 범위 등 추가 -->
  </div>
</div>

<hr class="section-divider">
<h2 id="overview">회의 개요</h2>
<p>1~2문장 요약</p>

<hr class="section-divider">
<h2 id="topic1">주제1 제목</h2>
<!-- 주제가 복잡하면 topic-section으로 감싸기 -->
<div class="topic-section">
  <div class="topic-header">
    <div class="topic-title">소주제</div>
  </div>
  <ul>...</ul>
</div>

<!-- 또는 단순하게 h3 + ul -->
<h3>소주제</h3>
<ul><li>내용</li></ul>

<hr class="section-divider">
<h2 id="decisions">결정 사항</h2>
<div class="decision">
  <strong>결정 제목</strong> — 결정 내용
</div>

<hr class="section-divider">
<h2 id="actions">액션 아이템</h2>
<div class="action-item">
  <strong>담당자</strong> — 해야 할 일
</div>

<!-- 액션 아이템이 많으면 테이블 사용 -->
<div class="data-table-wrap">
<table class="data-table">
  <thead><tr><th>담당</th><th>내용</th><th>기한</th></tr></thead>
  <tbody><tr><td>홍길동</td><td>작업 내용</td><td>4월 중순</td></tr></tbody>
</table>
</div>

<h2>기타 메모</h2>
<div class="highlight-box">
  <ul><li>부수적으로 언급된 내용</li></ul>
</div>
```

#### 작성 원칙

- 트랜스크립트의 구어체를 정제된 문어체로 변환
- 인명은 트랜스크립트에 나오는 그대로 사용 (음성 인식 오류 가능성 주의)
- 화자 인식이 있으면 각 주제에서 화자별 주장, 질문, 요청, 반응을 분리해 정리
- 실명 매핑 근거가 없으면 `SPEAKER_01`, `화자 A`처럼 중립 라벨 유지
- 결정 사항과 액션 아이템은 반드시 분리하여 명확하게 표기
- 전체 트랜스크립트는 HTML에 포함하지 않는다 (회의록은 분석/정리 결과만 담는다)
- 사이드바는 논의 주제가 3개 이상일 때만 생성 (짧은 회의는 생략)
- `<hr class="section-divider">`로 주요 섹션을 시각적으로 구분
- 파일명: m4a 파일과 동일한 이름으로 `.html` 확장자 (예: `0401-QA프로세스-WBS상세화.html`)

### Step 5: 총정리 문서 (선택)

같은 날짜의 회의록이 2개 이상이면 `{MMDD}-00-전체총정리.html` 파일을 생성하여 당일 전체 회의를 하나의 문서로 종합 정리.

## File Structure

```
{날짜}/
├── {MMDD}-{주제1}.m4a          # 원본 음성
├── {MMDD}-{주제1}.html         # 회의록
├── {MMDD}-{주제2}.m4a
├── {MMDD}-{주제2}.html
└── {MMDD}-00-전체총정리.html    # 당일 전체 종합 (선택)
```

## Tips

- 긴 회의는 먼저 주제 단위와 의사결정 단위를 분리한 뒤 HTML 구조에 매핑한다.
- 오디오 품질이 낮거나 겹침 발화가 많으면, 불확실한 구간은 단정하지 말고 `추가 확인 필요`로 남긴다.
- 별도 JSON 캐시나 전사 스크립트를 만들지 않는다.
