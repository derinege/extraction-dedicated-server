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
    publicAddress: "",
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

function startRegistry(port) {
  if (registryProcess && registryProcess.exitCode == null) {
    return { ok: true, alreadyRunning: true };
  }

  const dir = registryDir();
  const entry = path.join(dir, "index.js");
  if (!fs.existsSync(entry)) {
    return { ok: false, error: `Registry bulunamadi: ${entry}` };
  }

  try {
    const env = { ...process.env, REGISTRY_PORT: String(port) };
    if (app.isPackaged) {
      registryProcess = spawn(process.execPath, [entry], {
        cwd: dir,
        env: { ...env, ELECTRON_RUN_AS_NODE: "1" },
        stdio: "ignore",
      });
    } else {
      registryProcess = spawn(process.platform === "win32" ? "node.exe" : "node", [entry], {
        cwd: dir,
        env,
        stdio: "ignore",
        shell: process.platform === "win32",
      });
    }
    registryProcess.on("exit", () => {
      registryProcess = null;
    });
    return { ok: true };
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

function startDedicatedServer(opts) {
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
  const publicAddress =
    String(opts.publicAddress || "").trim() || listLanAddresses()[0] || "127.0.0.1";
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
      registryUrl: `http://${publicAddress}:${registryPort}/v1`,
      gameAddress: publicAddress,
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
  return {
    platform: process.platform,
    repoRoot: repoRoot(),
    gameBinary: resolveGameBinary(),
    registryDir: registryDir(),
    lanAddresses: lan,
    config: cfg,
    status: {
      registryRunning: registryProcess != null && registryProcess.exitCode == null,
      serverRunning: gameServerProcess != null && gameServerProcess.exitCode == null,
    },
  };
});

ipcMain.handle("panel:getMonitorStatus", async () => {
  const cfg = readConfig();
  const info = {
    config: cfg,
    lanAddresses: listLanAddresses(),
    status: {
      registryRunning: registryProcess != null && registryProcess.exitCode == null,
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
  return startRegistry(port || cfg.registryPort || 8787);
});

ipcMain.handle("panel:stopRegistry", async () => stopRegistry());

ipcMain.handle("panel:startServer", async (_e, opts) => {
  const cfg = { ...readConfig(), ...opts };
  writeConfig(cfg);

  const reg = startRegistry(cfg.registryPort);
  if (!reg.ok) return reg;

  await new Promise((r) => setTimeout(r, 600));
  return startDedicatedServer(cfg);
});

ipcMain.handle("panel:stopServer", async () => stopDedicatedServer());

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
