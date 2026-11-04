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

# Locomocao por saltos (docs/BOSS4_REWORK_BRIEF.md secao 2). Nunca desliza.
const HOP_PREP := 0.22
const HOP_PUSH := 0.08
const HOP_AIR := 0.46
const HOP_IMPACT := 0.14
const HOP_PAUSE_RANGE := Vector2(0.24, 0.55)
const HOP_DISTANCE_RANGE := Vector2(140.0, 240.0)
const HOP_HEIGHT := 64.0
const HOP_PHASE_PAUSE := "pause"
const HOP_PHASE_PREP := "prep"
const HOP_PHASE_PUSH := "push"
const HOP_PHASE_AIR := "air"
const HOP_PHASE_IMPACT := "impact"

# Lingua-Arpao (secao 4 do brief).
const TONGUE_RANGE := 430.0
const TONGUE_TRACK_TIME := 0.30
const TONGUE_FIRE_TIME := 0.15
const TONGUE_HOLD_TIME := 0.30
const TONGUE_HIT_RADIUS := 38.0
const TONGUE_GRAB_DISTANCE := 96.0
const TONGUE_MOUTH_OFFSET := 44.0
const TONGUE_DASH_BREAK_WINDOW := 0.22

# Raio do Capacete: varre um arco a partir do visor.
const BEAM_RANGE := 540.0
const BEAM_ARC := deg_to_rad(110.0)
const BEAM_HALF_WIDTH := 22.0
const BEAM_TICK := 0.3
## Visor medido em boss4_comet_v2_02/03 (138,166), quadro reduzido 0.9 nos pes, escala 224/384.
const BEAM_VISOR_OFFSET := Vector2(-28.0, -4.0)

# Poco Gravitacional: singularidade que puxa; o sapo salta em volta e o poco implode.
const WELL_PULL_RADIUS := 300.0
const WELL_CORE_RADIUS := 56.0
const WELL_BURST_RADIUS := 150.0
const WELL_COLLAPSE_AT := 2.9
const WELL_COLLAPSE_WARN := 0.5
const WELL_LIFE := 3.35
const WELL_PULL_SPEED := Vector2(60.0, 200.0)
const WELL_CORE_TICK := 0.4
const WELL_SLAM_TIME := 0.32
const WELL_HOP_START := 0.4
const WELL_HOP_SPACING := 0.98
const WELL_HOP_COUNT := 2
const WELL_ORBIT_RADIUS := 215.0
const WELL_HOP_RING := Vector2(40.0, 175.0)
const WELL_HOP_RING_LIFE := 0.5

# Salto Esmagador: anel de choque que se expande a partir do pouso.
const SHOCK_RING_LIFE := 0.72
const SHOCK_RING_RADIUS := Vector2(70.0, 340.0)
const SHOCK_RING_BAND := 30.0
const JUMP_DIRECT_RADIUS := 120.0

# Sorteio de assinatura por estagio; as demais habilidades seguem disponiveis via
# force_action_for_test/variacoes futuras, mas fora do sorteio padrao.
const STAGE_ACTIONS := {
	1: ["slam", "tongue", "jump"],
	2: ["slam", "tongue", "jump", "comet"],
	3: ["slam", "tongue", "jump", "comet", "gravity"],
	4: ["slam", "tongue", "jump", "comet", "gravity"],
}

