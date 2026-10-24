class_name RTPhase6AmberSuturerController
extends Node

const TYPE_ID := "suturador_ambar"
const NODE_TYPE_ID := "sutura_ambar_node"

const STATE_ENTRY := "entry"
const STATE_OBSERVE := "observe"
const STATE_TELEGRAPH := "telegraph"
const STATE_ACTIVE := "active"
const STATE_NEEDLE_TELEGRAPH := "needle_telegraph"
const STATE_NEEDLE_RECOVERY := "needle_recovery"
const STATE_REPOSITION := "reposition"
const STATE_DYING := "dying"

# Phase-local cadence, matching the recurring pressure role used by Larápio
# while leaving a short random window between Suturador encounters.
const FIRST_SPAWN_TIME := 120.0
const RESPAWN_MIN_TIME := 120.0
const RESPAWN_MAX_TIME := 150.0
const MAX_LIFETIME := 45.0
const ENTRY_TIME := 1.0
const OBSERVE_TIME := 2.1
const TELEGRAPH_TIME := 1.5
const ACTIVE_TIME := 7.0
const REPOSITION_TIME := 1.15
const NEEDLE_TELEGRAPH_TIME := 0.85
const NEEDLE_RECOVERY_TIME := 0.72
const NEEDLE_FAN_COUNT := 5
const NEEDLE_RADIAL_COUNT := 12
const HISTORY_SAMPLE_INTERVAL := 0.12
const HISTORY_WINDOW := 2.8
const DAMAGE_MAX_HP_RATIO := 0.05
const DAMAGE_INTERVAL := 1.2
const SUTURE_RADIUS := 17.0
const NODE_RADIUS := 27.0
const MAX_ACTIVE_SUTURES := 2
const MAX_LINE_LENGTH := 520.0
const MIN_LINE_LENGTH := 170.0
const MOVE_SPEED := 118.0

const PARTY_HP_MULTIPLIERS := {
	1: 1.0,
	2: 1.75,
	3: 2.40,
}

var game: Node
var _history_by_peer: Dictionary = {}
var _history_sample_timer := 0.0
var _target_cursor := -1


func bind_game(p_game: Node) -> void:
	game = p_game
	if game.amber_suturer_state.is_empty():
		game.amber_suturer_state = _default_state()


func _default_state() -> Dictionary:
	return {
		"active": false,
		"encounter_id": "",
		"enemy_uid": -1,
		"party_size": 1,
		"hp_multiplier": 1.0,
		"battle_elapsed": 0.0,
		"next_spawn_phase_time": FIRST_SPAWN_TIME,
		"last_end_phase_time": -1.0,
		"event_sequence": 0,
		"cycle": 0,
		"ability_cycle": 0,
		"current_ability": "suture",
		"target_peer_id": 0,
		"state": STATE_ENTRY,
		"state_timer": 0.0,
		"anim_time": 0.0,
		"damage_gate_by_peer": {},
		"cleanup_reason": "",
	}


func reset_for_new_run() -> void:
	if game == null:
		return
	game.amber_suturer_state = _default_state()
	game.amber_sutures.clear()
	game.amber_suturer_visual_events.clear()
	_history_by_peer.clear()
	_history_sample_timer = 0.0
	_target_cursor = -1


func reset_for_phase() -> void:
	if game == null:
		return
	cleanup("phase_reset", false)
	reset_for_new_run()


func hp_multiplier_for_party(party_size: int) -> float:
	return float(PARTY_HP_MULTIPLIERS.get(clampi(party_size, 1, 3), PARTY_HP_MULTIPLIERS[3]))


func update(delta: float) -> void:
	if game == null:
		return
	_update_visual_events(delta)
	if game.current_phase != 6:
		if game._is_world_authority() and bool(game.amber_suturer_state.get("active", false)):
			cleanup("phase_changed")
		return
	if not game._is_world_authority():
		return
	if _event_incompatible():
		if bool(game.amber_suturer_state.get("active", false)):
			cleanup("incompatible_state")
		return
	_sample_player_history(delta)
	if bool(game.amber_suturer_state.get("active", false)):
		game.amber_suturer_state["battle_elapsed"] = float(game.amber_suturer_state.get("battle_elapsed", 0.0)) + delta
		_update_damage_gates(delta)
		if active_enemy().is_empty():
			_finish_event("enemy_missing")
			return
		if float(game.amber_suturer_state.get("battle_elapsed", 0.0)) >= MAX_LIFETIME:
			cleanup("timeout")
	else:
		_try_spawn()


