class_name RTPhase2SineiroBorealController
extends Node

const TYPE_ID := "sineiro_boreal"

const STATE_ENTRY := "entry"
const STATE_APPROACH := "approach"
const STATE_POSITION := "position"
const STATE_TELEGRAPH := "telegraph"
const STATE_ATTACK := "attack"
const STATE_RECOVERY := "recovery"
const STATE_EXHAUSTED := "exhausted"
const STATE_STAGGER := "stagger"
const STATE_DYING := "dying"
const STATE_DESPAWN := "despawn"

const ATTACK_ECHO := "badalada_passado"
const ATTACK_SHARDS := "estilhacos_ressonantes"

const SPAWN_TIME_ONBOARDING := 300.0
const SPAWN_TIME_EXPERIENCED := 240.0
const ACTIVE_LIFETIME := 110.0
const ENTRY_TIME := 1.05
const ECHO_TELEGRAPH_TIME := 1.10
const SHARD_TELEGRAPH_TIME := 0.80
const ATTACK_COMMIT_TIME := 0.12
const EXHAUSTION_TIME := 1.60
const RETREAT_TIME := 0.90
const ECHO_COOLDOWN := 7.0
const LOW_HP_COOLDOWN_MULT := 0.82
const HISTORY_WINDOW := 2.25
const HISTORY_SAMPLE_INTERVAL := 0.12
const ECHO_RADIUS := 48.0
const ECHO_MIN_SPACING := 88.0
const PREFERRED_MIN_DISTANCE := 200.0
const PREFERRED_MAX_DISTANCE := 330.0
const MOVE_SPEED := 112.0
const VISUAL_SYNC_INTERVAL := 0.28
const REWARD_CARD_COUNT := 2
const REWARD_POINT_RATIO := 0.35

const PARTY_HP_MULTIPLIERS := {
	1: 1.0,
	2: 1.70,
	3: 2.35,
}

var game: Node
var _history_by_peer: Dictionary = {}
var _history_sample_timer := 0.0
var _sync_timer := 0.0
var _seen_visual_events: Dictionary = {}


func bind_game(p_game: Node) -> void:
	game = p_game
	if game.sineiro_boreal_state.is_empty():
		game.sineiro_boreal_state = _default_state()


func spawn_time_for_profile(experienced: bool) -> float:
	return SPAWN_TIME_EXPERIENCED if experienced else SPAWN_TIME_ONBOARDING


func hp_multiplier_for_party(party_size: int) -> float:
	return float(PARTY_HP_MULTIPLIERS.get(clampi(party_size, 1, 3), PARTY_HP_MULTIPLIERS[3]))


func _default_state() -> Dictionary:
	return {
		"spawned": false,
		"active": false,
		"encounter_id": "",
		"enemy_uid": -1,
		"party_size": 1,
		"hp_multiplier": 1.0,
		"battle_elapsed": 0.0,
		"reward_processed": false,
		"processed_reward_ids": {},
		"event_sequence": 0,
		"cleanup_reason": "",
	}


func reset_for_new_run() -> void:
	if game == null:
		return
	game.sineiro_boreal_state = _default_state()
	game.sineiro_echo_marks.clear()
	game.sineiro_visual_events.clear()
	_history_by_peer.clear()
	_history_sample_timer = 0.0
	_sync_timer = 0.0
	_seen_visual_events.clear()


func update(delta: float) -> void:
	if game == null:
		return
	_update_local_visual_state(delta)
	if game.current_phase != 2:
		if game._is_world_authority() and bool(game.sineiro_boreal_state.get("active", false)):
			cleanup("phase_changed")
		return
	if game.mode == "boss_call" or game.boss_active or game.phase_transition_timer > 0.0:
		if game._is_world_authority() and bool(game.sineiro_boreal_state.get("active", false)):
			cleanup("boss_or_transition")
		return
	if not game._is_world_authority():
		return
	_sample_player_history(delta)
	if bool(game.sineiro_boreal_state.get("active", false)):
		game.sineiro_boreal_state["battle_elapsed"] = float(game.sineiro_boreal_state.get("battle_elapsed", 0.0)) + delta
		var enemy := active_enemy()
		if enemy.is_empty():
			game.sineiro_boreal_state["active"] = false
			game.sineiro_echo_marks.clear()
			return
		if float(game.sineiro_boreal_state.get("battle_elapsed", 0.0)) >= ACTIVE_LIFETIME and String(enemy.get("sineiro_state", "")) != STATE_DESPAWN:
			_begin_retreat(enemy)
		_sync_timer -= delta
		if game.is_multiplayer and _sync_timer <= 0.0:
			_sync_timer = VISUAL_SYNC_INTERVAL
			rpc("_rpc_sineiro_snapshot", _build_visual_snapshot(enemy))
	else:
		_try_spawn()


