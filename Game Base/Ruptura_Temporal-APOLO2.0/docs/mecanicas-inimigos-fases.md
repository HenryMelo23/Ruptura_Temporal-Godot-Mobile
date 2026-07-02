# Mecânicas de inimigos por fase

Este documento descreve a intenção de design dos inimigos de **Ruptura Temporal - APOLO 2.0** e como eles constroem pressão ao longo das fases. Ele não substitui o código das fases, mas serve como mapa de leitura para entender o papel de cada ameaça.

---

## Filosofia dos inimigos

Os inimigos não devem existir apenas como “vida andando até o jogador”. Cada tipo precisa cumprir ao menos uma função:

- **pressão direta**: obriga movimento constante;
- **quebra de conforto**: impede o jogador de ficar parado no ponto ideal;
- **prioridade visual**: cria alvo que precisa ser resolvido primeiro;
- **controle de área**: muda onde é seguro ficar;
- **economia/risco**: ameaça recursos, cartas ou pontos;
- **preparação para boss**: ensina leitura que será exigida depois.

O objetivo é que a horda pareça viva, mas ainda seja legível.

---

## Fase 1 - Primeiro Rasgo

A fase 1 é a porta de entrada. Ela deve ser receptiva, mas não passiva. O jogador aprende movimento, mira, coleta, loja, teleporte, inimigos especiais e o primeiro boss.

### Errante Temporal

Inimigo base. Persegue Geovana de forma direta e serve como unidade de comparação para vida, velocidade e dano.

Função:

- ensinar kite;
- preencher a horda;
- criar risco de contato.

### Aglomerador

Inimigo maior e mais resistente. A função é impedir que o jogador resolva tudo apenas com tiros dispersos.

Comportamentos principais:

- vida superior ao inimigo comum;
- presença visual maior;
- pode se dividir ou surgir por fusão de inimigos comuns;
- recompensa o jogador que controla agrupamentos.

Função de design:

- criar alvo resistente;
- punir ignorar grupos compactos;
- ensinar foco de alvo.

### Espreitador

Inimigo de pressão psicológica. Fica difícil de ler à distância e cria ameaça de aproximação.

Comportamentos principais:

- invisibilidade ou baixa opacidade quando longe;
- arranque temporário;
- ameaça o jogador que olha só para o centro da tela.

Função de design:

- quebrar conforto visual;
- impedir rota automática;
- ensinar atenção periférica.

### Cristalizador

Suporte defensivo. O problema não é o dano direto dele, mas a proteção que entrega aos outros.

Comportamentos principais:

- reduz dano recebido por aliados próximos;
- cria prioridade clara de abate;
- não deve existir em excesso ao mesmo tempo.

Função de design:

- ensinar target priority;
- punir dano espalhado sem leitura;
- transformar posição da horda em problema.

### Projetador

Inimigo de pressão à distância. Ele força movimento lateral e antecipa padrões de boss.

Comportamentos principais:

- atira projéteis;
- ameaça rotas previsíveis;
- cria zonas temporariamente inseguras.

Função de design:

- introduzir desvio de projéteis;
- quebrar o domínio do jogador que só corre em círculo;
- criar leitura de linha de tiro.

### Curater

Suporte de cura. Ele torna a horda mais resistente se for ignorado.

Comportamentos principais:

- cura aliados feridos;
- possui resistência própria;
- ao morrer, pode recompensar o jogador com cura.

Função de design:

- transformar cura inimiga em objetivo;
- criar decisão entre sobreviver e focar suporte;
- recompensar abate estratégico.

### Larapio

Anomalia econômica. O Larapio existe para incomodar o jogador quando ele acumula pontos ou ignora recursos importantes.

Comportamentos principais:

- aparece depois de uma janela mínima de tempo;
- tenta roubar pontos, cartas ou chave da loja;
- foge depois de conseguir roubar;
- pode arremessar pedras e aplicar stun;
- seus ataques são limitados para não causar hit kill;
- ao morrer, devolve chave e recursos roubados, além de pontos extras.

Função de design:

- impedir acumular economia sem risco;
- criar perseguição curta e memorável;
- transformar ganância em tensão.

---

## Mini boss - Arauto: Condutor de Ecos

O Arauto é uma ameaça intermediária, mais perigosa que um inimigo comum e menos decisiva que um boss principal.

### Gatilho

O Arauto surge uma vez aos **8 minutos**, desde que a luta contra boss principal não esteja ocupando a arena.

### Controle da arena

Durante o confronto:

- a onda atual é estabilizada;
- apenas dois inimigos comuns acompanham o mini boss;
- novos spawns comuns são segurados;
- o jogador precisa ler o mini boss sem virar uma luta de boss completa.

### Ecos

Os dois inimigos comuns funcionam como **Ecos**:

