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
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.get_viewport_rect().size), Color("10121b"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(26, 34), "LACERANTE / FOLHA INTEGRADA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ff626e"))
	var labels := ["idle", "down", "right", "left", "up", "damage", "attack_right", "attack_left", "q_cast", "ultimate", "start_down", "frozen", "idle_extra"]
	var i := 0
	for key in labels:
		var frames: Array = game.textures.get("player_lacerante_" + key, [])
		_check(frames.size() > 0, "missing " + key)
		for f in range(frames.size()):
			var pos := Vector2(72.0 + (i % 8) * 158.0, 48.0 + floori(float(i) / 8.0) * 94.0)
			canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-50, 0), key + " / " + str(f), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("a8b8c1"))
			canvas.draw_texture_rect(frames[f], Rect2(pos + Vector2(-50, 4), Vector2(100, 80)), false)
			canvas.draw_line(pos + Vector2(-52, 84), pos + Vector2(52, 84), Color("39434d"), 1.0)
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
	_check(game.textures["player_lacerante_attack_right"].size() == 9, "right attack frames")
	_check(game.textures["player_lacerante_attack_left"].size() == 9, "left attack frames")
	_check(game.textures["player_lacerante_q_cast"].size() == 6, "Q cast frames")
	_check(game.textures["player_lacerante_ultimate"].size() == 8, "ultimate frames")
	_check(game.textures["player_lacerante_start_down"].size() == 6, "smoke bomb entry frames")
	_check(game.textures["player_lacerante_action_network"].size() == 32, "network action frames")
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
	_check(is_equal_approx(float(game._player_draw_profile()["height"]), game.LaceranteSprites.ATTACK_DRAW_HEIGHT), "attack body scale")
	game.last_attack_time = -100.0
	game.player_freeze_visual_timer = 0.4
	_check(game._player_texture() in game.textures["player_lacerante_frozen"], "frozen identity")
	game.player_freeze_visual_timer = 0.0
	_verify_sequences()
	root.size = Vector2i(1280, 720)
	await _capture("all_registered_frames")
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
	game.is_multiplayer = true
	for down_frame in range(2):
		game.net_players_by_peer = {2: {
			"render_pos": game.player_pos + Vector2(150, 0), "has_snapshot": true,
			"manifestation": 1, "anim_state": game.NET_ANIM_DOWN, "frame_idx": down_frame,
			"flip_h": false, "name": "Baixo %d" % down_frame, "hp": 400, "hp_max": 400}}
		await _capture("down_runtime_frame_%d" % down_frame)
	game.is_multiplayer = false
	game.net_players_by_peer.clear()
	for side in [Vector2.LEFT, Vector2.RIGHT]:
		for stage in range(3):
			game.lacerante_preparing = true
			game.lacerante_prepare_dir = side
			game.lacerante_prepare_stage = stage
			game.lacerante_prepare_frame = 0
			await _capture("prepare_%s_%d" % [str(side), stage])
			game.lacerante_prepare_frame = 1
			await _capture("impact_%s_%d" % [str(side), stage])
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
	for sample in [[0.12, "entrance_fall_early"], [0.50, "entrance_fall_mid"], [0.84, "entrance_impact_approach"], [0.98, "entrance_impact_contact"]]:
		game.player_start_down_fall_timer = game.PLAYER_START_DOWN_FALL_TIME * (1.0 - float(sample[0]))
		await _capture(String(sample[1]))
	game.player_start_down_fall_timer = 0.0
	for sample in [[0.08, "entrance_smoke_reveal"], [0.48, "entrance_landing"], [0.86, "entrance_recovery"]]:
		game.player_start_down_landing_timer = game.PLAYER_START_DOWN_LAND_TIME * (1.0 - float(sample[0]))
		await _capture(String(sample[1]))
	game.player_start_down_landing_timer = 0.0
	game.last_skill_time = -999.0
	game._use_skill()
	for q_frame in range(6):
		var spin: Dictionary = game.slashes[-1]
		spin["life"] = spin["max"] - game.LaceranteSprites.Q_CAST_SECONDS * (float(q_frame) + 0.25) / 6.0
		game.slashes[-1] = spin
		await _capture("q_cast_%d" % q_frame)
	game.slashes.clear()
	# Exercise the actual remote drawing path, including size and asymmetric art.
	game.is_multiplayer = true
	game.net_players_by_peer = {2: {
		"render_pos": game.player_pos + Vector2(150, 0), "has_snapshot": true,
		"manifestation": 1, "anim_state": game.NET_ANIM_LACERANTE, "frame_idx": 20,
		"flip_h": true, "name": "Lacerante remota", "hp": 240, "hp_max": 400}}
	await _capture("local_remote_scale")
	game.is_multiplayer = false
	game.net_players_by_peer.clear()
	root.size = Vector2i(960, 540)
	await _capture("mobile_landscape")
	if not failed:
		print("LACERANTE_SPRITE_VISUAL_OK attack_frames=18 q_frames=6 ultimate_frames=8 entry_frames=6 stages=3 sides=2 idle=true no_mirror=true damage_clamped=true network=true")
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


