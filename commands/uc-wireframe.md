---
description: |
  화면 와이어프레임을 HTML로 생성하거나 갱신한다. ua-ux 에이전트가 담당한다.
  생성된 HTML 파일은 `u-docs/{app}/02-design/2_Screen_Wireframes/`에 저장된다. 모든 텍스트는 `u-maker.config.json`의 `documentLanguage` 설정을 따른다. `u_design` 또는 `u-design` 폴더는 사용하지 않는다.
  각 화면 요소에는 floating 어노테이션 패널이 포함된다 — 관련 요구사항(FR), 플로우(SC/User Flow), 조건(Business Rule), 요소 설명을 표시한다.
  Optional [app] argument for multi-app projects (e.g., `/uc-wireframe web`).
  Triggers: /uc-wireframe, HTML 와이어프레임, wireframe generate
---

Invoke the `u-maker` skill with argument `/uc-wireframe` and pass any user-provided arguments.
