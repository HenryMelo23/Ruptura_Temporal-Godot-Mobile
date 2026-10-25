class_name RTBoss4Controller
extends RefCounted

## Authoritative high-level owner for Boss 4 locomotion, attack cadence and
## state transitions. Existing hazard helpers remain behind the runtime facade
## while they are migrated independently.

const STATE_IDLE := "idle"
const STATE_WALK := "walk"
const STATE_WINDUP := "windup"
const STATE_ACTIVE := "active"
const STATE_RECOVER := "recover"
const STATE_JUMP := "jump"
const STATE_LAND := "land"
const STATE_TRANSITION := "transition"
const STATE_STUN := "stun"
const STATE_ULTIMATE := "ultimate"

const MOVE_SPEED := 92.0
const MOVE_TARGET_MIN_DISTANCE := 205.0
const MOVE_TARGET_MAX_DISTANCE := 335.0
const CONTACT_RADIUS := 92.0
const CONTACT_COOLDOWN := 0.92
const CONTACT_KNOCKBACK := 118.0
const ACTION_GAP_BY_STAGE := [0.0, 1.35, 1.16, 1.02, 0.88]

const ACTION_TIMINGS := {
	"slam": {"windup": 0.62, "active": 0.14, "recover": 0.55, "cooldown": 4.6},
	"tongue": {"windup": 0.58, "active": 0.16, "recover": 0.48, "cooldown": 6.2},
	"jump": {"windup": 0.54, "active": 0.74, "recover": 0.62, "cooldown": 8.4},
	"comet": {"windup": 0.52, "active": 0.12, "recover": 0.43, "cooldown": 5.2},
	"fissure": {"windup": 0.72, "active": 0.12, "recover": 0.58, "cooldown": 10.5},
	"leak": {"windup": 0.76, "active": 0.12, "recover": 0.62, "cooldown": 14.5},
	"prison": {"windup": 0.76, "active": 0.12, "recover": 0.64, "cooldown": 13.0},
	"clone": {"windup": 0.64, "active": 0.12, "recover": 0.58, "cooldown": 11.5},
	"vampirism": {"windup": 0.88, "active": 0.12, "recover": 0.68, "cooldown": 18.0},
	"combo": {"windup": 0.54, "active": 1.44, "recover": 0.68, "cooldown": 14.0},
	"fragments": {"windup": 0.68, "active": 0.12, "recover": 0.56, "cooldown": 9.5},
	"gravity": {"windup": 0.78, "active": 0.12, "recover": 0.72, "cooldown": 12.0},
	"collapse": {"windup": 0.82, "active": 0.12, "recover": 0.72, "cooldown": 11.0},
	"meteor": {"windup": 0.92, "active": 0.12, "recover": 0.76, "cooldown": 20.0}
}

var game: Node


func configure(runtime: Node) -> void:
	game = runtime


func reset() -> void:
	if game == null:
		return
	game.boss4_ai_state = {
		"state": STATE_WALK,
		"elapsed": 0.0,
		"action": "",
		"action_elapsed": 0.0,
		"action_total_elapsed": 0.0,
		"action_fired": false,
		"combo_step": 0,
		"facing": -1.0,
		"move_target": game.boss4_entry_target,
		"jump_from": game.boss4_entry_target,
		"jump_to": game.boss4_entry_target,
		"jump_progress": 0.0,
		"land_hit": false,
		"attack_dir": Vector2.LEFT,
		"cooldowns": {},
		"contact_cooldowns": {},
		"history": [],
		"stage_transition": 0
	}
	game.boss4_last_attack = ""
	game.boss4_attack_timer = 0.85


