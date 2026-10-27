"use strict";

// Competitive presentation is separate from the v1 client signature protocol.
// Old signed reports must remain valid when the server changes ranking rules.
const policy = Object.freeze(require("./ranking_policy.json"));
const finite = (v) => Number.isFinite(Number(v)) ? Math.max(0, Number(v)) : 0;
const array = (v) => Array.isArray(v) ? v : [];
const victory = (r) => String(r.result).normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase() === "vitoria";

function campaignPhase(run) {
  const phase = Math.floor(finite(run.phase));
  // Chaga (6), Fenix (7), FaseEX (8) are branches, never later campaign floors.
  const reported = phase >= 1 && phase <= 5 ? phase : 1;
  const reached = array(run.bossDetail).filter(b => b && b.reached === true && b.phase >= 1 && b.phase <= 5);
  return Math.max(reported, ...reached.map(b => Math.floor(b.phase)));
}

function bossEvidence(run) {
  const rows = array(run.bossDetail).filter(b => b && b.reached === true && Number.isInteger(Number(b.phase)) && b.phase >= 1 && b.phase <= 7);
  const unique = [...new Map(rows.map(b => [Number(b.phase), b])).values()];
  return unique.map(b => {
    const phase = Number(b.phase);
    // Legacy reports did not send a death bit. Only a reached later campaign
    // boss (not simply a numeric final phase) supports this labelled inference.
    const inferred = phase <= 5 && (unique.some(other => other.phase > phase && other.phase <= 5) || (phase === 5 && victory(run)));
    const explicit = typeof b.defeated === "boolean";
    const defeated = explicit ? b.defeated : inferred;
    const sources = array(run.damageThreats).filter(d => d && d.kind === `boss_${phase}`);
    // A missing top-N source is NOT a zero-damage encounter.
    const explicitDamage = typeof b.damage_taken === "number" && Number.isFinite(b.damage_taken) && b.damage_taken >= 0;
    const damage = explicitDamage ? b.damage_taken : sources.length ? sources.reduce((s,d) => s + finite(d.damage), 0) : null;
    const hits = sources.length ? sources.reduce((s,d) => s + finite(d.hits), 0) : null;
    return { phase, defeated, defeatEvidence: explicit ? "explicit" : inferred ? "legacy_progression_inference" : "unknown", damage, hits,
      damageEvidence: explicitDamage ? "encounter_total" : sources.length ? "recorded_boss_source" : "missing",
      resilience: defeated && damage !== null ? Math.round(policy.resilienceMax / (1 + damage / (policy.damageReferencePerPhase * Math.min(phase, 5)))) : 0 };
  });
}

function scoreRun(run) {
  const phase = campaignPhase(run);
  const bosses = bossEvidence(run);
  const parts = [
    { key: "progression", label: "Progresso", rule: `${phase - 1} etapa(s) além da primeira × ${policy.phasePoints}`, points: (phase - 1) * policy.phasePoints },
    { key: "bosses", label: "Bosses superados", rule: `${bosses.filter(b => b.defeated).length} boss(es) distintos × ${policy.bossPoints}`, points: bosses.filter(b => b.defeated).length * policy.bossPoints },
    { key: "resilience", label: "Resistência aos bosses", rule: "Por boss superado: 500 ÷ (1 + dano recebido ÷ (500 × fase)); arredondado", points: bosses.reduce((s,b) => s + b.resilience, 0) },
    { key: "victory", label: "Vitória", rule: "Bônus fixo de conclusão", points: victory(run) ? policy.victoryPoints : 0 }
  ];
  return { version: policy.schemaVersion, label: policy.name, phase, parts, bosses, total: parts.reduce((s,p) => s + p.points, 0),
    unknownDamageBosses: bosses.filter(b => b.defeated && b.damage === null).length,
    inferredBosses: bosses.filter(b => b.defeated && b.defeatEvidence === "legacy_progression_inference").length };
}

function projectRun(run) {
  const ranking = scoreRun(run);
  const withdrawn = policy.withdrawnRunIds.includes(String(run.id));
  return { ...run, legacyScore: run.legacyScore ?? run.score ?? 0, ranking,
    score: run.rankEligible === false ? 0 : ranking.total,
    rankingWithdrawn: withdrawn,
    rankingWithdrawalReason: withdrawn ? policy.withdrawalReason : "" };
}

// No duration or boss clear time tie-breaker. Equal achievements share rank.
function compareRuns(a, b) { return finite(b.score) - finite(a.score) || String(a.id || "").localeCompare(String(b.id || "")); }

module.exports = { policy, campaignPhase, bossEvidence, scoreRun, projectRun, compareRuns };
