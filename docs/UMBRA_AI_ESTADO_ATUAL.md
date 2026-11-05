# UMBRA — estado atual da IA antes das incursões

Este documento registra o estado encontrado antes da Tarefa 03. Ele separa o
combate que roda no jogo, os artefatos de modelo, a memória comportamental e o
treino externo. Essa separação é importante para a Tarefa 04: hoje existem
mais de um mecanismo chamado de “memória” ou “aprendizado”, mas eles não são a
mesma coisa.

## Mapa de arquivos e responsabilidades

| Arquivo | Responsabilidade atual |
| --- | --- |
| `scripts/main_runtime_state.gd` | Contratos e estado legado do Boss 5: 23 ações, 24 atributos do DQN legado, cooldowns, dimensão transmutada, hazards, memória carregada e referências dos artefatos. |
| `scripts/main_runtime_core.gd` | Orquestra a luta real: carrega memória/modelo, escolhe e executa ações, movimenta a Umbra, aplica hazards, Transmutar, Sifão, recompensas locais e início/fim da luta. |
| `scripts/systems/umbra_dqn_contract.gd` | Valida o formato JSON matricial legado (`24 -> 128 -> 64 -> 23`) e a ordem exata de ações/atributos. |
| `scripts/systems/umbra_neural_runtime.gd` | Inferência FP32 feed-forward, com buffers persistentes e validação de tensores/integração. Não treina. |
| `scripts/systems/umbra_observation_schema.gd` | Esquema de observação 2.0 mais rico: Umbra, até três jogadores, espaço, hazards, histórico e multiplayer. Também contém a ordem canônica das 23 ações. |
| `scripts/systems/umbra_multihead_policy.gd` | Runtime da política 2.0 multi-head recorrente (encoder + GRU + cabeças de ação, alvo, espaço e valor). Mantém memória de trabalho apenas durante o encontro. Não aplica gameplay nem treina. |
| `scripts/systems/online/umbra_authority_controller.gd` | Faz o host escolher/revalidar ação, alvo e posição; réplicas só consomem decisões. Mantém sequência compacta e rejeita alvo morto/inválido. |
| `scripts/systems/umbra_memory_controller.gd` | Memórias de trabalho, da run e persistente; observa comportamento local, produz o relatório de conhecimento e salva perfil agregado no solo. Isola multiplayer. |
| `scripts/presentation/umbra_knowledge_presentation.gd` | Desenha o resumo “Conhecimento da Umbra” e suas categorias. |
| `assets/data/memoria_predatoria_umbra.json` | Perfil-base legível com estatísticas históricas, perfil do jogador, adaptações e profecias. O arquivo atual começa zerado. |
| `assets/weights/umbra_dqn_weights.json` | Exportação antiga de 22 ações (`24 -> 128 -> 64 -> 22`). É referência legada e não satisfaz o contrato atual. |
| `assets/weights/umbra_dqn_2_0_actions_23.json` | Caminho esperado pelo runtime para um DQN válido de 23 ações. O arquivo não existe no estado auditado; por isso o runtime usa fallback. |
| `tools/export_umbra_weights.py` | Exporta e valida o DQN de 23 saídas. |
| `tools/umbra_rl_rollout.gd` | Rollout headless autoritativo usado pelo treino externo; calcula recompensa versionada e emite transições. |
| `tools/umbra_selfplay_core.gd` | Simulação de self-play Umbra × Apolo, estatísticas por ação e recompensa própria da simulação. Não é a luta runtime. |
| `tools/train_umbra_ppo.py` e `tools/umbra_rl_curriculum.py` | Treino externo PPO/currículo. Não rodam no celular nem dentro da partida. |
| `tests/phase5_umbra_smoke.gd` | Contrato amplo da fase 5: mapa, assets, memória, decisão, habilidades e vitória. |
| `tests/umbra_dqn_contract_smoke.gd`, `tests/umbra_neural_runtime_smoke.gd` | Formato/ABI e inferência feed-forward. |
| `tests/umbra_observation_schema_v2_smoke.gd`, `tests/umbra_multihead_policy_smoke.gd`, `tests/umbra_multihead_parity_smoke.gd` | Observação 2.0, política recorrente e paridade de fixture. |
| `tests/umbra_memory_controller_smoke.gd`, `tests/umbra_precombat_knowledge_smoke.gd` | Ciclo da memória local e dossier pré-combate. |
| `tests/phase5_umbra_transmute_visual_smoke.gd`, `tests/umbra_transmutation_lab_smoke.gd`, `tests/umbra_siphon_sustain_smoke.gd` | Transmutar, kits dimensionais, apresentação e sustentação limitada do Sifão. |

## Como a Umbra decide ataques hoje

