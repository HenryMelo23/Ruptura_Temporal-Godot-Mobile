class_name RTPhase4InstabilityPulseController
extends Node

## Authoritative physical objective for normal Phase 4. This state is separate
## from boss4_instability; presentation and replicas consume snapshots only.

const SCHEMA_VERSION: int = 1
const FIRST_START_PHASE_TIME: float = 120.0
const CADENCE_SECONDS: float = 120.0
const PULSE_DURATION: float = 24.0
const FRAGMENT_COUNT: int = 3
const FRAGMENT_SAFE_MARGIN: Vector2 = Vector2(105.0, 100.0)
const FRAGMENT_COLLECTION_RADIUS: float = 46.0
const FRAGMENT_MOVE_SPEED: float = 44.0
const FRAGMENT_TURN_RATE: float = 0.58
const INITIAL_INSTABILITY: float = 75.0
const INSTABILITY_REDUCTION_PER_FRAGMENT: float = 25.0
const FAILURE_INSTABILITY_INCREASE: float = 25.0
const REWARD_POINTS: int = 240
const SUCCESS_TEMPORAL_BONUS_DURATION: float = 8.0
const SUCCESS_TEMPORAL_MOVE_MULTIPLIER: float = 1.08
const FAILURE_PRESSURE_DURATION: float = 6.0
const RESULT_DISPLAY_TIME: float = 1.5

var game: Node = null
var _active: Dictionary = {}
var _next_start_phase_time: float = FIRST_START_PHASE_TIME
var _sequence: int = 0
var _rewarded_events: Dictionary = {}
var _temporal_bonus_remaining: float = 0.0
var _remote_feedback_stage_by_event: Dictionary = {}
var _remote_collected_by_event: Dictionary = {}


func bind_game(runtime: Node) -> void:
	game = runtime


func reset() -> void:
	_active.clear()
	_next_start_phase_time = FIRST_START_PHASE_TIME
	_sequence = 0
	_rewarded_events.clear()
	_temporal_bonus_remaining = 0.0
	_remote_feedback_stage_by_event.clear()
	_remote_collected_by_event.clear()


func cleanup(_reason: String) -> void:
	_active.clear()
	_temporal_bonus_remaining = 0.0


func is_active() -> bool:
	return not _active.is_empty() and bool(_active.get("active", false))


func player_move_speed_multiplier() -> float:
	return SUCCESS_TEMPORAL_MOVE_MULTIPLIER if _temporal_bonus_remaining > 0.0 else 1.0


func update(delta: float, authority: bool) -> void:
	if game == null or delta <= 0.0:
		return
	if int(game.current_phase) != 4:
		if authority and (is_active() or _temporal_bonus_remaining > 0.0):
			cleanup("phase_changed")
		return
	if not authority:
		return
	_temporal_bonus_remaining = maxf(0.0, _temporal_bonus_remaining - delta)
	if is_active() and (bool(game.boss_active) or float(game.boss_call_timer) >= 0.0 or String(game.mode) not in ["game", "shop", "settings"]):
		cleanup("incompatible_state")
		return
	if is_active() and game._combat_targets().is_empty():
		cleanup("no_living_players")
		return
	if not is_active():
		_try_start_from_cadence()
		return
	if String(_active.get("state", "pulse")) == "result":
		_active["result_remaining"] = maxf(0.0, float(_active.get("result_remaining", 0.0)) - delta)
		_active["temporal_bonus_remaining"] = _temporal_bonus_remaining
		if float(_active.get("result_remaining", 0.0)) <= 0.0:
			_active.clear()
			_next_start_phase_time = float(game._phase_elapsed_time()) + CADENCE_SECONDS
		return

	_active["remaining"] = maxf(0.0, float(_active.get("remaining", PULSE_DURATION)) - delta)
	_update_fragments(delta)
	_collect_overlapping_fragments()
	if _collected_count() >= FRAGMENT_COUNT:
		_finish_success()
	elif float(_active.get("remaining", 0.0)) <= 0.0:
		_finish_failure()


func force_start_for_test() -> bool:
	if game == null or not game._is_world_authority():
		return false
	return _start_pulse()


