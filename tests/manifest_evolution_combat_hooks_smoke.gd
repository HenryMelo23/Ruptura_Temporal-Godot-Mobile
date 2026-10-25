extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_EVOLUTION_COMBAT_HOOKS_FAIL " + message)
	quit(1)


func _entry_for(key: String, effect: String) -> Dictionary:
	for entry_value in game._manifest_evolution_entries(key):
		var entry: Dictionary = Dictionary(entry_value)
		if String(Dictionary(entry.get("profile", {})).get("effect", "")) == effect:
			return entry
	return {}


func _activate(key: String, entry: Dictionary) -> void:
	game.manifestation_key = key
	game._reset_manifest_evolution_state()
	game.manifest_evolution_options = [entry]
	game._choose_manifest_evolution(0)


func _has_event(event_type: String, target_uid: String = "") -> bool:
	for event_value in game.manifest_evolution_combat_event_log:
		var event: Dictionary = Dictionary(event_value)
		if String(event.get("type", "")) == event_type and (target_uid == "" or String(event.get("target_uid", "")) == target_uid):
			return true
	return false


func _spawn_target(pos: Vector2) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = 100000.0
	enemy["max_hp"] = 100000.0
	return enemy


func _run_manifest_regression() -> void:
	var checked := 0
	for item_value in game.MANIFESTATIONS:
		var key := String(Dictionary(item_value).get("key", ""))
		game.enemies.clear()
		var target := _spawn_target(game.player_pos + Vector2(80, 0))
		if key == "prismatica":
			_activate(key, Dictionary(game._manifest_evolution_entries(key)[0]))
			var prism_bullet := {"pos": game.player_pos, "dir": Vector2.RIGHT, "damage": 20.0, "life": 1.0, "hits": {}, "kind": key}
			game._apply_manifest_evolution_to_bullet(prism_bullet)
			_check(_has_event("attack_emitted"), "prismatica projectile emission was not typed")
		elif key == "acorrentada":
			var moving_shackle := _entry_for(key, "acorrentada_grilhao_movel")
			_check(not moving_shackle.is_empty(), "acorrentada lacks its explicit impact contract")
			_activate(key, moving_shackle)
			var event_id := "regression:%s:hit:%s" % [key, str(target.get("uid", ""))]
			game._manifest_evolution_on_combat_hit(event_id, "regression_" + key, target, Vector2(target["pos"]))
			var state := Dictionary(game.manifest_evolution_state.get("acorrentada", {}))
			_check(Array(state.get("shackles", [])).size() == 1, "acorrentada direct hit did not invoke its non-projectile impact hook")
		elif key == "ancorada":
			var absolute_weight := _entry_for(key, "ancorada_peso_absoluto")
			_check(not absolute_weight.is_empty(), "ancorada lacks its explicit structural impact contract")
			_activate(key, absolute_weight)
			game.lastro_stacks = 3
			var event_id := "regression:%s:hit:%s" % [key, str(target.get("uid", ""))]
			game._manifest_evolution_on_combat_hit(event_id, "regression_" + key, target, Vector2(target["pos"]))
			var state := Dictionary(game.manifest_evolution_state.get("ancorada", {}))
			_check(Array(state.get("absolute_pins", [])).size() == 1, "ancorada direct hit did not invoke Peso Absoluto")
		else:
			var link := _entry_for(key, "impact_link")
			_check(not link.is_empty(), key + " lacks impact profile")
			_activate(key, link)
			var event_id := "regression:%s:hit:%s" % [key, str(target.get("uid", ""))]
			game._manifest_evolution_on_combat_hit(event_id, "regression_" + key, target, Vector2(target["pos"]))
			_check(float(target.get("evolution_slow", 0.0)) > 0.0, key + " direct hit did not invoke its impact hook")
		checked += 1
	_check(checked == game.MANIFESTATIONS.size(), "not all manifestations passed through a typed combat hook")


