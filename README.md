# reMarkable Chinese Toolkit

令 reMarkable 更完整支援中文閱讀、中文輸入同中文手寫轉文字。

Chinese reading, input, and handwriting tools for reMarkable paper tablets.

![Platform](https://img.shields.io/badge/desktop-Windows%20%7C%20macOS-blue)
![Device](https://img.shields.io/badge/device-rM2%20%7C%20Paper%20Pro%20family-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 專案狀態

| 功能 | 狀態 | 備註 |
| --- | --- | --- |
| 中文字體安裝 | Legacy；3.28 未驗證 | 3.28+ 已由 installer safety gate 暫停 |
| 中文輸入法核心 | 開發中 | 已加入 Qt Quick + `librime` prototype |
| Xochitl 原生輸入 | 等候 3.28 stable SDK | Beta 期間不提供裝置安裝 |
| 中文手寫轉文字 | 規劃中 | 中文輸入法完成後開始 |

reMarkable OS 3.28 Beta 已經改善中文顯示，但顯示中文字形、中文輸入法同中文手寫辨識係三個獨立功能。本專案會先完成中文輸入，再處理中文手寫轉文字。

> [!IMPORTANT]
> reMarkable Beta Program 條款不容許參與 Beta 時在裝置安裝第三方軟件。3.28 Beta 用戶可以參與桌面端及模擬測試，但請等 3.28 stable、對應官方 SDK 同兼容嘅 extension framework 發佈後，先安裝裝置端輸入法。

> [!CAUTION]
> 本專案目前冇 3.28 實機中文字體安裝及閱讀測試結果。唔可以假設舊 installer、fontconfig fallback、PDF／EPUB 閱讀或 OS update recovery 喺 3.28 仍然有效。Desktop app 同 CLI installer 會拒絕 3.28 或更新版本，直至指定 build 完成兼容性測試。

## 中文輸入法方向

輸入法採用 [Rime](https://github.com/rime/librime) 做核心，目標支援：

- 粵拼（香港繁體）
- 普通話拼音（繁體／簡體）
- 倉頡五代
- 速成
- Type Folio 鍵盤
- reMarkable 螢幕鍵盤及候選字列
- 常用廣東話字同 HKSCS 字形測試

目前 `device/ime/` 已經包含一個 Qt Quick prototype：

- 真正使用 `librime` C API
- 顯示組字文字及候選字
- 可切換已部署嘅 Rime schema
- 為 e-ink 設計嘅黑白、大按鈕、無動畫介面
- ARM32（rM2）同 AArch64（Paper Pro family）共用程式碼

呢個階段係 standalone 測試程式，未注入 Xochitl。詳細設計見 [中文輸入法架構](docs/IME_ARCHITECTURE.md)。

## Desktop Toolkit

Desktop app 目前保留原有中文字體管理功能，並會先讀取 software version。無法識別版本或版本係 3.28+ 時，字體安裝會被鎖定；之後會成為輸入法、手寫辨識同裝置兼容性檢查嘅統一入口。

### 前提條件

- Windows 10/11 或 macOS
- reMarkable 2 或 Paper Pro family
- USB 連接；預設 IP：`10.11.99.1`
- 可用嘅 SSH access
- Paper Pro family 需要先啟用 Developer Mode

### 開發模式

```bash
git clone https://github.com/xxxJay123/remarkable-chinese-toolkit.git
cd remarkable-chinese-toolkit/app
npm ci
npm start
```

### Desktop build

```bash
cd app
npm run build:win
# 或
npm run build:mac
```

## Legacy 中文字體安裝

如果你使用 3.28 之前、而且已自行確認兼容嘅穩定版 reMarkable OS，可以繼續使用舊有字體功能。3.28 或更新版本目前唔支援安裝。

### Desktop app

1. 用 USB 連接 reMarkable。
2. 輸入 IP 同 SSH 密碼。
3. 拖入 `.ttf` 或 `.otf`。
4. 選擇安裝字體。

### Command line

```bash
# macOS / Linux
chmod +x scripts/install-fonts.sh
./scripts/install-fonts.sh

# Windows PowerShell
.\scripts\install-fonts.ps1
```

安裝器會將字體保存到 `/home/root/.local/share/fonts/`，建立 fontconfig fallback，再重新建立字體 cache。

> [!WARNING]
> 字體安裝會修改裝置檔案並重新啟動 Xochitl。請先備份資料。3.28+ 同無法識別嘅 firmware 會 fail closed，唔會開始上傳或修改檔案。

### 3.28 中文閱讀兼容性

| 項目 | 目前狀態 |
| --- | --- |
| 3.28.0.163 中文字體安裝 | 未測試 |
| PDF 內嵌中文字體 | 未測試 |
| PDF 依賴系統 CJK fallback | 未測試 |
| EPUB 繁體／簡體閱讀 | 未測試 |
| Variable font 粗幼顯示 | 未測試 |
| Restart／reboot 後保留 | 未測試 |
| OS update recovery | 未測試 |

「PDF 有內嵌字體所以睇到中文」唔代表 installer 有效；測試時必須分開檢查內嵌字體同系統 fallback。完整測試矩陣見 [docs/FONT_READING_COMPATIBILITY.md](docs/FONT_READING_COMPATIBILITY.md)。

## Roadmap

### Phase 1 — 中文輸入法

- [x] 將專案改名做 reMarkable Chinese Toolkit
- [x] 建立 `librime` + Qt Quick prototype
- [x] 定義 ARM32／AArch64 共用架構
- [ ] 加入及驗證粵拼、拼音、倉頡、速成資料
- [ ] 建立桌面模擬器及自動測試
- [ ] 等候 3.28 stable SDK
- [ ] 實機驗證 Qt Unicode commit event
- [ ] 建立 Xovi overlay 同 Type Folio interception
- [ ] 發佈第一個裝置端 alpha

### Phase 2 — 中文手寫轉文字

- [ ] 讀取 `.rmdoc`／`.rm` v6 筆劃
- [ ] 香港繁體、台灣繁體、簡體辨識
- [ ] 桌面端校對及 TXT／Markdown export
- [ ] 安全產生新 notebook／typed-text page
- [ ] 評估裝置端短句手寫輸入

## 支援範圍

| 裝置 | CPU | 計劃 |
| --- | --- | --- |
| reMarkable 2 | ARM32 | 支援 |
| reMarkable Paper Pro | AArch64 | 支援 |
| reMarkable Paper Pro Move | AArch64 | SDK 發佈後驗證 |
| reMarkable Paper Pure | AArch64 | SDK 發佈後驗證 |

Xochitl 係 proprietary application，版本之間冇兼容保證。裝置端 binary 必須同目標 firmware／SDK 明確配對，唔會使用「可能兼容」方式跨版本安裝。

## 貢獻

開發環境、分支規則、測試要求同輸入法資料授權注意事項，請參閱 [CONTRIBUTING.md](CONTRIBUTING.md)。

## Credits

- [Rime Input Method Engine](https://github.com/rime/librime)
- [Rime Cantonese](https://github.com/rime/rime-cantonese)
- [Xovi](https://github.com/asivery/xovi)
- [reMarkable Developer Portal](https://developer.remarkable.com/)
- [Noto Fonts](https://fonts.google.com/noto)

## License

程式碼以 [MIT License](LICENSE) 發佈。Rime schemas、字典、字體及其他第三方資料保留各自授權，打包或分發前必須逐項確認。
