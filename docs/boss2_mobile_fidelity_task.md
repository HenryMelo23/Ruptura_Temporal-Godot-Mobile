# Task: Boss 2 Mobile Fidelity

Fonte desktop: `Game Base/Ruptura_Temporal-APOLO2.0/Fases/GAME2.py`.

Objetivo: portar o Sentinela Glacial para o modelo mobile preservando a identidade mecanica e visual da fase 2.

## Escopo aplicado

- Entrada do boss com queda de cristal, impacto, tremor, estilhacos de gelo e aviso "A NEVASCA EMITE UM GRITO".
- Timing principal do desktop: entrada de 2.5s, aviso de 1.7s e intervalo de habilidade de 5.2s.
- Nevascas horizontais e verticais com padroes variados, ondas suavizadas, largura reduzida e velocidade ajustada.
- Avalanche com marcadores no chao, queda de gelo, explosao em estilhacos e zona de lentidao temporaria.
- Sopro congelante com telegraph, cone visual, particulas e disparos em leque.
- Escudo de cristais com mitigacao real de dano, cristais orbitando e tiros periodicos contra o jogador.
- Rastros e zonas de neve desaceleram o jogador na fase 2 sem bloquear o resto do controle mobile.

## Arquivo principal

- `scripts/main.gd`

## Validacao

- Godot `--check-only --script scripts/main.gd`
- Godot headless na cena `res://scenes/Main.tscn` por 2 segundos
- `git diff --check -- scripts/main.gd`
