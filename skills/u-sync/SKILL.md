---
name: u-sync
description: "전체 문서 일관성 검증 + 불일치 자동 수정 제안. 13개 교차 검증 규칙으로 SSoT 문서 간 정합성을 확인한다."
triggers:
  - "/u-sync"
  - "동기화"
  - "consistency check"
  - "일관성 검증"
---

# u-sync -- Full Consistency Verification

`/u-sync [scope] [--fix] [--rule N]` 명령으로 SSoT 문서 전체의 교차 일관성을 검증하고, 불일치 항목에 대해 수정 제안을 생성한다.

**Primary Agent:** u-agent-guardian (engine-validator, engine-dep 사용)

---

## Flags

| Flag | Description |
|------|-------------|
| `--fix` | 자동 수정 가능한 불일치를 즉시 수정 |
| `--rule N` | 특정 규칙만 실행 (C-01 ~ C-13) |
| `--verbose` | 각 규칙별 상세 결과 출력 |
| `-i` | 각 수정 제안에서 사용자 확인 |

---

## Execution Flow

### Step 1: Load All Documents

1. `u-maker.config.json` 읽어 scope 해석
2. `docs/{app}/_index.json` 읽기 → 등록된 전체 문서 목록
3. 각 문서의 `.md` + `.json` 파일 로드
4. `_classified/_summary.json` 로드
5. `_backlog/_index.json` 로드
6. `.u-maker/_links.json` 로드
7. `_assumptions/_index.json` 로드

### Step 2: Execute 13 Validation Rules

#### C-01: Every FR in SRS has >= 1 US

- `srs.json` → FR 목록 추출
- 각 FR에 대해 US 역참조 확인
- **위반:** FR-XXXX에 매핑된 US가 0개
- **수정 제안:** "FR-{id}에 대한 US를 생성하세요: /u-add {scope} us --parent FR-{id}"

#### C-02: Every US has >= 1 FT

- `srs.json` → US 목록 추출
- 각 US에 대해 FT 역참조 확인
- **위반:** US-XXXX에 매핑된 FT가 0개
- **수정 제안:** "US-{id}에 대한 FT를 분해하세요"

#### C-03: Every FT maps to a Screen

- `srs.json` → FT 목록 + `screens.json` → Screen-FT 매핑
- FT가 어떤 Screen에도 매핑되지 않으면 위반
- **위반:** FT-XXXX가 어떤 Screen에도 매핑되지 않음
- **수정 제안:** "FT-{id}를 적절한 Screen에 매핑하세요"
- **예외:** backend-only FT (API/DB 전용)는 Screen 매핑 면제

#### C-04: Every Screen maps to API endpoints

- `screens.json` → 각 Screen의 데이터 요구사항
- `api.json` → 엔드포인트 목록
- Screen에서 필요한 API가 api.json에 존재하는지 확인
- **위반:** SCR-XXX에 필요한 API가 미정의
- **수정 제안:** "SCR-{id}에 필요한 {method} {path} 엔드포인트를 추가하세요"

#### C-05: Every API endpoint maps to ERD entities

- `api.json` → request/response body 스키마
- `erd.json` → 엔티티 목록
- API가 참조하는 엔티티가 ERD에 존재하는지 확인
- **위반:** API {method} {path}가 참조하는 {entity}가 ERD에 없음
- **수정 제안:** "{entity} 엔티티를 ERD에 추가하세요"

#### C-06: RTM covers all FR -> US -> FT -> Screen -> TC chains

- `rtm.json` → 추적 행 목록
- SRS의 전체 FR→US→FT chain vs RTM 행 비교
- 누락된 chain이 있으면 위반
- **위반:** FR-{id} → US-{id} → FT-{id} chain이 RTM에 누락
- **자동 수정 가능:** RTM에 누락 행 추가 (`--fix` 시)

#### C-07: _index.json matches actual files

- `_index.json`에 등록된 문서 vs 실제 파일 시스템 비교
- 인덱스에 있지만 파일 없음 → 고스트 엔트리
- 파일 있지만 인덱스에 없음 → 미등록 파일
- **자동 수정 가능:** 고스트 제거 + 미등록 추가 (`--fix` 시)

#### C-08: _links.json references are valid

- `_links.json`의 모든 `from`/`to` 참조가 실제 존재하는 문서인지 확인
- 삭제/이동된 문서에 대한 dangling reference 탐지
- **자동 수정 가능:** dangling reference 제거 (`--fix` 시)

#### C-09: All .md files have companion .json

- `docs/{app}/` 하위 모든 `.md` 파일에 대해 동명 `.json` 존재 확인
- **위반:** {file}.md에 동반 .json이 없음
- **자동 수정 가능:** `.md`에서 `.json` 재생성 (`--fix` 시)

#### C-10: Document headers have required fields

- 모든 SSoT `.md` 파일의 frontmatter 검사
- 필수 필드: `Owner`, `Status`, `Version`, `Last Updated`
- **위반:** {file}에 {field} 헤더가 누락
- **자동 수정 가능:** 기본값으로 필드 추가 (`--fix` 시)

