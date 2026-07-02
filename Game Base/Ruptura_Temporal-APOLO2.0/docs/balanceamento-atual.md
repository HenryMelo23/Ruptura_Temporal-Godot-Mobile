# Balanceamento atual

Este documento resume a lógica de balanceamento de **Ruptura Temporal - APOLO 2.0**. O objetivo é explicar por que os números existem e como eles devem ser ajustados sem quebrar a experiência.

O principal arquivo de referência é:

- `Engine/balanceamento.py`

---

## Objetivo do balanceamento

O jogo busca uma curva em que:

- a fase 1 seja receptiva;
- o jogador aprenda antes de ser punido com força;
- builds diferentes sejam viáveis;
- a sorte ajude, mas não decida tudo;
- bosses durem o suficiente para mostrar mecânica;
- o dano explosivo não derreta boss por acidente;
- o desempenho continue estável mesmo com muitos efeitos.

---

## Cartas

As cartas são melhorias de run. Elas ajustam atributos como:

- dano;
- velocidade;
- velocidade de ataque;
- crítico;
- teleporte;
- sorte;
- efeitos especiais como veneno, coleta, mercenária e aliados.

### Dano

A carta de dano aplica ganho percentual e possui escala tardia limitada por abates. A intenção é:

- dar sensação clara de crescimento;
- evitar que muitas compras quebrem boss;
- deixar o dano escalar, mas com teto controlado.

### Velocidade

A carta de velocidade melhora mobilidade, mas não deve tornar a colisão irrelevante.

### Speed Attack

Reduz intervalo entre disparos até um mínimo. Essa trava é essencial para evitar:

- explosão de projéteis;
- queda de FPS;
- multiplicação exagerada de efeitos por segundo.

### Crítico

Crítico existe como pico de dano, não como base obrigatória. Deve ser bom, mas não substituir identidade de manifestação.

### Teleporte

Reduz cooldown do teleporte até um mínimo. O teleporte é defesa, reposicionamento e parte de várias manifestações; por isso não pode chegar a cooldown trivial.

---

## Raridade e sorte

Cartas raras são controladas por:

- chance base;
- chance máxima;
- bônus de Sorte;
- bônus por cartas de Sorte;
- teto de raridade.

Design:

Sorte deve melhorar a sensação de descoberta, mas não transformar raras em padrão. O jogador que investe em Sorte abre possibilidades, mas ainda joga o combate.

---

## Drops de carta

No modo difícil/drops, inimigos podem soltar cartas. O sistema usa:

- chance base inicial;
- chance máxima;
- escala por tempo;
- influência de Sorte;
- assistência no início;
- intervalo de drop garantido.

Por que existe assistência:

Sem proteção, o jogador pode passar muito tempo sem drop e sentir que perdeu por azar. Com assistência, a aleatoriedade continua existindo, mas a run não fica refém dela.

---

## Loja por chave

No modo clássico, a loja depende da chave.

Regras atuais:

- inimigos têm chance baixa de gerar chave;
- existe garantia de geração após tempo sem chave;
- a chave dura tempo limitado no chão;
- ao coletar, a loja abre automaticamente se o jogador tiver pontos suficientes;
- o Larapio pode roubar a chave se o jogador demorar;
- ao matar o Larapio, a chave pode ser recuperada.

Valores centrais atuais:

- chance de chave por inimigo: **2%**;
- garantia: **3 minutos**;
- duração no chão: **15 segundos**.

Design:

A chave cria deslocamento e decisão. O jogador precisa sair da rota segura para garantir acesso à loja, mas não deve depender de uma tecla manual escondida.

---

## Larapio

O Larapio atua como balanceador de economia.

Ele pune:

- acúmulo excessivo de pontos;
- demora para coletar chave;
- negligência com cartas no chão.

Mas também recompensa:

- perseguição bem sucedida;
- foco de alvo;
- recuperação de recursos roubados.

Regras de segurança:

- dano limitado;
- não deve ser fonte de hit kill;
- cooldown de retorno após aparecer;
- devolução de recursos ao morrer.

---

## Dano inimigo

O dano dos inimigos usa multiplicador de tempo para aliviar o início da run.

Intenção:

