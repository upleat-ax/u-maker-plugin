---
name: u-assume
description: "Assumption 관리. approve/reject 액션으로 가정을 채택하거나 기각한다. 기각 시 영향받는 문서에 cascade re-evaluation을 트리거한다."
triggers:
  - "/u-assume"
  - "assume"
  - "가정"
  - "assumption"
---

# u-assume -- Assumptions Review & Management

`/u-assume [scope] [action] [id] [args]` 명령으로 에이전트가 자동 기록한 가정(Assumption)을 검토하고, 승인 또는 기각한다.

**Primary Agent:** u-agent-orchestrator (engine-validator, engine-dep 사용)

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 자동 선택 |
| `action` | Optional | `approve`, `reject`. 생략 시 목록 표시 |
| `id` | Conditional | 대상 가정 ID (approve/reject 시 필수) |

## Flags

| Flag | Description |
|------|-------------|
| `--all` | 전체 pending 가정 일괄 처리 (approve 전용) |
| `--reason "text"` | 기각 사유 (reject 시 필수) |
| `--confidence X` | 필터: high, medium, low |
| `--agent X` | 필터: 특정 에이전트가 생성한 가정만 |

---

## Assumption Structure

```json
{
  "id": "A-001",
  "agent": "planner",
  "context": "FR-012 payment cancellation scope",
  "question": "Include partial cancellation?",
  "decided": "Yes, include partial",
  "rationale": "Industry standard for e-commerce payment systems",
  "confidence": "medium",
  "impact": ["FR-012", "api.md", "test-cases.md"],
  "status": "pending-review",
  "createdAt": "{ISO 8601}",
  "reviewedAt": null,
  "reviewedBy": null,
  "rejectReason": null
}
```

### Assumption Lifecycle

```
auto-generated → pending-review → approved | rejected
```

| Status | Description |
|--------|-------------|
| `pending-review` | 에이전트가 자동 생성, FDE 검토 대기 |
| `approved` | FDE가 승인, 가정이 사실로 확정 |
| `rejected` | FDE가 기각, cascade re-evaluation 트리거 |

### Auto-Generation Sources

가정이 자동 생성되는 시점:

| Source | Trigger | Example |
|--------|---------|---------|
| `/u-ingest` (auto mode) | classified 데이터 해석 시 불확실한 판단 | "이 요구사항의 scope에 부분 취소 포함?" |
| `/u-plan` (auto mode) | SRS 작성 시 미확인 요건에 대한 판단 | "FR-012는 Must priority로 추정" |
| `/u-design` (auto mode) | 설계 시 명시되지 않은 기술 결정 | "JWT 토큰 만료 시간 30분으로 설정" |
| `/u-dev` (auto mode) | 코드 생성 시 구현 세부사항 결정 | "파일 업로드 최대 크기 10MB" |
| `/u-check` (auto mode) | 테스트 시 기대 동작 추정 | "동시 접속 100명 기준 성능 테스트" |

---

## Execution Flow

### Action: (none) -- List Assumptions

`/u-assume [scope]`

모든 pending-review 가정 표시:

```markdown
## Pending Assumptions - {app}

**Total Pending:** {n} | **By Confidence:** High({n}) Medium({n}) Low({n})

### High Confidence ({count})

| ID | Agent | Context | Question → Decided | Impact |
|----|-------|---------|-------------------|--------|
| A-001 | planner | FR-012 scope | 부분 취소 포함? → Yes | FR-012, api.md, TC |
| A-002 | sa | Auth method | JWT vs Session? → JWT | api.md, code |

### Medium Confidence ({count})

| ID | Agent | Context | Question → Decided | Impact |
|----|-------|---------|-------------------|--------|
| A-005 | planner | NR-003 perf | 응답 시간 기준? → 2초 | NR-003, TC |

### Low Confidence ({count})

| ID | Agent | Context | Question → Decided | Impact |
|----|-------|---------|-------------------|--------|
| A-008 | builder | File upload | 최대 크기? → 10MB | api.md, code |

---

**Actions:**
- Approve: `/u-assume {scope} approve A-001`
- Reject: `/u-assume {scope} reject A-005 --reason "3초로 변경"`
- Approve all high: `/u-assume {scope} approve --all --confidence high`
```

### Action: approve -- Accept Assumption

`/u-assume [scope] approve [id]`

가정을 승인하여 사실로 확정:

1. 대상 가정 읽기
2. status → `approved`
3. `reviewedAt` → 현재 시각
4. `reviewedBy` → "FDE" (사용자)
5. `_assumptions/_index.json` 갱신

**영향 처리:**
- impact 목록의 classified 항목: status 유지 (이미 반영됨)
- 관련 문서의 해당 내용이 가정에 기반했음을 메타데이터에 기록

