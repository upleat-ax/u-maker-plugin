#!/usr/bin/env node
/**
 * prompt-docs-first-guard.js — u-ssot UserPromptSubmit Hook
 *
 * Detects prompts that imply new requirements, features, or user stories,
 * and injects a reminder to update SSoT documents BEFORE implementing.
 *
 * Input:  JSON from stdin with { prompt, ... }
 * Output: JSON with additionalContext (non-blocking) or plain success
 */

const fs = require('fs');

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

const prompt = (input.prompt || '').trim();

if (!prompt) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// ============================================================
// Skip: already using a document-update slash command
// ============================================================

const DOC_COMMANDS = [
  '/u-us-add', '/u-fr-add', '/u-srs', '/u-plan', '/u-design',
  '/u-backlog-add', '/u-erd', '/u-api', '/u-screen', '/u-index',
  '/u-create-project', '/u-init', '/u-check', '/u-act',
  '/u-loop', '/u-loop-from', '/u-dev', '/u-fe', '/u-be',
  '/u-test', '/u-bug-report', '/u-gap-detector',
  '/u-validate', '/u-status', '/u-docs', '/u-backlog',
  '/u-help', '/u-history', '/u-archive', '/u-storybook',
  '/u-build', '/u-summary', '/u-git-pr', '/u-stop', '/u-resume',
];

const promptLower = prompt.toLowerCase();

if (DOC_COMMANDS.some(cmd => promptLower.startsWith(cmd))) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// ============================================================
// Skip: prompt is about document updates already
// ============================================================

const DOC_AWARE_PATTERNS = [
  /문서\s*(수정|갱신|업데이트|작성|생성)/,
  /SRS\s*(수정|갱신|업데이트|작성)/i,
  /Roadmap\s*(수정|갱신|업데이트|작성)/i,
  /update\s+(document|srs|roadmap)/i,
];

if (DOC_AWARE_PATTERNS.some(p => p.test(prompt))) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// ============================================================
// Detect: requirement / feature / user story change intent
// ============================================================

// Korean patterns
const KO_PATTERNS = [
  // 기능 추가/만들기/생성
  /(?:새로운?|신규)\s*기능/,
  /기능\s*(?:추가|만들|생성|개발|구현)/,
  // 요구사항 추가/변경
  /요구사항\s*(?:추가|변경|수정)/,
  // 유저 스토리 추가
  /(?:유저|사용자)\s*스토리\s*(?:추가|새|생성)?/,
  // 페이지/화면 추가
  /(?:페이지|화면|스크린)\s*(?:추가|만들|새로|생성)/,
  // API/엔드포인트 추가
  /(?:API|엔드포인트|api)\s*(?:추가|만들|새로|생성)/,
  // ~하는 기능을 추가/만들어
  /(?:하는|할 수 있는)\s*기능/,
  // 새 + noun
  /새\s*(?:기능|페이지|화면|API|엔드포인트)/,
  // ~해줘/해주세요 + feature context (broad but useful)
  /(?:추가|만들|생성|개발|구현).*(?:해줘|해주세요|해 줘|해 주세요|하자|합시다)/,
  // User story format: ~로서 ~하고 싶다
  /(?:로서|으로서)\s.*(?:하고 싶|원한|필요)/,
];

// English patterns
const EN_PATTERNS = [
  /(?:add|create|build|implement|develop)\s+(?:a\s+)?(?:new\s+)?(?:feature|functionality|capability)/i,
  /new\s+(?:feature|requirement|user\s*story|page|screen|endpoint|api)/i,
  /(?:add|create)\s+(?:a\s+)?(?:page|screen|endpoint|api|route)/i,
  /(?:modify|change|update|revise)\s+(?:the\s+)?(?:requirement|feature|spec|specification)/i,
  /(?:user\s*story|use\s*case|scenario)\s+(?:add|create|new)/i,
  /(?:as\s+a\s+\w+,?\s+I\s+want\s+to)/i,
  /I\s+(?:want|need)\s+(?:a\s+)?(?:new\s+)?(?:feature|page|screen|endpoint)/i,
];

const matched =
  KO_PATTERNS.some(p => p.test(prompt)) ||
  EN_PATTERNS.some(p => p.test(prompt));

if (!matched) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// ============================================================
// Inject: "Documents First" reminder
// ============================================================

const reminder = [
  '# SSoT Documents-First Reminder',
  '',
  'The user\'s request appears to involve adding or modifying requirements, features, or user stories.',
  '',
  '**Before implementing code, guide the user to update SSoT documents first:**',
  '',
  '1. **New User Story** → Suggest `/u-us-add` to add to `1_Roadmap_PM.md`',
  '2. **New Functional Requirement** → Suggest `/u-fr-add` to add to `1_SRS_RA.md`',
  '3. **Multiple changes** → Suggest `/u-plan` or `/u-srs` for full document regeneration',
  '4. **Bug/defect** → Suggest `/u-backlog-add` to add to `backlog.md`',
  '',
  'Only proceed to implementation after the relevant SSoT documents have been updated.',
  'This ensures traceability (US → FR → ERD → API → Code → Test).',
].join('\n');

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext: reminder,
  },
}));
process.exit(0);
