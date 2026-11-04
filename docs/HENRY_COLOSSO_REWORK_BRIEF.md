# Henry — Mutação Colosso D37: rework de peso e quadros

## 1. Diagnóstico (antes)
- **Quadros:** só 3 direções (frente/lado/costas) e 3–4 quadros por ação; a transformação são 8 Henrys
  minúsculos crescendo; combo inteiro (3 golpes) espremido em 5 quadros.
- **Peso:** soco = risquinho + 3 partículas; gigante anda sem tremer o chão; salto pousa com poeira pequena;
  investida não deixa rastro; transformação termina sem impacto.

## 2. Kit (mantido) com peso novo
| Ação | Peso novo |
|---|---|
| Soco (normal/gigante) | o alvo trava 0,08 s (hit-freeze), micro-tremor, estrela de impacto |
| 3º soco | **onda de choque em leque** à frente (90 px normal / 150 px gigante, 40% do dano em quem estiver nela) + chão rachado |
| Gigante andando | **pisadas**: tremor leve e poeira a cada passo |
| Investida (HAB1 gigante) | sulco de poeira no chão ao longo do caminho |
| Salto (DASH gigante) | pouso com **rachaduras grandes**, duas ondas de choque e destroços |
| Fim da transformação | **estouro** que empurra os inimigos em 180 px |

## 3. Quadros (Codex) — 8 direções
Linhas: east, southeast, south, southwest, west, northwest, north, northeast. Células 256×256.
| Tarefa | Folhas |
|---|---|
| `.codex/tasks/henry_colossus_giant_sprites.md` | gigante: andar 6, combo 3×4 |
| `.codex/tasks/henry_colossus_normal_sprites.md` | normal: combo 3×4, frasco 6 |
| `.codex/tasks/henry_colossus_abilities_sprites.md` | gigante: investida 6, salto 6; transformação 10 (frente); texturas de impacto |

O jogo usa as folhas v2 sozinho quando existirem (`RTHenryColossusAbilityController.v2_texture`);
o pacote de rede continua com as folhas v1 (índices fixos).
