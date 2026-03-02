---
name: u-test
description: |
  테스트 케이스를 설계한다. SRS FR 기반으로 정상/비정상/경계값 케이스를 작성하며,
  각 FR에 대해 Unit Test 케이스와 E2E Test 케이스를 모두 포함해야 한다.
  테스트 스텝은 Actor/Screen/Element/Action/Input/Expected를 상세하게 작성한다.
  u-qa 에이전트가 담당한다.
  Optional [app] argument for multi-app projects (e.g., `/u-test web`).
  Triggers: /u-test, 테스트 케이스, test case, QA
user-invocable: true
argument-hint: "[web]"
---

Invoke the `u-ssot` skill with argument `/u-test` and pass any user-provided arguments.
