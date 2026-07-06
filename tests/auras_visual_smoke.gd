extends SceneTree

var game: Node

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	assert(image.save_png("res://.codex/aura_" + name.to_lower() + ".png") == OK)

func _arm_visual(name: String) -> void:
	match name:
		"Racional": game.aura_state["rational_dilation"] = 8.0
		"Impulsiva":
			game.aura_state["impulsive_active"] = 4.0
			game.aura_state["impulsive_rank"] = 2
		"Devota": game.aura_state["devoted_charges"] = 2
		"Vanguarda":
			game.aura_state["vanguard_ring"] = 5.0
			game.enemies[0]["aura_burn"] = 7.0
		"Insana": game.aura_state["insane_queue"] = [{"pos": game.player_pos + Vector2(110, 0), "dir": Vector2.RIGHT, "delay": 1.0}]
		"Voraz":
			game.aura_state["voracious_hunger"] = 72.0
			game.aura_state["voracious_drops"] = [{"pos": game.player_pos + Vector2(100, 40), "life": 6.0, "value": 28.0}]
		"Nula":
			game.aura_state["null_charge"] = 100.0
			game.aura_state["null_armed"] = true
			game.enemies[0]["aura_null"] = 4.0
		"Abissal": game.aura_state["abyss_tide"] = 5.0
		"Profetica":
			game.aura_state["prophecy_uid"] = int(game.enemies[0]["uid"])
			game.aura_state["prophecy_time"] = 6.0
			game.enemies[0]["aura_prophecy"] = 6.0
		"Sanguinaria":
			game.aura_state["blood_thirst"] = 76.0
			game.enemies[0]["aura_wound"] = 7.0

func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	for index in range(game.AURAS.size()):
		game.selected_aura = index
		game._start_game()
		game.spawn_timer = 999.0
		game.enemies[0]["speed"] = 0.0
		game.enemies[0]["pos"] = game.player_pos + Vector2(210, -30)
		var name := String(game.AURAS[index]["name"])
		_arm_visual(name)
		game.queue_redraw()
		await process_frame
		await process_frame
		_save(name)
	print("AURAS_VISUAL_SMOKE_OK captures=10 viewport=1280x720")
	quit(0)
