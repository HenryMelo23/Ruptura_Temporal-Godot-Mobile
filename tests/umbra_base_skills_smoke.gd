extends SceneTree

## Rebobinar e Eco Profetico: disponibilidade, efeito, fuga com teleporte,
## aprendizado de desvio, combo e save/load.

var game: Node
var checks := 0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		push_error("UMBRA_BASE_SKILLS_FAIL " + msg)
		quit(1)


func _setup() -> void:
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 30000.0
	game.boss_hp = 28000.0
	var c: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.boss_pos = c + Vector2(300, 0)
	game.player_pos = c + Vector2(-200, 0)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_stun_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.boss5_dimension = "base"
	game.boss5_transmute_hangover = 0.0
	game.boss5_authoritative_decision = {}
	game.last_dash_time = -10.0
	game.phase5_player_history.clear()
	game._reset_phase5_state()


func _hist_moving(vel: Vector2) -> void:
	game.phase5_player_history.clear()
	for i in range(10):
		game.phase5_player_history.append(game.player_pos - vel * 0.1 * float(10 - i))


func _step(skills: RTUmbraBaseSkills, seconds: float, move: Vector2 = Vector2.ZERO) -> void:
	var dt := 1.0 / 60.0
	var t := 0.0
	while t < seconds:
		game.time_alive += dt
		if game.player_stun_timer <= 0.0:
			game.player_pos += move * dt
		game.player_stun_timer = maxf(0.0, game.player_stun_timer - dt)
		skills.update(dt)
		t += dt


