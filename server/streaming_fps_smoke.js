"use strict";

const assert = require("assert");
const http = require("http");
const net = require("net");
const os = require("os");
const path = require("path");
const { spawn } = require("child_process");

function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      server.close(() => resolve(address.port));
    });
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function request(port, method, route, body = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const isBuffer = Buffer.isBuffer(body);
    const data = body == null ? null : (isBuffer ? body : Buffer.from(JSON.stringify(body)));
    const req = http.request({
      hostname: "127.0.0.1",
      port,
      path: route,
      method,
      headers: data ? {
        "Content-Type": isBuffer ? "image/jpeg" : "application/json",
        "Content-Length": data.length,
        ...headers
      } : headers
    }, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => resolve({ status: res.statusCode, body: Buffer.concat(chunks), headers: res.headers }));
    });
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

async function waitForHealth(port) {
  let lastError = null;
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      const response = await request(port, "GET", "/health");
      if (response.status === 200) return;
    } catch (error) {
      lastError = error;
    }
    await sleep(100);
  }
  throw lastError || new Error("relay did not become healthy");
}

function openMjpegViewer(port, streamId) {
  let chunksText = "";
  let frameBoundaries = 0;
  const req = http.get({
    hostname: "127.0.0.1",
    port,
    path: `/streams/${streamId}/mjpeg`,
    headers: { Accept: "multipart/x-mixed-replace" }
  }, (res) => {
    res.on("data", (chunk) => {
      chunksText += chunk.toString("latin1");
      const parts = chunksText.split("--ruptura-frame");
      frameBoundaries += Math.max(0, parts.length - 1);
      chunksText = parts[parts.length - 1].slice(-64);
    });
  });
  req.on("error", () => {});
  return {
    close: () => req.destroy(),
    frameCount: () => frameBoundaries
  };
}

async function run() {
  const port = await freePort();
  const tempRoot = path.join(os.tmpdir(), `ruptura_streaming_fps_${Date.now()}`);
  const child = spawn(process.execPath, ["relay_manager.js"], {
    cwd: __dirname,
    env: {
      ...process.env,
      PORT: String(port),
      ROOM_HOST: "127.0.0.1",
      ROOM_PORT_START: "19322",
      ROOM_PORT_END: "19325",
      WARM_STANDBY_ROOMS: "0",
      STREAMING_ENABLED: "1",
      STREAM_MAX_ACTIVE: "1",
      STREAM_FRAME_MAX_BYTES: "2400000",
      STREAM_FRAME_BUFFER_MAX: "8",
      STREAM_FRAME_BUFFER_MS: "80",
      STREAM_MANAGER_PUBLIC_BASE_URL: `http://127.0.0.1:${port}`,
      ALLOW_LOCAL_PUBLIC_BASE_URL: "1",
      LEADERBOARD_PATH: path.join(tempRoot, "leaderboard_runs.json"),
      RUN_SECURITY_PATH: path.join(tempRoot, "leaderboard_security.json"),
      UPDATE_MANIFEST_PATH: path.join(tempRoot, "updates", "latest.json")
    },
    stdio: ["ignore", "pipe", "pipe"]
  });
  let output = "";
  child.stdout.on("data", (chunk) => { output += chunk; });
  child.stderr.on("data", (chunk) => { output += chunk; });

  let viewer = null;
  try {
    await waitForHealth(port);
    const created = await request(port, "POST", "/streams", {
      player: "FPSQA",
      room: "fps-smoke",
      version: "2.0.30-stream-smoke",
      protocol: "frame-mjpeg",
      streamWidth: 1280,
      streamHeight: 720,
      streamFps: 60,
      streamQuality: 0.66,
      streamBitrate: 8000000,
      bufferMs: 60
    });
    assert.strictEqual(created.status, 201, output || created.body.toString("utf8"));
    const stream = JSON.parse(created.body.toString("utf8"));
    assert.strictEqual(stream.streamFps, 60, "relay should preserve 60fps target");
    assert.strictEqual(stream.bufferMs, 60, "relay should accept low-latency buffer");

    viewer = openMjpegViewer(port, stream.id);
    await sleep(150);

    const frame = Buffer.concat([
      Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01]),
      Buffer.alloc(140 * 1024, 0x36),
      Buffer.from([0xff, 0xd9])
    ]);
    const targetFps = 60;
    const durationMs = 2600;
    const startedAt = Date.now();
    let published = 0;
    let accepted = 0;
    let nextFrameAt = startedAt;
    while (Date.now() - startedAt < durationMs) {
      nextFrameAt += 1000 / targetFps;
      published += 1;
      const response = await request(port, "POST", `/streams/${stream.id}/frame`, frame, { "X-Frame-Seq": String(published) });
      if (response.status === 202) {
        const body = JSON.parse(response.body.toString("utf8"));
        if (body.accepted) accepted += 1;
      }
      const waitMs = Math.max(0, nextFrameAt - Date.now());
      if (waitMs > 0) await sleep(waitMs);
    }
    const publishEndedAt = Date.now();
    await sleep(350);

    const publishSeconds = (publishEndedAt - startedAt) / 1000;
    const acceptedFps = accepted / publishSeconds;
    const viewerFrames = viewer.frameCount();
    const viewerFps = viewerFrames / publishSeconds;
    const status = await request(port, "GET", `/streams/${stream.id}?format=json`);
    assert.strictEqual(status.status, 200, "stream status should remain readable");
    const statusJson = JSON.parse(status.body.toString("utf8"));

    assert(acceptedFps >= 54, `accepted fps too low: ${acceptedFps.toFixed(1)}`);
    assert(viewerFps >= 50, `viewer fps too low: ${viewerFps.toFixed(1)}`);
    assert(statusJson.frameCount >= accepted, "status should include all accepted frames");

    console.log(
      `STREAMING_FPS_SMOKE_OK target=60 published=${published} accepted=${accepted} ` +
      `accepted_fps=${acceptedFps.toFixed(1)} viewer_frames=${viewerFrames} ` +
      `viewer_fps=${viewerFps.toFixed(1)} server_fps=${statusJson.framesPerSecond || 0}`
    );
    await request(port, "DELETE", `/streams/${stream.id}`);
  } finally {
    if (viewer) viewer.close();
    child.kill("SIGTERM");
    await sleep(150);
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
