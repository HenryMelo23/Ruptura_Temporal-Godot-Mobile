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
	_check(is_equal_approx(controller.FIRST_SPAWN_TIME, 120.0), "first spawn timing drifted from recurring encounter cadence")
	_check(is_equal_approx(controller.RESPAWN_MIN_TIME, 120.0), "minimum recurrence drifted")
	_check(is_equal_approx(controller.RESPAWN_MAX_TIME, 150.0), "maximum recurrence drifted")
	_check(is_inf(controller.MAX_LIFETIME), "Suturador still has a lifetime timeout")
	_check(is_equal_approx(controller.MOVE_SPEED, 59.0), "base speed is not half of the original 118")
	_check(is_equal_approx(controller.hp_multiplier_for_party(1), 1.0), "solo HP multiplier drifted")
	_check(is_equal_approx(controller.hp_multiplier_for_party(2), 1.75), "duo HP multiplier drifted")
	_check(is_equal_approx(controller.hp_multiplier_for_party(3), 2.40), "trio HP multiplier drifted")
	_check(not game.is_multiplayer, "singleplayer fixture unexpectedly entered multiplayer")

	game.time_alive = controller.FIRST_SPAWN_TIME - 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "Suturador appeared before two minutes")
	game.arauto = {"active": true, "hp": 1.0}
	game.fusion_check_timer = 30.0
	game.time_alive = controller.FIRST_SPAWN_TIME + 0.1
	controller.update(0.0)
	_check(not controller.active_enemy().is_empty(), "Suturador failed to appear at two minutes while Arauto/event flow was active")
	controller.cleanup("overlap_fixture", false)
	controller.reset_for_new_run()
	game.arauto.clear()
	game.fusion_check_timer = 0.0
	game.boss_active = true
	game.time_alive = controller.FIRST_SPAWN_TIME + 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "Suturador spawned while boss was active")
	game.boss_active = false
	controller.update(0.0)
	var enemy: Dictionary = controller.active_enemy()
	_check(not enemy.is_empty(), "Suturador did not spawn in singleplayer at two minutes")
	_check(String(enemy.get("type", "")) == game.ENEMY_AMBER_SUTURER, "spawned wrong event enemy")
	_check(controller.spawn_now() == enemy, "second spawn created a duplicate Suturador")
	_check(game.enemies.filter(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_AMBER_SUTURER).size() == 1, "more than one Suturador exists")
	_check(int(enemy.get("max_hp", 0)) >= 2200, "Suturador max HP was not configured")
	_check(is_equal_approx(float(enemy.get("speed", 0.0)), 59.0) and not bool(enemy.get("parado", true)), "Suturador base movement is not 59 px/s")
	game.arauto.clear()
	game.arauto_spawned = false
	game._spawn_arauto()
	_check(not controller.active_enemy().is_empty(), "Arauto entry removed the active Suturador")
	game.arauto.clear()
	game.arauto_spawned = false
	game.enemies = game.enemies.filter(func(value): return not bool(Dictionary(value).get("aguilhao_nodule", false)))


