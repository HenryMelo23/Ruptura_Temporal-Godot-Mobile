extends SceneTree

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _prepare_phase6() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.mode = "game"
	game.current_phase = 6
	game.phase_started_at = 0.0
	game.time_alive = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.phase_transition_timer = 0.0
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.amber_suturer_controller.reset_for_new_run()


func _test_timing_and_authority() -> void:
	var controller = game.amber_suturer_controller
	_check(is_equal_approx(controller.FIRST_SPAWN_TIME, 200.0), "first spawn timing drifted")
	_check(is_equal_approx(controller.RESPAWN_MIN_TIME, 240.0), "minimum recurrence drifted")
	_check(is_equal_approx(controller.RESPAWN_MAX_TIME, 300.0), "maximum recurrence drifted")
	_check(is_equal_approx(controller.MAX_LIFETIME, 45.0), "maximum lifetime drifted")
	_check(is_equal_approx(controller.hp_multiplier_for_party(1), 1.0), "solo HP multiplier drifted")
	_check(is_equal_approx(controller.hp_multiplier_for_party(2), 1.75), "duo HP multiplier drifted")
	_check(is_equal_approx(controller.hp_multiplier_for_party(3), 2.40), "trio HP multiplier drifted")

	game.time_alive = controller.FIRST_SPAWN_TIME - 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "Suturador appeared before 200s")
	game.arauto = {"active": true, "hp": 1.0}
	game.time_alive = controller.FIRST_SPAWN_TIME + 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "Suturador spawned while Arauto was active")
	game.arauto.clear()
	game.boss_active = true
	game.time_alive = controller.FIRST_SPAWN_TIME + 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "Suturador spawned while boss was active")
	game.boss_active = false
	controller.update(0.0)
	var enemy: Dictionary = controller.active_enemy()
	_check(not enemy.is_empty(), "Suturador did not spawn at 200s")
	_check(String(enemy.get("type", "")) == game.ENEMY_AMBER_SUTURER, "spawned wrong event enemy")
	_check(controller.spawn_now() == enemy, "second spawn created a duplicate Suturador")
	_check(game.enemies.filter(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_AMBER_SUTURER).size() == 1, "more than one Suturador exists")
	_check(int(enemy.get("max_hp", 0)) >= 2200, "Suturador max HP was not configured")


func _test_sutures_nodes_and_damage_gate() -> void:
	var controller = game.amber_suturer_controller
	var enemy: Dictionary = controller.active_enemy()
	game.player_pos = Vector2(740, 420)
	controller._history_by_peer = {
		0: [
			{"time": 201.0, "pos": Vector2(420, 420)},
			{"time": 201.8, "pos": Vector2(580, 420)},
			{"time": 202.0, "pos": Vector2(740, 420)},
		]
	}
	var segments: Array = controller.build_suture_segments(0, game.player_pos)
	_check(not segments.is_empty() and segments.size() <= controller.MAX_ACTIVE_SUTURES, "suture generation exceeded the two-line cap")
	_check(controller.has_safe_route(game.player_pos, segments), "suture generation left no safe route")
	controller._begin_suture_cycle(enemy)
	_check(String(enemy.get("suturer_state", "")) == controller.STATE_TELEGRAPH, "cycle did not begin with a telegraph")
	_check(game.amber_sutures.size() >= 1 and game.amber_sutures.size() <= 2, "cycle did not create one or two sutures")
	var nodes: Array = game.enemies.filter(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_AMBER_SUTURE_NODE)
	_check(nodes.size() == game.amber_sutures.size() * 2, "each suture did not create two breakable endpoints")
	var core_hp_before: float = float(enemy.get("hp", 0.0))
	game._damage_enemy(enemy, 100.0, "smoke", false, false)
	_check(float(enemy.get("hp", 0.0)) < core_hp_before, "normal attacks could not damage the Suturador core")
	var node: Dictionary = nodes.front()
	var node_hp_before: float = float(node.get("hp", 0.0))
	game._damage_enemy(node, 100.0, "smoke", false, false)
	_check(float(node.get("hp", 0.0)) < node_hp_before, "normal attacks could not damage a suture endpoint")
	var hp_before: float = game.player_hp
	controller._update_active_sutures(0.1)
	_check(is_equal_approx(game.player_hp, hp_before), "telegraph damaged the player before activation")
	controller._activate_sutures(enemy)
	var suture: Dictionary = game.amber_sutures.front()
	game.player_pos = Vector2(suture.get("a", game.player_pos)).lerp(Vector2(suture.get("b", game.player_pos)), 0.5)
	controller._update_active_sutures(0.01)
	var hp_after_first: float = game.player_hp
	_check(hp_after_first < hp_before, "active suture did not damage an intersecting player")
	controller._update_active_sutures(0.01)
	_check(is_equal_approx(game.player_hp, hp_after_first), "suture ignored the 1.2s damage gate")
	controller.on_enemy_defeated(node)
	_check(game.amber_sutures.size() == max(0, int(nodes.size() / 2) - 1), "destroying an endpoint did not break its suture")
	_check(not game.enemies.any(func(value): return int(Dictionary(value).get("uid", -1)) == int(node.get("uid", -2))), "destroyed endpoint stayed in the world")


