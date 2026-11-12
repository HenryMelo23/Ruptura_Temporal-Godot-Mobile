"use strict";

// Mente coletiva da UMBRA. Cada partida solo que chega a ela manda um
// `umbra_combat` com estatisticas suficientes por acao (X'X e X'y do contexto
// de 12 features contra o retorno em 3 s). Aqui elas sao somadas entre todas
// as partidas e viram uma regressao ridge global, igual ao treino headless,
// mas com jogadores reais. O resultado vai para o jogo como camada "blend".

const crypto = require("crypto");
const fs = require("fs");

const FEATURES = ["bias", "distance", "umbra_hp", "player_hp", "player_speed", "player_edge",
  "player_dash_ready", "under_fire", "dimension_base", "hazards", "rewind_armed", "fight_time"];
const ACTIONS = ["ATAQUE", "SIFON", "TELEPORTE", "TELEPORTE_JUKE",
  "TRANSMUTAR_VORTICE", "TRANSMUTAR_GRAVIDADE", "TRANSMUTAR_NECROSE", "TRANSMUTAR_RESSONANCIA",
  "TRANSMUTAR_HEMORRAGIA", "TRANSMUTAR_ATRITO", "TRANSMUTAR_RASTRO",
  "VORTICE", "PRISAO", "MIASMA", "DESCARGA_ELETRICA", "CAMINHO_ESPINHOS", "LASER_SOBRECARGA", "PRAGA_RATOS",
  "REBOBINAR", "ECO_PROFETICO"];
const PRIOR_KEYS = ["eco_along", "eco_side", "rewind_escape"];
const NF = FEATURES.length;
const RIDGE = 6.0;
const MIN_ACTION_SAMPLES = 20;
const MAX_BONUS = 1.4;
const MIN_AVG = -1.2;
const FULL_CONFIDENCE_SAMPLES = 15000;
const MAX_CONFIDENCE = 0.7;
const MIN_ENCOUNTER_SECONDS = 15;

