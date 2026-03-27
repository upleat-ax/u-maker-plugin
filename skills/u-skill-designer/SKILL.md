---
name: u-skill-designer
description: "IA, Screen, ScreenFlow, ERD, API 등 설계 문서를 통합 생성하고, engine-doc을 통해 파일을 관리하는 내부 설계 엔진."
---

# u-skill-designer -- Integrated Design Engine

IA, Screen, ScreenFlow, ERD, API Contract, UX Guide, Design Token, RTM 등 설계 문서를 생성하는 통합 엔진이다. 분류된 데이터와 SRS를 입력으로 받아 설계 산출물을 생성하고, engine-doc을 통해 파일을 관리한다.

**Owner Agent:** u-agent-planner

---

## 1. Operations

### designIA(classifiedData)

Information Architecture를 생성한다.

**입력:**
- `_classified/workflows/` -- 사용자 태스크 흐름
- `_classified/screens/` -- AS-IS 화면 목록
- `_classified/domain-terms/` -- 도메인 용어
- `srs.json` -- USR 및 FT 목록

**프로세스:**

1. workflows에서 사용자 태스크 흐름 추출
2. screens에서 AS-IS → TO-BE 화면 매핑
3. SRS USR 정의 → 사용자 유형별 내비게이션 구성
4. 화면 계층 정의:
   - Level 0: 앱 진입점
   - Level 1: 메인 내비게이션 탭/섹션
   - Level 2: 하위 페이지
   - Level 3+: 상세, 모달, 드로어
5. 화면 ID 배정: `SCR-{NNN}` (scope 내 전역 고유)
6. Mermaid 다이어그램 생성 (tree 또는 mindmap, 곡선 커넥터)
7. 교차 검증: IA 모든 화면 → SRS FT와 매핑 확인 (고아 화면 탐지)
8. engine-doc.create("ia", scope, data) 호출 → `ia.md` + `ia.json`

**IA 출력 구조:**

```markdown
## Screen Hierarchy

| Screen ID | Name | Level | Parent | Related FT | Priority |
|-----------|------|-------|--------|-----------|----------|
| SCR-001 | Home | 1 | -- | FT-0001 | Must |
| SCR-002 | Login | 1 | -- | FT-0010 | Must |
| SCR-003 | Dashboard | 2 | SCR-001 | FT-0015 | Must |
```

### designScreens(ia, requirements)

화면 상세 설계서를 생성한다.

**입력:**
- `ia.json` -- 화면 계층
- `srs.json` -- FT 목록 (화면별 기능)
- `_classified/screens/` -- AS-IS 화면 참조

**프로세스:**

1. IA 화면 목록에서 화면별 반복
2. 화면별 상세 설계:
   - 레이아웃 구조 (header, sidebar, main, footer)
   - 컴포넌트 인벤토리 (버튼, 입력, 카드, 테이블, 모달 등)
   - 데이터 요구사항 (연결 API 엔드포인트)
   - 인터랙션 패턴 (click, submit, navigate, drag 등)
   - 상태 관리 (loading, error, empty, success)
   - 반응형 브레이크포인트 (mobile, tablet, desktop)
3. 관련 FT 매핑 필수
4. engine-doc.create("screens", scope, data) → `screens.md` + `screens.json`

**화면 설계 출력:**

```markdown
### SCR-003: Dashboard

| Field | Value |
|-------|-------|
| **Level** | 2 |
| **Parent** | SCR-001 (Home) |
| **Related FT** | FT-0015, FT-0016 |
| **Layout** | Sidebar + Main Content |
| **Auth Required** | Yes |

**Components:**
- KPI Card x 4 (매출, 주문, 방문자, 전환율)
- Chart: Line (일별 매출 추이)
- Table: 최근 주문 목록 (정렬, 필터, 페이지네이션)
- Quick Actions: 상품 추가, 주문 처리

**API Endpoints:**
- GET /api/v1/dashboard/kpi
- GET /api/v1/orders?limit=10&sort=createdAt:desc
```

### designScreenFlow(screens)

화면 간 내비게이션 흐름을 생성한다.

**입력:**
- `screens.json` -- 화면 상세 설계
- `ia.json` -- 화면 계층

**프로세스:**

1. 화면 간 내비게이션 경로 정의
2. 진입점(entry), 분기점(branch), 종단점(exit) 식별
3. 조건부 내비게이션 (인증 여부, 권한 등)
4. Mermaid flowchart 다이어그램 생성 (곡선 커넥터)
5. 모든 화면에 incoming/outgoing 흐름 확인 (entry/exit 제외)
6. engine-doc.create("screen-flow", scope, data) → `screen-flow.md` + `screen-flow.json`

