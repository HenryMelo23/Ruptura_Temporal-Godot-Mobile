extends Node
class_name EarlyBossController

var game: Node = null


func bind_game(root: Node) -> void:
	game = root


func capture_boss1_rewind_projectiles() -> Array:
	var captured = []
	for bullet in game.bullets:
		if captured.size() >= 24:
			break
		captured.append({
			"visual": "player",
			"kind": String(bullet.get("kind", "eletrica")),
			"pos": Vector2(bullet.get("pos", game.player_pos)),
			"dir": Vector2(bullet.get("dir", game.last_facing))
		})
	for bullet in game.return_bullets:
		if captured.size() >= 30:
			break
		captured.append({
			"visual": "returning",
			"kind": "retornante",
			"pos": Vector2(bullet.get("pos", game.player_pos)),
			"dir": Vector2(bullet.get("dir", game.last_facing))
		})
	for bullet in game.enemy_bullets:
		if captured.size() >= 36:
			break
		captured.append({
			"visual": "enemy",
			"kind": String(bullet.get("type", "enemy")),
			"pos": Vector2(bullet.get("pos", game.boss_pos)),
			"dir": Vector2(bullet.get("dir", Vector2.DOWN))
		})
	for wave in game.shockwaves:
		if captured.size() >= 40:
			break
		captured.append({"visual": "shockwave", "pos": Vector2(wave.get("pos", game.player_pos)), "radius": float(wave.get("radius", 0.0))})
	for prism in game.prisms:
		if captured.size() >= 44:
			break
		captured.append({"visual": "prism", "pos": Vector2(prism.get("pos", game.player_pos))})
	for wave in game.boss_transition_waves:
		if captured.size() >= 47:
			break
		captured.append({"visual": "boss_wave", "pos": Vector2(wave.get("pos", game.boss_pos)), "radius": float(wave.get("radius", 0.0))})
	return captured


func capture_boss1_rewind_snapshot() -> Dictionary:
	return {
		"time": game.time_alive,
		"elapsed": game.elapsed_unpaused,
		"player_pos": game.player_pos,
		"boss_pos": game.boss_pos,
		"player_hp": game.player_hp,
		"last_facing": game.last_facing,
		"last_attack": game.last_attack_time,
		"last_dash": game.last_dash_time,
		"last_skill": game.last_skill_time,
		"last_secondary": game.last_secondary_time,
		"last_damage": game.last_damage_time,
		"boss_phase": game.boss_phase,
		"boss_attack_timer": game.boss_attack_timer,
		"projectiles": capture_boss1_rewind_projectiles()
	}


func record_boss1_rewind_history(delta: float) -> void:
	if not game.boss1_rewind_sequence.is_empty():
		return
	game.boss1_rewind_sample_timer += delta
	if not game.boss1_rewind_history.is_empty() and game.boss1_rewind_sample_timer < game.BOSS1_REWIND_SAMPLE_INTERVAL:
		return
	game.boss1_rewind_sample_timer = fmod(game.boss1_rewind_sample_timer, game.BOSS1_REWIND_SAMPLE_INTERVAL)
	game.boss1_rewind_history.append(capture_boss1_rewind_snapshot())
	var cutoff = game.time_alive - game.BOSS1_REWIND_SECONDS - game.BOSS1_REWIND_SAMPLE_INTERVAL
	while game.boss1_rewind_history.size() > 1 and float(game.boss1_rewind_history[0].get("time", game.time_alive)) < cutoff:
		game.boss1_rewind_history.pop_front()


func chrono_variant_name(variant: int) -> String:
	match variant:
		1:
			return "CRONO-FENDA DUPLA"
		2:
			return "ESPIRAL DE 11:10"
		3:
			return "PONTEIROS PARTIDOS"
	return "ONDA DE RETROCESSO"


func chrono_variant_color(variant: int) -> Color:
	match variant:
		1:
			return Color(1.0, 0.44, 0.78)
		2:
			return Color(0.72, 0.52, 1.0)
		3:
			return Color(1.0, 0.78, 0.3)
	return Color(0.36, 0.94, 1.0)


