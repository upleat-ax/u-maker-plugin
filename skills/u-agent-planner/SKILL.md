---
name: u-agent-planner
description: |
  Planner 에이전트에게 직접 분석/설계 작업을 요청한다. SRS, IA, ERD, API, Screen 등.
  Triggers: /u-agent-planner, 플래너, planner, 분석, 설계, 기획, 아키텍처
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
  u-agent-planner: u-maker:u-agent-planner
---

# u-agent-planner -- Planner 직접 호출

> Planner 에이전트에게 자유 형식으로 분석/설계 작업을 직접 요청한다.

## 문법

```
/u-agent-planner [자유 형식 요청]
```

## 역할

Planner는 분석과 설계를 담당하는 에이전트로서 다음 역할을 수행한다:

- **요구사항 분석** -- FR, NR, US, FT 도출 및 정리
- **SRS 작성** -- Software Requirements Specification 문서 생성/갱신
- **IA 설계** -- 정보 구조도(Information Architecture) 설계
- **ERD 설계** -- 엔티티-관계 다이어그램 설계
- **API 설계** -- RESTful API Contract 정의
- **Screen 설계** -- 화면 명세 작성
- **Roadmap 작성** -- 마일스톤 및 릴리스 계획

## 실행 흐름

1. **요청 수신** -- 사용자의 분석/설계 요청 분석
2. **컨텍스트 수집** -- 기존 문서, classified 데이터 확인
3. **작업 수행** -- 요청에 따라 문서 생성/갱신/분석
4. **결과 보고** -- Post-Execution Summary 출력

## 적합한 요청 유형

- "결제 모듈의 ERD를 설계해줘"
- "US-0008을 더 세분화된 FT로 분해해줘"
- "API Contract에 파일 업로드 엔드포인트를 추가해줘"
- "IA에서 관리자 섹션 구조를 재설계해줘"
- "Roadmap v2.0 마일스톤을 작성해줘"

## 규칙

- 문서 생성/갱신 시 SSoT 표준 준수 필수
- 모든 산출물은 `.md` + `.json` 동시 생성
- 추적 체계(USR→FR→US→FT) 유지 필수

## 사용 예시

```
/u-agent-planner 사용자 인증 모듈의 SRS를 작성해줘
/u-agent-planner IA에 설정 페이지 하위 구조를 추가해줘
/u-agent-planner FR-0003의 유저 스토리를 도출해줘
```
