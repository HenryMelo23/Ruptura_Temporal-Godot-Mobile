# Guia de criação de fases

Contrato para novas fases de Ruptura Temporal. Leia este arquivo antes de
implementar uma fase; consulte código apenas nos pontos de integração necessários.
Revisão das fontes: 17/11/2026. Os símbolos abaixo são âncoras de busca, não números
de linha. Mudanças futuras de comportamento devem atualizar este guia.

## 1. Pedido mínimo e autonomia

O senhor pode informar somente tema, família de inimigos e mecânicas principais.
Complete nomes, funções dos quatro especiais, cadência e parâmetros iniciais
coerentes com o tema. Registre essas escolhas na ficha da fase. Pergunte somente
se houver uma decisão essencial que não possa ser deduzida do pedido.

```text
Crie uma nova fase seguindo docs/PHASE_CREATION_GUIDE.md.
Tema: [ambiente e identidade].
Inimigos: [família/espécie; nomes são opcionais].
Mecânicas principais: [ideias que desejo explorar].
Restrições ou exceções: [opcional].
Estruture o gameplay e prepare o encaixe dos frames; a arte será feita à parte.
```

Claude estrutura lógica, mecânicas, integrações e especificação dos estados.
A produção de imagens/frames é encaminhada ao Codex pelo fluxo já utilizado.
A lógica precisa funcionar com representação provisória antes da arte final.

## 2. Estrutura obrigatória de uma nova fase

| Parte | Contrato |
| --- | --- |
| Identidade | Nome próprio, materiais/paleta e uma regra temática reconhecível no combate. |
| Mundo | Mapa grande compartilhado: atualmente **3200 × 2250**, área 5× a base de 1600 × 900. Reutilizar controlador e renderer de chunks. |
| Inimigo comum | **1 tipo**, presente desde o início; ensina a ameaça básica e continua compondo as ondas. |
| Especiais | **4 tipos distintos**, com funções e respostas diferentes; entram gradualmente e têm limites simultâneos. |
| Miniboss | **1 tipo próprio da fase**, com entrada, ataques anunciados, recuperação, morte e recompensa. Agendamento separado das ondas. |
| Boss | **1 chefe principal**, invocado pelo fluxo compartilhado do altar, com entrada, estados de combate, morte, recompensa e saída pela rota. |
| Arte pendente | Estados, orientação, âncoras e tempos prontos para receber frames sem reescrever o combate. |

O conjunto é de **7 tipos de combatentes: 1 + 4 + 1 + 1**. Invocações, ovos,
projéteis, estruturas e hazards são auxiliares; não preenchem vagas dos quatro
especiais. Uma recoloração ou aumento de atributos também não cria um novo papel.

Este é o padrão de criação daqui em diante. **Não é uma afirmação de que todas
as fases existentes já cumprem essas quantidades.** Não completar ou reduzir
elencos antigos como efeito colateral. A fase 5, centrada na UMBRA, é exceção e
não deve servir como template de horda nem ser alterada por este contrato.

## 3. Referências existentes: preservar identidade, reutilizar contratos

Resumo conferido nos seletores de spawn, controladores e testes indicados adiante.
A coluna de encontros distingue o miniboss de outros especiais recorrentes.

