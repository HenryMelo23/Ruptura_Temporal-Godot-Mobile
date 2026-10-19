class_name RTPhase3RitualPulseController
extends Node

## Temporary physical objective for Phase 3. Gameplay state is authoritative
## here; presentation consumes immutable snapshots from the world-visual packet.

const SCHEMA_VERSION: int = 1
const FIRST_START_PHASE_TIME: float = 135.0
const CADENCE_SECONDS: float = 150.0
const RITUAL_DURATION: float = 20.0
const CHANNEL_DURATION: float = 7.5
const CHANNEL_RADIUS: float = 54.0
const CIRCLE_RADIUS: float = 70.0
const PROGRESS_DECAY_PER_SECOND: float = 0.08
const REWARD_POINTS_PER_CIRCLE: int = 90
const FAILURE_MIASMA_RADIUS: float = 82.0
const FAILURE_MIASMA_DURATION: float = 7.0
const FAILURE_MIASMA_DAMAGE_RATIO: float = 0.01
const RESULT_DISPLAY_TIME: float = 1.35

var game: Node = null
var _active: Dictionary = {}
var _next_start_phase_time: float = FIRST_START_PHASE_TIME
var _sequence: int = 0
var _rewarded_events: Dictionary = {}
var _remote_feedback_stage_by_event: Dictionary = {}


func bind_game(owner: Node) -> void:
	game = owner


func reset() -> void:
	_unmark_all_devotees()
	_active.clear()
	_next_start_phase_time = FIRST_START_PHASE_TIME
	_sequence = 0
	_rewarded_events.clear()
	_remote_feedback_stage_by_event.clear()


func cleanup(_reason: String) -> void:
	_unmark_all_devotees()
	_active.clear()


func is_active() -> bool:
	return not _active.is_empty() and bool(_active.get("active", false))


func update(delta: float, authority: bool) -> void:
	if game == null or delta <= 0.0:
		return
	if int(game.current_phase) != 3:
		if authority and is_active():
			cleanup("phase_changed")
		return
	if not authority:
		return
	if is_active() and (bool(game.boss_active) or float(game.boss_call_timer) >= 0.0 or String(game.mode) not in ["game", "shop", "settings"]):
		cleanup("incompatible_state")
		return
	if is_active() and game._combat_targets().is_empty():
		cleanup("no_living_players")
		return
	if not is_active():
		_try_start_from_cadence()
		return
	if String(_active.get("state", "ritual")) == "result":
		_active["result_remaining"] = maxf(0.0, float(_active.get("result_remaining", 0.0)) - delta)
		if float(_active.get("result_remaining", 0.0)) <= 0.0:
			_active.clear()
			_next_start_phase_time = float(game._phase_elapsed_time()) + CADENCE_SECONDS
		return

	_active["remaining"] = maxf(0.0, float(_active.get("remaining", RITUAL_DURATION)) - delta)
	_refresh_missing_devotees()
	if _all_circles_disrupted():
		_finish_success("all_devotees_defeated")
	elif _all_circles_completed():
		_finish_failure()
	elif float(_active.get("remaining", 0.0)) <= 0.0:
		_finish_success("ritual_timeout")


func force_start_for_test() -> bool:
	if game == null or not game._is_world_authority():
		return false
	return _start_ritual()


func update_devotee(enemy: Dictionary, delta: float) -> bool:
	if game == null or not game._is_world_authority() or not is_active():
		return false
	if String(_active.get("state", "")) != "ritual":
		return false
	if String(enemy.get("phase3_ritual_event_id", "")) != String(_active.get("event_id", "")):
		return false
	var circle_id: int = int(enemy.get("phase3_ritual_circle_id", -1))
	var circles: Array = Array(_active.get("circles", []))
	var circle_index: int = _circle_index(circles, circle_id)
	if circle_index < 0:
		_clear_devotee_mark(enemy)
		return false
	var circle: Dictionary = Dictionary(circles[circle_index])
	if bool(circle.get("disrupted", false)):
		_clear_devotee_mark(enemy)
		return false

	enemy["parado"] = true
	enemy["state"] = "ritual_move"
	var position: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
	var destination: Vector2 = Vector2(circle.get("pos", position))
	var distance: float = position.distance_to(destination)
	var stunned: bool = float(enemy.get("stun", 0.0)) > 0.0
	var rooted: bool = float(enemy.get("ferrolho_root", 0.0)) > 0.0
	var channeling: bool = distance <= CHANNEL_RADIUS and not stunned
	if channeling:
		enemy["state"] = "ritual_channel"
		circle["occupied"] = true
		circle["progress"] = minf(1.0, float(circle.get("progress", 0.0)) + delta / CHANNEL_DURATION)
	else:
		circle["occupied"] = false
		circle["progress"] = maxf(0.0, float(circle.get("progress", 0.0)) - delta * PROGRESS_DECAY_PER_SECOND)
		if not stunned and not rooted and distance > 1.0:
			var direction: Vector2 = (destination - position).normalized()
			direction = game._steer_entity_with_avoidance(enemy, position, direction, delta)
			var ritual_speed: float = float(enemy.get("speed", 100.0)) * 0.82
			enemy["pos"] = (position + direction * ritual_speed * delta).clamp(Vector2(40.0, 40.0), game.WORLD_SIZE - Vector2(40.0, 40.0))
			enemy["last_move_dir"] = direction
			enemy["facing_dir"] = direction
	circles[circle_index] = circle
	_active["circles"] = circles
	return true


