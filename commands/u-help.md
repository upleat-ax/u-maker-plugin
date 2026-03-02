---
description: |
  u-ssot 전체 명령어 도움말 표시.
  Show all available u-ssot commands and agents.

  Triggers: /u-help, u-help, u-agent help, 도움말, 명령어 목록, help
allowed-tools:
  - Read
---

# u-Agent SSoT Help

> Show all available commands and agents.

Display the following help message:

```
====================================================================
  u-Agent SSoT - PDCA-based SSoT Collaboration Orchestrator
====================================================================

LIFECYCLE COMMANDS
  /u-create-project          새 프로젝트 초기화 (Turborepo + u-docs)
  /u-plan                    PLAN Phase 실행
  /u-design                  DESIGN Phase 실행
  /u-dev                     DO Phase 실행 (FE/BE 병렬 개발)
  /u-check                   CHECK Phase 실행
  /u-act                     ACT Phase 실행

LOOP COMMANDS
  /u-loop                    종료 조건 충족까지 PDCA 자동 반복
  /u-loop-from [phase]       지정 Phase부터 루프 시작
  /u-stop                    루프 중단
  /u-resume                  루프 재개

DOCUMENT MANAGEMENT
  /u-status                  현재 상태 보고 (Iteration, Phase, 진행률)
  /u-docs                    문서 목록 조회 (u-docs/ 트리)
  /u-validate                SSoT 무결성 검증
  /u-backlog                 백로그 Open 항목 조회
  /u-backlog-add             백로그 항목 추가
  /u-index                   문서 인덱스 갱신
  /u-us-add                  유저 스토리 추가
  /u-fr-add                  기능 요구사항 추가

INDIVIDUAL AGENT COMMANDS
  /u-srs                     SRS 문서 생성/갱신 (u-sa)
  /u-erd                     ERD 문서 생성/갱신 (u-sa)
  /u-api                     API Contract 생성/갱신 (u-sa)
  /u-screen                  화면 설계 생성/갱신 (u-ux)
  /u-fe                      Frontend 개발 실행 (u-dv-fe)
  /u-be                      Backend 개발 실행 (u-dv-be)
  /u-test                    테스트 케이스 설계 (u-qa)
  /u-bug-report              결함 분석 리포트 (u-qa)

QUALITY ASSURANCE
  /u-gap-detector            설계-구현 Gap 분석 (Match Rate 산출)

UTILITY
  /u-help                    이 도움말 표시
  /u-history                 Iteration 이력 조회
  /u-archive                 현재 Iteration 아카이브
  /u-summary                 프로젝트 요약 생성
  /u-storybook               Storybook 실행
  /u-build                   프로젝트 빌드
  /u-git-pr                  Git 커밋 및 PR 생성
  /u-init                    기존 프로젝트 SSoT 초기화

--------------------------------------------------------------------

AGENTS (6)
  u-ra      Requirements Analyst   PLAN, ACT (Roadmap, Index, Backlog, Retrospective)
  u-sa      Solution Architect     PLAN, DESIGN (SRS, ERD, API)
  u-ux      UX Designer            PLAN, DESIGN, DO (IA, Screen, DesignSystem, UIComponents, DesignToken)
  u-dv-fe   Frontend Developer     DO
  u-dv-be   Backend Developer      DO
  u-qa      QA Engineer            CHECK (Test Case, Report, Bug Report)

--------------------------------------------------------------------

DOCUMENTS BY PHASE
  01-plan    1_Roadmap_PM, 1_SRS_RA, 1_IA_RA, 1_Index_PM
  02-design  2_ERD_SA, 2_API_SA, 2_Screen_UX, 2_DesignSystem_UX
  03-dev     3_Code_DV, 3_Screen_UX, 3_UIComponents_UX, 3_DesignToken_UX
  04-check   4_Case_QA, 4_Report_QA
  05-act     5_IterationLog_RA, 5_Retrospective_PM
  root       backlog.md, summary.md

--------------------------------------------------------------------

PDCA WORKFLOW
  PLAN → DESIGN → DO → CHECK → [COMPLETE | ACT → next Iteration]

PHASE GATES
  PLAN → DESIGN    Roadmap + SRS + IA = Final
  DESIGN → DO      ERD + API + Screen = Final + 모순검수 통과
  DO → CHECK       코드 구현 완료 + 빌드 성공
  CHECK → COMPLETE Critical/Major 0건 + FR 전체 구현

====================================================================
  Tip: /u-status 로 현재 진행 상태를 확인하세요.
  Tip: /u-loop 으로 종료 조건까지 자동 반복할 수 있습니다.
====================================================================
```