func _event_incompatible() -> bool:
	if game.mode != "game":
		return true
	if game.boss_active or game.boss_dead or game.boss_call_timer >= 0.0 or game.phase_transition_timer > 0.0:
		return true
	return false


func _try_spawn() -> void:
	if float(game._phase_elapsed_time()) < float(game.amber_suturer_state.get("next_spawn_phase_time", FIRST_SPAWN_TIME)):
		return
	spawn_now()


func spawn_now() -> Dictionary:
	if game == null or not game._is_world_authority() or game.current_phase != 6 or _event_incompatible():
		return {}
	var existing := active_enemy()
	if not existing.is_empty():
		return existing
	var spawn_pos: Vector2 = game._spawn_point_on_edge().clamp(Vector2(100.0, 90.0), game.WORLD_SIZE - Vector2(100.0, 90.0))
	var previous_count: int = game.enemies.size()
	game._spawn_enemy(TYPE_ID, spawn_pos)
	if game.enemies.size() <= previous_count:
		return {}
	var enemy: Dictionary = game.enemies.back()
	var party_size := clampi(game._active_run_player_count(), 1, 3)
	var hp_multiplier := hp_multiplier_for_party(party_size)
	var solo_hp := maxf(2200.0, game.enemy_base_hp * 12.0)
	var hp := solo_hp * hp_multiplier
	var encounter_id := "suturador_%d_%d" % [int(game._phase_elapsed_time() * 1000.0), int(enemy.get("uid", previous_count + 1))]
	enemy["type"] = TYPE_ID
	enemy["is_event_enemy"] = true
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["points"] = 190
	enemy["damage"] = maxf(1.0, game.player_hp_max * 0.04 + game.enemy_close_damage * 0.45)
	enemy["speed"] = MOVE_SPEED
	enemy["parado"] = true
	enemy["state"] = STATE_ENTRY
	enemy["suturer_state"] = STATE_ENTRY
	enemy["suturer_state_timer"] = ENTRY_TIME
	enemy["suturer_anim_time"] = 0.0
	enemy["suturer_target_peer"] = 0
	enemy["suturer_reposition_dir"] = Vector2.ZERO
	enemy["suturer_attack_dir"] = Vector2.LEFT
	enemy["suturer_needle_pattern"] = "fan"
	enemy["contact_grace"] = ENTRY_TIME
	enemy["reconstituted_once"] = true
	game.amber_suturer_state = _default_state()
	game.amber_suturer_state.merge({
		"active": true,
		"encounter_id": encounter_id,
		"enemy_uid": int(enemy.get("uid", -1)),
		"party_size": party_size,
		"hp_multiplier": hp_multiplier,
		"next_spawn_phase_time": INF,
		"state": STATE_ENTRY,
		"state_timer": ENTRY_TIME,
	}, true)
	_history_by_peer.clear()
	game.event_alert_text = "O SUTURADOR DE AMBAR COSTURA A CHAGA!"
	game.event_alert_timer = 3.2
	game.event_alert_seed = int(enemy.get("uid", 0))
	# Match Larápio's readable arrival cue: edge spawns must not push the title
	# outside the current camera view.
	game._add_text("SUTURADOR DE AMBAR", game.player_pos + Vector2(0.0, -150.0), Color(1.0, 0.66, 0.18), 2.5, 25)
	game._play_sfx("Lodario-mov.mp3", 0.03, 0.66, 0.74)
	_emit_visual_event("entry", {"pos": spawn_pos})
	return enemy


func active_enemy() -> Dictionary:
	if game == null:
		return {}
	var expected_uid := int(game.amber_suturer_state.get("enemy_uid", -1))
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("type", "")) == TYPE_ID and (expected_uid < 0 or int(enemy.get("uid", -2)) == expected_uid):
			return enemy
	return {}


