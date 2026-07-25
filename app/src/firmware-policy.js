const FONT_INSTALLER_UNVERIFIED_FROM = Object.freeze({
  major: 3,
  minor: 28
});

function parseSoftwareVersion(rawVersion) {
  const match = String(rawVersion || '').match(
    /(?:^|[^0-9])(\d+)\.(\d+)(?:\.(\d+))?(?:\.(\d+))?/
  );

  if (!match) {
    return null;
  }

  const parts = match.slice(1).map((part) => Number.parseInt(part || '0', 10));
  return {
    major: parts[0],
    minor: parts[1],
    patch: parts[2],
    build: parts[3],
    display: match[0].replace(/^[^0-9]+/, '')
  };
}

function assessFontInstallerSupport(rawVersion) {
  const version = parseSoftwareVersion(rawVersion);

  if (!version) {
    return {
      allowed: false,
      status: 'unknown',
      version: null,
      reason: '無法確認 reMarkable software 版本；為免改壞系統，已停止字體安裝。'
    };
  }

  const isUnverified =
    version.major > FONT_INSTALLER_UNVERIFIED_FROM.major ||
    (
      version.major === FONT_INSTALLER_UNVERIFIED_FROM.major &&
      version.minor >= FONT_INSTALLER_UNVERIFIED_FROM.minor
    );

  if (isUnverified) {
    return {
      allowed: false,
      status: 'unverified',
      version,
      reason: `${version.display} 嘅中文閱讀／字體安裝未經實機驗證，已暫停安裝。`
    };
  }

  return {
    allowed: true,
    status: 'legacy',
    version,
    reason: `${version.display} 只會使用原有 legacy 字體安裝流程。`
  };
}

module.exports = {
  FONT_INSTALLER_UNVERIFIED_FROM,
  assessFontInstallerSupport,
  parseSoftwareVersion
};
