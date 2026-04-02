---
name: u-design
description: "DESIGN Phase 문서 생성. SRS/IA 기반 ERD, API Contract, Screen, ScreenFlow, UX Override, Design Token, RTM을 연쇄 생성한다."
triggers:
  - "/u-design"
  - "design phase"
  - "설계 문서"
  - "ERD 생성"
  - "API 설계"
---

# u-design -- Design Phase Document Generation

`/u-design [scope] [--only X] [-i] [--step]` 명령으로 Plan 문서(SRS + IA) 기반의 Design 문서를 연쇄 생성한다.

**Primary Agent:** u-agent-planner (engine-designer, engine-doc 사용)

---

## Flags

| Flag | Description |
|------|-------------|
| `--only X` | 지정 문서만 생성 (erd, api, screens, screen-flow, ux-guide, design-token, rtm) |
| `-i` | 분기점에서 사용자 확인 |
| `--step` | 매 단계 결과 표시 후 승인 대기 |
| `--loop` | Content+Style Quality Loop (QV-01~QV-10 평가, 평균 95점 초과까지 반복) |

---

## Execution Flow

### Step 0: Verify Plan Phase Gate

1. `_index.json` 읽어 Plan 문서 상태 확인
2. **필수 조건:** SRS = Final AND IA = Final
3. Gate 미통과 시:
   - 누락 문서 목록 표시
   - "/u-plan 또는 /u-gate를 먼저 실행하세요" 안내
   - 강제 진행 불가 (Always-Pause)

### Step 1: Generate ERD

**입력:** `data/classified/data-models/`, `data/classified/standards/`, SRS requirements

**프로세스:**
1. `data-models/_index.json` → AS-IS 테이블 구조
2. `srs.json` → 데이터 요구사항 (FR/US 중 data 관련)
3. AS-IS + 신규 요구사항 → TO-BE ERD 합성
4. `common/architecture/erd-common.md` 참조 → 공통 테이블(User, Auth, Audit) 포함
5. Mermaid ER 다이어그램 생성
6. 각 엔티티 → FR 역참조 필수
7. `erd.md` + `erd.json` 생성

**ERD 구조:**

```markdown
---
Owner: u-agent-planner
Status: Draft
Version: 1.0.0
Related Docs: [SRS, API, RTM]
---

# Entity-Relationship Diagram

## Entities

| Entity | Description | Related FR | Columns |
|--------|-------------|-----------|---------|
| User | 사용자 계정 | FR-0001 | id, email, name, ... |
| Order | 주문 | FR-0012 | id, user_id, total, ... |
```

### Step 2: Generate API Contract

**입력:** SRS Features (FT), ERD entities, `data/classified/workflows/`

**프로세스:**
1. `srs.json` → FT 목록에서 API 필요 항목 식별
2. `erd.json` → 엔티티 → request/response 스키마 도출
3. `workflows/_index.json` → API 흐름 시퀀스
4. `common/architecture/api-common.md` → 공통 API(auth, file upload) 포함
5. OpenAPI 3.0 스타일 스펙 생성
6. 각 엔드포인트 → FT 역참조 필수
7. `api.md` + `api.json` 생성

**API 구조:**

```markdown
### POST /api/v1/auth/login
- **Related FT:** FT-0010
- **Request Body:** { email: string, password: string }
- **Response 200:** { token: string, user: UserDTO }
- **Response 401:** { error: string, code: "AUTH_FAILED" }
- **Auth:** None
```

### Step 3: Generate Screen Designs

**입력:** IA, `data/classified/screens/`, `data/classified/ux-standards/`, `data/classified/standards/`, SRS

> **UX Standards 반영:** `ux-standards/_index.json`에서 `appliesTo`에 `"screens"`를 포함하는 UXS 항목을 읽어, 화면 컴포넌트 규격(레이아웃, 인터랙션 패턴, 컴포넌트 사용 규칙)에 반영한다.
> **Standards 반영:** `standards/_index.json`에서 폼 표준, 네이밍 컨벤션 등 화면 관련 항목을 참조하여 일관된 UI 규칙을 적용한다.