func _try_spawn() -> void:
	if bool(game.sineiro_boreal_state.get("spawned", false)):
		return
	if game.mode != "game" or game.boss_active or game.boss_dead or game.boss_call_timer >= 0.0:
		return
	if game._arauto_active() or game._bargain_capsule_active() or game.runtime_event_director.is_active():
		return
	if game.fusion_check_timer > 0.0:
		return
	var spawn_time := spawn_time_for_profile(game._pacing_experienced_active())
	if game._phase_elapsed_time() < spawn_time:
		return
	spawn_now()


func spawn_now() -> Dictionary:
	if game == null or not game._is_world_authority() or game.current_phase != 2:
		return {}
	if not active_enemy().is_empty():
		return active_enemy()
	var spawn_pos: Vector2 = game._spawn_point_on_edge().clamp(Vector2(90.0, 90.0), game.WORLD_SIZE - Vector2(90.0, 90.0))
	var previous_count: int = game.enemies.size()
	game._spawn_enemy(TYPE_ID, spawn_pos)
	if game.enemies.size() <= previous_count:
		return {}
	var enemy: Dictionary = game.enemies.back()
	var party_size: int = clampi(game._active_run_player_count(), 1, 3)
	var hp_multiplier: float = hp_multiplier_for_party(party_size)
	var solo_hp: float = maxf(3000.0, game.enemy_base_hp * 16.0)
	var hp: float = solo_hp * hp_multiplier
	var encounter_id := "sineiro_%d_%d" % [int(game.time_alive * 1000.0), int(enemy.get("uid", previous_count + 1))]
	enemy["type"] = TYPE_ID
	enemy["is_mini_boss"] = true
	enemy["mini_boss"] = true
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["points"] = 0
	enemy["damage"] = maxf(1.0, game.player_hp_max * 0.045 + game.enemy_close_damage * 0.55)
	enemy["speed"] = minf(145.0, maxf(92.0, MOVE_SPEED + game.enemy_speed_base * 0.08))
	enemy["parado"] = true
	enemy["state"] = STATE_ENTRY
	enemy["sineiro_state"] = STATE_ENTRY
	enemy["sineiro_state_timer"] = ENTRY_TIME
	enemy["sineiro_attack_kind"] = ""
	enemy["sineiro_action_cd"] = 1.25
	enemy["sineiro_echo_cd"] = 1.25
	enemy["sineiro_attack_anim_timer"] = 0.0
	enemy["sineiro_target_switch"] = 0.0
	enemy["sineiro_target_cursor"] = -1
	enemy["sineiro_attack_dir"] = Vector2.LEFT
	enemy["sineiro_strafe_sign"] = -1.0 if game.rng.randf() < 0.5 else 1.0
	enemy["sineiro_anim_time"] = 0.0
	enemy["facing_dir"] = Vector2.LEFT
	enemy["last_move_dir"] = Vector2.ZERO
	enemy["contact_grace"] = ENTRY_TIME
	enemy["reconstituted_once"] = true
	game.sineiro_boreal_state = _default_state()
	game.sineiro_boreal_state.merge({
		"spawned": true,
		"active": true,
		"encounter_id": encounter_id,
		"enemy_uid": int(enemy.get("uid", -1)),
		"party_size": party_size,
		"hp_multiplier": hp_multiplier,
	}, true)
	_history_by_peer.clear()
	game.event_alert_text = "O SINEIRO BOREAL DESPERTOU!"
	game.event_alert_timer = 3.2
	game.event_alert_seed = int(enemy.get("uid", 0))
	game._add_text("O SINEIRO BOREAL DESPERTOU!", spawn_pos + Vector2(-190.0, -132.0), Color(0.58, 0.94, 1.0), 2.8, 27)
	game._play_sfx("Congelando.mp3", 0.03, 0.78, 0.78)
	_emit_visual_event("entry", {"pos": spawn_pos, "uid": int(enemy.get("uid", -1))})
	return enemy


