---
name: the-voice-meeting
description: This skill should be used when the user asks to "회의록 작성", "회의록 만들어", "m4a 트랜스크립션", "음성 파일 분석", "녹음 파일 정리", "meeting minutes", "transcribe audio", or mentions m4a/txt files in meeting-related context. 2개의 에이전트(Minutes Writer + Minutes Reviewer)가 협업하여 품질 95점 이상까지 반복 보완하는 구조화된 HTML 회의록을 자동 생성.
---

# Meeting Minutes Generator (2-Agent Quality Loop)

m4a 음성 녹음 파일이나 텍스트 트랜스크립트(`.txt`, `.md`, `.srt`, `.vtt`)를 분석하여 구조화된 HTML 회의록을 생성하는 워크플로우.
**Minutes Writer**와 **Minutes Reviewer** 2개의 에이전트가 역할을 분담하여, 10개 품질 기준의 평균 점수가 **95점 이상**이 될 때까지 반복 보완한다.

## Architecture: 2-Agent Quality Loop

```
┌──────────────────────────────────────────────────────────┐
│                    Orchestrator                          │
│              (Main Claude Instance)                      │
│                                                          │
│  1. 입력 파일 탐색 + 전사 (Step 1-3)                     │
│  2. Writer에게 회의록 생성 지시                          │
│  3. 생성 완료 → Reviewer에게 평가 지시                   │
│  4. 평균 < 95 → Writer에게 피드백 전달 (반복)            │
│  5. 평균 >= 95 → 다이어그램 삽입 + 업로드 (Step 5-7)    │
│                                                          │
│  ┌────────────────┐        ┌───────────────────┐         │
│  │ Minutes Writer │◄──────►│ Minutes Reviewer  │         │
│  │   (Agent 1)    │        │    (Agent 2)      │         │
│  │                │        │                   │         │
│  │ HTML 회의록    │        │ 10개 기준 평가    │         │
│  │ 생성/수정 전담 │        │ 점수+피드백 산출  │         │
│  └────────────────┘        └───────────────────┘         │
└──────────────────────────────────────────────────────────┘
```

## Processing Policy

이 스킬은 macOS 내장 Apple Speech Recognition을 활용한 전사를 기본으로 한다.

- **1순위**: `scripts/transcribe-apple.swift`로 Apple Speech 전사 실행 (macOS 내장, 추가 설치 불필요)
- **2순위**: 이미 `.txt`, `.md`, `.srt`, `.vtt` 텍스트 트랜스크립트가 있으면 그것을 우선 사용
- **3순위**: LLM이 오디오를 직접 읽을 수 있는 환경이면 직접 처리
- `whisper`, `mlx-whisper`, `ffmpeg`, diarization 등 외부 패키지 설치를 전제로 하지 않는다
- 화자 라벨은 항상 **`참여자1`, `참여자2`, `참여자N`** 형식을 사용한다
- 문맥으로 화자의 실명·역할을 추론할 수 있으면 **별도 "화자 추론" 섹션**에 기록 (근거 컬럼 없이 화자/추론 이름·역할/확신도 3컬럼만)

## Workflow

### Step 1: 입력 파일 탐색

대상 폴더에서 오디오 파일과 텍스트 트랜스크립트 파일을 **모두** 확인한다.

- `Recording`으로 시작하는 m4a 파일은 미처리 상태이므로 우선 처리 대상
- `.txt` 파일이 단독으로 존재하면 **텍스트 트랜스크립트 자체가 입력 원본** → Apple Speech 전사 없이 바로 Step 4로 진행
- `.txt` 파일에 `Attendees N` 라벨이 있으면 이를 `참여자N`으로 매핑

### Step 2: Apple Speech 전사

```bash
# 한국어 (기본)
swift ~/.claude/skills/the-voice-meeting/scripts/transcribe-apple.swift "<m4a파일경로>"

# JSON 출력 (타임스탬프 + 세그먼트)
swift ~/.claude/skills/the-voice-meeting/scripts/transcribe-apple.swift "<m4a파일경로>" ko-KR --json

# 영어 회의
swift ~/.claude/skills/the-voice-meeting/scripts/transcribe-apple.swift "<m4a파일경로>" en-US
```

