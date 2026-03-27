#!/usr/bin/env node
/**
 * on-doc-change.js — u-maker PostToolUse Hook (Write|Edit)
 *
 * When an SSoT document is modified, checks _links.json for dependent documents
 * and reports impact flags that need attention.
 *
 * Input: JSON from stdin with tool_input.file_path
 * Output: JSON { result: "success" } with cascade impact info
 */

const fs = require('fs');
const path = require('path');

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
} catch {}

const toolInput = input.tool_input || {};
const filePath = toolInput.file_path || '';

if (!filePath) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

const normalized = path.resolve(filePath);
const umakerPath = path.resolve(path.join(process.cwd(), '.u-maker'));

// Only process files under .u-maker/
if (!normalized.startsWith(umakerPath)) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// Only process SSoT documents (not _index.json, not config, not classified items)
const basename = path.basename(filePath);
const V2_SSOT_DOCS = new Set([
  'srs.md', 'ia.md', 'roadmap.md', 'erd.md', 'api.md', 'screen.md',
  'screen-flow.md', 'ux-guide.md', 'rtm.md', 'code.md', 'test-cases.md',
  'test-report.md', 'iteration-log.md', 'retrospective.md',
]);

if (!V2_SSOT_DOCS.has(basename)) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// Look for _links.json
const linksPath = path.join(umakerPath, '_links.json');
if (!fs.existsSync(linksPath)) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

try {
  const links = JSON.parse(fs.readFileSync(linksPath, 'utf8'));
  const docId = basename.replace('.md', '');

  // Find edges where this document is the source
  const impactedEdges = (links.edges || []).filter(e => e.from === docId);

  if (impactedEdges.length === 0) {
    console.log(JSON.stringify({ result: 'success' }));
    process.exit(0);
  }

  const impactList = impactedEdges.map(e => {
    const strength = e.strength || 'strong';
    const flag = strength === 'strong' ? 'MUST-UPDATE' : strength === 'moderate' ? 'REVIEW-NEEDED' : 'INFO';
    return `  - ${e.to} [${flag}] (${e.type})`;
  });

  console.log(JSON.stringify({
    result: 'success',
    hookSpecificOutput: {
      hookEventName: 'PostToolUse',
      additionalContext: [
        `[u-maker] CASCADE: ${basename} was modified. Impacted documents:`,
        ...impactList,
        '',
        'Use `/u-sync` to verify consistency or `/u-update --cascade` to auto-propagate changes.',
      ].join('\n'),
    },
  }));
} catch {
  console.log(JSON.stringify({ result: 'success' }));
}

process.exit(0);
