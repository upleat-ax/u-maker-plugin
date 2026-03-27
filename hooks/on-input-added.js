#!/usr/bin/env node

/**
 * Hook: on-input-added
 * Trigger: PostToolUse(Write)
 * Purpose: Detect new files in _input/ and suggest running /u-ingest
 */

const input = JSON.parse(process.env.CLAUDE_TOOL_INPUT || '{}');
const filePath = input.file_path || '';

if (filePath.includes('_input/')) {
  const fileName = filePath.split('/').pop();
  console.log(`[u-maker] New input file detected: ${fileName}. Run /u-ingest to analyze and classify.`);
}
