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


func _prepare_phase2() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.mode = "game"
	game.current_phase = 2
	# A real phase transition preserves the run clock and moves phase_started_at.
	# Keep the fixture on that path so timing does not accidentally depend on phase 2
	# being the first phase of a run.
	game.phase_started_at = 91.0
	game.time_alive = game.phase_started_at
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.phase_transition_timer = 0.0
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.arauto_card_drops.clear()
	game.sineiro_boreal_controller.reset_for_new_run()


func _test_spawn_and_combat() -> void:
	var controller = game.sineiro_boreal_controller
	_check(is_equal_approx(controller.SPAWN_TIME_ONBOARDING, 120.0), "onboarding spawn timing drifted from two minutes")
	_check(is_equal_approx(controller.SPAWN_TIME_EXPERIENCED, 120.0), "experienced spawn timing drifted from two minutes")
	_check(is_equal_approx(float(controller.PARTY_HP_MULTIPLIERS[1]), 1.0), "solo HP multiplier drifted")
	_check(is_equal_approx(float(controller.PARTY_HP_MULTIPLIERS[2]), 1.70), "duo HP multiplier drifted")
	_check(is_equal_approx(float(controller.PARTY_HP_MULTIPLIERS[3]), 2.35), "trio HP multiplier drifted")
	_check(is_equal_approx(controller.hp_multiplier_for_party(2), 1.70), "duo HP path did not use configured multiplier")

	var enemy: Dictionary = controller.spawn_now()
	_check(not enemy.is_empty(), "forced Sineiro spawn failed")
	_check(String(enemy.get("type", "")) == game.ENEMY_SINEIRO_BOREAL, "spawned wrong enemy type")
	_check(bool(enemy.get("is_mini_boss", false)), "Sineiro was not marked as miniboss")
	_check(int(enemy.get("points", -1)) == 0, "generic kill points were not suppressed")
	_check(controller.spawn_now() == enemy, "second spawn created another encounter")
	_check(game.enemies.filter(func(value): return String(Dictionary(value).get("type", "")) == game.ENEMY_SINEIRO_BOREAL).size() == 1, "more than one Sineiro exists")

	game.player_pos = Vector2(520, 410)
	controller._history_by_peer = {
		0: [
			{"time": 7.0, "pos": Vector2(370, 330)},
			{"time": 7.9, "pos": Vector2(480, 370)},
			{"time": 8.8, "pos": Vector2(520, 410)},
		]
	}
	game.time_alive = 9.0
	var marks: Array = controller.build_echo_positions()
	_check(marks.size() == 2, "solo Badalada did not create exactly two marks")
	_check(Vector2(Dictionary(marks[0]).get("pos", Vector2.ZERO)).distance_to(Vector2(Dictionary(marks[1]).get("pos", Vector2.ZERO))) >= controller.ECHO_MIN_SPACING - 0.1, "solo marks overlap")
	var fixed_positions := marks.duplicate(true)
	game.player_pos = Vector2(1180, 620)
	_check(marks == fixed_positions, "telegraph marks followed the current player position")

	controller._begin_shard_attack(enemy, game.player_pos)
	enemy["sineiro_state_timer"] = 0.0
	controller._update_telegraph(enemy, 0.01)
	_check(String(enemy.get("sineiro_state", "")) == controller.STATE_ATTACK, "telegraph did not enter the attack commit state")
	controller.update_enemy(enemy, controller.ATTACK_COMMIT_TIME + 0.01)
	var shards: Array = game.enemy_bullets.filter(func(value): return String(Dictionary(value).get("type", "")) == "sineiro_shard")
	_check(shards.size() == 3, "secondary attack did not create three shards")
	var initial_dirs: Array = shards.map(func(value): return Vector2(Dictionary(value).get("dir", Vector2.ZERO)))
	game.player_pos = Vector2(120, 140)
	_check(initial_dirs == shards.map(func(value): return Vector2(Dictionary(value).get("dir", Vector2.ZERO))), "shards gained homing after firing")

	enemy["sineiro_state"] = controller.STATE_EXHAUSTED
	_check(is_equal_approx(controller.damage_taken_multiplier(enemy), 1.15), "exhaustion vulnerability is not 15%")
	enemy["sineiro_state"] = controller.STATE_APPROACH
	_check(is_equal_approx(controller.damage_taken_multiplier(enemy), 1.0), "damage bonus leaked outside exhaustion")


