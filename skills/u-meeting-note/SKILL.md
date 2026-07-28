---
name: u-meeting-note
description: This skill should be used when the user asks to "회의록", "회의록 작성", "구글밋 회의록", "Google Meet 녹화 분석", "미팅 녹화 정리", "리뷰 회의록", "화면 리뷰 정리", "수정사항 정리", "meeting minutes", "m4a 트랜스크립션", "음성 파일 분석", "녹음 파일 정리", "transcribe audio", or mentions Meet 녹화 영상 / Gemini 스크립트(.txt) / m4a·음성 녹음 파일 / 단독 텍스트 트랜스크립트 / meeting 폴더 in meeting-related context. 회의 입력(Meet 녹화+Gemini 스크립트 / 일반 오디오 m4a / 단독 텍스트 트랜스크립트)을 분석해 회의 유형을 판별하고 — 일반 회의는 2-Agent 품질 루프 HTML 회의록(고도화 템플릿), 화면 리뷰 회의는 수정사항 카드(지금/할 일/확인 + 뱃지 + 타임스탬프 + 화면캡쳐) HTML 리포트를 생성. (구 the-voice-meeting 스킬 흡수·대체.)
---

# u-meeting-note — 회의록 생성기 (Meet · 오디오 · 트랜스크립트, Dual-Mode)

회의 입력을 분석하여 회의 성격에 맞는 HTML 회의록을 생성하는 워크플로우. 입력은 **① Google Meet 녹화 영상 + Gemini 스크립트**(주력 — 화면캡쳐·리뷰모드 지원) · **② 일반 오디오 파일(m4a 등)** · **③ 단독 텍스트 트랜스크립트(.txt/.md/.srt/.vtt)** 를 받는다 (②③ 은 구 `the-voice-meeting` 스킬 흡수).

| 모드 | 대상 회의 | 산출물 | 템플릿 |
|------|-----------|--------|--------|
| **Mode A — 일반 회의록** | 논의·의사결정 중심의 일반 회의 (티타임, 협의, 킥오프 등) | 다크 사이드바 분석 회의록 (개요→논의→결정→액션→AI 커멘트) | `assets/template-general.html` |
| **Mode B — 리뷰 회의록** | 개발자·기획자가 화면을 보며 수정사항을 짚는 리뷰/검수 회의 | 수정사항 카드 리포트 — 항목별 **지금/할 일/확인** 3단 + 뱃지 + 영상 타임스탬프 + 화면캡쳐 (예: graphene-share 공유본) | `assets/template-review.html` |

