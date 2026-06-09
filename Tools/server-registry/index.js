/**
 * Extraction Shooter — online server registry (master list).
 * Dedicated / listen server'lar buraya kayıt olur; client'lar GET /v1/servers ile listeler.
 *
 * Start: npm install && npm start  (default :8787)
 * Env: REGISTRY_PORT, REGISTRY_TTL_SEC
 */
import cors from "cors";
import express from "express";
import {
  clientKey,
  mutationRateLimit,
  readRateLimit,
  requireRegistrySecret,
} from "./security.js";

const app = express();

const corsOrigins = String(process.env.REGISTRY_CORS_ORIGINS || "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);
app.use(
  cors(
    corsOrigins.length
      ? {
          origin(origin, cb) {
            if (!origin || corsOrigins.includes(origin)) cb(null, true);
            else cb(new Error("cors blocked"));
          },
        }
      : undefined
  )
);
app.use(express.json({ limit: "32kb" }));

const PORT = Number(process.env.REGISTRY_PORT || 8787);
const BIND = String(process.env.REGISTRY_BIND || "0.0.0.0").trim() || "0.0.0.0";
const TTL_MS = Number(process.env.REGISTRY_TTL_SEC || 25) * 1000;
const MAX_SERVERS = Math.max(1, Number(process.env.REGISTRY_MAX_SERVERS || 16));

/** @type {Map<string, object>} */
const servers = new Map();

function prune() {
  const now = Date.now();
  for (const [id, s] of servers) {
    if (now - s.lastHeartbeat > TTL_MS) servers.delete(id);
  }
}

setInterval(prune, 5000);

function clientIp(req) {
  const fwd = req.headers["x-forwarded-for"];
  if (typeof fwd === "string" && fwd.length) return fwd.split(",")[0].trim();
  return req.socket.remoteAddress?.replace("::ffff:", "") || "0.0.0.0";
}

app.get("/", (_req, res) => {
  prune();
  const list = [...servers.values()].sort((a, b) => b.lastHeartbeat - a.lastHeartbeat);
  const rows = list.length
    ? list
        .map(
          (s) =>
            `<tr><td>${escapeHtml(s.name)}</td><td>${escapeHtml(s.hostName)}</td><td><code>${escapeHtml(s.address)}:${s.port}</code></td><td>${s.players}/${s.maxPlayers}</td><td>${escapeHtml(s.region)}</td></tr>`
        )
        .join("")
    : `<tr><td colspan="5" style="opacity:.7">Sunucu bekleniyor… (heartbeat gelince burada görünür, sayfa 5 sn'de bir yenilenir)</td></tr>`;

  res.type("html").send(`<!DOCTYPE html>
<html lang="tr"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Extraction Shooter — Server Registry</title>
<style>
  body{font-family:system-ui,sans-serif;background:#0d1117;color:#e6edf3;margin:0;padding:24px;max-width:900px}
  h1{font-size:1.4rem;margin:0 0 8px} p{opacity:.8;line-height:1.5}
  table{width:100%;border-collapse:collapse;margin:20px 0} th,td{text-align:left;padding:10px;border-bottom:1px solid #30363d}
  code{background:#161b22;padding:2px 6px;border-radius:4px}
  a{color:#58a6ff}
</style></head><body>
<h1>Extraction Shooter — Online Registry</h1>
<p>Unity menüsü hazır olunca client buradan sunucu listesini çeker. Şimdilik tarayıcı testi.</p>
<table><thead><tr><th>Raid</th><th>Host</th><th>Adres</th><th>Oyuncu</th><th>Bölge</th></tr></thead>
<tbody>${rows}</tbody></table>
<p>API: <a href="/v1/servers">/v1/servers</a> · <a href="/v1/health">/v1/health</a></p>
<script>setTimeout(()=>location.reload(),5000)</script>
</body></html>`);
});

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

app.get("/v1/health", readRateLimit, (_req, res) => {
  res.json({ ok: true, servers: servers.size });
});

/** Server kendi public IP'sini öğrenmek için (VPS arkasında değilse). */
app.get("/v1/myip", readRateLimit, (req, res) => {
  res.json({ address: clientIp(req) });
});

app.get("/v1/servers", readRateLimit, (_req, res) => {
  prune();
  const list = [...servers.values()]
    .sort((a, b) => b.lastHeartbeat - a.lastHeartbeat)
    .map(
      ({
        serverId,
        name,
        hostName,
        address,
        port,
        players,
        maxPlayers,
        region,
        scene,
        clients,
        lastHeartbeat,
      }) => ({
        serverId,
        name,
        hostName,
        address,
        port,
        players,
        maxPlayers,
        region,
        scene: scene || "Base",
        clients: clients || [],
        lastHeartbeat,
      })
    );
  res.json({ servers: list });
});

app.post("/v1/servers/register", mutationRateLimit, requireRegistrySecret, (req, res) => {
  const b = req.body || {};
  const serverId = String(b.serverId || "").trim();
  const port = Number(b.port);
  if (!serverId || !Number.isFinite(port) || port <= 0 || port > 65535) {
    return res.status(400).json({ error: "serverId and valid port required" });
  }

  if (!servers.has(serverId) && servers.size >= MAX_SERVERS) {
    return res.status(503).json({ error: "server list full" });
  }

  let address = String(b.address || "").trim();
  if (!address || address === "0.0.0.0" || address === "auto") address = clientIp(req);

  if (/^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)/.test(address)) {
    return res.status(400).json({ error: "private address not allowed for public registry" });
  }

  const entry = {
    serverId,
    name: String(b.name || "Raid Server").slice(0, 64),
    hostName: String(b.hostName || "Host").slice(0, 32),
    address,
    port,
    players: Math.max(0, Number(b.players) || 0),
    maxPlayers: Math.max(1, Number(b.maxPlayers) || 8),
    region: String(b.region || "GLOBAL").slice(0, 16),
    scene: String(b.scene || "Base").slice(0, 32),
    clients: normalizeClients(b.clients),
    lastHeartbeat: Date.now(),
  };
  servers.set(serverId, entry);
  res.json({ ok: true, server: entry });
});

