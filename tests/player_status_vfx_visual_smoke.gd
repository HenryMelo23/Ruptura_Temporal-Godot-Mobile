extends SceneTree

const OUTPUT := "res://.agent_logs/player_status_vfx"
var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _capture(label: String) -> Image:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	if capture.save_png(OUTPUT + "/" + label + ".png") != OK:
		failed = true
	return capture


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	game._start_game(false)
	game._reset_tutorial_state()
	game.set_process(false)
	game.set_physics_process(false)
	game.startup_thanks_done = true
	game.mode = "game"
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 400
	game.player_hp = 270
	game.hud_feedback.reset(game)
	game.player_run_xp = 250
	game.time_alive = 12.0
	game.aura_state = {"name": "Impulsiva", "impulsive_kills": 3}
	game.revive_heal_penalty_timer = 12.0
	game.reserva_pulso_stored = 90.0
	game.mandamento_skill_uses = 2
	game.impulso_charges = 2
	game.folego_charge = 0.7
	game.ressonancia_ready_timer = 3.0
	game.paradox_charge_hits = 3
	game.cards_bought["Mercenaria"] = 1
	game.cards_bought["mandamento_ruptura"] = 1
	game.cards_bought[game.CARD_TREGUA_ID] = 1
	game.cards_bought[game.CARD_ESTASE_ID] = 1
	game.combo_kills = 3
	game.tregua_regenerativa_timer = 1.0
	game.estase_reparadora_timer = 2.0
	root.content_scale_size = Vector2i.ZERO
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = viewport
		game.ui_platform_override_unlocked = true
		game.ui_platform_override = "desktop" if viewport.x == 1280 else "android"
		for manifestation in ["ancorada", "acorrentada", "bombastica", "necronada"]:
			game.manifestation_key = manifestation
			game.lastro_stacks = 3
			game.lastro_points = 2
			game.acorrentada_tension = 75.0
			game.acorrentada_combo_step = 2
			game.necronada_horde_progress = 3
			await _capture("%d_%s" % [viewport.x, manifestation])
		game.gfx_low_resource = true
		await _capture("%d_lightweight" % viewport.x)
		game.gfx_low_resource = false
		game.manifestation_key = "ancorada"
		var early := await _capture("%d_motion_start" % viewport.x)
		game.time_alive += 0.5
		var later := await _capture("%d_motion_end" % viewport.x)
		var player_screen: Vector2 = game.player_pos - game._camera(Vector2(viewport))
		var effect_region := Rect2i(Vector2i(player_screen) - Vector2i(60, 65), Vector2i(120, 130))
		_check(early.get_region(effect_region).get_data() != later.get_region(effect_region).get_data(), "status effects must animate")
		for level in range(1, 11):
			game.player_run_level = level
			game.player_run_xp = int(game._player_run_level_controller().xp_to_next() / 2)
			var capture := await _capture("%d_xp_%d" % [viewport.x, level])
			var origin := Vector2(18, 16) if viewport.x == 1280 else Vector2(game._left_panel_pos(Vector2(viewport)))
			var width := 252.0 if viewport.x == 1280 else 212.0
			var head := Vector2i(origin + Vector2(12 + width * 0.25, 101))
			var tail := Vector2i(origin + Vector2(12 + width * 0.75, 101))
			_check(capture.get_pixelv(head).b > 0.65, "XP fill missing at level %d" % level)
			_check((capture.get_pixelv(tail).b > 0.65) == (level == 10), "XP ratio incorrect at level %d" % level)
		game.player_run_level = 1
		game.player_run_xp = 250
		game.contractual_order = {"label": "CUMPRIR SENTENCA", "progress": 3, "goal": 8, "time_left": 15.0, "real_age": game.CONTRACT_ORDER_EXECUTION_START_TIME + 1.0}
		game.contractual_order_rewards = {"damage": 8.0}
		game.contractual_order_penalties = {"speed": 5.0}
		await _capture("%d_contract" % viewport.x)
		game.contractual_order.clear()
		game.contractual_order_rewards.clear()
		game.contractual_order_penalties.clear()
		game.is_dead = true
		await _capture("%d_dead" % viewport.x)
		game.is_dead = false
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	print("PLAYER_STATUS_VFX_VISUAL_OK" if not failed else "PLAYER_STATUS_VFX_VISUAL_FAIL")
	quit(1 if failed else 0)
