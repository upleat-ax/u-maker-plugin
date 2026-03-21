---
name: u-skill-import
description: |
  외부 소스(문서, Figma, pencil.dev, Stitch, URL, 이미지)를 SSoT 문서로 변환한다.
  .u-maker/refs/ 폴더의 참고 자료와 _sources.json 매핑을 기반으로 SRS, Screen, ERD, API 등 SSoT 문서를 자동 생성한다.
  Args: `[source-type] [path-or-url]` — 단건 임포트 또는 인자 없이 _sources.json 일괄 처리
  Triggers: /u-skill-import, 임포트, import, 문서 임포트, 외부 문서, 참고 자료, reference import,
  figma import, 디자인 임포트, url import, 문서 변환, 소스 임포트, 자료 가져오기, 문서화, 문서 생성,
  from figma, from pencil, from stitch, from url, from document
model: sonnet
user-invocable: true
argument-hint: "[source-type] [path-or-url]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  u-agent-ra: u-maker:u-agent-ra
  u-agent-sa: u-maker:u-agent-sa
  u-agent-ux: u-maker:u-agent-ux
---

# u-skill-import

외부 소스(문서, 디자인 파일, URL, 이미지)를 분석하여 SSoT 문서를 자동 생성하거나 갱신한다.

## Syntax

```
/u-skill-import                              # _sources.json 기반 일괄 임포트
/u-skill-import figma <url>                  # Figma 디자인 → Screen/UXGuide
/u-skill-import pencil <path>                # .pen 파일 → Screen/DesignToken
/u-skill-import stitch <path>                # .stitch 파일 → Screen/DesignToken
/u-skill-import url <url>                    # 웹페이지 분석 → SRS/Screen
/u-skill-import doc <path>                   # 문서(PDF/MD/DOCX) → SRS/IA
/u-skill-import image <path>                 # 스크린샷/이미지 → Screen
/u-skill-import init                         # .u-maker/refs/ 구조 초기화
/u-skill-import sources                      # _sources.json 현황 조회
```

## Reference Folder Structure

```
.u-maker/refs/
├── _sources.json              # 소스 매핑 메타데이터
├── docs/                      # 문서 파일 (PDF, MD, DOCX, PPTX 등)
├── screenshots/               # 캡처/이미지 (PNG, JPG 등)
└── data/                      # 기타 데이터 (CSV, JSON, XML 등)
```

### _sources.json Schema

`references/sources-schema.md` 참조. 핵심 구조:

```json
{
  "version": "1.0.0",
  "sources": [
    {
      "id": "SRC-001",
      "type": "figma|pencil|stitch|url|doc|image",
      "location": "<URL or relative path from .u-maker/refs/>",
      "target": ["srs", "screen", "erd", "api", "ia", "uxguide"],
      "app": "web",
      "description": "소스 설명",
      "status": "pending|imported|failed",
      "lastImported": null
    }
  ]
}
```

## Source Type → SSoT Document Mapping

| Source Type | MCP/Tool | Target Documents |
|-------------|----------|-----------------|
| `figma` | Figma MCP (`get_design_context`, `get_screenshot`) | Screen, UXGuide, DesignToken, ScreenFlow |
| `pencil` | pencil.dev MCP (`batch_get`, `get_screenshot`) | Screen, UXGuide, DesignToken |
| `stitch` | Stitch MCP | Screen, UXGuide, DesignToken |
| `url` | WebFetch | SRS, Screen, IA |
| `doc` | Read (MD/TXT), Bash+pdftotext (PDF) | SRS, IA, ERD, API, Glossary |
| `image` | Read (이미지 인식) | Screen, IA |

## Flow

### Mode 1: 단건 임포트 (인자 지정)

