extends "res://scripts/main.gd"

## Research-only adapter. Combat, movement, collision and cadence remain in
## the inherited runtime. No laboratory result is uploaded or saved as a mind.
var external_command: Dictionary = {}
var applied_commands: Array[Dictionary] = []
var damage_events: Array[Dictionary] = []
var reference_movement: Dictionary = {}
var reference_center := Vector2.ZERO
var opponent_mode := "scripted_reference"
var player_auto_attack := true
var player_velocity := Vector2.ZERO
var action_repeat := 0
var last_executed := ""
var training_tick := 0


func _start_run_security_session() -> void:
	run_security_session_failed = true
	run_security_last_error = "offline research episode"


func _send_run_report_to_leaderboard(_payload: Dictionary) -> void:
	pass


func _send_run_report_to_discord(_payload: Dictionary) -> void:
	pass


func _app_update_supported() -> bool:
	return false


func _umbra_mind_remote_supported() -> bool:
	return false


func _update_player_progress_sync(_delta: float) -> void:
	pass


func _umbra_choose_action() -> String:
	var action := String(external_command.get("action", "NENHUMA"))
	return action if _umbra_available_actions().has(action) else "NENHUMA"


func _spawn_umbra_action(action: String) -> void:
	if action == "NENHUMA":
		return
	if not external_command.is_empty():
		boss5_authoritative_decision["space"] = Dictionary(external_command.get("space", {})).duplicate()
		boss5_authoritative_decision["source"] = "external_research_policy"
	super._spawn_umbra_action(action)
	action_repeat = action_repeat + 1 if last_executed == action else 1
	last_executed = action
	applied_commands.append({"action": action, "tick": training_tick, "simulation_time": time_alive,
		"space": Dictionary(boss5_authoritative_decision.get("space", {})).duplicate(), "target_slot": 0})
	external_command.clear()


func command_ready_within(seconds: float) -> bool:
	var cadence := (1.0 + boss5_cadence_bonus) * _boss_party_tempo_multiplier()
	return boss5_action_timer <= seconds * cadence and boss5_decision_timer <= seconds and boss5_siphon_timer <= seconds


func _update_apolo_phase5_exhibition(delta: float) -> void:
	if opponent_mode == "heuristic_reference":
		super._update_apolo_phase5_exhibition(delta)
		return
	if not _apolo_phase5_exhibition_active():
		apolo_phase5_exhibition_move = Vector2.ZERO
		return
	apolo_phase5_exhibition_timer += delta
	var style := String(reference_movement.get("style", "orbit"))
	var radius := float(reference_movement.get("radius", 260.0))
	var t := apolo_phase5_exhibition_timer * float(reference_movement.get("angular_speed", 0.66))
	var offset := Vector2(cos(t) * radius, sin(t * 1.37) * radius * 0.62)
	match style:
		"stationary": offset = player_pos - reference_center
		"strafe": offset = Vector2(sin(t * 3.1) * radius, cos(t * 1.2) * radius * 0.32)
		"edge_weave": offset = Vector2(sin(t * 1.7) * radius, cos(t * 2.1) * radius)
		"zigzag": offset = Vector2(sin(t * 4.4) * radius, sin(t * 2.0) * radius * 0.55)
		"anchor_pulse": offset = Vector2(cos(t * 1.2) * radius * 0.32, sin(t * 1.2) * radius * 0.32)
		"feint": offset = Vector2(signf(sin(t * 2.2)) * radius * 0.72, sin(t * 3.7) * radius * 0.42)
		"breakout": offset = Vector2(cos(t * 0.8) * radius, sin(t * 1.9) * radius * 0.5)
	apolo_phase5_exhibition_target = (reference_center + offset).clamp(Vector2(60, 60), WORLD_SIZE - Vector2(60, 60))
	apolo_phase5_exhibition_move = (apolo_phase5_exhibition_target - player_pos).limit_length(1.0)
	apolo_phase5_exhibition_aim = player_pos.direction_to(boss_pos + boss5_velocity * 0.3)
	if player_auto_attack and time_alive - last_attack_time >= _current_attack_interval():
		_try_attack()


func advance_training_tick(delta: float) -> void:
	var previous: Vector2 = player_pos
	training_tick += 1
	_process(delta)
	player_velocity = (player_pos - previous) / maxf(delta, 0.0001)


func _damage_player(amount: int, source: String, silent_hit_sfx: bool = false) -> void:
	var before: int = player_hp
	super._damage_player(amount, source, silent_hit_sfx)
	var actual := maxf(0.0, float(before - player_hp))
	if actual > 0.0:
		damage_events.append({"recipient": "player", "source": source, "amount": actual, "tick": training_tick,
			"simulation_time": time_alive, "threat_id": null, "attribution": "source_only_instance_unresolved"})


func _damage_boss(amount: float, source: String, apply_aura_multiplier: bool = true, release_boss_feed: bool = true, source_category: String = "", attack_origin: Vector2 = Vector2.ZERO, source_peer_id: int = 0, source_manifestation: String = "", critical_hit: bool = false, damage_text_label: String = "") -> void:
	var before: float = boss_hp
	super._damage_boss(amount, source, apply_aura_multiplier, release_boss_feed, source_category, attack_origin, source_peer_id, source_manifestation, critical_hit, damage_text_label)
	var actual := maxf(0.0, before - boss_hp)
	if actual > 0.0:
		damage_events.append({"recipient": "umbra", "source": source, "amount": actual, "tick": training_tick,
			"simulation_time": time_alive, "threat_id": null, "attribution": "source_only_instance_unresolved"})


func training_metrics() -> Dictionary:
	var metrics := {"player_velocity": player_velocity, "player_damage_recent": 0.0, "boss_damage_recent": 0.0,
		"hits_recent": 0, "action_repeat": action_repeat, "player_action_recent": 1.0 if time_alive - last_attack_time < 0.5 else 0.0}
	for event in damage_events:
		if time_alive - float(event["simulation_time"]) <= 3.0:
			var key := "player_damage_recent" if event["recipient"] == "player" else "boss_damage_recent"
			metrics[key] = float(metrics[key]) + float(event["amount"])
			metrics["hits_recent"] = int(metrics["hits_recent"]) + 1
	return metrics
