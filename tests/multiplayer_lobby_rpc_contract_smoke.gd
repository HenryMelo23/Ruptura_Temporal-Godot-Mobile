extends SceneTree

const CORE_PATH := "res://scripts/main_runtime_core.gd"
const MAIN_SCENE := "res://scenes/Main.tscn"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MULTIPLAYER_LOBBY_RPC_CONTRACT_SMOKE_FAIL: " + message)
	quit(1)


func _require_contract(source: String, rpc_config: String, signature: String) -> void:
	_check(source.contains(rpc_config + "\n" + signature), "RPC contract drifted for " + signature)


func _initialize() -> void:
	var source := FileAccess.get_file_as_string(CORE_PATH)
	_check(not source.is_empty(), "could not read Main RPC owner")
	var client_rpc := '@rpc("any_peer", "call_remote", "reliable", 3)'
	var authority_rpc := '@rpc("authority", "call_remote", "reliable", 3)'
	_require_contract(source, client_rpc, "func _toggle_ready(ready: bool) -> void :")
	_require_contract(source, client_rpc, "func _toggle_ready_v2(ready: bool, sequence: int) -> void:")
	_require_contract(source, authority_rpc, "func _online_lobby_ready_ack(sequence: int, confirmed_ready: bool, accepted: bool, room_code: String = \"\") -> void:")
	_require_contract(source, authority_rpc, "func _online_start_ack(sequence: int, accepted: bool, reason: String = \"\") -> void:")
	_require_contract(source, authority_rpc, "func _online_lobby_state(room_code: String, connected: int, ready: int) -> void :")
	_require_contract(source, authority_rpc, "func _online_lobby_roster(roster: Array) -> void:")
	_require_contract(source, authority_rpc, "func _online_lobby_state_v2(room_code: String, connected: int, ready: int, local_ready_confirmed: bool, remote_client_ready = null) -> void :")
	_require_contract(source, authority_rpc, "func _online_lobby_state_v3(room_code: String, connected: int, active_players: int, spectators: int, ready: int, local_ready_confirmed: bool, remote_client_ready = null, local_spectator_confirmed: bool = false) -> void :")
	game = load(MAIN_SCENE).instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	_check(String(game.get_path()) == "/root/Main", "lobby RPC node path must remain /root/Main")
	_check(game.lobby_controller != null, "lobby controller was not created")
	for handler in [
		"apply_lobby_ready_request",
		"apply_online_lobby_ready_ack",
		"apply_online_start_ack",
		"apply_online_lobby_state",
		"apply_online_lobby_roster",
		"apply_online_lobby_state_v2",
		"apply_online_lobby_state_v3"
	]:
		_check(game.lobby_controller.has_method(handler), "missing delegated lobby handler: " + handler)
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for _frame in range(3):
		await process_frame
	print("MULTIPLAYER_LOBBY_RPC_CONTRACT_SMOKE_OK rpc_count=8 path=/root/Main ready_handshake=true")
	quit(0)
