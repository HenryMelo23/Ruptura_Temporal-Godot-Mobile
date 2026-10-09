# Boss 3 — apresentação dos Miasmas da Vida

Branch: `runtime-refactor-next`. Escopo: variantes **1, 2 e 4**, somente apresentação. O Ritual em Setores e a Umbra mantêm seus desenhos e regras.

## Referências realmente inspecionadas

- `assets/sprites/Boss3_1.png`: capuz ameixa quase preto, bordado oliva, rosto de cera/queijo, reflexos de marfim; reaproveitado nas cinco aparições.
- `assets/sprites/Boss3_2.png`: segundo frame do mesmo Pai-Rato; preservada a seleção existente da animação.
- `assets/maps/calm/phase_3.png`: mapa efetivamente usado na captura; pedra cinza, limo oliva, dourado envelhecido, motivos de olho/lua.
- `assets/sprites/Fase3.png`: referência legada da Catedral; alvenaria rachada e iconografia ritual.
- `assets/sprites/queijo.png`: granulação e cavidades reaproveitadas como pequenos recortes na superfície fechada das pálpebras.
- `assets/sprites/disparo_boss3.png`: frasco verde existente; referência de contraste, sem alteração no projétil.
- `assets/fonts/World.otf`: fonte já utilizada pela HUD e reaproveitada no aviso e no QTE.

Os sprites e os recortes existentes são usados diretamente. Não foram criadas imagens grandes, partículas persistentes, shaders de tela inteira ou dependências novas. Contornos e movimentos são quantizados em uma malha visual de 2 px. Modo leve reduz fatias, ecos e detalhes.

## Alterações

**Alucinação:** as quatro cópias e o boss real são desenhados pelo mesmo caminho, com a mesma textura, escala, opacidade, sombra e ordenação por profundidade. Fatias curtas na troca de posição, ecos sobrepostos e névoa rasteira substituem anéis verdes e o filtro amarelo de tela inteira. O desenho lê as posições e o timer já existentes, sem sortear nada.

**Breu:** a abertura quadrada foi substituída por uma máscara opaca de contorno irregular, penumbra estreita e véu escuro exterior. A máscara nunca revela pontos além dos 250 px. A respiração invade apenas a borda interna. Quatro polígonos principais e oito faixas substituem centenas de pequenos desenhos; o centro preserva personagem, projéteis e aviso do cuspe.

**Olhos fechados:** contornos em degraus, camadas de tecido escuro, granulação do queijo, secreção e poucos filamentos substituem as linhas luminosas e os círculos. O vínculo tem fios estreitos, sem halos nos personagens. O painel central reúne instrução de plataforma, taps/required, tempo, overtime e progresso. A área de toque continua sendo a área original do runtime.

O fechamento visual usa a flag real no host. Como o contrato de rede existente não transmite essa flag, o cliente representa a mesma janela de 0,18 s a partir de `boss3_miasma_qte_elapsed`, `taps` e `required` já recebidos; não há relógio local nem mudança de pacote. O teste compara esse resultado com a decisão real do runtime em 27 situações.

A entrada e saída dos acentos decorativos usam os timers recebidos. O fim deixa somente um resíduo periférico de até 0,24 s, sem prolongar restrição de visão ou input. Derrota do boss, morte do jogador, spectator e troca de fase removem esse resíduo. No breu, a cobertura além do raio permanece opaca desde o primeiro frame: o acabamento de entrada não abre uma janela de informação fora da área permitida. As mensagens existentes distinguem o sucesso e a falha do QTE. Nenhum SFX por frame foi introduzido; áudio e vibração permanecem no fluxo existente.

## Contrato preservado

| Parâmetro atual | Valor preservado |
| --- | --- |
| Variantes / sorteio | `[1, 2, 4]`, mesma bag |
| Duração não-QTE | 15 s |
| Cooldown atual | 24 s |
| Clones / troca | 4 / 1,5 s |
| Breu / aviso do cuspe | 250 px / 0,8 s |
| QTE base / janela | 18 toques / 7 s |
| Hitboxes, dano, status, overtime e input | Implementação original |