func _test_spawn_timing() -> void:
	var controller = game.sineiro_boreal_controller
	game.run_pacing_profile = game.PACING_PROFILE_ONBOARDING
	game.fusion_check_timer = 0.75
	game.time_alive = game.phase_started_at + controller.SPAWN_TIME_ONBOARDING - 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "onboarding encounter spawned early")
	game.time_alive = game.phase_started_at + controller.SPAWN_TIME_ONBOARDING + 0.1
	controller.update(0.0)
	_check(not controller.active_enemy().is_empty(), "onboarding encounter did not spawn two minutes after phase 2 began")
	controller.cleanup("timing_fixture")
	controller.reset_for_new_run()
	game.run_pacing_profile = game.PACING_PROFILE_EXPERIENCED
	game.fusion_check_timer = 0.75
	game.time_alive = game.phase_started_at + controller.SPAWN_TIME_EXPERIENCED - 0.1
	controller.update(0.0)
	_check(controller.active_enemy().is_empty(), "experienced encounter spawned early")
	game.time_alive = game.phase_started_at + controller.SPAWN_TIME_EXPERIENCED + 0.1
	controller.update(0.0)
	_check(not controller.active_enemy().is_empty(), "experienced encounter did not spawn two minutes after phase 2 began")
	controller.cleanup("timing_fixture")
	controller.reset_for_new_run()
	game.run_pacing_profile = game.PACING_PROFILE_ONBOARDING
	game.time_alive = game.phase_started_at


func _test_multiplayer_targets_and_rewards() -> void:
	var controller = game.sineiro_boreal_controller
	var enemy: Dictionary = controller.active_enemy()
	game.is_multiplayer = true
	game.net_players_by_peer = {
		2: {"has_snapshot": true, "dead": false, "eliminated": false, "hp": 100.0, "pos": Vector2(820, 320)},
		3: {"has_snapshot": true, "dead": false, "eliminated": false, "hp": 100.0, "pos": Vector2(1040, 540)},
		4: {"has_snapshot": true, "dead": true, "eliminated": true, "hp": 0.0, "pos": Vector2(600, 500)},
	}
	controller._history_by_peer = {
		0: [{"time": 8.0, "pos": Vector2(410, 310)}],
		2: [{"time": 8.0, "pos": Vector2(820, 320)}],
		3: [{"time": 8.0, "pos": Vector2(1040, 540)}],
	}
	var marks: Array = controller.build_echo_positions()
	_check(marks.size() == 3, "trio target set did not cap Badalada at three marks")
	var target_peers: Array = game._combat_targets().map(func(value): return int(Dictionary(value).get("peer_id", -1)))
	_check(target_peers.has(2) and target_peers.has(3), "living remote peers were not eligible")
	_check(not target_peers.has(4), "dead/eliminated peer blocked the encounter")
	var visual_count: int = game.sineiro_visual_events.size()
	var replicated_event := {"kind": "shard_prepare", "event_id": "replica_dedupe", "origin": Vector2(420, 320), "direction": Vector2.RIGHT}
	controller._rpc_sineiro_event(replicated_event)
	controller._rpc_sineiro_event(replicated_event)
	_check(game.sineiro_visual_events.size() == visual_count + 1, "duplicated reliable VFX event was applied twice")
	controller._rpc_sineiro_snapshot({
		"encounter_id": String(game.sineiro_boreal_state.get("encounter_id", "")),
		"enemy_uid": int(enemy.get("uid", -1)),
		"party_size": 3,
		"state": controller.STATE_EXHAUSTED,
		"state_timer": 1.2,
		"attack_kind": controller.ATTACK_ECHO,
		"attack_anim_timer": 0.0,
		"anim_time": 4.0,
		"facing_dir": Vector2.RIGHT,
		"last_move_dir": Vector2.ZERO,
		"marks": marks,
	})
	_check(String(enemy.get("sineiro_state", "")) == controller.STATE_EXHAUSTED, "replica did not apply authoritative state")
	_check(int(game.sineiro_boreal_state.get("party_size", 0)) == 3, "replica lost fixed encounter party size")
	_check(game.sineiro_echo_marks.size() == 3, "replica did not restore telegraph marks")
	game.is_multiplayer = false
	game.net_players_by_peer.clear()

	var score_before: int = int(game.score)
	var drops_before: int = game.arauto_card_drops.size()
	var fragments_before: int = int(game.manifest_evolution_fragment_claim_count)
	controller.on_enemy_defeated(enemy)
	controller.on_enemy_defeated(enemy)
	var expected_points := int(round(float(game.card_cost) * controller.REWARD_POINT_RATIO))
	_check(game.score - score_before == expected_points, "reward points were missing or duplicated")
	_check(game.arauto_card_drops.size() - drops_before == 2, "solo reward was not exactly two cards")
	_check(game.manifest_evolution_fragment_claim_count == fragments_before, "Sineiro granted manifestation evolution progress")
	_check(bool(game.sineiro_boreal_state.get("reward_processed", false)), "reward idempotency state was not recorded")
	game.enemies.erase(enemy)