const ACTION_TIMINGS := {
	"slam": {"windup": 0.62, "active": 0.14, "recover": 0.55, "cooldown": 4.6},
	"tongue": {"windup": 0.55, "active": 0.45, "recover": 0.35, "cooldown": 5.6},
	"jump": {"windup": 0.54, "active": 0.74, "recover": 0.62, "cooldown": 7.2},
	"comet": {"windup": 0.7, "active": 0.9, "recover": 0.4, "cooldown": 6.5},
	"fissure": {"windup": 0.72, "active": 0.12, "recover": 0.58, "cooldown": 10.5},
	"leak": {"windup": 0.76, "active": 0.12, "recover": 0.62, "cooldown": 14.5},
	"prison": {"windup": 0.76, "active": 0.12, "recover": 0.64, "cooldown": 13.0},
	"clone": {"windup": 0.64, "active": 0.12, "recover": 0.58, "cooldown": 11.5},
	"vampirism": {"windup": 0.88, "active": 0.12, "recover": 0.68, "cooldown": 18.0},
	"combo": {"windup": 0.54, "active": 1.44, "recover": 0.68, "cooldown": 14.0},
	"fragments": {"windup": 0.68, "active": 0.12, "recover": 0.56, "cooldown": 9.5},
	"gravity": {"windup": 0.8, "active": 3.0, "recover": 0.6, "cooldown": 12.0},
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
		"hop_phase": HOP_PHASE_PAUSE,
		"hop_t": 0.0,
		"hop_pause": 0.12,
		"hop_from": game.boss4_entry_target,
		"hop_to": game.boss4_entry_target,
		"hop_progress": 0.0,
		"aim_locked": false,
		"tongue_len": 0.0,
		"tongue_hit": false,
		"tongue_grab_local": false,
		"tongue_broken": false,
		"tongue_tip": game.boss4_entry_target,
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
	_update_shock_rings()
	_update_singularities(delta)
	var state := String(game.boss4_ai_state.get("state", STATE_IDLE))
	if state != STATE_JUMP and not _hop_airborne() and not game.boss4_ultimate_active:
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
	if game.boss4_attack_timer <= 0.0 and _hop_grounded():
		_begin_action(_choose_action())


func _hop_grounded() -> bool:
	# A preparacao pode ser cancelada por um ataque; no ar e no impacto, nao.
	return String(game.boss4_ai_state.get("hop_phase", HOP_PHASE_PAUSE)) in [HOP_PHASE_PAUSE, HOP_PHASE_PREP]


func _hop_airborne() -> bool:
	var ai: Dictionary = game.boss4_ai_state
	var state := String(ai.get("state", ""))
	var orbiting: bool = state == STATE_ACTIVE and String(ai.get("action", "")) == "gravity"
	return (state == STATE_WALK or orbiting) and String(ai.get("hop_phase", HOP_PHASE_PAUSE)) in [HOP_PHASE_PUSH, HOP_PHASE_AIR]


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
			"jump":
				return "jump"
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
	_set_state(STATE_WALK)
	var ai: Dictionary = game.boss4_ai_state
	var phase := String(ai.get("hop_phase", HOP_PHASE_PAUSE))
	ai["hop_t"] = float(ai.get("hop_t", 0.0)) + delta
	var t: float = float(ai["hop_t"])
	match phase:
		HOP_PHASE_PAUSE:
			ai["hop_progress"] = 0.0
			if t >= float(ai.get("hop_pause", 0.3)):
				_plan_hop()
		HOP_PHASE_PREP:
			if t >= HOP_PREP:
				_set_hop_phase(HOP_PHASE_PUSH)
		HOP_PHASE_PUSH:
			if t >= HOP_PUSH:
				_set_hop_phase(HOP_PHASE_AIR)
		HOP_PHASE_AIR:
			var progress: float = clampf(t / HOP_AIR, 0.0, 1.0)
			ai["hop_progress"] = progress
			var eased: float = progress * progress * (3.0 - 2.0 * progress)
			game.boss_pos = Vector2(ai.get("hop_from", game.boss_pos)).lerp(Vector2(ai.get("hop_to", game.boss_pos)), eased)
			if progress >= 1.0:
				_set_hop_phase(HOP_PHASE_IMPACT)
				game._spawn_radial_particles(game.boss_pos + Vector2(0.0, 18.0), Color(0.72, 0.6, 0.5), 14)
				if game.boss_pos.distance_to(game.player_pos) < 520.0:
					game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.12)
					game.screen_shake_strength = maxf(float(game.screen_shake_strength), 4.0)
		HOP_PHASE_IMPACT:
			ai["hop_progress"] = 0.0
			if t >= HOP_IMPACT:
				var stage := clampi(int(game.boss4_stage), 1, 4)
				var chain_hop: bool = stage >= 3 and game.rng.randf() < 0.35
				ai["hop_pause"] = 0.04 if chain_hop else game.rng.randf_range(HOP_PAUSE_RANGE.x, HOP_PAUSE_RANGE.y) * (1.0 - float(stage - 1) * 0.1)
				_set_hop_phase(HOP_PHASE_PAUSE)


