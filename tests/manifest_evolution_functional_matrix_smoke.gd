extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_EVOLUTION_FUNCTIONAL_FAIL " + message)
	quit(1)


func _activate_single(key: String, entry: Dictionary) -> Dictionary:
	game.manifestation_key = key
	game._reset_manifest_evolution_state()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.player_damage = 100.0
	game.enemies.clear()
	game.bullets.clear()
	game.shockwaves.clear()
	game.slashes.clear()
	game.manifest_evolution_options = [entry]
	game._choose_manifest_evolution(0)
	var choices: Array = game._manifest_evolution_choices()
	_check(choices.size() == 1, key + " did not activate " + String(entry.get("id", "")))
	return Dictionary(choices[0])


func _run_projectile_behavior(key: String, entry: Dictionary, effect: String) -> void:
	var choice := _activate_single(key, entry)
	var profile: Dictionary = Dictionary(choice.get("profile", {}))
	var choices: Array = game._manifest_evolution_choices()
	if effect == "projectile_echo" or effect == "projectile_echo_plus":
		choices[0]["shot_counter"] = maxi(0, int(profile.get("every", 4)) - 1)
		game.manifest_evolution_state["choices"] = choices
	var bullet := {"pos": game.player_pos, "dir": Vector2.RIGHT, "damage": 80.0, "life": 1.0, "max_life": 1.0, "hits": {}, "color": Color.WHITE, "kind": key}
	var before_bullets: int = game.bullets.size()
	game._apply_manifest_evolution_to_bullet(bullet)
	match effect:
		"projectile_echo", "projectile_echo_plus":
			_check(game.bullets.size() > before_bullets, key + " echo did not spawn echoes")
		"projectile_pierce":
			_check(bool(bullet.get("pierce", false)) and int(bullet.get("evolution_pierce_left", 0)) > 0, key + " pierce inactive")
		"projectile_homing":
			_check(bool(bullet.get("evolution_homing", false)), key + " homing inactive")
		"grand_manifestation":
			_check(bool(bullet.get("pierce", false)) and bool(bullet.get("evolution_homing", false)), key + " grand projectile hybrid inactive")


func _run_impact_behavior(key: String, entry: Dictionary, effect: String) -> void:
	var choice := _activate_single(key, entry)
	var profile: Dictionary = Dictionary(choice.get("profile", {}))
	var bullet := {"pos": game.player_pos, "dir": Vector2.RIGHT, "damage": 80.0, "life": 1.0, "max_life": 1.0, "hits": {}, "color": Color.WHITE, "kind": key, "pierce": false}
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(80, 0))
	var target: Dictionary = game.enemies[0]
	match effect:
		"impact_link":
			game._manifest_evolution_on_projectile_hit(bullet, target, Vector2(target["pos"]))
			_check(float(game.enemies[0].get("evolution_slow", 0.0)) > 0.0 or game.slashes.size() > 0, key + " link inactive")
		"impact_burst", "impact_chain_burst", "impact_vortex", "grand_manifestation":
			var choices: Array = game._manifest_evolution_choices()
			choices[0]["impact_counter"] = maxi(0, int(profile.get("every", 4)) - 1)
			game.manifest_evolution_state["choices"] = choices
			var before: int = game.shockwaves.size()
			game._manifest_evolution_on_projectile_hit(bullet, target, Vector2(target["pos"]))
			_check(game.shockwaves.size() > before, key + " impact wave inactive")
		"impact_seal":
			for i in range(maxi(1, int(profile.get("hits", 3)))):
				game._manifest_evolution_on_projectile_hit(bullet, target, Vector2(target["pos"]))
			_check(float(target.get("stun", 0.0)) > 0.0, key + " seal inactive")


func _run_skill_behavior(key: String, entry: Dictionary) -> void:
	_activate_single(key, entry)
	var before: int = Array(game.manifest_evolution_state.get("fields", [])).size()
	game._manifest_evolution_on_skill(game.player_pos + Vector2(60, 0))
	_check(Array(game.manifest_evolution_state.get("fields", [])).size() > before, key + " skill field inactive")


func _run_teleport_behavior(key: String, entry: Dictionary) -> void:
	_activate_single(key, entry)
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(70, 0))
	var before: int = game.shockwaves.size()
	game._manifest_evolution_on_teleport(game.player_pos, game.player_pos + Vector2(120, 0))
	_check(game.shockwaves.size() > before, key + " teleport burst inactive")


func _run() -> void:
	game._start_game()
	game.mode = "game"
	var checked := 0
	for item in game.MANIFESTATIONS:
		var key := String(item.get("key", ""))
		for entry in game._manifest_evolution_entries(key):
			var profile: Dictionary = Dictionary(Dictionary(entry).get("profile", {}))
			var effect := String(profile.get("effect", ""))
			match effect:
				"projectile_echo", "projectile_echo_plus", "projectile_pierce", "projectile_homing", "grand_manifestation":
					_run_projectile_behavior(key, Dictionary(entry), effect)
				"impact_link", "impact_burst", "impact_chain_burst", "impact_vortex", "impact_seal":
					_run_impact_behavior(key, Dictionary(entry), effect)
				"skill_field":
					_run_skill_behavior(key, Dictionary(entry))
				"teleport_burst":
					_run_teleport_behavior(key, Dictionary(entry))
				_:
					push_error("MANIFEST_EVOLUTION_FUNCTIONAL_FAIL unhandled effect " + effect)
					quit(1)
					return
			checked += 1
	print("MANIFEST_EVOLUTION_FUNCTIONAL_OK definitions=%d manifestations=%d" % [checked, game.MANIFESTATIONS.size()])
	quit(0)
