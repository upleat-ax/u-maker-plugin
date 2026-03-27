---
name: u-agent-orchestrator
description: |
  Orchestrator 에이전트에게 직접 작업을 요청한다. Phase 관리, 라우팅, 의존성 분석 등.
  Triggers: /u-agent-orchestrator, 오케스트레이터, orchestrator, 전체 조율, 라우팅, phase 관리
version: 2.0.0
user-invocable: true
argument-hint: "자유 형식 작업 요청"
model: opus
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
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
---

# u-agent-orchestrator -- Orchestrator 직접 호출

> Orchestrator 에이전트에게 자유 형식으로 작업을 직접 요청한다.

## 문법

```
/u-agent-orchestrator [자유 형식 요청]
```

## 역할

Orchestrator는 u-maker 시스템의 중앙 조율자로서 다음 역할을 수행한다:

- **Phase 관리** -- 현재 Phase 판단, Gate 조건 확인, 전환 제어
- **요청 라우팅** -- 사용자 요청을 적절한 에이전트/엔진으로 분배
- **의존성 분석** -- 문서/항목 간 의존성 그래프 관리
- **상태 추적** -- 프로젝트 전체 진행 상태 모니터링
- **충돌 해결** -- 에이전트 간 결과 불일치 조정

## 실행 흐름

1. **요청 수신** -- 사용자의 자유 형식 작업 요청 분석
2. **컨텍스트 수집** -- 현재 Phase, 문서 상태, config 확인
3. **작업 수행** -- 요청에 따라 직접 수행 또는 sub-agent 위임
4. **결과 보고** -- Post-Execution Summary 출력

## 적합한 요청 유형

- "현재 프로젝트 상태를 분석해줘"
- "다음 Phase로 넘어갈 수 있는지 확인해줘"
- "FT-0012와 관련된 모든 문서를 찾아줘"
- "SRS 변경 시 영향 범위를 분석해줘"
- "전체 문서 의존성 그래프를 보여줘"

## 규칙

- Orchestrator는 최상위 조율자이므로 모든 Phase에서 활동 가능
- 구체적 Phase 작업은 해당 커맨드(`/u-plan`, `/u-build` 등) 사용 권장
- 자유 형식이므로 요청이 모호할 경우 AskUserQuestion으로 명확화

## 사용 예시

```
/u-agent-orchestrator 현재 PLAN Phase에서 누락된 항목을 분석해줘
/u-agent-orchestrator SRS와 ERD 간 불일치를 찾아줘
/u-agent-orchestrator 전체 프로젝트 의존성 맵을 그려줘
```