- começo menos agressivo;
- normalização após alguns minutos;
- fase 1 mais receptiva;
- evitar que um jogador novo morra antes de entender a tela.

---

## Vida e dano de inimigos

O crescimento dos inimigos considera:

- abates;
- tempo;
- fase;
- modo de cartas;
- tipo de inimigo;
- presença de boss;
- pressão pós-boss.

Diretriz:

O aumento de vida deve fazer o jogador sentir que precisa melhorar a build, mas não deve transformar todo inimigo comum em tanque.

---

## Bosses

Bosses usam multiplicadores de vida e armadura por fase.

Elementos atuais:

- vida inicial multiplicada por fase;
- armadura base por fase;
- armadura máxima;
- aumento por minuto;
- aumento por abate;
- interação com Coletora;
- mitigação especial para veneno;
- limite para execução.

Design:

Boss precisa mostrar mecânica. Se morre rápido demais, o conteúdo desaparece; se demora demais, vira parede de vida. A armadura existe para controlar picos e DoTs sem matar a sensação de progresso.

---

## Mini boss Arauto

O Arauto deve ser ameaça intermediária.

Balanceamento esperado:

- aparece aos 8 minutos;
- não divide arena com boss principal;
- limita inimigos comuns durante o confronto;
- possui fase 2 abaixo de 50%;
- deixa fragmento poderoso ao morrer;
- deve punir erro, mas não exigir execução de boss final.

Ponto crítico:

Como ele entrega evolução de manifestação, ele precisa ser perigoso o bastante para a recompensa parecer merecida.

---

## Ultimates

As ultimates possuem cooldown alto. O valor central atual é:

- **75 segundos**.

Intenção:

- começar disponível;
- virar recurso de virada;
- não substituir disparo/habilidade secundária;
- ter efeito visual e mecânico forte;
- ser usada em momentos de risco, boss ou horda crítica.

---

## Regeneração passiva

O jogador possui regeneração passiva baixa:

- cura baseada na vida máxima;
- tick curto;
- só ativa após ficar tempo suficiente sem tomar dano.

Função:

- reduzir frustração depois de sobreviver bem;
- não substituir cartas de cura;
- não permitir tanque passivo durante combate ativo.

---

## Pontos

Pontos escalam com:

- tempo de run;
- tipo de inimigo;
- multiplicador máximo.

Função:

- manter economia viva em runs longas;
- recompensar inimigos especiais;
- sustentar custo de loja sem inflar demais o começo.

---

## Limite de inimigos

O limite pode crescer quando:

- o boss ainda não foi chamado;
- a run passou de certo marco;
- o jogador acumulou abates após esse marco;
- o modo difícil exige pressão mais cedo.

Design:

Aumentar limite é uma das formas mais perigosas de escalar dificuldade, porque afeta desempenho, leitura visual e dano recebido. Deve ser usado com cuidado.

---

## Como ajustar sem quebrar

### Se a fase está fácil demais

Preferir:

- aumentar diversidade de inimigos especiais;
- reduzir intervalo de spawn com cuidado;
- melhorar comportamento de boss;
- aumentar pontos de decisão.

Evitar primeiro:

- dobrar vida de tudo;
- aumentar dano de contato cedo;
- lotar a tela sem ganho de leitura.

### Se a fase está difícil demais

Preferir:

- reduzir dano inicial;
- atrasar inimigos especiais;
- aumentar clareza visual;
- melhorar recompensa de Curater/chaves/cartas;
- reduzir vida de boss sem remover mecânica.

### Se uma manifestação derrete boss

Verificar:

- passiva aplicada muitas vezes por frame;
- ausência de cooldown interno por alvo;
- DoT escalando com vida máxima sem teto;
- interação com crítico;
- multiplicador duplicado entre disparo, passiva e ultimate.

### Se o FPS cai

Verificar:

- criação de Surface por frame;
- smoothscale dentro do loop;
- fontes renderizadas todo frame;
- partículas sem limite;
- projéteis com colisão O(n²);
- efeitos de HUD que redesenham sem cache.

---

## Regra de ouro

Balanceamento bom não é deixar tudo “igual”. É fazer cada escolha parecer injusta de um jeito divertido, mas justa o bastante para o jogador querer tentar de novo.