func on_enemy_defeated(enemy: Dictionary) -> void:
	if not is_active() or String(_active.get("state", "")) != "ritual":
		return
	if String(enemy.get("phase3_ritual_event_id", "")) != String(_active.get("event_id", "")):
		return
	var circles: Array = Array(_active.get("circles", []))
	var circle_index: int = _circle_index(circles, int(enemy.get("phase3_ritual_circle_id", -1)))
	if circle_index >= 0:
		var circle: Dictionary = Dictionary(circles[circle_index])
		circle["disrupted"] = true
		circle["occupied"] = false
		circle["progress"] = 0.0
		circles[circle_index] = circle
		_active["circles"] = circles
		game._spawn_radial_particles(Vector2(enemy.get("pos", game.player_pos)), Color(0.58, 1.0, 0.36), 12)
	_clear_devotee_mark(enemy)
	if _all_circles_disrupted():
		_finish_success("all_devotees_defeated")


func active_snapshot() -> Dictionary:
	if not is_active():
		return {
			"schema_version": SCHEMA_VERSION,
			"active": false,
			"next_start_phase_time": snappedf(_next_start_phase_time, 0.1)
		}
	var snapshot: Dictionary = _active.duplicate(true)
	snapshot["schema_version"] = SCHEMA_VERSION
	# Only the authority owns the enemy dictionaries that carry ritual marks.
	# Replicas must preserve the immutable visual list received from the host.
	if game != null and game._is_world_authority():
		snapshot["devotees"] = _marked_devotee_visuals()
		snapshot["overall_progress"] = snappedf(_overall_progress(), 0.001)
	else:
		snapshot["devotees"] = Array(_active.get("devotees", [])).duplicate(true)
		snapshot["overall_progress"] = float(_active.get("overall_progress", 0.0))
	return snapshot


func apply_remote_snapshot(snapshot: Dictionary) -> void:
	if int(snapshot.get("schema_version", SCHEMA_VERSION)) != SCHEMA_VERSION or not bool(snapshot.get("active", false)):
		_active.clear()
		return
	var event_id: String = String(snapshot.get("event_id", ""))
	var stage: String = String(snapshot.get("result", "active"))
	var previous_stage: String = String(_remote_feedback_stage_by_event.get(event_id, ""))
	_active = snapshot.duplicate(true)
	if event_id.is_empty() or previous_stage == stage:
		return
	_remote_feedback_stage_by_event[event_id] = stage
	if stage == "active":
		game._play_sfx("Portal.mp3", 0.03, 0.38, 0.82)
	elif stage == "success":
		game._add_text("RITUAL INTERROMPIDO", game.player_pos + Vector2(0, -108), Color(0.62, 1.0, 0.38), 1.2, 22)
		game._play_sfx("boss_impact", 0.018, 0.36, 1.28)
	elif stage == "failure":
		game._add_text("RITUAL CONCLUIDO: MIASMA", game.player_pos + Vector2(0, -108), Color(0.92, 0.34, 0.62), 1.35, 22)
		game._play_sfx("boss_impact", 0.024, 0.48, 0.82)


func _try_start_from_cadence() -> void:
	if String(game.mode) != "game" or bool(game.boss_active) or float(game.boss_call_timer) >= 0.0:
		return
	if float(game._phase_elapsed_time()) < _next_start_phase_time:
		return
	if game.runtime_event_director != null and game.runtime_event_director.is_active():
		return
	_start_ritual()


