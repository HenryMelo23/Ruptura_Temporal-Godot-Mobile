# Reconciliação com o backup 2.0.43

## Origem e decisão

- Branch de trabalho: `refactor-runtime-core-continuation`.
- Trabalho antes da integração: `4c04ea0`.
- Backup incorporado: `origin/codex/release-2.0.43`, `31d7d8c`.
- Base comum: `0659225`.
- Integração por merge com adaptação dos owners; backup não reescrito.
- Este registro trata da integração; a publicação 2.0.44 é uma etapa posterior.

O reroll pago não era uma funcionalidade nova a criar. A branch de trabalho
estava sem parte da linha de release. A reconciliação recupera essa linha inteira
antes de implementar as três melhorias de apresentação solicitadas.

## Preservação funcional

| Área | Resultado da reconciliação |
| --- | --- |
| Reroll | 3 gratuitos; primeiro pago em 20% do custo da carta, crescimento 1,6x e teto 3x. Nenhuma fórmula de 25% introduzida. |
| Queimar | Catálogo e bônus por atributo recuperados; contagem efetiva também passa pelo owner de progressão. |
| Saves | Identidade recuperável, cache assinado e fila offline preservados no save owner. Snapshot schema 1 inclui rerolls pagos, bônus de Queimar e contador de fragmentos. |
| Fases | Owner preserva carry de densidade, autoridade de desbloqueios, reset do encontro e limpeza de VFX da Gravitante. |
| Runs longas | Baseline de economia/HP/spawn mantido; os 70% usam o cap efetivo anterior, já incluindo a pressão late-game, sem multiplicar novamente na entrada. |
| Conteúdo | Mapas, Gravitante, catálogo de evoluções, Event Director, Larápio, scaling de bosses e contratos multiplayer recuperados. |
| Arquitetura | Save/Phase/Progression/BossWave continuam extraídos. Core: 47.443 linhas no backup → 46.378 na integração, redução de 1.065 linhas. |

A comparação por símbolo não encontrou funções do core do backup ausentes,
descontadas as implementações delegadas aos owners. As diferenças restantes são
binding/cleanup dos controllers e o baseline de runs longas já aprovado.

## Correções expostas pelos testes

### Cache de progresso

A assinatura antiga dependia de tipos numéricos em memória: JSON transforma
inteiros em floats ao carregar. O teste anterior assinava e validava sem passar
pelo disco, por isso não detectava o problema.

- Assinatura local v2 usa a representação JSON persistida; schema do payload
  continua 1, com `cache_signature_version` aditivo.
- Cache v1 continua aceito mediante sua assinatura original, restaurando apenas
  os tipos inteiros conhecidos; nenhuma assinatura é dispensada.
- Arquivo adulterado, assinatura corrompida e versão desconhecida são rejeitados.
- O backend continua sendo a fonte canônica; a chave local não torna o cache
  autoritativo perante o servidor.

### UMBRA

O arquivo legado `assets/weights/umbra_dqn_weights.json` tem 22 saídas e não tem
o contrato versionado. Seus bytes foram preservados, mas o runtime/exportador
agora apontam para `umbra_dqn_2_0_actions_23.json`.

Esse modelo treinado compatível ainda não está disponível. O fallback não-DQN
existente permanece ativo. Não houve padding, fabricação de pesos, reordenação
silenciosa, mudança de reward ou de heurísticas. O loader continua rejeitando
contratos inválidos com diagnóstico específico. Ver `assets/weights/README.md`.

### Harnesses

- Teste Voraz distingue orbe de fome de drops aleatórios normais de cura e não
  sobrescreve falha com saída de sucesso.
- Teste de fase 5 valida o carry de 70%, não o antigo cap fixo 5.
- Matriz de evoluções e teste de orbes limpam suas instâncias antes de sair.
- Testes de rede aceitam diretório isolado de resultados, impedindo falso
  positivo por arquivos de execuções anteriores já presentes no repositório.

## Validação

Comandos reproduzíveis, usando diretórios temporários para não alterar saves
reais do jogador:

```bash
XDG_DATA_HOME="$(mktemp -d /tmp/ruptura-check-XXXXXX)" godot --headless --path . --script tests/runtime_backup_reconciliation_smoke.gd
python3 tools/run_multiplayer_reconciliation_smoke.py
XDG_DATA_HOME="$(mktemp -d /tmp/ruptura-deep-XXXXXX)" bash tools/validate_godot.sh --deep --scene res://scenes/Boot.tscn --frames 120
python3 tools/check_architecture_budget.py
```

Cobertura focada: save/config ausente/corrompido, autosave/resume/retry e bloqueios
online; cache v1/v2/tamper/fila; reroll; atributos de Queimar; densidade e runs
longas; scaling de bosses; preservação do Larápio; contrato DQN e fase 5; 180
definições/540 combinações de evolução; revive, desbloqueios, orbes e loja
multiplayer; Event Director e telemetria.

Resultados: importação e parse profundo de 400 scripts concluídos; Boot e Main
executados por 120 frames sem erros do Godot. Rede local: confirmação de pronto,
espectador, compra/saída consensual da loja e fluxo dedicado + três jogadores
até manifestação, espectro e partida passaram. O teste de lobby também exercita
reenvio, timeout e reconhecimento de confirmação por sequência.

Capturas renderizadas em 1280×720 e 960×540: mapas das oito superfícies e galeria
da Gravitante (39 capturas, renderer Mobile/Vulkan). Teste de movimento dos mapas
cobre perfis normal/leve, centro estável e tempo congelado. Não é benchmark de
celular: o ambiente de captura usa renderização por software.

Limites: testes de rede são locais, não homologação da VPS pública nem de APK/EXE
instalado. As melhorias novas de Queimar/loja/deck da equipe continuam sendo a
próxima etapa; esta integração não as declara entregues.
