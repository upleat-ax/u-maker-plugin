---
document: "2_API_SA"
title: "{{PROJECT_NAME}} API Contract"
owner: "u-SA"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
app: "{{APP_NAME}}"
related_docs:
  - "u-docs/{{APP_NAME}}/01-plan/1_SRS_RA.md"
  - "u-docs/shared/02-design/2_ERD_SA.md"
  - "u-docs/{{APP_NAME}}/02-design/2_Screen_UX.md"
  - "u-docs/{{APP_NAME}}/03-dev/3_Code_DV.md"
  - "u-docs/{{APP_NAME}}/04-check/4_Case_QA.md"
  - "u-docs/shared/01-plan/1_Index_PM.md"
external_links: []
---

# {{PROJECT_NAME}} API Contract

## 1. Background

### 1.1 Purpose

{{API Contract 문서의 목적. Frontend/Backend 간 인터페이스를 정의한다.}}

### 1.2 Data Specification

| Item | Value |
|------|-------|
| Base URL | `{{BASE_URL}}` |
| Protocol | REST (JSON) |
| Auth | Bearer Token (JWT) |
| Spec | OpenAPI 3.0 |

---

## 2. API Overview

| Method | Path | Description | FR Mapping | Screen Mapping | Menu Mapping | Auth |
|--------|------|-------------|------------|---------------|-------------|------|
| POST | `/auth/login` | 로그인 | FR-001 | S-006 | MN-AUTH-001 | No |
| POST | `/auth/register` | 회원가입 | FR-001 | S-007 | MN-AUTH-002 | No |
| GET | `/{{resource}}` | {{설명}} | FR-002 | S-003 | MN-XXX-NNN | Yes |
| POST | `/{{resource}}` | {{설명}} | FR-003 | S-004 | MN-XXX-NNN | Yes |
| PUT | `/{{resource}}/:id` | {{설명}} | FR-003 | S-004 | MN-XXX-NNN | Yes |
| DELETE | `/{{resource}}/:id` | {{설명}} | FR-003 | S-004 | MN-XXX-NNN | Yes |

---

## 3. API Details

### 3.1 POST /auth/login

**Description**: 사용자 로그인

**Request**:
```json
{
  "email": "string (required)",
  "password": "string (required)"
}
```

**Response (200)**:
```json
{
  "token": "string (JWT)",
  "user": {
    "id": "number",
    "email": "string",
    "name": "string",
    "role": "string"
  }
}
```

**Error Responses**:

| Status | Code | Message |
|--------|------|---------|
| 400 | VALIDATION_ERROR | 입력값 검증 실패 |
| 401 | INVALID_CREDENTIALS | 이메일 또는 비밀번호 불일치 |
| 429 | TOO_MANY_REQUESTS | 요청 횟수 초과 |

### 3.2 GET /{{resource}}

**Description**: {{설명}}

**Query Parameters**:

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| page | number | No | 1 | 페이지 번호 |
| limit | number | No | 20 | 페이지당 항목 수 |
| sort | string | No | created_at | 정렬 기준 |

**Response (200)**:
```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 0,
    "totalPages": 0
  }
}
```

### 3.3 POST /{{resource}}

**Description**: {{설명}}

**Request**:
```json
{
  "{{field}}": "{{type}} (required)"
}
```

**Response (201)**:
```json
{
  "id": "number",
  "{{field}}": "{{value}}"
}
```

---

## 3.5 System Context

```mermaid
C4Context
    title System Context — {{PROJECT_NAME}}
    Person(user, "User", "서비스 사용자")
    System(app, "{{PROJECT_NAME}}", "메인 애플리케이션")
    System_Ext(auth, "OAuth Provider", "Google / GitHub 인증")
    System_Ext(email, "Email Service", "알림 이메일 발송")
    System_Ext(storage, "Cloud Storage", "파일 업로드/다운로드")

    Rel(user, app, "사용", "HTTPS")
    Rel(app, auth, "OAuth 인증", "HTTPS")
    Rel(app, email, "이메일 발송", "SMTP/API")
    Rel(app, storage, "파일 저장", "S3 API")
```

---

## 4. Sequence Diagrams

### 4.1 Login Flow

```mermaid
sequenceDiagram
    actor User
    participant Client
    participant API
    participant DB

    User->>Client: Enter credentials
    Client->>API: POST /auth/login
    API->>DB: SELECT user WHERE email
    DB-->>API: User record

    alt Valid password
        API-->>Client: 200 {token, user}
        Client-->>User: Redirect to Dashboard
    else Invalid password
        API-->>Client: 401 INVALID_CREDENTIALS
        Client-->>User: Show error message
    end
```

### 4.2 {{Resource}} CRUD Flow

```mermaid
sequenceDiagram
    actor User
    participant Client
    participant API
    participant DB

    User->>Client: {{Action}}
    Client->>API: {{METHOD}} /{{resource}}
    API->>DB: {{DB Operation}}
    DB-->>API: Result
    API-->>Client: {{Response}}
    Client-->>User: {{UI Update}}
```

### 4.3 Token Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Valid : Login success
    Valid --> Expiring : TTL < 5min
    Expiring --> Valid : Token refresh
    Expiring --> Expired : No refresh
    Valid --> Revoked : Logout
    Expired --> [*]
    Revoked --> [*]
```

### 4.4 Complex Auth Flow (zenuml)

> 3단계 이상 중첩 조건이 있는 복잡한 인증·트랜잭션 플로우에 사용한다.

```zenuml
@Actor User
@Boundary Client
@Control API
@Database DB

// Login with token refresh
User -> Client.submitLogin(email, password) {
  Client -> API.POST_auth_login(credentials) {
    API -> DB.findUserByEmail(email) {
      return userRecord
    }
    if (passwordValid) {
      API -> DB.createSession(userId) {
        return sessionId
      }
      return {token, refreshToken, user}
    } else {
      throw INVALID_CREDENTIALS
    }
  }
}

// Token refresh flow
User -> Client.makeAuthenticatedRequest() {
  if (tokenExpiring) {
    Client -> API.POST_auth_refresh(refreshToken) {
      if (refreshTokenValid) {
        return {newToken}
      } else {
        throw REFRESH_TOKEN_EXPIRED
      }
    }
  }
  Client -> API.resource(newToken) {
    return data
  }
}
```

---

## 5. OpenAPI 3.0 Spec (YAML)

```yaml
openapi: "3.0.3"
info:
  title: "{{PROJECT_NAME}} API"
  version: "1.0.0"
  description: "{{API 설명}}"
servers:
  - url: "{{BASE_URL}}"
paths:
  /auth/login:
    post:
      summary: "로그인"
      tags: ["Auth"]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [email, password]
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
      responses:
        "200":
          description: "로그인 성공"
        "401":
          description: "인증 실패"
```

---

## 6. Exception Handling

| # | Endpoint | Exception | Status | Response |
|---|----------|-----------|--------|----------|
| E-001 | POST /auth/login | 잘못된 인증 정보 | 401 | `{error: "INVALID_CREDENTIALS"}` |
| E-002 | ALL | 인증 토큰 만료 | 401 | `{error: "TOKEN_EXPIRED"}` |
| E-003 | ALL | 서버 내부 오류 | 500 | `{error: "INTERNAL_SERVER_ERROR"}` |
| E-004 | {{endpoint}} | {{예외}} | {{status}} | {{response}} |

---

## 7. Common Response Format

```json
// Success
{
  "data": {},
  "message": "Success"
}

// Error
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message"
  }
}

// Paginated
{
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-SA | Initial draft |
