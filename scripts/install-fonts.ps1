# =============================================================================
# reMarkable Chinese Toolkit - Legacy Font Installer (Windows PowerShell)
# =============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  reMarkable Chinese Toolkit                       ║" -ForegroundColor Cyan
Write-Host "║  Legacy Chinese Font Installer                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# --- Gather info ---
$RM_IP = Read-Host "reMarkable IP (default: 10.11.99.1)"
if ([string]::IsNullOrWhiteSpace($RM_IP)) { $RM_IP = "10.11.99.1" }

$RM_PASS = Read-Host "SSH Password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($RM_PASS)
$RM_PASS_PLAIN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host ""
Write-Host "請輸入字體檔案路徑（支援 .ttf / .otf）" -ForegroundColor Yellow
Write-Host "可以輸入單個檔案或整個資料夾：" -ForegroundColor Yellow
$FONT_PATH = Read-Host "Font path"

# --- Validate ---
if (-not (Test-Path $FONT_PATH)) {
    Write-Host "❌ 路徑不存在: $FONT_PATH" -ForegroundColor Red
    exit 1
}

# --- Collect font files ---
$fontFiles = @()
if (Test-Path $FONT_PATH -PathType Container) {
    $fontFiles = Get-ChildItem -Path $FONT_PATH -Recurse -Include "*.ttf", "*.otf"
} else {
    $fontFiles = @(Get-Item $FONT_PATH)
}

if ($fontFiles.Count -eq 0) {
    Write-Host "❌ 搵唔到 .ttf 或 .otf 字體檔案" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "搵到 $($fontFiles.Count) 個字體檔案：" -ForegroundColor Green
foreach ($f in $fontFiles) {
    Write-Host "  → $($f.Name)"
}
Write-Host ""

# --- Check if ssh/scp available ---
$sshAvailable = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $sshAvailable) {
    Write-Host "❌ 搵唔到 ssh 命令。請確認已安裝 OpenSSH。" -ForegroundColor Red
    Write-Host "Windows 10/11 通常已內建，試下喺 Settings → Apps → Optional Features → OpenSSH Client" -ForegroundColor Yellow
    exit 1
}

# --- Test connection ---
Write-Host "[1/6] 測試 SSH 連接..." -ForegroundColor Cyan
try {
    $result = echo y | ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@$RM_IP "echo ok" 2>&1
} catch {}
Write-Host "⚠️  如果要求輸入密碼，請輸入你嘅 SSH 密碼" -ForegroundColor Yellow

# --- Firmware compatibility gate ---
$versionRaw = (ssh root@$RM_IP "cat /etc/version 2>/dev/null || true").Trim()
$versionMatch = [regex]::Match($versionRaw, '\d+\.\d+(?:\.\d+){0,2}')

if (-not $versionMatch.Success) {
    Write-Host "⛔ 無法確認 reMarkable software 版本，已停止安裝。" -ForegroundColor Red
    Write-Host "未知 firmware 唔可以安全使用 legacy 字體安裝器。" -ForegroundColor Yellow
    exit 1
}

$versionParts = $versionMatch.Value.Split('.')
$versionMajor = [int]$versionParts[0]
$versionMinor = [int]$versionParts[1]

Write-Host "reMarkable software: $($versionMatch.Value)" -ForegroundColor Cyan
if ($versionMajor -gt 3 -or ($versionMajor -eq 3 -and $versionMinor -ge 28)) {
    Write-Host "⛔ $($versionMatch.Value) 嘅中文閱讀／字體安裝未經實機驗證。" -ForegroundColor Red
    Write-Host "已停止安裝，避免修改未知嘅系統字體或 Xochitl 設定。" -ForegroundColor Yellow
    exit 1
}

# --- Create remote directories ---
Write-Host "[2/6] 建立字體目錄..." -ForegroundColor Cyan
ssh root@$RM_IP "mkdir -p /home/root/.local/share/fonts/"
Write-Host "✅ 目錄就緒" -ForegroundColor Green

# --- Upload fonts ---
Write-Host "[3/6] 上傳字體檔案..." -ForegroundColor Cyan
foreach ($f in $fontFiles) {
    Write-Host "  ↑ $($f.Name)"
    scp "$($f.FullName)" "root@${RM_IP}:/home/root/.local/share/fonts/"
}
Write-Host "✅ 上傳完成" -ForegroundColor Green

