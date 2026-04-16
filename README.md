# U-MAKER Plugin v3.4.9

PDCA-based SSoT(Single Source of Truth) plugin for Claude Code.

Drop planning materials, and it automatically performs analysis → design → implementation → verification.

**16 Skills** (13 user-facing + 1 engine + 2 reports) · **7 Agents** · **5 PDCA Phases** · **11 Gate Criteria** (configurable via `--loop [N]`, default 5)

## Documentation

| Language | Link |
|----------|------|
| 한국어 | [README (Korean)](https://umaker.upleat.ai/README.ko.html) |
| English | [README (English)](https://umaker.upleat.ai/README.en.html) |
| 시작하기 | [GET STARTED](https://umaker.upleat.ai/GET_STARTED.html) |

## Quick Start

```bash
# Install
claude plugin add upleat-ax/u-maker-plugin

# Create new monorepo project
/u-createproject my-app

# Or initialize in existing directory
/u-init my-app

# Drop files into .u-maker/data/dropzone/ then:
/u-plan [app]            # SRS + IA
/u-design [app]          # ERD + API + Screens + Design System
/u-dev [app]             # FE + BE + DB code
/u-check [app]           # Test Cases + Results
/u-output [app]          # HTML output generation

# Or run all phases unattended:
/u-loop [app]
```

## License

Proprietary - Copyright (c) 2026 U PLEAT
