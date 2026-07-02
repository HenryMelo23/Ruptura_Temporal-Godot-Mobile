extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.boss_ready = true
	game.manifestation_key = "parasitica"
	game.selected_manifestation = 4
	game.player_pos = Vector2(700, 500)
	game.enemies.clear()
	for pos in [Vector2(430, 330), Vector2(840, 310), Vector2(1050, 520)]:
		game._spawn_enemy(game.ENEMY_COMMON, pos)
		var enemy = game.enemies[game.enemies.size() - 1]
		enemy["hp"] = 900.0
		enemy["max_hp"] = 900.0
		enemy["seeds"] = 4
		enemy["parasite_mark_time"] = 6.0
	game._spawn_secondary_parasitica()
	var secondary = game.manifestation_secondaries[0]
	secondary["targets"][0]["arrived"] = true
	secondary["targets"][0]["feed_left"] = 7.2
	secondary["targets"][0]["age"] = 2.2
	secondary["targets"][1]["age"] = 0.82
	secondary["targets"][2]["age"] = 1.34
	game.effects.clear()

	game._spawn_enemy(game.ENEMY_COMMON, Vector2(610, 250))
	var marked = game.enemies[game.enemies.size() - 1]
	marked["hp"] = 900.0
	marked["max_hp"] = 900.0
	marked["seeds"] = 5
	marked["parasite_mark_time"] = 5.4
	game.parasite_spit_zones.append({
		"state": "active",
		"origin": game.player_pos,
		"target": Vector2(760, 560),
		"age": 0.0,
		"travel": game.PARASITE_SPIT_TRAVEL,
		"life": 4.0,
		"max": game.PARASITE_SPIT_DURATION,
		"tick": 0.3,
		"phase": 1.7,
		"infected": {}
	})

	game.queue_redraw()
	await process_frame
	await process_frame
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output = "res://.codex/parasitica_qa_1280x720.png"
	assert(image.save_png(output) == OK)
	print("PARASITICA_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