func active_enemy() -> Dictionary:
	if game == null:
		return {}
	var expected_uid := int(game.sineiro_boreal_state.get("enemy_uid", -1))
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("type", "")) != TYPE_ID:
			continue
		if expected_uid < 0 or int(enemy.get("uid", -2)) == expected_uid:
			return enemy
	return {}


func update_enemy(enemy: Dictionary, delta: float) -> void:
	if game == null or not game._is_world_authority() or String(enemy.get("type", "")) != TYPE_ID:
		return
	enemy["parado"] = true
	enemy["sineiro_anim_time"] = float(enemy.get("sineiro_anim_time", 0.0)) + delta
	enemy["sineiro_attack_anim_timer"] = maxf(0.0, float(enemy.get("sineiro_attack_anim_timer", 0.0)) - delta)
	enemy["sineiro_echo_cd"] = maxf(0.0, float(enemy.get("sineiro_echo_cd", 0.0)) - delta)
	var state := String(enemy.get("sineiro_state", STATE_APPROACH))
	if state == STATE_DESPAWN:
		_update_retreat(enemy, delta)
		return
	if float(enemy.get("stun", 0.0)) > 0.0 or float(enemy.get("ferrolho_root", 0.0)) > 0.0:
		if state not in [STATE_ENTRY, STATE_STAGGER, STATE_DYING]:
			enemy["sineiro_resume_state"] = state
			enemy["sineiro_resume_timer"] = float(enemy.get("sineiro_state_timer", 0.0))
			_set_state(enemy, STATE_STAGGER, maxf(float(enemy.get("stun", 0.0)), float(enemy.get("ferrolho_root", 0.0))))
		enemy["last_move_dir"] = Vector2.ZERO
		return
	if state == STATE_STAGGER:
		state = String(enemy.get("sineiro_resume_state", STATE_APPROACH))
		_set_state(enemy, state, float(enemy.get("sineiro_resume_timer", 0.0)))
		enemy.erase("sineiro_resume_state")
		enemy.erase("sineiro_resume_timer")
	match state:
		STATE_ENTRY:
			enemy["sineiro_state_timer"] = float(enemy.get("sineiro_state_timer", ENTRY_TIME)) - delta
			enemy["last_move_dir"] = Vector2.ZERO
			if float(enemy["sineiro_state_timer"]) <= 0.0:
				_set_state(enemy, STATE_APPROACH, 0.0)
		STATE_TELEGRAPH:
			_update_telegraph(enemy, delta)
		STATE_ATTACK:
			enemy["sineiro_state_timer"] = float(enemy.get("sineiro_state_timer", ATTACK_COMMIT_TIME)) - delta
			enemy["last_move_dir"] = Vector2.ZERO
			if float(enemy["sineiro_state_timer"]) <= 0.0:
				if String(enemy.get("sineiro_attack_kind", "")) == ATTACK_ECHO:
					_execute_echo_attack(enemy)
				else:
					_execute_shard_attack(enemy)
		STATE_EXHAUSTED:
			enemy["sineiro_state_timer"] = float(enemy.get("sineiro_state_timer", EXHAUSTION_TIME)) - delta
			enemy["last_move_dir"] = Vector2.ZERO
			if float(enemy["sineiro_state_timer"]) <= 0.0:
				_set_state(enemy, STATE_APPROACH, 0.0)
		STATE_RECOVERY:
			enemy["sineiro_state_timer"] = float(enemy.get("sineiro_state_timer", 0.75)) - delta
			enemy["last_move_dir"] = Vector2.ZERO
			if float(enemy["sineiro_state_timer"]) <= 0.0:
				_set_state(enemy, STATE_APPROACH, 0.0)
		_:
			_update_positioning(enemy, delta)


func damage_taken_multiplier(enemy: Dictionary) -> float:
	if String(enemy.get("type", "")) == TYPE_ID and String(enemy.get("sineiro_state", "")) == STATE_EXHAUSTED:
		return 1.15
	return 1.0


