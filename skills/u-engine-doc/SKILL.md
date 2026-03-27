---
name: engine-doc
description: |
  모든 SSoT 문서의 CRUD, 템플릿 렌더링, JSON 병행 내보내기,
  버전 관리, 상태 생명주기, _index.json 자동 갱신을 담당하는 문서 관리 엔진.
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
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
---

# Engine: Document Manager

> SSoT 문서의 생성, 읽기, 수정, 삭제 및 관련 메타데이터를 일괄 관리한다.

## 역할

- 문서 CRUD 오퍼레이션 (생성/읽기/수정/삭제)
- 템플릿 기반 문서 생성 (변수 치환)
- JSON 병행 내보내기 (.md 생성 시 .json 동시 생성)
- 문서 버전 관리 (SemVer)
- 상태 생명주기 관리 (Draft → Review → Final)
- _index.json 자동 갱신
- 문서 헤더(YAML frontmatter) 유효성 검증

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | 작업 유형(create/read/update/delete), 대상 경로, 문서 데이터 |
| **Output** | 생성/수정된 .md + .json 파일, 갱신된 _index.json |

## 실행 절차

### Step 1. 템플릿 렌더링 (Create 시)

1. `.u-maker/templates/` 에서 해당 문서 유형의 템플릿 로드
2. 변수 치환:
   - `{{PROJECT_NAME}}` → config의 projectName
   - `{{APP_NAME}}` → 대상 앱 이름
   - `{{DATE}}` → 현재 날짜 (YYYY-MM-DD)
   - `{{VERSION}}` → `v0.1.0` (신규 생성 기본값)
   - `{{AUTHOR}}` → 담당 에이전트 이름
3. 렌더링된 내용으로 .md 파일 생성

### Step 2. JSON 병행 내보내기

모든 .md 파일 쓰기 시 동일 경로에 동명의 .json 생성:
- 파일명: `1_SRS_RA.md` → `1_SRS_RA.json`
- 스키마: `json-export.md`에 정의된 문서 유형별 JSON 스키마 준수
- 내용: .md의 구조화된 데이터를 JSON으로 변환

### Step 3. 버전 관리

| 변경 유형 | 버전 변경 | 예시 |
|----------|----------|------|
| 최초 생성 | `v0.1.0` | 신규 문서 |
| 내용 변경 | MINOR 증가 | `v0.1.0` → `v0.2.0` |
| 오타/서식 | PATCH 증가 | `v0.2.0` → `v0.2.1` |
| Phase Gate 통과 | `v1.0.0` | Final 확정 시 |

### Step 4. 상태 생명주기

```
Draft → Review → Final
  ↑                 |
  └── (변경 발생) ──┘
```

- **Draft**: 초기 작성 또는 수정 중
- **Review**: 검토 요청 상태
- **Final**: 확정. 변경 시 Draft로 강등

### Step 5. _index.json 자동 갱신

문서 쓰기 완료 후:
1. 해당 Phase 디렉토리의 `_index.json` 로드
2. 문서 엔트리 추가/갱신:
   ```json
   {
     "file": "1_SRS_RA.md",
     "type": "SRS",
     "owner": "u-agent-sa",
     "status": "Draft",
     "version": "v0.1.0",
     "lastUpdated": "2026-03-27"
   }
   ```
3. `_index.json` 저장

### Step 6. 헤더 유효성 검증

문서 읽기/쓰기 시 YAML frontmatter 필수 필드 확인:
- `title`, `version`, `status`, `owner`, `lastUpdated`
- 누락 시 경고 + 기본값 보충

## 오류 처리

| 상황 | 처리 |
|------|------|
| 템플릿 미존재 | 최소 헤더만 가진 기본 문서 생성 + 경고 |
| JSON 스키마 미일치 | 경고 로그 + best-effort 변환 |
| _index.json 손상 | 디렉토리 스캔으로 재생성 |
| Final 문서 수정 시도 | Draft 강등 확인 후 수정 진행 |
| 파일 경로 충돌 | 기존 파일 백업 후 덮어쓰기 |

## 연동

- **호출원**: 모든 에이전트 및 스킬 (문서 쓰기가 필요한 모든 곳)
- **호출 대상**: 없음 (파일 시스템 직접 조작)
- **의존 엔진**: engine-dep (문서 쓰기 후 의존성 갱신 트리거)
