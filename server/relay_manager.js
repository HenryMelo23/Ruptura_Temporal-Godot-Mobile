"use strict";

const http = require("http");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const { renderLeaderboardSite } = require("./leaderboard_site");

const MANAGER_PORT = numberEnv("PORT", 8090);
const ROOM_HOST = process.env.ROOM_HOST || "72.61.217.238";
const ROOM_PORT_START = numberEnv("ROOM_PORT_START", 4522);
const ROOM_PORT_END = numberEnv("ROOM_PORT_END", 4599);
const GODOT_BIN = process.env.GODOT_BIN || "/opt/godot/Godot_v4.7-stable_linux.x86_64";
const PROJECT_PATH = process.env.PROJECT_PATH || "/opt/ruptura/Ruptura_Temporal-Godot-Mobile";
const ROOM_IDLE_MS = numberEnv("ROOM_IDLE_MS", 15 * 60 * 1000);
const ROOM_EVENT_LIMIT = numberEnv("ROOM_EVENT_LIMIT", 80);
const WARM_STANDBY_ROOMS = numberEnv("WARM_STANDBY_ROOMS", 1, true);
const WARM_STANDBY_REFILL_MS = numberEnv("WARM_STANDBY_REFILL_MS", 1500);
const ROOM_READY_TIMEOUT_MS = numberEnv("ROOM_READY_TIMEOUT_MS", 30 * 1000);
const MAX_PLAYERS = 3;
const STREAMING_ENABLED = process.env.STREAMING_ENABLED === "1";
const STREAM_PUBLIC_HOST = process.env.STREAM_PUBLIC_HOST || ROOM_HOST;
const STREAM_PUBLIC_SCHEME = process.env.STREAM_PUBLIC_SCHEME || "http";
const STREAM_WEBRTC_PORT = numberEnv("STREAM_WEBRTC_PORT", 8889);
const STREAM_HLS_PORT = numberEnv("STREAM_HLS_PORT", 8888);
const STREAM_RTMP_PORT = numberEnv("STREAM_RTMP_PORT", 1935);
const STREAM_RTMP_APP = process.env.STREAM_RTMP_APP || "live";
const DEFAULT_MANAGER_PUBLIC_BASE_URL = "http://72.61.217.238:8090";
const STREAM_MANAGER_PUBLIC_BASE_URL = publicManagerBaseUrl();
const STREAM_TTL_MS = numberEnv("STREAM_TTL_MS", 30 * 60 * 1000);
const STREAM_MAX_ACTIVE = numberEnv("STREAM_MAX_ACTIVE", 2);
const STREAM_FRAME_MAX_BYTES = numberEnv("STREAM_FRAME_MAX_BYTES", 2_400_000);
const STREAM_FRAME_BUFFER_MAX = numberEnv("STREAM_FRAME_BUFFER_MAX", 8);
const STREAM_FRAME_BUFFER_MS = numberEnv("STREAM_FRAME_BUFFER_MS", 100);
const RUN_REPORT_MAX_BYTES = numberEnv("RUN_REPORT_MAX_BYTES", 512 * 1024);
const LEADERBOARD_PATH = process.env.LEADERBOARD_PATH || path.join(__dirname, "leaderboard_runs.json");
const LEADERBOARD_MAX_RUNS = numberEnv("LEADERBOARD_MAX_RUNS", 500);
const RUN_REPORT_INTEGRITY_VERSION = 1;
const RUN_REPORT_INTEGRITY_MIN_VERSION_CODE = 23002;
const RUN_REPORT_INTEGRITY_SALT = "ruptura-temporal-run-integrity-v1-2.0.30c";
const RUN_REPORT_SESSION_MIN_VERSION_CODE = numberEnv("RUN_REPORT_SESSION_MIN_VERSION_CODE", 23003);
const RUN_REPORT_COMPETITIVE_MIN_VERSION_CODE = numberEnv("RUN_REPORT_COMPETITIVE_MIN_VERSION_CODE", RUN_REPORT_SESSION_MIN_VERSION_CODE);
const RUN_REPORT_MAX_CLOCK_SKEW_SECONDS = numberEnv("RUN_REPORT_MAX_CLOCK_SKEW_SECONDS", 10 * 60);
const RUN_REPORT_MAX_AGE_SECONDS = numberEnv("RUN_REPORT_MAX_AGE_SECONDS", 36 * 60 * 60);
const RUN_SECURITY_PATH = process.env.RUN_SECURITY_PATH || path.join(__dirname, "leaderboard_security.json");
const RUN_SESSION_TTL_MS = numberEnv("RUN_SESSION_TTL_MS", 8 * 60 * 60 * 1000);
const RUN_SESSION_CHECKPOINT_INTERVAL_SECONDS = numberEnv("RUN_SESSION_CHECKPOINT_INTERVAL_SECONDS", 120);
const RUN_SESSION_MAX_CHECKPOINT_GAP_SECONDS = numberEnv("RUN_SESSION_MAX_CHECKPOINT_GAP_SECONDS", 95);
const RUN_SESSION_TIMELINE_LIMIT = numberEnv("RUN_SESSION_TIMELINE_LIMIT", 1440);
const UMBRA_TRAINING_MIN_PHASE1_SECONDS = numberEnv("UMBRA_TRAINING_MIN_PHASE1_SECONDS", 300);
const UMBRA_MIND_REFRESH_DAYS = numberEnv("UMBRA_MIND_REFRESH_DAYS", 7);
const RUN_SECURITY_WINDOW_MS = numberEnv("RUN_SECURITY_WINDOW_MS", 10 * 60 * 1000);
const RUN_SECURITY_MAX_REPORTS_PER_WINDOW = numberEnv("RUN_SECURITY_MAX_REPORTS_PER_WINDOW", 10);
const RUN_SECURITY_BLOCK_THRESHOLD = numberEnv("RUN_SECURITY_BLOCK_THRESHOLD", 4);
const RUN_SECURITY_BLOCK_MS = numberEnv("RUN_SECURITY_BLOCK_MS", 30 * 60 * 1000);
const RUN_SECURITY_AUDIT_LIMIT = numberEnv("RUN_SECURITY_AUDIT_LIMIT", 500);
const RUN_AUDIT_BENIGN_REASONS = new Set([
  "duration_exceeds_wall_clock",
  "checkpoint_duration_regressed",
  "checkpoint_phase_regressed",
  "checkpoint_cards_jump",
  "session_cards_not_observed",
  "session_phase_not_observed",
  "session_kills_not_observed",
  "session_points_not_observed",
  "session_boss_damage_not_observed",
  "session_checkpoint_gap"
]);
const ANDROID_UPDATE_ROOT = path.resolve(process.env.ANDROID_UPDATE_ROOT || path.join(__dirname, "updates", "android"));
const WINDOWS_UPDATE_ROOT = path.resolve(process.env.WINDOWS_UPDATE_ROOT || path.join(__dirname, "updates", "windows"));
const ANDROID_UPDATE_MANIFEST = path.join(ANDROID_UPDATE_ROOT, "latest.json");
const WINDOWS_UPDATE_MANIFEST = path.join(WINDOWS_UPDATE_ROOT, "latest.json");

const rooms = new Map();
const streams = new Map();
let warmRefillTimer = null;

function numberEnv(name, fallback, allowZero = false) {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && (value > 0 || (allowZero && value === 0)) ? value : fallback;
}

function clampNumber(value, fallback, min, max) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) {
    return fallback;
  }
  return Math.max(min, Math.min(max, numeric));
}

function publicManagerBaseUrl() {
  const configured = String(process.env.STREAM_MANAGER_PUBLIC_BASE_URL || "").trim().replace(/\/+$/, "");
  if (!configured) {
    return DEFAULT_MANAGER_PUBLIC_BASE_URL;
  }
  if (/^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/i.test(configured) && process.env.ALLOW_LOCAL_PUBLIC_BASE_URL !== "1") {
    console.warn(`Ignoring local STREAM_MANAGER_PUBLIC_BASE_URL=${configured}; using ${DEFAULT_MANAGER_PUBLIC_BASE_URL}`);
    return DEFAULT_MANAGER_PUBLIC_BASE_URL;
  }
  return configured;
}

function leaderboardRunUrl(run) {
  return `${STREAM_MANAGER_PUBLIC_BASE_URL}/leaderboard/run/${encodeURIComponent(String(run && run.id || ""))}`;
}

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,X-Frame-Seq,X-Frame-At",
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(body)
  });
  res.end(body);
}

function sendStreamingDisabled(res) {
  sendJson(res, 410, {
    ok: false,
    error: "streaming disabled",
    message: "Ruptura QA streaming was removed. Multiplayer, ranking, and APK updates remain active."
  });
}

function updateConfig(platform) {
  if (platform === "windows") {
    return {
      platform: "windows",
      root: WINDOWS_UPDATE_ROOT,
      manifest: WINDOWS_UPDATE_MANIFEST,
      extension: ".exe",
      urlField: "exe_url",
      downloadPath: "/updates/windows/download/"
    };
  }
  return {
    platform: "android",
    root: ANDROID_UPDATE_ROOT,
    manifest: ANDROID_UPDATE_MANIFEST,
    extension: ".apk",
    urlField: "apk_url",
    downloadPath: "/updates/android/download/"
  };
}

function readUpdateManifest(platform = "android") {
  const config = updateConfig(platform);
  try {
    const raw = fs.readFileSync(config.manifest, "utf8").replace(/^\uFEFF/, "");
    const parsed = JSON.parse(raw);
    const filename = path.basename(String(parsed.filename || ""));
    const versionCode = Math.max(0, Math.floor(Number(parsed.version_code) || 0));
    const sha256 = String(parsed.sha256 || "").toLowerCase();
    const filePath = filename ? path.join(config.root, filename) : "";
    if (!filename.endsWith(config.extension) || versionCode <= 0 || !/^[a-f0-9]{64}$/.test(sha256) || !filePath || !fs.existsSync(filePath)) {
      return null;
    }
    const stat = fs.statSync(filePath);
    if (!stat.isFile()) {
      return null;
    }
    return {
      version: String(parsed.version || "").slice(0, 32),
      versionCode,
      filename,
      sha256,
      size: stat.size,
      notes: Array.isArray(parsed.notes) ? parsed.notes.map((note) => String(note).slice(0, 240)).slice(0, 8) : [],
      mandatory: Boolean(parsed.mandatory),
      publishedAt: String(parsed.published_at || "").slice(0, 64),
      filePath
    };
  } catch (_error) {
    return null;
  }
}

function readAndroidUpdateManifest() {
  return readUpdateManifest("android");
}

function updatePublic(platform = "android", currentVersionCode = 0) {
  const config = updateConfig(platform);
  const update = readUpdateManifest(platform);
  if (!update) {
    return { ok: true, available: false, current_version_code: currentVersionCode };
  }
  const payload = {
    ok: true,
    available: update.versionCode > currentVersionCode,
    current_version_code: currentVersionCode,
    version: update.version,
    version_code: update.versionCode,
    size: update.size,
    sha256: update.sha256,
    notes: update.notes,
    mandatory: update.mandatory,
    published_at: update.publishedAt,
    filename: update.filename
  };
  payload[config.urlField] = `${STREAM_MANAGER_PUBLIC_BASE_URL}${config.downloadPath}${encodeURIComponent(update.filename)}`;
  payload.download_url = payload[config.urlField];
  return payload;
}

function androidUpdatePublic(currentVersionCode = 0) {
  return updatePublic("android", currentVersionCode);
}

function sendUpdateFile(req, res, platform, filename) {
  const update = readUpdateManifest(platform);
  const requested = path.basename(decodeURIComponent(filename || ""));
  if (!update || requested !== update.filename) {
    sendJson(res, 404, { error: `${platform} update not found` });
    return;
  }
  const total = update.size;
  const range = String(req.headers.range || "");
  let start = 0;
  let end = total - 1;
  let status = 200;
  if (range) {
    const match = range.match(/^bytes=(\d*)-(\d*)$/);
    if (!match) {
      res.writeHead(416, { "Content-Range": `bytes */${total}` });
      res.end();
      return;
    }
    if (match[1] === "" && match[2] !== "") {
      const suffix = Math.max(1, Number(match[2]) || 0);
      start = Math.max(0, total - suffix);
    } else {
      start = Math.max(0, Number(match[1]) || 0);
      end = match[2] === "" ? end : Math.min(end, Number(match[2]) || 0);
    }
    if (start > end || start >= total) {
      res.writeHead(416, { "Content-Range": `bytes */${total}` });
      res.end();
      return;
    }
    status = 206;
  }
  const headers = {
    "Accept-Ranges": "bytes",
    "Cache-Control": "public, max-age=31536000, immutable",
    "Content-Type": "application/vnd.android.package-archive",
    "Content-Disposition": `attachment; filename="${update.filename.replace(/"/g, "")}"`,
    "Content-Length": end - start + 1
  };
  if (status === 206) {
    headers["Content-Range"] = `bytes ${start}-${end}/${total}`;
  }
  res.writeHead(status, headers);
  if (req.method === "HEAD") {
    res.end();
    return;
  }
  const stream = fs.createReadStream(update.filePath, { start, end });
  stream.on("error", () => res.destroy());
  stream.pipe(res);
}

function sendAndroidApk(req, res, filename) {
  sendUpdateFile(req, res, "android", filename);
}

function readJson(req, maxBytes = 16 * 1024) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.setEncoding("utf8");
    req.on("data", (chunk) => {
      body += chunk;
      if (Buffer.byteLength(body) > maxBytes) {
        reject(new Error("payload too large"));
        req.destroy();
      }
    });
    req.on("end", () => {
      if (!body) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(body));
      } catch (error) {
        reject(error);
      }
    });
    req.on("error", reject);
  });
}

function readBinary(req, maxBytes = STREAM_FRAME_MAX_BYTES) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let total = 0;
    let settled = false;
    req.on("data", (chunk) => {
      if (settled) {
        return;
      }
      total += chunk.length;
      if (total > maxBytes) {
        settled = true;
        const error = new Error("frame too large");
        error.statusCode = 413;
        reject(error);
        req.resume();
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => {
      if (!settled) {
        settled = true;
        resolve(Buffer.concat(chunks, total));
      }
    });
    req.on("error", (error) => {
      if (!settled) {
        settled = true;
        reject(error);
      }
    });
  });
}

function roomPublic(room) {
  const expiresInMs = Math.max(0, room.lastSeen + ROOM_IDLE_MS - Date.now());
  return {
    code: room.code,
    host: ROOM_HOST,
    port: room.port,
    players: room.players,
    maxPlayers: MAX_PLAYERS,
    createdAt: room.createdAt,
    lastSeen: room.lastSeen,
    expiresInMs,
    heartbeatCount: room.heartbeatCount || 0
  };
}

function boundUdpPorts() {
  const ports = new Set();
  if (process.platform !== "linux") {
    return ports;
  }
  for (const table of ["/proc/net/udp", "/proc/net/udp6"]) {
    try {
      const lines = fs.readFileSync(table, "utf8").split(/\r?\n/).slice(1);
      for (const line of lines) {
        const columns = line.trim().split(/\s+/);
        const localAddress = columns[1] || "";
        const separator = localAddress.lastIndexOf(":");
        if (separator < 0) {
          continue;
        }
        const port = Number.parseInt(localAddress.slice(separator + 1), 16);
        if (Number.isInteger(port) && port > 0) {
          ports.add(port);
        }
      }
    } catch (_error) {
      // Non-Linux development environments do not expose procfs.
    }
  }
  return ports;
}

