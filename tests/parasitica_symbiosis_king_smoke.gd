extends SceneTree

## Simbiose Predatoria (HAB1) + Verme-Rei (E): contratos de regra.

var game: Node
var ctl: RTParasiticaController
var failed := false
var checks := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		return
	failed = true
	push_error("PARASITICA_KING_FAIL " + message)


func _setup() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.manifestation_key = "parasitica"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 200.0
	game.player_damage = 100.0
	game.player_attack_interval = game.PLAYER_BASE_ATTACK_INTERVAL
	game.player_hp_max = 1000.0
	game.player_hp = 500.0
	game.player_pos = Vector2(1600, 1200)
	game.enemies.clear()
	game.boss_active = false
	game.boss_hp = 0.0
	game.boss_parasite_seeds = 0
	game.boss_parasite_mark_time = 0.0
	game.arauto.clear()
	game.effects.clear()
	ctl = game._parasitica()
	ctl.clear_all()


func _enemy(offset: Vector2, hp: float = 100000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
	var e: Dictionary = game.enemies[-1]
	e["hp"] = hp
	e["max_hp"] = hp
	e["speed"] = 0.0
	e["damage"] = 0.0
	return e


func _seed(e: Dictionary, n: int) -> void:
	e["seeds"] = n
	e["parasite_mark_time"] = game.PARASITE_MARK_DURATION


func _hit(e: Dictionary, amount: float = 10.0) -> void:
	game._damage_enemy(e, amount, "parasitica", false, true, game.player_pos, "basic_attack")


func _step(dt: float, steps: int = 1) -> void:
	for i in range(steps):
		game.time_alive += dt
		ctl.update(dt)
		_reap()


func _reap() -> void:
	for i in range(game.enemies.size() - 1, -1, -1):
		var e: Dictionary = game.enemies[i]
		if float(e.get("hp", 0.0)) <= 0.0:
			game._kill_enemy(e)


func _run() -> void:
	await process_frame
	_setup()
	_test_symbiosis()
	_setup()
	_test_king()
	_setup()
	_test_integration()
	if failed:
		print("PARASITICA_KING_SMOKE_FAILED checks=%d" % checks)
		quit(1)
		return
	print("PARASITICA_KING_SMOKE_OK checks=%d" % checks)
	quit(0)


# ======================================================================
func _test_symbiosis() -> void:
	# Ativacao sem reticulo.
	_check(game._ground_target_profile(false).is_empty(), "HAB1 still exposes a ground reticle profile")
	_check(not game.player_control_controller.desktop_action_uses_aim("skill"), "desktop HAB1 still arms cursor aim")
	_check(is_equal_approx(game._skill_cooldown_base(), 8.0), "base cooldown is not 8s")
	_check(is_equal_approx(game._skill_cooldown(), game._intervalo_apply_to_hab1(8.0)), "HAB1 cooldown skips interval cards")
	game.last_skill_time = -999.0
	game._use_skill()
	_check(ctl.sym_active and is_equal_approx(ctl.sym_left, 9.0), "symbiosis did not start with 9s")
	_check(game.parasite_spit_zones.is_empty(), "old spit zone was spawned")
	var cd_mark: float = game.last_skill_time
	game._use_skill()
	_check(game.last_skill_time == cd_mark, "HAB1 recast ignored cooldown")

	# Fome so contra infestados.
	var clean := _enemy(Vector2(140, 0))
	var host := _enemy(Vector2(-140, 0))
	_hit(clean)
	_check(ctl.hunger == 0, "Fome gained against a target without larvae")
	_seed(host, 1)
	_hit(host)
	_check(ctl.hunger == 1, "Fome not gained against infested target")
	_hit(host)
	_check(ctl.hunger == 1, "Fome ignored 0.22s gain interval")
	_step(0.23)
	_hit(host)
	_check(ctl.hunger == 2, "Fome not gained after interval")

	# Bonus por acumulo e maximo 12.
	ctl.hunger = 30
	ctl._gain_hunger(1)
	_check(ctl.hunger == 12, "Fome passed base max 12")
	_check(is_equal_approx(ctl.damage_multiplier(), 1.36), "12 Fome damage != +36%")
	_check(is_equal_approx(ctl.attack_speed_multiplier(), 1.24), "12 Fome attack speed != +24%")
	_check(is_equal_approx(ctl.move_multiplier(), 1.06), "12 Fome move != +6%")
	ctl.hunger = 0
	var interval0: float = game._current_attack_interval()
	ctl.hunger = 12
	var interval12: float = game._current_attack_interval()
	_check(absf(interval0 / interval12 - 1.24) < 0.01, "attack interval did not use Fome (%.3f/%.3f)" % [interval0, interval12])
	ctl.hunger = 0
	var base_dmg_probe := _enemy(Vector2(0, 160))
	var before := float(base_dmg_probe["hp"])
	_hit(base_dmg_probe, 100.0)
	var plain_delta: float = before - float(base_dmg_probe["hp"])
	ctl.hunger = 12
	before = float(base_dmg_probe["hp"])
	_hit(base_dmg_probe, 100.0)
	var fed_delta: float = before - float(base_dmg_probe["hp"])
	_check(absf(fed_delta / plain_delta - 1.36) < 0.02, "Fome damage did not go through the damage path (%.2f)" % (fed_delta / plain_delta))

	# Mordida a cada 4 acertos (3 com Fome maxima), cura e larva.
	ctl.hunger = 0
	ctl.bite_counter = 0
	ctl.bite_cd = 0.0
	_seed(host, 1)
	game.player_hp = 500.0
	var host_hp: float = float(host["hp"])
	for i in range(3):
		_hit(host)
		_step(0.23)
	_check(ctl.pending_bites.is_empty() and int(host["seeds"]) == 1, "bite fired before the 4th hit")
	_hit(host)
	_step(0.1)
	_check(int(host["seeds"]) == 2, "bite did not implant a larva")
	_check(absf(game.player_hp - 515.0) < 0.6, "bite heal is not 1.5%% of max (%.2f)" % game.player_hp)
	_check(float(host["hp"]) < host_hp, "bite did no damage")
	# Intervalo interno 0,65s.
	for i in range(4):
		_hit(host)
	_step(0.1)
	_check(int(host["seeds"]) == 2, "bite ignored its 0.65s internal cooldown")
	_step(0.6)
	_hit(host)
	_step(0.1)
	_check(int(host["seeds"]) == 3, "bite did not fire after the internal cooldown")
	# Fome maxima: 3 acertos e cura 2%.
	ctl.hunger = 12
	ctl.bite_counter = 0
	ctl.bite_cd = 0.0
	game.player_hp = 500.0
	for i in range(3):
		_hit(host)
	_step(0.1)
	_check(int(host["seeds"]) == 4, "max Fome bite did not fire on the 3rd hit")
	_check(absf(game.player_hp - 520.0) < 0.6, "max Fome bite heal is not 2%%")
	# Sem atacar nao ha cura.
	game.player_hp = 500.0
	_step(0.1, 10)
	_check(is_equal_approx(game.player_hp, 500.0), "symbiosis healed without attacking")

	# Abate infestado: +2 Fome, +1,2s, ate 18s no total.
	ctl.hunger = 3
	var left_before: float = ctl.sym_left
	ctl.on_infested_kill({})
	_check(ctl.hunger == 5 and absf(ctl.sym_left - left_before - 1.2) < 0.001, "infested kill did not give +2 Fome / +1.2s")
	for i in range(20):
		ctl.on_infested_kill({})
	_check(absf(ctl.sym_extended - 9.0) < 0.001, "extension did not cap at 18s total")
	var killed := _enemy(Vector2(60, 60), 10.0)
	_seed(killed, 2)
	ctl.sym_extended = 0.0
	var hunger_before: int = ctl.hunger
	ctl.hunger = 1
	_hit(killed, 999.0)
	_reap()
	_check(ctl.hunger >= 3, "real infested kill did not feed Fome")

	# Perda por inatividade.
	ctl.sym_left = 9.0
	ctl.hunger = 10
	ctl.hunger_idle = 0.0
	_step(0.1, 24)
	_check(ctl.hunger == 10, "Fome dropped before 2.5s idle")
	_step(0.1, 10)
	_check(ctl.hunger <= 8 and ctl.hunger >= 7 and ctl.hunger_falling, "Fome did not fall 2/s after idle (%d)" % ctl.hunger)

	# Recast renova sem apagar.
	ctl.hunger = 7
	ctl.sym_left = 2.0
	game.last_skill_time = -999.0
	game.effects.clear()
	game._use_skill()
	_check(ctl.hunger == 7 and ctl.sym_left >= 9.0, "recast cleared Fome or did not renew")

	# Encerramento remove tudo.
	_step(0.5, 40)
	_check(not ctl.sym_active and ctl.hunger == 0 and is_equal_approx(ctl.damage_multiplier(), 1.0) and is_equal_approx(ctl.attack_speed_multiplier(), 1.0) and is_equal_approx(ctl.move_multiplier(), 1.0), "symbiosis end kept bonuses")
	_check(hunger_before >= 0, "")


# ======================================================================
func _test_king() -> void:
	# Sem alvo: nao gasta recarga.
	game.last_secondary_time = -999.0
	_enemy(Vector2(200, 0))
	game._use_secondary_skill()
	_check(game.last_secondary_time == -999.0 and not ctl.king_active(), "E without larvae consumed cooldown or spawned")
	_check(is_equal_approx(game._secondary_skill_cooldown(), game._intervalo_apply_to_ultimate(75.0)), "E cooldown is not 75s through interval cards")

	# Selecao: mais larvas; empate -> chefe > mini > mais perto.
	game.enemies.clear()
	var a := _enemy(Vector2(100, 0))
	var b := _enemy(Vector2(400, 0))
	var c := _enemy(Vector2(700, 0))
	_seed(a, 2)
	_seed(b, 4)
	_seed(c, 4)
	c["mini_boss"] = true
	_check(ctl.ref_rank(ctl.enemy_ref(c)) == 1, "mini boss rank")
	var best: Dictionary = ctl.best_host()
	_check(int(best["ref"]["uid"]) == int(c["uid"]), "tie did not prefer mini boss")
	c.erase("mini_boss")
	best = ctl.best_host()
	_check(int(best["ref"]["uid"]) == int(b["uid"]), "tie did not prefer the closest")
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 100000.0
	game.boss_hp_max = 100000.0
	game.boss_pos = game.player_pos + Vector2(900, 0)
	game.boss_parasite_seeds = 4
	game.boss_parasite_mark_time = 8.0
	best = ctl.best_host()
	_check(String(best["ref"]["kind"]) == "boss", "tie did not prefer the boss")
	game.boss_active = false
	game.boss_parasite_seeds = 0

	# Consumo e escala (4 larvas).
	game.last_secondary_time = -999.0
	game._use_secondary_skill()
	_check(ctl.king_active() and game.last_secondary_time == game.time_alive, "king did not spawn / cooldown not consumed")
	_check(int(b["seeds"]) == 0 and int(ctl.king["consumed"]) == 4, "host larvae were not consumed")
	_check(is_equal_approx(float(ctl.king["life"]), 18.0), "duration != 14 + larvae")
	_check(absf(ctl.king_damage_multiplier() - 1.82) < 0.001, "damage multiplier != 1.10 + 0.18*4")
	_check(absf(ctl.king_interval() - 0.56) < 0.001, "interval != 0.72 - 0.04*4 (%.3f)" % ctl.king_interval())
	_check(not bool(ctl.king["perfect"]), "4 larvae king is perfect")
	# Escala com 1 e 5 larvas.
	ctl.king["consumed"] = 1
	_check(absf(ctl.king_damage_multiplier() - 1.28) < 0.001 and absf(ctl.king_interval() - 0.68) < 0.001, "1 larva scale")
	ctl.king["consumed"] = 5
	_check(absf(ctl.king_damage_multiplier() - 2.0) < 0.001 and absf(ctl.king_interval() - 0.52) < 0.001, "5 larvae scale")
	ctl.clear_all()

	# Rei Perfeito.
	_seed(c, 5)
	game.last_secondary_time = -999.0
	game._use_secondary_skill()
	_check(bool(ctl.king["perfect"]) and int(ctl.king["fed"]) == 2 and is_equal_approx(float(ctl.king["life"]), 19.0), "perfect king state (life %.1f fed %d)" % [float(ctl.king.get("life", 0)), int(ctl.king.get("fed", 0))])
	_check(is_equal_approx(ctl.execute_threshold(), 0.25), "perfect execution threshold")
	_check(ctl.visual_level() > 1.4, "perfect king is not visually bigger")
	ctl.clear_all()

	# Perseguicao, implantacao, devorar, alimentado.
	game.enemies.clear()
	var t1 := _enemy(Vector2(150, 0))
	var t2 := _enemy(Vector2(-500, 200))
	_seed(t1, 1)
	game.last_secondary_time = -999.0
	game._use_secondary_skill()
	_check(ctl.king_active() and int(ctl.king["consumed"]) == 1, "1-larva king")
	var target_uid: int = int(ctl.king["target"]["uid"])
	var tgt = game._enemy_by_uid(target_uid)
	_step(1.0 / 60.0, 30)
	_check(String(ctl.king["state"]) == "attack", "king did not emerge to attack (%s)" % ctl.king["state"])
	var seeds_before: int = int(tgt.get("seeds", 0))
	var hp_before: float = float(tgt["hp"])
	_step(1.0 / 60.0, 50)
	_check(int(tgt.get("seeds", 0)) > seeds_before and float(tgt["hp"]) < hp_before, "king bites did not implant larvae / damage")
	# Devorar: forcar 4 larvas e esperar a proxima mordida.
	var fed_before: int = int(ctl.king["fed"])
	var life_before: float = float(ctl.king["life"])
	_seed(tgt, 4)
	var devours: int = int(ctl.king["devours"])
	for i in range(80):
		_step(1.0 / 60.0)
		if int(ctl.king["devours"]) > devours:
			break
	_check(int(ctl.king["devours"]) == devours + 1 and int(tgt.get("seeds", 0)) == 0, "devour did not consume 5 larvae")
	_check(int(ctl.king["fed"]) == fed_before + 1, "devour did not add Alimentado")
	_check(float(ctl.king["life"]) > life_before - 1.5 + 0.7, "Alimentado did not extend duration")
	# Troca de alvo preservando acumulos.
	var fed_keep: int = int(ctl.king["fed"])
	tgt["hp"] = 0.0
	_reap()
	_step(1.0 / 60.0, 6)
	_check(String(ctl.king["state"]) in ["burrow", "tunnel", "resurface", "attack"], "king did not switch underground (%s)" % ctl.king["state"])
	var other_uid: int = int(t1["uid"]) if target_uid == int(t2["uid"]) else int(t2["uid"])
	_step(1.0 / 60.0, 90)
	_check(int(Dictionary(ctl.king.get("target", {})).get("uid", -1)) == other_uid and String(ctl.king["state"]) == "attack", "king did not reach the next target")
	_check(int(ctl.king["fed"]) == fed_keep, "retarget lost Alimentado")

	# Execucao: comum abaixo de 20% (25% Perfeito).
	var exec_e := _enemy(Vector2(30, -200), 1000000.0)
	exec_e["hp"] = 1000000.0 * 0.19
	ctl.king["target"] = ctl.enemy_ref(exec_e)
	_seed(exec_e, 5)
	ctl._devour(ctl.enemy_ref(exec_e))
	_check(float(exec_e["hp"]) <= 0.0, "common enemy below 20% was not executed")
	var survive := _enemy(Vector2(30, -260), 1000000.0)
	survive["hp"] = 1000000.0 * 0.23
	_seed(survive, 5)
	ctl.king["perfect"] = false
	ctl._devour(ctl.enemy_ref(survive))
	_check(float(survive["hp"]) > 0.0, "normal king executed above 20%")
	ctl.king["perfect"] = true
	var perfect_e := _enemy(Vector2(30, -320), 1000000.0)
	perfect_e["hp"] = 1000000.0 * 0.23
	_seed(perfect_e, 5)
	ctl._devour(ctl.enemy_ref(perfect_e))
	_check(float(perfect_e["hp"]) <= 0.0, "perfect king did not execute below 25%")
	_reap()

	# Chefe: dano percentual pelo caminho seguro + invulnerabilidade.
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 1000000.0
	game.boss_hp_max = 1000000.0
	game.boss_pos = game.player_pos + Vector2(300, 0)
	game.boss_parasite_seeds = 5
	game.boss_parasite_mark_time = 8.0
	var boss_ref := {"kind": "boss", "uid": -1}
	var boss_before: float = game.boss_hp
	var fed_b: int = int(ctl.king["fed"])
	ctl._devour(boss_ref)
	var lost: float = boss_before - game.boss_hp
	# 6% da vida atual passa pelo _damage_boss (armadura/fases como qualquer dano).
	_check(lost >= boss_before * 0.02, "boss devour did not deal the current-hp chunk (lost %.0f)" % lost)
	_check(game.boss_parasite_seeds == 0 and int(ctl.king["fed"]) == fed_b + 1, "boss devour consumed/fed")
	var phase_keep: int = game.current_phase
	game.current_phase = 1
	game.boss1_time_wave = {"active": true}
	game.boss_parasite_seeds = 5
	boss_before = game.boss_hp
	ctl._devour(boss_ref)
	_check(is_equal_approx(game.boss_hp, boss_before), "devour ignored boss invulnerability window")
	game.boss1_time_wave = {}
	game.current_phase = phase_keep
	game.boss_active = false

	# Teto tecnico de extensao (10s) sem teto de dano.
	var fed_time0: float = float(ctl.king["fed_time"])
	for i in range(40):
		ctl._add_fed(1)
	_check(float(ctl.king["fed_time"]) <= 10.0 + 0.001 and float(ctl.king["fed_time"]) >= fed_time0, "fed extension passed 10s")
	_check(ctl.king_damage_multiplier() > 5.0, "Alimentado damage has a low hidden cap")
	_check(ctl.king_interval() >= RTParasiticaController.KING_TECH_MIN_INTERVAL, "interval below technical min")

	# Nova ativacao alimenta o rei existente (sem duplicar).
	var life_now: float = float(ctl.king["life"])
	var fed_now: int = int(ctl.king["fed"])
	var feeder := _enemy(Vector2(-60, 220))
	_seed(feeder, 3)
	game.last_secondary_time = -999.0
	game._use_secondary_skill()
	_check(ctl.king_active() and absf(float(ctl.king["life"]) - (life_now + 17.0)) < 0.05, "recast did not add initial duration")
	_check(int(ctl.king["fed"]) == fed_now + 2 and int(feeder["seeds"]) == 0, "recast did not feed +2 / consume host")

	# Encerramento e limpeza.
	ctl.king["life"] = 0.05
	_step(0.1, 2)
	_check(String(ctl.king.get("state", "")) == "leave", "king did not start leaving")
	_step(0.1, 8)
	_check(not ctl.king_active() and ctl.king.is_empty(), "king left orphan state")
	_step(0.2, 5)
	_check(ctl.events.is_empty(), "king events were not cleaned up")


# ======================================================================
func _test_integration() -> void:
	# Simbiose + rei no mesmo alvo ate devorar.
	var host := _enemy(Vector2(160, 0))
	_seed(host, 2)
	game.last_skill_time = -999.0
	game._use_skill()
	game.last_secondary_time = -999.0
	_seed(host, 3)
	var other := _enemy(Vector2(200, 30))
	_seed(other, 2)
	game._use_secondary_skill()
	var tgt = game._enemy_by_uid(int(ctl.king["target"]["uid"]))
	_check(tgt != null, "king target missing")
	_step(1.0 / 60.0, 30)
	var devours0: int = int(ctl.king["devours"])
	for i in range(240):
		if i % 4 == 0 and tgt != null and float(tgt.get("hp", 0.0)) > 0.0:
			game._apply_bullet_effect({"kind": "parasitica", "damage": 20.0, "pos": tgt["pos"]}, tgt)
		_step(1.0 / 60.0)
		if int(ctl.king["devours"]) > devours0:
			break
	_check(int(ctl.king["devours"]) > devours0, "symbiosis + king did not devour the shared host")
	_check(ctl.hunger > 0, "shared host did not build Fome")

	# Bonus atuais do jogador afetam ataques futuros do rei.
	var dmg100: float = ctl.king_damage()
	game.player_damage = 200.0
	_check(absf(ctl.king_damage() / dmg100 - 2.0) < 0.001, "king damage does not follow current player damage")
	game.player_damage = 100.0
	var iv: float = ctl.king_interval()
	game.player_attack_interval = game.PLAYER_BASE_ATTACK_INTERVAL * 0.5
	_check(ctl.king_interval() < iv * 0.6, "attack speed cards do not speed the king")
	game.player_attack_interval = game.PLAYER_BASE_ATTACK_INTERVAL

	# Save durante as habilidades.
	var saved: Dictionary = game.parasitica_ability_state
	_check(bool(saved.get("sym_active", false)) and Dictionary(saved.get("king", {})).has("fed"), "save state missing symbiosis/king")
	_check(game.save_controller._interrupted_run_field_names().has("parasitica_ability_state"), "save field list missing parasitica")
	var fed_saved: int = int(Dictionary(saved["king"])["fed"])
	ctl.clear_all()
	_check(not ctl.king_active() and not ctl.sym_active, "clear_all left state")
	game.parasitica_ability_state = saved
	_check(ctl.king_active() and int(ctl.king["fed"]) == fed_saved and ctl.sym_active, "save restore failed")

	# Limpeza ao trocar de fase e ao iniciar outra run.
	game._advance_to_phase(2)
	_check(not ctl.king_active() and not ctl.sym_active, "phase change kept parasitica state")
	game.parasitica_ability_state = saved
	game._start_game()
	game.set_process(false)
	_check(not ctl.king_active() and not ctl.sym_active, "new run kept parasitica state")

	# TP (Ninhada) inalterado.
	_setup()
	game.last_dash_time = -999.0
	game.last_facing = Vector2.RIGHT
	game._try_dash()
	var has_egg := false
	for effect in game.tp_effects:
		if String(Dictionary(effect).get("kind", "")) == "parasite_egg":
			has_egg = true
	_check(has_egg, "Parasitica TP no longer lays eggs")

	# Catalogo e dossie.
	var dossier: Dictionary = RTBuildChoiceDossier.manifestation("parasitica")
	var dossier_text: String = JSON.stringify(dossier)
	_check(dossier_text.find("Simbiose Predatória") >= 0 and dossier_text.find("Verme-Rei") >= 0 and dossier_text.find("Cuspe") < 0 and dossier_text.find("Enxame") < 0, "dossier still describes the old kit")
	var details_text: String = JSON.stringify(game._manifestation_details("parasitica"))
	_check(details_text.find("Simbiose") >= 0 and details_text.find("Cuspe") < 0, "catalog details still describe the old kit")
