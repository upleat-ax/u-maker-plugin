---
name: engine-facilitator
description: |
  /u-discuss 세션을 관리하고, 마이크로 커맨드 파싱,
  세션 직렬화/복원, 결과물 파이프라인 분류를 수행하는 토론 촉진 엔진.
version: 2.0.0
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
imports: []
---

# Engine: Facilitator

> /u-discuss 기반 협업 세션을 관리하고 토론 결과를 구조화된 산출물로 분류한다.

## 역할

- 5가지 세션 유형 관리: brainstorm, review, decision, workshop, retro
- 마이크로 커맨드 파싱 및 실행
- 세션 컨텍스트 직렬화/복원 (pause/resume)
- 세션 종료 시 결과물을 분류된 파이프라인으로 변환

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | 세션 유형, 참여 역할, 사용자 발언 + 마이크로 커맨드 |
| **Output** | `{ sessionLog, classifiedItems[], decisions[], actions[] }` |

## 세션 유형

| 유형 | 목적 | 기본 참여자 |
|------|------|-----------|
| `brainstorm` | 자유 아이디어 발산 | @all |
| `review` | 산출물 검토 및 피드백 | @guardian, @planner |
| `decision` | 의사결정 및 합의 도출 | @planner, @builder |
| `workshop` | 특정 주제 심층 작업 | 주제별 지정 |
| `retro` | 회고 및 개선점 도출 | @all |

## 마이크로 커맨드

### 역할 지정
| 커맨드 | 설명 |
|--------|------|
| `@planner` | PM/RA/SA 관점 발언 요청 |
| `@builder` | FE/BE 개발 관점 발언 요청 |
| `@guardian` | QA/검증 관점 발언 요청 |
| `@all` | 모든 역할 순차 발언 |

### 세션 제어
| 커맨드 | 설명 |
|--------|------|
| `/idea` | 아이디어 등록 → requirements 분류 |
| `/decide` | 결정 사항 기록 → decisions 분류 |
| `/concern` | 우려/위험 등록 → constraints 분류 |
| `/action` | 액션 아이템 등록 → TODO 플래그 |
| `/next-phase` | 다음 토론 단계 전환 |
| `/pause` | 세션 일시중지 + 컨텍스트 저장 |
| `/resume` | 저장된 세션 복원 |

## 실행 절차

### Step 1. 세션 초기화

1. 세션 유형 결정 (사용자 지정 또는 컨텍스트 기반 추론)
2. 참여 역할 배정
3. 세션 ID 생성: `discuss-{type}-{timestamp}`
4. 세션 로그 파일 생성: `.u-maker/.sessions/{sessionId}.json`

### Step 2. 발언 처리 루프

각 사용자 입력에 대해:
1. 마이크로 커맨드 여부 확인
2. 커맨드이면 → 해당 액션 실행
3. 일반 발언이면 → 역할 관점 응답 생성
4. 세션 로그에 발언 기록 (역할, 내용, 타임스탬프)

### Step 3. 세션 일시중지 (`/pause`)

컨텍스트 직렬화:
```json
{
  "sessionId": "discuss-brainstorm-20260327",
  "type": "brainstorm",
  "status": "paused",
  "participants": ["planner", "builder"],
  "log": [...],
  "classifiedItems": [...],
  "resumePoint": "step-3"
}
```

### Step 4. 세션 종료 및 결과 분류

세션 wrap 시 수집된 항목을 분류 파이프라인으로 변환:

| 마이크로 커맨드 | 분류 대상 | 후속 처리 |
|----------------|----------|----------|
| `/idea` | requirements | FR 후보로 등록 |
| `/decide` | decisions | 의사결정 로그 기록 |
| `/concern` | constraints | NFR/리스크 항목 등록 |
| `/action` | TODO flags | 백로그 항목 생성 |

## 오류 처리

| 상황 | 처리 |
|------|------|
| 미인식 마이크로 커맨드 | 사용 가능 커맨드 목록 출력 |
| /resume 시 세션 미존재 | 사용 가능한 세션 목록 제시 |
| 세션 파일 손상 | 마지막 정상 체크포인트로 복원 시도 |
| 역할 충돌 | 우선순위 기반 발언 순서 조정 |

## 연동

- **호출원**: orchestrator (`/u-discuss` 커맨드)
- **호출 대상**: 에이전트 역할별 응답 생성 (u-agent-pm, u-agent-sa 등)
- **의존 엔진**: engine-doc (결과물 문서화 시)
