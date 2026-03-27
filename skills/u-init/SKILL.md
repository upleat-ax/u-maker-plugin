---
name: u-init
description: "프로젝트 초기화. .u-maker/ 전체 구조 생성, u-maker.config.json 초기화, 모노레포 감지, 앱 등록까지 수행한다."
triggers:
  - "/u-init"
  - "initialize project"
  - "프로젝트 초기화"
---

# u-init -- Project Initialization

`/u-init [project-name]` 명령으로 `.u-maker/` SSoT 디렉토리 구조를 생성하고, 프로젝트 설정을 초기화한다.

---

## Execution Flow

### Step 1: Gather Project Info

1. `project-name` 인자가 없으면 사용자에게 질문
2. 현재 디렉토리의 기존 `.u-maker/` 유무 확인
   - 이미 존재하면: "기존 설정 덮어쓸까요?" 확인 (Always-Pause)
3. `package.json`, `turbo.json` 읽어 모노레포 여부 판별

### Step 2: Detect Monorepo Structure

```
조건                          판정
────────────────────────────  ──────────
turbo.json 존재               Turborepo 모노레포
apps/ + packages/ 존재        모노레포 (non-turbo)
apps/ 없음                    단일 앱
```

- 모노레포: `apps/` 하위 각 디렉토리를 앱 후보로 인식
- 단일 앱: 프로젝트 루트 = 앱 하나

### Step 3: Create Directory Tree

```
.u-maker/
├── u-maker.config.json          # 프로젝트 설정 (Single Source of Truth)
├── _links.json                  # 글로벌 의존성 그래프 (empty)
│
├── docs/
│   ├── common/                  # 공통 문서 (모든 앱이 상속)
│   │   ├── policy/
│   │   │   └── .gitkeep
│   │   ├── ux/
│   │   │   ├── ux-guide.md      # placeholder
│   │   │   └── design-token.md  # placeholder
│   │   ├── dev/
│   │   │   └── coding-convention.md  # placeholder
│   │   ├── architecture/
│   │   │   ├── erd-common.md    # placeholder
│   │   │   └── api-common.md    # placeholder
│   │   └── project/
│   │       ├── glossary.md      # placeholder
│   │       └── iteration-log.md # placeholder
│   │
│   └── {app}/                   # 앱별 문서 (앱 등록 시 생성)
│       ├── _index.json          # 문서 인벤토리
│       ├── app.config.json      # 앱별 설정
│       ├── 01-plan/
│       │   └── .gitkeep
│       ├── 02-design/
│       │   ├── wireframes/        # 와이어프레임 파일 + index.html 뷰어
│       │   └── .gitkeep
│       ├── 03-dev/
│       │   └── .gitkeep
│       └── 04-check/
│           └── .gitkeep
│
├── _input/                      # 원시 자료 (READ-ONLY)
│   ├── raw/                     # 미분류 파일 드롭존 (자동 분류 대상)
│   ├── rfp/
│   ├── as-is/
│   ├── meeting-notes/
│   ├── benchmarks/
│   ├── links/
│   └── _manifest.json           # 입력 파일 인벤토리
│
├── _classified/                 # 정제 데이터
│   ├── requirements/
│   │   └── _index.json
│   ├── pain-points/
│   │   └── _index.json
│   ├── domain-terms/
│   │   └── _index.json
│   ├── stakeholders/
│   │   └── _index.json
│   ├── workflows/
│   │   └── _index.json
│   ├── screens/
│   │   └── _index.json
│   ├── data-models/
│   │   └── _index.json
│   ├── constraints/
│   │   └── _index.json
│   ├── decisions/
│   │   └── _index.json
│   ├── questions/
│   │   └── _index.json
│   └── _summary.json            # 분류 요약
│
├── _sessions/                   # 토론 세션 기록
├── _assumptions/                # 자동 가정 로그
│   └── _index.json
└── _backlog/                    # 백로그 임시 저장
    └── _index.json
```

### Step 4: Generate u-maker.config.json

```json
{
  "projectName": "{project-name}",
  "version": "1.0.0",
  "createdAt": "{ISO 8601}",
  "updatedAt": "{ISO 8601}",

  "apps": [],

  "documentPaths": {
    "root": ".u-maker/docs",
    "common": ".u-maker/docs/common",
    "input": ".u-maker/_input",
    "classified": ".u-maker/_classified",
    "sessions": ".u-maker/_sessions",
    "assumptions": ".u-maker/_assumptions",
    "backlog": ".u-maker/_backlog"
  },

  "language": {
    "documents": "ko",
    "supported": ["ko", "en", "ja", "zh"]
  },

  "interaction": {
    "defaultMode": "interactive",
    "maxAssumptions": 20
  },

  "designTool": {
    "tool": "pencil",
    "supportedTools": ["pencil", "figma", "stitch"]
  },

  "iteration": {
    "current": 1,
    "phase": "init"
  }
}
```

### Step 5: Register Detected Apps

모노레포에서 감지된 각 앱에 대해:

1. `apps[]` 배열에 앱 엔트리 추가:
   ```json
   {
     "name": "{app-dir-name}",
     "path": "apps/{app-dir-name}",
     "description": "",
     "techStack": {}
   }
   ```
2. `docs/{app}/` 디렉토리 구조 생성 (Step 3의 `{app}` 부분)
3. `docs/{app}/_index.json` 초기화 (빈 문서 목록)
4. `docs/{app}/app.config.json` 생성:
   ```json
   {
     "name": "{app-name}",
     "phase": "plan",
     "techStack": {},
     "team": []
   }
   ```

단일 앱 모드:
- 앱 이름 = 프로젝트 이름
- `apps[]`에 단일 엔트리 등록

### Step 6: Display Status Summary

```
## u-init Complete

**Project:** {project-name}
**Type:** {monorepo | single-app}
**Apps registered:** {count}

### Apps
- {app-name} (apps/{path})

### Directory Structure
.u-maker/ .............. created
  u-maker.config.json .. initialized
  _links.json .......... initialized
  docs/common/ ......... created (7 placeholders)
  docs/{app}/ .......... created ({count} apps)
  _input/ .............. created (ready for raw data)
  _classified/ ......... created (10 categories)
  _sessions/ ........... created
  _assumptions/ ........ created
  _backlog/ ............ created

### Next Steps
1. Place raw data (RFP, AS-IS docs, meeting notes) into `.u-maker/_input/raw/`
2. Run `/u-ingest {app}` to auto-sort raw files and analyze/classify data
3. Run `/u-plan {app}` to generate SRS + IA + Roadmap
```

---

## _index.json Initial Structure

각 분류 카테고리의 `_index.json`:

```json
{
  "category": "{category-name}",
  "items": [],
  "lastUpdated": "{ISO 8601}",
  "totalCount": 0
}
```

앱 문서의 `_index.json`:

```json
{
  "app": "{app-name}",
  "documents": [],
  "lastUpdated": "{ISO 8601}",
  "phase": "plan"
}
```

---

## _manifest.json Initial Structure

```json
{
  "files": [],
  "lastScanned": null,
  "totalFiles": 0,
  "totalSizeBytes": 0
}
```

---

## Safety Rules

1. 기존 `.u-maker/` 발견 시 반드시 사용자 확인 후 진행
2. `_input/` 폴더는 생성만 하고 내용을 절대 수정하지 않음
3. 모노레포 감지 실패 시 단일 앱으로 fallback (사용자에게 고지)
4. 설정 파일(`u-maker.config.json`)은 항상 UTF-8, 2-space indent JSON으로 저장
5. 모든 placeholder 파일에 최소 frontmatter 포함 (Owner, Status: Draft)