func update_enemy(enemy: Dictionary, delta: float) -> void:
	if game == null or not game._is_world_authority() or String(enemy.get("type", "")) != TYPE_ID:
		return
	enemy["parado"] = true
	enemy["suturer_anim_time"] = float(enemy.get("suturer_anim_time", 0.0)) + delta
	var state := String(enemy.get("suturer_state", STATE_ENTRY))
	if state == STATE_DYING:
		return
	match state:
		STATE_ENTRY:
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_set_state(enemy, STATE_OBSERVE, OBSERVE_TIME)
		STATE_OBSERVE:
			_update_observation_movement(enemy, delta)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_begin_attack_cycle(enemy)
		STATE_TELEGRAPH:
			enemy["last_move_dir"] = Vector2.ZERO
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_activate_sutures(enemy)
		STATE_ACTIVE:
			enemy["last_move_dir"] = Vector2.ZERO
			_update_active_sutures(delta)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_clear_sutures("cycle_complete")
				_begin_reposition(enemy)
		STATE_NEEDLE_TELEGRAPH:
			enemy["last_move_dir"] = Vector2.ZERO
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_fire_needle_attack(enemy)
		STATE_NEEDLE_RECOVERY:
			enemy["last_move_dir"] = Vector2.ZERO
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_begin_reposition(enemy)
		STATE_REPOSITION:
			_update_reposition(enemy, delta)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_set_state(enemy, STATE_OBSERVE, OBSERVE_TIME)
	_sync_public_enemy_state(enemy)


func update_node(enemy: Dictionary, _delta: float) -> void:
	if String(enemy.get("type", "")) != NODE_TYPE_ID:
		return
	enemy["parado"] = true
	enemy["last_move_dir"] = Vector2.ZERO
	enemy["contact_grace"] = 999.0


func _tick_state(enemy: Dictionary, delta: float) -> void:
	enemy["suturer_state_timer"] = maxf(0.0, float(enemy.get("suturer_state_timer", 0.0)) - delta)


func _set_state(enemy: Dictionary, state: String, timer: float) -> void:
	enemy["suturer_state"] = state
	enemy["state"] = state
	enemy["suturer_state_timer"] = timer
	_sync_public_enemy_state(enemy)


func _sync_public_enemy_state(enemy: Dictionary) -> void:
	game.amber_suturer_state["state"] = String(enemy.get("suturer_state", STATE_ENTRY))
	game.amber_suturer_state["state_timer"] = float(enemy.get("suturer_state_timer", 0.0))
	game.amber_suturer_state["anim_time"] = float(enemy.get("suturer_anim_time", 0.0))
	game.amber_suturer_state["facing_dir"] = Vector2(enemy.get("facing_dir", Vector2.LEFT))
	game.amber_suturer_state["last_move_dir"] = Vector2(enemy.get("last_move_dir", Vector2.ZERO))
	game.amber_suturer_state["current_ability"] = String(enemy.get("suturer_current_ability", "suture"))


func _update_observation_movement(enemy: Dictionary, delta: float) -> void:
	var target := _target_by_peer(int(enemy.get("suturer_target_peer", 0)))
	if target.is_empty():
		target = _select_next_target()
		if target.is_empty():
			enemy["last_move_dir"] = Vector2.ZERO
			return
		enemy["suturer_target_peer"] = int(target.get("peer_id", 0))
	var pos := Vector2(enemy.get("pos", game.player_pos))
	var target_pos := Vector2(target.get("pos", game.player_pos))
	var toward := (target_pos - pos).normalized()
	if toward.length_squared() <= 0.01:
		toward = Vector2.RIGHT
	var lateral := toward.orthogonal() * (-1.0 if int(enemy.get("uid", 0)) % 2 == 0 else 1.0)
	var distance := pos.distance_to(target_pos)
	var move_dir := lateral
	if distance > 410.0:
		move_dir = (toward * 0.78 + lateral * 0.22).normalized()
	elif distance < 220.0:
		move_dir = (-toward * 0.72 + lateral * 0.28).normalized()
	var next_pos := (pos + move_dir * float(enemy.get("speed", MOVE_SPEED)) * delta).clamp(Vector2(86.0, 78.0), game.WORLD_SIZE - Vector2(86.0, 78.0))
	enemy["pos"] = next_pos
	enemy["last_move_dir"] = move_dir
	if absf(move_dir.x) > 0.02:
		enemy["facing_dir"] = Vector2(signf(move_dir.x), 0.0)


