# Lógica das IAs

Este documento explica como a lógica de inteligência do jogo é pensada. Em Ruptura Temporal existem duas camadas bem diferentes:

1. **IA procedural de gameplay**, usada por inimigos, mini boss, bosses e eventos de fase.
2. **IA experimental APOLO/Umbra**, usada como laboratório técnico com PyTorch/DQN e comportamento adaptativo.

---

## Princípio geral

A IA do jogo não precisa parecer “inteligente” no sentido humano. Ela precisa parecer **intencional**, legível e justa.

Um comportamento bom deve:

- avisar antes de punir;
- ter resposta possível;
- criar decisão, não apenas dano inevitável;
- respeitar o espaço visual;
- combinar com a personalidade da fase.

---

## IA procedural dos inimigos

Grande parte dos inimigos usa regras diretas:

- procurar posição de Geovana;
- calcular distância;
- decidir se persegue, ataca, foge ou mantém distância;
- respeitar cooldowns;
- aplicar estados como stun, invisibilidade, cura, fuga ou ataque.

Esse modelo é preferido para inimigos comuns porque é previsível, barato para desempenho e fácil de balancear.

### Exemplo de decisões comuns

| Situação | Decisão esperada |
| --- | --- |
| Inimigo corpo a corpo longe | Perseguir Geovana. |
| Inimigo corpo a corpo perto | Causar dano com cooldown. |
| Atirador na distância ideal | Parar e disparar. |
| Suporte com aliados feridos | Curar ou fortalecer aliados. |
| Larapio com recurso roubado | Fugir. |
| Larapio sem recurso | Importunar, arremessar pedra ou tentar roubar. |

---

## Direção e movimento

O movimento normalmente parte de um vetor:

```text
direção = posição_do_jogador - posição_do_inimigo
direção_normalizada = direção / distância
```

A partir disso, cada inimigo modifica a regra:

- Espreitador acelera em janelas.
- Projetador prefere distância de tiro.
- Larapio foge depois de roubar.
- Arauto orbita e mantém distância.
- Bosses podem ignorar a lógica simples e executar padrões próprios.

---

## IA do Larapio

O Larapio é uma IA de economia e perturbação.

Ele possui estados aproximados:

- **caçando**: procura jogador, cartas ou chave;
- **preparando ataque**: entra em alcance e ameaça;
- **fugindo**: tenta escapar após roubar;
- **importunando**: quando não roubou nada, usa pedra, stun e aproximações curtas.

Regras importantes:

- não deve causar hit kill;
- deve demorar para voltar depois de eliminado;
- deve virar recompensa se o jogador conseguir pegá-lo;
- se roubar uma chave, deve devolvê-la ao morrer.

Design:

O Larapio é menos “monstro” e mais “problema ambulante”. A graça dele é criar raiva controlada no jogador sem virar injustiça.

---

## IA do Arauto

O Arauto é uma IA de mini boss.

Ele precisa ser mais especial que um inimigo comum, mas sem ocupar o mesmo peso de um boss principal.

### Estados principais

- entrada;
- movimentação orbital;
- disparo de esporos/projéteis;
- preparação do Olhar da Ruptura;
- travamento de mira;
- disparo do raio;
- fase 2 abaixo de 50% de vida;
- morte e drop do fragmento.

### Decisões

O Arauto tenta:

- manter distância útil do jogador;
- orbitar em vez de perseguir reto;
- usar o raio quando a janela permite;
- acelerar a pressão na segunda fase;
- preservar ameaça mesmo com apenas dois inimigos comuns no confronto.

### Por que os Ecos importam

Os dois inimigos comuns do confronto não são simples decoração. Eles:

- reduzem dano recebido pelo Arauto;
- podem bloquear o raio;
- criam uma escolha tática.

Essa é a parte que dá personalidade ao mini boss.

---

## IA de bosses

Bosses usam padrões mais telegrafados. Isso é intencional: quanto maior a ameaça, mais claro deve ser o aviso.

Um boss deve alternar entre:

- janelas de dano;
- janelas de esquiva;
- mudança de fase;
- ataque de área;
- pressão por projéteis;
- reposicionamento ou invocação.

O jogador precisa sentir que perdeu porque leu mal ou executou mal, não porque o jogo decidiu puni-lo sem aviso.

---

## Pressão pós-boss

Algumas fases mantêm pressão ou ajustes depois da morte do boss. Isso evita que a arena fique morta enquanto fragmentos, transição e recompensas acontecem.

Diretriz:

- manter tensão leve;
- não roubar o momento de recompensa;
- evitar spawns caóticos durante coleta obrigatória.

---

## IA experimental APOLO

APOLO é uma camada experimental baseada em PyTorch. Ela existe como pesquisa e protótipo de agente adaptativo.

Componentes principais:

- **Dueling DQN**;
- **Double DQN**;
- **target network**;
- **replay buffer**;
- **gates de sobrevivência**;
- **gates para projéteis e lasers**;
- **neurogênese experimental**, aumentando a rede quando a entropia indica confusão persistente.

Essa camada fica fora do pacote leve de jogador porque adiciona dependências pesadas e não é necessária para a experiência base.

---

## Survival Gates

Os gates são atalhos de segurança que ajustam decisões da rede para evitar escolhas absurdas em situações críticas.

Exemplos:

- vida baixa aumenta prioridade de fugir;
- projétil próximo aumenta prioridade de esquiva perpendicular;
- laser em varredura aumenta prioridade de sair do caminho.

Isso impede que a IA precise “aprender do zero” comportamentos óbvios de sobrevivência.

---

## Umbra

Umbra representa uma camada mais avançada/experimental ligada às fases posteriores. Ela combina:

- dossiês;
- profecias;
- comportamento de boss;
- leitura de manifestação;
- efeitos específicos de fase.

No build leve atual, essa parte é tratada como conteúdo fora do caminho principal de jogador.

---

## Regras para criar novas IAs

Ao criar ou ajustar uma IA, use esta checklist:

- Existe um aviso visual ou sonoro antes da punição?
- O jogador tem pelo menos uma resposta viável?
- A IA tem função diferente das existentes?
- O comportamento combina com a fase?
- O custo de CPU é compatível com muitos inimigos?
- O estado reseta corretamente entre fases?
- Cooldowns e variáveis globais são reiniciados em retry/transição?

---

## O que evitar

Evite IAs que:

- perseguem perfeitamente o jogador sem erro;
- atravessam o mapa sem telegráfico;
- misturam muitos estados invisíveis;
- dependem de aleatoriedade sem limite;
- causam dano letal sem janela de reação;
- exigem reflexo impossível para o FPS alvo.

IA boa em Ruptura Temporal é aquela que parece maliciosa, mas ainda honesta.
