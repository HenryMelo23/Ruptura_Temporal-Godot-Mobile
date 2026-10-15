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

    assert.match(created.payload.recovery_code, /^(?:[0-9A-F]{4}-){7}[0-9A-F]{4}$/);
    assert.ok(created.payload.unlocks.unlocked.includes("Speed Boost"));
    assert.ok(created.payload.unlocks.unlocked_manifestations.includes("eletrica"));

    const player_id = created.payload.player_id;
    const auth_token = created.payload.auth_token;
    const recovery_code = created.payload.recovery_code;
    const event = {
      schema_version: 2,
      event_version: 2,
      event_id: "event_enemy_kills_180",
      client_sequence: 1,
      device_id: "ppd_smoke_device",
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
      events: [{ ...event, event_id: "impossible_jump", client_sequence: 2, amount: 999999 }]
    });
    assert.equal(impossible.status, 200);
    assert.deepEqual(impossible.payload.rejected_event_ids, ["impossible_jump"]);
    assert.deepEqual(impossible.payload.rejected_events, [{ event_id: "impossible_jump", reason: "invalid_metric_amount", permanent: true }]);
    assert.equal(impossible.payload.unlocks.progress.enemy_kills, 180);

    const reordered = await postJson(base, "/players/unlocks/events", {
      player_id,
      auth_token,
      events: [{ ...event, event_id: "out_of_order", client_sequence: 9, amount: 1 }]
    });
    assert.equal(reordered.status, 200);
    assert.deepEqual(reordered.payload.rejected_events, [{ event_id: "out_of_order", reason: "event_sequence_mismatch", permanent: true }]);

    const offlineQueued = {
      schema_version: 2,
      event_version: 2,
      event_id: "offline_then_online_70",
      client_sequence: 2,
      device_id: "ppd_smoke_device",
      type: "unlock_progress",
      metric: "enemy_kills",
      amount: 70,
      max_mode: false,
      version_code: 24100
    };
    const offlineSynced = await postJson(base, "/players/unlocks/events", { player_id, auth_token, events: [offlineQueued] });
    assert.equal(offlineSynced.status, 200);
    assert.ok(offlineSynced.payload.unlocks.unlocked_manifestations.includes("lacerante"));
    const backup = JSON.parse(fs.readFileSync(`${path.join(directory, "player_progress.json")}.bak`, "utf8"));
    assert.ok(backup.identities[player_id], "atomic backup did not preserve a valid prior snapshot");

    const wrongRecovery = await postJson(base, "/players/identity/claim", { recovery_code: "not-a-real-code", version_code: 24100 });
    assert.equal(wrongRecovery.status, 401);
    assert.equal(wrongRecovery.payload.error, "recovery unavailable");

    const claimed = await postJson(base, "/players/identity/claim", { recovery_code, nickname: "QA reinstall", version_code: 24100 });
    assert.equal(claimed.status, 200);
    assert.equal(claimed.payload.player_id, player_id);
    assert.ok(claimed.payload.auth_token);
    assert.ok(claimed.payload.unlocks.unlocked.includes("Poison"));
    assert.ok(claimed.payload.unlocks.unlocked_manifestations.includes("lacerante"));
    assert.equal(claimed.payload.unlocks.progress.enemy_kills, 250);

    console.log("PLAYER_PROGRESS_OK create=true restart=true reinstall_claim=true tamper_rejected=true duplicate_idempotent=true ordering=true backup=true offline_queue=true");
  } finally {
    child.kill();
    await closed;
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

async function runProtectedCorruptionTest() {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "ruptura-progress-corrupt-"));
  const storePath = path.join(directory, "player_progress.json");
  const corrupt = "{this is intentionally not valid json";
  fs.writeFileSync(storePath, corrupt);
  fs.writeFileSync(`${storePath}.bak`, corrupt);
  const port = 18208;
  const child = spawn(process.execPath, [path.join(__dirname, "relay_manager.js")], {
    env: {
      ...process.env,
      PORT: String(port), WARM_STANDBY_ROOMS: "0", STREAMING_ENABLED: "0",
      PLAYER_PROGRESS_PATH: storePath,
      LEADERBOARD_PATH: path.join(directory, "leaderboard_runs.json"),
      RUN_SECURITY_PATH: path.join(directory, "leaderboard_security.json")
    },
    stdio: ["ignore", "pipe", "pipe"]
  });
  const closed = once(child, "exit");
  const base = `http://127.0.0.1:${port}`;
  try {
    let ready = false;
    for (let i = 0; i < 50; i++) {
      try { ready = (await fetch(`${base}/health`)).ok; } catch {}
      if (ready) break;
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    assert.equal(ready, true, "corruption fixture relay did not start");
    const create = await postJson(base, "/players/identity/create", { nickname: "must not overwrite", version_code: 24100 });
    assert.equal(create.status, 503);
    const health = await (await fetch(`${base}/health`)).json();
    assert.equal(health.playerProgressStore, "protected_read_only");
    assert.equal(fs.readFileSync(storePath, "utf8"), corrupt, "corrupt primary was overwritten");
    assert.equal(fs.readFileSync(`${storePath}.bak`, "utf8"), corrupt, "corrupt backup was overwritten");
    console.log("PLAYER_PROGRESS_CORRUPTION_OK protected_read_only=true no_overwrite=true");
  } finally {
    child.kill();
    await closed;
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

async function runBackupRecoveryTest() {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "ruptura-progress-backup-"));
  const storePath = path.join(directory, "player_progress.json");
  const startRelay = port => spawn(process.execPath, [path.join(__dirname, "relay_manager.js")], {
    env: {
      ...process.env,
      PORT: String(port), WARM_STANDBY_ROOMS: "0", STREAMING_ENABLED: "0",
      PLAYER_PROGRESS_PATH: storePath,
      LEADERBOARD_PATH: path.join(directory, "leaderboard_runs.json"),
      RUN_SECURITY_PATH: path.join(directory, "leaderboard_security.json")
    },
    stdio: ["ignore", "pipe", "pipe"]
  });
  const waitReady = async base => {
    for (let i = 0; i < 50; i++) {
      try { if ((await fetch(`${base}/health`)).ok) return; } catch {}
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    assert.fail("backup recovery relay did not start");
  };
  let child = startRelay(18209);
  let closed = once(child, "exit");
  try {
    const firstBase = "http://127.0.0.1:18209";
    await waitReady(firstBase);
    const created = await postJson(firstBase, "/players/identity/create", { nickname: "backup", version_code: 24100 });
    assert.equal(created.status, 201);
    const event = {
      schema_version: 2, event_version: 2, event_id: "backup_seed", client_sequence: 1, device_id: "backup_device",
      type: "unlock_progress", metric: "enemy_kills", amount: 1, max_mode: false, version_code: 24100
    };
    const seeded = await postJson(firstBase, "/players/unlocks/events", { player_id: created.payload.player_id, auth_token: created.payload.auth_token, events: [event] });
    assert.equal(seeded.status, 200);
    assert.ok(fs.existsSync(`${storePath}.bak`), "valid backup was not written");
    child.kill();
    await closed;
    fs.writeFileSync(storePath, "{corrupt primary after restart");

    child = startRelay(18210);
    closed = once(child, "exit");
    const recoveredBase = "http://127.0.0.1:18210";
    await waitReady(recoveredBase);
    const probe = await postJson(recoveredBase, "/players/unlocks/events", { player_id: "invalid", auth_token: "invalid", events: [] });
    assert.equal(probe.status, 401);
    const recoveredHealth = await (await fetch(`${recoveredBase}/health`)).json();
    assert.equal(recoveredHealth.playerProgressStore, "recovered_backup");
    const restored = await postJson(recoveredBase, "/players/identity/claim", { recovery_code: created.payload.recovery_code, version_code: 24100 });
    assert.equal(restored.status, 200, "valid backup could not recover profile after restart");
    assert.equal(restored.payload.player_id, created.payload.player_id);
    const health = await (await fetch(`${recoveredBase}/health`)).json();
    assert.equal(health.playerProgressStore, "healthy");
    assert.doesNotThrow(() => JSON.parse(fs.readFileSync(storePath, "utf8")), "recovered primary was not rebuilt atomically");
    assert.doesNotThrow(() => JSON.parse(fs.readFileSync(`${storePath}.bak`, "utf8")), "backup was replaced by corrupt primary");
    console.log("PLAYER_PROGRESS_BACKUP_OK restart=true recovery=true backup_preserved=true");
  } finally {
    if (!child.killed) child.kill();
    await closed;
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

run().then(runProtectedCorruptionTest).then(runBackupRecoveryTest).catch(error => { console.error(error); process.exitCode = 1; });
