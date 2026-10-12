# Sineiro Boreal — contrato de runtime

Miniboss exclusivo da Fase 2, controlado por `RTPhase2SineiroBorealController`.
O runtime principal apenas compõe o owner, encaminha dano/morte e chama sua
apresentação.

## Fluxo

- Spawn uma vez por run aos 300 s de Fase 2 no onboarding ou 240 s no perfil
  experiente. Eventos especiais, loja, boss e transição adiam o spawn.
- Estados: entrada, aproximação, posicionamento, telegraph, ataque, recuperação,
  stagger, exaustão, morte e retirada.
- A Badalada registra posições por `peer_id`, fixa no máximo três marcas e
  aplica dano autoritativo após 1,1 s. As marcas não acompanham o jogador.
- Os Estilhaços fixam a direção após 0,8 s e lançam três projéteis sem homing.
- Após a Badalada, o Sineiro fica parado por 1,6 s e recebe 15% a mais de dano.
- Após 110 s, boss call ou mudança de fase, sai sem recompensa.

## Multiplayer e persistência

O host decide spawn, party size, HP, alvos, ataques, dano, morte e recompensa.
O tamanho da equipe fica fixo no encontro e usa HP 1,00x / 1,70x / 2,35x.
Eventos visuais confiáveis e snapshots visuais periódicos alimentam clientes;
os tipos do inimigo e dos estilhaços também fazem parte dos snapshots normais.

`sineiro_boreal_state`, `sineiro_echo_marks` e `sineiro_visual_events` fazem
parte do snapshot de run interrompida/retry. Saves antigos continuam válidos,
pois os campos ausentes mantêm os defaults do owner.

## Recompensa

Uma morte autoritativa concede exatamente duas cartas comuns por participante
e pontos iguais a 35% do `card_cost` atual. O `encounter_id` gera uma chave
idempotente. Retirada e cleanup não concedem cartas, pontos, fragmentos ou
evolução de Manifestação.

## Atlas

- `sineiro_boreal_motion.png`: grade 6x4, 256 px por célula. Idle 0–3, dano
  4–5, caminhada 6–11, preparação 12–16, início 17, ataque 18–20 e exaustão
  21–23.
- `sineiro_boreal_death.png`: faixa 6x1, 256 px por célula.