func start_boss1_time_wave() -> void:
	if game.current_phase != 1 or game.boss1_rewind_cooldown > 0.0 or game.boss_dead or game.boss_hp <= 0.0 or game.boss_hp >= game.boss_hp_max * game.BOSS1_REWIND_THRESHOLD:
		return
	game.boss1_rewind_cooldown = game.BOSS1_REWIND_COOLDOWN
	game.boss_stage_timer = 0.0
	game.boss_stage_approaching = false
	game.boss_attacks.clear()
	game.boss_transition_waves.clear()
	if game.boss1_rewind_history.is_empty() or game.time_alive - float(game.boss1_rewind_history[-1].get("time", -999.0)) > 0.02:
		game.boss1_rewind_history.append(capture_boss1_rewind_snapshot())
	var origin = game.boss_pos
	var max_radius = 0.0
	for corner in [Vector2.ZERO, Vector2(game.WORLD_SIZE.x, 0.0), Vector2(0.0, game.WORLD_SIZE.y), game.WORLD_SIZE]:
		max_radius = max(max_radius, origin.distance_to(corner))
	var variant = game.rng.randi_range(0, 3)
	var wave_target: Dictionary = game._boss_target_entry(true)
	game.boss1_time_wave = {
		"origin": origin,
		"radius": 48.0,
		"direction": 1.0,
		"max_radius": max_radius + 48.0,
		"age": 0.0,
		"variant": variant,
		"target_peer": int(wave_target.get("peer_id", game._mp_unique_id()))
	}
	game.boss_pos = origin
	game.screen_shake_timer = 0.18
	game.screen_shake_strength = 7.0
	game._vibrate(70, 0.24)
	game._add_text(chrono_variant_name(variant), game.boss_pos + Vector2(0, -126), chrono_variant_color(variant), 2.0, 28)
	game._play_sfx("Retrocede.mp3", 0.05, 0.85, 1.0)
	game._spawn_radial_particles(game.boss_pos, Color(0.34, 0.84, 1.0), 32)


func update_boss1_time_wave(delta: float) -> void:
	if game.boss1_time_wave.is_empty():
		return
	game.boss_pos = Vector2(game.boss1_time_wave["origin"])
	game.boss1_time_wave["age"] = float(game.boss1_time_wave.get("age", 0.0)) + delta
	if float(game.boss1_time_wave["age"]) < game.BOSS1_TIME_WAVE_WARNING:
		return
	var previous_radius = float(game.boss1_time_wave["radius"])
	var direction = float(game.boss1_time_wave["direction"])
	var next_radius = previous_radius + direction * game.BOSS1_TIME_WAVE_SPEED * delta
	var max_radius = float(game.boss1_time_wave["max_radius"])
	if direction > 0.0 and next_radius >= max_radius:
		next_radius = max_radius
		game.boss1_time_wave["direction"] = -1.0
		game.screen_shake_timer = 0.2
		game.screen_shake_strength = 9.0
		game._add_text("A ONDA ESTA VOLTANDO", game.boss_pos + Vector2(0, -112), Color(1.0, 0.34, 0.72), 1.4, 22)
	elif direction < 0.0 and next_radius <= 34.0:
		game.boss1_time_wave.clear()
		game.boss_attack_timer = 1.6
		game._add_text("LINHA TEMPORAL EVITADA", game.boss_pos + Vector2(0, -108), Color(0.42, 1.0, 0.78), 1.2, 21)
		return
	game.boss1_time_wave["radius"] = next_radius
	var swept_min = min(previous_radius, next_radius) - game.BOSS1_TIME_WAVE_WIDTH - 22.0
	var swept_max = max(previous_radius, next_radius) + game.BOSS1_TIME_WAVE_WIDTH + 22.0
	var target_peer: int = int(game.boss1_time_wave.get("target_peer", game._mp_unique_id()))
	if target_peer == game._mp_unique_id():
		var player_distance = game.player_pos.distance_to(Vector2(game.boss1_time_wave["origin"]))
		if player_distance >= swept_min and player_distance <= swept_max:
			start_boss1_rewind_sequence()
	else:
		var remote_state: Dictionary = game.net_players_by_peer.get(target_peer, {})
		if remote_state.is_empty() or bool(remote_state.get("dead", false)) or bool(remote_state.get("stealthed", false)):
			var replacement: Dictionary = game._boss_target_entry(true)
			game.boss1_time_wave["target_peer"] = int(replacement.get("peer_id", game._mp_unique_id()))
			return
		var remote_distance = Vector2(remote_state.get("pos", Vector2.ZERO)).distance_to(Vector2(game.boss1_time_wave["origin"]))
		if remote_distance >= swept_min and remote_distance <= swept_max:
			trigger_boss1_remote_rewind(target_peer)


func trigger_boss1_remote_rewind(peer_id: int) -> void:
	var state: Dictionary = game.net_players_by_peer.get(peer_id, {})
	if not game._is_world_authority() or state.is_empty() or bool(state.get("dead", false)):
		return
	start_boss1_rewind_sequence()


