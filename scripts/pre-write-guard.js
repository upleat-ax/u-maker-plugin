#!/usr/bin/env node
/**
 * pre-write-guard.js — u-maker PreToolUse Guard (Write|Edit)
 *
 * Validates:
 * 1. SSoT documents (pattern: *_*.md) must be under .u-maker/docs/
 * 2. Code files must not contain tech stack violations:
 *    - styled-components, @emotion, CSS-in-JS imports
 *    - class extends Component (class components)
 *    - npm/yarn commands
 *
 * Input: JSON from stdin with tool_input.file_path and tool_input.content
 * Output: JSON { result: "success" } or block message
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
  // Not valid JSON, skip
}

const toolInput = input.tool_input || {};
const filePath = toolInput.file_path || '';
const content = toolInput.content || '';

// ============================================================
// Skip if no file path
// ============================================================

if (!filePath) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// ============================================================
// Check 1: SSoT Document Path Enforcement
// ============================================================

// SSoT document pattern: files like 1_Roadmap_PM.md, 2_ERD_SA.md, etc.
const SSOT_DOC_PATTERN = /^\d+_[A-Za-z]+_[A-Z]+(?:_\d{12})?\.md$/;
const basename = path.basename(filePath);

if (SSOT_DOC_PATTERN.test(basename)) {
  // Must be under .u-maker/docs/
  const normalized = path.resolve(filePath);
  const udocsPath = path.resolve(path.join(process.cwd(), '.u-maker', 'docs'));

  if (!normalized.startsWith(udocsPath)) {
    console.log(JSON.stringify({
      result: 'block',
      message: [
        `SSoT document "${basename}" must be placed under .u-maker/docs/.`,
        `Attempted path: ${filePath}`,
        `Expected under: .u-maker/docs/`,
        '',
        'SSoT documents follow the naming pattern: [PhaseNum][Agent]_[Name].md',
        'and must be stored in the appropriate .u-maker/docs/ subdirectory.',
      ].join('\n'),
    }));
    process.exit(2);
  }
}

// ============================================================
// Check 2: Tech Stack Violations (code files only)
// ============================================================

const CODE_EXTENSIONS = ['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs'];
const ext = path.extname(filePath).toLowerCase();

if (CODE_EXTENSIONS.includes(ext) && content) {
  const violations = [];

  // Violation: styled-components or @emotion (CSS-in-JS)
  if (/import\s+.*from\s+['"]styled-components['"]/.test(content) ||
      /import\s+.*from\s+['"]@emotion/.test(content) ||
      /import\s+.*from\s+['"]@styled-system/.test(content) ||
      /require\(['"]styled-components['"]\)/.test(content) ||
      /require\(['"]@emotion/.test(content)) {
    violations.push(
      'CSS-in-JS import detected (styled-components/@emotion). ' +
      'Use plain .css files instead (no CSS-in-JS). (Tech Stack Rule #3)'
    );
  }

  // Violation: Class components
  if (/class\s+\w+\s+extends\s+(React\.)?Component/.test(content) ||
      /class\s+\w+\s+extends\s+(React\.)?PureComponent/.test(content)) {
    violations.push(
      'Class component detected. Use functional components with hooks only. (Tech Stack Rule #7)'
    );
  }

  // Violation: npm/yarn commands in scripts or config
  if (/["']npm\s+(install|i|add|run)/.test(content) ||
      /["']yarn\s+(install|add|run)/.test(content)) {
    violations.push(
      'npm/yarn command detected. Use bun as the package manager. (Tech Stack Rule #10)'
    );
  }

  if (violations.length > 0) {
    console.log(JSON.stringify({
      result: 'block',
      message: [
        `Tech stack violations detected in ${basename}:`,
        '',
        ...violations.map((v, i) => `  ${i + 1}. ${v}`),
        '',
        'Refer to .u-maker/docs/db/tech-stack-rules.md for the complete ruleset.',
      ].join('\n'),
    }));
    process.exit(2);
  }
}

// ============================================================
// All checks passed
// ============================================================

console.log(JSON.stringify({ result: 'success' }));
process.exit(0);
