class_name RTRuntimeEventDirector
extends Node

const Catalog = preload("res://scripts/systems/events/runtime_event_catalog.gd")

var _game: Node = null
var _active_event: Dictionary = {}
var _active_remaining: float = 0.0
var _cooldown_remaining: float = 0.0
var _charge: float = 0.0
var _sequence: int = 0
var _last_started_id: String = ""
var _events_log: Array = []


func bind_game(game: Node) -> void:
	_game = game


func reset() -> void:
	_active_event.clear()
	_active_remaining = 0.0
	_cooldown_remaining = 0.0
	_charge = 0.0
	_sequence = 0
	_last_started_id = ""
	_events_log.clear()


func context_from_game(game: Object) -> Dictionary:
	return {
		"time": float(game.get("time_alive")),
		"phase": int(game.get("current_phase")),
		"kills": int(game.get("enemies_killed")),
		"boss_active": bool(game.get("boss_active")),
		"boss_name": String(game.get("boss_name")),
		"umbra": int(game.get("current_phase")) == 5 or String(game.get("boss_name")) == "UMBRA"
	}


func update(delta: float, context: Dictionary, authority: bool) -> void:
	if delta <= 0.0:
		return
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	if is_active():
		_active_remaining = maxf(0.0, _active_remaining - delta)
		_active_event["remaining"] = snappedf(_active_remaining, 0.1)
		if _active_remaining <= 0.0 and authority:
			_finish_active_event("expired", context)


func on_enemy_killed(enemy: Dictionary, context: Dictionary, authority: bool) -> void:
	if not authority:
		return
	var run_time: float = float(context.get("time", 0.0))
	if run_time < float(Catalog.CONFIG.get("min_start_time", 240.0)):
		return
	var enemy_type: String = String(enemy.get("type", "default"))
	_charge += Catalog.enemy_charge(enemy_type)
	if is_active() or _cooldown_remaining > 0.0:
		return
	var threshold: float = Catalog.threshold_for(run_time)
	if _charge < threshold:
		return
	_start_event(_choose_event(context), context, threshold)


func is_active() -> bool:
	return not _active_event.is_empty() and _active_remaining > 0.0


func damage_multiplier() -> float:
	return _stat_multiplier("damage", 1.0)


func move_speed_multiplier() -> float:
	return _stat_multiplier("move_speed", 1.0)


func attack_interval_multiplier() -> float:
	return _stat_multiplier("attack_interval", 1.0)


func point_multiplier() -> float:
	return _stat_multiplier("points", 1.0)


func active_snapshot() -> Dictionary:
	if _active_event.is_empty():
		return {
			"active": false,
			"cooldown": snappedf(_cooldown_remaining, 0.1),
			"charge": snappedf(_charge, 0.01)
		}
	var snapshot: Dictionary = _active_event.duplicate(true)
	snapshot["active"] = is_active()
	snapshot["remaining"] = snappedf(_active_remaining, 0.1)
	snapshot["cooldown"] = snappedf(_cooldown_remaining, 0.1)
	snapshot["charge"] = snappedf(_charge, 0.01)
	return snapshot


func telemetry_events() -> Array:
	return _events_log.duplicate(true)


func apply_remote_snapshot(snapshot: Dictionary) -> void:
	if bool(snapshot.get("active", false)):
		_active_event = snapshot.duplicate(true)
		_active_remaining = float(snapshot.get("remaining", snapshot.get("duration", 0.0)))
	else:
		_active_event.clear()
		_active_remaining = 0.0
	_cooldown_remaining = float(snapshot.get("cooldown", _cooldown_remaining))
	_charge = float(snapshot.get("charge", _charge))


func cleanup(reason: String, context: Dictionary) -> void:
	if is_active():
		_finish_active_event(reason, context)
	_active_event.clear()
	_active_remaining = 0.0
	_cooldown_remaining = 0.0
	_charge = 0.0


