# Documentação do GAME4.py

Este documento explica detalhadamente o funcionamento, a estrutura e as mecânicas implementadas na Fase 4 (`GAME4.py`) do projeto.

## 1. Estrutura do `GAME4.py`
O arquivo `GAME4.py` (localizado em `Game Base/Ruptura_Temporal-APOLO2.0/Fases/GAME4.py`) é um script construído com a biblioteca **Pygame**, que controla o fluxo da Fase 4 do jogo. Sua estrutura principal é baseada no padrão clássico de Game Loop:
- **Inicialização e Imports:** Carrega módulos externos, dados do jogador, save states e inicializa o Pygame.
- **Variáveis Globais e Configurações:** Define atributos, listas de inimigos, projéteis, timers de spawn e referências ao Boss.
- **Funções de Controle:** Métodos para calcular vetores de projéteis, processar dano (`aplicar_hit_jogador`), resolver colisões e calcular a movimentação.
- **Game Loop Principal (`while running:`):** 
  - **Eventos:** Processa inputs de teclado, mouse ou joystick para movimento e *dash* (teleporte).
  - **Atualização de Lógica:** Move o personagem, processa habilidades (auras como Vanguarda, Devota, Impulsiva), atualiza disparos do jogador e cooldowns.
  - **Mecânicas Inimigas:** Gerencia o *spawn* (surgimento), movimentação vetorial dos inimigos, colisões com o jogador e lançamentos de disparos.
  - **Renderização (Draw):** Desenha na tela (Superfície `tela`) o fundo (mapa), sombras, projéteis, inimigos, o Boss e por fim a interface do usuário (HUD).

## 2. Inimigos Comuns (Mecânicas e Sprites)

### Mecânicas dos Inimigos
Os inimigos operam através de um sistema vetorial de perseguição direta.
- **Movimentação:** A cada frame, o inimigo calcula a diferença de distância `(dx, dy)` entre ele e o jogador. Esse vetor é normalizado e multiplicado pela variável `velocidade_inimigo2` para que ele caminhe diretamente até o personagem.
- **Dano Físico (Melee):** Se o retângulo de colisão do inimigo intercepta o do jogador e o tempo de invulnerabilidade do jogador expirou, o inimigo aplica dano baseado na variável `dano_inimigo_perto`.
- **Ataque à Distância:** Aleatoriamente (chance de `0.008` por frame) e respeitando um tempo mínimo entre tiros (`intervalo_disparo_inimigo` de 1500ms), o inimigo dispara um projétil contra o jogador (`criar_disparo_inimigo()`).
- **Progressão (Escalonamento):** Ao ser abatido, o inimigo aumenta progressivamente o multiplicador de ameaça e fortalece os próximos inimigos (aumento de vida, dano e resistências).

### Sprites dos Inimigos
Os sprites são carregados nas listas `frames_inimigo_esquerda4` e `frames_inimigo_direita4` (definidos em `Variaveis.py`).
- **Arquivos Usados:**
  - `Sprites/inimigo_direita4-1.png`
  - `Sprites/inimigo_direita4-2.png`
  - `Sprites/inimigo_esquerda4-1.png`
  - `Sprites/inimigo_esquerda4-2.png`
- **Animação:** O jogo verifica constantemente em que direção o jogador está (`dx > 0`). Se estiver à direita, ele usa o array `frames_inimigo_direita4` e alterna entre os frames usando `frame_atual % len()`.

## 3. Boss (Chefe da Fase 4)

O Boss desta fase possui um comportamento central que atua diretamente contra um elemento de suporte: o "Petro".

### Como funciona e Habilidades
- **Status:** Controlado pela flag booleana `boss_vivo4`.
- **Habilidade Principal - Perseguição do Petro:** Diferente dos inimigos comuns que focam no jogador, o Boss 4 foca agressivamente no "Petro" (o ajudante do jogador). Ele calcula a distância entre `(pos_x_chefe2, pos_y_chefe2)` e `(pos_x_petro, pos_y_petro)`. *(Nota: o script utiliza uma mistura de `pos_x_chefe2` e coordenadas do `boss4` na movimentação devido a reuso de código).*
- **Ataque de Absorção/Dano:** Quando o Boss alcança o Petro (distância `<= 50`), ele ativa sua habilidade: ataca o Petro (tirando vida dele) e, simultaneamente, **cura a si mesmo** roubando vida (`vida_boss4 -= dano_boss_mitigado...`), funcionando como um vampirismo constante enquanto estiver próximo do mascote.
- **Vulnerabilidades:** O boss toma dano de ondas de choque do dash do jogador, auras avançadas (ex: mordida da aura Voraz) e acertos diretos.
- **Transição de Fase:** Quando sua vida (`vida_boss4`) chega a `<= 0`, a variável `boss_vivo4` vira `False`. Quando o jogador encosta no hitbox do Boss derrotado, a fase se encerra, salvando atributos e iniciando a transição para a Fase 5.

### Sprites do Boss
Os sprites originais do Boss são definidos em `Variaveis.py` e carregados como:
- `Sprites/Boss4.png`
- `Sprites/Boss4_1.png`
- `Sprites/Boss4_2.png`
- `Sprites/Boss4_3.png`
- O sprite principal exibido durante a fase é referenciado no script através da imagem instanciada `boss4_2_img` ajustada nas dimensões `(chefe_largura4, chefe_altura4)`.

## 4. Mapa (Cenário)

### Sprite do Mapa
- **Arquivo Usado:** O arquivo original é referenciado pela variável `mapa_path4`, que corresponde ao arquivo `Sprites/Fase4.png`.

### Mecânica e Renderização
- **Fundo Estático Escalável:** A imagem do mapa é carregada no início do script (`pygame.image.load(mapa_path4)`) e forçada a preencher toda a tela usando a escala `pygame.transform.scale(mapa, (largura_tela, altura_tela))`.
- **Limites de Tela:** As posições do jogador e inimigos utilizam `largura_mapa` e `altura_mapa` dentro da função `max(0, min(limite, posicao))` para garantir que nenhuma entidade "fuja" para fora das dimensões limitadas pelo tamanho do mapa renderizado.
- **Renderização Constante:** O mapa funciona como a base de pintura (Background). A cada frame no *loop* principal do Pygame, a primeira etapa de desenho é aplicar (blit) a superfície do `mapa` sobre a `tela` para apagar os rastros do frame anterior.
