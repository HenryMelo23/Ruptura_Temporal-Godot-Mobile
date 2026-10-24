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


# Boss 1 - Pinças em Tenaz. Runtime state intentionally remains on the root so
# snapshots, authority and existing core RPC contracts keep their current shape.
func boss1_pincer_target_prediction(target: Dictionary, prediction: float) -> Vector2:
	var base_pos: Vector2 = Vector2(target.get("pos", game.player_pos))
	if bool(target.get("local", false)):
		return (base_pos + game._read_move() * game.player_speed * prediction).clamp(Vector2(70, 80), game.WORLD_SIZE - Vector2(70, 80))
	var peer_id: int = int(target.get("peer_id", 0))
	var state: Dictionary = game.net_players_by_peer.get(peer_id, {})
	return (base_pos + Vector2(state.get("velocity", Vector2.ZERO)) * prediction).clamp(Vector2(70, 80), game.WORLD_SIZE - Vector2(70, 80))


func boss1_pincer_target_excluding(excluded_peer_id: int) -> Dictionary:
	var candidates: Array = []
	for target_value in game._combat_targets():
		var target: Dictionary = target_value
		if int(target.get("peer_id", 0)) != excluded_peer_id:
			candidates.append(target)
	if candidates.is_empty():
		return {}
	return game._choose_boss_target(candidates)


func boss1_pincer_prepare_leg(attack: Dictionary, prefix: String, target: Dictionary, prediction: float) -> void:
	var origin: Vector2 = game.boss_pos
	var target_pos: Vector2 = boss1_pincer_target_prediction(target, prediction)
	var direction: Vector2 = (target_pos - origin).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	var end_pos: Vector2 = (origin + direction * 680.0).clamp(Vector2(76, 76), game.WORLD_SIZE - Vector2(76, 76))
	attack["%s_target_peer_id" % prefix] = int(target.get("peer_id", 0))
	attack["%s_target_pos" % prefix] = target_pos
	attack["%s_origin" % prefix] = origin
	attack["%s_dir" % prefix] = (end_pos - origin).normalized()
	attack["%s_end" % prefix] = end_pos


func add_boss1_pincer_tenaz() -> void:
	game._ensure_boss_party_scaling_context(1)
	var first_target: Dictionary = game._boss_target_entry(true)
	var second_target: Dictionary = boss1_pincer_target_excluding(int(first_target.get("peer_id", 0)))
	if second_target.is_empty():
		second_target = first_target.duplicate(true)
	game.boss1_pincer_tenaz_sequence += 1
	var gap: float = game._boss_party_scaled_interval(game.BOSS1_PINCER_TENAZ_GAP, 0.62)
	var attack: Dictionary = {
		"kind": "pincer_tenaz",
		"event_id": "%s-%d" % [game.BOSS1_PINCER_TENAZ_EVENT_PREFIX, game.boss1_pincer_tenaz_sequence],
		"seed": game.rng.randi(),
		"started_ms": Time.get_ticks_msec(),
		"party_size": clampi(game.boss_party_scaling_size, 1, game.ONLINE_MAX_PLAYERS),
		"age": 0.0,
		"state_age": 0.0,
		"state": "telegraph_first",
		"duration": game.BOSS1_PINCER_TENAZ_WARNING * 2.0 + game.BOSS1_PINCER_TENAZ_DASH_TIME * 2.0 + gap + 0.55,
		"gap": gap,
		"dash_time": game.BOSS1_PINCER_TENAZ_DASH_TIME,
		"warning": game.BOSS1_PINCER_TENAZ_WARNING,
		"width": game.BOSS1_PINCER_TENAZ_WIDTH,
		"strike_index": 0,
		"first_hit": false,
		"second_hit": false,
		"impact": false,
		"first_target_peer_id": int(first_target.get("peer_id", 0)),
		"second_target_peer_id": int(second_target.get("peer_id", 0))
	}
	boss1_pincer_prepare_leg(attack, "first", first_target, 0.22)
	boss1_pincer_prepare_leg(attack, "second", second_target, 0.20)
	game._add_boss_attack(attack)
	game._play_sfx("boss1_dash", 0.018, 0.72, 0.88)


