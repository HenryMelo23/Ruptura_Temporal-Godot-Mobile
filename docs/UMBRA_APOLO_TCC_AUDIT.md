# UMBRA e APOLO: auditoria de aprendizado e plano experimental

> Atualização posterior: o simulador e a percepção de pesquisa foram corrigidos
> com contratos novos. Consulte [a implementação e validação v3](UMBRA_SIMULATOR_PERCEPTION_V3.md).
> As lacunas e os resultados abaixo descrevem a fotografia anterior à correção.

Data: 16/11/2026. Escopo: código local, combate solo, provas de contrato e
piloto headless. Nenhum modelo foi promovido para o jogo ou enviado à VPS.

## Conclusão que os dados permitem

Existem mecanismos de adaptação e ajuste de parâmetros. Isso não equivale a
uma demonstração de melhora, evolução conjunta ou comportamento humano.
O resultado científico inicial permanece **inconclusivo**. A existência de
um `.pt`, uma geração maior, uma nova versão remota ou uma barra de
conhecimento não demonstra aprendizado útil.

As evidências compactas desta investigação ficam em
[`research/umbra_2026_11_16/`](research/umbra_2026_11_16/README.md).
Dados sintéticos, combate simulado e observações da VPS são categorias
distintas e precisam continuar identificadas nos relatórios do TCC.

## O que realmente decide e o que realmente aprende

| Caminho | Decisão | Atualização | Limite da afirmação |
| --- | --- | --- | --- |
| Umbra em produção | `_umbra_choose_action`: heurística, pesos legados, DQN se válido, bônus linear; depois controlador de autoridade pode usar a policy multihead | Kit base adapta parâmetros durante a luta; camadas pessoal e coletiva podem influenciar lutas futuras | Uma camada carregada pode ser sobreposta por outra policy; identificar `source` da decisão é necessário |
| Mente linear | `RTUmbraMind.apply`: produto de 12 features pelos pesos de cada uma de 20 ações, bônus limitado a ±2 | Regressão ridge no treino/VPS; atualização pessoal de vieses por ação | Aprendizado estatístico contextual sobre heurísticas, sem gradiente neural no aparelho |
| Memória pessoal | `_update_player_layer`: vantagem média relativa ajusta o bias; incorpora priors de habilidades | No fim de encontro com pelo menos 10 s; dados pessoais decaem | Gravar e recarregar é demonstrável; melhorar combate requer A/B separado |
| Coletiva | `server/umbra_collective.js`: acumula X'X e X'y, faz ridge e produz camada `blend` | Relatório elegível, encontro ≥15 s, ID ainda não ingerido; mínimo de 20 amostras por ação e duas ações aptas para gerar pesos | Nem toda partida gera pesos úteis; confiança depende do volume |
| PPO | GRU multihead: observação → ação → simulador → retorno → atualização em Python | `train_umbra_ppo.py` | A ponte atual não executa o ciclo completo de combate e não cobre o kit atual inteiro |
| Laboratório `umbra_selfplay_core.gd` | Simulador próprio e seletores separados | Umbra atualiza sua memória; sessão visual acumula estatísticas do Apolo | `_choose_apolo_action` não recebe nem consulta `apolo_memory`; as estatísticas exibidas não constituem aprendizado desse seletor |
| Apolo no Godot | `_update_apolo_phase5_exhibition`, perigo geométrico, alvo seguro e mira preditiva | Grid de posições recebe feedback no encontro | Não executa os pesos do DQN Python; não há demonstração de evolução neural entre partidas |
| Apolo Python | `ApoloDQN`: 42 entradas, 9 saídas, gates fixos, replay/treino no `ApoloAgent` | Otimizador e checkpoint `.pt`; crescimento pode reiniciar pesos | Os gates podem explicar boa sobrevivência. A existência do checkpoint não mede sua qualidade |

No ambiente auditado, o log do combate informa que
`assets/weights/umbra_dqn_2_0_actions_23.json` não foi encontrado. Há caminho
de fallback funcional. Isso impede descrever aquele combate como evidência de
inferência DQN carregada. O experimento novo desliga DQN e multihead
explicitamente para isolar a mente linear.

## Ciclo local → VPS → próximas partidas

1. `RTUmbraMind.on_decision` guarda ação, contexto e acumuladores de dano.
2. `track` observa variações de HP; após 3 s, `_flush` produz o retorno
   `10 × fração de dano causado − 30 × fração de dano recebido`.
