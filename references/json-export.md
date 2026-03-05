# JSON Export Standard

> u-maker 플러그인의 모든 SSoT 문서에 적용되는 JSON 내보내기 규칙.
> 에이전트는 마크다운 문서를 생성하거나 갱신할 때마다 **같은 경로에 동명의 .json 파일도 반드시 함께 생성/갱신**해야 한다.

---

## 1. 적용 규칙

| 조건 | 규칙 |
|------|------|
| **적용 시점** | 마크다운 문서를 Write 또는 Edit할 때마다 |
| **파일 경로** | 마크다운 파일과 **동일한 경로**, 확장자만 `.json`으로 변경 |
| **대상 내용** | 문서 내의 **목록(List) 데이터** — 개별 항목(ID, 상태, 매핑 등) |
| **항상 포함** | `document`, `meta`, 목록 배열 |
| **스키마 버전** | 마크다운 문서 `version`과 동기화 |

### 경로 예시

```
u-docs/shared/01-plan/1_Roadmap_PM.md  →  u-docs/shared/01-plan/1_Roadmap_PM.json
u-docs/web/01-plan/1_SRS_RA.md        →  u-docs/web/01-plan/1_SRS_RA.json
```

### 공통 메타 구조

모든 JSON 파일은 아래 공통 구조를 포함한다:

```json
{
  "document": "1_SRS_RA",
  "meta": {
    "owner": "ua-sa",
    "status": "Draft",
    "version": "v0.1.0",
    "lastUpdated": "YYYY-MM-DD",
    "app": "web"
  },
  "<listKey>": [ ... ]
}
```

---

## 2. 문서별 JSON 스키마

### 2.1 `1_Roadmap_PM.json`

```json
{
  "document": "1_Roadmap_PM",
  "meta": { "owner": "ua-ra", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
  "milestones": [
    {
      "name": "MVP 출시",
      "targetDate": "YYYY-MM-DD",
      "status": "Planned"
    }
  ]
}
```

### 2.2 `1_SRS_RA.json`

```json
{
  "document": "1_SRS_RA",
  "meta": { "owner": "ua-sa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "userStories": [
    {
      "id": "US-0010",
      "role": "사용자",
      "feature": "...",
      "benefit": "...",
      "priority": "Must",
      "frMapping": "FR-0010"
    }
  ],
  "functionalRequirements": [
    {
      "id": "FR-0010",
      "feature": "...",
      "description": "...",
      "priority": "Must",
      "usMapping": "US-0010",
      "status": "Not Started"
    }
  ],
  "nonFunctionalRequirements": [
    {
      "id": "NFR-0010",
      "category": "Performance",
      "requirement": "...",
      "metric": "..."
    }
  ]
}
```

### 2.3 `1_IA_RA.json`

```json
{
  "document": "1_IA_RA",
  "meta": { "owner": "ua-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "menuTree": [
    {
      "id": "MN-AUTH-0010",
      "name": "Login",
      "path": "/login",
      "depth": 2,
      "parentId": "MN-AUTH",
      "screenId": "S-0010",
      "frMapping": "FR-0010"
    }
  ],
  "screens": [
    {
      "id": "S-0010",
      "name": "로그인",
      "menuId": "MN-AUTH-0010",
      "path": "/login",
      "accessRole": "Public"
    }
  ]
}
```

### 2.4 `1_Index_PM.json`

```json
{
  "document": "1_Index_PM",
  "meta": { "owner": "ua-ra", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
  "documents": [
    {
      "id": "1_Roadmap_PM",
      "title": "로드맵",
      "owner": "ua-ra",
      "status": "Final",
      "version": "v1.0.0",
      "path": "u-docs/shared/01-plan/1_Roadmap_PM.md",
      "phase": "PLAN"
    }
  ]
}
```

### 2.5 `2_ERD_SA.json`

```json
{
  "document": "2_ERD_SA",
  "meta": { "owner": "ua-sa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
  "entities": [
    {
      "name": "User",
      "description": "...",
      "attributes": [
        { "name": "id", "type": "String", "primaryKey": true },
        { "name": "email", "type": "String", "unique": true }
      ],
      "relationships": [
        { "type": "hasMany", "target": "Post", "foreignKey": "userId" }
      ]
    }
  ]
}
```

### 2.6 `2_API_SA.json`

