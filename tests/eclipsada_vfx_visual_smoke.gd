extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ECLIPSADA_VFX_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var manifestation_index := -1
	for index in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[index].get("key", "")) == "eclipsada":
			manifestation_index = index
			break
	_check(manifestation_index >= 0, "manifestation missing")
	game.selected_manifestation = manifestation_index
	game.selected_aura = 0
	game._start_game()
	game.mode = "game"
	game.manifestation_key = "eclipsada"
	game.vol_master = 0.0
	game.qa_streaming_enabled = false
	game.is_multiplayer = false
	game.player_pos = Vector2(640, 390)
	game.last_facing = Vector2.RIGHT
	game.attack_dragging = true
	game.attack_drag_direction = Vector2.RIGHT
	game.time_alive = 20.0
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(710, 390))
	game.enemies[0]["hp"] = 900.0
	game.enemies[0]["max_hp"] = 900.0
	game.enemies[0]["stun"] = 999.0
	game.set_process(false)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))

	game._try_attack()
	await _capture("eclipsada_atk_1280x720.png")

	game.last_skill_time = -999.0
	game._use_skill(game.player_pos + Vector2.RIGHT * 100.0)
	await _capture("eclipsada_q_1280x720.png")

	game.eclipsada_stealth_timer = 0.0
	game.last_secondary_time = -999.0
	game._use_secondary_skill(Vector2(game.enemies[0]["pos"]))
	game._update_eclipsada_state(0.08)
	await _capture("eclipsada_e_1280x720.png")

	print("ECLIPSADA_VFX_VISUAL_OK atk=true q=true e=true")
	game.queue_free()
	await process_frame
	quit(0)


func _capture(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid capture " + file_name)
	_check(image.get_used_rect().size.x > 1000 and image.get_used_rect().size.y > 600, "blank capture " + file_name)
	var output := "res://.codex/" + file_name
	_check(image.save_png(output) == OK, "could not save " + file_name)
