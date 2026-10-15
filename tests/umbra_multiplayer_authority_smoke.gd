extends SceneTree

const Schema = preload("res://scripts/systems/umbra_observation_schema.gd")

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UMBRA_MULTIPLAYER_AUTHORITY_FAIL " + message)
	_cleanup()
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _remote_state(position: Vector2, alive: bool = true, eliminated: bool = false) -> Dictionary:
	return {
		"pos": position,
		"velocity": Vector2.ZERO,
		"hp": 550.0 if alive else 0.0,
		"hp_max": 550.0,
		"alive": alive,
		"dead": not alive,
		"eliminated": eliminated,
		"manifestation": "prismatica"
	}


func _run() -> void:
	# Host fixture: local peer first, followed by stable sorted remote peer slots.
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = false
	game.dedicated_server_mode = false
	game.current_phase = 5
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_pos = Vector2(800.0, 450.0)
	game.boss_hp_max = 22000.0
	game.boss_hp = game.boss_hp_max
	game.player_pos = Vector2(380.0, 370.0)
	game.player_hp_max = 600
	game.player_hp = 600
	game.is_dead = false
	game.net_players_by_peer = {
		41: _remote_state(Vector2(1190.0, 500.0)),
		77: _remote_state(Vector2(1040.0, 260.0), false, true)
	}
	game._reset_phase5_state()

	var host_observation: Dictionary = Schema.build_from_runtime(game)
	_check(Array(host_observation.get("valid_player_mask", [])) == [1.0, 1.0, 0.0], "dead/eliminated peer remained targetable")
	_check(int(host_observation.get("input_size", -1)) == Array(host_observation.get("values", [])).size(), "host observation shape invalid")

	# The host is the only side allowed to advance decision state and execute.
	game.boss5_action_timer = 0.0
	game.boss5_decision_timer = 0.0
	game._update_boss_phase5(0.02)
	var host_event: Dictionary = game.boss5_authoritative_decision.duplicate(true)
	_check(not host_event.is_empty(), "host did not produce a decision")
	_check(int(host_event.get("target_peer_id", 0)) != 77, "host selected eliminated target")
	_check(not host_event.has("weights") and not host_event.has("hidden_state"), "decision leaked model state")
	var visual_packet: Dictionary = game._pack_net_boss_visuals()
	_check(Dictionary(visual_packet.get("umbra_decision", {})).get("event_id", "") == host_event.get("event_id", ""), "visual packet omitted compact decision")

	# A target dying after selection but before the windup is revalidated by the
	# host. With nobody alive, the attack becomes an explicit no-op.
	game.is_dead = true
	game.player_hp = 0
	game.net_players_by_peer[41] = _remote_state(Vector2(1190.0, 500.0))
	var windup_event: Dictionary = game.umbra_authority_controller.build_authoritative_decision(game, null, ["ATAQUE"], "ATAQUE")
	_check(int(windup_event.get("target_peer_id", 0)) == 41, "living remote target was not selected")
	game.net_players_by_peer[41] = _remote_state(Vector2(1190.0, 500.0), false, true)
	var revalidated: Dictionary = game.umbra_authority_controller.revalidate_before_execution(game, windup_event)
	_check(String(revalidated.get("action", "")) == "NENHUMA", "dead windup target still executed an attack")
	_check(int(revalidated.get("target_peer_id", -1)) == 0, "dead windup target was retained")
	_check(String(game.umbra_authority_controller.public_event().get("action", "")) == "NENHUMA", "revalidated target was not propagated to replicas")

	# Revive restores only the corresponding stable slot to the target mask.
	game.is_dead = false
	game.player_hp = game.player_hp_max
	game.net_players_by_peer[41] = _remote_state(Vector2(1190.0, 500.0))
	var revived_observation: Dictionary = Schema.build_from_runtime(game)
	_check(Array(revived_observation.get("valid_player_mask", [])) == [1.0, 1.0, 0.0], "revive did not restore the valid remote slot")

	# Replica fixture: late/repeated snapshots only update presentation state;
	# they never advance timers, policy state, hazards or a second action.
	game.is_host = false
	game.online_room_owner = false
	game.umbra_authority_controller.reset()
	game.boss5_action_timer = 13.0
	game.boss5_decision_timer = 7.0
	game._apply_remote_boss_visual_snapshot({
		"boss_entry_timer": 0.0,
		"phase5_hazards": [],
		"phase5_telegraphs": [],
		"umbra_decision": host_event
	})
	_check(game.boss5_authoritative_decision.get("sequence", -1) == host_event.get("sequence", -2), "replica rejected host decision")
	var applied_sequence: int = int(game.boss5_authoritative_decision.get("sequence", -1))
	game._apply_remote_boss_visual_snapshot({"umbra_decision": host_event})
	_check(int(game.boss5_authoritative_decision.get("sequence", -1)) == applied_sequence, "duplicate decision changed replica state")
	var stale_event := host_event.duplicate(true)
	stale_event["sequence"] = applied_sequence - 1
	game._apply_remote_boss_visual_snapshot({"umbra_decision": stale_event})
	_check(int(game.boss5_authoritative_decision.get("sequence", -1)) == applied_sequence, "late decision replaced newer replica state")
	game._update_boss_phase5(1.0)
	_check(is_equal_approx(game.boss5_action_timer, 13.0) and is_equal_approx(game.boss5_decision_timer, 7.0), "replica advanced host-only decision timers")

	# A reconnect starts with a fresh receiver but accepts the latest snapshot.
	game.umbra_authority_controller.reset()
	game.boss5_authoritative_decision.clear()
	game._apply_remote_boss_visual_snapshot({"umbra_decision": host_event})
	_check(game.boss5_authoritative_decision.get("event_id", "") == host_event.get("event_id", ""), "reconnect could not recover latest decision")
	print("UMBRA_MULTIPLAYER_AUTHORITY_OK host=true replica=true masks=true late_duplicate=true windup_revalidate=true revive=true reconnect=true")
	_cleanup()
	for _frame in range(3):
		await process_frame
	quit(0)


func _cleanup() -> void:
	if game == null or not is_instance_valid(game):
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
