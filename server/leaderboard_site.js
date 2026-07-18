"use strict";

function safeNumber(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function clampNumber(value, min, max, fallback = 0) {
  return Math.max(min, Math.min(max, safeNumber(value, fallback)));
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function escapeAttr(value) {
  return escapeHtml(value).replace(/`/g, "&#96;");
}

function safeJson(value) {
  return JSON.stringify(value).replace(/</g, "\\u003c").replace(/\u2028/g, "\\u2028").replace(/\u2029/g, "\\u2029");
}

function arrayOf(value) {
  return Array.isArray(value) ? value : [];
}

function textValue(value, fallback = "Nao registrado") {
  const text = String(value ?? "").trim();
  return text ? text : fallback;
}

function formatNumber(value) {
  return Math.round(safeNumber(value)).toLocaleString("pt-BR");
}

function formatDecimal(value, digits = 1) {
  return safeNumber(value).toLocaleString("pt-BR", { minimumFractionDigits: digits, maximumFractionDigits: digits });
}

function formatDuration(value) {
  const total = Math.max(0, Math.floor(safeNumber(value)));
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const seconds = total % 60;
  return hours > 0
    ? `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
    : `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

function formatDate(run) {
  const timestamp = safeNumber(run && run.endedUnix) * 1000;
  if (timestamp > 0) {
    return new Intl.DateTimeFormat("pt-BR", {
      timeZone: "America/Sao_Paulo",
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit"
    }).format(new Date(timestamp));
  }
  return textValue(run && run.date, "Data nao registrada");
}

function profileKey(run) {
  return String((run && (run.profileKey || run.profileId)) || `player-${(run && run.player) || "jogador"}`);
}

function runPath(run) {
  return `/leaderboard/run/${encodeURIComponent(String(run && run.id))}`;
}

function playerPath(run) {
  return `/leaderboard/player/${encodeURIComponent(profileKey(run))}`;
}

function playerPathByKey(key) {
  return `/leaderboard/player/${encodeURIComponent(String(key || ""))}`;
}

function phaseLabel(run) {
  const phase = Math.max(0, Math.floor(safeNumber(run && run.phase)));
  const reached = arrayOf(run && run.bossDetail).filter((row) => row && row.reached).length;
  if (String(run && run.result).toLowerCase().includes("vitoria")) return `Vitoria completa - fase ${phase || 1}`;
  if (reached >= phase && phase > 0) return `Boss da fase ${phase} alcancado`;
  return `Fase ${phase || 1}`;
}

function progressValue(run) {
  const victory = String(run && run.result || "").toLowerCase().includes("vitoria") ? 1 : 0;
  const reached = arrayOf(run && run.bossDetail).filter((row) => row && row.reached).length;
  return victory * 1000000000 + safeNumber(run && run.phase) * 1000000 + reached * 10000 + safeNumber(run && run.durationSeconds);
}

function phaseMapPath(phase) {
  if (phase === 5) return "Fase5-1.png";
  return `Fase${Math.max(1, Math.min(4, Math.floor(safeNumber(phase, 1))))}.png`;
}

function normalizedKey(value) {
  return String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]/g, "");
}

function groupProfiles(runs) {
  const groups = new Map();
  for (const run of runs) {
    const key = profileKey(run);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(run);
  }
  return groups;
}

function mostFrequent(values) {
  const counts = new Map();
  for (const value of values.map((item) => textValue(item, "")).filter(Boolean)) {
    counts.set(value, (counts.get(value) || 0) + 1);
  }
  return Array.from(counts.entries()).sort((a, b) => b[1] - a[1] || String(a[0]).localeCompare(String(b[0])))[0] || ["Nao registrado", 0];
}

function aggregatePlayer(key, runs) {
  const sorted = [...runs].sort((a, b) => safeNumber(b.score) - safeNumber(a.score));
  const best = sorted[0] || {};
  const bestTime = [...runs].sort((a, b) => safeNumber(b.durationSeconds) - safeNumber(a.durationSeconds))[0] || best;
  const bestBoss = [...runs].sort((a, b) => safeNumber(b.bossDamage) - safeNumber(a.bossDamage))[0] || best;
  const farthest = [...runs].sort((a, b) => progressValue(b) - progressValue(a))[0] || best;
  const build = mostFrequent(runs.map((run) => `${textValue(run.manifestation, "?")} + ${textValue(run.spectrum, "?")}`));
  const version = mostFrequent(runs.map((run) => textValue(run.version, "?")));
  return {
    key,
    player: textValue(best.player || (runs[0] && runs[0].player), "Jogador"),
    runs: runs.length,
    best,
    bestTime,
    bestBoss,
    farthest,
    favoriteBuild: build[0],
    favoriteBuildRuns: build[1],
    favoriteVersion: version[0],
    favoriteVersionRuns: version[1],
    averageScore: runs.reduce((sum, run) => sum + safeNumber(run.score), 0) / Math.max(1, runs.length),
    averageDamageTaken: runs.reduce((sum, run) => sum + safeNumber(run.damageTaken), 0) / Math.max(1, runs.length),
    totalBossDamage: runs.reduce((sum, run) => sum + safeNumber(run.bossDamage), 0),
    totalKills: runs.reduce((sum, run) => sum + safeNumber(run.kills), 0),
    lastRun: [...runs].sort((a, b) => safeNumber(b.endedUnix) - safeNumber(a.endedUnix))[0] || best
  };
}

function playerAggregates(runs) {
  return Array.from(groupProfiles(runs).entries()).map(([key, playerRuns]) => aggregatePlayer(key, playerRuns));
}

function countBy(values) {
  const counts = new Map();
  for (const value of values) {
    const label = textValue(value, "");
    if (!label) continue;
    counts.set(label, (counts.get(label) || 0) + 1);
  }
  return Array.from(counts.entries()).map(([label, count]) => ({ label, count })).sort((a, b) => b.count - a.count || a.label.localeCompare(b.label));
}

function collectCards(runs) {
  const cards = new Map();
  for (const run of runs) {
    for (const card of arrayOf(run.cards)) {
      const key = normalizedKey(card.id || card.name || card.nick);
      if (!key) continue;
      const current = cards.get(key) || {
        id: card.id || key,
        name: textValue(card.name || card.nick, "Carta"),
        rarity: textValue(card.rarity, "Raridade nao registrada"),
        effect: textValue(card.effect, "Efeito nao registrado nesta build."),
        icon: card.icon,
        count: 0,
        runs: 0
      };
      current.count += Math.max(0, Math.floor(safeNumber(card.count, 1)));
      current.runs += 1;
      cards.set(key, current);
    }
  }
  return Array.from(cards.values()).sort((a, b) => b.runs - a.runs || b.count - a.count || a.name.localeCompare(b.name));
}

function aggregateSnapshot(snapshot) {
  const runs = arrayOf(snapshot && (snapshot.runs || snapshot.recent));
  const profiles = playerAggregates(runs);
  const bestScore = [...runs].sort((a, b) => safeNumber(b.score) - safeNumber(a.score))[0] || null;
  const bestTime = [...runs].sort((a, b) => safeNumber(b.durationSeconds) - safeNumber(a.durationSeconds))[0] || null;
  const bestBoss = [...runs].sort((a, b) => safeNumber(b.bossDamage) - safeNumber(a.bossDamage))[0] || null;
  const bestProgress = [...runs].sort((a, b) => progressValue(b) - progressValue(a))[0] || null;
  const latest = [...runs].sort((a, b) => safeNumber(b.endedUnix) - safeNumber(a.endedUnix));
  const totalBossDamage = runs.reduce((sum, run) => sum + safeNumber(run.bossDamage), 0);
  const totalEnemyDamage = runs.reduce((sum, run) => sum + safeNumber(run.enemyDamage), 0);
  const totalKills = runs.reduce((sum, run) => sum + safeNumber(run.kills), 0);
  const latestVersion = mostFrequent(latest.slice(0, 20).map((run) => run.version))[0];
  const maxPhase = Math.max(0, ...runs.map((run) => safeNumber(run.phase)));
  return {
    runs,
    profiles: profiles.sort((a, b) => safeNumber(b.best.score) - safeNumber(a.best.score)),
    bestScore,
    bestTime,
    bestBoss,
    bestProgress,
    latest,
    latestRun: latest[0] || null,
    totalBossDamage,
    totalEnemyDamage,
    totalKills,
    latestVersion,
    maxPhase,
    manifestations: countBy(runs.map((run) => run.manifestation)).slice(0, 10),
    spectra: countBy(runs.map((run) => run.spectrum)).slice(0, 10),
    versions: countBy(runs.map((run) => run.version)).slice(0, 10),
    phases: countBy(runs.map((run) => `Fase ${Math.max(1, Math.floor(safeNumber(run.phase, 1)))}`)).slice(0, 8),
    cards: collectCards(runs)
  };
}

function pageMeta(active) {
  const meta = {
    home: ["CENTRAL DO OBSERVATORIO", "Estado consolidado das linhas temporais registradas."],
    rankings: ["MATRIZ COMPETITIVA", "Comparacao entre sobrevivencia, ofensiva e progressao."],
    player: ["DOSSIE DO OPERADOR", "Historico, padroes de combate e assinaturas recorrentes."],
    run: ["RELATORIO DE EXPEDICAO", "Reconstrucao tecnica de uma linha temporal registrada."],
    missing: ["LINHA TEMPORAL NAO LOCALIZADA", "O registro solicitado nao existe, foi removido ou pertence a uma linha temporal nao sincronizada."]
  };
  return meta[active] || meta.home;
}

function sectionHeader(label, title, detail = "", action = "") {
  return `<div class="section-head">
    <div><p class="eyebrow">${escapeHtml(label)}</p><h2>${escapeHtml(title)}</h2>${detail ? `<p>${escapeHtml(detail)}</p>` : ""}</div>
    ${action}
  </div>`;
}

function emptyState(title, detail) {
  return `<div class="empty-state"><b>${escapeHtml(title)}</b><span>${escapeHtml(detail)}</span></div>`;
}

function statusBadge(label, tone = "cyan") {
  return `<span class="status-badge tone-${tone}">${escapeHtml(label)}</span>`;
}

function safeImage(src, alt, className = "", fallback = "RT", eager = false) {
  const label = textValue(fallback, "RT").slice(0, 3).toUpperCase();
  if (!src) {
    return `<span class="asset-fallback ${escapeAttr(className)}" aria-label="${escapeAttr(alt)}">${escapeHtml(label)}</span>`;
  }
  return `<img class="${escapeAttr(className)}" src="${escapeAttr(src)}" alt="${escapeAttr(alt)}" ${eager ? "" : "loading=\"lazy\""} decoding="async" onerror="this.replaceWith(Object.assign(document.createElement('span'),{className:'asset-fallback ${escapeAttr(className)}',textContent:'${escapeAttr(label)}'}))">`;
}

function publicAsset(publicAssetUrl, rawPath) {
  if (!publicAssetUrl) return "";
  return publicAssetUrl(rawPath) || "";
}

function manifestationIcon(run, publicAssetUrl) {
  const values = [run && run.manifestationKey, run && run.manifestation].filter(Boolean);
  for (const value of values) {
    const key = normalizedKey(value);
    const candidates = [`manifestacao_${key}.png`, `manifestacao-${key}.png`, `Manifestacao_${key}.png`];
    for (const candidate of candidates) {
      const url = publicAsset(publicAssetUrl, candidate);
      if (url) return url;
    }
  }
  return publicAsset(publicAssetUrl, "Geo1.png") || publicAsset(publicAssetUrl, "Geo2.png");
}

function bossIcon(run, publicAssetUrl) {
  const phase = Math.max(1, Math.floor(safeNumber(run && run.phase, 1)));
  return publicAsset(publicAssetUrl, `Boss${Math.min(6, phase)}.png`) || publicAsset(publicAssetUrl, "Boss1.png");
}

function nav(active, analytics) {
  const links = [
    ["home", "/leaderboard", "Visao geral"],
    ["operators", "/leaderboard#operadores", "Operadores"],
    ["rankings", "/leaderboard/rankings", "Rankings"],
    ["archive", "/leaderboard#arquivo", "Arquivo de runs"]
  ];
  return `<nav class="main-nav" aria-label="Navegacao principal">
    ${links.map(([key, href, label]) => `<a href="${href}" ${active === key || (active === "home" && key === "home") || (active === "rankings" && key === "rankings") ? "aria-current=\"page\" class=\"active\"" : ""}>${escapeHtml(label)}</a>`).join("")}
    <span class="nav-sync"><i></i>v${escapeHtml(analytics.latestVersion || "?")} · ${escapeHtml(analytics.latestRun ? formatDate(analytics.latestRun) : "sem sync")}</span>
  </nav>`;
}

function searchBox(analytics) {
  const searchData = analytics.profiles.map((profile) => ({ key: profile.key, player: profile.player, build: profile.favoriteBuild }));
  return `<div class="operator-search" data-search-root>
    <label for="operator-search-input">Buscar operador</label>
    <input id="operator-search-input" type="search" autocomplete="off" placeholder="Buscar jogador..." data-search-input>
    <div class="search-results" data-search-results role="listbox" aria-label="Sugestoes de operadores"></div>
    <script type="application/json" id="operator-search-data">${safeJson(searchData)}</script>
  </div>`;
}

function pageShell({ title, subtitle, active, content, analytics, script = "", pageClass = "" }) {
  const [fallbackTitle, fallbackSubtitle] = pageMeta(active);
  const pageTitle = title || fallbackTitle;
  const pageSubtitle = subtitle || fallbackSubtitle;
  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="dark">
  <link rel="icon" href="data:,">
  <title>${escapeHtml(pageTitle)} - Ruptura Temporal</title>
  <style>${siteCss()}</style>
</head>
<body class="${escapeAttr(pageClass)}">
  <a class="skip-link" href="#conteudo">Ir para o conteudo</a>
  <header class="topbar">
    <a class="brand" href="/leaderboard" aria-label="Ruptura Temporal - Observatorio Cronologico">
      <span class="brand-mark">RT</span>
      <span><b>Ruptura Temporal</b><small>Observatorio Cronologico</small></span>
      <em>TERMINAL // 3099</em>
    </a>
    ${nav(active, analytics)}
    ${searchBox(analytics)}
  </header>
  <main id="conteudo" tabindex="-1">
    <section class="page-heading">
      <p class="eyebrow">OBSERVATORIO DA RUPTURA</p>
      <h1>${escapeHtml(pageTitle)}</h1>
      <p>${escapeHtml(pageSubtitle)}</p>
    </section>
    ${content}
  </main>
  <footer class="terminal-footer">
    <b>OBSERVATORIO CRONOLOGICO // RUPTURA TEMPORAL</b>
    <span>${formatNumber(analytics.runs.length)} expedicoes sincronizadas · Build mais recente v${escapeHtml(analytics.latestVersion || "?")}</span>
    <span>Horarios exibidos em America/Sao_Paulo · Dados enviados pelas builds do jogo</span>
  </footer>
  <script>${baseClientScript()}${script}</script>
</body>
</html>`;
}

function metric(label, value, detail, tone = "cyan", code = "SYS") {
  return `<article class="metric tone-${tone}">
    <span>${escapeHtml(code)}</span>
    <b data-count-value="${escapeAttr(String(safeNumber(String(value).replace(/\D/g, ""), 0)))}">${escapeHtml(value)}</b>
    <strong>${escapeHtml(label)}</strong>
    <small>${escapeHtml(detail)}</small>
  </article>`;
}

function leaderStrip(label, run, value, detail, tone, publicAssetUrl) {
  if (!run) {
    return `<article class="operator-highlight empty">${emptyState(label, "Aguardando uma expedicao sincronizada.")}</article>`;
  }
  return `<a class="operator-highlight tone-${tone}" href="${playerPath(run)}">
    <div class="operator-avatar">${safeImage(manifestationIcon(run, publicAssetUrl), textValue(run.manifestation, "Manifestacao"), "", "RT")}</div>
    <span>${escapeHtml(label)}</span>
    <b>${escapeHtml(textValue(run.player, "Jogador"))}</b>
    <strong>${escapeHtml(value)}</strong>
    <small>${escapeHtml(detail)}</small>
  </a>`;
}

function cardTile(card, cardAssetUrl, compact = false) {
  const source = cardAssetUrl ? cardAssetUrl(card) : "";
  const name = textValue(card && card.name, "Carta");
  const initials = name.split(/\s+/).map((part) => part[0]).join("").slice(0, 2).toUpperCase();
  const rarity = textValue(card && card.rarity, "Raridade nao registrada");
  const effect = textValue(card && card.effect, "Efeito nao registrado nesta versao.");
  return `<article class="deck-card ${compact ? "compact" : ""}" title="${escapeAttr(effect)}">
    <div class="card-art">${safeImage(source, name, "", initials)}</div>
    <div class="card-copy">
      <b>${escapeHtml(name)}</b>
      <small><span>${escapeHtml(rarity)}</span> · x${formatNumber(card && card.count)}</small>
      ${compact ? "" : `<p>${escapeHtml(effect)}</p>`}
    </div>
  </article>`;
}

function runCode(run, index = 0) {
  const source = String((run && run.id) || index + 1).replace(/[^a-zA-Z0-9]/g, "").slice(0, 6).toUpperCase();
  return `TRANSMISSAO ${source || String(index + 1).padStart(4, "0")}`;
}

function runResultTone(run) {
  const result = String(run && run.result || "").toLowerCase();
  if (result.includes("vitoria")) return "green";
  if (result.includes("erro")) return "red";
  if (result.includes("derrota")) return "magenta";
  return "cyan";
}

function runRow(run, index = 0) {
  return `<article class="run-row">
    <a class="run-row-main" href="${runPath(run)}">
      <time>${escapeHtml(formatDate(run))}</time>
      <div>
        <span>${escapeHtml(runCode(run, index))}</span>
        <b>${escapeHtml(textValue(run.player, "Jogador"))}</b>
        <small>${escapeHtml(textValue(run.manifestation, "?"))} + ${escapeHtml(textValue(run.spectrum, "?"))} · v${escapeHtml(textValue(run.version, "?"))}</small>
      </div>
      <strong>${formatNumber(run && run.score)} pts</strong>
    </a>
    <div class="run-row-meta">
      ${statusBadge(textValue(run && run.result, "Run"), runResultTone(run))}
      <span>${escapeHtml(phaseLabel(run))}</span>
      <span>${formatDuration(run && run.durationSeconds)}</span>
    </div>
  </article>`;
}

function signatureList(items, tone) {
  const max = Math.max(1, ...items.map((item) => item.count));
  if (!items.length) return emptyState("Nenhuma assinatura registrada", "As builds ainda nao enviaram dados suficientes.");
  return `<div class="signature-list">${items.map((item) => `<div class="signature-row tone-${tone}">
    <span>${escapeHtml(item.label)}</span><b>${formatNumber(item.count)}</b><i style="width:${Math.max(4, item.count / max * 100)}%"></i>
  </div>`).join("")}</div>`;
}

function renderHome(snapshot, cardAssetUrl, publicAssetUrl) {
  const analytics = aggregateSnapshot(snapshot);
  const best = analytics.bestScore;
  const latest = analytics.latest.slice(0, 14);
  const heroImage = best ? manifestationIcon(best, publicAssetUrl) : publicAsset(publicAssetUrl, "Geo1.png");
  const heroTitle = analytics.runs.length ? "A RUPTURA CONTINUA INSTAVEL" : "NENHUMA EXPEDICAO SINCRONIZADA";
  const heroText = analytics.runs.length
    ? `${formatNumber(analytics.runs.length)} expedicoes de ${formatNumber(analytics.profiles.length)} operadores foram recuperadas. O limite registrado atualmente e a Fase ${formatNumber(analytics.maxPhase || 1)}.`
    : "O terminal esta ativo e aguardando a primeira run enviada pelas builds do jogo.";
  const cards = arrayOf(best && best.cards).slice(0, 8);
  const campaign = [1, 2, 3, 4, 5].map((phase) => {
    const count = analytics.runs.filter((run) => Math.floor(safeNumber(run.phase)) >= phase).length;
    const active = count > 0;
    return `<article class="campaign-stage ${active ? "active" : ""}">
      <span>F${phase}</span><b>${active ? `${formatNumber(count)} registros` : "Sem leitura"}</b><small>${phase === 5 ? "Umbra" : `Linha ${phase}`}</small>
    </article>`;
  }).join("");
  const playerCards = analytics.profiles.slice(0, 6).map((profile, index) => `<a class="player-tile" href="${playerPathByKey(profile.key)}">
    <span>#${index + 1}</span>
    <b>${escapeHtml(profile.player)}</b>
    <small>${escapeHtml(profile.favoriteBuild)} · v${escapeHtml(profile.favoriteVersion)}</small>
    <i>${formatNumber(profile.best.score)} pts</i>
  </a>`).join("");
  const content = `
    <section class="hero-terminal">
      <div class="hero-copy">
        <p class="eyebrow">LINHA TEMPORAL // ESTADO GLOBAL</p>
        <h2>${escapeHtml(heroTitle)}</h2>
        <p>${escapeHtml(heroText)}</p>
        <div class="hero-actions">
          <a class="button primary" href="/leaderboard/rankings">Explorar rankings</a>
          ${analytics.latestRun ? `<a class="button ghost" href="${runPath(analytics.latestRun)}">Abrir ultima expedicao</a>` : `<span class="button disabled">Aguardando expedicao</span>`}
        </div>
      </div>
      <aside class="hero-operator">
        <span>OPERADOR EM DESTAQUE</span>
        <div class="hero-orbit">${safeImage(heroImage, best ? textValue(best.manifestation, "Manifestacao") : "Ruptura Temporal", "", "RT", true)}</div>
        <h3>${escapeHtml(best ? textValue(best.player, "Jogador") : "Sem operador")}</h3>
        <strong>${formatNumber(best && best.score)} pts</strong>
        <p>${escapeHtml(best ? `${textValue(best.manifestation, "?")} + ${textValue(best.spectrum, "?")} · ${phaseLabel(best)} · v${textValue(best.version, "?")}` : "Aguardando dados reais.")}</p>
        ${best ? `<a href="${playerPath(best)}">Abrir dossie</a>` : ""}
      </aside>
    </section>
    <section class="pulse-grid" aria-label="Pulso da ruptura">
      ${metric("Expedicoes registradas", formatNumber(analytics.runs.length), `${formatNumber(analytics.profiles.length)} operadores unicos`, "cyan", "RUN")}
      ${metric("Maior dano em boss", formatNumber(analytics.bestBoss && analytics.bestBoss.bossDamage), analytics.bestBoss ? textValue(analytics.bestBoss.player, "Jogador") : "Sem leitura", "magenta", "DMG")}
      ${metric("Recorde de sobrevivencia", formatDuration(analytics.bestTime && analytics.bestTime.durationSeconds), analytics.bestTime ? textValue(analytics.bestTime.player, "Jogador") : "Sem leitura", "amber", "TMP")}
      ${metric("Dano total auditado", formatNumber(analytics.totalBossDamage + analytics.totalEnemyDamage), "Boss + inimigos em todas as runs", "green", "AUD")}
      ${metric("Maior progressao", analytics.bestProgress ? phaseLabel(analytics.bestProgress) : "Fase 0", analytics.bestProgress ? textValue(analytics.bestProgress.player, "Jogador") : "Sem leitura", "violet", "PRG")}
    </section>
    <section class="observatory-grid">
      <div class="terminal-panel span-8" id="arquivo">
        ${sectionHeader("Arquivo temporal", "Expedicoes recentes", "Partidas enviadas pelas builds QA em ordem cronologica.", `<a href="/leaderboard/rankings">Comparar jogadores</a>`)}
        <div class="run-list">${latest.map(runRow).join("") || emptyState("Nenhuma expedicao recuperada", "Quando uma run terminar, ela aparecera neste arquivo.")}</div>
      </div>
      <aside class="terminal-panel span-4 build-feature">
        ${sectionHeader("Build do recorde", "Arsenal sincronizado", best ? `${textValue(best.manifestation, "?")} + ${textValue(best.spectrum, "?")} · v${textValue(best.version, "?")}` : "Sem run registrada")}
        <div class="deck-grid compact-grid">${cards.map((card) => cardTile(card, cardAssetUrl, true)).join("") || emptyState("Deck nao registrado", "A build do recorde ainda nao enviou cartas.")}</div>
        ${best ? `<a class="button ghost full" href="${runPath(best)}">Abrir relatorio completo</a>` : ""}
      </aside>
      <div class="terminal-panel span-12">
        ${sectionHeader("Mapa de campanha", "Limite de progressao global", "Cada capsula mostra quantas runs atravessaram aquela fase.")}
        <div class="campaign-line">${campaign}</div>
      </div>
      <div class="terminal-panel span-7" id="operadores">
        ${sectionHeader("Operadores", "Dossies em destaque", "Perfis persistentes com melhor score, build favorita e versao mais usada.")}
        <div class="player-grid">${playerCards || emptyState("Nenhum operador catalogado", "O primeiro jogador aparecera aqui apos enviar uma run.")}</div>
      </div>
      <div class="terminal-panel span-5">
        ${sectionHeader("Assinaturas recorrentes", "Manifestacoes e espectros", "Leitura agregada das escolhas mais frequentes.")}
        <div class="dual-signatures">
          <div><h3>Manifestacoes</h3>${signatureList(analytics.manifestations, "violet")}</div>
          <div><h3>Espectros</h3>${signatureList(analytics.spectra, "cyan")}</div>
        </div>
      </div>
    </section>`;
  return pageShell({ title: "CENTRAL DO OBSERVATORIO", subtitle: "Estado consolidado das linhas temporais registradas.", active: "home", analytics, content, pageClass: "home-page" });
}

function renderPlayer(runKey, snapshot, cardAssetUrl, publicAssetUrl) {
  const analytics = aggregateSnapshot(snapshot);
  const allRuns = analytics.runs;
  const runs = allRuns.filter((run) => profileKey(run) === runKey).sort((a, b) => safeNumber(b.endedUnix) - safeNumber(a.endedUnix));
  if (!runs.length) return renderNotFound("Jogador nao encontrado", snapshot);
  const player = aggregatePlayer(runKey, runs);
  const favoriteCards = collectCards(runs).slice(0, 12);
  const timeline = [...runs].reverse().map((run) => ({
    label: formatDate(run).slice(0, 10),
    score: safeNumber(run.score),
    time: safeNumber(run.durationSeconds),
    boss: safeNumber(run.bossDamage)
  }));
  const content = `
    <section class="profile-hero">
      <div>
        <p class="eyebrow">FICHA PERSISTENTE // OPERADOR</p>
        <h2>${escapeHtml(player.player)}</h2>
        <p>${formatNumber(player.runs)} runs registradas · visto por ultimo em ${escapeHtml(formatDate(player.lastRun))}</p>
      </div>
      <div class="profile-badges">
        ${statusBadge(`Build mais usada: ${player.favoriteBuild}`, "violet")}
        ${statusBadge(`Versao recorrente: v${player.favoriteVersion}`, "cyan")}
      </div>
      <a class="button primary" href="${runPath(player.best)}">Ver melhor partida</a>
    </section>
    <section class="pulse-grid">
      ${metric("Melhor score", `${formatNumber(player.best.score)} pts`, `v${textValue(player.best.version, "?")}`, "cyan", "SCR")}
      ${metric("Melhor tempo", formatDuration(player.bestTime.durationSeconds), formatDate(player.bestTime), "amber", "TMP")}
      ${metric("Maior dano em boss", `${formatNumber(player.bestBoss.bossDamage)} dano`, phaseLabel(player.bestBoss), "magenta", "DMG")}
      ${metric("Maior progressao", phaseLabel(player.farthest), textValue(player.farthest.result, "Run"), "green", "PRG")}
    </section>
    <section class="observatory-grid">
      <div class="terminal-panel span-7">
        ${sectionHeader("Tendencia", "Evolucao entre partidas", "Score, sobrevivencia e dano em boss ao longo do historico.")}
        <div class="chart-wrap"><canvas id="player-chart" aria-label="Grafico de score, tempo e dano em boss"></canvas></div>
        <div class="chart-legend"><span class="cyan">Score</span><span class="amber">Tempo vivo</span><span class="magenta">Dano em boss</span></div>
      </div>
      <aside class="terminal-panel span-5 facts-list">
        ${sectionHeader("Padroes", "Assinatura de combate")}
        <dl>
          <div><dt>Build mais usada</dt><dd>${escapeHtml(player.favoriteBuild)} <small>${player.favoriteBuildRuns} runs</small></dd></div>
          <div><dt>Versao mais usada</dt><dd>v${escapeHtml(player.favoriteVersion)} <small>${player.favoriteVersionRuns} runs</small></dd></div>
          <div><dt>Score medio</dt><dd>${formatNumber(player.averageScore)} pts</dd></div>
          <div><dt>Dano medio recebido</dt><dd>${formatNumber(player.averageDamageTaken)} dano</dd></div>
          <div><dt>Dano total em boss</dt><dd>${formatNumber(player.totalBossDamage)} dano</dd></div>
        </dl>
      </aside>
      <div class="terminal-panel span-12">
        ${sectionHeader("Deck recorrente", "Cartas mais usadas", "Cartas presentes nas runs deste operador.")}
        <div class="deck-grid">${favoriteCards.map((card) => cardTile(card, cardAssetUrl)).join("") || emptyState("Sem cartas registradas", "Nenhuma run deste operador trouxe detalhes de deck.")}</div>
      </div>
      <div class="terminal-panel span-12">
        ${sectionHeader("Historico", "Arquivo do operador", "Todas as runs preservadas para este perfil.")}
        <div class="run-list">${runs.map(runRow).join("")}</div>
      </div>
    </section>`;
  return pageShell({
    title: "DOSSIE DO OPERADOR",
    subtitle: "Historico, padroes de combate e assinaturas recorrentes.",
    active: "player",
    analytics,
    content,
    script: chartScript(timeline),
    pageClass: "player-page"
  });
}

function rankingTable(title, subtitle, runs, value, detail, tone) {
  const max = Math.max(1, ...runs.map((run) => safeNumber(value(run))));
  const rows = runs.slice(0, 12).map((run, index) => {
    const raw = safeNumber(value(run));
    const display = value(run, true);
    return `<a href="${playerPath(run)}">
      <b>#${index + 1}</b>
      <div><strong>${escapeHtml(textValue(run.player, "Jogador"))}</strong><small>${escapeHtml(detail(run))}</small><i style="width:${Math.max(3, raw / max * 100)}%"></i></div>
      <span>${escapeHtml(String(display))}</span>
    </a>`;
  }).join("");
  return `<section class="ranking-column tone-${tone}">
    ${sectionHeader(subtitle, title)}
    <div class="ranking-list">${rows || emptyState("Sem ranking", "Aguardando runs suficientes para comparar.")}</div>
  </section>`;
}

function renderRankings(snapshot) {
  const analytics = aggregateSnapshot(snapshot);
  const bestRuns = analytics.profiles.map((player) => player.best).sort((a, b) => safeNumber(b.score) - safeNumber(a.score));
  const byTime = analytics.profiles.map((player) => player.bestTime).sort((a, b) => safeNumber(b.durationSeconds) - safeNumber(a.durationSeconds));
  const byBoss = analytics.profiles.map((player) => player.bestBoss).sort((a, b) => safeNumber(b.bossDamage) - safeNumber(a.bossDamage));
  const byProgress = analytics.profiles.map((player) => player.farthest).sort((a, b) => progressValue(b) - progressValue(a));
  const scatter = bestRuns.slice(0, 48).map((run) => ({
    player: textValue(run.player, "Jogador"),
    time: safeNumber(run.durationSeconds),
    boss: safeNumber(run.bossDamage),
    score: safeNumber(run.score),
    phase: safeNumber(run.phase)
  }));
  const phaseChart = analytics.phases.map((item) => ({ label: item.label, count: item.count }));
  const content = `
    <section class="terminal-panel chart-section">
      ${sectionHeader("Plano cartesiano", "Sobrevivencia x dano em boss", "Cada ponto e a melhor run de um operador; o tamanho representa o score.")}
      <div class="chart-wrap large"><canvas id="scatter-chart" aria-label="Plano cartesiano comparando tempo e dano em boss"></canvas></div>
      <p class="data-note">Resumo textual: ${formatNumber(bestRuns.length)} operadores comparados, maior tempo ${formatDuration(byTime[0] && byTime[0].durationSeconds)}, maior dano em boss ${formatNumber(byBoss[0] && byBoss[0].bossDamage)}.</p>
    </section>
    <section class="rankings-layout">
      ${rankingTable("Melhor score geral", "Indice final", bestRuns, (run, formatted) => formatted ? `${formatNumber(run.score)} pts` : run.score, (run) => `${textValue(run.manifestation, "?")} + ${textValue(run.spectrum, "?")} | v${textValue(run.version, "?")}`, "cyan")}
      ${rankingTable("Maior tempo vivo", "Sobrevivencia", byTime, (run, formatted) => formatted ? formatDuration(run.durationSeconds) : run.durationSeconds, (run) => `${phaseLabel(run)} | v${textValue(run.version, "?")}`, "amber")}
      ${rankingTable("Maior dano em boss", "Pressao ofensiva", byBoss, (run, formatted) => formatted ? `${formatNumber(run.bossDamage)} dano` : run.bossDamage, (run) => `${textValue(run.manifestation, "?")} + ${textValue(run.spectrum, "?")}`, "magenta")}
      ${rankingTable("Maior progressao", "Avanco na campanha", byProgress, (run, formatted) => formatted ? phaseLabel(run) : progressValue(run), (run) => `${formatDuration(run.durationSeconds)} | ${textValue(run.result, "Run")}`, "green")}
    </section>
    <section class="observatory-grid">
      <div class="terminal-panel span-7">
        ${sectionHeader("Distribuicao", "Progresso por fase", "Quantidade de runs registradas por fase final.")}
        <div class="chart-wrap"><canvas id="phase-chart" aria-label="Grafico de distribuicao por fase"></canvas></div>
      </div>
      <div class="terminal-panel span-5">
        ${sectionHeader("Formula", "Score auditavel", "A exibicao segue o score enviado e registrado pela build do jogo.")}
        <p class="formula-text">O ranking principal usa o valor <b>leaderboard_score</b> recebido em cada run. Quando o jogo calcula esse campo, ele combina progresso, combate, sobrevivencia, cartas e bonus de resultado. O site nao altera a pontuacao: ele apenas ordena e explica os registros recebidos.</p>
        ${signatureList(analytics.versions, "cyan")}
      </div>
    </section>`;
  return pageShell({
    title: "MATRIZ COMPETITIVA",
    subtitle: "Comparacao entre sobrevivencia, ofensiva e progressao.",
    active: "rankings",
    analytics,
    content,
    script: scatterScript(scatter) + barChartScript("phase-chart", phaseChart),
    pageClass: "rankings-page"
  });
}

function enemyThreatTile(threat, publicAssetUrl, maxDamage) {
  const name = textValue(threat && threat.name, "Origem desconhecida");
  const icon = publicAsset(publicAssetUrl, threat && threat.icon);
  const width = Math.max(4, safeNumber(threat && threat.damage) / Math.max(1, maxDamage) * 100);
  return `<article class="threat">
    <div class="threat-icon">${safeImage(icon, name, "", name[0] || "?")}</div>
    <div>
      <b>${escapeHtml(name)}</b>
      <small>${formatNumber(threat && threat.damage)} dano · ${formatNumber(threat && threat.hits)} impactos · fase ${formatNumber(threat && threat.phase)}</small>
      <i style="width:${width}%"></i>
    </div>
  </article>`;
}

function renderRun(runId, snapshot, cardAssetUrl, publicAssetUrl) {
  const analytics = aggregateSnapshot(snapshot);
  const run = analytics.runs.find((item) => String(item.id) === runId);
  if (!run) return renderNotFound("Partida nao encontrada", snapshot);
  const threats = arrayOf(run.damageThreats);
  const maxThreat = Math.max(1, ...threats.map((row) => safeNumber(row.damage)));
  const phaseSet = new Set([
    ...arrayOf(run.heatmap && run.heatmap.cells).map((cell) => safeNumber(cell && cell.phase, 1)),
    ...arrayOf(run.damageEvents).map((event) => safeNumber(event && event.phase, 1)),
    safeNumber(run.phase, 1)
  ]);
  const phases = Array.from(phaseSet).filter((phase) => phase > 0).sort((a, b) => a - b);
  const mapUrls = Object.fromEntries(phases.map((phase) => [phase, publicAsset(publicAssetUrl, phaseMapPath(phase))]));
  const mapData = {
    heatmap: run.heatmap || { columns: 16, rows: 9, cells: [] },
    events: arrayOf(run.damageEvents),
    maps: mapUrls,
    phases
  };
  const bossRows = arrayOf(run.bossDetail).filter((row) => row && (row.reached || safeNumber(row.damage) > 0));
  const currentIndex = analytics.latest.findIndex((item) => String(item.id) === String(run.id));
  const prev = currentIndex >= 0 ? analytics.latest[currentIndex + 1] : null;
  const next = currentIndex > 0 ? analytics.latest[currentIndex - 1] : null;
  const content = `
    <section class="run-header">
      <div>
        <a class="back-link" href="${playerPath(run)}">Voltar ao dossie</a>
        <p class="eyebrow">${escapeHtml(runCode(run))} // ${escapeHtml(formatDate(run))}</p>
        <h2>${escapeHtml(textValue(run.player, "Jogador"))}</h2>
        <p>${escapeHtml(textValue(run.manifestation, "?"))} + ${escapeHtml(textValue(run.spectrum, "?"))} · versao ${escapeHtml(textValue(run.version, "?"))} · ${escapeHtml(textValue(run.platform, "?"))}</p>
      </div>
      <div class="run-actions">
        ${prev ? `<a href="${runPath(prev)}">Run anterior</a>` : ""}
        ${next ? `<a href="${runPath(next)}">Run seguinte</a>` : ""}
        ${statusBadge(textValue(run.result, "Run"), runResultTone(run))}
      </div>
    </section>
    <section class="pulse-grid">
      ${metric("Score calculado", `${formatNumber(run.score)} pts`, "indice recebido da build", "cyan", "SCR")}
      ${metric("Tempo vivo", formatDuration(run.durationSeconds), formatDate(run), "amber", "TMP")}
      ${metric("Dano em boss", `${formatNumber(run.bossDamage)} dano`, phaseLabel(run), "magenta", "BOS")}
      ${metric("Dano recebido", `${formatNumber(run.damageTaken)} dano`, `${formatNumber(arrayOf(run.damageEvents).length)} eventos mapeados`, "red", "HIT")}
      ${metric("Abates", formatNumber(run.kills), `${formatNumber(run.enemyDamage)} dano em inimigos`, "green", "KIL")}
    </section>
    <section class="observatory-grid">
      <div class="terminal-panel span-7">
        ${sectionHeader("Posicionamento", "Mapa de calor e dano", "Reconstrucao espacial da permanencia e dos pontos de impacto.", `<div class="phase-switch">${phases.map((phase, index) => `<button type="button" data-phase="${phase}" class="${index === 0 ? "active" : ""}">Fase ${phase}</button>`).join("")}</div>`)}
        <div class="map-wrap"><canvas id="run-map" aria-label="Mapa de calor da movimentacao e pontos de dano"></canvas></div>
        <div class="map-legend"><span><i class="heat"></i>Tempo de permanencia</span><span><i class="damage"></i>Ponto onde sofreu dano</span></div>
        <p class="data-note">O mapa preserva a proporcao da fase. Runs antigas podem nao possuir amostras suficientes.</p>
      </div>
      <aside class="terminal-panel span-5">
        ${sectionHeader("Ameacas", "Inimigos mais problematicos", "Fontes de dano ordenadas por impacto total.")}
        <div class="threat-list">${threats.map((row) => enemyThreatTile(row, publicAssetUrl, maxThreat)).join("") || emptyState("Nenhuma origem de dano recuperada", "Esta build nao enviou detalhamento de inimigos problemáticos.")}</div>
      </aside>
      <div class="terminal-panel span-7">
        ${sectionHeader("Build final", "Deck da partida", `${formatNumber(run.cardsTotal)} cartas registradas nesta run.`)}
        <div class="deck-grid">${arrayOf(run.cards).map((card) => cardTile(card, cardAssetUrl)).join("") || emptyState("Deck nao registrado", "Esta versao da build nao enviou os detalhes das cartas.")}</div>
      </div>
      <div class="terminal-panel span-5 facts-list">
        ${sectionHeader("Reconstrucao", "Resumo tecnico")}
        <dl>
          <div><dt>Fase alcancada</dt><dd>${escapeHtml(phaseLabel(run))}</dd></div>
          <div><dt>Resultado</dt><dd>${escapeHtml(textValue(run.result, "Run"))}</dd></div>
          <div><dt>Pontos ganhos / gastos</dt><dd>${formatNumber(run.pointsEarned)} / ${formatNumber(run.pointsSpent)}</dd></div>
          <div><dt>Bosses encontrados</dt><dd>${bossRows.length ? bossRows.map((row) => `F${formatNumber(row.phase)}: ${formatNumber(row.damage)} dano em ${escapeHtml(textValue(row.duration, "--"))}`).join("<br>") : "Nenhum boss registrado"}</dd></div>
          <div><dt>Rede</dt><dd>${escapeHtml(run.network && typeof run.network === "object" ? Object.keys(run.network).slice(0, 4).join(", ") || "Sem telemetria" : "Sem telemetria")}</dd></div>
        </dl>
      </div>
    </section>`;
  return pageShell({
    title: "RELATORIO DE EXPEDICAO",
    subtitle: "Reconstrucao tecnica de uma linha temporal registrada.",
    active: "run",
    analytics,
    content,
    script: mapScript(mapData),
    pageClass: "run-page"
  });
}

function renderNotFound(message, snapshot = {}) {
  const analytics = aggregateSnapshot(snapshot);
  const content = `<section class="empty-page">
    <p class="eyebrow">ERRO 404 // DIVERGENCIA TEMPORAL</p>
    <h2>${escapeHtml(message || "Linha temporal nao localizada")}</h2>
    <p>O registro solicitado nao existe, foi removido ou pertence a uma linha temporal nao sincronizada.</p>
    <a class="button primary" href="/leaderboard">Voltar ao observatorio</a>
  </section>`;
  return pageShell({
    title: "LINHA TEMPORAL NAO LOCALIZADA",
    subtitle: "O registro solicitado nao existe, foi removido ou pertence a uma linha temporal nao sincronizada.",
    active: "missing",
    analytics,
    content,
    pageClass: "missing-page"
  });
}

function renderLeaderboardSite({ pathname, snapshot, cardAssetUrl, publicAssetUrl }) {
  if (pathname === "/leaderboard" || pathname === "/leaderboard/") return renderHome(snapshot, cardAssetUrl, publicAssetUrl);
  if (pathname === "/leaderboard/rankings") return renderRankings(snapshot, publicAssetUrl);
  const playerMatch = pathname.match(/^\/leaderboard\/player\/([^/]+)$/);
  if (playerMatch) return renderPlayer(decodeURIComponent(playerMatch[1]), snapshot, cardAssetUrl, publicAssetUrl);
  const runMatch = pathname.match(/^\/leaderboard\/run\/([^/]+)$/);
  if (runMatch) return renderRun(decodeURIComponent(runMatch[1]), snapshot, cardAssetUrl, publicAssetUrl);
  return renderNotFound("Pagina nao encontrada", snapshot);
}

function chartScript(data) {
  return `registerLineChart('player-chart',${safeJson(data)},[['score','#25f4e5'],['time','#ffc94a'],['boss','#ff48bd']]);`;
}

function scatterScript(data) {
  return `registerScatterChart('scatter-chart',${safeJson(data)});`;
}

function barChartScript(id, data) {
  return `registerBarChart('${escapeAttr(id)}',${safeJson(data)});`;
}

function mapScript(data) {
  return `registerRunMap('run-map',${safeJson(data)});`;
}

function baseClientScript() {
  return `
(function(){
  const reduceMotion=window.matchMedia&&window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const charts=[];
  function byId(id){return document.getElementById(id)}
  function prepareCanvas(canvas,minHeight){
    const ratio=Math.min(2,window.devicePixelRatio||1);
    const box=canvas.getBoundingClientRect();
    const width=Math.max(320,Math.floor(box.width||canvas.clientWidth||640));
    const height=Math.max(minHeight||220,Math.floor(box.height||canvas.clientHeight||260));
    canvas.width=Math.floor(width*ratio);
    canvas.height=Math.floor(height*ratio);
    const ctx=canvas.getContext('2d');
    ctx.setTransform(ratio,0,0,ratio,0,0);
    return{ctx,w:width,h:height};
  }
  function axes(ctx,w,h,xLabel,yLabel){
    ctx.strokeStyle='rgba(129,213,224,.18)';
    ctx.fillStyle='#8b9aac';
    ctx.font='12px Segoe UI, sans-serif';
    ctx.lineWidth=1;
    for(let i=0;i<=5;i+=1){const y=26+(h-68)*i/5;ctx.beginPath();ctx.moveTo(54,y);ctx.lineTo(w-20,y);ctx.stroke()}
    ctx.fillText(xLabel,w-142,h-14);
    ctx.save();ctx.translate(15,140);ctx.rotate(-Math.PI/2);ctx.fillText(yLabel,0,0);ctx.restore();
  }
  function registerLineChart(id,data,series){
    const canvas=byId(id); if(!canvas) return;
    const draw=function(){
      const prepared=prepareCanvas(canvas,230),ctx=prepared.ctx,w=prepared.w,h=prepared.h;
      ctx.clearRect(0,0,w,h);axes(ctx,w,h,'partidas','valor relativo');
      if(!data.length){ctx.fillStyle='#8b9aac';ctx.fillText('Sem dados suficientes para reconstruir a tendencia.',64,62);return}
      series.forEach(function(item){
        const key=item[0],color=item[1],max=Math.max(1,...data.map(function(row){return Number(row[key])||0}));
        const points=data.map(function(row,index){return{x:56+(w-86)*(data.length===1?.5:index/(data.length-1)),y:h-40-(h-78)*(Number(row[key])||0)/max}});
        ctx.strokeStyle=color;ctx.lineWidth=2.5;ctx.beginPath();
        points.forEach(function(point,index){if(index===0)ctx.moveTo(point.x,point.y);else ctx.lineTo(point.x,point.y)});
        ctx.stroke();ctx.fillStyle=color;points.forEach(function(point){ctx.beginPath();ctx.arc(point.x,point.y,4,0,Math.PI*2);ctx.fill()});
      });
    };
    charts.push(draw);draw();
  }
  function registerScatterChart(id,data){
    const canvas=byId(id); if(!canvas) return;
    const draw=function(){
      const prepared=prepareCanvas(canvas,320),ctx=prepared.ctx,w=prepared.w,h=prepared.h;
      ctx.clearRect(0,0,w,h);axes(ctx,w,h,'tempo vivo','dano em boss');
      if(!data.length){ctx.fillStyle='#8b9aac';ctx.fillText('Nenhum operador comparavel encontrado.',64,62);return}
      const maxTime=Math.max(1,...data.map(function(item){return item.time||0}));
      const maxBoss=Math.max(1,...data.map(function(item){return item.boss||0}));
      const maxScore=Math.max(1,...data.map(function(item){return item.score||0}));
      data.forEach(function(item,index){
        const x=60+(w-154)*(item.time||0)/maxTime;
        const y=h-48-(h-104)*(item.boss||0)/maxBoss;
        const radius=5+13*Math.sqrt((item.score||0)/maxScore);
        ctx.fillStyle=index===0?'rgba(255,72,189,.82)':'rgba(37,244,229,.58)';
        ctx.strokeStyle='rgba(255,255,255,.72)';
        ctx.beginPath();ctx.arc(x,y,radius,0,Math.PI*2);ctx.fill();ctx.stroke();
        ctx.fillStyle='#f3f7fa';ctx.font='11px Segoe UI, sans-serif';
        const label=String(item.player||'Jogador'),lw=ctx.measureText(label).width;
        ctx.fillText(label,x+radius+lw+12>w?x-radius-lw-6:x+radius+6,y+4);
      });
    };
    charts.push(draw);draw();
  }
  function registerBarChart(id,data){
    const canvas=byId(id); if(!canvas) return;
    const draw=function(){
      const prepared=prepareCanvas(canvas,230),ctx=prepared.ctx,w=prepared.w,h=prepared.h;
      ctx.clearRect(0,0,w,h);
      if(!data.length){ctx.fillStyle='#8b9aac';ctx.fillText('Sem distribuicao de fase registrada.',24,34);return}
      const max=Math.max(1,...data.map(function(item){return item.count||0}));
      const gap=12,barW=(w-50-gap*(data.length-1))/Math.max(1,data.length);
      data.forEach(function(item,index){
        const x=24+index*(barW+gap),bh=(h-70)*(item.count||0)/max,y=h-42-bh;
        const gradient=ctx.createLinearGradient(0,y,0,h-42);gradient.addColorStop(0,'#ff48bd');gradient.addColorStop(1,'#25f4e5');
        ctx.fillStyle=gradient;ctx.fillRect(x,y,barW,bh);
        ctx.fillStyle='#f3f7fa';ctx.font='12px Segoe UI, sans-serif';ctx.fillText(String(item.count||0),x+4,y-8);
        ctx.fillStyle='#8b9aac';ctx.fillText(String(item.label||''),x,h-18);
      });
    };
    charts.push(draw);draw();
  }
  function registerRunMap(id,data){
    const canvas=byId(id); if(!canvas) return;
    let selected=(data.phases&&data.phases[0])||1;
    const draw=function(){
      const prepared=prepareCanvas(canvas,250),ctx=prepared.ctx,w=prepared.w,h=prepared.h;
      ctx.clearRect(0,0,w,h);ctx.fillStyle='#05070b';ctx.fillRect(0,0,w,h);
      const image=new Image();
      image.onload=function(){
        const scale=Math.min(w/image.width,h/image.height),dw=image.width*scale,dh=image.height*scale,ox=(w-dw)/2,oy=(h-dh)/2;
        ctx.clearRect(0,0,w,h);ctx.drawImage(image,ox,oy,dw,dh);
        const cells=((data.heatmap&&data.heatmap.cells)||[]).filter(function(cell){return Number(cell.phase||1)===Number(selected)});
        const cols=Math.max(1,Number(data.heatmap&&data.heatmap.columns)||16),rows=Math.max(1,Number(data.heatmap&&data.heatmap.rows)||9);
        const max=Math.max(1,...cells.map(function(cell){return Number(cell.count)||0}));
        cells.forEach(function(cell){
          const cw=dw/cols,ch=dh/rows,x=ox+(Number(cell.x)||0)*cw,y=oy+(Number(cell.y)||0)*ch,intensity=(Number(cell.count)||0)/max;
          const gradient=ctx.createRadialGradient(x+cw/2,y+ch/2,0,x+cw/2,y+ch/2,Math.max(cw,ch)*1.2);
          gradient.addColorStop(0,'rgba(255,72,189,'+(0.20+intensity*.55)+')');
          gradient.addColorStop(.55,'rgba(255,201,74,'+(intensity*.32)+')');
          gradient.addColorStop(1,'rgba(255,201,74,0)');
          ctx.fillStyle=gradient;ctx.fillRect(x-cw/2,y-ch/2,cw*2,ch*2);
        });
        ((data.events)||[]).filter(function(event){return Number(event.phase||1)===Number(selected)}).forEach(function(event){
          const x=ox+clamp(Number(event.x)||0,0,1)*dw,y=oy+clamp(Number(event.y)||0,0,1)*dh,r=Math.max(4,Math.min(13,4+Math.sqrt(Number(event.amount)||0)*.35));
          ctx.fillStyle='rgba(255,93,104,.82)';ctx.strokeStyle='#fff1f3';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill();ctx.stroke();
        });
        if(!cells.length && !((data.events)||[]).length){ctx.fillStyle='rgba(2,5,10,.74)';ctx.fillRect(0,0,w,h);ctx.fillStyle='#f3f7fa';ctx.font='14px Segoe UI, sans-serif';ctx.fillText('Nenhuma telemetria espacial recuperada para esta fase.',24,36)}
      };
      image.onerror=function(){ctx.fillStyle='#8b9aac';ctx.font='14px Segoe UI, sans-serif';ctx.fillText('Mapa da fase indisponivel.',24,36)};
      image.src=(data.maps&&data.maps[selected])||'';
    };
    function clamp(value,min,max){return Math.max(min,Math.min(max,value))}
    document.querySelectorAll('[data-phase]').forEach(function(button){button.addEventListener('click',function(){document.querySelectorAll('[data-phase]').forEach(function(item){item.classList.remove('active')});button.classList.add('active');selected=Number(button.dataset.phase)||selected;draw()})});
    charts.push(draw);draw();
  }
  window.registerLineChart=registerLineChart;
  window.registerScatterChart=registerScatterChart;
  window.registerBarChart=registerBarChart;
  window.registerRunMap=registerRunMap;
  let timer=0;window.addEventListener('resize',function(){clearTimeout(timer);timer=setTimeout(function(){charts.forEach(function(draw){draw()})},160)},{passive:true});
  if(!reduceMotion){
    document.querySelectorAll('[data-count-value]').forEach(function(node){
      const raw=Number(node.getAttribute('data-count-value'))||0;if(raw<=0||raw>9999999)return;
      const final=node.textContent,start=performance.now(),duration=720;
      function tick(now){const t=Math.min(1,(now-start)/duration),value=Math.round(raw*(1-Math.pow(1-t,3)));node.textContent=value.toLocaleString('pt-BR');if(t<1)requestAnimationFrame(tick);else node.textContent=final}
      requestAnimationFrame(tick);
    });
  }
  const searchDataNode=byId('operator-search-data'),input=document.querySelector('[data-search-input]'),results=document.querySelector('[data-search-results]');
  const searchData=searchDataNode?JSON.parse(searchDataNode.textContent||'[]'):[];
  function clearSearch(){if(results)results.innerHTML=''}
  if(input&&results){
    input.addEventListener('input',function(){
      const query=input.value.trim().toLowerCase();results.innerHTML='';
      if(!query){return}
      const matches=searchData.filter(function(item){return String(item.player||'').toLowerCase().includes(query)||String(item.build||'').toLowerCase().includes(query)}).slice(0,6);
      if(!matches.length){results.innerHTML='<div class="search-empty">Nenhum operador localizado</div>';return}
      matches.forEach(function(item){
        const link=document.createElement('a');link.href='/leaderboard/player/'+encodeURIComponent(item.key);link.setAttribute('role','option');
        const b=document.createElement('b');b.textContent=item.player||'Jogador';const s=document.createElement('span');s.textContent=item.build||'Build nao registrada';
        link.appendChild(b);link.appendChild(s);results.appendChild(link);
      });
    });
    input.addEventListener('keydown',function(event){if(event.key==='Escape'){input.value='';clearSearch();input.blur()}});
    document.addEventListener('click',function(event){if(!event.target.closest('[data-search-root]'))clearSearch()});
  }
})();`;
}

function siteCss() {
  return `
:root{
  color-scheme:dark;
  --void:#02050a;--void-soft:#050a11;--deep-space:#07101a;
  --surface:rgba(10,19,30,.92);--surface-soft:rgba(12,23,36,.78);--surface-strong:#0d1723;
  --rupture-cyan:#25f4e5;--rupture-cyan-soft:rgba(37,244,229,.16);--rupture-blue:#4aa8ff;--rupture-violet:#985cff;--rupture-magenta:#ff48bd;
  --survival-yellow:#ffc94a;--progress-green:#55ef8b;--danger-red:#ff5d68;
  --text-main:#f3f7fa;--text-soft:#8b9aac;--text-muted:#5f7185;
  --line:rgba(129,179,207,.17);--line-strong:rgba(129,213,224,.32);
  --content-width:1500px;--page-padding:clamp(18px,4vw,64px);
  --font-display:"Arial Narrow","Bahnschrift","Trebuchet MS",system-ui,sans-serif;
  --font-body:Inter,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --font-mono:"Cascadia Code","JetBrains Mono","IBM Plex Mono",Consolas,monospace;
  --space-1:6px;--space-2:10px;--space-3:16px;--space-4:22px;--space-5:32px;--radius:8px;--fast:.16s;--mid:.28s;
}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;min-height:100vh;background:
  radial-gradient(circle at 78% 8%,rgba(152,92,255,.16),transparent 34%),
  radial-gradient(circle at 14% 36%,rgba(37,244,229,.10),transparent 31%),
  radial-gradient(circle at 52% 96%,rgba(255,72,189,.09),transparent 28%),
  linear-gradient(180deg,#03070d 0%,#020409 62%,#010307 100%);
  color:var(--text-main);font-family:var(--font-body);letter-spacing:0;overflow-x:hidden}
body:before{content:"";position:fixed;inset:0;z-index:-2;pointer-events:none;background:
  linear-gradient(rgba(37,244,229,.026) 1px,transparent 1px),
  linear-gradient(90deg,rgba(37,244,229,.026) 1px,transparent 1px);
  background-size:38px 38px;mask-image:linear-gradient(to bottom,black,transparent 74%)}
body:after{content:"";position:fixed;inset:0;z-index:-1;pointer-events:none;background:
  linear-gradient(90deg,rgba(255,255,255,.025),transparent 18%,transparent 82%,rgba(255,255,255,.025)),
  radial-gradient(circle at center,transparent 46%,rgba(0,0,0,.64));mix-blend-mode:screen;opacity:.55}
a{color:inherit;text-decoration:none}
button,input{font:inherit}
img{image-rendering:auto}
.skip-link{position:absolute;left:12px;top:-60px;z-index:100;padding:10px 12px;background:var(--rupture-cyan);color:#00110f;font-weight:800}
.skip-link:focus{top:12px}
.topbar{position:sticky;top:0;z-index:40;display:grid;grid-template-columns:auto minmax(0,1fr) minmax(220px,320px);align-items:center;gap:22px;min-height:76px;padding:12px var(--page-padding);border-bottom:1px solid var(--line-strong);background:rgba(2,5,10,.88);backdrop-filter:blur(18px)}
.brand{display:grid;grid-template-columns:44px auto;align-items:center;gap:12px;min-width:260px}
.brand-mark{display:grid;place-items:center;width:44px;height:44px;border:1px solid var(--rupture-cyan);clip-path:polygon(10px 0,100% 0,100% calc(100% - 10px),calc(100% - 10px) 100%,0 100%,0 10px);color:var(--rupture-cyan);font-family:var(--font-mono);font-weight:900;box-shadow:inset 0 0 20px rgba(37,244,229,.13),0 0 22px rgba(37,244,229,.12)}
.brand b,.brand small,.brand em{display:block}.brand b{font-family:var(--font-display);font-size:18px}.brand small,.brand em{color:var(--text-soft);font-size:11px;text-transform:uppercase;font-style:normal}.brand em{grid-column:2;color:var(--rupture-cyan);font-family:var(--font-mono)}
.main-nav{display:flex;align-items:center;gap:8px;min-width:0;overflow:auto;scrollbar-width:thin}
.main-nav a{position:relative;flex:0 0 auto;padding:10px 12px;color:var(--text-soft);font-size:13px;text-transform:uppercase;font-weight:800}
.main-nav a:after{content:"";position:absolute;left:12px;right:12px;bottom:5px;height:2px;background:linear-gradient(90deg,var(--rupture-cyan),var(--rupture-magenta));transform:scaleX(0);transform-origin:left;transition:transform var(--fast)}
.main-nav a:hover,.main-nav a.active{color:var(--text-main)}.main-nav a:hover:after,.main-nav a.active:after{transform:scaleX(1)}
.nav-sync{display:inline-flex;align-items:center;gap:7px;flex:0 0 auto;margin-left:6px;color:var(--text-muted);font:11px var(--font-mono)}
.nav-sync i{width:8px;height:8px;border-radius:50%;background:var(--progress-green);box-shadow:0 0 12px var(--progress-green)}
.operator-search{position:relative}.operator-search label{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0)}
.operator-search input{width:100%;height:38px;padding:0 12px;border:1px solid var(--line);background:rgba(255,255,255,.035);color:var(--text-main);outline:none}
.operator-search input:focus{border-color:var(--rupture-cyan);box-shadow:0 0 0 3px rgba(37,244,229,.10)}
.search-results{position:absolute;top:calc(100% + 6px);right:0;width:min(360px,86vw);z-index:50;border:1px solid var(--line-strong);background:#07101a;box-shadow:0 22px 54px rgba(0,0,0,.52)}
.search-results:empty{display:none}.search-results a,.search-empty{display:block;padding:11px 12px;border-bottom:1px solid var(--line)}.search-results a:hover,.search-results a:focus{background:var(--rupture-cyan-soft)}.search-results b,.search-results span{display:block}.search-results span,.search-empty{color:var(--text-soft);font-size:12px}
main{position:relative;width:min(var(--content-width),100%);margin:auto;padding:34px var(--page-padding) 76px}
.page-heading{margin:8px 0 28px}.eyebrow{margin:0 0 8px;color:var(--rupture-cyan);font:800 11px var(--font-mono);letter-spacing:.08em;text-transform:uppercase}
.page-heading h1{margin:0;font-family:var(--font-display);font-size:clamp(34px,5.4vw,76px);line-height:.95;text-transform:uppercase}
.page-heading p{max-width:760px;color:var(--text-soft);font-size:16px;line-height:1.55}
.hero-terminal{position:relative;display:grid;grid-template-columns:minmax(0,1.35fr) minmax(310px,.65fr);gap:22px;min-height:420px;margin-bottom:24px;padding:clamp(22px,4vw,42px);border:1px solid var(--line-strong);background:
  linear-gradient(110deg,rgba(37,244,229,.12),rgba(10,19,30,.90) 43%,rgba(255,72,189,.08)),
  var(--surface);overflow:hidden;clip-path:polygon(18px 0,100% 0,100% calc(100% - 18px),calc(100% - 18px) 100%,0 100%,0 18px)}
.hero-terminal:before{content:"";position:absolute;inset:0;background:linear-gradient(90deg,transparent,rgba(37,244,229,.10),transparent);transform:translateX(-70%);animation:scan 7s linear infinite;pointer-events:none}
.hero-copy,.hero-operator{position:relative;z-index:1}.hero-copy{align-self:center}.hero-copy h2{max-width:860px;margin:0 0 18px;font-family:var(--font-display);font-size:clamp(42px,7vw,96px);line-height:.88;text-transform:uppercase}.hero-copy p{max-width:680px;color:#c5d5df;font-size:18px;line-height:1.65}
.hero-actions{display:flex;flex-wrap:wrap;gap:12px;margin-top:24px}.button{display:inline-flex;align-items:center;justify-content:center;min-height:42px;padding:10px 15px;border:1px solid var(--rupture-cyan);clip-path:polygon(10px 0,100% 0,100% calc(100% - 10px),calc(100% - 10px) 100%,0 100%,0 10px);font-weight:900;text-transform:uppercase;font-size:12px;transition:background var(--fast),color var(--fast),transform var(--fast)}
.button.primary{background:var(--rupture-cyan);color:#02100f}.button.ghost{background:rgba(37,244,229,.06);color:var(--rupture-cyan)}.button.disabled{border-color:var(--line);color:var(--text-muted);background:rgba(255,255,255,.03)}.button:hover{transform:translateY(-2px)}.button.full{width:100%}
.hero-operator{align-self:stretch;display:grid;align-content:center;justify-items:center;text-align:center;padding:24px;border:1px solid rgba(255,255,255,.10);background:rgba(2,5,10,.32)}
.hero-operator>span{font:800 11px var(--font-mono);color:var(--text-soft)}.hero-orbit{display:grid;place-items:center;width:178px;height:178px;margin:18px 0;border:1px solid var(--rupture-cyan);border-radius:50%;background:radial-gradient(circle,rgba(37,244,229,.14),transparent 64%);box-shadow:0 0 55px rgba(37,244,229,.15)}
.hero-orbit img,.hero-orbit .asset-fallback{max-width:132px;max-height:132px;object-fit:contain;image-rendering:auto}.hero-operator h3{margin:0;font-size:28px}.hero-operator strong{margin-top:8px;color:var(--rupture-cyan);font:900 36px var(--font-mono)}.hero-operator p{color:var(--text-soft);line-height:1.45}.hero-operator a{color:var(--rupture-cyan);font-weight:800}
.pulse-grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:12px;margin-bottom:24px}.metric{position:relative;min-height:146px;padding:18px;border:1px solid var(--line);border-top:3px solid var(--tone);background:linear-gradient(180deg,var(--surface),rgba(5,10,17,.92));overflow:hidden}
.metric:before{content:"";position:absolute;right:-28px;bottom:-36px;width:110px;height:110px;border:18px solid var(--tone);opacity:.045;transform:rotate(24deg)}.metric span{color:var(--tone);font:800 11px var(--font-mono)}.metric b{display:block;margin:14px 0 4px;color:var(--text-main);font:900 clamp(23px,2.4vw,36px) var(--font-mono);overflow-wrap:anywhere}.metric strong{display:block;text-transform:uppercase;font-size:12px}.metric small{display:block;margin-top:7px;color:var(--text-soft);line-height:1.4}
.tone-cyan{--tone:var(--rupture-cyan)}.tone-magenta{--tone:var(--rupture-magenta)}.tone-amber{--tone:var(--survival-yellow)}.tone-green{--tone:var(--progress-green)}.tone-red{--tone:var(--danger-red)}.tone-violet{--tone:var(--rupture-violet)}
.observatory-grid{display:grid;grid-template-columns:repeat(12,minmax(0,1fr));gap:22px}.span-12{grid-column:span 12}.span-8{grid-column:span 8}.span-7{grid-column:span 7}.span-5{grid-column:span 5}.span-4{grid-column:span 4}
.terminal-panel{position:relative;padding:20px;border:1px solid var(--line);background:linear-gradient(180deg,var(--surface),rgba(4,8,14,.92));box-shadow:0 20px 46px rgba(0,0,0,.24);overflow:hidden}.terminal-panel:before{content:"";position:absolute;left:12px;top:12px;width:76px;height:1px;background:linear-gradient(90deg,var(--rupture-cyan),transparent);opacity:.7}
.section-head{display:flex;align-items:flex-start;justify-content:space-between;gap:18px;margin-bottom:18px}.section-head h2{margin:0;font-family:var(--font-display);font-size:clamp(22px,2vw,32px);text-transform:uppercase}.section-head p:not(.eyebrow){margin:7px 0 0;color:var(--text-soft);line-height:1.45}.section-head>a{color:var(--rupture-cyan);font-weight:800;font-size:12px;text-transform:uppercase}
.run-list{display:grid;gap:8px}.run-row{border:1px solid var(--line);background:rgba(255,255,255,.025);transition:transform var(--fast),border-color var(--fast),background var(--fast)}.run-row:hover{transform:translateX(4px);border-color:var(--line-strong);background:rgba(37,244,229,.045)}.run-row-main{display:grid;grid-template-columns:170px minmax(0,1fr) 118px;align-items:center;gap:14px;padding:13px}.run-row time,.run-row small,.run-row-meta span{color:var(--text-soft);font-size:12px}.run-row b,.run-row small,.run-row-main span{display:block}.run-row-main span{color:var(--rupture-cyan);font:800 11px var(--font-mono)}.run-row strong{text-align:right;color:var(--rupture-cyan);font-family:var(--font-mono)}.run-row-meta{display:flex;align-items:center;gap:10px;flex-wrap:wrap;padding:0 13px 13px}
.status-badge{display:inline-flex;align-items:center;min-height:24px;padding:4px 8px;border:1px solid var(--tone);color:var(--tone);font:800 11px var(--font-mono);text-transform:uppercase;background:rgba(255,255,255,.025)}
.deck-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.compact-grid{grid-template-columns:1fr}.deck-card{display:grid;grid-template-columns:62px minmax(0,1fr);gap:12px;min-height:92px;padding:10px;border:1px solid var(--line);background:rgba(2,5,10,.48);transition:border-color var(--fast),transform var(--fast)}.deck-card:hover{transform:translateY(-2px);border-color:var(--rupture-magenta)}.deck-card.compact{grid-template-columns:44px minmax(0,1fr);min-height:58px;padding:7px}.card-art{display:grid;place-items:center;min-width:0;min-height:48px;background:#101924}.card-art img{width:100%;height:100%;max-height:100px;object-fit:contain}.card-copy{min-width:0}.deck-card b,.deck-card small{display:block}.deck-card b{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.deck-card small{margin-top:4px;color:var(--text-soft);font-size:11px}.deck-card small span{color:var(--survival-yellow)}.deck-card p{margin:8px 0 0;color:#c1d0d8;font-size:12px;line-height:1.42}
.asset-fallback{display:grid;place-items:center;width:100%;height:100%;min-height:42px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(135deg,rgba(37,244,229,.13),rgba(255,72,189,.10));color:var(--rupture-cyan);font:900 16px var(--font-mono)}
.campaign-line{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:10px}.campaign-stage{position:relative;padding:16px;border:1px solid var(--line);background:rgba(255,255,255,.025)}.campaign-stage.active{border-color:rgba(85,239,139,.45);background:rgba(85,239,139,.045)}.campaign-stage span{color:var(--rupture-cyan);font:900 28px var(--font-mono)}.campaign-stage b,.campaign-stage small{display:block}.campaign-stage small{color:var(--text-soft);margin-top:4px}
.player-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.player-tile{display:grid;gap:5px;padding:13px;border:1px solid var(--line);background:rgba(255,255,255,.025)}.player-tile:hover{border-color:var(--rupture-cyan);background:var(--rupture-cyan-soft)}.player-tile span{color:var(--rupture-magenta);font:900 13px var(--font-mono)}.player-tile small{color:var(--text-soft)}.player-tile i{color:var(--rupture-cyan);font-style:normal;font-weight:900}
.dual-signatures{display:grid;gap:18px}.dual-signatures h3{margin:0 0 8px;font-size:15px;text-transform:uppercase}.signature-list{display:grid;gap:8px}.signature-row{position:relative;display:grid;grid-template-columns:minmax(0,1fr) auto;gap:10px;padding:9px 0;border-bottom:1px solid var(--line)}.signature-row span{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.signature-row b{color:var(--tone)}.signature-row i{grid-column:1/-1;height:3px;background:var(--tone);box-shadow:0 0 12px var(--tone)}
.operator-highlight{display:grid;align-content:start;gap:7px;min-height:196px;padding:18px;border:1px solid var(--line);background:var(--surface)}.operator-avatar{width:64px;height:64px}.operator-highlight>span{color:var(--text-soft);font-size:11px;text-transform:uppercase}.operator-highlight b{font-size:20px}.operator-highlight strong{color:var(--tone);font:900 26px var(--font-mono)}.operator-highlight small{color:var(--text-soft);line-height:1.4}
.profile-hero,.run-header{display:flex;align-items:flex-end;justify-content:space-between;gap:22px;margin-bottom:24px;padding:24px;border-left:3px solid var(--rupture-cyan);background:linear-gradient(90deg,rgba(37,244,229,.09),var(--surface) 54%,rgba(152,92,255,.08))}.profile-hero h2,.run-header h2{margin:0;font-family:var(--font-display);font-size:clamp(36px,5vw,66px);text-transform:uppercase}.profile-hero p,.run-header p{color:var(--text-soft)}.profile-badges,.run-actions{display:flex;align-items:center;gap:8px;flex-wrap:wrap}.run-actions a,.back-link{color:var(--rupture-cyan);font-weight:800;font-size:12px;text-transform:uppercase}
.facts-list dl{margin:0}.facts-list dl>div{display:grid;grid-template-columns:1fr 1.35fr;gap:18px;padding:14px 0;border-top:1px solid var(--line)}.facts-list dt{color:var(--text-soft)}.facts-list dd{margin:0;text-align:right;font-weight:800}.facts-list dd small{display:block;color:var(--text-soft);font-weight:400}
.chart-wrap{position:relative;height:300px}.chart-wrap.large{height:460px}.chart-wrap canvas,.map-wrap canvas{display:block;width:100%;height:100%}.chart-legend,.map-legend{display:flex;gap:18px;flex-wrap:wrap;color:var(--text-soft);font-size:12px}.chart-legend span:before{content:"";display:inline-block;width:9px;height:9px;margin-right:6px;background:currentColor}.cyan{color:var(--rupture-cyan)}.amber{color:var(--survival-yellow)}.magenta{color:var(--rupture-magenta)}
.rankings-layout{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px;margin:22px 0}.ranking-column{padding:18px;border:1px solid var(--line);border-top:3px solid var(--tone);background:var(--surface)}.ranking-list a{display:grid;grid-template-columns:34px minmax(0,1fr) auto;gap:12px;align-items:center;padding:13px 0;border-top:1px solid var(--line)}.ranking-list a:hover strong{color:var(--tone)}.ranking-list a>b{color:var(--tone);font-family:var(--font-mono)}.ranking-list strong,.ranking-list small{display:block}.ranking-list small{margin:4px 0 8px;color:var(--text-soft);font-size:11px}.ranking-list i{display:block;height:3px;background:var(--tone)}.ranking-list span{text-align:right;font-weight:900}
.formula-text{color:#c1d0d8;line-height:1.75}.formula-text b{color:var(--rupture-cyan)}
.map-wrap{width:100%;aspect-ratio:16/9;min-height:320px;background:#05070b;border:1px solid var(--line)}.phase-switch{display:flex;gap:6px;flex-wrap:wrap}.phase-switch button{min-height:34px;padding:7px 10px;border:1px solid var(--line);background:#07101a;color:var(--text-soft);cursor:pointer}.phase-switch button:hover,.phase-switch button.active{border-color:var(--rupture-cyan);color:var(--rupture-cyan);background:var(--rupture-cyan-soft)}.map-legend{margin-top:12px}.map-legend i{display:inline-block;width:10px;height:10px;margin-right:6px}.map-legend .heat{background:var(--survival-yellow);box-shadow:0 0 8px var(--rupture-magenta)}.map-legend .damage{border-radius:50%;background:var(--danger-red)}.data-note{color:var(--text-soft);font-size:12px;line-height:1.55}
.threat-list{display:grid;gap:8px}.threat{display:grid;grid-template-columns:56px minmax(0,1fr);align-items:center;gap:12px;padding:10px;border-bottom:1px solid var(--line)}.threat-icon{display:grid;place-items:center;width:56px;height:56px;background:#08101a}.threat-icon img{width:100%;height:100%;object-fit:contain}.threat b,.threat small{display:block}.threat small{margin:4px 0 8px;color:var(--text-soft);font-size:11px}.threat i{display:block;height:4px;background:linear-gradient(90deg,var(--danger-red),var(--survival-yellow))}
.empty-state{display:grid;gap:5px;padding:18px;border:1px dashed var(--line);color:var(--text-soft);background:rgba(255,255,255,.02)}.empty-state b{color:var(--text-main)}.empty-page{min-height:420px;display:grid;place-items:start;align-content:center;padding:32px;border:1px solid var(--line);background:var(--surface)}.empty-page h2{margin:0;font-size:clamp(30px,5vw,62px);font-family:var(--font-display);text-transform:uppercase}.empty-page p{color:var(--text-soft)}
.terminal-footer{display:grid;gap:6px;padding:28px var(--page-padding);border-top:1px solid var(--line);background:rgba(2,5,10,.84);color:var(--text-soft);font-size:12px}.terminal-footer b{color:var(--rupture-cyan);font-family:var(--font-mono)}
@keyframes scan{0%{transform:translateX(-80%)}100%{transform:translateX(80%)}}
@media (prefers-reduced-motion: reduce){*{scroll-behavior:auto!important;animation:none!important;transition:none!important}}
@media (prefers-contrast: more){:root{--line:rgba(210,240,255,.35);--text-soft:#c8d8e2}.terminal-panel,.metric,.run-row{border-color:var(--line-strong)}}
@media(max-width:1180px){.topbar{grid-template-columns:1fr}.brand{min-width:0}.operator-search{max-width:420px}.pulse-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.span-8,.span-7,.span-5,.span-4{grid-column:span 12}.hero-terminal{grid-template-columns:1fr}.rankings-layout{grid-template-columns:1fr}}
@media(max-width:760px){main{padding-left:16px;padding-right:16px}.topbar{position:relative;padding:12px 16px}.main-nav{width:100%;padding-bottom:4px}.page-heading h1{font-size:38px}.hero-copy h2{font-size:42px}.pulse-grid,.campaign-line,.player-grid{grid-template-columns:1fr}.run-row-main{grid-template-columns:1fr}.run-row strong{text-align:left}.deck-grid{grid-template-columns:1fr}.section-head,.profile-hero,.run-header{flex-direction:column;align-items:flex-start}.facts-list dl>div{grid-template-columns:1fr}.facts-list dd{text-align:left}.chart-wrap.large{height:330px}.map-wrap{min-height:230px}.terminal-panel{padding:16px}.brand em{display:none}}
`;
}

module.exports = { renderLeaderboardSite };
