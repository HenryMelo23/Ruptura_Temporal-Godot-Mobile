# Henry — Mutação Incendiário + Efeito Combustão: rework

## 1. Diagnóstico (antes)
- **Quadros:** ataque = "arminha de dedo" genérica sem fogo; habilidade = palmas empurrando sem fogo
  nas mãos; dash = pose em T girando por 2,45 s; nada diz "piromante".
- **Habilidades:** dash longo demais (2,45 s preso girando); 3º golpe do combo igual aos outros.
- **VFX:** fagulha = ponto laranja; cargas de Queimadura invisíveis; aura da passiva = círculo fino.
- **Passiva (Incandescência):** depende de TOMAR dano e solta sozinha a cada 5 s — o jogador não
  controla nem percebe.

## 2. Kit novo
| Botão | Nome | Mecânica |
|---|---|---|
| ATK | **Estalo Ígneo** | estalo de dedos dispara fagulha (1 Queimadura). O **3º do combo** é uma **bola de fogo** maior que explode no impacto (raio 74, 55% do dano, +1 Queimadura em todos). |
| HAB1 | **Sopro de Fornalha** | mantém o cone + guarda; consome as Queimaduras em dano verdadeiro (inalterado nesta etapa, VFX na etapa 2). |
| ULT | **Ignição Total** | mantém 3 ondas (VFX na etapa 2). |
| DASH | **Rastro de Brasa** | investida de até 300 px em 0,2 s (imune 0,32 s) que deixa uma **trilha de chão em chamas** por 3 s: quem pisa leva dano a cada 0,45 s e ganha 1 Queimadura. Chegada solta um estalo (raio 110). |
| PASSIVA (efeito) | **Combustão em Cadeia** (chave `incandescencia`) | inimigo que **morre queimando explode** (raio 70+16/carga, dano ∝ cargas) e **passa cargas-1 (mín. 1)** para quem estiver perto — reação em cadeia. Fila com no máx. 6 explosões por quadro e profundidade 4 (não trava com horda). Com outras Mutações, cada 3º golpe confirmado no mesmo alvo acende 1 Queimadura. |

**Leitura:** cargas de Queimadura aparecem como chamas pequenas acima do inimigo (1–5);
explosão de combustão = anel + estilhaços de brasa; trilha = chão rachado em brasa.

## 3. Arte (Codex) — `.codex/tasks/henry_incendiary_sprites.md`
Folhas no mesmo padrão das atuais (`henry_fire_sheet_v2.png`): 1280×2048, 5 colunas × 8 linhas,
células 256×256, linhas = east, southeast, south, southwest, west, northwest, north, northeast,
**mesma escala/pés do `henry_walk_sheet_v2.png`**. Sem projétil/jato/rastro pintado: só fogo colado às mãos/sapatos.

## 4. Etapas
1. **Agora:** passiva Combustão, Rastro de Brasa, bola de fogo do 3º golpe, VFX de cargas/explosão/trilha/fagulha.
2. Integrar a arte do Codex (ataque, habilidade, dash) + VFX novo do cone e da ultimate.

## 5. Status
- **Etapa 1 (feita):** tudo em `RTHenryIncendiaryAbilityController`.
  - `on_damage_dealt` (antes `_apply_henry_burn_from_damage` no core) + ignição a cada 3º golpe com outras Mutações.
  - `on_enemy_killed` → fila `combustion_queue` (6/quadro, profundidade 4, teto 48) → `_detonate`.
  - Dash: `HENRY_SPIN_DURATION 0.32`, `HENRY_SPIN_DASH_DURATION 0.2`, `DASH_MAX_DISTANCE 300`, trilha `ember_trail`
    (pontos a cada 26 px, 3 s, tique 0,45 s por inimigo) e estalo final (raio 110, 50%).
  - Bola de fogo: 3º golpe ganha `henry_fireball_id` + `visual_scale 2.1`; explode quando some antes do fim.
  - Atrito/aura antigos desligados (campos mantidos para save/snapshot).
  - VFX procedural: `HenryFire.burn_pips/draw_ember_trail/dash/draw_combustion/fireball`; usam as texturas
    `henry_burn_pip/fire_patch/combustion_burst/fireball` sozinhas quando existirem.
  - Quadro do dash: `dash_texture()` usa `henry_incendiary_dash_<dir>` quando a folha existir; senão o andar.
  - Testes: `henry_incendiary_smoke` e `henry_incendiary_visual_smoke` atualizados (combustão, trilha, bola de
    fogo); `henry_barometric_smoke` agora valida a ignição da Combustão com o Barométrico.

## 6. Ultimate — Ignição Total (rework)
- **Antes:** os 8 quadros repetiam 3× (agacha → pega fogo) e cada pulso era um anel genérico de 280 px.
- **Agora:** uma animação contínua de 2,55 s com **3 impactos** em 0,70 s / 1,45 s / 2,20 s
  (soco no chão → braços abertos → martelo duplo). Cada impacto racha o chão e ergue um **anel de colunas
  de fogo** cada vez mais longe (150 → 225 → 300 px), com tremor crescente. Quem está perto apanha dos 3.
- Dano por impacto 0,9× (antes 0,78× em 280 px nos três).
- Quadros: `henry_incendiary_ultimate_sheet_v2` (10 quadros, tarefa `.codex/tasks/henry_incendiary_ultimate_sprites.md`);
  enquanto não chega, a folha v1 é remapeada na linha do tempo (sem repetir em loop).
- Texturas opcionais: `henry_fire_pillar`, `henry_ground_cracks`.
