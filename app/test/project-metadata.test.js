const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const appRoot = path.join(__dirname, '..');
const packageJson = require(path.join(appRoot, 'package.json'));
const indexHtml = fs.readFileSync(path.join(appRoot, 'src', 'index.html'), 'utf8');

test('desktop package uses the Toolkit identity', () => {
  assert.equal(packageJson.name, 'remarkable-chinese-toolkit');
  assert.equal(packageJson.build.appId, 'com.remarkable.chinese-toolkit');
  assert.equal(packageJson.build.productName, 'reMarkable Chinese Toolkit');
});

test('desktop UI exposes the input-method development status', () => {
  assert.match(indexHtml, /<title>reMarkable Chinese Toolkit<\/title>/);
  assert.match(indexHtml, /中文輸入法：prototype/);
  assert.match(indexHtml, /3\.28 stable SDK/);
});
