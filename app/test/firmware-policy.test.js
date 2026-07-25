const assert = require('node:assert/strict');
const test = require('node:test');

const {
  assessFontInstallerSupport,
  parseSoftwareVersion
} = require('../src/firmware-policy');

test('parses a four-part reMarkable software version from command output', () => {
  assert.deepEqual(parseSoftwareVersion('Version: 3.28.0.163\n'), {
    major: 3,
    minor: 28,
    patch: 0,
    build: 163,
    display: '3.28.0.163'
  });
});

test('keeps the legacy installer available below 3.28', () => {
  const policy = assessFontInstallerSupport('3.27.0.97');
  assert.equal(policy.allowed, true);
  assert.equal(policy.status, 'legacy');
});

test('blocks the unverified 3.28 beta build', () => {
  const policy = assessFontInstallerSupport('3.28.0.163');
  assert.equal(policy.allowed, false);
  assert.equal(policy.status, 'unverified');
  assert.match(policy.reason, /未經實機驗證/);
});

test('blocks later firmware until it has an explicit compatibility review', () => {
  assert.equal(assessFontInstallerSupport('3.29.1.2').allowed, false);
  assert.equal(assessFontInstallerSupport('4.0.0.1').allowed, false);
});

test('fails closed when the software version cannot be identified', () => {
  const policy = assessFontInstallerSupport('reMarkable');
  assert.equal(policy.allowed, false);
  assert.equal(policy.status, 'unknown');
});
