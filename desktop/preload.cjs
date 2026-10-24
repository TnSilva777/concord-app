'use strict';
const {contextBridge, ipcRenderer} = require('electron');
contextBridge.exposeInMainWorld('concordDesktop', {
  listShareSources: () => ipcRenderer.invoke('concord-list-share-sources'),
  selectShareSource: id => ipcRenderer.invoke('concord-select-share-source', id),
  startGoogleLogin: url => ipcRenderer.invoke('concord-open-google-oauth', url),
  onOAuthCallback: callback => {
    if (typeof callback !== 'function') return;
    ipcRenderer.on('concord-oauth-callback', (_event, data) => callback(data));
  }
});