func _test_solo_duo_trio_hp() -> void:
	var controller = game.amber_suturer_controller
	var solo_enemy: Dictionary = controller.active_enemy()
	var solo_hp := float(solo_enemy.get("max_hp", 0.0))
	_check(is_equal_approx(float(game.amber_suturer_state.get("hp_multiplier", 0.0)), 1.0), "solo encounter did not use 1.0x HP")
	controller.cleanup("party_fixture", false)
	for party_size in [2, 3]:
		controller.reset_for_new_run()
		game.is_multiplayer = true
		game.online_room_owner = true
		game.online_lobby_connected_count = party_size
		var enemy: Dictionary = controller.spawn_now()
		_check(not enemy.is_empty(), "party fixture could not spawn for %d players" % party_size)
		_check(int(game.amber_suturer_state.get("party_size", 0)) == party_size, "party size was not captured for %d players" % party_size)
		_check(is_equal_approx(float(enemy.get("max_hp", 0.0)), solo_hp * controller.hp_multiplier_for_party(party_size)), "party HP scaling drifted for %d players" % party_size)
		controller.cleanup("party_fixture", false)
	game.is_multiplayer = false
	game.online_room_owner = false
	game.online_lobby_connected_count = 0
	controller.reset_for_new_run()
	var restored_solo: Dictionary = controller.spawn_now()
	_check(not restored_solo.is_empty() and is_equal_approx(float(restored_solo.get("max_hp", 0.0)), solo_hp), "solo fixture was not restored after party scaling")


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
	_check(segments.size() == controller.MAX_ACTIVE_SUTURES, "suture generation did not create exactly two lines")
	_check(controller.has_safe_route(game.player_pos, segments), "suture generation left no safe route")
	var endpoints: Array[Vector2] = []
	for segment_value in segments:
		var segment: Dictionary = segment_value
		var a := Vector2(segment.get("a", Vector2.ZERO))
		var b := Vector2(segment.get("b", Vector2.ZERO))
		var length := a.distance_to(b)
		_check(length >= controller.MIN_LINE_LENGTH and length <= controller.MAX_LINE_LENGTH + 0.1, "long suture escaped its 520-820 px contract")
		_check(absf(a.x - b.x) > 120.0 and absf(a.y - b.y) > 120.0, "suture was not diagonal")
		_check(a.x >= 62.0 and a.y >= 62.0 and b.x <= game.WORLD_SIZE.x - 62.0 and b.y <= game.WORLD_SIZE.y - 62.0, "suture endpoint escaped 2D world bounds")
		endpoints.append(a)
		endpoints.append(b)
	var min_x: float = endpoints.map(func(point): return Vector2(point).x).min()
	var max_x: float = endpoints.map(func(point): return Vector2(point).x).max()
	var min_y: float = endpoints.map(func(point): return Vector2(point).y).min()
	var max_y: float = endpoints.map(func(point): return Vector2(point).y).max()
	_check(max_x - min_x >= 650.0 and max_y - min_y >= 420.0, "two sutures were not spread across distinct map sectors")
	controller._begin_suture_cycle(enemy)
	_check(String(enemy.get("suturer_state", "")) == controller.STATE_TELEGRAPH, "cycle did not begin with a telegraph")
	_check(game.amber_sutures.size() == 2, "cycle did not create exactly two sutures")
	var nodes: Array = game.enemies.filter(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_AMBER_SUTURE_NODE)
	_check(nodes.size() == 4, "cycle did not create four independent crystals")
	var core_hp_before: float = float(enemy.get("hp", 0.0))
	game._damage_enemy(enemy, 100.0, "smoke", false, false)
	_check(float(enemy.get("hp", 0.0)) < core_hp_before, "normal attacks could not damage the Suturador core")
	var expected_node_hp := maxf(100.0, float(enemy.get("max_hp", 0.0)) * 0.04)
	_check(nodes.all(func(value): return is_equal_approx(float(Dictionary(value).get("max_hp", 0.0)), expected_node_hp)), "crystal HP is not max(100, owner_hp * 0.04)")
	var common_shots := ceili(expected_node_hp / game.PLAYER_BASE_DAMAGE)
	_check(common_shots >= 2 and common_shots <= 4, "crystal does not die in 2-4 common base shots")
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
	var score_before: int = game.score
	var kills_before: int = game.enemies_killed
	var drops_before: int = game.arauto_card_drops.size()
	var first_suture_id := String(Dictionary(nodes[0]).get("suture_id", ""))
	var partner_uid := int(Dictionary(nodes.filter(func(value): return String(Dictionary(value).get("suture_id", "")) == first_suture_id)[1]).get("uid", -1))
	var expected_speeds := [47.2, 35.4, 23.6, 11.8]
	for index in range(nodes.size()):
		var node: Dictionary = nodes[index]
		node["hp"] = 0.0
		game._kill_enemy(node)
		_check(int(enemy.get("suturer_crystal_slow_stacks", 0)) == index + 1, "crystal kill did not add one independent slow stack")
		_check(is_equal_approx(controller._effective_move_speed(enemy), expected_speeds[index]), "crystal slow did not apply additive 20% base-speed steps")
		_check(is_equal_approx(float(enemy.get("suturer_crystal_slow_timer", 0.0)), controller.CRYSTAL_SLOW_DURATION), "new crystal did not refresh the 7s slow")
		if index == 0:
			_check(game.enemies.any(func(value): return int(Dictionary(value).get("uid", -2)) == partner_uid), "breaking one endpoint deleted its partner crystal")
	_check(game.amber_sutures.is_empty(), "four crystal kills did not independently break both lines")
	_check(game.score == score_before and game.enemies_killed == kills_before and game.arauto_card_drops.size() == drops_before, "crystals incorrectly granted XP/score/drops")
	controller._update_crystal_slow(enemy, 6.5)
	_check(int(enemy.get("suturer_crystal_slow_stacks", 0)) == 4, "slow expired before seven seconds")
	controller._update_crystal_slow(enemy, 0.5)
	_check(int(enemy.get("suturer_crystal_slow_stacks", -1)) == 0 and is_equal_approx(controller._effective_move_speed(enemy), 59.0), "speed did not return to base after slow expiry")


