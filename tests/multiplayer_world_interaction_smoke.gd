extends SceneTree

const TIMEOUT_MS := 45000
const FAR_POS := Vector2(180.0, 160.0)
const SHOP_POS := Vector2(920.0, 540.0)

var game: Node
var role := ""
var scenario := "altar"
var relay_host := "127.0.0.1"
var port := 4620
var result_dir := ""
var started_ms := 0
var game_started_ms := 0
var client_ready_sent := false
var host_start_requested := false
var manifestation_selected := false
var aura_selected := false
var henry_effect_opened := false
var henry_ready_sent := false
var final_start_requested := false
var host_fixture_ready := false
var blocked_proved := false
var client_blocked_seen_ms := 0
var shop_dimension_seen := false
var shop_dialogue_seen := false
var shop_open_seen := false
var shop_exit_requested := false
var shop_return_seen := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			role = arg.trim_prefix("--role=")
		elif arg.begins_with("--scenario="):
			scenario = arg.trim_prefix("--scenario=")
		elif arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--host="):
			relay_host = arg.trim_prefix("--host=")
		elif arg.begins_with("--result-dir="):
			result_dir = arg.trim_prefix("--result-dir=")
	if role not in ["server", "host", "client"] or scenario not in ["altar", "shop", "phase8"]:
		_fail("invalid arguments")
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	started_ms = Time.get_ticks_msec()
	call_deferred("_start_role")


func _start_role() -> void:
	game.startup_thanks_done = true
	game.run_tutorial_enabled = false
	game.player_profile_id = "multiplayer-world-interaction-smoke"
	game.player_identity_auth_token = "local-smoke-token"
	game.player_progress_sync_timer = INF
	game.unlocked_manifestation_ids[game.MANIFESTATIONS[1]["key"]] = true
	game.unlocked_spectrum_ids[game.AURAS[1]["key"]] = true
	if role == "server":
		game.dedicated_room_code = "WORLD_INTERACTION_" + scenario.to_upper()
		game._start_dedicated_room_server(port)
	else:
		game.player_nickname = "WorldHost" if role == "host" else "WorldClient"
		game.is_multiplayer = true
		game.is_host = false
		game.online_room_owner = role == "host"
		game.mode = "lobby_online_host" if role == "host" else "lobby_online_client"
		game._connect_to_online_host(relay_host, port)
	call_deferred("_run")


func _run() -> void:
	while Time.get_ticks_msec() - started_ms < TIMEOUT_MS:
		await process_frame
		if role == "server":
			_run_server_step()
		else:
			_run_player_step()
		if _result_exists(role):
			if role != "server" or (_result_exists("host") and _result_exists("client")):
				await _finish()
				return
	_fail("timeout role=%s scenario=%s mode=%s" % [role, scenario, game.mode])


func _run_server_step() -> void:
	if _result_exists("host") and _result_exists("client"):
		_write_result("server", "relay=true")


func _run_player_step() -> void:
	_lobby_and_selection_step()
	if game.mode == "game" and game_started_ms == 0:
		game_started_ms = Time.get_ticks_msec()
	if game_started_ms == 0:
		return
	if role == "host":
		_run_host_interaction_step()
	else:
		_run_client_interaction_step()


func _lobby_and_selection_step() -> void:
	if role == "client" and not client_ready_sent and game.online_connected and game.mode == "lobby_online_client":
		client_ready_sent = true
		game._set_lobby_ready(true)
	if role == "host" and not host_start_requested and game.online_lobby_connected_count == 2 and game.online_lobby_ready_count >= 1:
		host_start_requested = true
		game._send_host_start_request()
	if game.active_character_key == game.CHARACTER_HENRY:
		if game.mode == "mutation_select_mp" and not henry_effect_opened:
			henry_effect_opened = true
			game.selected_mutation = 0
			game.selected_effect = 0
			game._sync_manifest_mp_selection(true)
			game.mode = "effect_select_mp"
			game.manifest_select_stage = game.MANIFEST_STAGE_AURA
			game._sync_manifest_mp_selection(true)
		elif game.mode == "effect_select_mp" and not henry_ready_sent:
			henry_ready_sent = true
			game._toggle_henry_multiplayer_ready()
	else:
		if game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION and not manifestation_selected:
			manifestation_selected = true
			game._set_selected_manifestation(1, false)
			game._confirm_manifest_mp_selection()
		elif game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_AURA and not aura_selected:
			aura_selected = true
			game._set_selected_aura(1, false)
			game._confirm_manifest_mp_selection()
	if role == "host" and aura_selected and not final_start_requested and game._manifest_all_players_ready():
		final_start_requested = true
		game._request_manifest_mp_start()


