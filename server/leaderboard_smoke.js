"use strict";

const assert = require("assert");
const fs = require("fs");
const http = require("http");
const path = require("path");
const { spawn } = require("child_process");

const port = 18090;
const projectPath = path.resolve(__dirname, "..");
const logDir = path.join(projectPath, ".agent_logs");
const storePath = path.join(logDir, "leaderboard_smoke_runs.json");
const updateRoot = path.join(logDir, "android_update_smoke");
fs.mkdirSync(logDir, { recursive: true });
if (fs.existsSync(storePath)) fs.rmSync(storePath, { force: true });
fs.rmSync(updateRoot, { recursive: true, force: true });
fs.mkdirSync(updateRoot, { recursive: true });
const fakeApk = Buffer.from("RUPTURA_ANDROID_UPDATE_SMOKE");
const fakeApkName = "ruptura_temporal_2.0.27_smoke.apk";
fs.writeFileSync(path.join(updateRoot, fakeApkName), fakeApk);
fs.writeFileSync(path.join(updateRoot, "latest.json"), JSON.stringify({
  version: "2.0.27",
  version_code: 227,
  filename: fakeApkName,
  sha256: require("crypto").createHash("sha256").update(fakeApk).digest("hex"),
  notes: ["Atualizador smoke"],
  mandatory: false,
  published_at: "2026-07-16T12:00:00Z"
}));

