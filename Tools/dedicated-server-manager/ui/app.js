const $ = (id) => document.getElementById(id);

let pollTimer = null;
let activeServerId = null;

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

function updateClientUrls(cfg, lan) {
  const ip = cfg.publicAddress?.trim() || lan[0] || "127.0.0.1";
  $("clientRegistryUrl").textContent = `http://${ip}:${cfg.registryPort}/v1`;
  $("clientGameEndpoint").textContent = `${ip}:${cfg.port}`;
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

async function refreshMonitor() {
  const mon = await window.serverPanel.getMonitorStatus();
  const info = mon.info;
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
  updateClientUrls(cfg, info.lanAddresses);
}

async function loadPanel() {
  const info = await window.serverPanel.getInfo();
  const cfg = info.config;

  $("port").value = cfg.port;
  $("registryPort").value = cfg.registryPort;
  $("publicAddress").value = cfg.publicAddress || "";
  $("binaryPath").textContent = info.gameBinary || "BINARY NOT FOUND";
  $("binaryPath").title = info.gameBinary || "";

  updateClientUrls(cfg, info.lanAddresses);

  if (!info.gameBinary) {
    log("UYARI: game/ klasorunde server binary yok.");
  }

  await refreshMonitor();
}

function readForm() {
  return {
    port: Number($("port").value) || 7777,
    registryPort: Number($("registryPort").value) || 8787,
    publicAddress: $("publicAddress").value.trim(),
  };
}

function startPolling() {
  if (pollTimer) clearInterval(pollTimer);
  pollTimer = setInterval(() => refreshMonitor().catch(() => {}), 3000);
}

$("btnStart").addEventListener("click", async () => {
  const cfg = readForm();
  $("btnStart").disabled = true;
  log("Dedicated server baslatiliyor (headless)...");

  const result = await window.serverPanel.startServer(cfg);
  if (!result.ok) {
    log(`HATA: ${result.error}`);
    $("btnStart").disabled = false;
    return;
  }

  activeServerId = result.serverId;
  log(`OK: ${result.gameAddress}:${result.port}`);
  log(`Registry URL (launcher Settings): ${result.registryUrl}`);
  log("Harita secimi HOST oyuncunun launcher HOST & PLAY ekraninda.");

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
