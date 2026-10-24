extends SceneTree

const OUT_DIR := "res://.agent_logs/lacerante_ultimate_runtime"
const OUT_MOBILE_AIM := "res://.agent_logs/lacerante_ultimate_mobile_hold_960x540.png"
const OUT_DESKTOP_AIM := "res://.agent_logs/lacerante_ultimate_desktop_hold_960x540.png"

var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("LACERANTE_ULTIMATE_VISUAL_FAIL " + message)
	quit(1)


func _capture(path: String) -> void:
	for frame in range(5):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != Vector2i(960, 540) or image.save_png(path) != OK:
		_fail("%s actual=%s" % [path, image.get_size() if image != null else Vector2i.ZERO])


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


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("renderer required")
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.run_tutorial_enabled = false
	game._start_game()
	game._finish_startup_thanks()
	game.mode = "game"
	game.manifestation_key = "lacerante"
	game.selected_manifestation = game._manifestation_index_for_key("lacerante", -1)
	game.player_pos = Vector2(720.0, 460.0)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.last_damage_time = -999.0
	game.gfx_screen_shake = false
	game.mobile_adaptive_visual_budget = false
	game.time_alive = 50.0
	game.process_mode = Node.PROCESS_MODE_DISABLED
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	await process_frame
	root.min_size = Vector2i.ZERO
	root.content_scale_size = Vector2i.ZERO
	DisplayServer.window_set_size(Vector2i(960, 540))
	root.size = Vector2i(960, 540)
	await create_timer(0.35).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var frames: Array = game.textures.get("player_lacerante_ultimate", [])
	if frames.size() != 8:
		_fail("expected 8 ultimate frames, got %d" % frames.size())
	var frame_bounds: Array[Rect2i] = []
	for texture: Texture2D in frames:
		if texture.get_size() != Vector2(320, 256):
			_fail("ultimate frame canvas is not 320x256")
		var used := _opaque_used_rect(texture.get_image())
		if used.position.x < 8 or used.position.y < 8 or 320 - used.end.x < 8 or 256 - used.end.y < 8:
			_fail("cropped frame bounds=%s" % used)
		frame_bounds.append(used)
	var feet_baseline: int = frame_bounds[0].end.y
	for used in frame_bounds:
		if absi(used.end.y - feet_baseline) > 1:
			_fail("feet baseline drift expected=%d actual=%d" % [feet_baseline, used.end.y])
	var idle_texture: Texture2D = game.textures["player_lacerante_idle"][0]
	var idle_bounds := _opaque_used_rect(idle_texture.get_image())
	var idle_screen_height: float = float(idle_bounds.size.y) * game.LaceranteSprites.DRAW_HEIGHT / 256.0
	var ultimate_guard_screen_height: float = float(frame_bounds[0].size.y) * game.LaceranteSprites.ULTIMATE_DRAW_HEIGHT / 256.0
	if absf(ultimate_guard_screen_height - idle_screen_height) / maxf(1.0, idle_screen_height) > 0.05:
		_fail("guard body scale drift idle=%.2f ultimate=%.2f" % [idle_screen_height, ultimate_guard_screen_height])

	game.manifestation_secondaries = [{"kind": "lacerante", "life": game.SECONDARY_LACERANTE_DURATION, "max": game.SECONDARY_LACERANTE_DURATION, "center": game.player_pos, "lock_player": true, "cuts": []}]
	var sample_life := [2.92, 2.76, 2.66, 2.55, 2.44, 2.33, 0.34, 0.12]
	for frame_index in range(8):
		game.manifestation_secondaries[0]["life"] = sample_life[frame_index]
		var texture: Texture2D = game._player_texture()
		if texture != frames[frame_index]:
			_fail("runtime did not select frame %d" % frame_index)
		if not is_equal_approx(float(game._player_draw_profile()["height"]), game.LaceranteSprites.ULTIMATE_DRAW_HEIGHT):
			_fail("ultimate draw height drift")
		await _capture("%s/frame_%02d_960x540.png" % [OUT_DIR, frame_index])
	game.manifestation_secondaries.clear()

	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	game._update_button_layout(Vector2(960, 540))
	var secondary_center: Vector2 = game.buttons["secondary"].get_center()
	game._handle_touch_press(51, secondary_center, Vector2(960, 540))
	game._handle_touch_drag(51, secondary_center + Vector2(64.0, -24.0), Vector2(960, 540))
	await _capture(OUT_MOBILE_AIM)
	game._cancel_touch_index(51)

	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game._update_button_layout(Vector2(960, 540))
	game.get_viewport().warp_mouse(Vector2(610.0, 220.0))
	game._begin_desktop_aim("secondary", game._key_input_binding(KEY_E), true)
	await _capture(OUT_DESKTOP_AIM)

	print("LACERANTE_ULTIMATE_VISUAL_OK frames=8 canvas=320x256 runtime=8x960x540 mobile_hold=960x540 desktop_hold=960x540")
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