func _run_host_interaction_step() -> void:
	if game.net_players_by_peer.size() != 1:
		return
	if not host_fixture_ready:
		host_fixture_ready = true
		game.spawn_timer = 9999.0
		game.enemies.clear()
		game.enemy_bullets.clear()
		game.boss_active = false
		game.boss_dead = false
		game.boss_call_timer = -1.0
		if scenario == "altar":
			game.experimental_phase_controller.begin_definitive_phase(game.current_phase)
			game.player_pos = game.experimental_boss_altar_pos
		elif scenario == "shop":
			game.shop_rift_controller.clear_active()
			game.shop_rift_next_allowed_time = INF
			game.shop_rift_controller.spawn("multiplayer_smoke", SHOP_POS)
			game.player_pos = SHOP_POS
		else:
			_prepare_phase8_fixture()
		game.net_world_visual_sync_last_ms = 0
		return
	if scenario == "altar":
		game.player_pos = game.experimental_boss_altar_pos
		if not blocked_proved and game.experimental_phase_controller.altar_present_count == 1 and game.experimental_phase_controller.altar_expected_count == 2:
			_check(game.mode == "game" and game.boss_call_timer < 0.0, "boss started before every living player touched the altar")
			blocked_proved = true
		if blocked_proved and game.mode == "boss_call":
			_write_result("host", "blocked=1/2 committed=2/2 map=expanded")
	elif scenario == "shop":
		game.player_pos = SHOP_POS
		var rift: Dictionary = game.shop_rift_controller.rift()
		if not blocked_proved and int(rift.get("present_count", 0)) == 1 and int(rift.get("expected_count", 0)) == 2:
			_check(game.mode == "game", "shop opened before every living player touched the portal")
			blocked_proved = true
		_run_shop_roundtrip_step()
	else:
		_check(game.current_phase == 8, "host did not enter phase 8")
		_check(game._story().active_id == "" and not game._dialogue().busy(), "host opened multiplayer narrative")
		# Keep the authority alive until the replica proves it received the state.
		if _result_exists("client") and not _result_exists("host"):
			_write_result("host", "phase8=true authority=true enemy=true bullets=true boss_visual=true narrative=false")


func _run_client_interaction_step() -> void:
	if scenario == "altar":
		game.player_pos = FAR_POS
		_check(game.experimental_phase_controller.uses_definitive_world(), "client did not keep the expanded campaign map")
		if client_blocked_seen_ms == 0 and game.experimental_phase_controller.altar_present_count == 1 and game.experimental_phase_controller.altar_expected_count == 2:
			client_blocked_seen_ms = Time.get_ticks_msec()
		if client_blocked_seen_ms == 0 or Time.get_ticks_msec() - client_blocked_seen_ms < 500:
			return
		game.player_pos = game.experimental_boss_altar_pos
		if game.mode == "boss_call":
			_write_result("client", "altar_synced=true boss_call=true")
	elif scenario == "shop":
		if game._merchant_dimension().active:
			_run_shop_roundtrip_step()
			return
		game.player_pos = FAR_POS
		if not shop_open_seen and not game.shop_rift_controller.active():
			return
		var rift: Dictionary = game.shop_rift_controller.rift()
		if client_blocked_seen_ms == 0 and int(rift.get("present_count", 0)) == 1 and int(rift.get("expected_count", 0)) == 2:
			client_blocked_seen_ms = Time.get_ticks_msec()
		if client_blocked_seen_ms == 0 or Time.get_ticks_msec() - client_blocked_seen_ms < 500:
			return
		if not shop_open_seen:
			game.player_pos = Vector2(rift.get("pos", Vector2.ZERO))
		_run_shop_roundtrip_step()
	else:
		if game.current_phase != 8:
			return
		var phase8_enemy_seen := false
		for enemy_value in game.enemies:
			if enemy_value is Dictionary and String(enemy_value.get("type", "")) == RTSertaoController.CANGACEIRO:
				phase8_enemy_seen = String(enemy_value.get("s8_state", "")) == "rajada_aim"
				break
		if not phase8_enemy_seen or game.sertao_controller.bullets.is_empty():
			return
		if game.boss8_controller.mode != "gnomon" or not game.boss8_controller.shadow_on:
			return
		_check(game._story().active_id == "" and not game._dialogue().busy(), "client opened multiplayer narrative")
		_write_result("client", "phase8=true replica=true enemy=true bullets=true boss_visual=true narrative=false")


