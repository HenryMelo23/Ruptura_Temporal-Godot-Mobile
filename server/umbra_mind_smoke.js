"use strict";

const assert = require("assert");
const fs = require("fs");
const http = require("http");
const path = require("path");
const { spawn } = require("child_process");

const port = 18096;
const projectPath = path.resolve(__dirname, "..");
const storePath = path.join(projectPath, ".agent_logs", "umbra_mind_smoke_store.json");
fs.mkdirSync(path.dirname(storePath), { recursive: true });
fs.writeFileSync(storePath, JSON.stringify({
  profiles: {},
  runs: [{
    player: "PrivateQA", profileId: "private-qa", rankEligible: true, umbraTrainingEligible: true,
    durationSeconds: 480, damageTaken: 900,
    behaviorMetrics: { phase1Seconds: 330, edgeRatio: 0.12, cornerRatio: 0.02, centerRatio: 0.31, dashPerMinute: 4.2, shotsPerMinute: 46, hitRate: 0.55, stationaryRatio: 0.1 },
    umbraKnowledge: {
      schemaVersion: 1, totalPercent: 68, archetype: "CORREDOR_CIRCULAR", sampleSeconds: 480, phasesObserved: 3,
      categories: { movement: { percent: 82 }, shooting: { percent: 71 }, choices: { percent: 64 }, preferences: { percent: 73 }, weaknesses: { percent: 50 } }
    }
  }]
}, null, 2));

function request(route) {
  return new Promise((resolve, reject) => {
    const req = http.get({ hostname: "127.0.0.1", port, path: route }, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => resolve({ status: res.statusCode, body: Buffer.concat(chunks).toString("utf8") }));
    });
    req.on("error", reject);
  });
}

async function waitForHealth() {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    try {
      if ((await request("/health")).status === 200) return;
    } catch (_error) {}
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error("relay did not become healthy");
}

async function run() {
  const child = spawn(process.execPath, ["relay_manager.js"], {
    cwd: __dirname,
    env: { ...process.env, PORT: String(port), WARM_STANDBY_ROOMS: "0", PROJECT_PATH: projectPath, LEADERBOARD_PATH: storePath, ALLOW_LOCAL_PUBLIC_BASE_URL: "1", STREAM_MANAGER_PUBLIC_BASE_URL: `http://127.0.0.1:${port}` },
    stdio: ["ignore", "pipe", "pipe"]
  });
  try {
    await waitForHealth();
    const response = await request("/umbra/mind/latest?profile_id=private-qa&current=stale");
    assert.strictEqual(response.status, 200);
    const payload = JSON.parse(response.body);
    const dossierPayload = payload.files["umbra_player_dossiers.json"];
    assert.strictEqual(dossierPayload.schema_version, 2);
    assert.strictEqual(dossierPayload.players, undefined, "complete dossier map leaked");
    assert(dossierPayload.selected, "selected private dossier missing");
    assert.strictEqual(dossierPayload.selected.player, undefined, "player name leaked");
    assert.strictEqual(dossierPayload.selected.profile_key, undefined, "profile key leaked");
    assert.strictEqual(dossierPayload.selected.knowledge.total_percent, 68);
    assert(Object.keys(dossierPayload.cohorts).includes("CORREDOR_CIRCULAR"));
    console.log("UMBRA_MIND_SERVER_OK schema=2 selected_only=true cohorts=anonymous knowledge=5");
  } finally {
    child.kill("SIGTERM");
    fs.rmSync(storePath, { force: true });
  }
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
