#!/usr/bin/env node

/**
 * Hook: on-classified-validated
 * Trigger: PostToolUse(Write)
 * Purpose: Detect validated classified items and suggest backlog registration
 */

const input = JSON.parse(process.env.CLAUDE_TOOL_INPUT || '{}');
const filePath = input.file_path || '';

if (filePath.includes('data/classified/') && filePath.endsWith('.json')) {
  try {
    const fs = require('fs');
    if (fs.existsSync(filePath)) {
      const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      const requirements = data.requirements || [];
      const validated = requirements.filter(r => r.status === 'validated');

      if (validated.length > 0) {
        const ids = validated.map(r => r.id).join(', ');
        console.log(`[u-maker] ${validated.length} classified item(s) validated: ${ids}. Run /u-skill-backlog-add to register to backlog.`);
      }
    }
  } catch (e) {
    // Silent fail - non-critical hook
  }
}
