extends SceneTree

## Teste prolongado: mantem a Simbiose, alimenta o Verme-Rei repetidamente e
## confirma que o snowball acontece sem vazar estado ou entidades.
## Simula CDR extremo no E (recast a cada 20s) para exercitar o rei permanente.

var game: Node
var ctl: RTParasiticaController
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("PARASITICA_SOAK_FAIL " + message)


func _spawn_ring() -> void:
	while game.enemies.size() < 14:
		var a: float = game.rng.randf_range(0.0, TAU)
		var d: float = game.rng.randf_range(150.0, 420.0)
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(a) * d)
		var e: Dictionary = game.enemies[-1]
		e["hp"] = 2600.0
		e["max_hp"] = 2600.0
		e["speed"] = 0.0
		e["damage"] = 0.0


func _focus_target() -> Dictionary:
	var king_target: Dictionary = Dictionary(ctl.king.get("target", {})) if ctl.king_active() else {}
	if not king_target.is_empty() and String(king_target.get("kind", "")) == "enemy":
		var e = game._enemy_by_uid(int(king_target["uid"]))
		if e != null and float(e.get("hp", 0.0)) > 0.0:
			return e
	var best: Dictionary = {}
	var best_d := INF
	for e in game.enemies:
		if float(e.get("hp", 0.0)) <= 0.0:
			continue
		var d: float = Vector2(e["pos"]).distance_squared_to(game.player_pos)
		if d < best_d:
			best = e
			best_d = d
	return best


func _run() -> void:
	await process_frame
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.manifestation_key = "parasitica"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 100.0
	game.player_damage = 100.0
	game.player_pos = Vector2(1600, 1200)
	game.enemies.clear()
	game.boss_active = false
	game.arauto.clear()
	ctl = game._parasitica()
	ctl.clear_all()
	var dt := 1.0 / 60.0
	var attack_timer := 0.0
	var last_e_try := -999.0
	var kills := 0
	var sym_frames := 0
	var hunger_sum := 0.0
	var max_fed := 0
	var first_king_mult := 0.0
	var peak_king_mult := 0.0
	var max_events := 0
	var max_trail := 0
	var max_bites := 0
	var max_pending := 0
	var update_usec := 0
	var frames := 0
	var e_casts := 0
	var recasts := 0
	var seconds := 150.0
	while frames < int(seconds / dt):
		frames += 1
		game.time_alive += dt
		_spawn_ring()
		# Geovana: ATK no alvo em foco + Simbiose sempre que pronta.
		attack_timer -= dt
		if attack_timer <= 0.0:
			attack_timer += game._current_attack_interval()
			var target := _focus_target()
			if not target.is_empty():
				game._apply_bullet_effect({"kind": "parasitica", "damage": game.player_damage * 0.88, "pos": target["pos"]}, target)
		if game.time_alive - game.last_skill_time >= game._skill_cooldown():
			game.effects = game.effects.filter(func(e): return not bool(e.get("skill_lock", false)))
			game._use_skill()
		if game.time_alive - last_e_try >= 20.0:
			last_e_try = game.time_alive
			var was_active: bool = ctl.king_active()
			game.last_secondary_time = -999.0
			game._use_secondary_skill()
			if ctl.king_active():
				e_casts += 1
				if was_active:
					recasts += 1
				if first_king_mult <= 0.0:
					first_king_mult = ctl.king_damage_multiplier()
		var t0 := Time.get_ticks_usec()
		ctl.update(dt)
		update_usec += Time.get_ticks_usec() - t0
		for e in game.enemies:
			game._update_enemy_dots(e, dt)
		for i in range(game.enemies.size() - 1, -1, -1):
			if float(game.enemies[i].get("hp", 0.0)) <= 0.0:
				game._kill_enemy(game.enemies[i])
				kills += 1
		if game.effects.size() > 400:
			game.effects.clear()
		game.heal_orbs.clear()
		if ctl.sym_active:
			sym_frames += 1
			hunger_sum += float(ctl.hunger)
		if ctl.king_active():
			max_fed = maxi(max_fed, int(ctl.king["fed"]))
			peak_king_mult = maxf(peak_king_mult, ctl.king_damage_multiplier())
			max_trail = maxi(max_trail, Array(ctl.king.get("trail", [])).size())
		max_events = maxi(max_events, ctl.events.size())
		max_bites = maxi(max_bites, ctl.bite_visuals.size())
		max_pending = maxi(max_pending, ctl.pending_bites.size())
	var uptime: float = float(sym_frames) / float(frames)
	var avg_hunger: float = hunger_sum / maxf(1.0, float(sym_frames))
	var devours_seen := max_fed
	_check(uptime > 0.85, "symbiosis uptime too low %.2f" % uptime)
	_check(avg_hunger > 6.0, "average Fome too low %.1f" % avg_hunger)
	_check(e_casts >= 5 and recasts >= 3, "king casts/recasts %d/%d" % [e_casts, recasts])
	_check(peak_king_mult > first_king_mult * 2.0, "king did not snowball (%.2f -> %.2f)" % [first_king_mult, peak_king_mult])
	_check(max_events <= RTParasiticaController.EVENT_LIMIT and max_bites <= RTParasiticaController.EVENT_LIMIT and max_trail <= RTParasiticaController.TRAIL_POINTS and max_pending <= 4, "visual/event lists grew unbounded")
	_check(game.enemies.size() <= 14, "enemy list leaked")
	# Fim: sem novos casts, tudo expira e limpa.
	var drain := 0
	while drain < int(60.0 / dt):
		drain += 1
		game.time_alive += dt
		ctl.update(dt)
	_check(not ctl.king_active() and ctl.king.is_empty() and not ctl.sym_active and ctl.events.is_empty() and ctl.bite_visuals.is_empty() and ctl.pending_bites.is_empty(), "state leaked after abilities expired")
	var avg_us: float = float(update_usec) / float(frames)
	print("PARASITICA_SOAK %s secs=%d kills=%d uptime=%.2f avg_fome=%.1f casts=%d recasts=%d max_fed=%d king_mult=%.2f->%.2f update_avg_us=%.1f" % ["OK" if not failed else "FAILED", int(seconds), kills, uptime, avg_hunger, e_casts, recasts, max_fed, first_king_mult, peak_king_mult, avg_us])
	quit(1 if failed else 0)
