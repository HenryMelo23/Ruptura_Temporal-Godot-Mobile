class_name RTPhase6AmberSuturerController
extends Node

const TYPE_ID := "suturador_ambar"
const NODE_TYPE_ID := "sutura_ambar_node"

const STATE_ENTRY := "entry"
const STATE_OBSERVE := "observe"
const STATE_TELEGRAPH := "telegraph"
const STATE_ACTIVE := "active"
const STATE_NEEDLE_TELEGRAPH := "needle_telegraph"
const STATE_NEEDLE_RECOVERY := "needle_recovery"
const STATE_HOOK_TELEGRAPH := "hook_telegraph"
const STATE_HOOK_RECOVERY := "hook_recovery"
const STATE_REPOSITION := "reposition"
const STATE_DYING := "dying"

# Phase-local cadence, matching the recurring pressure role used by Larápio
# while leaving a short random window between Suturador encounters.
const FIRST_SPAWN_TIME := 120.0
const RESPAWN_MIN_TIME := 120.0
const RESPAWN_MAX_TIME := 150.0
const MAX_LIFETIME := INF
const ENTRY_TIME := 1.0
const OBSERVE_TIME := 2.1
const TELEGRAPH_TIME := 1.5
const ACTIVE_TIME := 9.5
const REPOSITION_TIME := 1.15
const NEEDLE_TELEGRAPH_TIME := 0.85
const NEEDLE_RECOVERY_TIME := 0.72
const NEEDLE_FAN_COUNT := 5
const NEEDLE_RADIAL_COUNT := 12
const HOOK_TELEGRAPH_TIME := 1.0
const HOOK_RECOVERY_TIME := 0.82
const HOOK_RANGE := 720.0
const HOOK_PULL_DISTANCE := 104.0
const HOOK_STUN_TIME := 0.65
const MAX_STOLEN_CARDS := 2
const REWARD_CARD_COUNT := 2
const HISTORY_SAMPLE_INTERVAL := 0.12
const HISTORY_WINDOW := 2.8
const DAMAGE_MAX_HP_RATIO := 0.05
const DAMAGE_INTERVAL := 1.2
const SUTURE_RADIUS := 17.0
const NODE_RADIUS := 27.0
const MAX_ACTIVE_SUTURES := 2
const MAX_LINE_LENGTH := 820.0
const MIN_LINE_LENGTH := 520.0
const MOVE_SPEED := 59.0
const CRYSTAL_SLOW_PER_STACK := 0.20
const CRYSTAL_SLOW_DURATION := 7.0
const CRYSTAL_SLOW_MAX_STACKS := 4
const CAST_STRAFE_MULT := 0.48
const ACTIVE_STRAFE_MULT := 0.34
const RECOVERY_STRAFE_MULT := 0.72
const EVASION_HP_RATIO := 0.07
const EVASION_COOLDOWN := 2.4

const STEALABLE_CARD_IDS: Array[String] = [
	"Speed Boost",
	"Disparo crescente",
	"Tempestade",
	"Roubo de Vida",
	"Speed Atack",
	"Teleporte",
	"Defesa",
	"Sorte",
]

const PARTY_HP_MULTIPLIERS := {
	1: 1.0,
	2: 1.75,
	3: 2.40,
}

var game: Node
var _history_by_peer: Dictionary = {}
var _history_sample_timer := 0.0
var _target_cursor := -1
var _remote_card_change_state: Dictionary = {}
var _remote_card_change_order: Array[String] = []


func bind_game(p_game: Node) -> void:
	game = p_game
	if game.amber_suturer_state.is_empty():
		game.amber_suturer_state = _default_state()


func _default_state() -> Dictionary:
	return {
		"active": false,
		"encounter_id": "",
		"enemy_uid": -1,
		"party_size": 1,
		"hp_multiplier": 1.0,
		"battle_elapsed": 0.0,
		"next_spawn_phase_time": FIRST_SPAWN_TIME,
		"last_end_phase_time": -1.0,
		"event_sequence": 0,
		"cycle": 0,
		"ability_cycle": 0,
		"current_ability": "suture",
		"target_peer_id": 0,
		"state": STATE_ENTRY,
		"state_timer": 0.0,
		"anim_time": 0.0,
		"damage_gate_by_peer": {},
		"crystal_slow_stacks": 0,
		"crystal_slow_timer": 0.0,
		"crystals_destroyed_cycle": 0,
		"effective_speed": MOVE_SPEED,
		"stolen_cards": [],
		"cleanup_reason": "",
	}


func reset_for_new_run() -> void:
	if game == null:
		return
	game.amber_suturer_state = _default_state()
	game.amber_sutures.clear()
	game.amber_suturer_visual_events.clear()
	_history_by_peer.clear()
	_history_sample_timer = 0.0
	_target_cursor = -1
	_remote_card_change_state.clear()
	_remote_card_change_order.clear()


func reset_for_phase() -> void:
	if game == null:
		return
	cleanup("phase_reset", false)
	reset_for_new_run()


func hp_multiplier_for_party(party_size: int) -> float:
	return float(PARTY_HP_MULTIPLIERS.get(clampi(party_size, 1, 3), PARTY_HP_MULTIPLIERS[3]))


func update(delta: float) -> void:
	if game == null:
		return
	_update_visual_events(delta)
	if game.current_phase != 6:
		if game._is_world_authority() and bool(game.amber_suturer_state.get("active", false)):
			cleanup("phase_changed")
		return
	if not game._is_world_authority():
		return
	if _event_incompatible():
		# The boss gate prevents normal coexistence. Cleanup here is only a
		# defensive recovery for legacy saves that already contain both actors.
		if bool(game.amber_suturer_state.get("active", false)) and (game.boss_active or game.boss_dead):
			cleanup("incompatible_state")
		return
	_sample_player_history(delta)
	if bool(game.amber_suturer_state.get("active", false)):
		game.amber_suturer_state["battle_elapsed"] = float(game.amber_suturer_state.get("battle_elapsed", 0.0)) + delta
		_update_damage_gates(delta)
		if active_enemy().is_empty():
			_finish_event("enemy_missing")
			return
	else:
		_try_spawn()


func _event_incompatible() -> bool:
	if game.mode != "game":
		return true
	if game.boss_active or game.boss_dead or game.boss_call_timer >= 0.0 or game.phase_transition_timer > 0.0:
		return true
	return false


func _try_spawn() -> void:
	if float(game._phase_elapsed_time()) < float(game.amber_suturer_state.get("next_spawn_phase_time", FIRST_SPAWN_TIME)):
		return
	spawn_now()


