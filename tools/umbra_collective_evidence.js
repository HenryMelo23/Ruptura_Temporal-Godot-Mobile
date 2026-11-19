"use strict";

// Offline fixtures only: no HTTP, relay, ranked submission or production store.
const assert = require("assert");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { normalizeUmbraCombat, createCollective, buildFromState, emptyState } = require("../server/umbra_collective");

function parameterHash(layer) {
  const data = {};
  for (const key of ["schema_version", "features", "weights", "mode", "confidence", "aim_lead", "aim_lead_delta", "skill_priors"]) {
    if (key in layer) data[key] = layer[key];
  }
  return crypto.createHash("sha256").update(JSON.stringify(data)).digest("hex");
}

const [fixturePath, directory] = process.argv.slice(2);
if (!fixturePath || !directory || fs.existsSync(directory)) {
  throw new Error("usage: node tools/umbra_collective_evidence.js combat_fixture.json NEW_DIRECTORY");
}
fs.mkdirSync(directory, { recursive: true });
const raw = JSON.parse(fs.readFileSync(fixturePath, "utf8"));
const normalized = normalizeUmbraCombat(raw);
assert(normalized, "runtime-generated synthetic statistics rejected");
const store = path.join(directory, "synthetic_collective_store.json");
const collective = createCollective(store);
for (let i = 0; i < 32; i++) {
  const run = { id: `synthetic-only-${i}`, rankEligible: true, umbraCombat: normalized };
  assert(collective.ingest(run));
  assert(!collective.ingest(run), "duplicate changed state");
}
const model = collective.build();
const reloaded = createCollective(store).build();
assert.deepStrictEqual(model, reloaded, "persistent accumulator changed after restart");
assert(model.confidence > 0 && Object.keys(model.weights).length >= 2);

// Concrete false-positive witness: a newer collective version can have
// identical inference parameters. Version is derived from counters/lastId.
const state = emptyState();
const before = buildFromState(state);
state.runs = 1;
state.lastId = "metadata-only-fixture";
const after = buildFromState(state);
assert.notStrictEqual(before.collective_version, after.collective_version);
assert.strictEqual(parameterHash(before), parameterHash(after));

const report = {
  evidence_kind: "synthetic_offline_pipeline_contract",
  accepted_fixture: true, persistent_reload_equal: true, duplicate_rejected: true,
  synthetic_runs: model.runs, confidence: model.confidence,
  metadata_false_positive: { version_changed: true, parameters_changed: false,
    before: before.collective_version, after: after.collective_version },
  learning_improvement_proven: false, live_vps_verified: false,
};
fs.writeFileSync(path.join(directory, "collective_layer.json"), JSON.stringify(model, null, 2));
fs.writeFileSync(path.join(directory, "report.json"), JSON.stringify(report, null, 2));
console.log("UMBRA_COLLECTIVE_EVIDENCE_OK " + JSON.stringify(report));
