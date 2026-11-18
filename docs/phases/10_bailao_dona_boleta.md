# Fase 10 — Bailão da Dona Boleta

> Status: **gameplay implementado com arte final integrada** (entregue pelo Codex
> em 18/11/2026; conferida em captura desktop 1280 × 720). Pendentes: trilha a
> 130 BPM, conferência em Android físico e multiplayer.

## Tema / regra central

Um baile de eletrofunk numa quadra de concreto rachada pela Ruptura. Toda a
família é de borboletas — óculos Juliet, correntes douradas, algumas com
guarda-chuva — e **ninguém para de dançar para lutar**.

**Regra central — A Batida.** Um relógio de batida global (`beat clock`) dita o
combate. Inimigos se deslocam e atacam *na batida*, nunca fora dela: a música é
o aviso. Quem aprende o ritmo lê a fase.

Base musical pesquisada (ver Fontes):

- Eletrofunk é um ramo de clube do funk carioca: kick reto de electro/electro
  house sobre a síncope do tamborzão, palmas brilhantes e viradas de
  tom/percussão, MC em call-and-response.
- Andamento de catálogo: **~128–131 BPM**. O funk em geral fica em ~130 BPM e,
  desde 2019, a variação acelerada de **150 BPM** (mandelão/rave) virou marca da
  cena — usada aqui como a "virada" do Estágio 2 do boss.
- Dança: passinho (pés rápidos, deslocamentos curtos), e a ênfase de
  ombro/rosto/mãos popularizada pelos enquadramentos fechados do TikTok.

### Tradução para o movimento (contrato do beat clock)

| Parâmetro | Valor inicial | Uso |
| --- | --- | --- |
| BPM base | 130 (batida = 0,4615 s) | Fase inteira até o Estágio 2 do boss |
| BPM virada | 150 (batida = 0,4 s) | Estágio 2 do boss ("Remix Mandelão") |
| Compasso | 4 batidas | Ataques "no 4" |
| Síncope tamborzão | semicolcheias 0, 3, 6 de cada grupo de 8 (3+3+2) | Microimpulsos do passinho |
| Drop | a cada 16 batidas (~7,4 s) | 1 batida de congelamento + arrancada |

Movimento de borboleta (todas as espécies dançantes):

1. **Passinho** — em vez de velocidade contínua, cada inimigo dá *impulsos*
   nos pulsos 3+3+2: aceleração curta (0,12 s) e desaceleração rápida. A
   velocidade média equivale à de um comum normal; a leitura é "sai do lugar no
   tum, para no tá".
2. **Balanço lateral** — entre impulsos, oscilação perpendicular ao alvo
   (amplitude 6–10 px, fase por instância) para não andarem em fila.
3. **Drop** — na batida 15 todo mundo *trava* (pose, asas abertas: aviso
   visual/sonoro); na batida 16 arranca com 1,8× de impulso. É a janela de
   punição: o jogador vê o congelamento e se reposiciona.

Timers são em segundos derivados do BPM; nada depende da contagem de frames.

### Efeito colateral — Teor (embriaguez de Geovana)

Cada garrafa que acerta Geovana soma **Teor** (0–100). Decai 6/s após 2 s sem
novo acerto. Efeitos **somente visuais** (nunca dano invisível, nunca inversão
de controle — injusto no touch):

| Teor | Efeito |
| --- | --- |
| ≥ 20 | Vinheta quente que balança (pulsa) — a câmera em si não é movida |
| ≥ 45 | Visão dupla: aberração cromática e "fantasma" deslocado dos inimigos |
| ≥ 70 | Ilusões: 2–4 borboletas falsas translúcidas (sem colisão/dano), distorção ondulada |
| 100 | "Apagão" de 1 s (tela escurece 70%) e Teor volta a 60 |

Avisos de ataque (marcadores no chão) **não são distorcidos**: a leitura do
perigo permanece honesta. Modo leve: reduz sway/ondulação pela metade e
desliga ilusões.

## Entrada na campanha

Rota normal: entra em `DIMENSION_ROUTE_POOL` como dimensão de farm. Não é fase
inicial. Saída pelo controlador de rota existente (nunca `id + 1`).

## Mapa / altar

Perfil expandido padrão (3200 × 2250, células 384, atlas 4 × 4, chave proposta
`phase10_baile_terrain_atlas`). Identidade: concreto de quadra com linhas
pintadas gastas, poças refletindo luz, fios de gambiarra, **paredões de som**
como obstáculos sólidos (contrato compartilhado de colisão), barracas de
bebida. Paleta: concreto dessaturado; luzes com função — **âmbar/laranja**
(perigo, holofote), **magenta** (identidade do baile), **ciano** só na Ruptura
e no altar.

