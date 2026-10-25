class_name RTBoss4InstabilityFissureController
extends RefCounted

## Authoritative owner for the Boss 4 instability-fissure pattern.
##
## It records recent positions of every living combatant, turns those trails
## into delayed fissures and stores only snapshot-friendly data in the runtime
## hazard list. Damage remains in the runtime combat resolver.

const FIRST_DELAY := 5.5
const BASE_COOLDOWN := 12.0
const MIN_COOLDOWN := 8.5
const HISTORY_SAMPLE_INTERVAL := 0.16
const HISTORY_LIMIT := 24
const HISTORY_LOOKBACK_SAMPLES := 6
const TARGET_GRACE := 4.2
const WARNING_TIME := 1.05
const ACTIVE_TIME := 0.65
const DISSIPATE_TIME := 0.45
const BASE_FISSURE_COUNT := 2
const FISSURE_HALF_LENGTH := 172.0
const FISSURE_WIDTH := 28.0
const DIRECT_CLEARANCE := 96.0
const SAFE_CORRIDOR_BASE_WIDTH := 72.0
const SAFE_MARGIN := Vector2(84.0, 82.0)

var _game: Node
var _cooldown := FIRST_DELAY
var _sample_timer := 0.0
var _sequence := 0
var _last_target_peer_id := 0
var _target_grace: Dictionary = {}
var _history_by_peer: Dictionary = {}


func configure(game: Node) -> void:
	_game = game
	reset()


func reset() -> void:
	_cooldown = FIRST_DELAY
	_sample_timer = 0.0
	_sequence = 0
	_last_target_peer_id = 0
	_target_grace.clear()
	_history_by_peer.clear()


func update(delta: float, authority: bool, allow_autocast: bool = true) -> void:
	if _game == null or not is_instance_valid(_game):
		return
	_target_grace = _game.shared_boss_attack_contract.tick_target_grace(_target_grace, delta)
	if authority:
		_sample_recent_positions(delta)
	if not authority or not allow_autocast or not _can_cast():
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0 or _has_live_fissure_event():
		return
	cast_now()
	_cooldown = _game._boss_party_scaled_interval(BASE_COOLDOWN, MIN_COOLDOWN)


func cast_now() -> int:
	if _game == null or not is_instance_valid(_game):
		return 0
	var targets: Array = _game._combat_targets()
	if targets.is_empty():
		return 0
	_game._ensure_boss_party_scaling_context(4)
	var count: int = BASE_FISSURE_COUNT + int(_game._boss_party_hazard_bonus(2))
	var safe_corridor := _build_safe_corridor(targets)
	var event_seed := int(_game.rng.randi())
	var started_ms := int(Time.get_ticks_msec())
	var base_event: Dictionary = _game.shared_boss_attack_contract.make_authoritative_event(
		"b4_fissures", _sequence, event_seed, 0, started_ms
	)
	var event_id := String(base_event.get("event_id", "b4_fissures_%d" % _sequence))
	var event_grace := _target_grace.duplicate()
	var previous_peer := _last_target_peer_id
	var spawned := 0
	for index in range(count):
		var chosen: Dictionary = _game.shared_boss_attack_contract.select_target(targets, event_grace, previous_peer, _sequence + index)
		if chosen.is_empty():
			event_grace.clear()
			chosen = _game.shared_boss_attack_contract.select_target(targets, event_grace, previous_peer, _sequence + index)
		if chosen.is_empty():
			break
		var peer_id := int(chosen.get("peer_id", 0))
		var target_pos := Vector2(chosen.get("pos", _game.player_pos))
		var segment := _segment_from_recent_path(peer_id, target_pos, event_seed + index * 7919)
		var stagger := _stagger_for_party() * float(index)
		var duration := WARNING_TIME + ACTIVE_TIME + DISSIPATE_TIME + stagger
		var fissure_event := base_event.duplicate(true)
		fissure_event["event_id"] = "%s_%d" % [event_id, index]
		fissure_event["target_peer"] = peer_id
		var hazard: Dictionary = _game.shared_boss_attack_contract.build_telegraphed_attack("boss4_fissure", fissure_event, {
			"group_event_id": event_id,
			"started_ms": started_ms,
			"a": segment[0],
			"b": segment[1],
			"age": -stagger,
			"delay": stagger,
			"life": duration,
			"max": duration,
			"warning": WARNING_TIME,
			"active_duration": ACTIVE_TIME,
			"dissipate_duration": DISSIPATE_TIME,
			"width": FISSURE_WIDTH,
			"safe_a": safe_corridor[0],
			"safe_b": safe_corridor[1],
			"safe_width": _safe_corridor_width(),
			"fissure_index": index,
			"fissure_count": count,
			"teleport": posmod(event_seed + index * 17, 100) < 48,
			"source": "boss4_instability_fissure"
		})
		_game._add_phase4_hazard(hazard)
		_game.shared_boss_attack_contract.claim_target_grace(event_grace, peer_id, TARGET_GRACE)
		_game.shared_boss_attack_contract.claim_target_grace(_target_grace, peer_id, TARGET_GRACE)
		previous_peer = peer_id
		spawned += 1
	_last_target_peer_id = previous_peer
	_sequence += 1
	if spawned > 0:
		_game.boss4_attack_pose_timer = maxf(_game.boss4_attack_pose_timer, WARNING_TIME)
		_game._add_text("FENDAS DE INSTABILIDADE", _game.boss_pos + Vector2(0.0, -154.0), Color(0.86, 0.42, 1.0), 1.0, 20)
	return spawned


