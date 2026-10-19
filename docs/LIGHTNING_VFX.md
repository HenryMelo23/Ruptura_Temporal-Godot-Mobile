# Raios dinâmicos — apresentação

Owner: `scripts/presentation/lightning_presentation.gd`. Não decide dano,
colisão, alvo, cooldown, telegraph ou eventos de rede. Não usa RNG de gameplay.
Os owners anteriores continuam responsáveis pelas regras e pelos tempos.

## Fontes integradas

| Fonte | Integração |
| --- | --- |
| Elétrica: corrente, secundária, ultimate e teleporte visual remoto | `_draw_tesla_bolt` |
| Prismática: zaps coloridos | `_draw_prismatica_colored_bolt`; feixes ópticos continuam feixes |
| Projéteis elétricos/carregados | `_draw_projectiles` |
| Descarga de ambiente da fase 4 | `_draw_procedural_lightning_bolt` |
| Boss 4: conexões e tempestade de raios | `_draw_boss4_lightning_link`, `boss4_ultimate_ray` |
| Boss 1: carga, queda e impacto horizontal | `Boss1VFX.lightning` |
| Impactos verticais compartilhados | `VFXDirector.draw_world_vfx` |
| Abertura da loja | `_draw_shop_opening_upgrade` |
| Coroa elétrica dos inimigos | `_draw_tesla_enemy_crown` |
| Prévias no menu | `_draw_preview_bolt` (sem máscara de mundo) |

Ícones estáticos de HUD, lasers ópticos, fendas e feixes de drenagem não foram
convertidos em raios. O escopo é a descarga elétrica, não todo efeito luminoso.

## Desenho e orçamento

Canal muda com seed/tempo, endpoints fixos, ramificações presas ao canal,
núcleo claro, intensidade pulsante e centelhas curtas de contato. Sem nodes,
texturas adicionais ou luzes dinâmicas por descarga.

| Perfil interno | Segmentos máximos | Ramificações | Traços do canal |
| --- | ---: | ---: | ---: |
| ULTRA | 22 | 5 | 3 |
| HIGH | 14 | 3 | 2 |
| PERFORMANCE | 8 | 1 | 2 |

Usa configurações existentes, não adiciona outro seletor: baixo recurso ou
economia de memória → PERFORMANCE; orçamento adaptativo ou partículas
desligadas → HIGH; detalhe completo → ULTRA. Impactos verticais do Director
com partículas desligadas usam PERFORMANCE. Desktop/mobile seguem os mesmos
critérios. O canal principal permanece visível com partículas desativadas.

Após 20/48/80 chamadas por frame, conforme o perfil, o detalhe passa ao mínimo.
Isso limita detalhe, não o número de eventos de combate. O Director retém no
máximo 24 descargas verticais, com vida de 0,26 s. Não há limite novo de hits.

`begin_frame` abre contexto; o primeiro raio monta um índice espacial de
silhuetas visíveis; os demais reutilizam. `end_frame` impede que previews usem
máscaras antigas. Sem raio não ocorre varredura de inimigos.

O recorte é analítico contra **elipses aproximadas** do corpo, com margem para
o brilho; não é máscara por pixel. Segmentos ocultos não são reconectados.
Protege jogador, peers válidos, boss e inimigos, inclusive no overlay tardio
da loja. Partículas/halos intencionais de impacto continuam legíveis no chão.

## Reprodução e evidências

```sh
godot4 --headless --path . --script res://tests/lightning_presentation_smoke.gd
godot4 --headless --path . --script res://tests/lightning_geometry_benchmark.gd
xvfb-run -a godot4 --path . --script res://tests/lightning_visual_smoke.gd --display-driver x11 --audio-driver Dummy
godot4 --headless --path . --script res://tests/boss1_whirlpool_lightning_smoke.gd
godot4 --headless --path . --script res://tests/eletrica_kinetic_wave_smoke.gd
godot4 --headless --path . --script res://tests/vfx_runtime_extraction_smoke.gd
bash tools/validate_godot.sh
```

Smokes: determinismo temporal, endpoints, recorte sobreposto, limite de
geometria, ciclo de vida sem partículas, corrente elétrica com dano real e
teste de emissores existentes. Capturas em `.codex/lightning_vfx/`: Ultra
1280×720 e Desempenho 960×540, dois instantes e fontes adicionais de loja,
Director e Boss 4. A sprite remota usa o renderer real com snapshot de fixture;
isso **não** constitui uma sessão multiplayer.

Benchmark local inicial: 120 elipses e 12 canais com ramificações, 100 amostras
após aquecimento; PERFORMANCE média 1,62 ms/P95 2,02 ms; ULTRA média
4,39 ms/P95 5,67 ms. Inclui índice sintético/geometria/recorte, não GPU, draw
calls nem obtenção dos tamanhos reais. Não é comparação de FPS antes/depois.
Capturas usam Linux/llvmpipe: não provam desempenho Android físico.

Limites: sem teste em aparelho Android nem sessão real host/client nesta
tarefa; sem parse individual de toda a suíte. Validador padrão importa o
projeto e executa Boot por 300 frames. Architecture budget permanece acima da
referência em múltiplos owners anteriores; baseline não foi atualizado.