**프로세스:**
1. `ia.json` → 화면 계층 구조
2. `screens/_index.json` → AS-IS 화면 참조
3. `ux-standards/_index.json` → `appliesTo` 포함 `"screens"` 항목 필터 → 컴포넌트 규격 적용
4. `standards/_index.json` → 폼 표준, 네이밍 컨벤션 등 화면 관련 항목 참조
5. `srs.json` → 화면별 관련 FT 매핑
6. 화면별 컴포넌트 구성, 레이아웃, 인터랙션 패턴 정의 (UX standards 준수)
7. `screens.md` + `screens.json` 생성
8. `wireframes/index.html` 자동 생성 (engine-doc의 Wireframe Viewer 기능 호출)

### Step 4: Generate Screen Flow

**입력:** IA, Screens

**프로세스:**
1. 화면 간 내비게이션 경로 정의
2. 진입점, 분기점, 종단점 식별
3. Mermaid flowchart 다이어그램 생성
4. 모든 화면에 incoming/outgoing 흐름 확인 (entry/exit 제외)
5. `screen-flow.md` + `screen-flow.json` 생성

### Step 5: Generate UX Override (app-specific)

**입력:** `common/ux/ux-guide.md`, `data/classified/ux-standards/`, 앱별 UX 요구사항

앱별 공통 UX와 다른 점이 있을 때만 생성:
1. common UX guide 읽기
2. `ux-standards/_index.json` → `appliesTo` 포함 `"ux-guide"` 항목 필터 → UX 가이드 보완
3. 앱 특화 UX 요구사항 식별
4. 차이점만 선언적으로 기록 (UX standards 기반 항목 포함)
5. `ux-override.md` 생성

### Step 6: Generate Design Token (app-specific)

**입력:** `common/ux/design-token.md`, `data/classified/ux-standards/`, UX Override

> **UX Standards 반영:** `ux-standards/_index.json`에서 `appliesTo`에 `"design-token"`을 포함하는 UXS 항목을 읽어, 디자인 토큰 값(색상, 타이포그래피, 간격 등)에 반영한다.

앱별 디자인 토큰 커스터마이즈:
1. common design token 읽기
2. `ux-standards/_index.json` → `appliesTo` 포함 `"design-token"` 항목 필터 → 토큰 값 반영
3. 앱 override 적용
4. `design-token.md` + `design-token.json` 생성

### Step 7: Generate RTM

**입력:** SRS (FR→US→FT), Screens, API, ERD, TestCases (있는 경우)

**RTM (Requirements Traceability Matrix) 구조:**

```markdown
| FR ID | FR Title | US ID | FT ID | Screen | API | ERD Entity | TC IDs | Status |
|-------|----------|-------|-------|--------|-----|------------|--------|--------|
| FR-0001 | Login | US-0001 | FT-0010 | SCR-002 | POST /auth/login | User | -- | Design |
```

**프로세스:**
1. `srs.json` → FR → US → FT 계층
2. `screens.json` → FT → Screen 매핑
3. `api.json` → FT → API endpoint 매핑
4. `erd.json` → API → ERD entity 매핑
5. TC 매핑 (있으면 포함, 없으면 "--")
6. 모든 FR이 RTM에 포함되는지 검증
7. `rtm.md` + `rtm.json` 생성

### Step 8: Update Indexes and Links

1. `_index.json` 갱신: 모든 Design 문서 등록
2. `data/links.json` 갱신:
   ```json
   {"from": "{app}/srs", "to": "{app}/erd", "type": "derives"},
   {"from": "{app}/srs", "to": "{app}/api", "type": "derives"},
   {"from": "{app}/srs", "to": "{app}/rtm", "type": "traces"},
   {"from": "{app}/ia", "to": "{app}/screens", "type": "derives"},
   {"from": "{app}/screens", "to": "{app}/screen-flow", "type": "derives"},
   {"from": "{app}/erd", "to": "{app}/api", "type": "derives"}
   ```

---

## --only Flag 동작

