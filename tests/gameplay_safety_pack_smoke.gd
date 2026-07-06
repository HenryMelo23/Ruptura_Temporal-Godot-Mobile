extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("GAMEPLAY_SAFETY_PACK_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.current_phase = 2
	game.phase2_fire_walls = [{"pos": Vector2(400, 300), "life": 15.0, "max": 15.0}]
	var blocked: Vector2 = game._resolve_phase2_fire_wall_movement(Vector2(350, 300), Vector2(375, 300))
	_check(blocked.x == 350.0, "fire wall did not block player movement")
	var sliding: Vector2 = game._resolve_phase2_fire_wall_movement(Vector2(350, 300), Vector2(375, 330))
	_check(sliding.x == 350.0 and sliding.y == 330.0, "fire wall did not preserve movement along its edge")
	game.player_pos = Vector2(365, 300)
	var hp_before: int = game.player_hp
	game._update_phase2_fire_walls(0.01)
	_check(game.player_hp < hp_before, "solid fire wall did not apply contact damage")

	game.enemies.clear()
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 1000.0
	game.boss_hp_max = 1000.0
	game.player_pos = Vector2(500, 400)
	game.boss_pos = Vector2(620, 400)
	game.boss2_ultimate_timer = 20.0
	game.boss2_ultimate_wind_active = 0.0
	game.boss2_ultimate_spit_timer = 4.0
	_check(game._nearest_target() == Vector2.ZERO, "automatic aim revealed boss2 inside the blizzard")
	game.boss2_ultimate_wind_active = 1.0
	_check(game._nearest_target() == game.boss_pos, "automatic aim ignored boss2 while visibly attacking")

	game.current_phase = 3
	game.boss2_ultimate_timer = 0.0
	game.boss3_miasma_variant = 1
	game.boss3_miasma_timer = 10.0
	_check(game._nearest_target() == Vector2.ZERO, "automatic aim revealed boss3 during miasma")
	game.boss3_miasma_timer = 0.0
	game.boss3_miasma_variant = 0
	_check(game._nearest_target() == game.boss_pos, "automatic aim did not return after miasma")

	game.player_hp_max = 400
	game.player_hp = 100
	_check(is_zero_approx(game._low_health_red_alpha()), "red danger overlay started at or above 25 percent")
	game.player_hp = 50
	var half_danger: float = game._low_health_red_alpha()
	game.player_hp = 10
	_check(game._low_health_red_alpha() > half_danger, "red danger overlay did not intensify as health dropped")

	_check(is_equal_approx(game.BOSS3_MIASMA_QTE_OVERTIME_RATE, 0.008), "miasma overtime base damage was not reduced")
	_check(game.BOSS3_MIASMA_QTE_OVERTIME_GROWTH < 2.0, "miasma overtime still doubles every tick")

	var viewport := Vector2(1280, 720)
	game.manifestation_key = "eletrica"
	game._open_edit_layout(viewport)
	game._update_button_layout(viewport)
	_check(game.buttons.has("lacerante_empower"), "plus button is missing from layout editor")
	var plus_center: Vector2 = game.buttons["lacerante_empower"].get_center()
	game._handle_edit_layout_press(7, plus_center, viewport)
	_check(game.edit_layout_selected == "lacerante_empower", "plus button cannot be selected")
	var moved_to := plus_center + Vector2(-120, 55)
	game._handle_edit_layout_drag(7, moved_to, viewport)
	_check(game.hud_lacerante_empower_pos.distance_to(moved_to) < 1.0, "plus button cannot be moved")

	print("GAMEPLAY_SAFETY_PACK_OK wall=solid low_hp=progressive hidden_boss=no_auto_target miasma=softer plus=moves")
	quit(0)
