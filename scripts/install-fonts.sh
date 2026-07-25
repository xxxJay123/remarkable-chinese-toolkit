#!/bin/bash
# =============================================================================
# reMarkable Chinese Toolkit - Legacy Font Installer (macOS / Linux)
# =============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  reMarkable Chinese Toolkit                       ║${NC}"
echo -e "${CYAN}║  Legacy Chinese Font Installer                    ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# --- Gather info ---
read -p "reMarkable IP (default: 10.11.99.1): " RM_IP
RM_IP=${RM_IP:-10.11.99.1}

read -sp "SSH Password: " RM_PASS
echo ""

echo ""
echo -e "${YELLOW}請輸入字體檔案路徑（支援 .ttf / .otf）${NC}"
echo -e "${YELLOW}可以輸入單個檔案或整個資料夾：${NC}"
read -p "Font path: " FONT_PATH

# --- Validate ---
if [ ! -e "$FONT_PATH" ]; then
    echo -e "${RED}❌ 路徑不存在: $FONT_PATH${NC}"
    exit 1
fi

# --- Collect font files ---
FONT_FILES=()
if [ -d "$FONT_PATH" ]; then
    while IFS= read -r -d '' file; do
        FONT_FILES+=("$file")
    done < <(find "$FONT_PATH" -type f \( -name "*.ttf" -o -name "*.otf" \) -print0)
else
    FONT_FILES=("$FONT_PATH")
fi

