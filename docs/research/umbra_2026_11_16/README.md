# Evidências — Umbra/Apolo, 16/11/2026

Esta pasta preserva dados do piloto e provas de contrato. Não é um resultado
confirmatório de evolução da Umbra. O plano e a auditoria de código estão em
[`../../UMBRA_APOLO_TCC_AUDIT.md`](../../UMBRA_APOLO_TCC_AUDIT.md).

## Piloto de treinamento linear

Comando executado a partir da raiz do projeto:

```bash
python3 tools/umbra_learning_audit.py experiment \
  --train-episodes 16 --episodes 8 --seconds 45 \
  --out .agent_logs/umbra_evidence/20261116_fit_v2
```

Godot 4.7.2. Seed de treino 271; seeds dos episódios 27100813–27100828.
Seed de avaliação 10271; episódios 1027130813–1027130820. O protocolo e
os argumentos exatos foram gravados antes da avaliação em
[`pilot/manifest.json`](pilot/manifest.json).

| Medida | Antes do fit | Depois do fit |
| --- | ---: | ---: |
| Episódios de avaliação | 8 | 8 |
| Score médio `10·dano causado − 30·dano recebido`, em frações de HP | 1,4964 | 1,8082 |
| Dano causado, média da fração de HP | 0,3818 | 0,4133 |
| Dano recebido, média da fração de HP | 0,07739 | 0,07751 |
| Vitórias da Umbra | 0 | 1 |

Diferença média de score: +0,3118. Intervalo bootstrap exploratório de 95%:
**[−0,9811; +1,4299]**. Inclui zero. Todos os oito pares tiveram histogramas
de ações diferentes; isso comprova alteração comportamental neste teste,
sem demonstrar melhora consistente. A repetição dos oito episódios do
candidato reproduziu exatamente os resumos registrados.

O fit usou 334 amostras de decisão em 16 episódios e ajustou três ações
com cobertura mínima: ATAQUE, TELEPORTE e MIASMA. As outras ações mantiveram
seus pesos anteriores. Não houve vitória da Umbra no lote de coleta.
Há apenas uma seed independente de treinamento e um adversário heurístico.
Os 45 s limitam a avaliação a um trecho do encontro.

O candidato ficou congelado durante avaliação e replay. Não houve mudança
das fontes monitoradas durante esta rodada. A base embarcada permaneceu
inalterada: SHA-256
`f30fd5fa6d326516e0ee0a496602c55eae7f56eae18dd0edfc5975c39bd06c3e`.
O candidato experimental tem SHA-256
`76d7e241878c771fa36369c8b3e99af70d5b1817ff2ec0096a38f1bdc1d26c32`.

Conclusão: **ajuste de parâmetros demonstrado; efeito em ações demonstrado;
melhora de competência inconclusiva; coevolução e semelhança humana não
avaliadas**. Nenhum arquivo foi promovido para `assets/data` ou publicado.

## Provas sintéticas e contraprovas

[`contract/probe.json`](contract/probe.json) registra 33 checks executados:

- Memória pessoal: retornos artificiais conhecidos produziram, após
  persistência/reload, scores ATAQUE=−0,1 e REBOBINAR=+0,1; antes eram zero.
- Camada coletiva: o método real `_apply_umbra_mind_payload` gravou o
  arquivo igual ao payload; `load_layers` carregou `base` + `coletiva`,
  alterando os scores. Dados inteiramente sintéticos; sem HTTP.
- Percepção: presença de sinal para as 11 categorias de ataque examinadas.
  Isso não mede esquiva nem atribuição correta de cada dano.
- Lacunas neurais: Eco/Rebobinar não estão no action schema; Sopro Ártico
  deixa o indicador de prisão desligado; base/Vórtice têm a mesma feature
  normalizada (−1).
- Ponte PPO: atualização isolada do boss deixou o plasma imóvel;
  atualização normal de projéteis o moveu. É uma contraprova da hipótese
  de que o rollout atual simula combate completo.

