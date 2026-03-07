#!/usr/bin/env bash
# init-project.sh — u-maker Project Initialization Script
# Creates Turborepo + bun + Next.js + Storybook + .u-maker/docs structure
#
# Usage: ./init-project.sh <project-name>

set -euo pipefail

# ============================================================
# Arguments
# ============================================================
PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Error: Project name is required."
  echo "Usage: ./init-project.sh <project-name>"
  exit 1
fi

# Validate project name (lowercase, hyphens, no spaces)
if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Error: Project name must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  exit 1
fi

echo "============================================================"
echo "  u-maker: Project Initialization"
echo "  Project: $PROJECT_NAME"
echo "============================================================"
echo ""

# ============================================================
# 1. Create Turborepo with bun (with-tailwind example)
# ============================================================
echo "[1/5] Creating Turborepo monorepo with bun..."

bunx create-turbo@latest "$PROJECT_NAME" --example with-tailwind --package-manager bun

cd "$PROJECT_NAME"
echo "  -> Turborepo created at $(pwd)"

# ============================================================
# 2. Create Clean Architecture folders
# ============================================================
echo ""
echo "[2/5] Creating Clean Architecture folder structure..."

# apps/
mkdir -p apps/web
mkdir -p apps/admin

# packages/ (Clean Architecture layers)
PACKAGES=(ui data domain infrastructure tokens config)
for pkg in "${PACKAGES[@]}"; do
  mkdir -p "packages/$pkg/src"
  # Create minimal package.json for each package
  cat > "packages/$pkg/package.json" <<PKGJSON
{
  "name": "@${PROJECT_NAME}/${pkg}",
  "version": "0.0.0",
  "private": true,
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "scripts": {
    "build": "tsc",
    "lint": "eslint src/",
    "type-check": "tsc --noEmit"
  }
}
PKGJSON

  # Create index.ts entry point
  cat > "packages/$pkg/src/index.ts" <<INDEXTS
// @${PROJECT_NAME}/${pkg}
// Clean Architecture: ${pkg} layer
export {};
INDEXTS
done

echo "  -> Created packages: ${PACKAGES[*]}"

# ============================================================
# 3. Install Storybook dev dependencies
# ============================================================
echo ""
echo "[3/5] Installing Storybook dev dependencies..."

bun add -d @storybook/react @storybook/react-vite @storybook/addon-essentials @storybook/addon-interactions @storybook/addon-links storybook

# Create basic Storybook config
mkdir -p .storybook

cat > .storybook/main.ts <<SBMAIN
import type { StorybookConfig } from '@storybook/react-vite';

const config: StorybookConfig = {
  stories: [
    '../packages/ui/src/**/*.stories.@(ts|tsx)',
    '../apps/*/src/**/*.stories.@(ts|tsx)',
  ],
  addons: [
    '@storybook/addon-essentials',
    '@storybook/addon-interactions',
    '@storybook/addon-links',
  ],
  framework: {
    name: '@storybook/react-vite',
    options: {},
  },
};

export default config;
SBMAIN

cat > .storybook/preview.ts <<SBPREVIEW
import type { Preview } from '@storybook/react';

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
  },
};

export default preview;
SBPREVIEW

echo "  -> Storybook configured"

# ============================================================
# 4. Create .u-maker/docs/ full structure
# ============================================================
echo ""
echo "[4/5] Creating .u-maker/docs/ SSoT document structure..."

# Common directories
COMMON_DIRS=(
  ".u-maker/docs/common/01-plan"
  ".u-maker/docs/common/02-design"
  ".u-maker/docs/common/03-dev"
  ".u-maker/docs/common/05-act"
  ".u-maker/docs/common/assets/diagrams"
  ".u-maker/docs/common/assets/screenshots"
  ".u-maker/docs/iterations"
)

for dir in "${COMMON_DIRS[@]}"; do
  mkdir -p "$dir"
done

# Per-app directories (read from config or default to web)
APP_NAMES=("web")
APP_PHASES=("01-plan" "02-design" "03-dev" "04-check")

for app in "${APP_NAMES[@]}"; do
  for phase in "${APP_PHASES[@]}"; do
    mkdir -p ".u-maker/docs/${app}/${phase}"
  done
done

# Create .u-maker/docs/README.md
cat > .u-maker/docs/README.md <<'UDOCSREADME'
# .u-maker/docs: SSoT Document Repository

This directory is the **Single Source of Truth (SSoT)** for all project documentation, managed by the u-maker plugin.

## Structure

| Directory | Scope | Phase | Contents |
|-----------|-------|-------|----------|
| `common/01-plan/` | Common | PLAN | Roadmap, Master Index |
| `common/02-design/` | Common | DESIGN | ERD, Design System |
| `common/03-dev/` | Common | DO | UI Components, Design Tokens |
| `common/05-act/` | Common | ACT | Backlog, Iteration Log, Retrospective |
| `{app}/01-plan/` | Per-App | PLAN | SRS, Information Architecture |
| `{app}/02-design/` | Per-App | DESIGN | API Contract, Screen Design |
| `{app}/03-dev/` | Per-App | DO | Code Implementation Log |
| `{app}/04-check/` | Per-App | CHECK | QA Test Cases, QA Report |
| `common/assets/` | Common | - | Diagrams, Screenshots |
| `iterations/` | - | - | Iteration Archives (iter-1/, iter-2/, ...) |

## Document Standards

All SSoT documents must include the standard header:

```markdown
- **Owner**: [Agent Name]
- **Status**: Draft | Review | Final
- **Version**: v0.1.0
- **Last Updated**: YYYY-MM-DD
- **Related Docs**: [links]
```

## Commands

- `/u-agent-status` — View current project status
- `/u-agent-docs` — List all documents in .u-maker/docs
- `/u-agent-validate` — Validate document integrity
- `/u-agent-backlog` — View open backlog items
UDOCSREADME

echo "  -> .u-maker/docs/ structure created with README.md"

# ============================================================
# 5. Create .gitkeep files for empty directories
# ============================================================
echo ""
echo "[5/5] Finalizing project structure..."

# Add .gitkeep to empty dirs
for dir in "${COMMON_DIRS[@]}"; do
  if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    touch "$dir/.gitkeep"
  fi
done
for app in "${APP_NAMES[@]}"; do
  for phase in "${APP_PHASES[@]}"; do
    dir=".u-maker/docs/${app}/${phase}"
    if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
      touch "$dir/.gitkeep"
    fi
  done
done

# Add storybook script to root package.json if not already present
if command -v jq &>/dev/null; then
  TMP=$(mktemp)
  jq '.scripts.storybook = "storybook dev -p 6006" | .scripts["build-storybook"] = "storybook build"' package.json > "$TMP" && mv "$TMP" package.json
fi

echo ""
echo "============================================================"
echo "  Project '$PROJECT_NAME' initialized successfully!"
echo ""
echo "  Next steps:"
echo "    cd $PROJECT_NAME"
echo "    bun install"
echo "    bun run dev          # Start development"
echo "    bun run storybook    # Start Storybook"
echo ""
echo "  u-maker commands:"
echo "    /u-plan              # Start PLAN phase"
echo "    /u-status            # Check project status"
echo "    /u-help              # Show all commands"
echo "============================================================"
