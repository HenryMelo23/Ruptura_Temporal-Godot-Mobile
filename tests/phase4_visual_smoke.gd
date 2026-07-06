extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game._advance_to_phase(4)
	game.player_pos = Vector2(620, 520)
	game.boss_active = true
	game.boss_entry_timer = 0.0
	game.boss_pos = game.boss4_entry_target
	game.boss_hp = game.boss_hp_max * 0.72
	game._spawn_boss4_planet()
	game.phase4_planets[0]["pos"] = Vector2(890, 430)
	game._add_phase4_null_zone(Vector2(440, 330))
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(320, 560))
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(1040, 610))
	game.enemies[0]["shoot_cd"] = 0.0
	game._update_phase4_enemy(game.enemies[0], 0.01)
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output := "res://.codex/phase4_qa_1280x720.png"
	assert(image.save_png(output) == OK)
	print("PHASE4_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
