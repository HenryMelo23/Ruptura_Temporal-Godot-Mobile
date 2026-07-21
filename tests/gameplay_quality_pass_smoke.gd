extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("GAMEPLAY_QUALITY_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	var viewport := Vector2(1280, 720)
	game._start_game()
	game._update_button_layout(viewport)
	game.hud_attack_scale = 2.0
	for press in range(12):
		game._update_button_layout(viewport)
		var center: Vector2 = game.buttons["attack"].get_center()
		var radius: float = 54.0 * game._attack_scale()
		game._handle_edit_layout_press(1, center + Vector2(35.0, radius + 30.0), viewport)
	_check(is_equal_approx(game.hud_attack_scale, game.HUD_ATTACK_SCALE_MAX), "ATK plus did not reach the new maximum")
	game.hud_lacerante_empower_scale = 1.0
	game.mode = "edit_layout"
	for press in range(8):
		game._update_button_layout(viewport)
		var empower_center: Vector2 = game.buttons["lacerante_empower"].get_center()
		var empower_radius: float = game.buttons["lacerante_empower"].size.x * 0.5
		game._handle_edit_layout_press(2, empower_center + Vector2(35.0, empower_radius + 30.0), viewport)
	_check(game.hud_lacerante_empower_scale > 1.7, "Lacerante plus button still cannot be enlarged")
	game._adjust_layout_box_scale("aura_panel", 9.0)
	_check(is_equal_approx(game.hud_aura_panel_scale, game.HUD_PANEL_SCALE_MAX), "panel plus remained capped at the old size")

	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_SHIELD_REFLECTOR, Vector2(420, 360))
	var shield: Dictionary = game.enemies[0]
	_check(game._shield_reflector_active(shield), "shield did not spawn active")
	game._update_shield_reflector(shield, game.SHIELD_REFLECTOR_ACTIVE_TIME + 0.01)
	_check(not game._shield_reflector_active(shield), "shield did not lower after fifteen seconds")
	var start: Vector2 = Vector2(shield["pos"])
	game.player_pos = start + Vector2(500, 0)
	game._move_enemy(shield, 0.25)
	var unburdened_distance: float = start.distance_to(Vector2(shield["pos"]))
	_check(unburdened_distance >= float(shield["speed"]) * 0.25 * 2.35, "shieldless enemy did not gain the stronger speed")
	var shieldless_damage: int = game._enemy_damage(shield)
	shield["shield_active"] = true
	var shielded_damage: int = game._enemy_damage(shield)
	_check(shieldless_damage > shielded_damage, "shieldless enemy did not gain damage")
	shield["shield_active"] = false
	game._update_shield_reflector(shield, game.SHIELD_REFLECTOR_DOWN_TIME + 0.01)
	_check(game._shield_reflector_active(shield), "shield did not return after twenty seconds")

	game.aura_state = game.AuraSystem.create("Voraz", 3)
	game.player_pos = Vector2(500, 400)
	game.boss_pos = Vector2(900, 400)
	game.AuraSystem.on_boss_hit(game.aura_state, game.boss_pos, 400.0)
	_check(game.aura_state["voracious_drops"].size() == 1, "boss hit did not release hunger")
	var initial_distance: float = game.player_pos.distance_to(Vector2(game.aura_state["voracious_drops"][0]["pos"]))
	game.AuraSystem.update(game.aura_state, 0.5, {"player_pos": game.player_pos, "enemies": []})
	var moved_distance: float = game.player_pos.distance_to(Vector2(game.aura_state["voracious_drops"][0]["pos"]))
	_check(moved_distance < initial_distance, "boss hunger particle did not seek the player")

	_check(game.audio_streams["atk_lacerante_1"] is AudioStreamMP3, "Lacerante cut did not use root recording")
	_check(game.audio_streams["player_shot"] is AudioStreamMP3, "player firing did not use root recording")
	print("GAMEPLAY_QUALITY_SMOKE_OK atk_scale=%.1f plus_scale=%.1f shield=15/20 hunger_seek=true audio=true" % [game.hud_attack_scale, game.hud_lacerante_empower_scale])
	quit(0)
