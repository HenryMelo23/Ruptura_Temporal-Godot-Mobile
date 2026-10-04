extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS_PARTY_SCALING_FAIL " + message)
	quit(1)


func _approx(actual: float, expected: float, tolerance: float = 0.01) -> bool:
	return absf(actual - expected) <= tolerance


func _set_party_size(size: int) -> void:
	game.is_multiplayer = size > 1
	game.online_connected = size > 1
	game.online_local_spectator = false
	game.online_lobby_active_player_count = size
	game.online_lobby_connected_count = size


func _run() -> void:
	await process_frame
	game.score_total = 0
	game.enemies_killed = 0
	game.time_alive = 0.0

	_set_party_size(1)
	game.current_phase = 1
	game._reset_boss_party_scaling_context(1)
	var solo_hp: float = game._boss_hp_for_phase(1)
	_check(_approx(solo_hp, game.BOSS_BASE_HP), "solo boss hp baseline changed")
	_check(_approx(game._multiplayer_boss_damage_scale(), 1.0), "solo pressure baseline changed")
	var solo_report: Dictionary = game._boss_party_scaling_report()
	_check(int(solo_report.get("party_size", 0)) == 1, "solo telemetry party size mismatch")
	_check(_approx(float(solo_report.get("hp_coeff", 0.0)), 1.0), "solo telemetry hp coeff mismatch")

	_set_party_size(2)
	game.current_phase = 1
	game._reset_boss_party_scaling_context(1)
	var two_player_hp: float = game._boss_hp_for_phase(1)
	_check(_approx(two_player_hp, game.BOSS_BASE_HP * 1.35), "2p boss hp coeff mismatch")
	_check(int(game._boss_party_scaling_report().get("party_size", 0)) == 2, "2p party size was not snapshotted")
	_check(_approx(game._multiplayer_boss_damage_scale(), 0.92), "2p pressure coeff mismatch")

	game.boss_active = true
	game.boss_hp_max = two_player_hp
	game.boss_hp = two_player_hp
	game.is_dead = true
	_set_party_size(1)
	_check(_approx(game._boss_hp_for_phase(1), two_player_hp), "boss hp scale decreased after elimination")
	_check(_approx(game._multiplayer_boss_damage_scale(), 0.92), "pressure coeff decreased after elimination")

	game.is_dead = false
	_set_party_size(3)
	_check(_approx(game._boss_hp_for_phase(1), two_player_hp), "revive/rejoin reapplied boss hp multiplier during encounter")
	_check(_approx(game._multiplayer_boss_damage_scale(), 0.92), "revive/rejoin reapplied pressure multiplier during encounter")

	game.current_phase = 2
	game._reset_boss_party_scaling_context(2)
	var phase2_hp: float = game._boss_hp_for_phase(2)
	_check(_approx(phase2_hp, 8910.0 * 1.70), "new boss/fase did not recalculate 3p hp coeff")
	_check(_approx(game._multiplayer_boss_damage_scale(), 0.88), "new boss/fase did not recalculate 3p pressure coeff")

	var minimal_payload: Dictionary = get_root().get_node("/root/TelemetrySystem").build_minimal_session_payload("Teste")
	var minimal_boss: Dictionary = Dictionary(minimal_payload.get("boss", {}))
	_check(int(minimal_boss.get("party_size", 0)) == 3, "minimal telemetry missing boss party size")
	_check(_approx(float(minimal_boss.get("hp_coeff", 0.0)), 1.70), "minimal telemetry missing boss hp coeff")
	_check(_approx(float(minimal_boss.get("pressure_coeff", 0.0)), 0.88), "minimal telemetry missing boss pressure coeff")
	var report_payload: Dictionary = get_root().get_node("/root/TelemetrySystem").build_run_report_payload("Teste")
	var report_scaling: Dictionary = Dictionary(report_payload.get("boss_scaling", {}))
	_check(int(report_scaling.get("party_size", 0)) == 3, "run telemetry missing boss party size")

	print("BOSS_PARTY_SCALING_SMOKE_OK solo=1.0 two_hp=1.35 two_pressure=0.92 three_hp=1.70 three_pressure=0.88")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _i in range(3):
		await process_frame
	quit(0)