# --- Setup fontconfig ---
Write-Host "[4/6] 設定 fontconfig..." -ForegroundColor Cyan

$fontsConfContent = @'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif TC</family>
      <family>Noto Serif SC</family>
    </prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Serif TC</family>
      <family>Noto Serif SC</family>
    </prefer>
  </alias>
  <alias>
    <family>Noto Sans</family>
    <prefer>
      <family>Noto Serif TC</family>
      <family>Noto Serif SC</family>
    </prefer>
  </alias>
  <alias>
    <family>Noto Sans UI</family>
    <prefer>
      <family>Noto Serif TC</family>
      <family>Noto Serif SC</family>
    </prefer>
  </alias>
  <alias>
    <family>Noto Mono</family>
    <prefer>
      <family>Noto Serif TC</family>
      <family>Noto Serif SC</family>
    </prefer>
  </alias>
  <match target="pattern">
    <edit name="family" mode="append">
      <family>Noto Serif TC</family>
      <family>Noto Serif SC</family>
    </edit>
  </match>
</fontconfig>
'@

# Write to temp file and scp
$tempFile = [System.IO.Path]::GetTempFileName()
$fontsConfContent | Out-File -FilePath $tempFile -Encoding utf8 -NoNewline
scp $tempFile "root@${RM_IP}:/home/root/.fonts.conf"
Remove-Item $tempFile
Write-Host "✅ Fontconfig 設定完成" -ForegroundColor Green

# --- Setup restore script ---
Write-Host "[5/6] 設定 OS Update 自動修復..." -ForegroundColor Cyan

$restoreScript = @'
#!/bin/sh
FONT_SRC="/home/root/.local/share/fonts"
FONT_DST="/usr/share/fonts/ttf/chinese"

if [ -d "$FONT_SRC" ] && [ ! -d "$FONT_DST" ]; then
    mount -o remount,rw /
    mkdir -p "$FONT_DST"
    cp "$FONT_SRC"/*.ttf "$FONT_DST"/ 2>/dev/null
    cp "$FONT_SRC"/*.otf "$FONT_DST"/ 2>/dev/null
    chmod 644 "$FONT_DST"/* 2>/dev/null
    mount -o remount,ro / 2>/dev/null
fi

fc-cache -f -v

if [ ! -f "/etc/systemd/system/xochitl.service.d/fonts.conf" ]; then
    mkdir -p /etc/systemd/system/xochitl.service.d/
    printf "[Service]\nExecStartPre=/home/root/restore-fonts.sh\n" > /etc/systemd/system/xochitl.service.d/fonts.conf
    systemctl daemon-reload
fi
'@

$tempFile2 = [System.IO.Path]::GetTempFileName()
$restoreScript | Out-File -FilePath $tempFile2 -Encoding utf8 -NoNewline
scp $tempFile2 "root@${RM_IP}:/home/root/restore-fonts.sh"
Remove-Item $tempFile2
ssh root@$RM_IP "chmod +x /home/root/restore-fonts.sh"

$profileContent = @'
if [ ! -d "/usr/share/fonts/ttf/chinese" ] || [ ! -f "/etc/systemd/system/xochitl.service.d/fonts.conf" ]; then
    /home/root/restore-fonts.sh
    systemctl restart xochitl
fi
'@

$tempFile3 = [System.IO.Path]::GetTempFileName()
$profileContent | Out-File -FilePath $tempFile3 -Encoding utf8 -NoNewline
scp $tempFile3 "root@${RM_IP}:/home/root/.profile"
Remove-Item $tempFile3
Write-Host "✅ 自動修復設定完成" -ForegroundColor Green

# --- Install + restart ---
Write-Host "[6/6] 安裝字體到系統並重啟介面..." -ForegroundColor Cyan
ssh root@$RM_IP "/home/root/restore-fonts.sh && systemctl restart xochitl"
Write-Host "✅ 安裝完成！" -ForegroundColor Green

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  🎉 安裝成功！                                    ║" -ForegroundColor Green
Write-Host "║                                                  ║" -ForegroundColor Green
Write-Host "║  • PDF/EPUB 中文 → 自動顯示                      ║" -ForegroundColor Green
Write-Host "║  • 主介面書名 → 已修復                            ║" -ForegroundColor Green
Write-Host "║  • OS 更新後 → SSH 登入一次即自動修復              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
