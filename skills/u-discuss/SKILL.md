---
name: u-discuss
description: |
  다자간 토론 세션. brainstorm, review, decision, workshop, retro 모드 지원.
  Triggers: /u-discuss, 토론, 논의, discuss, brainstorm, 리뷰, 워크숍, workshop, 회의
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [type] \"topic\" [--wrap]"
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
  - ${PLUGIN_ROOT}/skills/u-discuss/references/discuss-protocols.md
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-discuss -- 토론 세션

> 다자간 에이전트 토론 세션을 진행한다. 브레인스토밍, 리뷰, 의사결정 등을 지원한다.

## 문법

```
/u-discuss [scope] [type] "topic" [--wrap]
```

- `scope`: 앱 이름 | `common` (생략 시 자동 감지)
- `type`: 세션 유형
- `topic`: 토론 주제 (큰따옴표)

## 세션 유형

| Type | 설명 | 특성 |
|------|------|------|
| `brainstorm` | 아이디어 발산 | 자유 발언, 비판 금지 |
| `review` | 산출물 리뷰 | 구조적 피드백, 액션 아이템 |
| `decision` | 의사결정 | 선택지 비교, 투표, 결론 |
| `workshop` | 협업 작업 | 실시간 공동 작업 |
| `retro` | 회고 | 잘한 점/개선점/액션 |

## Micro-commands (세션 내 사용)

| Command | 설명 |
|---------|------|
| `@planner` | Planner 에이전트 의견 요청 |
| `@builder` | Builder 에이전트 의견 요청 |
| `@guardian` | Guardian 에이전트 의견 요청 |
| `@all` | 모든 에이전트 의견 요청 |
| `/idea` | 새 아이디어 등록 |
| `/decide` | 결정 사항 기록 |
| `/concern` | 우려 사항 등록 |
| `/action` | 액션 아이템 등록 |

## Flags

| Flag | 설명 |
|------|------|
| `--wrap` | 세션 종료 후 결과를 `_classified/`에 적재 |

## 실행 흐름

1. **세션 시작** -- 유형 + 주제 확인, 프로토콜 로드
2. **참여 에이전트 설정** -- engine-facilitator로 초기 참여자 결정
3. **토론 진행** -- Micro-command 기반 대화 루프
4. **결과 정리** -- 아이디어, 결정, 우려, 액션 분류 수집
5. **세션 종료** -- 요약 리포트 생성
6. **Classified 적재** (--wrap) -- 결과를 `_classified/`에 구조화 저장
7. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-facilitator | 세션 관리 + 발언권 조율 |

## 에이전트 시퀀스

```
orchestrator → (planner/builder/guardian via @ mentions)
```

## 규칙

- 세션 내 모든 발언은 로그로 기록
- brainstorm 모드에서는 비판/부정적 피드백 자제
- decision 모드에서는 반드시 결론(decision) 도출
- --wrap 시 classified 항목에 세션 ID 태그 부여

## 사용 예시

```
/u-discuss my-app brainstorm "결제 시스템 아키텍처"
/u-discuss review "SRS v1.2 리뷰" --wrap
/u-discuss decision "DB 선택: PostgreSQL vs MySQL"
```
