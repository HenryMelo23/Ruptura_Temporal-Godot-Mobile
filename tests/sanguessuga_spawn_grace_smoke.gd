extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("SANGUESSUGA_SPAWN_GRACE_FAIL " + message)
	quit(1)


func _run() -> void:
	await process_frame
	game._start_game()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	game.player_pos = Vector2(640, 360)
	game.player_hp = game.player_hp_max
	game._spawn_enemy(game.ENEMY_CHRONAL_LEECH, game.player_pos)
	_check(game.enemies.size() == 1, "Chronal Leech was not spawned")
	var leech: Dictionary = game.enemies.back()
	_check(is_equal_approx(game.SANGUESSUGA_CONTACT_GRACE_TIME, 0.5), "grace constant is not 500ms")
	_check(is_equal_approx(float(leech.get("contact_grace", 0.0)), 0.5), "spawn did not assign contact grace")
	var hp_before: float = float(game.player_hp)
	game._sanguessuga_try_hit(leech)
	_check(float(game.player_hp) == hp_before, "direct hit applied during spawn grace")
	game._update_enemies(0.45)
	_check(float(game.player_hp) == hp_before, "contact damage applied during spawn grace")
	game._update_enemies(0.08)
	_check(float(game.player_hp) == hp_before, "generic contact damage was not blocked after grace")
	print("SANGUESSUGA_SPAWN_GRACE_SMOKE_OK grace=0.5 generic_contact=false")
	quit(0)