| Fase | Identidade e ecossistema atual | Encontros e chefe |
| --- | --- | --- |
| **1 — Ruínas Cósmicas** | Ruínas e energia temporal. Comum inicial; Espreitador pressiona com ocultação, Projetador dispara à distância, Cristalizador resiste, Curater cura aliados; há também Escudeiro Refletor e `cout_attack_speed` (reação à cadência de ataques). Liberações progressivas. | Arauto: Condutor de Ecos; Larápio é pressão adicional de roubo com agenda própria. **Cronoguejo**: retorno temporal e pinças. |
| **2 — Fenda Glacial** | Gelo, neve, pedra azul e cristais cianos. Pinguim comum, com disparo controlado pelo manager; Kamikaze e Pinguim Incendiário entram por cadência. Sineiro Boreal é encontro dedicado de badaladas, ecos e gelo, fora do sorteio comum. | Sineiro com FSM/agenda próprios. **Sentinela Glacial**: combate do pinguim chefe, vento, congelamento e nevasca. |
| **3 — Catedral do Esgoto** | Catedral e esgoto no mesmo ambiente. Comum atirador; Devoto Febril deixa miasma, Incensário cria zonas, Guardião de Sucata integra o elenco; Flagelante avança, Salmodiante dispara em leque e Portador de Relicário fortalece aliados. Pulso Ritual tem controlador próprio. | Não foi identificado agendamento de miniboss próprio nos caminhos revisados. **Pai-Rato**: miasma e rituais. |
| **4 — Coração do Nexo** | Pedra escura, ouro envelhecido e fissuras magenta. Cinco espécies de anomalias: Cartógrafo desloca por fendas, Cronófago consome progresso de cooldown, Refrator divide disparos, Tecelão altera movimento e Eco Entrópico detona posições passadas. O início já seleciona um subconjunto delas; não usa o comum genérico. | Não foi identificado agendamento de miniboss próprio nos caminhos revisados. **Nexo Anfíbio**: sapo astronauta com estágios, saltos, língua e instabilidade. |
| **6 — Chaga de Âmbar** | Pântano, doença, ossos e âmbar orgânico discreto. Lodário inicial; Sanguessuga Cronal, Enguia de Miasma e Pústula Fóssil ampliam a pressão. Suturador de Âmbar é encontro recorrente separado, com suturas e interação com cartas. | Arauto na variante **Aguilhão**; Suturador mantém sua própria agenda. **Matriarca da Chaga**: três estágios, foices, ácido e carnificina em arena local. |
| **7 — Cinzas da Ruptura** | Floresta queimada, cinza, raízes e brasas. Cinerídeo inicial ataca em cone; Pangoliro tem armadura frontal, rolagem e vulnerabilidade; Corvol prepara mergulhos. Brasas usam orçamento próprio. | Não foi identificado agendamento de miniboss próprio nos caminhos revisados. **Fênix**: voo, mergulhos, fogo e renascimento. |
| **8 — Sertão das Tartarugas** | Sertão e tempo de tartaruga. Jabuti Errante inicial gira no casco; Mandacaru emite espinhos, Morteiro lança ovos e Cágado-Pião ricocheteia. Ovos são auxiliares. Motor próprio de bullet hell: hitbox pequena, proteção entre impactos e graze. | **Cágado Cangaceiro** tem agenda separada. **Casco-de-Sol**, jabuti-relógio, tem três estágios. Dimensão bônus: após 7 dimensões concluídas, chance de 30% por travessia elegível, até uma visita por ciclo de farm. |

Na fase 5, o perfil de terreno pode variar conforme a dimensão da UMBRA e o spawn
reutiliza o seletor do Nexo. Não importar esses acoplamentos para uma nova fase.
As diferenças de quantidade e os minibosses ainda ausentes acima são contexto,
não tarefas autorizadas por um pedido de criação de outra fase.

## 4. Ciclo de gameplay e justiça dos ataques

1. Entrar pela orquestração normal, configurar identidade, limites e atributos,
   zerar timers/flags próprios e preparar os assets da fase ativa.
2. Começar com o comum e ensinar sua mecânica. Liberar os quatro especiais em
   sequência, com pesos, intervalo mínimo e teto por espécie; manter fallback
   para o comum quando os tetos forem atingidos.
3. Introduzir o miniboss por agenda explícita. Padrão inicial: uma ocorrência
   por visita, no máximo uma instância viva; recorrência só se fizer parte do
   conceito. Definir o que acontece se o boss for chamado antes dele.
4. Explorar, descobrir o altar e invocar o boss pelo contrato existente. A chegada
   e o combate usam a âncora local do encontro, não o centro fixo do mundo grande.
5. Encerrar o encontro uma única vez, conceder recompensa e entregar a saída
   ao controlador de rota. Nunca assumir que a próxima fase é `id + 1`.

Para os especiais, combinar quatro papéis coerentes com o tema: perseguição,
pressão à distância, controle de espaço e suporte são um ponto de partida,
não quatro habilidades obrigatórias. Cada espécie deve exigir uma decisão do
jogador. Miniboss e boss desenvolvem essas ideias com padrões próprios.

Todo ataque precisa definir **condição → aviso → execução → recuperação**,
alvo/posição de compromisso, geometria de dano e oportunidade de resposta.
Definir cooldown, limite de impactos e limpeza. Aviso visual e colisão devem
usar as mesmas coordenadas; efeitos decorativos não podem causar dano invisível.
Timers são em segundos e independem do número de frames entregues pela arte.
Não inflar vida para substituir mecânicas ou permitir cura sem limite que impeça
o jogador de progredir. Balancear comum/especiais pela curva compartilhada;
miniboss/boss precisam de tratamento explícito, sem cair na curva de comum.

