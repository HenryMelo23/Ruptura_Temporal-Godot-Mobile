extends SceneTree

var game: Node
var before := false
var out_dir := "res://.agent_logs/fenix_fire_after"


func _initialize() -> void:
	before = "--before" in OS.get_cmdline_user_args()
	if before:
		out_dir = "res://.agent_logs/fenix_fire_before"
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(out_dir + "/" + label + ".png")
	assert(result == OK, "Fenix capture failed: " + label)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game._start_game(false)
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 7
	game.mode = "game"
	game.player_pos = Vector2(800, 520)
	game.player_hp = game.player_hp_max
	game.last_damage_time = -100.0
	game.last_attack_time = -100.0
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 10000.0
	game.boss_hp = 2900.0
	game.boss_name = "FENIX"
	game.boss_pos = Vector2(820, 270)
	game.boss7_state = game.BOSS7_STATE_FLY
	game.boss_entry_timer = 0.0
	game.enemies.clear()
	game.effects.clear()
	game.enemy_bullets.clear()
	game.boss_attacks.clear()
	game._check_boss7_ultimate(0.0)
	for elapsed in [1.0, 5.0, 9.0, 15.0, 25.0, 37.0, 48.0]:
		game.boss7_ultimate_timer = 50.0 - elapsed
		game._update_boss7_ultimate(0.0)
		game.time_alive = 100.0 + elapsed
		await _capture("quadrants_%02d" % int(elapsed))
	game.boss7_ultimate_active = false
	game._spawn_boss7_flame_wave(Vector2(570, 525), 375.0)
	game.boss7_flame_waves[0]["radius"] = 155.0
	game.enemy_bullets = [
		{"type": "boss7_dive_fireball", "pos": Vector2(1040, 440), "dir": Vector2.DOWN, "radius": 38.0, "phase": 0.8},
		{"type": "phase7_fireball", "pos": Vector2(760, 490), "dir": Vector2.LEFT, "radius": 14.0, "phase": 1.2}]
	game.boss_attacks = [
		{"kind": game.BOSS7_ATTACK_DIVE_TRAIL, "a": Vector2(400, 650), "b": Vector2(1180, 650), "age": 0.6, "duration": 3.2},
		{"kind": game.BOSS7_ATTACK_THERMAL, "spots": [Vector2(1050, 580)], "age": 0.95, "duration": 1.25, "fired": true}]
	await _capture("fire_abilities")
	# Advance the same draw paths through many phases to catch degenerate geometry.
	for step in range(45):
		game.time_alive += 1.0 / 30.0
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
	await _capture("fire_motion_later")
	game.boss_attacks = [
		{"kind": game.BOSS7_ATTACK_FEATHER, "pos": Vector2(620, 510), "dir": Vector2.LEFT, "age": 0.2, "phase": 0.4},
		{"kind": game.BOSS7_ATTACK_WING, "origin": Vector2(820, 460), "dir": Vector2.LEFT, "age": 0.6, "duration": 1.2},
		{"kind": game.BOSS7_ATTACK_ASH_RAIN, "age": 0.8, "drops": [
			{"pos": Vector2(1050, 540), "age": 0.3, "warn": 0.52, "hit": false},
			{"pos": Vector2(1080, 650), "age": 0.7, "warn": 0.52, "hit": true}]},
		{"kind": game.BOSS7_ATTACK_CROWN, "age": 1.65, "duration": 2.1}]
	await _capture("feathers_wing_ash_crown")
	game.gfx_low_resource = true
	game.gfx_memory_saver = true
	game.gfx_particles = false
	game._apply_graphics_settings()
	root.size = Vector2i(960, 540)
	await _capture("fire_mobile_low")
	game.boss7_ultimate_active = true
	game.boss7_ultimate_timer = 35.0
	game._update_boss7_ultimate(0.0)
	game.enemy_bullets.clear()
	game.boss_attacks.clear()
	game.boss7_flame_waves.clear()
	await _capture("quadrants_mobile_low")
	# Check the budget inside a draw callback, with all visible active quadrants.
	var budget_canvas := Node2D.new()
	root.add_child(budget_canvas)
	budget_canvas.draw.connect(func():
		var count: int = game.PhoenixFire.draw_quadrants(budget_canvas, Vector2.ZERO, Vector2(1600, 900), game.WORLD_SIZE, 15.0, game.time_alive, true)
		assert(count <= game.PhoenixFire.LOW_FLAME_CAP, "Fenix exceeded low visual budget"))
	budget_canvas.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	budget_canvas.queue_free()
	print("BOSS7_FIRE_VISUAL_OK before=", before, " desktop=1280x720 mobile=960x540 particles_disabled=true")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	quit()