3. `finish_encounter` fecha as amostras e pode salvar a camada pessoal.
4. `telemetry_system.gd` inclui `umbra_combat` no relatório solo.
5. O servidor normaliza os dados, verifica elegibilidade e acumula a run
   antes de substituir o relatório detalhado pelo resumo do ranking.
6. `/umbra/mind/latest` publica perfis e a camada coletiva; o cliente grava
   os JSONs e `load_layers` os incorpora no carregamento subsequente.

O código suporta esse fluxo. As provas locais reproduzem a ingestão,
persistência, entrega pelo método real do cliente e alteração dos scores
usando **dados sintéticos**, sem rede. A VPS publicada não pôde ser lida nesta
sessão: falha de resolução DNS no terminal e endpoint inacessível pela
ferramenta de pesquisa. Portanto não sabemos quantos combates reais foram
ingeridos, quais coeficientes estão publicados, nem se os aparelhos os usam.

### Falsos positivos concretos

- `buildUmbraMind` inclui janela de tempo e contadores na versão do pacote.
  A versão pode mudar sem alteração relevante da política.
- `buildFromState` deriva `collective_version` de contadores/último ID. O
  teste offline produz duas versões diferentes com os mesmos parâmetros.
- `trained_runs`, amostras e porcentagem de conhecimento medem volume ou
  cobertura; não são uma pontuação de competência.
- `_apply_umbra_mind_payload` pode atualizar o status mesmo se uma abertura
  de arquivo falhar. O status de UI não substitui confirmação do arquivo,
  carregamento e efeito causal. Não foi feita injeção de falha de disco.
- O retorno de uma janela sobreposta de 3 s também pode incluir dano de
  outras ações. O ajuste é associativo; não demonstra causalidade isolada de
  cada habilidade nem otimização de toda a luta.
- Mudança de coeficientes pode piorar a policy. Só contagem ou hash não
  distingue aprendizagem útil de deriva.

## Cegueira: o que foi observado

O probe gera os payloads reais das habilidades e consulta o perigo utilizado
pelo bot do Godot. Houve sinal para plasma, Sifão, Vórtice, Sopro Ártico,
Miasma, Descarga, Espinhos, Laser, Ratos e Eco. Rebobinar usa um gate próprio
de fuga. Isso demonstra presença de sinal, sem demonstrar que o bot reage a
tempo, escolhe uma rota transitável ou dispõe só de informação perceptível
para uma pessoa. O probe usa estado interno do simulador.

Há lacunas verificadas no caminho neural atual:

| Lacuna | Evidência | Consequência |
| --- | --- | --- |
| Eco e Rebobinar ausentes nas 23 ações | `RTUmbraObservationSchema.ACTIONS` e probe | A policy multihead não pode escolher essas habilidades pelo contrato atual |
| `PRISAO` agora gera `sopro_artico` | Spawn real confrontado com `space.hazard.prison` | O indicador permanece desligado: −1 no vetor normalizado significa ausência |
| Dimensão base e Vórtice colidem | `_dimension_value` e probe: ambas dão −1 normalizado | A observação não distingue diretamente esses estados |
| Posições limitadas a 2000 em arena maior | `POSITION_LIMIT` e tamanho real do mapa | Valores além do limite saturam; extensão e gravidade precisam de fixtures específicas |
| Parte das features recentes não é alimentada | `build_from_runtime` fixa/omite campos de dano e histórico | O tamanho 83 não significa 83 sinais informativos; falta rastrear cada campo |
| Rollout PPO só atualiza o boss | Probe: plasma não se move em `_update_boss_phase5`, move em `_update_enemy_bullets` | Ataque comum e resposta ofensiva não são simulados como no jogo completo |

Essas lacunas ficaram **documentadas e reproduzidas**, sem mudança silenciosa
do ABI, pesos ou balanceamento em produção. Um schema novo precisa de versão,
adaptador e novo artefato validado. O protocolo antigo permanece como referência.

### Condição para treinar Apolo sem punição cega

Antes de medir aprendizado, cada fonte de dano precisa de um caso que prove:
ameaça nasce → observação muda antes do impacto → ação evasiva é possível →
ação modifica o resultado → dano carrega o ID da ameaça que o causou.

Registrar por transição: tick de simulação, observação anterior/posterior,
ações pedida/aplicada, motivo de recusa, máscara legal, policy/checkpoint,
latência de reação, dano/cura separados, fonte/ID do dano, telegráfo,
tempo até ativação, centro/raio/segmentos/velocidade e término da ameaça.
Uma habilidade nova precisa falhar no teste de cobertura se não houver
encoder para ela. Falta de sinal deve resultar em `unknown_threat`, nunca
em uma observação de arena segura.

