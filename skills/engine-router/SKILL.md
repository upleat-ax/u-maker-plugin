---
name: engine-router
description: |
  자연어 및 /u-* 커맨드에서 의도를 분류하고, 스코프 해석, 플래그 파싱,
  에이전트 디스패치를 수행하는 중앙 라우팅 엔진.
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
  - ${PLUGIN_ROOT}/_refer/slash-commands.md
---

# Engine: Router

> 사용자 입력(자연어 또는 `/u-*` 커맨드)을 분석하여 적절한 스킬/에이전트로 라우팅한다.

## 역할

- Intent Classification: 자연어 → 커맨드 매핑
- Scope Resolution: 대상 앱 결정
- Flag Parsing: CLI 옵션 해석
- Agent Dispatch: 커맨드 → 에이전트/스킬 매핑 및 실행 위임
- Fallback Handling: 미인식 커맨드 처리

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | 사용자 프롬프트 (자연어 또는 `/u-*` 커맨드) |
| **Output** | `{ command, scope, flags, agent, skill }` 라우팅 결과 객체 |

## 실행 절차

### Step 1. 커맨드 파싱

1. `/u-` prefix 존재 시 → 직접 커맨드 매칭 (slash-commands.md 참조)
2. 자연어 입력 시 → 키워드/의도 기반 분류:
   - Phase 키워드: "계획", "설계", "개발", "테스트", "검토" 등
   - Action 키워드: "생성", "수정", "삭제", "검증", "분석" 등
   - Document 키워드: "SRS", "ERD", "API", "테스트케이스" 등

### Step 2. 스코프 해석

| 패턴 | 해석 |
|------|------|
| `/u-plan web` | 단일 앱: `web` |
| `/u-plan web,admin` | 멀티 앱: `[web, admin]` |
| `/u-plan --all` | 전체 앱 |
| `/u-plan` (앱 미지정) | config에서 apps 배열 확인 → 단일이면 자동 선택, 복수이면 질의 |
| `common` 키워드 포함 | 공용 문서 대상 |

### Step 3. 플래그 파싱

| 플래그 | 단축 | 설명 |
|--------|------|------|
| `--interactive` | `-i` | 각 결정 포인트에서 사용자 확인 |
| `--step` | | 단계별 실행 (매 스텝 일시정지) |
| `--only` | | 특정 서브스텝만 실행 |
| `--cascade` | | 변경 전파 활성화 |
| `--verbose` | `-v` | 상세 로그 출력 |
| `--dry-run` | | 실제 파일 쓰기 없이 미리보기 |
| `--json` | | JSON 형식 출력 |

### Step 4. 에이전트 디스패치

1. 커맨드 → 스킬 매핑 테이블에서 대상 스킬 결정
2. 스킬의 frontmatter에서 선언된 agents 확인
3. 라우팅 결과 객체 구성 후 실행 위임

### Step 5. 폴백 처리

- 매칭 실패 시 → 유사 커맨드 제안 (Levenshtein distance 기반)
- 예약어 충돌 시 → 경고 메시지 출력
- 모호한 의도 시 → 사용자에게 AskUserQuestion으로 명확화 요청

## 오류 처리

| 상황 | 처리 |
|------|------|
| 미인식 커맨드 | 유사 커맨드 3개 제안 + help 안내 |
| 스코프 앱 미존재 | config의 apps 목록 출력 + 재입력 요청 |
| 충돌 플래그 조합 | 경고 출력 + 우선순위 높은 플래그 적용 |
| 예약어 사용 | 예약어 목록 안내 + 대체 커맨드 제안 |

## 연동

- **호출원**: orchestrator (모든 사용자 입력의 진입점)
- **호출 대상**: 모든 `u-skill-*`, `u-agent-*` 스킬
- **의존 엔진**: engine-phase-detector (현재 Phase 컨텍스트 확인)