func _begin_attack_cycle(enemy: Dictionary) -> void:
	var ability_cycle := int(game.amber_suturer_state.get("ability_cycle", 0))
	game.amber_suturer_state["ability_cycle"] = ability_cycle + 1
	match posmod(ability_cycle, 3):
		0:
			_begin_suture_cycle(enemy)
		1:
			_begin_needle_cycle(enemy, false)
		_:
			_begin_needle_cycle(enemy, true)


func _begin_suture_cycle(enemy: Dictionary) -> void:
	var target := _select_next_target()
	if target.is_empty():
		_set_state(enemy, STATE_OBSERVE, 0.8)
		return
	var peer_id := int(target.get("peer_id", 0))
	var target_pos := Vector2(target.get("pos", game.player_pos))
	var segments := build_suture_segments(peer_id, target_pos)
	if segments.is_empty():
		_set_state(enemy, STATE_OBSERVE, 0.8)
		return
	_clear_sutures("new_cycle", false)
	game.amber_suturer_state["cycle"] = int(game.amber_suturer_state.get("cycle", 0)) + 1
	game.amber_suturer_state["target_peer_id"] = peer_id
	enemy["suturer_target_peer"] = peer_id
	enemy["suturer_current_ability"] = "suture"
	game.amber_suturer_state["current_ability"] = "suture"
	var cycle_id := _next_event_id("cycle")
	for index in range(mini(MAX_ACTIVE_SUTURES, segments.size())):
		var segment: Dictionary = segments[index]
		var suture_id := "%s_%d" % [cycle_id, index]
		var node_a := _spawn_suture_node(Vector2(segment["a"]), suture_id, 0, enemy)
		var node_b := _spawn_suture_node(Vector2(segment["b"]), suture_id, 1, enemy)
		game.amber_sutures.append({
			"id": suture_id,
			"event_id": cycle_id,
			"a": Vector2(segment["a"]),
			"b": Vector2(segment["b"]),
			"state": STATE_TELEGRAPH,
			"timer": TELEGRAPH_TIME,
			"life": ACTIVE_TIME,
			"node_a_uid": int(node_a.get("uid", -1)),
			"node_b_uid": int(node_b.get("uid", -1)),
		})
	_set_state(enemy, STATE_TELEGRAPH, TELEGRAPH_TIME)
	game.event_alert_text = "SUTURA EM FORMACAO — QUEBRE OS NOS"
	game.event_alert_timer = TELEGRAPH_TIME
	game._play_sfx("Boss-Onda.mp3", 0.02, 0.52, 1.12)
	_emit_visual_event("telegraph", {"event_id": cycle_id, "pos": Vector2(enemy.get("pos", target_pos))})


func _begin_needle_cycle(enemy: Dictionary, radial: bool) -> void:
	var target := _select_next_target()
	if target.is_empty():
		_set_state(enemy, STATE_OBSERVE, 0.8)
		return
	_clear_sutures("needle_cycle", false)
	var origin := Vector2(enemy.get("pos", game.player_pos))
	var target_pos := Vector2(target.get("pos", game.player_pos))
	var direction := (target_pos - origin).normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.LEFT
	var pattern := "radial" if radial else "fan"
	var ability := "needle_burst" if radial else "needle_fan"
	var event_id := _next_event_id(ability)
	enemy["suturer_target_peer"] = int(target.get("peer_id", 0))
	enemy["suturer_attack_dir"] = direction
	enemy["suturer_needle_pattern"] = pattern
	enemy["suturer_attack_event_id"] = event_id
	enemy["suturer_current_ability"] = ability
	game.amber_suturer_state["target_peer_id"] = int(target.get("peer_id", 0))
	game.amber_suturer_state["current_ability"] = ability
	_set_state(enemy, STATE_NEEDLE_TELEGRAPH, NEEDLE_TELEGRAPH_TIME)
	game.event_alert_text = "COROA DE AGULHAS — AFASTE-SE" if radial else "AGULHAS DE AMBAR — ROMPA O LEQUE"
	game.event_alert_timer = NEEDLE_TELEGRAPH_TIME
	game._play_sfx("Boss-Onda.mp3", 0.02, 0.62, 1.18 if radial else 1.05)
	_emit_visual_event("needle_telegraph", {
		"event_id": event_id,
		"pos": origin,
		"direction": direction,
		"pattern": pattern,
	})