func _prepare_phase8_fixture() -> void:
	game.current_phase = 8
	game.experimental_phase_controller.begin_definitive_phase(8)
	game.sertao_controller.reset()
	game.boss8_controller.reset()
	game.enemies = [{
		"uid": 88001, "type": RTSertaoController.CANGACEIRO, "pos": Vector2(660, 440),
		"hp": 900.0, "max_hp": 900.0, "phase": 0.0, "s8_state": "rajada_aim",
		"s8_t": 0.5, "s8_flash": 0.4, "s8_aim": Vector2.RIGHT,
	}]
	game.sertao_controller.shoot(Vector2(1000, 700), Vector2.RIGHT, 0.0, RTSertaoController.COL_SUN, {"delay": 30.0, "owner": 88001})
	game.boss8_controller.mode = "gnomon"
	game.boss8_controller.anim = "sun"
	game.boss8_controller.stage = 3
	game.boss8_controller.shadow_on = true
	game.boss8_controller.shadow_angle = 1.0
	game.boss8_controller.sun_power = 0.8
	game.boss_active = false
	game.boss_dead = false
	game.boss_pos = Vector2(820, 460)
	game.boss_hp = 1000.0
	game.boss_hp_max = 1000.0
	game.boss_name = "CASCO-DE-SOL"
	game.net_world_sync_last_ms = 0
	game.net_world_visual_sync_last_ms = 0


func _run_shop_roundtrip_step() -> void:
	var dimension: RTMerchantDimension = game._merchant_dimension()
	if dimension.active:
		shop_dimension_seen = true
		var dialogue: RTDialogueController = game._dialogue()
		if dialogue.busy():
			shop_dialogue_seen = true
			dialogue.grace = 0.0
			dialogue.revealed = 99999.0
			dialogue.advance_input()
			return
		if not dimension.talked_this_visit:
			game.player_pos = RTMerchantDimension.MERCHANT_POS
			return
		if not shop_open_seen and game.mode == "game":
			# Multiplayer skips narrative; the first approach opens the real counter.
			game.player_pos = RTMerchantDimension.MERCHANT_POS
			return
	if game.mode == "shop":
		shop_open_seen = true
	if shop_open_seen and not shop_exit_requested:
		shop_exit_requested = true
		game.shop_controller.request_exit_or_finish()
	if game.mode == "shop_return":
		shop_return_seen = true
	if shop_return_seen and game.mode == "game" and dimension.active:
		game.player_pos = RTMerchantDimension.EXIT_PORTAL_POS
		return
	if not shop_return_seen or game.mode != "game" or dimension.active:
		return
	_check(shop_dimension_seen, "player never entered the Merchant Dimension")
	_check(not shop_dialogue_seen, "merchant narrative opened in multiplayer")
	_check(shop_open_seen, "merchant counter did not open the shop")
	_check(game.online_connected, "relay connection was lost after leaving the shop")
	_check(game._multiplayer_peer_active(), "multiplayer peer became inactive after leaving the shop")
	_check(not game.shop_rift_controller.active(), "merchant rift stayed active after the shop roundtrip")
	var detail := "dimension=true dialogue=false counter=true group_exit=true connected=true"
	if role == "host":
		detail += " blocked=1/2 committed=2/2 portal=authoritative"
	else:
		detail += " rift_synced=true"
	_write_result(role, detail)


func _result_path(result_role: String) -> String:
	if result_dir != "":
		return result_dir.path_join("world_interaction_%s_%s_result.txt" % [scenario, result_role])
	return "res://tests/world_interaction_%s_%s_result.txt" % [scenario, result_role]


func _result_exists(result_role: String) -> bool:
	return FileAccess.file_exists(_result_path(result_role))


func _write_result(result_role: String, detail: String) -> void:
	if _result_exists(result_role):
		return
	var file := FileAccess.open(_result_path(result_role), FileAccess.WRITE)
	_check(file != null, "could not write result for " + result_role)
	file.store_string("OK " + detail)
	file.close()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	push_error("MULTIPLAYER_WORLD_INTERACTION_FAIL %s/%s %s" % [scenario, role, message])
	quit(1)


func _finish() -> void:
	print("MULTIPLAYER_WORLD_INTERACTION_OK scenario=%s role=%s" % [scenario, role])
	if role == "server":
		# The production server owns its asynchronous room shutdown. Let that
		# lifecycle finish instead of freeing the Main node under its await.
		return
	var barrier_deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < barrier_deadline and not (_result_exists("host") and _result_exists("client")):
		await process_frame
	var settle_frames := 12 if role == "client" else 54
	for _frame in range(settle_frames):
		await process_frame
	if is_instance_valid(game):
		game._leave_multiplayer()
		for _frame in range(4):
			await process_frame
		game._cleanup_runtime_resources()
		if game.music_player != null:
			game.music_player.stop()
			game.music_player.stream = null
		if game.rain_audio_player != null:
			game.rain_audio_player.stop()
			game.rain_audio_player.stream = null
		for player in game.sfx_players:
			if player != null:
				player.stop()
				player.stream = null
		game.audio_streams.clear()
		game.textures.clear()
		root.remove_child(game)
		game.free()
		game = null
	for _frame in range(8):
		await process_frame
	quit(0)