func _update_positioning(enemy: Dictionary, delta: float) -> void:
	var target := _select_target(enemy, delta)
	if target.is_empty():
		enemy["last_move_dir"] = Vector2.ZERO
		return
	var pos := Vector2(enemy.get("pos", game.player_pos))
	var target_pos := Vector2(target.get("pos", game.player_pos))
	var to_target := target_pos - pos
	var distance := to_target.length()
	var toward := to_target.normalized() if distance > 0.01 else Vector2.RIGHT
	var lateral := toward.orthogonal() * float(enemy.get("sineiro_strafe_sign", 1.0))
	var move_dir := Vector2.ZERO
	var next_state := STATE_POSITION
	if distance > PREFERRED_MAX_DISTANCE:
		move_dir = toward
		next_state = STATE_APPROACH
	elif distance < PREFERRED_MIN_DISTANCE:
		move_dir = (-toward + lateral * 0.42).normalized()
		next_state = STATE_POSITION
	else:
		move_dir = lateral * 0.58
		next_state = STATE_POSITION
	var margin := Vector2(78.0, 82.0)
	var candidate: Vector2 = (pos + move_dir * float(enemy.get("speed", MOVE_SPEED)) * delta).clamp(margin, game.WORLD_SIZE - margin)
	if candidate.distance_squared_to(pos) <= 0.04:
		enemy["sineiro_strafe_sign"] = -float(enemy.get("sineiro_strafe_sign", 1.0))
		move_dir = -lateral
		candidate = (pos + move_dir * float(enemy.get("speed", MOVE_SPEED)) * delta).clamp(margin, game.WORLD_SIZE - margin)
	enemy["pos"] = candidate
	enemy["last_move_dir"] = move_dir
	if absf(move_dir.x) > 0.02:
		enemy["facing_dir"] = Vector2(signf(move_dir.x), 0.0)
	enemy["sineiro_state"] = next_state
	enemy["state"] = next_state
	var hp_ratio := float(enemy.get("hp", 1.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0)))
	var cadence_mult := LOW_HP_COOLDOWN_MULT if hp_ratio <= 0.40 else 1.0
	enemy["sineiro_action_cd"] = maxf(0.0, float(enemy.get("sineiro_action_cd", 0.0)) - delta / cadence_mult)
	if float(enemy.get("sineiro_action_cd", 0.0)) <= 0.0:
		if float(enemy.get("sineiro_echo_cd", 0.0)) <= 0.0:
			_begin_echo_attack(enemy)
		else:
			_begin_shard_attack(enemy, target_pos)


func _select_target(enemy: Dictionary, delta: float) -> Dictionary:
	var targets: Array = game._combat_targets()
	if targets.is_empty():
		return {}
	enemy["sineiro_target_switch"] = maxf(0.0, float(enemy.get("sineiro_target_switch", 0.0)) - delta)
	var current_peer := int(enemy.get("target_peer_id", 0))
	if float(enemy.get("sineiro_target_switch", 0.0)) > 0.0:
		for target_value in targets:
			var current: Dictionary = target_value
			if int(current.get("peer_id", 0)) == current_peer:
				return current
	var cursor := posmod(int(enemy.get("sineiro_target_cursor", -1)) + 1, targets.size())
	var selected: Dictionary = targets[cursor]
	enemy["sineiro_target_cursor"] = cursor
	enemy["target_peer_id"] = int(selected.get("peer_id", 0))
	enemy["sineiro_target_switch"] = 3.6
	return selected


func _begin_echo_attack(enemy: Dictionary) -> void:
	var marks := build_echo_positions()
	if marks.is_empty():
		enemy["sineiro_action_cd"] = 0.8
		return
	var event_id := _next_event_id("echo")
	for mark_value in marks:
		var mark: Dictionary = mark_value
		mark["event_id"] = event_id
		mark["phase"] = "telegraph"
		mark["age"] = 0.0
		mark["life"] = ECHO_TELEGRAPH_TIME
		mark["max_life"] = ECHO_TELEGRAPH_TIME
	_set_state(enemy, STATE_TELEGRAPH, ECHO_TELEGRAPH_TIME)
	enemy["sineiro_attack_kind"] = ATTACK_ECHO
	enemy["sineiro_attack_event_id"] = event_id
	enemy["sineiro_echo_positions"] = marks.duplicate(true)
	enemy["sineiro_attack_anim_timer"] = ECHO_TELEGRAPH_TIME
	_emit_visual_event("echo_start", {"event_id": event_id, "marks": marks, "origin": Vector2(enemy.get("pos", game.player_pos))})
	game._play_sfx("Congelando.mp3", 0.02, 0.62, 0.66)


