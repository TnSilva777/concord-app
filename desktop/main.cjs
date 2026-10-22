'use strict';
const { app, BrowserWindow, shell, session, dialog, Menu } = require('electron');
const { autoUpdater } = require('electron-updater');
const APP_URL = 'https://concord-app-tn-silva777.vercel.app/';
const APP_ORIGIN = new URL(APP_URL).origin;
let mainWindow;
let updateStarted = false;

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
  const allowed = new Set(['media', 'mediaTypes', 'display-capture', 'fullscreen', 'notifications']);
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
  mainWindow.webContents.on('did-fail-load', (_event, errorCode, description, validatedURL, isMainFrame) => {
    if (isMainFrame) console.warn('CONCORD offline:', errorCode, description, validatedURL);
  });
  mainWindow.loadURL(APP_URL);
  mainWindow.once('ready-to-show', startUpdates);
  mainWindow.webContents.once('did-finish-load', startUpdates);
}
app.whenReady().then(() => {
  installPermissions();
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
