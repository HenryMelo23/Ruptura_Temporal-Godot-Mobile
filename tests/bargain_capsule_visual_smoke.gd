extends SceneTree

const CAPTURE_SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(960, 540)]
const BargainCapsulePresentation = preload("res://scripts/presentation/bargain_capsule_presentation.gd")

var game: Node
var failures: Array[String] = []
var capture_prefix: String = "after"


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-prefix="):
			capture_prefix = argument.trim_prefix("--capture-prefix=").strip_edges()
	root.size = CAPTURE_SIZES[0]
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _capsule_snapshot(state: String, timer: float, hp_ratio: float, visual_age: float = 0.0, hit_flash: float = 0.0) -> Dictionary:
	var max_hp: float = 170.0
	return {
		"id": "visual_%s_%s" % [capture_prefix, state],
		"state": state,
		"pos": game.player_pos + Vector2(155.0, 15.0),
		"target_pos": game.player_pos + Vector2(155.0, 15.0),
		"timer": timer,
		"fall_time": game.BARGAIN_CAPSULE_FALL_TIME,
		"hp": max_hp * hp_ratio,
		"max_hp": max_hp,
		"collapse_time": 8.0,
		"collapse_max": game.BARGAIN_CAPSULE_ACTIVE_TIME,
		"cleanup_time": game.BARGAIN_CAPSULE_CLEANUP_TIME,
		"visual_state_age": visual_age,
		"hit_flash": hit_flash,
		"seed": 41,
		"result": "success" if state == game.BARGAIN_CAPSULE_STATE_SUCCESS else ("fail" if state == game.BARGAIN_CAPSULE_STATE_FAIL else "")
	}


func _capture(label: String, snapshot: Dictionary) -> void:
	game.bargain_capsule = snapshot
	for size in CAPTURE_SIZES:
		root.size = size
		root.content_scale_size = size
		game.queue_redraw()
		await process_frame
		await process_frame
		var image: Image = root.get_texture().get_image()
		_check(image != null and image.get_size() == size, "invalid capture %s %s" % [label, size])
		if image != null:
			var path: String = "res://.agent_logs/bargain_%s_%s_%dx%d.png" % [capture_prefix, label, size.x, size.y]
			_check(image.save_png(ProjectSettings.globalize_path(path)) == OK, "could not save " + path)


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs"))
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.boss_call_tutorial_seen = true
	game.shop_tutorial_seen = true
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.boss_ready = false
	game.time_alive = 30.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.gfx_low_resource = false
	game.enemies.clear()
	game.heal_orbs.clear()
	game.effects.clear()
	_check(load(BargainCapsulePresentation.MOTION_RESULTS_PATH).get_size() == Vector2(576, 384), "motion/result atlas size drifted")
	_check(load(BargainCapsulePresentation.IDLE_DAMAGE_PATH).get_size() == Vector2(576, 384), "idle/damage atlas size drifted")
	_check(load(BargainCapsulePresentation.HIT_REACTION_PATH).get_size() == Vector2(576, 96), "hit atlas size drifted")

	await _capture("preparing", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_PREPARING, 0.48, 1.0))
	await _capture("fall_start", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_FALLING, 0.82, 1.0, 0.08))
	await _capture("fall_mid", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_FALLING, 0.45, 1.0, 0.45))
	await _capture("fall_end", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_FALLING, 0.08, 1.0, 0.82))
	await _capture("impact", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_ACTIVE, 0.0, 1.0, 0.12))
	await _capture("active", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_ACTIVE, 0.0, 1.0, 0.8))
	await _capture("hit", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_ACTIVE, 0.0, 0.82, 1.0, 0.18))
	await _capture("damaged", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_ACTIVE, 0.0, 0.55, 1.2))
	await _capture("critical", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_ACTIVE, 0.0, 0.22, 1.4))
	await _capture("success", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_SUCCESS, 0.0, 0.0, 0.48))
	await _capture("fail", _capsule_snapshot(game.BARGAIN_CAPSULE_STATE_FAIL, 0.0, 0.0, 0.48))

	game.bargain_capsule.clear()
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("BARGAIN_CAPSULE_VISUAL_SMOKE_OK prefix=%s captures=%d" % [capture_prefix, CAPTURE_SIZES.size() * 11])
	quit(0 if failures.is_empty() else 1)
