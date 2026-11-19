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
var shop_transition_seen: Dictionary = {}
var aftermath_sent := false
var aftermath_voted := false
var chip_drop_sent := false
var chip_rift_spawned := false
var chip_redeemed := false
var phase9_events_sent := false
var phase9_last_press_frame := -10
var phase9_escape_sent := false


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
	if role not in ["server", "host", "client"] or scenario not in ["altar", "shop", "phase8", "phase9", "aftermath", "chips"]:
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
		if scenario == "chips":
			game._quantum_chips().selected.clear()
			game._quantum_chips().random_mode = role == "host"
			if role == "host":
				for chip_id in [RTQuantumChipController.CORRUPTOR, RTQuantumChipController.SEDENTA, RTQuantumChipController.GANANCIA]:
					game._quantum_chips().selected[chip_id] = true
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
		if scenario == "aftermath":
			game.current_phase = 1
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
		elif scenario in ["aftermath", "chips"]:
			game.spawn_timer = 99999.0
			game.player_pos = FAR_POS
		elif scenario == "phase9":
			_prepare_phase9_fixture()
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
		if game._rift_transition().busy():
			_run_shop_roundtrip_step()
			return
		game.player_pos = SHOP_POS
		var rift: Dictionary = game.shop_rift_controller.rift()
		if not blocked_proved and int(rift.get("present_count", 0)) == 1 and int(rift.get("expected_count", 0)) == 2:
			_check(game.mode == "game", "shop opened before every living player touched the portal")
			blocked_proved = true
		_run_shop_roundtrip_step()
	elif scenario == "aftermath":
		_run_aftermath_step()
	elif scenario == "chips":
		_run_chips_step()
	elif scenario == "phase9":
		_run_phase9_host_step()
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
		if game._rift_transition().busy():
			_run_shop_roundtrip_step()
			return
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
	elif scenario == "aftermath":
		_run_aftermath_step()
	elif scenario == "chips":
		_run_chips_step()
	elif scenario == "phase9":
		_run_phase9_client_step()
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


func _prepare_phase9_fixture() -> void:
	game.current_phase = RTCriptaController.PHASE
	game.experimental_phase_controller.begin_definitive_phase(game.current_phase)
	game.cripta_controller.reset()
	game.player_pos = FAR_POS
	var cr: RTCriptaController = game.cripta_controller
	for lamp in cr.lamps:
		lamp["on"] = false
		lamp["life"] = 60.0
	cr.lamps[2]["on"] = true
	cr.echoes = [{"pos": Vector2(900, 700), "t": 0.0, "uid": 991}]
	cr.echo_timer = 999.0
	cr.threads = [{"a": Vector2(700, 700), "b": Vector2(900, 700), "t": 0.0, "life": 60.0, "hp": 3}]
	game._spawn_enemy(RTCriptaGrapple.BOLEADEIRA, Vector2(1200, 900))
	game.boss9_controller.mode = "olhar"
	game.boss9_controller.anim = "gaze"
	game.boss9_controller.stage = 2
	game.boss9_controller.beam_angle = 1.2
	game.net_world_sync_last_ms = 0
	game.net_world_visual_sync_last_ms = 0


func _run_phase9_host_step() -> void:
	if not _result_exists("client_phase9_seen"):
		return
	var cr: RTCriptaController = game.cripta_controller
	var peer_id: int = int(game.net_players_by_peer.keys()[0])
	var enemy: Dictionary = game.enemies[0]
	if not phase9_events_sent:
		var peer_pos: Vector2 = Vector2(Dictionary(game.net_players_by_peer[peer_id]).get("pos", FAR_POS))
		if peer_pos.distance_to(game.player_pos) < 200.0:
			return
		phase9_events_sent = true
		cr.echoes = [{"pos": peer_pos + Vector2(0, 30), "t": 0.0, "uid": 992}]
		cr._update_echoes(0.0)
		_check(cr.echoes.is_empty() and cr.echoes_taken == 1, "client did not collect the authoritative Echo")
		cr.grapple._held[peer_id] = int(enemy["uid"])
		enemy["gp"] = peer_id
		enemy["cr_state"] = "drag"
		enemy["cr_t"] = 0.0
		game._send_peer_phase9_event(peer_id, "grab", float(enemy["uid"]), Vector2(enemy["pos"]))
		return
	if not _result_exists("client_phase9_escaped"):
		return
	if int(enemy.get("gp", -1)) != 0 or not cr.threads.is_empty() or not cr.echoes.is_empty():
		return
	_write_result("host", "phase9=true visual=true echo=collected grab_escape=true thread=broken")


