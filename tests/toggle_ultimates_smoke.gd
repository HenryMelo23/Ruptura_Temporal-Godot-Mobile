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
	game._update_secondary_eletrica(electric, game.SECONDARY_ELETRICA_DRAIN_DELAY)
	assert(game.player_hp == 1000)
	game._update_secondary_eletrica(electric, 1.01)
	assert(game.player_hp == 995)

	game.time_alive += game.SECONDARY_ELETRICA_DRAIN_DELAY + 1.01
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

	print("TOGGLE_ULTIMATES_SMOKE_OK electric_drain=0.5%% cancel=true cooldown_on_stop=true prism_cancel=true")
	quit(0)