function allocatePort() {
  const used = new Set(Array.from(rooms.values()).map((room) => room.port));
  const occupied = boundUdpPorts();
  for (let port = ROOM_PORT_START; port <= ROOM_PORT_END; port += 1) {
    if (!used.has(port) && !occupied.has(port)) {
      return port;
    }
  }
  return 0;
}

function createCode() {
  return crypto.randomBytes(3).toString("hex").toUpperCase();
}

function roomIsReady(room) {
  if (!room || room.stopping || !rooms.has(room.code)) {
    return false;
  }
  room.ready = room.ready || boundUdpPorts().has(room.port);
  return room.ready;
}

function waitForRoomReady(room, timeoutMs = ROOM_READY_TIMEOUT_MS) {
  const startedAt = Date.now();
  return new Promise((resolve, reject) => {
    const check = () => {
      if (!rooms.has(room.code) || room.stopping || room.child.exitCode !== null) {
        reject(new Error(`room ${room.code} exited before opening UDP port ${room.port}`));
        return;
      }
      if (roomIsReady(room)) {
        resolve(room);
        return;
      }
      if (Date.now() - startedAt >= timeoutMs) {
        stopRoom(room.code, "startup timeout");
        reject(new Error(`room ${room.code} did not open UDP port ${room.port} in time`));
        return;
      }
      setTimeout(check, 100);
    };
    check();
  });
}

function spawnRoomProcess(args) {
  if (/\.js$/i.test(GODOT_BIN)) {
    return spawn(process.execPath, [GODOT_BIN, ...args], {
      cwd: PROJECT_PATH,
      stdio: ["ignore", "pipe", "pipe"]
    });
  }
  return spawn(GODOT_BIN, args, {
    cwd: PROJECT_PATH,
    stdio: ["ignore", "pipe", "pipe"]
  });
}

function logRoomEvent(room, kind, detail = {}) {
  if (!room) {
    return;
  }
  const event = {
    at: Date.now(),
    kind,
    ...detail
  };
  if (!Array.isArray(room.events)) {
    room.events = [];
  }
  room.events.push(event);
  while (room.events.length > ROOM_EVENT_LIMIT) {
    room.events.shift();
  }
  const detailText = Object.entries(detail)
    .map(([key, value]) => `${key}=${value}`)
    .join(" ");
  console.log(`room_event code=${room.code} kind=${kind}${detailText ? " " + detailText : ""}`);
}

function touchRoom(room, reason, detail = {}) {
  if (!room || room.stopping || !rooms.has(room.code)) {
    return;
  }
  room.lastSeen = Date.now();
  scheduleRoomStop(room);
  logRoomEvent(room, reason, {
    players: room.players,
    expiresInMs: roomPublic(room).expiresInMs,
    ...detail
  });
}

function createStreamId() {
  return `rtm_${crypto.randomBytes(6).toString("hex")}`;
}

function streamPublic(stream) {
  refreshStreamFps(stream);
  const path = stream.path;
  const isNative = stream.protocol === "rtmp-hls";
  const rtmpPath = `${STREAM_RTMP_APP}/${path}`;
  const rtmpUrl = `rtmp://${STREAM_PUBLIC_HOST}:${STREAM_RTMP_PORT}/${rtmpPath}`;
  const hlsUrl = `${STREAM_PUBLIC_SCHEME}://${STREAM_PUBLIC_HOST}:${STREAM_HLS_PORT}/${rtmpPath}/`;
  const hlsPlaylistUrl = `${STREAM_PUBLIC_SCHEME}://${STREAM_PUBLIC_HOST}:${STREAM_HLS_PORT}/${rtmpPath}/index.m3u8`;
  const webrtcUrl = `${STREAM_PUBLIC_SCHEME}://${STREAM_PUBLIC_HOST}:${STREAM_WEBRTC_PORT}/${rtmpPath}/`;
  const mjpegUrl = `${STREAM_MANAGER_PUBLIC_BASE_URL}/streams/${stream.id}/mjpeg`;
  const frameUrl = `${STREAM_MANAGER_PUBLIC_BASE_URL}/streams/${stream.id}/frame`;
  const mjpegPublishUrl = `${STREAM_MANAGER_PUBLIC_BASE_URL}/streams/${stream.id}/mjpeg-publish`;
  return {
    id: stream.id,
    path,
    rtmpPath,
    room: stream.room,
    player: stream.player,
    protocol: stream.protocol,
    publishUrl: isNative ? rtmpUrl : frameUrl,
    watchUrl: isNative ? hlsUrl : mjpegUrl,
    rtmpPublishUrl: rtmpUrl,
    hlsUrl,
    hlsPlaylistUrl,
    webrtcUrl,
    frameUrl,
    mjpegPublishUrl,
    mjpegUrl,
    viewerUrl: `${STREAM_MANAGER_PUBLIC_BASE_URL}/streams/${stream.id}`,
    createdAt: stream.createdAt,
    expiresAt: stream.expiresAt,
    lastFrameAt: stream.lastFrameAt,
    frameCount: stream.frameCount,
    framesPerSecond: stream.framesPerSecond,
    bytesReceived: stream.bytesReceived,
    streamWidth: stream.streamWidth,
    streamHeight: stream.streamHeight,
    streamFps: stream.streamFps,
    streamQuality: stream.streamQuality,
    streamBitrate: stream.streamBitrate,
    bufferMs: stream.bufferMs
  };
}

function createStream(payload = {}) {
  const id = createStreamId();
  const now = Date.now();
  const stream = {
    id,
    path: id,
    room: String(payload.room || ""),
    player: String(payload.player || "QA"),
    version: String(payload.version || ""),
    protocol: payload.protocol === "rtmp-hls" ? "rtmp-hls" : "frame-mjpeg",
    streamWidth: clampNumber(payload.streamWidth, 640, 320, 1280),
    streamHeight: clampNumber(payload.streamHeight, 360, 180, 720),
    streamFps: clampNumber(payload.streamFps, 24, 8, 60),
    streamQuality: clampNumber(payload.streamQuality, 0.64, 0.42, 0.78),
    streamBitrate: clampNumber(payload.streamBitrate, 1_600_000, 250_000, 10_000_000),
    bufferMs: clampNumber(payload.bufferMs, STREAM_FRAME_BUFFER_MS, 50, 220),
    createdAt: now,
    expiresAt: now + STREAM_TTL_MS,
    lastFrame: null,
    lastFrameType: "image/jpeg",
    lastFrameAt: 0,
    lastFrameSeq: 0,
    frameCount: 0,
    framesThisSecond: 0,
    framesPerSecond: 0,
    fpsWindowStartedAt: now,
    bytesReceived: 0,
    frameBuffer: [],
    mjpegPublishBuffer: Buffer.alloc(0),
    subscribers: new Set(),
    idleTimer: null
  };
  streams.set(id, stream);
  stream.idleTimer = setTimeout(() => streams.delete(id), STREAM_TTL_MS);
  stream.idleTimer.unref();
  console.log(`stream ${id} opened for ${stream.player || "QA"}${stream.room ? ` room=${stream.room}` : ""}`);
  return stream;
}

function closeStream(id) {
  const stream = streams.get(String(id || ""));
  if (!stream) {
    return false;
  }
  clearTimeout(stream.idleTimer);
  for (const res of stream.subscribers) {
    try {
      res.end();
    } catch (_error) {
      // ignore closed sockets
    }
  }
  stream.subscribers.clear();
  streams.delete(stream.id);
  console.log(`stream ${stream.id} closed`);
  return true;
}

function refreshStreamTtl(stream) {
  clearTimeout(stream.idleTimer);
  stream.expiresAt = Date.now() + STREAM_TTL_MS;
  stream.idleTimer = setTimeout(() => closeStream(stream.id), STREAM_TTL_MS);
  stream.idleTimer.unref();
}

function contentTypeForFrame(req) {
  const requested = String(req.headers["content-type"] || "").split(";")[0].trim().toLowerCase();
  if (requested === "image/png" || requested === "image/webp" || requested === "image/jpeg") {
    return requested;
  }
  return "image/jpeg";
}

function pushFrameToSubscriber(res, frame, contentType, seq, createdAt) {
  if (res.rupturaBlocked) {
    return;
  }
  res.write(`--ruptura-frame\r\nContent-Type: ${contentType}\r\nContent-Length: ${frame.length}\r\nX-Frame-Seq: ${seq}\r\nX-Frame-At: ${createdAt}\r\n\r\n`);
  res.write(frame);
  const ok = res.write("\r\n");
  if (!ok) {
    res.rupturaBlocked = true;
    res.once("drain", () => {
      res.rupturaBlocked = false;
      if (res.rupturaLatest && !res.destroyed) {
        const latest = res.rupturaLatest;
        res.rupturaLatest = null;
        pushFrameToSubscriber(res, latest.frame, latest.contentType, latest.seq, latest.createdAt);
      }
    });
  }
}

function refreshStreamFps(stream, now = Date.now()) {
  if (!stream.fpsWindowStartedAt) {
    stream.fpsWindowStartedAt = now;
  }
  if (now - stream.fpsWindowStartedAt >= 1000) {
    stream.framesPerSecond = stream.framesThisSecond;
    stream.framesThisSecond = 0;
    stream.fpsWindowStartedAt = now;
  }
}

function publishFrame(stream, frame, contentType, seq = 0) {
  const now = Date.now();
  const frameSeq = seq || stream.lastFrameSeq + 1;
  stream.lastFrame = frame;
  stream.lastFrameType = contentType;
  stream.lastFrameAt = now;
  stream.lastFrameSeq = Math.max(stream.lastFrameSeq, frameSeq);
  stream.frameCount += 1;
  refreshStreamFps(stream, now);
  stream.framesThisSecond += 1;
  stream.bytesReceived += frame.length;
  stream.frameBuffer.push({ frame, contentType, seq: frameSeq, createdAt: now });
  const keepAfter = now - Math.max(stream.bufferMs, STREAM_FRAME_BUFFER_MS);
  stream.frameBuffer = stream.frameBuffer
    .filter((entry) => entry.createdAt >= keepAfter)
    .slice(-STREAM_FRAME_BUFFER_MAX);
  refreshStreamTtl(stream);
  for (const res of Array.from(stream.subscribers)) {
    try {
      if (res.rupturaBlocked) {
        res.rupturaLatest = { frame, contentType, seq: frameSeq, createdAt: now };
        continue;
      }
      pushFrameToSubscriber(res, frame, contentType, frameSeq, now);
    } catch (_error) {
      stream.subscribers.delete(res);
    }
  }
  return true;
}

function publishMjpegChunk(stream, chunk) {
  if (!Buffer.isBuffer(chunk) || chunk.length === 0) {
    return 0;
  }
  stream.mjpegPublishBuffer = Buffer.concat([stream.mjpegPublishBuffer || Buffer.alloc(0), chunk]);
  if (stream.mjpegPublishBuffer.length > STREAM_FRAME_MAX_BYTES * 3) {
    const start = stream.mjpegPublishBuffer.indexOf(Buffer.from([0xff, 0xd8]), Math.max(0, stream.mjpegPublishBuffer.length - STREAM_FRAME_MAX_BYTES * 2));
    stream.mjpegPublishBuffer = start >= 0 ? stream.mjpegPublishBuffer.slice(start) : Buffer.alloc(0);
  }
  let published = 0;
  while (stream.mjpegPublishBuffer.length > 4) {
    const start = stream.mjpegPublishBuffer.indexOf(Buffer.from([0xff, 0xd8]));
    if (start < 0) {
      stream.mjpegPublishBuffer = stream.mjpegPublishBuffer.slice(-2);
      break;
    }
    const end = stream.mjpegPublishBuffer.indexOf(Buffer.from([0xff, 0xd9]), start + 2);
    if (end < 0) {
      if (start > 0) stream.mjpegPublishBuffer = stream.mjpegPublishBuffer.slice(start);
      break;
    }
    const frame = stream.mjpegPublishBuffer.slice(start, end + 2);
    stream.mjpegPublishBuffer = stream.mjpegPublishBuffer.slice(end + 2);
    if (frame.length <= STREAM_FRAME_MAX_BYTES) {
      publishFrame(stream, frame, "image/jpeg");
      published += 1;
    }
  }
  return published;
}

function sendLatestFrame(res, stream) {
  if (!stream.lastFrame) {
    sendJson(res, 404, { error: "frame not ready" });
    return;
  }
  res.writeHead(200, {
    "Access-Control-Allow-Origin": "*",
    "Cache-Control": "no-store, no-cache, must-revalidate",
    "Pragma": "no-cache",
    "X-Accel-Buffering": "no",
    "Content-Type": stream.lastFrameType,
    "Content-Length": stream.lastFrame.length,
    "X-Frame-Seq": String(stream.lastFrameSeq),
    "X-Frame-At": String(stream.lastFrameAt)
  });
  res.end(stream.lastFrame);
}

function sendMjpegStream(req, res, stream) {
  res.writeHead(200, {
    "Access-Control-Allow-Origin": "*",
    "Cache-Control": "no-store, no-cache, must-revalidate",
    "Pragma": "no-cache",
    "Connection": "keep-alive",
    "X-Accel-Buffering": "no",
    "Content-Type": "multipart/x-mixed-replace; boundary=ruptura-frame"
  });
  stream.subscribers.add(res);
  req.on("close", () => stream.subscribers.delete(res));
  res.write("\r\n");
  const now = Date.now();
  const buffered = stream.frameBuffer.filter((entry) => entry.createdAt >= now - Math.max(stream.bufferMs, STREAM_FRAME_BUFFER_MS));
  if (buffered.length > 0) {
    for (const entry of buffered) {
      pushFrameToSubscriber(res, entry.frame, entry.contentType, entry.seq, entry.createdAt);
    }
  } else if (stream.lastFrame) {
    pushFrameToSubscriber(res, stream.lastFrame, stream.lastFrameType, stream.lastFrameSeq, stream.lastFrameAt);
  }
}

function sendHtml(res, status, html) {
  res.writeHead(status, {
    "Access-Control-Allow-Origin": "*",
    "Content-Type": "text/html; charset=utf-8",
    "Content-Length": Buffer.byteLength(html)
  });
  res.end(html);
}

