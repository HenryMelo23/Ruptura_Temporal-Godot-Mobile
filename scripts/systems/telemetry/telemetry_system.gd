class_name RTTelemetrySystem
extends Node

const MINIMAL_SCHEMA: String = "ruptura.college_run_telemetry"
const MINIMAL_SCHEMA_VERSION: int = 1
const MAX_SCORE_EVENTS: int = 160
const MAX_SHOP_EVENTS: int = 80
const MAX_ABILITY_EVENTS: int = 180
const MAX_RUNTIME_EVENTS: int = 96

var _game: Node
var _score_events: Array = []
var _shop_opens: Array = []
var _shop_offers: Array = []
var _shop_rerolls: Array = []
var _shop_purchases: Array = []
var _ability_events: Array = []
var _ability_counts: Dictionary = {}
var _runtime_events: Array = []


func bind_game(game: Node) -> void:
	_game = game


func unbind_game(game: Node) -> void:
	if _game == game:
		_game = null


func start_report() -> void:
	var game: Node = _game
	if game == null or not is_instance_valid(game):
		return
	_reset_minimal_session()
	game.run_report_sent = false
	game.run_report_in_flight = false
	game.run_finalized_result = ""
	game.run_report_status = "Pendente"
	game.run_end_payload.clear()
	game.run_started_at = game._datetime_text()
	game.run_started_unix = int(Time.get_unix_time_from_system())
	game.run_security_session_id = ""
	game.run_security_session_token = ""
	game.run_security_session_ready = false
	game.run_security_session_failed = false
	game.run_security_checkpoint_timer = 0.0
	game.run_security_checkpoint_interval = game.RUN_SECURITY_CHECKPOINT_INTERVAL
	game.run_security_checkpoint_count = 0
	game.run_security_last_error = ""
	game.run_start_damage = game.player_damage
	game.run_damage_to_enemies = 0.0
	game.run_damage_by_enemy.clear()
	game.run_damage_to_boss_by_phase.clear()
	game.run_boss_reached.clear()
	game.run_boss_started_at.clear()
	game.run_boss_duration.clear()
	game.run_damage_taken_total = 0
	game.run_damage_taken_by_source.clear()
	game.run_damage_hits_by_source.clear()
	game.run_damage_source_meta.clear()
	game.run_damage_events.clear()
	game.run_heatmap_cells.clear()
	game.run_heatmap_sample_timer = 0.0
	game.run_phase_seconds.clear()
	game.run_behavior_distance = 0.0
	game.run_behavior_edge_seconds = 0.0
	game.run_behavior_corner_seconds = 0.0
	game.run_behavior_center_seconds = 0.0
	game.run_behavior_dash_count = 0
	game.run_behavior_shots_fired = 0
	game.run_behavior_hits = 0
	game.run_behavior_boss_hits = 0
	game.run_behavior_player_last_pos = game.player_pos
	game.run_behavior_player_last_sample_pos = game.player_pos
	game.run_behavior_move_samples = 0
	game.run_behavior_stationary_samples = 0
	for phase in range(1, 6):
		game.run_damage_to_boss_by_phase[phase] = 0.0
		game.run_boss_reached[phase] = false
		game.run_boss_started_at[phase] = -1.0
		game.run_boss_duration[phase] = -1.0


func _reset_minimal_session() -> void:
	_score_events.clear()
	_shop_opens.clear()
	_shop_offers.clear()
	_shop_rerolls.clear()
	_shop_purchases.clear()
	_ability_events.clear()
	_ability_counts.clear()
	_runtime_events.clear()


func _run_time() -> float:
	var game: Node = _game
	if game == null or not is_instance_valid(game):
		return 0.0
	return snappedf(float(game.time_alive), 0.1)


func _run_phase() -> int:
	var game: Node = _game
	if game == null or not is_instance_valid(game):
		return 0
	return int(game.current_phase)


func _append_limited(target: Array, item: Dictionary, max_count: int) -> void:
	target.append(item)
	while target.size() > max_count:
		target.pop_front()