func boss1_pincer_resolve_second_leg(attack: Dictionary) -> void:
	var first_peer_id: int = int(attack.get("first_target_peer_id", 0))
	var second_target: Dictionary = boss1_pincer_target_excluding(first_peer_id)
	var prediction: float = 0.20
	if second_target.is_empty():
		second_target = {
			"peer_id": first_peer_id,
			"pos": Vector2(attack.get("first_target_pos", game.player_pos)),
			"local": first_peer_id == game._mp_unique_id()
		}
		prediction = 0.12
	attack["second_target_peer_id"] = int(second_target.get("peer_id", first_peer_id))
	boss1_pincer_prepare_leg(attack, "second", second_target, prediction)


func update_boss1_pincer_dash(attack: Dictionary, prefix: String, delta: float) -> bool:
	var state_age: float = float(attack.get("state_age", 0.0)) + delta
	attack["state_age"] = state_age
	var dash_time: float = maxf(0.1, float(attack.get("dash_time", game.BOSS1_PINCER_TENAZ_DASH_TIME)))
	var progress: float = clampf(state_age / dash_time, 0.0, 1.0)
	var old_pos: Vector2 = game.boss_pos
	var origin: Vector2 = Vector2(attack.get("%s_origin" % prefix, game.boss_pos))
	var end_pos: Vector2 = Vector2(attack.get("%s_end" % prefix, game.boss_pos))
	game.boss_pos = origin.lerp(end_pos, progress)
	var dir: Vector2 = Vector2(attack.get("%s_dir" % prefix, Vector2.RIGHT)).normalized()
	attack["last_dash_from"] = old_pos
	attack["last_dash_to"] = game.boss_pos
	for trail_index in range(2):
		game.effects.append({"pos": old_pos + dir.orthogonal() * (trail_index * 18.0 - 9.0), "vel": -dir * (90.0 + trail_index * 22.0), "life": 0.16, "max": 0.16, "color": Color(0.92, 0.48, 0.16, 0.48), "size": 10.0 + trail_index * 3.0, "kind": "trail"})
	var damage: int = int(game.player_hp_max * 0.18 + 85)
	var hit_key: String = "%s_hit" % prefix
	if not bool(attack.get(hit_key, false)) and game._local_player_damageable_by_contact() and game._distance_to_segment(game.player_pos, old_pos, game.boss_pos) <= float(attack.get("width", game.BOSS1_PINCER_TENAZ_WIDTH)):
		attack[hit_key] = true
		game._damage_player(damage, "boss_rush")
	game._damage_remote_player_on_segment(old_pos, game.boss_pos, float(attack.get("width", game.BOSS1_PINCER_TENAZ_WIDTH)), damage, "boss_rush", attack, "%s_remote" % prefix)
	return progress >= 1.0


func update_boss1_pincer_tenaz(attack: Dictionary, delta: float) -> void:
	var state: String = String(attack.get("state", "telegraph_first"))
	var state_age: float = float(attack.get("state_age", 0.0))
	var warning: float = float(attack.get("warning", game.BOSS1_PINCER_TENAZ_WARNING))
	match state:
		"telegraph_first":
			state_age += delta
			attack["state_age"] = state_age
			if state_age >= warning:
				attack["state"] = "dash_first"
				attack["state_age"] = 0.0
				attack["strike_index"] = 1
				game._play_sfx("boss1_dash", 0.018, 0.72, 0.88)
		"dash_first":
			if update_boss1_pincer_dash(attack, "first", delta):
				attack["state"] = "gap"
				attack["state_age"] = 0.0
		"gap":
			state_age += delta
			attack["state_age"] = state_age
			if state_age >= float(attack.get("gap", game.BOSS1_PINCER_TENAZ_GAP)):
				boss1_pincer_resolve_second_leg(attack)
				attack["state"] = "telegraph_second"
				attack["state_age"] = 0.0
				attack["strike_index"] = 2
		"telegraph_second":
			state_age += delta
			attack["state_age"] = state_age
			if state_age >= warning:
				attack["state"] = "dash_second"
				attack["state_age"] = 0.0
				game._play_sfx("boss1_dash", 0.018, 0.72, 1.02)
		"dash_second":
			if update_boss1_pincer_dash(attack, "second", delta):
				attack["state"] = "recovery"
				attack["state_age"] = 0.0
				if not bool(attack.get("impact_played", false)):
					attack["impact_played"] = true
					# Replicas use the shared event ledger to present this transition
					# exactly once; damage remains exclusively authoritative.
					attack["impact"] = true
					game._spawn_radial_particles(game.boss_pos, Color(1.0, 0.52, 0.16), 14)
					game._play_sfx("boss_impact", 0.02, 0.74, 0.96)
		"recovery":
			state_age += delta
			attack["state_age"] = state_age
			if state_age >= 0.42:
				attack["age"] = float(attack.get("duration", 1.0))