### designERD(dataModels, requirements)

Entity-Relationship Diagram을 생성한다.

**입력:**
- `_classified/data-models/` -- AS-IS 테이블 구조
- `srs.json` -- 데이터 관련 FR/US/FT
- `common/architecture/erd-common.md` -- 공통 테이블 (User, Auth, Audit)

**프로세스:**

1. AS-IS 데이터 모델 읽기
2. SRS에서 데이터 요구사항 추출
3. AS-IS + 신규 요구사항 → TO-BE ERD 합성
4. 공통 테이블 포함 (User, Auth, AuditLog, File 등)
5. 엔티티별 필드:
   - PK, FK, type, nullable, unique, default, index
   - 관계: one-to-one, one-to-many, many-to-many
6. Mermaid ER 다이어그램 생성
7. 각 엔티티 → FR/FT 역참조 필수
8. engine-doc.create("erd", scope, data) → `erd.md` + `erd.json`

### designAPI(features, erd)

API Contract (OpenAPI-style)를 생성한다.

**입력:**
- `srs.json` → FT 목록에서 API 필요 항목 식별
- `erd.json` → 엔티티 → request/response 스키마 도출
- `_classified/workflows/` → API 흐름 시퀀스
- `common/architecture/api-common.md` → 공통 API (auth, file upload)

**프로세스:**

1. FT 목록에서 API가 필요한 기능 식별
2. ERD 엔티티로부터 DTO 스키마 도출
3. 엔드포인트별 정의:
   - HTTP method + path
   - Request body schema
   - Response schema (success + error)
   - Auth 요구사항 (None, Bearer, API Key)
   - Validation 규칙
   - Error codes + messages
4. 공통 API 포함 (auth, file upload, health check)
5. 각 엔드포인트 → FT 역참조 필수
6. engine-doc.create("api", scope, data) → `api.md` + `api.json`

**API 출력 구조:**

```markdown
### POST /api/v1/auth/login
- **Related FT:** FT-0010
- **Request Body:** { email: string, password: string }
- **Response 200:** { token: string, user: UserDTO }
- **Response 401:** { error: string, code: "AUTH_FAILED" }
- **Auth:** None
```

### designUXGuide(scope)

앱별 UX Override를 생성한다.

**입력:**
- `common/ux/ux-guide.md` -- 공통 UX 가이드
- 앱별 UX 요구사항

**프로세스:**

1. common UX guide 읽기
2. 앱 특화 요구사항 식별
3. 차이점만 선언적으로 기록 (전체 복사 아님)
4. engine-doc.create("ux-override", scope, data) → `ux-override.md`

---

## 2. Cross-Document Validation

설계 문서 생성 후 교차 검증을 수행한다.

| Check | Source | Target | Rule |
|-------|--------|--------|------|
| FT → Screen | SRS | Screens | 모든 FT가 최소 1개 Screen에 매핑 |
| Screen → API | Screens | API | 데이터를 표시하는 Screen은 API 엔드포인트 필요 |
| API → ERD | API | ERD | 모든 API response 스키마가 ERD 엔티티에 대응 |
| Screen → IA | Screens | IA | 모든 Screen이 IA 계층에 포함 |
| FT orphan | SRS | -- | 어떤 Screen/API에도 매핑되지 않은 FT |

검증 실패 시:
- auto mode: 경고 + `_assumptions/`에 기록
- interactive mode: 사용자에게 매핑 확인 요청

---

## 3. Common Inheritance

앱 문서 생성 시 항상 공통 문서를 확인한다.

```
common/ux/ux-guide.md           → base UX rules
common/ux/design-token.md       → base design tokens
common/architecture/erd-common.md  → shared tables (User, Auth, Audit)
common/architecture/api-common.md  → shared endpoints (auth, file, health)
common/dev/coding-convention.md    → naming rules
```

앱 override가 충돌 시 override 우선.

---

## 4. Safety Rules

1. 모든 설계 문서 생성은 engine-doc을 통해 수행 (.md + .json 동반 필수)
2. 모든 엔티티/엔드포인트/화면에 FR/FT 역참조 필수
3. common 문서 참조 무결성 확인
4. Mermaid 다이어그램에 곡선 커넥터 사용 (직선 화살표 금지)
5. 고아 항목(FT→Screen 미매핑, Screen→API 미연결) 탐지 시 경고
6. Design Token은 하드코딩 금지 (색상, 간격 등 모두 토큰 참조)
7. ERD 필드명은 snake_case, API path는 kebab-case 준수
8. `_index.json`, `_links.json` 갱신 필수
