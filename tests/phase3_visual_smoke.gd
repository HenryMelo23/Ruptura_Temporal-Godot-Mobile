extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._advance_to_phase(3)
	game.player_pos = Vector2(720, 560)
	game.boss_active = true
	game.boss_hp_max = 8200.0
	game.boss_hp = 5600.0
	game.boss_entry_timer = 0.0
	game.boss_pos = Vector2(800, 390)
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(500, 360))
	game._spawn_enemy(game.ENEMY_INCENSARIO, Vector2(1030, 480))
	game._spawn_enemy(game.ENEMY_GUARDIAO, Vector2(1180, 300))
	game._add_phase3_miasma(Vector2(560, 400), 86.0, 3.5, 0.015)
	game._spawn_boss3_cheese(Vector2(950, 610), true, 38.0, 12.0, false)
	game.boss_attacks.append({"kind": "rat_charge", "age": 0.2, "duration": 1.55, "warn": 0.70, "dir": Vector2(-1, 0), "hit": false})
	game.queue_redraw()
	await process_frame
	await process_frame
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output = "res://.codex/phase3_qa_1280x720.png"
	assert(image.save_png(output) == OK)
	print("PHASE3_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
