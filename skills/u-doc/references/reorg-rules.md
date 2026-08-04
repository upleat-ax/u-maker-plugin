# reorg-rules — `.u-maker/` Reorganization Rules (u-doc Reorganize Mode)

`/u-doc` **Reorganize 모드**의 규칙. `.u-maker/docs`, `.u-maker/output`, `.u-maker/reports` 아래의 폴더·파일을 **표준 구조와 네이밍 규칙**에 맞게 재정리한다.

> **핵심 원칙 (tree별 분리 — advisor 권고):** 세 트리는 git 상태와 성격이 다르므로 **다른 메커니즘**으로 처리한다. `output/`·`reports/`는 gitignore된 **생성물**이므로 hand-move하지 않고 **재생성**한다.

---

## 1. 대상 트리와 처리 방식

| Tree | git 상태 | 성격 | 처리 메커니즘 |
|------|---------|------|--------------|
| `docs/` | **tracked** | SSoT 원본(MD+JSON) | misplaced/misnamed 감지 → **`git mv`** → `links.json` 경로 갱신 |
| `output/` | **gitignored** | `/u-output` 생성물 | drift 감지 → **`/u-output`으로 재생성** (직접 mv 금지) |
| `reports/` | **gitignored** | `/u-report` 생성물 | 네이밍/위치 위반 감지 → **`/u-report`로 재생성** 또는 정리 제안 |

`.state/`는 런타임 상태이므로 **건드리지 않는다**.

---

## 2. `docs/` 표준 구조 (정답)

```
docs/
├── common/                         # 교차 앱 공유 문서
└── {app}/
    ├── plan/
    │   ├── srs.md   + srs.json
    │   └── ia.md    + ia.json
    ├── design/
    │   ├── erd.md           + erd.json
    │   ├── api.md           + api.json
    │   ├── screens.md       + screens.json
    │   └── design-system.md + design-system.json   # HTML-first 파생(원본은 output/.../design-system.html)
    └── gatekeeping/
        ├── testcases.md    + testcases.json
        └── test-results.md + test-results.json
```

- phase 폴더는 **`plan` / `design` / `gatekeeping`** 3종만(레거시 `check/`·`build/` 아님).
- 파일명은 **kebab-case 소문자**의 정확한 docType 이름(아래 §3.2 표).
- 모든 `.md`는 동명 `.json` companion 1:1 동반.

### docType ↔ 표준 경로/파일명

| docType | 표준 경로 | 파일명 |
|---------|----------|--------|
| srs | `docs/{app}/plan/` | `srs.md` + `srs.json` |
| ia | `docs/{app}/plan/` | `ia.md` + `ia.json` |
| erd | `docs/{app}/design/` | `erd.md` + `erd.json` |
| api | `docs/{app}/design/` | `api.md` + `api.json` |
| screens | `docs/{app}/design/` | `screens.md` + `screens.json` |
| design-system | `docs/{app}/design/` | `design-system.md` + `design-system.json` |
| testcases | `docs/{app}/gatekeeping/` | `testcases.md` + `testcases.json` |
| test-results | `docs/{app}/gatekeeping/` | `test-results.md` + `test-results.json` |

---

## 3. `docs/` misplaced / misnamed 판정

각 파일의 **frontmatter(`docType`/`App`/`Status`)** + **경로 패턴**으로 판정한다. frontmatter가 우선, 없으면 파일명·내용으로 docType 추론.

### 3.1 위치 오류 (wrong location)

| 증상 | 교정 |
|------|------|
| phase 폴더 밖 SSoT (`docs/{app}/srs.md`) | → `docs/{app}/plan/srs.md` |
| 레거시 phase 폴더 `docs/{app}/check/**` | → `docs/{app}/gatekeeping/**` |
| design 문서가 plan에, 또는 그 반대 | → docType의 표준 phase 폴더로 |
| companion `.json`이 `.md`와 다른 폴더 | → `.md` 옆으로 |

### 3.2 이름 오류 (wrong name)

| 증상 | 교정 |
|------|------|
| 대문자/혼합(`SRS.md`, `DesignSystem.md`) | → kebab 소문자(`srs.md`, `design-system.md`) |
| snake_case(`test_results.md`) | → `test-results.md` |
| 비표준 별칭(`test-cases.md`, `requirements.md`) | → 표준 docType명(`testcases.md`, `srs.md`)으로(내용 확인 후) |

### 3.3 companion 무결성

| 증상 | 동작 |
|------|------|
| `.md`만 있고 `.json` 없음 | 플래그 → doc-engine로 `.json` 재생성 **제안**(자동 생성은 확인 후) |
| `.json`만 있고 `.md` 없음 | 플래그 → 사용자 확인(고아 companion일 수 있음) |
| `.md`↔`.json` 항목/버전 불일치 | 플래그 → `/u-output` 또는 doc-engine 재동기화 제안 |

### 3.4 분류 불가

