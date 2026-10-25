# Boss 4 — Nexo Anfíbio

## Estado anterior registrado

- Branch de trabalho: `runtime-refactor-next`; commit inicial inspecionado: `de2e3468a4dc5e81d424460743b7e3e9139b88ed`.
- A apresentação carregava somente três PNGs antigos (`Boss4_1`, `Boss4_2` e `Boss4_3`) e alternava essencialmente entre repouso e ataque.
- A posição era reescrita para `boss4_entry_target` durante a atualização, portanto o corpo não tinha locomoção real.
- O wrapper de ataque contextual disparava apenas cometa. Fissuras, salto, vazamento, prisão, clone, vampirismo, fragmentos, gravidade, colapso e meteoritos existiam como auxiliares, mas não formavam um repertório contextual completo.
- A ultimate possuía contador de âncoras, porém não criava as âncoras, e o fim do cronômetro concluía o evento como sucesso automático.
- Evidências anteriores: `.codex/boss4_rework_before/`.

## Identidade e atlas

O chefe final é um sapo astronauta bípede, monstruoso e pesado, com traje espacial rompido absorvendo energia violeta/esverdeada da Ruptura. A silhueta selecionada foi o estudo B de `.codex/boss4_rework_art/silhouette_studies.png`.

Todos os frames finais são inéditos e ficam em `assets/sprites/boss4_rework/`. Os três PNGs antigos permanecem apenas como arquivo legado e não são mais carregados pelo Boss 4.

| Estado | Frames |
|---|---:|
| idle | 4 |
| walk | 4 |
| hit | 2 |
| jump | 2 |
| land | 2 |
| slam | 4 |
| tongue | 4 |
| comet | 4 |
| gravity | 4 |
| transição de HP | 4 |
| ultimate | 3 |
| ultimate interrompida | 2 |
| ultimate concluída | 2 |
| death | 6 |

Cada frame usa canvas transparente de 384×384, pivô lógico `(192, 366)`, escala de desenho fixa de 224×224 e filtro nearest. O manifesto é `assets/sprites/boss4_rework/boss4_animation_manifest.json`.

## Corpo, FSM e contato

`RTBoss4Controller` é o proprietário autoritativo da locomoção e da seleção de ataques. A máquina de estados percorre `walk/idle -> windup -> active -> recover`, além de `jump`, `land`, `transition`, `stun` e `ultimate`.

- Velocidade: 92 px/s.
- Distância de combate preferida: 205–335 px.
- Contato: raio de 92 px, cooldown individual de 0,92 s por jogador e knockback de 118 px.
- A posição deixa de ser fixa após a entrada.
- O chefe evita repetir o último ataque e penaliza os dois ataques recentes.
- Clientes recebem o snapshot da FSM, estágio, ataque anterior e estado da ultimate; dano e escolha de ação permanecem no host.

## Ataques por estágio

| Vida | Estágio | Repertório contextual |
|---|---:|---|
| 100–75% | 1 | pancada frontal, língua de ruptura e cometa canalizado |
| 75–50% | 2 | repertório anterior + salto esmagador, fissura e vazamento do traje |
| 50–25% | 3 | repertório anterior + prisão orbital, clone, combo de três golpes e vampirismo somente se Petro estiver ativo |
| 25–0% | 4 | repertório anterior + fragmentos cósmicos, gravidade/feixe, colapso vetorial, meteoritos e Singularidade Absoluta |

### Tempos por ação

| Ação | Antecipação | Ativa | Recuperação | Cooldown |
|---|---:|---:|---:|---:|
| pancada | 0,62 s | 0,14 s | 0,55 s | 4,6 s |
| língua | 0,58 s | 0,16 s | 0,48 s | 6,2 s |
| cometa | 0,52 s | 0,12 s | 0,43 s | 5,2 s |
| salto | 0,54 s | 0,74 s | 0,62 s | 8,4 s |
| fissura | 0,72 s | 0,12 s | 0,58 s | 10,5 s |
| vazamento | 0,76 s | 0,12 s | 0,62 s | 14,5 s |
| prisão | 0,76 s | 0,12 s | 0,64 s | 13 s |
| clone | 0,64 s | 0,12 s | 0,58 s | 11,5 s |
| vampirismo | 0,88 s | 0,12 s | 0,68 s | 18 s |
| combo | 0,54 s | 1,44 s | 0,68 s | 14 s |
| fragmentos | 0,68 s | 0,12 s | 0,56 s | 9,5 s |
| gravidade | 0,78 s | 0,12 s | 0,72 s | 12 s |
| colapso | 0,82 s | 0,12 s | 0,72 s | 11 s |
| meteoritos | 0,92 s | 0,12 s | 0,76 s | 20 s |

O intervalo global entre ações cai por estágio: 1,35 s, 1,16 s, 1,02 s e 0,88 s. Os golpes corpo a corpo aplicam o dano somente no frame ativo; salto causa impacto apenas na aterrissagem.

## Singularidade Absoluta

- Cria exatamente três âncoras atacáveis, em triângulo, com barras de vida e contador `0/3`.
- Destruir as três interrompe a canalização, atordoa o chefe e abre uma janela de exposição.
- Deixar o cronômetro acabar é falha, não sucesso. A falha cria três poços gravitacionais espaçados e um leque de feixes com aviso, mantendo corredores de fuga.
- O aviso de canalização é removido antes de mostrar o resultado, evitando textos sobrepostos.
- A antiga conclusão automática e os efeitos duplicados foram removidos.

## Salvamento, retry e multiplayer

O save inclui FSM, estágio, último ataque, estado visual, timers de hit/morte, resultado da ultimate e posição da morte. Retry chama o reset do controlador e da apresentação. O snapshot visual replica FSM, âncoras destruídas, stun, vulnerabilidade e resultado da ultimate. A autoridade permanece no host.

## Evidências visuais

- Estudos e contato geral: `.codex/boss4_rework_art/`.
- Antes: `.codex/boss4_rework_before/`.
- Depois, quatro estágios, entrada, ultimate interrompida/concluída, morte e mobile: `.codex/boss4_rework_after/`.

## Validação executada

- Parse isolado dos controladores, apresentação, loader, save, sincronização, fluxo de fase e core.
- `boss4_integral_rework_smoke.gd`: movimento, contato com cooldown, quatro thresholds, seleção contextual, dois desfechos da ultimate, estados de sprite e save.
- `boss4_multiplayer_sync_smoke.gd`: host/cliente, solo/duo/trio, FSM e três âncoras.
- `boss4_instability_fissures_smoke.gd`: cadência, corredor seguro, dano idempotente, morte/revive/reconexão e cleanup.
- `phase4_smoke.gd`: mapa, ecossistema, Petro, morte do chefe e portais para a fase seguinte.
- `runtime_save_controller_smoke.gd`: autosave, resume e retry.
- `boss4_integral_visual_smoke.gd`: frames 384×384 e capturas reais em 1280×720 e 960×540.
- `boss4_continuous_performance_smoke.gd`: 1.800 updates/30 s simulados; medição lógica headless, não FPS de aparelho.

## Limites da evidência

- O multiplayer foi validado localmente por snapshots host/cliente; não houve sessão real via VPS nesta rodada.
- A composição mobile foi renderizada em 960×540 com Xvfb/llvmpipe; não substitui teste em aparelho Android físico.
- A medição de desempenho cobre custo lógico contínuo, não GPU, latência de rede nem frame pacing de um dispositivo real.

