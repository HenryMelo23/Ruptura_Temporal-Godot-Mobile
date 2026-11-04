# Boss 6 — Matriarca da Chaga: rework (mecânica, estágios e quadros)

## 1. Diagnóstico (antes)
- **Presa no centro:** `boss6_stage_controller.update()` força `boss_pos = arena_center()` todo quadro;
  a "relocação" é um stub. Ela nunca se move.
- **Arte inconsistente:** idle `Boss6-1/2/3-x.png` com tamanhos diferentes (224–235 × 191–206) →
  o corpo "treme" entre quadros; ataques `boss6_rework/stageN_attack` (440×398) com VFX pintado e
  cortado nas bordas (foice e ácido vazam do quadro).
- **Kit raso:** só 3 habilidades sorteadas (foices, florada, maré) + 5 eventos por % de vida
  (80/60/40/30/15) que se empilham em sequência rápida.
- **VFX primitivo:** foices = linhas com bolinhas; ácido = círculos; nada sai do corpo dela.

## 2. Regras (iguais ao boss 4)
1. O sprite mostra só o corpo; tudo que é direcional (ondas, cuspe, cauda varrendo) é desenhado pelo código.
2. Cada quadro = uma fase do golpe (preparar, soltar, sustentar, recuperar).
3. Âncoras fixas: boca, coração e ponta da cauda no mesmo lugar dentro da mesma sequência.
4. **Proporção garantida por teste** (`tests/boss6_frame_proportion_smoke.gd`): todo quadro de corpo
   tem os pés na mesma linha, a mesma escala, pés centrados em x≈254 e (idle/rastejar) coroa até
   ~40 px abaixo do idle. Arte antiga 440×398 só entra normalizada (`LEGACY_FEET`, escala ×1,18);
   quadros novos fora do centro são corrigidos em `FRAME_SHIFT_X`; `boss6_crawl_03` fica fora do
   ciclo (`CRAWL_ORDER`) até a refação (`.codex/tasks/boss6_fix_proportions.md`).
5. Célula **448×448**, olhando para a **ESQUERDA**, pés em **y≈420**, centro **x≈224**, mesma escala
   em todas as sequências. Desenho em jogo ≈ 300 px (escala 0.67), `flip_h` olhando para a direita.

## 3. Identidade
Mãe-organismo pesada de seis patas. **Não persegue correndo: rasteja devagar e se reposiciona
mergulhando na lama da Chaga**, emergindo perto do jogador. Cada estágio muda o corpo dela.

| Estágio | Vida | Corpo | Locomoção |
|---|---|---|---|
| I — Carapaça Viva | 100–66% | carapaça de osso fechada, coração âmbar coberto | rasteja lento; mergulha a cada ~9 s |
| II — Florada Ácida | 66–33% | carapaça rachada, bolsas ácidas verdes nas costas | rasteja médio; mergulha a cada ~7 s |
| III — Maré de Carnificina | 33–0% | carne exposta, coração aberto pulsando | rasteja rápido; mergulha a cada ~5,5 s |

## 4. Habilidades
| # | Habilidade | Estágio | Ideia | Leitura / contra-jogo |
|---|---|---|---|---|
| 1 | **Mergulho na Chaga** | 1+ | afunda, vira um monte de lama que corre até o jogador, avisa 0,55 s e **irrompe** | círculo de aviso no ponto; dash ou sair do círculo; imune enquanto submersa |
| 2 | **Foices Vertebrais** (rework) | 1+ | empina e varre duas ondas-foice em cone de 120° (ida e volta) | ondas desenhadas no chão; passar pelo vão entre ondas ou dash |
| 3 | **Incubação** | 1+ | mantida (pústulas) | — |
| 4 | **Cuspe Florado** (rework da Florada) | 2+ | 3 bolas ácidas em leque nas posições previstas, poças menores (110 px, 8 s) | sombra cresce no chão onde cai |
| 5 | **Cauda Condutiva** | 2+ | crava a cauda e varre 200° atrás/laterais | pune quem flanqueia; aviso em arco |
| 6 | **Maré de Carnificina** (rework) | 3 | vomita um jato contínuo que segue o jogador devagar e deixa rastro | correr em círculo; rastro limita o espaço |

**Eventos por vida:** reduzidos às viradas de estágio — 66% *Ecdise Dolorosa* (solta a carapaça),
33% *Coração Exposto* (janela de dano) e 15% *Parto do Fim* (final).

## 5. Ordem de trabalho
1. **Agora:** corpo base + locomoção (idle, rastejar, mergulhar, emergir) e o Mergulho na Chaga.
   Tarefa Codex: `.codex/tasks/boss6_body_burrow_sprites.md`.
