#!/usr/bin/env node

/**
 * Hook: on-check-fail
 * Trigger: PostToolUse(Write)
 * Purpose: Detect test reports with failures and suggest bug registration
 */

const input = JSON.parse(process.env.CLAUDE_TOOL_INPUT || '{}');
const filePath = input.file_path || '';

const isTestReport = filePath.includes('test-report') ||
                     filePath.includes('qa-report') ||
                     filePath.includes('QA_Report') ||
                     filePath.includes('Case_QA');

if (isTestReport && filePath.endsWith('.json')) {
  try {
    const fs = require('fs');
    if (fs.existsSync(filePath)) {
      const report = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      const data = report.data || report;

      // Check for failures in various report formats
      const failures = data.failures || data.failedCount || 0;
      const critical = data.criticalDefects || 0;
      const major = data.majorDefects || 0;

      if (failures > 0 || critical > 0 || major > 0) {
        const parts = [];
        if (critical > 0) parts.push(`${critical} critical`);
        if (major > 0) parts.push(`${major} major`);
        if (failures > 0 && critical === 0 && major === 0) parts.push(`${failures} failure(s)`);

        console.log(`[u-maker] Test failures detected: ${parts.join(', ')}. Run /u-skill-backlog-add type=bug to register defects.`);
      }
    }
  } catch (e) {
    // Silent fail - non-critical hook
  }
}
