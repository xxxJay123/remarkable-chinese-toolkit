const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { Client } = require('ssh2');
const fs = require('fs');
const { assessFontInstallerSupport } = require('./firmware-policy');

const SOFTWARE_VERSION_COMMAND =
  'cat /etc/version 2>/dev/null || cat /usr/share/remarkable/update.conf 2>/dev/null || true';

let mainWindow;

app.setName('reMarkable Chinese Toolkit');

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 680,
    height: 780,
    resizable: false,
    title: 'reMarkable Chinese Toolkit',
    titleBarStyle: 'hiddenInset',
    backgroundColor: '#0a0a0a',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  mainWindow.loadFile(path.join(__dirname, 'index.html'));
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => app.quit());

// --- SSH Operations ---

function sshExec(conn, command) {
  return new Promise((resolve, reject) => {
    conn.exec(command, (err, stream) => {
      if (err) return reject(err);
      let stdout = '', stderr = '';
      stream.on('data', (data) => { stdout += data.toString(); });
      stream.stderr.on('data', (data) => { stderr += data.toString(); });
      stream.on('close', (code) => {
        resolve({ stdout, stderr, code });
      });
    });
  });
}

function scpUpload(conn, localPath, remotePath) {
  return new Promise((resolve, reject) => {
    conn.sftp((err, sftp) => {
      if (err) return reject(err);
      const readStream = fs.createReadStream(localPath);
      const writeStream = sftp.createWriteStream(remotePath);
      writeStream.on('close', () => resolve());
      writeStream.on('error', (err) => reject(err));
      readStream.pipe(writeStream);
    });
  });
}

// --- IPC Handlers ---

ipcMain.handle('test-connection', async (event, { ip, password }) => {
  return new Promise((resolve) => {
    const conn = new Client();
    const timeout = setTimeout(() => {
      conn.end();
      resolve({ success: false, error: '連接逾時 — 請確認 IP 同連接方式' });
    }, 8000);

    conn.on('ready', async () => {
      clearTimeout(timeout);
      try {
        const result = await sshExec(conn, SOFTWARE_VERSION_COMMAND);
        const version = result.stdout.trim();
        const fontInstallerPolicy = assessFontInstallerSupport(version);
        conn.end();
        resolve({ success: true, version, fontInstallerPolicy });
      } catch (e) {
        conn.end();
        resolve({
          success: true,
          version: '',
          fontInstallerPolicy: assessFontInstallerSupport('')
        });
      }
    });

    conn.on('error', (err) => {
      clearTimeout(timeout);
      resolve({ success: false, error: err.message });
    });

    conn.connect({
      host: ip,
      port: 22,
      username: 'root',
      password: password,
      readyTimeout: 7000
    });
  });
});