func _fire_needle_attack(enemy: Dictionary) -> void:
	var origin := Vector2(enemy.get("pos", game.player_pos))
	var base_direction := Vector2(enemy.get("suturer_attack_dir", Vector2.LEFT)).normalized()
	if base_direction.length_squared() <= 0.01:
		base_direction = Vector2.LEFT
	var radial := String(enemy.get("suturer_needle_pattern", "fan")) == "radial"
	var directions: Array[Vector2] = []
	if radial:
		var phase_offset := float(int(game.amber_suturer_state.get("ability_cycle", 0)) % 2) * PI / float(NEEDLE_RADIAL_COUNT)
		for index in range(NEEDLE_RADIAL_COUNT):
			directions.append(Vector2.from_angle(phase_offset + float(index) * TAU / float(NEEDLE_RADIAL_COUNT)))
	else:
		for angle in [-0.30, -0.15, 0.0, 0.15, 0.30]:
			directions.append(base_direction.rotated(float(angle)))
	var damage_ratio := 0.026 if radial else 0.034
	var far_scale := 0.28 if radial else 0.38
	var damage := maxi(1, int(game.player_hp_max * damage_ratio + game.enemy_far_damage * far_scale))
	var encounter_id := String(game.amber_suturer_state.get("encounter_id", ""))
	for direction in directions:
		game.enemy_bullets.append({
			"pos": origin + direction * 48.0,
			"dir": direction,
			"life": 4.0,
			"damage": damage,
			"phase": game.rng.randf_range(0.0, TAU),
			"type": "suturer_needle",
			"speed_mult": 0.90 if radial else 1.16,
			"radius": 9.0,
			"hit_radius": 15.0,
			"suturer_encounter_id": encounter_id,
		})
	_emit_visual_event("needle_fire", {
		"event_id": String(enemy.get("suturer_attack_event_id", _next_event_id("needle_fire"))),
		"pos": origin,
		"direction": base_direction,
		"pattern": "radial" if radial else "fan",
	})
	game._play_sfx("Boss-Impacto.mp3", 0.022, 0.64, 1.2 if radial else 1.08)
	_set_state(enemy, STATE_NEEDLE_RECOVERY, NEEDLE_RECOVERY_TIME)


func build_suture_segments(peer_id: int, fallback_pos: Vector2) -> Array:
	var samples: Array = _history_by_peer.get(peer_id, [])
	var recent := fallback_pos
	var previous := fallback_pos - Vector2.RIGHT * 180.0
	if not samples.is_empty():
		recent = Vector2(Dictionary(samples.back()).get("pos", fallback_pos))
		previous = Vector2(Dictionary(samples[maxi(0, samples.size() - 7)]).get("pos", recent))
	var velocity := recent - previous
	var direction := velocity.normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.from_angle(float(int(game.amber_suturer_state.get("cycle", 0)) % 8) * TAU / 8.0)
	var predicted := (recent + velocity * 0.65).clamp(Vector2(70.0, 70.0), game.WORLD_SIZE - Vector2(70.0, 70.0))
	var route_start := _clamp_line_endpoint(previous - direction * 54.0)
	var route_end := _clamp_line_endpoint(predicted + direction * 118.0)
	var segments: Array = []
	_append_valid_segment(segments, route_start, route_end)
	var cross_dir := direction.orthogonal()
	var cross_center := recent.lerp(predicted, 0.58) + direction * 58.0
	_append_valid_segment(segments, _clamp_line_endpoint(cross_center - cross_dir * 150.0), _clamp_line_endpoint(cross_center + cross_dir * 150.0))
	while segments.size() > 1 and not has_safe_route(recent, segments):
		segments.pop_back()
	if not has_safe_route(recent, segments) and not segments.is_empty():
		var first: Dictionary = segments[0]
		var middle := Vector2(first["a"]).lerp(Vector2(first["b"]), 0.5)
		var half := (Vector2(first["b"]) - Vector2(first["a"])).normalized() * MIN_LINE_LENGTH * 0.5
		segments[0] = {"a": _clamp_line_endpoint(middle - half), "b": _clamp_line_endpoint(middle + half)}
	if not has_safe_route(recent, segments):
		return []
	return segments.slice(0, MAX_ACTIVE_SUTURES)