Separar um modo com informação completa para depuração de outro com sinais
perceptíveis para avaliação. Gates geométricos devem ter ablações: gates
sozinhos, rede sozinha e combinação. Punição exponencial não corrige uma
observação incompleta e pode fazer a rede aprender correlações espúrias.

## Estrutura headless executável entregue

| Arquivo | Função |
| --- | --- |
| `tools/umbra_mind_collect.gd` | Combate solo real via `_process`, bot existente, artefato externo validado, hash carregado, ações e dano por episódio; encerra tutorial no laboratório |
| `tools/umbra_mind_fit.py` | Ridge; rejeita ajuste sem duas ações suficientemente amostradas |
| `tools/umbra_learning_audit.py` | Congela artefatos/fontes, isola saves, coleta, ajusta opcionalmente, avalia antes/depois e repete as mesmas seeds; também inspeciona snapshot remoto |
| `tools/umbra_learning_probe.gd` | Contraprovas de percepção/ponte PPO e causalidade sintética da memória pessoal e entrega coletiva |
| `tools/umbra_collective_evidence.js` | Ingestão/reload/deduplicação offline e contraprova de versão sem mudança de parâmetros |
| `tools/umbra_learning_audit_smoke.py` | Rejeita falsos positivos por metadados, corrupção, amostras ausentes e treino insuficiente |

Treinar uma cópia e avaliar contra a mesma mente antes do ajuste:

```bash
python3 tools/umbra_learning_audit.py experiment \
  --train-episodes 64 --episodes 32 --seconds 90 --seed 271 \
  --out .agent_logs/umbra_evidence/novo_experimento
```

`NumPy` é necessário para o fit existente. Não há PyTorch nesse caminho.
Python/PyTorch continua sendo ferramenta de desenvolvimento quando se usar
o PPO; não deve entrar na exportação do jogo. Os episódios são simulados no
Godot, preservando a física e as regras daquele build.

A ablação `--zero-baseline` compara ausência da mente linear com o
artefato, incluindo sua antecipação de mira. Não isola o ganho causado pelo
novo treino; para isso use a comparação padrão antes/depois. O adversário
usa o mesmo código e parâmetros entre braços, mas ainda adapta seu grid
dentro de cada encontro. RNG de combate pode ser consumido de forma
diferente por políticas diferentes; seeds iguais não implicam trajetórias
iguais. O replay exige igualdade dos resumos, não de todos os estados.

O runner salva manifesto, hashes de arquivos, patch local, fontes novas,
comandos, stdout/stderr, JSONL de decisões e episódios, modelos antes/depois
e relatório. Recusa pasta já existente, batches incompletos, simulação sem
decisões e hashes carregados diferentes. Detecta mudança de fontes e
artefato durante a rodada. Nunca publica um candidato automaticamente.
O intervalo bootstrap é exploratório; 30 pares é apenas um piso operacional,
não garantia de poder estatístico. O relatório nunca define aprendizado
como provado automaticamente.

Inspecionar a publicação, sem enviar partidas:

```bash
python3 tools/umbra_learning_audit.py inspect-remote \
  --out .agent_logs/umbra_evidence/snapshot_vps_01

python3 tools/umbra_learning_audit.py inspect-remote \
  --snapshot resposta_vps.json --previous resposta_vps_anterior.json \
  --out .agent_logs/umbra_evidence/comparacao_snapshots
```

Snapshot fornecido localmente verifica contrato/parametrização, sem afirmar
que o endpoint foi acessado ao vivo. Um erro de rede produz `failure.json`,
sem preencher a conclusão com um modelo local substituto.

## Como aproveitar a mente do Apolo Python

Origem examinada: `/home/hermes/Documentos/GitHub/Ruptura_Temporal-APOLO2.0`.
Há `saves/apolo_memoria_dqn.pt` de 2.214.159 bytes e arquitetura declarada
hidden=512, versão=5. O checkpoint não foi desserializado nem executado.
Os hashes de identificação constam no registro de evidências.

Não é suficiente copiar o `.pt`. O adaptador precisa preservar significado,
ordem, normalização das 42 entradas, nove ações, cooldown do dash e direção
das diagonais. É necessário reconstruir os gates que fazem parte do
`forward`. Adicionar Eco/Rebobinar ou mudar dimensões das features exige
versionamento e fine-tuning; zeros no lugar de ameaças desconhecidas criam
cegueira. Congelar arquitetura e desativar crescimento/reset e exploração
durante avaliação evita perder o checkpoint ou medir aprendizado acidental.