func spawn_now() -> Dictionary:
	if game == null or not game._is_world_authority() or game.current_phase != 6 or _event_incompatible():
		return {}
	var existing := active_enemy()
	if not existing.is_empty():
		return existing
	var spawn_pos: Vector2 = game._spawn_point_on_edge().clamp(Vector2(100.0, 90.0), game.WORLD_SIZE - Vector2(100.0, 90.0))
	var previous_count: int = game.enemies.size()
	game._spawn_enemy(TYPE_ID, spawn_pos)
	if game.enemies.size() <= previous_count:
		return {}
	var enemy: Dictionary = game.enemies.back()
	var party_size := clampi(game._active_run_player_count(), 1, 3)
	var hp_multiplier := hp_multiplier_for_party(party_size)
	var solo_hp := maxf(3200.0, game.enemy_base_hp * 16.0)
	var hp := solo_hp * hp_multiplier
	var encounter_id := "suturador_%d_%d" % [int(game._phase_elapsed_time() * 1000.0), int(enemy.get("uid", previous_count + 1))]
	enemy["type"] = TYPE_ID
	enemy["is_event_enemy"] = true
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["points"] = 260
	enemy["damage"] = maxf(1.0, game.player_hp_max * 0.04 + game.enemy_close_damage * 0.45)
	enemy["speed"] = MOVE_SPEED
	enemy["suturer_base_speed"] = MOVE_SPEED
	enemy["suturer_crystal_slow_stacks"] = 0
	enemy["suturer_crystal_slow_timer"] = 0.0
	enemy["parado"] = false
	enemy["state"] = STATE_ENTRY
	enemy["suturer_state"] = STATE_ENTRY
	enemy["suturer_state_timer"] = ENTRY_TIME
	enemy["suturer_anim_time"] = 0.0
	enemy["suturer_target_peer"] = 0
	enemy["suturer_reposition_dir"] = Vector2.ZERO
	enemy["suturer_attack_dir"] = Vector2.LEFT
	enemy["suturer_needle_pattern"] = "fan"
	enemy["suturer_evasion_cd"] = 0.0
	enemy["suturer_last_hp"] = hp
	enemy["contact_grace"] = ENTRY_TIME
	enemy["reconstituted_once"] = true
	game.amber_suturer_state = _default_state()
	game.amber_suturer_state.merge({
		"active": true,
		"encounter_id": encounter_id,
		"enemy_uid": int(enemy.get("uid", -1)),
		"party_size": party_size,
		"hp_multiplier": hp_multiplier,
		"next_spawn_phase_time": INF,
		"state": STATE_ENTRY,
		"state_timer": ENTRY_TIME,
	}, true)
	_history_by_peer.clear()
	game.event_alert_text = "O SUTURADOR DE AMBAR COSTURA A CHAGA!"
	game.event_alert_timer = 3.2
	game.event_alert_seed = int(enemy.get("uid", 0))
	# Match Larápio's readable arrival cue: edge spawns must not push the title
	# outside the current camera view.
	game._add_text("SUTURADOR DE AMBAR", game.player_pos + Vector2(0.0, -150.0), Color(1.0, 0.66, 0.18), 2.5, 25)
	game._play_sfx("Lodario-mov.mp3", 0.03, 0.66, 0.74)
	_emit_visual_event("entry", {"pos": spawn_pos})
	return enemy


func active_enemy() -> Dictionary:
	if game == null:
		return {}
	var expected_uid := int(game.amber_suturer_state.get("enemy_uid", -1))
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("type", "")) == TYPE_ID and (expected_uid < 0 or int(enemy.get("uid", -2)) == expected_uid):
			return enemy
	return {}


func update_enemy(enemy: Dictionary, delta: float) -> void:
	if game == null or not game._is_world_authority() or String(enemy.get("type", "")) != TYPE_ID:
		return
	if game._update_bargain_capsule_controller_enemy(enemy, delta):
		return
	enemy["parado"] = false
	enemy["suturer_anim_time"] = float(enemy.get("suturer_anim_time", 0.0)) + delta
	enemy["suturer_evasion_cd"] = maxf(0.0, float(enemy.get("suturer_evasion_cd", 0.0)) - delta)
	_update_crystal_slow(enemy, delta)
	var state := String(enemy.get("suturer_state", STATE_ENTRY))
	if state == STATE_DYING:
		return
	match state:
		STATE_ENTRY:
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_set_state(enemy, STATE_OBSERVE, OBSERVE_TIME)
		STATE_OBSERVE:
			_update_observation_movement(enemy, delta)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_begin_attack_cycle(enemy)
		STATE_TELEGRAPH:
			_update_combat_strafe(enemy, delta, CAST_STRAFE_MULT)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_activate_sutures(enemy)
		STATE_ACTIVE:
			_update_combat_strafe(enemy, delta, ACTIVE_STRAFE_MULT)
			_update_active_sutures(delta)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_clear_sutures("cycle_complete")
				_begin_reposition(enemy)
		STATE_NEEDLE_TELEGRAPH:
			_update_combat_strafe(enemy, delta, CAST_STRAFE_MULT)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_fire_needle_attack(enemy)
		STATE_NEEDLE_RECOVERY:
			_update_combat_strafe(enemy, delta, RECOVERY_STRAFE_MULT)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_begin_reposition(enemy)
		STATE_HOOK_TELEGRAPH:
			_update_combat_strafe(enemy, delta, CAST_STRAFE_MULT)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_fire_hook(enemy)
		STATE_HOOK_RECOVERY:
			_update_combat_strafe(enemy, delta, RECOVERY_STRAFE_MULT)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_begin_reposition(enemy)
		STATE_REPOSITION:
			_update_reposition(enemy, delta)
			_tick_state(enemy, delta)
			if float(enemy.get("suturer_state_timer", 0.0)) <= 0.0:
				_set_state(enemy, STATE_OBSERVE, OBSERVE_TIME)
	_try_damage_evasion(enemy)
	_sync_public_enemy_state(enemy)


func update_node(enemy: Dictionary, _delta: float) -> void:
	if String(enemy.get("type", "")) != NODE_TYPE_ID:
		return
	enemy["parado"] = true
	enemy["last_move_dir"] = Vector2.ZERO
	enemy["contact_grace"] = 999.0


func _tick_state(enemy: Dictionary, delta: float) -> void:
	enemy["suturer_state_timer"] = maxf(0.0, float(enemy.get("suturer_state_timer", 0.0)) - delta)


