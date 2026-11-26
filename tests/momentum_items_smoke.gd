extends SceneTree
## Itens de 26/11: Retorno Voluntario (usos guardados da HAB1), Estoque da
## Ganancia (dano por abate), Espectro Eletrico (orbes de velocidade) e Eco da
## Ruina (dano parcelado, so o ultimo golpe mata).
## godot4 --headless --path . --script tests/momentum_items_smoke.gd

const UserFileGuard = preload("res://tests/support/user_file_guard.gd")
const IDS := ["retorno_voluntario", "estoque_ganancia", "espectro_eletrico", "eco_ruina"]

var game: Node
var failures: Array[String] = []
var guards: Array = []


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
		game.momentum_items_controller.update(dt)


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
	var items = game.momentum_items_controller
	# Catalogo: os 4 sao comuns, desbloqueados e podem queimar.
	for id in IDS:
		var card: Dictionary = game._find_card_by_id(id)
		_check(not card.is_empty(), "%s fora do CARDS" % id)
		_check(game._card_rarity_key(card) == "common", "%s deveria ser comum" % id)
		_check(bool(game.unlocked_card_ids.get(id, false)), "%s deveria vir desbloqueado" % id)
		_check(bool(CardCatalogDefinitions.get_card_definition(id).get("can_burn", false)), "%s deveria aceitar Cinzas" % id)

	# --- Retorno Voluntario: 2 copias = 2 usos guardados, recarga igual.
	_own("retorno_voluntario", 2)
	var cd: float = game._skill_cooldown()
	game.last_skill_time = game.time_alive - cd - 1.0
	_tick(cd * 2.0 + 0.2)
	_check(items.hab1_charges == 2, "Retorno: usos guardados %d (esperado 2)" % items.hab1_charges)
	_check(is_equal_approx(game._skill_cooldown(), cd), "Retorno mudou a recarga da HAB1")
	game._use_skill(game.player_pos + Vector2(200, 0))
	var after_base: float = game.last_skill_time
	_check(is_equal_approx(after_base, game.time_alive), "primeiro uso deveria usar a HAB1 normal")
	# Efeitos da habilidade anterior travam a HAB1 enquanto duram (skill_lock).
	game.effects.clear()
	game._use_skill(game.player_pos + Vector2(200, 0))
	game.effects.clear()
	game._use_skill(game.player_pos + Vector2(200, 0))
	_check(items.hab1_charges == 0, "Retorno: dois usos guardados deveriam ser gastos (%d)" % items.hab1_charges)
	_check(is_equal_approx(game.last_skill_time, after_base), "usar o guardado reiniciou a recarga")
	_tick(cd * 0.5)
	_check(items.hab1_charges == 0, "guardado recarregou com a HAB1 em recarga")
	_own("retorno_voluntario", 0)
	_tick(0.1)

	# --- Estoque da Ganancia.
	_own("estoque_ganancia", 1)
	var me := {"killed_by_peer_id": game._mp_unique_id()}
	for k in range(14):
		items.on_enemy_killed(me)
	_check(items.ganancia_stacks == 10, "Ganancia: limite de 10 (%d)" % items.ganancia_stacks)
	_check(is_equal_approx(items.damage_multiplier(), 1.35), "Ganancia: 10 x 3,5%% = +35%% (%.3f)" % items.damage_multiplier())
	var dealt: float = game._apply_limiar_ruina_damage(100.0, 10.0, 100.0, "atk", "basic_attack", game.player_pos)
	_check(dealt >= 134.9, "Ganancia nao entrou no dano direto (%.1f)" % dealt)
	_tick(6.0)
	game._apply_limiar_ruina_damage(10.0, 10.0, 100.0, "atk", "basic_attack", game.player_pos)
	_tick(6.0)
	_check(items.ganancia_stacks == 10, "causar dano deveria renovar os 7 s")
	_tick(7.2)
	_check(items.ganancia_stacks == 0, "Ganancia deveria zerar apos 7 s sem dano")
	items.on_enemy_killed({"killed_by_peer_id": game._mp_unique_id() + 99})
	_check(items.ganancia_stacks == 0, "abate de outro jogador contou")
	_own("estoque_ganancia", 2)
	_check(items.ganancia_max_stacks() == 15 and is_equal_approx(items.ganancia_per_stack(), 0.045), "Ganancia com 2 copias: 15 acumulos e 4,5%%")
	_own("estoque_ganancia", 0)

	# --- Espectro Eletrico.
	_own("espectro_eletrico", 1)
	items.orb_timer = 0.0
	_tick(10.1)
	_check(items.orbs.size() == 1, "Espectro: 1 orbe em 10 s (%d)" % items.orbs.size())
	if items.orbs.size() > 0:
		game.player_pos = Vector2(items.orbs[0]["pos"])
		_tick(0.05)
	_check(items.speed_stacks == 1 and is_equal_approx(items.movement_speed_bonus(), 0.12), "Espectro: pegar o orbe = +12%%")
	_check(game._new_common_speed_multiplier() >= 1.119, "Espectro fora da velocidade de movimento")
	items.speed_stacks = 9
	items.speed_timer = 12.0
	items.speed_stacks = mini(items.speed_max_stacks(), items.speed_stacks)
	_check(items.speed_stacks == 3, "Espectro: limite de 3 acumulos com 1 copia")
	_own("espectro_eletrico", 2)
	_check(is_equal_approx(items.espectro_interval(), 9.0) and items.speed_max_stacks() == 6, "Espectro com 2 copias: 9 s e 6 acumulos")
	_tick(12.5)
	_check(items.speed_stacks == 0, "Espectro: bonus deveria acabar em 12 s")
	_own("espectro_eletrico", 0)
	_tick(0.1)

	# --- Eco da Ruina: 3 golpes, so o ultimo mata.
	_own("eco_ruina", 1)
	game.player_hp_max = 200
	game.player_hp = 50
	_check(items.on_player_hit(100) == 0, "Eco deveria segurar o golpe")
	_check(items.pending_eco_hits() == 3, "Eco: 3 golpes (%d)" % items.pending_eco_hits())
	_tick(0.5)
	_check(game.player_hp == 20, "Eco: 1o golpe de 30 (hp %d)" % game.player_hp)
	_tick(0.45)
	_check(game.player_hp == 1, "Eco: golpe do meio nao mata (hp %d)" % game.player_hp)
	_tick(0.45)
	_check(game.player_hp <= 0, "Eco: o ultimo golpe pode matar (hp %d)" % game.player_hp)
	_check(items.on_player_hit(10) == 10, "Eco em recarga deveria deixar o dano passar")
	_tick(15.1)
	_check(items.eco_ready(), "Eco: recarga de 15 s")
	game.player_hp = 200
	game.player_defense = 0
	var before: int = game.player_hp
	game.run_retry_invulnerability_timer = 0.0
	game._damage_player(40, "test_hit", true)
	_check(game.player_hp == before and items.pending_eco_hits() == 3, "Eco nao esta no dano sofrido (hp %d, golpes %d)" % [game.player_hp, items.pending_eco_hits()])
	_own("eco_ruina", 2)
	_check(items.eco_hit_count() == 4, "Eco com 2 copias: 4 golpes")

	game.mode = "menu"
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for guard in guards:
		guard.restore()
	if failures.is_empty():
		print("MOMENTUM_ITEMS_SMOKE_OK")
		quit(0)
	else:
		for f in failures:
			printerr("MOMENTUM_ITEMS_SMOKE_FAIL " + f)
		quit(1)
