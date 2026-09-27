extends SceneTree

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _peer(dead: bool = false) -> Dictionary:
	return {"pos": Vector2(900, 430), "hp": 0.0 if dead else 450.0, "hp_max": 450.0, "dead": dead, "has_snapshot": true, "name": "ALIADO"}


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	root.size = Vector2i(1280, 720)
	game.set_process(false)
	game.startup_thanks_done = true
	game.startup_thanks_timer = 0.0
	game.ui_platform_override_unlocked = true
	game.ui_platform_override = "android"
	game.run_tutorial_enabled = false
	game.vol_master = 0.0
	game._start_game()
	_test_layout()
	_test_progression()
	_test_death_and_votes()
	await _test_revive_touch()
	_test_hit_audio()
	_test_music()
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("MOBILE_MULTIPLAYER_REGRESSIONS_OK saved_gameplay_layout=true touch_revive=true kill_growth=true death_phases=7 living_votes=true silent_impacts=true music=true")
	quit(0 if failures.is_empty() else 1)


func _test_layout() -> void:
	var config_path := "user://hud_config.save"
	var had_config := FileAccess.file_exists(config_path)
	var original := FileAccess.get_file_as_bytes(config_path) if had_config else PackedByteArray()
	var viewport := Vector2(1280, 720)
	game._open_edit_layout(viewport)
	game.hud_attack_pos = Vector2(760, 500)
	game.hud_secondary_pos = Vector2(920, 510)
	game.hud_dash_pos = Vector2(1060, 510)
	game.hud_skill_pos = Vector2(790, 450)
	game.hud_attack_scale = 1.3
	game._update_button_layout(viewport)
	var expected: Rect2 = game.buttons["attack"]
	game._save_config()
	game.hud_attack_pos = Vector2.ZERO
	game.hud_attack_scale = 1.0
	game.hud_skill_pos = Vector2(-1, -1)
	game._load_config()
	game._start_game()
	game._update_button_layout(viewport)
	_check(game.buttons["attack"] == expected, "saved position/scale was replaced on entering gameplay")
	if had_config:
		var file := FileAccess.open(config_path, FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(config_path)


func _test_progression() -> void:
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = false
	game.enemies_killed = 0
	game.player_damage = 30.0
	var expected := 30.0
	for kills in range(1, 301):
		expected += 0.06 * (1.0 + int(kills / 10) * 0.1)
		if kills % 17 == 0 or kills == 300:
			game._apply_remote_boss_visual_snapshot({"team_kills": kills})
			game._apply_remote_boss_visual_snapshot({"team_kills": kills})
	_check(is_equal_approx(game.player_damage, expected), "client passive damage growth differs from host or duplicates")
	game.player_damage += 12.0
	game._apply_remote_boss_visual_snapshot({"team_kills": 299})
	_check(is_equal_approx(game.player_damage, expected + 12.0), "old snapshot overwrote damage/card progress")
	game._apply_remote_boss_visual_snapshot({})
	_check(game.enemies_killed == 300, "legacy packet reset kill progress")
	game.is_host = true
	_check(game._pack_net_boss_visuals().get("team_kills") == 300, "host omitted kill progress from packet")


func _test_death_and_votes() -> void:
	game.online_connected = false
	game.online_lobby_connected_count = 2
	game.online_lobby_active_player_count = 2
	game.dedicated_names_by_peer = {42: "HOST", 43: "CLIENT"}
	game.dedicated_spectator_by_peer = {42: false, 43: false}
	game.dedicated_room_owner_peer_id = 42
	for phase in range(1, 8):
		game.current_phase = phase
		game.mode = "game"
		game.dedicated_server_mode = true
		game._dedicated_store_player_state(42, _peer(false))
		game._dedicated_store_player_state(43, _peer(true))
		_check(game._dedicated_all_peers_voted({42: true}), "dead client blocks consensus in phase %d" % phase)
		game._dedicated_store_player_state(43, _peer(false))
		_check(not game._dedicated_all_peers_voted({42: true}), "revived client missing from consensus")
		game._dedicated_store_player_state(43, _peer(true))
		_check(game._dedicated_all_peers_voted({42: true}), "second death blocks consensus")
		game.dedicated_server_mode = false
		game.net_players_by_peer = {43: _peer(false)}
		game.is_dead = true
		game.player_hp = 0.0
		_check(not game._finish_multiplayer_defeat_if_all_dead(), "ended while teammate is alive")
		game._store_remote_player_state(43, _peer(true))
		_check(game.mode == "game_over", "all-dead snapshot failed to end phase %d" % phase)
		game.mode = "game"
		game._update_game(0.0)
		_check(game.mode == "game_over", "all-dead recovery check failed")
	game.is_dead = false
	game.player_hp = 450.0


func _test_revive_touch() -> void:
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.is_host = true
	game.dedicated_server_mode = false
	game.online_connected = false
	game._clear_team_revival_state()
	game.net_players_by_peer = {43: _peer(true)}
	game._start_team_revival_for_dead(43, Vector2(900, 430), "ALIADO", false)
	for fragment in game.revival_fragments.duplicate(true):
		game.player_pos = fragment["pos"]
		game._collect_revival_fragment(fragment["id"], game._mp_unique_id())
	game.player_pos = game.revival_altar_points_pos
	game.score = game._revival_points_cost()
	game.ui_platform_override = "android"
	game.hud_attack_pos = Vector2.ZERO
	game.hud_secondary_pos = Vector2.ZERO
	game.hud_dash_pos = Vector2.ZERO
	game.hud_skill_pos = Vector2(-1, -1)
	game.hud_attack_scale = 1.0
	game._update_button_layout(Vector2(root.size))
	game.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png("res://.agent_logs/mobile_revive_1280x720.png") == OK, "revive capture failed")
		root.size = Vector2i(960, 540)
		game._update_button_layout(Vector2(root.size))
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png("res://.agent_logs/mobile_revive_960x540.png") == OK, "small revive capture failed")
	# Input must work even before a draw or after another overlay rebuilt its buttons.
	game.buttons.erase("revival_mobile")
	var touch := InputEventScreenTouch.new()
	touch.index = 4
	touch.position = game.buttons["attack"].get_center()
	touch.pressed = true
	game._unhandled_input(touch)
	_check(game.revival_active, "first tap spent revival cost without confirmation")
	touch.pressed = false
	game._unhandled_input(touch)
	touch.pressed = true
	game._unhandled_input(touch)
	touch.pressed = false
	game._unhandled_input(touch)
	_check(not game.revival_active and game.score == 0, "two touch events did not revive teammate")
	_check(not game.net_players_by_peer[43]["dead"], "revived teammate remains dead")


