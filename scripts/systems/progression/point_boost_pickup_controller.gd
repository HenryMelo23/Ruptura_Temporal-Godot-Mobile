class_name RTPointBoostPickupController
extends RefCounted

const PICKUP_KIND := "point_boost"
const SCHEMA := "point_boost_pickup_v2"
const SCHEMA_VERSION := 2

# A deterministic pity budget replaces the old independent 8% roll on every kill.
# These values are deliberately centralized so balance tests and live tuning use
# the same contract.
const CONFIG := {
	"min_run_time": 300.0,
	"min_phase": 1,
	"charge_threshold": 90.0,
	"cooldown": 240.0,
	"duration": 12.0,
	"multiplier": 2.0,
	"ground_lifetime": 16.0,
	"collect_radius": 66.0,
	"window_duration": 600.0,
	"max_drops_per_window": 2,
	"luck_threshold_reduction_cap": 0.15,
	"final_warning_time": 3.0,
}

const ENEMY_CHARGE := {
	"common": 1.0,
	"shooter": 1.25,
	"curater": 2.0,
	"agglomerator": 2.5,
	"elite": 4.0,
	"larapio": 6.0,
}

var core
var _charge := 0.0
var _cooldown_remaining := 0.0
var _buff_remaining := 0.0
var _window_elapsed := 0.0
var _window_drops := 0
var _sequence := 0
var _expiry_feedback_emitted := true
var _warning_feedback_emitted := true


func configure(runtime_core) -> void:
	core = runtime_core


func reset() -> void:
	_charge = 0.0
	_cooldown_remaining = 0.0
	_buff_remaining = 0.0
	_window_elapsed = 0.0
	_window_drops = 0
	_sequence = 0
	_expiry_feedback_emitted = true
	_warning_feedback_emitted = true


func update(delta: float, authority: bool) -> void:
	if delta <= 0.0:
		return
	_window_elapsed += delta
	while _window_elapsed >= float(CONFIG["window_duration"]):
		_window_elapsed -= float(CONFIG["window_duration"])
		_window_drops = 0
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	if _buff_remaining <= 0.0:
		return
	_buff_remaining = maxf(0.0, _buff_remaining - delta)
	if _buff_remaining > 0.0 and _buff_remaining <= float(CONFIG["final_warning_time"]) and not _warning_feedback_emitted:
		_warning_feedback_emitted = true
		if core != null and core.has_method("_on_point_boost_final_warning"):
			core._on_point_boost_final_warning()
	if _buff_remaining <= 0.0 and not _expiry_feedback_emitted:
		_expiry_feedback_emitted = true
		if core != null and core.has_method("_on_point_boost_expired"):
			core._on_point_boost_expired(authority)


func on_enemy_defeated(enemy: Dictionary, run_time: float, phase: int, luck: float, event_points_active: bool, authority: bool) -> Dictionary:
	if not authority or core == null:
		return {}
	if run_time < float(CONFIG["min_run_time"]) or phase < int(CONFIG["min_phase"]):
		return {}
	_charge = minf(effective_threshold(luck), _charge + enemy_charge(String(enemy.get("type", "common"))))
	if not can_spawn(event_points_active, luck):
		return {}
	var threshold := effective_threshold(luck)
	if _charge < threshold:
		return {}
	var pos: Vector2 = Vector2(enemy.get("pos", core.player_pos))
	var orb: Dictionary = core._spawn_gameplay_orb(PICKUP_KIND, pos, {
		"collect_radius": float(CONFIG["collect_radius"]),
		"spawn_time": run_time,
		"artifact": true,
	}, 0, float(CONFIG["ground_lifetime"]))
	if orb.is_empty():
		return {}
	_charge = maxf(0.0, _charge - threshold)
	_cooldown_remaining = float(CONFIG["cooldown"])
	_window_drops += 1
	if core.has_method("_on_point_boost_spawned"):
		core._on_point_boost_spawned(orb)
	return orb


func can_spawn(event_points_active: bool, luck: float = 0.0) -> bool:
	if core == null or _cooldown_remaining > 0.0 or is_active() or event_points_active:
		return false
	if _window_drops >= int(CONFIG["max_drops_per_window"]):
		return false
	for orb in core.heal_orbs:
		if String(orb.get("kind", "")) == PICKUP_KIND and float(orb.get("life", 0.0)) > 0.0:
			return false
	return _charge >= effective_threshold(luck)


func activate(collector_peer_id: int, authority: bool) -> bool:
	if not authority or is_active():
		return false
	_sequence += 1
	_buff_remaining = float(CONFIG["duration"])
	_expiry_feedback_emitted = false
	_warning_feedback_emitted = false
	if core != null and core.has_method("_on_point_boost_activated"):
		core._on_point_boost_activated(collector_peer_id, true)
	return true


func is_active() -> bool:
	return _buff_remaining > 0.0


func remaining() -> float:
	return maxf(0.0, _buff_remaining)


func duration() -> float:
	return float(CONFIG["duration"])


func multiplier() -> float:
	return float(CONFIG["multiplier"]) if is_active() else 1.0


func effective_point_multiplier(event_multiplier: float) -> float:
	# Explicit stacking rule: the stronger x2 source wins; x2 times x2 never becomes x4.
	return maxf(1.0, maxf(event_multiplier, multiplier()))


func final_warning_active() -> bool:
	return is_active() and _buff_remaining <= float(CONFIG["final_warning_time"])


func active_snapshot() -> Dictionary:
	return {
		"schema": SCHEMA,
		"schema_version": SCHEMA_VERSION,
		"active": is_active(),
		"sequence": _sequence,
		"remaining": snappedf(_buff_remaining, 0.1),
		"duration": float(CONFIG["duration"]),
		"multiplier": float(CONFIG["multiplier"]),
		"cooldown": snappedf(_cooldown_remaining, 0.1),
		"charge": snappedf(_charge, 0.01),
		"window_drops": _window_drops,
		"window_elapsed": snappedf(_window_elapsed, 0.1),
	}


func apply_remote_snapshot(snapshot: Dictionary) -> void:
	var was_active := is_active()
	var previous_sequence := _sequence
	_sequence = maxi(_sequence, int(snapshot.get("sequence", _sequence)))
	_buff_remaining = maxf(0.0, float(snapshot.get("remaining", 0.0))) if bool(snapshot.get("active", false)) else 0.0
	_cooldown_remaining = maxf(0.0, float(snapshot.get("cooldown", _cooldown_remaining)))
	_charge = maxf(0.0, float(snapshot.get("charge", _charge)))
	_window_drops = maxi(0, int(snapshot.get("window_drops", _window_drops)))
	_window_elapsed = maxf(0.0, float(snapshot.get("window_elapsed", _window_elapsed)))
	if is_active() and _sequence > previous_sequence:
		_expiry_feedback_emitted = false
		_warning_feedback_emitted = _buff_remaining <= float(CONFIG["final_warning_time"])
		if core != null and core.has_method("_on_point_boost_activated"):
			core._on_point_boost_activated(0, false)
	elif was_active and not is_active() and not _expiry_feedback_emitted:
		_expiry_feedback_emitted = true
		if core != null and core.has_method("_on_point_boost_expired"):
			core._on_point_boost_expired(false)


func effective_threshold(luck: float) -> float:
	var luck_reduction := minf(float(CONFIG["luck_threshold_reduction_cap"]), maxf(0.0, luck) * 0.01)
	return float(CONFIG["charge_threshold"]) * (1.0 - luck_reduction)


static func enemy_charge(enemy_type: String) -> float:
	return float(ENEMY_CHARGE.get(enemy_type, 1.0))
