---
document: git-strategy
title: "{{PROJECT_NAME}} Git 브랜치 전략"
owner: "u-agent-builder"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
---

# {{PROJECT_NAME}} Git 브랜치 전략

## 1. 브랜치 모델
- main: 프로덕션
- develop: 개발 통합
- feature/{FT-ID}-{description}: 기능 개발
- fix/{BL-ID}-{description}: 버그 수정
- release/{version}: 릴리스 준비

## 2. 커밋 규칙
- 형식: `{type}({scope}): {subject}`
- type: feat, fix, docs, style, refactor, test, chore

## 3. PR 규칙
## 4. 머지 전략
## 5. Change Log
| Version | Date | Author | Description |
|---------|------|--------|-------------|
