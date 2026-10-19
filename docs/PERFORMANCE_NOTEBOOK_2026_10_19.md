# Otimização de desenho — 2026-10-19

Base: branch `runtime-refactor-2.0.48`, HEAD `c4eee47`, com alterações anteriores no workspace preservadas. Sem alteração de gameplay, resolução ou níveis de qualidade.

## Alterações desta etapa

- `scripts/presentation/entities_presentation.gd`: reutiliza dimensões e estilos de barras por tipo de inimigo dentro do mesmo frame. Mantém tintas, transparência, estados especiais, sombras e marcas. Não mantém cache de estado de gameplay entre frames.
- `scripts/presentation/gravitante_vfx_presentation.gd`: reutiliza malhas dos discos, evitando triangular os mesmos polígonos a cada desenho. Mantém os mesmos vértices, cores e transformação, com cache limitado a 20 malhas nos quatro níveis de detalhe.
- Testes: renderer anterior congelado em fixture, comparação visual pareada, instrumentação de desenho e verificação do cache da Gravitante. O benchmark de render agora rejeita execução headless para não ficar esperando um frame que não será apresentado.

## Evidência medida

Godot 4.7.2, Vulkan Mobile, GPU real Intel Graphics (RPL-P), Mesa 26.1.6. Renderização na sessão gráfica; não foi usado renderizador de software. Estes números medem envio de desenho pela CPU, não FPS de uma partida completa.

Comparação pareada de snapshots iguais, 40 amostras por versão/cenário:

| Cenário | Antes (ms) | Depois (ms) | Redução média |
| --- | ---: | ---: | ---: |
| Fase 1, 20 inimigos | 4,755 | 3,720 | 21,8% |
| Fase 1, 120 inimigos | 28,731 | 14,337 | 50,1% |
| Fase 2, 20 inimigos | 5,529 | 4,741 | 14,2% |
| Fase 2, 120 inimigos | 25,952 | 22,531 | 13,2% |

As 12 galerias (fases 1/2/3/4/6/7 em 1280×720 e 960×540) e os quatro cenários de multidão tiveram igualdade pixel a pixel. As galerias usam apenas duas amostras por versão: servem para equivalência visual, não conclusão de desempenho. A Gravitante também produziu imagens idênticas nos quatro LODs, com reaproveitamento das 20 malhas.

O workload de render completo HIGH:3 caiu de 34,11 ms para 28,63 ms de média e de 41,00 ms para 35,91 ms de P95 entre execuções. Há variabilidade entre execuções; a comparação pareada acima é a evidência principal. Não converter esses resultados em promessa de FPS durante gameplay.

Resultados locais: `.codex/render_optimization/results.json`, capturas na mesma pasta e benchmarks em `.codex/gravitante_vfx/`. Esses arquivos são evidência local, não artefatos de release.

## Validações executadas

```sh
godot4 --headless --path . --script tests/enemy_spatial_grid_smoke.gd
godot4 --headless --path . --script tests/mobile_adaptive_visual_budget_smoke.gd
godot4 --path . --audio-driver Dummy --disable-vsync --script tests/gravitante_vfx_performance_smoke.gd -- --label=profile_after --only=HIGH:0,HIGH:3 --profile-render
godot4 --path . --audio-driver Dummy --disable-vsync --script tests/enemy_render_equivalence_smoke.gd
godot4 --path . --audio-driver Dummy --script tests/gravitante_geometry_cache_smoke.gd
godot4 --headless --path . --script tests/gravitante_vfx_contract_smoke.gd
bash tools/validate_godot.sh --frames 60 --scene res://scenes/Main.tscn
```

Todos passaram. O contrato da Gravitante verificou 36 pares, lifecycle, dano e budgets. O validador concluiu `GODOT VALIDATION PASSED`; ainda há warnings de scripts existentes, portanto não se afirma console sem warnings. Foi executado o validador padrão, não a suíte deep completa.

## Limites

- Não houve partida longa, teste em aparelho Android nem sessão multiplayer real nesta etapa.
- A captura 960×540 verifica layout/render nessa resolução, não desempenho no Android.
- Os resultados não provam que todo travamento relatado foi resolvido; simulação, compilação inicial de recursos, sincronização e pressão de memória ainda podem contribuir.
- O cache pequeno de malhas troca algum armazenamento residente por menos trabalho repetido. Não foi medida redução de RAM.
- Sem commit, publicação ou nova versão nesta etapa.
