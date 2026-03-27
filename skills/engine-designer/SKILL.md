---
name: engine-designer
description: |
  IA, Screen, ScreenFlow, ERD, API 등 설계 문서를 통합 생성하고,
  문서 간 교차 참조 정합성을 보장하는 설계 엔진.
version: 2.0.0
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
imports:
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
---

# Engine: Designer

> 분류 데이터와 기존 문서를 기반으로 설계 문서를 생성하고, 교차 참조 정합성을 보장한다.

## 역할

- 설계 문서 통합 생성: IA, Screen, ScreenFlow, ERD, API
- _classified 데이터 + 기존 SSoT 문서 참조
- engine-doc을 통한 실제 파일 쓰기 위임
- 설계 문서 간 교차 참조 일관성 유지
- Mermaid 다이어그램 생성 (flowchart, ER, sequence, state, C4)

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | 문서 유형, 앱 스코프, SRS/분류 데이터 참조 |
| **Output** | 설계 문서 (.md + .json) + Mermaid 다이어그램 |

## 지원 문서 유형

| 문서 | 주요 내용 | 다이어그램 |
|------|----------|-----------|
| **IA (정보구조도)** | 화면 계층 구조, 네비게이션 | Mermaid flowchart |
| **Screen (화면 명세)** | 화면별 구성요소, 인터랙션 | 없음 (Wireframe 연동) |
| **ScreenFlow (화면 흐름)** | 화면 간 전환 로직 | Mermaid stateDiagram |
| **ERD (데이터 모델)** | 엔티티, 관계, 속성 | Mermaid erDiagram |
| **API (API 계약)** | 엔드포인트, 스키마, 에러 | Mermaid sequenceDiagram |

## 실행 절차

### Step 1. 데이터 수집

1. SRS에서 FR/US/FT 목록 로드
2. _classified 데이터에서 관련 항목 참조 (screens, data-models, workflows)
3. 기존 설계 문서 확인 (증분 갱신 시)

### Step 2. 문서 생성

각 문서 유형별 생성 로직:

**IA 생성**:
1. SRS의 FT 목록에서 화면 관련 항목 추출
2. 도메인별 화면 그룹핑
3. 네비게이션 계층 구조 설계
4. Mermaid flowchart로 시각화

**Screen 생성**:
1. IA의 각 화면 노드에 대해 상세 명세 작성
2. FT → Screen 매핑 기록
3. 구성요소, 인터랙션, 유효성 검증 규칙 정의

**ERD 생성**:
1. SRS의 데이터 관련 FR + _classified/data-models 참조
2. 엔티티 추출 및 관계 정의
3. Mermaid erDiagram으로 시각화
4. 정규화 레벨 명시 (최소 3NF)

**API 생성**:
1. FT 중 API 관련 항목 추출
2. RESTful 엔드포인트 설계
3. Request/Response 스키마 정의
4. Mermaid sequenceDiagram으로 주요 흐름 시각화

### Step 3. 교차 참조 검증

생성 후 다음 교차 참조 정합성 검사:
- Screen의 모든 화면이 IA에 존재하는가
- ERD의 엔티티가 API 스키마와 일치하는가
- API 엔드포인트가 Screen 인터랙션과 매핑되는가
- 모든 FT가 최소 1개 설계 문서에 매핑되는가

### Step 4. engine-doc 위임

검증 완료 후 engine-doc을 통해:
1. .md 파일 쓰기
2. .json 병행 내보내기
3. _index.json 갱신
4. engine-dep에 의존성 갱신 트리거

## 오류 처리

| 상황 | 처리 |
|------|------|
| SRS 미존재 | Plan Phase 선행 필요 안내 |
| FT→Screen 매핑 누락 | 미매핑 FT 목록 경고 + 수동 매핑 요청 |
| ERD 순환 참조 | 관계 경고 + 정규화 제안 |
| Mermaid 렌더링 실패 | 다이어그램 코드 출력 + 수동 확인 요청 |
| 교차 참조 불일치 | 불일치 목록 출력 + 수정 제안 |

## 연동

- **호출원**: `u-skill-design`, `u-skill-erd`, `u-skill-api`, `u-skill-screen`
- **호출 대상**: engine-doc (파일 쓰기), engine-dep (의존성 갱신)
- **참조 엔진**: engine-analyzer (_classified 데이터)
