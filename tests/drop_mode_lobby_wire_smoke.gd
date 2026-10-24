extends "res://tests/multiplayer_lobby_integration_smoke.gd"

var last_mode_request_ms := 0
var client_rejected_change := false
var observed_drop_mode := false


func _result_path(result_role: String) -> String:
	if result_dir != "":
		return result_dir.path_join("drop_mode_%s_result.txt" % result_role)
	return "res://.codex/drop_mode_wire_%s.txt" % result_role


func _run() -> void:
	while Time.get_ticks_msec() - started_ms < TIMEOUT_MS:
		await process_frame
		if role == "host":
			_run_drop_host_step()
		elif role == "client":
			_run_drop_client_step()
		else:
			_run_drop_server_step()
		if _result_exists(role) and (role == "server" or _result_exists("server")):
			print("DROP_MODE_LOBBY_WIRE_OK role=%s mode_observed=%s host_only=true synced=true" % [role, game.RUN_MODE_DROP if observed_drop_mode else "missing"])
			await _finish()
			return
	_fail("drop mode timeout role=%s selected=%s" % [role, game.selected_run_mode])


func _run_drop_host_step() -> void:
	if not game.online_connected or game.online_lobby_connected_count != 2:
		return
	var now_ms := Time.get_ticks_msec()
	if game.selected_run_mode != game.RUN_MODE_DROP or now_ms - last_mode_request_ms >= 500:
		last_mode_request_ms = now_ms
		game._request_lobby_run_mode(game.RUN_MODE_DROP)
	if game.selected_run_mode == game.RUN_MODE_DROP:
		observed_drop_mode = true
		_write_result(role)


func _run_drop_client_step() -> void:
	if not game.online_connected or game.selected_run_mode != game.RUN_MODE_DROP:
		return
	game._request_lobby_run_mode(game.RUN_MODE_SHOP)
	client_rejected_change = game.selected_run_mode == game.RUN_MODE_DROP
	if client_rejected_change:
		observed_drop_mode = true
		_write_result(role)


func _run_drop_server_step() -> void:
	if game.dedicated_room_owner_peer_id == 0 or game.selected_run_mode != game.RUN_MODE_DROP:
		return
	observed_drop_mode = true
	if _result_exists("host") and _result_exists("client"):
		_write_result(role)


func _state_summary() -> String:
	return "%s selected_mode=%s observed_drop=%s" % [super._state_summary(), game.selected_run_mode, str(observed_drop_mode)]
