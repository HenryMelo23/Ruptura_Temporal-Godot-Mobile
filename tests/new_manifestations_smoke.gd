extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("NEW_MANIFESTATIONS_FAIL " + message)
	quit(1)


func _set_manifestation(key: String) -> void:
	var found := false
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i]["key"]) == key:
			game.selected_manifestation = i
			found = true
			break
	_check(found, key + " not registered")
	_check(game._manifestation_unlocked(game.selected_manifestation), key + " should be selectable")
	game.manifestation_key = key
	game.player_damage = game._manifestation_base_damage()
	game.player_attack_interval = game._manifestation_attack_interval()
	game.last_attack_time = -100.0
	game.last_skill_time = -100.0
	game.last_secondary_time = -100.0
	game.tp_effects.clear()
	game.tp_cooldown_pending = false
	game.tp_cooldown_override = -1.0
	game.bullets.clear()
	game.effects.clear()
	game.slashes.clear()
	game.shockwaves.clear()
	game.manifestation_secondaries.clear()
	game.enemies.clear()
	game.boss_active = false
	game.boss_dead = false
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT


func _enemy(pos: Vector2, hp := 5000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies.back()
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	return enemy


func _advance_tp(seconds: float, step := 0.1) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		var dt: float = min(step, seconds - elapsed)
		game.time_alive += dt
		game._update_teleport_effects(dt)
		game._update_advanced_manifestation_state(dt)
		elapsed += dt


func _run() -> void:
	game._start_game()
	game.mode = "game"
	var keys = ["cartografica", "mnesica", "ressonante", "contratual"]
	for key in keys:
		_set_manifestation(key)
		var details: Dictionary = game._manifestation_details(key)
		_check(String(details.get("funcao", "")).length() > 20, key + " missing detailed text")
		game._try_attack()
		_check(game.bullets.size() == 1, key + " did not fire a projectile")
		_check(String(game.bullets[0].get("kind", "")) == key, key + " projectile kind mismatch")

	_set_manifestation("cartografica")
	game._add_cartographic_coord(Vector2(520, 360))
	game._add_cartographic_coord(Vector2(760, 360))
	game._use_skill()
	_check(game.cartographic_route_timer > 0.0, "cartographic Q did not activate routes")
	game._execute_teleport(Vector2(530, 360))
	_check(game.player_pos.distance_to(Vector2(520, 360)) < 2.0, "cartographic TP did not snap to coordinate")

	_set_manifestation("mnesica")
	var memory_enemy := _enemy(Vector2(710, 360))
	game._register_mnesic_memory(memory_enemy, 90.0)
	game._register_mnesic_memory(memory_enemy, 80.0)
	game._register_mnesic_memory(memory_enemy, 70.0)
	var before_mnesic_hp: float = float(memory_enemy["hp"])
	game._use_skill()
	_check(float(memory_enemy["hp"]) < before_mnesic_hp or float(memory_enemy.get("mnesic_vulnerable", 0.0)) > 0.0, "mnesic Q did not punish memories")
	_set_manifestation("mnesica")
	var trick_enemy := _enemy(Vector2(580, 360))
	game._execute_teleport(Vector2(720, 360))
	_check(float(trick_enemy.get("mnesic_tricked", 0.0)) > 0.0, "mnesic TP did not trick nearby enemy")

	_set_manifestation("ressonante")
	var resonant_enemy := _enemy(Vector2(710, 360))
	resonant_enemy["resonant_notes"] = ["grave", "aguda", "quebrada"]
	var before_resonant_hp: float = float(resonant_enemy["hp"])
	game._use_skill()
	_check(float(resonant_enemy["hp"]) < before_resonant_hp, "resonant Q did not detonate notes")
	_set_manifestation("ressonante")
	game.time_alive = 0.0
	game._execute_teleport(Vector2(720, 360))
	_check(game.resonant_next_perfect or game.resonant_speed_timer > 0.0, "resonant perfect TP did not prime next note")

	_set_manifestation("contratual")
	var contract_enemy := _enemy(Vector2(710, 360))
	game._apply_contract_clause(contract_enemy)
	contract_enemy["contract_infractions"] = 3
	var before_contract_hp: float = float(contract_enemy["hp"])
	game._use_skill()
	_check(float(contract_enemy["hp"]) < before_contract_hp and not contract_enemy.has("contract_clause"), "contractual Q did not execute contract")
	_set_manifestation("contratual")
	game._execute_teleport(Vector2(720, 360))
	_check(game.contractual_notifications.size() == 1, "contractual TP did not leave notification trap")

	quit(0)