func _test_cleanup_and_persistence_contract() -> void:
	var controller = game.sineiro_boreal_controller
	controller.reset_for_new_run()
	var enemy: Dictionary = controller.spawn_now()
	_check(not enemy.is_empty(), "cleanup fixture could not spawn")
	controller.cleanup("phase_transition")
	_check(controller.active_enemy().is_empty(), "phase transition kept the Sineiro alive")
	_check(not game.enemy_bullets.any(func(value): return String(Dictionary(value).get("type", "")) == "sineiro_shard"), "cleanup retained Sineiro shards")
	_check(not bool(game.sineiro_boreal_state.get("reward_processed", false)), "cleanup granted the kill reward")
	_check(bool(game.sineiro_boreal_state.get("spawned", false)), "cleanup made the once-per-run encounter eligible again")
	var save_fields: Array = game.save_controller._interrupted_run_field_names()
	for field_name in ["sineiro_boreal_state", "sineiro_echo_marks", "sineiro_visual_events"]:
		_check(save_fields.has(field_name), "save/retry contract missing " + field_name)
	_check(game.NET_ENEMY_TYPES.has(game.ENEMY_SINEIRO_BOREAL), "enemy snapshot contract missing Sineiro type")
	_check(game.NET_BULLET_TYPES.has("sineiro_shard"), "bullet snapshot contract missing shard type")

	controller.reset_for_new_run()
	var timeout_enemy: Dictionary = controller.spawn_now()
	var timeout_score: int = int(game.score)
	var timeout_drops: int = game.arauto_card_drops.size()
	game.sineiro_boreal_state["battle_elapsed"] = controller.ACTIVE_LIFETIME
	controller.update(0.0)
	_check(String(timeout_enemy.get("sineiro_state", "")) == controller.STATE_DESPAWN, "110s timeout did not begin retreat")
	controller.update_enemy(timeout_enemy, controller.RETREAT_TIME + 0.01)
	_check(controller.active_enemy().is_empty(), "timeout retreat did not remove the Sineiro")
	_check(int(game.score) == timeout_score and game.arauto_card_drops.size() == timeout_drops, "timeout incorrectly granted the kill reward")


func _run() -> void:
	await process_frame
	_prepare_phase2()
	_test_spawn_timing()
	_test_spawn_and_combat()
	_test_multiplayer_targets_and_rewards()
	_test_cleanup_and_persistence_contract()
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _frame in range(3):
		await process_frame
	if not failures.is_empty():
		for failure in failures:
			printerr("PHASE2_SINEIRO_BOREAL_SMOKE_FAIL " + failure)
		quit(1)
		return
	print("PHASE2_SINEIRO_BOREAL_SMOKE_OK spawn=true attacks=true authority_targets=true rewards=true cleanup=true save=true")
	quit(0)
