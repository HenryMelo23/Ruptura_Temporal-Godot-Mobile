extends SceneTree

## Pressao infinita da horda: o desejado cresce sem fim, o vivo respeita o orcamento aprendido
## pelo FPS, o excesso vira enxame condensado (mais vida e mais pontos) e a IA distante usa LOD.

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition or failed:
		return
	failed = true
	push_error("HORDE_PRESSURE_FAIL " + message)
	quit(1)


func _setup() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.shop_rift_controller.allow_rift = false
	game.enemies.clear()
	game.runtime_performance_controller.reset()
	game.enemy_manager.horde.reset_run()


func _run() -> void:
	_setup()
	var horde = game.enemy_manager.horde
	var em = game.enemy_manager
	# 1) Crescimento infinito e gradual.
	var last := -1
	for minutes in [0.0, 3.0, 5.0, 10.0, 20.0, 30.0, 60.0, 120.0, 600.0]:
		var value: int = horde.growth_for_minutes(minutes)
		_check(value >= last, "growth decreased at %.0f min" % minutes)
		last = value
	_check(horde.growth_for_minutes(3.0) == 0, "growth started before the onboarding delay")
	_check(horde.growth_for_minutes(10.0) <= 12, "early growth is too steep")
	_check(horde.growth_for_minutes(600.0) > 2000, "growth is not unbounded")
	game.time_alive = 30.0 * 60.0
	var desired_30: int = em.get_desired_enemy_limit()
	game.time_alive = 90.0 * 60.0
	var desired_90: int = em.get_desired_enemy_limit()
	_check(desired_90 > desired_30, "desired limit did not keep growing")
	_check(em.get_enemy_limit() <= horde.budget_cap(), "live limit exceeded the device budget cap")
	_check(em.get_enemy_limit() == mini(desired_90, horde.live_budget()), "live limit is not min(desired, budget)")

	# 2) Governador: queda de FPS encolhe o orcamento; folga sob carga faz crescer.
	horde.budget = 100
	for i in range(80):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(900.0 + float(i), 0.0))
	# FPS baixo mas inimigos baratos (GPU/vsync): segura o orcamento, nao encolhe.
	game.runtime_performance_controller.stage = 1
	horde.update_cost_us = 300.0
	horde.draw_cost_us = 300.0
	horde.update(0.016)
	_check(horde.budget == 100, "budget shrank although enemies are not what costs the frame")
	horde.update_cost_us = 4000.0
	horde.draw_cost_us = 3000.0
	horde.last_stage = 0
	horde.update(0.016)
	_check(horde.budget < 80, "reduced FPS did not shrink the live budget (%d)" % horde.budget)
	var shrunk: int = horde.budget
	game.runtime_performance_controller.stage = 2
	horde.update(0.016)
	_check(horde.budget < shrunk, "emergency did not shrink the budget further")
	_check(horde.budget >= horde.BUDGET_MIN, "budget fell below the playable minimum")
	game.time_alive = 90.0 * 60.0
	game.spawn_timer = 0.0
	var live_before: int = game.enemies.size()
	em.spawn_wave()
	_check(game.enemies.size() == live_before, "spawned while above the shrunk budget")
	game.runtime_performance_controller.stage = 0
	game.runtime_performance_controller.smoothed_fps = 60.0
	horde.shrink_hold = 0.0
	while game.enemies.size() > horde.budget:
		game.enemies.pop_back()
	var grown_from: int = horde.budget
	for _i in range(int(horde.PROBE_HEALTHY_SECONDS / 0.05) + 2):
		horde.update(0.05)
	_check(horde.budget > grown_from, "healthy FPS under load did not grow the budget")
	# Sonda longa sob carga: nunca passa do teto aprendido na queda (sem oscilar de volta ao travamento).
	var learned_ceiling: int = horde.ceiling
	for _i in range(600):
		while game.enemies.size() < horde.budget:
			game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(900.0, 0.0))
		horde.update(0.05)
		horde.ceiling_relax = 0.0
	_check(horde.budget <= learned_ceiling - 2, "probing passed the learned ceiling (%d > %d)" % [horde.budget, learned_ceiling - 2])

	# 3) Enxame condensado: excesso vira vida e pontos.
	game.enemies.clear()
	horde.budget = horde.BUDGET_MIN
	game.time_alive = 120.0 * 60.0
	game.spawn_timer = 0.0
	em.spawn_wave()
	_check(not game.enemies.is_empty(), "no spawn under the budget")
	var condensed: Dictionary = game.enemies.back()
	_check(float(condensed.get("horde_condensed", 1.0)) > 1.5, "overflow did not condense the spawned enemy")
	_check(float(condensed.get("horde_points", 1.0)) > 1.5, "condensed enemy is not worth more points")
	_check(game._elite_point_multiplier(condensed) > 1.5, "point multiplier ignores the horde bonus")
	_check(game.enemies.size() <= horde.MAX_SPAWNS_PER_TICK, "spawned more than the per-tick cap")
	_check(horde.spawn_interval(1.0) < 1.0 and horde.spawn_interval(1.0) >= horde.SPAWN_INTERVAL_FLOOR, "spawn interval does not speed up within its floor")

	# 4) LOD de IA: longe pula quadros alternados mas acumula o tempo; perto atualiza sempre.
	_setup()
	for i in range(horde.AI_LOD_MIN_CROWD + 4):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(2000.0 + float(i) * 3.0, 400.0))
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(300.0, 0.0))
	var near: Dictionary = game.enemies.back()
	var far: Dictionary = game.enemies[0]
	var far_start: Vector2 = Vector2(far["pos"])
	var near_phase: float = float(near.get("phase", 0.0))
	var far_phase: float = float(far.get("phase", 0.0))
	for _f in range(10):
		horde.frame_parity += 1
		em.update_enemies(0.02)
	_check(absf(float(near["phase"]) - near_phase - 10.0 * 0.02 * 7.0) < 0.01, "near enemy skipped AI frames")
	var far_progress: float = float(far["phase"]) - far_phase + float(far.get("lod_dt", 0.0)) * 7.0
	_check(absf(far_progress - 10.0 * 0.02 * 7.0) < 0.02, "far enemy lost time under LOD (%.3f)" % far_progress)
	_check(Vector2(far["pos"]).distance_to(far_start) > 1.0, "far enemy stopped moving under LOD")
	if failed:
		return
	print("HORDE_PRESSURE_OK growth=infinite desired_30=%d desired_90=%d budget_cap=%d governor=shrink_grow overflow=hp_points lod=alternate_frames" % [desired_30, desired_90, horde.budget_cap()])
	quit(0)
