extends SceneTree

const CombatEffectsPresentation = preload("res://scripts/presentation/combat_effects_presentation.gd")

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("MOBILE_ADAPTIVE_VISUAL_BUDGET_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "") == "gl_compatibility", "Android did not select the low-overhead compatibility renderer")
	_check(ProjectSettings.get_setting("rendering/gl_compatibility/driver.android", "") == "opengl3", "Android compatibility renderer did not select native OpenGL ES")

	game.mode = "game"
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.gfx_shadows = true
	game.mobile_adaptive_visual_budget = true
	_check(CombatEffectsPresentation.is_world_point_visible(Vector2(640.0, 360.0), Vector2.ZERO, Vector2(1280.0, 720.0)), "visible pickup was culled")
	_check(CombatEffectsPresentation.is_world_point_visible(Vector2(-32.0, 360.0), Vector2.ZERO, Vector2(1280.0, 720.0)), "pickup margin was not preserved")
	_check(not CombatEffectsPresentation.is_world_point_visible(Vector2(-96.0, 360.0), Vector2.ZERO, Vector2(1280.0, 720.0)), "offscreen pickup was still submitted for drawing")
	_check(CombatEffectsPresentation.advanced_world_channels("eletrica", false).is_empty(), "solo rendered inactive manifestation channels")
	_check(CombatEffectsPresentation.advanced_world_channels("mnesica", false) == PackedStringArray(["mnesica"]), "solo did not isolate the active manifestation channel")
	_check(CombatEffectsPresentation.advanced_world_channels("eletrica", true).size() == 5, "multiplayer lost remote manifestation channels")
	_check(is_equal_approx(game._mobile_adaptive_trigger_time(12.0), game.MOBILE_ADAPTIVE_CRITICAL_TRIGGER_TIME), "critical FPS did not select the emergency trigger")
	_check(is_equal_approx(game._mobile_adaptive_trigger_time(38.0), game.MOBILE_ADAPTIVE_TRIGGER_TIME), "ordinary low FPS lost the debounce window")
	var phase_map = game.PhaseMapPresentation.new()
	game.add_child(phase_map)
	phase_map.present(null, Rect2(0, 0, 592, 592), 2, 5.0, game._runtime_visual_budget_active())
	_check(not bool(phase_map.life_material.get_shader_parameter("fluid_surface")), "adaptive budget left the animated map shader enabled")
	_check(phase_map.material == phase_map.static_material, "adaptive budget did not select the opaque static map material")
	_check(game._shadows_enabled(), "desktop adaptive recovery stole the player's explicit shadow preference")

	game.effects.clear()
	for i in range(game.LOW_RESOURCE_EFFECT_CAP + 80):
		game.effects.append({"text": "", "pos": Vector2(640 + i, 420), "life": 1.0, "max": 1.0})

	game.raindrops.clear()
	for i in range(game.LOW_RESOURCE_RAIN_DROP_CAP + 40):
		game.raindrops.append({
			"ground": Vector2(640 + i, 420),
			"height": 120.0,
			"speed": 900.0,
			"wind": -90.0,
			"len": 24.0,
			"size": 1.4,
			"phase": 0.0
		})

	game.snowflakes.clear()
	for i in range(game.LOW_RESOURCE_SNOW_FLAKE_CAP + 40):
		game.snowflakes.append({
			"pos": Vector2(640 + i, 420),
			"speed": 70.0,
			"drift": 30.0,
			"size": 2.0,
			"phase": 0.0,
			"life": 1.0
		})

	game.puddles.clear()
	for i in range(game.LOW_RESOURCE_PUDDLE_CAP + 14):
		game.puddles.append({
			"pos": Vector2(640 + i, 420),
			"r": 18.0,
			"life": 1.0,
			"max_life": 1.0,
			"grow": 1.0,
			"grow_time": 1.0,
			"phase": 0.0,
			"shine": 1.0,
			"tilt": 0.0
		})

	game.boss7_flame_waves.clear()
	for i in range(8):
		game.boss7_flame_waves.append({
			"center": Vector2(640, 420),
			"life": 1.0,
			"duration": 1.0,
			"radius": 80.0,
			"max_radius": 120.0,
			"thickness": 28.0,
			"flames": []
		})

	game._trim_visual_effect_arrays()
	_check(game.effects.size() <= game.LOW_RESOURCE_EFFECT_CAP, "adaptive effect cap was not enforced")
	_check(game.raindrops.size() <= game._low_resource_cap(game.WEATHER_MAX_RAIN_DROPS, game.LOW_RESOURCE_RAIN_DROP_CAP), "adaptive rain cap was not enforced")
	_check(game.snowflakes.size() <= game._low_resource_cap(game.WEATHER_MAX_SNOW_FLAKES, game.LOW_RESOURCE_SNOW_FLAKE_CAP), "adaptive snow cap was not enforced")
	_check(game.puddles.size() <= game._low_resource_cap(game.WEATHER_MAX_PUDDLES, game.LOW_RESOURCE_PUDDLE_CAP), "adaptive puddle cap was not enforced")
	_check(game.boss7_flame_waves.size() <= 4, "adaptive boss7 flame wave cap was not enforced")
	_check(game._adaptive_particle_count(40) <= 12, "adaptive particle count is too high for mobile recovery mode")
	_check(not game.gfx_low_resource, "adaptive recovery must not overwrite the player's quality preference")

	game.boss7_flame_waves.clear()
	game._spawn_boss7_flame_wave(Vector2(640, 420), 250.0)
	var flames: Array = Array(game.boss7_flame_waves[0].get("flames", []))
	_check(flames.size() <= 34, "adaptive boss7 flame wave spawned too many flame particles")

	game.gfx_memory_saver = true
	game._trim_visual_effect_arrays()
	_check(game.effects.size() <= game.MEMORY_SAVER_EFFECT_CAP, "memory saver still must be stricter than adaptive mode")

	if failed:
		_cleanup()
		quit(1)
		return
	print("MOBILE_ADAPTIVE_VISUAL_BUDGET_OK effects=%d rain=%d snow=%d puddles=%d flames=%d" % [
		game.effects.size(),
		game.raindrops.size(),
		game.snowflakes.size(),
		game.puddles.size(),
		flames.size()
	])
	phase_map.free()
	_cleanup()
	quit(0)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