func _set_hop_phase(phase: String) -> void:
	game.boss4_ai_state["hop_phase"] = phase
	game.boss4_ai_state["hop_t"] = 0.0


func _plan_hop() -> void:
	var target: Vector2 = Vector2(game.boss4_ai_state.get("move_target", game.boss4_entry_target))
	var target_player: Vector2 = game._boss_target_pos(false, 0.18)
	var desired_distance: float = lerpf(MOVE_TARGET_MIN_DISTANCE, MOVE_TARGET_MAX_DISTANCE, 0.32 + float(game.boss4_stage - 1) * 0.12)
	if target == Vector2.ZERO or game.boss_pos.distance_to(target) <= 36.0 or target.distance_to(target_player) > desired_distance * 1.9:
		_pick_move_target()
		target = Vector2(game.boss4_ai_state.get("move_target", game.boss4_entry_target))
	var offset: Vector2 = target - game.boss_pos
	if offset.length() <= 8.0:
		game.boss4_ai_state["hop_pause"] = 0.2
		game.boss4_ai_state["hop_t"] = 0.0
		return
	var hop_length: float = clampf(offset.length(), HOP_DISTANCE_RANGE.x, HOP_DISTANCE_RANGE.y)
	var destination: Vector2 = (game.boss_pos + offset.normalized() * hop_length).clamp(Vector2(128.0, 120.0), game.WORLD_SIZE - Vector2(128.0, 120.0))
	game.boss4_ai_state["hop_from"] = game.boss_pos
	game.boss4_ai_state["hop_to"] = destination
	if absf(offset.x) > 0.05:
		game.boss4_ai_state["facing"] = signf(offset.x)
	_set_hop_phase(HOP_PHASE_PREP)


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
	var available: Array[String] = []
	for action_name in Array(STAGE_ACTIONS.get(stage, STAGE_ACTIONS[1])):
		available.append(String(action_name))
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
		"tongue": return 37.0 if distance >= 150.0 and distance <= TONGUE_RANGE else 12.0
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
	game.boss4_ai_state["hop_phase"] = HOP_PHASE_PAUSE
	game.boss4_ai_state["hop_progress"] = 0.0
	if action == "tongue":
		game.boss4_ai_state["aim_locked"] = false
		game.boss4_ai_state["tongue_len"] = 0.0
		game.boss4_ai_state["tongue_hit"] = false
		game.boss4_ai_state["tongue_grab_local"] = false
		game.boss4_ai_state["tongue_broken"] = false
		game.boss4_ai_state["tongue_tip"] = game.boss_pos
	if action == "comet":
		var sweep_side: float = -1.0 if game.rng.randf() < 0.5 else 1.0
		var center_angle: float = direction.angle()
		game.boss4_ai_state["beam_from"] = center_angle - sweep_side * BEAM_ARC * 0.5
		game.boss4_ai_state["beam_to"] = center_angle + sweep_side * BEAM_ARC * 0.5
		game.boss4_ai_state["beam_angle"] = float(game.boss4_ai_state["beam_from"])
		game.boss4_ai_state["beam_hits"] = {}
	if action == "gravity":
		game.boss4_ai_state["well_pos"] = target.clamp(Vector2(120.0, 120.0), game.WORLD_SIZE - Vector2(120.0, 120.0))
		game.boss4_ai_state["well_spawned"] = false
		game.boss4_ai_state["orbit_hop"] = -1
		game.boss4_ai_state["orbit_sign"] = -1.0 if game.rng.randf() < 0.5 else 1.0
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
		if action == "tongue":
			_update_tongue_aim(elapsed)
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
		if action == "gravity":
			_update_gravity_orbit(elapsed)
			if elapsed >= float(timings.get("active", 3.0)):
				game.boss4_ai_state["action_elapsed"] = 0.0
				game.boss4_ai_state["hop_phase"] = HOP_PHASE_PAUSE
				game.boss4_ai_state["hop_progress"] = 0.0
				_set_state(STATE_RECOVER)
			return
		if action == "comet":
			_update_beam(elapsed, float(timings.get("active", 0.9)))
			if elapsed >= float(timings.get("active", 0.9)):
				game.boss4_ai_state["action_elapsed"] = 0.0
				_set_state(STATE_RECOVER)
			return
		if action == "tongue":
			_update_tongue(elapsed, delta)
			if elapsed >= float(timings.get("active", 0.45)):
				game.boss4_ai_state["action_elapsed"] = 0.0
				_finish_tongue_hold()
				_set_state(STATE_RECOVER)
			return
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
		_apply_radial_hit(game.boss_pos, JUMP_DIRECT_RADIUS, game._boss4_damage(0.115, 48.0), "salto_boss4", 148.0)
		game.phase4_enemy_hazards.append({"kind": "boss4_shock_ring", "center": game.boss_pos, "age": 0.0, "life": SHOCK_RING_LIFE, "max": SHOCK_RING_LIFE, "hit": {}})
		game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.32)
		game.screen_shake_strength = maxf(float(game.screen_shake_strength), 11.0)
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


