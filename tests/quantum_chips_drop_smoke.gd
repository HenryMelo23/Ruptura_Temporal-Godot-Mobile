extends SceneTree

## Drop de cartas estilo RoR2 (curva por tempo/regiao, elite, piedade, sem travas)
## + chips quanticos (Sedenta, Multidao, Ganancia, Corruptor, Aleatorio).

var game: Node
var chips: RTQuantumChipController
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("QCHIP_FAIL " + message)


func _start(selected: Array, drop_mode: bool = false, random_mode: bool = false) -> void:
	chips = game._quantum_chips()
	chips.selected.clear()
	chips.random_mode = random_mode
	for id in selected:
		chips.selected[id] = true
	game._set_run_mode_local(game.RUN_MODE_DROP if drop_mode else game.RUN_MODE_SHOP)
	game.forced_initial_phase = 1
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	game.arauto_card_drops.clear()
	game.net_collected_drop_ids.clear()
	game.player_pos = Vector2(1200, 900)


func _enemy(offset: Vector2, hp: float = 100000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
	var e: Dictionary = game.enemies[-1]
	e["hp"] = hp
	e["max_hp"] = hp
	return e


func _run() -> void:
	await process_frame
	_test_drops()
	_test_sedenta()
	_test_multidao()
	_test_ganancia()
	_test_corruptor()
	_test_random_and_save()
	print("QUANTUM_CHIPS_DROP_SMOKE_%s" % ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)


func _test_drops() -> void:
	_start([], true)
	var dm = game._drop_mode()
	_check(is_equal_approx(dm.drop_chance(0.0, 1, 0), 0.04), "start chance is not 4%")
	_check(dm.drop_chance(10.0 * 60.0, 1, 0) > dm.drop_chance(5.0 * 60.0, 1, 0), "chance does not grow with time")
	_check(dm.drop_chance(10.0 * 60.0, 1, 3) > dm.drop_chance(10.0 * 60.0, 1, 0), "chance does not grow with regions")
	_check(is_equal_approx(dm.drop_chance(400.0 * 60.0, 1, 12), dm.MAX_DROP_CHANCE), "chance is not capped")
	_check(dm.drop_chance(20.0 * 60.0, 2, 0) < dm.drop_chance(20.0 * 60.0, 1, 0), "party scaling lost")
	game.time_alive = 0.0
	dm.pity_bonus = 0.0
	var common := {"type": game.ENEMY_COMMON}
	var elite := {"type": game.ENEMY_DEVOTO}
	_check(dm.kill_drop_chance(elite) > dm.kill_drop_chance(common) * 2.0, "elite multiplier missing")
	for i in range(10):
		dm.on_enemy_killed({"killed_by_peer_id": game._mp_unique_id()}, game.player_pos, 0.99)
	_check(absf(dm.pity_bonus - 0.05) < 0.0001, "pity did not grow per dry kill (%.3f)" % dm.pity_bonus)
	_check(dm.on_enemy_killed({"killed_by_peer_id": game._mp_unique_id()}, game.player_pos + Vector2(150, 0), 0.0), "forced drop failed")
	_check(is_equal_approx(dm.pity_bonus, 0.0), "pity did not reset on drop")
	_check(is_equal_approx(float(game.arauto_card_drops[-1].get("life", 0.0)), dm.DROP_LIFETIME) and dm.DROP_LIFETIME >= 10.0, "drop lifetime still short")
	# Travas removidas: pool com texturas descarregadas e raras sem a carta Sorte.
	game.RuntimeAssetController.release_transient_gallery_assets(game)
	game.cards_bought.erase("Sorte")
	game.time_alive = 900.0
	var rare_ok := false
	var pool_ok := false
	for value in game.CARDS:
		var card: Dictionary = value
		if dm._card_available_for_owner(card, game._mp_unique_id()):
			pool_ok = true
			if game._card_rarity_key(card) == game.CARD_RARITY_RARE:
				rare_ok = true
	_check(pool_ok, "drop pool empty when card textures are not resident")
	_check(rare_ok, "rare cards still require the Sorte card")


func _test_sedenta() -> void:
	_start([RTQuantumChipController.SEDENTA])
	_check(game.player_hp_max == int(round(game.PLAYER_BASE_HP * 0.1)), "Sedenta max hp is not 10%% (%d)" % game.player_hp_max)
	var e := _enemy(Vector2(120, 0))
	var before: float = float(e["hp"])
	game._damage_enemy(e, 10.0, "eletrica", false, true, game.player_pos, "basic_attack")
	var with_chip: float = before - float(e["hp"])
	chips.active.erase(RTQuantumChipController.SEDENTA)
	before = float(e["hp"])
	game._damage_enemy(e, 10.0, "eletrica", false, true, game.player_pos, "basic_attack")
	var plain: float = before - float(e["hp"])
	_check(absf(with_chip / plain - 6.0) < 0.05, "Sedenta damage is not +500%% (%.2f)" % (with_chip / plain))


func _test_multidao() -> void:
	_start([])
	game.time_alive = 400.0
	game.spawn_timer = 0.0
	game.enemy_manager.spawn_wave()
	var timer_plain: float = game.spawn_timer
	var count_plain: int = game.enemies.size()
	var hp_plain: float = float(game.enemies[0].get("max_hp", 1.0)) if count_plain > 0 else 1.0
	_start([RTQuantumChipController.MULTIDAO])
	game.time_alive = 400.0
	game.spawn_timer = 0.0
	game.enemy_manager.spawn_wave()
	_check(game.spawn_timer < timer_plain * 0.6, "Multidao did not speed spawns")
	_check(game.enemies.size() >= count_plain, "Multidao spawned fewer enemies")
	_check(game.enemies.size() > 0, "Multidao wave spawned nothing")
	if game.enemies.size() > 0:
		var spawned: Dictionary = game.enemies[0]
		game._spawn_enemy(String(spawned.get("type", game.ENEMY_COMMON)), game.player_pos + Vector2(500, 0))
		var reference: Dictionary = game.enemies[-1]
		var ratio: float = float(spawned.get("max_hp", 1.0)) / maxf(1.0, float(reference.get("max_hp", 1.0)))
		_check(ratio < 0.6, "Multidao enemies kept full hp (ratio %.2f)" % ratio)
	_check(hp_plain > 0.0, "")


func _test_ganancia() -> void:
	_start([RTQuantumChipController.GANANCIA])
	_check(is_equal_approx(chips.points_multiplier(), 2.0), "Ganancia points multiplier")
	game.score = 100000
	var cost: int = int(round(float(game._points_for_enemy({"points": 75})) * 3.0))
	var extra: int = chips.on_player_hit(20)
	_check(game.score == 100000 - cost and extra == 0, "Ganancia did not charge the hit (score %d, cost %d)" % [game.score, cost])
	game.score = 0
	extra = chips.on_player_hit(20)
	_check(extra == 10, "missing points did not become +50%% damage (%d)" % extra)
	var hp0: int = game.player_hp
	game.score = 0
	game._damage_player(20, "test_hit")
	_check(hp0 - game.player_hp > 20 - int(game.player_defense) - 1, "Ganancia debt damage not applied")


func _test_corruptor() -> void:
	_start([RTQuantumChipController.CORRUPTOR], true)
	var dm = game._drop_mode()
	game.time_alive = 900.0
	_check(dm.on_enemy_killed({"killed_by_peer_id": game._mp_unique_id()}, game.player_pos + Vector2(40, 0), 0.0), "corruptor drop failed")
	var drop: Dictionary = game.arauto_card_drops[-1]
	_check(bool(drop.get("mystery", false)) and String(drop.get("mystery_rarity", "")) != "", "drop is not a ? token")
	var bought_before: int = game.cards_bought.size()
	var deck_before: Dictionary = game.cards_bought.duplicate()
	drop["pos"] = game.player_pos
	game._update_arauto_card_drops(0.016)
	_check(chips.token_total() == 1, "token was not collected")
	_check(game.cards_bought == deck_before and game.cards_bought.size() == bought_before, "? token applied a card immediately")
	# Mais duas fichas: comum e incomum (ordem de resgate).
	chips.tokens = {"common": 1, "uncommon": 1}
	_check(game.shop_rift_controller.enabled(), "rift disabled in drop mode with Corruptor")
	game.shop_last_exit_time = -100.0
	game.shop_rift_next_allowed_time = 0.0
	_check(game.shop_rift_controller._should_spawn(), "pending ? tokens did not call the rift")
	game.shop_rift_controller.spawn("test", game.player_pos)
	_check(game.shop_rift_controller.enter(), "entering rift failed")
	var shop: RTCorruptorShop = game._corruptor_shop()
	_check(game.mode == RTCorruptorShop.MODE and shop.rarity == "common", "corruptor shop did not open on commons first")
	var commons: int = 0
	for c in game.CARDS:
		if game._card_rarity_key(c) == "common" and game._card_unlocked(c) and not game._card_at_max(c):
			commons += 1
	_check(shop.pool.size() == commons, "carousel does not list every common card")
	shop.step(1)
	shop.step(1)
	var chosen_id: String = game._card_id(shop.current_card())
	var count_before: int = game._card_count(shop.current_card())
	shop.pick()
	_check(game._card_count(game._find_card_by_id(chosen_id)) == count_before + 1, "picked card was not granted")
	_check(shop.rarity == "uncommon", "did not move to the next rarity")
	shop.pick()
	_check(game.mode == "game" and chips.token_total() == 0, "shop did not close after the last token")
	_check(String(chips.last_pick_id.get("common", "")) == chosen_id, "last pick not remembered")
	chips.tokens = {"common": 1}
	game.mode = "game"
	shop.open()
	_check(game._card_id(shop.current_card()) == chosen_id, "carousel did not return to the last picked card")
	shop.pick()
	game.mode = "game"


func _test_random_and_save() -> void:
	_start([], false, true)
	_check(chips.active.size() == 1 and chips.random_rolled != "", "random chip did not roll exactly one chip")
	var saved: Dictionary = game.quantum_chip_state
	chips.active.clear()
	game.quantum_chip_state = saved
	_check(chips.is_active(chips.random_rolled), "chip state did not survive save/restore")
	_check(game.save_controller._interrupted_run_field_names().has("quantum_chip_state"), "save field missing")
	# Aleatorio na selecao de manifestacao.
	game.mode = "manifest"
	game.manifest_select_stage = game.MANIFEST_STAGE_MANIFESTATION
	var before: int = game.selected_manifestation
	var changed := false
	for i in range(6):
		RTQuantumChipUI.pick_random_build(game)
		if game.selected_manifestation != before:
			changed = true
			break
	_check(changed, "random manifestation pick did nothing")
	game.mode = "game"
