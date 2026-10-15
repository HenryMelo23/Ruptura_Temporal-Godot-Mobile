# Boss 1 — contrato visual do Cronoguejo

Este documento registra apenas a apresentação. Timings, dano, hitboxes,
seleção de alvo, autoridade e mensagens de rede continuam pertencendo aos
owners de gameplay existentes.

## Identidade e atlas

- 55 quadros finais transparentes, todos normalizados para `257x239`.
- Silhueta preservada: caranguejo cósmico roxo com relógio central.
- Pivô inferior e escala constantes entre estados para evitar saltos visuais.
- Virada horizontal ocorre somente no desenho; colisões não são espelhadas.
- As três pranchas-fonte ficam em `art_sources/boss1/`, fora da importação e
  do pacote final por meio de `.gdignore`.

## Mapa de estados

| Evento real | Estado visual | Quadros | Regra de apresentação |
| --- | --- | ---: | --- |
| parado | `idle` | 4 | ciclo leve do relógio e das pinças |
| deslocamento efetivo | `walk` | 4 | persiste por uma pequena janela entre snapshots de rede |
| inversão do eixo X | `turn` | 3 | transição curta antes da nova direção |
| dano recebido sem movimento/cast | `hit` | 5 | não interrompe ataque nem locomoção |
| entrada, salto de estágio ou Maré de Cerco | `jump` | 5 | aterrissagem continua governada pelo evento de gameplay |
| bolha e bolhas de pressão | `bubble` | 4 | acompanha a idade do ataque existente |
| rush e Pinças em Tenaz | `pincer` | 4 | distingue antecipação, investida e recuperação |
| absorção/retaliação temporal | `absorb` | 4 | progresso deriva do timer autoritativo |
| areia | `sand` | 4 | cast alinhado ao telegraph existente |
| maré | `tide` | 4 | cast alinhado ao telegraph existente |
| chuva fervente | `rain` | 4 | cast alinhado ao telegraph existente |
| onda temporal e rewind | `rewind` | 4 | ativo enquanto o snapshot temporal existe |
| morte | `death` | 6 | desintegração completa, sem sumiço abrupto |

Prioridade visual: entrada/salto/estágio, rewind, absorção, ataque ativo,
virada, locomoção, hit elegível e idle. Assim um flash de dano nunca esconde
o aviso de uma habilidade.

## Multiplayer e modo econômico

O renderer consome `boss_pos`, `boss_attacks`, timers e snapshots já
replicados. Nenhum RPC visual novo concede dano ou cria ataque. Em modo de
pouca memória, cada ciclo comum mantém primeiro/último quadro e
hit/salto/morte mantêm começo/meio/fim; a leitura do estado permanece, com
menos texturas residentes.

## Evidência automatizada

- `tests/boss1_animation_smoke.gd`: FSM, direção, prioridade, sete famílias
  de ataque, absorção, rewind, salto, hit e morte.
- `tests/boss1_animation_visual_smoke.gd`: capturas desktop `1280x720` e
  modo econômico `960x540`.
- `tests/runtime_asset_controller_smoke.gd`: importação por fase, descarte e
  conjuntos compactos do Boss 1.
- Smokes existentes de Maré de Cerco, Pinças em Tenaz, rewind, chuva,
  estados ininterruptíveis e sincronização multiplayer continuam cobrindo os
  contratos de gameplay que alimentam a apresentação.
