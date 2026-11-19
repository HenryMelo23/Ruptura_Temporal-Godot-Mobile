extends SceneTree

## Henry Incendiario: Q/ultimate repelem + lentidao, guarda durante a canalizacao,
## teleporte e novo toque cancelam. Tambem cobre empurrao suave do jogador (sem teleporte).

var game: Node
const DT := 1.0 / 60.0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("HENRY_CHANNEL_GUARD_FAIL " + message)
	quit(1)


func _ring(count: int, radius: float) -> Array:
	var made: Array = []
	for index in range(count):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(float(index) * TAU / float(count)) * radius)
		game.enemies[-1]["hp"] = 1.0e7
		game.enemies[-1]["max_hp"] = 1.0e7
		made.append(game.enemies[-1])
	return made


func _min_distance(list: Array) -> float:
	var best := INF
	for enemy in list:
		best = minf(best, Vector2(enemy["pos"]).distance_to(game.player_pos))
	return best


func _sim(seconds: float) -> void:
	var owner = game.henry_incendiary_ability_controller
	for _i in range(int(round(seconds / DT))):
		game.time_alive += DT
		owner.update(DT)
		game.player_shove.update(game, DT)


func _run() -> void:
	game.startup_thanks_done = true
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 0
	game.selected_effect = 0
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.henry_entry_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	game.player_pos = game.WORLD_SIZE * 0.5
	_check(game.mutation_key == "incendiario", "mutation is %s" % game.mutation_key)
	var owner = game.henry_incendiary_ability_controller

	# Ultimate: repele e aplica lentidao ao iniciar.
	var ring := _ring(8, 70.0)
	game.last_secondary_time = -999.0
	game._use_secondary_skill()
	_check(game.henry_ultimate_cast_active, "ultimate did not start")
	_check(float(ring[0].get("evolution_slow", 0.0)) > 0.0 and float(ring[0].get("evolution_slow_mult", 1.0)) <= 0.5, "repel did not slow")
	_sim(0.5)
	_check(_min_distance(ring) > 95.0, "ultimate repel left enemies close: %.1f" % _min_distance(ring))
	# Guarda: inimigo que chega perto durante a canalizacao e empurrado.
	var intruder: Array = _ring(1, 40.0)
	_sim(0.3)
	_check(_min_distance(intruder) > 70.0, "channel guard did not push intruder: %.1f" % _min_distance(intruder))
	# Apertar a ultimate de novo cancela.
	game._use_secondary_skill()
	_check(not game.henry_ultimate_cast_active, "re-press did not cancel ultimate")

	# Q: teleporte cancela e o Henry se move.
	game.enemies.clear()
	_ring(6, 80.0)
	game.last_skill_time = -999.0
	game._use_skill(game.player_pos + Vector2(200.0, 0.0))
	_check(game.henry_skill_cast_active, "skill did not start")
	_check(owner.channel_interruptible(), "skill channel not interruptible")
	_check(game._combat_controls_active(), "combat input closed during channel")
	game.last_dash_time = -999.0
	var before: Vector2 = game.player_pos
	game._try_dash_to_world(game.player_pos + Vector2(0.0, 220.0))
	_check(not game.henry_skill_cast_active, "teleport did not cancel skill")
	_check(game.henry_spin_active, "teleport did not start spin dash after cancel")
	# Q novamente cancela o proprio Q.
	game.henry_spin_active = false
	game.last_skill_time = -999.0
	game._use_skill(game.player_pos + Vector2(200.0, 0.0))
	_check(game.henry_skill_cast_active, "second skill did not start")
	game._use_skill()
	_check(not game.henry_skill_cast_active, "re-press did not cancel skill")

	# Empurrao do jogador: desloca ao longo de quadros, nao teleporta.
	game.player_pos = game.WORLD_SIZE * 0.5
	var start: Vector2 = game.player_pos
	game._shove_player(Vector2(160.0, 0.0))
	game.player_shove.update(game, DT)
	var first_step: float = Vector2(game.player_pos).distance_to(start)
	_check(first_step > 5.0 and first_step < 60.0, "shove first frame moved %.1f" % first_step)
	for _i in range(30):
		game.player_shove.update(game, DT)
	_check(absf(game.player_pos.distance_to(start) - 160.0) < 3.0, "shove total %.1f" % game.player_pos.distance_to(start))
	_check(not game.player_shove.active, "shove did not finish")
	# Teleporte no meio do empurrao descarta o resto.
	game._shove_player(Vector2(-160.0, 0.0))
	game.player_shove.update(game, DT)
	game.player_pos += Vector2(0.0, 300.0)
	game.player_shove.update(game, DT)
	_check(not game.player_shove.active, "teleport did not cancel shove")
	print("HENRY_CHANNEL_GUARD_OK repel_slow=true guard=true repress_cancel=true tp_cancel=true shove_smooth=true first_step=%.1f" % first_step)
	game._cleanup_runtime_resources()
	game.free()
	quit(0)
