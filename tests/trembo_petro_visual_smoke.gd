extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _card(name: String) -> Dictionary:
	for card in game.CARDS:
		if card["name"] == name:
			return card
	return {}


func _run() -> void:
	game._start_game()
	game.player_pos = Vector2(800, 450)
	game._apply_card(_card("Trembo"))
	for i in range(5):
		game._apply_card(_card("Petro"))
	game.trembo_pos = game.player_pos + Vector2(76, 18)
	game.trembo_facing = "down"
	game.petro_pos = game.player_pos + Vector2(-120, 28)
	game.petro_facing = "right"
	game.petro_hp = game.petro_hp_max * 0.72
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(250, -40))
	game.enemies[0]["speed"] = 0.0
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	await process_frame
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	assert(image.save_png("res://.codex/trembo_petro_qa_1280x720.png") == OK)
	print("TREMBO_PETRO_VISUAL_OK " + ProjectSettings.globalize_path("res://.codex/trembo_petro_qa_1280x720.png"))
	quit(0)
