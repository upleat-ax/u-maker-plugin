#!/usr/bin/env node

/**
 * Hook: on-ship-incomplete
 * Trigger: PostToolUse(Write)
 * Purpose: Warn about carry-over items when iteration has incomplete items during ship/act phase
 */

const input = JSON.parse(process.env.CLAUDE_TOOL_INPUT || '{}');
const filePath = input.file_path || '';

const isIterationLog = filePath.includes('IterationLog') || filePath.includes('iteration-log');
const isRetrospective = filePath.includes('Retrospective') || filePath.includes('retrospective');

if ((isIterationLog || isRetrospective) && filePath.endsWith('.json')) {
  try {
    const fs = require('fs');
    if (fs.existsSync(filePath)) {
      const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      const data = content.data || content;

      // Check for incomplete items
      const incomplete = data.incompleteItems || [];
      const backlogItems = data.backlogItems || [];
      const inProgress = backlogItems.filter(i =>
        i.status === 'in-progress' || i.status === 'todo' || i.status === 'review'
      );

      const carryCount = incomplete.length + inProgress.length;

      if (carryCount > 0) {
        console.log(`[u-maker] WARNING: ${carryCount} incomplete item(s) detected during iteration close. These will carry over to the next iteration. Review carry-over impact before finalizing.`);
      }
    }
  } catch (e) {
    // Silent fail - non-critical hook
  }
}
