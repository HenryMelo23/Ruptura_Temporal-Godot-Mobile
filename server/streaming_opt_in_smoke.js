"use strict";

const assert = require("assert");
const http = require("http");
const { spawn } = require("child_process");

const port = 18093;

function request(method, route, body = null, headers = {}) {
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

async function waitForHealth() {
  let lastError = null;
  for (let attempt = 0; attempt < 40; attempt += 1) {
    try {
      const response = await request("GET", "/health");
      if (response.status === 200) return;
    } catch (error) {
      lastError = error;
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw lastError || new Error("relay did not become healthy");
}

async function run() {
  const child = spawn(process.execPath, ["relay_manager.js"], {
    cwd: __dirname,
    env: {
      ...process.env,
      PORT: String(port),
      ROOM_HOST: "127.0.0.1",
      ROOM_PORT_START: "19222",
      ROOM_PORT_END: "19225",
      WARM_STANDBY_ROOMS: "0",
      STREAMING_ENABLED: "1",
      STREAM_MAX_ACTIVE: "1",
      STREAM_FRAME_MAX_BYTES: "1024",
      STREAM_FRAME_BUFFER_MAX: "2",
      STREAM_FRAME_BUFFER_MS: "120",
      STREAM_MANAGER_PUBLIC_BASE_URL: `http://127.0.0.1:${port}`,
      ALLOW_LOCAL_PUBLIC_BASE_URL: "1"
    },
    stdio: ["ignore", "pipe", "pipe"]
  });
  let output = "";
  child.stdout.on("data", (chunk) => { output += chunk; });
  child.stderr.on("data", (chunk) => { output += chunk; });
  try {
    await waitForHealth();
    const created = await request("POST", "/streams", {
      player: "QA",
      room: "smoke",
      version: "smoke",
      protocol: "frame-mjpeg",
      streamWidth: 4096,
      streamHeight: 2160,
      streamFps: 120,
      streamQuality: 0.99,
      streamBitrate: 9000000,
      bufferMs: 900
    });
    assert.strictEqual(created.status, 201, output);
    const stream = JSON.parse(created.body.toString("utf8"));
    assert.strictEqual(stream.streamWidth, 1280, "width should be clamped");
    assert.strictEqual(stream.streamHeight, 720, "height should be clamped");
    assert.strictEqual(stream.streamFps, 60, "fps should be clamped");
    assert.strictEqual(stream.streamBitrate, 9000000, "bitrate should accept high quality requests");
    assert(stream.viewerUrl.includes(`127.0.0.1:${port}/streams/`), "viewer URL should use public manager base");

    const second = await request("POST", "/streams", { player: "QA2" });
    assert.strictEqual(second.status, 429, "capacity limit should refuse a second active stream");

    const frame = await request("POST", `/streams/${stream.id}/frame`, Buffer.from([0xff, 0xd8, 0xff, 0xd9]), { "X-Frame-Seq": "1" });
    assert.strictEqual(frame.status, 202, "small frame should be accepted");
    const latest = await request("GET", `/streams/${stream.id}/frame`);
    assert.strictEqual(latest.status, 200, "latest frame should be readable");
    assert.strictEqual(latest.headers["x-accel-buffering"], "no", "latest frame should disable proxy buffering");

    const tooLarge = await request("POST", `/streams/${stream.id}/frame`, Buffer.alloc(2048, 1), { "X-Frame-Seq": "2" });
    assert.strictEqual(tooLarge.status, 413, "oversized frames should be rejected");

    const closed = await request("DELETE", `/streams/${stream.id}`);
    assert.strictEqual(closed.status, 200, "stream should close cleanly");
    const missing = await request("GET", `/streams/${stream.id}`);
    assert.strictEqual(missing.status, 404, "closed stream should disappear");

    const native = await request("POST", "/streams", {
      player: "AndroidQA",
      room: "android-smoke",
      version: "smoke",
      protocol: "rtmp-hls",
      streamWidth: 640,
      streamHeight: 360,
      streamFps: 60,
      streamBitrate: 1600000
    });
    assert.strictEqual(native.status, 201, output || native.body.toString("utf8"));
    const nativeStream = JSON.parse(native.body.toString("utf8"));
    assert.strictEqual(nativeStream.protocol, "rtmp-hls", "native stream should keep RTMP/HLS protocol");
    assert(nativeStream.rtmpPublishUrl.endsWith(`/live/${nativeStream.id}`), "native publish URL should target RTMP live path");
    assert(nativeStream.hlsUrl.endsWith(`/live/${nativeStream.id}/`), "native HLS URL should point to MediaMTX player path");
    assert(nativeStream.hlsPlaylistUrl.endsWith(`/live/${nativeStream.id}/index.m3u8`), "native playlist URL should remain available for diagnostics");
    assert(nativeStream.webrtcUrl.endsWith(`/live/${nativeStream.id}/`), "native WebRTC URL should point to MediaMTX player path");
    assert.strictEqual(nativeStream.watchUrl, nativeStream.hlsUrl, "Android should probe the playable media page");
    await request("DELETE", `/streams/${nativeStream.id}`);

    console.log("STREAMING_OPT_IN_SMOKE_OK clamp=true capacity=true frame=true close=true");
  } finally {
    child.kill("SIGTERM");
    await new Promise((resolve) => setTimeout(resolve, 150));
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
