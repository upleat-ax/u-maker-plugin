#!/usr/bin/env node
/**
 * session-start.js — u-ssot SessionStart Hook
 *
 * Checks if u-docs/ exists in the current working directory.
 * If not, creates the full SSoT folder structure.
 *
 * Output: JSON { result: "success" }
 */

const fs = require('fs');
const path = require('path');

const cwd = process.cwd();
const udocsRoot = path.join(cwd, 'u-docs');

// Required directory structure
const UDOCS_DIRS = [
  '01-plan',
  '02-design',
  '03-dev',
  '04-check',
  '05-act',
  'assets/diagrams',
  'assets/screenshots',
  'iterations',
];

/**
 * Create u-docs/ directory structure if it doesn't exist.
 */
function ensureUdocsStructure() {
  const created = [];

  for (const dir of UDOCS_DIRS) {
    const fullPath = path.join(udocsRoot, dir);
    if (!fs.existsSync(fullPath)) {
      fs.mkdirSync(fullPath, { recursive: true });
      created.push(dir);
    }
  }

  // Create README.md if missing
  const readmePath = path.join(udocsRoot, 'README.md');
  if (!fs.existsSync(readmePath)) {
    fs.writeFileSync(readmePath, [
      '# u-docs: SSoT Document Repository',
      '',
      'Managed by the u-ssot plugin.',
      '',
      '| Directory | Phase |',
      '|-----------|-------|',
      '| `01-plan/` | PLAN |',
      '| `02-design/` | DESIGN |',
      '| `03-dev/` | DO |',
      '| `04-check/` | CHECK |',
      '| `05-act/` | ACT |',
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
          '# u-ssot: Session Start',
          '',
          `u-docs/ structure created at ${udocsRoot}`,
          `Created directories: ${created.join(', ')}`,
          '',
          'Ready for PDCA workflow. Use /u-plan to start.',
        ].join('\n'),
      },
    };
    console.log(JSON.stringify(response));
  } else {
    // u-docs/ exists, verify structure completeness
    const created = ensureUdocsStructure();
    const response = {
      result: 'success',
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: [
          '# u-ssot: Session Start',
          '',
          `u-docs/ found at ${udocsRoot}`,
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
      additionalContext: `u-ssot session start warning: ${err.message}`,
    },
  }));
}

process.exit(0);