func _run_lacerante_and_acorrentada() -> void:
	game.enemies.clear()
	var lacerante_link := _entry_for("lacerante", "impact_link")
	_activate("lacerante", lacerante_link)
	var lacerante_target := _spawn_target(game.player_pos + Vector2(76, 0))
	game._fire_lacerante(0, Vector2.RIGHT)
	_check(float(lacerante_target.get("evolution_slow", 0.0)) > 0.0, "lacerante melee hit did not resolve evolution impact")
	_check(_has_event("attack_emitted") and _has_event("hit_resolved", str(lacerante_target.get("uid", ""))), "lacerante typed events missing")

	game.enemies.clear()
	game.boss_active = true
	game.boss_hp = 100000.0
	game.boss_pos = game.player_pos + Vector2(76, 0)
	game._fire_lacerante(0, Vector2.RIGHT)
	_check(_has_event("hit_resolved", "boss"), "lacerante boss hit did not resolve evolution event")
	game.boss_active = false

	game.enemies.clear()
	var chained_link := _entry_for("acorrentada", "acorrentada_grilhao_movel")
	_check(not chained_link.is_empty(), "acorrentada lacks its non-projectile Grilhao Movel contract")
	_activate("acorrentada", chained_link)
	var chain_target := _spawn_target(game.player_pos + Vector2(100, 0))
	game._resolve_acorrentada_attack_motion({"stage": 1, "dir": Vector2.RIGHT, "target": {"kind": "enemy", "uid": int(chain_target["uid"])}, "damage_impact": Vector2(chain_target["pos"]), "manifest_evolution_event_id": "acorrentada:test"})
	var chain_state := Dictionary(game.manifest_evolution_state.get("acorrentada", {}))
	_check(Array(chain_state.get("shackles", [])).size() == 1 and game._acorrentada_enemy_elos(chain_target) > 0, "acorrentada chain hit did not resolve its moving shackle")
	_check(game.bullets.is_empty(), "acorrentada combo hook incorrectly required a projectile")
	_check(_has_event("hit_resolved", str(chain_target.get("uid", ""))), "acorrentada typed hit missing")

	var log_before: int = game.manifest_evolution_combat_event_log.size()
	game._manifest_evolution_on_combat_hit("duplicate:one", "acorrentada", chain_target, Vector2(chain_target["pos"]))
	game._manifest_evolution_on_combat_hit("duplicate:one", "acorrentada", chain_target, Vector2(chain_target["pos"]))
	_check(game.manifest_evolution_combat_event_log.size() == log_before + 1, "duplicate combat event was consumed twice")


func _run_necronada_skill() -> void:
	var field := _entry_for("necronada", "skill_field")
	_activate("necronada", field)
	game.necronada_vestiges.clear()
	var fields_before := Array(game.manifest_evolution_state.get("fields", [])).size()
	_check(not game._try_use_necronada_skill(game.player_pos), "empty necronada Q reported success")
	_check(Array(game.manifest_evolution_state.get("fields", [])).size() == fields_before, "failed necronada Q emitted skill field")
	game.necronada_vestiges.append({"id": 9001, "enemy_type": game.ENEMY_COMMON, "pos": game.player_pos + Vector2(24, 0), "profile": game._necronada_profile(game.ENEMY_COMMON), "depth": 1})
	_check(game._try_use_necronada_skill(game.player_pos), "valid necronada Q did not report success")
	_check(Array(game.manifest_evolution_state.get("fields", [])).size() == fields_before + 1, "valid necronada Q missed skill hook")
	_check(_has_event("skill_cast"), "necronada skill event missing")


func _run_multiplayer_event_identity() -> void:
	var target := {"uid": "shared-target", "kind": "enemy", "pos": game.player_pos}
	var before: int = game.manifest_evolution_combat_event_log.size()
	game._manifest_evolution_dispatch_combat_event({"type": "hit_resolved", "event_id": "peer:2:hit:9", "source": "network_test", "author_peer_id": 2, "target_uid": "shared-target", "target": target, "target_pos": game.player_pos})
	game._manifest_evolution_dispatch_combat_event({"type": "hit_resolved", "event_id": "peer:3:hit:9", "source": "network_test", "author_peer_id": 3, "target_uid": "shared-target", "target": target, "target_pos": game.player_pos})
	game._manifest_evolution_dispatch_combat_event({"type": "hit_resolved", "event_id": "peer:2:hit:9", "source": "network_test", "author_peer_id": 2, "target_uid": "shared-target", "target": target, "target_pos": game.player_pos})
	_check(game.manifest_evolution_combat_event_log.size() == before + 2, "author-scoped multiplayer events did not deduplicate correctly")


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.player_damage = 100.0
	game.last_facing = Vector2.RIGHT
	_run_manifest_regression()
	_run_lacerante_and_acorrentada()
	_run_necronada_skill()
	_run_multiplayer_event_identity()
	print("MANIFEST_EVOLUTION_COMBAT_HOOKS_OK manifestations=15 explicit=ancorada melee=lacerante/acorrentada necronada=valid_only multiplayer=deduped")
	game.set_process(false)
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	quit(0)