**확인 메시지:**
```
## Assumption Approved

**ID:** A-001
**Question:** 부분 취소 포함?
**Decided:** Yes, include partial
**Impact:** FR-012, api.md, test-cases.md

No cascade needed (assumption confirmed as-is).
```

### --all 일괄 승인

```
/u-assume myapp approve --all
/u-assume myapp approve --all --confidence high
```

1. 대상 가정 목록 표시
2. 사용자 최종 확인 (Always-Pause)
3. 일괄 status → `approved`
4. 결과 요약 표시

### Action: reject -- Reject Assumption

`/u-assume [scope] reject [id] --reason "사유"`

가정을 기각하고, 영향받는 항목에 cascade re-evaluation 트리거:

1. 대상 가정 읽기
2. `--reason` 필수 검증 (없으면 사용자에게 질문)
3. status → `rejected`
4. `rejectReason` → 사유 기록
5. `reviewedAt` → 현재 시각

### Cascade Re-Evaluation (reject 시)

기각된 가정의 impact 목록에 대해:

1. **Impact 분석:**
   ```markdown
   ## Cascade Impact: A-005 Rejected

   **Rejected:** "응답 시간 2초 이내" → Rejected (사유: "3초로 변경")

   ### Impacted Items
   | Item | Type | Impact | Action Needed |
   |------|------|--------|---------------|
   | NR-003 | Non-Functional Req | 성능 기준 변경 | Update threshold |
   | api.md | Document | 응답 시간 SLA 갱신 | Edit section |
   | test-cases.md | Document | 성능 TC 기준 갱신 | Regenerate TC |
   ```

2. **자동 조치:**
   - 영향받는 문서에 Impact Flag 설정:
     ```json
     {
       "source": "assumption",
       "ref": "A-005",
       "change": "Rejected: '응답 시간 2초 → 3초 변경'",
       "flaggedAt": "{ISO 8601}",
       "severity": "re-evaluation-needed"
     }
     ```
   - `_index.json`에 impact flags 등록
   - 영향받는 classified 항목의 status → `extracted` (re-validation 필요)

3. **수동 조치 안내:**
   ```
   ### Required Actions
   1. Update NR-003: /u-doc {scope} srs edit --section "Non-Functional"
   2. Update api.md: /u-update {scope} api --cascade
   3. Regenerate TC: /u-doc {scope} test-cases regenerate

   Or run /u-sync {scope} to identify all affected areas.
   ```

**확인 메시지:**
```
## Assumption Rejected

**ID:** A-005
**Question:** 응답 시간 기준?
**Was:** 2초 이내
**Reason:** 3초로 변경

### Cascade Actions
- Impact flags set: {count} documents
- Items reverted to extracted: {count}
- Manual actions required: {count}

### Next Steps
- Review impacted docs: /u-status {scope}
- Fix affected items: /u-update {scope} srs --cascade
- Re-validate: /u-sync {scope}
```

---

## Assumption Statistics

`/u-assume [scope]` 실행 시 하단에 통계 표시:

```markdown
### Statistics

| Metric | Value |
|--------|-------|
| Total Assumptions | {n} |
| Pending Review | {n} |
| Approved | {n} |
| Rejected | {n} |
| Approval Rate | {pct}% |
| Avg. Confidence | {high/medium/low} |

### By Agent
| Agent | Total | Pending | Approved | Rejected |
|-------|-------|---------|----------|----------|
| planner | 8 | 2 | 5 | 1 |
| sa | 5 | 1 | 4 | 0 |
| builder | 3 | 1 | 1 | 1 |
| guardian | 2 | 0 | 2 | 0 |
```

---

## maxAssumptions Enforcement

`u-maker.config.json` → `interaction.maxAssumptions` (기본 20):

- pending-review 가정이 maxAssumptions에 도달하면:
  - auto mode 에이전트는 더 이상 가정 생성 불가
  - "가정 한도 도달. /u-assume으로 검토해주세요" 경고
  - 에이전트는 해당 분기에서 일시 중지 (사용자 입력 대기)

---

## Safety Rules

1. reject 시 `--reason` 필수 (사유 없는 기각 불가)
2. approved 가정은 이후 reject 불가 (새 가정으로 재기록)
3. rejected 가정의 cascade는 자동 수행 (Impact Flag 설정)
4. cascade 중 실제 문서 수정은 자동 수행하지 않음 (Flag만 설정)
5. `--all` 일괄 승인은 반드시 사용자 확인 필수 (Always-Pause)
6. 가정 ID 재사용 금지 (삭제된 ID도 재할당 없음)
7. `_assumptions/_index.json` 갱신 필수
8. maxAssumptions 한도 초과 시 에이전트 자동 진행 차단
