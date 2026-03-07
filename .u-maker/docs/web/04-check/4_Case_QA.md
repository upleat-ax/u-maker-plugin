---
document: "4_Case_QA"
title: "u-maker Plugin Test Cases"
owner: "u-QA"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
app: "web"
related_docs:
  - ".u-maker/docs/web/01-plan/1_SRS_RA.md"
  - ".u-maker/docs/web/02-design/2_API_SA.md"
  - ".u-maker/docs/web/02-design/2_Screen_UX.md"
  - ".u-maker/docs/web/03-dev/3_Code_DV.md"
  - ".u-maker/docs/web/04-check/4_Report_QA.md"
external_links: []
---

# u-maker Plugin Test Cases

- **Owner**: u-QA
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [SRS](../01-plan/1_SRS_RA.md), [API Contract](../02-design/2_API_SA.md), [Screen Design](../02-design/2_Screen_UX.md), [Code Record](../03-dev/3_Code_DV.md), [QA Report](4_Report_QA.md)

## 1. Preconditions

- `python3`와 `node` 실행 가능
- 테스트 저장소가 `.u-maker/u-maker.config.json`을 포함
- `.u-maker/docs` 경로에 쓰기 가능

## 2. Test Cases

| TC-ID | FT | Level | Scenario | Expected |
|---|---|---|---|---|
| TC-0010 | FT-0010 | Integration | `./deploy_local.sh --check` 실행 | 설치 상태 요약이 출력된다 |
| TC-0020 | FT-0020 | Integration | 현재 저장소에서 `/u-skill-init` 실행 | Draft 문서 세트와 `_links.json`이 생성된다 |
| TC-0030 | FT-0040 | Unit | 기능 추가 의도 프롬프트를 `prompt-docs-first-guard.js`에 전달 | 구현 차단과 문서 명령 제안이 반환된다 |
| TC-0040 | FT-0050 | Integration | `validate-ssot.py .u-maker/docs` 실행 | 필수 헤더와 관련 문서 링크를 검사한다 |
| TC-0050 | FT-0060 | Integration | `check-exit-criteria.py .u-maker/docs` 실행 | build, defect, FR 구현 상태가 집계된다 |
| TC-0060 | FT-0080 | Unit | 빈 docs 구조에서 `hooks/session-start.js` 실행 | common/app 디렉토리가 자동 생성된다 |

## 3. Coverage Note

실제 자동 테스트 코드는 아직 저장소에 없으므로, 위 케이스는 재현 가능한 수동/스크립트 실행 기준의 초안이다.

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-QA | Bootstrap QA cases authored from current scripts and hooks |
