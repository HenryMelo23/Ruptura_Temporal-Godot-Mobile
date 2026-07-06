# Ruptura Temporal Mobile 2.0.11

## Novidades desde a 2.0.10

### Lacerante

- Rework completo da manifestacao Lacerante para aumentar sua recompensa de risco.
- Os tres cortes basicos ganharam mais 15px de alcance e novo visual de lamina rasgando o espaco-tempo.
- Inimigos grandes recebem dano adicional dos cortes, com bonus proprio para especies robustas e Bosses.
- Lacerante agora recebe 50% mais pontos ao eliminar inimigos incomuns.
- Adicionado o botao Reforco, com recarga de 3 segundos, que fortalece o proximo ATK.
- Executar um inimigo com o corte reforcado concede 1 Coagulo Temporal.
- Cada Coagulo aumenta o dano da Lacerante em 0,30% e a velocidade de ataque em 0,25%.
- Adicionado contador centralizado de Coagulos, preparado para valores com quatro ou mais digitos.
- O novo botao procura automaticamente uma posicao livre para nao sobrepor layouts personalizados antigos.
- O Q agora mostra uma lamina real girando 360 graus em sentido horario, com brilho, rastro e fenda carmesim.
- A tela de manifestacoes agora explica separadamente ATK, Q, Reforco, passivas e E da Lacerante.

### Manifestacoes e interface

- Adicionadas previews reais de gameplay para ATK, Q e E de todas as manifestacoes.
- A preview agora mostra uma habilidade grande por vez, com abas ATK, Q e E no topo.
- Os clipes usam capturas WebP em loop para manter os efeitos iguais aos vistos durante a partida.
- As previews da Lacerante foram recapturadas com os novos cortes e o novo Q.
- Melhorada a leitura da tela de manifestacoes e espectros em celulares e tamanhos maiores de fonte.

### Boss 2 e Nevasca

- A Nevasca do Boss 2 agora dura 30 segundos, sem aumento ou reducao dinamica de duracao.
- A zona segura foi balanceada para 285px.
- A nevasca ficou mais densa e recebeu uma camada branca translucida nas bordas.
- O Boss pode se esconder dentro da tempestade e se revela ao soprar ou 1 segundo antes do disparo de gelo.
- Durante o sopro, mover o analogico contra o vento reduz o empurrao e permite resistencia lenta.

### Boss 3 e Miasma da Vida

- As mascaras dos olhos receberam bordas suaves e esfumacadas.
- O sintoma dos olhos fechados ganhou queijo viscoso prendendo as palpebras.
- Boss e jogador ficam ligados por uma energia amarela, verde e preta enquanto levitam.
- O dano forte acontece quando as palpebras voltam a se encostar, sem contar o primeiro fechamento.
- O jogador pode continuar tentando abrir os olhos, mas passa a sofrer dano crescente ao exceder o tempo esperado.

### Audio e feedback

- Adicionados efeitos diferentes ao alternar manifestacoes e espectros.
- Cada manifestacao recebeu identidade sonora propria para disparo, trajeto e impacto.
- Prismatica ganhou sons de laser, vidro batendo e estilhacamento.
- Retornante ganhou propagacao oscilante e retorno reverso.
- Parasitica ganhou disparo organico e impacto molhado.
- Eletrica ganhou geracao, propagacao e impacto eletrico.
- Lacerante ganhou tres intensidades de corte para seu combo.
- Gravitante ganhou disparo sintetico e oscilacao orbital.

## Validacao

- Parser de `scripts/main.gd` validado no Godot 4.6.3.
- `tests/lacerante_rework_smoke.gd` passou cobrindo alcance, dano contra alvos grandes, Coagulos, recarga, pontos e botao adaptativo.
- `tests/manifest_spectrum_select_smoke.gd` passou cobrindo selecao, transicao, audio e previews.
- `tests/combat_pack_2_0_10_smoke.gd` permaneceu verde, protegendo Bosses, recompensas, Gravitante e Pinguim Incendiario.
- Capturas visuais em 1280x720 confirmaram HUD, Q, tela de informacoes e preview da Lacerante.
- `git diff --check` passou sem erros de whitespace.
