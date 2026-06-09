const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

function repoPublicOnlineDir(repoRoot) {
  return path.join(repoRoot, "public-online");
}

function playitConfigPath(repoRoot) {
  return path.join(repoPublicOnlineDir(repoRoot), "playit.config.json");
}

function registrySecretPath(repoRoot) {
  return path.join(repoPublicOnlineDir(repoRoot), "secrets", "registry-secret.txt");
}

function exampleConfigPath(repoRoot) {
  return path.join(repoPublicOnlineDir(repoRoot), "playit.config.example.json");
}

function readJsonFile(file) {
  if (!fs.existsSync(file)) return null;
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return null;
  }
}

function normalizeRegistryUrl(url) {
  const raw = String(url || "").trim().replace(/\/$/, "");
  if (!raw) return "";
  return raw.endsWith("/v1") ? raw : `${raw}/v1`;
}

function loadPlayitConfig(repoRoot) {
  const file = playitConfigPath(repoRoot);
  const data = readJsonFile(file);
  if (!data) return { ok: false, error: "playit.config.json bulunamadi", path: file };

  const registryPublicUrl = normalizeRegistryUrl(data.registryPublicUrl);
  const gameHost = String(data.gameHost || "").trim();
  const gamePort = Number(data.gamePort);
  const localGamePort = Number(data.localGamePort) || 7777;
  const localRegistryPort = Number(data.localRegistryPort) || 8787;

  const missing = [];
  if (!registryPublicUrl) missing.push("registryPublicUrl");
  if (!gameHost) missing.push("gameHost");
  if (!Number.isFinite(gamePort) || gamePort <= 0) missing.push("gamePort");

  if (missing.length) {
    return {
      ok: false,
      error: `playit.config.json eksik alan: ${missing.join(", ")}`,
      path: file,
      partial: { registryPublicUrl, gameHost, gamePort, localGamePort, localRegistryPort },
    };
  }

  return {
    ok: true,
    path: file,
    registryPublicUrl,
    gameHost,
    gamePort,
    localGamePort,
    localRegistryPort,
  };
}

function loadRegistrySecret(repoRoot) {
  const fromEnv = String(process.env.REGISTRY_SECRET || process.env.EXTRACTION_REGISTRY_SECRET || "").trim();
  if (fromEnv) return fromEnv;

  const file = registrySecretPath(repoRoot);
  if (!fs.existsSync(file)) return "";
  return fs.readFileSync(file, "utf8").trim();
}

function ensureRegistrySecret(repoRoot) {
  const existing = loadRegistrySecret(repoRoot);
  if (existing) return existing;

  const dir = path.dirname(registrySecretPath(repoRoot));
  fs.mkdirSync(dir, { recursive: true });
  const secret = crypto.randomBytes(32).toString("hex");
  fs.writeFileSync(registrySecretPath(repoRoot), secret, "utf8");
  return secret;
}

function ensurePlayitConfigFromExample(repoRoot) {
  const target = playitConfigPath(repoRoot);
  if (fs.existsSync(target)) return { created: false, path: target };

  const example = exampleConfigPath(repoRoot);
  if (!fs.existsSync(example)) return { created: false, path: target, error: "example missing" };

  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(example, target);
  return { created: true, path: target };
}

module.exports = {
  playitConfigPath,
  registrySecretPath,
  loadPlayitConfig,
  loadRegistrySecret,
  ensureRegistrySecret,
  ensurePlayitConfigFromExample,
  normalizeRegistryUrl,
};
