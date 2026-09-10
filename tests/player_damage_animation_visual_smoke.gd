extends SceneTree

const OUTPUT := "res://.agent_logs/damage_after"
var game: Node
var failed: bool = false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PLAYER_DAMAGE_VISUAL_FAIL " + message)


func _capture(name: String) -> void:
	game.queue_redraw()
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == root.size, "wrong viewport " + name)
	_check(image.save_png(OUTPUT + "/" + name + ".png") == OK, "capture " + name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game._start_game(false)
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(640, 420)
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO
	game.manifestation_key = "eletrica"
	game.player_hp_max = 400
	game.player_hp = 260
	game.time_alive = 20.0
	game.last_damage_time = game.time_alive
	var frames: Array = game.textures.get("player_damage", [])
	_check(frames.size() == 4, "damage sequence does not contain four frames")
	var fingerprints: Array[String] = []
	for index in range(frames.size()):
		var texture: Texture2D = frames[index]
		_check(texture != null, "missing damage frame %d" % index)
		_check(texture.get_size() == Vector2(165, 254), "damage frame %d changed stop canvas size" % index)
		var image: Image = texture.get_image()
		_check(image.get_pixel(0, 0).a == 0.0, "damage frame %d has an opaque background" % index)
		_check(image.get_used_rect().size.y >= 248, "damage frame %d lost the feet baseline" % index)
		fingerprints.append(image.get_data().hex_encode())
	_check(fingerprints[0] != fingerprints[1] and fingerprints[1] != fingerprints[2] and fingerprints[2] != fingerprints[3], "damage frames are duplicates")
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = viewport
		game.ui_platform_override_unlocked = true
		game.ui_platform_override = "desktop" if viewport.x == 1280 else "android"
		for index in range(4):
			game.time_alive = game.last_damage_time + 0.012 + index * 0.07
			_check(game._player_texture() == frames[index], "runtime selected wrong damage frame %d" % index)
			await _capture("%d_frame_%d" % [viewport.x, index])
		game.time_alive = game.last_damage_time + 0.36
		_check(game.textures["player_idle"].has(game._player_texture()), "damage did not return to stop animation")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	if not failed:
		print("PLAYER_DAMAGE_VISUAL_OK frames=4 coherent=true stop_identity=true glitch_progression=true desktop=true mobile=true recovery=true")
	quit(1 if failed else 0)
