"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { spawn } = require("node:child_process");
const { once } = require("node:events");

async function run() {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "ruptura-content-"));
  const packs = ["android", "windows"].map(platform => {
    const filename = `${platform}.pck`;
    fs.writeFileSync(path.join(directory, filename), "fixture");
    return { filename, platform, required_game_version_code: 24100, sha256: "a".repeat(64), signature: "fixture" };
  });
  fs.writeFileSync(path.join(directory, "latest.json"), JSON.stringify({ content_version_code: 1, packs }));
  const port = 18196;
  const child = spawn(process.execPath, [path.join(__dirname, "relay_manager.js")], {
    env: { ...process.env, PORT: String(port), WARM_STANDBY_ROOMS: "0", STREAMING_ENABLED: "0", CONTENT_UPDATE_ROOT: directory },
    stdio: ["ignore", "pipe", "pipe"]
  });
  let output = "";
  child.stdout.on("data", data => { output += data; });
  child.stderr.on("data", data => { output += data; });
  const closed = once(child, "exit");
  const endpoint = `http://127.0.0.1:${port}/updates/content/latest`;
  try {
    let healthy = false;
    for (let i = 0; i < 50; i++) {
      try { healthy = (await fetch(endpoint)).ok; } catch {}
      if (healthy) break;
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    assert(healthy, output);
    for (const platform of ["android", "windows"]) {
      const data = await (await fetch(`${endpoint}?version_code=24100&platform=${platform}`)).json();
      assert.equal(data.available, true);
      assert.equal(data.packs.length, 1);
      assert.equal(data.packs[0].platform, platform);
      assert.equal(data.packs[0].signature, "fixture");
    }
    for (const query of ["version_code=24099&platform=android", "version_code=24101&platform=android", "version_code=24100", "version_code=24100&platform=android&content_version_code=1"]) {
      const data = await (await fetch(`${endpoint}?${query}`)).json();
      assert.equal(data.available, false);
    }
    const partial = await fetch(`http://127.0.0.1:${port}/updates/content/download/android.pck`, { headers: { Range: "bytes=3-" } });
    assert.equal(partial.status, 206);
    assert.equal(partial.headers.get("accept-ranges"), "bytes");
    assert.equal(partial.headers.get("content-range"), "bytes 3-6/7");
    assert.equal(partial.headers.get("content-length"), "4");
    assert.equal(await partial.text(), "ture");
    const invalidRange = await fetch(`http://127.0.0.1:${port}/updates/content/download/android.pck`, { headers: { Range: "bytes=99-" } });
    assert.equal(invalidRange.status, 416);
    assert.equal(invalidRange.headers.get("content-range"), "bytes */7");
    console.log("CONTENT_SERVER_OK platform=true base=true current=true signature=true range=true");
  } finally {
    child.kill();
    await closed;
    for (const filename of ["latest.json", "android.pck", "windows.pck"]) fs.unlinkSync(path.join(directory, filename));
    fs.rmdirSync(directory);
  }
}
run().catch(error => { console.error(error); process.exitCode = 1; });