func _test_four_attack_rotation_and_hook() -> void:
	var controller = game.amber_suturer_controller
	var enemy: Dictionary = controller.active_enemy()
	controller._clear_sutures("attack_rotation_fixture", false)
	game.enemy_bullets.clear()
	game.amber_suturer_state["ability_cycle"] = 0

	controller._begin_attack_cycle(enemy)
	_check(String(enemy.get("suturer_current_ability", "")) == "suture", "attack rotation did not start with route sutures")
	_check(not game.amber_sutures.is_empty(), "route-suture ability did not build its arena hazard")
	controller._clear_sutures("attack_rotation_fixture", false)

	controller._begin_attack_cycle(enemy)
	_check(String(enemy.get("suturer_current_ability", "")) == "needle_fan", "second attack was not the aimed needle fan")
	_check(String(enemy.get("suturer_state", "")) == controller.STATE_NEEDLE_TELEGRAPH, "needle fan skipped its readable telegraph")
	controller._fire_needle_attack(enemy)
	var fan_bullets: Array = game.enemy_bullets.filter(func(value): return String(Dictionary(value).get("type", "")) == "suturer_needle")
	_check(fan_bullets.size() == controller.NEEDLE_FAN_COUNT, "needle fan did not emit exactly five projectiles")
	_check(fan_bullets.all(func(value): return is_equal_approx(Vector2(Dictionary(value).get("dir", Vector2.ZERO)).length(), 1.0)), "needle fan emitted a malformed direction")

	game.enemy_bullets.clear()
	controller._begin_attack_cycle(enemy)
	_check(String(enemy.get("suturer_current_ability", "")) == "amber_hook", "third attack was not the amber hook")
	_check(String(enemy.get("suturer_state", "")) == controller.STATE_HOOK_TELEGRAPH, "amber hook skipped its readable telegraph")
	controller._fire_hook(enemy)
	var hook_bullets: Array = game.enemy_bullets.filter(func(value): return String(Dictionary(value).get("type", "")) == "suturer_hook")
	_check(hook_bullets.size() == 1, "amber hook did not emit exactly one ranged projectile")
	_check(float(hook_bullets.front().get("hit_radius", 0.0)) >= 20.0, "amber hook projectile has an unreadable collision profile")

	game.cards_bought["Disparo crescente"] = 1
	game._recalculate_common_card_stat_bonuses()
	var before_pull: Vector2 = game.player_pos
	controller.on_hook_hit(hook_bullets.front(), game._mp_unique_id())
	_check(game.player_pos != before_pull and game.player_pos.distance_to(Vector2(enemy.get("pos", game.player_pos))) <= controller.HOOK_PULL_DISTANCE + 2.0, "amber hook did not pull the player close")
	_check(game.player_stun_timer > 0.0, "amber hook did not apply its punishment window")
	_check(int(game.cards_bought.get("Disparo crescente", 0)) == 0, "amber hook did not steal an owned card")
	var stolen_cards: Array = game.amber_suturer_state.get("stolen_cards", [])
	_check(stolen_cards.size() == 1 and String(Dictionary(stolen_cards.front()).get("display_name", "")).length() > 0, "stolen card identity was not exposed")
	controller.restore_local_card("Disparo crescente")
	game.amber_suturer_state["stolen_cards"] = []

	game.enemy_bullets.clear()
	controller._begin_attack_cycle(enemy)
	_check(String(enemy.get("suturer_current_ability", "")) == "needle_burst", "fourth attack was not the radial needle crown")
	controller._fire_needle_attack(enemy)
	var radial_bullets: Array = game.enemy_bullets.filter(func(value): return String(Dictionary(value).get("type", "")) == "suturer_needle")
	_check(radial_bullets.size() == controller.NEEDLE_RADIAL_COUNT, "needle crown did not emit its twelve-way burst")
	var unique_directions: Dictionary = {}
	for bullet_value in radial_bullets:
		var direction := Vector2(Dictionary(bullet_value).get("dir", Vector2.ZERO))
		unique_directions[Vector2i(roundi(direction.x * 1000.0), roundi(direction.y * 1000.0))] = true
	_check(unique_directions.size() == controller.NEEDLE_RADIAL_COUNT, "needle crown repeated directions instead of covering the arena")
	_check(String(game.amber_suturer_state.get("current_ability", "")) == "needle_burst", "public encounter state did not expose the active ability")


