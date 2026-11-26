extends SceneTree
## Itens incomuns de 26/11: Fe Emaculada, Tornozeleira de Chumbo, Disparo
## Vital, Ultimo Impulso, Sangue Coagulado, Pulso da Conversao, Bobina
## Catalisadora, Espinhos do Vaghnor, Veu Entropico e Botas de Veludo.
## godot4 --headless --path . --script tests/skirmish_items_smoke.gd

const UserFileGuard = preload("res://tests/support/user_file_guard.gd")
const IDS := ["fe_emaculada", "tornozeleira_chumbo", "disparo_vital", "ultimo_impulso", "sangue_coagulado", "pulso_conversao", "bobina_catalisadora", "espinhos_vaghnor", "veu_entropico", "botas_veludo"]

var game: Node
var failures: Array[String] = []
var guards: Array = []
var next_uid := 5000


func _initialize() -> void:
	for path in ["user://hud_config.save", "user://interrupted_run.save", "user://player_progress_cache.json", "user://player_profile.save", "user://merchant_npc.cfg", "user://story_progress.cfg", "user://quantum_chips.cfg"]:
		guards.append(UserFileGuard.new(path))
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)


func _own(card_id: String, n: int) -> void:
	for c in game.CARDS:
		if String(Dictionary(c).get("id", "")) == card_id:
			game.cards_bought[game._card_counter_key(c)] = n
			return
	failures.append("item nao esta no catalogo: " + card_id)


func _tick(seconds: float) -> void:
	var dt := 1.0 / 30.0
	var t := 0.0
	while t < seconds:
		t += dt
		game.time_alive += dt
		game.skirmish_items_controller.update(dt)


