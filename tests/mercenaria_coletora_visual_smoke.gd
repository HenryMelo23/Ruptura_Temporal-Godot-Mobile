extends SceneTree

var game: Node


func _card(name: String) -> Dictionary:
	for card in game.CARDS:
		if card["name"] == name:
			return card
	return {}


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game._apply_card(_card("Mercenaria"))
	game._apply_card(_card("Coletora"))
	game.combo_kills = 4
	game.mercenary_bonus_points = 130
	game.mercenary_hud_pulse = 0.7
	game.collector_hud_pulse = 0.7
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(260, 0))
	game.enemies[0]["max_hp"] = 1000.0
	game.enemies[0]["hp"] = 54.0
	game.enemies[0]["speed"] = 0.0
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	await process_frame
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	assert(image.save_png("res://.codex/mercenaria_coletora_qa_1280x720.png") == OK)
	print("MERCENARIA_COLETORA_VISUAL_OK " + ProjectSettings.globalize_path("res://.codex/mercenaria_coletora_qa_1280x720.png"))
	quit(0)