func _begin_shard_attack(enemy: Dictionary, target_pos: Vector2) -> void:
	var origin := Vector2(enemy.get("pos", game.player_pos))
	var direction := (target_pos - origin).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.LEFT
	_set_state(enemy, STATE_TELEGRAPH, SHARD_TELEGRAPH_TIME)
	enemy["sineiro_attack_kind"] = ATTACK_SHARDS
	enemy["sineiro_attack_event_id"] = _next_event_id("shards")
	enemy["sineiro_attack_dir"] = direction
	enemy["sineiro_attack_anim_timer"] = SHARD_TELEGRAPH_TIME
	_emit_visual_event("shard_prepare", {
		"event_id": String(enemy["sineiro_attack_event_id"]),
		"origin": origin,
		"direction": direction,
	})


func _update_telegraph(enemy: Dictionary, delta: float) -> void:
	enemy["sineiro_state_timer"] = float(enemy.get("sineiro_state_timer", 0.0)) - delta
	enemy["last_move_dir"] = Vector2.ZERO
	if float(enemy["sineiro_state_timer"]) > 0.0:
		return
	_set_state(enemy, STATE_ATTACK, ATTACK_COMMIT_TIME)
	enemy["sineiro_attack_anim_timer"] = ATTACK_COMMIT_TIME + 0.20


func _execute_echo_attack(enemy: Dictionary) -> void:
	var event_id := String(enemy.get("sineiro_attack_event_id", _next_event_id("echo_impact")))
	var damage := maxi(1, int(game.player_hp_max * 0.082 + game.enemy_far_damage * 0.72))
	var targets: Array = game._combat_targets()
	var attack_marks: Array = enemy.get("sineiro_echo_positions", game.sineiro_echo_marks)
	for target_value in targets:
		var target: Dictionary = target_value
		var peer_id := int(target.get("peer_id", 0))
		var target_pos := Vector2(target.get("pos", game.player_pos))
		var inside := false
		for mark_value in attack_marks:
			var mark: Dictionary = mark_value
			if String(mark.get("event_id", "")) == event_id and target_pos.distance_to(Vector2(mark.get("pos", target_pos))) <= float(mark.get("radius", ECHO_RADIUS)):
				inside = true
				break
		if not inside:
			continue
		if bool(target.get("local", false)):
			game._damage_player(damage, TYPE_ID)
		else:
			game._send_peer_damage(peer_id, damage, TYPE_ID)
	_emit_visual_event("echo_impact", {"event_id": event_id, "marks": attack_marks.duplicate(true), "origin": Vector2(enemy.get("pos", game.player_pos))})
	enemy.erase("sineiro_echo_positions")
	game._play_sfx("Congelando.mp3", 0.025, 0.84, 0.86)
	_set_state(enemy, STATE_EXHAUSTED, EXHAUSTION_TIME)
	enemy["sineiro_attack_anim_timer"] = 0.38
	enemy["sineiro_echo_cd"] = ECHO_COOLDOWN
	enemy["sineiro_action_cd"] = ECHO_COOLDOWN
	game._add_text("SINO EXAUSTO: +15% DANO", Vector2(enemy.get("pos", game.player_pos)) + Vector2(-105.0, -116.0), Color(0.72, 0.94, 1.0), 1.2, 17)


func _execute_shard_attack(enemy: Dictionary) -> void:
	var origin := Vector2(enemy.get("pos", game.player_pos))
	var direction := Vector2(enemy.get("sineiro_attack_dir", Vector2.LEFT)).normalized()
	var damage := maxi(1, int(game.player_hp_max * 0.055 + game.enemy_far_damage * 0.58))
	for angle in [-0.18, 0.0, 0.18]:
		game.enemy_bullets.append({
			"pos": origin + direction * 48.0,
			"dir": direction.rotated(float(angle)),
			"life": 4.2,
			"damage": damage,
			"phase": game.rng.randf_range(0.0, TAU),
			"type": "sineiro_shard",
			"speed_mult": 1.18,
			"radius": 12.0,
			"hit_radius": 18.0,
		})
	_emit_visual_event("shard_attack", {
		"event_id": String(enemy.get("sineiro_attack_event_id", _next_event_id("shards_fire"))),
		"origin": origin,
		"direction": direction,
	})
	_set_state(enemy, STATE_RECOVERY, 0.72)
	enemy["sineiro_attack_anim_timer"] = 0.34
	enemy["sineiro_action_cd"] = 2.65


