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
	_check(String(damage_card.get("desc", "")).find("+15%") >= 0, "card description does not show +15%")
	_check(Array(game._card_stat_chips("Disparo crescente")).has("+15% DANO"), "shop stat chip does not show +15%")

	game.cards_bought["Disparo crescente"] = 1
	game._recalculate_common_card_stat_bonuses()
	var expected_one: float = game._manifestation_base_damage() * 0.15
	_check(is_equal_approx(float(game.common_card_stat_cache.get("damage_bonus", 0.0)), expected_one), "one copy did not grant 15% base manifestation damage")
	var projection_one: Array = game._card_projection_lines(damage_card)
	_check(String(projection_one[0]).find("+15.0%") >= 0, "current projection does not show +15.0%")
	_check(String(projection_one[1]).find("+32.2%") >= 0, "next projection does not show compound +32.2%")

	game.cards_bought["Disparo crescente"] = 2
	game._recalculate_common_card_stat_bonuses()
	var expected_two: float = game._manifestation_base_damage() * (pow(1.15, 2.0) - 1.0)
	_check(is_equal_approx(float(game.common_card_stat_cache.get("damage_bonus", 0.0)), expected_two), "two copies did not compound to 32.25%")
	_check(String(game._card_effect_snapshot(damage_card, 2)).find("+32.2%") >= 0, "snapshot does not show compound +32.2%")

	if failed:
		_cleanup()
		quit(1)
		return
	print("DISPARO_CRESCENTE_BALANCE_SMOKE_OK one_copy=15pct two_copies=32.25pct")
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
