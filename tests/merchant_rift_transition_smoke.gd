extends SceneTree

## Cena de entrada/saida da Fenda do Mercador (RTMerchantRiftTransition):
##  - humor por numero de entradas: 1a assustada, 2a-4a conformada, 5a estilosa
##  - ao entrar, a horda e empurrada para fora do anel e fica la na volta
##  - controles travados e jogador invulneravel durante a cena
##  - expulsao pelo colapso sempre sai "cuspida"
## Fora do modo headless, salva quadros em res://.codex/rift_transition_*.png.

var game: Node
var failed := false
var shots := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		return
	failed = true
	push_error("RIFT_TRANSITION_FAIL " + msg)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	game.queue_redraw()
	await process_frame
	await process_frame
	var dir_path := ProjectSettings.globalize_path("res://.codex")
	DirAccess.make_dir_recursive_absolute(dir_path)
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://.codex/rift_transition_%02d_%s.png" % [shots, label]))
	shots += 1


func _step(seconds: float, capture_at: Array = [], label: String = "", stop_when_idle: bool = false) -> void:
	var dt := 1.0 / 30.0
	var elapsed := 0.0
	var next_capture := 0
	while elapsed < seconds:
		if stop_when_idle and not game._rift_transition().busy():
			return
		game._update_game(dt)
		elapsed += dt
		if next_capture < capture_at.size() and elapsed >= float(capture_at[next_capture]):
			await _capture("%s_%d" % [label, next_capture])
			next_capture += 1


func _open_rift_near_player(offset: Vector2) -> Vector2:
	var rc = game.shop_rift_controller
	rc.clear_active()
	game.shop_rift_next_allowed_time = 0.0
	var pos: Vector2 = game.player_pos + offset
	rc.spawn("test", pos)
	game.shop_rift["state"] = rc.STATE_OPEN
	return pos


func _full_visit(label: String, capture: bool) -> void:
	var tr: RTMerchantRiftTransition = game._rift_transition()
	var dim: RTMerchantDimension = game._merchant_dimension()
	var rift_pos: Vector2 = _open_rift_near_player(Vector2(40.0, 0.0))
	game.player_pos = rift_pos
	game.shop_rift_controller.update(0.016)
	_check(tr.phase == tr.PHASE_DIVE, label + ": entry did not start the dive")
	_check(game._local_player_controls_locked() and game._local_player_movement_locked(), label + ": controls not locked during the dive")
	_check(game._player_invulnerable(), label + ": player hittable during the dive")
	await _step(2.0, [0.25, 0.7] if capture else [], label + "_dive")
	_check(dim.active, label + ": dive did not end inside the workshop")
	await _step(2.2, [0.2, 0.6, 1.2] if capture else [], label + "_land")
	_check(not tr.busy(), label + ": landing did not finish")
	_check(not game._local_player_controls_locked(), label + ": controls stayed locked after landing")
	game.player_pos = RTMerchantDimension.EXIT_PORTAL_POS
	dim.entry_age = 5.0
	dim._reach_exit()
	_check(tr.phase == tr.PHASE_EXIT_DIVE, label + ": exit portal did not start the exit dive")
	await _step(1.2, [0.5] if capture else [], label + "_exit")
	_check(not dim.active, label + ": exit dive did not leave the workshop")
	_check(tr.phase == tr.PHASE_EMERGE, label + ": leaving did not start the emerge scene")
	await _step(1.8, [0.3, 0.7, 1.1] if capture else [], label + "_emerge", true)
	_check(not tr.busy(), label + ": emerge did not finish")
	_check(tr.grace > 0.0, label + ": no grace after emerging")