func _set_state(enemy: Dictionary, state: String, timer: float) -> void:
	enemy["suturer_state"] = state
	enemy["state"] = state
	enemy["suturer_state_timer"] = timer
	_sync_public_enemy_state(enemy)


func _sync_public_enemy_state(enemy: Dictionary) -> void:
	game.amber_suturer_state["state"] = String(enemy.get("suturer_state", STATE_ENTRY))
	game.amber_suturer_state["state_timer"] = float(enemy.get("suturer_state_timer", 0.0))
	game.amber_suturer_state["anim_time"] = float(enemy.get("suturer_anim_time", 0.0))
	game.amber_suturer_state["facing_dir"] = Vector2(enemy.get("facing_dir", Vector2.LEFT))
	game.amber_suturer_state["last_move_dir"] = Vector2(enemy.get("last_move_dir", Vector2.ZERO))
	game.amber_suturer_state["current_ability"] = String(enemy.get("suturer_current_ability", "suture"))
	game.amber_suturer_state["crystal_slow_stacks"] = int(enemy.get("suturer_crystal_slow_stacks", 0))
	game.amber_suturer_state["crystal_slow_timer"] = float(enemy.get("suturer_crystal_slow_timer", 0.0))
	game.amber_suturer_state["effective_speed"] = _effective_move_speed(enemy)


func _update_crystal_slow(enemy: Dictionary, delta: float) -> void:
	var timer := maxf(0.0, float(enemy.get("suturer_crystal_slow_timer", 0.0)) - delta)
	if timer <= 0.0:
		enemy["suturer_crystal_slow_stacks"] = 0
		timer = 0.0
	enemy["suturer_crystal_slow_timer"] = timer


func _effective_move_speed(enemy: Dictionary) -> float:
	var base_speed := float(enemy.get("suturer_base_speed", MOVE_SPEED))
	var stacks := clampi(int(enemy.get("suturer_crystal_slow_stacks", 0)), 0, CRYSTAL_SLOW_MAX_STACKS)
	return base_speed * maxf(0.20, 1.0 - float(stacks) * CRYSTAL_SLOW_PER_STACK)


func _update_observation_movement(enemy: Dictionary, delta: float) -> void:
	var target := _target_by_peer(int(enemy.get("suturer_target_peer", 0)))
	if target.is_empty():
		target = _select_next_target()
		if target.is_empty():
			enemy["last_move_dir"] = Vector2.ZERO
			return
		enemy["suturer_target_peer"] = int(target.get("peer_id", 0))
	var pos := Vector2(enemy.get("pos", game.player_pos))
	var target_pos := Vector2(target.get("pos", game.player_pos))
	var toward := (target_pos - pos).normalized()
	if toward.length_squared() <= 0.01:
		toward = Vector2.RIGHT
	var lateral := toward.orthogonal() * (-1.0 if int(enemy.get("uid", 0)) % 2 == 0 else 1.0)
	var distance := pos.distance_to(target_pos)
	var move_dir := lateral
	if distance > 410.0:
		move_dir = (toward * 0.78 + lateral * 0.22).normalized()
	elif distance < 220.0:
		move_dir = (-toward * 0.72 + lateral * 0.28).normalized()
	var next_pos := (pos + move_dir * _effective_move_speed(enemy) * delta).clamp(Vector2(86.0, 78.0), game.WORLD_SIZE - Vector2(86.0, 78.0))
	enemy["pos"] = next_pos
	enemy["last_move_dir"] = move_dir
	if absf(move_dir.x) > 0.02:
		enemy["facing_dir"] = Vector2(signf(move_dir.x), 0.0)


func _update_combat_strafe(enemy: Dictionary, delta: float, speed_multiplier: float) -> void:
	var target := _target_by_peer(int(enemy.get("suturer_target_peer", 0)))
	if target.is_empty():
		target = _select_next_target()
	if target.is_empty():
		enemy["last_move_dir"] = Vector2.ZERO
		return
	var pos := Vector2(enemy.get("pos", game.player_pos))
	var target_pos := Vector2(target.get("pos", game.player_pos))
	var toward := (target_pos - pos).normalized()
	if toward.length_squared() <= 0.01:
		toward = Vector2.RIGHT
	var orbit_sign := -1.0 if int(enemy.get("uid", 0)) % 2 == 0 else 1.0
	var move_dir := toward.orthogonal() * orbit_sign
	var distance := pos.distance_to(target_pos)
	if distance < 250.0:
		move_dir = (move_dir * 0.55 - toward * 0.45).normalized()
	elif distance > 500.0:
		move_dir = (move_dir * 0.58 + toward * 0.42).normalized()
	var next_pos := (pos + move_dir * _effective_move_speed(enemy) * speed_multiplier * delta).clamp(Vector2(86.0, 78.0), game.WORLD_SIZE - Vector2(86.0, 78.0))
	enemy["pos"] = next_pos
	enemy["last_move_dir"] = move_dir
	if absf(move_dir.x) > 0.02:
		enemy["facing_dir"] = Vector2(signf(move_dir.x), 0.0)


func _try_damage_evasion(enemy: Dictionary) -> void:
	var hp := float(enemy.get("hp", 0.0))
	var previous_hp := float(enemy.get("suturer_last_hp", hp))
	enemy["suturer_last_hp"] = hp
	if float(enemy.get("suturer_evasion_cd", 0.0)) > 0.0:
		return
	if previous_hp - hp < float(enemy.get("max_hp", 1.0)) * EVASION_HP_RATIO:
		return
	var state := String(enemy.get("suturer_state", STATE_ENTRY))
	if state not in [STATE_OBSERVE, STATE_NEEDLE_RECOVERY, STATE_HOOK_RECOVERY]:
		return
	enemy["suturer_evasion_cd"] = EVASION_COOLDOWN
	_begin_reposition(enemy, 0.62)
	_emit_visual_event("evasion", {"pos": Vector2(enemy.get("pos", game.player_pos))})


func _begin_attack_cycle(enemy: Dictionary) -> void:
	var ability_cycle := int(game.amber_suturer_state.get("ability_cycle", 0))
	game.amber_suturer_state["ability_cycle"] = ability_cycle + 1
	match posmod(ability_cycle, 4):
		0:
			_begin_suture_cycle(enemy)
		1:
			_begin_needle_cycle(enemy, false)
		2:
			_begin_hook_cycle(enemy)
		_:
			_begin_needle_cycle(enemy, true)


