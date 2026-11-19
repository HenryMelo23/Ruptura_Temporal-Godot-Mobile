extends SceneTree

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("DISPARO_CRESCENTE_BALANCE_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.cards_bought.clear()
	game.common_card_stat_cache = game._common_card_stat_defaults()
	game._recalculate_common_card_stat_bonuses()

	var damage_card: Dictionary = game._find_card_by_id("Disparo crescente")
	_check(not damage_card.is_empty(), "damage card was not found")
	_check(String(damage_card.get("desc", "")).find("+20%") >= 0, "card description does not show +20%")
	_check(Array(game._card_stat_chips("Disparo crescente")).has("+20% DANO"), "shop stat chip does not show +20%")

	game.cards_bought["Disparo crescente"] = 1
	game._recalculate_common_card_stat_bonuses()
	var expected_one: float = game._manifestation_base_damage() * 0.20
	_check(is_equal_approx(float(game.common_card_stat_cache.get("damage_bonus", 0.0)), expected_one), "one copy did not grant 20% base manifestation damage")
	var projection_one: Array = game._card_projection_lines(damage_card)
	_check(String(projection_one[0]).find("+20.0%") >= 0, "current projection does not show +20.0%")
	_check(String(projection_one[1]).find("+44.0%") >= 0, "next projection does not show compound +44.0%")

	game.cards_bought["Disparo crescente"] = 2
	game._recalculate_common_card_stat_bonuses()
	var expected_two: float = game._manifestation_base_damage() * (pow(game.COMMON_DISPARO_DAMAGE_GROWTH, 2.0) - 1.0)
	_check(is_equal_approx(float(game.common_card_stat_cache.get("damage_bonus", 0.0)), expected_two), "two copies did not compound to 44%")
	_check(String(game._card_effect_snapshot(damage_card, 2)).find("+44.0%") >= 0, "snapshot does not show compound +44.0%")

	game.cards_bought.clear()
	game._recalculate_common_card_stat_bonuses()
	game.cards_bought["Tempestade"] = 1
	game.cards_bought["Defesa"] = 1
	game._recalculate_common_card_stat_bonuses()
	_check(is_equal_approx(float(game.common_card_stat_cache.get("damage_bonus", 0.0)), game.COMMON_TEMPESTADE_FLAT_DAMAGE), "Tempestade did not grant +8 flat damage")
	_check(is_equal_approx(float(game.common_card_stat_cache.get("crit_bonus", 0.0)), game.COMMON_TEMPESTADE_CRIT_CHANCE), "Tempestade did not grant +12% critical chance")
	_check(is_equal_approx(float(game.common_card_stat_cache.get("defense_bonus", 0.0)), game.COMMON_DEFENSE_PER_COPY), "Defesa did not grant +5 resistance")
	_check(Array(game._card_stat_chips("Tempestade")).has("+12% CRIT"), "Tempestade shop chip is stale")
	_check(Array(game._card_stat_chips("Defesa")).has("+5 DEF"), "Defesa shop chip is stale")

	if failed:
		_cleanup()
		quit(1)
		return
	print("DISPARO_CRESCENTE_BALANCE_SMOKE_OK disparo=20pct/44pct tempestade=8dmg+12crit defesa=5")
	_cleanup()
	quit(0)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
