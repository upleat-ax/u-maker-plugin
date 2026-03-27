#!/usr/bin/env node

/**
 * Hook: on-gate-pass
 * Trigger: PostToolUse(Write)
 * Purpose: Detect when gate-rules conditions may be met and suggest phase transition
 */

const input = JSON.parse(process.env.CLAUDE_TOOL_INPUT || '{}');
const filePath = input.file_path || '';

// Detect index or status file updates that may indicate gate readiness
if (filePath.includes('_index.json') || filePath.includes('_status.json')) {
  console.log('[u-maker] Index/status updated. Run /u-gate to check phase transition readiness.');
}

// Detect document status changes to Final
if (filePath.includes('/docs/') && filePath.endsWith('.json')) {
  try {
    const fs = require('fs');
    if (fs.existsSync(filePath)) {
      const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      if (content.meta && content.meta.status === 'Final') {
        const docName = filePath.split('/').pop().replace('.json', '');
        console.log(`[u-maker] Document "${docName}" is now Final. Run /u-gate to check if phase gate conditions are met.`);
      }
    }
  } catch (e) {
    // Silent fail - non-critical hook
  }
}