func _begin_suture_cycle(enemy: Dictionary) -> void:
	var target := _select_next_target()
	if target.is_empty():
		_set_state(enemy, STATE_OBSERVE, 0.8)
		return
	var peer_id := int(target.get("peer_id", 0))
	var target_pos := Vector2(target.get("pos", game.player_pos))
	var segments := build_suture_segments(peer_id, target_pos)
	if segments.is_empty():
		_set_state(enemy, STATE_OBSERVE, 0.8)
		return
	_clear_sutures("new_cycle", false)
	game.amber_suturer_state["cycle"] = int(game.amber_suturer_state.get("cycle", 0)) + 1
	game.amber_suturer_state["crystals_destroyed_cycle"] = 0
	game.amber_suturer_state["target_peer_id"] = peer_id
	enemy["suturer_target_peer"] = peer_id
	enemy["suturer_current_ability"] = "suture"
	game.amber_suturer_state["current_ability"] = "suture"
	var cycle_id := _next_event_id("cycle")
	for index in range(mini(MAX_ACTIVE_SUTURES, segments.size())):
		var segment: Dictionary = segments[index]
		var suture_id := "%s_%d" % [cycle_id, index]
		var node_a := _spawn_suture_node(Vector2(segment["a"]), suture_id, 0, enemy)
		var node_b := _spawn_suture_node(Vector2(segment["b"]), suture_id, 1, enemy)
		game.amber_sutures.append({
			"id": suture_id,
			"event_id": cycle_id,
			"a": Vector2(segment["a"]),
			"b": Vector2(segment["b"]),
			"state": STATE_TELEGRAPH,
			"timer": TELEGRAPH_TIME,
			"life": ACTIVE_TIME,
			"node_a_uid": int(node_a.get("uid", -1)),
			"node_b_uid": int(node_b.get("uid", -1)),
		})
	_set_state(enemy, STATE_TELEGRAPH, TELEGRAPH_TIME)
	game.event_alert_text = "SUTURA EM FORMACAO — QUEBRE OS NOS"
	game.event_alert_timer = TELEGRAPH_TIME
	game._play_sfx("Boss-Onda.mp3", 0.02, 0.52, 1.12)
	_emit_visual_event("telegraph", {"event_id": cycle_id, "pos": Vector2(enemy.get("pos", target_pos))})


func _begin_needle_cycle(enemy: Dictionary, radial: bool) -> void:
	var target := _select_next_target()
	if target.is_empty():
		_set_state(enemy, STATE_OBSERVE, 0.8)
		return
	_clear_sutures("needle_cycle", false)
	var origin := Vector2(enemy.get("pos", game.player_pos))
	var target_pos := Vector2(target.get("pos", game.player_pos))
	var direction := (target_pos - origin).normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.LEFT
	var pattern := "radial" if radial else "fan"
	var ability := "needle_burst" if radial else "needle_fan"
	var event_id := _next_event_id(ability)
	enemy["suturer_target_peer"] = int(target.get("peer_id", 0))
	enemy["suturer_attack_dir"] = direction
	enemy["suturer_needle_pattern"] = pattern
	enemy["suturer_attack_event_id"] = event_id
	enemy["suturer_current_ability"] = ability
	game.amber_suturer_state["target_peer_id"] = int(target.get("peer_id", 0))
	game.amber_suturer_state["current_ability"] = ability
	_set_state(enemy, STATE_NEEDLE_TELEGRAPH, NEEDLE_TELEGRAPH_TIME)
	game.event_alert_text = "COROA DE AGULHAS — AFASTE-SE" if radial else "AGULHAS DE AMBAR — ROMPA O LEQUE"
	game.event_alert_timer = NEEDLE_TELEGRAPH_TIME
	game._play_sfx("Boss-Onda.mp3", 0.02, 0.62, 1.18 if radial else 1.05)
	_emit_visual_event("needle_telegraph", {
		"event_id": event_id,
		"pos": origin,
		"direction": direction,
		"pattern": pattern,
	})


func _fire_needle_attack(enemy: Dictionary) -> void:
	var origin := Vector2(enemy.get("pos", game.player_pos))
	var base_direction := Vector2(enemy.get("suturer_attack_dir", Vector2.LEFT)).normalized()
	if base_direction.length_squared() <= 0.01:
		base_direction = Vector2.LEFT
	var radial := String(enemy.get("suturer_needle_pattern", "fan")) == "radial"
	var directions: Array[Vector2] = []
	if radial:
		var phase_offset := float(int(game.amber_suturer_state.get("ability_cycle", 0)) % 2) * PI / float(NEEDLE_RADIAL_COUNT)
		for index in range(NEEDLE_RADIAL_COUNT):
			directions.append(Vector2.from_angle(phase_offset + float(index) * TAU / float(NEEDLE_RADIAL_COUNT)))
	else:
		for angle in [-0.30, -0.15, 0.0, 0.15, 0.30]:
			directions.append(base_direction.rotated(float(angle)))
	var damage_ratio := 0.026 if radial else 0.034
	var far_scale := 0.28 if radial else 0.38
	var damage := maxi(1, int(game.player_hp_max * damage_ratio + game.enemy_far_damage * far_scale))
	var encounter_id := String(game.amber_suturer_state.get("encounter_id", ""))
	for direction in directions:
		game.enemy_bullets.append({
			"pos": origin + direction * 48.0,
			"dir": direction,
			"life": 4.0,
			"damage": damage,
			"phase": game.rng.randf_range(0.0, TAU),
			"type": "suturer_needle",
			"speed_mult": 0.90 if radial else 1.16,
			"radius": 9.0,
			"hit_radius": 15.0,
			"suturer_encounter_id": encounter_id,
		})
	_emit_visual_event("needle_fire", {
		"event_id": String(enemy.get("suturer_attack_event_id", _next_event_id("needle_fire"))),
		"pos": origin,
		"direction": base_direction,
		"pattern": "radial" if radial else "fan",
	})
	game._play_sfx("Boss-Impacto.mp3", 0.022, 0.64, 1.2 if radial else 1.08)
	_set_state(enemy, STATE_NEEDLE_RECOVERY, NEEDLE_RECOVERY_TIME)


