extends SceneTree

## QA visual rapido da Parasitica nova: Simbiose ativa, hospedeiros com larvas
## (um Maduro) e Verme-Rei atacando.

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.forced_initial_phase = 1
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.boss_ready = true
	game.manifestation_key = "parasitica"
	game.selected_manifestation = 4
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(700, 500)
	game.enemies.clear()
	var seeds := [5, 3, 2]
	var i := 0
	for pos in [Vector2(430, 330), Vector2(840, 310), Vector2(1050, 520)]:
		game._spawn_enemy(game.ENEMY_COMMON, pos)
		var enemy = game.enemies[game.enemies.size() - 1]
		enemy["hp"] = 900.0
		enemy["max_hp"] = 900.0
		enemy["speed"] = 0.0
		enemy["seeds"] = seeds[i]
		enemy["parasite_mark_time"] = game.PARASITE_MARK_DURATION
		i += 1
	var ctl: RTParasiticaController = game._parasitica()
	game.last_skill_time = -999.0
	game._use_skill()
	ctl.hunger = 8
	game.enemies[1]["seeds"] = 4
	game.last_secondary_time = -999.0
	game._use_secondary_skill()
	assert(ctl.sym_active and ctl.king_active())
	for f in range(20):
		game.time_alive += 1.0 / 30.0
		ctl.update(1.0 / 30.0)
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