func active_snapshot() -> Dictionary:
	if not is_active():
		return {
			"schema_version": SCHEMA_VERSION,
			"active": false,
			"next_start_phase_time": snappedf(_next_start_phase_time, 0.1),
			"temporal_bonus_remaining": snappedf(_temporal_bonus_remaining, 0.1)
		}
	var snapshot: Dictionary = _active.duplicate(true)
	snapshot["schema_version"] = SCHEMA_VERSION
	snapshot["collected_count"] = _collected_count()
	snapshot["fragment_count"] = FRAGMENT_COUNT
	snapshot["pulse_instability"] = snappedf(float(_active.get("pulse_instability", INITIAL_INSTABILITY)), 0.1)
	snapshot["temporal_bonus_remaining"] = snappedf(_temporal_bonus_remaining, 0.1)
	return snapshot


func apply_remote_snapshot(snapshot: Dictionary) -> void:
	if int(snapshot.get("schema_version", SCHEMA_VERSION)) != SCHEMA_VERSION:
		cleanup("schema_mismatch")
		return
	_temporal_bonus_remaining = maxf(0.0, float(snapshot.get("temporal_bonus_remaining", 0.0)))
	if not bool(snapshot.get("active", false)):
		_active.clear()
		return
	var event_id: String = String(snapshot.get("event_id", ""))
	var previous_collected: int = int(_remote_collected_by_event.get(event_id, 0))
	var collected: int = int(snapshot.get("collected_count", 0))
	var previous_stage: String = String(_remote_feedback_stage_by_event.get(event_id, ""))
	var stage: String = String(snapshot.get("result", "active"))
	_active = snapshot.duplicate(true)
	if not event_id.is_empty() and collected > previous_collected:
		_remote_collected_by_event[event_id] = collected
		game._add_text("FRAGMENTO ESTABILIZADO  %d/%d" % [collected, FRAGMENT_COUNT], game.player_pos + Vector2(0, -104), Color(0.4, 1.0, 0.92), 0.9, 19)
		game._play_sfx("Portal.mp3", 0.018, 0.28, 1.32)
	if event_id.is_empty() or previous_stage == stage:
		return
	_remote_feedback_stage_by_event[event_id] = stage
	if stage == "active":
		game._play_sfx("Portal.mp3", 0.025, 0.34, 0.92)
	elif stage == "success":
		game._add_text("LINHA ESTABILIZADA", game.player_pos + Vector2(0, -112), Color(0.48, 1.0, 0.92), 1.25, 22)
		game._play_sfx("boss_impact", 0.018, 0.34, 1.24)
	elif stage == "failure":
		game._add_text("LINHA ROMPIDA", game.player_pos + Vector2(0, -112), Color(1.0, 0.36, 0.78), 1.25, 22)
		game._play_sfx("boss_impact", 0.024, 0.46, 0.78)


func _try_start_from_cadence() -> void:
	if String(game.mode) != "game" or bool(game.boss_active) or float(game.boss_call_timer) >= 0.0:
		return
	if float(game._phase_elapsed_time()) < _next_start_phase_time:
		return
	_start_pulse()


func _start_pulse() -> bool:
	if int(game.current_phase) != 4 or bool(game.boss_active) or float(game.boss_call_timer) >= 0.0 or is_active():
		return false
	if game._combat_targets().is_empty():
		return false
	_sequence += 1
	var started_ms: int = Time.get_ticks_msec()
	var event_id: String = "phase4_instability_%d_%d" % [_sequence, started_ms]
	_active = {
		"schema_version": SCHEMA_VERSION,
		"active": true,
		"event_id": event_id,
		"seed": game.rng.randi(),
		"sequence": _sequence,
		"started_ms": started_ms,
		"started_at": snappedf(float(game._phase_elapsed_time()), 0.1),
		"state": "pulse",
		"result": "active",
		"duration": PULSE_DURATION,
		"remaining": PULSE_DURATION,
		"pulse_instability": INITIAL_INSTABILITY,
		"fragments": _build_fragments()
	}
	game._add_text("PULSO DE INSTABILIDADE", game.player_pos + Vector2(0, -112), Color(0.58, 0.94, 1.0), 1.35, 23)
	game._play_sfx("Portal.mp3", 0.025, 0.34, 0.92)
	for value in Array(_active.get("fragments", [])):
		game._spawn_radial_particles(Vector2(Dictionary(value).get("pos", game.player_pos)), Color(0.42, 0.92, 1.0), 9)
	_record_telemetry("started", {"duration": PULSE_DURATION})
	return true


