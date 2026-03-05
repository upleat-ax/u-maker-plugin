---
name: us-init
description: |
  기존 프로젝트를 분석하여 SSoT 문서를 자동 생성한다.
  프로젝트 폴더 내 리소스(package.json, 소스코드, DB 스키마, README 등)를 읽고
  분석하여 가능한 모든 SSoT 문서를 사전 작성(pre-fill)한다.
  Triggers: /uc-init, 프로젝트 초기화, 기존 프로젝트 분석, init project, reverse engineer, 리버스 엔지니어링
user-invocable: true
argument-hint: "[args]"
---

Invoke the `u-maker` skill with argument `/uc-init` and pass any user-provided project path or arguments.

## Language Option

`/uc-init` 실행 시 `--lang` 옵션으로 문서 언어를 설정할 수 있다.

```
/uc-init [project-path] [--lang ko|en|ja|zh]
```

- `--lang`: 문서 작성 언어 (기본값: `ko`)
  - `ko`: 한국어
  - `en`: English
  - `ja`: 日本語
  - `zh`: 中文
- 설정값은 `u-maker.config.json`의 `documentLanguage`에 저장된다.
- 이후 모든 SSoT 문서 생성 시 해당 언어로 작성된다.
