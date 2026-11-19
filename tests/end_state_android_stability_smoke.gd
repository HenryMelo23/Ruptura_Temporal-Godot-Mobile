extends SceneTree

var game: Node
var capture_dir: String = ""


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("END_STATE_ANDROID_STABILITY_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			capture_dir = arg.trim_prefix("--out=")
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _draw_current_mode(filename: String = "") -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		print("END_STATE_ANDROID_STABILITY_CAPTURE_SKIP headless=true")
		return
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_size() == Vector2i(1280, 720), "end screen did not render")
	_check(image.get_used_rect().has_area(), "end screen image is blank")
	if capture_dir != "" and filename != "":
		DirAccess.make_dir_recursive_absolute(capture_dir)
		_check(image.save_png(capture_dir.path_join(filename)) == OK, "could not save visual capture")


func _run() -> void:
	game._clear_interrupted_run_save()
	game.selected_manifestation = 0
	game.selected_aura = 0
	game._start_game()
	game.player_hp = 0
	game._handle_player_down()
	_check(game.mode == "death_slow", "defeat did not enter death slowdown")
	_check(game.is_dead, "defeat did not mark local death")
	_check(game.death_screen_delay_timer > 0.0, "death slowdown timer was not armed")
	_check(game.DEATH_SCREEN_SLOW_TIME >= 1.4, "death camera is too short to read")
	_check(game.death_screen_focus_pos.is_equal_approx(game.player_pos), "death camera did not capture the player position")
	await _draw_current_mode("death_camera_start.png")
	game.death_screen_delay_timer = game.DEATH_SCREEN_SLOW_TIME * 0.5
	await _draw_current_mode("death_camera_midpoint.png")
	var zoom: float = game.get_viewport().canvas_transform.get_scale().x
	_check(zoom > 1.08, "death camera did not approach the player")
	var grade := game.get_node_or_null("DeathCameraPostProcess/Grade") as ColorRect
	_check(grade != null and grade.visible, "death grayscale post-process is not visible")
	var grade_material := grade.material as ShaderMaterial
	_check(grade_material != null and float(grade_material.get_shader_parameter("amount")) > 0.25, "death grayscale did not progress")
	game.death_screen_delay_timer = game.DEATH_SCREEN_SLOW_TIME * 0.22
	await _draw_current_mode("death_camera_final.png")
	_check(game.get_viewport().canvas_transform.get_scale().x > 1.4, "death camera did not reach its final close-up")
	_check(float(grade_material.get_shader_parameter("amount")) > 0.8, "death grayscale did not reach monochrome")
	game._update_death_screen_delay(game.DEATH_SCREEN_SLOW_TIME + 0.02)
	_check(game.mode == "specter_upgrade", "defeat did not open post-death specter screen")
	_check(game.run_finalized_result == "Derrota", "defeat did not finalize exactly once")
	game._handle_player_down()
	_check(game.mode == "specter_upgrade", "second death handling changed mode")
	_check(game.run_finalized_result == "Derrota", "second death handling changed final result")
	game._return_from_specter_upgrade()
	_check(game.mode == "game_over", "specter screen did not return to game_over")
	await _draw_current_mode()
	_check(not FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH), "defeat left an interrupted-run save")

	game._start_game()
	game._finalize_run_report("Vitoria")
	game.mode = "victory"
	_check(game.mode == "victory", "victory finalization did not enter victory")
	_check(game.run_finalized_result == "Vitoria", "victory did not finalize exactly once")
	game._finalize_run_report("Vitoria")
	_check(game.mode == "victory", "second victory finalization changed mode")
	_check(game.run_finalized_result == "Vitoria", "second victory finalization changed final result")
	await _draw_current_mode()
	_check(not FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH), "victory left an interrupted-run save")

	print("END_STATE_ANDROID_STABILITY_SMOKE_OK defeat=true victory=true idempotent=true rendered=true")
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	game = null
	await process_frame
	quit(0)