func _begin_hook_cycle(enemy: Dictionary) -> void:
	var target := _select_next_target()
	if target.is_empty():
		_set_state(enemy, STATE_OBSERVE, 0.8)
		return
	_clear_sutures("hook_cycle", false)
	var origin := Vector2(enemy.get("pos", game.player_pos))
	var target_pos := Vector2(target.get("pos", game.player_pos))
	var direction := (target_pos - origin).normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.LEFT
	var event_id := _next_event_id("hook")
	enemy["suturer_target_peer"] = int(target.get("peer_id", game._mp_unique_id()))
	enemy["suturer_attack_dir"] = direction
	enemy["suturer_attack_event_id"] = event_id
	enemy["suturer_current_ability"] = "amber_hook"
	game.amber_suturer_state["target_peer_id"] = int(target.get("peer_id", game._mp_unique_id()))
	game.amber_suturer_state["current_ability"] = "amber_hook"
	_set_state(enemy, STATE_HOOK_TELEGRAPH, HOOK_TELEGRAPH_TIME)
	game.event_alert_text = "ARPÃO DE SUTURA — ROMPA A LINHA"
	game.event_alert_timer = HOOK_TELEGRAPH_TIME
	game._play_sfx("Boss-Onda.mp3", 0.025, 0.56, 0.78)
	_emit_visual_event("hook_telegraph", {
		"event_id": event_id,
		"pos": origin,
		"target_pos": target_pos,
		"direction": direction,
	})


func _fire_hook(enemy: Dictionary) -> void:
	var origin := Vector2(enemy.get("pos", game.player_pos))
	var target := _target_by_peer(int(enemy.get("suturer_target_peer", game._mp_unique_id())))
	var target_pos := Vector2(target.get("pos", origin + Vector2(enemy.get("suturer_attack_dir", Vector2.LEFT)) * 360.0)) if not target.is_empty() else origin + Vector2(enemy.get("suturer_attack_dir", Vector2.LEFT)) * 360.0
	var direction := (target_pos - origin).normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2(enemy.get("suturer_attack_dir", Vector2.LEFT)).normalized()
	var damage := maxi(1, int(game.player_hp_max * 0.045 + game.enemy_far_damage * 0.42))
	game.enemy_bullets.append({
		"pos": origin + direction * 48.0,
		"dir": direction,
		"life": HOOK_RANGE / (210.0 * 1.72),
		"damage": damage,
		"phase": game.rng.randf_range(0.0, TAU),
		"type": "suturer_hook",
		"speed_mult": 1.72,
		"radius": 13.0,
		"hit_radius": 21.0,
		"source_enemy_uid": int(enemy.get("uid", -1)),
		"suturer_encounter_id": String(game.amber_suturer_state.get("encounter_id", "")),
		"target_peer_id": int(enemy.get("suturer_target_peer", game._mp_unique_id())),
	})
	_emit_visual_event("hook_fire", {
		"event_id": String(enemy.get("suturer_attack_event_id", _next_event_id("hook_fire"))),
		"pos": origin,
		"target_pos": target_pos,
		"direction": direction,
	})
	game._play_sfx("Boss-Impacto.mp3", 0.03, 0.62, 0.78)
	_set_state(enemy, STATE_HOOK_RECOVERY, HOOK_RECOVERY_TIME)


func on_hook_hit(bullet: Dictionary, peer_id: int = -1) -> void:
	if game == null or not game._is_world_authority():
		return
	if String(bullet.get("suturer_encounter_id", "")) != String(game.amber_suturer_state.get("encounter_id", "")):
		return
	var enemy := active_enemy()
	if enemy.is_empty():
		return
	var enemy_pos := Vector2(enemy.get("pos", game.player_pos))
	var target_pos := Vector2(bullet.get("pos", game.player_pos))
	var pull_dir := (target_pos - enemy_pos).normalized()
	if pull_dir.length_squared() <= 0.01:
		pull_dir = Vector2.RIGHT
	var destination := (enemy_pos + pull_dir * HOOK_PULL_DISTANCE).clamp(Vector2(48.0, 48.0), game.WORLD_SIZE - Vector2(48.0, 48.0))
	var target_peer_id: int = game._mp_unique_id() if peer_id < 0 else peer_id
	if not game.is_multiplayer or target_peer_id == game._mp_unique_id():
		game._apply_hostile_reposition(destination, TYPE_ID)
		if not game._player_invulnerable():
			game.player_stun_timer = maxf(game.player_stun_timer, game._hostile_control_duration(HOOK_STUN_TIME))
	else:
		game._send_peer_hostile_reposition(target_peer_id, destination, TYPE_ID)
	var stolen: Dictionary = _steal_card_from_peer(target_peer_id)
	var display_name := String(stolen.get("display_name", ""))
	if not game.is_multiplayer or target_peer_id == game._mp_unique_id():
		game._add_text("PUXADO E SUTURADO", destination + Vector2(-72.0, -76.0), Color(1.0, 0.68, 0.2), 1.0, 19)
	_emit_visual_event("hook_hit", {
		"pos": enemy_pos,
		"target_pos": destination,
		"card_name": display_name,
	})


func _steal_card_from_peer(peer_id: int) -> Dictionary:
	var stolen_cards: Array = game.amber_suturer_state.get("stolen_cards", [])
	if stolen_cards.size() >= MAX_STOLEN_CARDS:
		return {}
	var counts: Dictionary = game.cards_bought
	var local_target: bool = not game.is_multiplayer or peer_id == game._mp_unique_id()
	if not local_target:
		var remote_deck: Dictionary = game.net_decks_by_peer.get(peer_id, {})
		counts = Dictionary(remote_deck.get("counts", {}))
	var eligible: Array[String] = []
	for card_id in STEALABLE_CARD_IDS:
		if int(counts.get(card_id, 0)) > 0:
			eligible.append(card_id)
	if eligible.is_empty():
		game.event_alert_text = "ARPÃO PRENDEU — NENHUMA CARTA ROUBADA"
		game.event_alert_timer = 1.2
		return {}
	var card_id := eligible[game.rng.randi_range(0, eligible.size() - 1)]
	var card: Dictionary = game._find_card_by_id(card_id)
	if card.is_empty():
		return {}
	if local_target:
		if not game._consume_card_count(card_id, 1):
			return {}
	else:
		game._send_peer_suturer_card_change(peer_id, card_id, false, String(game.amber_suturer_state.get("encounter_id", "")))
		counts[card_id] = maxi(0, int(counts.get(card_id, 0)) - 1)
	var display_name := String(card.get("name", card_id))
	var entry := {
		"card_id": card_id,
		"display_name": display_name,
		"owner_peer_id": peer_id,
	}
	stolen_cards.append(entry)
	game.amber_suturer_state["stolen_cards"] = stolen_cards
	game.event_alert_text = "CARTA ROUBADA: %s" % display_name.to_upper()
	game.event_alert_timer = 2.2
	_emit_visual_event("card_steal", {
		"pos": Vector2(active_enemy().get("pos", game.player_pos)),
		"card_name": display_name,
		"card_color": Color(card.get("color", Color(1.0, 0.62, 0.18))),
	})
	return entry


