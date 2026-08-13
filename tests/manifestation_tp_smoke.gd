extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFESTATION_TP_FAIL " + message)
	quit(1)


func _reset_tp(kind: String) -> void:
	game.manifestation_key = kind
	game.tp_effects.clear()
	game.tp_cooldown_pending = false
	game.tp_cooldown_override = -1.0
	game.tp_cooldown_release_time = -1.0
	game.retornante_tp_window = 0.0
	game.player_pos = Vector2(500, 400)
	game.enemies.clear()
	game.boss_active = false
	game.boss_dead = false
	game.last_dash_time = -100.0


func _enemy(pos: Vector2, hp := 5000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies.back()
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	return enemy


func _advance_tp(seconds: float, step := 0.1) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		var dt: float = min(step, seconds - elapsed)
		game.time_alive += dt
		game._update_teleport_effects(dt)
		elapsed += dt


func _run() -> void:
	game._start_game()
	game.mode = "game"

	_reset_tp("lacerante")
	var q_enemy := _enemy(game.player_pos + Vector2(110, 0), 20000.0)
	game.player_hp_max = 1000
	game.player_hp = 400
	game.last_skill_time = -100.0
	game._use_skill()
	game._update_effects(0.01)
	var hp_after_first: float = float(q_enemy["hp"])
	var heal_after_first: int = game.player_hp
	game._update_effects(0.31)
	_check(float(q_enemy["hp"]) < hp_after_first, "lacerante Q did not damage again on the next rotation")
	_check(game.player_hp > heal_after_first, "lacerante Q did not heal again on the next rotation")

	_reset_tp("prismatica")
	game.player_dash_cooldown = game.PLAYER_BASE_DASH_COOLDOWN
	_check(is_equal_approx(game._current_dash_cooldown(), 4.0), "prismatic TP cooldown is not 4s")
	game._execute_teleport(Vector2(720, 400))
	_check(game.prisms.any(func(p): return bool(p.get("tp_prism", false)) and float(p.get("radius", 0.0)) >= 76.0), "prismatic TP did not create the large firing prism")
	var prism_dash_stamp: float = game.last_dash_time
	_advance_tp(3.85)
	_check(game.tp_cooldown_pending and game.last_dash_time == prism_dash_stamp, "prismatic TP released before 4s")
	_advance_tp(0.2)
	_check(not game.tp_cooldown_pending and game.last_dash_time == prism_dash_stamp, "prismatic TP did not release after 4s from activation")
	_check(not game.tp_effects.is_empty(), "prismatic visual ended together with the direct cooldown")

	_reset_tp("retornante")
	var return_origin: Vector2 = game.player_pos
	game._execute_teleport(Vector2(760, 400))
	_check(is_equal_approx(game.retornante_tp_window, 0.85), "return window is not 850ms")
	game._try_dash()
	_check(game.player_pos == return_origin, "returning TP did not go back to origin")
	_advance_tp(0.02)
	_check(not game.tp_cooldown_pending, "returning TP did not begin cooldown after returning")

	_reset_tp("parasitica")
	var parasite_enemy := _enemy(Vector2(455, 400))
	game._execute_teleport(Vector2(720, 400))
	_advance_tp(0.5, 0.05)
	_check(float(parasite_enemy.get("stun", 0.0)) >= 1.79, "parasite eggs did not stun their enemy for 1.8s")
	_reset_tp("parasitica")
	game.boss_active = true
	game.boss_hp = 5000.0
	game.boss_hp_max = 5000.0
	game.boss_pos = Vector2(455, 400)
	game.boss_attacks.clear()
	game._execute_teleport(Vector2(720, 400))
	_advance_tp(0.5, 0.05)
	_check(game.boss_tp_stun_timer > 1.7, "parasite eggs did not stun an idle boss")
	_reset_tp("parasitica")
	game.boss_active = true
	game.boss_hp = 5000.0
	game.boss_hp_max = 5000.0
	game.boss_pos = Vector2(455, 400)
	game.boss_tp_stun_timer = 0.0
	game.boss_attacks = [{"kind": "test_ability", "age": 0.0, "duration": 2.0}]
	game._execute_teleport(Vector2(720, 400))
	_advance_tp(0.5, 0.05)
	_check(is_zero_approx(game.boss_tp_stun_timer), "parasite eggs interrupted a boss ability")
	game.boss_attacks.clear()

	_reset_tp("gravitante")
	var gravity_enemy := _enemy(Vector2(560, 400))
	var gravity_before: Vector2 = gravity_enemy["pos"]
	game._execute_teleport(Vector2(720, 400))
	_check(Vector2(gravity_enemy["pos"]).distance_to(gravity_before) >= 140.0, "gravity TP did not push nearby enemies")

	_reset_tp("lacerante")
	var single_cut_enemy := _enemy(Vector2(610, 400), 10000.0)
	game._start_tp_lacerante(game.player_pos, Vector2(720, 400))
	var single_cut_hp: float = float(single_cut_enemy["hp"])
	game._update_tp_lacerante(game.tp_effects[0], 0.01)
	var expected_cut_damage: float = 50.0 + float(single_cut_enemy["max_hp"]) * 0.005
	_check(abs((single_cut_hp - float(single_cut_enemy["hp"])) - expected_cut_damage) <= 0.05, "lacerante TP first cut did not use the reduced damage")

	_reset_tp("lacerante")
	game.lacerante_coagula = 20
	game.lacerante_tp_charges = 2
	game.lacerante_tp_cooldown_until = -100.0
	var cut_enemy := _enemy(Vector2(610, 400), 50000.0)
	game._execute_teleport(Vector2(720, 400))
	game._consume_lacerante_tp_charge()
	_check(game.lacerante_tp_charges == 1 and is_equal_approx(game.lacerante_tp_chain_timer, game.LACERANTE_TP_CHAIN_WINDOW), "lacerante first TP did not expose one remaining chain charge")
	_check(game._player_invulnerable(), "lacerante TP did not grant immunity during its cuts")
	var cut_hp_before: float = cut_enemy["hp"]
	_advance_tp(0.4, 0.05)
	game._execute_teleport(Vector2(760, 400))
	game._consume_lacerante_tp_charge()
	_check(game.lacerante_tp_charges == 0, "lacerante second TP charge was not consumed")
	_advance_tp(3.05, 0.05)
	_check(float(cut_enemy["hp"]) < cut_hp_before - 500.0, "lacerante TP did not execute its repeated cuts")
	_check(not game.tp_cooldown_pending and game.lacerante_tp_charges == 0 and game.lacerante_tp_cooldown_until > game.time_alive, "lacerante absolute cooldown did not start after the cuts ended")
	_advance_tp(2.05, 0.05)
	game._update_lacerante_tp_state(0.01)
	_check(game.lacerante_tp_charges == 2, "lacerante charges did not refill after absolute cooldown")

	_reset_tp("eletrica")
	game.player_dash_cooldown = game.PLAYER_BASE_DASH_COOLDOWN
	_check(is_equal_approx(game._current_dash_cooldown(), 4.0), "electric TP cooldown is not 4s")
	var electric_enemy := _enemy(Vector2(610, 400), 10000.0)
	game._execute_teleport(Vector2(720, 400))
	_check(game._player_invulnerable(), "electric TP did not turn the player into invulnerable electricity")
	var electric_dash_stamp: float = game.last_dash_time
	var electric_before: float = electric_enemy["hp"]
	_advance_tp(0.65, 0.05)
	_check(float(electric_enemy["hp"]) <= electric_before - 100.0, "electric TP did not apply repeated 300ms ticks")
	_advance_tp(3.2, 0.05)
	_check(game.tp_cooldown_pending and game.last_dash_time == electric_dash_stamp, "electric TP released before 4s")
	_advance_tp(0.25, 0.05)
	_check(not game.tp_cooldown_pending and game.last_dash_time == electric_dash_stamp, "electric TP did not release after 4s from activation")

	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 1.0
	game.boss1_rain_active = true
	game.weather_kind = "rain"
	game.rain_audio_player.stream = AudioStreamWAV.new()
	game.rain_audio_player.play()
	game._damage_boss(100.0, "test")
	_check(not game.rain_audio_player.playing and game.rain_audio_fade_mode == "", "rain audio continued after boss1 died")

	print("MANIFESTATION_TP_OK q=multi_hit_heal prism=large return=850ms parasite=stun gravity=push lacerante=cuts electric=ticks rain=stopped")
	quit(0)
