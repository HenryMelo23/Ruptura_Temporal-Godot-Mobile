extends SceneTree

const ACID_PATH := "res://.agent_logs/boss6_acid_rain_visual.png"
const BLIZZARD_PATH := "res://.agent_logs/phase2_ambient_blizzard_visual.png"

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("BOSS6_ACID_PHASE2_BLIZZARD_VISUAL_FAIL " + message)
	_cleanup()
	quit(1)


func _capture(path: String) -> Image:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("viewport image is empty for " + path)
		return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	var absolute := ProjectSettings.globalize_path(path)
	if image.save_png(absolute) != OK:
		_fail("could not save screenshot: " + absolute)
		return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	print("VISUAL_CAPTURE " + absolute)
	return image


func _count_pixels(image: Image, predicate: Callable) -> int:
	var count := 0
	for x in range(80, image.get_width(), 24):
		for y in range(60, image.get_height(), 24):
			var color := image.get_pixel(x, y)
			if bool(predicate.call(color)):
				count += 1
	return count


func _run() -> void:
	await process_frame
	var display_name := DisplayServer.get_name().to_lower()
	if display_name.contains("headless"):
		print("BOSS6_ACID_PHASE2_BLIZZARD_VISUAL_SKIP display=" + display_name)
		_cleanup()
		quit(0)
		return
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.agent_logs"))
	game._start_game()
	game.startup_thanks_done = true
	game.mode = "game"
	game.current_phase = 6
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 860.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(-260, 160)
	game.boss_attacks.clear()
	var acid_targets := [
		game.player_pos + Vector2(180, -80),
		game.player_pos + Vector2(360, 50),
		game.player_pos + Vector2(520, -130)
	]
	for i in range(acid_targets.size()):
		game.boss_attacks.append({
			"kind": game.BOSS6_ABILITY_ACID_RAIN,
			"age": game.BOSS6_ACID_RAIN_WARNING * (0.55 + float(i) * 0.18),
			"duration": game.BOSS6_ACID_RAIN_WARNING + 0.62,
			"target": acid_targets[i],
			"radius": game.BOSS6_ACID_RAIN_RADIUS,
			"phase": float(i) * 1.7,
			"impacted": i == 2
		})
	var acid_image := await _capture(ACID_PATH)
	var green_pixels := _count_pixels(acid_image, func(color: Color) -> bool:
		return color.g > 0.55 and color.r < 0.72 and color.b < 0.36
	)
	if green_pixels < 6:
		_fail("acid rain warning/splash did not render enough green pixels")

	game.current_phase = 2
	game.boss_active = false
	game.boss_dead = false
	game.boss_attacks.clear()
	game._reset_boss2_state()
	game.phase2_ambient_blizzard_active = game.PHASE2_AMBIENT_BLIZZARD_DURATION
	for _i in range(18):
		game._update_phase2_ambient_blizzard(1.0 / 60.0)
	var blizzard_image := await _capture(BLIZZARD_PATH)
	var snow_pixels := _count_pixels(blizzard_image, func(color: Color) -> bool:
		return color.b > 0.62 and color.g > 0.58 and color.r > 0.42
	)
	if snow_pixels < 8:
		_fail("ambient blizzard did not render enough snow/light-blue pixels")

	print("BOSS6_ACID_PHASE2_BLIZZARD_VISUAL_OK acid_pixels=%d snow_pixels=%d" % [green_pixels, snow_pixels])
	_cleanup()
	for _i in range(4):
		await process_frame
	quit(0)


func _cleanup() -> void:
	if game == null:
		return
	if game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	if "music_player" in game and game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if "rain_audio_player" in game and game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	if "sfx_players" in game:
		for player in game.sfx_players:
			if player != null:
				player.stop()
				player.stream = null
	if "textures" in game:
		game.textures.clear()
	if "audio_streams" in game:
		game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
