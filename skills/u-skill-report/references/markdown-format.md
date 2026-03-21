# Report Sections (Markdown) — 포맷 상세

`.md` 파일은 HTML과 동일한 데이터를 마크다운 테이블로 표현한다. 구조는 아래와 같다:

```markdown
---
document: "5_Report_PM_{{TIMESTAMP}}"
title: "{{PROJECT_NAME}} 종합 보고서 ({{TIMESTAMP}})"
owner: "u-PM"
status: "Final"
version: "v1.0.0"
last_updated: "{{DATE}}"
---

# {{PROJECT_NAME}} 종합 보고서

## 1. Meta
## 2. KPI Dashboard (전체 카운트)
## 3. Gate 판정
## 4. 이전 보고서 비교 (Trend)
## 5. Iteration 구현 요약
## 6. FR 구현 현황
## 7. NFR 달성 현황
## 8. US 달성 현황
## 9. FT 구현 현황
## 10. QA 결과 요약
## 11. 결함 목록
## 12. 부채 현황 (기획/디자인/기술)
### 12-1. 기획 부채
### 12-2. 디자인 부채
### 12-3. 기술 부채
## 13. Git 활동 요약
## 14. 기여자별 작업 내역
## 15. Iteration 이력
## 16. 다음 Iteration 계획
## 17. Post-Execution Summary
## Change Log
```

## Markdown 차트 표현

`.md` 파일에서 차트는 아래 방식으로 표현한다:

- **바 차트**: 유니코드 블록 문자(`█`)로 수평 바 차트 표현
  ```
  FR  ████████████████░░░░ 80% (12/15)
  NFR ██████████░░░░░░░░░░ 50% (3/6)
  US  ████████████████████ 100% (8/8)
  FT  ██████████████░░░░░░ 70% (21/30)
  TC  ████████████████░░░░ 82% (45/55)
  ```
- **비교**: 이전→현재 화살표 표기
  ```
  FR: 9/12 → 12/15 (+3/+3) ▲
  ```
- **트렌드 표시**: `▲` 증가, `▼` 감소, `—` 변화없음