func apply_remote_card_change(card_id: String, restore: bool, encounter_id: String) -> void:
	if game == null or card_id == "" or encounter_id == "":
		return
	var card: Dictionary = game._find_card_by_id(card_id)
	if card.is_empty():
		return
	var change_key := "%s|%s" % [encounter_id, card_id]
	var previous_state := String(_remote_card_change_state.get(change_key, ""))
	if restore:
		if previous_state != "stolen":
			return
		restore_local_card(card_id)
		_remember_remote_card_change(change_key, "restored")
		game._add_text("CARTA DEVOLVIDA: %s" % String(card.get("nick", card.get("name", card_id))).to_upper(), game.player_pos + Vector2(-110.0, -112.0), Color(0.54, 1.0, 0.72), 1.45, 19)
	elif previous_state == "" and game._consume_card_count(card_id, 1):
		_remember_remote_card_change(change_key, "stolen")
		game.event_alert_text = "CARTA ROUBADA: %s" % String(card.get("name", card_id)).to_upper()
		game.event_alert_timer = 2.2


func _remember_remote_card_change(change_key: String, state: String) -> void:
	if not _remote_card_change_state.has(change_key):
		_remote_card_change_order.append(change_key)
	_remote_card_change_state[change_key] = state
	while _remote_card_change_order.size() > 64:
		var expired_key: String = _remote_card_change_order.pop_front()
		_remote_card_change_state.erase(expired_key)


func restore_local_card(card_id: String) -> bool:
	var card: Dictionary = game._find_card_by_id(card_id)
	if card.is_empty():
		return false
	game.cards_bought[card_id] = int(game.cards_bought.get(card_id, 0)) + 1
	game._recalculate_common_card_stat_bonuses()
	game._sync_deck_network()
	return true


func build_suture_segments(peer_id: int, fallback_pos: Vector2) -> Array:
	var samples: Array = _history_by_peer.get(peer_id, [])
	var recent := fallback_pos
	var previous := fallback_pos - Vector2.RIGHT * 180.0
	if not samples.is_empty():
		recent = Vector2(Dictionary(samples.back()).get("pos", fallback_pos))
		previous = Vector2(Dictionary(samples[maxi(0, samples.size() - 7)]).get("pos", recent))
	var velocity := recent - previous
	var direction := velocity.normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.from_angle(float(int(game.amber_suturer_state.get("cycle", 0)) % 8) * TAU / 8.0)
	var predicted := (recent + velocity * 0.65).clamp(Vector2(90.0, 90.0), game.WORLD_SIZE - Vector2(90.0, 90.0))
	var cycle := int(game.amber_suturer_state.get("cycle", 0))
	var world_center: Vector2 = game.WORLD_SIZE * 0.5
	var spread := Vector2(game.WORLD_SIZE.x * 0.20, game.WORLD_SIZE.y * 0.20)
	var diagonal_angles := [0.62, 2.18, -0.62, -2.18]
	for attempt in range(16):
		var pattern_index := posmod(cycle + attempt, diagonal_angles.size())
		var line_dir_a := Vector2.from_angle(float(diagonal_angles[pattern_index]))
		var line_dir_b := Vector2.from_angle(float(diagonal_angles[posmod(pattern_index + 1, diagonal_angles.size())]))
		var sector_sign := -1.0 if (cycle + attempt) % 2 == 0 else 1.0
		var center_a := predicted.lerp(world_center, 0.32) + Vector2(spread.x * sector_sign, -spread.y * 0.48)
		var center_b := recent.lerp(world_center, 0.46) + Vector2(-spread.x * sector_sign, spread.y * 0.62)
		var segments: Array = []
		_append_centered_segment(segments, center_a, line_dir_a, 760.0)
		_append_centered_segment(segments, center_b, line_dir_b, 720.0)
		if segments.size() == MAX_ACTIVE_SUTURES and has_safe_route(recent, segments):
			return segments
	return []


func _append_centered_segment(result: Array, center: Vector2, direction: Vector2, length: float) -> void:
	var half := direction.normalized() * minf(length, MAX_LINE_LENGTH) * 0.5
	_append_valid_segment(result, _clamp_line_endpoint(center - half), _clamp_line_endpoint(center + half))


func _append_valid_segment(result: Array, a: Vector2, b: Vector2) -> void:
	var delta := b - a
	var length := delta.length()
	if length < MIN_LINE_LENGTH:
		return
	if length > MAX_LINE_LENGTH:
		b = _clamp_line_endpoint(a + delta.normalized() * MAX_LINE_LENGTH)
	result.append({"a": a, "b": b})


func _clamp_line_endpoint(point: Vector2) -> Vector2:
	return point.clamp(Vector2(62.0, 62.0), game.WORLD_SIZE - Vector2(62.0, 62.0))


func has_safe_route(origin: Vector2, segments: Array) -> bool:
	if segments.is_empty():
		return true
	const ROUTE_LENGTH := 245.0
	const ROUTE_START := 72.0
	const ROUTE_STEPS := 8
	for ray_index in range(12):
		var direction := Vector2.from_angle(float(ray_index) * TAU / 12.0)
		var safe := true
		for step in range(1, ROUTE_STEPS + 1):
			var distance := lerpf(ROUTE_START, ROUTE_LENGTH, float(step - 1) / float(ROUTE_STEPS - 1))
			var point := (origin + direction * distance).clamp(Vector2(34.0, 34.0), game.WORLD_SIZE - Vector2(34.0, 34.0))
			for segment_value in segments:
				var segment: Dictionary = segment_value
				if _distance_to_segment(point, Vector2(segment["a"]), Vector2(segment["b"])) <= SUTURE_RADIUS + 24.0:
					safe = false
					break
			if not safe:
				break
		if safe:
			return true
	return false


func _spawn_suture_node(pos: Vector2, suture_id: String, endpoint: int, source_enemy: Dictionary) -> Dictionary:
	var previous_count: int = game.enemies.size()
	game._spawn_enemy(NODE_TYPE_ID, pos)
	if game.enemies.size() <= previous_count:
		return {}
	var node: Dictionary = game.enemies.back()
	var owner_hp := float(source_enemy.get("max_hp", 2200.0))
	var hp := maxf(100.0, owner_hp * 0.04)
	node["hp"] = hp
	node["max_hp"] = hp
	node["points"] = 0
	node["damage"] = 0.0
	node["speed"] = 0.0
	node["parado"] = true
	node["skip_rewards"] = true
	node["is_suture_node"] = true
	node["suture_id"] = suture_id
	node["suture_endpoint"] = endpoint
	node["reconstituted_once"] = true
	node["contact_grace"] = 999.0
	return node


