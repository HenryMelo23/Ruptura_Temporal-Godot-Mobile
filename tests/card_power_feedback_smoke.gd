extends SceneTree

var game: Node


func _has_effect(kind: String) -> bool:
	for effect in game.common_card_effects:
		if String(effect.get("kind", "")) == kind:
			return true
	return false


func _feedback_effect_count() -> int:
	var count := 0
	for effect in game.common_card_effects:
		var kind: String = String(effect.get("kind", ""))
		if kind.begins_with("card_") or kind == "enemy_threat_impact":
			count += 1
	return count


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.mode = "shop"
	game.common_card_effects.clear()
	game._apply_card(game._find_card_by_id("Speed Boost"))
	game._apply_card(game._find_card_by_id("Speed Boost"))
	assert(game.card_power_feedback_controller.pending_acquisitions.size() == 1)
	assert(int(game.card_power_feedback_controller.pending_acquisitions[0].get("copies", 0)) == 2)
	game.card_power_feedback_controller.update(1.0)
	assert(not _has_effect("card_power_acquired"))

	game.mode = "game"
	game.card_power_feedback_controller.update(1.0)
	assert(_has_effect("card_power_acquired"))
	assert(game.card_power_feedback_controller.pending_acquisitions.is_empty())

	game.common_card_effects.clear()
	game.player_pos = Vector2(400.0, 320.0)
	game.card_power_feedback_controller.last_player_pos = game.player_pos - Vector2(24.0, 0.0)
	game.card_power_feedback_controller.speed_trail_timer = 0.0
	game.card_power_feedback_controller.update(0.2)
	assert(_has_effect("card_speed_trail"))

	game.common_card_effects.clear()
	game.cards_bought["Disparo crescente"] = 2
	game.cards_bought["Tempestade"] = 2
	var enemy := {
		"pos": Vector2(560.0, 320.0),
		"max_hp": 100.0,
		"hp": 0.0,
		"overkill_damage": 24.0,
	}
	game.card_power_feedback_controller.on_damage_confirmed(enemy, 42.0, true, "basic_attack")
	assert(_has_effect("card_power_hit"))
	assert(_has_effect("card_critical_hit"))
	assert(_has_effect("card_overkill"))

	game.common_card_effects.clear()
	game.cards_bought["Roubo de Vida"] = 1
	game.card_power_feedback_controller.lifesteal_timer = 0.0
	game.card_power_feedback_controller.on_lifesteal(Vector2(560.0, 320.0), 8)
	assert(_has_effect("card_lifesteal"))
	var lifesteal_count := _feedback_effect_count()
	game.card_power_feedback_controller.on_lifesteal(Vector2(570.0, 320.0), 8)
	assert(_feedback_effect_count() == lifesteal_count)

	game.common_card_effects.clear()
	game.cards_bought["Defesa"] = 2
	game.player_hp_max = 200
	game.card_power_feedback_controller.threat_timer = 0.0
	game.card_power_feedback_controller.on_player_hit(72.0, 28.0, "smoke_enemy")
	assert(_has_effect("card_defense_block"))
	assert(_has_effect("enemy_threat_impact"))

	game.common_card_effects.clear()
	for index in range(20):
		enemy["pos"] = Vector2(520.0 + float(index), 320.0)
		game.card_power_feedback_controller.on_damage_confirmed(enemy, 42.0, true, "basic_attack")
	assert(_feedback_effect_count() <= game.card_power_feedback_controller.MAX_ACTIVE_FEEDBACK_EFFECTS)

	game.card_power_feedback_controller.on_card_acquired(game._find_card_by_id("Tempestade"), false)
	assert(not game.card_power_feedback_controller.pending_acquisitions.is_empty())
	game.card_power_feedback_controller.reset()
	assert(game.card_power_feedback_controller.pending_acquisitions.is_empty())
	assert(game.card_power_feedback_controller.lifesteal_timer == 0.0)

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for index in range(4):
		await process_frame
	print("CARD_POWER_FEEDBACK_SMOKE_OK acquisition=true speed=true damage=true critical=true lifesteal=true defense=true threat=true bounded=true")
	quit(0)
