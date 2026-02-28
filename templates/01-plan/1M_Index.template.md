---
document: "1M_Index"
title: "{{PROJECT_NAME}} Document Index"
owner: "u-M"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - "u-docs/01-plan/1PM_Roadmap.md"
  - "u-docs/01-plan/1A_SRS.md"
  - "u-docs/01-plan/1CX_IA.md"
external_links: []
---

# {{PROJECT_NAME}} Document Index

## 1. Background

### 1.1 Purpose

이 문서는 프로젝트의 모든 SSoT 문서를 중앙에서 추적하고 관리하는 마스터 인덱스이다.
`u-M` (Master/SSoT Guardian) 에이전트가 유지 관리한다.

### 1.2 Current State

| Key | Value |
|-----|-------|
| Project | {{PROJECT_NAME}} |
| Current Phase | PLAN |
| Current Iteration | 1 |
| Loop Status | STOPPED |
| Total Documents | 0 / 13 |
| Final Documents | 0 / 13 |

---

## 2. Document Registry

### 2.1 PLAN Phase (01-plan/)

| Doc ID | Document | Path | Owner | Status | Version | Last Updated |
|--------|----------|------|-------|--------|---------|-------------|
| 1PM_Roadmap | Roadmap | `u-docs/01-plan/1PM_Roadmap.md` | u-PM | Draft | v0.1.0 | {{DATE}} |
| 1A_SRS | SRS | `u-docs/01-plan/1A_SRS.md` | u-A | - | - | - |
| 1CX_IA | IA | `u-docs/01-plan/1CX_IA.md` | u-CX | - | - | - |
| 1M_Index | Index | `u-docs/01-plan/1M_Index.md` | u-M | Draft | v0.1.0 | {{DATE}} |

### 2.2 DESIGN Phase (02-design/)

| Doc ID | Document | Path | Owner | Status | Version | Last Updated |
|--------|----------|------|-------|--------|---------|-------------|
| 2A_ERD | ERD | `u-docs/02-design/2A_ERD.md` | u-A | - | - | - |
| 2A_API | API Contract | `u-docs/02-design/2A_API.md` | u-A | - | - | - |
| 2CX_Screen | Screen Design | `u-docs/02-design/2CX_Screen.md` | u-CX | - | - | - |

### 2.3 DEV Phase (03-dev/)

| Doc ID | Document | Path | Owner | Status | Version | Last Updated |
|--------|----------|------|-------|--------|---------|-------------|
| 3DV_Code | Code Record | `u-docs/03-dev/3DV_Code.md` | u-DV | - | - | - |

### 2.4 CHECK Phase (04-check/)

| Doc ID | Document | Path | Owner | Status | Version | Last Updated |
|--------|----------|------|-------|--------|---------|-------------|
| 4QA_Case | Test Cases | `u-docs/04-check/4QA_Case.md` | u-QA-A | - | - | - |
| 4QA_Report | QA Report | `u-docs/04-check/4QA_Report.md` | u-QA-T | - | - | - |

### 2.5 ACT Phase (05-act/)

| Doc ID | Document | Path | Owner | Status | Version | Last Updated |
|--------|----------|------|-------|--------|---------|-------------|
| 5ACT_Backlog | Backlog | `u-docs/05-act/5ACT_Backlog.md` | u-M | - | - | - |
| 5ACT_Iteration_Log | Iteration Log | `u-docs/05-act/5ACT_Iteration_Log.md` | u-PM | - | - | - |
| 5ACT_Retrospective | Retrospective | `u-docs/05-act/5ACT_Retrospective.md` | Team | - | - | - |

---

## 3. Phase Gate Status

| Gate | From → To | Conditions | Status |
|------|-----------|-----------|--------|
| Gate 1 | PLAN → DESIGN | `1PM_Roadmap`=Final, `1A_SRS`=Final, `1CX_IA`=Final | Not Ready |
| Gate 2 | DESIGN → DO | `2A_ERD`=Final, `2A_API`=Final, `2CX_Screen`=Final + u-M 검수 | Not Ready |
| Gate 3 | DO → CHECK | 코드 구현 완료 + `bun run build` 성공 | Not Ready |
| Gate 4 | CHECK → Complete | Critical/Major 0건 + Backlog 0건 + 전체 FR 구현 | Not Ready |
| Gate 5 | ACT → PLAN(N+1) | Backlog 정리 + 회고 + 아카이브 완료 | Not Ready |

---

## 4. FR Implementation Tracking

| FR-ID | Feature | SRS | ERD | API | Screen | Code | QA | Status |
|-------|---------|-----|-----|-----|--------|------|----|--------|
| FR-001 | {{기능명}} | - | - | - | - | - | - | Planned |
| FR-002 | {{기능명}} | - | - | - | - | - | - | Planned |

---

## 5. Iteration History

| Iteration | Start Date | End Date | Phase Reached | Result | Backlog Items |
|-----------|-----------|---------|---------------|--------|--------------|
| Iter 1 | {{DATE}} | - | PLAN | In Progress | 0 |

---

## 6. Validation Log

| Date | Validator | Type | Result | Issues |
|------|-----------|------|--------|--------|
| {{DATE}} | u-M | Initial | - | No documents yet |

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-M | Initial index created |
