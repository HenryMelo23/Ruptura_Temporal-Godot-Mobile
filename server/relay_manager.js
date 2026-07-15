"use strict";

const http = require("http");
const crypto = require("crypto");
const { spawn } = require("child_process");

const MANAGER_PORT = numberEnv("PORT", 8080);
const ROOM_HOST = process.env.ROOM_HOST || "72.61.217.238";
const ROOM_PORT_START = numberEnv("ROOM_PORT_START", 4522);
const ROOM_PORT_END = numberEnv("ROOM_PORT_END", 4599);
const GODOT_BIN = process.env.GODOT_BIN || "/opt/godot/Godot_v4.7-stable_linux.x86_64";
const PROJECT_PATH = process.env.PROJECT_PATH || "/opt/ruptura/Ruptura_Temporal-Godot-Mobile";
const ROOM_IDLE_MS = numberEnv("ROOM_IDLE_MS", 15 * 60 * 1000);
const WARM_STANDBY_ROOMS = numberEnv("WARM_STANDBY_ROOMS", 1, true);
const WARM_STANDBY_REFILL_MS = numberEnv("WARM_STANDBY_REFILL_MS", 1500);
const MAX_PLAYERS = 2;
const STREAM_PUBLIC_HOST = process.env.STREAM_PUBLIC_HOST || ROOM_HOST;
const STREAM_PUBLIC_SCHEME = process.env.STREAM_PUBLIC_SCHEME || "http";
const STREAM_WEBRTC_PORT = numberEnv("STREAM_WEBRTC_PORT", 8889);
const STREAM_HLS_PORT = numberEnv("STREAM_HLS_PORT", 8888);
const STREAM_RTMP_PORT = numberEnv("STREAM_RTMP_PORT", 1935);
const STREAM_RTMP_APP = process.env.STREAM_RTMP_APP || "live";
const STREAM_MANAGER_PUBLIC_BASE_URL = process.env.STREAM_MANAGER_PUBLIC_BASE_URL || `http://${ROOM_HOST}:${MANAGER_PORT}`;
const STREAM_TTL_MS = numberEnv("STREAM_TTL_MS", 4 * 60 * 60 * 1000);
const STREAM_FRAME_MAX_BYTES = numberEnv("STREAM_FRAME_MAX_BYTES", 6_000_000);
const STREAM_FRAME_BUFFER_MAX = numberEnv("STREAM_FRAME_BUFFER_MAX", 90);
const STREAM_FRAME_BUFFER_MS = numberEnv("STREAM_FRAME_BUFFER_MS", 900);

const rooms = new Map();
const streams = new Map();
let warmRefillTimer = null;

