# Mercenaria e Coletora - paridade do GAME.py

## Mercenaria

- Ativa um contrato de abates sem limite de tempo.
- Cada abate acrescenta o bonus atual aos pontos recebidos.
- A cada 5 abates, o bonus aumenta em `25 + 40 * numero_de_cartas`, limitado a 500.
- Sofrer dano real zera a sequencia e o bonus acumulado.
- O HUD mostra cinco marcos do contrato, total de abates e bonus atual.

## Coletora

- O limite base fica inativo ate a primeira carta.
- A primeira carta ativa 5% e soma 0,8 ponto percentual, resultando em 5,8%.
- Cada copia adicional soma mais 0,8 ponto percentual.
- Inimigos comuns abaixo do limite sao executados.
- Boss usa 20% do limite comum, limitado a 1,5%.
- Barras de vida mostram a marca exata da faixa de execucao.
- Quando o alvo entra na faixa, a marca pulsa em vermelho; ao executar, ha texto e fragmentacao carmesim.

## Validacao

- Combo nao expira esperando.
- Quinto abate melhora o contrato; o bonus novo vale a partir do proximo abate.
- Dano recebido quebra contrato; dano bloqueado por imunidade nao quebra.
- Limites comum e boss seguem formulas distintas.
- HUD permanece legivel em 1280x720 e nao cobre controles.
