# Contrato RPC — Lobby / Handshake

Escopo da extração: o processamento de pronto e snapshots de lobby pertence a
`scripts/systems/online/runtime_lobby_controller.gd`. As entradas RPC abaixo
permanecem no nó raiz `Main` de `res://scenes/Main.tscn`. Portanto, o caminho
de rede continua sendo `/root/Main/<nome-do-metodo>` e não pode ser movido para
o controller.

| RPC | Autoridade / modo | Confiabilidade / canal | Payload, na ordem wire |
| --- | --- | --- | --- |
| `_toggle_ready` | `any_peer`, `call_remote` | `reliable`, 3 | `ready: bool` |
| `_toggle_ready_v2` | `any_peer`, `call_remote` | `reliable`, 3 | `ready: bool`, `sequence: int` |
| `_online_lobby_ready_ack` | `authority`, `call_remote` | `reliable`, 3 | `sequence: int`, `confirmed_ready: bool`, `accepted: bool`, `room_code: String = ""` |
| `_online_start_ack` | `authority`, `call_remote` | `reliable`, 3 | `sequence: int`, `accepted: bool`, `reason: String = ""` |
| `_online_lobby_state` | `authority`, `call_remote` | `reliable`, 3 | `room_code: String`, `connected: int`, `ready: int` |
| `_online_lobby_roster` | `authority`, `call_remote` | `reliable`, 3 | `roster: Array` |
| `_online_lobby_state_v2` | `authority`, `call_remote` | `reliable`, 3 | `room_code: String`, `connected: int`, `ready: int`, `local_ready_confirmed: bool`, `remote_client_ready = null` |
| `_online_lobby_state_v3` | `authority`, `call_remote` | `reliable`, 3 | `room_code: String`, `connected: int`, `active_players: int`, `spectators: int`, `ready: int`, `local_ready_confirmed: bool`, `remote_client_ready = null`, `local_spectator_confirmed: bool = false` |

`tests/multiplayer_lobby_rpc_contract_smoke.gd` protege decorators, assinaturas,
ordem de payload e o caminho no nó `Main`. Testes de lobby e integração validam
o comportamento do host e do cliente através desses mesmos entrypoints.
