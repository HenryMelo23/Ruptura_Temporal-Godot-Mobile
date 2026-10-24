extends SceneTree

const Quimera = preload("res://scripts/presentation/henry_quimera_presentation.gd")
const OUTPUT_DIR := "res://.agent_logs/henry_quimera"

var game: Node2D
var failed := false
var baseline: Image


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	printerr("HENRY_QUIMERA_PRESENTATION_VISUAL_FAIL " + message)


func _placeholder_frame(color: Color, index: int) -> ImageTexture:
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var phase_shift := index % 2 * 7
	for y in range(72 + phase_shift, 190 + phase_shift):
		for x in range(82, 175):
			var border := x < 87 or x > 169 or y < 77 + phase_shift or y > 184 + phase_shift
			if border and ((x + y + index) % 3 != 0):
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _placeholder_frames(count: int, color: Color) -> Array:
	var frames: Array = []
	frames.resize(count)
	for index in range(count):
		frames[index] = _placeholder_frame(color, index)
	return frames


func _run() -> void:
	await process_frame
	game.active_character_key = game.CHARACTER_HENRY
	game._start_game(false)
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.set_process(false)
	game.mode = "game"
	game.startup_thanks_done = true
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(560.0, 390.0)
	game.last_facing = Vector2.RIGHT
	game.last_attack_time = -100.0
	game.last_damage_time = -100.0
	game.gfx_screen_shake = false
	game.gfx_particles = false
	game.gfx_shadows = true
	game.vol_master = 0.0
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	baseline = await _capture("before_base_henry_1280x720.png")

	game.textures[Quimera.STRUCTURAL_TEXTURE_KEY] = _placeholder_frames(6, Color(0.95, 0.7, 0.14, 0.9))
	game.textures[Quimera.PREDATORY_TEXTURE_KEY] = _placeholder_frames(12, Color(0.94, 0.12, 0.07, 0.88))
	game.textures[Quimera.ANOMALOUS_TEXTURE_KEY] = _placeholder_frames(6, Color(0.08, 0.94, 0.7, 0.84))
	game.set_meta(Quimera.LOCAL_VISUAL_META, {
		"families": {
			Quimera.FAMILY_STRUCTURAL: 3,
			Quimera.FAMILY_PREDATORY: 2,
			Quimera.FAMILY_ANOMALOUS: 1,
		},
		"direction": Vector2.DOWN,
		"locomotion_frame": 1,
		"accent_phase": 0.25,
	})
	var local_image := await _capture("placeholder_local_front_1280x720.png")
	_check(_changed_pixels(baseline, local_image) > 80, "local placeholder overlay did not alter the Henry silhouette")

	game.is_multiplayer = true
	var remote_pos: Vector2 = game.player_pos + Vector2(220.0, 0.0)
	game.net_players_by_peer[22] = {
		"pos": remote_pos,
		"render_pos": remote_pos,
		"hp": 450.0,
		"hp_max": 450.0,
		"dead": false,
		"has_snapshot": true,
		"manifestation": game.HENRY_SELECTION_INDEX,
		"manifestation_key": "incendiario",
		"anim_state": game.NET_ANIM_RIGHT,
		"frame_idx": 3,
		"flip_h": true,
		"input_move": Vector2.LEFT,
		"name": "Henry remoto",
		Quimera.REMOTE_VISUAL_KEY: {
			"families": {
				Quimera.FAMILY_STRUCTURAL: 1,
				Quimera.FAMILY_PREDATORY: 3,
				Quimera.FAMILY_ANOMALOUS: 2,
			},
			"direction": Vector2.LEFT,
			"locomotion_frame": 3,
			"accent_phase": 0.75,
		},
	}
	var remote_image := await _capture("placeholder_local_remote_side_1280x720.png")
	_check(_changed_pixels(local_image, remote_image) > 80, "remote placeholder pipeline did not render")

	root.size = Vector2i(800, 450)
	game.player_pos = Vector2(320.0, 270.0)
	game.net_players_by_peer[22]["pos"] = Vector2(500.0, 270.0)
	game.net_players_by_peer[22]["render_pos"] = Vector2(500.0, 270.0)
	var mobile_image := await _capture("placeholder_local_remote_800x450.png")
	_check(mobile_image.get_width() == 800 and mobile_image.get_height() == 450, "mobile landscape capture dimensions changed")

	if not failed:
		print("HENRY_QUIMERA_PRESENTATION_VISUAL_OK placeholder_only=true local=true remote=true desktop=1280x720 mobile=800x450 output=" + ProjectSettings.globalize_path(OUTPUT_DIR))
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _capture(file_name: String) -> Image:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_check(false, "blank capture " + file_name)
		return Image.new()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_check(image.save_png(OUTPUT_DIR.path_join(file_name)) == OK, "could not save " + file_name)
	return image


func _changed_pixels(before: Image, after: Image) -> int:
	if before == null or after == null or before.get_size() != after.get_size():
		return 0
	var changed := 0
	for y in range(0, before.get_height(), 2):
		for x in range(0, before.get_width(), 2):
			var before_color := before.get_pixel(x, y)
			var after_color := after.get_pixel(x, y)
			var delta := Vector4(before_color.r - after_color.r, before_color.g - after_color.g, before_color.b - after_color.b, before_color.a - after_color.a)
			if delta.length() > 0.08:
				changed += 1
	return changed