**Altar = palco.** O palco da Dona Boleta ocupa o índice 5 do atlas (centro do
encontro). Ela está lá **desde o início**, cantando: obstáculo sólido,
invulnerável (`hit` ignorado), não atravessável. A interação de invocação é o
microfone na boca do palco. A música da fase é "a voz dela".

## Elenco (1 + 4 + 1 + 1)

| Papel / ID | Mecânica e resposta do jogador | Liberação / teto / cooldown |
| --- | --- | --- |
| **Comum — Monarca do Passinho** (`borboleta_monarca`) | Persegue com passinho na síncope; contato corpo a corpo. No drop, arrancada. Resposta: ler o congelamento e sair da linha antes da arrancada. | Desde o início; curva compartilhada de comum. |
| **Especial 1 — Garrafeira** (`borboleta_garrafeira`, borboleta-coruja) | Mantém 260–360 px; **no 4 de cada compasso** arremessa garrafa em arco com marcador no chão (aviso 1 compasso). Tipos: *whisky* (mais dano, Teor 14), *gin* (poça de 70 px por 5 s que reduz 25% da velocidade, Teor 8), *vodka* (pouco dano, Teor 24 — a que mais embriaga). Arremessa a cada 2 compassos (paridade por instância); com Embalo, todo compasso. Resposta: sair do marcador; priorizar Garrafeiras quando Teor sobe. | Libera aos 35 s; teto 4; intervalo mín. 9 s. |
| **Especial 2 — Sombrinha** (`borboleta_sombrinha`, asa-de-vidro com guarda-chuva) | Escudo frontal (cone 100°) bloqueia projéteis do jogador; no drop gira a sombrinha e **devolve** o próximo projétil bloqueado. Gosta de ficar à frente de Garrafeiras. Resposta: flanquear / atacar pelas costas, melee. | Libera aos 70 s; teto 3; intervalo mín. 14 s. |
| **Especial 3 — Paredinha** (`borboleta_paredinha`, mariposa-atlas com caixinha de som) | Controle de espaço: planta-se e emite **ondas de grave** em anel a cada 2 batidas (anel visível expandindo 0→220 px); o anel empurra (knockback 140 px/s) e dá dano leve só na borda. Resposta: atravessar entre anéis no contratempo ou destruí-la. | Libera aos 110 s; teto 2; intervalo mín. 18 s. |
| **Especial 4 — Hype** (`borboleta_hype`, morpho azul "puxadora de bonde") | Suporte: aura de **Embalo** (raio 200 px) — aliados ganham +20% velocidade nos impulsos e Garrafeiras lançam 2 garrafas por compasso. Foge do jogador. Ao morrer, aliados no raio perdem o embalo e ficam 1 compasso "atordoados". Resposta: caçar a Hype primeiro. | Libera aos 150 s; teto 2; intervalo mín. 20 s. |
| **Miniboss — Lagartona do Paredão** (`lagartona_paredao`) | Ver seção própria. | 1 por visita, aos ~200 s; máx. 1 viva. Cancelada se o boss for chamado antes. |
| **Boss — Dona Boleta** (`boss10`) | Ver seção própria. | Altar/palco pelo fluxo compartilhado. |

Fallback: tetos atingidos → spawn vira Monarca. Ilusões de Teor, garrafas,
poças e anéis são auxiliares, não ocupam vagas de especiais.

## Miniboss — Lagartona do Paredão, "Bonde do Casulo"

Uma lagarta gigante (a borboleta que ainda não virou) arrastando um **trenzinho
de 6 segmentos-caixa-de-som** nas costas. Ela não dança — ela *é* o paredão.

| Ataque | Condição → aviso → execução → recuperação |
| --- | --- |
| **Trenzinho** | Jogador > 300 px → linha de luzes de chão traça o caminho por 1 compasso → investida seguindo a linha em S (corpo segmentado colide; segmentos seguem a cabeça) → 1 compasso parada ofegante (cabeça vulnerável, +30% dano). |
| **Grave Pesado** | Jogador < 300 px → segmentos acendem em sequência (1 batida cada) → cada segmento solta cone de grave de 70° para o lado em que o jogador está → 2 batidas de resfriamento. |
| **Vira-Vira** | A cada 3º ciclo → a cauda pisca → o corpo se fecha em círculo ao redor do jogador (raio 240) e gira 1 volta; a abertura do círculo é marcada → recuperação: cabeça tonta 1,5 s. |
| **Casulo** (≤ 35% vida, uma vez) | Corpo se enrola, 3 s de armadura (dano 20%), segmentos disparam garrafas no 4. Ao sair, perde 2 segmentos (menos alcance) mas sobe para tempo 150 BPM. |

