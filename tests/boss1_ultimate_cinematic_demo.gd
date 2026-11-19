extends SceneTree

## Demonstracao da ultimate do Cronoguejo: Geovana anda criando historico, a onda
## temporal sai do boss, acerta e roda a cinematica do rewind (camera + relogio).
## Uso: -- --frames=<dir> (salva quadros a ~20 fps em 640x360) e checagens basicas.
const DT := 1.0 / 60.0
const STEP := 3
var game: Node
var frames_dir := ""
var seq := 0
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("BOSS1_ULT_CINEMATIC " + message)


func _frame(step: int) -> void:
	if frames_dir == "" or step % STEP != 0:
		return
	game.queue_redraw()
	await process_frame
	var img := root.get_texture().get_image()
	img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
	img.save_png("%s/f_%03d.png" % [frames_dir, seq])
	seq += 1


func _run() -> void:
	game.startup_thanks_done = true
	game.forced_initial_phase = 1
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 1
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 1400.0
	game.player_hp_max = 450
	game.player_hp = 300
	game.enemies.clear()
	game.boss_pos = game.WORLD_SIZE * 0.5
	var start: Vector2 = game.boss_pos + Vector2(330.0, 60.0)
	game.player_pos = start
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	var step := 0
	# 1) Historico: a Geovana faz um arco em volta do boss (o rewind vai desfazer isso).
	for i in range(int(2.6 / DT)):
		game.time_alive += DT
		game.elapsed_unpaused += DT
		var a := float(i) * DT * 0.9
		game.player_pos = game.boss_pos + Vector2.from_angle(a * -0.9 + 0.18) * Vector2(330.0, 230.0)
		game.early_boss_controller.record_boss1_rewind_history(DT)
		step += 1
		if i > int(1.6 / DT):
			await _frame(step)
	# 2) Ultimate: onda temporal ate acertar.
	game.boss1_rewind_cooldown = 0.0
	game.early_boss_controller.start_boss1_time_wave()
	_check(not game.boss1_time_wave.is_empty(), "time wave did not start")
	var guard := 0
	while game.boss1_rewind_sequence.is_empty() and guard < 600:
		guard += 1
		game.time_alive += DT
		game.elapsed_unpaused += DT
		game.early_boss_controller.update_boss1_time_wave(DT)
		step += 1
		await _frame(step)
	_check(not game.boss1_rewind_sequence.is_empty(), "wave never hit the player")
	# 3) Cinematica do rewind.
	var saw_zoom := false
	var saw_tilt := false
	var total: float = RTRewindCamera.total_time(game)
	var t := 0.0
	while not game.boss1_rewind_sequence.is_empty() and t < total + 1.0:
		t += DT
		game.early_boss_controller.update_boss1_rewind_sequence(DT)
		step += 1
		game.queue_redraw()
		await process_frame
		var xf: Transform2D = root.canvas_transform
		if xf.get_scale().x > 1.1:
			saw_zoom = true
		if absf(xf.get_rotation()) > 0.02:
			saw_tilt = true
		await _frame(step)
	_check(saw_zoom, "camera never zoomed")
	_check(saw_tilt, "camera never tilted back")
	_check(game.player_pos.distance_to(start) < 60.0, "player was not rewound to the start of the history")
	# 4) Clarao de linha restaurada e camera de volta ao normal.
	for i in range(int(0.6 / DT)):
		game.time_alive += DT
		step += 1
		game.queue_redraw()
		await process_frame
		await _frame(step)
	_check(root.canvas_transform == Transform2D.IDENTITY, "camera did not reset")
	print("BOSS1_ULT_CINEMATIC_%s frames=%d" % ["FAIL" if failed else "OK", seq])
	quit(1 if failed else 0)
