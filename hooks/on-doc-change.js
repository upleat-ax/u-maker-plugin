#!/usr/bin/env node

/**
 * Hook: on-doc-change
 * Trigger: PostToolUse(Write)
 * Purpose: Detect document changes in docs/ and remind about cascade check
 */

const input = JSON.parse(process.env.CLAUDE_TOOL_INPUT || '{}');
const filePath = input.file_path || '';

if (filePath.includes('/docs/') && (filePath.endsWith('.md') || filePath.endsWith('.json'))) {
  const fileName = filePath.split('/').pop();
  const docDir = filePath.split('/docs/').pop();
  console.log(`[u-maker] Document updated: ${docDir}. Consider running /u-sync to check cascade dependencies.`);
}
