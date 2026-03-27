---
name: u-agent-guardian
description: |
  Guardian 에이전트에게 직접 검증/QA 작업을 요청한다. 테스트, 일관성 검증, 품질 분석 등.
  Triggers: /u-agent-guardian, 가디언, guardian, 검증, QA, 테스트, 품질, 일관성
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
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-agent-guardian -- Guardian 직접 호출

> Guardian 에이전트에게 자유 형식으로 검증/QA 작업을 직접 요청한다.

## 문법

```
/u-agent-guardian [자유 형식 요청]
```

## 역할

Guardian은 품질 보증과 검증을 담당하는 에이전트로서 다음 역할을 수행한다:

- **테스트 케이스 설계** -- FT/US 기반 TC 자동 생성
- **테스트 실행** -- Unit, Integration, E2E 테스트 수행
- **일관성 검증** -- 문서 간 cross-reference 무결성 확인
- **Gate 검증** -- Phase Gate 조건 충족 여부 판정
- **결함 분석** -- 테스트 실패 원인 분석 + 수정 방향 제시
- **QA 리포트** -- 테스트 결과 + 커버리지 리포트 생성

## 실행 흐름

1. **요청 수신** -- 사용자의 검증/QA 요청 분석
2. **대상 파악** -- 검증 대상 문서/코드 식별
3. **검증 수행** -- 요청에 따라 테스트/검증 실행
4. **결과 분석** -- Pass/Fail 집계, 결함 분류
5. **결과 보고** -- Post-Execution Summary 출력

## 적합한 요청 유형

- "FT-0012에 대한 테스트 케이스를 설계해줘"
- "SRS와 ERD 간 일관성을 검증해줘"
- "현재 CHECK Phase exit criteria를 확인해줘"
- "최근 테스트 실패 원인을 분석해줘"
- "전체 TC 커버리지 리포트를 생성해줘"

## 규칙

- 결함 severity 분류 필수: Critical, Major, Minor, Trivial
- QA Report는 `.md` + `.json` + `.html` 3종 생성
- 검증 결과는 객관적 근거와 함께 제시

## 사용 예시

```
/u-agent-guardian 인증 모듈 관련 TC를 전부 설계해줘
/u-agent-guardian SRS v1.2 변경 후 전체 일관성을 검증해줘
/u-agent-guardian CHECK Phase Gate 조건을 확인해줘
```