if [ ${#FONT_FILES[@]} -eq 0 ]; then
    echo -e "${RED}❌ 搵唔到 .ttf 或 .otf 字體檔案${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}搵到 ${#FONT_FILES[@]} 個字體檔案：${NC}"
for f in "${FONT_FILES[@]}"; do
    echo "  → $(basename "$f")"
done
echo ""

# --- Check SSH connection ---
echo -e "${CYAN}[1/6] 測試 SSH 連接...${NC}"
if ! sshpass -p "$RM_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@"$RM_IP" "echo ok" > /dev/null 2>&1; then
    echo -e "${RED}❌ 無法連接到 reMarkable ($RM_IP)${NC}"
    echo -e "${YELLOW}請確認：${NC}"
    echo "  1. USB 線已連接 或 同一 WiFi"
    echo "  2. IP 同密碼正確"
    echo "  3. 已安裝 sshpass (brew install sshpass / apt install sshpass)"
    exit 1
fi
echo -e "${GREEN}✅ 連接成功${NC}"

# --- Firmware compatibility gate ---
RM_VERSION_RAW=$(sshpass -p "$RM_PASS" ssh root@"$RM_IP" "cat /etc/version 2>/dev/null || true" 2>/dev/null)
RM_VERSION=$(printf '%s' "$RM_VERSION_RAW" | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+){0,2}' | head -1 || true)

if [ -z "$RM_VERSION" ]; then
    echo -e "${RED}⛔ 無法確認 reMarkable software 版本，已停止安裝。${NC}"
    echo -e "${YELLOW}未知 firmware 唔可以安全使用 legacy 字體安裝器。${NC}"
    exit 1
fi

IFS='.' read -r RM_MAJOR_TEXT RM_MINOR_TEXT _ <<< "$RM_VERSION"
RM_MAJOR=$((10#$RM_MAJOR_TEXT))
RM_MINOR=$((10#$RM_MINOR_TEXT))

echo -e "${CYAN}reMarkable software: $RM_VERSION${NC}"
if (( RM_MAJOR > 3 || (RM_MAJOR == 3 && RM_MINOR >= 28) )); then
    echo -e "${RED}⛔ $RM_VERSION 嘅中文閱讀／字體安裝未經實機驗證。${NC}"
    echo -e "${YELLOW}已停止安裝，避免修改未知嘅系統字體或 Xochitl 設定。${NC}"
    exit 1
fi

# --- Create remote directories ---
echo -e "${CYAN}[2/6] 建立字體目錄...${NC}"
sshpass -p "$RM_PASS" ssh root@"$RM_IP" "mkdir -p /home/root/.local/share/fonts/"
echo -e "${GREEN}✅ 目錄就緒${NC}"

# --- Upload fonts ---
echo -e "${CYAN}[3/6] 上傳字體檔案...${NC}"
for f in "${FONT_FILES[@]}"; do
    echo "  ↑ $(basename "$f")"
    sshpass -p "$RM_PASS" scp "$f" root@"$RM_IP":/home/root/.local/share/fonts/
done
echo -e "${GREEN}✅ 上傳完成${NC}"

# --- Extract font family names for .fonts.conf ---
echo -e "${CYAN}[4/6] 設定 fontconfig...${NC}"

# Get list of uploaded font families from the device
FONT_FAMILIES=$(sshpass -p "$RM_PASS" ssh root@"$RM_IP" "fc-cache -f 2>/dev/null; fc-list /home/root/.local/share/fonts/ --format='%{family}\n'" 2>/dev/null | sort -u | head -20)

# Build prefer blocks
PREFER_BLOCK=""
while IFS= read -r family; do
    # Take first name if comma-separated
    clean_family=$(echo "$family" | cut -d',' -f1 | xargs)
    if [ -n "$clean_family" ]; then
        PREFER_BLOCK="${PREFER_BLOCK}      <family>${clean_family}</family>\n"
    fi
done <<< "$FONT_FAMILIES"

sshpass -p "$RM_PASS" ssh root@"$RM_IP" "cat > /home/root/.fonts.conf << 'FONTCONF'
<?xml version=\"1.0\"?>
<!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">
<fontconfig>
  <alias>
    <family>serif</family>
    <prefer>
$(echo -e "$PREFER_BLOCK")
    </prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer>
$(echo -e "$PREFER_BLOCK")
    </prefer>
  </alias>
  <alias>
    <family>Noto Sans</family>
    <prefer>
$(echo -e "$PREFER_BLOCK")
    </prefer>
  </alias>
  <alias>
    <family>Noto Sans UI</family>
    <prefer>
$(echo -e "$PREFER_BLOCK")
    </prefer>
  </alias>
  <alias>
    <family>Noto Mono</family>
    <prefer>
$(echo -e "$PREFER_BLOCK")
    </prefer>
  </alias>
  <match target=\"pattern\">
    <edit name=\"family\" mode=\"append\">
$(echo -e "$PREFER_BLOCK")
    </edit>
  </match>
</fontconfig>
FONTCONF"
echo -e "${GREEN}✅ Fontconfig 設定完成${NC}"

# --- Setup restore script + auto-recovery ---
echo -e "${CYAN}[5/6] 設定 OS Update 自動修復...${NC}"
sshpass -p "$RM_PASS" ssh root@"$RM_IP" 'cat > /home/root/restore-fonts.sh << '\''SCRIPT'\''
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
SCRIPT
chmod +x /home/root/restore-fonts.sh'

sshpass -p "$RM_PASS" ssh root@"$RM_IP" 'cat > /home/root/.profile << '\''PROF'\''
if [ ! -d "/usr/share/fonts/ttf/chinese" ] || [ ! -f "/etc/systemd/system/xochitl.service.d/fonts.conf" ]; then
    /home/root/restore-fonts.sh
    systemctl restart xochitl
fi
PROF'
echo -e "${GREEN}✅ 自動修復設定完成${NC}"

# --- Install fonts to system + restart ---
echo -e "${CYAN}[6/6] 安裝字體到系統並重啟介面...${NC}"
sshpass -p "$RM_PASS" ssh root@"$RM_IP" '/home/root/restore-fonts.sh && systemctl restart xochitl'
echo -e "${GREEN}✅ 安裝完成！${NC}"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🎉 安裝成功！                                    ║${NC}"
echo -e "${GREEN}║                                                  ║${NC}"
echo -e "${GREEN}║  • PDF/EPUB 中文 → 自動顯示                      ║${NC}"
echo -e "${GREEN}║  • 主介面書名 → 已修復                            ║${NC}"
echo -e "${GREEN}║  • OS 更新後 → SSH 登入一次即自動修復              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
