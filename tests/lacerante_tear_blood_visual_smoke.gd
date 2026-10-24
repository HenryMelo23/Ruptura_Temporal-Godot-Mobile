extends SceneTree

# Visual verification test for Lacerante visceral teleport tear and dynamic passive blood/ground trail.

const OUT_DIR := "res://.agent_logs/lacerante_tear_runtime"
const OUT_TEAR := "res://.agent_logs/lacerante_tear_visceral_960x540.png"
const OUT_BLOOD := "res://.agent_logs/lacerante_blood_spurts_960x540.png"
const OUT_TRAIL := "res://.agent_logs/lacerante_ground_trail_960x540.png"

const LaceranteVfx = preload("res://scripts/presentation/lacerante_vfx_presentation.gd")

var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("LACERANTE_TEAR_VISUAL_FAIL " + message)
	quit(1)


func _capture(path: String) -> void:
	for frame in range(4):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != Vector2i(960, 540) or image.save_png(path) != OK:
		_fail("%s actual=%s" % [path, image.get_size() if image != null else Vector2i.ZERO])


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
	game.player_pos = Vector2(480.0, 270.0)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.last_damage_time = -999.0
	game.gfx_particles = true
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.gfx_screen_shake = false
	game.mobile_adaptive_visual_budget = false
	game.time_alive = 20.0
	game.process_mode = Node.PROCESS_MODE_DISABLED

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	await process_frame
	root.min_size = Vector2i.ZERO
	root.content_scale_size = Vector2i.ZERO
	DisplayServer.window_set_size(Vector2i(960, 540))
	root.size = Vector2i(960, 540)
	await process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	LaceranteVfx.reset()

	# Scenario 1: Visceral Teleport Tear ("Rasgo de Lacerado")
	var origin := Vector2(240.0, 270.0)
	var dest := Vector2(720.0, 270.0)
	game.player_pos = dest
	game.slashes.clear()
	game.slashes.append({
		"a": origin,
		"b": dest,
		"life": 2.5,
		"max": 3.0,
		"kind": "lacerante_tp",
		"color": Color(1.0, 0.08, 0.18),
		"width": 42.0
	})
	await _capture(OUT_TEAR)

	# Scenario 2: Lacerate Passive Applied - Enemies Gushing Dynamic Blood Spurts
	game.slashes.clear()
	LaceranteVfx.reset()
	game.enemies.clear()
	for i in range(3):
		var e_pos := Vector2(360.0 + float(i) * 120.0, 220.0 + float(i % 2) * 80.0)
		var enemy := {
			"uid": 1000 + i,
			"type": "comum",
			"pos": e_pos,
			"phase": float(i),
			"hp": 80.0,
			"max_hp": 80.0,
			"speed": 60.0,
			"laceracao": 2,
			"bleed_timer": 3.8
		}
		game.enemies.append(enemy)
		LaceranteVfx.on_lacerate_applied(game, enemy)

	# Advance physics slightly so droplets spray in mid-flight arcs
	LaceranteVfx.update(game, 0.12)
	if LaceranteVfx.flying_spurts.is_empty():
		_fail("blood-spurt scenario did not create flying droplets")
	await _capture(OUT_BLOOD)

	# Scenario 3: Progressive Ground Trail Marking as enemies move and bleed
	LaceranteVfx.flying_spurts.clear()
	for step in range(12):
		for enemy in game.enemies:
			enemy["pos"] = Vector2(enemy["pos"]) + Vector2(7.0, sin(float(step) * 0.4) * 4.0)
		LaceranteVfx.update(game, 0.12)

	await _capture(OUT_TRAIL)

	print("LACERANTE_TEAR_VISUAL_OK tear=%s blood=%s trail=%s" % [OUT_TEAR, OUT_BLOOD, OUT_TRAIL])
	quit(0)
