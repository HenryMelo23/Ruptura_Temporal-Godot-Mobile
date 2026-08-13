extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node
var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("TUTORIAL_RUN_SMOKE_FAIL " + message)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game._set_run_tutorial_enabled(true, false)
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	_check(game.tutorial_state == game.TUTORIAL_STATE_OFFER, "tutorial offer did not open on fresh run")
	_check(game._tutorial_blocks_normal_spawn(), "tutorial offer does not block normal spawn")
	_check(game.effects.is_empty(), "startup floating texts were not cleared for tutorial offer")
	await _capture("tutorial_offer_1280x720.png")
	root.size = Vector2i(960, 540)
	await process_frame
	await _capture("tutorial_offer_960x540.png", Vector2i(960, 540))
	root.size = Vector2i(1280, 720)
	await process_frame

	game._accept_tutorial_offer(true)
	_check(game.tutorial_state == game.TUTORIAL_STATE_ATTACK, "tutorial did not enter attack step")
	_check(game.enemies.size() == 1, "attack step did not create one training enemy")
	_check(bool(game.enemies[0].get("tutorial", false)), "training enemy was not marked")
	_check(float(game.enemies[0].get("damage", 999.0)) <= 8.0, "training damage is not reduced")
	_check(float(game.enemies[0].get("speed", 999.0)) <= game.enemy_speed_base * 0.45, "training speed is not reduced")
	await _capture("tutorial_attack_1280x720.png")
	root.size = Vector2i(960, 540)
	await process_frame
	await _capture("tutorial_attack_960x540.png", Vector2i(960, 540))
	root.size = Vector2i(1280, 720)
	await process_frame

	var target: Dictionary = game.enemies[0]
	game._kill_enemy(target)
	_check(game.tutorial_state == game.TUTORIAL_STATE_SKILL, "attack kill did not advance to HAB1")
	game.tutorial_action_grace = 0.0
	game._tutorial_note_action("skill")
	_check(game.tutorial_state == game.TUTORIAL_STATE_SECONDARY, "HAB1 action did not advance to secondary")
	game.tutorial_action_grace = 0.0
	game._tutorial_note_action("secondary")
	_check(game.tutorial_state == game.TUTORIAL_STATE_DASH, "secondary action did not advance to dash")
	game.tutorial_action_grace = 0.0
	game._tutorial_note_action("dash")
	_check(game.tutorial_state == game.TUTORIAL_STATE_MANIFESTATION, "dash action did not advance to manifestation context")
	game._continue_tutorial_story()
	_check(game.tutorial_state == game.TUTORIAL_STATE_AURA, "manifestation context did not advance to aura")
	game._continue_tutorial_story()
	_check(game.tutorial_state == game.TUTORIAL_STATE_ESSENCE, "aura context did not advance to essence")
	game._continue_tutorial_story()
	_check(game.tutorial_state == game.TUTORIAL_STATE_FINISH, "essence context did not advance to finish")
	game._continue_tutorial_story()
	_check(game.tutorial_state == game.TUTORIAL_STATE_NONE, "tutorial did not finish")
	_check(is_zero_approx(game.spawn_timer), "normal spawn was not released after tutorial")
	_check(not game.run_tutorial_enabled, "completed tutorial did not disable future offers")

	game._start_game()
	game.set_process(false)
	_check(game.tutorial_state == game.TUTORIAL_STATE_NONE, "completed tutorial offered again without settings reactivation")
	_check(game.effects.is_empty(), "normal run kept startup floating texts")

	_check(game._gameplay_preference_keys().has("tutorial"), "gameplay settings do not expose tutorial toggle")
	game.mode = "settings_gameplay"
	game._set_run_tutorial_enabled(true, false)
	await _capture("settings_gameplay_tutorial_1280x720.png")
	root.size = Vector2i(960, 540)
	await process_frame
	await _capture("settings_gameplay_tutorial_960x540.png", Vector2i(960, 540))
	root.size = Vector2i(1280, 720)
	await process_frame
	game._set_run_tutorial_enabled(true, false)
	game._start_game()
	game.set_process(false)
	_check(game.tutorial_state == game.TUTORIAL_STATE_OFFER, "settings-reactivated tutorial did not offer")
	game._accept_tutorial_offer(false)
	_check(game.tutorial_state == game.TUTORIAL_STATE_NONE, "declining tutorial did not return to normal run")
	_check(game.spawn_timer <= 0.2, "declined tutorial did not release normal spawn soon")
	_check(not game.run_tutorial_enabled, "declining tutorial did not disable future offers")

	if failed:
		_cleanup()
		quit(1)
		return
	print("TUTORIAL_RUN_SMOKE_OK " + ProjectSettings.globalize_path(OUT_DIR))
	_cleanup()
	quit(0)


func _capture(file_name: String, expected_size: Vector2i = Vector2i(1280, 720)) -> void:
	game.queue_redraw()
	await process_frame
	if DisplayServer.get_name() == "headless":
		return
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == expected_size.x and image.get_height() == expected_size.y, "invalid capture " + file_name)
	if image != null:
		_check(image.save_png(OUT_DIR + "/" + file_name) == OK, "could not save " + file_name)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
	game = null