func force_cast_for_test() -> int:
	_sample_recent_positions(HISTORY_SAMPLE_INTERVAL)
	return cast_now()


func cooldown_remaining() -> float:
	return _cooldown


func resolve_hazard(hazard: Dictionary) -> void:
	var age := float(hazard.get("age", 0.0))
	var warning := float(hazard.get("warning", _game.PHASE4_RIFT_WARNING))
	var active_duration := float(hazard.get("active_duration", _game.PHASE4_RIFT_ACTIVE_TIME))
	if age < warning or age > warning + active_duration:
		return
	var a := Vector2(hazard.get("a", Vector2.ZERO))
	var b := Vector2(hazard.get("b", Vector2.ZERO))
	var width := float(hazard.get("width", FISSURE_WIDTH))
	var damage := int(_game.player_hp_max * 0.075 + 34.0)
	if _game.shared_boss_attack_contract.claim_impact(hazard):
		hazard["triggered"] = true
		_game._spawn_radial_particles(a.lerp(b, 0.5), Color(0.5, 0.92, 1.0), 7 if _game.gfx_low_resource else 12)
		if int(hazard.get("fissure_index", 0)) == 0:
			_game._play_sfx("Projetil.mp3", 0.02, 0.58, 0.72)
	_game._damage_remnants_on_segment_once(a, b, width, float(damage) * 0.75, "fenda_boss4", hazard, "remnants")
	var local_peer_id := maxi(1, int(_game._mp_unique_id()))
	if _game._local_player_damageable_by_contact() \
		and not _inside_safe_corridor(_game.player_pos, hazard) \
		and float(_game._distance_to_segment(_game.player_pos, a, b)) <= width \
		and _game.shared_boss_attack_contract.claim_peer_hit(hazard, local_peer_id):
		if bool(hazard.get("teleport", false)):
			_game.player_pos = _game._safe_random_world_point_near(_game.player_pos, 240.0)
			_game._add_text("RASGO ESPACIAL", _game.player_pos + Vector2(0, -78), Color(1.0, 0.42, 0.94), 0.75, 18)
		_game._damage_player(damage, "fenda_boss4")
		_game._increase_boss4_instability(4.0)
	if not _game._remote_player_damage_ready():
		return
	for peer_id in _game._targetable_remote_peer_ids():
		var state: Dictionary = _game.net_players_by_peer.get(peer_id, {})
		var remote_pos := Vector2(state.get("pos", _game.net_player_pos))
		if _inside_safe_corridor(remote_pos, hazard):
			continue
		if float(_game._distance_to_segment(remote_pos, a, b)) > width:
			continue
		if not _game.shared_boss_attack_contract.claim_peer_hit(hazard, int(peer_id)):
			continue
		_game._send_peer_damage(int(peer_id), damage, "fenda_boss4")
		_game._increase_boss4_instability(2.0)


func _can_cast() -> bool:
	return int(_game.current_phase) == 4 \
		and bool(_game.boss_active) \
		and not bool(_game.boss_dead) \
		and float(_game.boss_hp) > 0.0 \
		and float(_game.boss_entry_timer) <= 0.0 \
		and not bool(_game.boss4_ultimate_active) \
		and float(_game.boss4_stun_timer) <= 0.0


func _has_live_fissure_event() -> bool:
	for value in _game.phase4_enemy_hazards:
		var hazard := Dictionary(value)
		if String(hazard.get("source", "")) == "boss4_instability_fissure" and float(hazard.get("life", 0.0)) > 0.0:
			return true
	return false


func _sample_recent_positions(delta: float) -> void:
	_sample_timer -= maxf(0.0, delta)
	if _sample_timer > 0.0:
		return
	_sample_timer = HISTORY_SAMPLE_INTERVAL
	var living: Dictionary = {}
	for value in _game._combat_targets():
		var target := Dictionary(value)
		var peer_id := int(target.get("peer_id", 0))
		if peer_id <= 0:
			continue
		living[peer_id] = true
		var history: Array = Array(_history_by_peer.get(peer_id, []))
		history.append(Vector2(target.get("pos", Vector2.ZERO)))
		while history.size() > HISTORY_LIMIT:
			history.pop_front()
		_history_by_peer[peer_id] = history
	for peer_key in _history_by_peer.keys():
		if not living.has(int(peer_key)):
			_history_by_peer.erase(peer_key)