func start_boss1_rewind_sequence(event_id: String = "", variant: int = -1) -> void:
	if not game.boss1_rewind_sequence.is_empty():
		return
	if game._is_world_replica() and event_id == "":
		return
	if event_id != "" and game.net_rewind_seen.has(event_id):
		return
	if event_id == "":
		event_id = game._next_network_event_id("boss1_team_rewind")
	game.net_rewind_seen[event_id] = true
	while game.net_rewind_seen.size() > game.NET_REPORT_EVENT_LIMIT:
		game.net_rewind_seen.erase(game.net_rewind_seen.keys()[0])
	if game.boss1_rewind_history.is_empty():
		game.boss1_rewind_history.append(capture_boss1_rewind_snapshot())
	elif game.time_alive - float(game.boss1_rewind_history[-1].get("time", -999.0)) > 0.02:
		game.boss1_rewind_history.append(capture_boss1_rewind_snapshot())
	var chrono_variant = variant if variant >= 0 else int(game.boss1_time_wave.get("variant", game.rng.randi_range(0, 3)))
	game.boss1_time_wave.clear()
	game.boss_attacks.clear()
	game.boss_transition_waves.clear()
	game.effects.clear()
	game.boss1_rewind_visual_projectiles = Array(game.boss1_rewind_history[-1].get("projectiles", [])).duplicate(true)
	game.boss1_rewind_sequence = {
		"event_id": event_id,
		"elapsed": 0.0,
		"variant": chrono_variant,
		"rewind_local_player": not game.is_dead and not game.online_local_spectator,
		"boss_heal": (game.boss_hp_max - game.boss_hp) * game.BOSS1_REWIND_BOSS_HEAL,
		"player_final_hp": min(game.player_hp_max, game.player_hp + (game.player_hp_max - game.player_hp) * game.BOSS1_REWIND_PLAYER_HEAL)
	}
	game._cancel_combat_aim_state(true)
	game.screen_shake_timer = 0.16
	game.screen_shake_strength = 6.0
	game._vibrate(110, 0.35)
	game.boss1_rewind_vibration_timer = 0.0
	game.boss1_rewind_clock_tick = -1
	game._add_text("TEMPO CAPTURADO", game.player_pos + Vector2(0, -102), Color(0.48, 0.92, 1.0), 1.2, 26)
	if game.is_multiplayer and game._is_world_authority() and game._shop_rpc_available():
		game.rpc("_rpc_boss1_team_rewind", event_id, chrono_variant)


func apply_boss1_rewind_sync(data: Dictionary) -> void:
	var event_id: String = String(data.get("event_id", ""))
	if event_id == "" or game.current_phase != 1 or not game.boss_active or game.boss_dead:
		return
	start_boss1_rewind_sequence(event_id, int(data.get("variant", 0)))
	if String(game.boss1_rewind_sequence.get("event_id", "")) == event_id:
		game.boss1_rewind_sequence["elapsed"] = maxf(float(game.boss1_rewind_sequence.get("elapsed", 0.0)), float(data.get("elapsed", 0.0)))
		game.boss1_time_wave.clear()


func boss1_rewind_interpolated_sample(progress: float) -> Dictionary:
	if game.boss1_rewind_history.is_empty():
		return {}
	var cursor = lerp(float(game.boss1_rewind_history.size() - 1), 0.0, clamp(progress, 0.0, 1.0))
	var lower_index = int(floor(cursor))
	var upper_index = min(lower_index + 1, game.boss1_rewind_history.size() - 1)
	var weight = cursor - lower_index
	var lower: Dictionary = game.boss1_rewind_history[lower_index]
	var upper: Dictionary = game.boss1_rewind_history[upper_index]
	var nearest: Dictionary = game.boss1_rewind_history[int(round(cursor))]
	return {
		"time": lerp(float(lower["time"]), float(upper["time"]), weight),
		"elapsed": lerp(float(lower["elapsed"]), float(upper["elapsed"]), weight),
		"player_pos": Vector2(lower["player_pos"]).lerp(Vector2(upper["player_pos"]), weight),
		"boss_pos": Vector2(lower["boss_pos"]).lerp(Vector2(upper["boss_pos"]), weight),
		"player_hp": lerp(float(lower["player_hp"]), float(upper["player_hp"]), weight),
		"last_facing": Vector2(nearest["last_facing"]),
		"last_attack": float(nearest["last_attack"]),
		"last_dash": float(nearest["last_dash"]),
		"last_skill": float(nearest["last_skill"]),
		"last_secondary": float(nearest["last_secondary"]),
		"last_damage": float(nearest["last_damage"]),
		"boss_phase": lerp(float(lower["boss_phase"]), float(upper["boss_phase"]), weight),
		"boss_attack_timer": float(nearest["boss_attack_timer"]),
		"projectiles": Array(nearest.get("projectiles", []))
	}