func _append_valid_segment(result: Array, a: Vector2, b: Vector2) -> void:
	var delta := b - a
	var length := delta.length()
	if length < MIN_LINE_LENGTH:
		var direction := delta.normalized() if length > 0.01 else Vector2.RIGHT
		b = _clamp_line_endpoint(a + direction * MIN_LINE_LENGTH)
		length = a.distance_to(b)
	if length > MAX_LINE_LENGTH:
		b = a + delta.normalized() * MAX_LINE_LENGTH
	result.append({"a": a, "b": b})


func _clamp_line_endpoint(point: Vector2) -> Vector2:
	return point.clamp(Vector2(62.0, 62.0), game.WORLD_SIZE - Vector2(62.0, 62.0))


func has_safe_route(origin: Vector2, segments: Array) -> bool:
	if segments.is_empty():
		return true
	const ROUTE_LENGTH := 245.0
	const ROUTE_START := 72.0
	const ROUTE_STEPS := 8
	for ray_index in range(12):
		var direction := Vector2.from_angle(float(ray_index) * TAU / 12.0)
		var safe := true
		for step in range(1, ROUTE_STEPS + 1):
			var distance := lerpf(ROUTE_START, ROUTE_LENGTH, float(step - 1) / float(ROUTE_STEPS - 1))
			var point := (origin + direction * distance).clamp(Vector2(34.0, 34.0), game.WORLD_SIZE - Vector2(34.0, 34.0))
			for segment_value in segments:
				var segment: Dictionary = segment_value
				if _distance_to_segment(point, Vector2(segment["a"]), Vector2(segment["b"])) <= SUTURE_RADIUS + 24.0:
					safe = false
					break
			if not safe:
				break
		if safe:
			return true
	return false


func _spawn_suture_node(pos: Vector2, suture_id: String, endpoint: int, source_enemy: Dictionary) -> Dictionary:
	var previous_count: int = game.enemies.size()
	game._spawn_enemy(NODE_TYPE_ID, pos)
	if game.enemies.size() <= previous_count:
		return {}
	var node: Dictionary = game.enemies.back()
	var owner_hp := float(source_enemy.get("max_hp", 2200.0))
	var hp := maxf(260.0, owner_hp * 0.12)
	node["hp"] = hp
	node["max_hp"] = hp
	node["points"] = 0
	node["damage"] = 0.0
	node["speed"] = 0.0
	node["parado"] = true
	node["skip_rewards"] = true
	node["is_suture_node"] = true
	node["suture_id"] = suture_id
	node["suture_endpoint"] = endpoint
	node["reconstituted_once"] = true
	node["contact_grace"] = 999.0
	return node


func _activate_sutures(enemy: Dictionary) -> void:
	for suture_value in game.amber_sutures:
		var suture: Dictionary = suture_value
		suture["state"] = STATE_ACTIVE
		suture["timer"] = ACTIVE_TIME
		suture["life"] = ACTIVE_TIME
	_set_state(enemy, STATE_ACTIVE, ACTIVE_TIME)
	game._play_sfx("Boss-Impacto.mp3", 0.025, 0.58, 0.92)
	_emit_visual_event("activate", {"pos": Vector2(enemy.get("pos", game.player_pos))})


func _update_active_sutures(delta: float) -> void:
	for suture_value in game.amber_sutures:
		var suture: Dictionary = suture_value
		if String(suture.get("state", "")) != STATE_ACTIVE:
			continue
		suture["timer"] = maxf(0.0, float(suture.get("timer", ACTIVE_TIME)) - delta)
	for target_value in game._combat_targets():
		var target: Dictionary = target_value
		var peer_id := int(target.get("peer_id", 0))
		var gates: Dictionary = game.amber_suturer_state.get("damage_gate_by_peer", {})
		if float(gates.get(str(peer_id), 0.0)) > 0.0:
			continue
		var pos := Vector2(target.get("pos", game.player_pos))
		var touched := false
		for suture_value in game.amber_sutures:
			var suture: Dictionary = suture_value
			if String(suture.get("state", "")) != STATE_ACTIVE:
				continue
			if _distance_to_segment(pos, Vector2(suture.get("a", pos)), Vector2(suture.get("b", pos))) <= SUTURE_RADIUS + 18.0:
				touched = true
				break
		if not touched:
			continue
		var damage := maxi(1, int(ceil(float(target.get("hp_max", game.player_hp_max)) * DAMAGE_MAX_HP_RATIO)))
		if bool(target.get("local", false)):
			game._damage_player(damage, TYPE_ID)
		else:
			game._send_peer_damage(peer_id, damage, TYPE_ID)
		gates[str(peer_id)] = DAMAGE_INTERVAL
		game.amber_suturer_state["damage_gate_by_peer"] = gates


