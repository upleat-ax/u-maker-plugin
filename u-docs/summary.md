---
Owner: u-ra
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
| 에이전트 | 6개 전문 에이전트 (u-ra, u-sa, u-ux, u-dv-fe, u-dv-be, u-qa) |
| 리포지토리 | u-ssot (main branch) |

## 플러그인 구조

| 구성 요소 | 수량 | 설명 |
|-----------|------|------|
| Agents | 6 | 전문 역할별 에이전트 (RA, SA, UX, FE/BE Dev, QA) |
| Slash Commands | 35+ | Lifecycle, Loop, Document, Agent, Utility 명령어 |
| Templates | 17 | SSoT 문서 템플릿 (01-plan ~ 05-act) |
| References | 8 | 표준 규격, 기술 스택, PDCA 워크플로우 등 참조 문서 |
| Scripts | 6 | 프로젝트 초기화, SSoT 검증, 종료 조건 확인 자동화 |
| Hooks | 2 | SessionStart, PreToolUse(Write/Edit) |

## 주요 기능 (Features)

- **PDCA 자동화**: Plan-Design-Do-Check-Act 사이클 자동 반복
- **SSoT 문서 체계**: u-docs/ 기반 단일 진실 원천 문서 관리
- **Phase Gate**: 각 Phase 전환 시 Gate 조건 자동 검증
- **6 Agent 협업**: 역할별 전문 에이전트가 문서 생성/검수/개발 수행
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
| PLAN | 1_Roadmap_RA.md | u-ra | - |
| PLAN | 1_SRS_SA.md | u-sa | - |
| PLAN | 1_IA_UX.md | u-ux | - |
| PLAN | 1_Index_RA.md | u-ra | - |
| DESIGN | 2_ERD_SA.md | u-sa | - |
| DESIGN | 2_API_SA.md | u-sa | - |
| DESIGN | 2_Screen_UX.md | u-ux | - |
| DESIGN | 2_DesignSystem_UX.md | u-ux | - |
| DO | 3_Code_DV.md | u-dv-fe/be | - |
| DO | 3_Screen_UX.md | u-ux | - |
| DO | 3_UIComponents_UX.md | u-ux | - |
| DO | 3_DesignToken_UX.md | u-ux | - |
| CHECK | 4_Case_QA.md | u-qa | - |
| CHECK | 4_Report_QA.md | u-qa | - |
| ACT | 5_Backlog_RA.md | u-ra | - |
| ACT | 5_IterationLog_RA.md | u-ra | - |
| ACT | 5_Retrospective_RA.md | u-ra | - |

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
