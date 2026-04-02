---
name: u-doc
description: "특정 SSoT 문서 조회, 편집, 재생성. 문서 메타데이터와 함께 내용을 표시하거나, 재생성 로직을 실행한다."
triggers:
  - "/u-doc"
  - "문서"
  - "document view"
  - "문서 조회"
---

# u-doc -- View / Edit / Regenerate Document

`/u-doc [scope] [doc] [action]` 명령으로 특정 SSoT 문서를 조회하거나 편집, 재생성한다.

**Primary Agent:** 대상 문서의 Owner 에이전트 (engine-doc 사용)

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 자동 선택 |
| `doc` | Required | 문서 이름 또는 약칭 |
| `action` | Optional | `view` (기본), `edit`, `regenerate` |

## Flags

| Flag | Description |
|------|-------------|
| `--format json` | JSON 형식으로 출력 (.json 동반 파일 내용) |
| `--section "name"` | 특정 섹션만 표시/편집 |
| `--diff` | 이전 버전과의 차이점 표시 |
| `--force` | regenerate 시 기존 문서 강제 덮어쓰기 (확인 생략) |

---

## Execution Flow

### Step 1: Resolve Document

1. `u-maker.config.json` 읽어 scope 해석
2. `doc` 약칭 → 파일 경로 매핑:

| Alias | Full Path | Owner Agent |
|-------|-----------|-------------|
| `srs` | `docs/{app}/01-plan/srs.md` | u-agent-planner |
| `ia` | `docs/{app}/01-plan/ia.md` | u-agent-planner |
| `roadmap` | `docs/{app}/01-plan/roadmap.md` | u-agent-planner |
| `erd` | `docs/{app}/02-design/erd.md` | u-agent-sa |
| `api` | `docs/{app}/02-design/api.md` | u-agent-sa |
| `screens` | `docs/{app}/02-design/screens.md` | u-agent-ux |
| `screen-flow` | `docs/{app}/02-design/screen-flow.md` | u-agent-ux |
| `rtm` | `docs/{app}/02-design/rtm.md` | u-agent-planner |
| `code` | `docs/{app}/03-dev/code.md` | u-agent-builder |
| `test-cases` | `docs/{app}/04-check/test-cases.md` | u-agent-gatekeeper |
| `test-report` | `docs/{app}/04-check/test-report.md` | u-agent-gatekeeper |
| `glossary` | `docs/common/project/glossary.md` | u-agent-planner |
| `iteration-log` | `docs/common/project/iteration-log.md` | u-agent-orchestrator |
| `retrospective` | `docs/common/project/retrospective.md` | u-agent-orchestrator |
| `design-token` | `docs/common/ux/design-token.md` | u-agent-ux-ds |
| `coding-convention` | `docs/common/dev/coding-convention.md` | u-agent-sa |
| `code-review-rules` | `docs/common/dev/code-review-rules.md` | u-agent-gatekeeper |

3. 파일 존재 확인 → 없으면 "문서가 아직 생성되지 않았습니다" + 생성 명령 안내

### Step 2: Read Document + Metadata

1. `.md` 파일 읽기
2. frontmatter 파싱 → 메타데이터 추출:
   ```
   Owner: {agent}
   Status: {Draft|Review|Final}
   Version: {semver}
   Last Updated: {ISO 8601}
   Related Docs: [{list}]
   ```
3. `_index.json`에서 추가 메타데이터 조회:
   - Impact flags (있으면)
   - 항목 수 통계
4. `.json` 동반 파일 존재 여부 확인

---

## Action: view (기본)

### Display Format

```markdown
## {Document Title}

| Field | Value |
|-------|-------|
| **Owner** | {agent} |
| **Status** | {status} |
| **Version** | {version} |
| **Last Updated** | {date} |
| **File** | {file-path} |
| **Companion JSON** | {있음/없음} |
| **Impact Flags** | {count 또는 None} |

---

{문서 본문 전체 또는 --section 지정 섹션}
```

**`--format json` 사용 시:**
- `.json` 동반 파일의 내용을 그대로 출력
- JSON 파일이 없으면 `.md`에서 파싱하여 JSON 구조로 변환 후 출력

**`--section` 사용 시:**
- 지정 섹션(H2/H3 기준)만 추출하여 표시
- 섹션명 fuzzy matching 지원 (예: "fr" → "Functional Requirements")

