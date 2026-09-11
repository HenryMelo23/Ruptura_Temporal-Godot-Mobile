extends SceneTree

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE7_MOBILE_PERFORMANCE_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame

	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.current_phase = 7
	game.gfx_low_resource = true
	game.gfx_memory_saver = false
	game.gfx_particles = true
	game._apply_graphics_settings()
	game.player_pos = Vector2(640, 420)
	game.enemies.clear()
	game.effects.clear()
	game.slashes.clear()
	game.phase7_ember_patches.clear()

	_check(game._phase7_visual_budget_enabled(), "phase 7 should use lean visuals in low resource mode")
	_check(game._phase7_ember_patch_cap() == game.PHASE7_EMBER_PATCH_LOW_CAP, "low resource ember patch cap mismatch")

	for i in range(96):
		var offset: Vector2 = Vector2(float((i % 16) * 8), float((i / 16) * 7))
		game._add_phase7_ember_patch(Vector2(280, 260) + offset, 10.0)
	_check(game.phase7_ember_patches.size() <= game.PHASE7_EMBER_PATCH_LOW_CAP, "ember patches exceeded low resource cap")

	game.phase7_ember_patches.clear()
	game._add_phase7_ember_patch(Vector2(500, 360), 10.0)
	var before_merge_count: int = game.phase7_ember_patches.size()
	game._add_phase7_ember_patch(Vector2(508, 367), 99.0)
	_check(game.phase7_ember_patches.size() <= before_merge_count, "near ember patch was not merged")

	var start_us: int = Time.get_ticks_usec()
	for frame in range(900):
		game._update_phase7_ember_patches(1.0 / 60.0)
		if frame % 10 == 0:
			game._add_phase7_ember_patch(Vector2(320 + (frame % 90), 300 + (frame % 40)), 8.0)
	var elapsed_ms: float = float(Time.get_ticks_usec() - start_us) / 1000.0
	_check(game.phase7_ember_patches.size() <= game.PHASE7_EMBER_PATCH_LOW_CAP, "ember patches grew after sustained update")
	_check(game._world_point_in_view(Vector2(640, 420), Vector2.ZERO, 0.0), "view culling rejected visible point")
	_check(not game._world_point_in_view(Vector2(-1000, -1000), Vector2.ZERO, 0.0), "view culling accepted far point")

	game.gfx_memory_saver = true
	game._apply_graphics_settings()
	for i in range(32):
		game.phase7_ember_patches.append({"pos": Vector2(200 + i, 200), "life": 1.0, "max": 1.0})
	game._trim_visual_effect_arrays()
	_check(game.phase7_ember_patches.size() <= game.PHASE7_EMBER_PATCH_MEMORY_CAP, "memory saver ember patch cap was not enforced")

	if failed:
		await _cleanup()
		quit(1)
		return
	print("PHASE7_MOBILE_PERFORMANCE_OK patches=%d elapsed_ms=%.2f" % [game.phase7_ember_patches.size(), elapsed_ms])
	await _cleanup()
	quit(0)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