func _run_phase9_client_step() -> void:
	var cr: RTCriptaController = game.cripta_controller
	game.player_pos = SHOP_POS
	if not _result_exists("client_phase9_seen"):
		if game.current_phase != RTCriptaController.PHASE or cr.echoes.is_empty() or cr.threads.is_empty():
			return
		if not bool(cr.lamps[2].get("on", false)) or game.boss9_controller.mode != "olhar":
			return
		_check(game._story().active_id == "" and not game._dialogue().busy(), "phase 9 opened multiplayer narrative")
		game.player_hp = game.player_hp_max / 2
		_write_result("client_phase9_seen", "world=true boss=true narrative=false")
		return
	if not phase9_escape_sent:
		if not cr.grapple.held() or cr.sight_stacks < 1:
			return
		var frame: int = Engine.get_process_frames()
		if frame - phase9_last_press_frame > 1:
			phase9_last_press_frame = frame
			game._try_attack()
		if cr.grapple.held():
			return
		_check(game.player_hp > game.player_hp_max / 2, "authoritative echo did not heal the client")
		phase9_escape_sent = true
		for _shot in range(3):
			_check(cr.bullet_hit(Vector2(800, 700)), "replica could not hit the silk thread")
		_write_result("client_phase9_escaped", "echo=true escape=true thread_hits=3")
		return
	if _result_exists("host") and cr.threads.is_empty() and cr.echoes.is_empty():
		_write_result("client", "phase9=true visual=true echo=collected grab_escape=true thread=broken")


func _run_aftermath_step() -> void:
	var choice: RTRunChoiceController = game._run_choice()
	if role == "host" and not aftermath_sent and _result_exists("client_prepared"):
		aftermath_sent = true
		game.boss_dead = true
		game.boss_active = false
		var event: Dictionary = choice.begin_multiplayer_boss("pact")
		game._spawn_phase_fragment(Vector2(2800, 2000), 2)
		game.rpc("_rpc_boss_aftermath", int(event["epoch"]), 1, game.phase_fragment.duplicate(true), "pact", Array(event["offer"]))
		game._phase_flow()._request_phase_mp_consensus(2)
		_check(not game.phase_mp_request_outgoing, "portal advanced before team pact vote")
	if role == "client" and not _result_exists("client_prepared"):
		_write_result("client_prepared", "phase=1")
	if not choice.mp_pending:
		if aftermath_voted and choice.multiplayer_ready() and game._boss_pacts().taken.size() == 1:
			_check(game._boss_pacts().taken[0] == choice.mp_offer_ids[0], "pact tie was not resolved in favor of host vote")
			_check(not game.phase_fragment.is_empty(), "post-boss portal was not replicated")
			_write_result(role, "pact=%s fragment=true vote=true" % game._boss_pacts().taken[0])
		return
	if choice.pending_kind != "":
		choice.pending_timer = 0.0
		if game.mode == "game":
			choice.update(0.1)
	if game.mode == "run_choice" and not aftermath_voted:
		_check(choice.options.size() == 3, "team pact offer did not contain three cards")
		_check(not game.phase_fragment.is_empty(), "post-boss portal is absent during choice")
		choice.select(0 if role == "host" else 1)
		choice.confirm()
		aftermath_voted = true


func _run_chips_step() -> void:
	var chips: RTQuantumChipController = game._quantum_chips()
	for id in [RTQuantumChipController.CORRUPTOR, RTQuantumChipController.SEDENTA, RTQuantumChipController.GANANCIA, RTQuantumChipController.MULTIDAO]:
		_check(chips.is_active(id), "team chip missing: " + id)
	_check(chips.random_rolled == RTQuantumChipController.MULTIDAO, "random chip differs between host and client")
	_check(game.player_hp_max == chips.apply_hp_max(game.PLAYER_BASE_HP), "Sedenta max HP differs from host config")
	_check(is_equal_approx(chips.damage_multiplier(), 6.0) and is_equal_approx(chips.points_multiplier(), 2.0), "team chip effects did not activate")
	if role == "host":
		if not chip_drop_sent:
			chip_drop_sent = true
			var peer_id: int = int(game.net_players_by_peer.keys()[0])
			var peer_pos: Vector2 = Vector2(Dictionary(game.net_players_by_peer[peer_id]).get("pos", FAR_POS))
			game.arauto_card_drops.append({"drop_id": "chip_wire_drop", "owner_peer": peer_id, "card": game.CARDS[0], "pos": peer_pos, "vel": Vector2.ZERO, "life": 30.0, "age": 0.0, "mystery": true, "mystery_rarity": "common"})
			game.net_world_visual_sync_last_ms = 0
		if chips.team_token_total() == 1 and _result_exists("client_token") and not chip_rift_spawned:
			game.time_alive = 1000.0
			game.arauto.clear()
			game.shop_last_exit_time = 0.0
			game.shop_rift_next_allowed_time = 0.0
			if game._local_player_controls_locked():
				return
			_check(game.shop_rift_controller._should_spawn(), "client token did not make Rift eligible: mode=%s boss=%s call=%.2f arauto=%s locked=%s tutorial=%s allowed=%.2f now=%.2f exit=%.2f corruptor=%s tokens=%d" % [game.mode, str(game.boss_active), game.boss_call_timer, str(game._arauto_active()), str(game._local_player_controls_locked()), str(game._tutorial_blocks_normal_spawn()), game.shop_rift_next_allowed_time, game.time_alive, game.shop_last_exit_time, str(chips.corruptor_active()), chips.team_token_total()])
			game.shop_rift_controller.spawn("multiplayer_smoke", SHOP_POS)
			game.shop_rift_next_allowed_time = INF
			chip_rift_spawned = true
	elif chips.token_total() == 1 and not _result_exists("client_token"):
		game.rpc_id(1, "_rpc_request_quantum_token", "chip_wire_drop", game._mp_unique_id())
		_check(chips.token_total() == 1, "duplicate token confirmation credited twice")
		_write_result("client_token", "token=1 duplicate=safe")
	_run_chip_shop_roundtrip_step(chips)


