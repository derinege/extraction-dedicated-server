const { app, BrowserWindow, ipcMain } = require("electron");
const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");
const os = require("os");

let mainWindow;
/** @type {import('child_process').ChildProcess | null} */
let registryProcess = null;
/** @type {import('child_process').ChildProcess | null} */
let gameServerProcess = null;

/** Headless dedicated her zaman lobby sahnesinde acilir; harita host launcher'da secilir. */
const DEDICATED_LOBBY_SCENE = "Base";

let activeServerId = null;
let serverStartedAt = null;

function repoRoot() {
  if (app.isPackaged) {
    return path.resolve(process.resourcesPath, "..");
  }
  return path.resolve(__dirname, "../../..");
}

function configPath() {
  return path.join(app.getPath("userData"), "server-panel-config.json");
}

function defaultConfig() {
  return {
    port: 7777,
    registryPort: 8787,
    /** Public IP or Tailscale IP — clients connect here (NOT 192.168.x.x for remote friends). */
    publicAddress: "",
    /** Optional: https://xxx.trycloudflare.com/v1 — registry tunnel without port 8787 forward. */
    tunnelRegistryUrl: "",
    maxPlayers: 8,
  };
}

function readConfig() {
  const file = configPath();
  if (!fs.existsSync(file)) return defaultConfig();
  try {
    return { ...defaultConfig(), ...JSON.parse(fs.readFileSync(file, "utf8")) };
  } catch {
    return defaultConfig();
  }
}

function writeConfig(data) {
  const file = configPath();
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(data, null, 2), "utf8");
}

function registryDir() {
  const packaged = path.join(process.resourcesPath, "registry");
  if (fs.existsSync(path.join(packaged, "index.js"))) return packaged;
  const dev = path.join(repoRoot(), "Tools/server-registry");
  if (fs.existsSync(path.join(dev, "index.js"))) return dev;
  return packaged;
}

function resolveGameBinary() {
  const fromEnv = process.env.EXTRACTION_GAME_PATH;
  if (fromEnv && fs.existsSync(fromEnv)) return fromEnv;

  const root = repoRoot();
  const candidates =
    process.platform === "win32"
      ? [
          path.join(root, "game/ExtractionShooterServer.exe"),
          path.join(
            root,
            "asıl proje/ExtractionShooterPrototype/Builds/Server/Windows/ExtractionShooterServer.exe"
          ),
          path.join(
            root,
            "asıl proje/ExtractionShooterPrototype/Builds/Server/Windows/ExtractionShooterPrototype.exe"
          ),
        ]
      : [
          path.join(
            root,
            "game/ExtractionShooterServer.app/Contents/MacOS/ExtractionShooterPrototype"
          ),
          path.join(
            root,
            "asıl proje/ExtractionShooterPrototype/Builds/Server/ExtractionShooterPrototype.app/Contents/MacOS/ExtractionShooterPrototype"
          ),
        ];

  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  return null;
}

function listLanAddresses() {
  const ips = [];
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      if (net.family !== "IPv4" || net.internal) continue;
      ips.push(net.address);
    }
  }
  return ips.length ? ips : ["127.0.0.1"];
}

function registryBaseUrl(port) {
  return `http://127.0.0.1:${port}/v1`;
}

async function isRegistryHealthy(port) {
  try {
    const res = await fetch(`${registryBaseUrl(port)}/health`);
    if (!res.ok) return false;
    const data = await res.json();
    return data.ok === true;
  } catch {
    return false;
  }
}

async function registryIsRunning(port) {
  if (registryProcess != null && registryProcess.exitCode == null) return true;
  return isRegistryHealthy(port);
}

function isTailscaleIp(ip) {
  if (!ip) return false;
  const p = String(ip).trim().split(".").map(Number);
  if (p.length !== 4 || p[0] !== 100) return false;
  return p[1] >= 64 && p[1] <= 127;
}

function listTailscaleAddresses() {
  const ips = [];
  for (const nets of Object.values(os.networkInterfaces())) {
    for (const net of nets || []) {
      if (net.family !== "IPv4" || net.internal) continue;
      if (isTailscaleIp(net.address)) ips.push(net.address);
    }
  }
  return ips;
}

function getTailscaleInfo() {
  const ips = listTailscaleAddresses();
  const winExe = "C:\\Program Files\\Tailscale\\tailscale.exe";
  const installed =
    process.platform === "win32"
      ? fs.existsSync(winExe)
      : fs.existsSync("/Applications/Tailscale.app") || ips.length > 0;
  return {
    installed,
    connected: ips.length > 0,
    ip: ips[0] || null,
    ips,
  };
}

