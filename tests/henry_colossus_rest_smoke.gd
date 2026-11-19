extends SceneTree

## Gigante parado: ao soltar o movimento toca a freada (stop) e depois a respiracao
## (idle) na direcao em que andava. Monta uma prancha em --out=<dir>.
const DT := 1.0 / 60.0
var game: Node
var out_dir := "user://henry_colossus_rest"
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_dir = a.substr(6)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("HENRY_COLOSSUS_REST " + message)


func _step(seconds: float) -> void:
	var owner = game.henry_colossus_ability_controller
	for _i in range(int(round(seconds / DT))):
		game.time_alive += DT
		owner.update(DT)
		var move: Vector2 = game._read_move()
		if move.length() > 0.1:
			game.last_facing = move.normalized()


func _crop() -> Image:
	var img := root.get_texture().get_image()
	var c := Vector2i(game.player_pos - game._camera(Vector2(1280, 720)))
	return img.get_region(Rect2i(c - Vector2i(80, 120), Vector2i(160, 170)))


func _shot(board: Image, col: int, row: int) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	board.blit_rect(_crop(), Rect2i(0, 0, 160, 170), Vector2i(col * 160, row * 170))


func _frames(key: String) -> Array:
	return game.textures.get(key, [])


func _run() -> void:
	game.startup_thanks_done = true
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 2
	game.selected_effect = 2
	game.forced_initial_phase = 1
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.henry_entry_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	var owner = game.henry_colossus_ability_controller
	_check(game.mutation_key == "colosso", "not colosso")
	for dir in ["down", "right", "up"]:
		_check(_frames("henry_colossus_idle_" + dir).size() == 4, "idle %s missing" % dir)
		_check(_frames("henry_colossus_stop_" + dir).size() == 3, "stop %s missing" % dir)
	owner.fury = owner.FURY_MAX
	owner.cast_ultimate()
	_step(owner.TRANSFORM_DURATION + 0.3)
	_check(owner.giant_active, "did not become giant")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var board := Image.create(160 * 6, 170 * 4, false, Image.FORMAT_RGBA8)
	board.fill(Color(0.1, 0.1, 0.12))
	var dirs := [[Vector2.RIGHT, "right"], [Vector2.DOWN, "down"], [Vector2.UP, "up"], [Vector2.LEFT, "right"]]
	for row in range(dirs.size()):
		var d: Vector2 = dirs[row][0]
		var key: String = dirs[row][1]
		game.move_touch_index = 0
		game.touch_move = d
		_step(0.5)
		await _shot(board, 0, row)
		game.move_touch_index = -1
		game.touch_move = Vector2.ZERO
		_step(DT)
		var tex: Texture2D = game._player_texture()
		_check(_frames("henry_colossus_stop_" + key).has(tex), "release %s did not start the stop" % key)
		await _shot(board, 1, row)
		_step(0.12)
		await _shot(board, 2, row)
		_step(0.12)
		await _shot(board, 3, row)
		_step(0.25)
		tex = game._player_texture()
		_check(_frames("henry_colossus_idle_" + key).has(tex), "%s did not settle into idle" % key)
		await _shot(board, 4, row)
		var first: Texture2D = tex
		_step(0.3)
		_check(game._player_texture() != first, "%s idle does not breathe" % key)
		await _shot(board, 5, row)
	_check(game._should_flip_player_sprite(), "left rest is not mirrored")
	board.save_png(out_dir + "/henry_colossus_rest_board.png")
	print("HENRY_COLOSSUS_REST_%s board=%s" % ["FAIL" if failed else "OK", out_dir + "/henry_colossus_rest_board.png"])
	quit(1 if failed else 0)
