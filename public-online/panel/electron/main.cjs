const { app, BrowserWindow, ipcMain } = require("electron");
const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");
const os = require("os");
const {
  loadPlayitConfig,
  loadRegistrySecret,
  ensureRegistrySecret,
  ensurePlayitConfigFromExample,
  playitConfigPath,
} = require("./playit-config.cjs");

let mainWindow;
/** @type {import('child_process').ChildProcess | null} */
let registryProcess = null;
/** @type {import('child_process').ChildProcess | null} */
let gameServerProcess = null;

const DEDICATED_LOBBY_SCENE = "Base";

let activeServerId = null;
let serverStartedAt = null;

function repoRoot() {
  if (app.isPackaged) {
    return path.resolve(process.resourcesPath, "..", "..");
  }
  return path.resolve(__dirname, "../../..");
}

function configPath() {
  return path.join(app.getPath("userData"), "public-server-panel-config.json");
}

function defaultConfig() {
  return {
    port: 7777,
    registryPort: 8787,
    maxPlayers: 8,
  };
}

function readConfig() {
  const file = configPath();
  if (!fs.existsSync(file)) return defaultConfig();
  try {
    const cfg = { ...defaultConfig(), ...JSON.parse(fs.readFileSync(file, "utf8")) };
    const playit = loadPlayitConfig(repoRoot());
    if (playit.ok) {
      cfg.port = playit.localGamePort;
      cfg.registryPort = playit.localRegistryPort;
    }
    return cfg;
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
        ]
      : [
          path.join(
            root,
            "game/ExtractionShooterServer.app/Contents/MacOS/ExtractionShooterPrototype"
          ),
        ];

  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  return null;
}

function listLanAddresses() {
  const ips = [];
  for (const nets of Object.values(os.networkInterfaces())) {
    for (const net of nets || []) {
      if (net.family !== "IPv4" || net.internal) continue;
      ips.push(net.address);
    }
  }
  return ips.length ? ips : ["127.0.0.1"];
}

function registryBaseUrl(port) {
  return `http://127.0.0.1:${port}/v1`;
}

function registryAuthHeaders() {
  const secret = loadRegistrySecret(repoRoot());
  if (!secret) return {};
  return { "X-Registry-Token": secret };
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

async function resolveRemoteAddresses(cfg) {
  const lan = listLanAddresses()[0] || "127.0.0.1";
  const playit = loadPlayitConfig(repoRoot());

  if (!playit.ok) {
    return {
      lanAddress: lan,
      gameAddress: "",
      gameEndpoint: "—",
      registryUrl: "—",
      playit,
      tailscale: { installed: false, connected: false, ip: null, ips: [] },
      isRemoteReady: false,
    };
  }

  const gameAddress = playit.gameHost;
  const gamePort = playit.gamePort;
  const tailscale = {
    installed: true,
    connected: true,
    ip: `${gameAddress}:${gamePort}`,
    ips: [gameAddress],
  };

  return {
    lanAddress: lan,
    gameAddress,
    gameEndpoint: `${gameAddress}:${gamePort}`,
    registryUrl: playit.registryPublicUrl,
    playit,
    tailscale,
    isRemoteReady: true,
  };
}

async function unregisterFromRegistry(registryPort, serverId) {
  if (!serverId) return;
  try {
    const url = `${registryBaseUrl(registryPort)}/servers/${encodeURIComponent(serverId)}`;
    await fetch(url, { method: "DELETE", headers: registryAuthHeaders() });
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

  const root = repoRoot();
  const secret = ensureRegistrySecret(root);

  try {
    const env = {
      ...process.env,
      REGISTRY_PORT: String(port),
      REGISTRY_BIND: "127.0.0.1",
      REGISTRY_SECRET: secret,
      REGISTRY_MAX_SERVERS: "8",
      ELECTRON_RUN_AS_NODE: "1",
    };
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

  const playit = loadPlayitConfig(repoRoot());
  if (!playit.ok) {
    return {
      ok: false,
      error: `${playit.error}. Dosya: ${playit.path}`,
    };
  }

  const binary = resolveGameBinary();
  if (!binary) {
    return {
      ok: false,
      error: "Oyun server binary bulunamadi. game/ klasorune Windows build koy.",
    };
  }

  const localPort = String(playit.localGamePort);
  const registryPort = String(playit.localRegistryPort);
  const remote = await resolveRemoteAddresses(opts);
  const publicAddress = playit.gameHost;
  const publicPort = String(playit.gamePort);
  const serverId = `dedicated-${Date.now()}`;
  const registrySecret = loadRegistrySecret(repoRoot());

  try {
    gameServerProcess = spawn(
      binary,
      ["-batchmode", "-nographics", "-server", "-port", localPort, "-scene", DEDICATED_LOBBY_SCENE],
      {
        detached: false,
        stdio: "ignore",
        env: {
          ...process.env,
          EXTRACTION_MODE: "server",
          EXTRACTION_DEDICATED: "1",
          EXTRACTION_PORT: localPort,
          EXTRACTION_SCENE: DEDICATED_LOBBY_SCENE,
          EXTRACTION_REGISTRY_URL: registryBaseUrl(registryPort),
          EXTRACTION_REGISTRY_SECRET: registrySecret,
          EXTRACTION_SERVER_ID: serverId,
          EXTRACTION_SERVER_NAME: "DEDICATED",
          EXTRACTION_HOST_NAME: "SERVER",
          EXTRACTION_PUBLIC_ADDRESS: publicAddress,
          EXTRACTION_PUBLIC_PORT: publicPort,
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
      port: localPort,
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
  ensurePlayitConfigFromExample(repoRoot());
  ensureRegistrySecret(repoRoot());

  const cfg = readConfig();
  const lan = listLanAddresses();
  const remote = await resolveRemoteAddresses(cfg);
  return {
    platform: process.platform,
    networkMode: "playit",
    playitConfigPath: playitConfigPath(repoRoot()),
    registrySecretReady: Boolean(loadRegistrySecret(repoRoot())),
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
  const playit = loadPlayitConfig(repoRoot());
  if (!playit.ok) {
    return { ok: false, error: playit.error };
  }
  const remote = await resolveRemoteAddresses(readConfig());
  return { ok: true, ip: playit.gameHost, remote };
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
