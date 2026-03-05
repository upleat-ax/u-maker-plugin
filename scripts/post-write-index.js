#!/usr/bin/env node
/**
 * post-write-index.js — u-maker PostToolUse Hook (Write)
 *
 * After writing to u-docs/, logs that index update may be needed.
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
// Check if file is under u-docs/
// ============================================================

if (!filePath) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

const normalized = path.resolve(filePath);
const udocsPath = path.resolve(path.join(process.cwd(), 'u-docs'));

if (!normalized.startsWith(udocsPath)) {
  // Not a u-docs file, skip
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// ============================================================
// Log index update notification
// ============================================================

const relPath = path.relative(udocsPath, normalized);
const basename = path.basename(filePath);

// Detect SSoT document pattern
const SSOT_DOC_PATTERN = /^\d+_[A-Za-z]+_[A-Z]+\.md$/;
const isSsotDoc = SSOT_DOC_PATTERN.test(basename);

let contextMessage = '';

if (isSsotDoc) {
  // Determine scope and phase from path
  // v2: relPath = "shared/01-plan/1_Roadmap_PM.md" or "web/01-plan/1_SRS_RA.md"
  // v1: relPath = "01-plan/1_SRS_RA.md"
  const parts = relPath.split(path.sep);
  let scope = '';
  let phaseDir = '';

  if (parts.length >= 3) {
    // v2 structure: parts[0] = scope (shared or app name), parts[1] = phaseDir
    scope = parts[0];
    phaseDir = parts[1];
  } else {
    // v1 flat structure: parts[0] = phaseDir
    phaseDir = parts[0] || '';
  }

  const scopeLabel = scope ? `Scope: ${scope}` : '';
  contextMessage = [
    `SSoT document written: ${relPath}`,
    `Consider updating 1_Index_PM.md to reflect this change.`,
    `Phase: ${phaseDir}`,
    scopeLabel,
  ].filter(Boolean).join(' | ');
} else {
  contextMessage = `Document written to u-docs/: ${relPath}`;
}

console.log(JSON.stringify({
  result: 'success',
  hookSpecificOutput: {
    hookEventName: 'PostToolUse',
    additionalContext: contextMessage,
  },
}));

process.exit(0);
