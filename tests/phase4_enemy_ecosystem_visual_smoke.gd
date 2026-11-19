extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(960, 540) if "--low" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.current_phase = 4
	game._prepare_phase_texture_assets(4)
	game.mode = "game"
	var viewport_size := Vector2(root.size)
	game.player_pos = Vector2(960, 540)
	game.enemies.clear()
	game.phase4_enemy_hazards.clear()
	var kinds = [game.ENEMY_NEXUS_CARTOGRAPHER, game.ENEMY_NEXUS_CHRONOPHAGE, game.ENEMY_NEXUS_REFRACTOR, game.ENEMY_NEXUS_WEAVER, game.ENEMY_NEXUS_ECHO]
	var camera: Vector2 = Vector2(game.player_pos) - viewport_size * 0.5
	for i in range(kinds.size()):
		var screen_x := viewport_size.x * (0.12 + float(i) * 0.19)
		for frame_index in range(2):
			var screen_y := viewport_size.y * (0.31 if frame_index == 0 else 0.70)
			game._spawn_enemy(String(kinds[i]), camera + Vector2(screen_x, screen_y))
			var enemy: Dictionary = game.enemies.back()
			enemy["phase"] = float(frame_index)
			enemy["facing_dir"] = Vector2.RIGHT
			enemy["nexus_cast_cd"] = 999.0
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := game.get_viewport().get_texture().get_image()
	assert(image != null and image.get_size() == root.size)
	var suffix := "960x540" if root.size == Vector2i(960, 540) else "1280x720"
	var output := "res://.codex/phase4_enemy_species_stride_%s.png" % suffix
	assert(image.save_png(output) == OK)
	print("PHASE4_ECOSYSTEM_VISUAL_OK species=5 frames=2 stride_swap=true size=%s capture=%s" % [suffix, ProjectSettings.globalize_path(output)])
	quit(0)
