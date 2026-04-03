// on-doc-change.js
// Trigger: .md file changed in docs/
// Action: flag JSON companion for sync check
const fs = require('fs');
const path = require('path');

module.exports = async function onDocChange({ filePath, projectRoot }) {
  const umaker = path.join(projectRoot, '.u-maker');
  const docsDir = path.join(umaker, 'docs');

  if (!filePath.startsWith(docsDir) || !filePath.endsWith('.md')) return;

  const jsonPath = filePath.replace(/\.md$/, '.json');
  if (fs.existsSync(jsonPath)) {
    const companion = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    companion._syncRequired = true;
    companion._lastMdChange = new Date().toISOString();
    fs.writeFileSync(jsonPath, JSON.stringify(companion, null, 2));
  }
};
