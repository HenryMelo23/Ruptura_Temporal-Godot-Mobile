extends SceneTree

const OUTPUT_DIR := "res://.agent_logs/auto_attack_range"
const CAPTURE_SIZE := Vector2i(960, 540)

var game: Node2D
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("AUTO_ATTACK_RANGE_VISUAL_FAIL " + message)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("AUTO_ATTACK_RANGE_VISUAL requires a real renderer")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = CAPTURE_SIZE
	root.content_scale_size = CAPTURE_SIZE
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.mode = "game"
	game.current_phase = 1
	game.startup_thanks_done = true
	game.show_fps_counter = false
	game.gfx_screen_shake = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(480.0, 270.0)
	game.enemies.clear()
	game.bullets.clear()
	game.enemy_bullets.clear()
	game.attack_holding = true
	game.set_process(false)
	game.set_physics_process(false)

	game.auto_attack_range_color_index = 1
	game.auto_attack_range_opacity = 1.0
	await _capture("range_ciano_100_960x540.png")
	_check(game.RangedAttackRange.indicator_color_name(game) == "CIANO", "cyan choice was not applied")

	game.auto_attack_range_color_index = 3
	game.auto_attack_range_opacity = 0.4
	await _capture("range_ambar_40_960x540.png")
	_check(game.RangedAttackRange.indicator_color_name(game) == "AMBAR", "amber choice was not applied")
	_check(is_equal_approx(game.RangedAttackRange.sanitize_indicator_opacity(game.auto_attack_range_opacity), 0.4), "40 percent opacity was not applied")

	if not failed:
		print("AUTO_ATTACK_RANGE_VISUAL_OK captures=2 colors=ciano,ambar opacity=100,40 size=960x540")
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failed else 0)


func _capture(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and image.get_size() == CAPTURE_SIZE, "invalid capture " + file_name)
	if image != null:
		_check(image.save_png(OUTPUT_DIR + "/" + file_name) == OK, "could not save " + file_name)