`main_runtime_core.gd`, `main_runtime_state.gd` e `systems/online/net_contract.gd` têm os mesmos SHA-256 do início desta tarefa. Os testes visuais comparam state/RNG antes e depois de desenhar. Nenhum símbolo das antigas nuvens perseguidoras foi adicionado.

## Capturas e reprodução

Capturas locais: [antes](../../.codex/miasma_before/) e [depois](../../.codex/miasma_after/). Cada conjunto contém 30 imagens em 1280×720 desktop e 960×540 com UI Android/modo leve: entrada, manutenção, saída e cleanup de clones/breu; QTE em 0%, 50%, 17/18, contato e overtime; também os dois estados do Ritual em Setores. O harness anterior deixava a animação inicial de queda ativa; a captura final desativa essa animação de teste para mostrar Geovana no chão. Isso não altera código de gameplay.

| Sintoma | Antes (desktop) | Depois (desktop) |
| --- | --- | --- |
| Alucinação | [captura](../../.codex/miasma_before/v1_middle_1280x720_desktop.png) | [captura](../../.codex/miasma_after/v1_middle_1280x720_desktop.png) |
| Breu | [captura](../../.codex/miasma_before/v2_middle_1280x720_desktop.png) | [captura](../../.codex/miasma_after/v2_middle_1280x720_desktop.png) |
| QTE | [captura](../../.codex/miasma_before/v4_middle_1280x720_desktop.png) | [captura](../../.codex/miasma_after/v4_middle_1280x720_desktop.png) |

```sh
xvfb-run -a godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script tests/boss3_miasma_visual_smoke.gd
```

O harness verifica dimensões reais das imagens, grava `performance.json` e falha se o desenho modificar state do miasma ou RNG. As imagens em `.codex/` são evidências locais, não assets de distribuição.

## Validações

- `tests/boss3_miasma_smoke.gd`: variantes, quatro clones, troca, cooldown, cuspe, dano e ausência da variante 3.
- `tests/boss3_miasma_visual_smoke.gd`: matriz de 30 capturas desktop/mobile leve, sem erros de desenho após correções.
- `tests/boss3_miasma_presentation_contract_smoke.gd`: snapshots 1/2/4, 27 combinações de QTE host/replica, 3.600 amostras de raio, RNG preservado e cleanup.
- `tests/phase3_desktop_miasma_qte_smoke.gd`: input de centro e rejeição de toque fora da área.
- `tests/boss_ultimate_time_stop_smoke.gd`: QTE/ultimate, regras de dano e parada do tempo.
- `tests/multiplayer_network_smoothing_smoke.gd`: snapshots e interpolação existentes, incluindo Miasma do Boss 3.
- `tools/validate_godot.sh --scene res://scenes/Main.tscn --frames 120`: importação/validação e boot da cena passaram; warnings legados de GDScript permanecem.
- `git diff --check`: sem erros de whitespace.

Performance foi medida em **Mesa llvmpipe**, renderização por software. A métrica é submissão CPU até `frame_post_draw` em cena estática, não FPS de gameplay nem tempo GPU. O relatório detalhado está em [performance.json](../../.codex/miasma_after/performance.json). Na otimização desta tarefa, as chamadas totais da cena de breu caíram de 534 para 218 no desktop e de 399 para 191 em mobile leve; essa comparação é entre duas iterações do redesign, não contra o código anterior.

Não foram exercitados: Android físico/Helio G80, toque em aparelho, sessão de rede com jogadores reais, nem desconexão/reconexão real durante combate. A cobertura multiplayer aqui usa os serializers e aplicação de snapshots reais em instâncias locais. O desempenho Android e a legibilidade durante uma partida longa continuam dependendo de playtest em hardware.
