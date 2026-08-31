extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node
var captures: Array[String] = []


func _fail(message: String) -> void:
	push_error("PLAYER_FEEDBACK_VISUAL_FAIL " + message)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.ui_platform_override = "desktop"
	game.ui_platform_override_unlocked = true
	game._start_game(false)
	game.player_pos = Vector2(640, 420)
	game.current_phase = 1
	game.player_hp_max = 450
	game.player_hp = 118
	game.damage_flash_timer = 0.22
	game.time_alive = 18.0

	var fall_frames: Array = game.textures.get("player_start_down", [])
	_check(fall_frames.size() == 6 and fall_frames.all(func(t): return t is Texture2D), "start down frames were not packaged or loaded")

	game.player_start_down_fall_timer = 0.34
	game.player_start_down_landing_timer = 0.0
	game.player_start_down_smoke_spawned = false
	await _capture("player_start_down_fall_1280x720.png")

	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.72
	game.player_start_down_smoke_spawned = true
	game.effects.clear()
	game._spawn_player_landing_smoke(game.player_pos)
	game._spawn_bullet_hit_fragments(game.player_pos + Vector2(132, -22), {
		"kind": "eletrica",
		"color": Color(0.36, 1.0, 0.94),
		"dir": Vector2.RIGHT
	})
	_check(game.effects.any(func(e): return String(Dictionary(e).get("kind", "")) == "landing_smoke"), "landing smoke particles were not spawned")
	_check(game.effects.any(func(e): return String(Dictionary(e).get("kind", "")) == "bullet_fragment"), "bullet hit fragments were not spawned")
	await _capture("player_feedback_damage_impact_1280x720.png")

	print("PLAYER_FEEDBACK_VISUAL_OK captures=", ", ".join(captures))
	game.queue_free()
	await process_frame
	quit(0)


func _capture(file_name: String, capture_size := Vector2i(1280, 720)) -> void:
	root.size = capture_size
	game.buttons.clear()
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == capture_size.x and image.get_height() == capture_size.y, "invalid capture " + file_name)
	_check(image.get_used_rect().size.x > int(float(capture_size.x) * 0.72) and image.get_used_rect().size.y > int(float(capture_size.y) * 0.72), "blank capture " + file_name)
	var output := OUT_DIR + "/" + file_name
	_check(image.save_png(output) == OK, "could not save " + file_name)
	captures.append(ProjectSettings.globalize_path(output))
