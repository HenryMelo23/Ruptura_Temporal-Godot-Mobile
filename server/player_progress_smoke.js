"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { spawn } = require("node:child_process");
const { once } = require("node:events");

async function postJson(base, route, body) {
  const response = await fetch(`${base}${route}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  const payload = await response.json();
  return { status: response.status, payload };
}

async function run() {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "ruptura-progress-"));
  const port = 18207;
  const child = spawn(process.execPath, [path.join(__dirname, "relay_manager.js")], {
    env: {
      ...process.env,
      PORT: String(port),
      WARM_STANDBY_ROOMS: "0",
      STREAMING_ENABLED: "0",
      PLAYER_PROGRESS_PATH: path.join(directory, "player_progress.json"),
      LEADERBOARD_PATH: path.join(directory, "leaderboard_runs.json"),
      RUN_SECURITY_PATH: path.join(directory, "leaderboard_security.json")
    },
    stdio: ["ignore", "pipe", "pipe"]
  });
  let output = "";
  child.stdout.on("data", data => { output += data; });
  child.stderr.on("data", data => { output += data; });
  const closed = once(child, "exit");
  const base = `http://127.0.0.1:${port}`;
  try {
    let healthy = false;
    for (let i = 0; i < 50; i++) {
      try { healthy = (await fetch(`${base}/health`)).ok; } catch {}
      if (healthy) break;
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    assert.equal(healthy, true, output);

    const created = await postJson(base, "/players/identity/create", { nickname: "QA", profile_id: "local-file-id", version_code: 24100 });
    assert.equal(created.status, 201);
    assert.equal(created.payload.ok, true);
    assert.ok(created.payload.player_id);
    assert.ok(created.payload.auth_token);
    assert.ok(created.payload.recovery_code);
    assert.ok(created.payload.unlocks.unlocked.includes("Speed Boost"));
    assert.ok(created.payload.unlocks.unlocked_manifestations.includes("eletrica"));

    const player_id = created.payload.player_id;
    const auth_token = created.payload.auth_token;
    const recovery_code = created.payload.recovery_code;
    const event = {
      schema_version: 1,
      event_version: 1,
      event_id: "event_enemy_kills_180",
      type: "unlock_progress",
      metric: "enemy_kills",
      amount: 180,
      max_mode: false,
      version_code: 24100
    };
    const synced = await postJson(base, "/players/unlocks/events", { player_id, auth_token, events: [event] });
    assert.equal(synced.status, 200);
    assert.deepEqual(synced.payload.accepted_event_ids, ["event_enemy_kills_180"]);
    assert.ok(synced.payload.unlocks.unlocked.includes("Poison"));
    assert.equal(synced.payload.unlocks.progress.enemy_kills, 180);

    const duplicated = await postJson(base, "/players/unlocks/events", { player_id, auth_token, events: [event] });
    assert.equal(duplicated.status, 200);
    assert.deepEqual(duplicated.payload.duplicate_event_ids, ["event_enemy_kills_180"]);
    assert.equal(duplicated.payload.unlocks.progress.enemy_kills, 180);

    const tampered = await postJson(base, "/players/unlocks/events", {
      player_id,
      auth_token: "token_from_tampered_local_file",
      events: [{ ...event, event_id: "tampered_local_cache", amount: 980 }]
    });
    assert.equal(tampered.status, 401);

    const impossible = await postJson(base, "/players/unlocks/events", {
      player_id,
      auth_token,
      events: [{ ...event, event_id: "impossible_jump", amount: 999999 }]
    });
    assert.equal(impossible.status, 200);
    assert.deepEqual(impossible.payload.rejected_event_ids, ["impossible_jump"]);
    assert.equal(impossible.payload.unlocks.progress.enemy_kills, 180);

    const offlineQueued = {
      schema_version: 1,
      event_version: 1,
      event_id: "offline_then_online_70",
      type: "unlock_progress",
      metric: "enemy_kills",
      amount: 70,
      max_mode: false,
      version_code: 24100
    };
    const offlineSynced = await postJson(base, "/players/unlocks/events", { player_id, auth_token, events: [offlineQueued] });
    assert.equal(offlineSynced.status, 200);
    assert.ok(offlineSynced.payload.unlocks.unlocked_manifestations.includes("lacerante"));

    const claimed = await postJson(base, "/players/identity/claim", { recovery_code, nickname: "QA reinstall", version_code: 24100 });
    assert.equal(claimed.status, 200);
    assert.equal(claimed.payload.player_id, player_id);
    assert.ok(claimed.payload.auth_token);
    assert.ok(claimed.payload.unlocks.unlocked.includes("Poison"));
    assert.ok(claimed.payload.unlocks.unlocked_manifestations.includes("lacerante"));
    assert.equal(claimed.payload.unlocks.progress.enemy_kills, 250);

    console.log("PLAYER_PROGRESS_OK create=true restart=true reinstall_claim=true tamper_rejected=true duplicate_idempotent=true offline_queue=true");
  } finally {
    child.kill();
    await closed;
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

run().catch(error => { console.error(error); process.exitCode = 1; });
