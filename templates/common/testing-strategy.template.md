---
document: testing-strategy
title: "{{PROJECT_NAME}} 테스트 전략"
owner: "u-agent-guardian"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
---

# {{PROJECT_NAME}} 테스트 전략

## 1. 테스트 레벨
| 레벨 | 도구 | 대상 | 커버리지 목표 |
|------|------|------|-------------|
| Unit | Vitest | 함수, 훅 | 80%+ |
| Integration | Vitest | API Route | 70%+ |
| E2E | Playwright | 사용자 시나리오 | 핵심 플로우 100% |
| Visual | Storybook | UI 컴포넌트 | 모든 컴포넌트 |

## 2. 테스트 데이터 관리
## 3. CI/CD 연동
## 4. 결함 분류 기준
| 등급 | 정의 | 대응 |
|------|------|------|
| Critical | 서비스 불가 | 즉시 수정 |
| Major | 핵심 기능 장애 | 24h 내 수정 |
| Minor | 사소한 문제 | 다음 iteration |
| Info | 개선 제안 | 백로그 |

## 5. Change Log
| Version | Date | Author | Description |
|---------|------|--------|-------------|
