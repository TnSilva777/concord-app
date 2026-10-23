const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('index.html', 'utf8');
for (const match of html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)) {
  if (!/\bsrc=/.test(match[1]) && !/application\//.test(match[1])) new vm.Script(match[2]);
}
const start = html.slice(html.indexOf('async function startVoiceNetwork(){'), html.indexOf('function stopVoiceNetwork(){'));
async function staleStart(rejectOld) {
  let finish;
  const pending = new Promise((resolve, reject) => { finish = rejectOld ? reject : resolve; });
  const state = { voiceStarting: false, voiceSignal: null, callJoined: true, joinedRoom: 'room-a', concordVoiceNetworkGeneration: 0,
    concordSupabase: { auth: { getSession: () => pending }, channel: () => { throw Error('Stale attempt created a channel'); } },
    concordJoinVoiceLobby: () => { throw Error('Stale attempt joined lobby'); },
    voiceStatus: () => { throw Error('Stale attempt changed status'); },
    stopVoiceNetwork: () => { throw Error('Stale attempt stopped new session'); } };
  vm.createContext(state); vm.runInContext(start, state);
  const task = state.startVoiceNetwork();
  state.concordVoiceNetworkGeneration++; state.voiceStarting = true; // A new entry is already running.
  finish(rejectOld ? Error('old request failed') : { data: { session: { user: { id: 'test' } } } });
  await task;
  assert.equal(state.voiceStarting, true, 'Old finally must not unlock a new entry');
}
async function desktopRoute() {
  const handlers = {}, loads = [];
  class Window {
    constructor() { this.webContents = { on: (name, cb) => handlers[name] = cb, once() {}, setWindowOpenHandler() {} }; }
    loadURL(url) { loads.push(url); return Promise.resolve(); }
    once() {}
  }
  const app = { commandLine: { appendSwitch() {} }, requestSingleInstanceLock: () => true, on() {}, whenReady: () => ({ then: fn => fn() }) };
  const session = { defaultSession: { setPermissionCheckHandler() {}, setPermissionRequestHandler() {} } };
  vm.runInNewContext(fs.readFileSync('desktop/main.cjs', 'utf8'), { require: name => name === 'electron' ? { app, BrowserWindow: Window, session, Menu: { setApplicationMenu() {} } } : name === 'electron-updater' ? { autoUpdater: {} } : require(name), __dirname: '/desktop', URL, console });
  const route = 'https://concord-app-tn-silva777.vercel.app/room?x=1&y=2#voz=sala';
  handlers['did-navigate']({}, route);
  handlers['did-fail-load']({}, -106, 'offline', route, true);
  assert.ok(decodeURIComponent(loads.at(-1)).includes('href="' + route.replaceAll('&', '&amp;') + '"'));
  const count = loads.length;
  handlers['did-fail-load']({}, -106, 'offline', 'https://other.example/', true);
  assert.equal(loads.length, count, 'External failure must not replace app');
}
(async () => { await staleStart(false); await staleStart(true); await desktopRoute(); console.log('PASS: inline syntax, stale success/failure isolation, offline route and external failure'); })().catch(error => { console.error(error); process.exitCode = 1; });