func _opaque_used_rect(image: Image, alpha_threshold := 0.06) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a < alpha_threshold:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _verify_sequences() -> void:
	# Every registered frame must have transparent gutters and a complete silhouette.
	var authored_keys := ["idle", "down", "right", "left", "up", "damage", "attack_right", "attack_left", "q_cast", "ultimate", "start_down", "frozen", "idle_extra"]
	var base_height := 0.0
	for suffix in authored_keys:
		var key: String = "player_lacerante_" + suffix
		for frame: Texture2D in game.textures[key]:
			_check(frame.get_size() == Vector2(320, 256), key + " canvas")
			var used_rect := _opaque_used_rect(frame.get_image())
			_check(used_rect.size.x > 0 and used_rect.size.y > 0, key + " visible content")
			_check(used_rect.position.x >= 8 and used_rect.position.y >= 8, key + " top/left crop")
			_check(320 - used_rect.end.x >= 8 and 256 - used_rect.end.y >= 8, key + " bottom/right crop")
			if suffix == "idle" and base_height <= 0.0:
				base_height = float(used_rect.size.y)
			if suffix in ["idle", "down", "right", "left", "up", "damage"]:
				var drift := absf(float(used_rect.size.y) - base_height) / maxf(1.0, base_height)
				_check(drift <= 0.05, "%s body height drift %.3f" % [key, drift])
	for side in [Vector2.LEFT, Vector2.RIGHT]:
		var key: String = "attack_left" if side.x < 0 else "attack_right"
		for stage in range(3):
			game.lacerante_preparing = true
			game.lacerante_prepare_dir = side
			game.lacerante_prepare_stage = stage
			for prep in range(2):
				game.lacerante_prepare_frame = prep
				_expect_frame(key, stage * 3 + prep, "attack phase %s/%d/%d" % [key, stage, prep])
			game._fire_lacerante(stage, side)
			game.lacerante_preparing = false
			game.last_facing = -side
			_check(game.player_attack_visual_dir == side, "emitted direction not captured")
			for elapsed in [0.0, 0.08, 0.16, 0.23]:
				game.time_alive = game.last_attack_time + elapsed
				_expect_frame(key, stage * 3 + 2, "recovery %s/%d" % [key, stage])
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
	game.last_skill_time = -999.0
	game._use_skill()
	_check(game.slashes.any(func(s): return String(s.get("kind", "")) == "lacerante_spin"), "Q visual missing")
	for q_frame in range(6):
		var spin: Dictionary = game.slashes[-1]
		spin["life"] = spin["max"] - game.LaceranteSprites.Q_CAST_SECONDS * (float(q_frame) + 0.25) / 6.0
		game.slashes[-1] = spin
		_expect_frame("q_cast", q_frame, "Q cast frame %d" % q_frame)
	game.slashes.clear()
	var ultimate := {
		"kind": "lacerante", "life": game.SECONDARY_LACERANTE_DURATION,
		"max": game.SECONDARY_LACERANTE_DURATION, "center": game.player_pos,
		"lock_player": true, "cuts": []
	}
	game.manifestation_secondaries.append(ultimate)
	var ultimate_life := [2.92, 2.76, 2.66, 2.55, 2.44, 2.33, 0.34, 0.12]
	for ultimate_frame in range(8):
		ultimate["life"] = ultimate_life[ultimate_frame]
		_expect_frame("ultimate", ultimate_frame, "ultimate frame %d" % ultimate_frame)
		_check(is_equal_approx(float(game._player_draw_profile()["height"]), game.LaceranteSprites.ULTIMATE_DRAW_HEIGHT), "ultimate body scale")
	game.manifestation_secondaries.clear()
