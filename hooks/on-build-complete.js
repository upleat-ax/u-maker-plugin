#!/usr/bin/env node

/**
 * Hook: on-build-complete
 * Trigger: PostToolUse(Write)
 * Purpose: Detect generated code files and suggest running /u-qa
 */

const input = JSON.parse(process.env.CLAUDE_TOOL_INPUT || '{}');
const filePath = input.file_path || '';

const codeExtensions = ['.tsx', '.ts', '.jsx', '.js', '.vue', '.svelte'];
const isCodeFile = codeExtensions.some(ext => filePath.endsWith(ext));
const isInSrc = filePath.includes('/src/') || filePath.includes('/app/') || filePath.includes('/pages/');
const isNotHook = !filePath.includes('/hooks/') || !filePath.includes('u-maker-plugin');
const isNotTest = !filePath.includes('.test.') && !filePath.includes('.spec.');

if (isCodeFile && isInSrc && isNotHook && isNotTest) {
  const fileName = filePath.split('/').pop();
  console.log(`[u-maker] Code file generated: ${fileName}. Run /u-qa to validate build and tests.`);
}
