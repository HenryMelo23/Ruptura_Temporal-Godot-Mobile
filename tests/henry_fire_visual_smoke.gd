extends SceneTree

const Fire = preload("res://scripts/presentation/henry_fire_presentation.gd")
const OUTPUT := "res://.codex/henry_fire/"
var game: Node
var canvas: SubViewport
var failed := false

func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("HENRY_FIRE_VISUAL_FAIL requires rendered frames")
		quit(1)
		return
	canvas = SubViewport.new()
	canvas.size = Vector2i(1280, 720)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	game = load("res://scenes/Main.tscn").instantiate()
	canvas.add_child(game)
	call_deferred("run")

func run() -> void:
	await process_frame
	game.set_process(false)
	game.run_tutorial_enabled = false
	game.forced_initial_phase = 1
	game.active_character_key = game.CHARACTER_HENRY
	game._start_game()
	game.mode = "game"
	game.startup_thanks_done = true
	game.startup_thanks_timer = 0.0
	game.startup_thanks_fading = false
	game.gfx_particles = true
	game.gfx_low_resource = false
	game.gfx_screen_shake = false
	game.show_fps_counter = false # Capturing images is not a frame-rate benchmark.
	game.player_pos = Vector2(800, 450)
	game.enemies.clear()
	for i in range(4):
		game._spawn_enemy(game.ENEMY_COMMON, Vector2(600 + 120 * i, 370 + (i % 2) * 140))
	game._update_game(0.6)
	await capture("entry_01_wander")
	game._update_game(0.9)
	await capture("entry_02_slow")
	game._update_game(0.7)
	await capture("entry_03_frozen_materialize")
	game._update_game(2.6)
	await capture("entry_04_glasses")
	game._update_game(0.3)
	await capture("entry_05_released")
	game.enemies.clear()
	game.henry_incendiary_ability_controller.reset()
	game.last_attack_time = -99.0
	var owner = game.henry_incendiary_ability_controller
	owner.begin_skill(game.player_pos + Vector2.RIGHT * 400)
	owner.update(0.46)
	await capture("fire_q_high")
	owner.update(0.16)
	await capture("fire_q_high_later")
	game.gfx_low_resource = true
	canvas.size = Vector2i(960, 540)
	await capture("fire_q_low")
	owner.reset()
	game.gfx_low_resource = false
	canvas.size = Vector2i(1280, 720)
	owner.cast_ultimate()
	owner.update(0.55)
	await capture("fire_e_charge_high")
	owner.update(0.26)
	owner.update(0.3)
	await capture("fire_e_wave_high")
	game.gfx_low_resource = true
	canvas.size = Vector2i(960, 540)
	await capture("fire_e_wave_low")
	if Fire.flame_meshes.size() != Fire.VARIANTS:
		failed = true
		printerr("HENRY_FIRE_VISUAL_FAIL unbounded mesh cache")
	print("HENRY_FIRE_VISUAL_OK captures=11 exact_sizes=true mesh_cache=%d" % Fire.flame_meshes.size())
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	canvas.queue_free()
	await process_frame
	quit(1 if failed else 0)

func capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = canvas.get_texture().get_image()
	if screenshot.get_size() != canvas.size:
		failed = true
		printerr("HENRY_FIRE_VISUAL_FAIL wrong image size " + label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	if screenshot.save_png(OUTPUT + label + ".png") != OK:
		failed = true