func _tongue_mouth() -> Vector2:
	var direction := Vector2(game.boss4_ai_state.get("attack_dir", Vector2.LEFT)).normalized()
	return game.boss_pos + Vector2(0.0, -34.0) + direction * TONGUE_MOUTH_OFFSET


func _update_tongue_aim(elapsed: float) -> void:
	if elapsed < TONGUE_TRACK_TIME:
		var direction: Vector2 = (game._boss_target_pos(false, 0.0) - game.boss_pos).normalized()
		if direction.length() > 0.01:
			game.boss4_ai_state["attack_dir"] = direction
			if absf(direction.x) > 0.05:
				game.boss4_ai_state["facing"] = signf(direction.x)
		return
	if not bool(game.boss4_ai_state.get("aim_locked", false)):
		game.boss4_ai_state["aim_locked"] = true
		game._play_sfx("shop_countdown_tick", 0.0, 0.5, 1.4)


func _update_tongue(elapsed: float, delta: float) -> void:
	var ai: Dictionary = game.boss4_ai_state
	var direction := Vector2(ai.get("attack_dir", Vector2.LEFT)).normalized()
	var mouth: Vector2 = _tongue_mouth()
	if elapsed <= TONGUE_FIRE_TIME and not bool(ai.get("tongue_hit", false)):
		var u: float = clampf(elapsed / TONGUE_FIRE_TIME, 0.0, 1.0)
		var length: float = TONGUE_RANGE * (1.0 - pow(1.0 - u, 3.0))
		ai["tongue_len"] = length
		ai["tongue_tip"] = mouth + direction * length
		for target_value in game._combat_targets():
			var target: Dictionary = Dictionary(target_value)
			var position := Vector2(target.get("pos", game.player_pos))
			if game._distance_to_segment(position, mouth, mouth + direction * length) > TONGUE_HIT_RADIUS:
				continue
			ai["tongue_hit"] = true
			ai["tongue_tip"] = position
			ai["tongue_len"] = mouth.distance_to(position)
			var is_local: bool = bool(target.get("local", int(target.get("peer_id", game._mp_unique_id())) == game._mp_unique_id()))
			ai["tongue_grab_local"] = is_local
			_damage_target(target, game._boss4_damage(0.04, 16.0), "lingua_boss4", Vector2.ZERO)
			game._vibrate(120, 0.55)
			break
		return
	if bool(ai.get("tongue_hit", false)):
		if bool(ai.get("tongue_grab_local", false)) and not bool(ai.get("tongue_broken", false)):
			if float(game.time_alive) - float(game.last_dash_time) <= TONGUE_DASH_BREAK_WINDOW:
				ai["tongue_broken"] = true
				game._add_text("SOLTOU!", game.player_pos + Vector2(0.0, -86.0), Color(0.7, 1.0, 0.9), 0.8, 18)
			else:
				var hold_point: Vector2 = mouth + direction * TONGUE_GRAB_DISTANCE
				game.player_pos = game._clamp_player_world(game.player_pos.lerp(hold_point, 1.0 - exp(-delta * 11.0)))
				ai["tongue_tip"] = game.player_pos
		ai["tongue_len"] = mouth.distance_to(Vector2(ai.get("tongue_tip", mouth)))
		return
	# Errou: a lingua gruda no chao e o sapo se puxa ate o ponto.
	var anchor: Vector2 = Vector2(ai.get("tongue_tip", mouth + direction * TONGUE_RANGE))
	var pull_speed: float = (TONGUE_RANGE * 0.55) / TONGUE_HOLD_TIME
	var to_anchor: Vector2 = anchor - game.boss_pos
	if to_anchor.length() > TONGUE_GRAB_DISTANCE:
		game.boss_pos = (game.boss_pos + to_anchor.normalized() * minf(pull_speed * delta, to_anchor.length() - TONGUE_GRAB_DISTANCE)).clamp(Vector2(128.0, 120.0), game.WORLD_SIZE - Vector2(128.0, 120.0))
	ai["tongue_len"] = _tongue_mouth().distance_to(anchor)