func _safe_card_id(card: Dictionary) -> String:
	var game: Node = _game
	if game != null and is_instance_valid(game) and game.has_method("_card_id"):
		return String(game._card_id(card))
	return String(card.get("id", String(card.get("name", ""))))


func _safe_card_rarity(card: Dictionary) -> String:
	var game: Node = _game
	if game != null and is_instance_valid(game) and game.has_method("_card_rarity_label") and not card.is_empty():
		return String(game._card_rarity_label(card))
	return String(card.get("rarity", ""))


func _minimal_card_row(card: Dictionary, count: int = 0) -> Dictionary:
	return {
		"id": _safe_card_id(card),
		"rarity": _safe_card_rarity(card),
		"count": count
	}


func _compact_shop_slots(slots: Array) -> Array:
	var compact: Array = []
	for slot in slots:
		var row: Dictionary = Dictionary(slot)
		compact.append({
			"slot": int(row.get("slot", compact.size())),
			"card_id": String(row.get("card_id", "")),
			"rarity": String(row.get("rarity", "")),
			"price": int(row.get("price", 0)),
			"affordable": bool(row.get("affordable", false)),
			"owned_count": int(row.get("owned_count", 0))
		})
	return compact


func record_score_delta(amount: int, reason: String = "") -> void:
	if amount == 0:
		return
	_append_limited(_score_events, {
		"t": _run_time(),
		"phase": _run_phase(),
		"amount": amount,
		"kind": "earned" if amount > 0 else "spent",
		"reason": reason
	}, MAX_SCORE_EVENTS)


func record_shop_open(forced: bool, visit_index: int, rerolls: int) -> void:
	_append_limited(_shop_opens, {
		"t": _run_time(),
		"phase": _run_phase(),
		"forced": forced,
		"visit": visit_index,
		"rerolls": rerolls
	}, MAX_SHOP_EVENTS)


func record_shop_offer(event: Dictionary) -> void:
	_append_limited(_shop_offers, {
		"t": snappedf(float(event.get("time_alive", _run_time())), 0.1),
		"phase": int(event.get("phase", _run_phase())),
		"visit": int(event.get("visit_index", 0)),
		"generation": int(event.get("generation_index", 0)),
		"type": String(event.get("generation_type", "")),
		"profile": String(event.get("profile", "")),
		"reroll_index": int(event.get("reroll_index", 0)),
		"rare_chance": snappedf(float(event.get("rare_chance", 0.0)), 0.0001),
		"rare_success": bool(event.get("rare_success", false)),
		"rare_selected": String(event.get("rare_selected", "")),
		"slots": _compact_shop_slots(Array(event.get("slots", [])))
	}, MAX_SHOP_EVENTS)


func record_shop_reroll(reroll_index: int, rerolls_left: int, free: bool = true, cost: int = 0, paid_index: int = 0, visit_index: int = 0) -> void:
	_append_limited(_shop_rerolls, {
		"t": _run_time(),
		"phase": _run_phase(),
		"visit": visit_index,
		"reroll_index": reroll_index,
		"rerolls_left": rerolls_left,
		"kind": "free" if free else "paid",
		"free": free,
		"paid": not free,
		"cost": cost,
		"paid_index": paid_index
	}, MAX_SHOP_EVENTS)


func record_shop_purchase(card: Dictionary, paid_price: int, visit_index: int) -> void:
	_append_limited(_shop_purchases, {
		"t": _run_time(),
		"phase": _run_phase(),
		"visit": visit_index,
		"card_id": _safe_card_id(card),
		"rarity": _safe_card_rarity(card),
		"price": paid_price
	}, MAX_SHOP_EVENTS)


