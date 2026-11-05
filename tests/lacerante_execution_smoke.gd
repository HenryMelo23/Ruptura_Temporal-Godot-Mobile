extends SceneTree

## Lacerante rework: Laceracao (cap/expira/sangra pelo pipeline), barra de execucao,
## execucao de 0,9 s com alvo reservado, invulnerabilidade, Coagulo garantido.

var game: Node
const DT := 1.0 / 60.0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("LACERANTE_EXECUTION_FAIL " + message)
	quit(1)


func _e(pos: Vector2, hp: float) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var e: Dictionary = game.enemies[-1]
	e["pos"] = pos
	e["hp"] = hp
	e["max_hp"] = 1000.0
	e["speed"] = 0.0
	return e


func _run() -> void:
	game.startup_thanks_done = true
	game.unlocked_manifestation_ids["lacerante"] = true
	game.qa_data_unlocked = true
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i]["key"]) == "lacerante":
			game.selected_manifestation = i
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.enemies.clear()
	game.player_damage = 40.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	_check(game.manifestation_key == "lacerante", "not lacerante")
	var ex: RTLaceranteExecutionController = game._lacerante_exec()
	# Laceracao: limite, expiracao, sangramento via _damage_enemy.
	var dummy := _e(game.player_pos + Vector2(600, 0), 1000.0)
	for i in range(8):
		ex.apply_laceration(dummy, 1)
	_check(ex.stacks(dummy) == 5, "laceration cap failed: %d" % ex.stacks(dummy))
	var hp0: float = float(dummy["hp"])
	for _i in range(60):
		ex.update_bleed(dummy, DT)
	_check(float(dummy["hp"]) < hp0, "bleed did not damage")
	for _i in range(240):
		ex.update_bleed(dummy, DT)
	_check(ex.stacks(dummy) == 0, "laceration did not expire")
	# Barra: limiar = dano do Reforco.
	var thr: float = ex.threshold(dummy)
	_check(thr > 0.0 and absf(float(ex.bar_overlay(dummy)["ratio"]) - thr / 1000.0) < 0.001, "bar ratio mismatch")
	game.enemies.clear()
	# Alvo forte: Reforco so arma; o ATK reforcado sai normal (sem execucao) e a recarga e 15 s.
	var tough := _e(game.player_pos + Vector2(90, 0), 900.0)
	_check(game._try_arm_lacerante_empower(), "empower failed")
	_check(not ex.is_active() and game.lacerante_empowered_ready, "tough target should only arm")
	var tough_hp: float = float(tough["hp"])
	game._fire_lacerante(0, Vector2.RIGHT)
	_check(not ex.is_active() and float(tough["hp"]) < tough_hp, "plain reinforced hit failed")
	_check(is_equal_approx(ex.reforco_total, ex.REFORCO_COOLDOWN_PLAIN) and ex.reforco_remaining() > 14.0, "plain reinforced cooldown is not 15s")
	_check(not game._try_arm_lacerante_empower(), "reforco re-armed during cooldown")
	# ATK normal que acerta adianta a recarga, mas sem carta nao passa do piso de 4 s.
	for _hit in range(200):
		game._fire_lacerante(0, Vector2.RIGHT)
		tough["hp"] = 900.0
	var floor_left: float = ex.reforco_remaining()
	_check(floor_left > 3.9 and floor_left <= 4.01, "attack refund broke the 4s floor (%.2f)" % floor_left)
	game.cards_bought[game.CARD_INTERVALO_ID] = 10
	ex.start_reforco_cooldown(false)
	for _hit2 in range(200):
		game._fire_lacerante(0, Vector2.RIGHT)
		tough["hp"] = 900.0
	_check(ex.reforco_remaining() < 1.0, "Intervalo Fraturado did not lower the floor (%.2f)" % ex.reforco_remaining())
	game.cards_bought.erase(game.CARD_INTERVALO_ID)
	ex.reforco_ready_at = 0.0
	game.enemies.clear()
	# Alvo executavel: Reforco executa.
	var weak := _e(game.player_pos + Vector2(120, 10), 20.0)
	_check(ex.can_be_executed(weak), "weak target not executable (thr %.1f)" % ex.threshold(weak))
	var coag: int = int(game.lacerante_coagula)
	_check(game._try_arm_lacerante_empower() and not ex.is_active(), "reforco should only arm")
	game._fire_lacerante(0, (Vector2(weak["pos"]) - game.player_pos).normalized())
	_check(ex.is_active(), "reinforced ATK on executable did not execute")
	_check(is_equal_approx(ex.reforco_total, ex.REFORCO_COOLDOWN_EXECUTE), "execution cooldown is not 10s")
	_check(game._player_invulnerable() and game._local_player_controls_locked(), "player not protected during execution")
	_check(Vector2(game.player_pos).distance_to(Vector2(weak["pos"])) < 70.0, "geovana did not close in")
	_check(not game._damage_enemy(weak, 999.0, "atk_remoto", false) and float(weak["hp"]) == 20.0, "reserved target took foreign damage")
	for _i in range(int(0.8 / DT)):
		game.time_alive += DT
		ex.update(DT)
	_check(not game.enemies.has(weak) or float(weak["hp"]) <= 0.0, "execution did not kill")
	_check(int(game.lacerante_coagula) == coag + 1, "coagulum not granted")
	for _i in range(int(0.2 / DT)):
		ex.update(DT)
	_check(not ex.is_active() and not game._local_player_controls_locked(), "execution did not end")
	_check(game._player_invulnerable(), "no post-execution immunity")
	for _i in range(int(1.0 / DT)):
		ex.update(DT)
	_check(not game._player_invulnerable(), "post-execution immunity did not expire")
	_check(ex.cine.is_empty(), "execution camera did not release")
	# Cadeia rapida: a 3a execucao em 6 s fica sem camera, mais rapida e sem imunidade extra.
	ex.exec_times = [game.time_alive - 1.0, game.time_alive - 0.5]
	var chain := _e(game.player_pos + Vector2(80, 0), 5.0)
	ex.reforco_ready_at = 0.0
	game._try_arm_lacerante_empower()
	game._fire_lacerante(0, Vector2.RIGHT)
	_check(ex.is_active() and ex.cine.is_empty() and bool(ex.active.get("fast", false)), "fast chain kept the camera")
	for _i in range(int(0.5 / DT)):
		ex.update(DT)
	_check(not ex.is_active() and not game._player_invulnerable(), "fast chain granted extra immunity")
	print("LACERANTE_EXECUTION_OK cap=5 bleed=pipeline expire=true bar=true arm_tough=true execute=true reserved=true coagulum=true chain=true post_immunity=0.9 camera=released cd=10/15 floor=4 fast_chain=true")
	game._cleanup_runtime_resources()
	game.free()
	quit(0)
