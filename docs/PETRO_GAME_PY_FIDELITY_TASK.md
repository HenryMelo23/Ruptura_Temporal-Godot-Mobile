# Petro mobile - analise fiel do GAME.py

## Fonte de verdade

Esta tarefa usa somente o fluxo executado em `Game Base/Ruptura_Temporal-APOLO2.0/Fases/GAME.py`, com os valores iniciais e sprites referenciados por ele. A tela de cartas serve apenas para identificar o efeito da coleta.

## O que Petro realmente e

Petro e uma unidade autonoma corpo a corpo. Ele nao orbita Geovana, nao a segue quando esta sem alvo e nao dispara projeteis. Ao ser invocado, permanece no mundo, procura o inimigo comum mais proximo e caminha diretamente ate ele. Dentro de 50 px, Petro e o inimigo trocam dano uma vez por segundo.

Quando o boss esta ativo, Petro tambem caminha diretamente ate o boss e usa uma regra de combate separada. Sua posicao, vida, resistencia, dano, nivel visual e progresso de evolucao fazem parte do estado persistente entre fases.

## Fluxo observado no GAME.py

1. A carta define `Petro_active = true` e adiciona `+5` ao dano proprio de Petro.
2. Cada compra cura Petro em `58%` da vida maxima, sem ultrapassar o limite.
3. `petro_evolucao` comeca em `1` e avanca `+4` nas faixas dos niveis 1 e 2.
4. Faixa `1..8`: usa sprites de nivel 1.
5. Faixa `9..16`: usa sprites de nivel 2 e recebe `+1400` de vida maxima por compra nessa faixa.
6. Acima de `16`: usa sprites de nivel 3 e recebe `+2800` de vida maxima, `+24` de resistencia e `+360` de dano por compra.
7. Durante a fase, escolhe sempre o inimigo comum mais proximo da posicao atual de Petro.
8. Petro caminha ate o alvo; a direcao visual e recalculada periodicamente a partir da posicao relativa.
9. Dentro de `50 px`, a cada `1000 ms`, Petro sofre `max(0, dano_inimigo - resistencia_petro)`.
10. No mesmo tick, o inimigo sofre `int(dano_jogador * 0.005) + dano_petro`.
11. Se Petro matar o inimigo, o abate entra no fluxo normal, concede pontos e melhora permanentemente `+0.08` resistencia, `+0.25` vida maxima e `+0.008` dano de Petro; o dano do jogador tambem recebe `+0.05`.
12. Contra o boss, Petro caminha ate `50 px`, sofre o dano de contato do boss e recupera parte da vida perdida usando o roubo de vida do jogador.
13. Contra o boss, causa `int(dano_jogador * 0.15) + 15`, passando pela mitigacao normal do boss.
14. Ao ficar sem vida, Petro e desativado. Uma nova carta pode invoca-lo novamente e aplicar a cura da compra.
15. O desenho usa barra de vida, sombra e o conjunto de sprites correspondente ao nivel atual.

## Defeitos do desktop que nao devem ser copiados

- A direcao de movimento retorna apenas `-1` ou `1` por eixo. No mobile, o vetor deve ser normalizado para nao acelerar na diagonal.
- A tentativa de cura ao Geovana acertar um inimigo testa `vida_petro > vida_maxima_petro`; essa condicao e invertida e nao produz a cura esperada. Nao criar uma cura por acerto sem uma regra confirmada.
- Ao morrer, o desktop soma a vida maxima ao valor negativo e transforma o resultado em nova vida maxima. No mobile, apenas desativar Petro e preservar seus atributos persistentes.
- Quando nao existe inimigo nem boss, o desktop nao manda Petro retornar ao jogador. O mobile deve manter Petro parado na ultima posicao, usando animacao `stop`.
- Com o boss ativo, o desktop executa no mesmo frame o bloco do inimigo comum e depois o bloco do boss, produzindo duas ordens de movimento concorrentes. No mobile, transformar essa sobreposicao em uma regra deterministica: boss ativo tem prioridade.

## Logica proposta para o mobile

```text
AO COLETAR PETRO:
    incrementar quantidade de cartas
    ativar Petro
    aumentar dano proprio em 5
    aplicar faixa de evolucao usando petro_evolucao
    aplicar bonus da faixa atual
    curar 58% da vida maxima

A CADA FRAME:
    se Petro estiver inativo: encerrar
    se boss estiver ativo: alvo = boss
    senao: alvo = inimigo comum mais proximo da posicao de Petro
    se nao existir alvo: ficar parado na ultima posicao
    senao:
        atualizar direcao visual pelo vetor ate o alvo
        caminhar com vetor normalizado ate ficar a 50 px
        se estiver a 50 px e o cooldown de 1 segundo terminou:
            aplicar dano recebido em Petro
            aplicar dano corpo a corpo no alvo
            processar morte e progressao se Petro matou
    se vida de Petro <= 0:
        desativar Petro
        preservar vida maxima, resistencia, dano e evolucao

AO DESENHAR:
    escolher sprites pelo nivel 1, 2 ou 3
    escolher frame por direcao e tempo de animacao
    desenhar sombra pela silhueta
    desenhar sprite ancorada pelos pes
    desenhar barra de vida acima da sprite
```

## Texto de aplicacao

> Reimplemente Petro no modelo mobile usando `Fases/GAME.py` como unica fonte comportamental. Remova qualquer logica de seguidor, orbita ou disparo a distancia. Petro deve ser uma unidade corpo a corpo autonoma e persistente: selecionar o inimigo comum mais proximo da propria posicao, caminhar ate 50 px, trocar dano a cada 1 segundo, receber dano mitigado pela resistencia e aplicar `int(dano_jogador * 0.005) + dano_petro`. Quando o boss estiver ativo, ele se torna o alvo prioritario e recebe `int(dano_jogador * 0.15) + 15` pela mitigacao normal do boss, enquanto Petro sofre o dano do boss e aplica o roubo de vida previsto no jogo base. Preserve o crescimento por abates, as faixas exatas de evolucao da carta, os tres conjuntos de sprites, a barra de vida e a sombra dinamica. Sem alvo, Petro deve ficar parado onde esta. Ao morrer, deve ser desativado sem corromper a vida maxima; uma nova carta o reativa e cura 58%. Corrija apenas os defeitos identificados de vetor diagonal, cura impossivel e corrupcao da vida maxima. Crie testes separados para invocacao, faixas de evolucao, escolha do alvo, ausencia de retorno ao jogador, tick de combate comum, combate contra boss, progressao por abate, morte/reativacao e desenho de cada nivel.

## Criterios de aceite

- Petro jamais cria projeteis.
- Petro nao segue Geovana quando esta sem alvo.
- O alvo comum e escolhido pela distancia ate Petro, nao pela distancia ate Geovana.
- Boss ativo tem prioridade sobre inimigos comuns.
- Movimento diagonal nao e mais rapido que movimento reto.
- O intervalo de troca de dano e exatamente 1 segundo.
- As formulas de dano comum e dano no boss sao distintas e testadas.
- Cada abate feito por Petro concede pontos e os quatro crescimentos observados no `GAME.py`.
- A coleta respeita as faixas `1..8`, `9..16` e `>16`, sem simplificar para numero de copias.
- Morte desativa; nova coleta reativa e cura 58% sem alterar indevidamente a vida maxima.
- Capturas dos niveis 1, 2 e 3 confirmam sprite, direcao, pes, sombra e barra de vida.
