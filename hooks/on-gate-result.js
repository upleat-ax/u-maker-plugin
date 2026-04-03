// on-gate-result.js
// Trigger: loop-state.json updated
// Action: check if loop should continue or stop
const fs = require('fs');
const path = require('path');

module.exports = async function onGateResult({ filePath, projectRoot }) {
  const umaker = path.join(projectRoot, '.u-maker');
  const statePath = path.join(umaker, '.state', 'loop-state.json');

  if (filePath !== statePath) return;

  const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));

  if (!state.loopActive) return;

  if (state.avgScore >= 95) {
    state.loopActive = false;
    state.result = 'PASS';
    state.completedAt = new Date().toISOString();
  } else if (state.retryCount >= 3) {
    state.loopActive = false;
    state.result = 'ESCALATE';
    state.completedAt = new Date().toISOString();
  }

  fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
};