```json
{
  "document": "2_API_SA",
  "meta": { "owner": "ua-sa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "endpoints": [
    {
      "id": "API-0010",
      "method": "POST",
      "path": "/api/auth/login",
      "description": "...",
      "frMapping": "FR-0010",
      "auth": false,
      "requestBody": { "email": "string", "password": "string" },
      "responses": {
        "200": { "token": "string" },
        "401": { "error": "string" }
      }
    }
  ]
}
```

### 2.7 `2_Screen_UX.json`

```json
{
  "document": "2_Screen_UX",
  "meta": { "owner": "ua-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "screens": [
    {
      "id": "S-0010",
      "name": "로그인",
      "goal": "...",
      "accessRole": "Public",
      "menuId": "MN-AUTH-0010",
      "frMapping": ["FR-0010"],
      "wireframe": "2_Screen_Wireframes/S-0010.html",
      "connectedScreens": [
        { "screenId": "S-0020", "condition": "로그인 성공" }
      ],
      "elements": [
        { "name": "LoginForm", "type": "Form", "roleVisibility": "All" }
      ]
    }
  ]
}
```

### 2.8 `2_ScreenFlow_UX.json`

```json
{
  "document": "2_ScreenFlow_UX",
  "meta": { "owner": "ua-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "flows": [
    {
      "from": "S-0010",
      "to": "S-0020",
      "trigger": "로그인 성공",
      "condition": "인증 성공",
      "notes": "토큰 저장 후 이동"
    }
  ],
  "deepLinks": [
    {
      "path": "/login",
      "screenId": "S-0010",
      "params": "?redirect=",
      "authRequired": false
    }
  ],
  "errorFlows": [
    {
      "scenario": "세션 만료",
      "currentScreen": "모든 화면",
      "behavior": "자동 로그아웃",
      "targetScreen": "S-0010"
    }
  ]
}
```

### 2.9 `2_UXGuide_UX.json`

```json
{
  "document": "2_UXGuide_UX",
  "meta": { "owner": "ua-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
  "components": [
    {
      "name": "Button",
      "category": "atom",
      "variants": ["primary", "secondary", "ghost"],
      "description": "..."
    }
  ],
  "breakpoints": [
    { "name": "mobile", "maxWidth": 767 },
    { "name": "tablet", "minWidth": 768, "maxWidth": 1023 },
    { "name": "desktop", "minWidth": 1024 }
  ]
}
```

### 2.9 `3_UIComponents_UX.json`

```json
{
  "document": "3_UIComponents_UX",
  "meta": { "owner": "ua-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
  "components": [
    {
      "name": "Button",
      "category": "atom",
      "status": { "implementation": "done", "storybook": "done", "tests": "not-started" },
      "props": [
        { "name": "variant", "type": "string", "required": true, "default": "primary", "description": "..." }
      ],
      "variants": ["primary", "secondary", "ghost", "danger"]
    }
  ],
  "summary": {
    "total": 0,
    "implemented": 0,
    "progress": 0
  }
}
```

### 2.10 `3_DesignToken_UX.json`

```json
{
  "document": "3_DesignToken_UX",
  "meta": { "owner": "ua-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
  "primitive": [
    { "name": "color-blue-500", "value": "#3B82F6", "category": "color", "implemented": true }
  ],
  "alias": [
    { "name": "color-primary-default", "primitiveRef": "color-blue-500", "light": "#3B82F6", "dark": "#60A5FA", "implemented": true }
  ],
  "component": [
    { "name": "button-bg-primary", "aliasRef": "color-primary-default", "component": "Button", "implemented": true }
  ]
}
```

### 2.11 `3_Code_DV.json`

```json
{
  "document": "3_Code_DV",
  "meta": { "owner": "ua-dv-fe", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "files": [
    {
      "path": "apps/web/app/login/page.tsx",
      "type": "page",
      "screenId": "S-0010",
      "frMapping": ["FR-0010"],
      "status": "implemented"
    }
  ],
  "summary": {
    "totalFr": 0,
    "implementedFr": 0,
    "progress": 0
  }
}
```

### 2.12 `4_Case_QA.json`

```json
{
  "document": "4_Case_QA",
  "meta": { "owner": "ua-qa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "testCases": [
    {
      "id": "TC-0010",
      "title": "...",
      "type": "unit",
      "priority": "Must",
      "frMapping": "FR-0010",
      "preconditions": "...",
      "steps": [
        { "step": 1, "actor": "User", "action": "...", "expected": "..." }
      ],
      "status": "Pending"
    }
  ],
  "summary": {
    "total": 0,
    "pass": 0,
    "fail": 0,
    "pending": 0
  }
}
```

