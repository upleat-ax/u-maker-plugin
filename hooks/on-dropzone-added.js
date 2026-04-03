// on-dropzone-added.js
// Trigger: file added to data/dropzone/
// Action: mark file for digest generation in _index.json
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

module.exports = async function onDropzoneAdded({ filePath, projectRoot }) {
  const umaker = path.join(projectRoot, '.u-maker');
  const dropzone = path.join(umaker, 'data', 'dropzone');
  const digestDir = path.join(umaker, 'data', 'digest');
  const indexPath = path.join(digestDir, '_index.json');

  if (!filePath.startsWith(dropzone)) return;

  const relativePath = path.relative(dropzone, filePath);
  const content = fs.readFileSync(filePath);
  const hash = crypto.createHash('sha256').update(content).digest('hex');

  let index = { files: [] };
  if (fs.existsSync(indexPath)) {
    index = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
  }

  const existing = index.files.find(f => f.path === relativePath);
  if (existing) {
    if (existing.hash !== hash) {
      existing.hash = hash;
      existing.status = 'pending';
      existing.updatedAt = new Date().toISOString();
    }
  } else {
    index.files.push({
      path: relativePath,
      hash,
      status: 'pending',
      addedAt: new Date().toISOString()
    });
  }

  fs.mkdirSync(path.dirname(indexPath), { recursive: true });
  fs.writeFileSync(indexPath, JSON.stringify(index, null, 2));
};
