---
document: system-overview
title: "{{PROJECT_NAME}} 시스템 구성도"
owner: "u-agent-planner"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
---

# {{PROJECT_NAME}} 시스템 구성도

## 1. 전체 아키텍처

```mermaid
C4Context
  title {{PROJECT_NAME}} System Context
  Person(user, "사용자", "서비스 이용자")
  System(app, "{{PROJECT_NAME}}", "메인 시스템")
  System_Ext(ext, "외부 시스템", "연동 시스템")
  Rel(user, app, "Uses")
  Rel(app, ext, "API Call")
```

## 2. 앱 구성
| 앱 | 유형 | 설명 | 기술 스택 |
|----|------|------|-----------|

## 3. 인프라 구성
## 4. 통신 구조
## 5. 배포 환경
| 환경 | URL | 용도 |
|------|-----|------|
| Development | | 개발 |
| Staging | | QA |
| Production | | 운영 |

## 6. Change Log
| Version | Date | Author | Description |
|---------|------|--------|-------------|
