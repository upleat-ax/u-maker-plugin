---
name: us-check
description: |
  CHECK Phase 실행. 테스트 케이스 설계 → 실행 → 결함 분석 순서로 진행한다.
  테스트 케이스는 Unit Test와 E2E Test를 모두 포함해야 하며,
  각 테스트는 재현 가능한 상세 스텝으로 문서화한다.
  Optional [app] argument for multi-app projects (e.g., `/uc-check web`).
  Triggers: /uc-check, check phase, 검증, 테스트
user-invocable: true
argument-hint: "[web]"
---

Invoke the `u-maker` skill with argument `/uc-check` and pass any user-provided arguments.