function num(value, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

// Valida e corta o relatorio do cliente. Retorna null se nao serve.
function normalizeUmbraCombat(value) {
  if (!value || typeof value !== "object") return null;
  if (Math.floor(num(value.schema_version)) !== 1) return null;
  const feats = Array.isArray(value.features) ? value.features.map(String) : [];
  if (feats.length !== NF || feats.some((f, i) => f !== FEATURES[i])) return null;
  const seconds = clamp(num(value.encounter_seconds), 0, 3600);
  const actions = {};
  const src = value.actions && typeof value.actions === "object" ? value.actions : {};
  let total = 0;
  for (const name of ACTIONS) {
    const row = src[name];
    if (!row || typeof row !== "object") continue;
    const n = Math.floor(num(row.n));
    if (n <= 0 || n > 600) continue;
    const xtx = Array.isArray(row.xtx) ? row.xtx.map((v) => num(v, NaN)) : [];
    const xty = Array.isArray(row.xty) ? row.xty.map((v) => num(v, NaN)) : [];
    if (xtx.length !== NF * NF || xty.length !== NF) continue;
    if (xtx.some((v) => !Number.isFinite(v) || Math.abs(v) > n * 4)) continue;
    if (xty.some((v) => !Number.isFinite(v) || Math.abs(v) > n * 40)) continue;
    actions[name] = { n, sumY: clamp(num(row.sum_y), -n * 20, n * 20), xtx, xty };
    total += n;
  }
  const plasma = value.plasma && typeof value.plasma === "object" ? value.plasma : {};
  const shots = clamp(Math.floor(num(plasma.shots)), 0, 2000);
  const priors = {};
  const priorSrc = value.skill_priors && typeof value.skill_priors === "object" ? value.skill_priors : {};
  for (const key of PRIOR_KEYS) {
    const row = priorSrc[key];
    if (!Array.isArray(row) || row.length < 2) continue;
    const lo = key === "eco_side" ? -1 : 0;
    const hi = key === "eco_along" ? 1.4 : 1;
    priors[key] = [clamp(num(row[0]), lo, hi), clamp(Math.floor(num(row[1])), 0, 500)];
  }
  if (total === 0 && shots === 0) return null;
  return {
    encounterSeconds: seconds,
    outcome: String(value.outcome || "").replace(/[^a-z_]/g, "").slice(0, 32),
    mindVersion: String(value.mind_version || "").slice(0, 48),
    aimLead: clamp(num(value.aim_lead, 0.72), 0.2, 1.1),
    plasma: { shots, hits: clamp(Math.floor(num(plasma.hits)), 0, shots) },
    actions,
    priors,
    samples: total
  };
}

// Resolve (A + rI) x = b por eliminacao gaussiana com pivoteamento.
function solve(A, b) {
  const n = b.length;
  const M = A.map((row, i) => [...row, b[i]]);
  for (let c = 0; c < n; c += 1) {
    let p = c;
    for (let r = c + 1; r < n; r += 1) if (Math.abs(M[r][c]) > Math.abs(M[p][c])) p = r;
    [M[c], M[p]] = [M[p], M[c]];
    const d = M[c][c] || 1e-9;
    for (let r = 0; r < n; r += 1) {
      if (r === c) continue;
      const f = M[r][c] / d;
      for (let k = c; k <= n; k += 1) M[r][k] -= f * M[c][k];
    }
  }
  return M.map((row, i) => row[n] / (row[i] || 1e-9));
}

const DECAY_PER_RUN = 0.998; // partidas antigas pesam menos aos poucos
const MAX_SEEN_IDS = 4000;

function emptyState() {
  return { version: 1, runs: 0, samples: 0, actions: {}, priors: {}, lead: {}, seen: [], lastId: "" };
}

// Acumulador persistente: a lista de runs do ranking gira (top 500 por
// pontuacao), mas o que a UMBRA aprendeu nao pode sumir junto.
function createCollective(filePath) {
  let state = emptyState();
  try {
    if (filePath && fs.existsSync(filePath)) state = { ...emptyState(), ...JSON.parse(fs.readFileSync(filePath, "utf8")) };
  } catch (_error) {
    state = emptyState();
  }
  let cached = null;

  function save() {
    if (!filePath) return;
    const tmp = `${filePath}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(state));
    fs.renameSync(tmp, filePath);
  }

  function ingest(run) {
    const c = run && run.umbraCombat;
    if (!c || !c.actions || run.rankEligible === false || c.encounterSeconds < MIN_ENCOUNTER_SECONDS) return false;
    const id = String(run.id || "");
    if (id && state.seen.includes(id)) return false;
    // Decaimento: multiplica tudo antes de somar a partida nova.
    for (const a of Object.values(state.actions)) {
      a.n *= DECAY_PER_RUN; a.sumY *= DECAY_PER_RUN;
      for (let i = 0; i < a.xtx.length; i += 1) a.xtx[i] *= DECAY_PER_RUN;
      for (let i = 0; i < a.xty.length; i += 1) a.xty[i] *= DECAY_PER_RUN;
    }
    for (const [name, row] of Object.entries(c.actions)) {
      if (!state.actions[name]) state.actions[name] = { n: 0, sumY: 0, xtx: new Array(NF * NF).fill(0), xty: new Array(NF).fill(0) };
      const a = state.actions[name];
      a.n += row.n; a.sumY += row.sumY;
      for (let i = 0; i < NF * NF; i += 1) a.xtx[i] += row.xtx[i];
      for (let i = 0; i < NF; i += 1) a.xty[i] += row.xty[i];
      state.samples += row.n;
    }
    for (const [key, [v, n]] of Object.entries(c.priors || {})) {
      if (key === "eco_side" || n <= 0) continue; // lado do desvio e pessoal
      if (!state.priors[key]) state.priors[key] = [0, 0];
      state.priors[key][0] += v * n;
      state.priors[key][1] += n;
    }
    if (c.plasma && c.plasma.shots > 0) {
      const k = (Math.round(c.aimLead * 20) / 20).toFixed(2);
      if (!state.lead[k]) state.lead[k] = [0, 0];
      state.lead[k][0] += c.plasma.shots;
      state.lead[k][1] += c.plasma.hits;
    }
    state.runs += 1;
    state.lastId = id;
    if (id) {
      state.seen.push(id);
      if (state.seen.length > MAX_SEEN_IDS) state.seen = state.seen.slice(-MAX_SEEN_IDS);
    }
    cached = null;
    save();
    return true;
  }

  function build() {
    if (!cached) cached = buildFromState(state);
    return cached;
  }

  return { ingest, build, state: () => state };
}

function buildFromState(state) {
  const coef = {};
  const meanFeat = new Array(NF).fill(0);
  let meanN = 0;
  for (const [name, a] of Object.entries(state.actions)) {
    if (a.n < MIN_ACTION_SAMPLES) continue;
    const A = [];
    for (let i = 0; i < NF; i += 1) {
      A.push(a.xtx.slice(i * NF, i * NF + NF).map((v, j) => v + (i === j ? (i === 0 ? 0.5 : RIDGE) : 0)));
    }
    coef[name] = solve(A, a.xty);
    for (let j = 0; j < NF; j += 1) meanFeat[j] += a.xtx[j]; // linha do bias = soma das features
    meanN += a.n;
  }
  const names = Object.keys(coef);
  const weights = {};
  if (names.length >= 2 && meanN > 0) {
    const ctx = meanFeat.map((v) => v / meanN);
    const avgCoef = new Array(NF).fill(0);
    for (const name of names) for (let j = 0; j < NF; j += 1) avgCoef[j] += coef[name][j] / names.length;
    const adv = {};
    let maxAbs = 0;
    for (const name of names) {
      adv[name] = coef[name].map((v, j) => v - avgCoef[j]);
      maxAbs = Math.max(maxAbs, Math.abs(adv[name].reduce((s, v, j) => s + v * ctx[j], 0)));
    }
    const scale = maxAbs > 1e-9 ? MAX_BONUS / maxAbs : 0;
    for (const name of names) {
      const w = adv[name].map((v) => clamp(v * scale, -3, 3));
      const avg = w.reduce((s, v, j) => s + v * ctx[j], 0);
      if (avg < MIN_AVG) w[0] += MIN_AVG - avg;
      weights[name] = w.map((v) => Number(v.toFixed(4)));
    }
  }
  const skillPriors = {};
  for (const [key, [sum, n]] of Object.entries(state.priors)) {
    skillPriors[key] = [Number((sum / Math.max(1, n)).toFixed(3)), Math.min(40, Math.round(n))];
  }
  let aimLead = null;
  const buckets = Object.entries(state.lead).map(([k, [s, h]]) => [Number(k), s, (h + 1) / (s + 4)]);
  const totalShots = buckets.reduce((s, b) => s + b[1], 0);
  if (buckets.length >= 1 && totalShots >= 400) {
    const km = buckets.reduce((s, b) => s + b[0] * b[1], 0) / totalShots;
    const rm = buckets.reduce((s, b) => s + b[2] * b[1], 0) / totalShots;
    const den = buckets.reduce((s, b) => s + b[1] * (b[0] - km) ** 2, 0);
    const slope = den > 1e-9 ? buckets.reduce((s, b) => s + b[1] * (b[0] - km) * (b[2] - rm), 0) / den : 0;
    aimLead = Number(clamp(km + clamp(slope * 0.1, -0.05, 0.05), 0.4, 0.95).toFixed(3));
  }
  const samples = Math.round(state.samples);
  const seed = `${state.runs}-${samples}-${state.lastId}`;
  const out = {
    schema_version: 1,
    mode: "blend",
    confidence: Number(Math.min(MAX_CONFIDENCE, samples / FULL_CONFIDENCE_SAMPLES).toFixed(3)),
    features: FEATURES,
    weights,
    skill_priors: skillPriors,
    runs: state.runs,
    samples,
    collective_version: `umbra-col-${crypto.createHash("sha1").update(seed).digest("hex").slice(0, 10)}`
  };
  if (aimLead !== null) out.aim_lead = aimLead;
  return out;
}

// O run guardado no ranking fica so com o resumo (as somas vivem no acumulador).
function summarizeCombat(c) {
  if (!c) return null;
  return { encounterSeconds: c.encounterSeconds, outcome: c.outcome, mindVersion: c.mindVersion,
    aimLead: c.aimLead, plasma: c.plasma, samples: c.samples, priors: c.priors };
}

module.exports = { normalizeUmbraCombat, createCollective, buildFromState, summarizeCombat, emptyState, FEATURES, ACTIONS };
