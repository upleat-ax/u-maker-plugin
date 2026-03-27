---
name: u-sync
description: |
  전체 문서 일관성 검증 + 불일치 자동 수정 제안.
  Triggers: /u-sync, 동기화, sync, 일관성, consistency, 정합성, 문서 동기화
version: 2.0.0
user-invocable: true
argument-hint: "[scope]"
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/shared/references/ssot-standard.md
  - ${PLUGIN_ROOT}/shared/references/post-execution-summary.md
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-sync -- 문서 일관성 동기화

> 전체 SSoT 문서 간 일관성을 검증하고 불일치를 자동 수정 제안한다.

## 문법

```
/u-sync [scope]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 전체 검사)

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 범위 결정
2. **문서 수집** -- 대상 범위 내 모든 SSoT 문서 로드
3. **ID 참조 검증** -- engine-validator로 cross-reference 무결성 확인
   - FR → US → FT 체인 완전성
   - Screen ↔ IA 매핑 완전성
   - TC ↔ FT 매핑 완전성
   - API ↔ ERD 엔티티 참조 정합성
4. **MD/JSON 동기화** -- `.md`와 `.json` 내용 일치 여부
5. **불일치 목록 생성** -- 유형별 불일치 분류
   - `MISSING_REF`: 참조 대상 부재
   - `ORPHAN`: 어디서도 참조되지 않는 항목
   - `MISMATCH`: md/json 내용 불일치
   - `STATUS_CONFLICT`: 하위가 Approved인데 상위가 Draft
6. **수정 제안** -- 각 불일치에 대한 자동 수정안 제시
7. **사용자 승인** -- AskUserQuestion으로 수정 적용 여부 확인
8. **일괄 수정** -- 승인된 항목 자동 갱신
9. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-validator | 일관성 검증 |
| engine-dep | 의존성 그래프 분석 |

## 에이전트 시퀀스

```
orchestrator → guardian (검증 + 수정 제안)
```

## 규칙

- 자동 수정은 사용자 승인 없이 적용하지 않음
- 검증 결과는 severity(ERROR/WARNING/INFO) 분류
- ERROR는 반드시 수정, WARNING은 권장, INFO는 참고

## 사용 예시

```
/u-sync my-app
/u-sync all
/u-sync
```