func _start_ritual() -> bool:
	if int(game.current_phase) != 3 or bool(game.boss_active) or is_active():
		return false
	var party_size: int = clampi(game._active_run_player_count(), 1, game.ONLINE_MAX_PLAYERS) if bool(game.is_multiplayer) else 1
	var circle_count: int = 3 if party_size >= 3 else 2
	_sequence += 1
	var started_ms: int = Time.get_ticks_msec()
	var event_id: String = "phase3_ritual_%d_%d" % [_sequence, started_ms]
	var circles: Array = _build_circles(circle_count)
	_active = {
		"schema_version": SCHEMA_VERSION,
		"active": true,
		"event_id": event_id,
		"seed": game.rng.randi(),
		"started_ms": started_ms,
		"started_at": snappedf(float(game._phase_elapsed_time()), 0.1),
		"state": "ritual",
		"result": "active",
		"duration": RITUAL_DURATION,
		"remaining": RITUAL_DURATION,
		"party_size": party_size,
		"circles": circles
	}
	_assign_devotees()
	game._add_text("RITUAL DA CATEDRAL", game.player_pos + Vector2(0, -112), Color(0.76, 1.0, 0.34), 1.4, 24)
	game._play_sfx("Portal.mp3", 0.03, 0.38, 0.82)
	for circle_value in Array(_active.get("circles", [])):
		game._spawn_radial_particles(Vector2(Dictionary(circle_value).get("pos", game.player_pos)), Color(0.52, 0.9, 0.28), 10)
	return true


func _build_circles(count: int) -> Array:
	var anchor: Vector2 = _living_players_center()
	var start_angle: float = game.rng.randf_range(0.0, TAU)
	var circles: Array = []
	for index in range(count):
		var angle: float = start_angle + TAU * float(index) / float(count) + game.rng.randf_range(-0.18, 0.18)
		var distance: float = game.rng.randf_range(155.0, 235.0)
		var position: Vector2 = (anchor + Vector2.from_angle(angle) * distance).clamp(Vector2(135.0, 125.0), game.WORLD_SIZE - Vector2(135.0, 125.0))
		circles.append({
			"id": index,
			"pos": position,
			"radius": CIRCLE_RADIUS,
			"progress": 0.0,
			"occupied": false,
			"disrupted": false,
			"devotee_uid": -1,
			"phase": game.rng.randf_range(0.0, TAU)
		})
	return circles


func _assign_devotees() -> void:
	var available: Array = []
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("type", "")) == game.ENEMY_DEVOTO and float(enemy.get("hp", 0.0)) > 0.0 and not bool(enemy.get("phase3_ritual_marked", false)):
			available.append(enemy)
	var circles: Array = Array(_active.get("circles", []))
	for circle_index in range(circles.size()):
		var circle: Dictionary = Dictionary(circles[circle_index])
		var devotee: Dictionary = _nearest_available_devotee(available, Vector2(circle.get("pos", game.player_pos)))
		if devotee.is_empty():
			var spawn_angle: float = game.rng.randf_range(0.0, TAU)
			var spawn_pos: Vector2 = (Vector2(circle.get("pos", game.player_pos)) + Vector2.from_angle(spawn_angle) * 190.0).clamp(Vector2(55.0, 55.0), game.WORLD_SIZE - Vector2(55.0, 55.0))
			var previous_size: int = game.enemies.size()
			game._spawn_enemy(game.ENEMY_DEVOTO, spawn_pos)
			if game.enemies.size() > previous_size:
				devotee = Dictionary(game.enemies[-1])
		if devotee.is_empty():
			circle["disrupted"] = true
			circles[circle_index] = circle
			continue
		available.erase(devotee)
		devotee["phase3_ritual_marked"] = true
		devotee["phase3_ritual_event_id"] = String(_active.get("event_id", ""))
		devotee["phase3_ritual_circle_id"] = int(circle.get("id", circle_index))
		circle["devotee_uid"] = int(devotee.get("uid", -1))
		circles[circle_index] = circle
	_active["circles"] = circles


