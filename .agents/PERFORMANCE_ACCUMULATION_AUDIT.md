# Auditoria de acumulacao e queda de FPS

Data: 2026-10-29

## Cenario controlado

- Godot 4.7.2, renderer `gl_compatibility`, Mesa `llvmpipe`.
- 180 segundos reais por variante, limite de 60 FPS.
- Seis inimigos mantidos no mapa.
- HUD permaneceu ativo.
- Na variante com mortes, os drops/cristais de `heal_orbs` foram removidos a cada quadro.
- Amostragem de todas as propriedades `Array` e `Dictionary` do runtime, inclusive colecoes aninhadas de primeiro nivel, mais objetos, nos, memoria estatica e VRAM.

Estes numeros servem para comparacao relativa local. Nao equivalem a GPU/RAM/FPS de um aparelho Android fisico.

## Resultados de 3 minutos

| Variante | Carga | Minuto 1 p50/p95 | Minuto 3 p50/p95 | Resultado |
| --- | --- | --- | --- | --- |
| Baseline | seis inimigos estaticos | 16,66 / 25,02 ms | 16,67 / 20,91 ms | sem queda progressiva |
| Autosave interrompido desligado | seis inimigos estaticos | 16,66 / 26,10 ms | 17,01 / 22,35 ms | nenhuma melhora; hipotese descartada |
| Persistencia de progresso desligada | seis inimigos estaticos | 16,67 / 25,42 ms | 16,70 / 21,64 ms | nenhuma melhora; hipotese descartada |
| Baseline antes da correcao | 240 mortes, seis inimigos, sem cristais | 16,68 / 28,12 ms | 17,80 / 27,56 ms | queda leve reproduzida |
| Persistencia realmente zerada | 240 mortes, seis inimigos, sem cristais | 16,68 / 27,32 ms | 17,55 / 26,12 ms | diferenca pequena e inconsistente; nao causal |
| Baseline apos correcao | 240 mortes, seis inimigos, sem cristais | 16,68 / 28,41 ms | 17,51 / 25,90 ms | p50 -1,6%, p95 -6,0% e pior quadro 63,92 -> 43,34 ms contra o baseline anterior |

## Colecoes e hipoteses

- `run_damage_events`: limite de 240.
- Telemetria minima: limites independentes de 80 a 180 eventos; runtime, 96.
- `run_heatmap_cells`: chaves finitas por fase e celula.
- Historicos de fase/boss/rede: janelas ou limites explicitos (18, 28, 40 ou tempo recente).
- VFX principais: removidos por vida; limites adicionais entram nos perfis mobile/memory saver.
- `player_progress_pending_events`: chegou a 18 no teste de 240 mortes, mas o teste zerando fila, escrita e sincronizacao nao removeu a queda. O limite global permanece 240 e eventos de uma mesma metrica sao agregados.
- `interrupted_run_summary`: cresceu de 0 para seis campos fixos e estabilizou.
- `metadata/lightning_draw_context`: seis campos fixos, substituidos a cada quadro; nao cresce depois da inicializacao.
- Objetos/nos: houve acomodacao inicial e depois plateau. No teste de mortes, objetos ficaram estaveis dos 60 aos 120 segundos e tiveram apenas uma pequena mudanca transitoria depois.
- VRAM caiu apos o aquecimento e permaneceu estavel; nao houve crescimento de VRAM nos seis testes longos validos.

## Correcao mantida

`MenusPresentation._draw_effects` criava um novo array com `effects + net_effects` a cada quadro. A iteracao agora usa indices sobre as duas colecoes sem copiar todos os VFX. A correcao reduziu o p95 e os piores quadros no teste com mortes, sem reduzir quantidade ou qualidade visual.

## Hipoteses descartadas nesta rodada

1. Autosave temporario da run como causa da queda progressiva.
2. Escrita/sincronizacao/fila de progresso como causa principal.
3. Crescimento de HUD ou cristais do chao no cenario reproduzido.
4. Crescimento linear das colecoes de runtime amostradas.

## Proxima investigacao recomendada

A queda leve restante acompanha mortes/atividade, mas nao o tamanho das colecoes. O proximo passe deve medir tempo por subsistema no aparelho alvo (update de inimigos, desenho de entidades, audio e VFX) e comparar CPU/GPU frame time. Nao repetir autosave nem persistencia de progresso sem nova evidencia.

## Segunda rodada: combate sustentado e modo Desempenho

Data: 2026-10-29

- Fixture real-time de cinco minutos: modo Desempenho, 12 inimigos moveis, 56 projeteis, morte e reposicao a cada 0,75 s, total de 400 mortes.
- Baseline: p50 de 32,77 ms no primeiro minuto e 33,49 ms no quinto; deriva de 0,72 ms.
- A repeticao apos eliminar rastros desligados e paletas repetidas reduziu o bloco de desenho de projeteis em cerca de 24% e o bloco de mundo em cerca de 4%, mas nao elevou o FPS total no llvmpipe.
- O tempo medido em GDScript ficou perto de 6,3 ms para update e 6,0 ms para montar o desenho. O restante do quadro ocorreu na execucao/sincronizacao do renderer por CPU.
- Diagnostico de dois minutos sem desenhar projeteis, mas mantendo sua simulacao: aproximadamente 31,6 FPS contra 28 FPS completos, ganho de cerca de 11%.
- Diagnostico de dois minutos sem desenhar inimigos, mas mantendo IA e combate: aproximadamente 33,6 FPS, ganho de cerca de 18%.
- Agrupar sprites de inimigos danificados foi testado e descartado: alterava a ordem de composicao em multidoes sobrepostas e nao compensava o segundo passe de barras no limiar de 12.
- Agrupamento seguro ficou restrito a inimigos comuns intactos e sem estados especiais, com limiar 12 no mobile/desempenho e 32 no perfil normal. A equivalencia passou em 20 cenarios e duas resolucoes.
- O perfil Desempenho nao limita mais um aparelho saudavel a 45 redesenhos por segundo; 45/40 Hz ficam reservados a degradacao adaptativa realmente acionada por FPS baixo.
- Cenario final de cinco minutos com seis inimigos, 56 projeteis e 400 mortes: media de 31-32 FPS no llvmpipe; p50 29,38 ms no primeiro minuto e 30,18 ms no quinto; deriva 0,80 ms.
- Nesse cenario de seis inimigos, update ficou perto de 4,6 ms e montagem do desenho perto de 5,1 ms. Aproximadamente 20 ms adicionais ficaram fora dos blocos GDScript, na execucao/sincronizacao do renderer por CPU.
- A meta de 55-60 FPS nao foi atingida nem certificada neste ambiente. O smoke aceita `--enforce-target` para transformar o alvo nao atingido em codigo de saida de falha durante a medicao no aparelho.

Nenhum Android estava conectado via ADB. Estes resultados nao certificam 55-60 FPS no aparelho fisico. A proxima medicao valida deve durar pelo menos cinco minutos no dispositivo, com o mesmo numero de inimigos/projeteis e amostragem por minuto.
