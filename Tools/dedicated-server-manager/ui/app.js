const $ = (id) => document.getElementById(id);

let pollTimer = null;
let activeServerId = null;
let lastRemote = null;

function log(msg) {
  const el = $("log");
  const line = `[${new Date().toLocaleTimeString()}] ${msg}\n`;
  el.textContent = line + el.textContent;
}

function setBadge(el, on, onText, offText) {
  el.textContent = on ? onText : offText;
  el.className = `badge ${on ? "on" : "off"}`;
}

function formatUptime(ms) {
  if (!ms || ms < 0) return "—";
  const s = Math.floor(ms / 1000);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  if (h > 0) return `${h}h ${m}m ${sec}s`;
  if (m > 0) return `${m}m ${sec}s`;
  return `${sec}s`;
}

function updateClientUrls(cfg, remote, lan) {
  lastRemote = remote;
  const registryUrl = remote?.registryUrl || `http://127.0.0.1:${cfg.registryPort}/v1`;
  const gameEp = remote?.gameEndpoint || `127.0.0.1:${cfg.port}`;
  $("clientRegistryUrl").textContent = registryUrl;
  $("clientGameEndpoint").textContent = gameEp;
  const lanIp = lan?.[0] || "127.0.0.1";
  $("lanRegistryUrl").textContent = `http://${lanIp}:${cfg.registryPort}/v1 (sadece ayni WiFi)`;

  const warn = $("privateIpWarn");
  if (remote?.isPrivateGameAddress && !remote?.usingTunnel) {
    warn.hidden = false;
  } else {
    warn.hidden = true;
  }
}

function renderPlayers(clients) {
  const body = $("playersBody");
  body.innerHTML = "";
  if (!clients || clients.length === 0) {
    body.innerHTML = '<tr class="empty-row"><td colspan="3">Bagli oyuncu yok</td></tr>';
    return;
  }
  for (const c of clients) {
    const tr = document.createElement("tr");
    const ping = c.pingMs > 0 ? `${c.pingMs} ms` : "—";
    tr.innerHTML = `<td>${c.id ?? "—"}</td><td>${c.name || "—"}</td><td>${ping}</td>`;
    body.appendChild(tr);
  }
}

async function saveFormConfig() {
  const data = readForm();
  await window.serverPanel.saveConfig(data);
  return data;
}

async function refreshMonitor() {
  const mon = await window.serverPanel.getMonitorStatus();
  const info = await window.serverPanel.getInfo();
  const cfg = info.config;

  setBadge($("registryStatus"), info.status.registryRunning, "ONLINE", "OFFLINE");
  setBadge($("serverStatus"), info.status.serverRunning, "ONLINE", "OFFLINE");

  if (mon.heartbeatAgeMs != null && mon.heartbeatAgeMs < 20000) {
    setBadge($("heartbeatStatus"), true, `${Math.round(mon.heartbeatAgeMs / 1000)}s ago`, "STALE");
  } else if (info.status.serverRunning) {
    setBadge($("heartbeatStatus"), false, "WAITING", "STALE");
  } else {
    $("heartbeatStatus").textContent = "—";
    $("heartbeatStatus").className = "badge off";
  }

  $("uptime").textContent = formatUptime(mon.uptimeMs);
  $("playerCount").textContent = `${mon.players ?? 0} / ${mon.maxPlayers ?? 8}`;
  $("activeScene").textContent = mon.scene || (info.status.serverRunning ? "Base (lobby)" : "—");
  renderPlayers(mon.clients);

  $("btnStop").disabled = !(info.status.registryRunning || info.status.serverRunning);
  $("btnStart").disabled = info.status.serverRunning;
  updateClientUrls(cfg, info.remote, info.lanAddresses);
}

async function loadPanel() {
  const info = await window.serverPanel.getInfo();
  const cfg = info.config;

  $("port").value = cfg.port;
  $("registryPort").value = cfg.registryPort;
  $("publicAddress").value = cfg.publicAddress || "";
  $("tunnelRegistryUrl").value = cfg.tunnelRegistryUrl || "";
  $("binaryPath").textContent = info.gameBinary || "BINARY NOT FOUND";
  $("binaryPath").title = info.gameBinary || "";

  updateClientUrls(cfg, info.remote, info.lanAddresses);

  if (!info.gameBinary) {
    log("UYARI: game/ klasorunde server binary yok.");
  }
  if (info.remote?.isPrivateGameAddress && !info.remote?.usingTunnel) {
    log("UYARI: Public IP yok — IP BUL veya Tailscale IP yaz. Port forward sart.");
  }

  await refreshMonitor();
}

function readForm() {
  return {
    port: Number($("port").value) || 7777,
    registryPort: Number($("registryPort").value) || 8787,
    publicAddress: $("publicAddress").value.trim(),
    tunnelRegistryUrl: $("tunnelRegistryUrl").value.trim(),
  };
}

function startPolling() {
  if (pollTimer) clearInterval(pollTimer);
  pollTimer = setInterval(() => refreshMonitor().catch(() => {}), 3000);
}

async function onConfigFieldChange() {
  await saveFormConfig();
  await refreshMonitor();
}

$("port").addEventListener("change", () => onConfigFieldChange().catch((e) => log(String(e))));
$("registryPort").addEventListener("change", () => onConfigFieldChange().catch((e) => log(String(e))));
$("publicAddress").addEventListener("change", () => onConfigFieldChange().catch((e) => log(String(e))));
$("tunnelRegistryUrl").addEventListener("change", () => onConfigFieldChange().catch((e) => log(String(e))));

$("btnFetchIp").addEventListener("click", async () => {
  log("Public IP araniyor...");
  const result = await window.serverPanel.fetchPublicIp();
  if (!result.ok) {
    log(`HATA: ${result.error}`);
    return;
  }
  $("publicAddress").value = result.ip;
  updateClientUrls(readForm(), result.remote, []);
  log(`Public IP: ${result.ip}`);
  log(`Registry URL: ${result.remote.registryUrl}`);
});

$("btnCopyRegistry").addEventListener("click", async () => {
  const url = $("clientRegistryUrl").textContent;
  try {
    await navigator.clipboard.writeText(url);
    log("Registry URL kopyalandi — Derin'e yapistir.");
  } catch {
    log(`Kopyala: ${url}`);
  }
});

$("btnStart").addEventListener("click", async () => {
  const cfg = readForm();
  await saveFormConfig();
  $("btnStart").disabled = true;
  log("Dedicated server baslatiliyor (internet modu)...");

  const result = await window.serverPanel.startServer(cfg);
  if (!result.ok) {
    log(`HATA: ${result.error}`);
    $("btnStart").disabled = false;
    return;
  }

  activeServerId = result.serverId;
  log(`OK game: ${result.gameEndpoint}`);
  log(`Registry (Derin Settings): ${result.registryUrl}`);
  if (result.isPrivateGameAddress && !result.usingTunnel) {
    log("UYARI: 192.168.x.x gorunuyor — uzaktan JOIN calismaz!");
  }
  log("Port forward: 7777 TCP+UDP (+ 8787 TCP veya tunel URL)");

  $("btnStop").disabled = false;
  startPolling();
  await refreshMonitor();
});

$("btnStop").addEventListener("click", async () => {
  log("Durduruluyor...");
  await window.serverPanel.stopServer();
  activeServerId = null;
  $("btnStart").disabled = false;
  $("btnStop").disabled = true;
  await refreshMonitor();
  log("Durduruldu (registry listesinden silindi).");
});

loadPanel()
  .then(() => startPolling())
  .catch((e) => log(String(e)));
