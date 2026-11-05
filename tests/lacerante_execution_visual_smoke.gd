extends SceneTree

## Captura as 5 execucoes da Lacerante com a folha de sprites e monta uma prancha.
## Uso: xvfb-run ... --script res://tests/lacerante_execution_visual_smoke.gd -- --out=/abs/dir
const DT := 1.0 / 60.0
var game: Node2D
var out_dir := "user://lacerante_exec_visual"


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_dir = a.substr(6)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _crop() -> Image:
	var img := root.get_texture().get_image()
	var c := Vector2i(game.get_viewport_rect().size * 0.5)
	return img.get_region(Rect2i(c - Vector2i(150, 130), Vector2i(300, 200)))


func _clear_fx() -> void:
	for key in ["floating_texts", "effects", "particles", "shockwaves", "heal_orbs"]:
		if key in game and game.get(key) is Array:
			(game.get(key) as Array).clear()


func _run() -> void:
	game.startup_thanks_done = true
	game.unlocked_manifestation_ids["lacerante"] = true
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i]["key"]) == "lacerante":
			game.selected_manifestation = i
	game.run_tutorial_enabled = false
	game.forced_initial_phase = 1
	game._start_game()
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.set_process(false)
	var ex: RTLaceranteExecutionController = game._lacerante_exec()
	var ok := RTLaceranteExecutionVfx.sheet() != null
	DirAccess.make_dir_recursive_absolute(out_dir)
	var board := Image.create(300 * 6, 200 * 5, false, Image.FORMAT_RGBA8)
	board.fill(Color(0.08, 0.08, 0.1))
	for anim in range(5):
		game.enemies.clear()
		ex.reset()
		_clear_fx()
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(70, 0))
		var e: Dictionary = game.enemies[-1]
		e["pos"] = game.player_pos + Vector2(70, 0)
		e["hp"] = 5.0
		e["max_hp"] = 1000.0
		e["speed"] = 0.0
		# Referencia: Geovana parada antes de executar.
		game.queue_redraw()
		await process_frame
		await process_frame
		if anim == 0:
			board.blit_rect(_crop(), Rect2i(0, 0, 300, 200), Vector2i(0, 0))
		ex.last_animation = (anim + 4) % 5
		game.rng.seed = 7
		ex._start(e)
		if not ex.is_active():
			print("LACERANTE_EXEC_VISUAL_FAIL could not start anim %d" % anim)
			quit(1)
			return
		ex.active["anim"] = anim
		var shots := [0.05, 0.2, 0.38, 0.56, 0.74]
		var col := 1
		var t := 0.0
		while ex.is_active() and col <= shots.size():
			ex.update(DT)
			ex.cine.clear()  # sem zoom de camera: compara escala 1:1 com a Geovana normal
			RTExecutionCamera.clear(game)
			t += DT
			if t >= float(shots[col - 1]):
				_clear_fx()
				game.queue_redraw()
				await process_frame
				await process_frame
				board.blit_rect(_crop(), Rect2i(0, 0, 300, 200), Vector2i(300 * col, 200 * anim))
				col += 1
		game.lacerante_execution.cine.clear()
		RTExecutionCamera.clear(game)
	board.save_png(out_dir + "/lacerante_execution_board.png")
	print("LACERANTE_EXEC_VISUAL_%s sheet=%s board=%s" % ["OK" if ok else "FAIL", ok, out_dir + "/lacerante_execution_board.png"])
	quit(0 if ok else 1)
