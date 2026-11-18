# Correção do simulador e da percepção — 16/11/2026

Esta etapa corrige o ambiente de pesquisa identificado na
[auditoria](UMBRA_APOLO_TCC_AUDIT.md). Não treina nem promove uma nova policy
de produção. Os dados históricos do piloto permanecem preservados.

## Contratos e compatibilidade

| Contrato | Produção existente | Pesquisa corrigida |
| --- | --- | --- |
| Observação | v2, 83 entradas | v3, 90 entradas |
| Ações | v2, 23 saídas | v3, 25 saídas, incluindo Eco/Rebobinar |
| Modelo | `umbra_2_0_multihead_gru` | `umbra_3_0_research_gru` |
| Protocolo de rollout | v1 antigo, retirado do runner ativo | v2 |
| Currículo/recompensa | v1 histórico preservado | v2 |

`RTUmbraMultiheadPolicy.create(model)` e `contract_error(model)` mantêm o
contrato de produção. A pesquisa exige **opt-in explícito**:
`create(model, 3)`. O carregador padrão rejeita o modelo novo. Checkpoints
antigos não podem ser retomados como se tivessem o mesmo espaço de estados.
O builder v3 recusa runtime multiplayer; nenhuma sessão online foi testada.

## Simulação

`tools/umbra_rl_scene.tscn` usa o runtime principal por herança em
`tools/umbra_rl_runtime.gd`. O adaptador troca a escolha da Umbra por um
comando externo e permite um oponente programado ou o bot heurístico.
O movimento passa pelo controle normal do jogador; nenhuma posição é
alterada diretamente por passo de treinamento para simular uma esquiva.

O rollout executa `_process` em ticks fixos de 1/60 s. Assim, o fluxo real
processa movimento, colisões, disparos do jogador, projéteis, habilidades,
telegráfos, dano, cura e cooldowns. A execução de ações da Umbra ocorre no
ponto normal de decisão do boss, com sua cadência; pedidos não geram um
disparo a cada tick. Máscaras incluem espera quando a cadência impede ação.
Uma ação de outra dimensão é recusada, em vez de virar um ataque oculto.

Pedidos espaciais explícitos são instalados na decisão que o executor
normal consome. O teste verifica o Miasma nas coordenadas solicitadas.
O alvo permanece o único jogador solo. O treino PPO continua otimizando
ação e valor; a cabeça espacial só participa com
`use_spatial_head=true` em um experimento explícito. Por padrão, o ponto
espacial é a posição atual do jogador, evitando usar uma cabeça não treinada.

As builds agora aplicam as cartas pelo método real `_apply_card`, antes
da simulação. Nomes antigos sem definição foram substituídos em um currículo
novo, com o mapeamento registrado em `legacy_card_replacements`. Não se
comparam diretamente seus resultados aos do currículo v1. Carta desconhecida
faz o setup falhar, em vez de ficar apenas em um contador.

## Percepção

`build_training` mantém a observação v2 intacta e cria o contrato v3:

- posições absolutas/relativas escaladas pelo tamanho real do mapa;
- oito dimensões com valores distintos;
- Sopro Ártico reconhecido pelo indicador de prisão;
- cooldowns, marca/âncora/tempo de Rebobinar e posição/tempo dos Ecos;
- velocidade observada do jogador, cópias de cartas e atividade de ataque;
- dano recente e repetição alimentados por eventos medidos;
- remoção de quatro campos v2 sem fonte medida nesse ambiente;
- validação de versão, ordem, tamanho e valores finitos.

`tools/apolo_observation.gd` fornece um envelope estruturado: projéteis e
velocidades, áreas e geometrias, lanças, segmentos, laser/fases, ratos,
teleportes reais/fintas, Eco, Rebobinar, orbes e estados de queimadura,
congelamento e invulnerabilidade. Ameaça sem encoder gera
`unknown_threat_count > 0`; o rollout falha antes de entregar experiência
ao treinador. Essa informação vem do **estado interno completo**, marcada
como `oracle_state_not_human_visibility`. Não é prova de percepção humana
nem um adaptador já compatível com o DQN Python de 42 entradas.

## Registro e recompensa

Cada transição inclui observação anterior/posterior, máscara, comando
pedido/validado, comandos realmente executados, ticks, relógio, posições,
percepção do Apolo e eventos de dano com fonte e destinatário. IDs de
instâncias causadoras ainda são `null`, identificados como
`source_only_instance_unresolved`; o simulador não inventa atribuição causal.
Os eventos medem redução de HP após a execução real, incluindo os bloqueios
do jogo. Não são uma auditoria de todo dano bruto antes de escudos/cura.

`terminated` identifica morte/fim real; `truncated` identifica limite de
tempo. O treinador usa valor do próximo estado no truncamento e zero na
terminação. A função de retorno descontado tem teste numérico sem PyTorch.
Espera obrigatória por cooldown e início de efeitos atrasados não são
punidos como repetição ineficaz. A recompensa continua sendo uma escolha
de projeto, não uma medida suficiente de inteligência.

O runner rejeita pausas inesperadas, relógio que não avança, inferência
inválida, protocolo antigo e ameaças desconhecidas. No Linux validado,
o ambiente de usuário dos rollouts Python é isolado por processo via XDG;
esse isolamento em outros sistemas ainda precisa de validação. O adaptador não abre sessão de
ranking, não envia relatórios e não consulta modelos/atualizações remotas.

## Validação reproduzível

```bash
# Combate, percepção, contratos v2/v3 e efeito espacial real.
mkdir -p /tmp/umbra_env/data /tmp/umbra_env/config
XDG_DATA_HOME=/tmp/umbra_env/data XDG_CONFIG_HOME=/tmp/umbra_env/config \
godot --headless --path . --script res://tests/umbra_training_environment_smoke.gd \
  -- --out=/tmp/umbra_env/result.json

# Transições completas idênticas com a mesma seed e dano nos dois sentidos.
python3 tools/umbra_rl_protocol_smoke.py --out /tmp/umbra_protocolo_novo

# Currículo separado, limites de recompensa, espera e retorno truncado.
python3 tools/umbra_rl_curriculum_smoke.py --out /tmp/umbra_curriculo_novo
```

Os resultados e logs desta correção ficam em
[`research/umbra_simulator_2026_11_16/`](research/umbra_simulator_2026_11_16/README.md).
As fixtures neurais usadas para validar o contrato são artificiais, sem
alegação de inteligência treinada. A regressão dos modelos v2 foi verificada
por testes existentes de schema, inferência e paridade determinística.

PyTorch não está instalado nesta sessão; nenhum gradiente PPO foi executado.
O próximo treino requer o ambiente de desenvolvimento com essa dependência.
Não foram validados checkpoint Python do Apolo, integração VPS, informação
limitada ao visível, atribuição por instância de ameaça, Android ou multiplayer.

O validador profundo foi iniciado e parou na importação: o editor tentou
abrir sockets TCP, bloqueados pelo ambiente. Isso não é um resultado verde
de validação profunda. Os parses focados, combates e scene smoke são
reportados separadamente. O orçamento arquitetural também já tinha falhas
preexistentes; o baseline não foi atualizado.

A anotação que deveria ser acrescentada ao backlog protegido está em
[pendências multiplayer desta etapa](UMBRA_MULTIPLAYER_DEFERRED_SIMULATOR_V3.md).