func _test_multiplayer_cleanup_and_persistence() -> void:
	var controller = game.amber_suturer_controller
	var enemy: Dictionary = controller.active_enemy()
	game.is_multiplayer = true
	game.online_room_owner = true
	game.net_players_by_peer = {
		2: {"has_snapshot": true, "dead": false, "eliminated": false, "hp": 100.0, "hp_max": 100.0, "pos": Vector2(1060, 410)},
		3: {"has_snapshot": true, "dead": false, "eliminated": false, "hp": 100.0, "hp_max": 100.0, "pos": Vector2(1180, 570)},
		4: {"has_snapshot": true, "dead": true, "eliminated": true, "hp": 0.0, "hp_max": 100.0, "pos": Vector2(540, 570)},
	}
	_check(is_equal_approx(controller.hp_multiplier_for_party(3), 2.40), "fixed trio HP scaling drifted")
	var targets: Array = game._combat_targets()
	var peer_ids: Array = targets.map(func(value): return int(Dictionary(value).get("peer_id", -1)))
	_check(peer_ids.has(2) and peer_ids.has(3) and not peer_ids.has(4), "event target eligibility diverged from combat eligibility")
	var visuals: Dictionary = game._pack_net_boss_visuals()
	_check(visuals.has("amber_suturer_state") and visuals.has("amber_sutures") and visuals.has("amber_suturer_visual_events"), "world visual snapshot misses Suturador state")
	if game.amber_sutures.is_empty():
		controller._begin_suture_cycle(enemy)
		visuals = game._pack_net_boss_visuals()
	_check(not game.amber_sutures.is_empty(), "multiplayer fixture could not recreate a suture")
	var replica: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(replica)
	replica.is_multiplayer = true
	replica.online_room_owner = false
	replica.current_phase = 6
	replica._apply_remote_world_snapshot(game._pack_net_enemies(), game._pack_net_boss(), game._pack_net_enemy_bullets())
	replica._apply_remote_boss_visual_snapshot(visuals)
	_check(replica.enemies.any(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_AMBER_SUTURER), "replica did not receive the authoritative core")
	_check(replica.enemies.any(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_AMBER_SUTURE_NODE), "replica did not receive authoritative endpoints")
	_check(replica.amber_sutures.size() == game.amber_sutures.size(), "replica did not receive sutures from world visuals")
	_check(String(replica.amber_suturer_state.get("encounter_id", "")) == String(game.amber_suturer_state.get("encounter_id", "")), "replica did not receive the event identity")
	replica._cleanup_runtime_resources()
	root.remove_child(replica)
	replica.queue_free()
	game.is_multiplayer = false
	game.online_room_owner = false
	game.net_players_by_peer.clear()

	var save_fields: Array = game.save_controller._interrupted_run_field_names()
	for field_name in ["amber_suturer_state", "amber_sutures", "amber_suturer_visual_events"]:
		_check(save_fields.has(field_name), "save/retry contract missing " + field_name)
	var snapshot: Dictionary = game.save_controller._build_interrupted_run_snapshot()
	var snapshot_fields: Dictionary = snapshot.get("fields", {})
	_check(snapshot_fields.get("amber_suturer_state", {}) is Dictionary, "interrupted snapshot did not serialize event state")
	_check(snapshot_fields.get("amber_sutures", []) is Array, "interrupted snapshot did not serialize sutures")
	_check(game.NET_ENEMY_TYPES.has(game.ENEMY_AMBER_SUTURER), "enemy snapshot contract misses the core")
	_check(game.NET_ENEMY_TYPES.has(game.ENEMY_AMBER_SUTURE_NODE), "enemy snapshot contract misses endpoints")

	controller.on_enemy_defeated(enemy)
	game.enemies.erase(enemy) # Mirrors the normal generic enemy removal after the controller performs cleanup.
	_check(game.amber_sutures.is_empty(), "core death did not remove every suture")
	_check(not game.enemies.any(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_AMBER_SUTURE_NODE), "core death left orphan endpoints")
	_check(not bool(game.amber_suturer_state.get("active", true)), "core death left the encounter active")
	var next_time := float(game.amber_suturer_state.get("next_spawn_phase_time", 0.0))
	_check(next_time >= game._phase_elapsed_time() + controller.RESPAWN_MIN_TIME and next_time <= game._phase_elapsed_time() + controller.RESPAWN_MAX_TIME, "recurrence is outside 240-300 seconds")
	game.time_alive = next_time - 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "encounter respawned before its scheduled recurrence")
	game.time_alive = next_time + 0.1
	controller.update(0.0)
	_check(not controller.active_enemy().is_empty(), "encounter did not recur after its scheduled time")
	game.boss_active = true
	controller.update(0.0)
	_check(controller.active_enemy().is_empty() and game.amber_sutures.is_empty(), "boss start did not clean the event")
	game.boss_active = false
	controller.cleanup("phase_transition")
	_check(controller.active_enemy().is_empty() and game.amber_sutures.is_empty(), "phase cleanup left event state in the world")
	var timeout_enemy: Dictionary = controller.spawn_now()
	_check(not timeout_enemy.is_empty(), "timeout fixture could not spawn")
	game.amber_suturer_state["battle_elapsed"] = controller.MAX_LIFETIME
	controller.update(0.0)
	_check(controller.active_enemy().is_empty() and game.amber_sutures.is_empty(), "45s event expiry did not clean the world")


func _run() -> void:
	await process_frame
	_prepare_phase6()
	_test_timing_and_authority()
	_test_sutures_nodes_and_damage_gate()
	_test_multiplayer_cleanup_and_persistence()
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _frame in range(3):
		await process_frame
	if not failures.is_empty():
		for failure in failures:
			printerr("PHASE6_AMBER_SUTURER_SMOKE_FAIL " + failure)
		quit(1)
		return
	print("PHASE6_AMBER_SUTURER_SMOKE_OK timing=true sutures=true endpoints=true gate=true multiplayer=true cleanup=true save=true")
	quit(0)
