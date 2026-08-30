extends SceneTree

const SCREENSHOT_PATH := "res://.agent_logs/phase2_penguin_sprites_after.png"

var game: Node


func _fail(message: String) -> void:
	push_error("PHASE2_PENGUIN_SPRITE_VISUAL_FAIL " + message)
	_cleanup()
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.startup_thanks_done = true
	game.mode = "game"
	game.current_phase = 2
	game.player_pos = game.WORLD_SIZE * 0.5
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.phase2_fire_walls.clear()

	var pyro_frames: Array = game.textures.get("enemy_phase_2_pyro", [])
	var kamikaze_frames: Array = game.textures.get("enemy_phase_2_kamikaze", [])
	if pyro_frames.size() != 2:
		_fail("pyro penguin should load exactly two frames")
		return
	if kamikaze_frames.size() != 2:
		_fail("kamikaze penguin should load exactly two frames")
		return
	for frame in pyro_frames + kamikaze_frames:
		var texture := frame as Texture2D
		if texture == null or texture.get_size().x <= 0.0:
			_fail("penguin frame was not imported as a valid Texture2D")
			return

	var center: Vector2 = game.player_pos
	var staged := [
		{"type": game.ENEMY_PYRO_PENGUIN, "pos": center + Vector2(-210.0, -95.0), "phase": 0.0, "facing_dir": Vector2.LEFT},
		{"type": game.ENEMY_PYRO_PENGUIN, "pos": center + Vector2(210.0, -95.0), "phase": 1.0, "facing_dir": Vector2.RIGHT},
		{"type": game.ENEMY_KAMIKAZE, "pos": center + Vector2(-210.0, 125.0), "phase": 0.0, "facing_dir": Vector2.LEFT},
		{"type": game.ENEMY_KAMIKAZE, "pos": center + Vector2(210.0, 125.0), "phase": 1.0, "facing_dir": Vector2.RIGHT},
	]
	for data in staged:
		_stage_enemy(data)

	var pyro_texture: Texture2D = game._enemy_texture({"type": game.ENEMY_PYRO_PENGUIN, "phase": 1.0, "pos": center, "facing_dir": Vector2.LEFT})
	var kamikaze_texture: Texture2D = game._enemy_texture({"type": game.ENEMY_KAMIKAZE, "phase": 1.0, "pos": center, "facing_dir": Vector2.LEFT})
	if pyro_texture == null or not pyro_frames.has(pyro_texture):
		_fail("pyro enemy did not resolve its dedicated texture key")
		return
	if kamikaze_texture == null or not kamikaze_frames.has(kamikaze_texture):
		_fail("kamikaze enemy did not resolve its dedicated texture key")
		return
	if game._enemy_should_flip({"type": game.ENEMY_KAMIKAZE, "facing_dir": Vector2.LEFT}):
		_fail("left-facing kamikaze should use source orientation")
		return
	if not game._enemy_should_flip({"type": game.ENEMY_KAMIKAZE, "facing_dir": Vector2.RIGHT}):
		_fail("right-facing kamikaze should flip the source sprite")
		return
	if game._enemy_should_flip({"type": game.ENEMY_PYRO_PENGUIN, "facing_dir": Vector2.LEFT}):
		_fail("left-facing pyro penguin should use source orientation")
		return
	if not game._enemy_should_flip({"type": game.ENEMY_PYRO_PENGUIN, "facing_dir": Vector2.RIGHT}):
		_fail("right-facing pyro penguin should flip the source sprite")
		return

	game.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		print("PHASE2_PENGUIN_SPRITE_VISUAL_OK logic_only=true screenshot_skipped=headless")
		_cleanup()
		quit(0)
		return
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		print("PHASE2_PENGUIN_SPRITE_VISUAL_OK logic_only=true screenshot_skipped=no_viewport")
		_cleanup()
		quit(0)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		print("PHASE2_PENGUIN_SPRITE_VISUAL_OK logic_only=true screenshot_skipped=empty_viewport")
		_cleanup()
		quit(0)
		return
	var path := ProjectSettings.globalize_path(SCREENSHOT_PATH)
	if image.save_png(path) != OK:
		_fail("could not save screenshot")
		return
	print("PHASE2_PENGUIN_SPRITE_VISUAL_OK " + path)
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


func _stage_enemy(data: Dictionary) -> void:
	var previous_count: int = game.enemies.size()
	game._spawn_enemy(String(data["type"]), Vector2(data["pos"]))
	var enemy: Dictionary
	if game.enemies.size() > previous_count:
		enemy = game.enemies[game.enemies.size() - 1]
	else:
		var template: Dictionary = game.enemies[0].duplicate(true) if not game.enemies.is_empty() else {}
		if template.is_empty():
			_fail("could not stage duplicate penguin enemy")
			return
		enemy = template
		game.enemies.append(enemy)
	enemy["type"] = String(data["type"])
	enemy["uid"] = 9000 + game.enemies.size()
	enemy["pos"] = Vector2(data["pos"])
	enemy["phase"] = float(data["phase"])
	enemy["facing_dir"] = Vector2(data["facing_dir"])
	enemy["last_move_dir"] = Vector2(data["facing_dir"])
	enemy["speed"] = 0.0
	enemy["stun"] = 999.0
	enemy["shoot_cd"] = 999.0
	enemy["hp"] = 9999.0
	enemy["max_hp"] = 9999.0