func _run_chip_shop_roundtrip_step(chips: RTQuantumChipController) -> void:
	if game._rift_transition().busy():
		shop_transition_seen[game._rift_transition().phase] = true
		return
	var dimension: RTMerchantDimension = game._merchant_dimension()
	if not dimension.active and not shop_dimension_seen:
		if game.shop_rift_controller.active():
			game.player_pos = Vector2(game.shop_rift_controller.rift().get("pos", SHOP_POS))
		return
	if dimension.active:
		shop_dimension_seen = true
		if role == "client" and not chip_redeemed:
			if game.mode == RTCorruptorShop.MODE:
				_check(chips.token_total() == 1, "Corruptor shop lost the confirmed token")
				game._corruptor_shop().pick()
				chip_redeemed = true
				_check(chips.token_total() == 0, "Corruptor shop did not consume the token")
				return
			if game.mode == "game":
				game.player_pos = RTMerchantDimension.MERCHANT_POS
			return
		if role == "host" and chips.team_token_total() > 0:
			return
		if role == "client" and not chip_redeemed:
			return
		if game.mode == "game":
			game.player_pos = RTMerchantDimension.EXIT_PORTAL_POS
		return
	if not shop_dimension_seen or game.mode != "game" or game.shop_rift_controller.active():
		return
	for phase in [RTMerchantRiftTransition.PHASE_DIVE, RTMerchantRiftTransition.PHASE_LAND, RTMerchantRiftTransition.PHASE_EXIT_DIVE, RTMerchantRiftTransition.PHASE_EMERGE]:
		_check(bool(shop_transition_seen.get(phase, false)), "missing chip Rift transition: " + phase)
	_check(game.online_connected and game._multiplayer_peer_active(), "Corruptor shop disconnected the relay")
	_check(not game.shop_rift_controller.active(), "chip Rift stayed active after exit")
	if role == "host":
		_check(chips.team_token_total() == 0, "remote token was not redeemed on authority")
	else:
		_check(chip_redeemed, "client did not pick the Corruptor card")
	_write_result(role, "config=4 random=multidao token=1 duplicate=safe rift=true redeemed=true transition=4 connected=true")


func _run_shop_roundtrip_step() -> void:
	if game._rift_transition().busy():
		shop_transition_seen[game._rift_transition().phase] = true
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
	if not shop_return_seen or game.mode != "game" or dimension.active or game._rift_transition().busy():
		return
	for phase in [RTMerchantRiftTransition.PHASE_DIVE, RTMerchantRiftTransition.PHASE_LAND, RTMerchantRiftTransition.PHASE_EXIT_DIVE, RTMerchantRiftTransition.PHASE_EMERGE]:
		_check(bool(shop_transition_seen.get(phase, false)), "missing multiplayer Rift animation: " + phase)
	_check(shop_dimension_seen, "player never entered the Merchant Dimension")
	_check(not shop_dialogue_seen, "merchant narrative opened in multiplayer")
	_check(shop_open_seen, "merchant counter did not open the shop")
	_check(game.online_connected, "relay connection was lost after leaving the shop")
	_check(game._multiplayer_peer_active(), "multiplayer peer became inactive after leaving the shop")
	_check(not game.shop_rift_controller.active(), "merchant rift stayed active after the shop roundtrip")
	var detail := "dimension=true dialogue=false counter=true group_exit=true transition=4 connected=true"
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
