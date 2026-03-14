# JSON Export Standard

> u-maker 플러그인의 모든 SSoT 문서에 적용되는 JSON 내보내기 규칙.
> 에이전트는 마크다운 문서를 생성하거나 갱신할 때마다 **같은 경로에 동명의 .json 파일도 반드시 함께 생성/갱신**해야 한다.

---

## 1. 적용 규칙

| 조건 | 규칙 |
|------|------|
| **적용 시점** | 마크다운 문서를 Write 또는 Edit할 때마다 |
| **파일 경로** | 마크다운 파일과 **동일한 경로**, 확장자만 `.json`으로 변경 |
| **대상 내용** | 문서 내의 **ID가 부여된 모든 데이터** — ID 패턴(XX-NNNN, MN-*, Entity명 등)이 있는 테이블/목록 항목 전부 |
| **항상 포함** | `document`, `meta`, 목록 배열 |
| **스키마 버전** | 마크다운 문서 `version`과 동기화 |

### 경로 예시

```
.u-maker/docs/common/01-plan/1_Roadmap_PM.md  →  .u-maker/docs/common/01-plan/1_Roadmap_PM.json
.u-maker/docs/web/01-plan/1_SRS_RA.md        →  .u-maker/docs/web/01-plan/1_SRS_RA.json
```

### 공통 메타 구조

모든 JSON 파일은 아래 공통 구조를 포함한다:

