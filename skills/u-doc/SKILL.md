---
name: u-doc
description: "This skill should be used when the user asks to '/u-doc', '/u-ssot', 'u-doc', 'u-ssot', wants to add/ingest input (a file, image, link, or text) into the SSoT docs ('SSoT에 추가', '문서에 추가', '이 자료 넣어줘', 'ingest this', 'add to docs'), or wants to tidy/reorganize the .u-maker document tree ('문서 정리', '문서 재정리', '폴더 정리', 'docs 정리', 'reorganize docs', 'tidy .u-maker'). Two modes: (1) Ingest — normalize an input into data/dropzone/, generate a digest, and suggest where it belongs (does NOT edit SSoT docs directly); (2) Reorganize — move/rename misplaced docs/ files (git mv + links.json) and regenerate output/ + reports/ to match the standard structure."
version: 4.0.0
---

# u-doc — SSoT Ingest + Document Reorganization

`/u-doc [input…] [--app {name}] [--reorg] [--dry-run] [--force]`
Alias: `/u-ssot`

두 가지 모드를 가진 SSoT 문서 도우미.

1. **Ingest** — 사용자 입력(파일/이미지/링크/텍스트)을 `data/dropzone/`에 정규화하고 digest로 분석한 뒤, **어느 app/문서/섹션에 속하는지 제안**한다.
2. **Reorganize** — `.u-maker/docs`·`output`·`reports`를 표준 구조·네이밍에 맞게 재정리한다.

**Primary Agent:** u-agent-plan (Ingest 분석 책임) / inline (Reorganize 파일 작업)
**Engine Dependencies:** digest-engine, doc-engine, dep-engine, router
**PBGD Phase:** Cross-cutting (Plan.Prepare에 가까움)

> **비파괴 보장:** Ingest는 SSoT 문서(`docs/**/*.md`)를 **직접 수정하지 않는다**(digest + 배치 제안까지). Reorganize는 **삭제하지 않고** 이동·재생성만 하며 항상 dry-run + 사용자 확인을 거친다.

> **doc-engine 진입점:** `doc-engine.md`는 항목 추가(`/u-add`)·갱신(`/u-update`) 명령을 참조하지만 이들은 존재하지 않는다. `/u-doc`은 그 **입력 측**(수집 → digest → 배치 제안)을 담당하고, 실제 문서 삽입·갱신은 `/u-plan`·`/u-design`이 수행한다(사용자 정책: 비파괴).

> **쉬운 글쓰기(HARD RULE):** 이 스킬이 만드는 산출물(digest 요약, 배치 제안 표, 재정리 계획·보고)의 설명 문장은 중학생이 처음 읽어도 이해할 수 있게 쓴다. ID·경로·해시 등 기술 값은 그대로 둔다. 규칙 원문: `skills/u-engine/references/doc-engine.md` § 8(MD) · `html-engine.md` § 0.6(HTML), Gatekeeping GK-06 `plain-language-middle-school` 검사로 강제.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `input…` | No | 인라인 텍스트, 파일 경로, 이미지 경로, URL. 생략 시 모드/입력을 질문. |
| `--app {name}` | No | 대상 app. 미지정 시 단일앱 자동 / 다중앱 프롬프트(`--auto`면 에러). |
| `--reorg` | No | 강제로 Reorganize 모드 진입(입력 없이 정리만). |
| `--dry-run` | No | (Reorganize) 계획만 출력하고 종료. 어떤 파일도 바꾸지 않음. |
| `--force` | No | (Ingest) 해시가 같아도 digest 재분석. |

## Mode Detection (Step 0)

입력과 의도로 모드를 자동 판별한다:

1. `--reorg` 플래그 있음 → **Reorganize**.
2. 입력(파일/이미지/링크/텍스트)이 제공됨 → **Ingest**.
3. 입력 없이 "정리/재정리/tidy/reorganize" 의도(router 분류) → **Reorganize**.
4. 둘 다 모호 → `AskUserQuestion`으로 모드 확인(묵시적 진행 금지).

## Execution Flow — Ingest Mode

상세 규칙 → **`references/ingest-rules.md`**.

### Step I-1: Normalize Input → dropzone
입력 종류(file/image/link/text)를 판별하고 `data/dropzone/`(또는 `--app` 시 `data/dropzone/{app}/`)에 **복사/기록**한다. 원본은 보존(이동·삭제 금지). Figma URL은 `.figma-link`로 기록.

### Step I-2: Generate Digest (재사용)
`/u-analyze`의 Step 1–4(digest-engine)를 재사용해 신규/변경 파일만 digest화한다. Figma/DS 소스는 `/u-tools-figma`·`/u-tools-figma-ds`로 자동 위임. `data/links.json`에 `digest` 노드 등록(edge 없음).

