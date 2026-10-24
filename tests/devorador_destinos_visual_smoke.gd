extends SceneTree

const Presentation = preload("res://scripts/presentation/devorador_destinos_presentation.gd")
var game: Node
var canvas: SubViewport
var failed := false
var captures := 0
var mesh_ids: Array[int] = []
var output := "res://.codex/devorador_destinos/"


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("DEVORADOR_VISUAL_FAIL rendered frames required")
		quit(1)
		return
	if "--before" in OS.get_cmdline_user_args():
		output = "res://.codex/devorador_destinos_before/"
	canvas = SubViewport.new()
	canvas.size = Vector2i(1280, 720)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	game = load("res://scenes/Main.tscn").instantiate()
	canvas.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		printerr("DEVORADOR_VISUAL_FAIL " + message)


func _enemy(pos: Vector2, hp: float) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["stun"] = 999.0
	return enemy


func _run() -> void:
	Presentation.warmup()
	for mesh in Presentation._meshes:
		mesh_ids.append(mesh.get_instance_id())
	game.forced_initial_phase = 1
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.gfx_particles = true
	game.gfx_low_resource = false
	game.gfx_screen_shake = false
	game.show_fps_counter = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(640, 400)
	game.time_alive = 4.0
	game.enemies.clear()
	game.cards_bought["devorador_destinos"] = 1
	var target := _enemy(Vector2(820, 400), 1500.0)
	var neighbor := _enemy(Vector2(860, 445), 1000.0)
	_enemy(Vector2(735, 455), 1000.0)
	game._apply_devorador_enemy_mark(target)
	await _capture("01_mark_1280x720.png")
	canvas.size = Vector2i(960, 540)
	await _capture("02_mark_960x540.png")
	canvas.size = Vector2i(1280, 720)
	game._handle_devorador_enemy_death(target)
	game.enemies.erase(target)
	_check(float(neighbor["hp"]) < 1000.0, "real proc did not damage neighbor")
	_check(game.devorador_destiny_shield > 0.0, "real proc did not grant shield")
	game.effects.clear()
	for step in [["03_open", 0.08], ["04_bite", 0.35], ["05_release", 0.65], ["06_fade", 0.9]]:
		_set_burst_progress(float(step[1]))
		await _capture(String(step[0]) + "_1280x720.png")
	if "--motion" in OS.get_cmdline_user_args():
		for index in range(28):
			_set_burst_progress(float(index) / 28.0)
			game.time_alive = 4.0 + float(index) / 50.0
			await _capture("motion/burst_%02d.png" % index)
	game.devorador_effects.clear()
	game.shockwaves.clear()
	game.effects.clear()
	game.devorador_shield_timer = 6.0
	await _capture("07_shield_1280x720.png")
	game.devorador_shield_timer = 0.4
	await _capture("08_shield_expiring_1280x720.png")
	game.devorador_shield_timer = 0.0
	game.devorador_destiny_shield = 0.0
	game.enemies.clear()
	game.boss_active = true
	game.boss_dead = false
	game.boss_ready = true
	game.boss_entry_timer = 0.0
	game.boss_pos = Vector2(860, 400)
	game.boss_hp_max = 20000.0
	game.boss_hp = 20000.0
	game._apply_devorador_boss_mark()
	await _capture("09_boss_mark_1280x720.png")
	game.boss_hp = 18800.0
	await _capture("10_boss_charged_1280x720.png")
	game._damage_boss(1000.0, "test", false, false)
	_check(game.devorador_mark_kind == "", "real boss rupture did not trigger")
	_set_burst_progress(0.35)
	await _capture("11_boss_rupture_1280x720.png")
	canvas.size = Vector2i(960, 540)
	game.gfx_low_resource = true
	game.gfx_particles = false
	await _capture("12_boss_low_960x540.png")
	game._reset_card_proc_state()
	await _capture("13_reset_960x540.png")
	_check(game.devorador_effects.is_empty() and game.devorador_shield_timer == 0.0, "reset left visual state")
	_check(Presentation._meshes.size() == mesh_ids.size(), "mesh count grew")
	for index in range(mesh_ids.size()):
		_check(Presentation._meshes[index].get_instance_id() == mesh_ids[index], "mesh recreated")
	if not failed:
		print("DEVORADOR_VISUAL_OK captures=%d desktop=1280x720 low=960x540 real_enemy_proc=true real_boss_proc=true reset=true stable_resources=true render_preserves_hp=true output=%s" % [captures, ProjectSettings.globalize_path(output)])
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	canvas.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _set_burst_progress(progress: float) -> void:
	for event in game.devorador_effects:
		event["life"] = float(event["max"]) * (1.0 - progress)
		event["phase"] = 0.7
		game.devorador_shield_timer = game.DEVORADOR_SHIELD_DURATION - float(event["max"]) * progress
	# Generic particles do not advance with the frozen fixture.
	game.effects.clear()


func _capture(name: String) -> void:
	var player_hp: float = game.player_hp
	var boss_hp: float = game.boss_hp
	var shield: float = game.devorador_destiny_shield
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = canvas.get_texture().get_image()
	_check(game.player_hp == player_hp and game.boss_hp == boss_hp and game.devorador_destiny_shield == shield, "drawing changed combat state")
	_check(image != null and not image.is_empty() and image.get_size() == canvas.size, "invalid capture " + name)
	var path := output + name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_check(image.save_png(path) == OK, "save failed " + name)
	captures += 1
