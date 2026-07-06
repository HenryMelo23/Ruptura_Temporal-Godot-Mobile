# Ruptura Temporal Mobile 2.0.10

## Alteracoes desde a 2.0.9

- Boss 2 recebeu ajuste de sombra para alinhar melhor com a base real da sprite.
- Boss 2 ganhou a ultimate Nevasca do Sentinela.
- A ultimate ativa uma vez quando o Boss 2 chega a 40% de vida, sem espera de cooldown, e dura 40 segundos.
- A nevasca cria uma zona segura central de 550px e uma tempestade intensa e giratoria nas bordas.
- Acertos do jogador no Boss durante a ultimate reduzem 2 segundos da duracao.
- Acertos/danos do Boss durante a ultimate aumentam 5 segundos da duracao.
- Boss 2 passa a circular dentro da nevasca enquanto pressiona o jogador.
- Durante a ultimate, Boss 2 alterna cuspida de gelo e vento gelido.
- Cuspida de gelo tem aviso visual antes de disparar.
- Vento gelido tem aviso visual, dura 3 segundos e empurra o jogador para a nevasca.
- Jogador pode resistir ao vento andando na direcao oposta.
- Tocar na nevasca causa dano progressivo: 20 + 5% da vida maxima, com ticks cada vez mais rapidos enquanto permanecer fora da zona segura.
- Adicionado smoke test para validar timer, orbita, dano da nevasca e empurrao do vento.
- Cada Boss derrotado concede 5 cartas garantidas e 250% da pontuacao de um inimigo comum.
- A fase 2 ganhou um unico Pinguim Incendiario vermelho, que cria paredes de fogo em blocos de 32x32 por 15 segundos a cada disparo de 5 segundos.
- O Q da Gravitante agora colide todos os inimigos marcados e empurra os alvos nao marcados proximos.
- A ultimate da Gravitante agora prende, movimenta e causa dano tambem nos Bosses.
- Projeteis inimigos da fase 3 ficaram maiores e receberam contorno roxo de alto contraste.
- Boss 3 agora usa seus frames de caminhada em todo deslocamento e recupera apenas 25% da vida perdida ao consumir queijo.
- Boss 1 agora caminha ate o centro antes de iniciar as ondas de ruptura.
- Boss 3 ganhou a ultimate Miasma da Vida: dura 15 segundos e entra em recarga de 30 segundos somente ao terminar.
- O Miasma sorteia tres sintomas: clones amarelados com troca de posicao, breu de 250px com cuspe de queijo, ou um QTE de abertura dos olhos.
- O QTE exige de 20 a 40 toques centrais em 7 segundos, pausa o combate, concede invulnerabilidade e pune a falha com 100 + 25% da vida maxima.

## Validacao

- `tests/boss2_ultimate_smoke.gd` passou no Godot 4.6.3 headless.
- `tests/combat_pack_2_0_10_smoke.gd` passou cobrindo recompensas, Pinguim Incendiario, Gravitante e Bosses 1/3.
- Smokes de Gravitante, onda do Boss 1, fase 3 e maquina de estados do Boss 2 passaram.
- `git diff --check` passou sem erros de whitespace.