func record_runtime_event(kind: String, event: Dictionary, context: Dictionary) -> void:
	var event_context: Dictionary = Dictionary(event.get("context", {}))
	var row: Dictionary = {
		"t": _run_time(), "phase": _run_phase(), "kind": kind,
		"type": String(event.get("type", "")), "stat": String(event.get("stat", "")), "sequence": int(event.get("sequence", 0)), "multiplier": snappedf(float(event.get("multiplier", 1.0)), 0.001),
		"started_at": snappedf(float(event.get("started_at", _run_time())), 0.1), "duration": snappedf(float(event.get("duration", 0.0)), 0.1), "ended_at": snappedf(float(event.get("ended_at", 0.0)), 0.1), "end_reason": String(event.get("end_reason", "")),
		"context": {
			"phase": int(event_context.get("phase", context.get("phase", _run_phase()))), "kills": int(event_context.get("kills", context.get("kills", 0))), "boss_active": bool(event_context.get("boss_active", context.get("boss_active", false))), "boss_name": String(event_context.get("boss_name", context.get("boss_name", ""))), "umbra": bool(event_context.get("umbra", context.get("umbra", false)))
		}
	}
	_append_limited(_runtime_events, row, MAX_RUNTIME_EVENTS)


func record_ability_use(kind: String, cooldown_total: float = 0.0) -> void:
	if kind == "":
		return
	_ability_counts[kind] = int(_ability_counts.get(kind, 0)) + 1
	_append_limited(_ability_events, {
		"t": _run_time(),
		"phase": _run_phase(),
		"kind": kind,
		"cooldown": snappedf(cooldown_total, 0.01)
	}, MAX_ABILITY_EVENTS)


func update_run(delta: float) -> void:
	var game: Node = _game
	if game == null or not is_instance_valid(game) or game.is_dead:
		return
	game.run_phase_seconds[game.current_phase] = float(game.run_phase_seconds.get(game.current_phase, 0.0)) + delta
	game.run_behavior_distance += game.player_pos.distance_to(game.run_behavior_player_last_pos)
	game.run_behavior_player_last_pos = game.player_pos
	var edge_x: float = minf(game.player_pos.x, game.WORLD_SIZE.x - game.player_pos.x)
	var edge_y: float = minf(game.player_pos.y, game.WORLD_SIZE.y - game.player_pos.y)
	if edge_x < 180.0 or edge_y < 135.0:
		game.run_behavior_edge_seconds += delta
	if edge_x < 180.0 and edge_y < 135.0:
		game.run_behavior_corner_seconds += delta
	if game.player_pos.distance_to(game.WORLD_SIZE * 0.5) <= minf(game.WORLD_SIZE.x, game.WORLD_SIZE.y) * 0.22:
		game.run_behavior_center_seconds += delta
	game.run_heatmap_sample_timer -= delta
	if game.run_heatmap_sample_timer > 0.0:
		return
	game.run_heatmap_sample_timer = game.RUN_TELEMETRY_SAMPLE_INTERVAL
	if game.player_pos.distance_to(game.run_behavior_player_last_sample_pos) < 18.0:
		game.run_behavior_stationary_samples += 1
	else:
		game.run_behavior_move_samples += 1
	game.run_behavior_player_last_sample_pos = game.player_pos
	var normalized: Vector2 = game._telemetry_normalized_pos(game.player_pos)
	var cell_x: int = clampi(int(floor(normalized.x * game.RUN_TELEMETRY_GRID.x)), 0, game.RUN_TELEMETRY_GRID.x - 1)
	var cell_y: int = clampi(int(floor(normalized.y * game.RUN_TELEMETRY_GRID.y)), 0, game.RUN_TELEMETRY_GRID.y - 1)
	var cell_key: String = "%d:%d:%d" % [game.current_phase, cell_x, cell_y]
	game.run_heatmap_cells[cell_key] = int(game.run_heatmap_cells.get(cell_key, 0)) + 1


