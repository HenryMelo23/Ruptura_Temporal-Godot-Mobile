extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UMBRA_SIPHON_SUSTAIN_FAIL " + message)
	quit(1)


func _approx(actual: float, expected: float, tolerance: float = 0.01) -> bool:
	return absf(actual - expected) <= tolerance


func _set_party_size(size: int) -> void:
	game.is_multiplayer = size > 1
	game.online_connected = size > 1
	game.online_local_spectator = false
	game.online_lobby_active_player_count = size
	game.online_lobby_connected_count = size


func _setup_umbra(party_size: int = 1) -> void:
	_set_party_size(party_size)
	game.current_phase = 5
	game._reset_boss_party_scaling_context(5)
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 35100.0 * float(party_size)
	game.boss_hp = 25000.0
	game.boss_pos = Vector2(1000, 450)
	game.player_pos = Vector2(620, 450)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.boss5_siphon_timer = 0.0
	game.boss5_siphon_cooldown = 0.0
	game.boss5_siphon_heal_window_timer = 0.0
	game.boss5_siphon_heal_window_used = 0.0


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"

	_setup_umbra(1)
	game.boss5_siphon_timer = game.BOSS5_SIPHON_DURATION
	var before_passive: float = game.boss_hp
	game._update_boss_phase5(1.0)
	var passive_heal: float = game.boss_hp - before_passive
	_check(_approx(passive_heal, game.boss_hp_max * game.BOSS5_SIPHON_HEAL_RATE, 0.05), "passive siphon heal rate mismatch")
	_check(passive_heal <= game.boss_hp_max * 0.0076, "passive siphon heal rate exceeded nerfed target")

	_setup_umbra(1)
	var solo_budget: float = game._boss5_siphon_heal_budget_max()
	var applied_cap: float = game._apply_boss5_siphon_heal(999999.0, "cap")
	_check(_approx(applied_cap, solo_budget, 0.05), "siphon did not clamp to solo budget")
	_check(_approx(game._apply_boss5_siphon_heal(999999.0, "cap"), 0.0), "siphon exceeded budget in same window")
	game._update_boss5_siphon_heal_budget(game.BOSS5_SIPHON_HEAL_BUDGET_WINDOW + 0.1)
	_check(_approx(game._apply_boss5_siphon_heal(999999.0, "cap"), solo_budget, 0.05), "siphon budget did not reset after window")

	_setup_umbra(1)
	game.boss5_siphon_timer = 1.0
	var before_damage: float = game.boss_hp
	game._damage_boss(1000.0, "eletrica")
	_check(game.boss_hp < before_damage, "valid damage did not make net progress during siphon")
	_check(game.boss5_siphon_heal_window_used > 0.0, "valid damage during siphon did not grant limited heal")
	_check(game.boss5_siphon_heal_window_used <= 1000.0 * game.BOSS5_SIPHON_DAMAGE_ABSORB_RATIO * game.BOSS5_SIPHON_DAMAGE_HEAL_RATIO + 1.0, "damage heal exceeded configured event rate")

	_setup_umbra(1)
	game.boss5_siphon_timer = 1.0
	game._damage_boss(1000.0, "parasite_feast")
	_check(_approx(game.boss5_siphon_heal_window_used, 0.0), "excluded source granted siphon heal")

	_setup_umbra(3)
	var trio_budget: float = game._boss5_siphon_heal_budget_max()
	_check(_approx(trio_budget, solo_budget, 0.05), "trio siphon budget scaled with multiplayer HP")
	var trio_applied: float = game._apply_boss5_siphon_heal(999999.0, "trio_cap")
	_check(_approx(trio_applied, solo_budget, 0.05), "trio siphon did not use shared encounter budget")

	print("UMBRA_SIPHON_SUSTAIN_OK passive_rate=%.4f budget=%.0f damage_heal_ratio=%.2f trio_budget_shared=true" % [game.BOSS5_SIPHON_HEAL_RATE, solo_budget, game.BOSS5_SIPHON_DAMAGE_HEAL_RATIO])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _i in range(3):
		await process_frame
	quit(0)
