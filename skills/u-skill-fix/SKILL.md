---
name: u-skill-fix
description: |
  버그/기능을 수정한다. 코드를 fix한 후, 백그라운드에서 QA 에이전트가 해당 수정 사항에 대한 TC가
  4_Case_QA.md에 존재하는지 확인하고, 없으면 자동으로 TC를 추가한다.
  Args: `[app] [FT-NNNN|description]` — 앱 이름 + 수정 대상 FT 또는 설명 (생략 시 대화형 입력)
  Triggers: /u-skill-fix, 버그 수정, fix, bug fix, 수정, hotfix, patch
user-invocable: true
argument-hint: "[app] [FT-NNNN|description]"
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/tech-stack-rules.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  u-agent-dv-fe: u-maker:u-agent-dv-fe
  u-agent-dv-be: u-maker:u-agent-dv-be
  u-agent-qa: u-maker:u-agent-qa
---

# Fix

> 버그/기능을 수정하고, 백그라운드에서 QA 에이전트가 TC 커버리지를 자동 보장한다.

## Syntax

```
/u-skill-fix [app] [FT-NNNN|description]
```

- `[app]`: 멀티앱 프로젝트 시 앱 이름 (e.g., `web`). 단일앱이면 생략 가능
- `[FT-NNNN|description]`: 수정 대상 FT ID 또는 자연어 버그 설명 (생략 시 대화형 입력)

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Flow

```
1. App Context 결정 (단일앱 자동선택 / 멀티앱 인자 또는 AskUserQuestion)
2. 수정 대상 파악
   ├── FT-NNNN 제공 → 1_SRS_RA.md에서 FT 상세 확인
   └── 자연어 설명 → 관련 코드/문서 탐색하여 수정 범위 결정
3. 관련 코드 분석 (소스 파일, API, 컴포넌트 등)
4. **[Foreground] 코드 수정 실행**
   ├── Frontend 관련 → u-agent-dv-fe 호출
   ├── Backend 관련 → u-agent-dv-be 호출
   └── 복합 → 순차 호출 (BE → FE)
5. 수정 완료 후 빌드 검증: `bun run build`
6. **[Background] QA TC 커버리지 확인** (Agent tool, run_in_background=true)
   ├── 4_Case_QA.md에서 해당 FT의 TC 존재 여부 확인
   ├── TC 없음 → 수정 내용 기반으로 TC 자동 추가
   │   ├── Positive TC (수정된 기능이 정상 동작하는지)
   │   └── Negative TC (수정 전 버그 재현 시나리오)
   └── TC 있음 → 기존 TC가 수정 내용을 커버하는지 검토, 부족 시 보강
7. Post-Execution Summary Box 출력
```

## Background QA Task Detail

백그라운드 QA 에이전트에게 전달할 컨텍스트:

| Field | Description |
|-------|-------------|
| App | 대상 앱 이름 |
| FT | 수정 대상 FT-NNNN (있는 경우) |
| Fix Description | 수정 내용 요약 |
| Changed Files | 변경된 파일 목록 |
| Bug Description | 원래 버그/이슈 설명 |

QA 에이전트는 다음을 수행한다:

1. `{app}/04-check/4_Case_QA.md` 읽기
2. 해당 FT에 대한 기존 TC 검색
3. TC가 없거나 수정 내용을 커버하지 못하면:
   - TC-ID 자동 채번 (10단위)
   - Positive TC: 수정된 기능의 정상 동작 검증
   - Negative TC: 수정 전 버그가 재발하지 않는지 회귀 검증
   - 4_Case_QA.md에 TC 추가 (testCases 테이블 + Detail 블록)
   - coverageMatrix 갱신
   - 동명의 `.json` 파일 동기화
   - `_links.json` qa 필드 갱신
   - Change Log 갱신
4. 4_Case_QA.md가 존재하지 않으면 u-skill-tc-add의 Template 사용하여 자동 생성

## Rules

- 기술 스택 규칙 강제 (상세: `tech-stack-rules.md`). 위반 시 거부
- 수정 전 반드시 관련 코드를 읽고 이해한 후 수정
- 수정 범위를 최소화 — 요청된 버그/기능만 수정, 불필요한 리팩토링 금지
- 빌드 검증 실패 시 수정 코드를 재조정
- QA 백그라운드 태스크는 코드 수정과 독립적으로 실행 (코드 수정 완료를 기다리지 않음 — 단, fix 내용 요약은 전달)
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