func update(delta: float) -> void:
	if game == null or game.current_phase != 4 or not game.boss_active or game.boss_hp <= 0.0:
		return
	_ensure_state()
	_tick_cooldowns(delta)
	_update_stage()
	var state := String(game.boss4_ai_state.get("state", STATE_IDLE))
	if state != STATE_JUMP and not game.boss4_ultimate_active:
		_update_contact(delta)
	if game.boss4_ultimate_active:
		_set_state(STATE_ULTIMATE)
		return
	if game.boss4_stun_timer > 0.0:
		_set_state(STATE_STUN)
		return
	state = String(game.boss4_ai_state.get("state", STATE_IDLE))
	if state == STATE_TRANSITION:
		_update_transition(delta)
		return
	if state in [STATE_WINDUP, STATE_ACTIVE, STATE_RECOVER, STATE_JUMP, STATE_LAND]:
		_update_action(delta)
		return
	_update_locomotion(delta)
	game.boss4_attack_timer = maxf(0.0, game.boss4_attack_timer - delta)
	if game.boss4_stage == 4 and not game.boss4_ultimate_used and game.boss4_ultimate_cooldown <= 0.0:
		game._start_boss4_ultimate()
		return
	if game.boss4_attack_timer <= 0.0:
		_begin_action(_choose_action())


func visual_state() -> String:
	if game == null:
		return STATE_IDLE
	var state := String(game.boss4_ai_state.get("state", STATE_IDLE))
	var action := String(game.boss4_ai_state.get("action", ""))
	if state == STATE_JUMP:
		return "jump"
	if state == STATE_LAND:
		return "land"
	if state == STATE_TRANSITION:
		return "transition_%d" % clampi(int(game.boss4_stage), 2, 4)
	if state == STATE_ULTIMATE:
		return "ultimate"
	if state == STATE_STUN:
		return "hit"
	if state in [STATE_WINDUP, STATE_ACTIVE, STATE_RECOVER]:
		match action:
			"slam", "combo":
				return "slam"
			"tongue":
				return "tongue"
			"comet":
				return "comet"
			_:
				return "gravity"
	return "walk" if state == STATE_WALK else "idle"


func force_action_for_test(action: String) -> bool:
	if not ACTION_TIMINGS.has(action):
		return false
	_begin_action(action)
	return true


func request_contextual_action() -> bool:
	if game == null or game.boss4_ultimate_active or game.boss4_stun_timer > 0.0:
		return false
	var state := String(game.boss4_ai_state.get("state", STATE_IDLE))
	if state in [STATE_WINDUP, STATE_ACTIVE, STATE_RECOVER, STATE_JUMP, STATE_LAND, STATE_TRANSITION]:
		return false
	_begin_action(_choose_action())
	return true


func snapshot() -> Dictionary:
	if game == null:
		return {}
	return {
		"ai_state": game.boss4_ai_state.duplicate(true),
		"stage": game.boss4_stage,
		"last_attack": game.boss4_last_attack
	}


func apply_remote_snapshot(snapshot_data: Dictionary) -> void:
	if game == null or snapshot_data.is_empty():
		return
	var incoming = snapshot_data.get("ai_state", {})
	if incoming is Dictionary:
		game.boss4_ai_state = Dictionary(incoming).duplicate(true)
	game.boss4_stage = clampi(int(snapshot_data.get("stage", game.boss4_stage)), 1, 4)
	game.boss4_last_attack = String(snapshot_data.get("last_attack", game.boss4_last_attack))


func _ensure_state() -> void:
	if game.boss4_ai_state.is_empty():
		reset()


func _set_state(next_state: String) -> void:
	if String(game.boss4_ai_state.get("state", "")) == next_state:
		return
	game.boss4_ai_state["state"] = next_state
	game.boss4_ai_state["elapsed"] = 0.0


func _tick_cooldowns(delta: float) -> void:
	var cooldowns: Dictionary = Dictionary(game.boss4_ai_state.get("cooldowns", {}))
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, float(cooldowns.get(key, 0.0)) - delta)
	game.boss4_ai_state["cooldowns"] = cooldowns
	var contact: Dictionary = Dictionary(game.boss4_ai_state.get("contact_cooldowns", {}))
	for key in contact.keys():
		contact[key] = maxf(0.0, float(contact.get(key, 0.0)) - delta)
	game.boss4_ai_state["contact_cooldowns"] = contact


