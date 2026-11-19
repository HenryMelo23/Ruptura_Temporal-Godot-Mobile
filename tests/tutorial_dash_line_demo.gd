extends SceneTree

var game: Node

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")

func _shot(i: int) -> void:
	await process_frame
	var img: Image = root.get_texture().get_image()
	img.resize(640, 360)
	img.save_png(ProjectSettings.globalize_path("res://.agent_logs/tutgif/f_%03d.png" % i))

func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game._set_run_tutorial_enabled(true, false)
	game.forced_initial_phase = 0
	game._start_game()
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game._accept_tutorial_offer(true)
	game.desktop_attack_aim_mode = game.DESKTOP_ATTACK_AIM_AUTO
	game._advance_tutorial(RTTutorialGuide.STATE_DASH_LINE)
	var guide: RTTutorialGuide = game._tutorial_guide()
	var i := 0
	for k in range(34):
		game.player_pos.x += 9.0
		game.last_facing = Vector2.RIGHT
		await _shot(i); i += 1
	for k in range(10):
		await _shot(i); i += 1
	game.tutorial_action_grace = 0.0
	game.last_facing = Vector2.RIGHT
	game._try_dash()
	for k in range(26):
		if game.tutorial_state == RTTutorialGuide.STATE_DASH_LINE:
			game.player_pos.x += 6.0
		await _shot(i); i += 1
	print("DEMO_DONE state=", game.tutorial_state, " cleared=", guide.line_cleared)
	quit(0)
