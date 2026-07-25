# Contributing to reMarkable Chinese Toolkit

多謝你幫手改善 reMarkable 嘅中文體驗。

## 貢獻優先次序

目前請依照以下次序處理功能：

1. 中文輸入法核心、候選字 UI 同測試
2. 3.28 stable SDK／Xochitl integration
3. 中文手寫轉文字
4. Legacy 字體管理改善

如果改動涉及裝置端安裝，請先閱讀 Beta、Developer Mode、firmware compatibility 同 recovery 章節。

目前 3.28 中文字體安裝及閱讀係 **未驗證**。未有指定 firmware build 嘅實機結果之前，請勿將 3.28 標示為 supported，亦唔好移除 installer safety gate。

## 回報問題

開 Issue 時請提供：

- reMarkable 型號
- 完整 software version，例如 `3.28.0.163`
- stable 或 Beta channel
- Developer Mode 狀態
- 連接方式：USB 或 Wi-Fi
- 功能：字體、輸入法或手寫辨識
- 完整錯誤訊息及可重現步驟

請勿貼出 SSH 密碼、cloud token、MyScript key 或其他憑證。

字體／閱讀問題亦請列出：

- 測試文件係 PDF 或 EPUB
- 文件有冇內嵌中文字體
- 繁體、簡體或兩者
- 字體檔案名稱及版本
- Library 書名、文件內容、粗幼、restart、reboot 各自結果

## Clone 同分支

```bash
git clone https://github.com/xxxJay123/remarkable-chinese-toolkit.git
cd remarkable-chinese-toolkit
git switch -c feature/short-description
```

建議分支前綴：

- `feature/`：新功能
- `fix/`：修正
- `docs/`：文件
- `test/`：測試

## Repository layout

```text
app/                    Electron desktop toolkit
device/ime/             Qt Quick + librime device prototype
docs/                   Architecture and compatibility notes
scripts/                Legacy font installer
.github/workflows/      Build and release automation
```

字體閱讀兼容測試程序見 [docs/FONT_READING_COMPATIBILITY.md](docs/FONT_READING_COMPATIBILITY.md)。

## Desktop app 開發

需要 Node.js 20：

```bash
cd app
npm ci
npm start
```

提交前執行：

```bash
npm test
npm run check
```

如果改動影響打包，再執行目前平台嘅 build：

```bash
npm run build:win
# 或
npm run build:mac
```

## 中文輸入法開發

裝置端 prototype 使用：

- C++17
- Qt 6 Quick
- `librime`
- 對應目標 firmware 嘅官方 reMarkable SDK

請先閱讀 [docs/IME_ARCHITECTURE.md](docs/IME_ARCHITECTURE.md) 同 [device/ime/README.md](device/ime/README.md)。

### Firmware gate

裝置端 PR 必須列出：

- 已使用嘅 reMarkable software version
- 官方 SDK／OS build version
- CPU architecture
- Xovi 或其他 integration framework version
- 實機測試型號

唔接受以較舊 SDK 編譯，再假設新版 firmware 兼容嘅 release binary。

### Rime schema 同字典

程式碼同輸入資料係分開授權。新增 schema／字典時請：

1. 記錄 upstream repository 同 exact revision。
2. 記錄 license。
3. 保留 attribution。
4. 確認 license 容許重新分發。
5. 加入以下基本測試字串：
   - `中文輸入法`
   - `繁體中文`
   - `简体中文`
   - `香港廣東話`
   - `佢哋喺邊度`
   - `冇問題`
   - `𨋢`

罕用字顯示失敗可能係字體 coverage，唔一定係輸入法問題，請分開回報。

## Beta policy

參與 reMarkable Beta Program 時，唔好在裝置安裝本專案嘅第三方 binary、Xovi extension 或其他修改。

Beta 期間可以貢獻：

- Desktop UI
- Rime engine unit tests
- QML screenshot／layout review
- Schema 同字典測試
- 官方 release notes／SDK compatibility research

等 stable firmware 同對應 SDK 發佈後，先開始裝置端實機測試。

## 安全要求

- 唔可以將 SSH password 寫入 log、config 或 crash report。
- 唔可以將 API key 放入 renderer process 或 commit 入 repo。
- 修改 Xochitl document store 前必須停止 Xochitl，並先備份。
- Installer 要有清楚嘅版本／架構 gate。
- 3.28+ 必須 fail closed，直至 exact build 通過完整中文字體閱讀矩陣。
- 安裝失敗必須保留回復 stock 狀態嘅方法。
- 唔可以自動改寫使用者已存在嘅 shell profile 或 systemd config 而不先備份。

## Pull request checklist

- [ ] 改動只處理一個清楚範圍
- [ ] README／文件已同步
- [ ] 新功能有測試或清楚嘅手動驗證步驟
- [ ] 冇提交 credentials、build output 或使用者資料
- [ ] 第三方資料已記錄來源同授權
- [ ] 裝置端改動列明 firmware、SDK、architecture 同 recovery 方法

## License

提交本專案即表示你同意將自己嘅程式碼貢獻以 [MIT License](LICENSE) 發佈；第三方資料則繼續受原有授權約束。