func _update_stage() -> void:
	var ratio: float = game.boss_hp / maxf(1.0, game.boss_hp_max)
	var next_stage := 1
	if ratio <= 0.25:
		next_stage = 4
	elif ratio <= 0.50:
		next_stage = 3
	elif ratio <= 0.75:
		next_stage = 2
	if next_stage == game.boss4_stage:
		return
	game.boss4_stage = next_stage
	game.boss4_ai_state["stage_transition"] = next_stage
	game.boss4_ai_state["state"] = STATE_TRANSITION
	game.boss4_ai_state["elapsed"] = 0.0
	game.boss4_attack_timer = 1.15
	game._increase_boss4_instability(8.0)
	var labels := {2: "TRAJE EM VAZAMENTO", 3: "MUTACAO DA RUPTURA", 4: "COLAPSO ABSOLUTO"}
	game._add_text(String(labels.get(next_stage, "MUTACAO")), game.boss_pos + Vector2(0, -154), Color(1.0, 0.62, 0.18), 1.5, 25)
	game._spawn_radial_particles(game.boss_pos, Color(0.58, 0.18, 1.0), 30 + next_stage * 8)


func _update_transition(delta: float) -> void:
	game.boss4_ai_state["elapsed"] = float(game.boss4_ai_state.get("elapsed", 0.0)) + delta
	if float(game.boss4_ai_state["elapsed"]) >= 0.95:
		game.boss4_ai_state["stage_transition"] = 0
		_set_state(STATE_WALK)
		_pick_move_target()


func _update_locomotion(delta: float) -> void:
	var target: Vector2 = Vector2(game.boss4_ai_state.get("move_target", game.boss4_entry_target))
	var target_player: Vector2 = game._boss_target_pos(false, 0.18)
	var desired_distance: float = lerpf(MOVE_TARGET_MIN_DISTANCE, MOVE_TARGET_MAX_DISTANCE, 0.32 + float(game.boss4_stage - 1) * 0.12)
	if target == Vector2.ZERO or game.boss_pos.distance_to(target) <= 18.0 or target.distance_to(target_player) > desired_distance * 1.9:
		_pick_move_target()
		target = Vector2(game.boss4_ai_state.get("move_target", game.boss4_entry_target))
	var direction: Vector2 = (target - game.boss_pos).normalized()
	if direction.length() <= 0.01:
		_set_state(STATE_IDLE)
		return
	_set_state(STATE_WALK)
	game.boss4_ai_state["facing"] = signf(direction.x) if absf(direction.x) > 0.05 else float(game.boss4_ai_state.get("facing", -1.0))
	var stage_speed := MOVE_SPEED * (1.0 + float(game.boss4_stage - 1) * 0.08)
	game.boss_pos = (game.boss_pos + direction * stage_speed * game._boss_card_move_multiplier() * delta).clamp(Vector2(128.0, 120.0), game.WORLD_SIZE - Vector2(128.0, 120.0))


func _pick_move_target() -> void:
	var target_player: Vector2 = game._boss_target_pos(false, 0.14)
	var away: Vector2 = (game.boss_pos - target_player).normalized()
	if away.length() <= 0.01:
		away = Vector2.RIGHT
	var tangent: Vector2 = away.orthogonal() * (-1.0 if game.rng.randf() < 0.5 else 1.0)
	var distance: float = game.rng.randf_range(MOVE_TARGET_MIN_DISTANCE, MOVE_TARGET_MAX_DISTANCE)
	var target: Vector2 = target_player + away * distance * 0.55 + tangent * distance * 0.72
	game.boss4_ai_state["move_target"] = target.clamp(Vector2(150.0, 135.0), game.WORLD_SIZE - Vector2(150.0, 135.0))


func _update_contact(_delta: float) -> void:
	var cooldowns: Dictionary = Dictionary(game.boss4_ai_state.get("contact_cooldowns", {}))
	for target_value in game._combat_targets():
		var target: Dictionary = Dictionary(target_value)
		var peer_id := int(target.get("peer_id", game._mp_unique_id()))
		var key := str(peer_id)
		var position := Vector2(target.get("pos", game.player_pos))
		if position.distance_to(game.boss_pos) > CONTACT_RADIUS or float(cooldowns.get(key, 0.0)) > 0.0:
			continue
		var damage: int = game._boss4_damage(0.052, 22.0)
		var push: Vector2 = (position - game.boss_pos).normalized()
		if push.length() <= 0.01:
			push = Vector2.RIGHT
		if bool(target.get("local", peer_id == game._mp_unique_id())):
			game._damage_player(damage, "contato_boss4")
			game.player_pos = game._clamp_player_world(game.player_pos + game._hostile_knockback(push * CONTACT_KNOCKBACK))
		else:
			game._send_peer_damage(peer_id, damage, "contato_boss4")
		cooldowns[key] = CONTACT_COOLDOWN
	game.boss4_ai_state["contact_cooldowns"] = cooldowns


