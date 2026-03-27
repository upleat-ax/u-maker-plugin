#!/usr/bin/env node

/**
 * Hook: on-session-wrap
 * Trigger: PostToolUse(Write)
 * Purpose: Detect session file writes and remind to extract tagged items
 */

const input = JSON.parse(process.env.CLAUDE_TOOL_INPUT || '{}');
const filePath = input.file_path || '';

if (filePath.includes('_sessions/') && filePath.endsWith('.json')) {
  try {
    const fs = require('fs');
    if (fs.existsSync(filePath)) {
      const session = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      if (session.status === 'completed') {
        const actionCount = (session.items || []).filter(i => i.type === 'action').length;
        const decisionCount = (session.items || []).filter(i => i.type === 'decision').length;
        console.log(`[u-maker] Session completed: ${session.topic || 'untitled'}. Found ${actionCount} action(s) and ${decisionCount} decision(s). Extract tagged items to backlog.`);
      }
    }
  } catch (e) {
    // Silent fail - non-critical hook
  }
}