func _test_hit_audio() -> void:
	game.vol_master = 1.0
	game.vol_sfx = 1.0
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	for manifestation in ["eletrica", "prismatica", "lacerante", "parasitica", "retornante", "gravitante", "ancorada", "eclipsada", "bombastica", "necronada", "cartografica", "mnesica", "ressonante", "contratual", "acorrentada"]:
		game._play_enemy_hit_sfx({"uid": 17, "type": game.ENEMY_COMMON}, manifestation)
	for key in ["Inimigo1_hit.wav", "Inimigo3_hit.mp3", "Hit_Boss1.mp3", "eletrica_hit", "acorrentada_hit_1", "acorrentada_hit_2", "acorrentada_hit_3"]:
		game._play_sfx(key)
	for player in game.sfx_players:
		_check(not player.playing and player.stream == null, "enemy impact still played audio")


func _test_music() -> void:
	game.is_multiplayer = false
	game.is_dead = false
	game.boss_active = false
	game.gfx_memory_saver = true
	game.vol_music = 0.8
	game.mode = "game"
	var heard: Dictionary = {}
	var tracks: Array = game._shared_phase_music_tracks()
	_check(tracks.size() >= 20, "Sounds playlist is incomplete")
	game.phase_music_bag.clear()
	for index in range(tracks.size()):
		var previous: String = game.current_music
		game._play_phase_music_random(1 + index % 7)
		game._finish_music_crossfade()
		game._update_music_pause_fade(2.0)
		_check(game.music_player.stream != null and game.music_player.playing, "track is silent: " + game.current_music)
		_check(game.music_player.volume_db > -40.0, "track volume is inaudible")
		_check(previous != game.current_music, "adjacent track repeated")
		heard[game.current_music] = true
	_check(heard.size() == tracks.size(), "shuffle repeated before all tracks played")
	var previous: String = game.current_music
	game._on_music_finished()
	_check(game.current_music != previous, "finished callback did not rotate music")
	for phase in range(1, 8):
		previous = game.current_music
		game._advance_to_phase(phase)
		game._finish_music_crossfade()
		game._update_music_pause_fade(2.0)
		_check(game.current_music != previous and tracks.has(game.current_music), "phase transition did not rotate Sounds music")
		_check(game.music_player.stream != null and game.music_player.playing and game.music_player.volume_db > -40.0, "phase transition left inaudible music")