func build_minimal_session_payload(result: String) -> Dictionary:
	var game: Node = _game
	if game == null or not is_instance_valid(game):
		return {}
	var behavior: Dictionary = game._run_behavior_report()
	var cards: Array = []
	for row in game._cards_report_rows():
		var card_row: Dictionary = Dictionary(row)
		cards.append({
			"id": String(card_row.get("id", "")),
			"rarity": String(card_row.get("rarity", "")),
			"count": int(card_row.get("count", 0))
		})
	var temporary_event: Dictionary = {
		"active": game.event_alert_timer > 0.0 or game.boss6_special_event_id != "" or not game.manifestation_secondaries.is_empty() or bool(game.runtime_event_director.active_snapshot().get("active", false)),
		"alert": String(game.event_alert_text) if game.event_alert_timer > 0.0 else "",
		"boss6_special": String(game.boss6_special_event_id), "runtime": game.runtime_event_director.active_snapshot(), "events": _runtime_events.duplicate(true),
		"secondary_active": game.manifestation_secondaries.size(),
		"status": {
			"stunned": snappedf(float(game.player_stun_timer), 0.1),
			"silenced": snappedf(float(game.player_silence_timer), 0.1),
			"frozen": snappedf(float(game.player_freeze_visual_timer), 0.1)
		}
	}
	var boss_hp_ratio: float = 0.0
	if game.boss_hp_max > 0.0:
		boss_hp_ratio = clampf(float(game.boss_hp) / float(game.boss_hp_max), 0.0, 1.0)
	var boss_scaling: Dictionary = game._boss_party_scaling_report() if game.has_method("_boss_party_scaling_report") else {}
	var payload: Dictionary = {
		"schema": MINIMAL_SCHEMA,
		"schema_version": MINIMAL_SCHEMA_VERSION,
		"privacy": {
			"personal_data": false,
			"player_name": false,
			"profile_id": false,
			"network_room": false
		},
		"run": {
			"result": result,
			"role": game._run_role_text(),
			"started_unix": int(game.run_started_unix),
			"ended_unix": int(Time.get_unix_time_from_system()),
			"duration_seconds": int(round(game.time_alive)),
			"phase": int(game.current_phase),
			"phase_seconds": game._run_phase_seconds_report()
		},
		"build": {
			"version": String(game.GAME_VERSION),
			"version_code": int(game.GAME_VERSION_CODE),
			"platform": OS.get_name()
		},
		"progress": {
			"kills": int(game.enemies_killed),
			"points_earned": int(game.run_points_earned),
			"points_spent": int(game.run_points_spent),
			"score_current": int(game.score),
			"score_total": int(game.score_total),
			"score_events": _score_events.duplicate(true)
		},
		"shop": {
			"opens": _shop_opens.duplicate(true),
			"offers": _shop_offers.duplicate(true),
			"rerolls": _shop_rerolls.duplicate(true),
			"purchases": _shop_purchases.duplicate(true),
			"open_count": _shop_opens.size(),
			"offer_count": _shop_offers.size(),
			"reroll_count": _shop_rerolls.size(),
			"purchase_count": _shop_purchases.size()
		},
		"build_cards": {
			"cards_total": int(game._deck_total_cards()),
			"cards": cards
		},
		"damage": {
			"dealt_total": int(round(float(game.run_damage_to_enemies))) + int(game._total_boss_damage_report()),
			"enemy_total": int(round(float(game.run_damage_to_enemies))),
			"enemy_detail": game._enemy_damage_report_rows(),
			"boss_total": int(game._total_boss_damage_report()),
			"boss_detail": game._boss_report_rows(),
			"taken_total": int(game.run_damage_taken_total),
			"taken_detail": game._run_damage_taken_report_rows(),
			"taken_events": game.run_damage_events.duplicate(true)
		},
		"movement": {
			"heatmap": {
				"columns": game.RUN_TELEMETRY_GRID.x,
				"rows": game.RUN_TELEMETRY_GRID.y,
				"sample_interval": game.RUN_TELEMETRY_SAMPLE_INTERVAL,
				"cells": game._run_heatmap_report_rows()
			},
			"distance": int(behavior.get("distance_traveled", 0)),
			"dash_count": int(behavior.get("dash_count", 0)),
			"stationary_ratio": float(behavior.get("stationary_ratio", 0.0)),
			"edge_ratio": float(behavior.get("edge_ratio", 0.0)),
			"center_ratio": float(behavior.get("center_ratio", 0.0))
		},
		"attack_cadence": {
			"attack_interval": snappedf(float(game.player_attack_interval), 0.001),
			"shots_fired": int(behavior.get("shots_fired", 0)),
			"shots_per_minute": float(behavior.get("shots_per_minute", 0.0)),
			"hits": int(behavior.get("hits", 0)),
			"hit_rate": float(behavior.get("hit_rate", 0.0))
		},
		"abilities": {
			"counts": _ability_counts.duplicate(true),
			"events": _ability_events.duplicate(true)
		},
		"temporary_event": temporary_event,
		"boss": {
			"active": bool(game.boss_active),
			"phase": int(game.current_phase),
			"name": String(game.boss_name),
			"hp_ratio": snappedf(boss_hp_ratio, 0.0001),
			"stage": float(game.boss_phase),
			"party_size": int(boss_scaling.get("party_size", 1)),
			"hp_coeff": float(boss_scaling.get("hp_coeff", 1.0)),
			"pressure_coeff": float(boss_scaling.get("pressure_coeff", 1.0))
		},
		"umbra": {
			"phase5_context": int(game.current_phase) == 5,
			"mind_status": String(game.umbra_mind_status),
			"mind_version": String(game.umbra_mind_version),
			"apolo_exhibition": bool(game.apolo_phase5_exhibition_enabled),
			"runtime_event_context": game.runtime_event_director.umbra_observation_context()
		}
	}
	return payload


