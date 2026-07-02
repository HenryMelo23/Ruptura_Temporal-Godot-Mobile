# Ruptura Temporal - APOLO 2.0

**Ruptura Temporal - APOLO 2.0** é um jogo 2D de ação, sobrevivência e progressão sistêmica feito em **Python** com **Pygame-CE**. O jogador controla **Geovana**, uma pesquisadora presa no colapso de linhas temporais, e precisa sobreviver a hordas, chefes, anomalias, manifestações de poder e escolhas de build que mudam a forma de jogar.

O projeto também funciona como laboratório técnico: combina gameplay em tempo real, sistemas de progressão, IA experimental, cooperação em rede local, empacotamento para distribuição e uma camada visual construída para comunicar caos sem perder legibilidade.

> Status atual: versão em desenvolvimento. O pacote leve de jogador foca nas fases 1 a 4; sistemas avançados e fases posteriores podem existir como conteúdo experimental ou de desenvolvimento.

---

## O que é o jogo

Ruptura Temporal é um survival action top-down com foco em:

- combate de arena contra hordas;
- progressão por cartas, auras e manifestações;
- inimigos com funções diferentes dentro da pressão da fase;
- bosses e mini boss com janelas de leitura;
- escolhas de build que não são só “mais dano”, mas mudanças reais de mecânica;
- HUD e efeitos pensados para sustentar muitas informações sem poluir o mapa;
- modo clássico com loja e modo difícil baseado em drops.

A ideia central é simples: **o jogador não deve apenas ficar mais forte; ele deve jogar diferente conforme escolhe sua aura, manifestação e cartas.**

---

## Pilares de design

### 1. Caos legível

O jogo usa muitos efeitos, inimigos, projéteis e informações simultâneas. A regra de design é que a tela pode ser intensa, mas o jogador ainda precisa entender:

- onde está Geovana;
- qual inimigo é prioridade;
- qual habilidade está pronta;
- qual ameaça precisa ser desviada;
- qual recompensa está no chão.

### 2. Identidade de build

Auras e manifestações não são apenas bônus numéricos. Cada uma carrega uma personalidade mecânica:

- **Auras** mudam o comportamento macro do jogador.
- **Manifestações** mudam o ataque, a habilidade secundária, o teleporte, passivas e ultimate.
- **Cartas** ajustam atributos e sustentam escolhas durante a run.

### 3. Sorte com proteção contra frustração

O projeto usa aleatoriedade, mas evita depender apenas dela. Drops, loja, chave da loja, raridade e pressão do Larapio têm regras de assistência ou garantias para manter o fluxo justo.

### 4. Fases como curvas de aprendizado

Cada fase deve ensinar um tipo de tensão:

- fase 1: leitura básica, economia, primeiros inimigos especiais e boss inicial;
- fase 2: inimigos com papéis mais marcados e punição de posicionamento;
- fase 3: pressão ritualística, zonas perigosas e controle de objetivos;
- fase 4: consolidação do caos com exigência maior de leitura.

### 5. IA como camada de comportamento

O projeto possui IA procedural para inimigos e uma camada experimental chamada **APOLO**, baseada em DQN/PyTorch, voltada para estudo de agentes adaptativos. Essa camada não é requisito do pacote leve de jogador.

---

## Loop principal

1. Escolher modo, dificuldade, aura e manifestação.
2. Entrar na fase e sobreviver ao crescimento da horda.
3. Coletar pontos, cartas, chaves e recursos temporais.
4. Usar cartas ou drops para fortalecer a run.
5. Enfrentar mini boss, boss e eventos especiais.
6. Coletar fragmentos para evoluir manifestação ou avançar de fase.
7. Repetir com novas pressões e combinações.

---

## Sistemas principais

### Auras

A aura define a filosofia da run. Exemplos:

- **Racional** recompensa controle de ritmo e teleporte bem usado.
- **Impulsiva** recompensa abates em sequência e agressividade.
- **Devota** transforma erro em defesa e contra-ataque.
- **Voraz** recompensa coleta agressiva e risco.
- **Abissal**, **Nula**, **Profética** e **Sanguinária** adicionam leituras próprias de pressão, alvo, vazio e ferida.

### Manifestações

A manifestação define a forma como Geovana canaliza a Ruptura. As manifestações jogáveis atuais são:

- Elétrica;
- Lacerante;
- Prismática;
- Retornante;
- Parasítica;
- Condutora;
- Gravitante;
- Ancorada.

Cada manifestação pode ter disparo próprio, habilidade secundária, teleporte temático, passiva, evoluções de fragmento e ultimate.

### Cartas e loja

Existem dois fluxos principais:

- **Modo clássico**: o jogador acumula pontos e usa a loja.
- **Modo difícil/drops**: inimigos podem soltar cartas diretamente, sem loja inter-fases.

No fluxo atual da loja, inimigos podem gerar uma **chave da loja**. Ao coletar a chave e ter pontos suficientes, a loja abre automaticamente, sem depender de uma tecla manual.

### Mini boss Arauto

O **Arauto: Condutor de Ecos** surge como ameaça intermediária da fase. Ele aparece aos 8 minutos, controla a arena, limita os inimigos comuns durante o confronto e deixa um **Fragmento da Ruptura** ao morrer. Esse fragmento abre uma seleção especial de evolução da manifestação equipada.

### Ultimate

Cada manifestação possui uma ultimate própria, ativada no slot de habilidade dedicado. A ultimate começa disponível no início da run e depois entra em cooldown alto, para funcionar como recurso decisivo.

---

## Conteúdo documentado