func _run() -> void:
	await process_frame
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game._advance_to_phase(5)
	game.set_process(false)
	# So a camada base: o teste nao depende de arquivos de outros testes.
	game._umbra_mind().load_layers(false)
	_setup()
	var skills: RTUmbraBaseSkills = game._umbra_base_skills()

	# Disponibilidade: so na dimensao base e depois do cooldown inicial.
	var avail: Array = game._umbra_available_actions()
	_check(not avail.has("ECO_PROFETICO"), "eco disponivel antes do cooldown inicial")
	skills.cooldowns["ECO_PROFETICO"] = 0.0
	skills.cooldowns["REBOBINAR"] = 0.0
	avail = game._umbra_available_actions()
	_check(avail.has("ECO_PROFETICO") and avail.has("REBOBINAR"), "kit base ausente na dimensao base")
	game.boss5_dimension = "vortice"
	_check(not game._umbra_available_actions().has("REBOBINAR"), "rebobinar vazou para outra dimensao")
	game.boss5_dimension = "base"

	# Rebobinar puxa de volta e causa dano.
	var anchor: Vector2 = game.player_pos
	game._spawn_umbra_action("REBOBINAR")
	_check(skills.rewinds.size() == 1, "rebobinar nao armou")
	var hp0: int = game.player_hp
	_step(skills, 1.0, Vector2(320, 0))
	_check(game.player_pos.distance_to(anchor) > 250.0, "jogador nao se afastou no teste")
	_step(skills, 0.9)
	_check(game.player_pos.distance_to(anchor) < 4.0, "rebobinar nao puxou de volta (dist %.1f)" % game.player_pos.distance_to(anchor))
	_check(game.player_hp < hp0, "rebobinar nao causou dano")
	_check(int(skills.stats["REBOBINAR"]["hits"]) == 1, "acerto do rebobinar nao contado")
	var escape_before: float = float(skills.learned["rewind_escape"])

	# Teleportar quebra a marca e ensina a UMBRA.
	_setup()
	skills = game._umbra_base_skills()
	skills.cooldowns["REBOBINAR"] = 0.0
	anchor = game.player_pos
	game._spawn_umbra_action("REBOBINAR")
	_step(skills, 0.5, Vector2(300, 0))
	game.last_dash_time = game.time_alive
	game.player_pos += Vector2(220, 0)
	var escaped_pos: Vector2 = game.player_pos
	_step(skills, 1.5)
	_check(skills.rewinds.is_empty(), "marca nao quebrou com teleporte")
	_check(game.player_pos.distance_to(escaped_pos) < 1.0, "jogador foi puxado mesmo apos teleporte")
	_check(float(skills.learned["rewind_escape"]) > escape_before, "fuga nao aumentou rewind_escape")

	# Eco acerta quem anda em linha reta.
	_setup()
	skills = game._umbra_base_skills()
	skills.cooldowns["ECO_PROFETICO"] = 0.0
	var vel := Vector2(200, 0)
	_hist_moving(vel)
	hp0 = game.player_hp
	game._spawn_umbra_action("ECO_PROFETICO")
	_check(skills.ecos.size() >= 1, "eco nao criou sigilo")
	_step(skills, RTUmbraBaseSkills.ECO_WARNING + 0.05, vel)
	_check(game.player_hp < hp0, "eco nao acertou jogador previsivel")

	# Aprendizado: jogador que sempre desvia para o mesmo lado.
	var side_before: float = float(skills.learned["eco_side"])
	for n in range(5):
		# Mesmo encontro: so reposiciona (o aprendizado vive no encontro e na camada do jogador).
		var c: Vector2 = game.experimental_phase_controller.boss_encounter_center()
		game.boss_pos = c + Vector2(300, 0)
		game.player_pos = c + Vector2(-200, 0)
		game.player_hp = 1000
		skills.ecos.clear()
		skills.cooldowns["ECO_PROFETICO"] = 0.0
		_hist_moving(vel)
		game._spawn_umbra_action("ECO_PROFETICO")
		# Desvia para a direita do proprio movimento (+orthogonal).
		_step(skills, RTUmbraBaseSkills.ECO_WARNING + 0.05, vel * 0.5 + vel.normalized().orthogonal() * 180.0)
	_check(float(skills.learned["eco_side"]) > side_before + 0.3, "eco nao aprendeu o lado do desvio (%.2f)" % float(skills.learned["eco_side"]))
	_check(int(skills.learned["eco_samples"]) >= 6, "amostras do eco nao contadas")
	# Com leitura suficiente o eco cobre os dois lados.
	skills.ecos.clear()
	skills.cooldowns["ECO_PROFETICO"] = 0.0
	_hist_moving(vel)
	game._spawn_umbra_action("ECO_PROFETICO")
	_check(skills.ecos.size() == 2, "eco experiente deveria cobrir dois lados")

	# Combo: com rebobinar armado o eco cai no ponto de retorno.
	_setup()
	skills = game._umbra_base_skills()
	skills.cooldowns["REBOBINAR"] = 0.0
	skills.cooldowns["ECO_PROFETICO"] = 0.0
	anchor = game.player_pos
	game._spawn_umbra_action("REBOBINAR")
	_step(skills, 0.3, Vector2(250, 0))
	var scores := {}
	skills.score(scores, ["ECO_PROFETICO"], 400.0)
	_check(float(scores["ECO_PROFETICO"]) > 1.4, "combo nao priorizou o eco")
	game._spawn_umbra_action("ECO_PROFETICO")
	_check(Vector2(skills.ecos[0]["pos"]).distance_to(anchor) < 1.0, "eco do combo nao mirou a ancora")

	# Save/load.
	var snap: Dictionary = game.umbra_base_skill_state
	game.umbra_base_skill_state = {}
	game.umbra_base_skill_state = snap
	_check(skills.rewinds.size() == 1 and skills.ecos.size() == 1, "save/load perdeu efeitos ativos")

	# Escolha real: em 200 decisoes na base, as duas aparecem.
	_setup()
	skills = game._umbra_base_skills()
	var seen := {}
	for n in range(200):
		skills.cooldowns["REBOBINAR"] = 0.0
		skills.cooldowns["ECO_PROFETICO"] = 0.0
		skills.rewinds.clear()
		game.boss5_teleport_cooldown = 0.0 if n % 2 == 0 else 5.0
		game.player_pos = game.boss_pos + Vector2.from_angle(float(n)) * (150.0 + float(n % 7) * 80.0)
		_hist_moving(Vector2.from_angle(float(n) * 0.3) * float(n % 5) * 60.0)
		game.last_dash_time = game.time_alive - (0.2 if n % 3 == 0 else 10.0)
		seen[game._umbra_choose_action()] = true
	_check(seen.has("ECO_PROFETICO"), "decisao nunca escolheu eco")
	_check(seen.has("REBOBINAR"), "decisao nunca escolheu rebobinar")
	_check(seen.has("ATAQUE") or seen.has("TELEPORTE"), "kit base engoliu ataque/teleporte")
	print("UMBRA_BASE_SKILLS_OK checks=%d seen=%s" % [checks, str(seen.keys())])
	quit(0)
