extends SceneTree

const OUTPUT := "res://.codex/sanguinaria_hunt_path_hud_1280x720.png"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("SANGUINARIA_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var aura_index := -1
	for index in range(game.AURAS.size()):
		if String(game.AURAS[index].get("name", "")) == "Sanguinaria":
			aura_index = index
			break
	_check(aura_index >= 0, "Sanguinaria aura missing")
	game.selected_aura = aura_index
	game.selected_manifestation = 0
	game._start_game()
	game.mode = "game"
	game.vol_master = 0.0
	game.qa_streaming_enabled = false
	game.is_multiplayer = false
	game.player_pos = Vector2(640, 390)
	game.time_alive = 34.0
	game.spawn_timer = 999.0
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(245, -78))
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(-190, 68))
	for enemy in game.enemies:
		enemy["speed"] = 0.0
		enemy["hp"] = 800.0
		enemy["max_hp"] = 800.0
		enemy["stun"] = 999.0
	var hunted: Dictionary = game.enemies[0]
	game.aura_state["blood_thirst"] = 62.0
	game.aura_state["blood_combo"] = 4
	game.aura_state["blood_hunt_uid"] = int(hunted.get("uid", -1))
	game.aura_state["blood_hunt_rule"] = "hab1"
	game.aura_state["blood_hunt_quadrant"] = -1
	game.aura_state["blood_reward_text"] = "+DANO"
	game.aura_state["blood_grace"] = 0.0
	hunted["sanguinaria_hunt"] = true
	game.sanguinaria_hunt_notice_timer = 2.0
	game.set_process(false)
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid capture")
	_check(image.get_used_rect().size.x > 1000 and image.get_used_rect().size.y > 600, "blank capture")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	_check(image.save_png(OUTPUT) == OK, "could not save screenshot")
	print("SANGUINARIA_VISUAL_OK path=", ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	quit(0)
