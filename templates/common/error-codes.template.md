---
document: error-codes
title: "{{PROJECT_NAME}} 공통 에러코드 체계"
owner: "u-agent-planner"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
---

# {{PROJECT_NAME}} 공통 에러코드 체계

## 1. 에러코드 구조
- 형식: `{DOMAIN}-{CATEGORY}-{NUMBER}`
- 예시: `AUTH-TOKEN-001`

## 2. HTTP 상태코드 매핑
| HTTP Status | 용도 | 예시 |
|-------------|------|------|
| 400 | 입력 검증 실패 | |
| 401 | 인증 실패 | |
| 403 | 권한 없음 | |
| 404 | 리소스 없음 | |
| 409 | 상태 충돌 | |
| 500 | 서버 오류 | |

## 3. 도메인별 에러코드
### AUTH
### CORE
### ADMIN

## 4. 에러 응답 표준 포맷
```json
{
  "error": {
    "code": "AUTH-TOKEN-001",
    "message": "토큰이 만료되었습니다",
    "details": {}
  }
}
```

## 5. Change Log
| Version | Date | Author | Description |
|---------|------|--------|-------------|
