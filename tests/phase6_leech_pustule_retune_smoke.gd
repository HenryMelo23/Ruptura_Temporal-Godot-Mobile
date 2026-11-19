extends SceneTree

var game: Node
var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE6_LEECH_PUSTULE_RETUNE_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.current_phase = 6
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(640.0, 360.0)
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.phase6_pustule_pools.clear()

	game._spawn_enemy(game.ENEMY_CHRONAL_LEECH, game.player_pos)
	var leech: Dictionary = game.enemies.back()
	_check(Vector2(leech["pos"]).distance_to(game.player_pos) >= game.SANGUESSUGA_SPAWN_MIN_DISTANCE - 1.0, "leech spawn stayed perceptibly close")
	_check(game._enemy_draw_size(leech).is_equal_approx(Vector2(39.2, 24.8)), "leech visual size is not 40 percent of the former 98x62 body")
	_check(is_equal_approx(game._entity_physical_radius(leech), 13.0), "leech physical radius did not shrink with the body")
	leech["leech_state"] = game.SANGUESSUGA_STATE_DORMANT
	leech["leech_timer"] = 10.0
	leech["leech_arm_timer"] = 1.0
	game._update_sanguessuga_cronal(leech, 0.01)
	_check(float(leech.get("alpha", 1.0)) <= 0.24, "dormant leech alpha is still conspicuous")

	game.enemies.clear()
	game.player_pos = Vector2(760.0, 360.0)
	game._spawn_enemy(game.ENEMY_FOSSIL_PUSTULE, Vector2(360.0, 360.0))
	var pustule: Dictionary = game.enemies.back()
	var pustule_pos: Vector2 = Vector2(pustule["pos"])
	game._fire_fossil_pustule_spit(pustule, game.player_pos)
	game.enemy_bullets.back()["pos"] = game.player_pos
	game._update_enemy_bullets(0.0)
	_check(game.player_pos.distance_to(pustule_pos) < 1.0, "pustule spit did not pull the player to the source")
	_check(bool(pustule.get("pustule_exploded", false)), "pustule did not explode after its spit connected")
	_check(game.phase6_pustule_pools.size() == 1, "pustule spit impact did not create one explosion pool")
	if not game.phase6_pustule_pools.is_empty():
		_check(is_equal_approx(float(game.phase6_pustule_pools[0].get("radius", 0.0)), 192.0), "pustule explosion radius is not 112 plus 80 pixels")
	game.run_pacing_profile = game.PACING_PROFILE_ONBOARDING
	_check(is_equal_approx(game.enemy_manager.special_kind_unlock_time(6, game.ENEMY_FOSSIL_PUSTULE), 330.0), "pustule onboarding unlock is not delayed by 30 seconds")
	game.run_pacing_profile = game.PACING_PROFILE_EXPERIENCED
	_check(is_equal_approx(game.enemy_manager.special_kind_unlock_time(6, game.ENEMY_FOSSIL_PUSTULE), 255.0), "experienced pustule unlock is not delayed by 30 seconds")

	if not failed:
		print("PHASE6_LEECH_PUSTULE_RETUNE_OK leech_scale=0.40 alpha<=0.24 spawn_min=520 pustule_pull=true radius=192 unlock=330/255")
	game.mode = "menu"
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for _frame in range(4):
		await process_frame
	quit(1 if failed else 0)