func reset_boss1_environmental_mechanics() -> void:
	game.boss1_whirlpool_sequence = 0
	game.boss1_whirlpool_cooldown = game.BOSS1_WHIRLPOOL_INITIAL_DELAY
	game.boss1_lightning_storm_active = false
	game.boss1_lightning_spawn_timer = 0.0
	game.boss1_lightning_sequence = 0
	game.boss_attacks = game.boss_attacks.filter(func(value):
		return String(Dictionary(value).get("kind", "")) not in ["boss1_whirlpool", "boss1_lightning"]
	)
	game.shared_boss_attack_contract.forget_visual_events_with_prefix(game.BOSS1_WHIRLPOOL_EVENT_PREFIX)
	game.shared_boss_attack_contract.forget_visual_events_with_prefix(game.BOSS1_LIGHTNING_EVENT_PREFIX)


func boss1_attack_by_kind(kind: String) -> Dictionary:
	for value in game.boss_attacks:
		var attack := Dictionary(value)
		if String(attack.get("kind", "")) == kind:
			return attack
	return {}


func start_boss1_whirlpool() -> void:
	if game.current_phase != 1 or game.boss_dead or game.boss_hp <= 0.0 or not boss1_attack_by_kind("boss1_whirlpool").is_empty():
		return
	game.boss1_whirlpool_sequence += 1
	var event: Dictionary = game.shared_boss_attack_contract.make_authoritative_event(
		game.BOSS1_WHIRLPOOL_EVENT_PREFIX,
		game.boss1_whirlpool_sequence,
		game.rng.randi(),
		0,
		Time.get_ticks_msec()
	)
	var attack: Dictionary = game.shared_boss_attack_contract.build_telegraphed_attack("boss1_whirlpool", event, {
		"age": 0.0,
		"duration": game.BOSS1_WHIRLPOOL_APPROACH_TIMEOUT + game.BOSS1_WHIRLPOOL_ACTIVE_DURATION + game.BOSS1_WHIRLPOOL_DRY_DURATION + 0.5,
		"state": "approach",
		"state_age": 0.0,
		"center": game.WORLD_SIZE * 0.5,
		"world_radius": _boss1_whirlpool_world_radius(game.WORLD_SIZE * 0.5),
		"spin_direction": -1.0 if game.rng.randf() < 0.5 else 1.0,
		"beam_count": clampi(game.boss1_whirlpool_sequence, 1, 4),
		"beam_start_angle": game.rng.randf_range(-PI, PI),
		"laser_warning": game.BOSS1_WHIRLPOOL_LASER_WARNING,
		"laser_rotation_duration": game.BOSS1_WHIRLPOOL_LASER_ROTATION_DURATION,
		"laser_inner_radius": game.BOSS1_WHIRLPOOL_LASER_INNER_RADIUS,
		"laser_half_width": game.BOSS1_WHIRLPOOL_LASER_HALF_WIDTH,
		"impact": false
	})
	game._add_boss_attack(attack)
	game.boss1_whirlpool_cooldown = game.BOSS1_WHIRLPOOL_COOLDOWN
	game.boss_attack_timer = float(attack["duration"]) + 0.8
	game._add_text("REDOMOINHO DA RUPTURA", game.WORLD_SIZE * 0.5 + Vector2(0.0, -150.0), Color(0.3, 0.9, 1.0), 1.6, 27)
	game._add_text("RAIO ROTATIVO x%d" % int(attack["beam_count"]), game.WORLD_SIZE * 0.5 + Vector2(0.0, -116.0), Color(0.66, 0.96, 1.0), 1.35, 20)
	game._play_sfx("boss1_spin", 0.02, 0.68, 0.82)


