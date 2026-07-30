# Ruptura online relay

Este manager fica sempre ligado no VPS e cria uma sala Godot headless somente quando um jogador aperta `CRIAR SALA ONLINE`.

## Variaveis

- `PORT`: porta HTTP do manager. Padrao: `8090`.
- `ROOM_HOST`: IP ou DNS publico anunciado para o jogo. Padrao: `72.61.217.238`.
- `ROOM_PORT_START`: primeira porta ENet das salas. Padrao: `4522`.
- `ROOM_PORT_END`: ultima porta ENet das salas. Padrao: `4599`.
- `GODOT_BIN`: caminho do binario Linux headless do Godot.
- `PROJECT_PATH`: caminho do projeto no VPS.
- `ROOM_IDLE_MS`: tempo maximo de uma sala sem nova atividade antes de encerrar. O service usa 4h como fail-safe para clientes antigos; clientes novos renovam a sala via heartbeat.
- `STREAM_MANAGER_PUBLIC_BASE_URL`: URL publica do manager usada na pagina/link enviado ao Discord. Padrao: `http://ROOM_HOST:PORT`.
- `STREAMING_ENABLED`: `1` libera a transmissao QA opt-in. No jogo ela so aparece apos o cheat `CHANZADA` e so inicia quando o jogador aperta o botao `STREAM QA` no hub.
- `STREAM_MAX_ACTIVE`: limite duro de transmissoes simultaneas. Padrao: `2`.
- `STREAM_FRAME_MAX_BYTES`: maior frame aceito pelo modo MJPEG. Padrao: `1600000`.
- `STREAM_FRAME_BUFFER_MAX`: quantidade maxima de frames em memoria por stream. Padrao: `12`.
- `STREAM_FRAME_BUFFER_MS`: buffer alvo do modo MJPEG. Padrao: `250`.
- `RUN_REPORT_MAX_BYTES`: limite do JSON de ficha de run recebido em `/runs`. Padrao: `524288`.
- `LEADERBOARD_PATH`: arquivo local onde o ranking salva as runs. Padrao: `server/leaderboard_runs.json`.
- `LEADERBOARD_MAX_RUNS`: maximo de runs mantidas no ranking. Padrao: `500`.

## Exemplo

```bash
cd /opt/ruptura/Ruptura_Temporal-Godot-Mobile/server
PORT=8090 \
ROOM_HOST=72.61.217.238 \
GODOT_BIN=/opt/godot/Godot_v4.7-stable_linux.x86_64 \
PROJECT_PATH=/opt/ruptura/Ruptura_Temporal-Godot-Mobile \
node relay_manager.js
```

Liberar no firewall:

```bash
ufw allow 8090/tcp
ufw allow 4522:4599/udp
```

Teste rapido:

```bash
curl http://72.61.217.238:8090/health
```

Heartbeat de sala ativa:

```bash
curl -X POST http://72.61.217.238:8090/rooms/CODIGO/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"role":"owner","mode":"game","peer_id":1}'
```

## Ranking e fichas de run

O jogo envia automaticamente a ficha detalhada de cada partida para:

- `POST /runs`: salva player, perfil, versao, deck, dano, boss, rede e configuracoes.
- `GET /runs`: retorna os dados estruturados para auditoria.
- `GET /leaderboard`: dashboard com recordes, atividade recente e build do recorde.
- `GET /leaderboard/player/:profile`: perfil persistente, build/versao mais usadas e historico.
- `GET /leaderboard/rankings`: rankings separados e plano cartesiano de comparacao.
- `GET /leaderboard/run/:id`: ficha da partida com data/hora, deck, inimigos problematicos, mapa de calor e pontos de dano.

As sprites das cartas usadas no ranking sao servidas apenas de `assets/sprites/` pelo endpoint `/assets/...`.

## Atualizacoes Android

- `GET /updates/android/latest?version_code=227`: informa se existe uma versao Android mais nova.
- `GET /updates/android/download/:arquivo.apk`: entrega o APK publicado com suporte a download parcial (`Range`).

Depois de atualizar `version/name` e `version/code` no preset Android e gerar o APK, publique com:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\publish_android_update.ps1 `
  -Version "2.0.28" `
  -VersionCode 228 `
  -ApkPath ".\builds\2.0.28\ruptura_temporal_mobile_2.0.28.apk" `
  -Notes "Novo conteudo" "Correcoes multiplayer"
```

O script solicita a credencial do servidor, calcula o SHA-256, valida a versao do preset, envia o APK e ativa o manifesto de forma atomica. O relay nao precisa ser reiniciado. A primeira versao que contem o atualizador ainda precisa ser instalada manualmente; depois dela, as novas versoes aparecem na tela inicial do jogo.

## Streaming QA opt-in

A transmissao ao vivo voltou como recurso de QA, mas com consentimento explicito e limites de banda:

- fica invisivel ate o cheat `CHANZADA`;
- nao inicia automaticamente ao abrir o jogo ou iniciar run;
- o jogador escolhe `360p` ou `720p` nas configuracoes;
- o botao `STREAM QA` no hub abre/encerra a sessao;
- ao sair/fechar o jogo o cliente envia `DELETE /streams/:id`;
- o relay limita sessoes simultaneas, tamanho de frame, bitrate e buffer.

Nao use a porta `8080`; o manager publico deste projeto fica em `8090`.

Teste esperado:

```bash
curl -X POST http://72.61.217.238:8090/streams \
  -H 'Content-Type: application/json' \
  -d '{"player":"QA","room":"teste","version":"2.0.31","streamWidth":640,"streamHeight":360,"streamFps":24}'
```