```
1. 인자 파싱 (source-type, path-or-url)
2. App context 결정 (config 또는 AskUserQuestion)
3. 소스 읽기:
   - figma → Figma MCP: get_design_context + get_screenshot
   - pencil → pencil MCP: get_editor_state + batch_get + get_screenshot
   - stitch → Stitch MCP 초기화 + 읽기
   - url → WebFetch로 페이지 크롤링
   - doc → Read (MD/TXT) 또는 PDF 파싱
   - image → Read (시각 분석)
4. 소스 내용 분석 → 추출 가능한 SSoT 요소 식별:
   - 화면 구조 → Screen 항목 (S-NNNN)
   - 기능 요구사항 → FR/US/FT 항목
   - 데이터 모델 → ERD Entity
   - API 엔드포인트 → API Contract
   - 네비게이션 → IA 구조
5. 대상 SSoT 문서 생성/갱신 (u-agent-ra, u-agent-sa, u-agent-ux 협업)
6. _sources.json에 임포트 이력 기록
7. Post-Execution Summary Box 출력
```

### Mode 2: 일괄 임포트 (인자 없음)

```
1. .u-maker/refs/_sources.json 읽기
2. status: "pending" 소스 필터링
3. 소스별 순차 임포트 (Mode 1의 Step 3~5)
4. 각 소스의 status를 "imported"로 갱신 + lastImported 기록
5. 실패 시 status: "failed" + error 메시지 기록
6. 전체 결과 요약 출력
```

### Mode 3: init (초기화)

```
1. .u-maker/refs/ 디렉토리 생성 (docs/, screenshots/, data/)
2. _sources.json 초기 파일 생성 (빈 sources 배열)
3. 초기화 완료 메시지 출력
```

### Mode 4: sources (현황 조회)

```
1. _sources.json 읽기
2. 소스별 상태 테이블 출력 (ID, Type, Location, Target, Status)
3. refs/ 폴더 내 미등록 파일 탐지 → 등록 제안
```

## Design Tool Integration

`u-maker.config.json`의 `designTool.tool` 값을 확인하여:
- `pencil` → pencil.dev MCP 사용
- `figma` → Figma MCP 사용
- `stitch` → Stitch MCP 사용

단, source-type 인자가 명시된 경우 인자가 우선한다 (다른 도구의 디자인 파일도 임포트 가능).

## Source Analysis Rules

### figma/pencil/stitch → Screen

1. 프레임/페이지 목록 추출 → 각 프레임을 Screen 항목(S-NNNN)으로 매핑
2. 컴포넌트 라이브러리 → UIComponents 항목으로 추출
3. 컬러/타이포/스페이싱 → DesignToken으로 추출
4. 프레임 간 연결/프로토타입 → ScreenFlow로 추출

### url → SRS/Screen

1. 페이지 구조 분석 → IA (메뉴, 네비게이션)
2. 기능 식별 → FR/US/FT 후보 목록
3. UI 레이아웃 → Screen 참고 (스크린샷 자동 촬영)

### doc → SRS/ERD/API

1. 요구사항 문장 추출 → FR 후보
2. 사용자 시나리오 → US 후보
3. 데이터 구조/테이블 → ERD Entity 후보
4. API 명세 → API Contract 후보
5. 용어 → Glossary 후보

### image → Screen

1. UI 요소 인식 → Screen 항목의 Elements 추출
2. 레이아웃 구조 → Grid/Section 추출
3. 텍스트 인식 → 레이블, 메뉴 항목 추출

## Conflict Resolution

기존 SSoT 문서가 있는 경우:
- **Merge 모드** (기본): 기존 항목 유지 + 신규 항목 추가
- **Overwrite 모드** (`--force`): 기존 내용을 소스 기준으로 교체
- 충돌 시 AskUserQuestion으로 사용자 확인

## Rules

- 모든 SSoT 문서 생성/갱신 시 동명의 `.json` 파일 동일 경로에 함께 생성
- 소스에서 추출한 항목은 `[Imported: SRC-XXX]` 태그를 Origin에 기록
- 임포트 결과는 항상 사용자 검토 후 확정 (자동 Final 전환 금지, Draft로 생성)
- `.u-maker/refs/` 폴더 외부의 파일은 단건 임포트 시에만 허용 (일괄 모드는 refs/ 내부만)
- 디자인 도구 소스는 MCP를 통해 실시간 읽기 (파일 복사 불필요)
- URL 소스는 WebFetch로 실시간 크롤링
- Post-Execution Summary Box 출력 필수

## References

| File | Content |
|------|---------|
| `references/sources-schema.md` | _sources.json 전체 스키마 및 필드 설명 |