Morte: segmentos desabam em sequência no ritmo; recompensa padrão de miniboss
(pontos + fragmento). Limpeza: remove linhas de luz, cones e garrafas próprias.

## Boss — Dona Boleta, "A Rainha do Bailão"

Borboleta-imperatriz enorme, óculos Juliet espelhado, microfone cravejado,
casaco de pelúcia sobre as asas. Está **no palco desde a entrada na fase**:
cantando, sólida, sem hitbox de dano, bloqueando a passagem.

**Invocação:** interagir com o microfone do palco (fluxo de altar existente).
Ela solta o refrão, **desce do palco** (entrada de 2,2 s: salto com asas abertas
até a âncora do encontro; o palco permanece como obstáculo de fundo) e a
batalha começa. Ao chamar o boss: remove especiais, miniboss, poças e garrafas
da fase (`clear_for_boss_call`).

### Estágio 1 — 130 BPM (100% → 50%)

| Ataque | Condição → aviso → execução → recuperação |
| --- | --- |
| **Holofote + Rojão** | A cada 2 compassos → 1 holofote varre o chão até o jogador (cone de luz âmbar) e **trava** no círculo-alvo (0,8 s, círculo pisca no tempo) → rojão cai do teto no círculo travado (raio 90, dano alto) + fagulhas → 1 batida. Os círculos travados não seguem o jogador: sair resolve. |
| **Chuva de Garrafa** | Jogador > 260 px → ela aponta com o microfone → 4 garrafas, uma por batida, em marcadores que caminham em direção ao jogador → poses de 1 compasso (janela de dano). |
| **Grave do Microfone** | Jogador < 260 px → ela inspira (1 batida, anel de ar puxado) → cone de som 60° × 380 px a partir da boca → 2 batidas de recuperação, de costas. |
| **Sarrada** | Após 3 ataques → passos de dança laterais com 3 dashes curtos no ritmo (trilhas marcadas antes de cada dash) → 1 compasso de pose. |

### Habilidade assinatura — **A Roda**

A cada ~25 s (e obrigatória ao entrar no Estágio 2):

1. **Condição:** boss não está em outro ataque.
2. **Aviso (1 compasso):** ela grita "ABRE A RODA!"; um anel de pontos magenta
   aparece no chão envolvendo **jogador e boss** (centro = ponto médio, raio
   inicial = distância/2 + 140, mínimo 260).
3. **Execução (16 batidas):** 24 borboletas dançantes formam a roda, girando
   (passinho circular, sentido alterna a cada 4 compassos). **Nenhum dos dois
   pode sair:** a roda é uma parede circular (clamp de posição de jogador e
   boss; contato com dançarina = empurrão para dentro + dano leve). A roda
   **expande** de 260 → 520 px ao longo da duração. A cada compasso, 3
   dançarinas (marcadas por um brilho 1 batida antes) arremessam garrafa
   para dentro, em direção a Geovana. Dentro, o boss continua usando o
   Estágio atual com cooldowns ×1,3.
   **Público:** fora do círculo, uma multidão densa fecha todo o chão. São
   fileiras de borboletas das seis espécies, com tamanho, tom, espelhamento e
   balanço variados. Ela chega de fora para dentro durante o aviso e se dispersa
   no fim. Implementação: `scripts/presentation/baile_crowd_presentation.gd`.
   - Disposição montada uma vez por fase.
   - Um MultiMesh por espécie e quadro de dança.
   - Giro, raio e batida são uniforms de shader, com custo de CPU por quadro
     praticamente zero.
   - Camada `show_behind_parent`: acima do chão e abaixo das entidades.
   - Volume: ~4000 instâncias no modo normal e ~1500 no leve, com um anel escuro
     por baixo cobrindo os vãos.
4. **Recuperação:** a roda se desfaz em 1 compasso; o boss fica 1,5 s parado
   "agradecendo a plateia" (janela de dano +25%).

As dançarinas são auxiliares (sem vida própria, não contam como inimigos).
Limpeza garantida em morte do jogador, morte do boss, reinício e transição.

### Estágio 2 — "Remix Mandelão", 150 BPM (≤ 50%)

Transição: a música vira para 150 BPM, ela joga o casaco fora. Todos os
timers recalculam pelo novo BPM. Holofote passa a usar **3 holofotes** em
sequência; Chuva de Garrafa vira 6 garrafas; A Roda já começa com raio 320.

### Morte / recompensa / saída

