#!/usr/bin/env node
/**
 * prompt-docs-first-guard.js — u-maker UserPromptSubmit Hook
 *
 * Detects prompts that imply new requirements, features, or user stories,
 * and BLOCKS Claude from implementing until the user updates SSoT docs first.
 *
 * Input:  JSON from stdin with { prompt, ... }
 * Output: JSON with systemMessage (blocking reminder) or plain success
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
  '/u-agent-us-add', '/u-agent-fr-add', '/u-skill-srs', '/u-skill-plan', '/u-skill-design',
  '/u-agent-backlog-add', '/u-skill-erd', '/u-skill-api', '/u-agent-screen', '/u-agent-index',
  '/u-agent-create-project', '/u-skill-init', '/u-skill-check', '/u-skill-act',
  '/u-skill-loop', '/u-skill-loop-from', '/u-skill-dev', '/u-agent-dv-fe', '/u-agent-dv-be',
  '/u-agent-qa', '/u-agent-bug-report', '/u-skill-gap-detector',
  '/u-agent-validate', '/u-agent-status', '/u-agent-docs', '/u-agent-backlog',
  '/u-skill-help', '/u-agent-history', '/u-agent-archive', '/u-skill-storybook',
  '/u-skill-build', '/u-skill-git-pr', '/u-skill-stop', '/u-skill-resume',
  '/u-agent-summary', '/u-agent-wireframe', '/u-agent-ux-design', '/u-agent-ux-ds',
  '/u-agent-pm', '/u-skill-report',
];

const promptLower = prompt.toLowerCase();

if (DOC_COMMANDS.some(cmd => promptLower.startsWith(cmd))) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// ============================================================
// Skip: prompt is explicitly about document updates
// ============================================================

const DOC_AWARE_PATTERNS = [
  /문서\s*(수정|갱신|업데이트|작성|생성|먼저|부터)/,
  /SRS\s*(수정|갱신|업데이트|작성|에\s*추가)/i,
  /Roadmap\s*(수정|갱신|업데이트|작성)/i,
  /update\s+(document|docs|srs|roadmap|\.u-maker)/i,
  /modify\s+(document|docs|srs|spec)/i,
  /\.u-maker\/docs\s*(수정|갱신|업데이트|먼저)/,
  // User acknowledging the docs-first reminder
  /(?:알겠|먼저\s*문서|문서\s*먼저|문서부터|문서\s*업데이트\s*할)/,
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
  // 기능 추가/만들기/생성/개발
  /(?:새로운?|신규)\s*기능/,
  /기능\s*(?:추가|만들|생성|개발|구현|넣|붙)/,
  // 요구사항 추가/변경
  /요구사항\s*(?:추가|변경|수정|새)/,
  // 유저 스토리 추가
  /(?:유저|사용자)\s*스토리\s*(?:추가|새|생성)?/,
  // 페이지/화면 추가
  /(?:페이지|화면|스크린)\s*(?:추가|만들|새로|생성|넣)/,
  // API/엔드포인트 추가
  /(?:API|엔드포인트|api|라우트|route)\s*(?:추가|만들|새로|생성)/,
  // ~하는 기능
  /(?:하는|할 수 있는|해주는)\s*기능/,
  // 새 + noun
  /새\s*(?:기능|페이지|화면|API|엔드포인트|컴포넌트|모듈|서비스)/,
  // ~해줘/해주세요 + 추가/생성/만들
  /(?:추가|만들|생성|개발|구현).*(?:해줘|해주세요|해 줘|해 주세요|하자|합시다|해봐|해봅시다)/,
  // User story format: ~로서 ~하고 싶다
  /(?:로서|으로서)\s.*(?:하고 싶|원한|필요)/,
  // ~기능을 넣어줘 / ~를 추가해줘
  /(?:을|를|에)\s*(?:추가|넣어|붙여|달아)(?:줘|주세요|줄래|줄 수)/,
  // 없는 기능 / 안 되는 기능
  /(?:없는|안\s*되는|지원\s*안|미지원)\s*(?:기능|기능인데|기능이)/,
  // ~하고 싶어 (desire expression)
  /(?:하고\s*싶어|하고\s*싶은데|했으면\s*좋겠|됐으면\s*좋겠)/,
  // 컴포넌트/모듈/서비스 추가
  /(?:컴포넌트|모듈|서비스|위젯)\s*(?:추가|만들|생성|새로)/,
  // ~을 구현
  /(?:을|를)\s*구현/,
];

// English patterns
const EN_PATTERNS = [
  /(?:add|create|build|implement|develop)\s+(?:a\s+)?(?:new\s+)?(?:feature|functionality|capability|function)/i,
  /new\s+(?:feature|requirement|user\s*story|page|screen|endpoint|api|route|component|module|service)/i,
  /(?:add|create)\s+(?:a\s+)?(?:page|screen|endpoint|api|route|component|module)/i,
  /(?:modify|change|update|revise)\s+(?:the\s+)?(?:requirement|feature|spec|specification|behavior)/i,
  /(?:user\s*story|use\s*case|scenario)\s+(?:add|create|new)/i,
  /(?:as\s+a\s+\w+,?\s+I\s+want\s+to)/i,
  /I\s+(?:want|need|would\s+like)\s+(?:a\s+)?(?:new\s+)?(?:feature|page|screen|endpoint|functionality)/i,
  /(?:can\s+you|could\s+you|please)\s+(?:add|create|implement|build)\s+/i,
  /(?:it\s+would\s+be\s+(?:nice|great|good)\s+to\s+(?:have|add))/i,
  /(?:missing\s+feature|not\s+(?:yet\s+)?implemented|doesn'?t\s+(?:support|have))/i,
  /(?:make\s+it\s+(?:so\s+that|able\s+to))/i,
];

const matched =
  KO_PATTERNS.some(p => p.test(prompt)) ||
  EN_PATTERNS.some(p => p.test(prompt));

if (!matched) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// ============================================================
// Determine best doc command suggestion based on prompt content
// ============================================================

function suggestCommand(text) {
  const t = text.toLowerCase();
  if (/(?:유저|사용자)\s*스토리|user\s*story|as\s+a\s+\w+/.test(t)) {
    return '`/u-agent-us-add` — 유저 스토리 추가 후 SRS 연계';
  }
  if (/(?:api|엔드포인트|endpoint|route|라우트)/.test(t)) {
    return '`/u-skill-api` — API Contract 문서 갱신';
  }
  if (/(?:페이지|화면|스크린|page|screen)/.test(t)) {
    return '`/u-agent-screen` — 화면 설계 문서 갱신';
  }
  if (/(?:report|리포트|보고서|daily report|daily|데일리)/.test(t)) {
    return '`/u-skill-report` — 프로젝트 종합 보고서 생성';
  }
  if (/(?:erd|데이터|db|database|테이블|table|모델|model)/.test(t)) {
    return '`/u-skill-erd` — ERD 문서 갱신';
  }
  if (/(?:버그|bug|오류|error|결함|defect|수정|fix)/.test(t)) {
    return '`/u-agent-backlog-add` — 백로그에 결함/이슈 등록';
  }
  return '`/u-agent-fr-add` — FR(기능 요구사항) 추가 또는 `/u-skill-srs` — SRS 전체 갱신';
}

const suggestion = suggestCommand(prompt);

// ============================================================
// Output: STOP + docs-first directive (systemMessage = root level)
// ============================================================

const systemMessage = [
  '[u-maker] DOCS-FIRST GUARD 발동',
  '',
  '사용자의 프롬프트에 새로운 요구사항, 기능, 또는 화면 추가/변경 의도가 감지되었습니다.',
  '',
  '⚠️  구현 코드 작성 전에 반드시 SSoT 문서를 먼저 수정해야 합니다.',
  '',
  '지금 즉시 아래와 같이 사용자에게 안내하십시오:',
  '',
  `추천 명령어: ${suggestion}`,
  '',
  '안내 규칙:',
  '1. 코드 작성이나 구현을 시작하지 마십시오.',
  '2. 사용자에게 위 문서 수정 명령어를 먼저 실행할 것을 요청하십시오.',
  '3. 문서가 갱신된 후에만 구현을 진행하십시오.',
  '4. 사용자가 이미 문서를 갱신했다고 확인해 주면 그때 구현을 시작하십시오.',
  '',
  'SSoT 추적 체계: Roadmap → SRS(FR→US→FT(Feature)) → ERD → API → Code → Test',
].join('\n');

console.log(JSON.stringify({
  systemMessage,
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext: systemMessage,
  },
}));
process.exit(0);