docType을 확정할 수 없는 파일은 **삭제하지 않는다**. `misc`로 표시하고 사용자에게 확인을 요청한다(사용자가 의도적으로 둔 메모일 수 있음).

---

## 4. `docs/` 이동 실행 절차

1. **dry-run 계획 표 생성** (from → to, 사유). 변경 0건이면 "이미 표준 구조 ✓".
2. **사용자 확인 필수**(§6). 확인 전 어떤 파일도 이동하지 않는다.
3. 확인 후 이동:
   - tracked 파일 → **`git mv {from} {to}`**(이력 보존). `.md`와 `.json` companion을 **함께** 이동.
   - 미추적(untracked) 파일 → `mv` fallback + "git에 미추적이라 일반 이동했다" 경고.
4. **`links.json` 경로 갱신**: 이동한 doc의 `doc:` 노드 `path`, 그 문서에 속한 `item:` 노드들의 `path`를 새 경로로 갱신. 노드/엣지의 **id는 변경 금지**(cross-ref 보존).
5. 이동 후 빈 레거시 폴더(`check/` 등)는 비었으면 제거.

---

## 5. `output/` · `reports/` 재생성 (생성물 — hand-move 금지)

### 5.1 output/ drift 감지

`docs/`(정답)를 기준으로 현재 `output/` 구조를 비교한다.

| drift | 동작 |
|-------|------|
| docs에 있는데 output에 없는 문서 | 누락 → 재생성 대상 |
| output에 있는데 docs에 없는 문서 | 잉여(stale) → 재생성 시 정리됨 |
| 분할/단일 구조 불일치(`erd.html` 단일인데 분할이어야) | 구조 drift → 재생성 |
| 잘못된 위치/이름의 html | 재생성으로 교정 |

→ **조치:** `/u-output --app {app}` 재생성을 **제안/실행**. (output은 `docs/`에서 결정적으로 생성되므로 hand-move 대신 재생성이 정답.)

### 5.2 reports/ 정리

표준: `reports/{YYYY-MM-DD}-daily.html`, `reports/{YYYY-MM-DD}-weekly.html`, `reports/index.html`(시간순).

| drift | 동작 |
|-------|------|
| 날짜/타입 누락 네이밍(`2026-04-10.html`) | `/u-report` 재생성 또는 규칙명으로 정리 제안 |
| 하위 폴더로 분류(`reports/2026/04/...`) | flat 루트로 정리 제안 |
| `index.html` 부재/구식 | `/u-report`로 인덱스 재생성 |

→ reports는 과거 스냅샷이라 내용 재생성이 불가할 수 있으므로, **파일명/위치 교정**(필요 시 `mv`)과 **인덱스 재생성**만 제안한다. 원본 리포트 내용은 보존.

---

## 6. 안전 규칙 (필수)

1. **항상 dry-run 먼저** → 계획 표 제시 → **사용자 확인 후에만** 실행. `--dry-run` 플래그는 계획만 출력하고 종료.
2. **삭제 금지**: 재정리는 이동·재생성만. 분류 불가/사용자 생성 파일은 `misc`로 두고 확인.
3. `docs/` 이동은 **`git mv` 우선**(이력 보존), 미추적만 `mv`.
4. `output/`·`reports/`는 **직접 mv하지 않고 재생성**(reports 내용 보존이 필요한 파일명 교정은 예외적 `mv` 허용).
5. **`links.json` 동기화**는 `docs/` 이동과 **원자적**으로(같은 확인 사이클 내) 수행. 이동만 하고 links를 안 고치면 추적성이 깨진다.
6. `.state/`, `data/`는 reorganize 대상이 아니다.
7. **`out/` ↔ `output/` root 관용:** 표준 산출물 root는 `output/`이나, `doc-engine.md`(design-system 등 일부 경로)는 레거시로 `out/`을 쓴다. drift-detector는 **두 root를 모두 유효로 간주**하고, 어느 한쪽으로 단정해 이동/잉여 표시하기 전에 사용자 확인을 거친다(오탐 방지). 가능하면 사용자에게 어느 root가 정답인지 확인받아 통일을 제안한다.

---

## 7. 확인 UX

이동/재생성 계획은 `/u-tools-git-pr`의 multiline box 양식에 준하여 제시한다:

```
u-doc / Reorganize — 계획 (app: {app})

  docs/ (git mv + links 갱신):
    M  docs/{app}/srs.md            → docs/{app}/plan/srs.md
    M  docs/{app}/check/testcases.* → docs/{app}/gatekeeping/testcases.*
    !  docs/{app}/design/erd.md     companion erd.json 누락 → 재생성 제안

  output/ (재생성):
    drift 3건 → /u-output --app {app} 권장

  reports/ (정리):
    2026-04-10.html → 2026-04-10-daily.html (rename)

  [1] 실행 (docs git mv + links 갱신, output/reports 재생성 호출)
  [2] docs/ 만 실행
  [3] dry-run 종료 (아무것도 바꾸지 않음)
  [4] Abort
```

빈 응답 → 재질문(묵시적 진행 금지).