/** Tailscale IP first — remote friends, no port forward. */
async function resolveRemoteAddresses(cfg) {
  const lan = listLanAddresses()[0] || "127.0.0.1";
  const registryPort = cfg.registryPort || 8787;
  const gamePort = cfg.port || 7777;
  const tailscale = getTailscaleInfo();

  let gameAddress = String(cfg.publicAddress || "").trim();
  if (!gameAddress) {
    gameAddress = tailscale.ip || lan;
  }

  const registryUrl = `http://${gameAddress}:${registryPort}/v1`;

  return {
    lanAddress: lan,
    gameAddress,
    gameEndpoint: `${gameAddress}:${gamePort}`,
    registryUrl,
    tailscale,
    isRemoteReady: Boolean(tailscale.connected && tailscale.ip),
  };
}

async function unregisterFromRegistry(registryPort, serverId) {
  if (!serverId) return;
  try {
    const url = `${registryBaseUrl(registryPort)}/servers/${encodeURIComponent(serverId)}`;
    await fetch(url, { method: "DELETE" });
  } catch {
    /* registry offline */
  }
}

function killGameProcess(proc) {
  if (!proc || proc.exitCode != null) return;
  const pid = proc.pid;
  proc.kill("SIGTERM");
  if (process.platform === "win32" && pid) {
    setTimeout(() => {
      try {
        spawn("taskkill", ["/F", "/T", "/PID", String(pid)], { stdio: "ignore", shell: true });
      } catch {
        /* already exited */
      }
    }, 1500);
  }
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1024,
    height: 820,
    minWidth: 800,
    minHeight: 600,
    backgroundColor: "#050608",
    title: "Extraction Dedicated Server",
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, "preload.cjs"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.loadFile(path.join(__dirname, "../ui/index.html"));
}

async function startRegistry(port) {
  if (registryProcess && registryProcess.exitCode == null) {
    return { ok: true, alreadyRunning: true };
  }
  if (await isRegistryHealthy(port)) {
    return { ok: true, alreadyRunning: true };
  }

  const dir = registryDir();
  const entry = path.join(dir, "index.js");
  if (!fs.existsSync(entry)) {
    return { ok: false, error: `Registry bulunamadi: ${entry}` };
  }

  try {
    const env = { ...process.env, REGISTRY_PORT: String(port), ELECTRON_RUN_AS_NODE: "1" };
    registryProcess = spawn(process.execPath, [entry], {
      cwd: dir,
      env,
      stdio: "ignore",
    });
    registryProcess.on("exit", () => {
      registryProcess = null;
    });

    for (let i = 0; i < 10; i++) {
      await new Promise((r) => setTimeout(r, 300));
      if (await isRegistryHealthy(port)) return { ok: true };
      if (registryProcess.exitCode != null) break;
    }

    return { ok: false, error: `Registry baslatilamadi (port ${port})` };
  } catch (err) {
    return { ok: false, error: String(err.message || err) };
  }
}

function stopRegistry() {
  if (registryProcess && registryProcess.exitCode == null) {
    registryProcess.kill("SIGTERM");
  }
  registryProcess = null;
  return { ok: true };
}

async function startDedicatedServer(opts) {
  if (gameServerProcess && gameServerProcess.exitCode == null) {
    return { ok: false, error: "Dedicated server zaten calisiyor." };
  }

  const binary = resolveGameBinary();
  if (!binary) {
    return {
      ok: false,
      error:
        "Oyun server binary bulunamadi. game/ klasorune Windows/Mac build koy veya EXTRACTION_GAME_PATH ayarla.",
    };
  }

  const port = String(opts.port || 7777);
  const registryPort = String(opts.registryPort || 8787);
  const remote = await resolveRemoteAddresses(opts);
  const publicAddress = remote.gameAddress;
  const serverId = `dedicated-${Date.now()}`;

  try {
    gameServerProcess = spawn(
      binary,
      [
        "-batchmode",
        "-nographics",
        "-server",
        "-port",
        port,
        "-scene",
        DEDICATED_LOBBY_SCENE,
      ],
      {
        detached: false,
        stdio: "ignore",
        env: {
          ...process.env,
          EXTRACTION_MODE: "server",
          EXTRACTION_DEDICATED: "1",
          EXTRACTION_PORT: port,
          EXTRACTION_SCENE: DEDICATED_LOBBY_SCENE,
          EXTRACTION_REGISTRY_URL: registryBaseUrl(registryPort),
          EXTRACTION_SERVER_ID: serverId,
          EXTRACTION_SERVER_NAME: "DEDICATED",
          EXTRACTION_HOST_NAME: "SERVER",
          EXTRACTION_PUBLIC_ADDRESS: publicAddress,
        },
      }
    );
    gameServerProcess.on("exit", () => {
      gameServerProcess = null;
      activeServerId = null;
      serverStartedAt = null;
    });

    activeServerId = serverId;
    serverStartedAt = Date.now();

    return {
      ok: true,
      serverId,
      port,
      scene: DEDICATED_LOBBY_SCENE,
      publicAddress,
      registryUrl: remote.registryUrl,
      gameAddress: publicAddress,
      gameEndpoint: remote.gameEndpoint,
      tailscale: remote.tailscale,
      isRemoteReady: remote.isRemoteReady,
    };
  } catch (err) {
    return { ok: false, error: String(err.message || err) };
  }
}