func _finish_tongue_hold() -> void:
	var ai: Dictionary = game.boss4_ai_state
	if bool(ai.get("tongue_hit", false)) and not bool(ai.get("tongue_broken", false)):
		_apply_front_hit(160.0, 1.25, game._boss4_damage(0.085, 36.0), "tapa_boss4", 170.0)
		game._spawn_radial_particles(_tongue_mouth() + Vector2(ai.get("attack_dir", Vector2.LEFT)) * 70.0, Color(1.0, 0.42, 0.62), 22)
		game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.22)
		game.screen_shake_strength = maxf(float(game.screen_shake_strength), 8.0)


func beam_origin() -> Vector2:
	var offset := BEAM_VISOR_OFFSET
	if float(game.boss4_ai_state.get("facing", -1.0)) > 0.0:
		offset.x = -offset.x
	return game.boss_pos + offset


func _update_beam(elapsed: float, duration: float) -> void:
	var ai: Dictionary = game.boss4_ai_state
	var u: float = clampf(elapsed / maxf(0.01, duration), 0.0, 1.0)
	var eased: float = u * u * (3.0 - 2.0 * u)
	var angle: float = lerp_angle(float(ai.get("beam_from", 0.0)), float(ai.get("beam_to", 0.0)), eased)
	ai["beam_angle"] = angle
	var direction := Vector2.from_angle(angle)
	if absf(direction.x) > 0.2:
		ai["facing"] = signf(direction.x)
	var origin: Vector2 = beam_origin()
	var finish: Vector2 = origin + direction * BEAM_RANGE
	var hits: Dictionary = Dictionary(ai.get("beam_hits", {}))
	for target_value in game._combat_targets():
		var target: Dictionary = Dictionary(target_value)
		var key := str(int(target.get("peer_id", game._mp_unique_id())))
		if float(game.time_alive) < float(hits.get(key, -99.0)):
			continue
		var position := Vector2(target.get("pos", game.player_pos))
		if position.distance_to(Geometry2D.get_closest_point_to_segment(position, origin, finish)) > BEAM_HALF_WIDTH + 14.0:
			continue
		var is_local: bool = bool(target.get("local", int(target.get("peer_id", game._mp_unique_id())) == game._mp_unique_id()))
		if is_local and float(game.time_alive) - float(game.last_dash_time) <= 0.18:
			continue
		hits[key] = float(game.time_alive) + BEAM_TICK
		var push: Vector2 = direction.orthogonal() * signf(float(ai.get("beam_to", 0.0)) - float(ai.get("beam_from", 0.0)))
		_damage_target(target, game._boss4_damage(0.06, 26.0), "raio_capacete_boss4", push * 70.0)
	ai["beam_hits"] = hits