func build_run_report_payload(result: String) -> Dictionary:
	var game: Node = _game
	if game == null or not is_instance_valid(game):
		return {}
	var manifest_name: String = String(game.MANIFESTATIONS[game.selected_manifestation]["name"]) if game.selected_manifestation >= 0 and game.selected_manifestation < game.MANIFESTATIONS.size() else game.manifestation_key
	var aura_name: String = String(game.AURAS[game.selected_aura]["name"]) if game.selected_aura >= 0 and game.selected_aura < game.AURAS.size() else String(game.aura_state.get("name", "N/A"))
	var boss_scaling: Dictionary = game._boss_party_scaling_report() if game.has_method("_boss_party_scaling_report") else {}
	game._ensure_player_profile_id()
	var payload: Dictionary = {
		"player": game.player_nickname,
		"profile_id": game.player_profile_id,
		"room": game.online_room_code if game.online_room_code != "" else "solo",
		"version": game.GAME_VERSION,
		"version_code": game.GAME_VERSION_CODE,
		"platform": OS.get_name(),
		"role": game._run_role_text(),
		"run_session_id": game.run_security_session_id,
		"run_session_token": game.run_security_session_token,
		"run_session_checkpoints": game.run_security_checkpoint_count,
		"run_session_ready": game.run_security_session_ready,
		"run_session_last_error": game.run_security_last_error,
		"date": game._datetime_text(),
		"started_at": game.run_started_at,
		"started_unix": game.run_started_unix,
		"ended_unix": int(Time.get_unix_time_from_system()),
		"result": result,
		"duration": game._run_time_text(),
		"duration_seconds": int(round(game.time_alive)),
		"phase": game.current_phase,
		"kills": game.enemies_killed,
		"points_earned": game.run_points_earned,
		"points_spent": game.run_points_spent,
		"score_current": game.score,
		"score_total": game.score_total,
		"cards_total": game._deck_total_cards(),
		"cards": game._cards_report_text(),
		"cards_detail": game._cards_report_rows(),
		"manifestation": manifest_name,
		"manifestation_key": game.manifestation_key,
		"spectrum": aura_name,
		"spectrum_key": String(game.aura_state.get("name", "")),
		"base_damage_start": game.run_start_damage,
		"base_damage_end": game.player_damage,
		"player_stats": {
			"hp": game.player_hp,
			"hp_max": game.player_hp_max,
			"speed": game.player_speed,
			"attack_interval": game.player_attack_interval,
			"dash_cooldown": game.player_dash_cooldown,
			"defense": game.player_defense,
			"crit_chance": game.player_crit_chance,
			"lifesteal": game.player_lifesteal,
			"luck": game.luck
		},
		"enemy_scaling": {
			"limit": game._enemy_limit(),
			"base_hp": game.enemy_base_hp,
			"base_speed": game.enemy_speed_base,
			"close_damage": game.enemy_close_damage,
			"far_damage": game.enemy_far_damage
		},
		"enemy_damage_total": game.run_damage_to_enemies,
		"enemy_damage_breakdown": game._enemy_damage_report_text(),
		"enemy_damage_detail": game._enemy_damage_report_rows(),
		"damage_taken_total": game.run_damage_taken_total,
		"damage_taken_detail": game._run_damage_taken_report_rows(),
		"damage_events": game.run_damage_events.duplicate(true),
		"position_heatmap": {
			"columns": game.RUN_TELEMETRY_GRID.x,
			"rows": game.RUN_TELEMETRY_GRID.y,
			"sample_interval": game.RUN_TELEMETRY_SAMPLE_INTERVAL,
			"world_width": int(game.WORLD_SIZE.x),
			"world_height": int(game.WORLD_SIZE.y),
			"cells": game._run_heatmap_report_rows()
		},
		"behavior_metrics": game._run_behavior_report(),
		"boss_damage_total": game._total_boss_damage_report(),
		"boss_report": game._boss_report_text(),
		"boss_detail": game._boss_report_rows(),
		"boss_scaling": boss_scaling,
		"dimension_route": {
			"initial_phase": game.run_initial_phase,
			"farm_cycles": game.dimension_route_farm_cycles,
			"completed_count": game.dimension_route_completed_count,
			"last_phase": game.dimension_route_last_phase,
			"pending_queue": game.dimension_route_queue.duplicate(),
			"extracted": game.run_extracted
		},
		"network": {
			"ping_ms": game.net_ping_ms,
			"remote_ping_ms": game.net_remote_ping_ms,
			"bytes_in": game.net_report_total_bytes_in,
			"bytes_out": game.net_report_total_bytes_out,
			"packets_in": game.net_report_total_packets_in,
			"packets_out": game.net_report_total_packets_out
		},
		"settings": {
			"graphics_low_resource": game.gfx_low_resource,
			"memory_saver": game.gfx_memory_saver,
			"particles": game.gfx_particles,
			"shadows": game.gfx_shadows,
			"shop_auto": game.shop_auto_enabled,
			"streaming_enabled": game.QA_STREAMING_FEATURE_ENABLED,
			"streaming_unlocked": game.qa_streaming_unlocked,
			"streaming_active": game.qa_streaming_native_active or game.qa_streaming_desktop_ffmpeg_active or game.qa_streaming_frame_active,
			"streaming_quality": game._sanitize_qa_stream_quality_mode(game.qa_streaming_quality_mode)
		},
		"leaderboard_score": game._run_leaderboard_score(result),
		"balance_flags": game._run_balance_flags()
	}
	payload["integrity"] = {
		"version": game.RUN_REPORT_INTEGRITY_VERSION,
		"signature": run_report_signature(payload, game.RUN_REPORT_INTEGRITY_SALT)
	}
	return payload


func run_report_signature(payload: Dictionary, salt: String) -> String:
	var fields: Array[String] = [
		"player", "profile_id", "room", "version", "version_code", "platform", "role", "result",
		"started_unix", "ended_unix", "duration_seconds", "phase", "kills", "points_earned", "points_spent",
		"score_current", "score_total", "cards_total", "manifestation_key", "spectrum_key", "enemy_damage_total",
		"damage_taken_total", "boss_damage_total", "leaderboard_score", "run_session_id", "run_session_checkpoints"
	]
	var parts: Array[String] = []
	for field in fields:
		parts.append("%s=%s" % [field, str(payload.get(field, ""))])
	parts.append("salt=" + salt)
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK:
		return ""
	hashing.update("|".join(parts).to_utf8_buffer())
	return hashing.finish().hex_encode().to_lower()
