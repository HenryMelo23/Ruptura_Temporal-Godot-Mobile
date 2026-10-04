# Gravitante — revisão visual

O renderer está em `scripts/presentation/gravitante_vfx_presentation.gd`.
Ele desenha no CanvasItem existente e consome posições, tempos, capturas e
escolhas do runtime. Não altera dano, alcance, cooldown, movimento autoritativo,
seleção de hospedeiro ou regras de bosses.

## Composição e integração

- ATK: pequeno núcleo negro com borda fria, rastro de arcos orientado pelo tiro.
  Uma textura procedural de 40 × 40 é criada uma vez e compartilhada pelos
  pequenos núcleos; não há emissor de partículas por tiro.
- Impacto/captura: compressão breve e interpolação curva a partir da posição
  real do projétil. Duração visual de captura: 320 ms; dano não é adiado.
- Orbitais: elipses inclinadas, precessão suave, desenho traseiro antes dos
  personagens e dianteiro depois, halo breve baseado no tick real de dano.
- Transferência: curva tangencial entre a última posição orbital e o novo
  hospedeiro já escolhido pelo gameplay.
- Q: um evento coletivo guarda até oito posições anteriores à colisão;
  curvas convergem, halo comprime, núcleo fecha e onda abre. A colisão de
  gameplay continua imediata; a sequência é feedback visual, não telegraph
  que adia a habilidade.
- TP: origem contrai, destino reabre; eco comprimido da textura da personagem.
  Os eventos cosméticos têm recipiente próprio e não prolongam o cooldown.
- Ultimate: precursor, crescimento, disco elíptico em faixas, horizonte negro,
  lente falsa e matéria em espiral. Capturas/poder/velocidade alimentam tiers
  limitados; últimos 620 ms comprimem o conjunto, seguidos de um anel curto.
- Capturados: um eco tangencial discreto, limitado por qualidade. Boss mantém
  posição e tamanho reais e recebe arcos de resistência mais espessos.
- Preview da seleção: atlas de ATK/Q/Ultimate recapturados; fallback procedural
  reutiliza o renderer de projétil, convergência e singularidade.

Removidos do caminho antigo da Ultimate: malha de 140 quadriláteros texturados,
81 recortes adicionais do mapa, 34 fragmentos, feixes/cracks e múltiplas camadas
redundantes. O renderer novo não reamostra o mapa, em nenhuma qualidade.
Foram removidos também os bursts cosméticos antigos do Q/nascimento e o
rastro genérico de partículas do ATK gravitante.

## Evoluções: feedback e fonte do estado

| Evolução | Apresentação | Gatilho/dado consumido |
| --- | --- | --- |
| EV1 Limite de Roche | Até três fragmentos pequenos na órbita externa | Orbital ativo, fase orbital |
| EV1 Estilingue Gravitacional | Crescente e arco tangencial reforçado | Transferência efetiva de hospedeiro |
| EV1 Massa Crescente | Núcleo/halo se intensificam sem corpos adicionais | Idade visual do orbital |
| EV1 Sistema Binário | Pequeno baricentro e duas curvas | Dois hospedeiros orbitais visíveis |
| EV1 Lua Cativa | Até três satélites com frente/trás em Geovana | Existência de orbitais ativos |
| EV1 Maré de Passagem | Duas curvas longitudinais | Origem/destino do TP |
| EV2 Singularidade Compartilhada | Micro-singularidade com detalhe mínimo | Evento visual do Q |
| EV2 Sistema Planetário | Baricentro com até três curvas | Até três hospedeiros visíveis; campo existente usa mini-renderer |
| EV2 Evento de Maré | Anel viajando da borda ao núcleo | Ultimate ativa; TP mantém acento de maré |
| EV2 Colapso de Massa | Halo/núcleo residual que contrai | Perda de hospedeiro com transferência |
| EV2 Órbita Caótica | Elipse fantasma translúcida | Somente orbital representativo principal |
| EV2 Horizonte de Ruptura | Disco/rotação por tier e flash orbital sincronizado | Capturas e temporizador de pulso da Ultimate |

