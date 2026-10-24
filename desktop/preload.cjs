'use strict';
const {contextBridge, ipcRenderer} = require('electron');
contextBridge.exposeInMainWorld('concordDesktop', {
  startGoogleLogin: url => ipcRenderer.invoke('concord-open-google-oauth', url),
  onOAuthCallback: callback => {
    if (typeof callback !== 'function') return;
    ipcRenderer.on('concord-oauth-callback', (_event, data) => callback(data));
  }
});