### 2.13 `4_Report_QA.json`

```json
{
  "document": "4_Report_QA",
  "meta": { "owner": "ua-qa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "defects": [
    {
      "id": "DEF-0010",
      "title": "...",
      "severity": "Major",
      "status": "Open",
      "tcMapping": "TC-0010",
      "frMapping": "FR-0010",
      "steps": "...",
      "rootCause": "...",
      "fixSuggestion": "..."
    }
  ],
  "summary": {
    "total": 0,
    "critical": 0,
    "major": 0,
    "minor": 0,
    "trivial": 0,
    "open": 0,
    "closed": 0
  }
}
```

---

## 3. 생성/갱신 절차

에이전트는 마크다운 문서 Write/Edit 완료 직후 아래 절차를 따른다:

```
1. 마크다운 문서의 YAML 헤더에서 메타 정보 추출 (document, owner, status, version, last_updated)
2. 문서 내 목록 데이터 파싱 (테이블 행, ID 패턴 등)
3. 위 스키마에 따라 JSON 객체 구성
4. 마크다운과 동일한 경로에 .json 파일 Write
5. Summary Box에 JSON 파일 경로 포함
```

---

## 4. 규칙

- **필수**: 마크다운 문서 생성/갱신 시 JSON 파일도 반드시 함께 생성/갱신한다
- **동기화**: JSON의 `meta.version`과 `meta.lastUpdated`는 마크다운 헤더와 항상 동일해야 한다
- **부분 갱신**: 증분 갱신(Edit)의 경우 JSON 파일 전체를 재작성한다 (JSON은 병합이 아닌 전체 교체)
- **누락 값**: 마크다운에서 파싱 불가한 값은 `null`로 설정한다
- **배열 순서**: 마크다운 문서 내 순서를 유지한다 (ID 오름차순)
- **인코딩**: UTF-8, 들여쓰기 2 스페이스
- **Summary Box**: JSON 파일 생성/갱신 결과를 Post-Execution Summary Box에 표시한다

---

## 5. `_links.json` — 문서 간 매핑 파일

### 5.1 개요

`u-docs/_links.json`은 문서 간 추적성 매핑을 단일 관리하는 파일이다.
각 문서는 타 문서의 상세 내용을 복사하지 않고 ID만 참조(Reference-Only)하며,
문서 간 연결 관계는 이 파일이 유일한 진실 공급원이다.

### 5.2 스키마

```json
{
  "version": "v0.1.0",
  "lastUpdated": "YYYY-MM-DD",
  "mappings": [
    {
      "fr": "FR-0010",
      "us": ["US-0010"],
      "mn": "MN-AUTH-0010",
      "screen": "S-0010",
      "api": "POST /auth/login",
      "erd": ["USER"],
      "qa": "TC-0010"
    }
  ]
}
```

### 5.3 필드 정의

| 필드 | 타입 | Required | 설명 | 원본 문서 |
|------|------|----------|------|-----------|
| `fr` | `string` | Yes | 기능 요구사항 ID (매핑의 기준 키) | `1_SRS_RA.md` |
| `us` | `string[]` | Yes | 유저 스토리 ID 목록. Technical FR은 `["-"]` | `1_SRS_RA.md` |
| `mn` | `string \| null` | No | 메뉴 네비게이션 ID | `1_IA_RA.md` |
| `screen` | `string \| null` | No | 화면 ID | `2_Screen_UX.md` |
| `api` | `string \| null` | No | API Endpoint (`METHOD /path`) | `2_API_SA.md` |
| `erd` | `string[] \| null` | No | 관련 Entity 이름 목록 | `2_ERD_SA.md` |
| `qa` | `string \| null` | No | 테스트 케이스 ID | `4_Case_QA.md` |

### 5.4 규칙

1. FR 추가 시 `_links.json`에 매핑 행을 반드시 함께 추가한다
2. 미정 필드는 `null`로 기입한다 (나중에 해당 문서 작성 시 갱신)
3. FR 삭제 시 해당 매핑 행을 제거한다
4. `version`은 매핑 변경 시 MINOR bump, 구조 변경 시 MAJOR bump
5. `/uc-validate` 검증 시 이 파일 기준으로 누락을 탐지한다:
   - `"screen": "S-0050"` 인데 `2_Screen_UX.md`에 S-0050이 없음 → Fail
   - `"api": null` 인 FR이 DESIGN Phase Gate 시점에 존재 → Warning
6. `mappings` 배열은 `fr` ID 오름차순으로 정렬한다
