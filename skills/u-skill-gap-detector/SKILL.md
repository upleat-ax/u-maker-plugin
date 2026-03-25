---
name: u-skill-gap-detector
description: |
  설계-구현 Gap 분석을 수행한다. SRS/ERD/API/Screen 설계 vs 실제 코드 비교, Match Rate 산출.
  Triggers: /u-skill-gap-detector, 갭 분석, gap analysis, 설계 구현 비교, design implementation gap, match rate, 커버리지 분석, coverage analysis, 누락 기능, missing feature, 불일치 검사, discrepancy check, 구현 검증
user-invocable: true
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
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
agents:
  u-agent-ra: u-maker:u-agent-ra
  u-agent-qa: u-maker:u-agent-qa
---

# Gap Detector

> 설계 문서와 구현 코드 사이의 Gap을 자동 분석한다.

## Analysis Targets

| Design Document | Comparison Target | Check Items |
|----------------|-------------------|-------------|
| {app}/1_SRS_RA.md | 구현 코드 | 모든 FT 구현 여부 |
| common/2_ERD_SA.md | DB Schema/ORM | Entity, Relationship 일치 |
| {app}/2_API_SA.md | API Route | Endpoint, 스키마 일치 |
| {app}/2_Screen_UX.md | 페이지/컴포넌트 | 화면 구현, 인터랙션 |

## Flow

### Role Division
- **u-agent-ra**: 설계 문서 수집 + 구현 코드 스캔 (SSoT 문서 구조를 알고 있으므로 데이터 수집 담당)
- **u-agent-qa**: 수집된 데이터를 기반으로 설계↔구현 매칭 검사 + Gap 리포트 생성 (품질 검증 전문)

### Steps
1. u-agent-ra: 모든 앱의 SSoT 설계 문서 수집 (SRS, ERD, API, Screen)
2. u-agent-ra: 구현 코드 파일 스캔 (소스, DB 스키마, API 라우트, 페이지)
3. u-agent-qa: 설계 항목별 구현 매칭 검사 (FT, Entity, Endpoint, Screen)
4. Match Rate 산출: 항목 유형별 가중 평균
   - FT 구현 여부: 가중치 40%
   - API Endpoint 일치: 가중치 25%
   - ERD Entity 일치: 가중치 20%
   - Screen 구현 여부: 가중치 15%
   - `Match Rate = Σ(유형별 일치율 × 가중치)`
5. Gap 리포트 생성 → `{app}/04-check/4_GapReport_QA.md` + `.json`

## Output

- **파일명**: `4_GapReport_QA.md` (앱별 생성)
- **경로**: `.u-maker/docs/{app}/04-check/`
- **JSON 쌍**: `4_GapReport_QA.json` 동일 경로에 함께 생성

## Rules

- Match Rate >= 90%: PASS (config의 `gapThreshold`로 변경 가능, 기본 90)
- Match Rate < 90%: FAIL → ACT Phase에서 Gap 항목을 백로그로 전환
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성 (스키마: `json-export.md`)
- Post-Execution Summary Box 출력 필수