func _run() -> void:
	await process_frame
	game.run_tutorial_enabled = false
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game._finish_startup_thanks()
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mode = "game"
	game.is_multiplayer = false
	game.boss_active = false
	game.spawn_timer = 99999.0
	game.shop_rift_controller.allow_rift = true
	game.shop_auto_enabled = true
	var npc: RTMerchantNpc = game._merchant_npc()
	npc.seen.clear()
	var tr: RTMerchantRiftTransition = game._rift_transition()
	tr.reset_run()

	# Humor por entrada.
	_check(RTMerchantRiftTransition.mood_for_entry(1) == "scared", "1st entry is not scared")
	_check(RTMerchantRiftTransition.mood_for_entry(2) == "resigned", "2nd entry is not resigned")
	_check(RTMerchantRiftTransition.mood_for_entry(4) == "resigned", "4th entry is not resigned")
	_check(RTMerchantRiftTransition.mood_for_entry(5) == "stylish", "5th entry is not stylish")
	_check(RTMerchantRiftTransition.mood_for_entry(9) == "stylish", "later entries lost the style")

	# Empurrao: horda colada nela ao entrar.
	game.player_pos = Vector2(1400.0, 1000.0)
	game.enemies.clear()
	for i in range(10):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(float(i) * TAU / 10.0) * (60.0 + float(i) * 25.0))
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(900.0, 0.0))
	var far_uid: int = int(game.enemies[-1]["uid"])
	game.enemy_bullets.append({"pos": game.player_pos + Vector2(100.0, 0.0), "dir": Vector2.LEFT, "life": 3.0, "damage": 10.0, "phase": 0.0})

	await _capture("before_entry")
	var rift_pos: Vector2 = _open_rift_near_player(Vector2(30.0, 0.0))
	game.player_pos = rift_pos
	game.shop_rift_controller.update(0.016)
	_check(tr.mood == "scared", "first entry mood is %s" % tr.mood)
	_check(game.enemy_bullets.is_empty(), "enemy bullets near the rift were not cleared")
	await _step(0.5, [0.15, 0.4], "push")
	for enemy in game.enemies:
		if int(enemy["uid"]) == far_uid:
			continue
		_check(Vector2(enemy["pos"]).distance_to(rift_pos) >= RTMerchantRiftTransition.PUSH_RADIUS - 1.0, "enemy not pushed out of the ring (%.0f)" % Vector2(enemy["pos"]).distance_to(rift_pos))
	await _step(1.2, [0.4, 0.8], "first_dive")
	var dim: RTMerchantDimension = game._merchant_dimension()
	_check(dim.active, "first dive did not reach the workshop")
	var saved_enemies: Array = Array(dim.saved.get("enemies", []))
	var saved_positions := {}
	for enemy in saved_enemies:
		saved_positions[int(enemy["uid"])] = Vector2(enemy["pos"])
		_check(int(enemy["uid"]) == far_uid or Vector2(enemy["pos"]).distance_to(rift_pos) >= RTMerchantRiftTransition.PUSH_RADIUS - 1.0, "saved world kept an enemy inside the ring")
	await _step(2.2, [0.15, 0.5, 0.9, 1.4], "first_land")
	_check(tr.entries == 1, "entry counter did not advance (%d)" % tr.entries)
	game.player_pos = RTMerchantDimension.EXIT_PORTAL_POS
	dim.entry_age = 5.0
	dim._reach_exit()
	await _step(1.2, [0.5], "first_exit")
	_check(not dim.active, "first exit did not leave")
	_check(game.player_pos.distance_to(rift_pos) < 1.0, "she did not come back where she entered")
	for enemy in game.enemies:
		var uid: int = int(enemy["uid"])
		if saved_positions.has(uid):
			_check(Vector2(enemy["pos"]).distance_to(saved_positions[uid]) < 1.0, "enemy moved between leaving the world and coming back")
	_check(tr.phase == "emerge" and tr.mood == "scared", "first emerge is %s/%s" % [tr.phase, tr.mood])
	await _step(1.8, [0.3, 0.7, 1.1], "first_emerge", true)
	_check(not tr.busy(), "first emerge did not finish")
	_check(tr.grace > 0.0, "no invulnerability grace after emerging")

	# 2a a 4a: conformada. 5a: estilosa (com quadros).
	game.enemies.clear()
	for n in range(2, 6):
		var label := "visit%d" % n
		await _full_visit(label, n == 2 or n == 5)
		var expected: String = "stylish" if n >= 5 else "resigned"
		_check(tr.entries == n, "%s: entries=%d" % [label, tr.entries])
		_check(tr.mood == expected, "%s: mood %s, expected %s" % [label, tr.mood, expected])

	# Expulsao: sempre sai cuspida.
	var rift2: Vector2 = _open_rift_near_player(Vector2(30.0, 0.0))
	game.player_pos = rift2
	game.shop_rift_controller.update(0.016)
	await _step(4.0)
	_check(dim.active, "6th entry did not reach the workshop")
	dim.leave(true)
	_check(tr.phase == "emerge" and tr.mood == "ejected", "expulsion did not eject (%s/%s)" % [tr.phase, tr.mood])
	await _step(1.6, [0.3, 0.8], "ejected")

	# Save: o numero de entradas sobrevive a partida interrompida.
	var state: Dictionary = dim.save_state()
	tr.reset_run()
	dim.load_state(state)
	_check(tr.entries == 6, "entries were not restored from the run snapshot (%d)" % tr.entries)

	# Multiplayer continua instantaneo.
	game.is_multiplayer = true
	_check(not tr.enabled(), "multiplayer enabled the solo-only scene")
	game.is_multiplayer = false

	print("RIFT_TRANSITION_SMOKE_%s shots=%d" % ["FAIL" if failed else "OK", shots])
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(1 if failed else 0)
