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
