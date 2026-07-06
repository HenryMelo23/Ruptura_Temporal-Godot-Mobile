extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game._advance_to_phase(2)
	game.player_pos = Vector2(720, 470)
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_PYRO_PENGUIN, Vector2(960, 360))
	var pyro: Dictionary = game.enemies[0]
	pyro["shoot_cd"] = 0.0
	game._update_pyro_penguin(pyro, 0.01)
	for i in range(12):
		game._add_phase2_fire_wall_tile(Vector2(420 + i * 32, 430 + i * 6))
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output := "res://.codex/phase2_pyro_penguin_qa_1280x720.png"
	assert(image.save_png(output) == OK)
	print("PHASE2_PYRO_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