Na transição, morte, reinício e chamada do boss, remover hazards, projéteis,
invocações e efeitos temporários que pertencem ao encontro; restaurar mudanças
temporárias no jogador. Respeitar pausa, loja/dimensão do Mercador e autoridade.

## 5. Mapa de integração: abrir apenas o necessário

Começar por este guia e pelas instruções do repositório. Antes de editar terreno,
ler [PHASE_EX_TERRAIN.md](PHASE_EX_TERRAIN.md). Para código, buscar o símbolo exato
no arquivo abaixo e abrir sua função e chamadores diretos. Não ler o core inteiro,
uma fase inteira, `Game Base/` ou todos os testes para copiar uma estrutura.

| Necessidade | Arquivo / âncora de busca |
| --- | --- |
| Perfil, mundo e altar | `scripts/systems/phase/experimental_phase_controller.gd`: `PHASES`, `begin_definitive_phase`, `terrain_chunks`, `enemy_spawn_point`, `boss_encounter_center`, `boss_encounter_rect`. |
| Desenho do terreno | `scripts/presentation/experimental_phase_presentation.gd`; reutilizar o renderer e a seleção de chunks. |
| Entrada, saída e registro na rota | `scripts/systems/phase/phase_flow_controller.gd`: `phase_region_name`, `_apply_initial_phase_setup`, `_advance_to_phase`, `_spawn_phase_fragment`, `_spawn_phase_choice_portals`. |
| Identificadores e pools | `scripts/main_runtime_state.gd`: `ENEMY_*`, `NET_ENEMY_TYPES`, `DIMENSION_ROUTE_POOL`, `DIMENSION_START_ROUTES`, `INITIAL_PHASE_ROLL_POOL`. Alterar só os pools necessários; preservar UMBRA como final e a entrada bônus do Sertão. |
| Ondas e orçamento | `scripts/systems/enemy_manager.gd`: `SPECIAL_SPAWN_PACING`, `paced_special_type`, `is_phase_special_kind`, `update_enemies`, `spawn_wave`, `get_enemy_limit`, `get_enemy_spawn_interval`. |
| Seleção e criação de entidades | `scripts/main_runtime_core.gd`: `_choose_enemy_type`, `_choose_phase*_enemy_type`, `_spawn_enemy`; os controladores novos recebem apenas os hooks necessários. |
| Chamada, atualização e dano do boss | `scripts/main_runtime_core.gd`: `_begin_boss_call_for_all`, `_update_boss`, `_damage_boss`; conectar o owner do novo boss ao despacho existente e ao encerramento/recompensa já utilizado. |
| Modelo de lógica extraída | `scripts/systems/enemies/phase3_enemy_controller.gd`: `update_enemy`; para FSM/agenda de encontro: `phase2_sineiro_boreal_controller.gd` e `phase6_amber_suturer_controller.gd` no mesmo diretório. Escolher uma referência, não carregar todas. |
| Exemplo de fase com owner próprio | `scripts/systems/phase8/sertao_controller.gd`: `choose_enemy_type`, `spawn_stats`, `on_spawned`, `update_enemy`, `_update_miniboss_schedule`, `clear_for_boss_call`; boss em `scripts/systems/phase8/boss8_controller.gd`. O motor de bullet hell é específico do Sertão. |
| Curva de inimigos | `scripts/systems/enemies/regular_enemy_balance.gd`: verificar isenções de encontros especiais. |
| Carregamento e frames | `scripts/systems/assets/runtime_asset_controller.gd`: `PHASE_TEXTURE_SPECS`, `prepare_phase`, `ensure_key`; `scripts/vfx/entity_visual_profiles.gd`: `_enemy_texture`, `_enemy_draw_size`, `_enemy_should_flip`. |
| Sistemas transversais | Consultar a linha do domínio em `AGENT_CODEMAP.md` somente se tocar eventos, áudio, save, recompensas, colisão de props ou snapshots. |

Nova lógica temática deve ter owner próprio em `scripts/systems/`, apresentação
em `scripts/presentation/` e hooks curtos no runtime. Reutilizar os contratos de
spawn, alvo, dano, pontos, loja, eventos e progressão. Não duplicar uma fase nem
criar um framework paralelo para atender este guia.