app.post("/v1/servers/heartbeat", mutationRateLimit, requireRegistrySecret, (req, res) => {
  const serverId = String(req.body?.serverId || "").trim();
  if (!serverId || !servers.has(serverId)) {
    return res.status(404).json({ error: "unknown serverId" });
  }
  const s = servers.get(serverId);
  if (req.body.players != null) s.players = Math.max(0, Number(req.body.players) || 0);
  if (req.body.maxPlayers != null) s.maxPlayers = Math.max(1, Number(req.body.maxPlayers) || s.maxPlayers);
  if (req.body.scene != null) s.scene = String(req.body.scene || "Base").slice(0, 32);
  if (req.body.clients != null) s.clients = normalizeClients(req.body.clients);
  s.lastHeartbeat = Date.now();
  res.json({ ok: true });
});

function normalizeClients(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .slice(0, 32)
    .map((c, i) => ({
      id: Number.isFinite(Number(c?.id)) ? Number(c.id) : i + 1,
      name: String(c?.name || `Client ${i + 1}`).slice(0, 48),
      pingMs: Math.max(0, Number(c?.pingMs) || 0),
    }));
}

app.post("/v1/servers/unregister", mutationRateLimit, requireRegistrySecret, (req, res) => {
  const serverId = String(req.body?.serverId || "").trim();
  if (!serverId) return res.status(400).json({ error: "serverId required" });
  servers.delete(serverId);
  res.json({ ok: true });
});

app.delete("/v1/servers/:serverId", mutationRateLimit, requireRegistrySecret, (req, res) => {
  servers.delete(req.params.serverId);
  res.json({ ok: true });
});

app.listen(PORT, BIND, () => {
  const secretOn = Boolean(String(process.env.REGISTRY_SECRET || "").trim());
  console.log(
    `[registry] http://${BIND}:${PORT}  TTL=${TTL_MS / 1000}s  auth=${secretOn ? "on" : "off"}  max=${MAX_SERVERS}`
  );
});
