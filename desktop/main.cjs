'use strict';
const { app, BrowserWindow, shell, session, dialog, Menu, desktopCapturer } = require('electron');
const { autoUpdater } = require('electron-updater');
const path = require('node:path');
const APP_URL = 'https://concord-app-tn-silva777.vercel.app/';
const APP_ORIGIN = new URL(APP_URL).origin;
// Remote WebRTC audio may arrive before Windows grants a fresh interaction.
// CONCORD handles microphone permission separately from speaker playback.
app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');
let mainWindow;
let updateStarted = false;
let lastMainUrl = APP_URL;
const lock = app.requestSingleInstanceLock();
if (!lock) app.quit();
app.on('second-instance', () => {
  if (!mainWindow || mainWindow.isDestroyed()) return;
  if (mainWindow.isMinimized()) mainWindow.restore();
  mainWindow.show();
  mainWindow.focus();
});

function isAppUrl(raw) {
  try {
    const url = new URL(raw);
    return url.protocol === 'https:' && url.origin === APP_ORIGIN;
  } catch { return false; }
}

function openExternal(raw) {
  try {
    const u = new URL(raw);
    if (u.protocol === 'https:' || u.protocol === 'mailto:') shell.openExternal(raw);
  } catch {}
}

function installPermissions() {
  const ses = session.defaultSession;
  const allowed = new Set(['media', 'display-capture', 'fullscreen', 'notifications']);
  // Windows screen-share support. A user chooses a window or screen before sharing.
  if (typeof ses.setDisplayMediaRequestHandler === 'function') {
    ses.setDisplayMediaRequestHandler(async (request, callback) => {
      const origin = request.securityOrigin || request.frame?.url || '';
      if (!isAppUrl(origin)) {
        callback({});
        return;
      }
      try {
        const sources = await desktopCapturer.getSources({ types: ['screen', 'window'], thumbnailSize: { width: 240, height: 150 } });
        if (!sources.length) { callback({}); return; }
        const selected = await dialog.showMessageBox(mainWindow, {
          type: 'question',
          title: 'CONCORD — Compartilhar tela',
          message: 'Escolha o que deseja transmitir',
          detail: 'Selecione uma tela ou janela. Compartilhe apenas conteúdo que você deseja mostrar.',
          buttons: [...sources.slice(0, 15).map(source => source.name), 'Cancelar'],
          cancelId: Math.min(sources.length, 15),
          noLink: true
        });
        if (selected.response >= Math.min(sources.length, 15)) { callback({}); return; }
        callback({ video: sources[selected.response] });
      } catch (error) { console.warn('Captura de tela:', error.message); callback({}); }
    });
  }
  ses.setPermissionCheckHandler((webContents, permission, requestingOrigin) => {
    return allowed.has(permission) && isAppUrl(requestingOrigin || webContents?.getURL() || '');
  });
  ses.setPermissionRequestHandler((webContents, permission, callback, details) => {
    const requester = details?.requestingUrl || webContents.getURL();
    callback(allowed.has(permission) && isAppUrl(requester));
  });
}

function startUpdates() {
  if (!app.isPackaged || updateStarted) return;
  updateStarted = true;
  autoUpdater.autoDownload = true;
  autoUpdater.autoInstallOnAppQuit = true;
  autoUpdater.logger = console;
  autoUpdater.on('error', err => console.warn('Atualização indisponível:', err.message));
  autoUpdater.on('update-downloaded', () => {
    if (!mainWindow || mainWindow.isDestroyed()) return;
    mainWindow.webContents.send('concord-update-ready');
    dialog.showMessageBox(mainWindow, {
      type: 'info',
      title: 'CONCORD atualizado',
      message: 'Uma atualização foi baixada e será instalada ao fechar o aplicativo.',
      buttons: ['Entendi']
    }).catch(() => {});
  });
  autoUpdater.checkForUpdatesAndNotify().catch(err => console.warn('Busca de atualização:', err.message));
}

function createWindow() {
  mainWindow = new BrowserWindow({
    title: 'CONCORD',
    icon: path.join(__dirname, 'assets', 'concord.png'),
    width: 1250,
    height: 820,
    minWidth: 760,
    minHeight: 540,
    backgroundColor: '#07110e',
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
      webSecurity: true
    }
  });
  Menu.setApplicationMenu(null);
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    // Links internos pertencem à janela do CONCORD, não ao navegador padrão.
    if (isAppUrl(url)) {
      mainWindow.loadURL(url).catch(err => console.warn('Navegação interna:', err.message));
    } else {
      // Links de terceiros continuam no navegador, sem acesso ao Electron.
      openExternal(url);
    }
    return { action: 'deny' };
  });
  mainWindow.webContents.on('will-navigate', (event, url) => {
    if (!isAppUrl(url)) { event.preventDefault(); openExternal(url); }
  });
  mainWindow.webContents.on('did-navigate', (_event, url) => { if (isAppUrl(url)) lastMainUrl = url; });
  mainWindow.webContents.on('did-navigate-in-page', (_event, url) => { if (isAppUrl(url)) lastMainUrl = url; });
  // Retry when Internet access is restored; do not expose Node integration to the site.
  mainWindow.webContents.on('before-input-event', (event, input) => {
    if (input.type === 'keyDown' && (input.control || input.meta) && input.key.toLowerCase() === 'r') {
      event.preventDefault();
      if (isAppUrl(mainWindow.webContents.getURL())) mainWindow.reload();
      else mainWindow.loadURL(lastMainUrl).catch(console.warn);
    }
  });
  mainWindow.webContents.on('did-fail-load', (_event, errorCode, description, validatedURL, isMainFrame) => {
    if (isMainFrame) {
      console.warn('CONCORD offline:', errorCode, description, validatedURL);
      if (errorCode !== -3 && isAppUrl(validatedURL)) { const offlinePage = '<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>CONCORD</title><style>body{background:#07110e;color:#d7fce4;font:16px system-ui;display:grid;place-items:center;min-height:90vh;text-align:center}a{padding:12px 24px;border-radius:10px;background:#168354;color:white;text-decoration:none}</style><main><h1>CONCORD</h1><p>Sem conexão com o servidor. Verifique a Internet.</p><a href="' + APP_URL + '">Tentar novamente</a></main></html>'; mainWindow.loadURL('data:text/html;charset=utf-8,' + encodeURIComponent(offlinePage)).catch(console.warn); }
    }
  });
  mainWindow.loadURL(APP_URL).catch(err => console.warn('CONCORD inicialização:', err.message));
  mainWindow.once('ready-to-show', startUpdates);
  mainWindow.webContents.once('did-finish-load', startUpdates);
}
app.whenReady().then(() => {
  installPermissions();
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
