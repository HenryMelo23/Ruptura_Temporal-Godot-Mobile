extends SceneTree

var game: Node

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	_check(game.AURAS.size() == 10, "mobile aura selector does not expose all ten desktop auras")
	for index in range(game.AURAS.size()):
		game.selected_aura = index
		game._start_game()
		var expected := String(game.AURAS[index]["name"])
		_check(String(game.aura_state.get("name", "")) == expected, "aura state did not follow selector: " + expected)
		_check(game._aura_color() != Color.WHITE, "aura has no dedicated visual color: " + expected)
		game._update_aura(0.016)
		game.queue_redraw()
		await process_frame

	game.selected_aura = 2
	game._start_game()
	var hp_before: float = float(game.player_hp)
	game._damage_player(50, "integration")
	_check(game.player_hp >= hp_before and int(game.aura_state["devoted_charges"]) == 2, "Devota was not integrated into player damage")

	game.selected_aura = 0
	game._start_game()
	game._execute_teleport(game.player_pos + Vector2(100, 0))
	_check(is_equal_approx(game.AuraSystem.world_multiplier(game.aura_state), 0.42), "Racional was not integrated into teleport")
	_check(game._aura_status_text().begins_with("DILATACAO"), "Racional HUD did not expose active dilation")
	game.aura_state["rational_dilation"] = 0.0
	game.aura_state["rational_cooldown"] = 12.0
	_check(game._aura_status_text().begins_with("RECARGA"), "Racional HUD did not expose cooldown after teleport")

	game.selected_aura = 5
	game._start_game()
	game.player_damage = 100.0
	game.aura_state["voracious_hunger"] = 4.0
	game.aura_state["voracious_last_collect"] = 0.0
	game.enemies = [{"uid": 1001, "type": game.ENEMY_COMMON, "pos": game.player_pos + Vector2(130, 0), "hp": 1000.0, "max_hp": 1000.0, "speed": 0.0}]
	var far_pos: Vector2 = game.enemies[0]["pos"]
	game._update_voracious_contact(0.2)
	_check(Vector2(game.enemies[0]["pos"]).distance_to(far_pos) <= 0.01, "Voraz pulled an enemy from outside the bite radius")
	game.enemies[0]["pos"] = game.player_pos + Vector2(80, 0)
	game.enemies[0]["aura_bite_cd"] = 0.0
	game._update_voracious_contact(0.2)
	_check(is_equal_approx(float(game.enemies[0]["hp"]), 885.0), "Voraz bite did not use the balanced hunger-stack scaling")
	game.aura_state["voracious_hunger"] = 999.0
	game.aura_state["voracious_cycles"] = 3
	_check(is_equal_approx(game._voraz_bite_damage(), 145.0), "Voraz raw hunger still causes one-hit damage spikes")
	game.aura_state["voracious_cycles"] = 100
	_check(game._voraz_bite_damage() <= 355.0, "Voraz long-run hunger scaling can still reach one-hit damage")

	print("AURAS_MOBILE_INTEGRATION_SMOKE_OK selector=10 hud=true world=true damage=true")
	quit(0)
