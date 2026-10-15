# UMBRA v1 × v2 — protocolo de avaliação do TCC

Este protocolo não parte da premissa de que a UMBRA v2 vence. Ele mede duas
policies congeladas sob os mesmos casos, sem condensar tudo em uma pontuação
única. Uma conclusão negativa, mista ou inconclusiva é um resultado válido.

## Hipóteses pré-registradas

- **H0:** com dificuldade controlada, não há diferença clara entre v1 e v2 nas
  métricas primárias.
- **H1:** a v2 altera a distribuição de ações depois de uma mudança
  determinística de padrão do jogador, sem piorar estabilidade nem justiça
  percebida.
- **H2:** a v2 mantém a mesma policy, pesos e observações no PC e Android
  dentro do orçamento de execução; não existe uma versão mobile simplificada.

As hipóteses, a matriz de casos, as seeds e as métricas residem em
[`tools/config/umbra_v1_v2_tcc_protocol_v1.json`](../tools/config/umbra_v1_v2_tcc_protocol_v1.json).
Essa configuração precisa ser versionada antes de olhar os resultados.

## Controle experimental

Para cada par `scenario_id + seed`, v1 e v2 recebem a mesma arena, versão do
Godot, commit do jogo, HP, dano, cadência, cooldowns, build, movimento do
jogador, duração, action mask legal e brain Hz. A policy não recebe uma
máscara extra de “ação desejada”. Assim, mais dano ou mais vitórias não são
interpretados isoladamente como mais inteligência: podem simplesmente refletir
força diferente.

O conjunto possui 64 episódios por policy:

| Grupo | Casos | Propósito |
| --- | ---: | --- |
| Controle | 16 | Win rate e dano nas condições pareadas. |
| Adaptação | 16 | O padrão do jogador troca no passo 48 sem alterar a dificuldade. Mede-se a distância entre distribuições de ações antes/depois. |
| Generalização | 32 | Builds/manifestações held-out, nunca usadas para ajustar as policies avaliadas. |

O runner que produzir os dados deve registrar todas as transições e não apenas
um resumo de vitória. Para os 16 casos de adaptação, ele precisa preencher as
duas janelas de ações e dano. Sem isso, o validador rejeita o relatório.

## Congelamento e dados brutos

Não use o JSON de pesos atualmente em `assets/weights/umbra_dqn_weights.json`
como v1 de pesquisa: ele não contém o contrato v1 compatível. Também não use
as fixtures determinísticas da v2 como modelo treinado. Primeiro obtenha os
dois artefatos executáveis e então congele seus hashes:

```bash
python3 tools/umbra_v1_v2_tcc_evaluation.py freeze \
  --protocol tools/config/umbra_v1_v2_tcc_protocol_v1.json \
  --v1-model /caminho/para/umbra-v1-compativel.json \
  --v2-model /caminho/para/umbra-v2-treinada.json \
  --out artifacts/umbra_v1_v2_tcc/frozen_manifest.json
```

O congelamento também recusa um JSON aleatório ou export incompatível: v1 deve
ser o DQN canônico de 24 entradas/23 saídas e v2 deve declarar o schema de
observação 2, 83 entradas e head de 23 ações. O manifesto copia a matriz de
seeds, o commit, os tamanhos e SHA-256 dos dois modelos. Não o edite depois do
congelamento. Cada executor grava um JSON bruto
por policy, com `manifest_sha256`, hash do modelo, todas as ações, tempos de
decisão/frame, pico de memória, dano, resultado, ações inválidas/rejeitadas e
crashes. Preserve os JSONs, os logs do runner e o CSV humano junto ao
manifesto; uma nova rodada deve usar outra pasta, nunca sobrescrever a rodada
anterior.

Depois da coleta:

```bash
python3 tools/umbra_v1_v2_tcc_evaluation.py summarize \
  --manifest artifacts/umbra_v1_v2_tcc/frozen_manifest.json \
  --v1-raw artifacts/umbra_v1_v2_tcc/v1_raw.json \
  --v2-raw artifacts/umbra_v1_v2_tcc/v2_raw.json \
  --human-csv artifacts/umbra_v1_v2_tcc/human_blinded.csv \
  --out artifacts/umbra_v1_v2_tcc/report.json
```

O sumário falha se uma seed/cenário estiver ausente, duplicado ou diferente do
manifesto; se o hash do modelo não for o congelado; se o JSON bruto não provar
que o artefato carregou e teve o contrato verificado pelo runtime; se faltar
uma janela de adaptação; ou se um campo de estabilidade essencial estiver
inválido.

## Métricas e interpretação

O relatório calcula, sem escolher vencedor automático:

- win rate com intervalo de Wilson de 95%, dano aplicado/recebido e duração;
- entropia de ações, número de ações distintas, repetição adjacente e maior
  streak de repetição;
- distância de variação total das ações antes/depois da mudança de padrão;
- os mesmos resultados separados para generalização held-out;
- CPU por decisão e por frame (média/P95), pico de memória, tamanho do modelo,
  ação inválida, recusa do executor, crash e divergência determinística;
- survey cego A/B com escalas 1–7 para inteligência, justiça e diversão, além
  de comentário livre.

O estudo humano deve randomizar a ordem A/B e não mostrar a versão da policy.
Ele é exploratório: informe N, desistências e limitações; não transforme uma
amostra pequena em prova de preferência.

## Situação inicial

Ainda não há comparação de v1 contra v2: falta um artefato v1 compatível e um
modelo v2 treinado congelado. Há somente um benchmark técnico da fixture v2 no
PC e nenhuma medição Android conectada; ele prova parte do runtime, não
inteligência, generalização, equilíbrio ou paridade de plataformas. Portanto,
o estado científico atual é **sem conclusão**.

O contrato do avaliador é coberto por:

```bash
python3 tools/umbra_v1_v2_tcc_evaluation_smoke.py
```