function streamViewerHtml(stream) {
  const data = streamPublic(stream);
  const title = `Ruptura QA Stream ${data.id}`;
  const mjpegUrl = data.mjpegUrl;
  const frameUrl = data.frameUrl;
  const hlsUrl = data.hlsUrl;
  const hlsPlaylistUrl = data.hlsPlaylistUrl || data.hlsUrl;
  const webrtcUrl = data.webrtcUrl;
  const webrtcEmbedUrl = `${webrtcUrl}?controls=false&muted=true&autoplay=true&playsInline=true&disablepictureinpicture=true`;
  const statusUrl = `${data.viewerUrl}?format=json`;
  const aspectRatio = `${Math.max(1, data.streamWidth)} / ${Math.max(1, data.streamHeight)}`;
  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <style>
    :root{color-scheme:dark}
    *{box-sizing:border-box}
    html,body{margin:0;min-height:100%;background:#050608;color:#e9ffff;font-family:Arial,sans-serif}
    body{display:flex;flex-direction:column}
    header{min-height:48px;display:flex;align-items:center;gap:16px;flex-wrap:wrap;padding:9px 16px;background:#0b1220;border-bottom:1px solid #1f3b48;font-size:13px}
    strong{color:#00ffd5}
    #stage{min-height:calc(100vh - 48px);display:grid;place-items:center;padding:26px;background:radial-gradient(circle at 50% 30%,#16202b 0,#090b0e 62%,#030405 100%)}
    #shell{position:relative;width:min(1180px,94vw,calc((100vh - 124px) * (${aspectRatio})));aspect-ratio:${aspectRatio};display:grid;place-items:center;padding:12px;border:1px solid rgba(0,255,213,.55);border-radius:14px;background:linear-gradient(145deg,rgba(0,255,213,.10),rgba(255,255,255,.025));box-shadow:0 0 0 1px rgba(255,255,255,.06) inset,0 22px 65px rgba(0,0,0,.58),0 0 45px rgba(0,255,213,.10)}
    #screen{position:relative;width:100%;height:100%;overflow:hidden;border-radius:8px;background:#000;box-shadow:0 0 0 1px rgba(255,255,255,.10) inset}
    img,video,iframe{display:block;width:100%;height:100%;border:0;object-fit:contain;background:#000}
    #empty{position:absolute;inset:0;display:grid;place-items:center;color:#fff;text-shadow:0 2px 2px #000;font-weight:700;z-index:2}
    .muted{color:#9fb3c8}
    @media (max-width:700px){header{gap:10px;font-size:12px}#stage{padding:12px}#shell{width:min(98vw,calc((100vh - 76px) * (${aspectRatio})));padding:7px;border-radius:10px}}
  </style>
</head>
<body>
  <header><strong>Ruptura Temporal QA</strong><span>${data.player}</span><span>${data.room || "solo"}</span><span>${data.id}</span><span>${data.streamWidth}x${data.streamHeight} ${data.streamFps}fps</span><span id="status" class="muted">aguardando frame</span></header>
  <main id="stage"><section id="shell"><div id="screen"><div id="empty">Aguardando imagem real do jogo...</div><iframe id="webrtc" title="Ruptura WebRTC Stream" allow="autoplay; fullscreen" src="about:blank"></iframe><video id="video" autoplay muted playsinline controls></video><img id="player" alt="Ruptura QA Stream" src="${mjpegUrl}"></div></section></main>
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1"></script>
  <script>
    const protocol = "${data.protocol}";
    const hlsUrl = "${hlsUrl}";
    const hlsPlaylistUrl = "${hlsPlaylistUrl}";
    const webrtcUrl = "${webrtcEmbedUrl}";
    const statusEl = document.getElementById("status");
    const emptyEl = document.getElementById("empty");
    const img = document.getElementById("player");
    const video = document.getElementById("video");
    const webrtc = document.getElementById("webrtc");
    let lastCount = 0;
    let fallbackTimer = null;
    let usingWebRtc = false;
    function showFallbackHls(message) {
      usingWebRtc = false;
      video.style.display = "none";
      webrtc.style.display = "block";
      webrtc.src = hlsUrl;
      if (message) emptyEl.textContent = message;
    }
    if (protocol === "rtmp-hls") {
      img.style.display = "none";
      video.style.display = "none";
      usingWebRtc = true;
      // MediaMTX exposes the same RTMP path through WebRTC. This is the
      // preferred QA view because HLS buffering is what adds multi-second delay.
      webrtc.src = webrtcUrl;
      const fallbackToHls = setTimeout(() => {
        if (usingWebRtc) showFallbackHls("WebRTC demorou; usando HLS de reserva...");
        startHls();
      }, 4500);
      webrtc.onload = () => {
        clearTimeout(fallbackToHls);
        emptyEl.style.display = "none";
        statusEl.textContent = "${data.streamWidth}x${data.streamHeight} ${data.streamFps}fps alvo | WebRTC baixa latencia";
      };
      function startHls() {
      if (video.canPlayType("application/vnd.apple.mpegurl")) {
        video.src = hlsPlaylistUrl;
      } else if (window.Hls && Hls.isSupported()) {
        const hls = new Hls({
          lowLatencyMode: true,
          liveSyncDuration: 0.55,
          liveMaxLatencyDuration: 1.2,
          maxLiveSyncPlaybackRate: 1.35,
          maxBufferLength: 1.2,
          backBufferLength: 0,
          enableWorker: true
        });
        hls.loadSource(hlsPlaylistUrl);
        hls.attachMedia(video);
      } else {
        emptyEl.textContent = "Navegador sem HLS. Abra no Chrome/Edge atualizado.";
      }
      }
      video.onplaying = () => { emptyEl.style.display = "none"; };
      video.onerror = () => { emptyEl.textContent = "Aguardando publicacao HLS do celular..."; };
    } else {
      webrtc.style.display = "none";
      video.style.display = "none";
    }
    img.onload = () => { emptyEl.style.display = "none"; };
    img.onerror = () => {
      if (fallbackTimer) return;
      fallbackTimer = setInterval(() => {
        img.src = "${frameUrl}?t=" + Date.now();
      }, 350);
    };
    async function tick() {
      try {
        const res = await fetch("${statusUrl}", { cache: "no-store" });
        const data = await res.json();
        const age = data.lastFrameAt ? Math.max(0, ((Date.now() - data.lastFrameAt) / 1000)).toFixed(1) : "-";
        if (data.protocol === "rtmp-hls") {
          if (!usingWebRtc) statusEl.textContent = data.streamWidth + "x" + data.streamHeight + " " + data.streamFps + "fps alvo | HLS reserva";
        } else {
          statusEl.textContent = data.frameCount ? ("envio " + (data.framesPerSecond || 0) + " fps | ultimo " + age + "s | buffer " + (data.bufferMs || 0) + "ms") : "aguardando frame";
        }
        if (data.frameCount && data.frameCount !== lastCount) {
          lastCount = data.frameCount;
          emptyEl.style.display = "none";
        }
      } catch (_error) {
        statusEl.textContent = "reconectando";
      }
    }
    setInterval(tick, 1000);
    tick();
  </script>
</body>
</html>`;
}

function startRoom(ownerName, options = {}) {
  const standby = Boolean(options.standby);
  const port = allocatePort();
  if (!port) {
    throw new Error("no room ports available");
  }

  let code = createCode();
  while (rooms.has(code)) {
    code = createCode();
  }

  const args = [
    "--headless",
    "--path",
    PROJECT_PATH,
    "--",
    "--dedicated-server",
    `--room-code=${code}`,
    `--port=${port}`
  ];
  if (standby) {
    args.push("--warm-standby");
  }
  const child = spawnRoomProcess(args);

  const room = {
    code,
    port,
    ownerName: standby ? "" : (ownerName || "host"),
    players: standby ? 0 : 1,
    standby,
    createdAt: Date.now(),
    lastSeen: Date.now(),
    child,
    idleTimer: null,
    stopping: false,
    ready: false,
    heartbeatCount: 0,
    lastHeartbeatAt: 0,
    events: []
  };
  rooms.set(code, room);
  logRoomEvent(room, standby ? "standby_started" : "room_started", { owner: room.ownerName, port });

  child.stdout.on("data", (chunk) => {
    const text = chunk.toString("utf8");
    if (/ONLINE ROOM|ROOM .*READY|DEDICATED.*READY/i.test(text)) {
      room.ready = true;
    }
    process.stdout.write(`[${code}] ${chunk}`);
  });
  child.stderr.on("data", (chunk) => process.stderr.write(`[${code}] ${chunk}`));
  child.on("error", (error) => {
    clearTimeout(room.idleTimer);
    rooms.delete(code);
    console.error(`room ${code}${room.standby ? " standby" : ""} failed to start: ${error.message}`);
    if (room.standby && !room.stopping) {
      scheduleWarmStandbyRefill();
    }
  });
  child.on("exit", (status, signal) => {
    clearTimeout(room.idleTimer);
    rooms.delete(code);
    const uptimeMs = Date.now() - room.createdAt;
    const idleForMs = Date.now() - room.lastSeen;
    console.log(`room ${code}${room.standby ? " standby" : ""} exited status=${status} signal=${signal} uptimeMs=${uptimeMs} idleForMs=${idleForMs} stopping=${room.stopping}`);
    if (room.standby && !room.stopping) {
      scheduleWarmStandbyRefill();
    }
  });

  if (!standby) {
    scheduleRoomStop(room);
  }
  console.log(`room ${code}${standby ? " warmed" : " started"} on ${ROOM_HOST}:${port}`);
  return room;
}

function scheduleRoomStop(room) {
  clearTimeout(room.idleTimer);
  const delayMs = Math.max(5000, room.lastSeen + ROOM_IDLE_MS - Date.now());
  room.idleTimer = setTimeout(() => {
    stopRoom(room.code, "idle timeout");
  }, delayMs);
}

function stopRoom(code, reason) {
  const room = rooms.get(code);
  if (!room) {
    return false;
  }
  const uptimeMs = Date.now() - room.createdAt;
  const idleForMs = Date.now() - room.lastSeen;
  logRoomEvent(room, "stopping", { reason, uptimeMs, idleForMs, players: room.players });
  console.log(`stopping room ${code}: ${reason} players=${room.players} uptimeMs=${uptimeMs} idleForMs=${idleForMs}`);
  room.stopping = true;
  clearTimeout(room.idleTimer);
  rooms.delete(code);
  let exited = false;
  room.child.once("exit", () => {
    exited = true;
  });
  room.child.kill("SIGTERM");
  setTimeout(() => {
    if (!exited) {
      room.child.kill("SIGKILL");
    }
  }, 5000).unref();
  return true;
}

function warmStandbyRooms() {
  return Array.from(rooms.values()).filter((room) => room.standby && room.players === 0 && roomIsReady(room));
}

function standbyRooms() {
  return Array.from(rooms.values()).filter((room) => room.standby && room.players === 0);
}

function activeRooms() {
  return Array.from(rooms.values()).filter((room) => !room.standby);
}

function scheduleWarmStandbyRefill() {
  if (WARM_STANDBY_ROOMS <= 0 || warmRefillTimer) {
    return;
  }
  warmRefillTimer = setTimeout(() => {
    warmRefillTimer = null;
    ensureWarmStandby();
  }, WARM_STANDBY_REFILL_MS);
  warmRefillTimer.unref();
}

function ensureWarmStandby() {
  if (WARM_STANDBY_ROOMS <= 0) {
    return;
  }
  let missing = WARM_STANDBY_ROOMS - standbyRooms().length;
  while (missing > 0) {
    try {
      startRoom("", { standby: true });
    } catch (error) {
      console.error(`failed to warm standby room: ${error.message}`);
      break;
    }
    missing -= 1;
  }
}

function claimWarmStandby(ownerName) {
  const room = warmStandbyRooms().sort((left, right) => left.createdAt - right.createdAt)[0];
  if (!room) {
    return null;
  }
  room.standby = false;
  room.ownerName = ownerName || "host";
  room.players = 1;
  room.createdAt = Date.now();
  room.lastSeen = Date.now();
  room.heartbeatCount = 0;
  room.lastHeartbeatAt = 0;
  scheduleRoomStop(room);
  logRoomEvent(room, "standby_claimed", { owner: room.ownerName, port: room.port });
  console.log(`room ${room.code} claimed from warm standby by ${room.ownerName}`);
  scheduleWarmStandbyRefill();
  return room;
}

function availableRoom() {
  const candidates = activeRooms()
    .filter((room) => room.players < MAX_PLAYERS)
    .sort((left, right) => right.createdAt - left.createdAt);
  if (candidates.length === 0) {
    return null;
  }
  return reserveRoom(candidates[0]);
}

function listAvailableRooms() {
  return activeRooms()
    .filter((room) => room.players < MAX_PLAYERS)
    .sort((left, right) => right.createdAt - left.createdAt)
    .map(roomPublic);
}

function reserveRoom(room) {
  if (!room || room.players >= MAX_PLAYERS) {
    return null;
  }
  room.players += 1;
  touchRoom(room, "player_joined", { players: room.players });
  return room;
}

function roomByCode(code) {
  return rooms.get(String(code || "").toUpperCase()) || null;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function safeNumber(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function loadLeaderboardStore() {
  try {
    if (!fs.existsSync(LEADERBOARD_PATH)) {
      return { runs: [], profiles: {} };
    }
    const parsed = JSON.parse(fs.readFileSync(LEADERBOARD_PATH, "utf8"));
    return {
      runs: Array.isArray(parsed.runs) ? parsed.runs : [],
      profiles: parsed.profiles && typeof parsed.profiles === "object" ? parsed.profiles : {}
    };
  } catch (error) {
    console.error(`failed to read leaderboard: ${error.message}`);
    return { runs: [], profiles: {} };
  }
}

function saveLeaderboardStore(store) {
  fs.mkdirSync(path.dirname(LEADERBOARD_PATH), { recursive: true });
  fs.writeFileSync(LEADERBOARD_PATH, JSON.stringify(store, null, 2));
}

function defaultSecurityStore() {
  return { ips: {}, sessions: {}, audit: [] };
}

function loadSecurityStore() {
  try {
    if (!fs.existsSync(RUN_SECURITY_PATH)) {
      return defaultSecurityStore();
    }
    const parsed = JSON.parse(fs.readFileSync(RUN_SECURITY_PATH, "utf8"));
    return {
      ips: parsed.ips && typeof parsed.ips === "object" ? parsed.ips : {},
      sessions: parsed.sessions && typeof parsed.sessions === "object" ? parsed.sessions : {},
      audit: Array.isArray(parsed.audit) ? parsed.audit : []
    };
  } catch (error) {
    console.error(`failed to read ranking security store: ${error.message}`);
    return defaultSecurityStore();
  }
}

function cleanupSecurityStore(store, now = Date.now()) {
  store.sessions = store.sessions && typeof store.sessions === "object" ? store.sessions : {};
  for (const [id, session] of Object.entries(store.sessions)) {
    const createdAt = Number(session && session.createdAt) || 0;
    const endedAt = Number(session && session.endedAt) || 0;
    if (!createdAt || now - createdAt > RUN_SESSION_TTL_MS || (endedAt && now - endedAt > RUN_SECURITY_WINDOW_MS)) {
      delete store.sessions[id];
    }
  }
}

function saveSecurityStore(store) {
  fs.mkdirSync(path.dirname(RUN_SECURITY_PATH), { recursive: true });
  fs.writeFileSync(RUN_SECURITY_PATH, JSON.stringify(store, null, 2));
}

function clientIp(req) {
  const forwarded = String(req.headers["x-forwarded-for"] || "").split(",")[0].trim();
  const raw = forwarded || req.socket && req.socket.remoteAddress || "unknown";
  return raw.replace(/^::ffff:/, "").slice(0, 64);
}

function securityIpState(store, ip) {
  const key = String(ip || "unknown").slice(0, 64);
  if (!store.ips[key] || typeof store.ips[key] !== "object") {
    store.ips[key] = {
      strikes: 0,
      reports: [],
      blockedUntil: 0,
      lastReason: "",
      lastSeen: 0
    };
  }
  return store.ips[key];
}

function cleanSecurityWindow(state, now = Date.now()) {
  state.reports = Array.isArray(state.reports) ? state.reports.filter((stamp) => now - Number(stamp) <= RUN_SECURITY_WINDOW_MS) : [];
}

function isSecurityBlocked(ip) {
  const store = loadSecurityStore();
  const state = securityIpState(store, ip);
  const now = Date.now();
  if (Number(state.blockedUntil) > now) {
    return { blocked: true, retryAfterSeconds: Math.ceil((Number(state.blockedUntil) - now) / 1000) };
  }
  if (Number(state.blockedUntil) > 0) {
    state.blockedUntil = 0;
    saveSecurityStore(store);
  }
  return { blocked: false, retryAfterSeconds: 0 };
}

function registerRunReportAttempt(ip) {
  const store = loadSecurityStore();
  const state = securityIpState(store, ip);
  const now = Date.now();
  cleanSecurityWindow(state, now);
  state.reports.push(now);
  state.lastSeen = now;
  let limited = false;
  if (state.reports.length > RUN_SECURITY_MAX_REPORTS_PER_WINDOW) {
    limited = true;
    state.strikes = Math.max(Number(state.strikes) || 0, RUN_SECURITY_BLOCK_THRESHOLD);
    state.lastReason = "run_report_rate_limit";
    state.blockedUntil = Math.max(Number(state.blockedUntil) || 0, now + RUN_SECURITY_BLOCK_MS);
  }
  saveSecurityStore(store);
  return { limited, retryAfterSeconds: limited ? Math.ceil((Number(state.blockedUntil) - now) / 1000) : 0 };
}

function recordSecurityStrike(ip, reasons, context = {}) {
  const store = loadSecurityStore();
  cleanupSecurityStore(store);
  const state = securityIpState(store, ip);
  const now = Date.now();
  cleanSecurityWindow(state, now);
  const reasonList = Array.isArray(reasons) && reasons.length ? reasons.map(String).slice(0, 16) : ["suspicious_run_report"];
  const severity = reasonList.some((reason) => (
    reason.includes("signature")
    || reason.includes("protocol")
    || reason.includes("clock")
    || reason.includes("payload")
    || reason.includes("rate")
  )) ? 2 : 1;
  state.strikes = Math.max(0, Math.floor(Number(state.strikes) || 0)) + severity;
  state.lastSeen = now;
  state.lastReason = reasonList.join(",");
  if (state.strikes >= RUN_SECURITY_BLOCK_THRESHOLD) {
    const multiplier = Math.min(6, Math.max(1, state.strikes - RUN_SECURITY_BLOCK_THRESHOLD + 1));
    state.blockedUntil = Math.max(Number(state.blockedUntil) || 0, now + RUN_SECURITY_BLOCK_MS * multiplier);
  }
  store.audit.unshift({
    at: new Date(now).toISOString(),
    ip: String(ip || "unknown").slice(0, 64),
    reasons: reasonList,
    severity,
    strikes: state.strikes,
    blockedUntil: state.blockedUntil || 0,
    player: String(context.player || "").slice(0, 32),
    profileId: String(context.profileId || context.profile_id || "").slice(0, 64),
    version: String(context.version || "").slice(0, 24),
    versionCode: Math.max(0, Math.floor(safeNumber(context.versionCode || context.version_code))),
    score: Math.max(0, Math.floor(safeNumber(context.score || context.leaderboard_score)))
  });
  store.audit = store.audit.slice(0, RUN_SECURITY_AUDIT_LIMIT);
  saveSecurityStore(store);
  console.warn(`ranking security strike ip=${ip} reasons=${reasonList.join(",")} strikes=${state.strikes}`);
  return state;
}

function sessionTokenHash(token) {
  return crypto.createHash("sha256").update(String(token || "")).digest("hex");
}

function normalizeSessionMetrics(payload) {
  const stats = payload && payload.player_stats && typeof payload.player_stats === "object" ? payload.player_stats : {};
  const scaling = payload && payload.enemy_scaling && typeof payload.enemy_scaling === "object" ? payload.enemy_scaling : {};
  return {
    duration: Math.max(0, Math.floor(safeNumber(payload && payload.duration_seconds))),
    phase: Math.max(0, Math.floor(safeNumber(payload && payload.phase))),
    kills: Math.max(0, Math.floor(safeNumber(payload && payload.kills))),
    pointsEarned: Math.max(0, Math.floor(safeNumber(payload && payload.points_earned))),
    pointsSpent: Math.max(0, Math.floor(safeNumber(payload && payload.points_spent))),
    cardsTotal: Math.max(0, Math.floor(safeNumber(payload && payload.cards_total))),
    bossDamage: Math.max(0, Math.floor(safeNumber(payload && payload.boss_damage_total))),
    enemyDamage: Math.max(0, Math.floor(safeNumber(payload && payload.enemy_damage_total))),
    damageTaken: Math.max(0, Math.floor(safeNumber(payload && payload.damage_taken_total))),
    scoreCurrent: Math.max(0, Math.floor(safeNumber(payload && payload.score_current))),
    scoreTotal: Math.max(0, Math.floor(safeNumber(payload && payload.score_total))),
    hp: Math.max(0, safeNumber(stats.hp)),
    hpMax: Math.max(0, safeNumber(stats.hp_max)),
    damage: Math.max(0, safeNumber(payload && payload.base_damage_end)),
    defense: Math.max(0, safeNumber(stats.defense)),
    critChance: Math.max(0, safeNumber(stats.crit_chance)),
    attackInterval: Math.max(0, safeNumber(stats.attack_interval)),
    speed: Math.max(0, safeNumber(stats.speed)),
    enemyBaseHp: Math.max(0, safeNumber(scaling.base_hp)),
    enemyLimit: Math.max(0, Math.floor(safeNumber(scaling.limit))),
    enemySpeed: Math.max(0, safeNumber(scaling.base_speed)),
    enemyCloseDamage: Math.max(0, safeNumber(scaling.close_damage)),
    enemyFarDamage: Math.max(0, safeNumber(scaling.far_damage))
  };
}

function timelinePointFromMetrics(metrics, source = "checkpoint") {
  return {
    source,
    duration: Math.max(0, Math.floor(safeNumber(metrics && metrics.duration))),
    phase: Math.max(0, Math.floor(safeNumber(metrics && metrics.phase))),
    kills: Math.max(0, Math.floor(safeNumber(metrics && metrics.kills))),
    pointsEarned: Math.max(0, Math.floor(safeNumber(metrics && metrics.pointsEarned))),
    pointsSpent: Math.max(0, Math.floor(safeNumber(metrics && metrics.pointsSpent))),
    scoreCurrent: Math.max(0, Math.floor(safeNumber(metrics && metrics.scoreCurrent))),
    scoreTotal: Math.max(0, Math.floor(safeNumber(metrics && metrics.scoreTotal))),
    cardsTotal: Math.max(0, Math.floor(safeNumber(metrics && metrics.cardsTotal))),
    bossDamage: Math.max(0, Math.floor(safeNumber(metrics && metrics.bossDamage))),
    enemyDamage: Math.max(0, Math.floor(safeNumber(metrics && metrics.enemyDamage))),
    damageTaken: Math.max(0, Math.floor(safeNumber(metrics && metrics.damageTaken))),
    hp: Math.max(0, safeNumber(metrics && metrics.hp)),
    hpMax: Math.max(0, safeNumber(metrics && metrics.hpMax)),
    damage: Math.max(0, safeNumber(metrics && metrics.damage)),
    defense: Math.max(0, safeNumber(metrics && metrics.defense)),
    critChance: Math.max(0, safeNumber(metrics && metrics.critChance)),
    attackInterval: Math.max(0, safeNumber(metrics && metrics.attackInterval)),
    speed: Math.max(0, safeNumber(metrics && metrics.speed)),
    enemyBaseHp: Math.max(0, safeNumber(metrics && metrics.enemyBaseHp)),
    enemyLimit: Math.max(0, Math.floor(safeNumber(metrics && metrics.enemyLimit))),
    enemySpeed: Math.max(0, safeNumber(metrics && metrics.enemySpeed)),
    enemyCloseDamage: Math.max(0, safeNumber(metrics && metrics.enemyCloseDamage)),
    enemyFarDamage: Math.max(0, safeNumber(metrics && metrics.enemyFarDamage))
  };
}

function createRunSession(ip, payload) {
  const store = loadSecurityStore();
  const now = Date.now();
  cleanupSecurityStore(store, now);
  const versionCode = Math.max(0, Math.floor(safeNumber(payload.version_code)));
  const sessionId = crypto.randomBytes(12).toString("hex");
  const token = crypto.randomBytes(32).toString("hex");
  const metrics = normalizeSessionMetrics(payload);
  store.sessions[sessionId] = {
    id: sessionId,
    tokenHash: sessionTokenHash(token),
    ip: String(ip || "unknown").slice(0, 64),
    createdAt: now,
    lastAt: now,
    endedAt: 0,
    player: String(payload.player || "Jogador").slice(0, 32),
    profileId: String(payload.profile_id || "").slice(0, 64),
    version: String(payload.version || "").slice(0, 24),
    versionCode,
    room: String(payload.room || "solo").slice(0, 32),
    platform: String(payload.platform || "").slice(0, 32),
    checkpoints: 0,
    last: metrics,
    max: metrics,
    timeline: [timelinePointFromMetrics(metrics, "initial")],
    anomalies: []
  };
  saveSecurityStore(store);
  return { sessionId, token, checkpointIntervalSeconds: RUN_SESSION_CHECKPOINT_INTERVAL_SECONDS };
}

function validateSessionIdentity(session, ip, token, versionCode) {
  const reasons = [];
  if (!session || typeof session !== "object") {
    reasons.push("session_not_found");
    return reasons;
  }
  if (session.endedAt) reasons.push("session_already_closed");
  if (Date.now() - (Number(session.createdAt) || 0) > RUN_SESSION_TTL_MS) reasons.push("session_expired");
  if (session.ip && ip && session.ip !== ip) reasons.push("session_ip_mismatch");
  if (session.tokenHash !== sessionTokenHash(token)) reasons.push("session_token_mismatch");
  if (Math.max(0, Math.floor(safeNumber(session.versionCode))) !== Math.max(0, Math.floor(safeNumber(versionCode)))) reasons.push("session_version_mismatch");
  return reasons;
}

function mergeSessionMetrics(session, nextMetrics) {
  const previous = session.last || normalizeSessionMetrics({});
  const anomalies = [];
  const elapsed = Math.max(1, nextMetrics.duration - Math.max(0, Math.floor(safeNumber(previous.duration))));
  if (nextMetrics.duration + 30 < safeNumber(previous.duration)) anomalies.push("checkpoint_duration_regressed");
  if (nextMetrics.kills + 3 < safeNumber(previous.kills)) anomalies.push("checkpoint_kills_regressed");
  if (nextMetrics.pointsEarned + 250 < safeNumber(previous.pointsEarned)) anomalies.push("checkpoint_points_regressed");
  if (nextMetrics.cardsTotal + 1 < safeNumber(previous.cardsTotal)) anomalies.push("checkpoint_cards_regressed");
  if (nextMetrics.kills - safeNumber(previous.kills) > elapsed * 18 + 140) anomalies.push("checkpoint_kills_jump");
  if (nextMetrics.bossDamage - safeNumber(previous.bossDamage) > elapsed * 7000 + 180000) anomalies.push("checkpoint_boss_damage_jump");
  if (nextMetrics.cardsTotal - safeNumber(previous.cardsTotal) > Math.max(32, Math.floor(elapsed / 2) + 18)) anomalies.push("checkpoint_cards_jump");
  if (nextMetrics.pointsSpent > nextMetrics.pointsEarned + 2500) anomalies.push("checkpoint_points_spent_above_earned");
  session.last = nextMetrics;
  session.max = session.max || normalizeSessionMetrics({});
  for (const key of Object.keys(nextMetrics)) {
    session.max[key] = Math.max(safeNumber(session.max[key]), safeNumber(nextMetrics[key]));
  }
  if (anomalies.length) {
    session.anomalies = Array.from(new Set([...(session.anomalies || []), ...anomalies])).slice(0, 24);
  }
  return anomalies;
}

function updateRunSession(ip, payload) {
  const store = loadSecurityStore();
  const now = Date.now();
  cleanupSecurityStore(store, now);
  const sessionId = String(payload.session_id || payload.run_session_id || "").trim();
  const token = String(payload.session_token || payload.run_session_token || "").trim();
  const session = store.sessions[sessionId];
  const versionCode = Math.max(0, Math.floor(safeNumber(payload.version_code)));
  const reasons = validateSessionIdentity(session, ip, token, versionCode);
  if (reasons.length) {
    saveSecurityStore(store);
    return { ok: false, reasons, session: null };
  }
  const metrics = normalizeSessionMetrics(payload);
  const anomalies = mergeSessionMetrics(session, metrics);
  session.lastAt = now;
  session.checkpoints = Math.max(0, Math.floor(safeNumber(session.checkpoints))) + 1;
  session.timeline = Array.isArray(session.timeline) ? session.timeline : [];
  session.timeline.push(timelinePointFromMetrics(metrics, "checkpoint"));
  session.timeline = session.timeline.slice(-RUN_SESSION_TIMELINE_LIMIT);
  saveSecurityStore(store);
  return { ok: anomalies.length === 0, reasons: anomalies, session };
}

function hardRunAuditReasons(reasons) {
  return (Array.isArray(reasons) ? reasons : [])
    .map(String)
    .filter((reason) => reason && !RUN_AUDIT_BENIGN_REASONS.has(reason));
}

function evaluateRunSession(payload, ip, versionCode) {
  if (versionCode < RUN_REPORT_SESSION_MIN_VERSION_CODE) {
    return [];
  }
  const reasons = [];
  const sessionId = String(payload.run_session_id || "").trim();
  const token = String(payload.run_session_token || "").trim();
  if (!sessionId || !token) {
    return ["session_missing"];
  }
  const store = loadSecurityStore();
  const now = Date.now();
  cleanupSecurityStore(store, now);
  const session = store.sessions[sessionId];
  reasons.push(...validateSessionIdentity(session, ip, token, versionCode));
  if (reasons.length || !session) {
    saveSecurityStore(store);
    return reasons;
  }
  const finalMetrics = normalizeSessionMetrics(payload);
  const last = session.last || normalizeSessionMetrics({});
  const max = session.max || last;
  const sinceLastSeconds = Math.max(0, Math.floor((now - (Number(session.lastAt) || now)) / 1000));
  if (Math.floor(safeNumber(session.checkpoints)) < 1 && finalMetrics.duration >= RUN_SESSION_CHECKPOINT_INTERVAL_SECONDS * 2) reasons.push("session_checkpoint_missing");
  if (sinceLastSeconds > RUN_SESSION_MAX_CHECKPOINT_GAP_SECONDS * 3 && finalMetrics.duration >= RUN_SESSION_MAX_CHECKPOINT_GAP_SECONDS) reasons.push("session_checkpoint_gap");
  if (finalMetrics.duration + 10 < safeNumber(last.duration)) reasons.push("session_final_duration_regressed");
  if (finalMetrics.phase < 0 || finalMetrics.phase > 6) reasons.push("session_phase_out_of_range");
  if (finalMetrics.kills > safeNumber(max.kills) + Math.max(80, sinceLastSeconds * 18 + 20)) reasons.push("session_kills_not_observed");
  if (finalMetrics.cardsTotal > safeNumber(max.cardsTotal) + Math.max(36, Math.floor(sinceLastSeconds / 2) + 18)) reasons.push("session_cards_not_observed");
  if (finalMetrics.pointsEarned > safeNumber(max.pointsEarned) + Math.max(1800, sinceLastSeconds * 400)) reasons.push("session_points_not_observed");
  if (finalMetrics.bossDamage > safeNumber(max.bossDamage) + Math.max(140000, sinceLastSeconds * 7000)) reasons.push("session_boss_damage_not_observed");
  if (Array.isArray(session.anomalies) && session.anomalies.length) reasons.push(...hardRunAuditReasons(session.anomalies).slice(0, 8));
  session.endedAt = now;
  session.final = finalMetrics;
  saveSecurityStore(store);
  return Array.from(new Set(hardRunAuditReasons(reasons)));
}

function runTimelineFromSession(payload, ip, versionCode) {
  const sessionId = String(payload && payload.run_session_id || "").trim();
  const token = String(payload && payload.run_session_token || "").trim();
  if (!sessionId || !token || versionCode < RUN_REPORT_SESSION_MIN_VERSION_CODE) {
    return [];
  }
  const store = loadSecurityStore();
  const session = store.sessions[sessionId];
  if (!session || typeof session !== "object") {
    return [];
  }
  if (session.ip && ip && session.ip !== ip) {
    return [];
  }
  if (session.tokenHash !== sessionTokenHash(token)) {
    return [];
  }
  if (Math.max(0, Math.floor(safeNumber(session.versionCode))) !== Math.max(0, Math.floor(safeNumber(versionCode)))) {
    return [];
  }
  const timeline = (Array.isArray(session.timeline) ? session.timeline : [])
    .map((point) => timelinePointFromMetrics(point, String(point && point.source || "checkpoint")))
    .filter((point) => point.source === "initial" || point.duration > 0 || point.kills > 0 || point.pointsEarned > 0);
  const finalPoint = timelinePointFromMetrics(normalizeSessionMetrics(payload), "final");
  const lastPoint = timeline[timeline.length - 1];
  if (!lastPoint || lastPoint.duration !== finalPoint.duration || lastPoint.pointsEarned !== finalPoint.pointsEarned || lastPoint.kills !== finalPoint.kills) {
    timeline.push(finalPoint);
  } else {
    timeline[timeline.length - 1] = { ...lastPoint, ...finalPoint, source: "final" };
  }
  return timeline
    .sort((left, right) => safeNumber(left.duration) - safeNumber(right.duration))
    .slice(-RUN_SESSION_TIMELINE_LIMIT);
}

function runAnalysisCalculable(runTimeline, durationSeconds) {
  const timeline = Array.isArray(runTimeline) ? runTimeline : [];
  const hasInitial = timeline.some((point) => String(point && point.source) === "initial");
  const hasTwoMinuteEvidence = timeline.some((point) => safeNumber(point && point.duration) >= RUN_SESSION_CHECKPOINT_INTERVAL_SECONDS);
  return safeNumber(durationSeconds) >= RUN_SESSION_CHECKPOINT_INTERVAL_SECONDS && hasInitial && hasTwoMinuteEvidence;
}

function profileKeyForRun(run) {
  const profileId = String(run.profileId || "").trim();
  if (profileId) {
    return profileId;
  }
  const player = String(run.player || "Jogador").trim().toLowerCase();
  return `name-${crypto.createHash("sha1").update(player || "jogador").digest("hex").slice(0, 16)}`;
}

function runTrainingEligible(run) {
  return Boolean(run && run.umbraTrainingEligible && run.rankEligible !== false);
}

function behaviorForRun(run) {
  return normalizeBehaviorMetrics(run && (run.behaviorMetrics || run.behavior_metrics));
}

function mean(values) {
  const clean = values.map(Number).filter(Number.isFinite);
  return clean.length ? clean.reduce((sum, value) => sum + value, 0) / clean.length : 0;
}

function classifyUmbraArchetypeFromRuns(runs) {
  if (!Array.isArray(runs) || runs.length === 0) return "SOBREVIVENTE_ADAPTATIVO";
  const behaviors = runs.map(behaviorForRun);
  const edge = mean(behaviors.map((b) => b.edgeRatio));
  const corner = mean(behaviors.map((b) => b.cornerRatio));
  const dash = mean(behaviors.map((b) => b.dashPerMinute));
  const shots = mean(behaviors.map((b) => b.shotsPerMinute));
  const hitRate = mean(behaviors.map((b) => b.hitRate));
  const stationary = mean(behaviors.map((b) => b.stationaryRatio));
  const damageTakenPerMinute = mean(runs.map((run) => safeNumber(run.damageTaken) / Math.max(1, safeNumber(run.durationSeconds)) * 60));
  if (corner >= 0.12 || edge >= 0.34) return "REFUGIADO_DE_CANTO";
  if (dash >= 8) return "DEPENDENTE_DE_DASH";
  if (shots >= 48 && hitRate < 0.34) return "ATIRADOR_DISTANTE";
  if (stationary < 0.14 && edge < 0.22) return "CORREDOR_CIRCULAR";
  if (damageTakenPerMinute >= 120 && edge < 0.25) return "AGRESSOR_IMPULSIVO";
  if (hitRate >= 0.48 && damageTakenPerMinute < 80) return "SOBREVIVENTE_ADAPTATIVO";
  return "SOBREVIVENTE_ADAPTATIVO";
}

function profileForArchetype(archetype, confidence = 0.45, secondary = "INDEFINIDO") {
  return {
    arquetipo_principal: archetype,
    arquetipo_secundario: secondary,
    confianca: Math.max(0, Math.min(0.95, confidence)),
    historico_arquetipos: [archetype].filter(Boolean)
  };
}

function buildUmbraDossier(key, player, runs) {
  const eligibleRuns = runs.filter(runTrainingEligible);
  const archetype = classifyUmbraArchetypeFromRuns(eligibleRuns);
  const behaviors = eligibleRuns.map(behaviorForRun);
  const confidence = Math.min(0.92, 0.35 + eligibleRuns.length * 0.08);
  return {
    player,
    profile_key: key,
    runs: eligibleRuns.length,
    perfil_jogador: profileForArchetype(archetype, confidence),
    behavior: {
      edge_ratio: Number(mean(behaviors.map((b) => b.edgeRatio)).toFixed(4)),
      corner_ratio: Number(mean(behaviors.map((b) => b.cornerRatio)).toFixed(4)),
      center_ratio: Number(mean(behaviors.map((b) => b.centerRatio)).toFixed(4)),
      dash_per_minute: Number(mean(behaviors.map((b) => b.dashPerMinute)).toFixed(2)),
      shots_per_minute: Number(mean(behaviors.map((b) => b.shotsPerMinute)).toFixed(2)),
      hit_rate: Number(mean(behaviors.map((b) => b.hitRate)).toFixed(4)),
      stationary_ratio: Number(mean(behaviors.map((b) => b.stationaryRatio)).toFixed(4)),
      damage_taken_per_minute: Number(mean(eligibleRuns.map((run) => safeNumber(run.damageTaken) / Math.max(1, safeNumber(run.durationSeconds)) * 60)).toFixed(2))
    }
  };
}

function buildUmbraMind(snapshot, query = new URLSearchParams()) {
  const runs = Array.isArray(snapshot && snapshot.runs) ? snapshot.runs : [];
  const eligible = runs.filter(runTrainingEligible);
  const grouped = new Map();
  for (const run of eligible) {
    const key = profileKeyForRun(run);
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key).push(run);
  }
  const dossiers = {};
  for (const [key, playerRuns] of grouped.entries()) {
    dossiers[key] = buildUmbraDossier(key, String(playerRuns[0].player || "Jogador"), playerRuns);
    dossiers[String(playerRuns[0].player || "").toLowerCase()] = dossiers[key];
  }
  const globalArchetype = classifyUmbraArchetypeFromRuns(eligible);
  const versionSeed = `${Math.floor(Date.now() / (UMBRA_MIND_REFRESH_DAYS * 24 * 60 * 60 * 1000))}-${eligible.length}-${grouped.size}`;
  const mindVersion = `umbra-week-${crypto.createHash("sha1").update(versionSeed).digest("hex").slice(0, 10)}`;
  const profileId = String(query.get("profile_id") || "").trim();
  const player = String(query.get("player") || "").trim().toLowerCase();
  const current = String(query.get("current") || "").trim();
  const selected = dossiers[profileId] || dossiers[player] || null;
  const files = {
    "umbra_global_profile.json": {
      mind_version: mindVersion,
      trained_runs: eligible.length,
      trained_players: grouped.size,
      min_phase1_seconds: UMBRA_TRAINING_MIN_PHASE1_SECONDS,
      perfil_jogador: selected ? selected.perfil_jogador : profileForArchetype(globalArchetype, eligible.length ? 0.42 : 0.0)
    },
    "umbra_archetypes.json": {
      mind_version: mindVersion,
      actions: {
        REFUGIADO_DE_CANTO: ["CORTAR_BORDAS", 0.25],
        DEPENDENTE_DE_DASH: ["PUNIR_DASH_PREVISIVEL", 0.2],
        CACADOR_DE_ORBES: ["ISCA_DE_ORBE", 0.2],
        AGRESSOR_IMPULSIVO: ["CONTRA_IMPULSO", 0.2],
        ATIRADOR_DISTANTE: ["QUEBRAR_DISTANCIA", 0.25],
        CORREDOR_CIRCULAR: ["QUEBRAR_ROTACAO", 0.2],
        SOBREVIVENTE_ADAPTATIVO: ["RESPEITAR_ADAPTATIVO", 0.1]
      }
    },
    "umbra_player_dossiers.json": {
      mind_version: mindVersion,
      selected_profile: profileId || player,
      selected: selected || null,
      players: dossiers
    }
  };
  return {
    ok: true,
    mind_version: mindVersion,
    updated: current !== mindVersion,
    refresh_days: UMBRA_MIND_REFRESH_DAYS,
    trained_runs: eligible.length,
    trained_players: grouped.size,
    rejected_runs: runs.length - eligible.length,
    files
  };
}

const MANIFESTATION_UNLOCK_ALIASES = {
  eletrica: "eletrica",
  lacerante: "lacerante",
  prismatica: "prismatica",
  retornante: "retornante",
  parasitica: "parasitica",
  gravitante: "gravitante",
  ancorada: "ancorada",
  cartografica: "cartografica",
  mnesica: "mnesica",
  ressonante: "ressonante",
  contratual: "contratual",
  acorrentada: "acorrentada",
  eclipsada: "eclipsada",
  bombastica: "bombastica",
  necronada: "necronada"
};

const SPECTER_UNLOCK_ALIASES = {
  impulsiva: "impulsiva",
  racional: "racional",
  devota: "devota",
  vanguarda: "vanguarda",
  insana: "insana",
  voraz: "voraz",
  nula: "nula",
  abissal: "abissal",
  profetica: "profetica",
  sanguinaria: "sanguinaria",
  crepuscular: "crepuscular",
  peregrino: "peregrino",
  peregrina: "peregrino",
  equilibrista: "equilibrista",
  avarento: "avarento",
  avarenta: "avarento",
  oportunista: "oportunista"
};

function normalizeUnlockAlias(value) {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]/g, "");
}

function unlockKeyFromValue(value, aliases) {
  return aliases[normalizeUnlockAlias(value)] || "";
}

function veteranUnlockSnapshot(query) {
  const profileId = String(query.get("profile_id") || "").trim().slice(0, 64);
  const player = String(query.get("player") || "").trim().toLowerCase().slice(0, 32);
  const versionCode = Math.max(0, Math.floor(Number(query.get("version_code")) || 0));
  const store = loadLeaderboardStore();
  const manifestations = new Set(["eletrica"]);
  const specters = new Set(["impulsiva"]);
  let matchedRuns = 0;

  for (const run of Array.isArray(store.runs) ? store.runs : []) {
    const runProfileId = String(run.profileId || "").trim();
    const byProfile = profileId && runProfileId && runProfileId === profileId;
    const byName = !byProfile && player && String(run.player || "").trim().toLowerCase() === player && run.rankEligible !== false;
    if (!byProfile && !byName) continue;
    matchedRuns += 1;
    const manifestation = unlockKeyFromValue(run.manifestationKey || run.manifestation, MANIFESTATION_UNLOCK_ALIASES);
    const specter = unlockKeyFromValue(run.spectrumKey || run.spectrum, SPECTER_UNLOCK_ALIASES);
    if (manifestation) manifestations.add(manifestation);
    if (specter) specters.add(specter);
  }

  return {
    ok: true,
    profile_id: profileId,
    matched_runs: matchedRuns,
    version_code: versionCode,
    manifestations: Array.from(manifestations).sort(),
    specters: Array.from(specters).sort()
  };
}

function normalizeCardRows(cards) {
  if (!Array.isArray(cards)) {
    return [];
  }
  return cards
    .map((card) => ({
      id: String(card.id || card.name || ""),
      name: String(card.name || card.id || "Carta"),
      nick: String(card.nick || ""),
      rarity: String(card.rarity || ""),
      count: Math.max(0, Math.floor(safeNumber(card.count))),
      effect: String(card.effect || ""),
      icon: String(card.icon || ""),
      frame2: String(card.frame_2 || card.frame2 || "")
    }))
    .filter((card) => card.count > 0)
    .slice(0, 80);
}

function normalizeDamageThreats(rows) {
  if (!Array.isArray(rows)) return [];
  return rows.map((row) => ({
    kind: String(row.kind || row.source || "desconhecido").slice(0, 64),
    name: String(row.name || row.kind || "Fonte desconhecida").slice(0, 80),
    icon: String(row.icon || "").slice(0, 240),
    phase: Math.max(1, Math.min(5, Math.floor(safeNumber(row.phase, 1)))),
    damage: Math.max(0, Math.floor(safeNumber(row.damage))),
    hits: Math.max(0, Math.floor(safeNumber(row.hits)))
  })).filter((row) => row.damage > 0).slice(0, 80);
}

function normalizeDamageEvents(rows) {
  if (!Array.isArray(rows)) return [];
  return rows.map((row) => ({
    x: Math.max(0, Math.min(1, safeNumber(row.x))),
    y: Math.max(0, Math.min(1, safeNumber(row.y))),
    amount: Math.max(0, Math.floor(safeNumber(row.amount))),
    source: String(row.source || "desconhecido").slice(0, 64),
    name: String(row.name || row.source || "Fonte desconhecida").slice(0, 80),
    time: Math.max(0, safeNumber(row.time)),
    phase: Math.max(1, Math.min(5, Math.floor(safeNumber(row.phase, 1))))
  })).filter((row) => row.amount > 0).slice(0, 240);
}

function normalizeHeatmap(value) {
  const source = value && typeof value === "object" ? value : {};
  const columns = Math.max(1, Math.min(64, Math.floor(safeNumber(source.columns, 16))));
  const rows = Math.max(1, Math.min(36, Math.floor(safeNumber(source.rows, 9))));
  const cells = Array.isArray(source.cells) ? source.cells.map((cell) => ({
    phase: Math.max(1, Math.min(5, Math.floor(safeNumber(cell.phase, 1)))),
    x: Math.max(0, Math.min(columns - 1, Math.floor(safeNumber(cell.x)))),
    y: Math.max(0, Math.min(rows - 1, Math.floor(safeNumber(cell.y)))),
    count: Math.max(0, Math.floor(safeNumber(cell.count)))
  })).filter((cell) => cell.count > 0).slice(0, columns * rows * 5) : [];
  return {
    columns,
    rows,
    sampleInterval: Math.max(0.1, Math.min(10, safeNumber(source.sample_interval, 0.5))),
    worldWidth: Math.max(1, Math.floor(safeNumber(source.world_width, 1600))),
    worldHeight: Math.max(1, Math.floor(safeNumber(source.world_height, 900))),
    cells
  };
}

function normalizeBehaviorMetrics(value) {
  const source = value && typeof value === "object" ? value : {};
  const phaseSecondsSource = source.phase_seconds && typeof source.phase_seconds === "object" ? source.phase_seconds : {};
  const phaseSeconds = {};
  for (const key of Object.keys(phaseSecondsSource).slice(0, 8)) {
    const phase = Math.max(0, Math.min(7, Math.floor(safeNumber(key))));
    if (phase > 0) phaseSeconds[String(phase)] = Math.max(0, safeNumber(phaseSecondsSource[key]));
  }
  const phase1Seconds = Math.max(0, safeNumber(source.phase1_seconds, phaseSeconds["1"] || 0));
  if (phase1Seconds > 0) phaseSeconds["1"] = phase1Seconds;
  return {
    phaseSeconds,
    phase1Seconds,
    distanceTraveled: Math.max(0, Math.floor(safeNumber(source.distance_traveled))),
    edgeSeconds: Math.max(0, safeNumber(source.edge_seconds)),
    cornerSeconds: Math.max(0, safeNumber(source.corner_seconds)),
    centerSeconds: Math.max(0, safeNumber(source.center_seconds)),
    edgeRatio: Math.max(0, Math.min(1, safeNumber(source.edge_ratio))),
    cornerRatio: Math.max(0, Math.min(1, safeNumber(source.corner_ratio))),
    centerRatio: Math.max(0, Math.min(1, safeNumber(source.center_ratio))),
    dashCount: Math.max(0, Math.floor(safeNumber(source.dash_count))),
    dashPerMinute: Math.max(0, safeNumber(source.dash_per_minute)),
    shotsFired: Math.max(0, Math.floor(safeNumber(source.shots_fired))),
    shotsPerMinute: Math.max(0, safeNumber(source.shots_per_minute)),
    hits: Math.max(0, Math.floor(safeNumber(source.hits))),
    bossHits: Math.max(0, Math.floor(safeNumber(source.boss_hits))),
    hitRate: Math.max(0, Math.min(1, safeNumber(source.hit_rate))),
    stationaryRatio: Math.max(0, Math.min(1, safeNumber(source.stationary_ratio)))
  };
}

function umbraTrainingEligibility(payload, durationSeconds, rankEligible) {
  const behavior = normalizeBehaviorMetrics(payload && payload.behavior_metrics);
  const reasons = [];
  if (!rankEligible) reasons.push("run_not_rank_eligible");
  if (safeNumber(behavior.phase1Seconds) < UMBRA_TRAINING_MIN_PHASE1_SECONDS) reasons.push("phase1_under_5_minutes");
  if (durationSeconds < UMBRA_TRAINING_MIN_PHASE1_SECONDS) reasons.push("run_under_5_minutes");
  if (Math.floor(safeNumber(payload && payload.kills)) <= 0) reasons.push("no_combat_signal");
  return {
    eligible: reasons.length === 0,
    reasons,
    behavior
  };
}

function runReportSignatureSource(payload) {
  const fields = [
    "player",
    "profile_id",
    "room",
    "version",
    "version_code",
    "platform",
    "role",
    "result",
    "started_unix",
    "ended_unix",
    "duration_seconds",
    "phase",
    "kills",
    "points_earned",
    "points_spent",
    "score_current",
    "score_total",
    "cards_total",
    "manifestation_key",
    "spectrum_key",
    "enemy_damage_total",
    "damage_taken_total",
    "boss_damage_total",
    "leaderboard_score",
    "run_session_id",
    "run_session_checkpoints"
  ];
  return `${fields.map((field) => `${field}=${String(payload[field] ?? "")}`).join("|")}|salt=${RUN_REPORT_INTEGRITY_SALT}`;
}

function runReportSignature(payload) {
  return crypto.createHash("sha256").update(runReportSignatureSource(payload)).digest("hex");
}

function computeLeaderboardScore(payload) {
  const stats = payload.player_stats && typeof payload.player_stats === "object" ? payload.player_stats : {};
  let score = Math.round(safeNumber(payload.duration_seconds) * 2);
  score += Math.floor(safeNumber(payload.kills)) * 20;
  score += Math.floor(safeNumber(payload.phase)) * 250;
  score += Math.round(safeNumber(payload.boss_damage_total) / 12);
  score += Math.floor(safeNumber(payload.cards_total)) * 15;
  score += Math.round(Math.max(0, safeNumber(stats.hp)) * 0.5);
  if (String(payload.result || "") === "Vitoria") score += 1500;
  return Math.max(0, Math.floor(score));
}

function computeStoredRunScore(run) {
  const stats = run && run.playerStats && typeof run.playerStats === "object" ? run.playerStats : {};
  let score = Math.round(safeNumber(run && run.durationSeconds) * 2);
  score += Math.floor(safeNumber(run && run.kills)) * 20;
  score += Math.floor(safeNumber(run && run.phase)) * 250;
  score += Math.round(safeNumber(run && run.bossDamage) / 12);
  score += Math.floor(safeNumber(run && run.cardsTotal)) * 15;
  score += Math.round(Math.max(0, safeNumber(stats.hp)) * 0.5);
  if (String(run && run.result || "") === "Vitoria") score += 1500;
  return Math.max(0, Math.floor(score));
}

function evaluateRunIntegrity(payload, ip = "") {
  const reasons = [];
  const versionCode = Math.max(0, Math.floor(safeNumber(payload.version_code)));
  const duration = Math.max(0, Math.floor(safeNumber(payload.duration_seconds)));
  const startedUnix = Math.max(0, Math.floor(safeNumber(payload.started_unix)));
  const endedUnix = Math.max(0, Math.floor(safeNumber(payload.ended_unix, Date.now() / 1000)));
  const nowUnix = Math.floor(Date.now() / 1000);
  const kills = Math.max(0, Math.floor(safeNumber(payload.kills)));
  const pointsEarned = Math.max(0, Math.floor(safeNumber(payload.points_earned)));
  const pointsSpent = Math.max(0, Math.floor(safeNumber(payload.points_spent)));
  const cardsTotal = Math.max(0, Math.floor(safeNumber(payload.cards_total)));
  const bossDamage = Math.max(0, Math.floor(safeNumber(payload.boss_damage_total)));
  const reportedScore = Math.max(0, Math.floor(safeNumber(payload.leaderboard_score, payload.score_total || payload.score_current)));
  const expectedScore = computeLeaderboardScore(payload);
  const hasSessionEvidence = versionCode >= RUN_REPORT_SESSION_MIN_VERSION_CODE && String(payload.run_session_id || "").trim() !== "";
  if (versionCode < RUN_REPORT_COMPETITIVE_MIN_VERSION_CODE) {
    reasons.push("legacy_unsigned_protocol_closed");
  }
  if (versionCode >= RUN_REPORT_INTEGRITY_MIN_VERSION_CODE) {
    const integrity = payload.integrity && typeof payload.integrity === "object" ? payload.integrity : {};
    const signature = String(integrity.signature || "").toLowerCase();
    if (Math.floor(safeNumber(integrity.version)) !== RUN_REPORT_INTEGRITY_VERSION) {
      reasons.push("integrity_version_missing");
    }
    if (!/^[0-9a-f]{64}$/.test(signature) || signature !== runReportSignature(payload)) {
      reasons.push("signature_mismatch");
    }
  }
  if (duration < 3 || duration > 6 * 60 * 60) reasons.push("duration_out_of_range");
  if (startedUnix > 0 && endedUnix > 0 && endedUnix + RUN_REPORT_MAX_CLOCK_SKEW_SECONDS < startedUnix) reasons.push("clock_inverted");
  if (endedUnix > nowUnix + RUN_REPORT_MAX_CLOCK_SKEW_SECONDS) reasons.push("clock_future");
  if (endedUnix > 0 && nowUnix - endedUnix > RUN_REPORT_MAX_AGE_SECONDS) reasons.push("clock_too_old");
  if (!hasSessionEvidence && startedUnix > 0 && endedUnix > 0 && duration > Math.max(0, endedUnix - startedUnix) + 5 * 60) reasons.push("duration_exceeds_wall_clock");
  if (kills > duration * 16 + 240) reasons.push("kills_too_high_for_time");
  if (bossDamage > duration * 5500 + 250000) reasons.push("boss_damage_too_high_for_time");
  if (cardsTotal > Math.floor(pointsEarned / 100) + 18) reasons.push("cards_too_high_for_points");
  if (pointsSpent > pointsEarned + 1500) reasons.push("points_spent_above_earned");
  if (versionCode >= RUN_REPORT_INTEGRITY_MIN_VERSION_CODE && Math.abs(reportedScore - expectedScore) > 8) reasons.push("reported_score_mismatch");
  reasons.push(...evaluateRunSession(payload, ip, versionCode));
  return {
    rankEligible: reasons.length === 0,
    reasons,
    reportedScore,
    expectedScore,
    versionCode
  };
}

function normalizeRunPayload(payload, ip = "") {
  const player = String(payload.player || "Jogador").trim().slice(0, 32) || "Jogador";
  const durationSeconds = Math.max(0, Math.floor(safeNumber(payload.duration_seconds)));
  const bossDamage = Math.max(0, Math.floor(safeNumber(payload.boss_damage_total)));
  const kills = Math.max(0, Math.floor(safeNumber(payload.kills)));
  const integrity = evaluateRunIntegrity(payload, ip);
  const score = integrity.rankEligible ? (integrity.versionCode >= RUN_REPORT_INTEGRITY_MIN_VERSION_CODE ? integrity.expectedScore : integrity.reportedScore) : 0;
  const endedUnix = Math.max(0, Math.floor(safeNumber(payload.ended_unix, Date.now() / 1000)));
  const runTimeline = runTimelineFromSession(payload, ip, integrity.versionCode);
  const analysisCalculable = runAnalysisCalculable(runTimeline, durationSeconds);
  const umbraTraining = umbraTrainingEligibility(payload, durationSeconds, integrity.rankEligible);
  return {
    id: crypto.createHash("sha1").update(JSON.stringify(payload) + Date.now()).digest("hex").slice(0, 18),
    player,
    profileId: String(payload.profile_id || "").trim().slice(0, 64),
    room: String(payload.room || "solo").slice(0, 32),
    version: String(payload.version || "").slice(0, 24),
    versionCode: integrity.versionCode,
    platform: String(payload.platform || "").slice(0, 32),
    role: String(payload.role || "solo").slice(0, 16),
    result: String(payload.result || "").slice(0, 32),
    date: String(payload.date || new Date().toISOString()).slice(0, 48),
    startedUnix: Math.max(0, Math.floor(safeNumber(payload.started_unix))),
    endedUnix,
    duration: String(payload.duration || "").slice(0, 16),
    durationSeconds,
    phase: Math.max(0, Math.floor(safeNumber(payload.phase))),
    kills,
    score,
    reportedScore: integrity.reportedScore,
    serverScore: integrity.expectedScore,
    rankEligible: integrity.rankEligible,
    suspicious: !integrity.rankEligible,
    suspicionReasons: integrity.reasons,
    scoreCurrent: Math.max(0, Math.floor(safeNumber(payload.score_current))),
    scoreTotal: Math.max(0, Math.floor(safeNumber(payload.score_total))),
    pointsEarned: Math.max(0, Math.floor(safeNumber(payload.points_earned))),
    pointsSpent: Math.max(0, Math.floor(safeNumber(payload.points_spent))),
    baseDamageStart: Math.max(0, safeNumber(payload.base_damage_start)),
    baseDamageEnd: Math.max(0, safeNumber(payload.base_damage_end)),
    bossDamage,
    enemyDamage: Math.max(0, Math.floor(safeNumber(payload.enemy_damage_total))),
    damageTaken: Math.max(0, Math.floor(safeNumber(payload.damage_taken_total))),
    damageThreats: normalizeDamageThreats(payload.damage_taken_detail),
    damageEvents: normalizeDamageEvents(payload.damage_events),
    heatmap: normalizeHeatmap(payload.position_heatmap),
    behaviorMetrics: umbraTraining.behavior,
    umbraTrainingEligible: umbraTraining.eligible,
    umbraTrainingReasons: umbraTraining.reasons,
    manifestation: String(payload.manifestation || "").slice(0, 64),
    manifestationKey: String(payload.manifestation_key || "").slice(0, 48),
    spectrum: String(payload.spectrum || "").slice(0, 64),
    spectrumKey: String(payload.spectrum_key || "").slice(0, 48),
    cardsTotal: Math.max(0, Math.floor(safeNumber(payload.cards_total))),
    cards: normalizeCardRows(payload.cards_detail),
    playerStats: payload.player_stats && typeof payload.player_stats === "object" ? payload.player_stats : {},
    enemyScaling: payload.enemy_scaling && typeof payload.enemy_scaling === "object" ? payload.enemy_scaling : {},
    timeline: runTimeline,
    timelineSource: runTimeline.length > 1 ? "session_checkpoints" : "final_report",
    analysisCalculable,
    analysisNote: analysisCalculable
      ? "baseline inicial e janela minima de 2 minutos observados"
      : (durationSeconds < RUN_SESSION_CHECKPOINT_INTERVAL_SECONDS ? "run menor que 2 minutos; parametros insuficientes para grafico confiavel" : "baseline inicial/checkpoint de 2 minutos ausente"),
    network: payload.network && typeof payload.network === "object" ? payload.network : {},
    runSessionId: String(payload.run_session_id || "").slice(0, 64),
    settings: payload.settings && typeof payload.settings === "object" ? payload.settings : {},
    bossDetail: Array.isArray(payload.boss_detail) ? payload.boss_detail.slice(0, 8) : [],
    balanceFlags: Array.isArray(payload.balance_flags) ? payload.balance_flags.map(String).slice(0, 12) : []
  };
}

function recordRun(payload, ip = "") {
  const store = loadLeaderboardStore();
  const run = normalizeRunPayload(payload, ip);
  const profileKey = profileKeyForRun(run);
  const existingProfile = store.profiles[profileKey] || {};
  const canonicalPlayer = String(existingProfile.player || run.player || "Jogador").slice(0, 32);
  run.profileKey = profileKey;
  run.player = canonicalPlayer;
  store.profiles[profileKey] = {
    player: canonicalPlayer,
    profileId: run.profileId,
    firstSeen: existingProfile.firstSeen || run.endedUnix,
    lastSeen: run.endedUnix,
    bestScore: Math.max(safeNumber(existingProfile.bestScore), run.score),
    runs: Math.max(0, Math.floor(safeNumber(existingProfile.runs))) + 1
  };
  store.runs.unshift(run);
  store.runs = store.runs
    .sort((left, right) => safeNumber(right.score) - safeNumber(left.score) || safeNumber(right.durationSeconds) - safeNumber(left.durationSeconds) || safeNumber(right.endedUnix) - safeNumber(left.endedUnix))
    .slice(0, LEADERBOARD_MAX_RUNS);
  saveLeaderboardStore(store);
  return run;
}

function rebuildLeaderboardProfiles(store) {
  const profiles = {};
  for (const run of Array.isArray(store.runs) ? store.runs : []) {
    const key = profileKeyForRun(run);
    const existing = profiles[key] || {};
    const canonicalPlayer = String(existing.player || run.player || "Jogador").slice(0, 32);
    profiles[key] = {
      player: canonicalPlayer,
      profileId: String(run.profileId || existing.profileId || "").slice(0, 64),
      firstSeen: Math.min(safeNumber(existing.firstSeen, run.endedUnix), safeNumber(run.endedUnix)),
      lastSeen: Math.max(safeNumber(existing.lastSeen), safeNumber(run.endedUnix)),
      bestScore: Math.max(safeNumber(existing.bestScore), run.rankEligible === false ? 0 : safeNumber(run.score)),
      runs: Math.max(0, Math.floor(safeNumber(existing.runs))) + 1
    };
  }
  store.profiles = profiles;
}

function canRepairBenignAuditedRun(run) {
  if (!run || run.rankEligible !== false) return false;
  if (Math.max(0, Math.floor(safeNumber(run.versionCode))) < RUN_REPORT_SESSION_MIN_VERSION_CODE) return false;
  const reasons = Array.isArray(run.suspicionReasons) ? run.suspicionReasons.map(String) : [];
  if (!reasons.length || hardRunAuditReasons(reasons).length) return false;
  const duration = Math.max(0, Math.floor(safeNumber(run.durationSeconds)));
  const kills = Math.max(0, Math.floor(safeNumber(run.kills)));
  const cardsTotal = Math.max(0, Math.floor(safeNumber(run.cardsTotal)));
  const pointsEarned = Math.max(0, Math.floor(safeNumber(run.pointsEarned)));
  const pointsSpent = Math.max(0, Math.floor(safeNumber(run.pointsSpent)));
  const bossDamage = Math.max(0, Math.floor(safeNumber(run.bossDamage)));
  if (duration < 3 || duration > 6 * 60 * 60) return false;
  if (kills > duration * 18 + 300) return false;
  if (bossDamage > duration * 7000 + 300000) return false;
  if (cardsTotal > Math.floor(pointsEarned / 80) + 80) return false;
  if (pointsSpent > pointsEarned + Math.max(2500, Math.floor(pointsEarned * 0.25))) return false;
  return true;
}

function repairBenignLeaderboardAudits() {
  const store = loadLeaderboardStore();
  let repaired = 0;
  for (const run of Array.isArray(store.runs) ? store.runs : []) {
    if (!canRepairBenignAuditedRun(run)) continue;
    const repairedScore = safeNumber(run.serverScore, computeStoredRunScore(run)) || computeStoredRunScore(run);
    run.score = Math.max(1, Math.floor(repairedScore));
    run.serverScore = run.score;
    run.rankEligible = true;
    run.suspicious = false;
    run.auditRepairedReasons = Array.isArray(run.suspicionReasons) ? run.suspicionReasons.map(String).slice(0, 12) : [];
    run.suspicionReasons = [];
    run.auditRepairedAt = new Date().toISOString();
    repaired += 1;
  }
  if (repaired <= 0) return 0;
  store.runs = store.runs
    .sort((left, right) => safeNumber(right.score) - safeNumber(left.score) || safeNumber(right.durationSeconds) - safeNumber(left.durationSeconds) || safeNumber(right.endedUnix) - safeNumber(left.endedUnix))
    .slice(0, LEADERBOARD_MAX_RUNS);
  rebuildLeaderboardProfiles(store);
  saveLeaderboardStore(store);
  console.log(`leaderboard audit repair restored ${repaired} benign 2.0.30c run(s)`);
  return repaired;
}

function leaderboardSnapshot() {
  const store = loadLeaderboardStore();
  const eligibleRuns = store.runs.filter((run) => run.rankEligible !== false);
  const bestByProfile = new Map();
  for (const run of eligibleRuns) {
    const key = profileKeyForRun(run);
    const current = bestByProfile.get(key);
    if (!current || safeNumber(run.score) > safeNumber(current.score)) {
      bestByProfile.set(key, run);
    }
  }
  const players = Array.from(bestByProfile.values())
    .sort((left, right) => safeNumber(right.score) - safeNumber(left.score))
    .slice(0, 30);
  return { players, recent: store.runs.slice(0, 60), runs: eligibleRuns, auditedRuns: store.runs, profiles: store.profiles };
}

let cardCatalogIndex = null;

function normalizedCatalogKey(value) {
  return String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]/g, "");
}

function loadCardCatalogIndex() {
  if (cardCatalogIndex) return cardCatalogIndex;
  cardCatalogIndex = new Map();
  try {
    const source = fs.readFileSync(path.join(PROJECT_PATH, "scripts", "main.gd"), "utf8");
    for (const line of source.split(/\r?\n/)) {
      if (!line.includes('"icon": "Deck/')) continue;
      const icon = line.match(/"icon"\s*:\s*"([^"]+)"/);
      const name = line.match(/"name"\s*:\s*"([^"]+)"/);
      const id = line.match(/"id"\s*:\s*"([^"]+)"/);
      const nick = line.match(/"nick"\s*:\s*"([^"]+)"/);
      if (!icon) continue;
      for (const value of [name && name[1], id && id[1], nick && nick[1]]) {
        const key = normalizedCatalogKey(value);
        if (key) cardCatalogIndex.set(key, icon[1]);
      }
    }
  } catch (error) {
    console.error(`failed to index card catalog: ${error.message}`);
  }
  return cardCatalogIndex;
}

function publicAssetUrl(rawPath) {
  const raw = String(rawPath || "").replace(/\\/g, "/").replace(/^res:\/\//, "");
  if (!raw || raw.includes("..")) return "";
  const relative = raw.startsWith("assets/sprites/") ? raw : `assets/sprites/${raw.replace(/^assets\//, "")}`;
  const absolute = path.resolve(PROJECT_PATH, relative);
  const root = path.resolve(PROJECT_PATH, "assets", "sprites");
  if (!absolute.startsWith(root) || !fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) return "";
  return `/assets/${relative.split("/").map(encodeURIComponent).join("/")}`;
}

function cardAssetUrl(card) {
  const direct = publicAssetUrl(card.icon);
  if (direct) return direct;
  const catalog = loadCardCatalogIndex();
  for (const value of [card.id, card.name, card.nick]) {
    const catalogPath = catalog.get(normalizedCatalogKey(value));
    const resolved = publicAssetUrl(catalogPath);
    if (resolved) return resolved;
  }
  return "";
}

function leaderboardHtml() {
  const snapshot = leaderboardSnapshot();
  const best = snapshot.players[0] || null;
  const maxScore = Math.max(1, ...snapshot.players.map((run) => safeNumber(run.score)));
  const topRows = snapshot.players.map((run, index) => {
    const width = Math.max(4, Math.round((safeNumber(run.score) / maxScore) * 100));
    const deck = (run.cards || []).slice(0, 8).map((card) => {
      const src = cardAssetUrl(card);
      const label = `${escapeHtml(card.name)} x${card.count}`;
      return `<span class="card">${src ? `<img src="${escapeHtml(src)}" alt="">` : ""}<b>${label}</b></span>`;
    }).join("");
    return `<article class="runner ${index === 0 ? "winner" : ""}">
      <div class="rank">#${index + 1}</div>
      <div class="runner-main">
        <h2>${escapeHtml(run.player)}</h2>
        <p>${escapeHtml(run.manifestation)} + ${escapeHtml(run.spectrum)} | v${escapeHtml(run.version || "?")} | ${escapeHtml(run.result || "Run")}</p>
        <div class="bar"><i style="width:${width}%"></i></div>
        <div class="metrics">
          <span>Score <b>${Math.round(safeNumber(run.score))}</b></span>
          <span>Tempo <b>${escapeHtml(run.duration || `${run.durationSeconds}s`)}</b></span>
          <span>Abates <b>${Math.round(safeNumber(run.kills))}</b></span>
          <span>Boss <b>${Math.round(safeNumber(run.bossDamage))}</b></span>
          <span>Deck <b>${Math.round(safeNumber(run.cardsTotal))}</b></span>
        </div>
        <div class="deck">${deck || "<em>Sem cartas registradas</em>"}</div>
      </div>
    </article>`;
  }).join("");
  const recentRows = snapshot.recent.slice(0, 20).map((run) => `<tr><td>${escapeHtml(run.player)}</td><td>${escapeHtml(run.version || "?")}</td><td>${escapeHtml(run.duration || "")}</td><td>${Math.round(safeNumber(run.kills))}</td><td>${Math.round(safeNumber(run.bossDamage))}</td><td>${Math.round(safeNumber(run.score))}</td></tr>`).join("");
  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ruptura Temporal - Ranking QA</title>
  <style>
    :root{color-scheme:dark;--cyan:#00ffd5;--pink:#ff3df2;--bg:#05070d;--panel:#0d1524}
    *{box-sizing:border-box}body{margin:0;background:radial-gradient(circle at 50% -10%,#163445 0,#080b13 38%,#030409 100%);color:#eaffff;font-family:Inter,Segoe UI,Arial,sans-serif}
    header{padding:34px clamp(18px,4vw,58px);border-bottom:1px solid rgba(0,255,213,.24);background:linear-gradient(90deg,rgba(0,255,213,.08),rgba(255,61,242,.06))}
    h1{margin:0;font-size:clamp(26px,5vw,58px);letter-spacing:0;text-shadow:0 0 22px rgba(0,255,213,.28)}p{color:#aac4d8}
    main{display:grid;gap:22px;padding:24px clamp(14px,3vw,42px) 42px}.hero{display:grid;grid-template-columns:1.1fr .9fr;gap:18px}
    .panel,.runner{border:1px solid rgba(0,255,213,.30);background:linear-gradient(145deg,rgba(13,21,36,.92),rgba(5,7,13,.92));box-shadow:0 18px 54px rgba(0,0,0,.34),0 0 34px rgba(0,255,213,.08);border-radius:12px;padding:18px}
    .champ h2{font-size:clamp(24px,4vw,44px);margin:6px 0}.big{font-size:48px;color:var(--cyan);font-weight:800}.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px}
    .stat{padding:12px;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.035);border-radius:8px}.stat b{display:block;color:white;font-size:24px}
    .runner{display:grid;grid-template-columns:54px 1fr;gap:14px}.runner.winner{border-color:rgba(255,61,242,.72)}.rank{font-size:24px;color:var(--pink);font-weight:900}
    .runner h2{margin:0 0 4px}.runner p{margin:0 0 10px}.bar{height:10px;background:#172133;border-radius:999px;overflow:hidden}.bar i{display:block;height:100%;background:linear-gradient(90deg,var(--cyan),var(--pink));box-shadow:0 0 18px var(--cyan)}
    .metrics{display:flex;flex-wrap:wrap;gap:10px;margin:12px 0}.metrics span{padding:8px 10px;background:rgba(0,255,213,.07);border:1px solid rgba(0,255,213,.16);border-radius:8px}.metrics b{color:white}
    .deck{display:flex;gap:8px;flex-wrap:wrap}.card{display:flex;align-items:center;gap:6px;min-height:38px;padding:5px 8px;border:1px solid rgba(255,255,255,.10);border-radius:8px;background:rgba(255,255,255,.045)}.card img{width:28px;height:38px;object-fit:cover;border-radius:3px}
    table{width:100%;border-collapse:collapse}td,th{padding:10px;border-bottom:1px solid rgba(255,255,255,.08);text-align:left}th{color:var(--cyan)}
    @media(max-width:860px){.hero{grid-template-columns:1fr}.grid{grid-template-columns:repeat(2,minmax(0,1fr))}.runner{grid-template-columns:1fr}.rank{font-size:18px}}
  </style>
</head>
<body>
  <header><h1>Ranking Ruptura Temporal</h1><p>Comparativo vivo das runs enviadas pelo QA. A ficha preserva versao, deck, boss, tempo e sinais de balanceamento.</p></header>
  <main>
    <section class="hero">
      <div class="panel champ">
        <span>Melhor player atual</span>
        <h2>${best ? escapeHtml(best.player) : "Sem runs ainda"}</h2>
        <div class="big">${best ? Math.round(safeNumber(best.score)) : 0}</div>
        <p>${best ? `${escapeHtml(best.manifestation)} + ${escapeHtml(best.spectrum)} | v${escapeHtml(best.version || "?")}` : "Aguardando a primeira run."}</p>
      </div>
      <div class="panel">
        <div class="grid">
          <div class="stat"><span>Runs</span><b>${snapshot.recent.length}</b></div>
          <div class="stat"><span>Players</span><b>${snapshot.players.length}</b></div>
          <div class="stat"><span>Maior boss</span><b>${Math.max(0, ...snapshot.recent.map((run) => safeNumber(run.bossDamage))).toFixed(0)}</b></div>
          <div class="stat"><span>Maior tempo</span><b>${Math.max(0, ...snapshot.recent.map((run) => safeNumber(run.durationSeconds))).toFixed(0)}s</b></div>
        </div>
      </div>
    </section>
    <section>${topRows || '<div class="panel">Nenhuma run enviada ainda.</div>'}</section>
    <section class="panel"><h2>Historico recente</h2><table><thead><tr><th>Player</th><th>Versao</th><th>Tempo</th><th>Abates</th><th>Boss</th><th>Score</th></tr></thead><tbody>${recentRows}</tbody></table></section>
  </main>
</body>
</html>`;
}

function assetContentType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === ".png") return "image/png";
  if (ext === ".jpg" || ext === ".jpeg") return "image/jpeg";
  if (ext === ".webp") return "image/webp";
  return "application/octet-stream";
}

function sendAsset(res, assetPath) {
  const clean = decodeURIComponent(assetPath).replace(/\\/g, "/");
  if (clean.includes("..") || !clean.startsWith("assets/sprites/")) {
    sendJson(res, 404, { error: "asset not found" });
    return;
  }
  const absolute = path.resolve(PROJECT_PATH, clean);
  const root = path.resolve(PROJECT_PATH, "assets", "sprites");
  if (!absolute.startsWith(root) || !fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) {
    sendJson(res, 404, { error: "asset not found" });
    return;
  }
  const body = fs.readFileSync(absolute);
  res.writeHead(200, {
    "Access-Control-Allow-Origin": "*",
    "Cache-Control": "public, max-age=86400",
    "Content-Type": assetContentType(absolute),
    "Content-Length": body.length
  });
  res.end(body);
}

async function route(req, res) {
  if (req.method === "OPTIONS") {
    sendJson(res, 204, {});
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === "GET" && url.pathname === "/favicon.ico") {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": "public, max-age=86400"
    });
    res.end();
    return;
  }

  if (req.method === "GET" && url.pathname === "/health") {
    const readyStandby = warmStandbyRooms().length;
    sendJson(res, 200, {
      ok: true,
      rooms: activeRooms().length,
      standby: readyStandby,
      standbyStarting: Math.max(0, standbyRooms().length - readyStandby),
      streams: STREAMING_ENABLED ? streams.size : 0,
      runs: leaderboardSnapshot().recent.length,
      protocols: STREAMING_ENABLED ? ["rtmp-hls", "frame-mjpeg", "http-mjpeg"] : [],
      streaming: STREAMING_ENABLED
    });
    return;
  }

  if (req.method === "GET" && url.pathname === "/updates/android/latest") {
    const currentVersionCode = Math.max(0, Math.floor(Number(url.searchParams.get("version_code")) || 0));
    res.setHeader("Cache-Control", "no-store, max-age=0");
    sendJson(res, 200, androidUpdatePublic(currentVersionCode));
    return;
  }

  if (req.method === "GET" && url.pathname === "/updates/windows/latest") {
    const currentVersionCode = Math.max(0, Math.floor(Number(url.searchParams.get("version_code")) || 0));
    res.setHeader("Cache-Control", "no-store, max-age=0");
    sendJson(res, 200, updatePublic("windows", currentVersionCode));
    return;
  }

  if (req.method === "GET" && url.pathname === "/updates/unlocks/veteran") {
    res.setHeader("Cache-Control", "no-store, max-age=0");
    sendJson(res, 200, veteranUnlockSnapshot(url.searchParams));
    return;
  }

  if (req.method === "GET" && url.pathname === "/umbra/mind/latest") {
    res.setHeader("Cache-Control", "no-store, max-age=0");
    sendJson(res, 200, buildUmbraMind(leaderboardSnapshot(), url.searchParams));
    return;
  }

  const androidApkMatch = url.pathname.match(/^\/updates\/android\/download\/([^/]+)$/);
  if ((req.method === "GET" || req.method === "HEAD") && androidApkMatch) {
    sendAndroidApk(req, res, androidApkMatch[1]);
    return;
  }

  const windowsExeMatch = url.pathname.match(/^\/updates\/windows\/download\/([^/]+)$/);
  if ((req.method === "GET" || req.method === "HEAD") && windowsExeMatch) {
    sendUpdateFile(req, res, "windows", windowsExeMatch[1]);
    return;
  }

  if (req.method === "POST" && url.pathname === "/runs/start") {
    const ip = clientIp(req);
    const blocked = isSecurityBlocked(ip);
    if (blocked.blocked) {
      res.setHeader("Retry-After", String(blocked.retryAfterSeconds));
      sendJson(res, 429, { ok: false, error: "ranking temporarily locked", retry_after_seconds: blocked.retryAfterSeconds });
      return;
    }
    let payload;
    try {
      payload = await readJson(req, 64 * 1024);
    } catch (_error) {
      recordSecurityStrike(ip, ["invalid_run_session_start"], { version: "unknown" });
      sendJson(res, 400, { ok: false, error: "invalid run session start" });
      return;
    }
    const session = createRunSession(ip, payload);
    sendJson(res, 201, {
      ok: true,
      session_id: session.sessionId,
      session_token: session.token,
      checkpoint_interval_seconds: session.checkpointIntervalSeconds
    });
    return;
  }

  if (req.method === "POST" && url.pathname === "/runs/checkpoint") {
    const ip = clientIp(req);
    const blocked = isSecurityBlocked(ip);
    if (blocked.blocked) {
      res.setHeader("Retry-After", String(blocked.retryAfterSeconds));
      sendJson(res, 429, { ok: false, error: "ranking temporarily locked", retry_after_seconds: blocked.retryAfterSeconds });
      return;
    }
    let payload;
    try {
      payload = await readJson(req, 128 * 1024);
    } catch (_error) {
      recordSecurityStrike(ip, ["invalid_run_checkpoint"], { version: "unknown" });
      sendJson(res, 400, { ok: false, error: "invalid run checkpoint" });
      return;
    }
    const result = updateRunSession(ip, payload);
    if (!result.ok && result.reasons.some((reason) => reason.includes("token") || reason.includes("session_not_found") || reason.includes("ip_mismatch"))) {
      recordSecurityStrike(ip, result.reasons, payload);
    }
    sendJson(res, result.reasons.length ? 202 : 200, {
      ok: result.reasons.length === 0,
      accepted: true,
      reasons: result.reasons,
      checkpoint_interval_seconds: RUN_SESSION_CHECKPOINT_INTERVAL_SECONDS
    });
    return;
  }

  if (req.method === "POST" && url.pathname === "/runs") {
    const ip = clientIp(req);
    const blocked = isSecurityBlocked(ip);
    if (blocked.blocked) {
      res.setHeader("Retry-After", String(blocked.retryAfterSeconds));
      sendJson(res, 429, { ok: false, error: "ranking temporarily locked", retry_after_seconds: blocked.retryAfterSeconds });
      return;
    }
    const rate = registerRunReportAttempt(ip);
    if (rate.limited) {
      res.setHeader("Retry-After", String(rate.retryAfterSeconds));
      sendJson(res, 429, { ok: false, error: "too many ranking reports", retry_after_seconds: rate.retryAfterSeconds });
      return;
    }
    let payload;
    try {
      payload = await readJson(req, RUN_REPORT_MAX_BYTES);
    } catch (error) {
      recordSecurityStrike(ip, ["invalid_or_oversized_payload"], { version: "unknown" });
      sendJson(res, 400, { ok: false, error: "invalid run report" });
      return;
    }
    const run = recordRun(payload, ip);
    if (run.suspicious) {
      recordSecurityStrike(ip, run.suspicionReasons, run);
    }
    sendJson(res, run.suspicious ? 202 : 201, {
      ok: true,
      accepted: true,
      rankEligible: run.rankEligible !== false,
      run,
      leaderboardUrl: `${STREAM_MANAGER_PUBLIC_BASE_URL}/leaderboard`,
      runUrl: leaderboardRunUrl(run)
    });
    return;
  }

  if (req.method === "GET" && url.pathname === "/runs") {
    sendJson(res, 200, leaderboardSnapshot());
    return;
  }

  if (req.method === "GET" && (url.pathname === "/leaderboard" || url.pathname.startsWith("/leaderboard/"))) {
    sendHtml(res, 200, renderLeaderboardSite({
      pathname: url.pathname,
      snapshot: leaderboardSnapshot(),
      cardAssetUrl,
      publicAssetUrl
    }));
    return;
  }

  const assetMatch = url.pathname.match(/^\/assets\/(.+)$/);
  if (req.method === "GET" && assetMatch) {
    sendAsset(res, assetMatch[1]);
    return;
  }

  if (req.method === "POST" && url.pathname === "/streams") {
    if (!STREAMING_ENABLED) {
      sendStreamingDisabled(res);
      return;
    }
    const payload = await readJson(req);
    if (streams.size >= STREAM_MAX_ACTIVE) {
      sendJson(res, 429, { ok: false, error: "stream capacity reached", active: streams.size, limit: STREAM_MAX_ACTIVE });
      return;
    }
    sendJson(res, 201, streamPublic(createStream(payload)));
    return;
  }

  const streamMatch = url.pathname.match(/^\/streams\/([a-zA-Z0-9_-]+)$/);
  if (req.method === "GET" && streamMatch) {
    if (!STREAMING_ENABLED) {
      sendStreamingDisabled(res);
      return;
    }
    const stream = streams.get(streamMatch[1]);
    if (!stream) {
      sendJson(res, 404, { error: "stream not found" });
      return;
    }
    if (url.searchParams.get("format") === "json") {
      sendJson(res, 200, streamPublic(stream));
    } else {
      sendHtml(res, 200, streamViewerHtml(stream));
    }
    return;
  }

  if (req.method === "DELETE" && streamMatch) {
    if (!STREAMING_ENABLED) {
      sendStreamingDisabled(res);
      return;
    }
    const stopped = closeStream(streamMatch[1]);
    sendJson(res, stopped ? 200 : 404, { stopped });
    return;
  }

  const streamMjpegPublishMatch = url.pathname.match(/^\/streams\/([a-zA-Z0-9_-]+)\/mjpeg-publish$/);
  if (streamMjpegPublishMatch) {
    if (!STREAMING_ENABLED) {
      sendStreamingDisabled(res);
      return;
    }
    const stream = streams.get(streamMjpegPublishMatch[1]);
    if (!stream) {
      sendJson(res, 404, { error: "stream not found" });
      return;
    }
    if (req.method !== "POST") {
      sendJson(res, 405, { error: "method not allowed" });
      return;
    }
    refreshStreamTtl(stream);
    res.writeHead(200, {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "Connection": "keep-alive"
    });
    let published = 0;
    req.on("data", (chunk) => {
      published += publishMjpegChunk(stream, chunk);
    });
    req.on("end", () => {
      if (!res.destroyed) {
        res.end(JSON.stringify({ ok: true, id: stream.id, published, frameCount: stream.frameCount }));
      }
    });
    req.on("error", () => {
      if (!res.destroyed) res.end();
    });
    return;
  }

  const streamFrameMatch = url.pathname.match(/^\/streams\/([a-zA-Z0-9_-]+)\/frame$/);
  if (streamFrameMatch) {
    if (!STREAMING_ENABLED) {
      sendStreamingDisabled(res);
      return;
    }
    const stream = streams.get(streamFrameMatch[1]);
    if (!stream) {
      sendJson(res, 404, { error: "stream not found" });
      return;
    }
    if (req.method === "POST") {
      let frame;
      try {
        frame = await readBinary(req);
      } catch (error) {
        const status = error && error.statusCode === 413 ? 413 : 400;
        sendJson(res, status, { ok: false, error: error.message || "invalid frame" });
        return;
      }
      if (!frame.length) {
        sendJson(res, 400, { error: "empty frame" });
        return;
      }
      const seq = Number(req.headers["x-frame-seq"]) || 0;
      const accepted = publishFrame(stream, frame, contentTypeForFrame(req), seq);
      sendJson(res, 202, { ok: true, accepted, id: stream.id, frameCount: stream.frameCount, framesPerSecond: stream.framesPerSecond, bytesReceived: stream.bytesReceived, lastFrameAt: stream.lastFrameAt, lastFrameSeq: stream.lastFrameSeq });
      return;
    }
    if (req.method === "GET") {
      sendLatestFrame(res, stream);
      return;
    }
  }

  const streamMjpegMatch = url.pathname.match(/^\/streams\/([a-zA-Z0-9_-]+)\/mjpeg$/);
  if (req.method === "GET" && streamMjpegMatch) {
    if (!STREAMING_ENABLED) {
      sendStreamingDisabled(res);
      return;
    }
    const stream = streams.get(streamMjpegMatch[1]);
    if (!stream) {
      sendJson(res, 404, { error: "stream not found" });
      return;
    }
    sendMjpegStream(req, res, stream);
    return;
  }

  if (req.method === "POST" && url.pathname === "/rooms") {
    const payload = await readJson(req);
    const ownerName = String(payload.name || "host");
    const room = claimWarmStandby(ownerName) || startRoom(ownerName);
    await waitForRoomReady(room);
    sendJson(res, 201, roomPublic(room));
    return;
  }

  if (req.method === "GET" && url.pathname === "/rooms") {
    sendJson(res, 200, { rooms: listAvailableRooms() });
    return;
  }

  if (req.method === "GET" && url.pathname === "/rooms/available") {
    const room = availableRoom();
    if (!room) {
      sendJson(res, 404, { error: "no available rooms" });
      return;
    }
    sendJson(res, 200, roomPublic(room));
    return;
  }

  const joinMatch = url.pathname.match(/^\/rooms\/([A-F0-9]{6})\/join$/);
  if (req.method === "POST" && joinMatch) {
    const room = reserveRoom(roomByCode(joinMatch[1]));
    if (!room) {
      sendJson(res, 404, { error: "room not available" });
      return;
    }
    sendJson(res, 200, roomPublic(room));
    return;
  }

  const heartbeatMatch = url.pathname.match(/^\/rooms\/([A-F0-9]{6})\/heartbeat$/);
  if (req.method === "POST" && heartbeatMatch) {
    const room = roomByCode(heartbeatMatch[1]);
    if (!room || room.standby || room.stopping) {
      sendJson(res, 404, { error: "room not found" });
      return;
    }
    let payload = {};
    try {
      payload = await readJson(req, 8 * 1024);
    } catch (_error) {
      payload = {};
    }
    room.heartbeatCount = (room.heartbeatCount || 0) + 1;
    room.lastHeartbeatAt = Date.now();
    const role = String(payload.role || "unknown").slice(0, 24);
    const mode = String(payload.mode || "unknown").slice(0, 48);
    const peerId = Number.isFinite(Number(payload.peer_id)) ? Number(payload.peer_id) : 0;
    touchRoom(room, "heartbeat", {
      count: room.heartbeatCount,
      role,
      mode,
      peerId
    });
    sendJson(res, 200, { ok: true, room: roomPublic(room), expiresInMs: roomPublic(room).expiresInMs });
    return;
  }

  const getMatch = url.pathname.match(/^\/rooms\/([A-F0-9]{6})$/);
  if (req.method === "GET" && getMatch) {
    const room = roomByCode(getMatch[1]);
    if (!room) {
      sendJson(res, 404, { error: "room not found" });
      return;
    }
    sendJson(res, 200, roomPublic(room));
    return;
  }

  const deleteMatch = url.pathname.match(/^\/rooms\/([A-F0-9]{6})$/);
  if (req.method === "DELETE" && deleteMatch) {
    const stopped = stopRoom(deleteMatch[1], "delete request");
    sendJson(res, stopped ? 200 : 404, { stopped });
    scheduleWarmStandbyRefill();
    return;
  }

  sendJson(res, 404, { error: "not found" });
}

const server = http.createServer((req, res) => {
  route(req, res).catch((error) => {
    console.error(error);
    sendJson(res, 500, { error: error.message });
  });
});

server.listen(MANAGER_PORT, "0.0.0.0", () => {
  console.log(`ruptura relay manager listening on :${MANAGER_PORT}`);
  console.log(`rooms will advertise ${ROOM_HOST}:${ROOM_PORT_START}-${ROOM_PORT_END}`);
  repairBenignLeaderboardAudits();
  ensureWarmStandby();
});