func _boss1_whirlpool_world_radius(center: Vector2) -> float:
	var farthest := 0.0
	for corner in [Vector2.ZERO, Vector2(game.WORLD_SIZE.x, 0.0), Vector2(0.0, game.WORLD_SIZE.y), game.WORLD_SIZE]:
		farthest = maxf(farthest, center.distance_to(corner))
	return maxf(1080.0, farthest + 140.0)


func update_boss1_whirlpool(delta: float) -> bool:
	var attack := boss1_attack_by_kind("boss1_whirlpool")
	if attack.is_empty():
		return false
	attack["age"] = float(attack.get("age", 0.0)) + delta
	attack["state_age"] = float(attack.get("state_age", 0.0)) + delta
	var center: Vector2 = Vector2(attack.get("center", game.WORLD_SIZE * 0.5))
	match String(attack.get("state", "approach")):
		"approach":
			game.boss_phase += delta * 9.0
			game.boss_pos = game.boss_pos.move_toward(center, game.BOSS1_WHIRLPOOL_APPROACH_SPEED * delta)
			if game.boss_pos.distance_to(center) <= 5.0 or float(attack["state_age"]) >= game.BOSS1_WHIRLPOOL_APPROACH_TIMEOUT:
				game.boss_pos = center
				attack["state"] = "active"
				attack["state_age"] = 0.0
				game._spawn_radial_particles(center, Color(0.28, 0.88, 1.0), 22)
		"active":
			game.boss_pos = center
			game.boss_phase += delta * 24.0 * float(attack.get("spin_direction", 1.0))
			apply_boss1_whirlpool_force(delta, attack)
			apply_boss1_whirlpool_lasers(delta, attack)
			if float(attack["state_age"]) >= game.BOSS1_WHIRLPOOL_ACTIVE_DURATION:
				attack["state"] = "drying"
				attack["state_age"] = 0.0
				attack["impact"] = true
				game._play_sfx("boss_impact", 0.02, 0.42, 0.72)
		"drying":
			game.boss_pos = center
			game.boss_phase += delta * 3.0 * float(attack.get("spin_direction", 1.0))
			if float(attack["state_age"]) >= game.BOSS1_WHIRLPOOL_DRY_DURATION:
				game.boss_attacks = game.boss_attacks.filter(func(value): return String(Dictionary(value).get("kind", "")) != "boss1_whirlpool")
				game.boss_attack_timer = maxf(game.boss_attack_timer, 1.1)
	return true


func boss1_whirlpool_laser_angle(attack: Dictionary, beam_index: int) -> float:
	var warning: float = maxf(0.0, float(attack.get("laser_warning", game.BOSS1_WHIRLPOOL_LASER_WARNING)))
	var rotation_duration: float = maxf(0.01, float(attack.get("laser_rotation_duration", game.BOSS1_WHIRLPOOL_LASER_ROTATION_DURATION)))
	var rotation_age: float = maxf(0.0, float(attack.get("state_age", 0.0)) - warning)
	var rotation_progress: float = clampf(rotation_age / rotation_duration, 0.0, 1.0)
	var beam_count: int = clampi(int(attack.get("beam_count", 1)), 1, 4)
	return float(attack.get("beam_start_angle", 0.0)) + float(attack.get("spin_direction", 1.0)) * TAU * rotation_progress + TAU * float(beam_index) / float(beam_count)


func boss1_whirlpool_laser_hit_index(attack: Dictionary, target_pos: Vector2) -> int:
	if String(attack.get("state", "")) != "active":
		return -1
	var warning: float = maxf(0.0, float(attack.get("laser_warning", game.BOSS1_WHIRLPOOL_LASER_WARNING)))
	if float(attack.get("state_age", 0.0)) < warning:
		return -1
	var center: Vector2 = Vector2(attack.get("center", game.WORLD_SIZE * 0.5))
	var offset: Vector2 = target_pos - center
	var inner_radius: float = maxf(0.0, float(attack.get("laser_inner_radius", game.BOSS1_WHIRLPOOL_LASER_INNER_RADIUS)))
	var world_radius: float = maxf(inner_radius, float(attack.get("world_radius", 1080.0)))
	var half_width: float = maxf(1.0, float(attack.get("laser_half_width", game.BOSS1_WHIRLPOOL_LASER_HALF_WIDTH)))
	var beam_count: int = clampi(int(attack.get("beam_count", 1)), 1, 4)
	for beam_index in range(beam_count):
		var direction := Vector2.from_angle(boss1_whirlpool_laser_angle(attack, beam_index))
		var along: float = offset.dot(direction)
		if along < inner_radius or along > world_radius:
			continue
		if absf(offset.cross(direction)) <= half_width:
			return beam_index
	return -1


