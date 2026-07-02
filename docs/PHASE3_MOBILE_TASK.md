# Task: Fase 3 mobile - Catedral do Esgoto

Fonte de verdade: `Game Base/Ruptura_Temporal-APOLO2.0/Fases/GAME3.py`.

## Inventario do jogo-base

### Mapa, audio e sprites

- Mapa: `Sprites/Fase3.png`.
- Musica da fase mobile: playlist aleatoria entre `Fase3-1.mp3` e `Fase3-2.mp3`; ao terminar, sorteia novamente e pode repetir ou alternar. `Esgoto.mp3` permanece apenas como fallback se nenhuma faixa estiver disponivel.
- Musica do boss: `Sounds/Fase3_Boss.mp3`.
- Inimigo base: `inimigo_direita3-1/2.png` e `inimigo_esquerda3-1/2.png`.
- Disparo inimigo: `Disp_inimigo3_1/2.png`.
- Pai-Rato parado: `Boss3_1/2.png`.
- Pai-Rato andando: `Bossandando3_1/2.png`.
- Frasco do boss: `disparo_boss3.png`.
- Objetivo de queijo: `queijo.png`.

### Inimigos

- Rato base: persegue o jogador e pode disparar um projetil lento em linha reta.
- Devoto Febril: 60% da vida base, 135% da velocidade, escala 85%, deixa rastro toxico a cada 260 ms por 2,5 s; ao morrer cria nuvem de miasma por 2 s.
- Incensario: 90% da vida, 72% da velocidade, mantem 220-430 px de distancia, circula o jogador e prepara por 550 ms uma area de miasma no local marcado; cooldown de 2,2-3 s.
- Guardiao de Sucata: 275% da vida, 52% da velocidade, escala 135%, dano de contato 135%; escudo frontal reduz dano para 25% e ataques pelas costas causam 112%.
- Sorteio desktop: Guardiao 6%, Incensario ate 15%, Devoto ate 33%, respeitando limites 2/2/3.
- Miasma: ticks a cada 650 ms. Rastro causa 1,2%, nuvem de morte 1,8% e area do Incensario 1,5% da vida maxima.

### Pai-Rato

- Estagios por vida: fase 1 acima de 70%, fase 2 entre 70% e 35%, fase 3 abaixo de 35%.
- Recurso Fe: inicia em 50, vai de 0 a 100, cresce ao consumir queijo e cai quando queijos verdadeiros sao destruidos.
- Chuva de frascos: quatro corredores telegrafados por 650 ms, com uma abertura segura; cooldown base 4,3/3,6/3 s, reduzido pela Fe.
- Cuspida venenosa: linha telegrafada por 360 ms, projetil direcionado, 10% de dano, doenca por 800 ms e miasma no impacto; cooldown 4,2/3,4/3 s.
- Cauda: disponivel a partir do estagio 2 quando o jogador esta perto; circulo de 155 px por 520 ms, 12% de dano e empurrao de 42 px; cooldown 3,2 s.
- Carga cega: exclusiva do estagio 3; linha de 650 px por 700 ms, carga por ate 850 ms, 16% de dano; bater na parede atordoa o boss por 1,7 s.
- Queijo de 85%: um queijo verdadeiro.
- Evento de 60%: um verdadeiro, um falso e dois Devotos. O falso vira miasma.
- A partir do estagio 2: novo queijo verdadeiro a cada 12 s, com um Devoto auxiliar.
- Consumo: o boss corre ate o queijo, canaliza por cerca de 1 s, cura parte da vida perdida e ganha 20 de Fe.
- Ritual de 25%: tres queijos verdadeiros durante 8,5 s. Destruir dois quebra 30 de Fe e deixa o boss vulneravel por 3,2 s; falhar cura 32% da vida perdida, concede 25 de Fe e cria miasma grande.
- Vulnerabilidade: dano recebido multiplicado por 1,35 durante o atordoamento.
- Falas: entrada, ataque, queijo, queijo destruido e estagio final, com intervalo de 8-12 s.

## Checklist de implementacao mobile

- [x] Auditar o `GAME3.py` e dependencias em `Engine/Variaveis.py`.
- [x] Importar mapa, sprites, disparos e queijo sem substituir assets existentes.
- [x] Adicionar transicao Fase 2 -> fragmento -> Fase 3 -> vitoria.
- [x] Configurar musica, identidade visual, stats e HUD da Fase 3.
- [x] Portar rato base, Devoto Febril, Incensario e Guardiao de Sucata.
- [x] Portar projetil inimigo animado e todas as areas de miasma.
- [x] Portar Fe, tres estagios e falas do Pai-Rato.
- [x] Portar chuva de frascos, cuspida, cauda e carga cega com telegraphs.
- [x] Portar queijos verdadeiros/falsos, cura, auxiliares e ritual final.
- [x] Garantir que todas as manifestacoes possam destruir queijos.
- [x] Garantir trava de mira em inimigos da fase, boss e objetivos validos.
- [x] Validar parser, transicao, sorteio/caps, danos, ritual, morte e vitoria.
- [x] Renderizar QA visual em 1280x720 e conferir mapa, sprites e telegraphs.
