---
Owner: u-m
Status: Draft
Version: 1.0.0
Last Updated: 2026-03-01
---

# Project Summary

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 프로젝트명 | u-Agent SSoT |
| 목표 | PDCA 사이클 기반 SSoT 소프트웨어 개발 협업 자동화 Claude Code Plugin |
| 기술 스택 | Next.js App Router, react-query, Prisma/Drizzle, Turborepo, bun |
| 에이전트 | 9개 전문 에이전트 (u-pm, u-m, u-a, u-cx, u-dv-fe, u-dv-be, u-qa-a, u-qa-t, u-qa-n) |
| 리포지토리 | u-ssot (main branch) |

## 플러그인 구조

| 구성 요소 | 수량 | 설명 |
|-----------|------|------|
| Agents | 9 | 전문 역할별 에이전트 (PM, Master, Architect, CX, FE/BE Dev, QA x3) |
| Slash Commands | 30+ | Lifecycle, Loop, Document, Agent, Utility 명령어 |
| Templates | 13 | SSoT 문서 템플릿 (01-plan ~ 05-act) |
| References | 7 | 표준 규격, 기술 스택, PDCA 워크플로우 등 참조 문서 |
| Scripts | 6 | 프로젝트 초기화, SSoT 검증, 종료 조건 확인 자동화 |
| Hooks | 2 | SessionStart, PreToolUse(Write/Edit) |

## 주요 기능 (Features)

- **PDCA 자동화**: Plan-Design-Do-Check-Act 사이클 자동 반복
- **SSoT 문서 체계**: u-docs/ 기반 단일 진실 원천 문서 관리
- **Phase Gate**: 각 Phase 전환 시 Gate 조건 자동 검증
- **9 Agent 협업**: 역할별 전문 에이전트가 문서 생성/검수/개발 수행
- **기술 스택 강제**: 10가지 코딩 규칙 PreToolUse hook으로 자동 차단
- **Gap Detector**: 설계-구현 Gap 분석 및 Match Rate 산출
- **Iteration Loop**: 종료 조건 충족까지 PDCA 사이클 자동 반복 (최대 10회)

## 개발 상태

| 항목 | 상태 |
|------|------|
| Iteration | 1 / 10 |
| 현재 Phase | PLAN |
| Loop Status | STOPPED |
| FR 진행률 | - (SRS 미작성) |
| 빌드 | - (대상 프로젝트 미생성) |
| Open 결함 | - |
| 백로그 | - |

## 문서 현황

| Phase | 문서 | Owner | 상태 |
|-------|------|-------|------|
| PLAN | 1PM_Roadmap.md | u-pm | - |
| PLAN | 1A_SRS.md | u-a | - |
| PLAN | 1CX_IA.md | u-cx | - |
| PLAN | 1M_Index.md | u-m | - |
| DESIGN | 2A_ERD.md | u-a | - |
| DESIGN | 2A_API.md | u-a | - |
| DESIGN | 2CX_Screen.md | u-cx | - |
| DO | 3DV_Code.md | u-dv-fe/be | - |
| CHECK | 4QA_Case.md | u-qa-a | - |
| CHECK | 4QA_Report.md | u-qa-t | - |
| ACT | 5ACT_Backlog.md | u-qa-n | - |
| ACT | 5ACT_Iteration_Log.md | u-m | - |
| ACT | 5ACT_Retrospective.md | u-pm | - |

## 마일스톤

| # | 마일스톤 | 상태 |
|---|----------|------|
| 1 | 플러그인 구조 완성 (agents, commands, templates, references) | 완료 |
| 2 | 대상 프로젝트 생성 (`/u-create-project`) | 대기 |
| 3 | PLAN Phase 실행 (`/u-plan`) | 대기 |
| 4 | PDCA 전체 사이클 완주 (`/u-loop`) | 대기 |

## 다음 단계

1. `/u-create-project` 로 대상 프로젝트(Turborepo 모노레포 + u-docs 구조) 초기화
2. `/u-plan` 으로 PLAN Phase 시작 (Roadmap → SRS → IA → Index)
3. 이후 `/u-loop` 으로 종료 조건까지 PDCA 자동 반복