func apply_boss1_whirlpool_lasers(delta: float, attack_override: Dictionary = {}) -> void:
	var attack := attack_override if not attack_override.is_empty() else boss1_attack_by_kind("boss1_whirlpool")
	if attack.is_empty() or String(attack.get("state", "")) != "active":
		return
	var local_peer_id: int = game._mp_unique_id() if game.is_multiplayer else 0
	_boss1_whirlpool_laser_damage_target(delta, attack, game.player_pos, local_peer_id, false)
	for peer_id in game._targetable_remote_peer_ids():
		var state: Dictionary = game.net_players_by_peer.get(peer_id, {})
		_boss1_whirlpool_laser_damage_target(delta, attack, Vector2(state.get("pos", Vector2.ZERO)), peer_id, true)


func _boss1_whirlpool_laser_damage_target(delta: float, attack: Dictionary, target_pos: Vector2, peer_id: int, remote: bool) -> void:
	var cooldown_key := "laser_hit_cd_%d" % peer_id
	attack[cooldown_key] = maxf(0.0, float(attack.get(cooldown_key, 0.0)) - delta)
	if float(attack[cooldown_key]) > 0.0 or boss1_whirlpool_laser_hit_index(attack, target_pos) < 0:
		return
	if not remote and not game._local_player_damageable_by_contact():
		return
	attack[cooldown_key] = game.BOSS1_WHIRLPOOL_LASER_HIT_COOLDOWN
	var max_hp: float = game.net_player_hp_max if remote else game.player_hp_max
	var damage: int = maxi(1, int(round(max_hp * game.BOSS1_WHIRLPOOL_LASER_DAMAGE_RATE + game.BOSS1_WHIRLPOOL_LASER_DAMAGE_FLAT)))
	if remote:
		game._send_peer_damage(peer_id, damage, "boss1_whirlpool_laser")
	else:
		game._damage_player(damage, "boss1_whirlpool_laser")
	game._play_sfx("boss_impact", 0.025, 0.28, 1.24)


func apply_boss1_whirlpool_force(delta: float, attack_override: Dictionary = {}) -> void:
	if not game._local_player_damageable_by_contact():
		return
	var attack := attack_override if not attack_override.is_empty() else boss1_attack_by_kind("boss1_whirlpool")
	if attack.is_empty() or String(attack.get("state", "")) != "active":
		return
	var center: Vector2 = Vector2(attack.get("center", game.WORLD_SIZE * 0.5))
	var to_center: Vector2 = center - game.player_pos
	var distance: float = to_center.length()
	if distance <= 20.0:
		return
	var radial: Vector2 = to_center / distance
	var tangent: Vector2 = radial.orthogonal() * float(attack.get("spin_direction", 1.0))
	var inner_strength: float = 1.0 - clampf(distance / maxf(1.0, game.WORLD_SIZE.length() * 0.55), 0.0, 1.0)
	var pull_speed: float = game.BOSS1_WHIRLPOOL_PULL_SPEED * lerpf(0.72, 1.0, inner_strength)
	var force: Vector2 = (radial * pull_speed + tangent * game.BOSS1_WHIRLPOOL_TANGENT_SPEED) * delta
	game.player_pos = game._clamp_player_world(game.player_pos + game._hostile_knockback(force))