func _sample_player_history(delta: float) -> void:
	_history_sample_timer -= delta
	if _history_sample_timer > 0.0:
		return
	_history_sample_timer = HISTORY_SAMPLE_INTERVAL
	var now: float = float(game._phase_elapsed_time())
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


func build_echo_positions() -> Array:
	var targets: Array = game._combat_targets()
	var result: Array = []
	if targets.is_empty():
		return result
	var desired_count: int = mini(3, maxi(2, targets.size()))
	if targets.size() == 1:
		var solo_peer := int(Dictionary(targets[0]).get("peer_id", 0))
		_append_spaced_mark(result, _historical_position(solo_peer, 1.85, Vector2(Dictionary(targets[0]).get("pos", game.player_pos))))
		_append_spaced_mark(result, _historical_position(solo_peer, 0.95, Vector2(Dictionary(targets[0]).get("pos", game.player_pos))))
	else:
		for target_value in targets:
			var target: Dictionary = target_value
			_append_spaced_mark(result, _historical_position(int(target.get("peer_id", 0)), 1.55, Vector2(target.get("pos", game.player_pos))))
			if result.size() >= desired_count:
				break
	while result.size() < desired_count:
		var source := Vector2(Dictionary(targets[result.size() % targets.size()]).get("pos", game.player_pos))
		_append_spaced_mark(result, source + Vector2.from_angle(float(result.size()) * 2.39996) * 104.0)
	return result


func _historical_position(peer_id: int, seconds_ago: float, fallback: Vector2) -> Vector2:
	var samples: Array = _history_by_peer.get(peer_id, [])
	if samples.is_empty():
		return fallback
	var target_time: float = float(game._phase_elapsed_time()) - seconds_ago
	var best_pos: Vector2 = fallback
	var best_delta: float = INF
	for sample_value in samples:
		var sample: Dictionary = sample_value
		var distance := absf(float(sample.get("time", target_time)) - target_time)
		if distance < best_delta:
			best_delta = distance
			best_pos = Vector2(sample.get("pos", fallback))
	return best_pos


func _append_spaced_mark(result: Array, requested: Vector2) -> void:
	var margin := Vector2(ECHO_RADIUS + 18.0, ECHO_RADIUS + 18.0)
	var candidate := requested.clamp(margin, game.WORLD_SIZE - margin)
	for existing_value in result:
		var existing := Vector2(Dictionary(existing_value).get("pos", candidate))
		if candidate.distance_to(existing) < ECHO_MIN_SPACING:
			var away := (candidate - existing).normalized()
			if away.length() <= 0.01:
				away = Vector2.from_angle(float(result.size() + 1) * 2.39996)
			candidate = (existing + away * ECHO_MIN_SPACING).clamp(margin, game.WORLD_SIZE - margin)
	result.append({"pos": candidate, "radius": ECHO_RADIUS})


func on_enemy_defeated(enemy: Dictionary) -> void:
	if game == null or not game._is_world_authority() or String(enemy.get("type", "")) != TYPE_ID:
		return
	var encounter_id := String(game.sineiro_boreal_state.get("encounter_id", ""))
	var reward_id := "%s_reward" % encounter_id
	var processed: Dictionary = game.sineiro_boreal_state.get("processed_reward_ids", {})
	if reward_id == "_reward" or processed.has(reward_id):
		return
	processed[reward_id] = true
	game.sineiro_boreal_state["processed_reward_ids"] = processed
	game.sineiro_boreal_state["reward_processed"] = true
	game.sineiro_boreal_state["active"] = false
	_set_state(enemy, STATE_DYING, 1.05)
	var pos := Vector2(enemy.get("pos", game.player_pos))
	game._spawn_random_card_drops(pos, REWARD_CARD_COUNT, 0)
	var points := maxi(1, int(round(float(game.card_cost) * REWARD_POINT_RATIO)))
	game._apply_score_delta(points, true, reward_id + ":points")
	game._add_text("2 CARTAS POR JOGADOR", pos + Vector2(-108.0, -130.0), Color(0.72, 0.94, 1.0), 1.8, 20)
	game._add_text("+%d PONTOS" % points, pos + Vector2(-62.0, -98.0), Color(1.0, 0.84, 0.28), 1.5, 19)
	game._play_sfx("Descongelando.mp3", 0.03, 0.82, 0.72)
	_emit_visual_event("death", {"event_id": reward_id, "pos": pos})
	_clear_hostile_state()