func umbra_observation_context() -> Dictionary:
	var snapshot: Dictionary = active_snapshot()
	return {
		"event_active": bool(snapshot.get("active", false)),
		"event_type": String(snapshot.get("type", "")),
		"stat": String(snapshot.get("stat", "")),
		"remaining": float(snapshot.get("remaining", 0.0)),
		"intensity": float(snapshot.get("intensity", 0.0))
	}


func _stat_multiplier(stat: String, fallback: float) -> float:
	if not is_active():
		return fallback
	if String(_active_event.get("stat", "")) != stat:
		return fallback
	return float(_active_event.get("multiplier", fallback))


func _choose_event(context: Dictionary) -> Dictionary:
	var count: int = Catalog.event_count()
	if count <= 0:
		return {}
	var phase: int = int(context.get("phase", 1))
	var kills: int = int(context.get("kills", 0))
	var offset: int = 1 if _last_started_id != "" else 0
	for i in range(count):
		var event: Dictionary = Catalog.event_by_index(kills + phase + _sequence + i + offset)
		if String(event.get("id", "")) != _last_started_id:
			return event
	return Catalog.event_by_index(kills + phase + _sequence + offset)


func _start_event(event: Dictionary, context: Dictionary, threshold: float) -> void:
	if event.is_empty():
		return
	var run_time: float = float(context.get("time", 0.0))
	var duration: float = Catalog.event_duration(event, run_time)
	var multiplier: float = Catalog.event_multiplier(event, run_time)
	var intensity: float = Catalog.intensity_at(run_time)
	_sequence += 1
	_active_remaining = duration
	_active_event = {
		"schema": Catalog.SCHEMA,
		"schema_version": Catalog.SCHEMA_VERSION,
		"sequence": _sequence,
		"type": String(event.get("id", "")),
		"label": String(event.get("label", "")),
		"stat": String(event.get("stat", "")),
		"started_at": snappedf(run_time, 0.1),
		"duration": snappedf(duration, 0.1),
		"remaining": snappedf(duration, 0.1),
		"multiplier": snappedf(multiplier, 0.001),
		"intensity": snappedf(intensity, 0.001),
		"context": _context_payload(context, threshold)
	}
	_last_started_id = String(_active_event["type"])
	_charge = 0.0
	_append_event_log("start", _active_event.duplicate(true), context)
	_record_telemetry("start", _active_event.duplicate(true), context)


func _finish_active_event(reason: String, context: Dictionary) -> void:
	if _active_event.is_empty():
		return
	var finished: Dictionary = _active_event.duplicate(true)
	finished["ended_at"] = snappedf(float(context.get("time", 0.0)), 0.1)
	finished["end_reason"] = reason
	finished["elapsed"] = snappedf(float(finished.get("duration", 0.0)) - _active_remaining, 0.1)
	_cooldown_remaining = Catalog.cooldown_for(float(context.get("time", 0.0)))
	_active_event.clear()
	_active_remaining = 0.0
	_append_event_log("end", finished, context)
	_record_telemetry("end", finished, context)


func _context_payload(context: Dictionary, threshold: float) -> Dictionary:
	return {
		"phase": int(context.get("phase", 1)),
		"kills": int(context.get("kills", 0)),
		"boss_active": bool(context.get("boss_active", false)),
		"boss_name": String(context.get("boss_name", "")),
		"umbra": bool(context.get("umbra", false)),
		"threshold": snappedf(threshold, 0.01)
	}


func _append_event_log(kind: String, event: Dictionary, context: Dictionary) -> void:
	var row: Dictionary = event.duplicate(true)
	row["kind"] = kind
	row["t"] = snappedf(float(context.get("time", 0.0)), 0.1)
	_events_log.append(row)
	while _events_log.size() > 32:
		_events_log.pop_front()


func _record_telemetry(kind: String, event: Dictionary, context: Dictionary) -> void:
	var telemetry: Node = get_node_or_null("/root/TelemetrySystem")
	if telemetry == null or not telemetry.has_method("record_runtime_event"):
		return
	telemetry.record_runtime_event(kind, event, context)