func update_boss1_timeout_storm(delta: float) -> void:
	if game.current_phase != 1 or not game.boss_active or game.boss_dead or game.boss_hp <= 0.0:
		return
	if not game.boss1_lightning_storm_active:
		var started_at: float = float(game.run_boss_started_at.get(1, -1.0))
		if started_at < 0.0 or game.time_alive - started_at < game.BOSS1_LIGHTNING_START_TIME:
			return
		game.boss1_lightning_storm_active = true
		game.boss1_lightning_spawn_timer = 0.15
		game._add_text("TEMPESTADE CRONAL", game.WORLD_SIZE * 0.5 + Vector2(0.0, -168.0), Color(0.42, 0.82, 1.0), 1.8, 29)
		game._play_sfx("boss_impact", 0.02, 0.5, 1.28)

	var boss_damage_pending: float = 0.0
	var active_count := 0
	for value in game.boss_attacks:
		var strike := Dictionary(value)
		if String(strike.get("kind", "")) != "boss1_lightning":
			continue
		active_count += 1
		strike["age"] = float(strike.get("age", 0.0)) + delta
		var age: float = float(strike["age"])
		var warning: float = float(strike.get("warning", game.BOSS1_LIGHTNING_WARNING))
		if age >= warning and game.shared_boss_attack_contract.claim_impact(strike):
			var target: Vector2 = Vector2(strike.get("target", game.WORLD_SIZE * 0.5))
			var radius: float = float(strike.get("radius", game.BOSS1_LIGHTNING_RADIUS))
			var local_damage := int(game.player_hp_max * game.BOSS1_LIGHTNING_PLAYER_DAMAGE_RATE + game.BOSS1_LIGHTNING_PLAYER_DAMAGE_FLAT)
			if game.player_pos.distance_to(target) <= radius and game._local_player_damageable_by_contact():
				strike["hit_local"] = true
				game._damage_player(local_damage, "boss1_lightning")
			game._damage_remote_player_in_radius(target, radius, int(game.net_player_hp_max * game.BOSS1_LIGHTNING_PLAYER_DAMAGE_RATE + game.BOSS1_LIGHTNING_PLAYER_DAMAGE_FLAT), "boss1_lightning", strike, "lightning_remote")
			if game.boss_pos.distance_to(target) <= radius:
				strike["boss_hit"] = true
				boss_damage_pending += game.boss_hp_max * game.BOSS1_LIGHTNING_BOSS_DAMAGE_RATE
			game.screen_shake_timer = maxf(game.screen_shake_timer, 0.2)
			game.screen_shake_strength = maxf(game.screen_shake_strength, 11.0)
			game._spawn_radial_particles(target, Color(0.5, 0.88, 1.0), 18)
			game._play_sfx("boss_impact", 0.018, 0.58, 1.34)

	game.boss_attacks = game.boss_attacks.filter(func(value):
		var attack := Dictionary(value)
		return String(attack.get("kind", "")) != "boss1_lightning" or float(attack.get("age", 0.0)) < float(attack.get("duration", game.BOSS1_LIGHTNING_LIFETIME))
	)
	if boss_damage_pending > 0.0 and game.boss_active and game.boss_hp > 0.0:
		game._damage_boss(boss_damage_pending, "boss1_lightning", false, false, "environment", game.boss_pos)
		if not game.boss_active or game.boss_dead:
			return

	game.boss1_lightning_spawn_timer -= delta
	if game.boss1_lightning_spawn_timer > 0.0 or active_count >= game.BOSS1_LIGHTNING_MAX_ACTIVE:
		return
	spawn_boss1_lightning_strike()
	game.boss1_lightning_spawn_timer = game.rng.randf_range(game.BOSS1_LIGHTNING_MIN_INTERVAL, game.BOSS1_LIGHTNING_MAX_INTERVAL)


func spawn_boss1_lightning_strike() -> void:
	game.boss1_lightning_sequence += 1
	var event: Dictionary = game.shared_boss_attack_contract.make_authoritative_event(
		game.BOSS1_LIGHTNING_EVENT_PREFIX,
		game.boss1_lightning_sequence,
		game.rng.randi(),
		0,
		Time.get_ticks_msec()
	)
	var margin: Vector2 = Vector2(game.BOSS1_LIGHTNING_RADIUS + 28.0, game.BOSS1_LIGHTNING_RADIUS + 28.0)
	var target: Vector2 = Vector2(
		game.rng.randf_range(margin.x, game.WORLD_SIZE.x - margin.x),
		game.rng.randf_range(margin.y, game.WORLD_SIZE.y - margin.y)
	)
	game._add_boss_attack(game.shared_boss_attack_contract.build_telegraphed_attack("boss1_lightning", event, {
		"target": target,
		"age": 0.0,
		"warning": game.BOSS1_LIGHTNING_WARNING,
		"duration": game.BOSS1_LIGHTNING_LIFETIME,
		"radius": game.BOSS1_LIGHTNING_RADIUS,
		"impact": false,
		"boss_hit": false,
		"hit_local": false
	}))
	game._play_sfx("boss_impact", 0.018, 0.34, 1.42)
