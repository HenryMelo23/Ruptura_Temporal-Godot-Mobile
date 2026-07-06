# Paridade das aureas: desktop -> mobile

Fonte de verdade analisada: `Aureas/dados_aureas.py`, `Aureas/aureas_avancadas.py`, `Aureas/insana_aurea.py`, `Aureas/voraz_aurea.py`, `Engine/ui_helpers.py` e os pontos de integracao em `Fases/GAME.py` do jogo base.

## Racional

- Gatilho: permanecer imovel por 4,5s concede `5 + 2 * nivel` pontos.
- Teleporte pronto ativa 8s de Dilatacao: mundo a 0,42x, Geovana a 1,35x e intervalo de ataque a 0,72x.
- Custo: ao terminar, o mundo acelera para 1,18x por 3s. Recarga propria de 30s apos a Dilatacao.
- Leitura mobile: ondas temporais concentricas e medidor de analise.

## Impulsiva

- Gatilho: cinco abates sem receber dano ativam Frenesi por `3 + 0,5 * nivel` segundos.
- Frenesi multiplica dano e velocidade por `base * (1 + 0,15 * grau)`; renovar com pelo menos 1s restante aumenta o grau.
- Custo: receber dano encerra o Frenesi e arma Panico. O proximo dano e multiplicado por `2 + 0,5 * grau`.
- Leitura mobile: cinco pulsos de abate e indicador de grau.

## Devota

- Comeca com tres cargas; cada carga anula integralmente um impacto.
- Cada bloqueio cura 10% da vida perdida e concede 1,25x dano por 3s.
- A ultima carga ativa Fe Ardente: 1,65x dano por 4,5s e velocidade a 0,90x.
- Recarga: `22 - 2,5 * nivel` segundos, limitada a 9,5s.
- Leitura mobile: tres selos hexagonais que se apagam individualmente.

## Vanguarda

- Receber dano ativa um circulo de fogo por 5s; inimigos dentro de 150px queimam por `5 + nivel` segundos.
- Queimadura causa por segundo `1% + 0,2pp * nivel` da vida maxima.
- Custo: cada inimigo em chamas aumenta em 15% a recarga do Teleporte.
- Leitura mobile: borda de fogo irregular no mundo, chamas sobre os alvos e HUD sem barra generica.

## Insana

- A cada `20 - nivel` segundos, os proximos quatro tiros deixam ecos parados.
- Cada eco repete o tiro apos 1s, a 0,92x de velocidade e com `12% + 5pp * nivel` do dano.
- Inimigos devem perceber os ecos como ameacas; abate por eco eleva a proxima ativacao para cinco ecos.
- Custo: depois do ultimo eco, o proximo Teleporte recebe 2s extras.
- Leitura mobile: silhueta verde/roxa no ponto do disparo, pulso antes da copia e contador de ecos.

## Voraz

- Abates deixam coagulos coletaveis por 6,8s; coleta concede Fome e cura `2% + 2,5pp * ciclo` da vida perdida, teto de 14,5%.
- Fome maxima por ciclo: `100 + 54*ciclo + 9*ciclo^2`; ciclos altos decaem mais rapido.
- Fome aumenta tamanho/dano dos disparos e reduz cooldown, com limite de 12%.
- Proximidade puxa alvos; mordida a cada 1,3s causa `10% + 2,5pp * ciclo` do dano base, alimenta Fome e cura.
- Custo: 30s sem coletar drenam 1% da vida maxima a cada 1,5s.
- Leitura mobile: coagulos pulsantes, mandibula no HUD e Fome por ciclos `XN`.

## Nula

- Ficar 2,3s sem atacar carrega Vazio a 9,5 pontos/s; abate concede 18 pontos.
- Em 100 pontos, o proximo disparo aplica Nulificacao por `4,2 + 0,35 * nivel` segundos.
- Contra alvo com pelo menos 55% de vida, esse disparo causa `1,18 + 0,035 * nivel` do dano.
- Custo: enquanto Vazio esta parcialmente carregado, Teleporte recarrega 4% mais devagar.
- Leitura mobile: nucleo escuro que contrai, fissura orbital e anel nulo no alvo.

## Abissal

- Inimigos vivos, inimigos a ate 190px e boss ativo carregam Profundidade.
- Em 100, ativa Mare Negra por `5,2 + 0,55 * nivel` segundos: puxa inimigos e causa dano continuo aos fracos.
- Durante a Mare, alvos abaixo de `28% + 1,5pp * nivel` recebem `1,22 + 0,04 * nivel` do dano; os demais recebem bonus menor.
- Custo: Profundidade reduz ate 16% da velocidade; Mare adiciona 4% de peso e aumenta recarga do Teleporte.
- Leitura mobile: aneis profundos assimetricos e mare girando em torno da jogadora.

## Profetica

- A cada `11 - 0,85 * nivel` segundos, um inimigo recebe Pressagio por 6,4s.
- Acertar o marcado causa `1,22 + 0,04 * nivel` do dano; elimina-lo concede `35 + 15*nivel + 10*sequencia` pontos.
- Custo: deixar o Pressagio expirar zera a sequencia e aplica Destino Quebrado por 3,5s, aumentando Teleporte em 12%.
- Leitura mobile: olho dourado no alvo e constelacao progressiva no HUD.

## Sanguinaria

- Tres hits no mesmo alvo dentro da janela abrem Ferida por `7,8 + 0,45 * nivel` segundos; nivel 5 exige dois hits.
- Feridos recebem `1,12 + 0,035*nivel + ate 0,14 pela Sede` do dano.
- Quatro feridas preparam Carnificina; nivel 5 exige tres. O proximo acerto ferido recebe mais 1,35x.
- Abater ferido alimenta Sede e reduz a recarga da habilidade em `0,18 + 0,03 * nivel` segundos.
- Custo: apos 8,5s sem ferir, Sede decai; zerar com feridas pendentes pesa Geovana por 2,6s.
- Leitura mobile: cortes diagonais, feridas sobre a sprite e Sede vermelha.

## Contrato de smoke

O smoke deve validar, para todas as dez aureas: estado inicial, gatilho, formula principal, penalidade e evento produzido. O smoke visual deve abrir a cena de gameplay, alternar as dez aureas e confirmar que o desenho e o HUD nao geram erro em landscape mobile.