ipcMain.handle('install-fonts', async (event, { ip, password, fontPaths }) => {
  return new Promise((resolve) => {
    const conn = new Client();
    const logs = [];
    const log = (msg) => {
      logs.push(msg);
      mainWindow.webContents.send('install-log', msg);
    };

    conn.on('ready', async () => {
      try {
        const versionResult = await sshExec(conn, SOFTWARE_VERSION_COMMAND);
        const version = versionResult.stdout.trim();
        const fontInstallerPolicy = assessFontInstallerSupport(version);

        log(`🔎 reMarkable software：${version || '無法識別'}`);
        if (!fontInstallerPolicy.allowed) {
          log(`⛔ ${fontInstallerPolicy.reason}`);
          log('• 呢個 gate 會維持到相同 firmware 完成中文 PDF／EPUB 閱讀測試。');
          conn.end();
          resolve({
            success: false,
            code: 'UNVERIFIED_FIRMWARE',
            error: fontInstallerPolicy.reason,
            fontInstallerPolicy
          });
          return;
        }

        log(`✅ ${fontInstallerPolicy.reason}`);

        // Step 1: Create directories
        log('📁 建立字體目錄...');
        await sshExec(conn, 'mkdir -p /home/root/.local/share/fonts/');

        // Step 2: Upload fonts
        log('📤 上傳字體檔案...');
        for (const fontPath of fontPaths) {
          const filename = path.basename(fontPath);
          log(`  ↑ ${filename}`);
          await scpUpload(conn, fontPath, `/home/root/.local/share/fonts/${filename}`);
        }
        await sshExec(conn, 'chmod 644 /home/root/.local/share/fonts/*');

        // Step 3: Get font families
        log('🔍 偵測字體名稱...');
        await sshExec(conn, 'fc-cache -f 2>/dev/null');
        const fcResult = await sshExec(conn, "fc-list /home/root/.local/share/fonts/ --format='%{family}\\n' 2>/dev/null");
        const families = [...new Set(
          fcResult.stdout.split('\n')
            .map(f => f.split(',')[0].trim())
            .filter(f => f.length > 0)
        )];

        if (families.length === 0) {
          log('⚠️  無法偵測字體名稱，使用預設值...');
          families.push('Noto Serif TC', 'Noto Serif SC');
        }
        log(`  字體：${families.join(', ')}`);

        // Step 4: Create .fonts.conf
        log('⚙️  設定 fontconfig...');
        const preferBlock = families.map(f => `      <family>${f}</family>`).join('\n');
        const aliasNames = ['serif', 'sans-serif', 'Noto Sans', 'Noto Sans UI', 'Noto Mono'];
        const aliasBlocks = aliasNames.map(name => `
  <alias>
    <family>${name}</family>
    <prefer>
${preferBlock}
    </prefer>
  </alias>`).join('');

        const fontsConf = `<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>${aliasBlocks}
  <match target="pattern">
    <edit name="family" mode="append">
${preferBlock}
    </edit>
  </match>
</fontconfig>`;

        // Write via sftp
        await new Promise((res, rej) => {
          conn.sftp((err, sftp) => {
            if (err) return rej(err);
            sftp.writeFile('/home/root/.fonts.conf', fontsConf, (err) => {
              if (err) return rej(err);
              res();
            });
          });
        });

        // Step 5: Create restore script
        log('🛡️  設定 OS Update 自動修復...');
        const restoreScript = `#!/bin/sh
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
    printf "[Service]\\nExecStartPre=/home/root/restore-fonts.sh\\n" > /etc/systemd/system/xochitl.service.d/fonts.conf
    systemctl daemon-reload
fi`;

        await new Promise((res, rej) => {
          conn.sftp((err, sftp) => {
            if (err) return rej(err);
            sftp.writeFile('/home/root/restore-fonts.sh', restoreScript, { mode: 0o755 }, (err) => {
              if (err) return rej(err);
              res();
            });
          });
        });

        // Step 6: Create .profile
        const profile = `if [ ! -d "/usr/share/fonts/ttf/chinese" ] || [ ! -f "/etc/systemd/system/xochitl.service.d/fonts.conf" ]; then
    /home/root/restore-fonts.sh
    systemctl restart xochitl
fi`;

        await new Promise((res, rej) => {
          conn.sftp((err, sftp) => {
            if (err) return rej(err);
            sftp.writeFile('/home/root/.profile', profile, (err) => {
              if (err) return rej(err);
              res();
            });
          });
        });

        // Step 7: Run restore + restart xochitl
        log('🔄 安裝字體到系統...');
        await sshExec(conn, '/home/root/restore-fonts.sh');
        log('🔄 重啟 reMarkable 介面...');
        await sshExec(conn, 'systemctl restart xochitl');

        log('');
        log('🎉 安裝成功！');
        log('');
        log('• PDF/EPUB 中文 → 自動顯示');
        log('• 主介面書名 → 已修復');
        log('• OS 更新後 → SSH 登入一次即自動修復');

        conn.end();
        resolve({ success: true });

      } catch (err) {
        log(`❌ 錯誤：${err.message}`);
        conn.end();
        resolve({ success: false, error: err.message });
      }
    });

    conn.on('error', (err) => {
      log(`❌ 連接失敗：${err.message}`);
      resolve({ success: false, error: err.message });
    });

    conn.connect({
      host: ip,
      port: 22,
      username: 'root',
      password: password,
      readyTimeout: 10000
    });
  });
});
