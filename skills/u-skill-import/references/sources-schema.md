# _sources.json Schema

## Full Schema

```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-03-21T00:00:00.000Z",
  "sources": [
    {
      "id": "SRC-001",
      "type": "figma",
      "location": "https://figma.com/design/XXXXX/...",
      "target": ["screen", "uxguide", "designtoken"],
      "app": "web",
      "description": "메인 앱 디자인 파일",
      "priority": 1,
      "status": "pending",
      "lastImported": null,
      "error": null,
      "options": {
        "nodeId": "123:456",
        "pages": ["Home", "Dashboard"]
      }
    },
    {
      "id": "SRC-002",
      "type": "doc",
      "location": "docs/client-rfi.pdf",
      "target": ["srs"],
      "app": "web",
      "description": "고객 RFI 문서",
      "priority": 2,
      "status": "pending",
      "lastImported": null,
      "error": null,
      "options": {
        "pages": "1-20",
        "language": "ko"
      }
    },
    {
      "id": "SRC-003",
      "type": "url",
      "location": "https://competitor.com/dashboard",
      "target": ["srs", "screen", "ia"],
      "app": "web",
      "description": "경쟁사 대시보드 분석",
      "priority": 3,
      "status": "pending",
      "lastImported": null,
      "error": null,
      "options": {
        "depth": 2,
        "screenshot": true
      }
    }
  ]
}
```

## Field Definitions

### Root

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Schema version (semver) |
| `lastUpdated` | string | No | ISO 8601 timestamp of last modification |
| `sources` | array | Yes | Source entry list |

### Source Entry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier (SRC-NNN format, auto-increment) |
| `type` | enum | Yes | `figma`, `pencil`, `stitch`, `url`, `doc`, `image` |
| `location` | string | Yes | URL (figma/url) or relative path from `.u-maker/refs/` (doc/image/pencil/stitch) |
| `target` | string[] | Yes | Target SSoT document types |
| `app` | string | No | Target app name (생략 시 config의 첫 번째 앱) |
| `description` | string | No | Source description |
| `priority` | number | No | Import priority (lower = higher priority, default: 10) |
| `status` | enum | Yes | `pending`, `imported`, `failed` |
| `lastImported` | string | No | ISO 8601 timestamp of last successful import |
| `error` | string | No | Error message (status: failed일 때) |
| `options` | object | No | Source type별 추가 옵션 |

### type Values

| Type | location Format | Description |
|------|----------------|-------------|
| `figma` | Figma URL (`https://figma.com/design/...`) | Figma 디자인 파일 |
| `pencil` | Relative path (`designs/app.pen`) | pencil.dev .pen 파일 |
| `stitch` | Relative path (`designs/app.stitch`) | Stitch 디자인 파일 |
| `url` | Web URL (`https://...`) | 웹페이지 |
| `doc` | Relative path (`docs/spec.pdf`) | 문서 파일 (PDF, MD, DOCX, PPTX, TXT) |
| `image` | Relative path (`screenshots/home.png`) | 이미지 파일 (PNG, JPG, WEBP) |

### target Values

| Value | SSoT Document | Description |
|-------|--------------|-------------|
| `srs` | `1_SRS_RA.md` | FR, US, FT 추출 |
| `ia` | `1_IA_RA.md` | 메뉴/네비게이션 구조 |
| `glossary` | `1_Glossary_RA.md` | 용어 정의 |
| `screen` | `2_Screen_UX.md` | 화면 상세 설계 |
| `screenflow` | `2_ScreenFlow_UX.md` | 화면 흐름도 |
| `uxguide` | `2_UXGuide_UX.md` | UX 가이드/디자인 시스템 |
| `designtoken` | `3_DesignToken_UX.md` | 디자인 토큰 |
| `uicomponents` | `3_UIComponents_UX.md` | UI 컴포넌트 카탈로그 |
| `erd` | `2_ERD_SA.md` | 데이터 모델 |
| `api` | `2_API_SA.md` | API Contract |

### status Values

| Status | Description |
|--------|-------------|
| `pending` | 아직 임포트되지 않음 |
| `imported` | 임포트 완료 |
| `failed` | 임포트 실패 (error 필드 참조) |

### options (Source Type별)

#### figma options

| Field | Type | Description |
|-------|------|-------------|
| `nodeId` | string | 특정 노드/프레임 ID (생략 시 전체) |
| `pages` | string[] | 임포트할 페이지 이름 목록 |

#### pencil/stitch options

| Field | Type | Description |
|-------|------|-------------|
| `frames` | string[] | 임포트할 프레임 이름 목록 |

#### url options

| Field | Type | Description |
|-------|------|-------------|
| `depth` | number | 크롤링 깊이 (기본: 1, 해당 페이지만) |
| `screenshot` | boolean | 스크린샷 자동 촬영 여부 (기본: true) |
| `selectors` | string[] | 특정 CSS 셀렉터만 추출 |

#### doc options

| Field | Type | Description |
|-------|------|-------------|
| `pages` | string | PDF 페이지 범위 (예: "1-20") |
| `language` | string | 문서 언어 (자동 감지 시 생략) |
| `sections` | string[] | 특정 섹션/챕터만 추출 |

#### image options

| Field | Type | Description |
|-------|------|-------------|
| `screenId` | string | 매핑할 Screen ID (S-NNNN) |
| `description` | string | 이미지 설명 (인식 보조) |

## Initial File Template

`/u-skill-import init` 실행 시 생성되는 초기 파일:

```json
{
  "version": "1.0.0",
  "lastUpdated": null,
  "sources": []
}
```