func _test_remote_card_change_idempotence() -> void:
	var controller = game.amber_suturer_controller
	var card_id := "Disparo crescente"
	var encounter_id := "suturer_remote_idempotence"
	game.cards_bought[card_id] = 1
	controller.apply_remote_card_change(card_id, false, encounter_id)
	controller.apply_remote_card_change(card_id, false, encounter_id)
	_check(int(game.cards_bought.get(card_id, 0)) == 0, "duplicate remote steal consumed the same card twice")
	controller.apply_remote_card_change(card_id, true, encounter_id)
	controller.apply_remote_card_change(card_id, true, encounter_id)
	_check(int(game.cards_bought.get(card_id, 0)) == 1, "duplicate remote restore granted an extra card")
	controller.apply_remote_card_change(card_id, true, encounter_id + "_late")
	_check(int(game.cards_bought.get(card_id, 0)) == 1, "restore without a matching steal granted a card")


func _test_movement_slow_and_frame_rates() -> void:
	var controller = game.amber_suturer_controller
	var source: Dictionary = controller.active_enemy()
	game.player_pos = Vector2(1180.0, 450.0)
	for stacks in [0, 4]:
		var distances: Array[float] = []
		for fps in [30, 60]:
			var enemy: Dictionary = source.duplicate(true)
			enemy["pos"] = Vector2(800.0, 450.0)
			enemy["suturer_target_peer"] = game._mp_unique_id()
			enemy["suturer_crystal_slow_stacks"] = stacks
			enemy["suturer_crystal_slow_timer"] = 7.0 if stacks > 0 else 0.0
			var start := Vector2(enemy["pos"])
			for _frame in range(fps):
				controller._update_observation_movement(enemy, 1.0 / float(fps))
			distances.append(start.distance_to(Vector2(enemy["pos"])))
		_check(absf(distances[0] - distances[1]) <= 1.2, "observation movement diverged between 30 and 60 FPS")
		if stacks == 0:
			_check(distances[0] >= 57.0 and distances[0] <= 60.0, "observation movement bypassed 59 px/s base")
		else:
			_check(distances[0] >= 11.0 and distances[0] <= 12.5, "observation movement bypassed four-stack slow")

	var strafe_enemy: Dictionary = source.duplicate(true)
	strafe_enemy["pos"] = Vector2(800.0, 450.0)
	strafe_enemy["suturer_target_peer"] = game._mp_unique_id()
	strafe_enemy["suturer_crystal_slow_stacks"] = 4
	strafe_enemy["suturer_crystal_slow_timer"] = 7.0
	var strafe_start := Vector2(strafe_enemy["pos"])
	controller._update_combat_strafe(strafe_enemy, 1.0, 1.0)
	_check(strafe_start.distance_to(Vector2(strafe_enemy["pos"])) <= 12.0, "combat strafe bypassed crystal slow")

	var reposition_enemy: Dictionary = source.duplicate(true)
	reposition_enemy["pos"] = Vector2(800.0, 450.0)
	reposition_enemy["suturer_reposition_dir"] = Vector2.RIGHT
	reposition_enemy["suturer_crystal_slow_stacks"] = 4
	reposition_enemy["suturer_crystal_slow_timer"] = 7.0
	controller._update_reposition(reposition_enemy, 1.0)
	_check(float(reposition_enemy["pos"].x) - 800.0 <= 15.2, "reposition still bypasses effective speed")


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
	var saved_suturer_state: Dictionary = snapshot_fields.get("amber_suturer_state", {})
	_check(saved_suturer_state.has("crystal_slow_stacks") and saved_suturer_state.has("crystal_slow_timer"), "interrupted snapshot misses crystal slow state")
	_check(game.NET_ENEMY_TYPES.has(game.ENEMY_AMBER_SUTURER), "enemy snapshot contract misses the core")
	_check(game.NET_ENEMY_TYPES.has(game.ENEMY_AMBER_SUTURE_NODE), "enemy snapshot contract misses endpoints")

	game.cards_bought["Disparo crescente"] = 1
	game._recalculate_common_card_stat_bonuses()
	var stolen: Dictionary = controller._steal_card_from_peer(game._mp_unique_id())
	_check(not stolen.is_empty(), "defeat reward fixture could not steal a card")
	var drops_before: int = game.arauto_card_drops.size()
	controller.on_enemy_defeated(enemy)
	game.enemies.erase(enemy) # Mirrors the normal generic enemy removal after the controller performs cleanup.
	var defeat_drops: Array = game.arauto_card_drops.slice(drops_before)
	_check(defeat_drops.size() >= controller.REWARD_CARD_COUNT + 1, "Suturador death did not deliver reward cards plus the stolen card")
	_check(defeat_drops.any(func(value): return bool(Dictionary(value).get("suturer_returned", false))), "Suturador death did not mark the stolen card for restoration")
	_check(game.amber_sutures.is_empty(), "core death did not remove every suture")
	_check(not game.enemies.any(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_AMBER_SUTURE_NODE), "core death left orphan endpoints")
	_check(not bool(game.amber_suturer_state.get("active", true)), "core death left the encounter active")
	var next_time := float(game.amber_suturer_state.get("next_spawn_phase_time", 0.0))
	_check(next_time >= game._phase_elapsed_time() + controller.RESPAWN_MIN_TIME and next_time <= game._phase_elapsed_time() + controller.RESPAWN_MAX_TIME, "recurrence is outside 120-150 seconds")
	game.time_alive = next_time - 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "encounter respawned before its scheduled recurrence")
	game.time_alive = next_time + 0.1
	controller.update(0.0)
	_check(not controller.active_enemy().is_empty(), "encounter did not recur after its scheduled time")
	game.amber_suturer_state["battle_elapsed"] = 300.0
	controller.update(0.0)
	_check(not controller.active_enemy().is_empty(), "living Suturador disappeared after the old timeout window")
	var mode_before_boss_call: String = game.mode
	game.boss_ready = true
	game._start_boss_call_local()
	_check(game.mode == mode_before_boss_call and not controller.active_enemy().is_empty(), "boss call bypassed the living Suturador gate")
	game.boss_active = true
	controller.update(0.0)
	_check(controller.active_enemy().is_empty() and game.amber_sutures.is_empty(), "legacy boss/Suturador conflict did not recover without a softlock")
	game.boss_active = false
	controller.cleanup("phase_transition")
	_check(controller.active_enemy().is_empty() and game.amber_sutures.is_empty(), "phase cleanup left event state in the world")


func _run() -> void:
	await process_frame
	_prepare_phase6()
	_test_timing_and_authority()
	_test_solo_duo_trio_hp()
	_test_sutures_nodes_and_damage_gate()
	_test_four_attack_rotation_and_hook()
	_test_remote_card_change_idempotence()
	_test_movement_slow_and_frame_rates()
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
	print("PHASE6_AMBER_SUTURER_SMOKE_OK persistent=true speed=59 slow_stacks=4 slow_duration=7 lines=2 nodes=4 fps=30_60 attacks=4 multiplayer=true boss_gate=true save=true")
	quit(0)
