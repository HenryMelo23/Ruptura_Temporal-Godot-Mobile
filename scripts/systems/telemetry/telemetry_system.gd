class_name RTTelemetrySystem
extends Node

var _game: Node


func bind_game(game: Node) -> void:
	_game = game


func unbind_game(game: Node) -> void:
	if _game == game:
		_game = null


func start_report() -> void:
	var game: Node = _game
	if game == null or not is_instance_valid(game):
		return
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


func build_run_report_payload(result: String) -> Dictionary:
	var game: Node = _game
	if game == null or not is_instance_valid(game):
		return {}
	var manifest_name: String = String(game.MANIFESTATIONS[game.selected_manifestation]["name"]) if game.selected_manifestation >= 0 and game.selected_manifestation < game.MANIFESTATIONS.size() else game.manifestation_key
	var aura_name: String = String(game.AURAS[game.selected_aura]["name"]) if game.selected_aura >= 0 and game.selected_aura < game.AURAS.size() else String(game.aura_state.get("name", "N/A"))
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
