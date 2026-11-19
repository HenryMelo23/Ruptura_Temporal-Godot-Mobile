extends SceneTree

## Fenix 2026-11: chuva de fogo causa dano, rasante funciona, animador sempre
## devolve textura e o voo nao fica parado.
const DT := 1.0 / 60.0
var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("BOSS7_REWORK_FAIL " + msg)


func _steps(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		t += DT
		game.time_alive += DT
		game._update_boss(DT)


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game.forced_initial_phase = 7
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.current_phase = 7
	game.enemies.clear()
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.time_alive = game.BOSS_READY_TIME + 0.01
	game.player_pos = game.experimental_phase_controller.boss_encounter_center() + Vector2(0, 120)
	game.boss_ready = true
	game._start_boss_call_local()
	game.boss_call_timer = 0.01
	game._update_boss_call(0.02)
	await _steps(2.5)
	_check(String(game.boss7_state) != game.BOSS7_STATE_INTRO, "intro nao terminou")
	# Voo fluido: precisa se mover.
	var p0: Vector2 = game.boss_pos
	game.boss_attack_timer = 99.0
	await _steps(1.0)
	_check(game.boss_pos.distance_to(p0) > 60.0, "fenix parada no voo")
	_check(game._boss_texture() != null, "animador sem textura no voo")
	# Chuva de fogo em cima do jogador causa dano.
	game.boss_attacks.clear()
	game.player_hp = 1000
	game._start_boss7_sky_fireballs()
	await _steps(2.6)
	_check(float(game.player_hp) < 1000.0, "chuva de fogo nao causou dano")
	# Rasante: passa por swoop_warn -> swoop -> recovery e deixa rastro.
	game.boss_attacks.clear()
	game.boss7_state = game.BOSS7_STATE_FLY
	game._boss7_motion().start_swoop()
	_check(String(game.boss7_state) == RTBoss7MotionController.STATE_SWOOP_WARN, "rasante nao comecou")
	_check(game._boss_texture() != null, "animador sem textura no rasante")
	await _steps(0.9)
	_check(String(game.boss7_state) == RTBoss7MotionController.STATE_SWOOP, "rasante nao arrancou")
	await _steps(1.1)
	var trails: int = game.boss_attacks.filter(func(a): return String(a.get("kind", "")) == game.BOSS7_ATTACK_DIVE_TRAIL).size()
	_check(trails > 5, "rasante sem rastro de fogo")
	_check(String(game.boss7_state) != RTBoss7MotionController.STATE_SWOOP, "rasante nao terminou")
	# Mergulho: altitude sobe e a fenix some do desenho la em cima.
	game.boss_attacks.clear()
	game.boss7_state = game.BOSS7_STATE_FLY
	game._start_boss7_dive()
	await _steps(1.6)
	_check(game._boss7_motion().altitude > 0.8, "mergulho sem altitude")
	print("BOSS7_REWORK_SMOKE_OK flight=true meteors=true swoop=true dive_alt=true")
	quit(1 if failed else 0)
