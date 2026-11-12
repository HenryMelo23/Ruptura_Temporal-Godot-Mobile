"use strict";

// Mente coletiva da UMBRA: validacao do relatorio, acumulo entre partidas,
// regressao global, priors, aim_lead e versao que muda a cada partida.
const assert = require("assert");
const fs = require("fs");
const path = require("path");
const { normalizeUmbraCombat, createCollective, summarizeCombat, FEATURES } = require("./umbra_collective");

const NF = FEATURES.length;
const tmp = path.resolve(__dirname, "..", ".agent_logs", "umbra_collective_smoke.json");
fs.mkdirSync(path.dirname(tmp), { recursive: true });
if (fs.existsSync(tmp)) fs.renameSync(tmp, `${tmp}.old`);

// Gera estatisticas sinteticas: REBOBINAR rende mais quando distance alta,
// ATAQUE rende pouco, ECO rende medio.
function stats(action, n, fn, seed) {
  const xtx = new Array(NF * NF).fill(0);
  const xty = new Array(NF).fill(0);
  let sumY = 0;
  let s = seed;
  const rnd = () => { s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648; };
  for (let k = 0; k < n; k += 1) {
    const f = FEATURES.map((name, i) => (i === 0 ? 1 : rnd()));
    const y = fn(f) + (rnd() - 0.5) * 0.1;
    sumY += y;
    for (let i = 0; i < NF; i += 1) {
      xty[i] += f[i] * y;
      for (let j = 0; j < NF; j += 1) xtx[i * NF + j] += f[i] * f[j];
    }
  }
  return { n, sum_y: sumY, xtx, xty };
}

function report(seed, lead, shots, hits) {
  return {
    schema_version: 1, features: FEATURES, encounter_seconds: 95, outcome: "umbra_defeated",
    mind_version: "umbra-base-r3", aim_lead: lead, plasma: { shots, hits },
    actions: {
      REBOBINAR: stats("REBOBINAR", 30, (f) => 0.2 + 0.8 * f[1], seed),
      ATAQUE: stats("ATAQUE", 60, () => 0.05, seed + 1),
      ECO_PROFETICO: stats("ECO_PROFETICO", 30, () => 0.3, seed + 2)
    },
    skill_priors: { eco_along: [0.6, 8], eco_side: [0.9, 8], rewind_escape: [0.5, 4] }
  };
}

// Validacao
assert.strictEqual(normalizeUmbraCombat(null), null);
assert.strictEqual(normalizeUmbraCombat({ schema_version: 2 }), null, "schema errado aceito");
const bad = report(1, 0.7, 10, 2);
bad.actions.ATAQUE.xtx = [1, 2, 3];
assert.ok(!("ATAQUE" in normalizeUmbraCombat(bad).actions), "xtx de tamanho errado aceito");
const tampered = report(1, 0.7, 10, 2);
tampered.actions.ATAQUE.xtx[0] = 1e9;
assert.ok(!("ATAQUE" in normalizeUmbraCombat(tampered).actions), "valor absurdo aceito");
const clipped = normalizeUmbraCombat({ ...report(1, 5.0, 10, 99), skill_priors: { eco_along: [9, 3] } });
assert.strictEqual(clipped.aimLead, 1.1);
assert.strictEqual(clipped.plasma.hits, 10, "acertos maiores que tiros");
assert.strictEqual(clipped.priors.eco_along[0], 1.4);

// Acumulo
const col = createCollective(tmp);
let lastVersion = col.build().collective_version;
assert.strictEqual(col.build().runs, 0);
for (let r = 0; r < 8; r += 1) {
  const run = { id: `run-${r}`, rankEligible: true, umbraCombat: normalizeUmbraCombat(report(100 + r, 0.65 + (r % 3) * 0.05, 80, 8 + r)) };
  assert.ok(col.ingest(run), "partida valida nao ingerida");
  assert.ok(!col.ingest(run), "partida repetida ingerida duas vezes");
  const v = col.build().collective_version;
  assert.notStrictEqual(v, lastVersion, "versao nao mudou com a partida nova");
  lastVersion = v;
}
assert.ok(!col.ingest({ id: "x", rankEligible: false, umbraCombat: normalizeUmbraCombat(report(9, 0.7, 10, 1)) }), "run suspeito ingerido");
const mind = col.build();
assert.strictEqual(mind.mode, "blend");
assert.strictEqual(mind.runs, 8);
assert.ok(mind.confidence > 0 && mind.confidence <= 0.7);
assert.ok(mind.weights.REBOBINAR && mind.weights.ATAQUE && mind.weights.ECO_PROFETICO, "pesos ausentes");
const ctx = FEATURES.map((n, i) => (i === 0 ? 1 : 0.5));
const bonus = (w) => w.reduce((s, v, i) => s + v * ctx[i], 0);
assert.ok(bonus(mind.weights.REBOBINAR) > bonus(mind.weights.ECO_PROFETICO), "REBOBINAR deveria valer mais que ECO");
assert.ok(bonus(mind.weights.ECO_PROFETICO) > bonus(mind.weights.ATAQUE), "ECO deveria valer mais que ATAQUE");
assert.ok(mind.weights.REBOBINAR[1] > 0, "REBOBINAR deveria crescer com a distancia");
assert.ok(Math.abs(mind.skill_priors.eco_along[0] - 0.6) < 0.01);
assert.ok(!("eco_side" in mind.skill_priors), "lado do desvio e pessoal, nao coletivo");
assert.ok(mind.aim_lead >= 0.4 && mind.aim_lead <= 0.95, "aim_lead fora da faixa");

// Persistencia
const again = createCollective(tmp).build();
assert.strictEqual(again.runs, 8, "acumulador nao persistiu");
assert.deepStrictEqual(again.weights, mind.weights);
// Resumo guardado no ranking nao leva as matrizes.
const summary = summarizeCombat(normalizeUmbraCombat(report(1, 0.7, 10, 2)));
assert.ok(!("actions" in summary) && summary.samples === 120);

console.log("UMBRA_COLLECTIVE_SMOKE_OK runs=%d samples=%d confidence=%s aim=%s", mind.runs, mind.samples, mind.confidence, mind.aim_lead);