func apply_boss1_rewind_sample(sample: Dictionary) -> void:
	if sample.is_empty():
		return
	game.time_alive = float(sample["time"])
	game.elapsed_unpaused = float(sample["elapsed"])
	if game._is_world_authority():
		game.boss_pos = Vector2(sample["boss_pos"])
		game.boss_phase = float(sample["boss_phase"])
		game.boss_attack_timer = float(sample["boss_attack_timer"])
	if not bool(game.boss1_rewind_sequence.get("rewind_local_player", true)):
		return
	game.player_pos = Vector2(sample["player_pos"])
	game.player_hp = clampi(int(round(float(sample["player_hp"]))), 1, int(game.player_hp_max))
	game.last_facing = Vector2(sample["last_facing"])
	game.last_attack_time = float(sample["last_attack"])
	game.last_dash_time = float(sample["last_dash"])
	game.last_skill_time = float(sample["last_skill"])
	game.last_secondary_time = float(sample["last_secondary"])
	game.last_damage_time = float(sample["last_damage"])
	game.boss1_rewind_visual_projectiles = Array(sample.get("projectiles", [])).duplicate(true)


func update_boss1_rewind_sequence(delta: float) -> void:
	if game.boss1_rewind_sequence.is_empty():
		return
	game.boss1_rewind_sequence["elapsed"] = float(game.boss1_rewind_sequence.get("elapsed", 0.0)) + delta
	var elapsed = float(game.boss1_rewind_sequence["elapsed"])
	update_boss1_rewind_feedback(delta, elapsed)
	if elapsed < game.BOSS1_CLOCK_TRAVEL_TIME:
		return
	var progress = clamp((elapsed - game.BOSS1_CLOCK_TRAVEL_TIME) / game.BOSS1_CLOCK_TURN_TIME, 0.0, 1.0)
	apply_boss1_rewind_sample(boss1_rewind_interpolated_sample(progress))
	if progress >= 1.0:
		finish_boss1_rewind()


func update_boss1_rewind_feedback(delta: float, elapsed: float) -> void:
	game.boss1_rewind_vibration_timer -= delta
	if game.boss1_rewind_vibration_timer <= 0.0:
		game.boss1_rewind_vibration_timer = 0.9
		game._vibrate(95, 0.3)
	if elapsed >= game.BOSS1_CLOCK_TRAVEL_TIME and elapsed <= game.BOSS1_CLOCK_TRAVEL_TIME + game.BOSS1_CLOCK_TURN_TIME:
		var turn_progress = clamp((elapsed - game.BOSS1_CLOCK_TRAVEL_TIME) / game.BOSS1_CLOCK_TURN_TIME, 0.0, 1.0)
		var tick = int(floor(turn_progress * 10.0))
		if tick != game.boss1_rewind_clock_tick:
			game.boss1_rewind_clock_tick = tick
			game._play_sfx("shop_countdown_tick", 0.015, 0.52, 0.82 + turn_progress * 0.14)


func finish_boss1_rewind() -> void:
	if game.boss1_rewind_sequence.is_empty():
		return
	var heal = float(game.boss1_rewind_sequence.get("boss_heal", 0.0))
	if not game.boss1_rewind_history.is_empty():
		apply_boss1_rewind_sample(game.boss1_rewind_history[0])
	if game._is_world_authority():
		game.boss_hp = min(game.boss_hp_max, game.boss_hp + heal)
	if bool(game.boss1_rewind_sequence.get("rewind_local_player", true)):
		game.player_hp = clampi(int(round(float(game.boss1_rewind_sequence.get("player_final_hp", game.player_hp)))), 1, int(game.player_hp_max))
	game.bullets.clear()
	game.remote_bullets.clear()
	game.return_bullets.clear()
	game.enemy_bullets.clear()
	game.eletrica_waves.clear()
	game.eletrica_chains.clear()
	game.eletrica_recoil_velocity = Vector2.ZERO
	game.shockwaves.clear()
	game.slashes.clear()
	game.prisms.clear()
	game.orbitals.clear()
	game.seed_links.clear()
	game.parasite_spit_zones.clear()
	game.manifestation_secondaries.clear()
	game.effects.clear()
	game.boss_attacks.clear()
	game.boss_transition_waves.clear()
	game.boss1_rewind_history.clear()
	game.boss1_rewind_visual_projectiles.clear()
	game.boss1_rewind_sequence.clear()
	game.boss1_rewind_sample_timer = 0.0
	game.boss1_rewind_vibration_timer = 0.0
	game.boss1_rewind_clock_tick = -1
	game.boss_attack_timer = max(1.4, game.boss_attack_timer)
	game._add_text("-%.0fs  /  BOSS +40%%  /  GEO +25%%" % game.BOSS1_REWIND_SECONDS, game.boss_pos + Vector2(0, -120), Color(0.42, 0.94, 1.0), 1.8, 24)
	game._spawn_radial_particles(game.boss_pos, Color(0.3, 0.78, 1.0), 36)
