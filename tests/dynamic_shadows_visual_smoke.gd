extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._advance_to_phase(3)
	game.gfx_shadows = true
	game.boss_ready = true
	game.player_pos = Vector2(650, 520)
	game.enemies.clear()
	game.effects.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(400, 340))
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(560, 300))
	game._spawn_enemy(game.ENEMY_INCENSARIO, Vector2(850, 330))
	game._spawn_enemy(game.ENEMY_GUARDIAO, Vector2(1040, 470))
	game.enemies[0]["facing_dir"] = Vector2.RIGHT
	game.enemies[1]["facing_dir"] = Vector2.LEFT
	game.enemies[2]["facing_dir"] = Vector2.RIGHT
	game.enemies[3]["facing_dir"] = Vector2.LEFT
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 8200.0
	game.boss_hp = 8200.0
	game.boss_pos = Vector2(760, 430)
	game._spawn_boss3_cheese(Vector2(930, 590), true, 38.0, 12.0, false)
	game.effects.clear()
	game.queue_redraw()
	await process_frame
	await process_frame
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output = "res://.codex/dynamic_shadows_qa_1280x720.png"
	assert(image.save_png(output) == OK)
	print("DYNAMIC_SHADOWS_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