- 텍스트 트랜스크립트(`.txt` 등)가 이미 있으면 전사 건너뜀
- 전사 결과는 stdout으로 출력, 중간 파일로 별도 보존하지 않음
- 화자 분리(diarization) 미지원. 문맥으로 추론하되 불확실하면 중립 라벨 유지

### Step 3: 파일명 지정

`Recording YYYYMMDDHHMMSS.m4a` 형식 → `{MMDD}-{주제}.m4a`로 이름 변경.
- 날짜 prefix: `MMDD`, 주제: 핵심 키워드 2~3개를 하이픈으로 연결
- 예: `0401-인력배치-기획자투입.m4a`

### Step 4: 2-Agent HTML 회의록 생성

#### Minutes Writer Agent 실행

Agent 도구로 **minutes-writer** 에이전트를 생성한다. 프롬프트에 반드시 포함할 정보:

- 전사 결과 텍스트 전문 (또는 txt 파일 경로)
- 출력 HTML 파일 경로
- `assets/template.html`의 전체 CSS를 인라인으로 복사하여 단일 HTML 파일 생성 지시
- `references/design-system.md`를 읽어 디자인 시스템 규칙과 HTML 구조 준수 지시
- 작성 원칙 (아래 참조)
- **재작성 시**: Reviewer의 피드백과 감점 기준을 프롬프트에 포함하여 해당 부분만 개선 지시

#### Minutes Reviewer Agent 실행

Writer가 생성한 HTML 파일을 Minutes Reviewer 에이전트가 평가한다.
프롬프트에 반드시 포함할 정보:

- 생성된 HTML 파일 경로
- 원본 전사 텍스트 또는 txt 파일 경로 (콘텐츠 정확성 비교용)
- `references/scoring-criteria.md`를 읽어 10개 평가 기준 적용 지시
- 반드시 아래 형식으로 결과 출력 지시

**Reviewer 출력 형식:**

```
## 평가 결과

| # | 기준 | 점수 | 비고 |
|---|------|------|------|
| 1 | 구조 완전성 | XX | ... |
| ... | ... | ... | ... |

**평균 점수: XX.X / 100**
**합격 여부: PASS / FAIL**

## 개선 피드백 (95점 미만 항목)

### [기준명] (현재 XX점 → 목표 95+)
- 문제: [구체적 위치와 내용]
- 개선 방안: [어떻게 수정해야 하는지]
```

#### 반복 판단 (Orchestrator)

- **평균 >= 95**: 합격. Step 5로 진행.
- **평균 < 95**: Reviewer의 피드백을 Writer에게 전달하여 재작성 지시. Reviewer 재평가.
- **최대 반복**: 5회. 5회 후에도 미달 시 현재 상태로 완료 처리하고 미달 항목 보고.

### Step 5: 총정리 문서 (선택)

같은 날짜의 회의록이 2개 이상이면 `{MMDD}-00-전체총정리.html`로 종합 정리.

### Step 6: 서버 업로드

생성된 HTML 회의록을 서버에 업로드한다. `.env` 파일(`~/.claude/skills/the-voice-meeting/.env`) 참조.

```bash
curl -X POST 'https://m7d.firestick.live/v4/docs?bucketId=69cd33f60b6f1e9c6e7398f1' \
    -H 'Content-Type: application/json' \
    -H 'x-m7-api-key: m7_2e5834e5cb97e5f07be58d524a536c7f22362e0806ae80a0' \
    -d '[{
      "type": "WIKI", "subtype": "HYUNJIN", "substatus": "MEETING",
      "title": "<회의제목>", "subtitle": "<핵심요약 plain text 150자>",
      "content": "<HTML 전체>",
      "bucketId": "69cd33f60b6f1e9c6e7398f1",
      "userData": { "meetingDate": "YYYY-MM-DD HH:mm" }
    }]'
```

