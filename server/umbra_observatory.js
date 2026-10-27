"use strict";

const fs = require("fs");
const path = require("path");
const { bossEvidence } = require("./ranking_score");
const mean = xs => xs.length ? xs.reduce((a,b) => a+b,0)/xs.length : null;
const finite = v => Number.isFinite(Number(v)) ? Math.max(0,Number(v)) : 0;
const clamp = v => Math.min(100, Math.max(0, v));

function observation(run) {
  const boss = bossEvidence(run).find(b => b.phase === 5);
  if (!boss || !run.id || run.rankEligible === false || run.rankingWithdrawn) return null;
  const knowledge = run.umbraKnowledge || {};
  // No attack-attempt / confirmed-evade counters exist in legacy reports.
  // Missing telemetry is not evidence of a flawless player or a perfect AI.
  const advantage = boss.damage !== null && boss.hits !== null
    ? Math.round(50 * boss.damage / (boss.damage + 2500) + 50 * boss.hits / (boss.hits + 10)) : null;
  return { id: String(run.id), player: String(run.player || "Jogador").slice(0,32),
    profile: String(run.profileKey || run.profileId || run.player || ""),
    version: String(run.version || "desconhecida"), mode: String(run.role || "desconhecido"),
    at: finite(run.endedUnix), damage: boss.damage, hits: boss.hits, defeated: boss.defeated,
    advantage, knowledge: finite(knowledge.sampleSeconds) >= 30 ? clamp(finite(knowledge.totalPercent)) : null,
    trainingEligible: run.umbraTrainingEligible === true };
}

function compare(base, recent) {
  const a = base.filter(r => r.advantage !== null), b = recent.filter(r => r.advantage !== null);
  const ready = a.length >= 3 && b.length >= 3;
  return { baselineCount: a.length, currentCount: b.length, baseline: mean(a.map(r=>r.advantage)),
    current: mean(b.map(r=>r.advantage)), delta: ready ? mean(b.map(r=>r.advantage))-mean(a.map(r=>r.advantage)) : null,
    status: ready ? "observational_comparison" : "insufficient_comparable_encounters" };
}

function summarize(state) {
  const rows = Object.values(state.records).sort((a,b)=>a.at-b.at || a.id.localeCompare(b.id));
  const keys = [...new Set(rows.map(r=>`${r.version} / ${r.mode}`))].sort();
  const cohorts = keys.map(key => {
    const group = rows.filter(r=>`${r.version} / ${r.mode}` === key);
    const ids = state.cohorts[key] || [];
    return { key, ...compare(group.filter(r=>ids.includes(r.id)),group.filter(r=>!ids.includes(r.id))),
      baselineIds: ids, encounters: group.length };
  });
  const players = [...new Set(rows.map(r=>r.profile))].map(profile => {
    const all = rows.filter(r=>r.profile===profile), last = all[all.length-1];
    const group = all.filter(r=>r.version===last.version && r.mode===last.mode);
    const measured = group.filter(r=>r.advantage!==null);
    return { player:last.player, profile, version:last.version, mode:last.mode, encounters:group.length,
      advantage:mean(measured.map(r=>r.advantage)), coverage:measured.length,
      observation:mean(group.filter(r=>r.knowledge!==null).map(r=>r.knowledge)),
      ...{ comparison: compare(measured.slice(0,3),measured.slice(3)) } };
  }).sort((a,b)=>(a.advantage??101)-(b.advantage??101) || a.player.localeCompare(b.player));
  return { schemaVersion:1, baselineAt:state.baselineAt, baselineEncounters:state.baselineIds.length,
    encounters:rows.length, measured:rows.filter(r=>r.advantage!==null).length,
    advantage:mean(rows.filter(r=>r.advantage!==null).map(r=>r.advantage)),
    evasionAvailable:false, cohorts, players,
    interpretation:"Pressão observada, não probabilidade de vitória, impossibilidade ou prova de aprendizado. Comparações exigem 3 encontros em cada grupo, na mesma versão e modo; builds e jogadores ainda variam." };
}

function createObservatory(file) {
  let state = null;
  let cached = null;
  return { update(runs) {
    if (!state) {
      try { state=JSON.parse(fs.readFileSync(file,"utf8"));
        if (state.schemaVersion!==1 || !state.records || !state.cohorts || !Array.isArray(state.baselineIds)) throw new Error("Invalid observatory state");
      } catch(error) {
        state = null;
        if(error.code!=="ENOENT") throw error; // Never silently replace a damaged historical baseline.
        const initial=runs.map(observation).filter(Boolean);
        state={schemaVersion:1,baselineAt:new Date().toISOString(),baselineIds:initial.map(r=>r.id),records:{},cohorts:{}};
      }
    }
    let changed=false;
    for(const run of runs) {
      const row=observation(run);
      if(row && !state.records[row.id]) { state.records[row.id]=row; changed=true; }
    }
    for(const row of (changed ? Object.values(state.records).sort((a,b)=>a.at-b.at || a.id.localeCompare(b.id)) : [])) {
      const key=`${row.version} / ${row.mode}`;
      const ids=state.cohorts[key] || (state.cohorts[key]=[]);
      // Freeze the first three measured encounters of each version/mode.
      if(ids.length<3 && row.advantage!==null && !ids.includes(row.id)) { ids.push(row.id); changed=true; }
    }
    if(changed || !fs.existsSync(file)) {
      fs.mkdirSync(path.dirname(file),{recursive:true});
      const temp=`${file}.${process.pid}.tmp`;
      try {
        fs.writeFileSync(temp,JSON.stringify(state),{mode:0o600});
        fs.renameSync(temp,file);
      } catch(error) { state=null; cached=null; throw error; }
    }
    if (changed || !cached) cached = summarize(state);
    return cached;
  }};
}

module.exports={observation,compare,summarize,createObservatory};
