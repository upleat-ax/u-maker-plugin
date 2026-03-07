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
const udocsRoot = path.join(cwd, '.u-maker', 'docs');

// Required common directory structure
const UDOCS_DIRS = [
  'common/01-plan',
  'common/02-design',
  'common/03-dev',
  'common/05-act',
  'common/assets/diagrams',
  'common/assets/screenshots',
  'iterations',
];

// Per-app phase directories
const APP_PHASE_DIRS = ['01-plan', '02-design', '03-dev', '04-check'];

/**
 * Read app list from config.
 * @returns {string[]}
 */
function getAppsFromConfig() {
  const configPath = path.join(cwd, '.u-maker/u-maker.config.json');
  let apps = ['web'];
  try {
    if (fs.existsSync(configPath)) {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      apps = (config.techStack && config.techStack.monorepo && config.techStack.monorepo.structure && config.techStack.monorepo.structure.apps) || ['web'];
    }
  } catch {}
  return apps;
}

/**
 * Create .u-maker/docs/ directory structure if it doesn't exist.
 */
function ensureUdocsStructure() {
  const created = [];
  const apps = getAppsFromConfig();

  // Create common directories
  for (const dir of UDOCS_DIRS) {
    const fullPath = path.join(udocsRoot, dir);
    if (!fs.existsSync(fullPath)) {
      fs.mkdirSync(fullPath, { recursive: true });
      created.push(dir);
    }
  }

  // Create per-app directories
  for (const app of apps) {
    for (const dir of APP_PHASE_DIRS) {
      const fullPath = path.join(udocsRoot, app, dir);
      if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
        created.push(`${app}/${dir}`);
      }
    }
  }

  // Create README.md if missing
  const readmePath = path.join(udocsRoot, 'README.md');
  if (!fs.existsSync(readmePath)) {
    fs.writeFileSync(readmePath, [
      '# .u-maker/docs: SSoT Document Repository',
      '',
      'Managed by the u-maker plugin.',
      '',
      '| Directory | Scope | Phase |',
      '|-----------|-------|-------|',
      '| `common/01-plan/` | Shared | PLAN |',
      '| `common/02-design/` | Shared | DESIGN |',
      '| `common/03-dev/` | Shared | DO |',
      '| `common/05-act/` | Shared | ACT |',
      ...apps.map(app => `| \`${app}/01-plan/\` ~ \`${app}/04-check/\` | ${app} | PLAN~CHECK |`),
      '',
    ].join('\n'), 'utf8');
    created.push('README.md');
  }

  return created;
}

// ============================================================
// Main
// ============================================================

try {
  if (!fs.existsSync(udocsRoot)) {
    const created = ensureUdocsStructure();
    const response = {
      result: 'success',
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: [
          '# u-maker: Session Start',
          '',
          `.u-maker/docs/ structure created at ${udocsRoot}`,
          `Created directories: ${created.join(', ')}`,
          '',
          'Ready for PDCA workflow. Use /u-skill-plan to start.',
        ].join('\n'),
      },
    };
    console.log(JSON.stringify(response));
  } else {
    // .u-maker/docs/ exists, verify structure completeness
    const created = ensureUdocsStructure();
    const response = {
      result: 'success',
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: [
          '# u-maker: Session Start',
          '',
          `.u-maker/docs/ found at ${udocsRoot}`,
          created.length > 0
            ? `Repaired missing directories: ${created.join(', ')}`
            : 'All directories intact.',
          '',
          'PDCA workflow ready.',
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