function request(method, route, body = null) {
  return new Promise((resolve, reject) => {
    const data = body == null ? null : Buffer.from(typeof body === "string" ? body : JSON.stringify(body));
    const req = http.request({ hostname: "127.0.0.1", port, path: route, method, headers: data ? { "Content-Type": "application/json", "Content-Length": data.length } : {} }, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => resolve({ status: res.statusCode, headers: res.headers, body: Buffer.concat(chunks) }));
    });
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

function assertCleanHtml(label, html) {
  assert(!html.includes("undefined"), `${label} contains undefined`);
  assert(!html.includes("NaN"), `${label} contains NaN`);
  assert(!html.includes("[object Object]"), `${label} contains object string`);
  assert(!/C:\\Users/i.test(html), `${label} exposes a local Windows path`);
  assert(!/href="[^"]*undefined/i.test(html), `${label} contains undefined link`);
  assert(!/src="[^"]*undefined/i.test(html), `${label} contains undefined image`);
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
      WARM_STANDBY_ROOMS: "0",
      PROJECT_PATH: projectPath,
      LEADERBOARD_PATH: storePath,
      ANDROID_UPDATE_ROOT: updateRoot,
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
    const health = JSON.parse((await request("GET", "/health")).body.toString("utf8"));
    assert.strictEqual(health.streaming, false, "streaming should be disabled by default");
    assert.deepStrictEqual(health.protocols, [], "stream protocols should not be advertised");
    const removedStream = await request("POST", "/streams", { player: "QA", room: "removed" });
    assert.strictEqual(removedStream.status, 410, "removed stream endpoint should return 410");
    assert(JSON.parse(removedStream.body.toString("utf8")).error.includes("streaming disabled"), "removed stream response should explain the disabled state");
    const emptyHome = (await request("GET", "/leaderboard")).body.toString("utf8");
    assert(emptyHome.includes("CENTRAL DO OBSERVATORIO") && emptyHome.includes("NENHUMA EXPEDICAO SINCRONIZADA"), "empty dashboard state missing");
    assertCleanHtml("empty home", emptyHome);
    const payload = {
      player: "DashboardQA",
      profile_id: "dashboard-qa",
      version: "2.0.27",
      platform: "Windows",
      result: "Derrota",
      ended_unix: 1784187000,
      duration_seconds: 333,
      phase: 3,
      kills: 118,
      leaderboard_score: 3810,
      boss_damage_total: 4232,
      enemy_damage_total: 14000,
      damage_taken_total: 870,
      manifestation: "Ancorada",
      spectrum: "Sanguinaria",
      cards_total: 2,
      cards_detail: [{ id: "Porcao", name: "Porcao", count: 1 }, { id: "Defesa", name: "Defesa", count: 1 }],
      damage_taken_detail: [{ kind: "espreitador", name: "Espreitador", icon: "espreitador1.png", phase: 1, damage: 570, hits: 8 }],
      damage_events: [{ x: 0.5, y: 0.5, amount: 70, source: "espreitador", name: "Espreitador", time: 50, phase: 1 }],
      position_heatmap: { columns: 16, rows: 9, cells: [{ phase: 1, x: 8, y: 4, count: 30 }] },
      boss_detail: [{ phase: 1, reached: true, duration: "00:20", damage: 4232 }]
    };
    const created = await request("POST", "/runs", payload);
    assert.strictEqual(created.status, 201);
    const createdPayload = JSON.parse(created.body.toString("utf8"));
    const stored = createdPayload.run;
    assert.strictEqual(createdPayload.runUrl, `http://127.0.0.1:${port}/leaderboard/run/${stored.id}`, "run URL should point to the exact run");
    const home = (await request("GET", "/leaderboard")).body.toString("utf8");
    const profile = (await request("GET", `/leaderboard/player/${encodeURIComponent(stored.profileKey)}`)).body.toString("utf8");
    const rankings = (await request("GET", "/leaderboard/rankings")).body.toString("utf8");
    const summary = (await request("GET", `/leaderboard/run/${stored.id}`)).body.toString("utf8");
    const missing = (await request("GET", "/leaderboard/linha-inexistente")).body.toString("utf8");
    assert(home.includes("CENTRAL DO OBSERVATORIO") && home.includes("Maior dano em boss") && home.includes("4.232"), "dashboard metrics missing");
    assert(home.includes("OPERADOR EM DESTAQUE") && home.includes("Expedicoes recentes") && home.includes("Buscar operador"), "dashboard observatory shell missing");
    assert(profile.includes("DOSSIE DO OPERADOR") && profile.includes("Build mais usada") && profile.includes("Ancorada + Sanguinaria"), "player profile missing");
    assert(rankings.includes("MATRIZ COMPETITIVA") && rankings.includes("Plano cartesiano") && rankings.includes("Maior progressao"), "ranking charts missing");
    assert(summary.includes("RELATORIO DE EXPEDICAO") && summary.includes("Mapa de calor e dano") && summary.includes("Espreitador") && summary.includes("16/07/2026"), "run summary telemetry or date missing");
    assert(missing.includes("LINHA TEMPORAL NAO LOCALIZADA") && missing.includes("Voltar ao observatorio"), "not found page missing");
    for (const [label, html] of [["home", home], ["profile", profile], ["rankings", rankings], ["summary", summary], ["missing", missing]]) {
      assertCleanHtml(label, html);
    }
    const cardMatch = home.match(/src="([^"]*carta_por1\.png)"/i);
    assert(cardMatch, "card catalog fallback did not resolve the sprite");
    const asset = await request("GET", cardMatch[1].replace(/&amp;/g, "&"));
    assert.strictEqual(asset.status, 200, "resolved card sprite was not served");
    assert(String(asset.headers["content-type"]).startsWith("image/"), "sprite response is not an image");
    const update = await request("GET", "/updates/android/latest?version_code=226");
    assert.strictEqual(update.status, 200, "update manifest endpoint failed");
    const updatePayload = JSON.parse(update.body.toString("utf8"));
    assert.strictEqual(updatePayload.available, true, "newer Android version was not offered");
    assert.strictEqual(updatePayload.version_code, 227, "wrong Android version code");
    const noUpdate = JSON.parse((await request("GET", "/updates/android/latest?version_code=227")).body.toString("utf8"));
    assert.strictEqual(noUpdate.available, false, "current Android version should not update itself");
    const ranged = await new Promise((resolve, reject) => {
      const req = http.request({ hostname: "127.0.0.1", port, path: new URL(updatePayload.apk_url).pathname, method: "GET", headers: { Range: "bytes=0-7" } }, (res) => {
        const chunks = [];
        res.on("data", (chunk) => chunks.push(chunk));
        res.on("end", () => resolve({ status: res.statusCode, headers: res.headers, body: Buffer.concat(chunks) }));
      });
      req.on("error", reject);
      req.end();
    });
    assert.strictEqual(ranged.status, 206, "APK range download was not honored");
    assert.strictEqual(ranged.body.length, 8, "APK range returned the wrong byte count");
    console.log("LEADERBOARD_SMOKE_OK dashboard=true profile=true rankings=true run_heatmap=true sprites=true updater=true range=true port=18090");
  } finally {
    child.kill("SIGTERM");
    await new Promise((resolve) => child.once("exit", resolve));
    if (output.includes("Error:") || output.includes("Unhandled")) process.stderr.write(output);
  }
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
