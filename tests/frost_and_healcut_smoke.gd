extends SceneTree

## Gelo do Sineiro (geada, congelamento, patinacao) e corte de cura da fase 6.

var game: Node
var checks := 0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		push_error("FROST_HEALCUT_FAIL " + msg)
		quit(1)


func _setup_player() -> void:
	game.mode = "game"
	game.is_dead = false
	game.player_hp_max = 1000
	game.player_hp = 500
	game.player_stun_timer = 0.0
	game.player_control_immunity_timer = 0.0
	game.player_frost_stacks = 0
	game.player_frost_timer = 0.0
	game.player_ice_slip_timer = 0.0
	game.player_ice_slip_dir = Vector2.ZERO
	game.player_ice_slip_speed = 1.0
	game.boss6_heal_cut_timer = 0.0
	game.revive_heal_penalty_timer = 0.0


func _run() -> void:
	await process_frame
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)

	# ---------------------------------------------------------------- GEADA
	game.current_phase = 2
	_setup_player()
	game._add_frost_stack(1, "teste")
	_check(game.player_frost_stacks == 1, "geada nao acumulou")
	var slow_1: float = game._environment_player_slow_mult()
	_check(slow_1 < 1.0, "1 carga de geada nao deixou lento (%.2f)" % slow_1)
	game._add_frost_stack(1, "teste")
	_check(game.player_frost_stacks == 2, "segunda carga nao entrou")
	_check(game._environment_player_slow_mult() < slow_1, "2 cargas nao sao mais lentas que 1")
	# Na ultima carga o corpo trava e as cargas se desfazem.
	game._add_frost_stack(2, "teste")
	_check(game.player_frost_stacks == 0, "cargas nao zeraram ao congelar")
	_check(game.player_stun_timer > 0.0, "nao congelou ao encher a geada")
	# A geada cai sozinha com o tempo.
	_setup_player()
	game._add_frost_stack(1, "teste")
	game._update_frost(game.FROST_DECAY_TIME + 0.05)
	_check(game.player_frost_stacks == 0, "geada nao decaiu sozinha")

	# ------------------------------------------------------------ PATINACAO
	_setup_player()
	_check(game._apply_ice_slip(Vector2.RIGHT, 0.1) == Vector2.RIGHT, "sem gelo o movimento deve passar intacto")
	_check(is_equal_approx(game._ice_slip_speed_mult(), 1.0), "sem gelo a velocidade deve ser cheia")
	game._apply_ice_slip_floor(3.0)
	_check(game.player_ice_slip_timer > 0.0, "chao congelado nao ativou")
	# A direcao demora a obedecer.
	var first: Vector2 = game._apply_ice_slip(Vector2.RIGHT, 1.0 / 60.0)
	_check(first.length() < 0.9, "no gelo a direcao nao deveria responder na hora (%.2f)" % first.length())
	for i in range(90):
		game._apply_ice_slip(Vector2.RIGHT, 1.0 / 60.0)
	_check(game.player_ice_slip_dir.x > 0.9, "a direcao nunca alcancou o comando (%.3f)" % game.player_ice_slip_dir.x)
	# Ao soltar, o corpo continua escorregando antes de parar.
	var after_release: Vector2 = game._apply_ice_slip(Vector2.ZERO, 1.0 / 60.0)
	_check(after_release.length() > 0.5, "o corpo parou seco no gelo (%.2f)" % after_release.length())
	_check(game._ice_slip_speed_mult() < 1.0, "a inercia deveria reduzir a velocidade ao soltar")
	for i in range(240):
		game._apply_ice_slip(Vector2.ZERO, 1.0 / 60.0)
	_check(game.player_ice_slip_dir == Vector2.ZERO, "o deslize nunca parou")
	# O chao descongela.
	game._update_frost(4.0)
	_check(game.player_ice_slip_timer <= 0.0, "o chao congelado nao expirou")

	# Estilhacos do Sineiro empilham geada ao acertar.
	_setup_player()
	game._damage_player(10, "sineiro_shard")
	_check(game.player_frost_stacks == 1, "estilhaco do Sineiro nao aplicou geada")

	# --------------------------------------------------- CORTE DE CURA (fase 6)
	game.current_phase = 6
	_setup_player()
	var full: float = game._heal_player(100.0, "teste")
	_check(full > 90.0, "cura normal deveria ser cheia (%.0f)" % full)
	game.player_hp = 500
	game._damage_player(10, "boss6_carnage_pool")
	_check(game.boss6_heal_cut_timer > 0.0, "habilidade do chefe 6 nao cortou a cura")
	var cut: float = game._heal_player(100.0, "teste")
	_check(cut < full * 0.5, "a cura nao foi cortada (%.0f de %.0f)" % [cut, full])
	_check(is_equal_approx(cut, 100.0 * game.BOSS6_HEAL_CUT_MULT), "corte fora do multiplicador")
	# Outra habilidade qualquer da lista tambem corta.
	_setup_player()
	game._damage_player(10, "boss6_reflux_wave")
	_check(game.boss6_heal_cut_timer > 0.0, "refluxo organico nao cortou a cura")
	# Fora da fase 6 nao corta.
	game.current_phase = 1
	_setup_player()
	game._damage_player(10, "boss6_carnage_pool")
	_check(game.boss6_heal_cut_timer <= 0.0, "corte de cura vazou para outra fase")
	# A Necro-Erosao ficou mais curta.
	_check(is_equal_approx(game.BOSS6_NECRO_EROSION_TIME, 6.0), "duracao da Necro-Erosao mudou do combinado")
	game.current_phase = 6
	game._start_boss6_necro_erosion()
	_check(is_equal_approx(game.boss6_necro_erosion_timer, game.BOSS6_NECRO_EROSION_TIME), "Necro-Erosao nao usou a duracao nova")

	print("FROST_HEALCUT_OK checks=%d geada_max=%d corte=%.0f%% erosao=%.1fs" % [checks, game.FROST_MAX_STACKS, game.BOSS6_HEAL_CUT_MULT * 100.0, game.BOSS6_NECRO_EROSION_TIME])
	quit(0)
