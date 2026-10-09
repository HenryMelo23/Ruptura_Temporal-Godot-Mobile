extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS_MULTIPLAYER_PRESSURE_BALANCE_FAIL " + message)
	quit(1)


func _approx(actual: float, expected: float, tolerance: float = 0.01) -> bool:
	return absf(actual - expected) <= tolerance


func _set_party_size(size: int) -> void:
	game.is_multiplayer = size > 1
	game.online_connected = size > 1
	game.online_local_spectator = false
	game.online_lobby_active_player_count = size
	game.online_lobby_connected_count = size
	game.is_dead = false


func _boss_hp_for_party(phase: int, party_size: int) -> float:
	_set_party_size(party_size)
	game.current_phase = phase
	game._reset_boss_party_scaling_context(phase)
	return game._boss_hp_for_phase(phase)


func _assert_hp_curve() -> void:
	for phase in [1, 2, 3, 4, 5, 6, 7]:
		var solo_hp: float = _boss_hp_for_party(phase, 1)
		var duo_hp: float = _boss_hp_for_party(phase, 2)
		var trio_hp: float = _boss_hp_for_party(phase, 3)
		_check(_approx(duo_hp, solo_hp * 2.0), "phase %d duo hp is not 2x solo" % phase)
		_check(_approx(trio_hp, solo_hp * 3.0), "phase %d trio hp is not 3x solo" % phase)


func _assert_fixed_encounter_snapshot() -> void:
	var duo_hp: float = _boss_hp_for_party(2, 2)
	game.boss_active = true
	game.boss_hp_max = duo_hp
	game.boss_hp = duo_hp
	game.is_dead = true
	_set_party_size(1)
	_check(_approx(game._boss_hp_for_phase(2), duo_hp), "elimination reduced active boss hp scaling")
	game.is_dead = false
	_set_party_size(3)
	_check(_approx(game._boss_hp_for_phase(2), duo_hp), "revive/rejoin reapplied active boss hp scaling")


func _assert_mechanics_curve() -> void:
	_set_party_size(1)
	game.current_phase = 2
	game._reset_boss_party_scaling_context(2)
	game._boss2_start_idle(1.0)
	var solo_idle: float = game.boss2_action_timer
	var solo_interval: float = game._boss_party_scaled_interval(10.0, 1.0)
	var solo_hazards: int = game._boss_party_hazard_bonus(2)

	_set_party_size(2)
	game.current_phase = 2
	game._reset_boss_party_scaling_context(2)
	game._boss2_start_idle(1.0)
	var duo_idle: float = game.boss2_action_timer
	var duo_interval: float = game._boss_party_scaled_interval(10.0, 1.0)
	var duo_hazards: int = game._boss_party_hazard_bonus(2)

	_set_party_size(3)
	game.current_phase = 2
	game._reset_boss_party_scaling_context(2)
	game._boss2_start_idle(1.0)
	var trio_idle: float = game.boss2_action_timer
	var trio_interval: float = game._boss_party_scaled_interval(10.0, 1.0)
	var trio_hazards: int = game._boss_party_hazard_bonus(2)

	_check(_approx(solo_idle, 1.0), "solo boss2 idle changed")
	_check(duo_idle < solo_idle and trio_idle < duo_idle, "boss2 idle cadence did not scale by party")
	_check(_approx(solo_interval, 10.0), "solo scaled interval changed")
	_check(duo_interval < solo_interval and trio_interval < duo_interval, "shared tempo did not tighten intervals")
	_check(solo_hazards == 0 and duo_hazards == 1 and trio_hazards == 2, "hazard bonus curve mismatch")

	game.current_phase = 4
	game.phase4_enemy_hazards.clear()
	game._start_boss4_secondary()
	var trio_bubbles: int = game.phase4_enemy_hazards.size()
	game.phase4_enemy_hazards.clear()
	_set_party_size(1)
	game.current_phase = 4
	game._reset_boss_party_scaling_context(4)
	game._start_boss4_secondary()
	var solo_bubbles: int = game.phase4_enemy_hazards.size()
	_check(trio_bubbles > solo_bubbles, "boss4 bubble count did not scale")

	_set_party_size(3)
	game.current_phase = 4
	game._reset_boss_party_scaling_context(4)
	game.boss4_meteorites.clear()
	game._start_boss4_meteor_event()
	_check(game.boss4_meteorites.size() == game.BOSS4_METEOR_COUNT + 2, "boss4 meteor count did not use hazard bonus")

	game.current_phase = 6
	game._reset_boss_party_scaling_context(6)
	_check(game._boss6_acid_bloom_spots().size() == game.BOSS6_ACID_BLOOM_COUNT + 2, "boss6 acid bloom count did not use hazard bonus")

	game.current_phase = 7
	game._reset_boss_party_scaling_context(7)
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	var trio_boss7_delay: float = game._boss7_attack_delay()
	_set_party_size(1)
	game.current_phase = 7
	game._reset_boss_party_scaling_context(7)
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	var solo_boss7_delay: float = game._boss7_attack_delay()
	_check(trio_boss7_delay < solo_boss7_delay, "boss7 attack delay did not scale")


func _run() -> void:
	await process_frame
	game.score_total = 0
	game.enemies_killed = 0
	game.time_alive = 0.0

	_assert_hp_curve()
	_assert_fixed_encounter_snapshot()
	_assert_mechanics_curve()

	print("BOSS_MULTIPLAYER_PRESSURE_BALANCE_OK hp=1x/2x/3x tempo=1.0/1.12/1.22 hazards=0/1/2")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _i in range(3):
		await process_frame
	quit(0)
