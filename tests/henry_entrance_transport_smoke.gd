extends "res://tests/multiplayer_ability_visual_smoke.gd"

var party := 2
var client_index := 1

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--party="):
			party = clampi(int(arg.trim_prefix("--party=")), 2, 3)
		elif arg.begins_with("--client-index="):
			client_index = clampi(int(arg.trim_prefix("--client-index=")), 1, 2)
	super._initialize()

func all_clients(suffix: String) -> bool:
	for i in range(1, party):
		if not exists("client_%s_%d" % [suffix, i]):
			return false
	return true

## Run server/host/client with the same --port. Reuses the real relay handshake,
## world visual RPC and teardown; markers are isolated by port for repeat runs.
func marker(suffix: String) -> String:
	return "user://henry_entry_%d_%s.txt" % [port, suffix]

func mark(suffix: String) -> void:
	var file := FileAccess.open(marker(suffix), FileAccess.WRITE)
	file.store_string("OK")

func exists(suffix: String) -> bool:
	return FileAccess.file_exists(marker(suffix))

func _run_server() -> void:
	var deadline := Time.get_ticks_msec() + 65000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if exists("host_done") and all_clients("done"):
			print("HENRY_ENTRANCE_TRANSPORT_OK role=relay")
			mark("server_done")
			await _finish()
			return
	_fail("Henry relay timeout")

func _run_host() -> void:
	var deadline := Time.get_ticks_msec() + 65000
	var started := false
	var saw_frozen := false
	var frozen_positions: Dictionary = {}
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if not started and game.online_connected and all_clients("ready"):
			started = true
			var file := FileAccess.open(marker("client_id_1"), FileAccess.READ)
			var client_id := int(file.get_as_text())
			game.active_character_key = game.CHARACTER_GEOVANA
			game.run_tutorial_enabled = false
			game.forced_initial_phase = 1
			game.mp_manifest_state_by_peer = {client_id: {"manifestation": game.HENRY_SELECTION_INDEX}}
			game._start_game()
			game.mode = "game"
			game._finish_startup_thanks()
			_check(game.henry_incendiary_ability_controller.entrance_active, "host Geovana did not pause for client Henry")
			mark("start")
		if not started:
			continue
		var owner = game.henry_incendiary_ability_controller
		if owner.entrance_active and owner.entrance_world_speed() == 0.0:
			_check(game.time_alive == 0.0, "host combat clock advanced in cinematic")
			for enemy in game.enemies:
				var uid := int(enemy["uid"])
				if frozen_positions.has(uid):
					_check(Vector2(enemy["pos"]) == frozen_positions[uid], "authority moved enemy during freeze")
				frozen_positions[uid] = Vector2(enemy["pos"])
			saw_frozen = true
		if saw_frozen and not owner.entrance_active and all_clients("done"):
			print("HENRY_ENTRANCE_TRANSPORT_OK role=host frozen_enemies=%d" % frozen_positions.size())
			mark("host_done")
			while not exists("server_done") and Time.get_ticks_msec() < deadline:
				await process_frame
			await _finish()
			return
	_fail("Henry host timeout")

func _run_client() -> void:
	var deadline := Time.get_ticks_msec() + 65000
	var started := false
	var announced := false
	var saw_frozen := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.online_connected and not announced:
			announced = true
			var file := FileAccess.open(marker("client_id_%d" % client_index), FileAccess.WRITE)
			file.store_string(str(game._mp_unique_id()))
			file.close()
			mark("client_ready_%d" % client_index)
		if announced and not started and exists("start"):
			started = true
			game.active_character_key = game.CHARACTER_HENRY if client_index == 1 else game.CHARACTER_GEOVANA
			var file := FileAccess.open(marker("client_id_1"), FileAccess.READ)
			game.mp_manifest_state_by_peer = {int(file.get_as_text()): {"manifestation": game.HENRY_SELECTION_INDEX}}
			game.run_tutorial_enabled = false
			game.forced_initial_phase = 1
			game._start_game()
			game.mode = "game"
			game._finish_startup_thanks()
		if not started:
			continue
		var owner = game.henry_incendiary_ability_controller
		if owner.entrance_active and owner.entrance_world_speed() == 0.0:
			_check(game._local_player_controls_locked(), "client controls unlocked in frozen interval")
			_check(game.time_alive == 0.0, "client combat clock advanced in cinematic")
			saw_frozen = true
		if saw_frozen and owner.entrance_finished and not owner.entrance_active:
			_check(game.net_world_visual_last_sequence >= 0, "release did not arrive through world visual transport")
			print("HENRY_ENTRANCE_TRANSPORT_OK role=client%d sequence=%d released=true" % [client_index, game.net_world_visual_last_sequence])
			mark("client_done_%d" % client_index)
			while not exists("server_done") and Time.get_ticks_msec() < deadline:
				await process_frame
			await _finish()
			return
	_fail("Henry client timeout")