두 모드 모두 **Writer + Reviewer 2-Agent 품질 루프**로 평균 95점 이상까지 반복 보완한다.

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                     Orchestrator (Main)                    │
│                                                            │
│  Step 0  입력 수집 (Meet+스크립트 / 오디오 / 단독 txt)     │
│  Step 1  전사 확보 (Gemini txt 우선 / whisper fallback)    │
│  Step 2  회의 유형 판별 → Mode A / Mode B                  │
│  Step 3  (Mode B만) 타임라인 매핑 + 화면 프레임 추출       │
│  Step 4  Writer Agent → HTML 생성                          │
│  Step 5  Reviewer Agent → 10개 기준 채점                   │
│          평균 < 95 → 피드백 전달, Writer 재작성 (최대 5회) │
│  Step 6  렌더 검증 + (Mode A) 서버 업로드                  │
│                                                            │
│   ┌────────────────┐          ┌───────────────────┐        │
│   │ Minutes Writer │◄────────►│ Minutes Reviewer  │        │
│   │  HTML 생성/수정│          │  채점 + 피드백    │        │
│   └────────────────┘          └───────────────────┘        │
└────────────────────────────────────────────────────────────┘
```

## Step 0: 입력 수집

사용자가 파일/폴더를 지정하면 그것을 사용한다. 지정이 없으면 아래 기본 위치를 탐색한다.

> 이 스킬은 **u-maker 플러그인 스킬**(`u-maker:u-meeting-note`)이다. 아래 `meeting/`·Drive 마운트·`reports/` 경로와 M7D 업로드는 **현진시닝 환경 기본값**이며, 다른 레포/머신에서는 사용자에게 입력 위치를 확인하고 산출물은 CWD 또는 scratchpad 에 둔다. 자체 스크립트는 `${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-note/…` 로 참조한다.

**Gemini 회의 노트 (`Meeting started … - Notes by Gemini` gdoc / 내보낸 .txt):**

Google Meet 의 Gemini 노트는 **하나의 Google Doc 안에 2개의 문서 탭**이다 — **`회의록` 탭**(요약·결정·다음 단계)과 **`스크립트` 탭**(화자 라벨 + 타임스탬프 축어 전사). **두 탭을 모두 확보한다.**
- **`회의록` 탭 = 1차 요약 재료**: Gemini 가 정리한 요약/결정/액션이 이미 있음 → **우측 글랜스 레일(요약·결정·미결·액션)과 개요를 여기서 출발**, 스크립트로 사실 검증 후 **간결히 재작성**(그대로 복붙 금지 — 문체·정확성 교정)
- **`스크립트` 탭 = 축어 원문**: 화자 turn·인용·타임스탬프·정확성의 근거
- 확보 방법:
  - Drive 로컬 마운트의 `.gdoc` 은 포인터(JSON)라 본문이 없다 → **Google Docs MCP `read_file_content(fileId)`** 로 읽으면 `## 회의록`·`## 스크립트` 두 탭이 함께 나온다 (화자 diarization 이 있어 whisper 보다 우선)
  - 사용자가 `.txt` 로 내보냈으면 그 안에 요약+스크립트가 함께 들어있을 수 있음
- 기본 위치: 프로젝트 루트 `meeting/` 폴더, 또는 녹화와 같은 `Meet Recordings/` 폴더
- 스크립트 형식: 타임스탬프 `MM:SS`(1시간 초과 시 `H:MM:SS`), `Attendees N` 발화 라벨. `Attendees N` 번호와 헤더 실명 나열 순서는 **대응 보장 안 됨** → 실명은 화자 추론으로만. 선두 BOM(`﻿`) 가능
- ASR 오인식 빈발(레거시→네거시, ERP→P/VIP, 효성PG→효성피지 등) → 회의록엔 교정 표기

**Google Meet 녹화 영상:**
- `~/Library/CloudStorage/GoogleDrive-thinoo@thepsyentist.com/My Drive/4_Archive/미팅녹화/Meet Recordings/`
- 파일명: `<회의코드> (YYYY-MM-DD HH:MM GMT+9)`, 세션이 끊겼다 재개되면 ` (1)`, ` (2)` 접미사로 분할
- **gdown / yt-dlp / MCP `download_file_content` 금지** — 사용자 소유 Drive 영상은 401 실패하거나 base64 로 컨텍스트가 폭발한다. **Drive for Desktop 로컬 마운트에서 직접 읽는다.**
- 영상 파일의 메타데이터 날짜는 신뢰 불가 → 회의 날짜는 스크립트 헤더 > 파일명에서 추출

영상만 있고 스크립트가 없으면 Step 1 의 whisper 경로로 전사한다. 스크립트만 있고 영상이 없으면 Mode B 에서 화면캡쳐를 생략하고 타임스탬프만 기재한다.

**일반 오디오 파일 · 단독 텍스트 트랜스크립트 (Meet 아님):**
- Meet 녹화/Gemini 스크립트가 아닌 **m4a·wav·mp3 등 음성 녹음**, 또는 **단독 `.txt`/`.md`/`.srt`/`.vtt` 트랜스크립트** 도 입력으로 받는다 (구 `the-voice-meeting` 스킬 흡수).
- 영상이 없으므로 화면 프레임 추출 불가 → 거의 항상 **Mode A(일반 회의록)** 로 처리한다. 오디오는 Step 1 의 whisper.cpp 로 전사, 트랜스크립트는 그대로 사용.
- 화자 라벨은 `참여자1..N`, 실명 추론은 별도 테이블(근거 컬럼 없음). Step 3(프레임 추출)은 건너뛴다.

## Step 1: 전사 확보

- **1순위**: Gemini 스크립트 `.txt`, 또는 기존 텍스트 트랜스크립트(`.md`/`.srt`/`.vtt`)가 있으면 그대로 사용 (화자 라벨·타임스탬프가 있으면 품질 최상)
- **2순위**: 오디오/영상 파일에서 오디오 추출 → whisper.cpp 전사
  ```bash
  ffmpeg -y -nostdin -i "<오디오_또는_영상파일>" -ar 16000 -ac 1 -c:a pcm_s16le "<scratchpad>/audio.wav"
  whisper-cli -m ~/.cache/whisper-models/ggml-large-v3-turbo.bin -l ko \
    -f "<scratchpad>/audio.wav" -otxt -of "<scratchpad>/transcript" -np
  ```
  (약 8배속, Metal 가속. 타임스탬프가 필요하면 `-osrt` 병행)
- **Apple Speech(swift) 전사 금지** — 서버 모드는 ~1분에서 truncation, 온디바이스는 ko 모델 미설치로 빈 결과
- whisper 전사에는 무음 구간에서 **동일 문장 수십~수천 줄 반복 환각**이 생긴다 ("한글자막 by …" 등) → 회의록 작성 전 반드시 제거

## Step 2: 회의 유형 판별

전사 전체를 훑고 아래 신호로 판별한다. 사용자가 모드를 명시하면 (`리뷰 회의록으로`, `일반 회의록으로`) 그것이 우선.

| 신호 | Mode B (리뷰) | Mode A (일반) |
|------|---------------|----------------|
| 화면 지시 표현 | "이 화면", "여기 버튼", "다음 페이지", "이거 눌러보면" 이 반복적으로 등장 | 드묾 |
| 수정 지시 발화 | "안 눌려요", "수정해야", "연동이 안 돼", "이렇게 바꿔" 등 **개별 수정 항목 ~10건 이상** | 의사결정·계획 논의 중심 |
| 진행 방식 | 화면을 순서대로 넘기며 walkthrough | 안건별 토론 |
| 참석자 역할 | 개발자·기획자·디자이너가 산출물을 검수 | 다양 |

- 신호가 명확하면 자동으로 모드를 선택하고, 최종 보고에 판별 근거를 한 줄 남긴다.
- 신호가 섞여 애매하면 (수정 지시 3~9건 수준의 논의형 회의 등) **AskUserQuestion 으로 모드를 확인**한다.

## Step 3 (Mode B 전용): 타임라인 매핑 + 화면 프레임 추출

### 3-1. 스크립트 ↔ 녹화 타임라인 매핑

Gemini 스크립트의 타임스탬프는 **녹화 wall-clock 과 1:1** 이다.

- 회의가 여러 세션이면 ("세션이 종료되었습니다") 녹화도 여러 파일로 분할됨
- 각 녹화의 duration 을 확인해 세션과 매칭: **녹화 duration ≒ 그 세션의 (마지막 − 처음) 스크립트 시각**
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-note/scripts/extract-frames.sh probe "<영상1>" "<영상2>"
  ```
- `video_offset` = 그 녹화에 대응하는 첫 스크립트 시각
- 프레임 추출 시각 (video-relative) = `스크립트 시각 − video_offset`

### 3-2. 크롭 판단 → 프레임 추출

먼저 **샘플 프레임 1장을 full 로 추출해 Read 로 확인**하고 공유 화면 레이아웃에 맞는 크롭을 정한다.

- Meet 1920×1080 기준, **모바일 화면 공유**는 좌중앙 세로 영역 → `mobile` 프리셋 (`crop=440:1080:500:0`)
- 데스크톱/웹 화면 공유는 `full` 또는 참가자 타일(우측)을 제외한 커스텀 `W:H:X:Y`
- 항목별 캡쳐 시각은 그 항목 논의가 **시작된 스크립트 시각**을 그대로 쓰면 해당 화면이 잡힌다

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-note/scripts/extract-frames.sh \
  "<영상파일>" "<scratchpad>/frames" mobile \
  a01=00:12:34 a02=00:15:02 b01=01:23:45
```

- 산출물 라벨은 **ASCII** (`a01`, `b03` …) — 한글 파일명은 NFD/NFC 불일치로 매칭이 깨진다
- 스크립트가 끝나면 `_contact-sheet.jpg` (montage) 가 생성됨 → **Read 한 번으로 전체 캡쳐를 일괄 검증** (프레임별 Read 금지, 비용 낭비)
- 잘못 잡힌 프레임만 시각을 ±수 초 조정해 재추출

### 3-3. 수정 항목 추출

전사에서 수정 지시를 빠짐없이 항목화한다. 항목당 필드:

- **영역/화면** (어느 메뉴·화면인지) / **제목** (한 줄) / **유형 뱃지** (버그·수정·연동·정책) / **먼저!** 여부 (아예 안 되는 것)
- **지금** (현상) / **할 일** (작업) / **확인** (완료 기준) — 각 1~2문장, 비개발자도 이해하는 쉬운 말
- **타임스탬프** (해당 논의 시작 스크립트 시각) / **캡쳐 라벨** (있으면)

작성 규칙 상세는 `references/design-system-review.md` §작성 원칙.

## Step 4: Writer Agent 실행

Agent 도구로 **minutes-writer** 에이전트를 생성한다. 프롬프트에 반드시 포함:

- 전사 텍스트 전문 또는 파일 경로 (+ Mode B: 추출한 항목 목록, 프레임 파일 경로·라벨 매핑)
- 출력 HTML 파일 경로
- 템플릿 CSS **인라인 복사** 지시 — Mode A: `assets/template-general.html`, Mode B: `assets/template-review.html` (Pretendard + Font Awesome CDN 예외; head 의 FA `<link>` 유지, 아이콘은 이모지 금지 → `<i class="fa-solid fa-…">`)
- 디자인 시스템 문서 읽기 지시 — Mode A: `references/design-system-general.md`, Mode B: `references/design-system-review.md`
- 이미지는 **base64 인라인**으로 삽입해 자체완결 HTML 로 (Mode B)
- **재작성 시**: Reviewer 의 피드백과 감점 항목을 프롬프트에 포함, 해당 부분만 개선

### Mode A 작성 원칙 (요약)

- **3열 레이아웃**: 좌 다크 사이드바(목차) + 중앙 본문 + **우 글랜스 레일 필수**(요약·결정·미결·액션 한눈, 아이콘=Font Awesome `fa-solid`, 이모지 금지)
- 기본 구조 **7섹션**: `개요 → 참석자 & 안건 → 논의 내용 → 결정 사항 → 미결 사항(#open-issues) → 액션 아이템 → AI 커멘트`
- **간결·평이체 (최우선)**: 개조식 우선, 한 항목 1~2줄, 쉬운 말. **논문투·장문 금지** — "논문 같다"는 피드백의 직접 대응. 우측 레일은 각 항목 한 줄
- **결정 / 미결 / 액션 3분리**: 미결(아직 안 정한 것)은 결정에 넣지 말고 `#open-issues` `issue-list` 로
- 화자 라벨은 `참여자1..N` 만, 실명 추론은 별도 테이블 (근거 컬럼 없음)
- 다이어그램은 별도 섹션 금지 — 관련 논의 카드 바로 아래 인라인 SVG (시각화 가능 내용 있으면 필수)
- 고도화 요소 활용: 통계 칩(stat-row)·발언 인용(quote)·화자 칩(sp)·글랜스/폭 토글 — `references/design-system-general.md` 참조
- 원문 트랜스크립트 전문은 미포함

### Mode B 작성 원칙 (요약)

- 기본 구조: `히어로(메타) → 읽는 법(30초) → 먼저!(P0) → 목차 → 약속·규칙 → 영역별 수정 항목 → 전체 요약 테이블` + **우측 글랜스 레일**(요약·먼저!·유형별·약속, 아이콘=Font Awesome `fa-solid`, 이모지 금지)
- 항목마다 지금/할 일/확인 3단 + 뱃지 + `⏱ H:MM:SS` + (캡쳐)
- 뱃지 필터·본문 폭 토글(1440↔1920)·글랜스 토글 동작 유지
- **쉬운 설명판·간결**이 원칙: 전문용어는 풀어 쓰고, 지금/할 일/확인은 1~2문장, "확인" 은 검증 가능한 문장으로

## Step 5: Reviewer Agent 실행

Writer 가 생성한 HTML 을 **minutes-reviewer** 에이전트가 채점한다. 프롬프트에 포함:

- 생성된 HTML 경로 + 원본 전사(또는 항목 목록) 경로
- `references/scoring-criteria.md` 의 **해당 모드 섹션** (§A 또는 §B) 10개 기준 적용 지시
- 출력 형식 (scoring-criteria.md 말미의 Reviewer 출력 형식) 준수 지시

**반복 판단 (Orchestrator):**
- 평균 ≥ 95 → 합격, Step 6
- 평균 < 95 → 피드백을 Writer 에게 전달해 재작성 → 재채점
- 최대 5회. 미달 시 현재 상태로 완료 처리하고 미달 항목 보고

## Step 6: 렌더 검증 + 산출물

**렌더 검증 (두 모드 공통):**
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless \
  --window-size=1440,20000 --screenshot="<scratchpad>/render.png" "file://<HTML절대경로>"
```
스크린샷을 Read 로 확인 — 레이아웃 깨짐·빈 이미지·placeholder 잔존이 보이면 Writer 에 수정 지시.

**산출물 위치 (프로젝트 컨벤션):**
- Mode A: `reports/{YYYY-MM-DD}/{MMDD}-{주제}.html`
- Mode B: `reports/{YYYY-MM-DD}/{주제slug}-review-meeting-{YYYYMMDD}.html`
- 날짜는 **회의 날짜** (스크립트 헤더 기준, 오늘 날짜 아님)

**서버 업로드 (Mode A 만):** `the-m7-upload` 스킬에 위임한다 (같은 M7D bucket, 자체 `.env` 보유 — 이 스킬은 M7D 키를 갖지 않는다).
```bash
python3 ~/.claude/skills/the-m7-upload/scripts/upload.py \
  "<HTML절대경로>" --substatus MEETING \
  --title "<회의제목>" \
  --user-data '{"meetingDate":"YYYY-MM-DD HH:mm"}'
```
- `title`/`subtitle` 미지정 시 upload.py 가 HTML `<h1>`·highlight-box 에서 자동 추출 (150자 truncate)
- `meetingDate` 는 **회의 날짜** (스크립트 헤더 기준). the-m7-upload·`.env` 부재면 업로드 생략하고 최종 HTML 경로만 보고
- 회의록은 `type:WIKI · subtype:HYUNJIN · substatus:MEETING` 으로 분류된다 (upload.py 기본값)

**공유 (Mode B):** graphene-share 등 외부 공유는 사용자가 직접 진행 — 스킬은 최종 HTML 경로만 보고한다.

## 함정 (반드시 지킬 것)

- **zsh 단어분리**: Bash 도구 셸은 zsh — 루프·배열 처리는 `#!/bin/bash` 스크립트 파일로 (scripts/extract-frames.sh 가 이 이유로 bash)
- **한글 NFD**: 디스크의 한글 파일명은 NFD, 입력 문자열은 NFC → 직접 매칭 실패. 글롭으로 잡고, 산출 파일은 ASCII 라벨
- **whisper 환각**: 반복 문장 블록은 전량 제거 후 사용
- **영상 메타 날짜 신뢰 불가**: 회의 날짜는 스크립트 헤더/파일명/내용에서
- **base64 자체완결**: 외부 이미지 참조 금지 — 공유 시 깨진다
- **강조 스타일**: 한쪽 border accent 금지 — 전체 `border` + 옅은 배경 (프로젝트 HTML 리포트 규칙)
- **다이어그램**: ER·flowchart·mindmap·트리는 인라인 SVG 직접 작성 (Mermaid 사용 안 함)

## Additional Resources

### References
- **`references/design-system-general.md`** — Mode A 디자인 시스템 (다크 사이드바 + 고도화 컴포넌트 카탈로그)
- **`references/design-system-review.md`** — Mode B 디자인 시스템 (수정 항목 카드·뱃지·필터·요약 테이블)
- **`references/scoring-criteria.md`** — 모드별 10개 채점 기준 (§A 일반 / §B 리뷰) + Reviewer 출력 형식

### Assets & Scripts
- **`assets/template-general.html`** — Mode A 템플릿 (CSS 인라인 복사용)
- **`assets/template-review.html`** — Mode B 템플릿 (CSS 인라인 복사용)
- **`scripts/extract-frames.sh`** — 녹화 프레임 추출 (probe / mobile·full·커스텀 크롭 / contact-sheet 생성)

## File Structure (산출물)

```
reports/{YYYY-MM-DD}/
├── {MMDD}-{주제}.html                           # Mode A 일반 회의록
└── {주제slug}-review-meeting-{YYYYMMDD}.html    # Mode B 리뷰 회의록 (캡쳐 base64 인라인)
```
