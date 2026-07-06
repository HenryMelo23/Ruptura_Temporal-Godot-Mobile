# Fase 4 mobile - base de fidelidade

Fonte de verdade: `Fases/GAME4.py` e `Engine/Variaveis.py` do jogo desktop.

## Estrutura portada

- Mapa: `Fase4.png`, renderizado pela mesma câmera e escala das fases anteriores.
- Inimigo comum: dois frames por direção, perseguição direta e limite simultâneo de quatro unidades.
- Magia inimiga: disparo direcionado ao jogador; ao acertar, causa o dano da fase e desloca o jogador para outro ponto válido do mapa.
- Boss: **Nexo da Ruptura**, ancorado na lateral direita e animado por `Boss4_1`, `Boss4_2` e `Boss4_3`.
- Planeta perseguidor: lançado a cada 6 segundos, corrige gradualmente a rota durante 7 segundos e possui 150 de vida própria.
- Zona nula: nasce somente quando um planeta expira sem ser destruído, dura 4 segundos e causa 10% da vida máxima a cada 500 ms.
- Petro: procura primeiro inimigos comuns e depois o Nexo. Em contato com o Boss 4, sofre o contra-ataque, recupera parte da vida perdida pelo roubo de vida e causa `25%` do dano da Geovana mais `300` antes da mitigação do chefe.
- Progressão: derrotar o Pai-Rato cria o fragmento da Fase 4; derrotar o Nexo encerra a versão atual em vitória.

## Boss 4 - Nexo da Ruptura

O chefe agora usa a camada completa de controlador de arena descrita para o mobile.

- **Instabilidade da Ruptura:** barra própria no topo da tela. Sobe quando o jogador demora para atacar, falha em lidar com zonas/ataques e durante drenagens do Petro; cai quando o núcleo é atacado ou quando o clone deixa uma zona segura.
- **Estágio 1, 100%-75%:** planetas perseguidores e pulso gravitacional ao redor da âncora.
- **Estágio 2, 75%-50%:** fendas espaciais com aviso, inversão/puxão de gravidade e vetores de ruptura que deslocam a Geovana.
- **Estágio 3, 50%-25%:** vampirismo dimensional no Petro, prisão orbital quebrável por tiros e clone de ruptura da Geovana.
- **Estágio 4, 25%-0%:** núcleo exposto recebe mais dano, chuva de fragmentos cósmicos e zonas de colapso no mapa.
- **Ultimate, 20%:** Singularidade Absoluta cria quatro âncoras no mapa. Destruir 3 interrompe a canalização, atordoa o Nexo, expõe o núcleo e limpa zonas nulas. Falhar causa dano massivo, cura parcial o boss, cria zonas nulas e leva a instabilidade ao máximo.

## Separação de estado

Todos os elementos exclusivos usam `phase4_planets`, `phase4_null_zones`, `phase4_enemy_hazards`, `boss4_rupture_anchors` e os timers `boss4_*`. Isso impede que projéteis, zonas ou animações da Fase 4 contaminem as máquinas de estado dos bosses anteriores ou as âncoras da manifestação Ancorada.

## Habitantes do Coracao do Nexo

- **Cartografo do Vazio:** desenha uma fenda entre sua posicao e o futuro imediato da Geovana. A linha avisa antes de abrir; atravessa-la causa dano e desloca a personagem.
- **Cronofago:** expande um relogio territorial. O pulso nao causa dano direto, mas retira progresso dos cooldowns de ATK, Q, E e TP.
- **Refrator Hostil:** instala um prisma temporario no mapa. O prisma dispara salvas de tres fragmentos em angulos diferentes.
- **Tecelao Vetorial:** cobre uma area com setas inclinadas. Dentro dela, a direcao escolhida pelo jogador e rotacionada em 38 graus.
- **Eco Entropico:** grava tres pontos recentes do caminho do jogador e os detona em sequencia apos aviso claro.

Os cinco tipos reutilizam os frames-base com paletas e silhuetas procedurais distintas. O limite simultaneo continua em quatro unidades, o sorteio evita repeticao enquanto houver outro tipo disponivel e todas as anomalias sao removidas quando o Boss e chamado.

## Testes

- `tests/phase4_smoke.gd`: mapa, inimigos, teleporte, planeta, zona nula, Petro e transições.
- `tests/phase4_visual_smoke.gd`: composição visual em 1280x720 com todos os elementos principais ativos.
- `tests/boss4_nexus_mechanics_smoke.gd`: estágios, vampirismo, prisão, clone e resolução da ultimate com sucesso/falha.