O executor real chama `_umbra_available_actions()`, `_umbra_choose_action()` e
`_spawn_umbra_action()` em `main_runtime_core.gd`.

1. A cada janela de decisão, o runtime monta as ações atualmente legais pelos
   cooldowns, dimensão ativa e hazards em execução.
2. Se existe um modelo DQN válido, ele recebe 24 atributos e produz um valor Q
   para cada uma das 23 ações. A ordem é ABI e não pode ser alterada sem novo
   modelo.
3. No estado auditado não há um `umbra_dqn_2_0_actions_23.json` válido. O JSON
   `umbra_dqn_weights.json` tem apenas 22 saídas e é deliberadamente rejeitado.
4. Sem DQN válido, a escolha usa pesos locais por ação, ruído pequeno e regras
   heurísticas: distância, vida, posição na borda, movimento recente e dimensão.
5. O perfil predatório acrescenta vieses como cortar bordas, punir dash,
   quebrar distância e quebrar rotação.
6. O `RTUmbraAuthorityController` pode usar a política multi-head, quando
   carregada, para ação/alvo/espaço. Antes de executar, o host revalida o alvo.
   Se não houver alvo vivo, a decisão vira `NENHUMA`.
7. `_spawn_umbra_action()` continua sendo o executor final e valida o efeito de
   gameplay por ação. Modelo e memória nunca causam dano diretamente.

As 23 ações canônicas são: quatro intenções de movimento (`FUGIR`,
`INTERCEPTAR`, `ORBITAR`, `CERCAR`), ataque básico, Sifão, dois teleportes,
sete Transmutares, sete habilidades dimensionais e `NENHUMA`. No executor
runtime, o movimento não entra no mesmo sorteio de ataques: ele é escolhido
separadamente por `_umbra_movement_mode()`.

## Estado/observação e recompensa

Há dois contratos de observação:

- **DQN legado ativo/fallback:** 24 números em `BOSS5_DQN_FEATURES`: vida,
  distância, fogo recebido, velocidade estimada do jogador, deslocamento
  relativo, hazards ativos, ratos/Sifão, mapa dimensional, vetor de ameaça,
  distância das bordas e pressão de canto/centro.
- **Observação 2.0:** esquema versionado em `RTUmbraObservationSchema`, com
  estado/velocidade/ação/cooldowns da Umbra, até três jogadores estáveis,
  vida/build/manifestação/controle de cada jogador, hazards, pressão de
  projéteis, histórico e máscara de alvos vivos.

Também há três recompensas diferentes:

- No jogo, `_umbra_learn(action, reward)` faz uma atualização leve do peso da
  ação e salva no dispositivo. Acertos de hazard/contato dão reforço positivo;
  dano recebido durante a última ação aplica reforço negativo. Isso não é
  backpropagation nem treino do DQN/GRU.
- No rollout PPO, `_reward_for_transition()` combina dano causado, dano
  recebido, custo por passo, repetição/passividade e resultado terminal. O
  currículo limita o shaping por passo e por episódio.
- No self-play, `umbra_selfplay_core.gd` possui recompensa própria por dano,
  vitória/derrota e eficiência das ações. Ela serve ao simulador, não é lida
  diretamente pela luta da campanha.

## Onde a memória é salva e quando muda

### Memória leve legada da luta

- Base: `res://assets/data/memoria_predatoria_umbra.json`.
- Perfil local móvel: `user://memoria_predatoria_umbra_mobile.json`.
- Formato: JSON com versão do jogo, `weights` por ação, tendências, perfil do
  jogador e instante da atualização.
- Atualização: `_umbra_learn()` altera o peso da ação e `_save_umbra_mobile_memory()`
  grava no máximo uma vez a cada 5 s; o fim da luta força a gravação.

### Memória comportamental 2.0

- Caminho: `user://umbra_mind/behavior_profile_v2.json`.
- Formato: JSON versão 2, somente agregados (`runs_observed`, cinco métricas e
  relatório de conhecimento). Não salva coordenadas, inputs crus, peer IDs nem
  estado oculto da GRU.
- Ciclo: `begin_run()` carrega o perfil apenas no solo; amostras atualizam a
  memória da run; `begin_encounter()`/`end_encounter()` zeram recorrência;
  `finish_run()` mistura até seis runs e persiste quando há amostras suficientes
  ou pelo menos 30 s de conhecimento.
- Multiplayer não carrega nem grava esse perfil local.

### Mente remota

No menu, o jogo pode consultar `/umbra/mind/latest` uma vez por semana. Os JSONs
recebidos ficam em `user://umbra_mind/`, com metadados em
`user://umbra_mind/state.json`. O runtime pode mesclar perfil global, dossier do
jogador e ações por arquétipo. Isso é atualização de artefato/perfil, não treino
durante a luta.