func _choose_action() -> String:
	var stage := clampi(int(game.boss4_stage), 1, 4)
	var distance: float = game.boss_pos.distance_to(game._boss_target_pos(false, 0.16))
	var available: Array[String] = ["slam", "tongue", "comet"]
	if stage >= 2:
		available.append_array(["jump", "fissure", "leak"])
	if stage >= 3:
		available.append_array(["prison", "clone", "combo"])
		if game.petro_active:
			available.append("vampirism")
	if stage >= 4:
		available.append_array(["fragments", "gravity", "collapse", "meteor"])
	var cooldowns: Dictionary = Dictionary(game.boss4_ai_state.get("cooldowns", {}))
	var best := "comet"
	var best_score := -INF
	for action in available:
		if float(cooldowns.get(action, 0.0)) > 0.0:
			continue
		var score := _action_score(action, distance)
		if action == game.boss4_last_attack:
			score -= 100.0
		var history: Array = Array(game.boss4_ai_state.get("history", []))
		if action in history:
			score -= 16.0
		if score > best_score:
			best_score = score
			best = action
	return best


func _action_score(action: String, distance: float) -> float:
	match action:
		"slam": return 42.0 if distance <= 205.0 else 6.0
		"tongue": return 37.0 if distance >= 150.0 and distance <= 385.0 else 12.0
		"jump": return 39.0 if distance >= 280.0 else 14.0
		"comet": return 34.0 if distance >= 310.0 else 18.0
		"fissure": return 29.0 + float(game.boss4_stage) * 2.0
		"leak": return 27.0 if not game.boss4_secondary_active else -50.0
		"prison": return 33.0 if game.boss4_prison.is_empty() else -50.0
		"clone": return 30.0 if game.boss4_clone.is_empty() else -50.0
		"vampirism": return 38.0 if game.petro_active and game.boss4_vampire_timer <= 0.0 else -50.0
		"combo": return 36.0 if distance <= 330.0 else 22.0
		"fragments": return 34.0
		"gravity": return 35.0 if distance >= 200.0 else 24.0
		"collapse": return 31.0
		"meteor": return 40.0 if not game.boss4_meteor_event_started else -50.0
	return 0.0


func _begin_action(action: String) -> void:
	if action.is_empty() or not ACTION_TIMINGS.has(action):
		game.boss4_attack_timer = 0.4
		return
	var target: Vector2 = game._boss_target_pos(false, 0.20)
	var direction: Vector2 = (target - game.boss_pos).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.LEFT
	game.boss4_ai_state["action"] = action
	game.boss4_ai_state["action_elapsed"] = 0.0
	game.boss4_ai_state["action_total_elapsed"] = 0.0
	game.boss4_ai_state["action_fired"] = false
	game.boss4_ai_state["combo_step"] = 0
	game.boss4_ai_state["attack_dir"] = direction
	game.boss4_ai_state["facing"] = signf(direction.x) if absf(direction.x) > 0.05 else float(game.boss4_ai_state.get("facing", -1.0))
	if action == "jump":
		game.boss4_ai_state["jump_from"] = game.boss_pos
		game.boss4_ai_state["jump_to"] = target.clamp(Vector2(138.0, 128.0), game.WORLD_SIZE - Vector2(138.0, 128.0))
		game.boss4_ai_state["jump_progress"] = 0.0
		game.boss4_ai_state["land_hit"] = false
	_set_state(STATE_WINDUP)
	game.boss4_attack_pose_timer = maxf(game.boss4_attack_pose_timer, float(Dictionary(ACTION_TIMINGS[action]).get("windup", 0.5)))
	var cooldowns: Dictionary = Dictionary(game.boss4_ai_state.get("cooldowns", {}))
	cooldowns[action] = float(Dictionary(ACTION_TIMINGS[action]).get("cooldown", 5.0))
	game.boss4_ai_state["cooldowns"] = cooldowns
	var history: Array = Array(game.boss4_ai_state.get("history", []))
	history.append(action)
	while history.size() > 2:
		history.pop_front()
	game.boss4_ai_state["history"] = history
	game.boss4_last_attack = action


