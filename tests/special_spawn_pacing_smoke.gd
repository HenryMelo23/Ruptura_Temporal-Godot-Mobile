extends SceneTree

var game: Node
var failures: Array[String] = []

const SEEDS: Array[int] = [17, 41, 73, 109, 151]
const DURATIONS: Array[float] = [300.0, 600.0, 900.0]


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _reset_simulation(phase: int, profile: String, seed_value: int) -> void:
	game.current_phase = phase
	game.phase_started_at = 0.0
	game.time_alive = 0.0
	game.mode = "game"
	game.run_pacing_profile = profile
	game.is_multiplayer = false
	game.boss_active = false
	game.boss_dead = false
	game.arauto.clear()
	game.enemies.clear()
	game.enemy_manager.phase_density_carry_cap = 0
	game.enemy_manager.phase_density_native_entry_cap = 0
	game.enemy_manager.reset_special_pacing(true)
	game.rng.seed = seed_value


func _remove_expired_synthetic_enemies(elapsed: float) -> void:
	var survivors: Array = []
	for enemy in game.enemies:
		if float(enemy.get("synthetic_expires", elapsed + 1.0)) > elapsed:
			survivors.append(enemy)
	game.enemies = survivors


func _simulate(phase: int, profile: String, duration: float, seed_value: int) -> Dictionary:
	_reset_simulation(phase, profile, seed_value)
	var next_spawn: float = 0.0
	var elapsed: float = 0.0
	while elapsed <= duration:
		game.time_alive = elapsed
		_remove_expired_synthetic_enemies(elapsed)
		if elapsed >= next_spawn and game.enemies.size() < game._enemy_limit():
			var kind: String = game._choose_enemy_type()
			game.enemies.append({
				"type": kind,
				"hp": 1.0,
				"pos": Vector2(400, 400),
				"uid": int(elapsed * 1000.0) + seed_value,
				"synthetic_expires": elapsed + 6.0
			})
			game._record_pacing_enemy_spawn(kind)
			game.enemy_manager.record_special_spawn(kind)
			next_spawn = elapsed + game._enemy_spawn_interval()
		else:
			next_spawn = minf(next_spawn, elapsed + 0.2) if next_spawn < elapsed else next_spawn
		elapsed += 0.25
	return game.enemy_manager.special_spawn_report()


func _phase_report(report: Dictionary, phase: int) -> Dictionary:
	return Dictionary(Dictionary(report.get("by_phase", {})).get(str(phase), {"count": 0, "intervals": []}))


func _assert_simulation(phase: int, profile: String, first_target: float, repeat_gap: float) -> void:
	for duration in DURATIONS:
		for seed_value in SEEDS:
			var report: Dictionary = _simulate(phase, profile, duration, seed_value)
			var phase_report: Dictionary = _phase_report(report, phase)
			var count: int = int(phase_report.get("count", 0))
			if duration >= first_target + 30.0:
				_check(count > 0, "%s phase %d seed %d did not spawn a special by %.0fs" % [profile, phase, seed_value, duration])
			var intervals: Array = Array(phase_report.get("intervals", []))
			for interval in intervals:
				_check(float(interval) <= repeat_gap + 2.0, "%s phase %d seed %d exceeded pity gap: %.2fs" % [profile, phase, seed_value, float(interval)])


func _run() -> void:
	_check(is_equal_approx(game._phase1_stalker_unlock_time(), game.PHASE1_STALKER_UNLOCK_TIME), "phase 1 stalker unlock changed")
	_check(is_equal_approx(game._phase1_projector_unlock_time(), game.PHASE1_PROJECTOR_UNLOCK_TIME), "phase 1 projector unlock changed")
	_check(is_equal_approx(game.enemy_manager.special_first_unlock_time(2), 60.0), "phase 2 onboarding first unlock mismatch")
	_check(is_equal_approx(game.enemy_manager.special_first_unlock_time(3), 120.0), "phase 3 onboarding first unlock mismatch")
	_check(is_equal_approx(game.enemy_manager.special_first_unlock_time(6), 120.0), "phase 6 onboarding first unlock mismatch")

	game.run_pacing_profile = game.PACING_PROFILE_ONBOARDING
	_check(is_equal_approx(game._phase2_kamikaze_unlock_time(), 60.0), "phase 2 onboarding kamikaze timing mismatch")
	_check(is_equal_approx(game._phase2_pyro_unlock_time(), 240.0), "phase 2 onboarding pyro timing mismatch")
	_check(is_equal_approx(game._phase3_common_only_time(), 120.0), "phase 3 onboarding first pressure timing mismatch")
	_check(is_equal_approx(game._phase3_incensario_unlock_time(), 240.0), "phase 3 onboarding incensario timing mismatch")
	_check(is_equal_approx(game._phase3_guardiao_unlock_time(), 360.0), "phase 3 onboarding guardiao timing mismatch")
	_check(is_equal_approx(game._phase6_leech_unlock_time(), 120.0), "phase 6 onboarding leech timing mismatch")

	game.run_pacing_profile = game.PACING_PROFILE_EXPERIENCED
	_check(is_equal_approx(game._phase2_kamikaze_unlock_time(), 45.0), "phase 2 experienced timing was compounded")
	_check(is_equal_approx(game._phase2_pyro_unlock_time(), 180.0), "phase 2 experienced pyro timing mismatch")
	_check(is_equal_approx(game._phase3_common_only_time(), 90.0), "phase 3 experienced first pressure timing mismatch")
	_check(is_equal_approx(game._phase3_incensario_unlock_time(), 180.0), "phase 3 experienced incensario timing mismatch")
	_check(is_equal_approx(game._phase6_leech_unlock_time(), 90.0), "phase 6 experienced timing mismatch")

	_assert_simulation(2, game.PACING_PROFILE_ONBOARDING, 60.0, 52.0)
	_assert_simulation(3, game.PACING_PROFILE_ONBOARDING, 120.0, 54.0)
	_assert_simulation(6, game.PACING_PROFILE_ONBOARDING, 120.0, 66.0)
	_assert_simulation(2, game.PACING_PROFILE_EXPERIENCED, 45.0, 42.0)
	_assert_simulation(3, game.PACING_PROFILE_EXPERIENCED, 90.0, 43.0)
	_assert_simulation(6, game.PACING_PROFILE_EXPERIENCED, 90.0, 52.0)

	game.enemy_manager.special_last_spawn_phase_time = 99.0
	game.enemy_manager.prepare_phase_special_pacing()
	_check(game.enemy_manager.special_last_spawn_phase_time < 0.0, "phase transition carried a pending special")
	game.is_multiplayer = true
	game.run_pacing_profile = game.PACING_PROFILE_ONBOARDING
	_check(is_equal_approx(game.enemy_manager.special_first_unlock_time(2), 60.0), "multiplayer changed phase 2 pacing")
	_check(is_equal_approx(game.enemy_manager.special_repeat_gap(3), 54.0), "multiplayer changed phase 3 pacing")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
	assert(failures.is_empty(), "SPECIAL_SPAWN_PACING_SMOKE_FAILED")
	print("SPECIAL_SPAWN_PACING_SMOKE_OK phases=2,3,6 profiles=onboarding,experienced seeds=5 durations=5,10,15m pity=true phase1_unchanged=true mp_stable=true")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
