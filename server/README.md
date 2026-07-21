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
- `STREAMING_ENABLED`: deve permanecer `0`. A transmissao QA foi removida para preservar banda da VPS.
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

## Streaming QA removida

A transmissao ao vivo de partida foi removida do jogo e fica desligada no relay por padrao. A VPS deve manter apenas:

- multiplayer online;
- ranking/fichas de run;
- atualizacao Android por APK.

Os endpoints `/streams` retornam `410 streaming disabled`. Nao delete a VPS nem outros projetos para aplicar isso; pare apenas o servico `ruptura-mediamtx` caso ele ainda exista no host.

Teste esperado:

```bash
curl -X POST http://72.61.217.238:8090/streams \
  -H 'Content-Type: application/json' \
  -d '{"player":"QA","room":"teste","version":"2.0.24"}'
```