- reduzem o dano recebido pelo Arauto;
- podem servir de cobertura contra o raio;
- não são repostos quando morrem.

Decisão criada:

- matar os Ecos cedo remove proteção do Arauto;
- preservar os Ecos pode salvar o jogador do Olhar da Ruptura.

### Olhar da Ruptura

Ataque principal do Arauto:

- mira o jogador durante a carga;
- trava a direção antes de disparar;
- exige leitura de aviso visual;
- pode ser bloqueado por Eco posicionado no caminho.

### Segunda fase

Abaixo de 50% da vida, o Arauto:

- acelera;
- dispara com mais frequência;
- reduz janelas de reação;
- exige melhor posicionamento.

### Recompensa

Ao morrer, o Arauto deixa um **Fragmento da Ruptura**. Ao coletar:

- inimigos próximos são empurrados/desacelerados;
- a run pausa para escolha;
- o jogador vê 3 opções aleatórias dentre 9 evoluções da manifestação equipada.

Essas evoluções devem alterar mecânicas da manifestação, não apenas dano bruto.

---

## Boss 1 - Caranguejo do Nulo

O primeiro boss testa o aprendizado da fase 1:

- movimentação sob pressão;
- leitura de contato;
- desvio de área;
- manutenção de dano;
- coleta do fragmento temporal após a vitória.

Ele escala com a progressão da fase e serve como ponte para a fase 2.

---

## Fase 2 - Pressão de variantes

A fase 2 amplia a leitura da horda. Ela introduz inimigos que não apenas perseguem, mas mudam o tipo de ameaça.

### Inimigo comum

Continua sendo a base da pressão, agora com atributos mais altos e maior exigência de movimento.

### Atirador

Focado em projéteis.

Função:

- criar ameaça fora do corpo a corpo;
- forçar troca de rota;
- punir jogador parado.

### Kamikaze

Inimigo de colisão explosiva/alta pressão.

Função:

- impedir aproximação descuidada;
- criar urgência de eliminação;
- ensinar leitura de distância.

### Boss 2

O boss da fase 2 deve consolidar a ideia de arena mais perigosa: projéteis, padrões e punição de posicionamento.

---

## Fase 3 - Ritual, veneno e controle

A fase 3 traz inimigos com identidade mais marcada. A pressão deixa de ser apenas “quantos inimigos existem” e passa a envolver zonas, rituais e efeitos persistentes.

### Devoto Febril

Inimigo agressivo ligado ao tema ritualístico da fase.

Função:

- compor massa de perseguição;
- alimentar pressão de fé/ritual;
- criar ameaça constante em torno dos objetivos do boss.

### Incensário

Inimigo ligado a fumaça, miasma ou dano tóxico.

Função:

- criar área perigosa;
- punir permanência;
- obrigar reposicionamento.

### Guardião de Sucata

Inimigo mais resistente, com função de travar espaço e proteger a pressão do ritual.

Função:

- segurar o jogador;
- dar peso físico à horda;
- abrir janela para ameaças de área.

### Pai-Rato

Boss da fase 3. Trabalha com rituais, queijos sagrados, padrões telegrafados e pressão crescente. A luta exige leitura de objetivos temporários, não apenas dano no boss.

---

## Fase 4 - Consolidação do caos

A fase 4 é pensada como uma etapa de domínio. O jogador já conhece a lógica básica de:

- horda;
- suporte;
- projéteis;
- zonas;
- boss;
- build;
- economia.

Por isso, a fase 4 pode misturar mais pressões simultâneas, desde que mantenha avisos claros.

Diretrizes:

- menos inimigos “novos por novidade”;
- mais combinações perigosas;
- aumento gradual de vida, dano e limite;
- boss com punição maior para erro repetido;
- preservar espaço visual suficiente para que o jogador não perca Geovana.

---

## Escalonamento de inimigos

O escalonamento atual considera:

- tempo de run;
- inimigos eliminados;
- modo de cartas;
- tipo de inimigo;
- presença ou não de boss;
- pressão pós-boss;
- dificuldade escolhida.

Em termos de design, a fase deve ficar mais tensa por três caminhos:

1. mais inimigos;
2. inimigos mais resistentes;
3. mais papéis especiais aparecendo juntos.

O cuidado é evitar que os três picos aconteçam ao mesmo tempo cedo demais.

---

## Regras de bom inimigo

Um inimigo novo só deve entrar se responder “sim” para pelo menos uma pergunta:

- Ele muda a forma do jogador se mover?
- Ele muda a ordem de prioridade dos alvos?
- Ele muda a forma de usar teleporte?
- Ele combina com alguma aura ou manifestação de modo interessante?
- Ele prepara o jogador para uma mecânica de boss?
- Ele melhora a leitura da fase em vez de apenas aumentar números?

Se a resposta for “não”, provavelmente é só mais um corpo na tela.
