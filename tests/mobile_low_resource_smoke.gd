extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MOBILE_LOW_RESOURCE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.gfx_low_resource = true
	game.gfx_particles = true
	game.gfx_shadows = true
	game._apply_graphics_settings()
	_check(Engine.max_fps == game.LOW_RESOURCE_FPS, "low resource mode did not keep the 60fps gameplay target")
	_check(not game._shadows_enabled(), "dynamic shadows should be disabled while low resource mode is active")

	game.effects.clear()
	game.enemies.clear()
	game._spawn_radial_particles(Vector2(200, 200), Color.CYAN, 40)
	_check(game.effects.size() <= 18, "radial particles were not reduced enough")

	for i in range(game.LOW_RESOURCE_EFFECT_CAP + 40):
		game.effects.append({"text": "", "pos": Vector2.ZERO, "life": 1.0, "max": 1.0})
	for i in range(54):
		game.slashes.append({"life": 1.0, "max": 1.0})
	for i in range(86):
		game.boss2_frost_particles.append({"life": 1.0, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	game._trim_visual_effect_arrays()
	_check(game.effects.size() <= game.LOW_RESOURCE_EFFECT_CAP, "effect cap was not enforced")
	_check(game.slashes.size() <= 42, "slash cap was not enforced")
	_check(game.boss2_frost_particles.size() <= 70, "frost particle cap was not enforced")

	game.current_phase = 1
	var phase1 = game._current_map_texture()
	_check(phase1 != null, "current phase map could not be loaded lazily")
	game._release_unused_lazy_maps("map_phase_1")
	_check(game.textures.get("map_phase_2") == null, "unused phase map stayed resident in low resource mode")

	game.gfx_memory_saver = true
	game.qa_streaming_unlocked = true
	game.qa_streaming_enabled = true
	game.gfx_particles = true
	game.gfx_shadows = true
	game.gfx_screen_shake = true
	game._apply_graphics_settings()
	_check(Engine.max_fps == game.MEMORY_SAVER_FPS, "memory saver did not keep the 60fps gameplay target")
	_check(not game.gfx_particles, "memory saver should disable particles")
	_check(not game.gfx_shadows, "memory saver should disable shadows")
	_check(not game.gfx_screen_shake, "memory saver should disable screen shake")
	_check(not game.qa_streaming_unlocked, "memory saver should keep removed QA streaming locked")
	_check(not game.qa_streaming_enabled, "memory saver should keep removed QA streaming off")
	game.qa_streaming_quality_mode = "180p"
	game._cycle_qa_stream_quality_mode(1)
	_check(game.qa_streaming_quality_mode == "180p", "removed streaming quality selector should be inert")
	_check(game._capture_qa_stream_frame().is_empty(), "removed streaming should not capture frames in memory saver")
	_check(game.sfx_players.size() <= 5, "memory saver should shrink the sfx player pool")
	for i in range(game.MEMORY_SAVER_EFFECT_CAP + 40):
		game.effects.append({"text": "", "pos": Vector2.ZERO, "life": 1.0, "max": 1.0})
	game._trim_visual_effect_arrays()
	_check(game.effects.size() <= game.MEMORY_SAVER_EFFECT_CAP, "memory saver effect cap was not enforced")
	game.audio_streams.clear()
	game._load_audio_streams()
	_check(game.audio_stream_paths.has("Fases1.mp3"), "memory saver should register shared phase music")
	_check(not game.audio_streams.has("Fases1.mp3"), "memory saver should not eagerly load shared phase music")
	game._play_music("Fases1.mp3")
	_check(game.audio_streams.has("Fases1.mp3"), "memory saver should load music on demand")
	game.music_player.stop()
	game.music_player.stream = null

	print("MOBILE_LOW_RESOURCE_SMOKE_OK effects=%d fps=%d" % [game.effects.size(), Engine.max_fps])
	quit()
