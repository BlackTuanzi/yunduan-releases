/**
 * 扫描本目录下的安装包，生成 SHA256SUMS.txt 与 releases.json
 * 用法：node tools/update-manifest.js
 *
 * 文件名约定：雲端-<版本>-<类型>.exe
 *   例：雲端-1.2.0-beta.12-便携版.exe
 */
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.resolve(__dirname, '..');
const NAME_RE = /^雲端-(.+?)-(便携版|安装版)\.exe$/;

function sha256(file) {
  return new Promise(function (resolve, reject) {
    const hash = crypto.createHash('sha256');
    const stream = fs.createReadStream(file);
    stream.on('data', function (chunk) { hash.update(chunk); });
    stream.on('error', reject);
    stream.on('end', function () { resolve(hash.digest('hex')); });
  });
}

function fmtSize(bytes) {
  return (bytes / 1024 / 1024).toFixed(1) + ' MB';
}

(async function main() {
  const entries = fs.readdirSync(ROOT)
    .filter(function (name) { return NAME_RE.test(name); })
    .map(function (name) {
      const m = name.match(NAME_RE);
      const stat = fs.statSync(path.join(ROOT, name));
      return {
        name: name,
        version: m[1],
        kind: m[2],
        size: stat.size,
        mtime: stat.mtime
      };
    })
    .sort(function (a, b) {
      if (a.version !== b.version) return a.version < b.version ? 1 : -1;
      return a.kind === '便携版' ? -1 : 1;
    });

  if (!entries.length) {
    console.error('没有找到形如 雲端-<版本>-<便携版|安装版>.exe 的文件');
    process.exit(1);
  }

  for (const entry of entries) {
    entry.sha256 = await sha256(path.join(ROOT, entry.name));
  }

  // SHA256SUMS.txt：兼容 sha256sum -c 的格式
  const sums = entries.map(function (e) {
    return e.sha256 + '  ' + e.name;
  }).join('\n') + '\n';
  fs.writeFileSync(path.join(ROOT, 'SHA256SUMS.txt'), sums, 'utf8');

  // releases.json：按版本聚合，便于脚本读取
  const byVersion = new Map();
  entries.forEach(function (e) {
    if (!byVersion.has(e.version)) {
      byVersion.set(e.version, { version: e.version, builtAt: null, files: [] });
    }
    const group = byVersion.get(e.version);
    const iso = e.mtime.toISOString();
    if (!group.builtAt || iso < group.builtAt) group.builtAt = iso;
    group.files.push({
      kind: e.kind,
      name: e.name,
      size: e.size,
      sizeText: fmtSize(e.size),
      sha256: e.sha256
    });
  });

  const manifest = {
    product: '雲端',
    company: '雲阁科技工作室',
    author: 'BlackTuanzi',
    updatedAt: new Date().toISOString(),
    note: '本目录只保存构建产物与清单；安装包本身被 .gitignore 排除。',
    releases: Array.from(byVersion.values())
  };
  fs.writeFileSync(path.join(ROOT, 'releases.json'),
    JSON.stringify(manifest, null, 2) + '\n', 'utf8');

  console.log('已更新 SHA256SUMS.txt 与 releases.json');
  entries.forEach(function (e) {
    console.log('  ' + e.name + '  ' + fmtSize(e.size) + '  ' + e.sha256.slice(0, 16) + '…');
  });
})();
