---
name: u-update
description: "SSoT 문서 수정. 변경 사항 반영 및 cascade 옵션으로 의존 문서 자동 갱신. 버전/타임스탬프 갱신, companion JSON 재생성까지 수행한다."
triggers:
  - "/u-update"
  - "update document"
  - "문서 수정"
  - "문서 갱신"
---

# u-update -- Update Document + Cascade

`/u-update [scope] [doc] [flags]` 명령으로 지정 SSoT 문서를 수정하고, 변경 사항을 의존 문서에 전파(cascade)할 수 있다.

**Primary Agent:** 대상 문서의 Owner 에이전트 (engine-doc, engine-dep 사용)

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 자동 선택 |
| `doc` | Required | 문서 이름 또는 약칭 (srs, ia, erd, api, screens, rtm, roadmap 등) |

## Flags

| Flag | Description |
|------|-------------|
| `--cascade` | 수정 후 의존 문서에 변경 영향 전파 |
| `--field "key=value"` | 특정 필드만 수정 (예: `--field "FR-0001.priority=Must"`) |
| `--section "name"` | 특정 섹션만 수정 대상으로 열기 |
| `-i` | 각 cascade 대상에서 사용자 확인 |

---

## Execution Flow

### Step 1: Resolve Document Path

1. `u-maker.config.json` 읽어 scope 해석
2. `doc` 약칭 → 실제 파일 경로 매핑:

| Alias | File Path |
|-------|-----------|
| `srs` | `docs/{app}/01-plan/srs.md` |
| `ia` | `docs/{app}/01-plan/ia.md` |
| `roadmap` | `docs/{app}/01-plan/roadmap.md` |
| `erd` | `docs/{app}/02-design/erd.md` |
| `api` | `docs/{app}/02-design/api.md` |
| `screens` | `docs/{app}/02-design/screens.md` |
| `rtm` | `docs/{app}/02-design/rtm.md` |
| `screen-flow` | `docs/{app}/02-design/screen-flow.md` |
| `code` | `docs/{app}/03-dev/code.md` |
| `test-cases` | `docs/{app}/04-check/test-cases.md` |
| `test-report` | `docs/{app}/04-check/test-report.md` |
| `glossary` | `docs/common/project/glossary.md` |
| `iteration-log` | `docs/common/project/iteration-log.md` |
| `retrospective` | `docs/common/project/retrospective.md` |

3. 파일 존재 여부 확인 → 없으면 에러 + 생성 명령 안내

### Step 2: Read Current Document

1. 대상 `.md` 파일 전체 읽기
2. frontmatter 파싱:
   - `Owner`: 담당 에이전트
   - `Status`: Draft / Review / Final
   - `Version`: semantic version
   - `Last Updated`: ISO 8601 timestamp
3. 동반 `.json` 파일 읽기 (존재 시)

### Step 3: Apply Edit

**Interactive edit (기본):**
1. 문서 내용을 사용자에게 표시
2. 수정 지시 대기 (자연어로 "FR-0001의 priority를 Must로 변경해줘" 등)
3. 지시에 따라 에이전트가 수정 적용

**Field-level edit (`--field`):**
1. 지정 필드 위치 탐색 (ID 또는 key path)
2. 해당 필드만 값 변경
3. 예: `/u-update myapp srs --field "FR-0001.priority=Must"`

**Section edit (`--section`):**
1. 지정 섹션만 추출하여 표시
2. 섹션 내 수정 적용
3. 전체 문서에 다시 삽입

### Step 4: Update Document Header

수정 완료 후 헤더 자동 갱신:

1. `Version` 증가 규칙:
   - 항목 추가/삭제 → minor 증가 (1.0.0 → 1.1.0)
   - 항목 내용 수정 → patch 증가 (1.0.0 → 1.0.1)
   - 구조 대폭 변경 → major 증가 (1.0.0 → 2.0.0, 사용자 확인 필수)
2. `Last Updated` → 현재 시각 (ISO 8601)
3. `Status` → `Draft`로 리셋 (Final이었으면 사용자 확인 후)

### Step 5: Regenerate Companion JSON

1. 수정된 `.md` 파일을 파싱
2. 동일 경로에 `.json` 파일 재생성
3. JSON 구조:
   ```json
   {
     "documentId": "{app}/{doc}",
     "type": "{doc-type}",
     "version": "{new-version}",
     "status": "Draft",
     "lastUpdated": "{ISO 8601}",
     "owner": "{agent}",
     "data": { ... },
     "metadata": {
       "previousVersion": "{old-version}",
       "changeDescription": "{변경 요약}"
     }
   }
   ```