## Aneis de choque do Salto Esmagador: dano uma vez por alvo quando a frente da
## onda passa; dash no momento certo atravessa sem dano.
func _update_shock_rings() -> void:
	for hazard in game.phase4_enemy_hazards:
		if String(hazard.get("kind", "")) != "boss4_shock_ring":
			continue
		var progress: float = clampf(float(hazard.get("age", 0.0)) / maxf(0.01, float(hazard.get("max", SHOCK_RING_LIFE))), 0.0, 1.0)
		var radius: float = shock_ring_radius(progress, Vector2(hazard.get("radii", SHOCK_RING_RADIUS)))
		var center: Vector2 = Vector2(hazard.get("center", game.boss_pos))
		var hit: Dictionary = Dictionary(hazard.get("hit", {}))
		for target_value in game._combat_targets():
			var target: Dictionary = Dictionary(target_value)
			var peer_key := str(int(target.get("peer_id", game._mp_unique_id())))
			if hit.has(peer_key):
				continue
			var position := Vector2(target.get("pos", game.player_pos))
			if absf(position.distance_to(center) - radius) > SHOCK_RING_BAND:
				continue
			hit[peer_key] = true
			var is_local: bool = bool(target.get("local", int(target.get("peer_id", game._mp_unique_id())) == game._mp_unique_id()))
			if is_local and float(game.time_alive) - float(game.last_dash_time) <= 0.2:
				continue
			var push: Vector2 = (position - center).normalized()
			_damage_target(target, game._boss4_damage(0.07, 28.0), "onda_salto_boss4", push * 120.0)
		hazard["hit"] = hit


static func shock_ring_radius(progress: float, radii: Vector2 = SHOCK_RING_RADIUS) -> float:
	var eased: float = 1.0 - pow(1.0 - clampf(progress, 0.0, 1.0), 2.2)
	return lerpf(radii.x, radii.y, eased)


## Poco Gravitacional: cria o poco no fim da carga e faz o sapo saltar em volta dele.
func _update_gravity_orbit(elapsed: float) -> void:
	var ai: Dictionary = game.boss4_ai_state
	var well: Vector2 = Vector2(ai.get("well_pos", game.boss_pos))
	if not bool(ai.get("well_spawned", false)):
		ai["well_spawned"] = true
		game.phase4_enemy_hazards.append({"kind": "boss4_singularity", "pos": well, "age": 0.0, "life": WELL_LIFE, "max": WELL_LIFE, "hits": {}, "burst_done": false})
		game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.22)
		game.screen_shake_strength = maxf(float(game.screen_shake_strength), 7.0)
		game._vibrate(120, 0.45)
	var hop: int = int(floor((elapsed - WELL_HOP_START) / WELL_HOP_SPACING)) if elapsed >= WELL_HOP_START else -1
	if hop >= WELL_HOP_COUNT:
		ai["hop_phase"] = HOP_PHASE_PAUSE
		ai["hop_progress"] = 0.0
		_face_point(well)
		return
	if hop < 0:
		_face_point(well)
		return
	if hop != int(ai.get("orbit_hop", -1)):
		ai["orbit_hop"] = hop
		ai["hop_landed"] = false
		var from: Vector2 = game.boss_pos
		var angle: float = (from - well).angle() if from.distance_to(well) > 8.0 else 0.0
		angle += float(ai.get("orbit_sign", 1.0)) * deg_to_rad(95.0)
		ai["hop_from"] = from
		ai["hop_to"] = (well + Vector2.from_angle(angle) * WELL_ORBIT_RADIUS).clamp(Vector2(138.0, 128.0), game.WORLD_SIZE - Vector2(138.0, 128.0))
	var t: float = elapsed - WELL_HOP_START - float(hop) * WELL_HOP_SPACING
	var from_pos: Vector2 = Vector2(ai.get("hop_from", game.boss_pos))
	var to_pos: Vector2 = Vector2(ai.get("hop_to", game.boss_pos))
	var air_start: float = HOP_PREP + HOP_PUSH
	if t < HOP_PREP:
		ai["hop_phase"] = HOP_PHASE_PREP
		_face_point(to_pos)
	elif t < air_start:
		ai["hop_phase"] = HOP_PHASE_PUSH
	elif t < air_start + HOP_AIR:
		ai["hop_phase"] = HOP_PHASE_AIR
		var u: float = (t - air_start) / HOP_AIR
		ai["hop_progress"] = u
		game.boss_pos = from_pos.lerp(to_pos, u * u * (3.0 - 2.0 * u))
	elif t < air_start + HOP_AIR + HOP_IMPACT:
		ai["hop_phase"] = HOP_PHASE_IMPACT
		ai["hop_progress"] = 1.0
		game.boss_pos = to_pos
		if not bool(ai.get("hop_landed", false)):
			ai["hop_landed"] = true
			game.phase4_enemy_hazards.append({"kind": "boss4_shock_ring", "center": to_pos, "age": 0.0, "life": WELL_HOP_RING_LIFE, "max": WELL_HOP_RING_LIFE, "radii": WELL_HOP_RING, "hit": {}})
			game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.16)
			game.screen_shake_strength = maxf(float(game.screen_shake_strength), 6.0)
	else:
		ai["hop_phase"] = HOP_PHASE_PAUSE
		ai["hop_progress"] = 0.0
		_face_point(well)


