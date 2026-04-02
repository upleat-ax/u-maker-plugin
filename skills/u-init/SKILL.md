---
name: u-init
description: "프로젝트 초기화. .u-maker/ 전체 구조 생성, u-maker.config.json 초기화, 모노레포 감지, 앱 등록까지 수행한다."
triggers:
  - "/u-init"
  - "initialize project"
  - "프로젝트 초기화"
---

# u-init -- Project Initialization

`/u-init [project-name]` 명령으로 `.u-maker/` SSoT 디렉토리 구조 생성 + 프로젝트 설정 초기화.

---

## Execution Flow

### Step 1: Gather Project Info & Version Check

1. project-name 없으면 사용자 질문
2. 기존 `.u-maker/` 유무 확인
3. **SSoT 버전 체크:**
   - ssotVersion == "3.1" → 설정만 갱신
   - ssotVersion == "3.0" → 3.1 마이그레이션 실행 (폴더 재구성, 아래 Migration 참조)
   - <"3.0" 또는 없음 → docs/+data/classified/ 삭제 재생성 (사용자 확인 필수, data/input/ 보존)
   - 없음 → 신규
4. `package.json`, `turbo.json` → 모노레포 판별

### Step 2: Detect Monorepo

| 조건 | 판정 |
|------|------|
| turbo.json 존재 | Turborepo 모노레포 |
| apps/ + packages/ | 모노레포 (non-turbo) |
| apps/ 없음 | 단일 앱 |

### Step 3: Create Directory Tree

```
.u-maker/
├── u-maker.config.json
├── data/                        # 입력·분류·관리 데이터
│   ├── dropzone/                # 파일 드롭존 (/u-ingest가 분류+이동)
│   ├── input/                   # raw/, rfp/, as-is/, meeting-notes/, benchmarks/, links/, _manifest.json
│   ├── classified/              # 12 categories (각 _index.json) + _summary.json
│   ├── assumptions/             # _index.json
│   ├── backlog/                 # _index.json
│   └── links.json               # 문서 간 의존성 그래프
├── docs/
│   ├── common/                  # policy/, ux/, dev/, architecture/, project/
│   └── {app}/                   # _index.json, app.config.json, 01-plan/, 02-design/(wireframes/), 03-dev/, 04-check/
├── out/                         # 생성물 출력 (열람 전용)
│   ├── browse/                  # HTML 뷰어 (/u-browse 생성)
│   └── reports/                 # HTML 리포트 (/u-report 생성)
└── .state/                      # 런타임 상태
    ├── sessions/                # 토론 세션 기록
    └── loop-state.json          # /u-loop 체크포인트
```

### Step 4: Generate u-maker.config.json

```json
{
  "projectName": "{name}",
  "ssotVersion": "3.1",
  "version": "1.0.0",
  "apps": [],
  "documentPaths": {
    "root": ".u-maker/docs",
    "common": ".u-maker/docs/common",
    "data": ".u-maker/data",
    "input": ".u-maker/data/input",
    "classified": ".u-maker/data/classified",
    "dropzone": ".u-maker/data/dropzone",
    "assumptions": ".u-maker/data/assumptions",
    "backlog": ".u-maker/data/backlog",
    "links": ".u-maker/data/links.json",
    "sessions": ".u-maker/.state/sessions",
    "loopState": ".u-maker/.state/loop-state.json",
    "browse": ".u-maker/out/browse",
    "reports": ".u-maker/out/reports"
  },
  "language": { "documents": "ko" },
  "theme": "light",
  "license": { "type": "GPL-3.0", "copyright": "..." },
  "interaction": { "defaultMode": "interactive", "maxAssumptions": 20 },
  "designTool": { "tool": "pencil", "supportedTools": ["pencil", "figma", "stitch"] },
  "iteration": { "current": 1, "phase": "init" }
}
```

### Step 5: Register Apps

모노레포 앱별: `apps[]`에 추가 → `docs/{app}/` 구조 생성 → `_index.json` + `app.config.json` 초기화

단일 앱: 프로젝트 이름 = 앱 이름, 단일 엔트리

### Step 6: Display Summary

프로젝트명, 타입(monorepo/single), 등록 앱, 생성 디렉토리, Next Steps(`data/dropzone/`에 자료 배치 → `/u-ingest` → `/u-plan`)

---

## Initial Structures

**카테고리 _index.json:** `{ category, items: [], lastUpdated, totalCount: 0 }`

**앱 _index.json:** `{ app, documents: [], lastUpdated, phase: "plan" }`

**_manifest.json:** `{ files: [], lastScanned: null, totalFiles: 0, totalSizeBytes: 0 }`

---

## Migration: 3.0 → 3.1

ssotVersion "3.0" 발견 시 자동 폴더 재구성:

| 이전 경로 | 새 경로 |
|-----------|---------|
| `_dropzone/` | `data/dropzone/` |
| `_input/` | `data/input/` |
| `_classified/` | `data/classified/` |
| `_assumptions/` | `data/assumptions/` |
| `_backlog/` | `data/backlog/` |
| `_links.json` | `data/links.json` |
| `_browse/` | `out/browse/` |
| `_reports/` | `out/reports/` |
| `_sessions/` | `.state/sessions/` |
| `_loop-state.json` | `.state/loop-state.json` |

**절차:**
1. `data/`, `out/`, `.state/` 디렉토리 생성
2. 위 맵대로 `mv` (내용 보존)
3. `u-maker.config.json`의 `documentPaths` + `ssotVersion` → "3.1" 갱신
4. `.upgrade-pending` 파일 삭제 (있으면)
5. 빈 이전 디렉토리 정리 (삭제)

---

## Safety Rules

1. 기존 `.u-maker/` 발견 시 사용자 확인 필수
2. `data/input/` 생성만, 내용 무수정
3. 모노레포 감지 실패 시 단일 앱 fallback (사용자 고지)
4. 설정 파일 UTF-8, 2-space indent JSON
5. 모든 placeholder에 최소 frontmatter (Owner, Status: Draft)
