extends SceneTree

## Fenda do Mercador em cada fase da campanha (1-7): surge dentro do mundo,
## longe do jogador e do altar, leva para a oficina do Mercador ao entrar (onde
## a loja abre no balcao) e gera capturas por fase.
## Uso: godot --path . --script res://tests/merchant_rift_phases_smoke.gd [-- --no-capture]

var game: Node
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition or failed:
		return
	failed = true
	push_error("MERCHANT_RIFT_PHASES_FAIL " + message)
	quit(1)


func _run() -> void:
	var capture: bool = DisplayServer.get_name() != "headless" and not ("--no-capture" in OS.get_cmdline_user_args())
	var output_dir := "res://.agent_logs/merchant_rift/phases"
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game.startup_thanks_done = true
	game.vol_master = 0.0
	for phase in range(1, 8):
		game.forced_initial_phase = phase
		game._start_game()
		game.set_process(false)
		game.set_physics_process(false)
		game.tutorial_state = game.TUTORIAL_STATE_NONE
		game.enemies.clear()
		game.mode = "game"
		game.is_multiplayer = false
		game.shop_auto_enabled = true
		game.shop_rift_controller.allow_rift = true
		game.player_start_down_fall_timer = 0.0
		game.player_start_down_landing_timer = 0.0
		game.time_alive = 30.0 + phase
		game.score = int(game.card_cost) * 3
		_check(game.current_phase == phase, "phase %d was not started" % phase)
		var rift_controller = game.shop_rift_controller
		game.shop_rift_kills = rift_controller.kill_milestone()
		rift_controller.update(0.016)
		_check(rift_controller.active(), "phase %d: rift did not spawn" % phase)
		if failed:
			return
		var pos: Vector2 = Vector2(game.shop_rift["pos"])
		_check(Rect2(Vector2.ZERO, game.WORLD_SIZE).grow(-40.0).has_point(pos), "phase %d: rift outside the playable world" % phase)
		_check(pos.distance_to(game.player_pos) >= 300.0, "phase %d: rift too close to the player" % phase)
		if game.experimental_phase_controller.uses_definitive_world():
			_check(pos.distance_to(Vector2(game.experimental_boss_altar_pos)) >= rift_controller.ALTAR_CLEARANCE - 1.0, "phase %d: rift on top of the altar" % phase)
		game.shop_rift["state"] = rift_controller.STATE_OPEN
		game.shop_rift["state_age"] = 2.0
		game.shop_rift["age"] = 5.0
		if capture:
			var start: Vector2 = game.player_pos
			await _capture(output_dir + "/phase%d_guide_1280x720.png" % phase)
			game.player_pos = pos + Vector2(-230.0, 40.0)
			await _capture(output_dir + "/phase%d_rift_1280x720.png" % phase)
			game.player_pos = start
		game.player_pos = pos
		rift_controller.update(0.016)
		var dimension = game._merchant_dimension()
		# A entrada agora tem a cena do mergulho antes de abrir a oficina.
		var rift_tr = game._rift_transition()
		var waited := 0.0
		while rift_tr.busy() and waited < 5.0:
			rift_tr.update(1.0 / 30.0)
			waited += 1.0 / 30.0
		_check(dimension.active, "phase %d: entering the rift did not open the workshop" % phase)
		if failed:
			return
		if capture and phase == 1:
			# Uma captura da oficina ja com a arte do Mercador no lugar.
			game.camera_follow_initialized = false
			await _capture(output_dir + "/oficina_1280x720.png")
		# A loja fica no balcao: pula a fala e encosta no Mercador.
		game._dialogue().clear()
		dimension.talked_this_visit = true
		dimension.counter_armed = true
		game.player_pos = RTMerchantDimension.MERCHANT_POS
		dimension.update(0.016)
		# O balcao abre o menu COMPRAR / PERGUNTAR / NADA AGORA (solo): COMPRAR.
		if game._dialogue().busy():
			game._dialogue().revealed = 99999.0
			game._dialogue().grace = 0.0
			game._dialogue().choose(0)
		_check(game.mode == "shop", "phase %d: shop did not open at the counter" % phase)
		game.shop_controller.finish()
		dimension.leave(false)
		rift_tr.reset_run()
		_check(not rift_controller.active(), "phase %d: rift survived the shop exit" % phase)
		if failed:
			return
	print("MERCHANT_RIFT_PHASES_OK phases=7 spawn=true inside_world=true altar_clear=true oficina=true capture=%s" % str(capture))
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)


func _capture(path: String) -> void:
	game.effects.clear()
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	assert(image != null)
	assert(image.save_png(path) == OK)
