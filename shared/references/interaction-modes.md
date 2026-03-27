# Interaction Modes

> auto / interactive / step 3가지 실행 모드의 정의와 동작 규칙.

---

## 1. 3가지 Mode

| Mode | Flag | 동작 | 사용 시점 |
|------|------|------|-----------|
| **auto** | (default) | 질문 없이 끝까지 실행. 애매한 판단은 best-guess + assumptions log 기록. | 일반 작업, 야간 배치 |
| **interactive** | `-i` | 판단 분기에서만 pause. 단순 실행은 auto 속도. 중간에 "나머지 auto로" 전환 가능. | 중요 의사결정, 아키텍처 설계 |
| **step** | `--step` | 매 단계에서 pause. 결과 보여주고 승인 받음. | 최초 세팅, 학습, 디버깅 |

---

## 2. Pause Matrix

| Situation | auto | interactive | step |
|-----------|------|-------------|------|
| 단순 문서 생성 | skip | skip | pause |
| 2개 이상 선택지 | best-guess + log | pause + ask | pause + ask |
| classified에 없는 정보 | skip + log gap | pause + ask | pause + ask |
| 기존 산출물과 충돌 | log conflict | pause + ask | pause + ask |
| 우선순위 판단 | 기존 규칙 적용 + log | pause + ask | pause + ask |
| **Phase gate 실패** | **pause (항상)** | **pause (항상)** | **pause (항상)** |
| **파괴적 변경** | **pause (항상)** | **pause (항상)** | **pause (항상)** |

### Always-Pause 상황 (모든 모드에서)

1. **gate-failure**: Phase gate 검증 실패
2. **destructive-change**: 기존 산출물 대량 변경/삭제
3. **scope-change**: 요청 범위가 현재 앱을 넘어감

---

## 3. Auto Mode — Assumptions Log

auto 모드의 핵심 안전장치. agent가 "질문 대신 판단"할 때마다 기록.

### Assumption 스키마

```json
{
  "id": "A-001",
  "agent": "planner",
  "context": "FR-012 결제 취소 범위",
  "question": "부분취소 포함 여부",
  "decided": "부분취소 포함",
  "rationale": "업계 관행상 부분취소가 일반적",
  "confidence": "medium",
  "impact": ["FR-012", "api.md", "test-cases.md"],
  "status": "pending-review",
  "createdAt": "2026-03-27T10:00:00Z"
}
```

### Confidence Levels

| Level | 의미 | 후속 조치 |
|-------|------|-----------|
| high | 업계 표준 또는 명확한 근거 | 로그만 기록 |
| medium | 합리적 추론이나 확인 필요 | /u-status에 표시 |
| low | 추측. 다른 선택도 가능 | /u-status에 경고 표시 |

### maxAssumptions 초과 시

config의 `maxAssumptions` (default: 20) 초과 시 자동으로 interactive 전환.
이는 input 부족/모호 상태에서 억지로 밀어붙이기를 방지한다.

---

## 4. Interactive Mode 동작

1. 판단 분기 도달 시 선택지 + 분석 결과 제시
2. FDE의 선택 대기
3. 선택 후 다음 분기까지 auto 속도로 실행
4. 중간에 "나머지 auto로" 전환 가능

---

## 5. Step Mode 동작

1. 각 단계 시작 전 계획 제시
2. FDE 승인 후 실행
3. 결과 보여주고 다음 단계 대기
4. 스킵 가능: "다음 3단계 자동으로"

---

## 6. Config

```json
{
  "interaction": {
    "defaultMode": "auto",
    "alwaysPause": ["gate-failure", "destructive-change", "scope-change"],
    "assumptionsLog": true,
    "maxAssumptions": 20
  }
}
```
