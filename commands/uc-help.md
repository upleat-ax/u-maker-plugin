---
description: |
  u-maker 전체 명령어 도움말 표시.
  Show all available u-maker commands and agents.

  Triggers: /uc-help, u-help, u-agent help, 도움말, 명령어 목록, help
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
  /uc-create-project          새 프로젝트 초기화 (Turborepo + u-docs)
  /uc-plan                    PLAN Phase 실행
  /uc-design                  DESIGN Phase 실행
  /uc-dev                     DO Phase 실행 (FE/BE 병렬 개발)
  /uc-check                   CHECK Phase 실행
  /uc-act                     ACT Phase 실행

LOOP COMMANDS
  /uc-loop                    종료 조건 충족까지 PDCA 자동 반복
  /uc-loop-from [phase]       지정 Phase부터 루프 시작
  /uc-stop                    루프 중단
  /uc-resume                  루프 재개

DOCUMENT MANAGEMENT
  /uc-status                  현재 상태 보고 (Iteration, Phase, 진행률)
  /uc-docs                    문서 목록 조회 (u-docs/ 트리)
  /uc-validate                SSoT 무결성 검증
  /uc-backlog                 백로그 Open 항목 조회
  /uc-backlog-add             백로그 항목 추가
  /uc-index                   문서 인덱스 갱신
  /uc-us-add                  유저 스토리 추가
  /uc-fr-add                  기능 요구사항 추가

INDIVIDUAL AGENT COMMANDS
  /uc-srs                     SRS 문서 생성/갱신 (ua-sa)
  /uc-erd                     ERD 문서 생성/갱신 (ua-sa)
  /uc-api                     API Contract 생성/갱신 (ua-sa)
  /uc-screen                  화면 설계 생성/갱신 (ua-ux)
  /uc-fe                      Frontend 개발 실행 (ua-dv-fe)
  /uc-be                      Backend 개발 실행 (ua-dv-be)
  /uc-test                    테스트 케이스 설계 (ua-qa)
  /uc-bug-report              결함 분석 리포트 (ua-qa)

QUALITY ASSURANCE
  /uc-gap-detector            설계-구현 Gap 분석 (Match Rate 산출)

UTILITY
  /uc-help                    이 도움말 표시
  /uc-history                 Iteration 이력 조회
  /uc-archive                 현재 Iteration 아카이브
  /uc-summary                 프로젝트 요약 출력 (콘솔)
  /uc-storybook               Storybook 실행
  /uc-build                   프로젝트 빌드
  /uc-git-pr                  Git 커밋 및 PR 생성
  /uc-init                    기존 프로젝트 SSoT 초기화

--------------------------------------------------------------------

AGENTS (6)
  ua-ra      Requirements Analyst   PLAN, ACT (Roadmap, Index, IterationLog, Retrospective)
  ua-sa      Solution Architect     PLAN, DESIGN (SRS, ERD, API)
  ua-ux      UX Designer            PLAN, DESIGN, DO (IA, Screen, DesignSystem, UIComponents, DesignToken)
  ua-dv-fe   Frontend Developer     DO
  ua-dv-be   Backend Developer      DO
  ua-qa      QA Engineer            CHECK (Test Case, Report, Bug Report)

--------------------------------------------------------------------

DOCUMENTS BY PHASE
  01-plan    1_Roadmap_PM, 1_SRS_RA, 1_IA_RA, 1_Index_PM
  02-design  2_ERD_SA, 2_API_SA, 2_Screen_UX, 2_UXGuide_UX
  03-dev     3_Code_DV, 3_Screen_UX, 3_UIComponents_UX, 3_DesignToken_UX
  04-check   4_Case_QA, 4_Report_QA
  05-act     5_IterationLog_RA, 5_Retrospective_PM

--------------------------------------------------------------------

PDCA WORKFLOW
  PLAN → DESIGN → DO → CHECK → [COMPLETE | ACT → next Iteration]

PHASE GATES
  PLAN → DESIGN    Roadmap + SRS + IA = Final
  DESIGN → DO      ERD + API + Screen = Final + 모순검수 통과
  DO → CHECK       코드 구현 완료 + 빌드 성공
  CHECK → COMPLETE Critical/Major 0건 + FR 전체 구현

====================================================================
  Tip: /uc-status 로 현재 진행 상태를 확인하세요.
  Tip: /uc-loop 으로 종료 조건까지 자동 반복할 수 있습니다.
====================================================================
```