### Step I-3: Resolve App
`docs/{app}/` 배치를 위해 대상 app을 확정(§ingest-rules 4.1).

### Step I-4: Suggest Placement
digest 항목 타입 → 목적 문서/섹션을 매핑(§ingest-rules 4.2)하여 **제안 표 + 후속 커맨드**(`/u-plan`·`/u-design`·`/u-gatekeeping`)를 출력한다. **문서는 수정하지 않는다.** 분류 불명 항목은 `data/backlog/`에 기록(선택).

## Execution Flow — Reorganize Mode

상세 규칙 → **`references/reorg-rules.md`**. tree별로 다른 메커니즘을 쓴다(생성물은 hand-move 금지).

### Step R-1: Resolve App & Scan
대상 app 확정 후 `docs/{app}`·`output/{app}`·`reports/`를 스캔.

### Step R-2: Detect Drift
- `docs/` (tracked): frontmatter(`docType`/`App`) + 경로 패턴으로 misplaced/misnamed/companion 누락 감지.
- `output/` (gitignored, 생성물): `docs/` 기준 누락·잉여·구조 drift 감지.
- `reports/` (gitignored, 생성물): 네이밍/위치 위반 감지.

### Step R-3: Present Plan (확인 필수)
`references/reorg-rules.md` §7 multiline box로 이동/재생성 계획 제시. `--dry-run`이면 여기서 종료. **빈 응답 → 재질문**(묵시적 진행 금지).

### Step R-4: Execute
사용자 확인 후:
- `docs/`: **`git mv`**(미추적은 `mv` + 경고)로 `.md`+`.json` 함께 이동 → **`links.json` 경로 갱신**(id 불변). 빈 레거시 폴더 제거.
- `output/`: `/u-output --app {app}` 재생성 호출.
- `reports/`: 파일명/위치 교정(필요 시 `mv`) + `/u-report` 인덱스 재생성. 원본 리포트 내용 보존.

### Step R-5: Verify
재정리 후 다시 스캔하여 잔여 drift 0 확인 → "표준 구조 정합 ✓". 잔여 있으면 보고.

## Preconditions

- `.u-maker/` 폴더 트리 존재. 없으면 → `/u-prepare-foldertree`(또는 `/u-prepare`) 먼저 실행하도록 안내.
- Ingest: 입력이 1개 이상. Reorganize: 정리 대상 트리 중 1개 이상 존재.

## Postconditions

- **Ingest:** 입력이 `data/dropzone/`에 정규화 저장, 대응 digest가 `data/digest/`에 생성, `links.json`에 digest 노드 등록, 배치 제안 출력. (SSoT 문서 불변)
- **Reorganize:** `docs/`가 표준 경로·네이밍 정합, `links.json` 경로 동기화, `output/`·`reports/`가 표준 구조로 재생성. 삭제된 사용자 파일 없음.

## Error Handling

| Condition | Action |
|-----------|--------|
| `.u-maker/` 부재 | Error + `/u-prepare-foldertree` 안내 |
| 다중 app + `--app` 미지정 + `--auto` | Error: app 모호 → `--app` 지정 요청 |
| `git mv` 실패(미추적/충돌) | `mv` fallback + 경고. 충돌은 건너뛰고 보고 |
| digest 추출 실패 | 해당 파일 `_index.json` status `error` + 다음 파일 계속 |
| Reorganize 분류 불가 파일 | 삭제 금지 → `misc`로 표시 + 사용자 확인 |

## Reference Files

- **`references/ingest-rules.md`** — 입력 종류별 정규화, digest 재사용, app 스코핑, digest→문서 배치 매핑, 위임 규칙.
- **`references/reorg-rules.md`** — tree별 처리, `docs/` 표준 구조, misplaced/misnamed 판정, `git mv`+`links.json` 절차, `output/`·`reports/` 재생성, 안전 규칙.

## Related Commands

- `/u-analyze` — dropzone 배치 스캔 → digest (u-doc Ingest가 내부 재사용).
- `/u-plan` · `/u-design` · `/u-gatekeeping` — 배치 제안의 실제 문서 반영 주체.
- `/u-output` — `docs/` → HTML 재생성(Reorganize의 output/ 단계).
- `/u-report` — daily/weekly 리포트 + 인덱스 재생성(Reorganize의 reports/ 단계).
- `/u-tools-figma` · `/u-tools-figma-ds` · `/u-tools-browser` — heavy 입력 위임 대상.