```json
{
  "document": "1_SRS_RA",
  "meta": {
    "owner": "u-agent-sa",
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
  "meta": { "owner": "u-agent-ra", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
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
  "meta": { "owner": "u-agent-sa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "users": [
    {
      "id": "USR-0010",
      "role": "사용자",
      "description": "...",
      "priority": "Must"
    }
  ],
  "functionalRequirements": [
    {
      "id": "FR-0010",
      "requirement": "...",
      "description": "...",
      "priority": "Must",
      "usr": [{ "id": "USR-0010" }],
      "status": "Not Started"
    }
  ],
  "userStories": [
    {
      "id": "US-0010",
      "usr": { "id": "USR-0010" },
      "role": "사용자",
      "need": "...",
      "benefit": "...",
      "priority": "Must",
      "fr": [{ "id": "FR-0010" }],
      "ft": [{ "id": "FT-0010" }]
    }
  ],
  "features": [
    {
      "id": "FT-0010",
      "feature": "...",
      "description": "...",
      "priority": "Must",
      "us": [{ "id": "US-0010" }],
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

`1_SRS_RA.json` 필드 완전성 규칙:
- `users[]`: `id`, `role`, `description`, `priority`를 모두 포함한다.
- `functionalRequirements[]`: `id`, `requirement`, `description`, `priority`, `usr`, `status`를 모두 포함한다.
- `userStories[]`: `id`, `usr`, `role`, `need`, `benefit`, `priority`, `fr`, `ft`를 모두 포함한다.
- `features[]`: `id`, `feature`, `description`, `priority`, `us`, `status`를 모두 포함한다.
- `nonFunctionalRequirements[]`: `id`, `category`, `requirement`, `metric`를 모두 포함한다.
- `id`만 남기는 축약 출력은 금지한다. 값 미확정 시 키를 생략하지 말고 `null`로 기록한다.

### 2.3 `1_Common_RA.json`

```json
{
  "document": "1_Common_RA",
  "meta": { "owner": "u-agent-ra", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
  "authPolicy": {
    "methods": [
      { "method": "JWT", "description": "...", "useCase": "..." }
    ],
    "tokenManagement": {
      "tokenType": "JWT",
      "accessTokenTTL": "15min",
      "refreshTokenTTL": "7d",
      "storage": "httpOnly cookie"
    }
  },
  "rbacPolicy": {
    "roles": [
      { "role": "Admin", "description": "...", "accessLevel": "Full" }
    ],
    "permissions": [
      { "resource": "...", "public": "N", "user": "R", "admin": "W" }
    ]
  },
  "securityPolicy": {
    "inputValidation": [
      { "rule": "XSS Prevention", "description": "..." }
    ],
    "dataProtection": [
      { "item": "Password Hashing", "policy": "bcrypt" }
    ],
    "apiSecurity": [
      { "item": "Rate Limiting", "policy": "100 req/min per IP" }
    ]
  },
  "businessRules": [
    { "id": "BR-0010", "rule": "...", "description": "...", "scope": "..." }
  ],
  "errorHandling": {
    "format": "{ error: { code, message, details } }",
    "codes": [
      { "code": "ERR_AUTH_001", "httpStatus": 401, "description": "...", "action": "..." }
    ]
  },
  "glossary": [
    { "term": "...", "definition": "..." }
  ]
}
```

### 2.3a `1_Glossary_RA.json`

```json
{
  "document": "1_Glossary_RA",
  "meta": { "owner": "u-agent-ra", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "domainTerms": [
    {
      "id": "GL-0010",
      "termEN": "...",
      "termKO": "...",
      "definition": "...",
      "context": "...",
      "relatedDocs": [{ "id": "FR-XXXX" }]
    }
  ],
  "abbreviations": [
    {
      "abbreviation": "...",
      "fullName": "...",
      "definition": "...",
      "usageContext": "..."
    }
  ],
  "technicalTerms": [
    {
      "id": "GT-0010",
      "term": "...",
      "definition": "...",
      "category": "Frontend | Backend | Infra | DB",
      "relatedDocs": [{ "id": "FT-XXXX" }]
    }
  ]
}
```

### 2.3b `1_Workflow_RA.json`

```json
{
  "document": "1_Workflow_RA",
  "meta": { "owner": "u-agent-ra", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "workflows": [
    {
      "id": "WF-0010",
      "name": "...",
      "category": "Core | Support | Admin",
      "trigger": "...",
      "actors": [{ "id": "USR-XXXX" }],
      "precondition": "...",
      "postcondition": "...",
      "relatedFR": [{ "id": "FR-XXXX" }],
      "relatedFT": [{ "id": "FT-XXXX" }],
      "steps": [
        {
          "step": 1,
          "actor": "...",
          "action": "...",
          "systemResponse": "...",
          "branchCondition": null,
          "nextStep": 2
        }
      ],
      "exceptionFlows": [
        {
          "id": "EX-01",
          "triggerCondition": "...",
          "handling": "...",
          "recovery": "..."
        }
      ],
      "status": "Draft"
    }
  ]
}
```

### 2.4 `1_IA_RA.json`

```json
{
  "document": "1_IA_RA",
  "meta": { "owner": "u-agent-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "menuTree": [
    {
      "id": "MN-AUTH-0010",
      "name": "Login",
      "path": "/login",
      "depth": 2,
      "parent": { "id": "MN-AUTH" },
      "screen": { "id": "S-0010" },
      "ft": { "id": "FT-0010" }
    }
  ],
  "screens": [
    {
      "id": "S-0010",
      "name": "로그인",
      "menu": { "id": "MN-AUTH-0010" },
      "path": "/login",
      "accessRole": "Public"
    }
  ]
}
```

### 2.5 `1_Index_PM.json`

```json
{
  "document": "1_Index_PM",
  "meta": { "owner": "u-agent-ra", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
  "documents": [
    {
      "id": "1_Roadmap_PM",
      "title": "로드맵",
      "owner": "u-agent-ra",
      "status": "Final",
      "version": "v1.0.0",
      "path": ".u-maker/docs/common/01-plan/1_Roadmap_PM.md",
      "phase": "PLAN"
    }
  ]
}
```

### 2.6 `2_ERD_SA.json`

```json
{
  "document": "2_ERD_SA",
  "meta": { "owner": "u-agent-sa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
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

### 2.7 `2_API_SA.json`

```json
{
  "document": "2_API_SA",
  "meta": { "owner": "u-agent-sa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "endpoints": [
    {
      "id": "API-0010",
      "method": "POST",
      "path": "/api/auth/login",
      "description": "...",
      "ft": { "id": "FT-0010" },
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

### 2.8 `2_Screen_UX.json`

```json
{
  "document": "2_Screen_UX",
  "meta": { "owner": "u-agent-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "screens": [
    {
      "id": "S-0010",
      "name": "로그인",
      "goal": "...",
      "accessRole": "Public",
      "menu": { "id": "MN-AUTH-0010" },
      "ft": [{ "id": "FT-0010" }],
      "wireframe": "2_Screen_Wireframes/S-0010.html",
      "connectedScreens": [
        { "screen": { "id": "S-0020" }, "condition": "로그인 성공" }
      ],
      "elements": [
        { "name": "LoginForm", "type": "Form", "roleVisibility": "All" }
      ]
    }
  ]
}
```

### 2.9 `2_ScreenFlow_UX.json`

```json
{
  "document": "2_ScreenFlow_UX",
  "meta": { "owner": "u-agent-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "flows": [
    {
      "from": { "id": "S-0010" },
      "to": { "id": "S-0020" },
      "trigger": "로그인 성공",
      "condition": "인증 성공",
      "notes": "토큰 저장 후 이동"
    }
  ],
  "deepLinks": [
    {
      "path": "/login",
      "screen": { "id": "S-0010" },
      "params": "?redirect=",
      "authRequired": false
    }
  ],
  "errorFlows": [
    {
      "scenario": "세션 만료",
      "currentScreen": "모든 화면",
      "behavior": "자동 로그아웃",
      "target": { "id": "S-0010" }
    }
  ]
}
```

### 2.10 `2_UXGuide_UX.json`

```json
{
  "document": "2_UXGuide_UX",
  "meta": { "owner": "u-agent-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
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

### 2.10a `2_RTM_RA.json`

```json
{
  "document": "2_RTM_RA",
  "meta": { "owner": "u-agent-ra", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
  "coverageSummary": [
    {
      "app": "web",
      "frTotal": 0,
      "frLinked": 0,
      "usTotal": 0,
      "usLinked": 0,
      "ftTotal": 0,
      "ftLinked": 0,
      "coverage": "0%"
    }
  ],
  "matrix": [
    {
      "fr": { "id": "FR-0010" },
      "us": { "id": "US-0010" },
      "ft": { "id": "FT-0010" },
      "app": "web",
      "mn": { "id": "MN-AUTH-0010" },
      "screen": { "id": "S-0060" },
      "api": "POST /auth/login",
      "erd": ["USER"],
      "qa": { "id": "TC-0010" },
      "status": "Covered",
      "note": null
    }
  ],
  "gaps": [
    {
      "id": "GAP-0010",
      "scope": "FT-0130",
      "missingLink": "QA Case",
      "impact": "...",
      "action": "...",
      "owner": "u-agent-qa",
      "dueDate": "YYYY-MM-DD",
      "status": "Open"
    }
  ]
}
```

### 2.11 `3_UIComponents_UX.json`

```json
{
  "document": "3_UIComponents_UX",
  "meta": { "owner": "u-agent-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
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

### 2.12 `3_DesignToken_UX.json`

```json
{
  "document": "3_DesignToken_UX",
  "meta": { "owner": "u-agent-ux", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD" },
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

### 2.13 `3_Code_DV.json`

```json
{
  "document": "3_Code_DV",
  "meta": { "owner": "u-agent-dv-fe", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "files": [
    {
      "path": "apps/web/app/login/page.tsx",
      "type": "page",
      "screen": { "id": "S-0010" },
      "ft": [{ "id": "FT-0010" }],
      "status": "implemented"
    }
  ],
  "summary": {
    "totalFt": 0,
    "implementedFt": 0,
    "progress": 0
  }
}
```

### 2.14 `4_Case_QA.json`

```json
{
  "document": "4_Case_QA",
  "meta": { "owner": "u-agent-qa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "background": {
    "purpose": "SRS FT 기반 테스트 케이스 설계",
    "testStrategy": {
      "testTypes": ["Unit", "E2E"],
      "coverageTarget": "80%+",
      "tools": "Vitest (Unit), Playwright (E2E)",
      "environment": "Local + CI"
    }
  },
  "testConditions": {
    "prerequisites": [
      { "id": "PRE-0010", "condition": "빌드 성공", "description": "bun run build 성공 상태" }
    ],
    "testData": [
      { "dataSet": "Users", "description": "테스트 사용자 계정", "records": "admin@test.com, user@test.com" }
    ]
  },
  "testCases": [
    {
      "id": "TC-0010",
      "ft": { "id": "FT-0010" },
      "us": { "id": "US-0010" },
      "level": "Unit",
      "type": "Positive",
      "priority": "Critical",
      "actor": "일반 사용자",
      "precondition": "PRE-0010, PRE-0020",
      "automationTarget": "Vitest",
      "steps": [
        {
          "step": 1,
          "screen": "로그인 화면 (S-0010)",
          "element": "이메일 입력 필드",
          "action": "클릭 후 입력",
          "input": "user@test.com",
          "expected": "커서가 이메일 필드로 이동"
        }
      ],
      "result": "Pending",
      "note": null
    }
  ],
  "coverageMatrix": [
    {
      "ft": { "id": "FT-0010" },
      "feature": "로그인",
      "unitCases": [{ "id": "TC-0010" }, { "id": "TC-0020" }],
      "e2eCases": [{ "id": "TC-0030" }, { "id": "TC-0040" }],
      "coverage": "Covered"
    }
  ],
  "summary": {
    "total": 0,
    "pass": 0,
    "fail": 0,
    "skip": 0,
    "pending": 0
  }
}
```

`4_Case_QA.json` 필드 완전성 규칙:
- `background`: `purpose`, `testStrategy`(testTypes, coverageTarget, tools, environment)를 모두 포함한다.
- `testConditions.prerequisites[]`: `id`, `condition`, `description`을 모두 포함한다.
- `testConditions.testData[]`: `dataSet`, `description`, `records`를 모두 포함한다.
- `testCases[]`: `id`, `ft`, `us`, `level`, `type`, `priority`, `actor`, `precondition`, `automationTarget`, `steps`, `result`, `note`를 모두 포함한다.
- `testCases[].steps[]`: `step`, `screen`, `element`, `action`, `input`, `expected`를 모두 포함한다. 이는 "누가-어디서-무엇을-어떻게-무엇을입력-기대결과" 6W 구조를 반영한다.
- `coverageMatrix[]`: `ft`, `feature`, `unitCases`, `e2eCases`, `coverage`를 모두 포함한다.
- `summary`: `total`, `pass`, `fail`, `skip`, `pending`을 모두 포함한다.

### 2.15 `4_Report_QA.json`

```json
{
  "document": "4_Report_QA",
  "meta": { "owner": "u-agent-qa", "status": "Draft", "version": "v0.1.0", "lastUpdated": "YYYY-MM-DD", "app": "web" },
  "defects": [
    {
      "id": "DEF-0010",
      "title": "...",
      "severity": "Major",
      "status": "Open",
      "tc": { "id": "TC-0010" },
      "ft": { "id": "FT-0010" },
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
- **ID 필드명 규칙**: 식별자 필드는 항상 `id`를 사용한다
- **참조 필드 규칙**: 다른 문서/엔터티 ID를 참조할 때는 문자열 직접 삽입 대신 객체를 사용한다. 예: `"ft": { "id": "FT-0010" }`, `"fr": { "id": "FR-0010" }`, `"fr": [{ "id": "FR-0010" }]`
- **필드 완전성 규칙**: 테이블/목록의 각 행은 스키마에 정의된 필드를 모두 포함해야 하며, `id`만 남기는 축약 출력은 허용하지 않는다.
- **인코딩**: UTF-8, 들여쓰기 2 스페이스
- **Summary Box**: JSON 파일 생성/갱신 결과를 Post-Execution Summary Box에 표시한다

---

## 5. `_links.json` — 문서 간 매핑 파일

### 5.1 개요

`.u-maker/docs/_links.json`은 문서 간 추적성 매핑을 단일 관리하는 파일이다.
각 문서는 타 문서의 상세 내용을 복사하지 않고 ID만 참조(Reference-Only)하며,
문서 간 연결 관계는 이 파일이 유일한 진실 공급원이다.

### 5.2 스키마

```json
{
  "version": "v0.1.0",
  "lastUpdated": "YYYY-MM-DD",
  "mappings": [
    {
      "ft": { "id": "FT-0010" },
      "fr": { "id": "FR-0010" },
      "us": [{ "id": "US-0010" }],
      "usr": { "id": "USR-0010" },
      "mn": { "id": "MN-AUTH-0010" },
      "screen": { "id": "S-0010" },
      "api": "POST /auth/login",
      "erd": ["USER"],
      "qa": { "id": "TC-0010" }
    }
  ]
}
```

### 5.3 필드 정의

| 필드 | 타입 | Required | 설명 | 원본 문서 |
|------|------|----------|------|-----------|
| `ft` | `{ id: string }` | Yes | Feature ID (매핑의 기준 키) | `1_SRS_RA.md` |
| `fr` | `{ id: string }` | Yes | 기능 요구사항 ID | `1_SRS_RA.md` |
| `us` | `{ id: string }[]` | Yes | 유저 스토리 ID 목록. Technical FT는 `[{"id":"-"}]` | `1_SRS_RA.md` |
| `usr` | `{ id: string } \| null` | No | 사용자 유형 ID | `1_SRS_RA.md` |
| `mn` | `{ id: string } \| null` | No | 메뉴 네비게이션 ID | `1_IA_RA.md` |
| `screen` | `{ id: string } \| null` | No | 화면 ID | `2_Screen_UX.md` |
| `api` | `string \| null` | No | API Endpoint (`METHOD /path`) | `2_API_SA.md` |
| `erd` | `string[] \| null` | No | 관련 Entity 이름 목록 | `2_ERD_SA.md` |
| `qa` | `{ id: string } \| null` | No | 테스트 케이스 ID | `4_Case_QA.md` |

### 5.4 규칙

1. FT 추가 시 `_links.json`에 매핑 행을 반드시 함께 추가한다
2. 미정 필드는 `null`로 기입한다 (나중에 해당 문서 작성 시 갱신)
3. FT 삭제 시 해당 매핑 행을 제거한다
4. `version`은 매핑 변경 시 MINOR bump, 구조 변경 시 MAJOR bump
5. `/u-agent-validate` 검증 시 이 파일 기준으로 누락을 탐지한다:
   - `"screen": { "id": "S-0050" }` 인데 `2_Screen_UX.md`에 S-0050이 없음 → Fail
   - `"api": null` 인 FT가 DESIGN Phase Gate 시점에 존재 → Warning
6. `mappings` 배열은 `ft.id` 오름차순으로 정렬한다
