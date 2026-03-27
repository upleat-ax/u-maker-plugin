---
name: u-plan
description: |
  PLAN Phase 문서 연쇄 생성. classified 데이터 기반 SRS + IA + Roadmap 자동 생성.
  Triggers: /u-plan, 계획, 기획, plan, SRS, IA, 로드맵, roadmap, 요구사항 분석
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [-i] [--step] [--only srs|ia|roadmap]"
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
  - ${PLUGIN_ROOT}/templates/01-plan/srs.template.md
  - ${PLUGIN_ROOT}/templates/01-plan/ia.template.md
  - ${PLUGIN_ROOT}/templates/01-plan/roadmap.template.md
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-plan -- PLAN Phase 문서 생성

> classified 데이터를 기반으로 SRS, IA, Roadmap을 연쇄 생성한다.

## 문법

```
/u-plan [scope] [-i] [--step] [--only srs|ia|roadmap]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 자동 감지)

## Flags

| Flag | 설명 |
|------|------|
| `-i` | 대화형 모드. 각 단계마다 사용자 확인 |
| `--step` | 단계별 실행. 한 문서 생성 후 중단 |
| `--only` | 특정 문서만 생성: `srs`, `ia`, `roadmap` |

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **입력 확인** -- `_classified/` 데이터 존재 여부 검증
3. **발산 단계** -- Problems/Solutions 도출
4. **수렴 단계** -- FR(기능 요구사항) + NR(비기능 요구사항) 정리
5. **SRS 생성** -- engine-doc + srs.template.md 기반
   - USR(사용자 유형), FR, NR, US(유저 스토리), FT(기능 단위) 정의
6. **IA 생성** -- 정보 구조도(Information Architecture) 도출
7. **WF 생성** -- Wireframe (PLAN Phase에서 수행)
8. **Roadmap 생성** -- 마일스톤 및 릴리스 계획
9. **일관성 검증** -- engine-validator로 문서 간 정합성 확인
10. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-workflow-runner | 연쇄 생성 오케스트레이션 |
| engine-doc | 문서 생성/갱신 |
| engine-designer | 구조 설계 |
| engine-estimator | 공수 산정 |
| engine-validator | 일관성 검증 |

## 에이전트 시퀀스

```
orchestrator → planner (문서 생성) → guardian (자동 검증)
```

## 추적 체계

- USR-XXXX → FR-XXXX → US-XXXX → FT-XXXX (상위→하위)
- FT가 구현 추적의 기본 단위

## 규칙

- `_classified/` 데이터가 없으면 `/u-ingest` 실행을 안내
- 모든 문서는 `.md` + `.json` 동시 생성
- SRS의 FR/NR은 반드시 `_classified/` 데이터와 연결
- Phase Gate: PLAN 완료 조건 = SRS + IA + Roadmap 모두 Approved

## 사용 예시

```
/u-plan my-app
/u-plan my-app --only srs
/u-plan -i --step
```