function numberEnv(name, fallback, allowZero = false) {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && (value > 0 || (allowZero && value === 0)) ? value : fallback;
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

function readJson(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.setEncoding("utf8");
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 16 * 1024) {
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
    req.on("data", (chunk) => {
      total += chunk.length;
      if (total > maxBytes) {
        reject(new Error("frame too large"));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => resolve(Buffer.concat(chunks, total)));
    req.on("error", reject);
  });
}

function roomPublic(room) {
  return {
    code: room.code,
    host: ROOM_HOST,
    port: room.port,
    players: room.players,
    maxPlayers: MAX_PLAYERS,
    createdAt: room.createdAt
  };
}

function allocatePort() {
  const used = new Set(Array.from(rooms.values()).map((room) => room.port));
  for (let port = ROOM_PORT_START; port <= ROOM_PORT_END; port += 1) {
    if (!used.has(port)) {
      return port;
    }
  }
  return 0;
}

function createCode() {
  return crypto.randomBytes(3).toString("hex").toUpperCase();
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
  const hlsUrl = `${STREAM_PUBLIC_SCHEME}://${STREAM_PUBLIC_HOST}:${STREAM_HLS_PORT}/${rtmpPath}/index.m3u8`;
  const mjpegUrl = `${STREAM_MANAGER_PUBLIC_BASE_URL}/streams/${stream.id}/mjpeg`;
  const frameUrl = `${STREAM_MANAGER_PUBLIC_BASE_URL}/streams/${stream.id}/frame`;
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
    frameUrl,
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
    streamWidth: Number(payload.streamWidth) || 1280,
    streamHeight: Number(payload.streamHeight) || 720,
    streamFps: Number(payload.streamFps) || 30,
    streamQuality: Number(payload.streamQuality) || 0.86,
    streamBitrate: Number(payload.streamBitrate) || 3_500_000,
    bufferMs: Math.max(0, Math.min(1000, Number(payload.bufferMs) || STREAM_FRAME_BUFFER_MS)),
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
  if (seq && seq <= stream.lastFrameSeq) {
    return false;
  }
  stream.lastFrame = frame;
  stream.lastFrameType = contentType;
  stream.lastFrameAt = now;
  stream.lastFrameSeq = seq || stream.lastFrameSeq + 1;
  stream.frameCount += 1;
  refreshStreamFps(stream, now);
  stream.framesThisSecond += 1;
  stream.bytesReceived += frame.length;
  stream.frameBuffer.push({ frame, contentType, seq: stream.lastFrameSeq, createdAt: now });
  const keepAfter = now - Math.max(stream.bufferMs, STREAM_FRAME_BUFFER_MS);
  stream.frameBuffer = stream.frameBuffer
    .filter((entry) => entry.createdAt >= keepAfter)
    .slice(-STREAM_FRAME_BUFFER_MAX);
  refreshStreamTtl(stream);
  for (const res of Array.from(stream.subscribers)) {
    try {
      if (res.rupturaBlocked) {
        res.rupturaLatest = { frame, contentType, seq: stream.lastFrameSeq, createdAt: now };
        continue;
      }
      pushFrameToSubscriber(res, frame, contentType, stream.lastFrameSeq, now);
    } catch (_error) {
      stream.subscribers.delete(res);
    }
  }
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
    "Connection": "close",
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
    img,video{display:block;width:100%;height:100%;object-fit:contain;background:#000}
    #empty{position:absolute;inset:0;display:grid;place-items:center;color:#fff;text-shadow:0 2px 2px #000;font-weight:700;z-index:2}
    .muted{color:#9fb3c8}
    @media (max-width:700px){header{gap:10px;font-size:12px}#stage{padding:12px}#shell{width:min(98vw,calc((100vh - 76px) * (${aspectRatio})));padding:7px;border-radius:10px}}
  </style>
</head>
<body>
  <header><strong>Ruptura Temporal QA</strong><span>${data.player}</span><span>${data.room || "solo"}</span><span>${data.id}</span><span>${data.streamWidth}x${data.streamHeight} ${data.streamFps}fps</span><span id="status" class="muted">aguardando frame</span></header>
  <main id="stage"><section id="shell"><div id="screen"><div id="empty">Aguardando imagem real do jogo...</div><video id="video" autoplay muted playsinline controls></video><img id="player" alt="Ruptura QA Stream" src="${mjpegUrl}"></div></section></main>
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1"></script>
  <script>
    const protocol = "${data.protocol}";
    const hlsUrl = "${hlsUrl}";
    const statusEl = document.getElementById("status");
    const emptyEl = document.getElementById("empty");
    const img = document.getElementById("player");
    const video = document.getElementById("video");
    let lastCount = 0;
    let fallbackTimer = null;
    if (protocol === "rtmp-hls") {
      img.style.display = "none";
      if (video.canPlayType("application/vnd.apple.mpegurl")) {
        video.src = hlsUrl;
      } else if (window.Hls && Hls.isSupported()) {
        const hls = new Hls({
          lowLatencyMode: true,
          liveSyncDuration: 0.8,
          liveMaxLatencyDuration: 1.5,
          maxLiveSyncPlaybackRate: 1.2,
          enableWorker: true
        });
        hls.loadSource(hlsUrl);
        hls.attachMedia(video);
      } else {
        emptyEl.textContent = "Navegador sem HLS. Abra no Chrome/Edge atualizado.";
      }
      video.onplaying = () => { emptyEl.style.display = "none"; };
      video.onerror = () => { emptyEl.textContent = "Aguardando publicacao HLS do celular..."; };
    } else {
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
          statusEl.textContent = data.streamWidth + "x" + data.streamHeight + " " + data.streamFps + "fps alvo | HLS nativo";
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
  const child = spawn(GODOT_BIN, args, {
    cwd: PROJECT_PATH,
    stdio: ["ignore", "pipe", "pipe"]
  });

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
    stopping: false
  };
  rooms.set(code, room);

  child.stdout.on("data", (chunk) => process.stdout.write(`[${code}] ${chunk}`));
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
    console.log(`room ${code}${room.standby ? " standby" : ""} exited status=${status} signal=${signal}`);
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
  room.idleTimer = setTimeout(() => {
    stopRoom(room.code, "idle timeout");
  }, ROOM_IDLE_MS);
}

function stopRoom(code, reason) {
  const room = rooms.get(code);
  if (!room) {
    return false;
  }
  console.log(`stopping room ${code}: ${reason}`);
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
  let missing = WARM_STANDBY_ROOMS - warmStandbyRooms().length;
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
  scheduleRoomStop(room);
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
  room.lastSeen = Date.now();
  scheduleRoomStop(room);
  return room;
}

function roomByCode(code) {
  return rooms.get(String(code || "").toUpperCase()) || null;
}

async function route(req, res) {
  if (req.method === "OPTIONS") {
    sendJson(res, 204, {});
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === "GET" && url.pathname === "/health") {
    sendJson(res, 200, { ok: true, rooms: activeRooms().length, standby: warmStandbyRooms().length, streams: streams.size, protocols: ["rtmp-hls", "frame-mjpeg"] });
    return;
  }

  if (req.method === "POST" && url.pathname === "/streams") {
    const payload = await readJson(req);
    sendJson(res, 201, streamPublic(createStream(payload)));
    return;
  }

  const streamMatch = url.pathname.match(/^\/streams\/([a-zA-Z0-9_-]+)$/);
  if (req.method === "GET" && streamMatch) {
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
    const stopped = closeStream(streamMatch[1]);
    sendJson(res, stopped ? 200 : 404, { stopped });
    return;
  }

  const streamFrameMatch = url.pathname.match(/^\/streams\/([a-zA-Z0-9_-]+)\/frame$/);
  if (streamFrameMatch) {
    const stream = streams.get(streamFrameMatch[1]);
    if (!stream) {
      sendJson(res, 404, { error: "stream not found" });
      return;
    }
    if (req.method === "POST") {
      const frame = await readBinary(req);
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
  ensureWarmStandby();
});
