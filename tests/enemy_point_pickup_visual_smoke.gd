extends SceneTree

const OUTPUT_DIR := "res://.codex/enemy_point_pickup_vfx"

var game: Node
var failed := false


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("ENEMY_POINT_PICKUP_VISUAL_FAIL requires rendered frames")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _capture(label: String) -> void:
	game.queue_redraw()
	for _frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = ProjectSettings.globalize_path(OUTPUT_DIR + "/" + label + ".png")
	if image.is_empty() or image.get_size() != Vector2i(1280, 720) or image.save_png(path) != OK:
		failed = true
		push_error("ENEMY_POINT_PICKUP_VISUAL_FAIL capture=" + label)


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.online_local_spectator = false
	game.is_dead = false
	game.player_hp = game.player_hp_max
	game.startup_thanks_done = true
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 1
	game.player_pos = Vector2(1600.0, 450.0)
	game.enemies.clear()
	game.heal_orbs.clear()
	game.effects.clear()
	game.shockwaves.clear()
	game.show_fps_counter = false
	for fixture in [
		{"offset": Vector2(-210.0, -80.0), "value": 8},
		{"offset": Vector2(190.0, -58.0), "value": 16},
		{"offset": Vector2(-170.0, 120.0), "value": 32},
		{"offset": Vector2(210.0, 115.0), "value": 64}
	]:
		game._spawn_enemy_point_drop(game.player_pos + Vector2(fixture["offset"]), int(fixture["value"]))
	await _capture("01_ground_drops")

	game.heal_orbs.clear()
	game._spawn_enemy_point_drop(game.player_pos + Vector2(250.0, -115.0), 12)
	game._spawn_enemy_point_drop(game.player_pos + Vector2(210.0, 120.0), 18)
	var chasing: Dictionary = game._spawn_enemy_point_drop(game.player_pos + Vector2(66.0, 0.0), 40)
	game._update_heal_orbs(0.016)
	# Simulate the playful attempt to escape after attraction has already locked.
	game.player_pos += Vector2(-300.0, 0.0)
	for step in range(30):
		game.player_pos += Vector2(-2.0, sin(float(step) * 0.35) * 0.35)
		game._update_heal_orbs(0.016)
	if int(chasing.get("magnet_peer_id", 0)) == 0 or float(chasing.get("magnet_speed", 0.0)) <= game.ENEMY_POINT_MAGNET_START_SPEED:
		failed = true
		push_error("ENEMY_POINT_PICKUP_VISUAL_FAIL chase did not activate")
	if not game.heal_orbs.has(chasing):
		failed = true
		push_error("ENEMY_POINT_PICKUP_VISUAL_FAIL chase ended before its visual sample")
	await _capture("02_accelerating_chase")

	for step in range(180):
		if not game.heal_orbs.has(chasing):
			break
		game._update_heal_orbs(0.016)
	if game.heal_orbs.has(chasing):
		failed = true
		push_error("ENEMY_POINT_PICKUP_VISUAL_FAIL chase did not end in absorption")
	game._update_shockwaves(0.08)
	await _capture("03_absorption_burst")

	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	if not failed:
		print("ENEMY_POINT_PICKUP_VISUAL_SMOKE_OK ground=true chase=true absorption=true captures=3")
	quit(1 if failed else 0)