#### C-11: Status values are valid

- 모든 문서의 `Status` 필드가 허용 값인지 확인
- 허용 값: `Draft`, `Review`, `Final`
- **위반:** {file}의 Status "{value}"는 유효하지 않음
- **자동 수정 가능:** 가장 가까운 유효 값으로 수정 (`--fix` 시)

#### C-12: No orphaned classified items

- `_classified/` 각 카테고리의 항목 중 status = `validated` 이상인데 어떤 문서에도 `adopted`로 표시되지 않은 항목
- 장기간 미채택 항목은 잠재적 누락
- **위반:** {category}/{id}가 validated 상태이나 미채택 (30일 이상)
- **수정 제안:** "/u-plan으로 재생성하거나 수동으로 채택하세요"

#### C-13: Backlog items have valid source references

- `_backlog/_index.json`의 각 항목 `source.ref` 확인
- 참조 대상(FR, US, FT, TC, DEF)이 실제 존재하는지 검증
- **위반:** BL-{id}의 source ref "{ref}"가 존재하지 않음
- **자동 수정 가능:** source.ref 클리어 + source.type → "orphaned" (`--fix` 시)

### Step 3: Aggregate Results

검증 결과를 severity별로 분류:

| Severity | Criteria | Gate Impact |
|----------|----------|-------------|
| **Error** | 추적성 단절, 데이터 불일치 | Phase gate 차단 |
| **Warning** | 누락 가능성, 미갱신 | Phase gate 경고 (비차단) |
| **Info** | 개선 권장, 스타일 이슈 | 참고만 |

### Step 4: Generate Report

```markdown
## Sync Report - {app}

**Date:** {ISO 8601}
**Scope:** {app}
**Rules Executed:** {count}/13
**Duration:** {seconds}s

### Summary

| Severity | Count |
|----------|-------|
| Error | {n} |
| Warning | {n} |
| Info | {n} |
| **Total Issues** | **{n}** |

### Detailed Results

#### C-01: FR → US Mapping ✅ PASS
- FR total: {n}, all mapped to ≥1 US

#### C-02: US → FT Mapping ❌ FAIL (2 errors)
| US ID | Issue | Suggestion |
|-------|-------|------------|
| US-0023 | No FT mapped | Create FT for user story |
| US-0041 | No FT mapped | Create FT for user story |

...

### Auto-Fixable Issues: {count}
| Rule | Issue | Fix |
|------|-------|-----|
| C-07 | 3 unregistered files | Add to _index.json |
| C-09 | 2 missing .json | Regenerate from .md |
| C-10 | 1 missing header | Add default Owner |

### Manual Review Required: {count}
| Rule | Issue | Action |
|------|-------|--------|
| C-01 | FR-0042 has no US | /u-add {scope} us --parent FR-0042 |
| C-05 | Payment entity missing in ERD | /u-doc {scope} erd edit |
```

### Step 5: Apply Fixes (--fix)

`--fix` 플래그 사용 시:

1. auto-fixable 항목만 자동 수정
2. 각 수정 후:
   - 대상 파일 저장
   - `.json` 동반 파일 재생성 (해당 시)
   - `_index.json` 갱신
3. 수정 결과 보고:
   ```
   ### Auto-Fix Applied
   | Rule | Fix | Result |
   |------|-----|--------|
   | C-07 | Added 3 files to _index.json | ✅ Done |
   | C-09 | Generated 2 .json files | ✅ Done |
   | C-10 | Added Owner to 1 file | ✅ Done |
   ```
4. manual-review 항목은 수정하지 않음 → 목록만 표시

### Step 6: Display Final Summary

```
## Sync Complete

**Issues Found:** {total}
**Auto-Fixed:** {count} (--fix)
**Remaining:** {count}

### Gate Impact
- Phase gate: {PASS|BLOCKED}
- Blocking errors: {count}

### Next Steps
- Fix remaining issues manually
- Re-run: /u-sync {scope}
- Check gate readiness: /u-gate {scope}
```

---

## --rule Flag

특정 규칙만 실행:

```
/u-sync myapp --rule 1      # C-01만 실행
/u-sync myapp --rule 6,7,9  # C-06, C-07, C-09만 실행
```

---

## Safety Rules

1. `--fix`로 자동 수정 시에도 원본 파일은 변경 전 내용을 로그에 보존
2. manual-review 항목은 `--fix`로도 자동 수정하지 않음
3. 검증 중 문서 읽기 실패 시 해당 규칙 SKIP (다른 규칙은 계속)
4. 동시에 여러 앱을 검증할 수 있음 (scope = all)
5. 결과는 항상 사용자에게 표시 (auto mode에서도 생략 불가)
6. `.json` 재생성 시 기존 `.json`의 커스텀 필드 보존
7. `_index.json`, `_links.json` 갱신 필수
8. Phase gate 판정은 Error severity 기준 (Warning/Info는 비차단)