func _activate_sutures(enemy: Dictionary) -> void:
	for suture_value in game.amber_sutures:
		var suture: Dictionary = suture_value
		suture["state"] = STATE_ACTIVE
		suture["timer"] = ACTIVE_TIME
		suture["life"] = ACTIVE_TIME
	_set_state(enemy, STATE_ACTIVE, ACTIVE_TIME)
	game._play_sfx("Boss-Impacto.mp3", 0.025, 0.58, 0.92)
	_emit_visual_event("activate", {"pos": Vector2(enemy.get("pos", game.player_pos))})


func _update_active_sutures(delta: float) -> void:
	for suture_value in game.amber_sutures:
		var suture: Dictionary = suture_value
		if String(suture.get("state", "")) != STATE_ACTIVE:
			continue
		suture["timer"] = maxf(0.0, float(suture.get("timer", ACTIVE_TIME)) - delta)
	for target_value in game._combat_targets():
		var target: Dictionary = target_value
		var peer_id := int(target.get("peer_id", 0))
		var gates: Dictionary = game.amber_suturer_state.get("damage_gate_by_peer", {})
		if float(gates.get(str(peer_id), 0.0)) > 0.0:
			continue
		var pos := Vector2(target.get("pos", game.player_pos))
		var touched := false
		for suture_value in game.amber_sutures:
			var suture: Dictionary = suture_value
			if String(suture.get("state", "")) != STATE_ACTIVE:
				continue
			if _distance_to_segment(pos, Vector2(suture.get("a", pos)), Vector2(suture.get("b", pos))) <= SUTURE_RADIUS + 18.0:
				touched = true
				break
		if not touched:
			continue
		var damage := maxi(1, int(ceil(float(target.get("hp_max", game.player_hp_max)) * DAMAGE_MAX_HP_RATIO)))
		if bool(target.get("local", false)):
			game._damage_player(damage, TYPE_ID)
		else:
			game._send_peer_damage(peer_id, damage, TYPE_ID)
		gates[str(peer_id)] = DAMAGE_INTERVAL
		game.amber_suturer_state["damage_gate_by_peer"] = gates


func _update_damage_gates(delta: float) -> void:
	var gates: Dictionary = game.amber_suturer_state.get("damage_gate_by_peer", {})
	for peer_key in gates.keys():
		gates[peer_key] = maxf(0.0, float(gates[peer_key]) - delta)
	game.amber_suturer_state["damage_gate_by_peer"] = gates


func _begin_reposition(enemy: Dictionary, duration: float = REPOSITION_TIME) -> void:
	var target := _select_next_target()
	var target_pos: Vector2 = Vector2(target.get("pos", game.player_pos)) if not target.is_empty() else Vector2(game.player_pos)
	var from := Vector2(enemy.get("pos", game.player_pos))
	var direction: Vector2 = (target_pos - from).normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.RIGHT
	enemy["suturer_reposition_dir"] = direction.orthogonal() * (-1.0 if int(game.amber_suturer_state.get("cycle", 0)) % 2 == 0 else 1.0)
	_set_state(enemy, STATE_REPOSITION, duration)


func _update_reposition(enemy: Dictionary, delta: float) -> void:
	var direction := Vector2(enemy.get("suturer_reposition_dir", Vector2.RIGHT)).normalized()
	var pos := Vector2(enemy.get("pos", game.player_pos))
	var next_pos := (pos + direction * _effective_move_speed(enemy) * 1.28 * delta).clamp(Vector2(86.0, 78.0), game.WORLD_SIZE - Vector2(86.0, 78.0))
	enemy["pos"] = next_pos
	enemy["last_move_dir"] = direction
	if absf(direction.x) > 0.02:
		enemy["facing_dir"] = Vector2(signf(direction.x), 0.0)


func on_enemy_defeated(enemy: Dictionary) -> bool:
	if game == null or not game._is_world_authority():
		return false
	var kind := String(enemy.get("type", ""))
	if kind == NODE_TYPE_ID:
		_apply_crystal_slow(active_enemy(), Vector2(enemy.get("pos", game.player_pos)))
		break_suture(String(enemy.get("suture_id", "")), "node_destroyed", Vector2(enemy.get("pos", game.player_pos)))
		if game.enemies.has(enemy):
			game.enemies.erase(enemy)
		return true
	if kind != TYPE_ID:
		return false
	_set_state(enemy, STATE_DYING, 0.8)
	_emit_visual_event("death", {"pos": Vector2(enemy.get("pos", game.player_pos))})
	game._play_sfx("Larapio-Dead.mp3", 0.03, 0.72, 0.72)
	_drop_defeat_rewards(Vector2(enemy.get("pos", game.player_pos)))
	_clear_sutures("owner_defeated")
	_finish_event("defeated")
	return false


func _drop_defeat_rewards(pos: Vector2) -> void:
	var stolen_cards: Array = game.amber_suturer_state.get("stolen_cards", [])
	for index in range(stolen_cards.size()):
		var entry: Dictionary = stolen_cards[index]
		var card_id := String(entry.get("card_id", ""))
		var card: Dictionary = game._find_card_by_id(card_id)
		if card.is_empty():
			continue
		var angle := -PI * 0.5 + (float(index) - float(stolen_cards.size() - 1) * 0.5) * 0.58
		game._append_owned_card_drop(card, pos, angle, int(entry.get("owner_peer_id", game._mp_unique_id())), 24.0, 58.0, 88.0, 76.0, 118.0, {
			"suturer_returned": true,
			"suturer_encounter_id": String(game.amber_suturer_state.get("encounter_id", "")),
		})
	game._spawn_random_card_drops(pos, REWARD_CARD_COUNT, 0)
	game._add_text("%d CARTAS + ROUBADAS DEVOLVIDAS" % REWARD_CARD_COUNT, pos + Vector2(-150.0, -144.0), Color(1.0, 0.86, 0.32), 1.65, 20)
	game.amber_suturer_state["stolen_cards"] = []


