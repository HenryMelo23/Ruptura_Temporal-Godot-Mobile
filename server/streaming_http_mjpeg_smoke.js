"use strict";

const assert = require("assert");
const http = require("http");
const net = require("net");
const os = require("os");
const path = require("path");
const { spawn, spawnSync } = require("child_process");

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
    const data = body == null ? null : Buffer.from(JSON.stringify(body));
    const req = http.request({
      hostname: "127.0.0.1",
      port,
      path: route,
      method,
      headers: data ? {
        "Content-Type": "application/json",
        "Content-Length": data.length,
        ...headers
      } : headers,
      timeout: 8000
    }, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => resolve({ status: res.statusCode, body: Buffer.concat(chunks), headers: res.headers }));
    });
    req.on("timeout", () => req.destroy(new Error("timeout")));
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

function openMjpegViewer(port, streamId) {
  let chunksText = "";
  let frameBoundaries = 0;
  let bytes = 0;
  const req = http.get({
    hostname: "127.0.0.1",
    port,
    path: `/streams/${streamId}/mjpeg`,
    headers: { Accept: "multipart/x-mixed-replace" }
  }, (res) => {
    res.on("data", (chunk) => {
      bytes += chunk.length;
      chunksText += chunk.toString("latin1");
      const parts = chunksText.split("--ruptura-frame");
      frameBoundaries += Math.max(0, parts.length - 1);
      chunksText = parts[parts.length - 1].slice(-64);
    });
  });
  req.on("error", () => {});
  return {
    close: () => req.destroy(),
    frameCount: () => frameBoundaries,
    bytesReceived: () => bytes
  };
}

async function waitForHealth(port) {
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      const response = await request(port, "GET", "/health");
      if (response.status === 200) return;
    } catch (_error) {}
    await sleep(100);
  }
  throw new Error("relay did not become healthy");
}

async function run() {
  const ffmpegCheck = spawnSync("ffmpeg", ["-version"], { stdio: "ignore" });
  if (ffmpegCheck.status !== 0) {
    console.log("HTTP_MJPEG_FFMPEG_SMOKE_SKIPPED ffmpeg_not_found=true");
    return;
  }

  const port = await freePort();
  const tempRoot = path.join(os.tmpdir(), `ruptura_http_mjpeg_${Date.now()}`);
  const child = spawn(process.execPath, ["relay_manager.js"], {
    cwd: __dirname,
    env: {
      ...process.env,
      PORT: String(port),
      ROOM_HOST: "127.0.0.1",
      ROOM_PORT_START: "19412",
      ROOM_PORT_END: "19415",
      WARM_STANDBY_ROOMS: "0",
      STREAMING_ENABLED: "1",
      STREAM_MAX_ACTIVE: "1",
      STREAM_FRAME_MAX_BYTES: "2400000",
      STREAM_FRAME_BUFFER_MAX: "8",
      STREAM_FRAME_BUFFER_MS: "60",
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
      player: "HTTPMJPEG",
      room: "http-mjpeg-smoke",
      version: "2.0.30-stream-smoke",
      protocol: "frame-mjpeg",
      streamWidth: 640,
      streamHeight: 360,
      streamFps: 60,
      streamQuality: 0.58,
      streamBitrate: 3600000,
      bufferMs: 60
    });
    assert.strictEqual(created.status, 201, output || created.body.toString("utf8"));
    const stream = JSON.parse(created.body.toString("utf8"));
    assert(stream.mjpegPublishUrl, "mjpegPublishUrl should be returned");

    viewer = openMjpegViewer(port, stream.id);
    await sleep(250);
    const ffmpeg = spawn("ffmpeg", [
      "-hide_banner", "-loglevel", "error",
      "-re", "-f", "lavfi", "-i", "testsrc2=size=640x360:rate=60",
      "-t", "5",
      "-c:v", "mjpeg",
      "-q:v", "4",
      "-f", "mpjpeg",
      "-boundary_tag", "ruptura-frame",
      stream.mjpegPublishUrl
    ], { stdio: ["ignore", "pipe", "pipe"] });
    let ffmpegOutput = "";
    ffmpeg.stdout.on("data", (chunk) => { ffmpegOutput += chunk; });
    ffmpeg.stderr.on("data", (chunk) => { ffmpegOutput += chunk; });
    const ffmpegCode = await new Promise((resolve) => ffmpeg.on("exit", resolve));
    await sleep(500);
    const status = await request(port, "GET", `/streams/${stream.id}?format=json`);
    const statusJson = JSON.parse(status.body.toString("utf8"));
    const viewerFrames = viewer.frameCount();
    const viewerFps = viewerFrames / 5.0;

    assert.strictEqual(ffmpegCode, 0, ffmpegOutput);
    assert(statusJson.frameCount >= 290, `server frame count too low: ${statusJson.frameCount}`);
    assert(viewerFps >= 56, `viewer fps too low: ${viewerFps.toFixed(1)}`);
    console.log(
      `HTTP_MJPEG_FFMPEG_SMOKE_OK frameCount=${statusJson.frameCount} ` +
      `server_fps=${statusJson.framesPerSecond || 0} viewer_frames=${viewerFrames} ` +
      `viewer_fps=${viewerFps.toFixed(1)} bytes=${viewer.bytesReceived()}`
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