func _build_fragments() -> Array:
	var anchor: Vector2 = _living_players_center()
	var start_angle: float = game.rng.randf_range(0.0, TAU)
	var fragments: Array = []
	for index in range(FRAGMENT_COUNT):
		var angle: float = start_angle + TAU * float(index) / float(FRAGMENT_COUNT) + game.rng.randf_range(-0.16, 0.16)
		var distance: float = game.rng.randf_range(180.0, 255.0)
		var position: Vector2 = (anchor + Vector2.from_angle(angle) * distance).clamp(FRAGMENT_SAFE_MARGIN, game.WORLD_SIZE - FRAGMENT_SAFE_MARGIN)
		var move_angle: float = angle + PI * 0.5 + game.rng.randf_range(-0.55, 0.55)
		fragments.append({
			"id": index,
			"pos": position,
			"velocity": Vector2.from_angle(move_angle) * FRAGMENT_MOVE_SPEED,
			"phase": game.rng.randf_range(0.0, TAU),
			"turn_bias": game.rng.randf_range(-1.0, 1.0),
			"collected": false,
			"collector_peer_id": 0
		})
	return fragments


func _update_fragments(delta: float) -> void:
	var fragments: Array = Array(_active.get("fragments", []))
	for index in range(fragments.size()):
		var fragment: Dictionary = Dictionary(fragments[index])
		if bool(fragment.get("collected", false)):
			continue
		var phase: float = float(fragment.get("phase", 0.0)) + delta
		var velocity: Vector2 = Vector2(fragment.get("velocity", Vector2.RIGHT * FRAGMENT_MOVE_SPEED))
		if velocity.length_squared() <= 0.01:
			velocity = Vector2.RIGHT * FRAGMENT_MOVE_SPEED
		var turn: float = (sin(phase * 1.75 + float(index) * 1.9) * 0.72 + float(fragment.get("turn_bias", 0.0)) * 0.28) * FRAGMENT_TURN_RATE * delta
		velocity = velocity.rotated(turn).normalized() * FRAGMENT_MOVE_SPEED
		var position: Vector2 = Vector2(fragment.get("pos", game.WORLD_SIZE * 0.5)) + velocity * delta
		var max_pos: Vector2 = game.WORLD_SIZE - FRAGMENT_SAFE_MARGIN
		if position.x <= FRAGMENT_SAFE_MARGIN.x or position.x >= max_pos.x:
			velocity.x = -velocity.x
		if position.y <= FRAGMENT_SAFE_MARGIN.y or position.y >= max_pos.y:
			velocity.y = -velocity.y
		fragment["pos"] = position.clamp(FRAGMENT_SAFE_MARGIN, max_pos)
		fragment["velocity"] = velocity
		fragment["phase"] = phase
		fragments[index] = fragment
	_active["fragments"] = fragments


func _collect_overlapping_fragments() -> void:
	var targets: Array = game._combat_targets()
	if targets.is_empty():
		return
	var fragments: Array = Array(_active.get("fragments", []))
	for index in range(fragments.size()):
		var fragment: Dictionary = Dictionary(fragments[index])
		if bool(fragment.get("collected", false)):
			continue
		var fragment_pos: Vector2 = Vector2(fragment.get("pos", Vector2.ZERO))
		for target_value in targets:
			var target: Dictionary = Dictionary(target_value)
			if fragment_pos.distance_to(Vector2(target.get("pos", Vector2.ZERO))) > FRAGMENT_COLLECTION_RADIUS:
				continue
			fragment["collected"] = true
			fragment["collector_peer_id"] = int(target.get("peer_id", 0))
			fragments[index] = fragment
			_active["fragments"] = fragments
			_active["pulse_instability"] = maxf(0.0, float(_active.get("pulse_instability", INITIAL_INSTABILITY)) - INSTABILITY_REDUCTION_PER_FRAGMENT)
			var collected: int = _collected_count()
			game._add_text("FRAGMENTO ESTABILIZADO  %d/%d" % [collected, FRAGMENT_COUNT], fragment_pos + Vector2(0, -52), Color(0.42, 1.0, 0.94), 0.9, 18)
			game._spawn_radial_particles(fragment_pos, Color(0.4, 1.0, 0.92), 13)
			game._play_sfx("Portal.mp3", 0.018, 0.28, 1.32)
			_record_telemetry("fragment_collected", {"collector_peer_id": int(target.get("peer_id", 0)), "collected": collected})
			break


func _collected_count() -> int:
	var count: int = 0
	for value in Array(_active.get("fragments", [])):
		if bool(Dictionary(value).get("collected", false)):
			count += 1
	return count


