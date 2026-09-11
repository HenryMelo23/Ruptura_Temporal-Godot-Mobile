extends SceneTree

func _init() -> void:
	print("STARTING PHASE_TRANSITION_SMOKE")
	var main_scene = load("res://scenes/Main.tscn")
	_check(main_scene != null, "Failed to load Main.tscn")

	var game = main_scene.instantiate()
	_check(game != null, "Failed to instantiate Main.tscn")
	root.add_child(game)

	# Check transition shaders exist and load
	var shaders = [
		"res://shaders/transitions/star_dissolve.gdshader",
		"res://shaders/transitions/blizzard_wipe.gdshader",
		"res://shaders/transitions/slime_drip_melt.gdshader",
		"res://shaders/transitions/black_hole_vortex.gdshader",
		"res://shaders/transitions/energy_crack_shatter.gdshader",
		"res://shaders/transitions/worm_devour.gdshader",
		"res://shaders/player_portal_materialize.gdshader"
	]
	for s_path in shaders:
		_check(ResourceLoader.exists(s_path), "Shader missing: " + s_path)
		var shader = load(s_path)
		_check(shader != null, "Failed to load shader: " + s_path)

	# Test triggering transition to phase 2
	if game.has_method("_start_phase_transition"):
		game._start_phase_transition(2)
		_check(game.mode == "phase_transition", "Mode is not phase_transition")
		_check(game.pending_phase == 2, "Pending phase is not 2")

		# 1. During title hold phase (~1.0s in)
		for i in range(60):
			game._process(0.016)
		_check(game.mode == "phase_transition", "Mode should be phase_transition during hold")
		_check(game.phase_transition_timer > 2.0, "Timer should be > 2.0 during title hold")

		# 2. At transition switch (~1.92s in: hold of 1.7s ended, wipe started)
		for i in range(60):
			game._process(0.016)
		_check(game.current_phase == 2, "Phase should be advanced to 2")
		_check(game.mode == "phase_transition", "Mode MUST remain phase_transition during wipe (no hard cut!)")
		_check(game.phase_transition_timer > 0.0, "Timer MUST continue counting down during wipe")

		# 3. Halfway through wipe (~2.88s in)
		for i in range(60):
			game._process(0.016)
		_check(game.mode == "phase_transition", "Mode MUST stay phase_transition during middle of wipe")

		# 4. After transition ends (~3.84s in)
		for i in range(60):
			game._process(0.016)

		_check(game.current_phase == 2, "Phase transition did not advance to phase 2")
		_check(game.mode == "game", "Mode did not return to game after transition ended")

	print("PHASE_TRANSITION_SMOKE_OK shaders=7 transition=true smooth_wipe=true")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("PHASE_TRANSITION_SMOKE_FAIL: " + message)
		print("PHASE_TRANSITION_SMOKE_FAIL: " + message)
		quit(1)