O mapa expandido é definitivo; `FaseEX...` identifica a variante clássica de teste.
Não confundir o nome histórico do controlador/atlas com uma fase provisória.
O padrão atual usa células de **384**, atlas **4 × 4**, altar no índice **5** e
arte/interação/entrada do boss no mesmo centro. Obstáculos sólidos precisam do
contrato compartilhado de colisão. Os detalhes e exceções estão no guia de terreno.

## 6. Contrato para receber arte depois

Na ficha, especificar por entidade: ID estável, chave de textura, diretório de
destino, estados, direção original/flip, tamanho no mundo, pivô/pés, offsets,
hitbox e âncoras de disparo. Listar animações necessárias, duração/loop e instante
de compromisso do ataque. Boss pode precisar de âncoras adicionais, como boca.

Expor os estados de combate à apresentação. Preparar fallback visível e seguro
para assets ausentes, sem `preload` obrigatório para arquivos que não existem.
A troca de placeholders por frames altera somente apresentação e mapeamentos;
timing, dano, alcance e FSM continuam definidos pela lógica.

Respeitar streaming dos assets da fase ativa no mobile. Separar claramente
**gameplay implementado**, **arte provisória** e **arte integrada/conferida**.
Registrar o pedido de arte em `.agents/codex_requests/<nome_da_fase>.md` se o fluxo
exigir uma entrega ao Codex, reutilizando essas especificações.

## 7. Ficha curta a produzir para cada nova fase

Salvar em `docs/phases/<id>_<nome>.md`; preencher decisões em vez de repetir este
guia ou transcrever código. Caminhos futuros nesta seção são convenções propostas.

```markdown
# Fase <id> — <nome>
Tema / regra central:
Entrada na campanha: <rota normal ou condição bônus; saída pelo fluxo existente>
Mapa / altar: <perfil, chave do atlas, identidade; padrão compartilhado>

| Papel / ID | Mecânica e resposta do jogador | Liberação / teto / cooldown |
| --- | --- | --- |
| Comum | | |
| Especial 1 | | |
| Especial 2 | | |
| Especial 3 | | |
| Especial 4 | | |
| Miniboss | <agenda, ataques, recuperação, recompensa> | |
| Boss | <invocação, ataques/estágios, morte e recompensa> | |

Owners / hooks alterados:
Estados e parâmetros dos ataques: <aviso, geometria, execução, recuperação>
Limpeza / pausa / persistência / autoridade:
Arte: <IDs → chaves/caminhos; estados, pivôs, escala, direção e âncoras>
Validação solo executada / pendências de arte e multiplayer:
```

## 8. Verificação e encerramento

- Conferir os sete tipos e seus papéis, liberação/caps, agenda independente do
  miniboss e ataque com aviso/dano/recuperação; nenhum encontro pode duplicar
  spawn, recompensa ou saída.
- Executar parse dos scripts alterados e smoke solo focado: entrada direta,
  comum inicial, quatro especiais, miniboss, altar/boss, morte/saída, limpeza
  e reinício; verificar restauração se houver estado persistido novo.
- Usar como referências os testes `phase3_enemy_variety_smoke.gd`,
  `special_spawn_pacing_smoke.gd`, `phase8_sertao_smoke.gd` e
  `experimental_phase_smoke.gd` em `tests/`; selecionar trechos pelo contrato.
  Não executar automaticamente testes existentes que incluam multiplayer.
- Conferir com Geovana real em desktop e mobile paisagem, incluindo modo leve:
  escala, contraste, avisos, altar e custo das hordas/hazards. Sem arte final,
  registrar essa pendência; não declarar validação visual concluída.
- Preservar autoridade, IDs de rede, snapshots e apresentação remota existentes.
  Multiplayer continua congelado: não executar host/client, servidor ou múltiplos
  processos. Registrar cenários devidos e evidência solo em
  `.agents/MULTIPLAYER_DEFERRED_VALIDATION.md`, sem ler o backlog inteiro.
- Executar `git diff --check`; para trabalho de porte de refatoração, orçamento
  arquitetural antes/depois. Mudanças amplas de runtime, cenas, recursos ou
  exports também exigem a validação profunda prevista no repositório.
- Atualizar a ficha da fase e apenas os roteadores/índices afetados. Relatar
  arquivos, validações realmente executadas e caminhos ainda não exercitados.