func _update_damage_gates(delta: float) -> void:
	var gates: Dictionary = game.amber_suturer_state.get("damage_gate_by_peer", {})
	for peer_key in gates.keys():
		gates[peer_key] = maxf(0.0, float(gates[peer_key]) - delta)
	game.amber_suturer_state["damage_gate_by_peer"] = gates


func _begin_reposition(enemy: Dictionary) -> void:
	var target := _select_next_target()
	var target_pos: Vector2 = Vector2(target.get("pos", game.player_pos)) if not target.is_empty() else Vector2(game.player_pos)
	var from := Vector2(enemy.get("pos", game.player_pos))
	var direction: Vector2 = (target_pos - from).normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.RIGHT
	enemy["suturer_reposition_dir"] = direction.orthogonal() * (-1.0 if int(game.amber_suturer_state.get("cycle", 0)) % 2 == 0 else 1.0)
	_set_state(enemy, STATE_REPOSITION, REPOSITION_TIME)


func _update_reposition(enemy: Dictionary, delta: float) -> void:
	var direction := Vector2(enemy.get("suturer_reposition_dir", Vector2.RIGHT)).normalized()
	var pos := Vector2(enemy.get("pos", game.player_pos))
	var next_pos := (pos + direction * MOVE_SPEED * 1.28 * delta).clamp(Vector2(86.0, 78.0), game.WORLD_SIZE - Vector2(86.0, 78.0))
	enemy["pos"] = next_pos
	enemy["last_move_dir"] = direction
	if absf(direction.x) > 0.02:
		enemy["facing_dir"] = Vector2(signf(direction.x), 0.0)


func on_enemy_defeated(enemy: Dictionary) -> bool:
	if game == null or not game._is_world_authority():
		return false
	var kind := String(enemy.get("type", ""))
	if kind == NODE_TYPE_ID:
		break_suture(String(enemy.get("suture_id", "")), "node_destroyed")
		if game.enemies.has(enemy):
			game.enemies.erase(enemy)
		return true
	if kind != TYPE_ID:
		return false
	_set_state(enemy, STATE_DYING, 0.8)
	_emit_visual_event("death", {"pos": Vector2(enemy.get("pos", game.player_pos))})
	game._play_sfx("Larapio-Dead.mp3", 0.03, 0.72, 0.72)
	_clear_sutures("owner_defeated")
	_finish_event("defeated")
	return false


func break_suture(suture_id: String, reason: String) -> void:
	if suture_id == "":
		return
	var broken_pos := Vector2.ZERO
	var kept: Array = []
	for suture_value in game.amber_sutures:
		var suture: Dictionary = suture_value
		if String(suture.get("id", "")) == suture_id:
			broken_pos = Vector2(suture.get("a", Vector2.ZERO)).lerp(Vector2(suture.get("b", Vector2.ZERO)), 0.5)
		else:
			kept.append(suture)
	game.amber_sutures = kept
	game.enemies = game.enemies.filter(func(value):
		var candidate: Dictionary = value
		return not (String(candidate.get("type", "")) == NODE_TYPE_ID and String(candidate.get("suture_id", "")) == suture_id)
	)
	_emit_visual_event("break", {"pos": broken_pos, "reason": reason})
	game._play_sfx("Boss-Impacto.mp3", 0.03, 0.42, 1.18)


func cleanup(reason: String, schedule_next: bool = true) -> void:
	if game == null:
		return
	var enemy := active_enemy()
	var pos: Vector2 = Vector2(enemy.get("pos", game.player_pos)) if not enemy.is_empty() else Vector2(game.player_pos)
	if not enemy.is_empty():
		game.enemies.erase(enemy)
	_clear_sutures(reason)
	_finish_event(reason, schedule_next)
	_emit_visual_event("cleanup", {"pos": pos, "reason": reason})


