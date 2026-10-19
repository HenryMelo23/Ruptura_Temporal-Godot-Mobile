extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	print("UNCOMMON_CARDS_SMOKE_FAIL %s" % message)
	quit(1)


func _find_effect(kind: String) -> bool:
	for effect in game.common_card_effects:
		if String(effect.get("kind", "")) == kind:
			return true
	return false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	var ids := ["rastro_de_retorno", "eco_de_impacto", "zona_de_descompressao", "ferrolho_ruptura"]
	for card_id in ids:
		var card: Dictionary = game._find_card_by_id(card_id)
		_check(not card.is_empty(), "missing_%s" % card_id)
		_check(game._is_uncommon_card(card), "not_uncommon_%s" % card_id)
		_check(not game._is_common_card(card), "still_common_%s" % card_id)
		_check(not game._is_rare_card(card), "became_rare_%s" % card_id)
		_check(game._card_rarity_label(card) == "INCOMUM", "bad_label_%s" % card_id)
		_check(not game._can_burn_shop_card(card), "uncommon_burnable_%s" % card_id)

	var legendary_probe := {"name": "Espaco Lendario", "rarity": game.CARD_RARITY_LEGENDARY}
	_check(game._is_legendary_card(legendary_probe), "legendary_space_missing")
	_check(game._card_rarity_label(legendary_probe) == "LENDARIA", "legendary_label_missing")

	var chance_without_luck: float = game._chance_carta_incomum()
	_check(chance_without_luck >= 0.22, "uncommon_base_chance_missing")
	_check(is_equal_approx(game._chance_carta_rara(), 0.0), "rare_unlocked_without_luck")
	game.cards_bought["Sorte"] = 4
	_check(game._chance_carta_incomum() > chance_without_luck, "luck_did_not_improve_uncommon")
	_check(game._chance_carta_incomum() > game._chance_carta_rara(), "uncommon_not_easier_than_rare")

	game.cards_bought["rastro_de_retorno"] = 1
	_check(is_equal_approx(game._rastro_interval(), 6.5), "rastro_interval_not_improved")
	_check(game._rastro_duration() > 17.0, "rastro_duration_not_improved")
	_check(is_equal_approx(game._rastro_speed_multiplier_bonus(), 0.16), "rastro_speed_not_improved")
	_check(is_equal_approx(game._rastro_tp_recovery(), 0.55), "rastro_tp_not_improved")

	game.cards_bought["eco_de_impacto"] = 1
	_check(game._eco_required_impacts() == 5, "eco_hit_requirement_not_improved")
	_check(is_equal_approx(game._eco_damage_ratio(), 0.45), "eco_damage_not_improved")
	_check(game._eco_radius() > 53.0, "eco_radius_not_improved")
	game._register_eco_impact("enemy", 77, game.player_pos, 100.0, "atk", "basic_attack")
	_check(_find_effect("eco_charge"), "eco_charge_vfx_missing")

	game.cards_bought["zona_de_descompressao"] = 1
	_check(is_equal_approx(game._zona_pressure_radius(), 190.0), "zona_radius_not_improved")
	_check(is_equal_approx(game._zona_required_pressure(), 3.0), "zona_pressure_not_improved")
	_check(is_equal_approx(game._zona_charge_time(), 0.9), "zona_charge_not_improved")
	_check(is_equal_approx(game._zona_cooldown_time(), 6.8), "zona_cooldown_not_improved")
	_check(is_equal_approx(game._zona_slow_ratio(), 0.30), "zona_slow_not_improved")
	_check(is_equal_approx(game._zona_knockback(), 280.0), "zona_knockback_not_improved")

	var ferrolho: Dictionary = game._find_card_by_id("ferrolho_ruptura")
	game.cards_bought["ferrolho_ruptura"] = 0
	game.ferrolho_ruptura_armed = false
	game._apply_card(ferrolho)
	_check(game.ferrolho_ruptura_armed, "ferrolho_not_armed_on_purchase")
	_check(is_equal_approx(game.FERROLHO_RUPTURA_COOLDOWN, 8.0), "ferrolho_cooldown_not_improved")
	_check(game._ferrolho_root_duration() >= 1.6, "ferrolho_root_not_improved")
	_check(is_equal_approx(game._ferrolho_boss_slow_ratio(), 0.30), "ferrolho_boss_slow_not_improved")
	_check(game._ferrolho_boss_slow_duration() >= 1.5, "ferrolho_boss_duration_not_improved")
	_check(_find_effect("ferrolho_ready"), "ferrolho_ready_vfx_missing")

	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	print("UNCOMMON_CARDS_SMOKE_OK cards=4 chance_without_luck=true luck_scales=true legendary_space=true mechanics=true vfx=true")
	quit(0)
