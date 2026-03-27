#!/usr/bin/env node
/**
 * post-write-index.js — u-maker PostToolUse Hook (Write)
 *
 * After writing to .u-maker/docs/, logs that index update may be needed.
 * Detects new document creation vs updates.
 *
 * Input: JSON from stdin with tool_input.file_path
 * Output: JSON { result: "success" }
 */

const fs = require('fs');
const path = require('path');

// ============================================================
// Read stdin
// ============================================================

function readStdinSync() {
  try {
    return fs.readFileSync('/dev/stdin', 'utf8');
  } catch {
    return '{}';
  }
}

const rawInput = readStdinSync();
let input = {};
try {
  input = JSON.parse(rawInput);
} catch {
  // Not valid JSON
}

const toolInput = input.tool_input || {};
const filePath = toolInput.file_path || '';

// ============================================================
// Check if file is under .u-maker/docs/
// ============================================================

if (!filePath) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

const normalized = path.resolve(filePath);
const umakerPath = path.resolve(path.join(process.cwd(), '.u-maker'));

if (!normalized.startsWith(umakerPath)) {
  // Not a .u-maker/ file, skip
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// ============================================================
// Log index update notification (v2)
// ============================================================

const relPath = path.relative(umakerPath, normalized);
const basename = path.basename(filePath);

// v2 SSoT document names
const V2_SSOT_DOCS = new Set([
  'srs.md', 'ia.md', 'roadmap.md', 'erd.md', 'api.md', 'screen.md',
  'screen-flow.md', 'ux-guide.md', 'rtm.md', 'code.md', 'test-cases.md',
  'test-report.md', 'iteration-log.md', 'retrospective.md', 'backlog.md',
]);

let contextMessage = '';

if (V2_SSOT_DOCS.has(basename)) {
  // Determine scope from v2 path: apps/{app}/docs/{phase}/file.md or common/*/file.md
  const parts = relPath.split(path.sep);
  let scope = '';
  let phaseDir = '';

  if (parts[0] === 'apps' && parts.length >= 4) {
    scope = parts[1]; // app name
    phaseDir = parts[3]; // phase dir
  } else if (parts[0] === 'common') {
    scope = 'common';
    phaseDir = parts[1] || '';
  }

  contextMessage = [
    `SSoT document written: ${relPath}`,
    `Update _index.json in the same directory to reflect this change.`,
    scope ? `Scope: ${scope}` : '',
    phaseDir ? `Phase: ${phaseDir}` : '',
  ].filter(Boolean).join(' | ');
} else if (basename === '_index.json') {
  contextMessage = `Index updated: ${relPath}`;
} else if (basename.endsWith('.json') && relPath.includes('_classified')) {
  contextMessage = `Classified item written: ${relPath} | Update _index.json in the category folder.`;
} else {
  contextMessage = `File written to .u-maker/: ${relPath}`;
}

console.log(JSON.stringify({
  result: 'success',
  hookSpecificOutput: {
    hookEventName: 'PostToolUse',
    additionalContext: contextMessage,
  },
}));

process.exit(0);