func _finish_event(reason: String, schedule_next: bool = true) -> void:
	var encounter_id := String(game.amber_suturer_state.get("encounter_id", ""))
	game.enemy_bullets = game.enemy_bullets.filter(func(value):
		var bullet: Dictionary = value
		return String(bullet.get("type", "")) != "suturer_needle" or String(bullet.get("suturer_encounter_id", "")) != encounter_id
	)
	game.amber_suturer_state["active"] = false
	game.amber_suturer_state["enemy_uid"] = -1
	game.amber_suturer_state["cleanup_reason"] = reason
	game.amber_suturer_state["last_end_phase_time"] = game._phase_elapsed_time()
	game.amber_suturer_state["damage_gate_by_peer"] = {}
	if schedule_next and game.current_phase == 6:
		game.amber_suturer_state["next_spawn_phase_time"] = game._phase_elapsed_time() + game.rng.randf_range(RESPAWN_MIN_TIME, RESPAWN_MAX_TIME)
	_history_by_peer.clear()


func _clear_sutures(reason: String, emit_event: bool = true) -> void:
	if emit_event and not game.amber_sutures.is_empty():
		_emit_visual_event("dissipate", {"pos": _sutures_center(), "reason": reason})
	game.amber_sutures.clear()
	game.enemies = game.enemies.filter(func(value): return String(Dictionary(value).get("type", "")) != NODE_TYPE_ID)


func _sutures_center() -> Vector2:
	if game.amber_sutures.is_empty():
		return game.player_pos
	var sum := Vector2.ZERO
	for suture_value in game.amber_sutures:
		var suture: Dictionary = suture_value
		sum += Vector2(suture.get("a", Vector2.ZERO)).lerp(Vector2(suture.get("b", Vector2.ZERO)), 0.5)
	return sum / float(game.amber_sutures.size())


func _sample_player_history(delta: float) -> void:
	_history_sample_timer -= delta
	if _history_sample_timer > 0.0:
		return
	_history_sample_timer = HISTORY_SAMPLE_INTERVAL
	var now := float(game._phase_elapsed_time())
	var live_peers: Dictionary = {}
	for target_value in game._combat_targets():
		var target: Dictionary = target_value
		var peer_id := int(target.get("peer_id", 0))
		live_peers[peer_id] = true
		var samples: Array = _history_by_peer.get(peer_id, [])
		samples.append({"time": now, "pos": Vector2(target.get("pos", game.player_pos))})
		while not samples.is_empty() and now - float(Dictionary(samples[0]).get("time", now)) > HISTORY_WINDOW:
			samples.pop_front()
		_history_by_peer[peer_id] = samples
	for peer_key in _history_by_peer.keys():
		if not live_peers.has(int(peer_key)):
			_history_by_peer.erase(peer_key)


func _select_next_target() -> Dictionary:
	var targets: Array = game._combat_targets()
	if targets.is_empty():
		return {}
	_target_cursor = posmod(_target_cursor + 1, targets.size())
	return targets[_target_cursor]


func _target_by_peer(peer_id: int) -> Dictionary:
	for target_value in game._combat_targets():
		var target: Dictionary = target_value
		if int(target.get("peer_id", 0)) == peer_id:
			return target
	return {}


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_sq := ab.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / length_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _next_event_id(kind: String) -> String:
	var sequence := int(game.amber_suturer_state.get("event_sequence", 0)) + 1
	game.amber_suturer_state["event_sequence"] = sequence
	return "%s_%s_%d" % [String(game.amber_suturer_state.get("encounter_id", "suturador")), kind, sequence]


func _emit_visual_event(kind: String, data: Dictionary) -> void:
	var payload := data.duplicate(true)
	payload["kind"] = kind
	payload["age"] = 0.0
	payload["life"] = 0.9 if kind in ["entry", "death", "needle_telegraph"] else 0.55
	payload["max_life"] = payload["life"]
	if not payload.has("event_id"):
		payload["event_id"] = _next_event_id(kind)
	game.amber_suturer_visual_events.append(payload)
	if game.amber_suturer_visual_events.size() > 24:
		game.amber_suturer_visual_events.pop_front()


func _update_visual_events(delta: float) -> void:
	for event_value in game.amber_suturer_visual_events:
		var event: Dictionary = event_value
		event["age"] = float(event.get("age", 0.0)) + delta
		event["life"] = float(event.get("life", 0.0)) - delta
	game.amber_suturer_visual_events = game.amber_suturer_visual_events.filter(func(value): return float(Dictionary(value).get("life", 0.0)) > 0.0)
