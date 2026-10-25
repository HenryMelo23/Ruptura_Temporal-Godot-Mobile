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
				# A seal needs separate successful impacts. Replaying one collision is
				# intentionally ignored by the combat-event ledger.
				var next_bullet := bullet.duplicate(true)
				next_bullet["manifest_evolution_event_id"] = "functional_seal:%s:%d" % [key, i]
				game._manifest_evolution_on_projectile_hit(next_bullet, target, Vector2(target["pos"]))
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


func _run_acorrentada_behavior(entry: Dictionary) -> void:
	_activate_single("acorrentada", entry)
	var targets: Array = []
	for offset in [Vector2(80, 0), Vector2(130, 24), Vector2(176, -22), Vector2(205, 36)]:
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
		game.enemies.back()["hp"] = 100000.0
		game.enemies.back()["max_hp"] = 100000.0
		targets.append(game.enemies.back())
	var evolution_id := String(entry.get("id", ""))
	var effect := String(Dictionary(entry.get("profile", {})).get("effect", ""))
	match effect:
		"acorrentada_corrente_tripla":
			game._resolve_acorrentada_attack_motion({"stage": 3, "dir": Vector2.RIGHT, "target": {"kind": "enemy", "uid": int(Dictionary(targets[0])["uid"])}, "damage_impact": Vector2(Dictionary(targets[0])["pos"]), "manifest_evolution_event_id": "matrix:triple"})
		"acorrentada_tensao_residual":
			game._add_acorrentada_tension(100.0)
			game._consume_acorrentada_overcharge()
		"acorrentada_grilhao_movel", "acorrentada_elo_espelhado":
			game._manifest_evolution_on_combat_hit("matrix:%s" % effect, "acorrentada", Dictionary(targets[0]), Vector2(Dictionary(targets[0])["pos"]))
		"acorrentada_ancora_corrente", "acorrentada_teia_grilhoes", "acorrentada_prisao_total":
			game._manifest_evolution_on_skill(game.player_pos + Vector2(120, 0))
			game._update_manifest_evolution_effects(0.60)
		"acorrentada_sobretensao_continua":
			game._cast_acorrentada_q(game.player_pos + Vector2(120, 0))
			game._update_manifest_evolution_effects(1.05)
		"acorrentada_ruptura_sequencial":
			for index in range(3):
				game._manifest_evolution_on_combat_hit("matrix:sequence:%d" % index, "acorrentada", Dictionary(targets[index]), Vector2(Dictionary(targets[index])["pos"]))
		"acorrentada_corrente_arrasto":
			game._manifest_evolution_on_teleport(game.player_pos, game.player_pos + Vector2(220, 0))
		"acorrentada_sobrecarga_tensao":
			game.acorrentada_tension = 100.0
			game._consume_acorrentada_overcharge()
			game._manifest_evolution_on_combat_hit("matrix:overload", "acorrentada", Dictionary(targets[0]), Vector2(Dictionary(targets[0])["pos"]))
		"acorrentada_sentenca_ferro":
			game._cast_acorrentada_e(game.player_pos + Vector2(120, 0))
			game._manifest_evolution_on_combat_hit("matrix:sentence", "acorrentada", Dictionary(targets[0]), Vector2(Dictionary(targets[0])["pos"]))
		_:
			_check(false, "unhandled Acorrentada effect " + effect)
	var metrics: Dictionary = Dictionary(Dictionary(game.manifest_evolution_state.get("acorrentada", {})).get("metrics", {}))
	_check(int(metrics.get(evolution_id, 0)) > 0, "Acorrentada contract did not produce a real metric for " + evolution_id)


func _run() -> void:
	game._start_game()
	game.mode = "game"
	var checked := 0
	for item in game.MANIFESTATIONS:
		var key := String(item.get("key", ""))
		for entry in game._manifest_evolution_entries(key):
			if key == "prismatica":
				_activate_single(key, Dictionary(entry))
				var prism_bullet := {"pos": game.player_pos, "dir": Vector2.RIGHT, "damage": 80.0, "life": 1.0, "max_life": 1.0, "hits": {}, "color": Color.WHITE, "kind": key}
				game._apply_manifest_evolution_to_bullet(prism_bullet)
				_check(bool(prism_bullet.get("prismatica_evolution", false)), "prismatica did not delegate " + String(Dictionary(entry).get("id", "")))
				checked += 1
				continue
			if key == "acorrentada":
				_run_acorrentada_behavior(Dictionary(entry))
				checked += 1
				continue
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
	game.set_process(false)
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	quit(0)
