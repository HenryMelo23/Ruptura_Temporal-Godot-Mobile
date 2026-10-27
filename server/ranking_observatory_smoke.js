"use strict";
const assert=require("assert");
const fs=require("fs");
const os=require("os");
const path=require("path");
const {scoreRun,projectRun,compareRuns}=require("./ranking_score");
const {createObservatory,observation}=require("./umbra_observatory");
const {renderLeaderboardSite}=require("./leaderboard_site");

const base={id:"a",player:"Operator",profileId:"op",rankEligible:true,phase:5,version:"2.0.58",role:"solo",endedUnix:100,
  result:"Vitoria",bossDetail:[1,2,3,4,5].map(phase=>({phase,reached:true})),
  damageThreats:[1,2,3,4,5].map(phase=>({kind:`boss_${phase}`,damage:500*phase,hits:10})),
  umbraKnowledge:{sampleSeconds:100,totalPercent:75}};
assert.equal(scoreRun(base).total,18250);
assert.equal(scoreRun(base).inferredBosses,5);
assert.equal(scoreRun({...base,durationSeconds:1,bossDetail:base.bossDetail.map(b=>({...b,duration:1}))}).total,
  scoreRun({...base,durationSeconds:5400,bossDetail:base.bossDetail.map(b=>({...b,duration:5400}))}).total,"time must never score");
assert.equal(scoreRun({...base,cardsTotal:100000,kills:1e7,bossDamage:1e15,pointsEarned:1e10,playerStats:{hp:1e12}}).total,18250,"inflated economy must not score");
assert.equal(scoreRun({...base,bossDetail:[...base.bossDetail,...base.bossDetail]}).total,18250,"repeated bosses must not stack");
assert.equal(scoreRun({...base,damageThreats:[]}).total,17000,"missing damage cannot get no-hit bonus");
assert.equal(scoreRun({...base,damageThreats:[]}).unknownDamageBosses,5);
assert.equal(scoreRun({...base,bossDetail:base.bossDetail.map(b=>({...b,damage_taken:0,defeated:true}))}).total,19500);
assert(scoreRun({...base,damageThreats:base.damageThreats.map(d=>({...d,damage:d.damage*2}))}).total<scoreRun(base).total);
for(const phase of [6,7,8])assert.equal(scoreRun({...base,phase,result:"Derrota",bossDetail:[]}).total,0,"branch is not later campaign");
assert.equal(scoreRun({...base,result:"Derrota",bossDetail:[{phase:5,reached:true}]}).bosses[0].defeated,false);
assert.equal(scoreRun({...base,bossDetail:[{phase:1,reached:true,defeated:false},{phase:2,reached:true}]}).bosses[0].defeated,false);
assert(projectRun({...base,id:"d21f9000b1e8370f59"}).rankingWithdrawn);
assert(!projectRun({...base,id:"new",player:"Mika",profileId:"device-2376872352"}).rankingWithdrawn,"new runs must remain eligible");
assert.equal(projectRun({...base,rankEligible:false}).score,0);
assert.equal(compareRuns({id:"a",score:10,durationSeconds:900},{id:"b",score:10,durationSeconds:1}),-1);
assert.equal(observation({...base,bossDetail:[]}),null);
assert.equal(observation({...base,rankEligible:false}),null);
assert.equal(observation({...base,damageThreats:[]}).advantage,null);
assert.equal(observation(base).advantage,50);
assert.equal(observation(base).knowledge,75);

const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ruptura-observatory-"));
try {
 const file=path.join(dir,"state.json");
 const before=[0,1,2].map(i=>({...base,id:`old${i}`,endedUnix:i}));
 const obs=createObservatory(file);
 const first=obs.update(before);
 const disk=fs.readFileSync(file,"utf8");
 assert.equal(first.cohorts[0].delta,null);
 assert.equal(first.baselineEncounters,3);
 assert.equal(first.players[0].observation,75);
 assert.equal(obs.update(before).encounters,3);
 assert.equal(fs.readFileSync(file,"utf8"),disk,"replay must not rewrite baseline");
 const after=[3,4,5].map(i=>({...base,id:`new${i}`,endedUnix:i,damageThreats:[{kind:"boss_5",damage:7500,hits:30}]}));
 const next=createObservatory(file).update(after);
 assert.equal(next.baselineAt,first.baselineAt);
 assert.equal(next.encounters,6,"history must outlive ranking retention");
 assert.equal(next.cohorts[0].delta,25);
 assert.equal(next.players[0].comparison.delta,25);
 const withMissing=createObservatory(path.join(dir,"missing.json"));
 const missingComparison=withMissing.update([{...base,id:"missing",endedUnix:0,damageThreats:[]},...before,...after]);
 assert.equal(missingComparison.players[0].comparison.delta,25,"missing encounters must not consume measured baseline slots");
 const mixed=obs.update([...before,...after,{...base,id:"different",version:"2.0.59"}]);
 assert.equal(mixed.cohorts.find(c=>c.key.startsWith("2.0.59")).delta,null,"versions may not mix");
 assert.equal(mixed.evasionAvailable,false);
 const snapshot={runs:[projectRun({...base,player:'<script>alert("x")</script>'})],auditedRuns:[],profiles:{},observatory:next,downloads:[
   {platform:"windows",available:true,version:"2.0.58",filename:'game<script>.exe',size:1073741824,sha256:"a".repeat(64),notes:['<img src=x onerror=alert(1)>'],publishedAt:"2026-10-27T10:00:00Z",downloadUrl:"/updates/windows/download/game.exe"},
   {platform:"linux",available:false},{platform:"android",available:false}
 ]};
 for(const pathname of ["/leaderboard","/leaderboard/rankings","/leaderboard/umbra","/leaderboard/downloads","/leaderboard/run/a"]) {
   const html=renderLeaderboardSite({pathname,snapshot});
   assert(!html.includes('<script>alert("x")</script>'),"XSS must be escaped");
   assert(!html.includes("undefined"),`${pathname}: undefined markup`);
   assert(!html.includes("NaN"),`${pathname}: invalid number`);
   assert(html.includes("viewport"));
 }
 const home=renderLeaderboardSite({pathname:"/leaderboard",snapshot});
 assert(home.includes("mérito · não moedas"));
 assert(!home.includes("Speedrun de progressao"));
 assert(!home.includes("Tempo vivo</dt>"));
 const downloads=renderLeaderboardSite({pathname:"/leaderboard/downloads",snapshot});
 assert(downloads.includes("Baixar para Windows")&&downloads.includes("1 GB"));
 assert(downloads.includes("Arquivo temporariamente indisponível."));
 assert(!downloads.includes('game<script>.exe')&&!downloads.includes('<img src=x onerror=alert(1)>'));
 fs.writeFileSync(file,"invalid");
 assert.throws(()=>createObservatory(file).update([]),"damaged baseline must not be silently reset");
 console.log("RANKING_OBSERVATORY_OK time_invariant economy_invariant legacy_evidence withdrawal_exact persistence dedup cohorts privacy html");
} finally {fs.rmSync(dir,{recursive:true,force:true});}
