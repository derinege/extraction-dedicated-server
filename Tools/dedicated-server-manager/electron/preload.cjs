const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("serverPanel", {
  getInfo: () => ipcRenderer.invoke("panel:getInfo"),
  getMonitorStatus: () => ipcRenderer.invoke("panel:getMonitorStatus"),
  saveConfig: (data) => ipcRenderer.invoke("panel:saveConfig", data),
  startRegistry: (opts) => ipcRenderer.invoke("panel:startRegistry", opts),
  stopRegistry: () => ipcRenderer.invoke("panel:stopRegistry"),
  startServer: (opts) => ipcRenderer.invoke("panel:startServer", opts),
  stopServer: () => ipcRenderer.invoke("panel:stopServer"),
  stopAll: () => ipcRenderer.invoke("panel:stopAll"),
});