func _segment_from_recent_path(peer_id: int, current_pos: Vector2, local_seed: int) -> Array:
	var history: Array = Array(_history_by_peer.get(peer_id, []))
	var recent := current_pos
	var older := current_pos
	if not history.is_empty():
		recent = Vector2(history.back())
		older = Vector2(history[maxi(0, history.size() - 1 - HISTORY_LOOKBACK_SAMPLES)])
	var travel := recent - older
	if travel.length() < 18.0:
		travel = current_pos - Vector2(_game.boss_pos)
	if travel.length() < 0.01:
		travel = Vector2.RIGHT.rotated(float(posmod(local_seed, 6283)) / 1000.0)
	var direction := travel.normalized()
	var center := older.lerp(recent, 0.45)
	var a := center - direction * FISSURE_HALF_LENGTH
	var b := center + direction * FISSURE_HALF_LENGTH
	var distance_now: float = float(_game._distance_to_segment(current_pos, a, b))
	if distance_now < DIRECT_CLEARANCE:
		var side := direction.orthogonal()
		if posmod(local_seed, 2) == 0:
			side = -side
		var shift: Vector2 = side * (DIRECT_CLEARANCE - distance_now + FISSURE_WIDTH)
		a += shift
		b += shift
	a = a.clamp(SAFE_MARGIN, _game.WORLD_SIZE - SAFE_MARGIN)
	b = b.clamp(SAFE_MARGIN, _game.WORLD_SIZE - SAFE_MARGIN)
	if float(_game._distance_to_segment(current_pos, a, b)) < DIRECT_CLEARANCE:
		var room := [
			{"normal": Vector2.RIGHT, "distance": _game.WORLD_SIZE.x - SAFE_MARGIN.x - current_pos.x},
			{"normal": Vector2.LEFT, "distance": current_pos.x - SAFE_MARGIN.x},
			{"normal": Vector2.DOWN, "distance": _game.WORLD_SIZE.y - SAFE_MARGIN.y - current_pos.y},
			{"normal": Vector2.UP, "distance": current_pos.y - SAFE_MARGIN.y}
		]
		room.sort_custom(func(first, second): return float(Dictionary(first).get("distance", 0.0)) > float(Dictionary(second).get("distance", 0.0)))
		var normal := Vector2(Dictionary(room.front()).get("normal", Vector2.RIGHT))
		var available := float(Dictionary(room.front()).get("distance", DIRECT_CLEARANCE + FISSURE_WIDTH + 24.0))
		var offset := minf(DIRECT_CLEARANCE + FISSURE_WIDTH + 24.0, available - 4.0)
		var fallback_center := current_pos + normal * maxf(DIRECT_CLEARANCE + 2.0, offset)
		var fallback_direction := normal.orthogonal()
		a = (fallback_center - fallback_direction * FISSURE_HALF_LENGTH).clamp(SAFE_MARGIN, _game.WORLD_SIZE - SAFE_MARGIN)
		b = (fallback_center + fallback_direction * FISSURE_HALF_LENGTH).clamp(SAFE_MARGIN, _game.WORLD_SIZE - SAFE_MARGIN)
	if a.distance_to(b) < 90.0:
		b = (a + direction * 140.0).clamp(SAFE_MARGIN, _game.WORLD_SIZE - SAFE_MARGIN)
	return [a, b]


func _build_safe_corridor(targets: Array) -> Array:
	var center := Vector2.ZERO
	for value in targets:
		center += Vector2(Dictionary(value).get("pos", _game.WORLD_SIZE * 0.5))
	center /= maxf(1.0, float(targets.size()))
	var direction := Vector2.RIGHT
	if targets.size() >= 2:
		var first := Vector2(Dictionary(targets.front()).get("pos", center))
		var farthest := first
		for value in targets:
			var candidate := Vector2(Dictionary(value).get("pos", center))
			if candidate.distance_squared_to(first) > farthest.distance_squared_to(first):
				farthest = candidate
		if first.distance_to(farthest) > 36.0:
			direction = (farthest - first).normalized()
	else:
		var peer_id := int(Dictionary(targets.front()).get("peer_id", 0))
		var history: Array = Array(_history_by_peer.get(peer_id, []))
		if history.size() >= 2:
			var motion := Vector2(history.back()) - Vector2(history.front())
			if motion.length() > 12.0:
				direction = motion.normalized()
	var half_length := maxf(_game.WORLD_SIZE.x, _game.WORLD_SIZE.y)
	return [
		(center - direction * half_length).clamp(SAFE_MARGIN, _game.WORLD_SIZE - SAFE_MARGIN),
		(center + direction * half_length).clamp(SAFE_MARGIN, _game.WORLD_SIZE - SAFE_MARGIN)
	]


func _safe_corridor_width() -> float:
	return SAFE_CORRIDOR_BASE_WIDTH + float(_game._boss_party_hazard_bonus(2)) * 12.0


func _stagger_for_party() -> float:
	var party_size := clampi(int(_game.boss_party_scaling_size), 1, 3)
	return 0.22 if party_size == 1 else (0.18 if party_size == 2 else 0.14)


func _inside_safe_corridor(pos: Vector2, hazard: Dictionary) -> bool:
	if not hazard.has("safe_a") or not hazard.has("safe_b"):
		return false
	return float(_game._distance_to_segment(pos, Vector2(hazard["safe_a"]), Vector2(hazard["safe_b"]))) <= float(hazard.get("safe_width", SAFE_CORRIDOR_BASE_WIDTH))
