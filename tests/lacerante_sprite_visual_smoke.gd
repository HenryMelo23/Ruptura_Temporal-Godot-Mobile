extends SceneTree

const OUT := "res://.agent_logs/lacerante_sprite_after"
var game: Node
var canvas: Node2D
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	canvas = Node2D.new()
	root.add_child(canvas)
	canvas.draw.connect(_draw_scene)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("LACERANTE_SPRITE_FAIL " + message)


func _draw_scene() -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("10121b"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(26, 34), "LACERANTE / FOLHA INTEGRADA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ff626e"))
	var labels := ["idle", "right", "left", "up", "down", "damage", "attack_right", "attack_left", "frozen"]
	for i in range(labels.size()):
		var key: String = labels[i]
		var frames: Array = game.textures.get("player_lacerante_" + key, [])
		_check(frames.size() > 0, "missing " + key)
		var frame: Texture2D = frames[0]
		var pos := Vector2(86.0 + (i % 5) * 245.0, 110.0 + floori(float(i) / 5.0) * 265.0)
		canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-32, -20), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("a8b8c1"))
		canvas.draw_texture_rect(frame, Rect2(pos - Vector2(64, 92), Vector2(128, 128)), false)
		canvas.draw_line(pos + Vector2(-70, 40), pos + Vector2(70, 40), Color("39434d"), 1.0)


func _capture(name: String) -> void:
	canvas.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.save_png(OUT + "/" + name + ".png") == OK, "capture " + name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1280, 720)
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game._start_game(false)
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp = 400
	game.player_hp_max = 400
	game.manifestation_key = "lacerante"
	game.selected_manifestation = 1
	game.time_alive = 10.0
	game.last_damage_time = -100.0
	game.last_attack_time = -100.0
	game.move_touch_index = 0
	game.touch_move = Vector2.ZERO
	game.last_facing = Vector2.RIGHT
	var atlas: Texture2D = game.textures.get("player_lacerante_core")
	_check(atlas != null and atlas.get_size() == Vector2(1536, 1024), "core atlas size")
	_check(game.textures["player_lacerante_idle"].size() == 4, "idle frames")
	_check(game.textures["player_lacerante_damage"].size() == 4, "damage frames")
	_check(game.textures["player_lacerante_attack_right"].size() == 6, "right attack frames")
	_check(game.textures["player_lacerante_attack_left"].size() == 6, "left attack frames")
	_check(game._player_texture() == game.textures["player_lacerante_idle"][int(Time.get_ticks_msec() / 145) % 4], "idle does not use generated sheet")
	game.touch_move = Vector2.RIGHT
	_check(game._player_texture() in game.textures["player_lacerante_right"], "right walk identity")
	game.touch_move = Vector2.LEFT
	_check(game._player_texture() in game.textures["player_lacerante_left"], "left walk identity")
	game.touch_move = Vector2.ZERO
	game.last_damage_time = game.time_alive
	_check(game._player_texture() in game.textures["player_lacerante_damage"], "damage identity")
	game.last_damage_time = -100.0
	game.last_attack_time = game.time_alive
	game.player_attack_visual_dir = Vector2.LEFT
	_check(game._player_texture() in game.textures["player_lacerante_attack_left"], "left attack identity")
	game.player_attack_visual_dir = Vector2.RIGHT
	_check(game._player_texture() in game.textures["player_lacerante_attack_right"], "right attack identity")
	game.last_attack_time = -100.0
	game.player_freeze_visual_timer = 0.4
	_check(game._player_texture() in game.textures["player_lacerante_frozen"], "frozen identity")
	game.player_freeze_visual_timer = 0.0
	await _capture("sheet_preview")
	canvas.visible = false
	game.mode = "game"
	game.player_pos = Vector2(640, 390)
	game.touch_move = Vector2.ZERO
	game.last_damage_time = -100.0
	game.last_attack_time = -100.0
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(OUT + "/gameplay_idle.png") == OK, "gameplay idle capture")
	game.player_hp = 240
	game.last_damage_time = game.time_alive
	await _capture("damage_state")
	print("LACERANTE_SPRITE_VISUAL_OK atlas=true idle=4 walk=10 damage=4 attacks=12 frozen=2 identity=true")
	game.queue_free()
	canvas.queue_free()
	await process_frame
	await create_timer(0.6).timeout
	quit(1 if failed else 0)