func _enemy(offset: Vector2, hp: float = 100.0) -> Dictionary:
	next_uid += 1
	var e := {"type": game.ENEMY_COMMON, "uid": next_uid, "pos": game.player_pos + offset, "hp": hp, "max_hp": hp, "speed": game.enemy_speed_base, "stun": 0.0, "phase": 0.0, "killed_by_peer_id": game._mp_unique_id()}
	game.enemies.append(e)
	return e


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.enemies.clear()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(1200, 1200)
	var c = game.skirmish_items_controller
	for id in IDS:
		var card: Dictionary = game._find_card_by_id(id)
		_check(not card.is_empty(), "%s fora do CARDS" % id)
		_check(game._card_rarity_key(card) == "uncommon", "%s deveria ser incomum" % id)
		_check(bool(game.unlocked_card_ids.get(id, false)), "%s deveria vir desbloqueado" % id)

	# --- Fe Emaculada: 10 copias = chance de 108%, recarga zera na hora.
	_own("fe_emaculada", 10)
	game.last_skill_time = game.time_alive
	game.last_secondary_time = game.time_alive
	c.on_enemy_killed(_enemy(Vector2(300, 0)))
	_check(game.time_alive - game.last_skill_time >= game._skill_cooldown(), "Fe: HAB1 nao ficou pronta")
	_check(game.time_alive - game.last_secondary_time >= game._secondary_skill_cooldown(), "Fe: ULT nao ficou pronta")
	_own("fe_emaculada", 0)

	# --- Tornozeleira de Chumbo.
	_own("tornozeleira_chumbo", 1)
	var e1 := _enemy(Vector2(100, 0))
	c.on_enemy_hit(e1, 10.0, false, "atk", "basic_attack", 0)
	_check(is_equal_approx(float(e1.get("evolution_slow", 0.0)), 2.0) and is_equal_approx(float(e1.get("evolution_slow_mult", 1.0)), 0.4), "Tornozeleira: 60%% por 2 s")
	_own("tornozeleira_chumbo", 2)
	c.on_enemy_hit(e1, 10.0, false, "atk", "basic_attack", 0)
	_check(is_equal_approx(float(e1.get("evolution_slow", 0.0)), 4.0), "Tornozeleira: 2 copias = 4 s")
	var other := _enemy(Vector2(120, 0))
	c.on_enemy_hit(other, 10.0, false, "atk", "basic_attack", 77777)
	_check(not other.has("evolution_slow"), "Tornozeleira: acerto de outro jogador contou")
	# Cinzas: os 10 incomuns novos queimam; os incomuns antigos, nao.
	game.cards_bought[game.CARD_CINZAS_ID] = 1
	_check(game._can_burn_shop_card(game._find_card_by_id("tornozeleira_chumbo")), "Cinzas deveria aceitar a Tornozeleira")
	_check(not game._can_burn_shop_card(game._find_card_by_id("Roubo de Vida")), "Cinzas nao deveria aceitar incomum antigo")
	_own("tornozeleira_chumbo", 1)
	game.cinzas_card_bonuses["tornozeleira_chumbo"] = 1
	var burned := _enemy(Vector2(140, 0))
	c.on_enemy_hit(burned, 10.0, false, "atk", "basic_attack", 0)
	_check(is_equal_approx(float(burned.get("evolution_slow", 0.0)), 3.0), "Cinzas: queima soma meia copia (%.2f s)" % float(burned.get("evolution_slow", 0.0)))
	game.cinzas_card_bonuses.erase("tornozeleira_chumbo")
	game.cards_bought[game.CARD_CINZAS_ID] = 0
	_own("tornozeleira_chumbo", 0)

	# --- Disparo Vital.
	_own("disparo_vital", 1)
	_check(is_equal_approx(c.crit_bonus(), 0.05), "Disparo: +5% de critico")
	game.player_hp_max = 500
	game.player_hp = 100
	c.on_enemy_hit(e1, 10.0, true, "atk", "basic_attack", 0)
	_check(game.player_hp >= 107 and game.player_hp <= 109, "Disparo: critico cura 8 (hp %d)" % game.player_hp)
	_own("disparo_vital", 2)
	var hp_before: int = game.player_hp
	c.on_enemy_hit(e1, 10.0, true, "atk", "basic_attack", 0)
	_check(game.player_hp - hp_before >= 11, "Disparo: 2 copias curam 12 (+%d)" % (game.player_hp - hp_before))
	_own("disparo_vital", 0)

	# --- Ultimo Impulso.
	_own("ultimo_impulso", 1)
	c.on_enemy_killed(_enemy(Vector2(200, 0)))
	_check(is_equal_approx(c.movement_speed_bonus(), 1.25), "Impulso: +125%% no abate (%.2f)" % c.movement_speed_bonus())
	_tick(0.5)
	_check(c.movement_speed_bonus() > 0.5 and c.movement_speed_bonus() < 0.75, "Impulso: some ao longo de 1 s")
	_tick(0.6)
	_check(c.movement_speed_bonus() == 0.0, "Impulso: deveria acabar em 1 s")
	_own("ultimo_impulso", 2)
	c.on_enemy_killed(_enemy(Vector2(200, 0)))
	_check(is_equal_approx(c.impulso_duration, 1.5), "Impulso: 2 copias = 1,5 s")
	_tick(1.6)
	_own("ultimo_impulso", 0)

	# --- Sangue Coagulado.
	_own("sangue_coagulado", 1)
	var max_before: int = game.player_hp_max
	for k in range(130):
		c.on_enemy_killed(_enemy(Vector2(200, 0)))
	_check(game.player_hp_max - max_before == 100, "Sangue: +1 por abate ate +100 (+%d)" % (game.player_hp_max - max_before))
	_own("sangue_coagulado", 0)

	# --- Pulso da Conversao.
	_own("pulso_conversao", 1)
	game.boss_active = true
	game.boss_hp = 1000.0
	game.player_hp_max = 400
	game.player_hp = 100
	_tick(20.2)
	_check(game.player_hp >= 290, "Pulso: cura de 50%% na luta de chefe (hp %d)" % game.player_hp)
	game.player_hp = 100
	_tick(20.2)
	_check(game.player_hp == 100, "Pulso: 1 copia = uma vez por luta")
	game.boss_active = false
	_tick(0.1)
	_own("pulso_conversao", 2)
	_check(is_equal_approx(c.pulso_interval(), 18.0), "Pulso: 2 copias = 18 s")
	_own("pulso_conversao", 0)

	# --- Bobina Catalisadora.
	_own("bobina_catalisadora", 1)
	var base_q: float = game._skill_cooldown()
	_own("bobina_catalisadora", 0)
	var plain_q: float = game._skill_cooldown()
	_own("bobina_catalisadora", 1)
	_check(is_equal_approx(base_q, plain_q * 0.8), "Bobina: HAB1 -20%% (%.2f / %.2f)" % [base_q, plain_q])
	for k in range(7):
		c.on_skill_used("skill_q")
	_check(c.bobina_charges == 5, "Bobina: limite de 5 cargas (%d)" % c.bobina_charges)
	game.enemies.clear()
	var hit := _enemy(Vector2(60, 0), 5000.0)
	var near_a := _enemy(Vector2(90, 40), 5000.0)
	var near_b := _enemy(Vector2(70, -50), 5000.0)
	c.on_enemy_hit(hit, 10.0, false, "atk", "basic_attack", 0)
	_check(c.bobina_charges == 2, "Bobina: o raio gasta 3 cargas (%d)" % c.bobina_charges)
	_check(float(near_a["hp"]) < 5000.0 and float(near_b["hp"]) < 5000.0, "Bobina: os raios nao acertaram")
	c.on_enemy_hit(hit, 10.0, false, "atk", "basic_attack", 0)
	_check(c.bobina_charges == 2, "Bobina: sem 3 cargas nao dispara")
	_own("bobina_catalisadora", 0)

	# --- Espinhos do Vaghnor (10 copias = 100% de sangrar).
	_own("espinhos_vaghnor", 10)
	game.enemies.clear()
	var bleeder := _enemy(Vector2(50, 0), 5000.0)
	c.on_enemy_hit(bleeder, 10.0, false, "atk", "basic_attack", 0)
	c.on_enemy_hit(bleeder, 10.0, false, "atk", "basic_attack", 0)
	c.on_enemy_hit(bleeder, 10.0, false, "atk", "basic_attack", 0)
	_check(int(bleeder.get("item_bleed", 0)) == 3, "Espinhos: 3 sangramentos (%d)" % int(bleeder.get("item_bleed", 0)))
	var hp_bleed: float = float(bleeder["hp"])
	_tick(1.1)
	_check(float(bleeder["hp"]) < hp_bleed, "Espinhos: sangramento nao causou dano")
	var heir := _enemy(Vector2(150, 0), 5000.0)
	bleeder["poison"] = 3.0
	c.on_enemy_killed(bleeder)
	_check(int(heir.get("item_bleed", 0)) == 1 and is_equal_approx(float(heir.get("poison", 0.0)), 0.99), "Espinhos: 33%% dos debuffs passou (sangue %d, veneno %.2f)" % [int(heir.get("item_bleed", 0)), float(heir.get("poison", 0.0))])
	_own("espinhos_vaghnor", 0)
	game.enemies.clear()

	# --- Veu Entropico.
	_own("veu_entropico", 1)
	game.player_hp_max = 400
	game.player_hp = 80
	var at: Vector2 = game.player_pos
	c.on_player_damaged(20.0)
	_check(c.veiled(), "Veu: deveria ativar abaixo de 25%")
	_check(is_equal_approx(c.movement_speed_bonus(), 0.4), "Veu: +40% de velocidade")
	game.player_pos = at + Vector2(400, 0)
	var targets: Array = game._combat_targets()
	_check(targets.size() > 0 and Vector2(targets[0]["pos"]) == at, "Veu: inimigos deveriam mirar onde ela sumiu")
	_check(c.veil_blocks(game.ENEMY_COMMON), "Veu: contato deveria errar")
	_check(c.player_alpha() < 0.6, "Veu: Geovana deveria ficar translucida")
	_tick(5.1)
	_check(not c.veiled() and Vector2(game._combat_targets()[0]["pos"]) == game.player_pos, "Veu: dura 5 s")
	c.on_player_damaged(10.0)
	_check(not c.veiled(), "Veu: recarga de 30 s")
	_own("veu_entropico", 2)
	c.veu_cooldown = 0.0
	c.on_player_damaged(10.0)
	_check(is_equal_approx(c.veu_cooldown, 15.0), "Veu: 2 copias = 15 s de recarga")
	_tick(5.1)
	_own("veu_entropico", 0)
	game.player_hp = 400

	# --- Botas de Veludo.
	_own("botas_veludo", 1)
	c.combat_quiet = 0.0
	_tick(1.0)
	_check(c.movement_speed_bonus() == 0.0, "Botas: em combate nao acelera")
	_tick(0.6)
	_check(is_equal_approx(c.movement_speed_bonus(), 0.3), "Botas: +30%% fora de combate (%.2f)" % c.movement_speed_bonus())
	_own("botas_veludo", 2)
	_check(is_equal_approx(c.movement_speed_bonus(), 0.6), "Botas: 2 copias = +60%")
	c.on_player_damaged(5.0)
	_check(c.movement_speed_bonus() == 0.0, "Botas: levar dano tira de fora de combate")
	_check(game._new_common_speed_multiplier() >= 1.0, "velocidade comum quebrou")

	game.mode = "menu"
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for guard in guards:
		guard.restore()
	if failures.is_empty():
		print("SKIRMISH_ITEMS_SMOKE_OK")
		quit(0)
	else:
		for f in failures:
			printerr("SKIRMISH_ITEMS_SMOKE_FAIL " + f)
		quit(1)
