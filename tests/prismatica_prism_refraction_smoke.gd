extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PRISMATICA_PRISM_REFRACTION_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _make_prism() -> Dictionary:
	return {"pos": Vector2(500, 360), "life": 10.0, "max_life": 10.0, "damage_tick": 1.0, "radius": 76.0, "tp_prism": true}


func _make_prismatica_bullet(origin: Vector2, pos: Vector2) -> Dictionary:
	return {
		"pos": pos,
		"origin": origin,
		"source_category": "basic_attack",
		"dir": Vector2.RIGHT,
		"life": 1.0,
		"max_life": 1.0,
		"age": 0.0,
		"phase": 0.0,
		"trail_cd": 999.0,
		"damage": 10.0,
		"player_damage": 10.0,
		"speed": 1000.0,
		"kind": "prismatica",
		"pierce": true,
		"hits": {},
		"ricochets": 3,
		"durability": 100.0,
		"fly_sfx_cd": 99.0,
		"color": Color(0.32, 1.0, 0.96)
	}


func _max_refracted_angle() -> float:
	var max_angle := 0.0
	for bullet in game.bullets:
		if bool(bullet.get("refracted", false)):
			max_angle = maxf(max_angle, abs(Vector2(bullet.get("dir", Vector2.RIGHT)).angle()))
	return max_angle


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.manifestation_key = "prismatica"
	game.player_pos = Vector2(120, 360)
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.prisms = [_make_prism()]

	game.bullets = [_make_prismatica_bullet(Vector2(500, 360), Vector2(506, 360))]
	game._update_bullets(0.02)
	_check(game.bullets.size() == 1 and not bool(game.bullets[0].get("refracted", false)), "bullet born inside prism should not split")

	game.bullets = [_make_prismatica_bullet(Vector2(80, 360), Vector2(430, 360))]
	game._update_bullets(0.08)
	_check(game.bullets.size() == 5, "far prism crossing should split into five beams")
	var far_spread := _max_refracted_angle()

	game.bullets = [_make_prismatica_bullet(Vector2(410, 360), Vector2(430, 360))]
	game._update_bullets(0.08)
	_check(game.bullets.size() == 5, "near prism crossing should split into five beams")
	var near_spread := _max_refracted_angle()
	_check(near_spread > far_spread + 0.12, "near prism crossing should spread more than distant crossing")

	print("PRISMATICA_PRISM_REFRACTION_SMOKE_OK inside_blocked=true far_spread=%.3f near_spread=%.3f" % [far_spread, near_spread])
	root.remove_child(game)
	game.queue_free()
	await process_frame
	quit(0)
