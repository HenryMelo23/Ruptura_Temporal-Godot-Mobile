extends SceneTree

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game(false)
	game._reset_tutorial_state()
	game.set_process(false)
	game.startup_thanks_done = true
	game.mode = "game"
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 400
	game.player_hp = 270
	game.hud_feedback.reset(game)
	root.content_scale_size = Vector2i.ZERO
	var directory := "res://.agent_logs/health_barbed_wire"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = viewport
		game.ui_platform_override_unlocked = true
		game.ui_platform_override = "desktop" if viewport.x == 1280 else "android"
		var clear_pixels := PackedByteArray()
		for state in ["clear", "active", "expired", "calcified", "lightweight"]:
			game.revive_heal_penalty_timer = 12.0 if state in ["active", "lightweight"] else 0.0
			game.current_phase = 6 if state == "calcified" else 1
			game.boss6_necro_erosion_active = state == "calcified"
			game.boss6_necro_erosion_timer = 10.0 if state == "calcified" else 0.0
			game.boss6_necro_erosion_radius = 80.0
			game.boss_pos = game.player_pos + Vector2(300.0, 0.0)
			game.gfx_low_resource = state == "lightweight"
			game.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var capture := root.get_texture().get_image()
			var pixels := capture.get_region(Rect2i(30, 47, 200, 16)).get_data()
			if state == "clear":
				clear_pixels = pixels
			elif state == "expired":
				if pixels != clear_pixels:
					push_error("Wire remains after healing penalty expires")
					failed = true
			elif state in ["active", "calcified"] and pixels == clear_pixels:
				push_error("Missing anti-heal wire: " + state)
				failed = true
			var path := "%s/%d_%s.png" % [directory, viewport.x, state]
			if capture.save_png(path) != OK:
				failed = true
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	print("HEALTH_BARBED_WIRE_VISUAL_OK" if not failed else "HEALTH_BARBED_WIRE_VISUAL_FAIL")
	quit(1 if failed else 0)