Limite de escopo: o catálogo local de evoluções usa adaptadores de gameplay
compartilhados. Esta revisão adiciona identidade visual pelos IDs reais; não
implementa mecânicas novas de fragmentos, pares físicos, satélites ofensivos ou
acúmulo de massa. Os satélites/baricentros adicionais são cosméticos. A idade
visual em Massa Crescente não inventa um atributo de massa no save.

## Orçamento

O detalhe deriva de `_memory_saver_active`, `_runtime_visual_budget_active`,
`gfx_low_resource` e da plataforma mobile. Não existe controlador adaptativo
concorrente.

| Limite | HIGH | MEDIUM/adaptativo | LOW/mobile | MEMORY |
| --- | ---: | ---: | ---: | ---: |
| Segmentos por arco | 36 | 24 | 16 | 12 |
| Debris por Ultimate | 14 | 8 | 5 | 3 |
| Orbitais completos por hospedeiro | 3 | 3 | 2 | 1 |
| Curvas de Q | 8 | 5 | 3 | 2 |
| Ecos de inimigos por Ultimate | 12 | 9 | 6 | 0 |
| Recortes do mapa | 0 | 0 | 0 | 0 |

Acima de 24 orbitais representativos na tela (10 nos modos menores), os
seguintes mantêm o núcleo mas perdem decoração/trilha. Eventos de impacto,
Q e resíduo expiram e têm limite de 24; impactos não expulsam Qs ativos.
Elementos fora da tela não são desenhados. Pares/grupos cosméticos usam no
máximo três âncoras, sem comparação all-pairs. Geometria do disco é cacheada.

## Reprodução

```sh
godot --path . --rendering-method mobile --audio-driver Dummy --script res://tests/gravitante_visual_smoke.gd
godot --path . --rendering-method mobile --audio-driver Dummy --disable-vsync --script res://tests/gravitante_vfx_performance_smoke.gd -- --label=after_fixed
godot --headless --path . --script res://tests/gravitante_vfx_contract_smoke.gd
```

Capturas e JSONs ficam em `.codex/gravitante_vfx/`. A galeria congela a
simulação e força estados de teste; são desenhos reais do renderer, não
imagens conceituais. As folhas de contato apenas recortam essas capturas.

O benchmark mede submissão CPU até `frame_post_draw`, draw calls do engine,
contagens de entidades e P95. Não mede GPU isolada, FPS de uma partida completa
nem desempenho de Android físico. São seis cenários × quatro qualidades,
fase inicial fixa, seed fixa, VSync desligado, 20 frames de aquecimento e
80 amostras por cenário. Feedbacks transitórios são limpos entre cenários.
Os JSONs sem `_fixed` são ensaios descartados: a fase inicial ainda era
sorteada e alguns feedbacks acumulavam entre cenários.

## Validação e comparação

Rodada de 01/10/2026, Godot 4.7.2, Mobile/Vulkan, Intel Graphics RPL-P,
1280 × 720. Baseline visual extraído de `b4d327c` em cópia temporária isolada;
mesmos assets, fixture e fase. Execuções antes/depois foram seriais.

| Cenário | Qualidade | Antes (ms) | Depois (ms) | Variação | Draw calls antes → depois |
| --- | --- | ---: | ---: | ---: | --- |
| 120 inimigos + 60 orbitais + Ultimate | HIGH | 43,67 | 29,17 | -33,2% | 1322 → 722 |
| Mesmo cenário | LOW | 43,43 | 26,65 | -38,6% | 1322 → 681 |
| Mesmo cenário | MEMORY | 50,32 | 26,08 | -48,2% | 1322 → 659 |
| Boss + Ultimate + 20 orbitais | HIGH | 31,68 | 22,36 | -29,4% | 777 → 358 |
| 100 inimigos + 60 orbitais + EV1/EV2 + Ultimate | HIGH | 43,72 | 29,06 | -33,5% | 1226 → 698 |

Dados completos: `.codex/gravitante_vfx/before_fixed_performance.json` e
`after_fixed_performance.json`. Os modos leves foram simulados no desktop;
não são resultados de hardware Android.