A música corta seco; as borboletas da roda se espalham; ela cai sentada no
palco. Recompensa e saída pelo fluxo compartilhado de boss/rota.

## Owners / hooks alterados

Lógica (owners próprios, padrão da Fase 9):

- `scripts/systems/phase10/baile_beat_clock.gd` — `RTBaileBeatClock`: BPM,
  compasso, síncope 3+3+2, congelamento/drop, `step_multiplier`, `sync` de réplica.
- `scripts/systems/phase10/baile_controller.gd` — `RTBaileController`: elenco,
  `choose_enemy_type`/`special_available` (liberação, teto, intervalo),
  `spawn_stats`, `on_spawned`, `update_enemy`, garrafas, poças, anéis, tiros da
  Sombrinha, Teor por jogador, palco sólido (`stage_rect`, `push_out_of_stage`,
  `bullet_hit`), agenda do miniboss, `clear_for_boss_call`, snapshots.
- `scripts/systems/phase10/baile_lagartona.gd` — `RTBaileLagartona` (FSM do miniboss).
- `scripts/systems/phase10/boss10_controller.gd` — `RTBoss10Controller`.
- `scripts/presentation/baile_presentation.gd` — `RTBailePresentation`.

Hooks curtos (espelhando os da Cripta): `main_runtime_state.gd` (controladores,
`BOSS10_HP_SCALE`, `DIMENSION_FARM_POOL` + 10), `main_runtime_core.gd` (bind,
atualização autoridade/réplica, escolha/estatística/spawn/morte de inimigo,
multiplicadores de dano, absorção de tiro pelo palco, lentidão do gin, raio,
update/morte do boss, trava de chamada com a Lagartona viva, chamada do boss,
limpeza de hazards, nome/ícone no relatório, atlas `map_phase_ex10`),
`enemy_manager.gd`, `phase_flow_controller.gd` (`_setup_baile`, nome da região,
início forçado até 10), `experimental_phase_controller.gd` (perfil 10 e bloqueio
do altar), `entity_visual_profiles.gd`, `combat_effects_presentation.gd`,
`world_environment_presentation.gd`, `runtime_boss_visual_sync_controller.gd`
(`baile_visual`/`boss10_visual`), `catalog_interface.gd`.

## Parâmetros dos ataques (resumo do que está no código)

| Ataque | Aviso | Geometria | Execução / recuperação |
| --- | --- | --- | --- |
| Garrafa | marcador no chão durante o voo (2 batidas) + pose no 3 | círculo 46 px no marcador | dano 2,5–5% + Teor / — |
| Devolução da Sombrinha | congelamento do drop | projétil r 18, 340 px/s | 4% |
| Anel de grave | anel visível expandindo 0→220 em 2 batidas | faixa ±16 px | empurra 140 px/s, 2% uma vez por anel |
| Trenzinho | luzes de chão em S, 4 batidas | corpo (cabeça + segmentos r 34) | 520 px/s, 6% / ofegante 4 batidas (+30%) |
| Grave Pesado | segmento acende 1 batida | cone 70° × 260 | 4% / 2 batidas |
| Vira-Vira | anel verde 1 batida | círculo r 240 | 1 volta em 8 batidas, 6% / tonta 1,5 s (+50%) |
| Holofote + Rojão | feixe varre 4 batidas, trava 0,8 s | círculo 90 px | 9% / — (1 ou 3 holofotes) |
| Chuva de Garrafa | mira 1 batida | marcadores 46 px | 4/6 garrafas, uma por batida / pose 4 batidas (+25%) |
| Grave do Microfone | inspiração 1 batida (anel puxando) | cone 60° × 380 | 8% / de costas 2 batidas (+30%) |
| Sarrada | trilha marcada 1 batida antes de cada dash | varredura r 60 | 3 × 220 px, 6% / pose |
| A Roda | 36 pontos magenta, 4 batidas | círculo 260/320 → 520 | contém jogador e boss, toque 2%, 3 garrafas por compasso / agradece 1,5 s (+25%) |

## Limpeza / pausa / persistência / autoridade

- `clear_for_boss_call` remove garrafas, poças, anéis, tiros e o rastro da
  Lagartona; `_clear_boss_runtime_hazards` também zera holofotes e Roda.
- Morte do boss limpa holofotes, Roda e garrafas e devolve o BPM a 130.
- Todos os timers avançam só no `update` da fase (respeita pausa/loja/Mercador
  porque o hook fica dentro do bloco `not _merchant_dimension().active`).
