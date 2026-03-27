# Assumptions Specification

> Auto 모드에서 agent가 내린 판단을 기록하고 관리하는 Assumptions Log의 스키마, lifecycle, 관리 규칙.

---

## 1. Purpose

Auto 모드에서 agent는 질문 대신 best-guess로 판단한다. 이 판단을 Assumptions Log에 기록하여:
- FDE가 나중에 한꺼번에 리뷰 가능
- 잘못된 판단 발견 시 cascade 수정 가능
- 판단 근거가 명시되어 추후 감사 가능

---

## 2. Assumption Schema

```json
{
  "id": "A-001",
  "agent": "planner | builder | guardian",
  "phase": "plan | design | do | check | act",
  "context": "판단이 필요한 상황 설명",
  "question": "실제 질문했어야 할 내용",
  "decided": "agent가 내린 결정",
  "rationale": "결정 근거",
  "alternatives": ["대안 1", "대안 2"],
  "confidence": "high | medium | low",
  "impact": ["영향받는 문서/항목 ID 목록"],
  "status": "pending-review | approved | rejected | superseded",
  "createdAt": "ISO 8601",
  "reviewedAt": null,
  "reviewedBy": null,
  "reviewNote": null
}
```

---

## 3. Lifecycle

```
pending-review → approved
                → rejected → cascade update 트리거
                → superseded (새 assumption으로 대체)
```

### Status 정의

| Status | 의미 |
|--------|------|
| pending-review | 미검토. FDE 리뷰 필요 |
| approved | FDE가 승인. 현재 결정 유지 |
| rejected | FDE가 거부. impact 문서 cascade 수정 필요 |
| superseded | 이후 assumption이 이 결정을 대체 |

---

## 4. 관리 규칙

### 기록 시점
- 2개 이상 선택지가 있을 때
- classified에 없는 정보를 기반으로 판단할 때
- 기존 산출물과 충돌하는 결정을 할 때
- 우선순위를 임의로 판단할 때

### ID 규칙
- `A-{NNN}` 형식. 앱별 독립 시퀀스.
- 저장 위치: `apps/{app}/_assumptions/_index.json` 또는 `_assumptions/_index.json` (cross-app)

### maxAssumptions
- config의 `maxAssumptions` (default: 20) 초과 시 자동 interactive 전환
- 초과 시 메시지: "Auto 모드에서 {N}개의 가정을 했습니다. 불확실성이 높아 interactive 모드로 전환합니다."

---

## 5. Commands

### /u-assume [scope] approve [id]
- status → approved, reviewedAt 기록

### /u-assume [scope] reject [id] "사유"
- status → rejected, reviewNote 기록
- impact 목록의 문서에 cascade 수정 요청 생성
- engine-dep이 영향 범위 계산

### /u-status --assumptions
- pending-review 목록 표시
- confidence별 분류