**meetingDate 추출 우선순위**: 파일 내용(일시 정보) > 파일명 MMDD > m4a 파일명 타임스탬프.
**subtitle**: highlight-box 내용에서 HTML 태그 제거, 150자 truncate.
**PATCH/DELETE**: 로그인 토큰 필요 — `.env`의 `M7D_LOGIN_API_KEY`로 `/v4/auth/login` 호출 후 JWT 사용.

## 작성 원칙

Minutes Writer 에이전트에 전달할 핵심 규칙:

- `assets/template.html`의 CSS를 **인라인으로 복사**하여 단일 HTML 파일 생성 (Pretendard CDN만 예외)
- 기본 구조: `개요 → 참석자 & 안건 → 논의 내용 → 결정 사항 → 액션 아이템 → AI 커멘트 → 다이어그램`
- **사이드바 네비게이션 필수** (짧은 회의도 예외 없음)
- 화자 라벨은 `참여자1`, `참여자2` 형식만 사용. 실명 추론은 별도 테이블 (근거 컬럼 없이)
- 논의 내용은 feature-card로 주제별 묶기, 화자별 주장/질문/반박 분리
- 결정 사항(decision-list)과 액션 아이템(data-table) 반드시 분리
- AI 커멘트: 누락 논의(warning), 리스크(risk), 개선 제안(suggestion)
- 다이어그램: 의미 있는 프로세스/구조를 인라인 SVG로 (없으면 생략)
- 트랜스크립트의 구어체를 정제된 문어체로 변환
- 전체 원문 트랜스크립트는 HTML에 포함하지 않음

## 10개 품질 평가 기준 (요약)

| # | 기준 | 핵심 체크 포인트 |
|---|------|------------------|
| 1 | 구조 완전성 | 7개 필수 섹션 + 사이드바 + 메타카드 모두 포함 |
| 2 | 디자인 시스템 준수 | CSS 변수·클래스 정확 사용, template.html 스타일 일치 |
| 3 | 콘텐츠 정확성 | 원본 트랜스크립트 대비 누락·왜곡 없음 |
| 4 | 화자 추적 정확성 | 참여자N 라벨 일관성, 화자 추론 테이블 정확 |
| 5 | 논의 구조화 | 주제별 feature-card 그룹핑, 화자 turn 추적 |
| 6 | 결정/액션 분리 | 결정 사항 vs 액션 아이템 명확 분리, 구체적 |
| 7 | 네비게이션 기능성 | 사이드바 링크·앵커·스크롤 추적 정확 동작 |
| 8 | AI 분석 품질 | 통찰력 있는 커멘트, 단순 반복 아닌 분석적 |
| 9 | 다이어그램 적합성 | SVG 기술적 정확성, 회의 내용과 관련성 |
| 10 | 완성도 | 빈 섹션·TODO 없음, 문체 일관, 세부 마감 |

상세 채점 기준은 `references/scoring-criteria.md` 참조.

## Additional Resources

### Reference Files

- **`references/scoring-criteria.md`** — 10개 평가 기준의 상세 정의, 채점 루브릭, 감점 사례
- **`references/design-system.md`** — 다크 사이드바 디자인 시스템, CSS 클래스, HTML 구조, 컴포넌트 카탈로그

### Asset & Script Files

- **`assets/template.html`** — 기본 HTML 템플릿 (CSS 인라인 복사용)
- **`scripts/transcribe-apple.swift`** — macOS Apple Speech 전사 스크립트

## File Structure

```
{날짜}/
├── {MMDD}-{주제1}.m4a          # 원본 음성
├── {MMDD}-{주제1}.html         # 회의록
├── {MMDD}-{주제2}.txt          # 텍스트 트랜스크립트 (m4a 없이 단독 가능)
├── {MMDD}-{주제2}.html         # 회의록 (txt에서 직접 생성)
└── {MMDD}-00-전체총정리.html    # 당일 전체 종합 (선택)
```