func _update_action(delta: float) -> void:
	var action := String(game.boss4_ai_state.get("action", ""))
	if action.is_empty() or not ACTION_TIMINGS.has(action):
		_finish_action()
		return
	var timings: Dictionary = Dictionary(ACTION_TIMINGS[action])
	var state := String(game.boss4_ai_state.get("state", STATE_WINDUP))
	game.boss4_ai_state["action_elapsed"] = float(game.boss4_ai_state.get("action_elapsed", 0.0)) + delta
	game.boss4_ai_state["action_total_elapsed"] = float(game.boss4_ai_state.get("action_total_elapsed", 0.0)) + delta
	var elapsed := float(game.boss4_ai_state["action_elapsed"])
	if state == STATE_WINDUP:
		if elapsed >= float(timings.get("windup", 0.5)):
			game.boss4_ai_state["action_elapsed"] = 0.0
			_set_state(STATE_JUMP if action == "jump" else STATE_ACTIVE)
		return
	if state == STATE_JUMP:
		_update_jump(delta, timings)
		return
	if state == STATE_LAND:
		_update_land(delta, timings)
		return
	if state == STATE_ACTIVE:
		if action == "combo":
			_update_combo(elapsed)
		elif not bool(game.boss4_ai_state.get("action_fired", false)):
			game.boss4_ai_state["action_fired"] = true
			_fire_action(action)
		if elapsed >= float(timings.get("active", 0.12)):
			game.boss4_ai_state["action_elapsed"] = 0.0
			_set_state(STATE_RECOVER)
		return
	if state == STATE_RECOVER and elapsed >= float(timings.get("recover", 0.5)):
		_finish_action()


func _update_jump(_delta: float, timings: Dictionary) -> void:
	var duration := maxf(0.01, float(timings.get("active", 0.74)))
	var progress := clampf(float(game.boss4_ai_state.get("action_elapsed", 0.0)) / duration, 0.0, 1.0)
	var from := Vector2(game.boss4_ai_state.get("jump_from", game.boss_pos))
	var to := Vector2(game.boss4_ai_state.get("jump_to", game.boss_pos))
	game.boss4_ai_state["jump_progress"] = progress
	game.boss_pos = from.lerp(to, progress * progress * (3.0 - 2.0 * progress))
	if progress >= 1.0:
		game.boss4_ai_state["action_elapsed"] = 0.0
		_set_state(STATE_LAND)


func _update_land(_delta: float, timings: Dictionary) -> void:
	if not bool(game.boss4_ai_state.get("land_hit", false)):
		game.boss4_ai_state["land_hit"] = true
		_apply_radial_hit(game.boss_pos, 188.0, game._boss4_damage(0.115, 48.0), "salto_boss4", 148.0)
		game._spawn_radial_particles(game.boss_pos, Color(1.0, 0.48, 0.16), 38)
		game._vibrate(190, 0.62)
	if float(game.boss4_ai_state.get("action_elapsed", 0.0)) >= 0.18:
		game.boss4_ai_state["action_elapsed"] = 0.0
		_set_state(STATE_RECOVER)
		game.boss4_ai_state["jump_progress"] = 0.0


func _update_combo(elapsed: float) -> void:
	var step := int(game.boss4_ai_state.get("combo_step", 0))
	if step == 0:
		_apply_front_hit(178.0, 0.88, game._boss4_damage(0.072, 28.0), "combo_boss4_1", 82.0)
		game.boss4_ai_state["combo_step"] = 1
	elif step == 1 and elapsed >= 0.48:
		_apply_tongue_hit(game._boss4_damage(0.064, 24.0), "combo_boss4_2")
		game.boss4_ai_state["combo_step"] = 2
	elif step == 2 and elapsed >= 0.98:
		game._spawn_boss4_comet()
		game.boss4_ai_state["combo_step"] = 3


