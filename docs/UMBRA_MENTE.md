# Mente da UMBRA (v3)

## Camadas
| camada | onde | quem escreve | como entra |
|---|---|---|---|
| base | `assets/data/umbra_mind_base.json` (vai no jogo) | treino headless (`tools/umbra_mind_collect.gd` + `tools/umbra_mind_fit.py`) | substitui os zeros |
| coletiva | `user://umbra_mind/umbra_collective_mind.json` | VPS (`server/umbra_collective.js`), muda a cada partida | `mode: blend` com `confidence` ≤ 0,7 |
| jogador | `user://umbra_mind/umbra_player_mind.json` | o próprio aparelho, ao fim de cada encontro | soma vieses por ação + priors |
| fases | `RTUmbraPhaseObserver` (run atual) | observa desvios nas fases 1–4/6/7 | priors do kit base com peso 2 |

`RTUmbraMind.apply()` soma `W[ação]·contexto` (12 features) às pontuações
heurísticas de `_umbra_choose_action()`. O executor continua validando tudo, então a
mente só muda a preferência entre ações que já são legais.

## Kit base (dimensão base)
`RTUmbraBaseSkills`:
- **REBOBINAR**: marca o jogador e, 1,5 s depois, puxa ele para a âncora, com dano e 0,35 s de atordoamento. Teleportar quebra a marca.
- **ECO_PROFETICO**: sigilo na posição prevista, com detonação em 1,1 s. Aprende `eco_along` e `eco_side`. Com experiência, cobre os dois lados. Com Rebobinar armado, o sigilo cai na âncora.

## Treino headless (no PC)
```
godot --headless --path . --script res://tools/umbra_mind_collect.gd -- --budget=150 --seconds=45 --epsilon=0.25 --seed=N --out=res://.agent_logs/umbra_train/rK_sN.jsonl
python3 tools/umbra_mind_fit.py ".agent_logs/umbra_train/r*_*.jsonl" --out assets/data/umbra_mind_base.json --blend 0.5
godot --headless --path . --script res://tools/umbra_mind_collect.gd -- --episodes=20 --epsilon=0 --lead_jitter=0 --seed=4242 [--nomind=1]   # avaliação
```
- O oponente é o bot Apolo com build de fim de run e reflexo variável. Ele desvia dos sigilos e foge do Rebobinar.
- Retorno de cada decisão: 10·(dano causado nos próximos 3 s ÷ vida máxima) − 30·(dano sofrido ÷ vida máxima da UMBRA).
- Base r3, avaliada em sementes novas: dano causado 0,26 contra 0,20 sem a mente.

## VPS
- O cliente manda `umbra_combat` no relatório da run, com X'X e X'y por ação, plasma (tiros e acertos) e priors. Manda também `umbra_phase_lessons`.
- O servidor acumula tudo em `${LEADERBOARD_PATH}.umbra_collective.json`, com decaimento de 0,998 por partida. Esse acumulador não gira com o ranking.
- O servidor faz uma regressão ridge global e serve o resultado em `/umbra/mind/latest` como `umbra_collective_mind.json`.
- O cliente consulta a VPS no menu, no máximo a cada 10 minutos, e de novo depois de cada run.

## Testes
`tests/umbra_base_skills_smoke.gd`, `tests/umbra_mind_layers_smoke.gd`, `server/umbra_collective_smoke.js`, `server/umbra_mind_smoke.js`.
Demos: `tests/umbra_skills_visual_demo.gd` e `tests/umbra_base_skills_gif_demo.gd`.

## Arte (lote 1 das habilidades + corpo v3)
- **Corpo**: `assets/sprites/umbra_v3/<anim>_NN.png` (30 frames, 256×384). Animações em `RTUmbraBossAnimation`: idle, ataque, teleporte, sifao, transmutar, rebobinar, eco, conjurar, dano, morte. Recorte: `tools/umbra_v3_slice.py`.
- **Habilidades**: `assets/sprites/umbra_skills/<grupo>/<nome>_NN.png`, grupos `plasma`, `teleporte`, `sifao`, `rebobinar`, `eco`. Recorte: `tools/umbra_skills_slice.py`, que também desloca o vazio roxo das folhas para o azul-marinho do corpo v3.
- Cada VFX cai no procedural quando o PNG não existe, então o jogo nunca fica sem efeito.
- Falta o lote 2 (dimensões: Vórtice, Sopro Ártico, Miasma, Descarga, Espinhos, Laser, Ratos, Transmutar) — pedido em `.agents/codex_requests/umbra_skills_batch2.md`.