function stopDedicatedServer() {
  const cfg = readConfig();
  const serverId = activeServerId;
  const registryPort = cfg.registryPort || 8787;

  if (serverId) {
    unregisterFromRegistry(registryPort, serverId);
  }

  if (gameServerProcess && gameServerProcess.exitCode == null) {
    killGameProcess(gameServerProcess);
  }
  gameServerProcess = null;
  activeServerId = null;
  serverStartedAt = null;
  return { ok: true };
}

async function fetchRegistryServer(registryPort, serverId) {
  if (!serverId) return null;
  try {
    const res = await fetch(registryBaseUrl(registryPort) + "/servers");
    if (!res.ok) return null;
    const data = await res.json();
    return (data.servers || []).find((s) => s.serverId === serverId) || null;
  } catch {
    return null;
  }
}

ipcMain.handle("panel:getInfo", async () => {
  const cfg = readConfig();
  const lan = listLanAddresses();
  const remote = await resolveRemoteAddresses(cfg);
  return {
    platform: process.platform,
    repoRoot: repoRoot(),
    gameBinary: resolveGameBinary(),
    registryDir: registryDir(),
    lanAddresses: lan,
    config: cfg,
    remote,
    status: {
      registryRunning: await registryIsRunning(cfg.registryPort || 8787),
      serverRunning: gameServerProcess != null && gameServerProcess.exitCode == null,
    },
  };
});

ipcMain.handle("panel:fetchPublicIp", async () => {
  const ts = getTailscaleInfo();
  if (ts.ip) {
    const cfg = readConfig();
    writeConfig({ ...cfg, publicAddress: ts.ip });
    const remote = await resolveRemoteAddresses({ ...cfg, publicAddress: ts.ip });
    return { ok: true, ip: ts.ip, remote, tailscale: ts };
  }
  return { ok: false, error: "Tailscale bagli degil. Tailscale ac, giris yap." };
});

ipcMain.handle("panel:getMonitorStatus", async () => {
  const cfg = readConfig();
  const info = {
    config: cfg,
    lanAddresses: listLanAddresses(),
    status: {
      registryRunning: await registryIsRunning(cfg.registryPort || 8787),
      serverRunning: gameServerProcess != null && gameServerProcess.exitCode == null,
    },
  };

  const uptimeMs = serverStartedAt ? Date.now() - serverStartedAt : null;
  const entry = await fetchRegistryServer(cfg.registryPort, activeServerId);

  return {
    info,
    uptimeMs,
    players: entry?.players ?? 0,
    maxPlayers: entry?.maxPlayers ?? cfg.maxPlayers ?? 8,
    scene: entry?.scene ?? null,
    clients: entry?.clients ?? [],
    heartbeatAgeMs: entry?.lastHeartbeat ? Date.now() - entry.lastHeartbeat : null,
    serverId: activeServerId,
  };
});

ipcMain.handle("panel:saveConfig", async (_e, data) => {
  writeConfig({ ...readConfig(), ...data });
  return true;
});

ipcMain.handle("panel:startRegistry", async (_e, { port } = {}) => {
  const cfg = readConfig();
  return await startRegistry(port || cfg.registryPort || 8787);
});

ipcMain.handle("panel:stopRegistry", async () => stopRegistry());

ipcMain.handle("panel:startServer", async (_e, opts) => {
  const cfg = { ...readConfig(), ...opts };
  writeConfig(cfg);

  const reg = await startRegistry(cfg.registryPort);
  if (!reg.ok) return reg;

  await new Promise((r) => setTimeout(r, 600));
  return startDedicatedServer(cfg);
});

ipcMain.handle("panel:stopServer", async () => {
  stopDedicatedServer();
  return { ok: true };
});

ipcMain.handle("panel:stopAll", async () => {
  stopDedicatedServer();
  stopRegistry();
  return { ok: true };
});

app.whenReady().then(createWindow);

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});

app.on("before-quit", () => {
  stopDedicatedServer();
  stopRegistry();
});
