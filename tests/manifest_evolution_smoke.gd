extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_EVOLUTION_FAIL " + message)
	quit(1)


func _set_manifestation(key: String) -> void:
	game.manifestation_key = key
	game._reset_manifest_evolution_state()


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.enemies.clear()
	game.bullets.clear()
	game.shockwaves.clear()

	for item in game.MANIFESTATIONS:
		var key := String(item.get("key", ""))
		var entries: Array = game._manifest_evolution_entries(key)
		_check(entries.size() == 9, key + " should have 9 evolution entries")
		var options: Array = game._roll_manifest_evolution_options(key, 3)
		_check(options.size() == 3, key + " should roll 3 options")
		var seen := {}
		for option in options:
			var id := String(option.get("id", ""))
			_check(not seen.has(id), key + " rolled duplicate option")
			seen[id] = true

	_set_manifestation("eletrica")
	game.manifest_evolution_options = game._manifest_evolution_entries("eletrica")
	var pierce_index := 1
	game._choose_manifest_evolution(pierce_index)
	_check(String(game.manifest_evolution_state.get("family", "")) == "perfuracao", "pierce evolution not selected")
	game._fire_projectile("eletrica", 80.0, 600.0, 1.0, false)
	_check(game.bullets.size() >= 1, "projectile missing after fire")
	_check(bool(game.bullets[0].get("pierce", false)), "pierce evolution did not alter bullet")
	_check(int(game.bullets[0].get("evolution_pierce_left", 0)) > 0, "pierce charges missing")

	_set_manifestation("gravitante")
	game.manifest_evolution_options = game._manifest_evolution_entries("gravitante")
	game._choose_manifest_evolution(7)
	game._manifest_evolution_on_skill(Vector2(700, 360))
	_check(Array(game.manifest_evolution_state.get("fields", [])).size() == 1, "field evolution did not create field")

	_set_manifestation("lacerante")
	game.manifest_evolution_options = game._manifest_evolution_entries("lacerante")
	game._choose_manifest_evolution(8)
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(650, 360))
	var before_hp: float = float(game.enemies[0]["hp"])
	game._manifest_evolution_on_teleport(Vector2(640, 360), Vector2(720, 360))
	_check(game.shockwaves.size() >= 2, "teleport evolution did not create waves")
	_check(float(game.enemies[0]["hp"]) < before_hp, "teleport evolution did not damage nearby enemy")

	print("MANIFEST_EVOLUTION_SMOKE_OK manifestations=%d evolutions_per_manifestation=9 options=3 hooks=projectile/skill/teleport" % game.MANIFESTATIONS.size())
	quit(0)
