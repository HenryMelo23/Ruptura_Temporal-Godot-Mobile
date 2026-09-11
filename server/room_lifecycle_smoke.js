"use strict";

const assert = require("assert");
const fs = require("fs");
const http = require("http");
const path = require("path");
const { spawn } = require("child_process");

const port = 18092;
const projectPath = path.resolve(__dirname, "..");
const logDir = path.join(projectPath, ".agent_logs");
const fakeScript = path.join(logDir, "fake_godot_room.js");

fs.mkdirSync(logDir, { recursive: true });
fs.writeFileSync(fakeScript, `
const dgram = require("dgram");
const portArg = process.argv.find((arg) => arg.startsWith("--port="));
const port = Number(portArg ? portArg.slice("--port=".length) : 0);
if (!port) process.exit(2);
const socket = dgram.createSocket("udp4");
socket.bind(port, "0.0.0.0", () => console.log("ONLINE ROOM FAKE READY " + port));
process.on("SIGTERM", () => socket.close(() => process.exit(0)));
setInterval(() => {}, 1000);
`);

function request(method, route, body = null) {
  return new Promise((resolve, reject) => {
    const data = body == null ? null : Buffer.from(JSON.stringify(body));
    const req = http.request({
      hostname: "127.0.0.1",
      port,
      path: route,
      method,
      headers: data ? { "Content-Type": "application/json", "Content-Length": data.length } : {}
    }, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => resolve({ status: res.statusCode, body: Buffer.concat(chunks) }));
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
      ROOM_IDLE_MS: "600",
      ROOM_PORT_START: "19192",
      ROOM_PORT_END: "19195",
      ROOM_READY_TIMEOUT_MS: "2500",
      WARM_STANDBY_ROOMS: "0",
      GODOT_BIN: fakeScript,
      PROJECT_PATH: projectPath,
      STREAMING_ENABLED: "0",
      ALLOW_LOCAL_PUBLIC_BASE_URL: "1"
    },
    stdio: ["ignore", "pipe", "pipe"]
  });
  let output = "";
  child.stdout.on("data", (chunk) => { output += chunk; });
  child.stderr.on("data", (chunk) => { output += chunk; });
  try {
    await waitForHealth();
    const created = await request("POST", "/rooms", { name: "HeartbeatHost", roomName: "Sala QA", password: "d37" });
    assert.strictEqual(created.status, 201, output);
    const room = JSON.parse(created.body.toString("utf8"));
    assert(room.code && room.port, "room creation did not return code/port");
    assert.strictEqual(room.name, "Sala QA", "room name was not preserved");
    assert.strictEqual(room.locked, true, "password room should be marked as locked");
    const listed = await request("GET", "/rooms");
    assert.strictEqual(listed.status, 200, output);
    const listedBody = JSON.parse(listed.body.toString("utf8"));
    assert(listedBody.rooms.some((entry) => entry.code === room.code && entry.name === "Sala QA" && entry.locked === true), "locked named room was not visible in list");
    const rejectedJoin = await request("POST", `/rooms/${room.code}/join`, { name: "Intruso" });
    assert.strictEqual(rejectedJoin.status, 403, "locked room accepted a missing password");
    const acceptedJoin = await request("POST", `/rooms/${room.code}/join`, { name: "ClientQA", password: "d37" });
    assert.strictEqual(acceptedJoin.status, 200, "locked room rejected the correct password\n" + output);
    await new Promise((resolve) => setTimeout(resolve, 350));
    const hb1 = await request("POST", `/rooms/${room.code}/heartbeat`, { role: "owner", mode: "game", peer_id: 1 });
    assert.strictEqual(hb1.status, 200, output);
    await new Promise((resolve) => setTimeout(resolve, 350));
    const hb2 = await request("POST", `/rooms/${room.code}/heartbeat`, { role: "client", mode: "game", peer_id: 2 });
    assert.strictEqual(hb2.status, 200, output);
    const alive = await request("GET", `/rooms/${room.code}`);
    assert.strictEqual(alive.status, 200, "room died even with heartbeats\n" + output);
    const aliveRoom = JSON.parse(alive.body.toString("utf8"));
    assert(aliveRoom.heartbeatCount >= 2, "heartbeat count did not advance");
    await new Promise((resolve) => setTimeout(resolve, 5400));
    const expired = await request("GET", `/rooms/${room.code}`);
    assert.strictEqual(expired.status, 404, "abandoned room should expire after idle window");
    assert(output.includes("kind=heartbeat"), "heartbeat event was not logged");
    console.log("ROOM_LIFECYCLE_SMOKE_OK");
  } finally {
    child.kill("SIGTERM");
    await new Promise((resolve) => setTimeout(resolve, 150));
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