- Nenhum estado novo persistido em save: ao retomar, a fase reinicia o relógio.
- Autoridade decide IA/dano/Teor de todos; réplica recebe `baile_visual` /
  `boss10_visual`, anima e aplica localmente empurrões, palco e limite da Roda.

## Arte (final integrada)

Diretório `assets/sprites/baile/`, gerado por `tools/baile_placeholder_sprites.py`.
Pivô: pés no centro inferior do canvas; direção original: direita (flip por
`facing_dir`). Trocar os PNGs mantendo nome e canvas não exige mudar lógica.

| Entidade | Chaves | Canvas | Tamanho no mundo |
| --- | --- | --- | --- |
| Borboletas (5 espécies + dançarina da Roda) | `b10_<especie>_0..3` (0/1 dança, 2 ataque, 3 pose do drop) | 140–170 px | 84–100 px (dançarina 72) |
| Lagartona | `b10_lagartona_0..3`, `_attack`, `_daze`; `b10_segmento_0/1/casulo` | 170 / 130 | 150 / 100 |
| Dona Boleta | `boss10_idle_0..3`, `sing_0..3`, `attack_0..1`, `roda_0..1`, `daze_0..1`, `remix_0..1`, `death_0..3` | 360 × 300 | 360 × 300 (âncora: microfone) |
| Palco | `b10_palco` | 520 × 300 | retângulo 480 × 200 + 100 px de fundo |
| Garrafas | `b10_garrafa_whisky/gin/vodka` | 48 | 34 |
| Terreno | `experimental/phase_ex10_terrain_atlas.png` (4 × 4, índice 5 = piso do palco) | 1252 | células 384 |

Pendências de arte: frames finais de todas as entidades, atlas ilustrado no
padrão da EX7, trilha de eletrofunk a 130 BPM (com virada a 150) — o relógio é
o mestre e a música deve ser produzida nesse andamento.

## Validação

Executado em 18/11/2026 (Godot 4.7, Linux):

- Parse `--check-only` de todos os scripts novos e alterados: sem erros.
- `tests/phase10_baile_smoke.gd` (headless, solo): **OK**. Cobre rota (pool de
  farm, ~50% dos ciclos), entrada, mapa/atlas, texturas, relógio (média do
  passinho ~1,0, congelamento e drop), Monarca parada no aviso, liberação/teto/
  intervalo dos especiais, Garrafeira, garrafa→dano+Teor, apagão em 100, gin,
  Sombrinha (frente/costas/devolução), Paredinha (planta, anel empurra), Hype
  (embalo e atordoamento), palco sólido e absorção de tiro, Lagartona (agenda,
  trava do altar, todos os estados, casulo, morte, sem reaparecer), invocação
  (limpeza, descida invulnerável, âncora), todos os modos do boss, holofote,
  rojão, Roda contendo jogador e boss, Remix 150 BPM, morte e snapshot.
- Regressão (headless): `phase9_cripta_smoke`, `phase8_sertao_smoke`,
  `experimental_phase_smoke`, `phase_transition_smoke`,
  `special_spawn_pacing_smoke`, `phase3_enemy_variety_smoke`: **OK**.
- Capturas com janela (`tests/phase10_capture.gd`, normal e `--low`), em
  1280 × 720: palco, pista, Teor, Lagartona, descida, holofote, Roda e Remix.
  Ficam em `.codex/phase10/`, que não é versionado.
- `git diff --check`: OK. `tools/check_architecture_budget.py` já falhava
  antes desta fase (shop, enemy_manager, phase_flow, world_environment,
  progression). A fase acrescenta só os hooks curtos nesses arquivos.

Não exercitado / pendente: arte final e conferência visual em Android físico
(paisagem, modo leve, custo real), trilha musical, partida longa completa com a
Geovana real, multiplayer (ver `.agents/MULTIPLAYER_DEFERRED_VALIDATION.md`).

## Fontes da pesquisa

- [Beatport — Depende (Eletrofunk)](https://www.beatport.com/track/depende-eletrofunk/27911500) — andamento de catálogo ~131 BPM.
- [Melodigging — Eletrofunk](https://www.melodigging.com/genre/eletrofunk) — definição do gênero.
- [Correio Braziliense — movimento 150 BPM](https://www.correiobraziliense.com.br/app/noticia/diversao-e-arte/2019/02/18/interna_diversao_arte,738095/djs-explicam-como-funciona-o-movimento-150-bpm.shtml) — 130 → 150 BPM.
- [Billboard Brasil — dança do baile funk](https://billboard.com.br/danca-extrapola-baile-funk-e-ganha-o-mundo-para-demarcar-identidade-da-quebrada/) — passinho, ombro/rosto/mãos.