func _apply_crystal_slow(enemy: Dictionary, crystal_pos: Vector2) -> void:
	if enemy.is_empty():
		return
	var stacks := mini(CRYSTAL_SLOW_MAX_STACKS, int(enemy.get("suturer_crystal_slow_stacks", 0)) + 1)
	enemy["suturer_crystal_slow_stacks"] = stacks
	enemy["suturer_crystal_slow_timer"] = CRYSTAL_SLOW_DURATION
	game.amber_suturer_state["crystals_destroyed_cycle"] = int(game.amber_suturer_state.get("crystals_destroyed_cycle", 0)) + 1
	_sync_public_enemy_state(enemy)
	_emit_visual_event("crystal_slow", {
		"pos": crystal_pos,
		"stacks": stacks,
		"enemy_pos": Vector2(enemy.get("pos", game.player_pos)),
	})


func break_suture(suture_id: String, reason: String, broken_pos: Vector2 = Vector2.ZERO) -> void:
	if suture_id == "":
		return
	var kept: Array = []
	for suture_value in game.amber_sutures:
		var suture: Dictionary = suture_value
		if String(suture.get("id", "")) == suture_id:
			if broken_pos == Vector2.ZERO:
				broken_pos = Vector2(suture.get("a", Vector2.ZERO)).lerp(Vector2(suture.get("b", Vector2.ZERO)), 0.5)
		else:
			kept.append(suture)
	game.amber_sutures = kept
	_emit_visual_event("break", {"pos": broken_pos, "reason": reason})
	game._play_sfx("Boss-Impacto.mp3", 0.03, 0.42, 1.18)


func cleanup(reason: String, schedule_next: bool = true) -> void:
	if game == null:
		return
	var enemy := active_enemy()
	var pos: Vector2 = Vector2(enemy.get("pos", game.player_pos)) if not enemy.is_empty() else Vector2(game.player_pos)
	if not enemy.is_empty():
		game.enemies.erase(enemy)
	_restore_stolen_cards()
	_clear_sutures(reason)
	_finish_event(reason, schedule_next)
	_emit_visual_event("cleanup", {"pos": pos, "reason": reason})


func _restore_stolen_cards() -> void:
	var stolen_cards: Array = game.amber_suturer_state.get("stolen_cards", [])
	for entry_value in stolen_cards:
		var entry: Dictionary = entry_value
		var card_id := String(entry.get("card_id", ""))
		var owner_peer_id := int(entry.get("owner_peer_id", game._mp_unique_id()))
		if card_id == "":
			continue
		if not game.is_multiplayer or owner_peer_id == game._mp_unique_id():
			restore_local_card(card_id)
		else:
			game._send_peer_suturer_card_change(owner_peer_id, card_id, true, String(game.amber_suturer_state.get("encounter_id", "")))
	game.amber_suturer_state["stolen_cards"] = []


func _finish_event(reason: String, schedule_next: bool = true) -> void:
	var encounter_id := String(game.amber_suturer_state.get("encounter_id", ""))
	game.enemy_bullets = game.enemy_bullets.filter(func(value):
		var bullet: Dictionary = value
		return String(bullet.get("type", "")) not in ["suturer_needle", "suturer_hook"] or String(bullet.get("suturer_encounter_id", "")) != encounter_id
	)
	game.amber_suturer_state["active"] = false
	game.amber_suturer_state["enemy_uid"] = -1
	game.amber_suturer_state["cleanup_reason"] = reason
	game.amber_suturer_state["last_end_phase_time"] = game._phase_elapsed_time()
	game.amber_suturer_state["damage_gate_by_peer"] = {}
	if schedule_next and game.current_phase == 6:
		game.amber_suturer_state["next_spawn_phase_time"] = game._phase_elapsed_time() + game.rng.randf_range(RESPAWN_MIN_TIME, RESPAWN_MAX_TIME)
	_history_by_peer.clear()


func _clear_sutures(reason: String, emit_event: bool = true) -> void:
	if emit_event and not game.amber_sutures.is_empty():
		_emit_visual_event("dissipate", {"pos": _sutures_center(), "reason": reason})
	game.amber_sutures.clear()
	game.enemies = game.enemies.filter(func(value): return String(Dictionary(value).get("type", "")) != NODE_TYPE_ID)


func _sutures_center() -> Vector2:
	if game.amber_sutures.is_empty():
		return game.player_pos
	var sum := Vector2.ZERO
	for suture_value in game.amber_sutures:
		var suture: Dictionary = suture_value
		sum += Vector2(suture.get("a", Vector2.ZERO)).lerp(Vector2(suture.get("b", Vector2.ZERO)), 0.5)
	return sum / float(game.amber_sutures.size())


func _sample_player_history(delta: float) -> void:
	_history_sample_timer -= delta
	if _history_sample_timer > 0.0:
		return
	_history_sample_timer = HISTORY_SAMPLE_INTERVAL
	var now := float(game._phase_elapsed_time())
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


func _select_next_target() -> Dictionary:
	var targets: Array = game._combat_targets()
	if targets.is_empty():
		return {}
	_target_cursor = posmod(_target_cursor + 1, targets.size())
	return targets[_target_cursor]


func _target_by_peer(peer_id: int) -> Dictionary:
	for target_value in game._combat_targets():
		var target: Dictionary = target_value
		if int(target.get("peer_id", 0)) == peer_id:
			return target
	return {}


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_sq := ab.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / length_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _next_event_id(kind: String) -> String:
	var sequence := int(game.amber_suturer_state.get("event_sequence", 0)) + 1
	game.amber_suturer_state["event_sequence"] = sequence
	return "%s_%s_%d" % [String(game.amber_suturer_state.get("encounter_id", "suturador")), kind, sequence]


func _emit_visual_event(kind: String, data: Dictionary) -> void:
	var payload := data.duplicate(true)
	payload["kind"] = kind
	payload["age"] = 0.0
	if kind == "card_steal":
		payload["life"] = 1.8
	elif kind in ["entry", "death", "needle_telegraph", "hook_telegraph"]:
		payload["life"] = 0.9
	else:
		payload["life"] = 0.55
	payload["max_life"] = payload["life"]
	if not payload.has("event_id"):
		payload["event_id"] = _next_event_id(kind)
	game.amber_suturer_visual_events.append(payload)
	if game.amber_suturer_visual_events.size() > 24:
		game.amber_suturer_visual_events.pop_front()


func _update_visual_events(delta: float) -> void:
	for event_value in game.amber_suturer_visual_events:
		var event: Dictionary = event_value
		event["age"] = float(event.get("age", 0.0)) + delta
		event["life"] = float(event.get("life", 0.0)) - delta
	game.amber_suturer_visual_events = game.amber_suturer_visual_events.filter(func(value): return float(Dictionary(value).get("life", 0.0)) > 0.0)