func cleanup(reason: String) -> void:
	if game == null:
		return
	var enemy: Dictionary = active_enemy()
	var pos: Vector2 = Vector2(enemy.get("pos", game.player_pos)) if not enemy.is_empty() else game.player_pos
	if not enemy.is_empty():
		game.enemies.erase(enemy)
	game.sineiro_boreal_state["active"] = false
	game.sineiro_boreal_state["cleanup_reason"] = reason
	_clear_hostile_state()
	_emit_visual_event("cleanup", {"pos": pos, "reason": reason})


func _begin_retreat(enemy: Dictionary) -> void:
	_set_state(enemy, STATE_DESPAWN, RETREAT_TIME)
	enemy["contact_grace"] = RETREAT_TIME
	game._add_text("O ECO CONGELADO SE DISSIPA", Vector2(enemy.get("pos", game.player_pos)) + Vector2(-132.0, -116.0), Color(0.62, 0.82, 1.0), 1.4, 18)


func _update_retreat(enemy: Dictionary, delta: float) -> void:
	enemy["sineiro_state_timer"] = float(enemy.get("sineiro_state_timer", RETREAT_TIME)) - delta
	enemy["alpha"] = clampf(float(enemy.get("sineiro_state_timer", 0.0)) / RETREAT_TIME, 0.0, 1.0)
	if float(enemy["sineiro_state_timer"]) > 0.0:
		return
	var pos := Vector2(enemy.get("pos", game.player_pos))
	game.enemies.erase(enemy)
	game.sineiro_boreal_state["active"] = false
	game.sineiro_boreal_state["cleanup_reason"] = "timeout"
	_clear_hostile_state()
	_emit_visual_event("cleanup", {"pos": pos, "reason": "timeout"})


func _clear_hostile_state() -> void:
	game.sineiro_echo_marks.clear()
	game.enemy_bullets = game.enemy_bullets.filter(func(bullet): return String(Dictionary(bullet).get("type", "")) != "sineiro_shard")


func _set_state(enemy: Dictionary, state: String, timer: float) -> void:
	enemy["sineiro_state"] = state
	enemy["state"] = state
	enemy["sineiro_state_timer"] = timer


func _next_event_id(kind: String) -> String:
	var sequence := int(game.sineiro_boreal_state.get("event_sequence", 0)) + 1
	game.sineiro_boreal_state["event_sequence"] = sequence
	return "%s_%s_%d" % [String(game.sineiro_boreal_state.get("encounter_id", "sineiro")), kind, sequence]


func _emit_visual_event(kind: String, data: Dictionary) -> void:
	var payload := data.duplicate(true)
	payload["kind"] = kind
	if not payload.has("event_id"):
		payload["event_id"] = _next_event_id(kind)
	_apply_visual_event(payload)
	if game.is_multiplayer and game._is_world_authority():
		rpc("_rpc_sineiro_event", payload)


@rpc("authority", "call_remote", "reliable")
func _rpc_sineiro_event(payload: Dictionary) -> void:
	_apply_visual_event(payload)


func _apply_visual_event(payload: Dictionary) -> void:
	var event_id := String(payload.get("event_id", ""))
	var kind := String(payload.get("kind", ""))
	if event_id != "" and _seen_visual_events.has(event_id) and kind not in ["echo_impact", "cleanup"]:
		return
	if event_id != "":
		_seen_visual_events[event_id] = true
	match kind:
		"entry":
			game.sineiro_visual_events.append({"kind": "entry", "pos": Vector2(payload.get("pos", game.player_pos)), "age": 0.0, "life": 1.05, "max_life": 1.05})
		"echo_start":
			game.sineiro_echo_marks = Array(payload.get("marks", [])).duplicate(true)
		"echo_impact":
			game.sineiro_echo_marks = Array(payload.get("marks", game.sineiro_echo_marks)).duplicate(true)
			for mark_value in game.sineiro_echo_marks:
				var mark: Dictionary = mark_value
				if String(mark.get("event_id", "")) == event_id:
					mark["phase"] = "impact"
					mark["age"] = 0.0
					mark["life"] = 0.52
					mark["max_life"] = 0.52
		"shard_prepare":
			game.sineiro_visual_events.append({"kind": "shard_prepare", "pos": Vector2(payload.get("origin", game.player_pos)), "dir": Vector2(payload.get("direction", Vector2.LEFT)), "age": 0.0, "life": SHARD_TELEGRAPH_TIME, "max_life": SHARD_TELEGRAPH_TIME})
		"shard_attack":
			game.sineiro_visual_events.append({"kind": "shard_attack", "pos": Vector2(payload.get("origin", game.player_pos)), "dir": Vector2(payload.get("direction", Vector2.LEFT)), "age": 0.0, "life": 0.42, "max_life": 0.42})
		"death":
			game.sineiro_echo_marks.clear()
			game.sineiro_visual_events.append({"kind": "death", "pos": Vector2(payload.get("pos", game.player_pos)), "age": 0.0, "life": 1.05, "max_life": 1.05})
		"cleanup":
			game.sineiro_echo_marks.clear()
			game.sineiro_visual_events.append({"kind": "dissipate", "pos": Vector2(payload.get("pos", game.player_pos)), "age": 0.0, "life": 0.72, "max_life": 0.72})
	if _seen_visual_events.size() > 96:
		var keys: Array = _seen_visual_events.keys()
		while _seen_visual_events.size() > 64 and not keys.is_empty():
			_seen_visual_events.erase(keys.pop_front())


