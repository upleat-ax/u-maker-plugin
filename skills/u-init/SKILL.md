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
3. **SSoT 버전 체크:** ssotVersion == "3.0" → 설정만 갱신 / <"3.0" 또는 없음 → docs/+_classified/ 삭제 재생성 (사용자 확인 필수, _input/ 보존) / 없음 → 신규
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
├── _links.json
├── _dropzone/                   # 파일 드롭존 (/u-ingest가 분류+이동)
├── docs/
│   ├── common/                  # policy/, ux/, dev/, architecture/, project/
│   └── {app}/                   # _index.json, app.config.json, 01-plan/, 02-design/(wireframes/), 03-dev/, 04-check/
├── _input/                      # raw/, rfp/, as-is/, meeting-notes/, benchmarks/, links/, _manifest.json
├── _classified/                 # 12 categories (각 _index.json) + _summary.json
├── _sessions/
├── _assumptions/                # _index.json
└── _backlog/                    # _index.json
```

### Step 4: Generate u-maker.config.json

```json
{
  "projectName": "{name}",
  "ssotVersion": "3.0",
  "version": "1.0.0",
  "apps": [],
  "documentPaths": { "root": ".u-maker/docs", "common": "...", "input": "...", "classified": "...", "sessions": "...", "assumptions": "...", "backlog": "..." },
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

프로젝트명, 타입(monorepo/single), 등록 앱, 생성 디렉토리, Next Steps(`_dropzone/`에 자료 배치 → `/u-ingest` → `/u-plan`)

---

## Initial Structures

**카테고리 _index.json:** `{ category, items: [], lastUpdated, totalCount: 0 }`

**앱 _index.json:** `{ app, documents: [], lastUpdated, phase: "plan" }`

**_manifest.json:** `{ files: [], lastScanned: null, totalFiles: 0, totalSizeBytes: 0 }`

---

## Safety Rules

1. 기존 `.u-maker/` 발견 시 사용자 확인 필수
2. `_input/` 생성만, 내용 무수정
3. 모노레포 감지 실패 시 단일 앱 fallback (사용자 고지)
4. 설정 파일 UTF-8, 2-space indent JSON
5. 모든 placeholder에 최소 frontmatter (Owner, Status: Draft)
