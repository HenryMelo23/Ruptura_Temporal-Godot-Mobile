extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ELETRICA_STATIC_COMBO_FAIL " + message)
	_cleanup()
	quit(1)


func _run() -> void:
	await process_frame
	game._start_game()
	game.startup_thanks_done = true
	game.mode = "game"
	game.manifestation_key = "eletrica"
	game.selected_manifestation = 0
	game.player_pos = Vector2(420, 360)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 80.0
	game.enemies.clear()
	game.tp_effects.clear()
	game.manifestation_secondaries.clear()

	game._spawn_enemy(game.ENEMY_COMMON, Vector2(510, 360))
	var enemy: Dictionary = game.enemies[0]
	enemy["hp"] = 1600.0
	enemy["max_hp"] = 1600.0
	enemy["eletrica_static_stacks"] = 0
	enemy["eletrica_static_last_source"] = ""
	enemy["eletrica_static_timer"] = 0.0

	game._execute_teleport(Vector2(640, 360))
	game._update_teleport_effects(0.02)
	_check(int(enemy.get("eletrica_static_stacks", 0)) == 1, "teleport damage should add first electric static stack")
	_check(String(enemy.get("eletrica_static_last_source", "")) == "skill_shift", "teleport damage should be classified as skill_shift")

	game._spawn_secondary_eletrica()
	var secondary: Dictionary = game.manifestation_secondaries[-1]
	game._update_secondary_eletrica(secondary, 0.02)
	_check(int(enemy.get("eletrica_static_stacks", 0)) == 2, "electric HAB1/E ring should add second stack after teleport")
	_check(String(enemy.get("eletrica_static_last_source", "")) == "skill_e", "electric HAB1/E ring should be classified as skill_e")

	print("ELETRICA_STATIC_COMBO_SMOKE_OK teleport_stack=1 hab1_stack=2 source=%s" % String(enemy.get("eletrica_static_last_source", "")))
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
