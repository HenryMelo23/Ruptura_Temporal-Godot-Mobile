extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game._finish_startup_thanks()
	game._start_game()
	game.set_process(false)
	var card: Dictionary = game._find_card_by_id("Disparo crescente")
	game._apply_card(game._find_card_by_id("carta_zero"))
	game._apply_card(card)
	var enhanced := card.duplicate(true)
	enhanced["cinzas_return_buff"] = true
	enhanced["cinzas_buff_stacks"] = 1
	game._apply_card(enhanced)
	var stats: Dictionary = game._current_common_card_stat_bonuses()
	var expected := "%.1f%%" % (float(stats.damage_bonus) / game._manifestation_base_damage() * 100.0)
	assert(game._deck_effect_text(card).contains(expected), "deck must include Carta Zero and Cinzas like actual damage")
	assert(game._card_count(card) == 2, "burn bonus is not an extra physical copy")
	var porcao: Dictionary = game._find_card_by_id("Porcao")
	var old_max: int = game.player_hp_max
	game.player_hp = 1.0
	game._apply_card(porcao)
	var heal: float = game._apply_carta_zero_to_common_value("Porcao", "heal", game.PORCAO_HEAL_OLD_MAX_RATIO)
	var max_gain: float = game._apply_carta_zero_to_common_value("Porcao", "overflow_hp", game.PORCAO_MAX_HP_GAIN_RATIO)
	assert(game.player_hp_max - old_max == int(round(old_max * max_gain)))
	assert(is_equal_approx(game.player_hp - 1.0, round(old_max * heal)))
	assert(game._deck_effect_text(porcao).contains("cura %.0f%%" % (heal * 100.0)))
	assert(game._deck_effect_text(porcao).contains("em %.0f%%" % (max_gain * 100.0)))
	var before: Dictionary = game.cards_bought.duplicate(true)
	game._rpc_remote_deck(42, {"counts": {"Disparo crescente": 1}, "effects": {"Disparo crescente": "auto attack +15.0%"}}, "Outro")
	game.deck_view_peer_id = 42
	assert(game._deck_effect_text(card) == "auto attack +15.0%")
	assert(game.cards_bought == before, "reading remote effects must never change local gameplay")
	game._rpc_remote_deck(42, {"Disparo crescente": 1}, "Legado")
	assert(game._deck_effect_text(card).contains("indisponivel"), "legacy remote packet must not show local effects")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	print("DECK_EFFECT_CONSISTENCY_OK actual_damage=true cinzas=true zero=true porcao=true remote=true legacy=true")
	quit(0)