**`--diff` 사용 시:**
- 아카이브된 이전 iteration 문서와 비교
- `docs/iterations/{n-1}/{app}/` 에서 동일 문서 읽기
- 추가/삭제/변경된 항목 하이라이트

---

## Action: edit

1. 문서 내용 표시 (view와 동일)
2. 사용자의 수정 지시 대기
3. 수정 적용 후 `/u-update` 로직 위임:
   - 헤더 Version/Last Updated 갱신
   - `.json` 동반 파일 재생성
   - `_index.json` 갱신
4. cascade는 자동 적용하지 않음 → 필요 시 `/u-update --cascade` 안내

**편집 예시:**
```
/u-doc myapp srs edit
> "FR-0001의 priority를 Must에서 Should로 변경해줘"
> "US-0005를 삭제하고 관련 FT도 정리해줘"
> "NR-0003 뒤에 새 NR 항목을 추가해줘"
```

---

## Action: regenerate

기존 문서를 classified 데이터 또는 원본 소스로부터 재생성:

### Regenerate 프로세스

1. **확인 단계:**
   - 기존 문서의 Status 확인
   - Final 상태면 "Final 문서를 재생성하시겠습니까?" 확인 (Always-Pause)
   - `--force` 플래그로 확인 생략 가능

2. **데이터 소스 결정:**

   | Document | Regenerate Source |
   |----------|------------------|
   | srs | `data/classified/requirements/` + `data/classified/stakeholders/` + `data/classified/constraints/` |
   | ia | SRS + `data/classified/workflows/` + `data/classified/screens/` |
   | roadmap | SRS + engine-estimator |
   | erd | SRS + `data/classified/data-models/` |
   | api | SRS + ERD |
   | screens | SRS + IA + design-token |
   | rtm | SRS + screens + api + test-cases (교차 매핑) |
   | test-cases | SRS (FT 목록) + screens + api |

3. **기존 수동 수정 보존:**
   - 재생성 전 기존 문서에서 `manual-edit` 태그된 항목 추출
   - 재생성 후 수동 수정 항목 복원 (conflict 시 사용자에게 질문)

4. **재생성 실행:**
   - Owner 에이전트가 해당 Phase의 생성 로직 재실행
   - 새 버전 = 기존 major + 1 (재생성은 major 변경)
   - Status → `Draft`로 리셋

5. **후처리:**
   - `.json` 동반 파일 재생성
   - `_index.json` 갱신
   - `data/links.json` 의존 관계 재검증
   - Impact flags 클리어 (해당 문서에 대한)

### Regenerate 결과 표시

```
## Document Regenerated

**Document:** {doc} ({file-path})
**Version:** {old} → {new}
**Source:** {regenerate source description}
**Items:** {기존 count} → {신규 count}
**Manual edits preserved:** {count}

### Changes from Previous
- Added: {count} items
- Removed: {count} items
- Modified: {count} items

### Next Steps
- Review changes: /u-doc {scope} {doc} --diff
- Cascade to dependents: /u-update {scope} {doc} --cascade
- Validate consistency: /u-sync {scope}
```

---

## Document Listing

`/u-doc` (doc 인자 없이) 실행 시 전체 문서 목록 표시:

```markdown
## SSoT Documents - {app}

### 01-plan
| Document | Status | Version | Last Updated | Owner | Impact |
|----------|--------|---------|-------------|-------|--------|
| srs | Final | 1.2.0 | 2026-03-25 | planner | -- |
| ia | Review | 1.1.0 | 2026-03-24 | planner | 1 flag |
| roadmap | Draft | 1.0.0 | 2026-03-20 | planner | -- |

### 02-design
| Document | Status | Version | Last Updated | Owner | Impact |
|----------|--------|---------|-------------|-------|--------|
| erd | Final | 1.0.0 | 2026-03-23 | sa | -- |
...

### common
| Document | Status | Version | Last Updated | Owner |
|----------|--------|---------|-------------|-------|
| glossary | Draft | 1.0.0 | 2026-03-20 | planner |
...
```

---

## Safety Rules

1. 존재하지 않는 문서에 edit/regenerate 실행 불가
2. Final 문서 edit 시 사용자 확인 필수 (Always-Pause)
3. regenerate 시 기존 수동 수정 보존 시도 (conflict → 사용자 확인)
4. regenerate 후 `.json` 동반 파일 재생성 필수
5. `_index.json` 갱신 필수
6. 버전 rollback 금지
7. 문서 삭제 기능 없음 (archive만 가능)
8. `--diff`는 아카이브된 이전 버전이 있을 때만 동작