func _nearest_available_devotee(available: Array, position: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = INF
	for value in available:
		var enemy: Dictionary = value
		var distance: float = Vector2(enemy.get("pos", position)).distance_squared_to(position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _living_players_center() -> Vector2:
	var targets: Array = game._combat_targets()
	if targets.is_empty():
		return Vector2(game.player_pos)
	var sum: Vector2 = Vector2.ZERO
	for value in targets:
		sum += Vector2(Dictionary(value).get("pos", game.player_pos))
	return (sum / float(targets.size())).clamp(Vector2(300.0, 230.0), game.WORLD_SIZE - Vector2(300.0, 230.0))


func _refresh_missing_devotees() -> void:
	var circles: Array = Array(_active.get("circles", []))
	for circle_index in range(circles.size()):
		var circle: Dictionary = Dictionary(circles[circle_index])
		if bool(circle.get("disrupted", false)):
			continue
		var devotee_uid: int = int(circle.get("devotee_uid", -1))
		var devotee: Dictionary = _enemy_by_uid(devotee_uid)
		if devotee.is_empty() or float(devotee.get("hp", 0.0)) <= 0.0:
			circle["disrupted"] = true
			circle["occupied"] = false
			circle["progress"] = 0.0
			circles[circle_index] = circle
	_active["circles"] = circles


func _enemy_by_uid(uid: int) -> Dictionary:
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if int(enemy.get("uid", -2)) == uid:
			return enemy
	return {}


func _circle_index(circles: Array, circle_id: int) -> int:
	for index in range(circles.size()):
		if int(Dictionary(circles[index]).get("id", -1)) == circle_id:
			return index
	return -1


func _all_circles_disrupted() -> bool:
	var circles: Array = Array(_active.get("circles", []))
	return not circles.is_empty() and circles.all(func(value): return bool(Dictionary(value).get("disrupted", false)))


func _all_circles_completed() -> bool:
	var circles: Array = Array(_active.get("circles", []))
	if circles.is_empty():
		return false
	for value in circles:
		var circle: Dictionary = value
		if bool(circle.get("disrupted", false)) or float(circle.get("progress", 0.0)) < 1.0:
			return false
	return true


func _overall_progress() -> float:
	var circles: Array = Array(_active.get("circles", []))
	if circles.is_empty():
		return 0.0
	var progress: float = 0.0
	for value in circles:
		progress += float(Dictionary(value).get("progress", 0.0))
	return clampf(progress / float(circles.size()), 0.0, 1.0)


func _finish_success(reason: String) -> void:
	if String(_active.get("state", "")) != "ritual":
		return
	var event_id: String = String(_active.get("event_id", ""))
	var reward: int = Array(_active.get("circles", [])).size() * REWARD_POINTS_PER_CIRCLE
	if not _rewarded_events.has(event_id):
		_rewarded_events[event_id] = true
		game._apply_score_delta(reward, true, event_id + ":reward")
	_unmark_all_devotees()
	_active["state"] = "result"
	_active["result"] = "success"
	_active["result_reason"] = reason
	_active["reward"] = reward
	_active["result_remaining"] = RESULT_DISPLAY_TIME
	game._add_text("RITUAL INTERROMPIDO  +%d" % reward, game.player_pos + Vector2(0, -112), Color(0.62, 1.0, 0.38), 1.35, 23)
	game._spawn_radial_particles(game.player_pos, Color(0.58, 1.0, 0.34), 18)
	game._play_sfx("boss_impact", 0.018, 0.36, 1.28)


func _finish_failure() -> void:
	if String(_active.get("state", "")) != "ritual":
		return
	var circles: Array = Array(_active.get("circles", []))
	for value in circles:
		var circle: Dictionary = value
		var position: Vector2 = Vector2(circle.get("pos", game.player_pos))
		game._add_phase3_miasma(position, FAILURE_MIASMA_RADIUS, FAILURE_MIASMA_DURATION, FAILURE_MIASMA_DAMAGE_RATIO)
		game._spawn_radial_particles(position, Color(0.76, 0.16, 0.56), 16)
	_unmark_all_devotees()
	_active["state"] = "result"
	_active["result"] = "failure"
	_active["result_remaining"] = RESULT_DISPLAY_TIME
	game._add_text("RITUAL CONCLUIDO: MIASMA", game.player_pos + Vector2(0, -112), Color(0.92, 0.34, 0.62), 1.45, 23)
	game._play_sfx("boss_impact", 0.024, 0.48, 0.82)


func _unmark_all_devotees() -> void:
	if game == null:
		return
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if bool(enemy.get("phase3_ritual_marked", false)):
			_clear_devotee_mark(enemy)


func _clear_devotee_mark(enemy: Dictionary) -> void:
	enemy.erase("phase3_ritual_marked")
	enemy.erase("phase3_ritual_event_id")
	enemy.erase("phase3_ritual_circle_id")
	if String(enemy.get("state", "")).begins_with("ritual_"):
		enemy["state"] = "hunting"
		enemy["parado"] = false


func _marked_devotee_visuals() -> Array:
	var result: Array = []
	if game == null:
		return result
	var event_id: String = String(_active.get("event_id", ""))
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("phase3_ritual_event_id", "")) != event_id:
			continue
		result.append({
			"uid": int(enemy.get("uid", -1)),
			"circle_id": int(enemy.get("phase3_ritual_circle_id", -1)),
			"pos": Vector2(enemy.get("pos", Vector2.ZERO)),
			"channeling": String(enemy.get("state", "")) == "ritual_channel"
		})
	return result
