extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.time_alive = 100.0
	game.player_hp_max = 1000.0
	game.player_hp = 1000
	game.manifestation_key = "eletrica"
	game.last_secondary_time = -999.0
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(100.0, 0.0))
	game.enemies[0]["hp"] = 100000.0

	var cooldown_before = game.last_secondary_time
	game._use_secondary_skill()
	assert(not game._active_eletrica_secondary().is_empty())
	assert(game.last_secondary_time == cooldown_before)
	var electric = game._active_eletrica_secondary()
	var enemy_hp_before = float(game.enemies[0]["hp"])
	game._update_secondary_eletrica(electric, game.SECONDARY_ELETRICA_DRAIN_DELAY)
	assert(game.player_hp == 1000)
	var expected_shock_damage = float(game.enemies[0]["max_hp"]) * game.SECONDARY_ELETRICA_SHOCK_MAX_HP_RATE + game.player_damage * game.SECONDARY_ELETRICA_SHOCK_DAMAGE_RATE
	assert(is_equal_approx(float(game.enemies[0]["hp"]), enemy_hp_before - expected_shock_damage))
	assert(float(game.enemies[0]["stun"]) >= game.SECONDARY_ELETRICA_SHOCK_STUN)
	game._update_secondary_eletrica(electric, game.SECONDARY_ELETRICA_DRAIN_INTERVAL)
	assert(game.player_hp == 980)
	assert(game.secondary_drain_flash_timer > 0.0)
	game._update_secondary_eletrica(electric, game.SECONDARY_ELETRICA_DRAIN_INTERVAL)
	assert(game.player_hp == 960)

	game.time_alive += game.SECONDARY_ELETRICA_DRAIN_DELAY + game.SECONDARY_ELETRICA_DRAIN_INTERVAL * 2.0
	game._use_secondary_skill()
	assert(game._active_eletrica_secondary().is_empty())
	assert(is_equal_approx(game.last_secondary_time, game.time_alive))
	var electric_cancel_time = game.last_secondary_time
	game._use_secondary_skill()
	assert(game._active_eletrica_secondary().is_empty())
	assert(game.last_secondary_time == electric_cancel_time)

	game.manifestation_secondaries.clear()
	game.time_alive += game.SECONDARY_SKILL_COOLDOWN + 0.1
	game._use_secondary_skill()
	assert(not game._active_eletrica_secondary().is_empty())
	game.enemies.clear()
	game.time_alive += 3.1
	game._update_manifestation_secondaries(3.1)
	assert(game._active_eletrica_secondary().is_empty())
	assert(is_equal_approx(game.last_secondary_time, game.time_alive))

	game.manifestation_secondaries.clear()
	game.manifestation_key = "prismatica"
	game.time_alive += game.SECONDARY_SKILL_COOLDOWN + 0.1
	var prism_cooldown_before = game.last_secondary_time
	game._use_secondary_skill()
	assert(not game._active_prismatica_secondary().is_empty())
	assert(game.last_secondary_time != prism_cooldown_before)
	game.player_hp = 777
	game._damage_player(250, "smoke_prismatica")
	assert(game.player_hp == 777)
	var prism_activation_time = game.last_secondary_time
	game._use_secondary_skill()
	assert(game._active_prismatica_secondary().is_empty())
	assert(is_equal_approx(game.last_secondary_time, prism_activation_time))

	game.manifestation_secondaries.clear()
	game.time_alive += game.SECONDARY_SKILL_COOLDOWN + 0.1
	game._use_secondary_skill()
	assert(not game._active_prismatica_secondary().is_empty())
	var prism_second_activation_time = game.last_secondary_time
	game.time_alive += game.SECONDARY_PRISMATICA_DURATION + 0.1
	game._update_manifestation_secondaries(game.SECONDARY_PRISMATICA_DURATION + 0.1)
	assert(game._active_prismatica_secondary().is_empty())
	assert(is_equal_approx(game.last_secondary_time, prism_second_activation_time))

	print("TOGGLE_ULTIMATES_SMOKE_OK electric_tick=0.4s electric_drain_after=120s cancel=true cooldown_on_stop=true prism_cancel=true")
	quit(0)
