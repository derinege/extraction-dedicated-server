/**
 * In-memory rate limit + registry write auth.
 * REGISTRY_SECRET set => register/heartbeat/unregister/DELETE require X-Registry-Token.
 */

const buckets = new Map();

export function rateLimit(key, max, windowMs) {
  const now = Date.now();
  let bucket = buckets.get(key);
  if (!bucket || now - bucket.start > windowMs) {
    bucket = { start: now, count: 0 };
    buckets.set(key, bucket);
  }
  bucket.count += 1;
  if (bucket.count > max) {
    return false;
  }
  return true;
}

export function clientKey(req) {
  const fwd = req.headers["x-forwarded-for"];
  if (typeof fwd === "string" && fwd.length) return fwd.split(",")[0].trim();
  return req.socket.remoteAddress?.replace("::ffff:", "") || "unknown";
}

export function requireRegistrySecret(req, res, next) {
  const secret = String(process.env.REGISTRY_SECRET || "").trim();
  if (!secret) return next();

  const token = String(
    req.headers["x-registry-token"] ||
      (req.headers.authorization || "").replace(/^Bearer\s+/i, "") ||
      ""
  ).trim();

  if (token !== secret) {
    return res.status(401).json({ error: "invalid or missing registry token" });
  }
  return next();
}

export function mutationRateLimit(req, res, next) {
  const key = `mut:${clientKey(req)}`;
  if (!rateLimit(key, 40, 60_000)) {
    return res.status(429).json({ error: "too many requests" });
  }
  return next();
}

export function readRateLimit(req, res, next) {
  const key = `read:${clientKey(req)}`;
  if (!rateLimit(key, 120, 60_000)) {
    return res.status(429).json({ error: "too many requests" });
  }
  return next();
}