2. Foices Vertebrais (quadros de empinar/varrer + textura da onda).
3. Cuspe Florado + Cauda Condutiva.
4. Maré de Carnificina + eventos de estágio.

## 6. Status
- **Passo 1 (feito):** `scripts/systems/bosses/boss6_controller.gd` (`RTBoss6Controller`, estado em
  `game.boss6_ai_state`, salvo no save interrompido).
  - Rastejar por passos (velocidade pulsa com o ciclo de 0,9 s; 46/72/104 px/s por estágio), para a ~250 px do
    jogador, vira para ele; só anda quando a FSM de habilidades está ociosa/recuperando.
  - Mergulho na Chaga: afundar 0,6 s → monte persegue (270/310/350 px/s, até 2,2 s) → aviso 0,55 s
    (círculo 130 px) → irrompe (dano `9% vida + 34`, empurrão, dash escapa) → 0,55 s de pé. Imune submersa.
    Dispara com jogador a ≥520 px ou ao acaso quando a recarga (9/7/5,5 s) acaba. Virada de estágio e
    eventos especiais cancelam o mergulho.
  - `boss6_stage_controller` não prende mais em `arena_center()`; a Ecdise não teleporta mais.
    (Parto do Fim e Coração Rachado ainda centralizam — trocar por mergulho até o centro no passo 4.)
  - Sem a arte nova: usa o idle antigo, afunda por recorte na linha de lama e monte procedural.
    Com a arte (`boss6_idle/crawl/submerge/emerge`, `boss6_burrow_mound`, `boss6_emerge_burst`) troca sozinho.
  - Testes: `tests/boss6_locomotion_burrow_smoke.gd`, `tests/boss6_locomotion_visual_smoke.gd`;
    `boss6_three_stage_rework_smoke` atualizado (não exige mais boss parado).
- **Arte do passo 1 integrada:** `boss6_idle/crawl/submerge/emerge`, `boss6_burrow_mound`, `boss6_emerge_burst`
  (brutos em `body_raw/` com `.gdignore`). A arte 448×448 é desenhada com escala fixa 0,9 e pés em y=420
  (`BODY_SCALE`/`BODY_FEET_Y`), não pelo encaixe antigo; sombra acompanha (`draw_shadow`).
- **Passo 2 (mecânica feita, arte pendente):** Foices Vertebrais = ondas em meia-lua (cone 120° solo / 80° por
  alvo no online) que saem a 60 px e correm até 560 px (660/720/800 px/s), 2/3/3 ondas por estágio alternando o
  lado da varrida; cada onda re-mira no disparo, acerta uma vez (`6,5% vida + 20`, empurrão), dash e quem está
  atrás escapam. Aviso em cone no telegraph. Lógica em `RTBoss6Controller.update_scythes` (o ramo antigo de
  ossos saiu do core). Quadros `boss6_scythe_00..04` e texturas `boss6_bone_shard`/`boss6_scythe_slash` entram
  sozinhos — tarefa `.codex/tasks/boss6_scythes_sprites.md`. Testes: `tests/boss6_scythes_smoke.gd`,
  `tests/boss6_scythes_visual_smoke.gd`.
- **Arte do passo 2 integrada:** `boss6_scythe_00..04`, `boss6_bone_shard`, `boss6_scythe_slash` (fio do clarão
  fica no lado -x da arte → desenhado girado 180°). Barra de vida do boss 6 subiu para `-0,8 × altura` (poses empinadas).
- **Passo 3 (mecânica feita, arte pendente):**
  - Cuspe Florado (substitui a Florada de 5 poças de 200 px/20 s): bolas em arco saindo da boca, 3 (estágio II) /
    5 (III) em leque na posição prevista (0,45 s à frente), 2 por alvo no online; voo 0,85 s com sombra crescendo;
    ao cair respingo de 90 px (`5,5% vida + 18`, dash escapa) e poça de 110 px por 8 s.
  - Cauda Condutiva (nova no sorteio, estágio II+, só com alguém a ≤330 px): aviso em arco de 220° nas costas/lados,
    varrida de 0,42 s que acerta quando passa pelo alvo (`8% vida + 28`, empurrão 190); a frente fica livre.
  - Lógica em `RTBoss6Controller` (`build_spit_attack/update_spit`, `build_tail_attack/update_tail`); ramos antigos
    saíram do core. Quadros `boss6_spit_00..03`, `boss6_tail_00..02`, texturas `boss6_acid_glob/acid_splash/spark` —
    tarefa `.codex/tasks/boss6_spit_tail_sprites.md`. Testes: `tests/boss6_spit_tail_smoke.gd`,
    `tests/boss6_spit_tail_visual_smoke.gd`; `boss6_three_stage_rework_smoke` agora espera 4 habilidades.
