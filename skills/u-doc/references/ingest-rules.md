# ingest-rules — Input Normalization + Placement Suggestion (u-doc Ingest Mode)

`/u-doc` **Ingest 모드**의 규칙. 사용자가 제공한 임의 입력(파일/이미지/링크/텍스트)을 `data/dropzone/`에 **정규화**하고, digest-engine으로 분석한 뒤, 그 내용이 **어느 app/문서/섹션에 속하는지 제안**한다.

> **핵심 원칙 (사용자 정책):** Ingest 모드는 **SSoT 문서(`docs/**/*.md`)를 직접 수정하지 않는다.** digest 생성 + 배치 제안까지만 수행한다. 실제 문서 반영은 `/u-plan`·`/u-design`이 담당한다. (doc-engine이 참조하지만 부재한 `/u-add`의 경량·비파괴 버전)

---

## 1. 입력 종류 판별

| 종류 | 감지 기준 |
|------|----------|
| **file** | 로컬 파일 경로(존재하는 `.md/.txt/.pdf/.docx/.xlsx/.csv` 등) |
| **image** | `.png/.jpg/.jpeg/.svg/.webp` 경로 또는 첨부 이미지 |
| **link** | `http(s)://` URL. `figma.com` → Figma, 그 외 → 일반 web |
| **text** | 위 어디에도 해당 안 되는, 대화 중 붙여넣은 평문/기획 내용 |

여러 입력이 섞여 들어오면 각각 개별 항목으로 처리한다.

---

## 2. dropzone 정규화 (입력 → `data/dropzone/`)

digest-engine은 `data/dropzone/`를 재귀 스캔하므로(경로 자유), 입력을 아래 규칙으로 dropzone에 **복사/기록**한다. `--app {name}` 지정 시 `data/dropzone/{app}/` 하위에 둔다.

| 종류 | 정규화 동작 | 착지 경로(예시) |
|------|-----------|----------------|
| **file** | 원본을 dropzone으로 **복사**(이동 아님 — 원본 보존) | `data/dropzone/{원본파일명}` |
| **image** | dropzone에 복사. 파일명 패턴(`wireframe-`, `flow-`, `screen-`) 유지 | `data/dropzone/designs/{원본파일명}` |
| **link (figma)** | URL을 `.figma-link` 파일로 기록(digest-engine이 인식 → `/u-tools-figma` 위임) | `data/dropzone/{slug}.figma-link` |
| **link (web)** | URL + (가능 시) 제목/요약을 `.url.md`로 기록. 본문 페치가 필요하면 `/u-tools-browser`에 위임 | `data/dropzone/links/{slug}.url.md` |
| **text** | frontmatter(`title`, `capturedAt`, `source: u-doc`) + 본문을 `.md`로 저장 | `data/dropzone/notes/{slug}.md` |

- `slug`: 입력 제목 또는 첫 문장에서 kebab-case 생성(소문자, 공백→`-`, 특수문자 제거).
- 동일 slug 충돌 시 `-2`, `-3` suffix.
- **원본 파일은 절대 이동·삭제하지 않는다**(복사만).

---

## 3. digest 생성 (재사용 — 중복 구현 금지)

정규화로 dropzone에 새 파일이 생긴 뒤, **`/u-analyze`의 Step 1–4 로직(digest-engine)을 그대로 재사용**한다:

1. dropzone 스캔 → SHA-256 해시 → `data/digest/_index.json` 갱신(신규/변경만 `pending`).
2. 타입별 추출 → `data/digest/{mirror-path}/{filename}.digest.json` (`_meta/schemas/digest.schema.json` 준수).
3. Figma 링크 → `/u-tools-figma --app {app}` 자동 위임(`_index.json` status `delegated`).
4. `data/links.json`에 `digest` 노드 등록(edge는 만들지 않음 — 다운스트림 `/u-plan`이 생성).

> 이미 dropzone에 있던 미변경 파일은 해시 일치로 skip된다(idempotent). 같은 입력을 재-ingest해도 digest는 중복 생성되지 않는다.

---

## 4. 배치 제안 (Placement Suggestion) — u-doc 고유 가치