func _fire_action(action: String) -> void:
	match action:
		"slam":
			_apply_front_hit(192.0, 0.92, game._boss4_damage(0.095, 42.0), "pancada_boss4", 118.0)
			game._spawn_radial_particles(game.boss_pos + Vector2(game.boss4_ai_state.get("attack_dir", Vector2.LEFT)) * 86.0, Color(1.0, 0.56, 0.18), 28)
		"tongue":
			_apply_tongue_hit(game._boss4_damage(0.075, 34.0), "lingua_boss4")
		"comet":
			game._spawn_boss4_comet()
		"fissure":
			game._spawn_boss4_fissure()
		"leak":
			game._start_boss4_secondary()
		"prison":
			game._start_boss4_orbital_prison()
		"clone":
			game._spawn_boss4_clone()
		"vampirism":
			game._start_boss4_vampirism()
		"fragments":
			game._spawn_boss4_cosmic_fragments(5)
		"gravity":
			game._spawn_boss4_gravity_well()
			game._spawn_boss4_laser_fan(false)
		"collapse":
			game._spawn_boss4_collapse_zone()
			game._spawn_boss4_rupture_vector(true)
		"meteor":
			game._start_boss4_meteor_event()


func _apply_front_hit(reach: float, half_angle: float, damage: int, source: String, knockback: float) -> void:
	var direction := Vector2(game.boss4_ai_state.get("attack_dir", Vector2.LEFT)).normalized()
	for target_value in game._combat_targets():
		var target: Dictionary = Dictionary(target_value)
		var position := Vector2(target.get("pos", game.player_pos))
		var offset: Vector2 = position - game.boss_pos
		if offset.length() > reach or offset.length() <= 0.01 or absf(direction.angle_to(offset.normalized())) > half_angle:
			continue
		_damage_target(target, damage, source, offset.normalized() * knockback)


func _apply_radial_hit(center: Vector2, radius: float, damage: int, source: String, knockback: float) -> void:
	for target_value in game._combat_targets():
		var target: Dictionary = Dictionary(target_value)
		var position := Vector2(target.get("pos", game.player_pos))
		if position.distance_to(center) > radius:
			continue
		var direction := (position - center).normalized()
		if direction.length() <= 0.01:
			direction = Vector2.RIGHT
		_damage_target(target, damage, source, direction * knockback)


func _apply_tongue_hit(damage: int, source: String) -> void:
	var direction := Vector2(game.boss4_ai_state.get("attack_dir", Vector2.LEFT)).normalized()
	var start: Vector2 = game.boss_pos + direction * 52.0
	var finish: Vector2 = start + direction * 355.0
	for target_value in game._combat_targets():
		var target: Dictionary = Dictionary(target_value)
		var position := Vector2(target.get("pos", game.player_pos))
		if game._distance_to_segment(position, start, finish) > 44.0:
			continue
		var pull: Vector2 = (game.boss_pos - position).normalized() * 76.0
		_damage_target(target, damage, source, pull)
	game.phase4_enemy_hazards.append({"kind": "boss4_tongue_trace", "a": start, "b": finish, "age": 0.0, "life": 0.24, "max": 0.24, "warning": 0.0})


func _damage_target(target: Dictionary, damage: int, source: String, impulse: Vector2) -> void:
	var peer_id := int(target.get("peer_id", game._mp_unique_id()))
	if bool(target.get("local", peer_id == game._mp_unique_id())):
		game._damage_player(damage, source)
		game.player_pos = game._clamp_player_world(game.player_pos + game._hostile_knockback(impulse))
	else:
		game._send_peer_damage(peer_id, damage, source)


func _finish_action() -> void:
	game.boss4_ai_state["action"] = ""
	game.boss4_ai_state["action_elapsed"] = 0.0
	game.boss4_ai_state["action_total_elapsed"] = 0.0
	game.boss4_ai_state["action_fired"] = false
	game.boss4_ai_state["combo_step"] = 0
	_set_state(STATE_WALK)
	_pick_move_target()
	var stage := clampi(int(game.boss4_stage), 1, 4)
	game.boss4_attack_timer = game._boss_party_scaled_interval(ACTION_GAP_BY_STAGE[stage], 0.72)
