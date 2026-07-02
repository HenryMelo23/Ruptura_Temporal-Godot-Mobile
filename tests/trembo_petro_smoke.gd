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


func _card(name: String) -> Dictionary:
	for card in game.CARDS:
		if card["name"] == name:
			return card
	return {}


func _run() -> void:
	game._start_game()
	game._apply_card(_card("Trembo"))
	_check(game.trembo_charges == 1, "Trembo card did not add a charge")
	game.player_hp = 100
	game.trembo_heal_timer = 0.0
	game._update_trembo(0.1)
	_check(game.player_hp > 100, "Trembo did not heal the player")
	game.player_hp = 0
	var old_pos = game.player_pos
	game._handle_player_down()
	_check(game.player_hp == game.player_hp_max, "Trembo did not restore full health")
	_check(game.trembo_charges == 0, "Trembo charge was not consumed")
	_check(game.trembo_invulnerability >= 9.9, "Trembo did not grant revive immunity")
	_check(game.player_pos != old_pos, "Trembo did not teleport the player")

	for i in range(5):
		game._apply_card(_card("Petro"))
	_check(game.petro_active, "Petro card did not activate the pet")
	_check(game.petro_evolution == 3, "Petro did not reach visual evolution 3")
	_check(game.petro_hp_max > game.PETRO_BASE_HP, "Petro upgrades did not increase max HP")
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.petro_pos + Vector2(20, 0))
	var enemy = game.enemies[0]
	enemy["hp"] = 5000.0
	enemy["max_hp"] = 5000.0
	enemy["speed"] = 0.0
	var hp_before = float(enemy["hp"])
	game.petro_fire_timer = 0.0
	game._update_petrov(0.1)
	_check(float(enemy["hp"]) < hp_before, "Petro did not damage a nearby enemy")
	game.petro_hp = 1.0
	game.petro_defense = 0.0
	enemy["damage"] = 500.0
	game.petro_fire_timer = 0.0
	game._update_petrov(0.1)
	_check(not game.petro_active, "Petro should deactivate when its HP reaches zero")

	print("TREMBO_PETRO_SMOKE_OK heal=true revive=true immunity=true petro_evolution=3 combat=true")
	quit(0)