func _update_local_visual_state(delta: float) -> void:
	for mark_value in game.sineiro_echo_marks:
		var mark: Dictionary = mark_value
		mark["age"] = float(mark.get("age", 0.0)) + delta
		mark["life"] = float(mark.get("life", 0.0)) - delta
	game.sineiro_echo_marks = game.sineiro_echo_marks.filter(func(mark):
		var value: Dictionary = mark
		return String(value.get("phase", "telegraph")) == "telegraph" or float(value.get("life", 0.0)) > 0.0
	)
	for event_value in game.sineiro_visual_events:
		var event: Dictionary = event_value
		event["age"] = float(event.get("age", 0.0)) + delta
		event["life"] = float(event.get("life", 0.0)) - delta
	game.sineiro_visual_events = game.sineiro_visual_events.filter(func(event): return float(Dictionary(event).get("life", 0.0)) > 0.0)


func _build_visual_snapshot(enemy: Dictionary) -> Dictionary:
	return {
		"encounter_id": String(game.sineiro_boreal_state.get("encounter_id", "")),
		"enemy_uid": int(enemy.get("uid", -1)),
		"party_size": int(game.sineiro_boreal_state.get("party_size", 1)),
		"state": String(enemy.get("sineiro_state", STATE_APPROACH)),
		"state_timer": float(enemy.get("sineiro_state_timer", 0.0)),
		"attack_kind": String(enemy.get("sineiro_attack_kind", "")),
		"attack_anim_timer": float(enemy.get("sineiro_attack_anim_timer", 0.0)),
		"anim_time": float(enemy.get("sineiro_anim_time", 0.0)),
		"facing_dir": Vector2(enemy.get("facing_dir", Vector2.LEFT)),
		"last_move_dir": Vector2(enemy.get("last_move_dir", Vector2.ZERO)),
		"marks": game.sineiro_echo_marks.duplicate(true),
	}


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_sineiro_snapshot(snapshot: Dictionary) -> void:
	if game == null or game._is_world_authority():
		return
	game.sineiro_boreal_state["spawned"] = true
	game.sineiro_boreal_state["active"] = true
	game.sineiro_boreal_state["encounter_id"] = String(snapshot.get("encounter_id", ""))
	game.sineiro_boreal_state["enemy_uid"] = int(snapshot.get("enemy_uid", -1))
	game.sineiro_boreal_state["party_size"] = int(snapshot.get("party_size", 1))
	var enemy := active_enemy()
	if not enemy.is_empty():
		enemy["sineiro_state"] = String(snapshot.get("state", STATE_APPROACH))
		enemy["state"] = String(snapshot.get("state", STATE_APPROACH))
		enemy["sineiro_state_timer"] = float(snapshot.get("state_timer", 0.0))
		enemy["sineiro_attack_kind"] = String(snapshot.get("attack_kind", ""))
		enemy["sineiro_attack_anim_timer"] = float(snapshot.get("attack_anim_timer", 0.0))
		enemy["sineiro_anim_time"] = float(snapshot.get("anim_time", 0.0))
		enemy["facing_dir"] = Vector2(snapshot.get("facing_dir", Vector2.LEFT))
		enemy["last_move_dir"] = Vector2(snapshot.get("last_move_dir", Vector2.ZERO))
	game.sineiro_echo_marks = Array(snapshot.get("marks", [])).duplicate(true)