digest 내용을 분석해 **어느 app / 어느 SSoT 문서 / 어느 섹션**에 반영하면 좋을지 제안한다. **문서는 수정하지 않고**, 제안 표 + 다음 액션만 출력한다.

### 4.1 app 스코핑 (제안 전 필수)

`docs/{app}/...` 구조이므로 대상 app을 먼저 확정한다(advisor 권고).

1. `--app {name}` 제공 → 사용.
2. 미제공 + 단일 app 프로젝트(`u-maker.config.json`의 `project.apps` 길이 1) → 자동 선택.
3. 미제공 + 다중 app → `AskUserQuestion`으로 app 선택(`--auto`에서는 에러 + 안내).

### 4.2 digest 항목 → 목적 문서/섹션 매핑

| digest 필드 | 목적 문서 | 섹션 / 항목 타입 | 후속 커맨드 |
|-------------|----------|-----------------|------------|
| `requirements[]` (기능) | `plan/srs.md` | Functional Requirements (FR) | `/u-plan` |
| `requirements[]` (비기능) | `plan/srs.md` | Non-Functional (NFR) | `/u-plan` |
| `stakeholders[]` | `plan/srs.md` | Stakeholders (STK) | `/u-plan` |
| `domainTerms[]` | `plan/srs.md` | Glossary | `/u-plan` |
| `constraints[]` | `plan/srs.md` | Constraints | `/u-plan` |
| `workflows[]` | `plan/srs.md` | User Stories (US) + Features (FT) | `/u-plan` |
| `screenDescriptions[]` | `design/screens.md` + `plan/ia.md` | Screens (SC) / IA | `/u-design` |
| `businessRules[]` / `domainRules[]` | `design/erd.md` · `design/api.md` | Entities (ENT) / API | `/u-design` |
| `processingRules[]` | `design/api.md` | API Endpoint + FT | `/u-design` |
| `validationRules[]` | `gatekeeping/testcases.md` | Test Cases (TC) | `/u-gatekeeping` |
| `permissionRules[]` | `plan/srs.md` + `design/api.md` | FR(권한) / API auth | `/u-plan`, `/u-design` |
| `uiSpecifications[]` | `design/screens.md` | Screen Component (CMP) | `/u-design` |

매핑 불명확 항목 → "분류 보류"로 표시하고 `data/backlog/`에 기록(선택).

### 4.3 제안 출력 형식

```
u-doc / Ingest — 배치 제안 (app: {app})

  수집: {N}개 입력 → dropzone 정규화 + digest 생성 완료
    - notes/kickoff.md      (text)   → digest ✓
    - rfp-v2.pdf            (file)   → digest ✓
    - {figma-url}           (figma)  → /u-tools-figma 위임 ✓

  배치 제안:
  | 출처 digest        | 항목 수 | 제안 문서                 | 후속 커맨드   |
  |--------------------|---------|---------------------------|---------------|
  | kickoff (workflows)|   3     | {app}/plan/srs.md (US/FT) | /u-plan       |
  | rfp-v2 (requirements)| 8     | {app}/plan/srs.md (FR)    | /u-plan       |
  | figma (screens)    |  12     | {app}/design/screens.md   | /u-design     |

  다음 단계: /u-plan --app {app}  (digest를 SRS/IA로 반영)
```

---

## 5. links.json + 기록

- `data/links.json`: 각 digest에 대해 `digest` 노드만 등록(§3와 동일). 배치 제안 자체는 edge로 만들지 않는다(다운스트림 문서화 시점에 생성).
- 배치 보류/가정 항목은 `data/assumptions/` 또는 `data/backlog/`에 선택 기록.

---

## 6. 위임 (heavy extraction은 전용 도구로)

| 입력 | 위임 대상 | 이유 |
|------|----------|------|
| Figma URL / `.figma-link` | `/u-tools-figma` | 페이지·variant·컴포넌트·코멘트 전수 분석은 PM 컨텍스트에 과중 |
| DS 적용 소스 번들 | `/u-tools-figma-ds` | 토큰/컴포넌트 추출 + Figma DS push |
| web 본문 페치 필요 | `/u-tools-browser` | 페이지 렌더/추출 |

위임 후 결과(digest/manifest)는 `data/digest/`·`data/figma/`에 누적되어 배치 제안에 합산된다.