func _face_point(point: Vector2) -> void:
	var dx: float = point.x - game.boss_pos.x
	if absf(dx) > 6.0:
		game.boss4_ai_state["facing"] = signf(dx)


## Singularidades: puxam o jogador local, ferem no nucleo e implodem no fim.
func _update_singularities(delta: float) -> void:
	for hazard in game.phase4_enemy_hazards:
		if String(hazard.get("kind", "")) != "boss4_singularity":
			continue
		var age: float = float(hazard.get("age", 0.0))
		var center: Vector2 = Vector2(hazard.get("pos", game.boss_pos))
		var hits: Dictionary = Dictionary(hazard.get("hits", {}))
		var collapsing: bool = age >= WELL_COLLAPSE_AT
		for target_value in game._combat_targets():
			var target: Dictionary = Dictionary(target_value)
			var key := str(int(target.get("peer_id", game._mp_unique_id())))
			var position := Vector2(target.get("pos", game.player_pos))
			var distance: float = position.distance_to(center)
			var is_local: bool = bool(target.get("local", int(target.get("peer_id", game._mp_unique_id())) == game._mp_unique_id()))
			var dashing: bool = is_local and float(game.time_alive) - float(game.last_dash_time) <= 0.18
			if collapsing:
				if bool(hazard.get("burst_done", false)) or distance > WELL_BURST_RADIUS or dashing:
					continue
				_damage_target(target, game._boss4_damage(0.1, 42.0), "implosao_boss4", (position - center).normalized() * 170.0)
				continue
			if is_local and not dashing and distance < WELL_PULL_RADIUS and distance > 4.0:
				var strength: float = lerpf(WELL_PULL_SPEED.x, WELL_PULL_SPEED.y, 1.0 - distance / WELL_PULL_RADIUS)
				var ramp: float = clampf(age / 0.35, 0.0, 1.0)
				var step: float = minf(distance - 2.0, strength * ramp * delta)
				game.player_pos = game._clamp_player_world(game.player_pos + (center - position).normalized() * step)
			if distance <= WELL_CORE_RADIUS and float(game.time_alive) >= float(hits.get(key, -99.0)) and not dashing:
				hits[key] = float(game.time_alive) + WELL_CORE_TICK
				_damage_target(target, game._boss4_damage(0.035, 14.0), "nucleo_poco_boss4", Vector2.ZERO)
		if collapsing and not bool(hazard.get("burst_done", false)):
			hazard["burst_done"] = true
			game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.3)
			game.screen_shake_strength = maxf(float(game.screen_shake_strength), 10.0)
			game._spawn_radial_particles(center, Color(0.86, 0.4, 1.0), 34)
			game._vibrate(170, 0.6)
		hazard["hits"] = hits


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
