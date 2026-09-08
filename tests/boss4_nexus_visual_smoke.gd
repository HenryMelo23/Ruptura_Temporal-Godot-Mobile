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
	game.boss4_instability = 62.0
	game._spawn_boss4_comet()
	game._start_boss4_secondary()
	game.boss4_meteor_event_started = false
	game.boss4_meteor_event_timer = 0.0
	game._update_boss4_meteorites(0.01)
	game._update_boss4_meteorites(game.BOSS4_METEOR_WARNING + 0.04)
	game._update_boss4_meteorites(game.BOSS4_METEOR_ARM_TIME + 0.04)
	game._start_boss4_ultimate()
	game._update_boss4_ultimate(0.01)
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output := "res://.codex/boss4_nexus_rework_1280x720.png"
	assert(image.save_png(output) == OK)
	print("BOSS4_NEXUS_REWORK_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