Os guias abaixo detalham os sistemas principais de forma mais útil para desenvolvimento, apresentação e balanceamento:

| Documento | Conteúdo |
| --- | --- |
| [Mecânicas de inimigos por fase](docs/mecanicas-inimigos-fases.md) | Função dos inimigos, pressão por fase, Arauto e Larapio. |
| [Lógica das IAs](docs/logica-ias.md) | IA procedural, comportamento de inimigos, bosses, APOLO e Umbra. |
| [Balanceamento atual](docs/balanceamento-atual.md) | Regras de cartas, drops, boss, dano, pontos, loja e progressão. |
| [Auras, manifestações e cartas](docs/aureas-manifestacoes-cartas.md) | Como os três pilares de build se conectam. |
| [Estrutura do projeto](docs/STRUCTURE.md) | Organização técnica do repositório. |

---

## Controles principais

Os controles podem variar conforme configuração e modo, mas a base atual é:

- **W/A/S/D**: mover;
- **Mouse**: mirar;
- **LMB**: disparo/ataque principal;
- **Left Shift**: teleporte;
- **RMB**: habilidade secundária;
- **E**: ultimate da manifestação;
- **ESC**: pausa/menu;
- **Setas ou W/S**: navegar em menus.

---

## Requisitos

### Pacote completo de desenvolvimento

- Python 3.11+ recomendado;
- Pygame-CE;
- NumPy;
- Requests;
- Pyperclip;
- Python-VLC;
- Flask/Flask-CORS para ferramentas auxiliares;
- Matplotlib para análise/visualizações;
- PyTorch para a camada experimental de IA.

Instalação:

```bash
python -m pip install -r requirements.txt
```

### Pacote leve de jogador

O pacote leve evita dependência de PyTorch e usa:

```bash
python -m pip install -r requirements_player.txt
```

---

## Como rodar em desenvolvimento

Na raiz do projeto:

```bash
python Ruptura_Temporal.py
```

Se o ambiente tiver múltiplas versões de Python, use o executável desejado explicitamente:

```bash
py Ruptura_Temporal.py
```

---

## Como gerar build

O script de build fica em `scripts/build_dist.py`.

Build leve de jogador, com limite de fases 1 a 4 e sem PyTorch:

```bash
python scripts/build_dist.py
```

Build completo, incluindo fase 5 e dependências experimentais:

```bash
python scripts/build_dist.py --include-phase5
```

Observações:

- O build leve injeta limite de runtime para fase 4.
- O script verifica módulos obrigatórios antes de empacotar para evitar executável quebrado em outro PC.
- VLC é opcional para trailer/reprodução de mídia; se o runtime compatível não existir, o jogo segue sem essa reprodução.

---

## Estrutura do projeto

```text
Ruptura_Temporal-APOLO2.0/
├─ Ruptura_Temporal.py        # Entrada principal, menus e fluxo inicial
├─ Fases/                     # GAME.py, GAME2.py, GAME3.py, GAME4.py...
├─ Engine/                    # Variáveis globais, balanceamento, HUD e sistemas compartilhados
├─ Manifestacoes/             # Disparos, habilidades, passivas, evoluções e ultimates
├─ Aureas/                    # Dados e lógica de auras
├─ Boss/                      # Habilidades e efeitos de bosses
├─ Menus/                     # Loja, pausa, game over e telas auxiliares
├─ Rede/                      # Cooperação local e sincronização
├─ Sprites/                   # Arte e sprites
├─ Sounds/                    # Áudio e música
├─ saves/                     # Progresso e configurações locais
├─ docs/                      # Documentação técnica e de design
├─ scripts/                   # Build, validação e automações
└─ tests/                     # Testes e smokes
```

O projeto ainda preserva imports planos em alguns pontos por compatibilidade com o histórico do jogo e com o empacotamento. Por isso, nem todo módulo foi migrado para uma estrutura `src/`.

---

## Modos e configurações

O menu inclui opções de jogabilidade e gráficos, como:

- modo de teleporte fixo ou por alvo do mouse;
- HUD de habilidades inferior, vertical ou dinâmico;
- qualidade gráfica;
- partículas;
- efeitos visuais;
- efeitos de manifestações;
- limite de FPS: 30, 60, 120 ou ilimitado;
- exibição de FPS;
- modo janela ou tela cheia.

---

## Rede e cooperação

O projeto possui suporte a cooperação local/LAN em desenvolvimento. A lógica de rede fica principalmente em `Rede/` e a documentação específica está em:

- [NETCODE_COOP_NOVO.md](docs/NETCODE_COOP_NOVO.md)

---

## IA experimental

A camada **APOLO** usa PyTorch e DQN para experimentos com tomada de decisão. Ela possui:

- Double DQN;
- target network;
- replay buffer;
- gates de sobrevivência;
- avaliação de entropia;
- crescimento de arquitetura em cenário de confusão persistente.

Essa camada é tratada como experimental e não faz parte do pacote leve de jogador.

---

## Para quem este README serve

Este README foi escrito para:

- apresentar o jogo a jogadores e interessados;
- orientar novos colaboradores;
- explicar a intenção de design sem depender apenas do código;
- separar o que é sistema jogável, documentação técnica e camada experimental.

Se você quer entender o jogo como jogador, comece por este arquivo.
Se você quer mexer no balanceamento, leia `docs/balanceamento-atual.md`.
Se você quer criar conteúdo novo, leia `docs/aureas-manifestacoes-cartas.md` e `docs/mecanicas-inimigos-fases.md`.

---

## Licença

Consulte [LICENSE.txt](LICENSE.txt).