| Value | Action | Prerequisite |
|-------|--------|-------------|
| `--only erd` | ERD만 생성 | SRS Final |
| `--only api` | API만 생성 | SRS + ERD Final |
| `--only screens` | Screens만 생성 | SRS + IA Final |
| `--only screen-flow` | ScreenFlow만 생성 | IA + Screens Final |
| `--only ux-guide` | UX Override 생성 | common UX guide 존재 |
| `--only design-token` | Design Token 생성 | common design token 존재 |
| `--only rtm` | RTM만 생성 | SRS + Screens + API 존재 |

---

## Common Inheritance

앱 문서 생성 시 항상 공통 문서 확인:

```
common/ux/ux-guide.md           (base UX)
common/ux/design-token.md       (base tokens)
common/architecture/erd-common.md  (shared tables)
common/architecture/api-common.md  (shared endpoints)
common/dev/coding-convention.md    (naming rules)
```

앱이 override를 가지면 common + override 병합. override가 충돌 시 override 우선.

---

## --loop Quality Loop (Content + Style)

`/u-design --loop` 실행 시, 생성된 Design 문서를 gatekeeper가 **Content+Style 10대 기준(QV-01~QV-10)**으로 평가.

### 평가 대상

| 산출물 | Content 검증 | Style 검증 |
|--------|-------------|-----------|
| erd.md + erd.json | SRS 데이터 엔티티 전수 포함, 컬럼↔FR 역참조, FK 무결성 | Mermaid ER 다이어그램 가독성, 곡선 커넥터, 테이블 포맷 일관성 |
| api.md + api.json | FT→endpoint 전수 매핑, req/res 스키마↔ERD 타입 일치 | OpenAPI 스타일 일관성, 메서드 배지, 에러 응답 상세 |
| screens.md + screens.json | IA 노드→Screen 전수 매핑, 컴포넌트↔API 필드 매핑 | UX Standards 반영, 컴포넌트 규격 포맷, 인터랙션 패턴 기술 |
| screen-flow.md + screen-flow.json | 모든 화면 incoming/outgoing 경로, 진입/분기/종단점 | Mermaid flowchart 레이아웃, 노드 레이블, 곡선 커넥터 |
| rtm.md + rtm.json | 모든 FR의 FR→US→FT→Screen→API→ERD→TC 체인 완전 | 히트맵 매핑, Gap 하이라이트, 커버리지 비율 표시 |
| wireframes/index.html | SCR-NNN별 HTML 어노테이션·탭 콘텐츠 충실 | 와이어프레임 뷰어 레이아웃, 반응형, 테마 |

### Loop 동작

```
/u-design retail --loop
  → planner가 ERD→API→Screens→ScreenFlow→RTM 연쇄 생성
  → gatekeeper: QV-01~QV-10 평가
  → 평균 ≤ 95? → Content/Style 분리 Enhancement Directive
    → planner가 미달 문서만 증분 수정 (directive 기반)
  → 평균 > 95 또는 max 도달 → 종료
```

**재수행 시:** 전체 재생성이 아니라 **미달 문서만 증분 수정**. 예: QV-02 미달(ERD↔API 타입 불일치) → erd.md와 api.md의 불일치 필드만 수정. QV-04 미달(다이어그램 노드 누락) → 해당 Mermaid 코드만 보정.

**연쇄 영향:** 상위 문서 수정 시 하위 문서에 cascade 필요 여부를 gatekeeper가 판단. 예: ERD 수정 → API 스키마 영향 확인 → 다음 iteration에서 함께 평가.

---

## Safety Rules

1. Plan phase gate 미통과 시 진행 불가 (SRS + IA Final 필수)
2. 기존 Final 문서 덮어쓰기 시 반드시 사용자 확인
3. 모든 엔티티/엔드포인트/화면에 FR/FT 역참조 필수
4. common ERD/API 참조 무결성 확인
5. `.json` 동반 파일 생성 필수
6. `_index.json`, `data/links.json` 갱신 필수
7. Mermaid 다이어그램에 곡선 커넥터 사용 (직선 화살표 금지)
8. auto mode 가정은 `data/assumptions/`에 기록
