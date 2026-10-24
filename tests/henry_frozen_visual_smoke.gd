extends SceneTree

var game: Node
var failures: Array[String] = []
var baseline := "--baseline" in OS.get_cmdline_user_args()


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _capture(label: String, size := Vector2i(1280, 720)) -> void:
	if DisplayServer.get_name() == "headless":
		return
	root.size = size
	root.content_scale_size = size
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	_check(capture != null and capture.get_size() == size, "invalid capture: " + label)
	if capture != null:
		var prefix := "before_" if baseline else ""
		_check(capture.save_png("res://.agent_logs/henry_frozen_%s%s_%dx%d.png" % [prefix, label, size.x, size.y]) == OK, "capture save failed")


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs"))
	game.active_character_key = game.CHARACTER_HENRY
	game.run_tutorial_enabled = false
	game._start_game()
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.set_process(false)
	game.mode = "game"
	game.current_phase = 2
	game._prepare_phase_texture_assets(2)
	game.phase_started_at = 0.0
	game.time_alive = 20.0
	game.player_pos = Vector2(800, 450)
	game.henry_entry_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.last_attack_time = -99.0
	game.last_damage_time = -99.0
	game.run_retry_invulnerability_timer = 0.0
	game.player_control_immunity_timer = 0.0
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.boss_call_tutorial_seen = true
	game.shop_tutorial_seen = true
	game.unlock_notifications.clear()
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.geovana_bark_controller.active_text = ""
	game.geovana_bark_controller.active_timer = 0.0
	game.gfx_screen_shake = false
	game.vol_master = 0.0
	await _capture("idle")
	game._apply_phase2_projectile_freeze()
	_check(game.player_freeze_visual_timer > 0.0, "phase-2 projectile did not freeze Henry")
	await _capture("frame_0")
	if baseline:
		await _finish()
		return
	var frames: Array = game.textures.get("henry_frozen", [])
	_check(frames.size() == 2, "expected two dedicated Henry frozen frames")
	if frames.size() != 2:
		await _finish()
		return
	_check(game._player_texture() == frames[0], "phase-2 freeze is not visible locally")
	_check(game._network_player_animation_snapshot(0) == Vector2i(game.NET_ANIM_FROZEN, 0), "freeze not transmitted")
	var sheet: Image = frames[0].atlas.get_image()
	# The generated alpha includes a few 1/255 edge pixels; allow float rounding.
	_check(sheet != null and sheet.get_pixel(887, 400).a <= 0.004 and sheet.get_pixel(0, 0).a <= 0.004, "atlas does not have transparent background")
	for frame_index in range(2):
		game.player_freeze_visual_timer = game.player_freeze_visual_duration - float(frame_index) * 0.75
		_check(game._player_texture() == frames[frame_index], "wrong local frozen frame")
		var snapshot: Vector2i = game._network_player_animation_snapshot(0)
		_check(snapshot == Vector2i(game.NET_ANIM_FROZEN, frame_index), "wrong frozen network frame")
		_check(game._net_player_texture_for_state(snapshot.x, snapshot.y, game.HENRY_SELECTION_INDEX) == frames[frame_index], "remote Henry selected wrong texture")
		_check(game._net_player_texture_for_state(snapshot.x, snapshot.y, -1, "incendiario") == frames[frame_index], "remote character hint selected wrong texture")
		game.net_player_manifestation = game.HENRY_SELECTION_INDEX
		game.net_player_anim_state = snapshot.x
		game.net_player_frame_idx = snapshot.y
		_check(game._net_player_texture() == frames[frame_index], "legacy remote Henry selected wrong texture")
		await _capture("frame_%d" % frame_index)
	# Frozen presentation must win over queued movement, damage and cast poses.
	game.move_touch_index = 1
	game.touch_move = Vector2(-1, -1).normalized()
	game.last_damage_time = game.time_alive
	game.henry_skill_cast_active = true
	game.henry_ultimate_cast_active = true
	_check(game._player_texture() == frames[1], "cast overrode frozen local sprite")
	_check(game._network_player_animation_snapshot(0).x == game.NET_ANIM_FROZEN, "cast overrode frozen network state")
	_check(not game._should_flip_player_sprite(), "frozen pose flips with movement input")
	game.henry_skill_cast_active = false
	game.henry_ultimate_cast_active = false
	game.is_multiplayer = true
	game.net_players_by_peer[2] = {
		"pos": game.player_pos + Vector2(140, 0), "render_pos": game.player_pos + Vector2(140, 0),
		"name": "Henry remoto", "hp": 100.0, "hp_max": 100.0, "dead": false, "has_snapshot": true,
		"anim_state": game.NET_ANIM_FROZEN, "frame_idx": 0,
		"manifestation": game.HENRY_SELECTION_INDEX, "manifestation_key": "incendiario",
		"input_move": game.touch_move, "flip_h": true,
	}
	_check(game._remote_player_state_targetable(game.net_players_by_peer[2]), "remote fixture is not drawable")
	await _capture("local_remote")
	await _capture("mobile", Vector2i(800, 450))
	game.is_multiplayer = false
	game.net_players_by_peer.clear()
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO
	game.last_damage_time = -99.0
	game.spawn_timer = 999.0
	game.boss_ready = true
	# Let the actual game update expire the effect and return to normal animation.
	game.player_freeze_visual_timer = 0.01
	game._update_game(0.02)
	_check(game.player_freeze_visual_timer == 0.0, "freeze timer did not expire")
	_check(not frames.has(game._player_texture()), "Henry stayed frozen after expiration")
	_check(game._network_player_animation_snapshot(0).x != game.NET_ANIM_FROZEN, "remote freeze stuck after expiration")
	await _capture("thawed")
	# The shared freeze entry point also serves phase-2 boss abilities.
	game.player_control_immunity_timer = 0.0
	game._freeze_player(game.BOSS2_FLASH_FREEZE_STUN)
	_check(game._player_texture() == frames[0], "boss freeze did not select Henry sprite")
	game.active_character_key = game.CHARACTER_GEOVANA
	game.manifestation_key = "prismatica"
	_check(game._player_texture() == game.textures["player_frozen"][0], "Geovana frozen sprite regressed")
	await _finish()


func _finish() -> void:
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	for failure in failures:
		printerr("HENRY_FROZEN_FAIL " + failure)
	if failures.is_empty():
		print("HENRY_FROZEN_BASELINE_OK" if baseline else "HENRY_FROZEN_OK phase2=true frames=2 priority=true local_remote=true thaw=true geovana=true")
	quit(0 if failures.is_empty() else 1)