### Step 6: Cascade Impact Analysis (--cascade)

`--cascade` 플래그 사용 시:

1. `.u-maker/data/links.json` 읽기
2. 수정된 문서를 기준으로 의존 그래프 탐색:
   ```
   srs → ia, erd, api, screens, rtm, roadmap, test-cases
   ia → screens, screen-flow
   erd → api, code
   api → code
   screens → code, test-cases
   rtm → test-report
   ```
3. 영향받는 문서 목록 생성:
   ```markdown
   ## Cascade Impact Analysis

   **Modified:** srs.md (v1.0.0 → v1.1.0)

   ### Impacted Documents
   | Document | Relationship | Impact | Action Needed |
   |----------|-------------|--------|---------------|
   | ia.md | derives | FR-0042 추가로 Screen 매핑 필요 | Re-generate section |
   | erd.md | derives | 새 데이터 모델 검토 필요 | Manual review |
   | rtm.md | traces | FR-0042 traceability chain 추가 필요 | Auto-append row |
   ```

### Step 7: Apply Cascade Updates

`-i` 플래그 사용 시 각 문서별로 사용자 확인:

1. **Auto-fixable 항목** (에이전트가 자동 수정):
   - RTM에 새 FR → US → FT chain 행 추가
   - 인덱스에 항목 수 갱신
   - 의존 문서 헤더의 `Related Docs` 갱신

2. **Manual-review 항목** (사용자 확인 필요):
   - ERD 엔티티 추가/수정
   - API 엔드포인트 추가/수정
   - Screen 레이아웃 변경
   - 코드 재생성 필요

3. 각 cascade 대상 문서에 대해:
   - auto-fixable → 자동 수정 + 버전 patch 증가
   - manual-review → Impact Flag 설정 (status 변경 없이 플래그만)

### Step 8: Set Impact Flags

cascade 대상 중 manual-review 항목에 Impact Flag 설정:

1. `docs/{app}/_index.json` 갱신:
   ```json
   {
     "documentId": "erd",
     "impactFlags": [
       {
         "source": "srs",
         "change": "FR-0042 added",
         "flaggedAt": "{ISO 8601}",
         "severity": "review-needed"
       }
     ]
   }
   ```
2. `/u-status`에서 Impact Flags 섹션에 표시됨

### Step 9: Update Indexes

1. `docs/{app}/_index.json`:
   - 수정된 문서의 `version`, `lastUpdated`, `status` 갱신
   - cascade로 수정된 문서들도 동일 갱신
2. `.u-maker/data/links.json`:
   - 새 의존 관계 추가 (항목 추가로 인한)
   - 삭제된 항목의 관계 제거

### Step 10: Display Summary

```
## Update Complete

**Document:** {doc} ({file-path})
**Version:** {old} → {new}
**Changes:** {변경 요약}

### Cascade Results (--cascade)
| Document | Action | Result |
|----------|--------|--------|
| rtm.md | Auto-append | Done (v1.2.0 → v1.2.1) |
| ia.md | Impact flag | Flagged for review |
| erd.md | Impact flag | Flagged for review |

### Impact Flags Set: {count}
- erd.md: "FR-0042 추가로 데이터 모델 검토 필요"
- ia.md: "FR-0042 추가로 Screen 매핑 필요"

### Next Steps
- Review flagged docs: /u-doc {scope} {flagged-doc}
- Check consistency: /u-sync {scope}
- View status: /u-status {scope}
```

---

## Cascade Without --cascade

`--cascade` 미사용 시에도 경고 표시:

```
⚠ This document has {n} dependents in data/links.json.
  Run `/u-update {scope} {doc} --cascade` to propagate changes.
  Or run `/u-sync {scope}` to verify consistency.
```

---

## Safety Rules

1. Final 상태 문서 수정 시 반드시 사용자 확인 (Always-Pause)
2. cascade 자동 수정은 auto-fixable 항목에만 적용 (구조 변경은 사용자 확인 필수)
3. ID 변경/삭제 시 모든 역참조 확인 → 고아 항목 발생 방지
4. `.json` 동반 파일 재생성 필수
5. `_index.json` 갱신 필수
6. 버전 rollback 금지 (항상 증가)
7. cascade 중 에러 발생 시 해당 문서만 skip, 나머지 계속 진행
8. 모든 수정에 changeDescription 기록 (audit trail)
