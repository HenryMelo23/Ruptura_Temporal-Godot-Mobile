extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CARTOGRAFICA_REWORK_FAIL " + message)
	quit(1)


func _set_cartografica() -> void:
	game._start_game()
	game.mode = "game"
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i]["key"]) == "cartografica":
			game.selected_manifestation = i
			break
	game.manifestation_key = "cartografica"
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.attack_dragging = true
	game.attack_drag_direction = Vector2.RIGHT
	game.player_damage = game._manifestation_base_damage()
	game.player_attack_interval = game._manifestation_attack_interval()
	game.last_attack_time = -100.0
	game.last_skill_time = -100.0
	game.last_secondary_time = -100.0
	game.bullets.clear()
	game.cartographic_coords.clear()
	game.cartographic_route_timer = 0.0
	game.cartographic_complete_map_timer = 0.0
	game.tp_effects.clear()
	game.tp_cooldown_pending = false


func _run() -> void:
	_set_cartografica()

	game._try_attack()
	_check(game.bullets.size() == 1, "ATK did not create projectile")
	var first_bullet: Dictionary = game.bullets[0]
	_check(Vector2(first_bullet.get("origin", Vector2.ZERO)).distance_to(game.player_pos) < 0.1, "ATK origin is not player")
	_check(Vector2(first_bullet.get("pos", Vector2.ZERO)).distance_to(game.player_pos + Vector2.RIGHT * 44.0) < 0.1, "ATK did not spawn from player muzzle")
	_check(Vector2(first_bullet.get("dir", Vector2.ZERO)).distance_to(Vector2.RIGHT) < 0.01, "ATK direction ignored player aim")

	game.bullets.clear()
	game.last_attack_time = -100.0
	game._add_cartographic_coord(game.player_pos + Vector2(160, 0), -1, "fixed", "smoke")
	game._add_cartographic_coord(game.player_pos + Vector2(260, 0), -1, "fixed", "smoke")
	game._add_cartographic_coord(game.player_pos + Vector2(360, 0), -1, "fixed", "smoke")
	game._try_attack()
	var routed: Dictionary = game.bullets[0]
	var original_dir := Vector2(routed.get("dir", Vector2.ZERO))
	var original_origin := Vector2(routed.get("origin", Vector2.ZERO))
	game._update_bullets(0.36)
	_check(Vector2(routed.get("dir", Vector2.ZERO)).distance_to(original_dir) < 0.001, "Route changed projectile direction")
	_check(Vector2(routed.get("origin", Vector2.ZERO)).distance_to(original_origin) < 0.001, "Route changed projectile origin")
	_check(int(routed.get("carto_route_hits", 0)) >= 2, "Projectile did not read aligned coordinates")
	_check(bool(routed.get("pierce", false)), "Two or more route reads should grant pierce")

	game.cartographic_coords.clear()
	game._add_cartographic_coord(Vector2(500, 360), -1, "fixed", "first")
	var first_id := int(game.cartographic_coords[0].get("id", -1))
	game._add_cartographic_coord(Vector2(560, 360), -1, "fixed", "second")
	game._add_cartographic_coord(Vector2(620, 360), -1, "fixed", "third")
	game._add_cartographic_coord(Vector2(680, 360), -1, "fixed", "fourth")
	_check(game.cartographic_coords.size() == game.CARTO_COORD_MAX, "Coordinate cap should stay at three")
	_check(not game.cartographic_coords.any(func(coord): return int(coord.get("id", -1)) == first_id), "Fourth coordinate did not replace oldest")

	game.player_pos = Vector2(640, 360)
	game._execute_teleport(Vector2(720, 410))
	_check(game.player_pos.distance_to(Vector2(720, 410)) < 0.1, "Cartographic TP snapped away from aimed destination")

	game.boss_active = true
	game.boss_dead = false
	game.boss_pos = Vector2(700, 360)
	game.boss_hp = 1000.0
	game.boss_hp_max = 1000.0
	game._add_cartographic_coord(game.boss_pos, -1, "boss", "smoke")
	game._update_advanced_manifestation_state(0.1)
	_check(game.cartographic_coords.any(func(coord): return String(coord.get("kind", "")) == "boss"), "Boss coordinate was not kept")

	print("CARTOGRAFICA_REWORK_OK")
	quit(0)