func _living_players_center() -> Vector2:
	var targets: Array = game._combat_targets()
	if targets.is_empty():
		return Vector2(game.player_pos)
	var sum: Vector2 = Vector2.ZERO
	for value in targets:
		sum += Vector2(Dictionary(value).get("pos", game.player_pos))
	return (sum / float(targets.size())).clamp(Vector2(300.0, 220.0), game.WORLD_SIZE - Vector2(300.0, 220.0))


func _finish_success() -> void:
	if String(_active.get("state", "")) != "pulse":
		return
	var event_id: String = String(_active.get("event_id", ""))
	if not _rewarded_events.has(event_id):
		_rewarded_events[event_id] = true
		game._apply_score_delta(REWARD_POINTS, true, event_id + ":reward")
	_temporal_bonus_remaining = SUCCESS_TEMPORAL_BONUS_DURATION
	_active["state"] = "result"
	_active["result"] = "success"
	_active["reward"] = REWARD_POINTS
	_active["pulse_instability"] = 0.0
	_active["temporal_bonus_remaining"] = _temporal_bonus_remaining
	_active["result_remaining"] = RESULT_DISPLAY_TIME
	game._add_text("LINHA ESTABILIZADA  +%d" % REWARD_POINTS, game.player_pos + Vector2(0, -112), Color(0.48, 1.0, 0.92), 1.35, 23)
	game._spawn_radial_particles(game.player_pos, Color(0.38, 1.0, 0.94), 17)
	game._play_sfx("boss_impact", 0.018, 0.34, 1.24)
	_record_telemetry("success", {"reward": REWARD_POINTS, "bonus_duration": SUCCESS_TEMPORAL_BONUS_DURATION})


func _finish_failure() -> void:
	if String(_active.get("state", "")) != "pulse":
		return
	_active["pulse_instability"] = minf(100.0, float(_active.get("pulse_instability", INITIAL_INSTABILITY)) + FAILURE_INSTABILITY_INCREASE)
	_spawn_failure_pressure()
	_active["state"] = "result"
	_active["result"] = "failure"
	_active["result_remaining"] = RESULT_DISPLAY_TIME
	game._add_text("LINHA ROMPIDA: NEXO INSTAVEL", game.player_pos + Vector2(0, -112), Color(1.0, 0.36, 0.78), 1.4, 22)
	game._play_sfx("boss_impact", 0.024, 0.46, 0.78)
	_record_telemetry("failure", {"collected": _collected_count(), "pressure_duration": FAILURE_PRESSURE_DURATION})


func _spawn_failure_pressure() -> void:
	var center: Vector2 = _living_players_center()
	var spin: float = -1.0 if int(_active.get("seed", 0)) % 2 == 0 else 1.0
	game._add_phase4_hazard({
		"kind": "vector", "pos": center, "age": 0.0, "life": FAILURE_PRESSURE_DURATION,
		"max": FAILURE_PRESSURE_DURATION, "radius": 275.0, "spin": spin,
		"source": "phase4_instability_pulse"
	})
	for index in range(2):
		var angle: float = float(_active.get("seed", 0) % 628) * 0.01 + float(index) * PI * 0.5
		var direction: Vector2 = Vector2.from_angle(angle)
		var half_length: float = 520.0
		game._add_phase4_hazard({
			"kind": "rift", "a": (center - direction * half_length).clamp(Vector2(70.0, 70.0), game.WORLD_SIZE - Vector2(70.0, 70.0)),
			"b": (center + direction * half_length).clamp(Vector2(70.0, 70.0), game.WORLD_SIZE - Vector2(70.0, 70.0)),
			"age": 0.0, "life": FAILURE_PRESSURE_DURATION, "max": FAILURE_PRESSURE_DURATION,
			"warning": maxf(0.85, float(game.PHASE4_RIFT_WARNING)), "triggered": false,
			"phase": float(index), "source": "phase4_instability_pulse"
		})


func _record_telemetry(result: String, extra: Dictionary) -> void:
	if game == null:
		return
	var telemetry: Node = game.get_node_or_null("/root/TelemetrySystem")
	if telemetry == null or not telemetry.has_method("record_runtime_event"):
		return
	var event: Dictionary = {
		"type": "phase4_instability_pulse",
		"sequence": _sequence,
		"started_at": float(_active.get("started_at", game._phase_elapsed_time())),
		"duration": PULSE_DURATION,
		"end_reason": result,
		"context": game.runtime_event_director.context_from_game(game)
	}
	event.merge(extra, true)
	telemetry.record_runtime_event("phase4_instability_pulse", event, game.runtime_event_director.context_from_game(game))