Os cenários menores oscilaram. HIGH/20 inimigos teve +34,7% na primeira rodada,
mas +6,4% e -13,6% nas duas repetições isoladas. LOW/60 inimigos teve +17,1%,
seguido por -6,5% e -18,9%. Os JSONs `before_repeat_1/2` e `after_repeat_1/2`
guardam essas repetições. Não há alegação de ganho uniforme nem de 60 FPS em
partida completa: o ganho mais claro é a remoção do custo da Ultimate antiga.

### Verificações executadas

- `gravitante_smoke`: captura, giro, dano de borda, transferência e boss.
- `gravitante_vfx_contract_smoke`: dano/centro do Q, captura/transferência sem
  mutação das regras, expiração/reset, cap de 24, independência do TP, quatro
  níveis de detalhe e reconhecimento dos 36 pares EV1/EV2.
- `ground_target_skills_smoke`: mira no chão, TP e habilidades das demais
  manifestações cobertas pelo teste. Fixture libera a animação de entrada
  antes de testar os comandos.
- `manifest_evolution_smoke`, catálogo de 180 definições, matriz funcional
  de 180 definições e matriz de 540 pares.
- `boss4_nexus_mechanics_smoke` e `multiplayer_transport_smoke`.
- `settings_teleport_vfx_visual_smoke`: três capturas em 1280 × 720, incluindo
  o TP da Gravitante e outros nove TPs; janela de teste sem bordas para não
  perder pixels da altura para a decoração do desktop.
- `manifest_preview_capture_smoke --key=gravitante`: três atlas de 24 frames;
  simulação da captura em passos fixos para não depender do tempo do encoder.
- `manifest_preview_assets_smoke`: 45 atlas, dimensões e conteúdo visível.
- Validador profundo: importação, parse de 378 scripts e 60 frames da Main.
- Orçamento de arquitetura e `git diff --check`.

As matrizes de 540 pares, smoke geral de evoluções e transporte passaram suas
asserções, mas seus logs têm aviso de recursos ainda vivos ao encerrar. Isso
não foi apresentado como execução inteiramente limpa. Os testes focados de
Gravitante tiveram sua limpeza ajustada. Transporte simulado não equivale a
uma partida host/client real.

### Capturas reais

- `01_atk_orbitais_q_tp.png`: 15 estados de ATK, impacto, captura, profundidade,
  tick, transferência, slingshot, Q e TP.
- `02_ultimate_lod.png`: nascimento, sustentação, captura, boss, colapso e LOD.
- `03_evolucoes.png`: seis EV1 e seis EV2.
- `04_antes_depois.png`: comparação de capturas do benchmark controlado.
- `mobile_landscape_960x540.png`: viewport paisagem menor no renderer desktop.
- `preview_atk/skill/ultimate.png`: prévias no catálogo existente.

Os PNGs ficam em `.codex/gravitante_vfx/`. Não são mockups nem artes geradas
por IA. O roteiro visual congela estados; a avaliação de sensação durante uma
partida longa e o teste em Android físico continuam pendentes.

### Arquivos desta revisão

Runtime: `scripts/presentation/gravitante_vfx_presentation.gd` (novo),
`scripts/main_runtime_state.gd`, `scripts/main_runtime_core.gd`,
`scripts/presentation/combat_effects_presentation.gd`,
`scripts/presentation/entities_presentation.gd`,
`scripts/presentation/menus_presentation.gd`, `scripts/vfx/combat_vfx_runtime.gd`.

Testes: `tests/gravitante_vfx_contract_smoke.gd` e
`tests/gravitante_vfx_performance_smoke.gd` (novos),
`tests/gravitante_smoke.gd`, `tests/gravitante_visual_smoke.gd`,
`tests/ground_target_skills_smoke.gd`,
`tests/settings_teleport_vfx_visual_smoke.gd`,
`tests/manifest_preview_capture_smoke.gd`.

Assets: os três `assets/previews/manifestations/gravitante_*.webp`.
Navegação/documentação: `AGENT_CODEMAP.md`, `.agents/runtime_symbol_index.md`
e este relatório. Os UIDs de scripts novos são metadados gerados pelo Godot.

Alterações anteriores do catálogo/runtime, baseline de arquitetura e
`assets/sprites/Fase10.png` foram preservadas; não foi criado commit ou push.
