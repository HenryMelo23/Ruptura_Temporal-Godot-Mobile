extends SceneTree

const CardCatalogDefinitions = preload("res://scripts/catalog/card_catalog_definitions.gd")

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("TREGUA_RARITY_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _pool_count(cards: Array, card_id: String) -> int:
	var count := 0
	for card_value in cards:
		var card: Dictionary = Dictionary(card_value)
		if game._card_id(card) == card_id:
			count += 1
	return count


func _shop_roll_has_card(cards: Array, card_id: String) -> bool:
	return _pool_count(cards, card_id) > 0


func _cleanup() -> void:
	game.mode = "menu"
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	game = null


func _run() -> void:
	await process_frame
	game._start_game()
	game.cards_bought.clear()
	game.cinzas_burn_marks.clear()
	game.cinzas_card_bonuses.clear()
	var tregua: Dictionary = game._find_card_by_id(game.CARD_TREGUA_ID)
	_check(not tregua.is_empty(), "Trégua was not registered")
	_check(String(tregua.get("id", "")) == "tregua_regenerativa", "card id changed")
	_check(String(tregua.get("desc", "")) == "Sem receber dano, regenera vida passivamente.", "functional text changed")
	_check(String(tregua.get("icon", "")) == "Deck/carta-Tr_guaRegenerativa1.png", "frame 1 changed")
	_check(String(tregua.get("frame_2", "")) == "Deck/carta-Tr_guaRegenerativa2.png", "frame 2 changed")
	_check(game._card_rarity_key(tregua) == game.CARD_RARITY_RARE, "rarity key is not rare")
	_check(game._is_rare_card(tregua) and not game._is_common_card(tregua), "rare/common classifiers conflict")
	_check(game.RARE_CARD_NAMES.count(String(tregua.get("name", ""))) == 1, "canonical rare name is missing or duplicated")

	var definition: Dictionary = CardCatalogDefinitions.get_card_definition(game.CARD_TREGUA_ID)
	_check(String(definition.get("category", "")) == CardCatalogDefinitions.CATEGORY_HEALING, "healing category changed")
	_check(String(definition.get("rarity", "")) == CardCatalogDefinitions.RARITY_RARE, "catalog rarity is not rare")
	_check(not CardCatalogDefinitions.is_burn_eligible(game.CARD_TREGUA_ID), "rare Trégua remained burnable")
	game.unlocked_card_ids[game.CARD_TREGUA_ID] = true

	var common_pool: Array = game._shop_rarity_pool(game.CARD_RARITY_COMMON, {})
	var rare_pool: Array = game._shop_rarity_pool(game.CARD_RARITY_RARE, {})
	_check(_pool_count(common_pool, game.CARD_TREGUA_ID) == 0, "Trégua remained in the common shop pool")
	_check(_pool_count(rare_pool, game.CARD_TREGUA_ID) == 1, "Trégua is missing or duplicated in the rare shop pool")
	_check(not game._rare_cards_unlocked(), "rare gate opened without Sorte")
	_check(not game._card_available_for_reward(tregua, true, false), "boss reward gate exposed Trégua without Sorte")
	_check(_pool_count(game._available_card_drop_pool(), game.CARD_TREGUA_ID) == 0, "drop pool exposed Trégua without Sorte")
	for _i in range(256):
		_check(not _shop_roll_has_card(game._roll_shop_cards_v2("open"), game.CARD_TREGUA_ID), "shop rolled Trégua without Sorte")

	game.cards_bought["Sorte"] = 1
	game.luck = 1.0
	_check(game._rare_cards_unlocked(), "Sorte did not open the rare gate")
	_check(game._card_available_for_reward(tregua, true, false), "boss reward gate rejected Trégua with Sorte")
	_check(_pool_count(game._available_card_drop_pool(), game.CARD_TREGUA_ID) == 1, "drop pool did not contain exactly one Trégua with Sorte")
	_check(_pool_count(game._pick_boss_reward_cards(game.CARDS.size(), game.CARDS.size()), game.CARD_TREGUA_ID) == 1, "boss pool did not select exactly one Trégua")
	game._set_shop_rng_seed(30291)
	var rolled_tregua := false
	for _i in range(2048):
		if _shop_roll_has_card(game._roll_shop_cards_v2("open"), game.CARD_TREGUA_ID):
			rolled_tregua = true
			break
	_check(rolled_tregua, "rare shop rolls never selected Trégua after Sorte")

	game.cards_bought.clear()
	game.cards_bought[game.CARD_TREGUA_ID] = 1
	game.player_hp_max = 1000
	game.player_hp = 800
	var baseline_delay: float = game._tregua_delay()
	var baseline_regen: float = game._tregua_regen_per_second()
	_check(is_equal_approx(baseline_delay, 5.7), "activation delay changed")
	_check(is_equal_approx(baseline_regen, 3.0), "regeneration power changed")
	game.cinzas_burn_marks = [{"card_id": game.CARD_TREGUA_ID, "stacks": 4, "return_buff": true}]
	game.cinzas_card_bonuses[game.CARD_TREGUA_ID] = 4
	_check(game._cinzas_bonus_stacks(game.CARD_TREGUA_ID) == 0, "legacy Cinzas bonus still stacks on rare Trégua")
	_check(is_equal_approx(game._tregua_delay(), baseline_delay), "legacy Cinzas mark changed the activation delay")
	_check(is_equal_approx(game._tregua_regen_per_second(), baseline_regen), "legacy Cinzas bonus changed regeneration power")
	game._sanitize_legacy_cinzas_rarity_state()
	_check(game._cinzas_mark_index(game.CARD_TREGUA_ID) < 0, "legacy Cinzas mark was not removed")
	_check(not game.cinzas_card_bonuses.has(game.CARD_TREGUA_ID), "legacy Cinzas bonus was not removed")
	game.tregua_regenerativa_timer = baseline_delay
	game._update_tregua_regenerativa(1.0)
	_check(game.tregua_regenerativa_active, "regeneration did not activate")
	_check(is_equal_approx(float(game.player_hp), 800.0 + baseline_regen), "regeneration tick changed")

	print("TREGUA_RARITY_SMOKE_OK rarity=rare category=healing shop=true drops=true boss=true sorte_gate=true save_legacy_safe=true regen_unchanged=true")
	_cleanup()
	await process_frame
	quit(0)
