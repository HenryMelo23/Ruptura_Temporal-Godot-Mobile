# Ruptura online relay

Este manager fica sempre ligado no VPS e cria uma sala Godot headless somente quando um jogador aperta `CRIAR SALA ONLINE`.

## Variaveis

- `PORT`: porta HTTP do manager. Padrao: `8080`.
- `ROOM_HOST`: IP ou DNS publico anunciado para o jogo. Padrao: `72.61.217.238`.
- `ROOM_PORT_START`: primeira porta ENet das salas. Padrao: `4522`.
- `ROOM_PORT_END`: ultima porta ENet das salas. Padrao: `4599`.
- `GODOT_BIN`: caminho do binario Linux headless do Godot.
- `PROJECT_PATH`: caminho do projeto no VPS.
- `ROOM_IDLE_MS`: tempo maximo de uma sala sem nova atividade antes de encerrar.
- `STREAM_MANAGER_PUBLIC_BASE_URL`: URL publica do manager usada na pagina/link enviado ao Discord. Padrao: `http://ROOM_HOST:PORT`.
- `STREAM_TTL_MS`: tempo maximo de uma sessao de streaming registrada no manager. Padrao: 4h.
- `STREAM_FRAME_MAX_BYTES`: limite por frame enviado pelo jogo. Padrao: `6000000`.
- `STREAM_FRAME_BUFFER_MAX`: maximo de frames mantidos no buffer curto. Padrao: `90`.
- `STREAM_FRAME_BUFFER_MS`: janela maxima do buffer curto. Padrao: `900`.
- `RUN_REPORT_MAX_BYTES`: limite do JSON de ficha de run recebido em `/runs`. Padrao: `524288`.
- `LEADERBOARD_PATH`: arquivo local onde o ranking salva as runs. Padrao: `server/leaderboard_runs.json`.
- `LEADERBOARD_MAX_RUNS`: maximo de runs mantidas no ranking. Padrao: `500`.

## Exemplo

```bash
cd /opt/ruptura/Ruptura_Temporal-Godot-Mobile/server
PORT=8080 \
ROOM_HOST=72.61.217.238 \
GODOT_BIN=/opt/godot/Godot_v4.7-stable_linux.x86_64 \
PROJECT_PATH=/opt/ruptura/Ruptura_Temporal-Godot-Mobile \
node relay_manager.js
```

Liberar no firewall:

```bash
ufw allow 8080/tcp
ufw allow 4522:4599/udp
```

Teste rapido:

```bash
curl http://72.61.217.238:8080/health
```

## Ranking e fichas de run

O jogo envia automaticamente a ficha detalhada de cada partida para:

- `POST /runs`: salva player, perfil, versao, deck, dano, boss, rede e configuracoes.
- `GET /runs`: retorna os dados estruturados para auditoria.
- `GET /leaderboard`: mostra uma pagina HTML comparando os players, versoes, decks e parametros principais.

As sprites das cartas usadas no ranking sao servidas apenas de `assets/sprites/` pelo endpoint `/assets/...`.

## Streaming QA

O jogo captura o viewport renderizado em alta resolucao e publica frames reais no manager. Nao depende mais de MediaProjection, RTMP ou MediaMTX para o QA stream.

- `publishUrl`/`frameUrl`: endpoint HTTP que recebe `POST` binario `image/jpeg` ou `image/png`.
- `watchUrl`/`mjpegUrl`: stream `multipart/x-mixed-replace` para o navegador.
- `viewerUrl`: pagina leve do manager que mostra o stream, usa buffer curto e cai para polling do ultimo frame se o MJPEG falhar.

Teste de sessao:

```bash
curl -X POST http://72.61.217.238:8080/streams \
  -H 'Content-Type: application/json' \
  -d '{"player":"QA","room":"teste","version":"2.0.24"}'
```
