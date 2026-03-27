#!/usr/bin/env node
/**
 * session-start.js — u-maker SessionStart Hook
 *
 * Checks if .u-maker/docs/ exists in the current working directory.
 * If not, creates the full SSoT folder structure (v2: common/ + per-app).
 *
 * Output: JSON { result: "success" }
 */

const fs = require('fs');
const path = require('path');

const cwd = process.cwd();
const umakerRoot = path.join(cwd, '.u-maker');

// v2 common directory structure
const COMMON_DIRS = [
  'common/policy',
  'common/ux',
  'common/dev',
  'common/architecture',
  'common/project',
];

// v2 per-app directory structure (3-layer pipeline)
const APP_DIRS = [
  '_input/rfp',
  '_input/as-is',
  '_input/meeting-notes',
  '_classified/requirements',
  '_classified/pain-points',
  '_classified/domain-terms',
  '_classified/stakeholders',
  '_classified/workflows',
  '_classified/screens',
  '_classified/data-models',
  '_classified/constraints',
  '_classified/decisions',
  '_classified/questions',
  '_sessions',
  '_assumptions',
  'docs/01-plan',
  'docs/02-design',
  'docs/03-dev',
  'docs/04-check',
];

// v2 root-level shared directories
const ROOT_DIRS = [
  '_input',
  '_classified/requirements',
  '_classified/domain-terms',
  '_classified/stakeholders',
  '_classified/constraints',
  '_classified/decisions',
  '_sessions',
  '_assumptions',
];

/**
 * Read app list from v2 config.
 * @returns {string[]}
 */
function getAppsFromConfig() {
  const configPath = path.join(umakerRoot, 'u-maker.config.json');
  let apps = [];
  try {
    if (fs.existsSync(configPath)) {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      apps = config.apps || [];
    }
  } catch {}
  return apps;
}

/**
 * Create .u-maker/ v2 directory structure if it doesn't exist.
 */
function ensureStructure() {
  const created = [];

  // Create common directories
  for (const dir of COMMON_DIRS) {
    const fullPath = path.join(umakerRoot, dir);
    if (!fs.existsSync(fullPath)) {
      fs.mkdirSync(fullPath, { recursive: true });
      created.push(`common: ${dir}`);
    }
  }

  // Create root-level shared directories
  for (const dir of ROOT_DIRS) {
    const fullPath = path.join(umakerRoot, dir);
    if (!fs.existsSync(fullPath)) {
      fs.mkdirSync(fullPath, { recursive: true });
      created.push(`root: ${dir}`);
    }
  }

  // Create per-app directories
  const apps = getAppsFromConfig();
  for (const app of apps) {
    for (const dir of APP_DIRS) {
      const fullPath = path.join(umakerRoot, 'apps', app, dir);
      if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
        created.push(`${app}/${dir}`);
      }
    }
  }

  return created;
}

// ============================================================
// Main
// ============================================================

try {
  if (!fs.existsSync(umakerRoot)) {
    // No .u-maker/ at all — just report, /u-init will create it
    console.log(JSON.stringify({
      result: 'success',
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: [
          '# u-maker v2: Session Start',
          '',
          'No .u-maker/ directory found.',
          'Use `/u-init [project-name]` to initialize a new project.',
        ].join('\n'),
      },
    }));
  } else {
    // .u-maker/ exists, verify and repair structure
    const created = ensureStructure();
    const apps = getAppsFromConfig();
    const response = {
      result: 'success',
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: [
          '# u-maker v2: Session Start',
          '',
          `.u-maker/ found at ${umakerRoot}`,
          `Apps: ${apps.length > 0 ? apps.join(', ') : '(none registered)'}`,
          created.length > 0
            ? `Repaired missing directories: ${created.length} dirs`
            : 'All directories intact.',
          '',
          'PDCA workflow ready. Commands: /u-plan, /u-design, /u-build, /u-check, /u-ship',
        ].join('\n'),
      },
    };
    console.log(JSON.stringify(response));
  }
} catch (err) {
  console.log(JSON.stringify({
    result: 'success',
    hookSpecificOutput: {
      hookEventName: 'SessionStart',
      additionalContext: `u-maker session start warning: ${err.message}`,
    },
  }));
}

process.exit(0);