Depois da equivalência Python/Godot em fixtures, o Apolo pode começar como
baseline congelada, ser destilado para formato leve ou continuar em Python
no laboratório. O simulador continua no Godot; o processo Python recebe
observações e devolve comandos via protocolo versionado. A escolha depende
do custo medido da ponte, não de reimplementar a física em outro motor.

## Sequência de pesquisa e critérios de avanço

1. **Ambiente:** corrigir ponte PPO e cobrir encoder/ações das habilidades
   atuais; provar dano nos dois sentidos, movimento, colisão, cooldowns,
   recusa de ação ilegal e progressão real do relógio. Registrar fontes de
   dano/cura e distinguir término de truncamento.
2. **Apolo inicial:** executar o checkpoint com contrato validado; avaliar
   gates/rede separadamente e fazer a matriz de percepção antes de treinar.
3. **Aprendizado individual:** treinar Apolo contra Umbra congelada;
   congelar Apolo e treinar Umbra. Preservar checkpoints e comparação com o
   adversário original. Ainda sem alegar evolução conjunta.
4. **Treinamento alternado:** manter população de adversários antigos e
   alternar qual lado atualiza. Avaliação usa pool fixo separado; os dois
   lados não devem redefinir a régua de sucesso um do outro.
5. **TCC:** repetir treinos independentes; cruzar A0×U0, A1×U0, A0×U1,
   A1×U1 e checkpoints antigos. Separar seeds/builds/manifestações usados
   para treinar, validar e testar. Não ajustar a policy após olhar o teste.

Pré-registrar métricas e efeito mínimo antes de rodadas confirmatórias.
Medir vitória/derrota/timeout, sobrevivência, dano causado/recebido, cura,
ações ilegais/rejeitadas, variedade/repetição e desempenho por ameaça.
Recompensa modela um objetivo e não é uma medida suficiente de inteligência.
Stall, cura infinita, leitura de estado oculto e exploração de bugs precisam
de cenários próprios. Manter HP, dano, velocidade, telegráfos e cooldowns
fixos entre modelos comparados.

Semelhança com uma pessoa exige avaliação humana cega e comparação com
trajetórias humanas autorizadas. Self-play sozinho não demonstra isso.
Aprender contra jogadores requer separar adaptação na run, persistência
entre runs e agregado coletivo; comparar antes/depois com adversários fixos
e controlar o progresso do próprio jogador. Para a VPS, guardar IDs aceitos,
rejeitados, volume por ação, hash anterior/novo de parâmetros, artefato
entregue, hash efetivamente carregado e decisão produzida.

Para pesquisa confirmatória, uma sugestão inicial é cinco seeds de treino
independentes e pelo menos 30 pares por condição/seed, com tamanho final
decidido pela variância do piloto. Relatar incerteza entre treinos, não
apenas entre episódios de um único treino. Resultados negativos e ausência
de melhora continuam sendo conclusões válidas.

## Referências de método

- Henderson et al., *Deep Reinforcement Learning that Matters*, AAAI 2018:
  [arXiv:1709.06560](https://arxiv.org/abs/1709.06560). Motiva controles,
  variância, múltiplas execuções e relato reproduzível.
- Baker et al., *Emergent Tool Use From Multi-Agent Autocurricula*, ICLR
  2020: [arXiv:1909.07528](https://arxiv.org/abs/1909.07528). Demonstra que
  competição pode produzir estratégias e contraestratégias naquele
  ambiente. Não garante o mesmo resultado no Ruptura; aqui isso permanece
  uma hipótese a testar.

## Validação e caminhos ainda não exercitados

Executados: parse dos dois scripts GDScript de ferramentas, dez testes Python,
compilação Python, sintaxe Node, smoke coletivo existente, probe de percepção
e persistência/entrega sintética, piloto real de coleta/fit/A-B/replay e
smoke do ABI PPO. O ABI PPO passar não demonstra combate completo.
O smoke existente de camadas concluiu 29 checks, com tentativa HTTP de
segurança recusada pelo ambiente; isso não valida um serviço ao vivo.

O orçamento arquitetural já falhava antes desta tarefa em arquivos de loja,
inimigos, ambiente, fluxo de fase e progressão. A investigação não altera
esses owners nem atualiza o baseline. Alterações preexistentes foram preservadas.

Não exercitados: treino neural de Apolo/PPO válido para o kit atual,
coevolução, treino com dados humanos, eficácia da publicação real na VPS,
Android, multiplayer ou teste físico em dispositivos. Esta etapa muda
ferramentas e documentação, sem modificar contratos multiplayer de gameplay.
