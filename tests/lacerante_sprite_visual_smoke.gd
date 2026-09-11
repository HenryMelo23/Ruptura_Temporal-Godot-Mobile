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
	var labels := ["idle", "down", "right", "left", "up", "damage", "attack_right", "start_down", "frozen", "attack_left", "idle_extra"]
	var i := 0
	for key in labels:
		var frames: Array = game.textures.get("player_lacerante_" + key, [])
		_check(frames.size() > 0, "missing " + key)
		for f in range(frames.size()):
			var pos := Vector2(80.0 + (i % 8) * 160.0, 58.0 + floori(float(i) / 8.0) * 132.0)
			canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-68, 0), key + " / " + str(f), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a8b8c1"))
			canvas.draw_texture_rect(frames[f], Rect2(pos + Vector2(-70, 6), Vector2(140, 112)), false)
			canvas.draw_line(pos + Vector2(-72, 111), pos + Vector2(72, 111), Color("39434d"), 1.0)
			i += 1


func _capture(name: String) -> void:
	canvas.queue_redraw()
	game.queue_redraw()
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
	_check(atlas != null and atlas.get_size() == Vector2(1920, 1024), "core atlas size")
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
	_verify_sequences()
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
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		game.touch_move = direction
		await _capture("walk_" + str(direction))
	game.touch_move = Vector2.ZERO
	for side in [Vector2.LEFT, Vector2.RIGHT]:
		for stage in range(3):
			game.lacerante_preparing = true
			game.lacerante_prepare_dir = side
			game.lacerante_prepare_stage = stage
			await _capture("prepare_%s_%d" % [str(side), stage])
			game._fire_lacerante(stage, side)
			game.lacerante_preparing = false
			await _capture("strike_%s_%d" % [str(side), stage])
			game.time_alive += 0.3
			game.slashes.clear()
	game.player_hp = 240
	game.last_damage_time = game.time_alive
	await _capture("damage_state")
	game.last_damage_time = -100.0
	game.last_attack_time = -100.0
	game.effects.clear()
	game.player_start_down_fall_timer = game.PLAYER_START_DOWN_FALL_TIME * 0.25
	await _capture("entrance_fall")
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = game.PLAYER_START_DOWN_LAND_TIME * 0.5
	await _capture("entrance_landing")
	game.player_start_down_landing_timer = 0.01
	await _capture("entrance_recovery")
	game.player_start_down_landing_timer = 0.0
	# Exercise the actual remote drawing path, including size and asymmetric art.
	game.is_multiplayer = true
	game.net_players_by_peer = {2: {
		"render_pos": game.player_pos + Vector2(150, 0), "has_snapshot": true,
		"manifestation": 1, "anim_state": game.NET_ANIM_LACERANTE, "frame_idx": 11,
		"flip_h": true, "name": "Lacerante remota", "hp": 240, "hp_max": 400}}
	await _capture("local_remote_scale")
	game.is_multiplayer = false
	game.net_players_by_peer.clear()
	root.size = Vector2i(960, 540)
	await _capture("mobile_landscape")
	if not failed:
		print("LACERANTE_SPRITE_VISUAL_OK frames=40 stages=3 sides=2 idle=true no_mirror=true damage_clamped=true network=true")
	game.queue_free()
	canvas.queue_free()
	await process_frame
	await create_timer(0.6).timeout
	quit(1 if failed else 0)


func _expect_frame(key: String, index: int, message: String) -> void:
	var expected: Texture2D = game.textures["player_lacerante_" + key][index]
	_check(game._player_texture() == expected, message + " local")
	var state: Vector2i = game._network_player_animation_snapshot(Time.get_ticks_msec())
	_check(game._net_player_texture_for_state(state.x, state.y, 1) == expected, message + " remote")
	game.net_player_manifestation = 1
	game.net_player_anim_state = state.x
	game.net_player_frame_idx = state.y
	_check(game._net_player_texture() == expected, message + " legacy remote")
	_check(not game._should_flip_player_sprite(), message + " double mirror")


func _verify_sequences() -> void:
	# Every registered frame must have transparent gutters and a complete silhouette.
	for key in game.textures:
		if not String(key).begins_with("player_lacerante_") or not game.textures[key] is Array:
			continue
		for frame: Texture2D in game.textures[key]:
			var image: Image = frame.get_image()
			_check(image.get_size() == Vector2i(320, 256), key + " canvas")
			_check(Rect2i(2, 2, 316, 252).encloses(image.get_used_rect()), key + " clipped art")
	for side in [Vector2.LEFT, Vector2.RIGHT]:
		var key: String = "attack_left" if side.x < 0 else "attack_right"
		for stage in range(3):
			game.lacerante_preparing = true
			game.lacerante_prepare_dir = side
			game.lacerante_prepare_stage = stage
			for prep in range(2):
				game.lacerante_prepare_frame = prep
				_expect_frame(key, stage * 2, "anticipation %s/%d/%d" % [key, stage, prep])
			game._fire_lacerante(stage, side)
			game.lacerante_preparing = false
			game.last_facing = -side
			_check(game.player_attack_visual_dir == side, "emitted direction not captured")
			for elapsed in [0.0, 0.08, 0.16, 0.23]:
				game.time_alive = game.last_attack_time + elapsed
				_expect_frame(key, stage * 2 + 1, "strike %s/%d" % [key, stage])
			game.time_alive = game.last_attack_time + 0.25
			_check(game._player_texture() in game.textures["player_lacerante_idle"], "strike recovery")
	game.last_attack_time = -100.0
	for side in [Vector2.LEFT, Vector2.RIGHT]:
		game.last_facing = side
		game.touch_move = Vector2.ZERO
		game.last_attack_time = -100.0
		_check(game._player_texture() in game.textures["player_lacerante_idle"], "stationary player walks")
		for move in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			game.touch_move = move
			var key: String = "up" if move.y < 0 else ("down" if move.y > 0 else ("left" if move.x < 0 else "right"))
			game.last_attack_time = game.time_alive
			_check(game._player_texture() in game.textures["player_lacerante_" + key], "moving attack replaced walk")
			for now_ms in [0, 105, 120, 210, 240, 315, 480]:
				var state: Vector2i = game._network_player_animation_snapshot(now_ms)
				_check(game._net_player_texture_for_state(state.x, state.y, 1) in game.textures["player_lacerante_" + key], "remote walking direction")
	game.touch_move = Vector2.ZERO
	game.last_damage_time = game.time_alive
	for elapsed in [0.0, 0.071, 0.141, 0.211, 0.281, 0.349]:
		game.time_alive = game.last_damage_time + elapsed
		_expect_frame("damage", clampi(int(elapsed / 0.07), 0, 3), "damage once")
	game.player_freeze_visual_timer = 0.4
	_check(game._player_texture() in game.textures["player_lacerante_frozen"], "freeze priority")
	game.player_freeze_visual_timer = 0.0
	game.last_attack_time = -100.0
	game.last_damage_time = -100.0
	game.slashes.clear()
	game.effects.clear()
	# Keep secondary transformation priority, including freeze interruption.
	var secondary := {"kind": "prismatica", "life": 1.0}
	game.manifestation_secondaries.append(secondary)
	_check(game._player_texture() == game._prismatica_ultimate_frame_texture(secondary), "secondary animation priority")
	game.player_freeze_visual_timer = 0.4
	_check(game._player_texture() in game.textures["player_lacerante_frozen"], "freeze interrupts secondary")
	game.player_freeze_visual_timer = 0.0
	game.manifestation_secondaries.clear()
