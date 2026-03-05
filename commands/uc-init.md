---
description: |
  기존 프로젝트를 분석하여 SSoT 문서를 자동 생성한다.
  프로젝트 폴더 내 리소스(package.json, 소스코드, DB 스키마, README 등)를 읽고
  분석하여 가능한 모든 SSoT 문서를 사전 작성(pre-fill)한다.
  Triggers: /uc-init, 프로젝트 초기화, 기존 프로젝트 분석, init project, reverse engineer, 리버스 엔지니어링
---

Invoke the `u-maker` skill with argument `/uc-init` and pass any user-provided project path or arguments.
