extends SceneTree

const OUTPUT_DIR := "res://.agent_logs"

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _capture(label: String, size: Vector2i) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	root.min_size = Vector2i.ZERO
	root.content_scale_size = Vector2i.ZERO
	DisplayServer.window_set_size(size)
	root.size = size
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.get_size() == size, "invalid screenshot " + label)
	if image != null and not image.is_empty():
		var output := ProjectSettings.globalize_path("%s/amber_suturer_%s_%dx%d.png" % [OUTPUT_DIR, label, size.x, size.y])
		_check(image.save_png(output) == OK, "could not save " + output)


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.boss_call_tutorial_seen = true
	game.shop_tutorial_seen = true
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.current_phase = 6
	game.phase_started_at = 0.0
	game.time_alive = 0.0
	game.boss_active = false
	game.boss_dead = false
	game.boss_ready = false
	game.boss_call_timer = -1.0
	game.phase_transition_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(780, 470)
	game.geovana_bark_controller.active_text = ""
	game.geovana_bark_controller.active_timer = 0.0
	game.geovana_bark_controller.next_ambient_at = INF
	game.unlock_notifications.clear()
	game.enemies.clear()
	game._prepare_phase_texture_assets(6)
	var controller = game.amber_suturer_controller
	controller.reset_for_new_run()
	game.time_alive = controller.FIRST_SPAWN_TIME - 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "visual fixture spawned Suturador before its timer")
	game.time_alive = controller.FIRST_SPAWN_TIME + 0.1
	controller.update(0.0)
	var enemy: Dictionary = controller.active_enemy()
	_check(not enemy.is_empty(), "timed phase-6 path could not spawn Suturador")
	var atlas: Texture2D = game.textures.get("enemy_phase_6_suturador_ambar")
	_check(atlas != null and atlas.get_size() == Vector2(896, 864), "Suturador sprite sheet is missing or malformed")
	enemy["pos"] = Vector2(510, 410)
	await _capture("timed_entry", Vector2i(1280, 720))
	controller._history_by_peer = {0: [{"time": 203.8, "pos": Vector2(470, 470)}, {"time": 204.9, "pos": Vector2(780, 470)}]}
	controller._begin_suture_cycle(enemy)
	var nodes: Array = game.enemies.filter(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_AMBER_SUTURE_NODE)
	_check(nodes.size() == 4, "visual cycle did not expose four crystals")
	await _capture("telegraph", Vector2i(1280, 720))
	await _capture("telegraph", Vector2i(960, 540))
	controller._activate_sutures(enemy)
	await _capture("active", Vector2i(1280, 720))
	await _capture("active", Vector2i(960, 540))
	enemy["suturer_state_timer"] = controller.CROSSFIRE_TRIGGER_REMAINING - 0.01
	controller._update_active_sutures(0.01, enemy)
	await _capture("crystal_crossfire", Vector2i(1280, 720))
	enemy["hp"] = float(enemy.get("max_hp", 1.0)) * 0.65
	enemy["suturer_state_timer"] = controller.REPAIR_TRIGGER_REMAINING - 0.01
	controller._update_active_sutures(0.01, enemy)
	await _capture("amber_repair", Vector2i(1280, 720))
	var first_node: Dictionary = nodes.front()
	var first_suture_id := String(first_node.get("suture_id", ""))
	var partner_uid := int(Dictionary(nodes.filter(func(value): return String(Dictionary(value).get("suture_id", "")) == first_suture_id)[1]).get("uid", -1))
	first_node["hp"] = 0.0
	game._kill_enemy(first_node)
	_check(game.enemies.any(func(value): return int(Dictionary(value).get("uid", -2)) == partner_uid), "visual break deleted the partner crystal")
	_check(int(enemy.get("suturer_crystal_slow_stacks", 0)) == 1, "visual slow meter fixture did not receive a stack")
	await _capture("crystal_slow", Vector2i(1280, 720))
	game.gfx_low_resource = true
	await _capture("crystal_slow_mobile_low", Vector2i(960, 540))
	game.gfx_low_resource = false
	controller._clear_sutures("visual_fixture", false)
	game.amber_suturer_visual_events.clear()
	controller._begin_needle_cycle(enemy, false)
	await _capture("needle_fan_telegraph", Vector2i(1280, 720))
	controller._fire_needle_attack(enemy)
	game._update_enemy_bullets(0.22)
	await _capture("needle_fan_fire", Vector2i(1280, 720))
	await _capture("needle_fan_fire", Vector2i(960, 540))
	game.enemy_bullets.clear()
	game.amber_suturer_visual_events.clear()
	controller._begin_hook_cycle(enemy)
	await _capture("hook_telegraph", Vector2i(1280, 720))
	await _capture("hook_telegraph", Vector2i(960, 540))
	controller._fire_hook(enemy)
	game._update_enemy_bullets(0.22)
	await _capture("hook_fire", Vector2i(1280, 720))
	await _capture("hook_fire", Vector2i(960, 540))
	game.enemy_bullets.clear()
	game.amber_suturer_visual_events.clear()
	game.cards_bought["Disparo crescente"] = 1
	game._recalculate_common_card_stat_bonuses()
	controller._steal_card_from_peer(game._mp_unique_id())
	await _capture("card_stolen", Vector2i(1280, 720))
	await _capture("card_stolen", Vector2i(960, 540))
	controller.restore_local_card("Disparo crescente")
	game.amber_suturer_state["stolen_cards"] = []
	game.amber_suturer_visual_events.clear()
	controller._begin_needle_cycle(enemy, true)
	await _capture("needle_burst_telegraph", Vector2i(1280, 720))
	controller._fire_needle_attack(enemy)
	game._update_enemy_bullets(0.22)
	await _capture("needle_burst_fire", Vector2i(1280, 720))
	await _capture("needle_burst_fire", Vector2i(960, 540))
	controller.on_enemy_defeated(enemy)
	game.enemies.erase(enemy)
	await _capture("death_cleanup", Vector2i(1280, 720))
	# The visual fixture jumps the phase clock instead of processing real frames;
	# expire the first encounter's transient title and echoes before proving the
	# later recurrence.
	game._update_effects(3.0)
	controller._update_visual_events(3.0)
	game.unlock_notifications.clear()
	var recurrence_time := float(game.amber_suturer_state.get("next_spawn_phase_time", INF))
	game.time_alive = recurrence_time + 0.1
	controller.update(0.0)
	var recurring_enemy: Dictionary = controller.active_enemy()
	_check(not recurring_enemy.is_empty(), "timed recurrence path could not respawn Suturador")
	if not recurring_enemy.is_empty():
		recurring_enemy["pos"] = Vector2(620, 405)
	await _capture("recurrence_entry", Vector2i(1280, 720))

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _frame in range(3):
		await process_frame
	if not failures.is_empty():
		for failure in failures:
			printerr("PHASE6_AMBER_SUTURER_VISUAL_FAIL " + failure)
		quit(1)
		return
	print("PHASE6_AMBER_SUTURER_VISUAL_OK captures=23 nodes=4 armor_meter=true crossfire=true repair=true mobile_low=true timed_spawn=true recurrence=true sprite=true telegraph=true active=true hook=true cleanup=true")
	quit(0)
