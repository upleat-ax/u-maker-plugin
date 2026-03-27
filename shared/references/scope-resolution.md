# Scope Resolution Rules

> /u-{command} [scope] 의 scope 파싱 규칙. engine-router가 처리.

---

## 1. Grammar

```
/u-{command} [scope] [target] [flags]
```

- **scope** = 앱 이름 | `common` | `all` | 생략
- **target** = 문서/항목 이름 (command에 따라 선택적)
- **flags** = `-i` | `--step` | `--only X` | `--cascade` | ...

---

## 2. Scope 해석 순서

engine-router가 아래 순서로 scope를 해석:

1. `u-maker.config.json`의 `apps[]`에 등록된 앱 이름이면 → **해당 앱 스코프**
2. `common`이면 → **common/ 스코프**
3. `all`이면 → **전체 앱** (루프 실행)
4. 생략이면:
   - 앱 1개: **자동 선택**
   - 앱 2개+: **FDE에게 선택 요청** (interactive mode처럼 pause)
5. 등록된 앱도 예약어도 아니면 → **target으로 해석**
6. 콤마로 복수 앱 지정 가능: `retail,corporate`

---

## 3. 예약어 (앱 이름 사용 금지)

| 카테고리 | 예약어 |
|----------|--------|
| Scopes | `common`, `all` |
| Targets | `srs`, `ia`, `erd`, `api`, `screens`, `screen-flow`, `roadmap`, `rtm`, `ux-guide`, `design-token`, `test-cases`, `test-report`, `code` |
| Types | `brainstorm`, `review`, `decision`, `workshop`, `retro`, `approve`, `reject` |

---

## 4. 해석 예시

| Input | scope | target | 설명 |
|-------|-------|--------|------|
| `/u-plan retail` | retail | (all plan docs) | retail 앱 Plan phase |
| `/u-plan common` | common | (all plan docs) | 공통 정책 문서 |
| `/u-plan retail --only srs` | retail | srs | SRS만 생성 |
| `/u-doc retail screens` | retail | screens | Screen 문서 조회 |
| `/u-plan` (앱 1개) | (auto) | (all plan docs) | 유일한 앱 자동 선택 |
| `/u-plan` (앱 2개+) | (ask) | (all plan docs) | FDE에게 선택 요청 |
| `/u-plan retail,corporate` | retail+corporate | (all plan docs) | 2개 앱 순차 실행 |
| `/u-add retail fr "제목"` | retail | fr | FR 항목 추가 |
| `/u-discuss retail brainstorm "주제"` | retail | brainstorm | 세션 타입 = target |

---

## 5. 복수 앱 실행 규칙

`all` 또는 콤마 구분 복수 앱 지정 시:
- 각 앱별 순차 실행 (병렬 아님)
- 앱별 결과 요약 제공
- 하나의 앱에서 실패해도 다음 앱 계속 실행
- `common`은 마지막에 실행 (공통 정책은 앱별 결과 반영)

---

## 6. Claude 탐색 경로 (scope-first)

`/u-plan retail` 실행 시 Claude가 읽는 순서:

1. `u-maker.config.json` → apps 목록, 현재 mode 확인
2. `apps/retail/app.config.json` → 앱 설정, phase
3. `apps/retail/_index.json` → 문서 목차 + 상태
4. `common/_index.json` → 공통 정책 목차 (필요한 것만)
5. `apps/retail/_classified/_summary.json` → 정제 데이터 통계
6. 필요한 파일만 개별 로드