## Transmutar e kits dimensionais

`_transmute_umbra_dimension()` troca a dimensão por 40 s, aplica 5 s de ressaca,
prepara o cooldown da habilidade local, dispara partículas/glitch de mapa e
teleporta a Umbra. O vínculo atual é:

| Dimensão/fase | Ação Transmutar | Habilidade liberada | Implementação visível |
| --- | --- | --- | --- |
| 1 — Vórtice | `TRANSMUTAR_VORTICE` | `VORTICE` | sucção e dano no centro |
| 2 — Gravidade | `TRANSMUTAR_GRAVIDADE` | `PRISAO` | executor atual cria o “Sopro Ártico” radial |
| 3 — Necrose | `TRANSMUTAR_NECROSE` | `MIASMA` | zona tóxica persistente |
| 4 — Ressonância | `TRANSMUTAR_RESSONANCIA` | `DESCARGA_ELETRICA` | cone/descarga com aviso |
| 6 — Hemorragia | `TRANSMUTAR_HEMORRAGIA` | `CAMINHO_ESPINHOS` | trilhas em X ou três faixas |
| 7 — Atrito | `TRANSMUTAR_ATRITO` | `LASER_SOBRECARGA` | sequência de 2/4/6 feixes |
| mapa 9 — Rastro | `TRANSMUTAR_RASTRO` | `PRAGA_RATOS` | ratos perseguidoras e escalada limitada |

Quando os 40 s terminam e não há habilidade ativa, ela volta para `base`. A
Fase 5 troca também o material/mapa apresentado; não é só uma troca de lista de
ataques.

## Sifão

`SIFON` fica disponível por cooldown e após os primeiros 20 s. Dura 4,6 s,
cria um hazard em torno da Umbra, causa dano periódico e cura continuamente.
Durante o Sifão, parte do dano recebido é absorvida; uma fração da absorção
confirmada também vira cura. A cura usa uma janela de 10 s e teto de 3% da vida
de referência sem o coeficiente de grupo, impedindo sustentação explosiva no
multiplayer. O movimento fica no modo `SIFON` e a Umbra não toma outra decisão
até o fim do canal.

## O que é pré-programado na movimentação

A movimentação da campanha não usa a memória da política para escolher vetor a
cada quadro. `_umbra_movement_mode()` usa regras:

- foge abaixo de 210 px;
- cerca quando o jogador está na borda;
- às vezes intercepta pela posição prevista quando há histórico;
- caso contrário orbita;
- durante laser vai ao centro e fica preso ao centro nas etapas dos feixes;
- durante Sifão não avança uma ação de movimento comum.

`_move_umbra()` converte o modo em alvo, velocidade desejada, repulsão de curta
distância, interpolação e clamp no mundo. Confiança do perfil e certas dimensões
aumentam a velocidade, mas não substituem essas regras.

## Como a Fase 5 carrega e inicia a luta

Ao entrar na dimensão 5, o `phase_flow_controller` prepara HP, nome, cor, assets
e chama `_load_umbra_mobile_memory()`. O boss ainda não está ativo. A chamada de
chefe remove inimigos/hazards e entra no countdown comum.

Quando o countdown termina, `_update_boss_call()`:

1. define HP/nome/cor da Umbra;
2. carrega memória/modelo e apresenta a porcentagem de análise preditiva;
3. posiciona a entrada e usa `BOSS5_ENTRY_TIME = 2 s`;
4. chama `_reset_phase5_state()`, que inicia o encontro da memória, zera
   recorrência, cooldowns, dimensão, hazards, movimento e autoridade;
5. ativa `boss_active` e o loop geral passa a chamar `_update_boss_phase5()`.

Na morte, o caminho normal encerra a memória do encontro, força o save da
memória leve, entrega recompensa de chefe, registra conclusão dimensional e,
quando a Fase 5 é a final, segue para a vitória/upgrade de espectro.

## Implicações para as incursões e a Tarefa 04

- O JSON DQN legado de 22 saídas não deve ser renomeado ou ativado como se fosse
  um modelo de 23 ações.
- Registro de incursão deve ficar separado dos dois saves atuais. Misturá-lo em
  `weights`, perfil comportamental ou estado oculto mudaria a IA antes da
  definição da Tarefa 04.
- As incursões podem reutilizar executor, hazards e movimento, mas precisam
  mascarar `SIFON` e todos os `TRANSMUTAR_*`, fixando diretamente o kit da fase.
- A Fase 5 deve continuar usando todos os contratos atuais, inclusive memória,
  Transmutar, Sifão, autoridade e rota final.