[`collective/report.json`](collective/report.json) registra 32 ingestões
sintéticas, rejeição de duplicata e persistência idêntica após reload. A
contraprova de metadados gera versões `umbra-col-f5b9a6cb93` e
`umbra-col-fba21c77fb` com parâmetros idênticos. O contador sozinho não
comprova aprendizado.

Comandos para repetir os contratos, sempre com pastas novas:

```bash
mkdir -p /tmp/umbra_probe_novo/data /tmp/umbra_probe_novo/config
XDG_DATA_HOME=/tmp/umbra_probe_novo/data XDG_CONFIG_HOME=/tmp/umbra_probe_novo/config \
godot --headless --path . --script res://tools/umbra_learning_probe.gd -- \
  --out=/tmp/umbra_probe_novo/primeiro

node tools/umbra_collective_evidence.js \
  /tmp/umbra_probe_novo/primeiro/combat_fixture.json /tmp/umbra_probe_novo/servidor

XDG_DATA_HOME=/tmp/umbra_probe_novo/data XDG_CONFIG_HOME=/tmp/umbra_probe_novo/config \
godot --headless --path . --script res://tools/umbra_learning_probe.gd -- \
  --out=/tmp/umbra_probe_novo/entrega \
  --collective=/tmp/umbra_probe_novo/servidor/collective_layer.json
```

Os exemplos são caminhos de laboratório. Não executar o probe com os saves
pessoais como ambiente de trabalho. O orquestrador Python já isola os dados
de usuário para cada braço automaticamente.

## VPS e checkpoint Python

[`remote/failure.json`](remote/failure.json) registra a falha de DNS na
consulta de leitura ao endpoint público. Nenhuma partida foi submetida.
Não houve confirmação da política publicada ou de sua utilização por clientes.

[`apolo_source_identity.json`](apolo_source_identity.json) identifica o código,
arquitetura e checkpoint Python encontrados. O checkpoint não foi carregado
nem testado; nenhum arquivo do repositório Python foi alterado.

## Integridade, reprodução e limitações

`pilot/` inclui relatório, modelos antes/depois, JSONL bruto de coleta,
avaliação e replay, comandos e logs. `source_manifest.json` identifica commit
e hashes das fontes relevantes. `worktree.patch` preserva as alterações
rastreadas presentes no início; `untracked_sources/` preserva as fontes novas
daquele momento. Aplicar essa fotografia exige o commit indicado e uma cópia
separada do projeto; não aplicar sobre uma árvore com trabalho em andamento.
Assets e dependências do projeto continuam necessários. Não há promessa de
reprodução binária entre plataformas.

[`SHA256SUMS.json`](SHA256SUMS.json) cobre os arquivos de evidência, sem
incluir este README nem o próprio índice. Os hashes descrevem os dados
copiados da execução, não validam a hipótese científica.

Rodadas preliminares `ablation_v1`, `ablation_v2` e `fit_v1` em
`.agent_logs/umbra_evidence` não são a evidência principal desta pasta.
A primeira detectou ausência de combate com tutorial ativo; o coletor
passou a encerrar o tutorial, e o runner passou a recusar episódios sem
tempo simulado/decisões. Durante `fit_v1` ainda havia edição de ferramentas;
o novo runner detecta esse tipo de deriva, e a rodada `fit_v2` foi executada
com as fontes monitoradas estáveis.

Validações adicionais: dez testes adversariais Python, `py_compile`, parse
dos dois GDScripts, sintaxe Node, smoke coletivo existente e smoke do ABI PPO.
`git diff --check` passou. O orçamento arquitetural apresentou as mesmas
falhas preexistentes antes e depois, sem alteração de baseline.

O smoke existente de camadas concluiu 29 checks de contrato. Ele também
tentou abrir uma sessão HTTP de segurança, recusada pelo ambiente; não é
evidência de integração com serviço ao vivo. A tentativa e os resultados
estão em [`validation/`](validation/results.json). O piloto e o probe novos
desabilitam essas requisições e concluíram sem erros nos respectivos logs.
