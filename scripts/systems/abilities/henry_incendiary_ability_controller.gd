class_name RTHenryIncendiaryAbilityController
extends "res://scripts/systems/abilities/ability_controller_base.gd"

## Gameplay owner for Henry's first Mutation/Effect pair. Runtime fields stay on
## Main so snapshots and existing combat authority remain compatible.

const SPARK_DAMAGE_MULT := 0.72
const SPARK_SPEED_MULT := 1.12
const SPARK_LIFE := 1.15
const SKILL_NEAR_DAMAGE_MULT := 2.0
const SKILL_FAR_DAMAGE_MULT := 0.82
const SKILL_GUARD_DAMAGE_MULT := 0.46
const ULTIMATE_DAMAGE_MULT := 0.9
# Ignicao Total: uma animacao continua com 3 impactos, cada anel de colunas mais longe.
const ULT_PULSE_TIMES := [0.7, 1.45, 2.2]
const ULT_PULSE_RADII := [150.0, 225.0, 300.0]
const ULT_TOTAL := 2.55
const ULT_SHAKE := [5.0, 7.5, 11.0]
## Linha do tempo dos quadros (inicio em s -> quadro). v2 = folha nova de 10; v1 = folha antiga remapeada.
const ULT_FRAMES_V2 := [[0.0, 0], [0.25, 1], [0.5, 2], [0.7, 3], [0.9, 4], [1.45, 5], [1.75, 6], [2.2, 7], [2.38, 8], [2.5, 9]]
const ULT_FRAMES_V1 := [[0.0, 0], [0.25, 1], [0.5, 2], [0.7, 7], [0.85, 3], [1.15, 4], [1.45, 7], [1.6, 5], [1.95, 6], [2.2, 7], [2.42, 4]]
const SKILL_GUARD_PUSH_SPEED := 250.0
const ULTIMATE_PUSH_SPEED := 330.0
const SPIN_PUSH_SPEED := 390.0
const KNOCKBACK_DRAG := 620.0
const SPIN_DAMAGE_MULT := 0.5
const SPIN_TURNS := 3.5

# Rastro de Brasa (dash): investida curta que deixa chao em chamas.
const DASH_MAX_DISTANCE := 300.0
const TRAIL_SPACING := 26.0
const TRAIL_LIFE := 3.0
const TRAIL_RADIUS := 36.0
const TRAIL_TICK := 0.45
const TRAIL_DAMAGE_MULT := 0.22
const TRAIL_MAX_POINTS := 16

# Estalo Igneo: o 3o golpe do combo e uma bola de fogo que explode no impacto.
const FIREBALL_VISUAL_SCALE := 2.1
const FIREBALL_RADIUS := 74.0
const FIREBALL_DAMAGE_MULT := 0.55

# Combustao em Cadeia (efeito "incandescencia"): quem morre queimando explode e passa as cargas.
const COMBUSTION_BASE_RADIUS := 70.0
const COMBUSTION_RADIUS_PER_STACK := 16.0
const COMBUSTION_DAMAGE_BASE := 0.3
const COMBUSTION_DAMAGE_PER_STACK := 0.14
const COMBUSTION_MAX_PER_FRAME := 6
const COMBUSTION_MAX_DEPTH := 4
const COMBUSTION_QUEUE_CAP := 48
const COMBUSTION_VISUAL_LIFE := 0.5
const IGNITE_EVERY_HITS := 3
const NON_TRIGGER_SOURCES := ["henry_burn", "henry_combustion", "henry_ember_trail", "henry_true_fire", "henry_incandescence"]

const ENTRY_WANDER_TIME := 1.2
const ENTRY_BRAKE_TIME := 0.65
var entrance_active := false
var entrance_elapsed := 0.0
var entrance_peers: Array = []
var entrance_spawn_clock := 0.0
var entrance_finished := false
var entrance_phase := 0
var ember_trail: Array = []
var trail_tick := 0.0
var fireballs: Array = []
var fireball_sequence := 0
var combustion_queue: Array = []
var combustion_bursts: Array = []


func begin_entrance() -> void:
	entrance_active = false
	entrance_finished = false
	entrance_elapsed = 0.0
	entrance_spawn_clock = 0.0
	entrance_phase = core.current_phase
	entrance_peers.clear()
	if core.active_character_key == core.CHARACTER_HENRY:
		entrance_peers.append(core._mp_unique_id())
	if core.is_multiplayer:
		for peer in core.mp_manifest_state_by_peer:
			var selection: Dictionary = core.mp_manifest_state_by_peer[peer]
			if int(selection.get("manifestation", -1)) == core.HENRY_SELECTION_INDEX and not entrance_peers.has(int(peer)):
				entrance_peers.append(int(peer))
	entrance_peers.sort()
	entrance_active = not entrance_peers.is_empty()
	_sync_entrance_pose()


func entrance_duration() -> float:
	return ENTRY_WANDER_TIME + ENTRY_BRAKE_TIME + core.HENRY_ENTRY_DURATION


func entrance_world_speed() -> float:
	return 1.0 - smoothstep(ENTRY_WANDER_TIME, ENTRY_WANDER_TIME + ENTRY_BRAKE_TIME, entrance_elapsed)


func entrance_pose_time() -> float:
	return clampf(entrance_duration() - entrance_elapsed, 0.0, core.HENRY_ENTRY_DURATION)


func _sync_entrance_pose() -> void:
	if core.active_character_key == core.CHARACTER_HENRY:
		core.henry_entry_timer = entrance_pose_time() if entrance_active else 0.0


func cancel_entrance() -> void:
	entrance_active = false
	entrance_finished = true
	core.henry_entry_timer = 0.0


func maintain_entrance_lifecycle() -> void:
	if entrance_active and (core.current_phase != entrance_phase or core.mode in ["menu", "game_over", "phase_transition", "lobby_online_host", "lobby_online_client"]):
		cancel_entrance()


func remove_entrance_peer(peer_id: int) -> void:
	entrance_peers.erase(peer_id)
	if entrance_active and entrance_peers.is_empty() and core._is_world_authority():
		cancel_entrance()


func update_entrance(delta: float) -> bool:
	if not entrance_active:
		return false
	if core.is_dead or core.boss_active or core.time_alive > 0.1 or core.current_phase != entrance_phase:
		cancel_entrance()
		return false
	# Real time, not Engine.time_scale: networking/UI and Henry never freeze.
	var authority: bool = core._is_world_authority()
	entrance_elapsed = minf(entrance_duration() if authority else entrance_duration() - 0.001, entrance_elapsed + maxf(0.0, delta))
	if authority:
		var world_delta := delta * entrance_world_speed()
		entrance_spawn_clock -= world_delta
		if world_delta > 0.0 and entrance_spawn_clock <= 0.0:
			core._spawn_wave()
			entrance_spawn_clock = 0.45
		for enemy in core.enemies:
			var uid := int(enemy.get("uid", 0))
			var direction := Vector2.from_angle(float(uid) * 2.399 + sin(entrance_elapsed * 1.7 + float(uid)) * 0.75)
			var pos := Vector2(enemy.get("pos", core.PLAYER_START))
			enemy["pos"] = (pos + direction * 48.0 * world_delta).clamp(Vector2(48, 48), core.WORLD_SIZE - Vector2(48, 48))
			enemy["facing_dir"] = direction
			enemy["phase"] = float(enemy.get("phase", 0.0)) + world_delta * 6.0
		if entrance_elapsed >= entrance_duration():
			cancel_entrance()
			core._cancel_combat_aim_state(true)
			core.net_world_visual_sync_last_ms = 0
	_sync_entrance_pose()
	return true


func entrance_snapshot() -> Dictionary:
	return {"active": entrance_active, "elapsed": entrance_elapsed, "peers": entrance_peers.duplicate()}


func apply_entrance_snapshot(data: Dictionary) -> void:
	if not core._is_world_replica() or entrance_finished:
		return
	var incoming := clampf(float(data.get("elapsed", 0.0)), 0.0, entrance_duration())
	# World snapshots already reject stale sequence IDs. Never rewind the pose.
	entrance_elapsed = maxf(entrance_elapsed, incoming)
	entrance_peers.clear()
	for peer in Array(data.get("peers", [])).slice(0, 3):
		if int(peer) > 0 and not entrance_peers.has(int(peer)):
			entrance_peers.append(int(peer))
	entrance_active = bool(data.get("active", false)) and not entrance_peers.is_empty()
	if not entrance_active:
		cancel_entrance()
		core._cancel_combat_aim_state(true)
	_sync_entrance_pose()


func reset() -> void:
	if not is_configured():
		return
	cancel_entrance()
	core.henry_attack_combo = 0
	core.henry_attack_visual_stage = 0
	core.henry_skill_cast_active = false
	core.henry_skill_cast_elapsed = 0.0
	core.henry_skill_cast_direction = Vector2.RIGHT
	core.henry_skill_damage_applied = false
	core.henry_flame_cones.clear()
	core.henry_ultimate_cast_active = false
	core.henry_ultimate_cast_elapsed = 0.0
	core.henry_ultimate_center = Vector2.ZERO
	core.henry_ultimate_event_id = ""
	core.henry_ultimate_pulses_released = 0
	core.henry_heat_waves.clear()
	core.henry_spin_active = false
	core.henry_spin_elapsed = 0.0
	core.henry_spin_origin = Vector2.ZERO
	core.henry_spin_dash_target = Vector2.ZERO
	core.henry_spin_dash_direction = Vector2.RIGHT
	core.henry_spin_event_id = ""
	core.henry_boss_burn_state.clear()
	core.henry_friction = 0.0
	core.henry_friction_release_timer = 0.0
	core.henry_incandescence_active_timer = 0.0
	core.henry_incandescence_tick_timer = 0.0
	core.henry_incandescence_intensity = 0.0
	core.henry_incandescence_target_dwell.clear()
	core.henry_incandescence_zones.clear()
	core._reset_henry_idle_animation()
	ember_trail.clear()
	trail_tick = 0.0
	fireballs.clear()
	combustion_queue.clear()
	combustion_bursts.clear()
	for enemy in core.enemies:
		_clear_burn(enemy)
		enemy.erase("henry_incandescence_heat")


## Rework: a passiva nao depende mais de tomar dano (Combustao em Cadeia via on_enemy_killed).
func on_player_damaged(_actual_damage: int) -> void:
	return


func combustion_active() -> bool:
	return is_configured() and core.active_character_key == core.CHARACTER_HENRY and core.effect_key == "incandescencia"


func fire_auto_attack() -> bool:
	if not is_configured() or core.active_character_key != core.CHARACTER_HENRY or core.mutation_key != "incendiario":
		return false
	core.henry_attack_visual_stage = core.henry_attack_combo
	core.henry_attack_combo = (core.henry_attack_combo + 1) % 3
	var before: int = core.bullets.size()
	core._fire_projectile("henry_spark", core.player_damage * SPARK_DAMAGE_MULT, core.BULLET_SPEED * SPARK_SPEED_MULT, SPARK_LIFE, false)
	if core.bullets.size() <= before:
		return false
	var bullet: Dictionary = core.bullets[-1]
	bullet["henry_burn"] = true
	bullet["henry_combo_stage"] = core.henry_attack_visual_stage
	bullet["source_character"] = core.CHARACTER_HENRY
	if core.henry_attack_visual_stage == 2:
		fireball_sequence += 1
		bullet["henry_fireball_id"] = fireball_sequence
		bullet["visual_scale"] = maxf(float(bullet.get("visual_scale", 1.0)), FIREBALL_VISUAL_SCALE)
		fireballs.append({"id": fireball_sequence, "pos": Vector2(bullet.get("pos", core.player_pos)), "life": float(bullet.get("life", 1.0))})
	return true


func is_spin_invulnerable() -> bool:
	return is_configured() and core.active_character_key == core.CHARACTER_HENRY and core.mutation_key == "incendiario" and core.henry_spin_active


func spin_reached_destination() -> bool:
	return is_spin_invulnerable() and core.henry_spin_elapsed >= core.HENRY_SPIN_DASH_DURATION


func spin_turns() -> float:
	var progress := clampf(core.henry_spin_elapsed / maxf(0.01, core.HENRY_SPIN_DURATION), 0.0, 1.0)
	# Ease-out integrates a high initial angular speed into a readable stop.
	return SPIN_TURNS * (1.0 - pow(1.0 - progress, 2.15))


func spin_frame(frame_count: int = 8) -> int:
	return posmod(int(floor(spin_turns() * float(maxi(1, frame_count)))), maxi(1, frame_count))


func begin_spin_dash(target_world: Vector2) -> bool:
	if not is_configured() or core.active_character_key != core.CHARACTER_HENRY or core.mutation_key != "incendiario" or core.henry_spin_active:
		return false
	var direction: Vector2 = target_world - core.player_pos
	if direction.length_squared() <= 0.001:
		direction = core.last_facing
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	core.henry_spin_active = true
	core.henry_spin_elapsed = 0.0
	core.henry_spin_origin = core.player_pos
	var dash_target: Vector2 = target_world
	if dash_target.distance_to(core.player_pos) > DASH_MAX_DISTANCE:
		dash_target = core.player_pos + direction.normalized() * DASH_MAX_DISTANCE
	core.henry_spin_dash_target = core._clamp_player_world(dash_target)
	core.henry_spin_dash_direction = direction.normalized()
	_add_trail_point(core.player_pos)
	core.henry_spin_event_id = core._next_network_event_id("henry_spin")
	_clear_hostile_effects()
	core._cancel_combat_aim_state(true)
	return true


func begin_skill(target_world = null) -> bool:
	if not is_configured() or core.active_character_key != core.CHARACTER_HENRY or core.mutation_key != "incendiario" or core._local_player_controls_locked():
		return false
	var direction := _target_direction(target_world)
	core.henry_skill_cast_active = true
	core.henry_skill_cast_elapsed = 0.0
	core.henry_skill_cast_direction = direction
	core.henry_skill_damage_applied = false
	core._set_player_attack_visual_dir(direction)
	core.henry_flame_cones.append({
		"origin": core.player_pos,
		"dir": direction,
		"life": core.HENRY_SKILL_CAST_DURATION,
		"max": core.HENRY_SKILL_CAST_DURATION,
		"event_id": core._next_network_event_id("henry_cone"),
	})
	core._send_network_ability_visual(core.NET_ABILITY_SKILL, core.player_pos, core.player_pos + direction * core.HENRY_SKILL_RANGE, core.HENRY_SKILL_CAST_DURATION)
	return true


func cast_ultimate() -> bool:
	if not is_configured() or core.active_character_key != core.CHARACTER_HENRY or core.mutation_key != "incendiario" or core._local_player_controls_locked():
		return false
	core.henry_ultimate_cast_active = true
	core.henry_ultimate_cast_elapsed = 0.0
	core.henry_ultimate_center = core.player_pos
	core.henry_ultimate_event_id = core._next_network_event_id("henry_heat")
	core.henry_ultimate_pulses_released = 0
	core._send_network_ability_visual(
		core.NET_ABILITY_SECONDARY,
		core.henry_ultimate_center,
		core.henry_ultimate_center,
		ULT_TOTAL + core.HENRY_ULTIMATE_WAVE_DURATION,
		core.HENRY_ULTIMATE_CAST_DURATION
	)
	return true


func _release_ultimate_pulse(pulse_index: int) -> void:
	var center: Vector2 = core.henry_ultimate_center
	var pulse_radius: float = float(ULT_PULSE_RADII[clampi(pulse_index, 0, ULT_PULSE_RADII.size() - 1)])
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.22 + 0.06 * float(pulse_index))
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), float(ULT_SHAKE[clampi(pulse_index, 0, 2)]))
	core._vibrate(90 + 40 * pulse_index, 0.4 + 0.15 * float(pulse_index))
	core.henry_heat_waves.append({
		"center": center,
		"radius": 0.0,
		"max_radius": pulse_radius,
		"life": core.HENRY_ULTIMATE_WAVE_DURATION,
		"max": core.HENRY_ULTIMATE_WAVE_DURATION,
		"event_id": "%s:%d" % [core.henry_ultimate_event_id, pulse_index],
		"kind": "ultimate",
		"pulse": pulse_index,
	})
	_apply_heat_wave(center, pulse_radius)


func update(delta: float) -> void:
	if not is_configured():
		return
	if core.mutation_key == "incendiario":
		_update_cast(delta)
		_update_ultimate_cast(delta)
		_update_spin(delta)
	_update_incandescence(delta)
	_update_trail(delta)
	_update_fireballs()
	_update_combustion(delta)
	for cone in core.henry_flame_cones:
		cone["life"] = maxf(0.0, float(cone.get("life", 0.0)) - delta)
	core.henry_flame_cones = core.henry_flame_cones.filter(func(cone): return float(cone.get("life", 0.0)) > 0.0)
	for wave in core.henry_heat_waves:
		var delay := maxf(0.0, float(wave.get("delay", 0.0)) - delta)
		wave["delay"] = delay
		if delay > 0.0:
			continue
		wave["life"] = maxf(0.0, float(wave.get("life", 0.0)) - delta)
		var progress := 1.0 - float(wave["life"]) / maxf(0.01, float(wave.get("max", 0.72)))
		wave["radius"] = float(wave.get("max_radius", core.HENRY_ULTIMATE_RADIUS)) * clampf(progress, 0.0, 1.0)
	core.henry_heat_waves = core.henry_heat_waves.filter(func(wave): return float(wave.get("life", 0.0)) > 0.0 or float(wave.get("delay", 0.0)) > 0.0)
	if not core._is_world_authority():
		return
	for enemy in core.enemies:
		_update_enemy_burn(enemy, delta)
		_update_knockback(enemy, delta)
	if not core.arauto.is_empty():
		_update_enemy_burn(core.arauto, delta)
		_update_knockback(core.arauto, delta)
	_update_boss_burn(delta)


func _update_ultimate_cast(delta: float) -> void:
	if not core.henry_ultimate_cast_active:
		return
	var total_duration: float = ULT_TOTAL
	core.henry_ultimate_cast_elapsed = minf(total_duration, core.henry_ultimate_cast_elapsed + delta)
	var due_pulses := 0
	for pulse_time in ULT_PULSE_TIMES:
		if core.henry_ultimate_cast_elapsed + 0.0001 >= float(pulse_time):
			due_pulses += 1
	while core.henry_ultimate_pulses_released < due_pulses:
		_release_ultimate_pulse(core.henry_ultimate_pulses_released)
		core.henry_ultimate_pulses_released += 1
	if core.henry_ultimate_cast_elapsed >= total_duration:
		core.henry_ultimate_cast_active = false
		core.henry_ultimate_cast_elapsed = 0.0
		core.henry_ultimate_center = Vector2.ZERO
		core.henry_ultimate_event_id = ""


func _update_spin(delta: float) -> void:
	if not core.henry_spin_active:
		return
	var previous_elapsed: float = core.henry_spin_elapsed
	core.henry_spin_elapsed = minf(core.HENRY_SPIN_DURATION, core.henry_spin_elapsed + maxf(0.0, delta))
	var previous_dash := clampf(previous_elapsed / maxf(0.01, core.HENRY_SPIN_DASH_DURATION), 0.0, 1.0)
	var current_dash := clampf(core.henry_spin_elapsed / maxf(0.01, core.HENRY_SPIN_DASH_DURATION), 0.0, 1.0)
	if current_dash > previous_dash:
		var travel_ease := smoothstep(0.0, 1.0, current_dash)
		core.player_pos = core._clamp_player_world(core.henry_spin_origin.lerp(core.henry_spin_dash_target, travel_ease))
		_extend_trail_to(core.player_pos)
	_clear_hostile_effects()
	if core.henry_spin_elapsed >= core.HENRY_SPIN_DURATION:
		_release_spin_burst()


func _release_spin_burst() -> void:
	var center: Vector2 = core.player_pos
	core.henry_heat_waves.append({
		"center": center, "radius": 0.0, "max_radius": core.HENRY_SPIN_EXPLOSION_RADIUS,
		"life": core.HENRY_ULTIMATE_WAVE_DURATION, "max": core.HENRY_ULTIMATE_WAVE_DURATION,
		"event_id": core.henry_spin_event_id, "kind": "spin_final",
	})
	_apply_radial_damage(center, core.HENRY_SPIN_EXPLOSION_RADIUS, core.player_damage * SPIN_DAMAGE_MULT, "henry_spin_burst")
	core.henry_spin_active = false
	core.henry_spin_elapsed = 0.0
	core.henry_spin_origin = Vector2.ZERO
	core.henry_spin_dash_target = Vector2.ZERO
	core.henry_spin_event_id = ""


func _clear_hostile_effects() -> void:
	core.player_stun_timer = 0.0
	core.player_silence_timer = 0.0
	core.player_freeze_visual_timer = 0.0
	core.player_control_immunity_timer = maxf(core.player_control_immunity_timer, 0.05)
	core.boss_wave_slow_timer = 0.0
	core.controls_inverted_timer = 0.0
	core.sanguessuga_parasite_timer = 0.0
	core.sanguessuga_bleed_tick_timer = 0.0
	core.sanguessuga_parasite_visual_timer = 0.0


func _update_incandescence(delta: float) -> void:
	for enemy in core.enemies:
		if float(enemy.get("henry_incandescence_heat", 0.0)) > 0.0:
			enemy["henry_incandescence_heat"] = maxf(0.0, float(enemy["henry_incandescence_heat"]) - delta)
	if core.active_character_key != core.CHARACTER_HENRY or core.effect_key != "incandescencia" or core.is_dead or core.player_hp <= 0.0:
		core.henry_incandescence_active_timer = 0.0
		core.henry_incandescence_target_dwell.clear()
		core.henry_incandescence_zones.clear()
		return
	core.henry_friction = 0.0
	core.henry_friction_release_timer = 0.0
	core.henry_incandescence_zones.clear()
	if core.henry_incandescence_active_timer > 0.0:
		core.henry_incandescence_active_timer = maxf(0.0, core.henry_incandescence_active_timer - delta)
		_update_incandescence_targets(delta)
		if core.henry_incandescence_active_timer <= 0.0:
			core.henry_incandescence_target_dwell.clear()
			core.henry_incandescence_tick_timer = 0.0
		return
	if core.henry_friction <= 0.0:
		core.henry_friction_release_timer = 0.0
		return
	core.henry_friction_release_timer = maxf(0.0, core.henry_friction_release_timer - delta)
	if core.henry_friction_release_timer <= 0.0:
		if core.henry_friction >= core.HENRY_FRICTION_MIN_RELEASE:
			_release_incandescence()
		else:
			core.henry_friction_release_timer = core.HENRY_FRICTION_RELEASE_INTERVAL


func _release_incandescence() -> void:
	var intensity := clampf(core.henry_friction / core.HENRY_FRICTION_MAX, 0.08, 1.0)
	var event_id: String = core._next_network_event_id("henry_incandescence")
	core.henry_friction = 0.0
	core.henry_friction_release_timer = 0.0
	core.henry_incandescence_active_timer = core.HENRY_INCANDESCENCE_DURATION
	core.henry_incandescence_tick_timer = 0.0
	core.henry_incandescence_intensity = intensity
	core.henry_incandescence_target_dwell.clear()
	core.henry_incandescence_zones.append({
		"center": core.player_pos,
		"radius": core.HENRY_INCANDESCENCE_RADIUS,
		"life": core.HENRY_INCANDESCENCE_DURATION,
		"max": core.HENRY_INCANDESCENCE_DURATION,
		"intensity": intensity,
		"event_id": event_id,
	})
	core._add_text("ATRITO LIBERADO", core.player_pos + Vector2(0.0, -94.0), Color(1.0, 0.54, 0.12), 0.75, 17)
	core._send_network_ability_visual(
		core.NET_ABILITY_ATTACK,
		core.player_pos,
		core.player_pos,
		core.HENRY_INCANDESCENCE_DURATION,
		core.HENRY_INCANDESCENCE_NET_SENTINEL + intensity
	)


func _update_incandescence_targets(delta: float) -> void:
	var active_keys: Dictionary = {}
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var enemy_pos := Vector2(enemy.get("pos", core.player_pos))
		if core.player_pos.distance_to(enemy_pos) > core.HENRY_INCANDESCENCE_RADIUS:
			continue
		var key := "enemy:%d" % int(enemy.get("uid", hash(enemy)))
		active_keys[key] = true
		core.henry_incandescence_target_dwell[key] = float(core.henry_incandescence_target_dwell.get(key, 0.0)) + delta
		enemy["henry_incandescence_heat"] = 0.48
	if core._arauto_active() and core.player_pos.distance_to(Vector2(core.arauto.get("pos", core.player_pos))) <= core.HENRY_INCANDESCENCE_RADIUS:
		active_keys["arauto"] = true
		core.henry_incandescence_target_dwell["arauto"] = float(core.henry_incandescence_target_dwell.get("arauto", 0.0)) + delta
	if core.boss_active and core.boss_hp > 0.0 and core.player_pos.distance_to(core.boss_pos) <= core.HENRY_INCANDESCENCE_RADIUS:
		active_keys["boss"] = true
		core.henry_incandescence_target_dwell["boss"] = float(core.henry_incandescence_target_dwell.get("boss", 0.0)) + delta
	for key_value in core.henry_incandescence_target_dwell.keys().duplicate():
		if not active_keys.has(key_value):
			core.henry_incandescence_target_dwell.erase(key_value)
	core.henry_incandescence_tick_timer -= delta
	if core.henry_incandescence_tick_timer > 0.0:
		return
	core.henry_incandescence_tick_timer += core.HENRY_INCANDESCENCE_TICK_INTERVAL
	_tick_incandescence_targets(active_keys)


func _tick_incandescence_targets(active_keys: Dictionary) -> void:
	var source_peer: int = core._mp_unique_id()
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var key := "enemy:%d" % int(enemy.get("uid", hash(enemy)))
		if not active_keys.has(key):
			continue
		var damage := _incandescence_tick_damage(float(core.henry_incandescence_target_dwell.get(key, 0.0)))
		core._damage_enemy(enemy, damage, "henry_incandescence", false, false, core.player_pos, "status_tick", source_peer, "incendiario")
	if active_keys.has("arauto"):
		core._damage_arauto(_incandescence_tick_damage(float(core.henry_incandescence_target_dwell.get("arauto", 0.0))), "henry_incandescence", false, false, "status_tick", core.player_pos, source_peer, "incendiario")
	if active_keys.has("boss"):
		core._damage_boss(_incandescence_tick_damage(float(core.henry_incandescence_target_dwell.get("boss", 0.0))), "henry_incandescence", false, false, "status_tick", core.player_pos, source_peer, "incendiario")


func _incandescence_tick_damage(dwell: float) -> float:
	var dwell_ratio := clampf(dwell / core.HENRY_INCANDESCENCE_DURATION, 0.0, 1.0)
	var dwell_mult := lerpf(1.0, core.HENRY_INCANDESCENCE_DWELL_MAX_MULT, dwell_ratio)
	var friction_mult := lerpf(0.65, 1.35, core.henry_incandescence_intensity)
	return maxf(1.0, core.player_damage * core.HENRY_INCANDESCENCE_BURN_RATIO * dwell_mult * friction_mult)


func apply_burn_to_enemy(enemy: Dictionary, source_damage: float, source_peer_id: int = 0, add_stack: bool = true) -> void:
	if enemy.is_empty() or float(enemy.get("hp", 0.0)) <= 0.0:
		return
	enemy["henry_burn_time"] = core.HENRY_BURN_DURATION
	enemy["henry_burn_tick"] = minf(float(enemy.get("henry_burn_tick", core.HENRY_BURN_TICK_INTERVAL)), core.HENRY_BURN_TICK_INTERVAL)
	enemy["henry_burn_damage"] = maxf(float(enemy.get("henry_burn_damage", 0.0)), maxf(1.0, source_damage * core.HENRY_BURN_DAMAGE_RATIO))
	enemy["henry_burn_source_peer"] = source_peer_id if source_peer_id > 0 else core._mp_unique_id()
	if add_stack:
		enemy["henry_burn_stacks"] = mini(core.HENRY_BURN_STACK_MAX, int(enemy.get("henry_burn_stacks", 0)) + 1)
		enemy["henry_burn_stack_flash"] = 0.42


func apply_burn_to_boss(source_damage: float, source_peer_id: int = 0, add_stack: bool = true) -> void:
	if not core.boss_active or core.boss_hp <= 0.0:
		return
	core.henry_boss_burn_state["time"] = core.HENRY_BURN_DURATION
	core.henry_boss_burn_state["tick"] = minf(float(core.henry_boss_burn_state.get("tick", core.HENRY_BURN_TICK_INTERVAL)), core.HENRY_BURN_TICK_INTERVAL)
	core.henry_boss_burn_state["damage"] = maxf(float(core.henry_boss_burn_state.get("damage", 0.0)), maxf(1.0, source_damage * core.HENRY_BURN_DAMAGE_RATIO))
	core.henry_boss_burn_state["source_peer"] = source_peer_id if source_peer_id > 0 else core._mp_unique_id()
	if add_stack:
		core.henry_boss_burn_state["stacks"] = mini(core.HENRY_BURN_STACK_MAX, int(core.henry_boss_burn_state.get("stacks", 0)) + 1)
		core.henry_boss_burn_state["stack_flash"] = 0.42


func burn_stacks(target: Dictionary) -> int:
	return clampi(int(target.get("henry_burn_stacks", 0)), 0, core.HENRY_BURN_STACK_MAX)


func damage_taken_multiplier(target: Dictionary, source: String) -> float:
	if source == "henry_true_fire":
		return 1.0
	return 1.0 + float(burn_stacks(target)) * core.HENRY_BURN_WEAKNESS_PER_STACK


func boss_damage_taken_multiplier(source: String) -> float:
	if source == "henry_true_fire":
		return 1.0
	return 1.0 + float(clampi(int(core.henry_boss_burn_state.get("stacks", 0)), 0, core.HENRY_BURN_STACK_MAX)) * core.HENRY_BURN_WEAKNESS_PER_STACK


func true_damage_for_max_hp(max_hp: float, stacks: int, boss_target: bool = false) -> float:
	var rate: float = core.HENRY_TRUE_DAMAGE_BOSS_RATE_PER_STACK if boss_target else core.HENRY_TRUE_DAMAGE_RATE_PER_STACK
	return maxf(0.0, max_hp) * rate * float(clampi(stacks, 0, core.HENRY_BURN_STACK_MAX))


func consume_breach_enemy(enemy: Dictionary, source_peer_id: int = 0, boss_like: bool = false) -> float:
	var stacks := burn_stacks(enemy)
	if stacks <= 0 or float(enemy.get("hp", 0.0)) <= 0.0:
		return 0.0
	var amount := true_damage_for_max_hp(float(enemy.get("max_hp", enemy.get("hp", 1.0))), stacks, boss_like)
	_clear_burn(enemy)
	core._damage_enemy(enemy, amount, "henry_true_fire", true, false, Vector2(enemy.get("pos", core.player_pos)), "status_tick", source_peer_id, "incendiario", false, "DANO VERDADEIRO")
	return amount


func consume_breach_arauto(source_peer_id: int = 0) -> float:
	if core.arauto.is_empty():
		return 0.0
	var stacks := burn_stacks(core.arauto)
	if stacks <= 0 or float(core.arauto.get("hp", 0.0)) <= 0.0:
		return 0.0
	var amount := true_damage_for_max_hp(float(core.arauto.get("max_hp", core.arauto.get("hp", 1.0))), stacks, true)
	_clear_burn(core.arauto)
	core._damage_arauto(amount, "henry_true_fire", true, false, "status_tick", Vector2(core.arauto.get("pos", core.player_pos)), source_peer_id, "incendiario", false, "DANO VERDADEIRO")
	return amount


func consume_breach_boss(source_peer_id: int = 0) -> float:
	var stacks := clampi(int(core.henry_boss_burn_state.get("stacks", 0)), 0, core.HENRY_BURN_STACK_MAX)
	if stacks <= 0 or not core.boss_active or core.boss_hp <= 0.0:
		return 0.0
	var amount := true_damage_for_max_hp(core.boss_hp_max, stacks, true)
	core.henry_boss_burn_state.clear()
	core._damage_boss(amount, "henry_true_fire", false, true, "status_tick", core.boss_pos, source_peer_id, "incendiario", false, "DANO VERDADEIRO")
	return amount


func _update_cast(delta: float) -> void:
	if not core.henry_skill_cast_active:
		return
	core.henry_skill_cast_elapsed += delta
	if not core.henry_skill_damage_applied and core.henry_skill_cast_elapsed >= core.HENRY_SKILL_IMPACT_TIME:
		core.henry_skill_damage_applied = true
		_apply_flame_cone(core.player_pos, core.henry_skill_cast_direction)
		_apply_skill_guard_burst(core.player_pos)
		_spawn_skill_guard_explosions(core.player_pos)
	if core.henry_skill_cast_elapsed >= core.HENRY_SKILL_CAST_DURATION:
		core.henry_skill_cast_active = false
		core.henry_skill_cast_elapsed = 0.0


func _apply_flame_cone(origin: Vector2, direction: Vector2) -> void:
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var enemy_pos := Vector2(enemy.get("pos", origin))
		if not _inside_cone(origin, direction, enemy_pos):
			continue
		var distance := origin.distance_to(enemy_pos)
		var ratio := clampf(distance / core.HENRY_SKILL_RANGE, 0.0, 1.0)
		var damage_mult := lerpf(SKILL_NEAR_DAMAGE_MULT, SKILL_FAR_DAMAGE_MULT, ratio)
		core._damage_enemy(enemy, core.player_damage * damage_mult, "henry_flame_cone", true, true, origin, "skill_q")
	if core.boss_active and core.boss_hp > 0.0 and _inside_cone(origin, direction, core.boss_pos):
		var boss_ratio := clampf(origin.distance_to(core.boss_pos) / core.HENRY_SKILL_RANGE, 0.0, 1.0)
		core._damage_boss(core.player_damage * lerpf(SKILL_NEAR_DAMAGE_MULT, SKILL_FAR_DAMAGE_MULT, boss_ratio), "henry_flame_cone", true, true, "skill_q", origin)


func _apply_skill_guard_burst(center: Vector2) -> void:
	_apply_radial_damage(center, core.HENRY_SKILL_GUARD_RADIUS, core.player_damage * SKILL_GUARD_DAMAGE_MULT, "henry_guard_burst")


func _spawn_skill_guard_explosions(center: Vector2) -> void:
	for pulse in range(3):
		core.henry_heat_waves.append({
			"center": center, "radius": 0.0, "max_radius": core.HENRY_SKILL_GUARD_RADIUS * (0.72 + float(pulse) * 0.14),
			"life": 0.34, "max": 0.34, "delay": float(pulse) * 0.09,
			"event_id": core._next_network_event_id("henry_guard"), "kind": "guard_burst", "pulse": pulse,
		})


func _apply_radial_damage(center: Vector2, radius: float, damage: float, source: String) -> void:
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) > 0.0 and center.distance_to(Vector2(enemy.get("pos", center))) <= radius:
			core._damage_enemy(enemy, damage, source, true, true, center, "skill_q" if source == "henry_guard_burst" else "skill_shift")
	if core._arauto_active() and center.distance_to(Vector2(core.arauto.get("pos", center))) <= radius:
		core._damage_arauto(damage, source, true, true, "skill_q" if source == "henry_guard_burst" else "skill_shift", center)
	if core.boss_active and core.boss_hp > 0.0 and center.distance_to(core.boss_pos) <= radius:
		core._damage_boss(damage, source, true, true, "skill_q" if source == "henry_guard_burst" else "skill_shift", center)


func _apply_heat_wave(center: Vector2, radius: float = -1.0) -> void:
	if radius <= 0.0:
		radius = core.HENRY_ULTIMATE_RADIUS
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var enemy_pos := Vector2(enemy.get("pos", center))
		var distance := center.distance_to(enemy_pos)
		if distance > radius:
			continue
		core._damage_enemy(enemy, core.player_damage * ULTIMATE_DAMAGE_MULT, "henry_heat_wave", true, true, center, "skill_e")
	if core._arauto_active() and center.distance_to(Vector2(core.arauto.get("pos", center))) <= radius:
		core._damage_arauto(core.player_damage * ULTIMATE_DAMAGE_MULT, "henry_heat_wave", true, true, "skill_e", center)
	if core.boss_active and core.boss_hp > 0.0 and center.distance_to(core.boss_pos) <= radius + 40.0:
		core._damage_boss(core.player_damage * ULTIMATE_DAMAGE_MULT, "henry_heat_wave", true, true, "skill_e", center)


func apply_heat_wave_push(target: Dictionary, center: Vector2, source: String = "henry_heat_wave") -> void:
	if target.is_empty():
		return
	var target_pos := Vector2(target.get("pos", center))
	var push_dir := (target_pos - center).normalized()
	if push_dir.length_squared() <= 0.001:
		push_dir = Vector2.RIGHT.rotated(float(int(target.get("uid", 0)) % 16) * TAU / 16.0)
	var speed := SKILL_GUARD_PUSH_SPEED if source == "henry_guard_burst" else (SPIN_PUSH_SPEED if source == "henry_spin_burst" else ULTIMATE_PUSH_SPEED)
	var current := Vector2(target.get("henry_knockback_velocity", Vector2.ZERO))
	target["henry_knockback_velocity"] = current + push_dir * speed


func _update_knockback(target: Dictionary, delta: float) -> void:
	var velocity := Vector2(target.get("henry_knockback_velocity", Vector2.ZERO))
	if velocity.length_squared() <= 1.0:
		target.erase("henry_knockback_velocity")
		return
	var target_pos := Vector2(target.get("pos", core.player_pos))
	target["pos"] = (target_pos + velocity * delta).clamp(Vector2(40.0, 40.0), core.WORLD_SIZE - Vector2(40.0, 40.0))
	target["henry_knockback_velocity"] = velocity.move_toward(Vector2.ZERO, KNOCKBACK_DRAG * delta)


func _update_enemy_burn(enemy: Dictionary, delta: float) -> void:
	var remaining := maxf(0.0, float(enemy.get("henry_burn_time", 0.0)) - delta)
	var overdrive := maxf(0.0, float(enemy.get("henry_burn_overdrive", 0.0)) - delta)
	enemy["henry_burn_time"] = remaining
	enemy["henry_burn_overdrive"] = overdrive
	enemy["henry_burn_stack_flash"] = maxf(0.0, float(enemy.get("henry_burn_stack_flash", 0.0)) - delta)
	if float(enemy.get("hp", 0.0)) <= 0.0:
		return
	if remaining <= 0.0:
		_clear_burn(enemy)
		return
	enemy["henry_burn_tick"] = float(enemy.get("henry_burn_tick", core.HENRY_BURN_TICK_INTERVAL)) - delta
	if float(enemy["henry_burn_tick"]) > 0.0:
		return
	var interval: float = core.HENRY_BURN_TICK_INTERVAL * (core.HENRY_BURN_OVERDRIVE_TICK_MULT if overdrive > 0.0 else 1.0)
	enemy["henry_burn_tick"] += interval
	var damage: float = float(enemy.get("henry_burn_damage", 1.0)) * (core.HENRY_BURN_OVERDRIVE_DAMAGE_MULT if overdrive > 0.0 else 1.0)
	core._damage_enemy(enemy, damage, "henry_burn", false, false, Vector2(enemy.get("pos", core.player_pos)), "status_tick", int(enemy.get("henry_burn_source_peer", 0)), "incendiario")


func _update_boss_burn(delta: float) -> void:
	if core.henry_boss_burn_state.is_empty():
		return
	core.henry_boss_burn_state["time"] = maxf(0.0, float(core.henry_boss_burn_state.get("time", 0.0)) - delta)
	core.henry_boss_burn_state["overdrive"] = maxf(0.0, float(core.henry_boss_burn_state.get("overdrive", 0.0)) - delta)
	core.henry_boss_burn_state["stack_flash"] = maxf(0.0, float(core.henry_boss_burn_state.get("stack_flash", 0.0)) - delta)
	if not core.boss_active or core.boss_hp <= 0.0 or float(core.henry_boss_burn_state["time"]) <= 0.0:
		core.henry_boss_burn_state.clear()
		return
	core.henry_boss_burn_state["tick"] = float(core.henry_boss_burn_state.get("tick", core.HENRY_BURN_TICK_INTERVAL)) - delta
	if float(core.henry_boss_burn_state["tick"]) > 0.0:
		return
	var overdrive := float(core.henry_boss_burn_state.get("overdrive", 0.0)) > 0.0
	core.henry_boss_burn_state["tick"] += core.HENRY_BURN_TICK_INTERVAL * (core.HENRY_BURN_OVERDRIVE_TICK_MULT if overdrive else 1.0)
	var damage: float = float(core.henry_boss_burn_state.get("damage", 1.0)) * (core.HENRY_BURN_OVERDRIVE_DAMAGE_MULT if overdrive else 1.0)
	core._damage_boss(damage, "henry_burn", false, false, "status_tick", core.boss_pos, int(core.henry_boss_burn_state.get("source_peer", 0)), "incendiario")


func _inside_cone(origin: Vector2, direction: Vector2, target: Vector2) -> bool:
	var offset := target - origin
	if offset.length() > core.HENRY_SKILL_RANGE or offset.length_squared() <= 0.001:
		return false
	return absf(direction.normalized().angle_to(offset.normalized())) <= core.HENRY_SKILL_HALF_ANGLE


func _target_direction(target_world) -> Vector2:
	var direction: Vector2 = core._ability_aim_direction()
	if target_world is Vector2:
		direction = Vector2(target_world) - core.player_pos
	if direction.length_squared() <= 0.001:
		direction = core.last_facing
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT


func _clear_burn(enemy: Dictionary) -> void:
	for key in ["henry_burn_time", "henry_burn_tick", "henry_burn_damage", "henry_burn_overdrive", "henry_burn_source_peer", "henry_burn_stacks", "henry_burn_stack_flash"]:
		enemy.erase(key)



## --- Dano confirmado (antes em main_runtime_core._apply_henry_burn_from_damage) ---
func on_damage_dealt(target: Dictionary, source: String, source_damage: float, source_peer_id: int, boss_target: bool) -> void:
	if source == "henry_true_fire":
		return
	if source == "henry_spark":
		var normalized_damage := source_damage / SPARK_DAMAGE_MULT
		if boss_target:
			apply_burn_to_boss(normalized_damage, source_peer_id, true)
		else:
			apply_burn_to_enemy(target, normalized_damage, source_peer_id, true)
		return
	if source in ["henry_flame_cone", "henry_guard_burst", "henry_heat_wave", "henry_spin_burst"]:
		if boss_target:
			consume_breach_boss(source_peer_id)
		elif target == core.arauto:
			consume_breach_arauto(source_peer_id)
		else:
			consume_breach_enemy(target, source_peer_id)
		return
	# Combustao com outras Mutacoes: cada 3o golpe confirmado no mesmo alvo acende 1 Queimadura.
	if not combustion_active() or core.mutation_key == "incendiario" or source in NON_TRIGGER_SOURCES:
		return
	if boss_target:
		var boss_hits := int(core.henry_boss_burn_state.get("ignite_hits", 0)) + 1
		core.henry_boss_burn_state["ignite_hits"] = boss_hits % IGNITE_EVERY_HITS
		if boss_hits >= IGNITE_EVERY_HITS:
			apply_burn_to_boss(source_damage, source_peer_id, true)
		return
	if target.is_empty():
		return
	var hits := int(target.get("henry_ignite_hits", 0)) + 1
	target["henry_ignite_hits"] = hits % IGNITE_EVERY_HITS
	if hits >= IGNITE_EVERY_HITS:
		apply_burn_to_enemy(target, source_damage, source_peer_id, true)


## --- Combustao em Cadeia ---
func on_enemy_killed(enemy: Dictionary) -> void:
	if not combustion_active() or not core._is_world_authority():
		return
	var stacks := burn_stacks(enemy)
	if stacks <= 0 or combustion_queue.size() >= COMBUSTION_QUEUE_CAP:
		return
	combustion_queue.append({"pos": Vector2(enemy.get("pos", core.player_pos)), "stacks": stacks, "depth": int(enemy.get("henry_combustion_depth", 0)), "source_peer": int(enemy.get("henry_burn_source_peer", 0))})


static func combustion_radius(stacks: int) -> float:
	return COMBUSTION_BASE_RADIUS + COMBUSTION_RADIUS_PER_STACK * float(clampi(stacks, 1, 5))


func _update_combustion(delta: float) -> void:
	for burst in combustion_bursts:
		burst["life"] = float(burst.get("life", 0.0)) - delta
	combustion_bursts = combustion_bursts.filter(func(burst): return float(burst.get("life", 0.0)) > 0.0)
	var processed := 0
	while not combustion_queue.is_empty() and processed < COMBUSTION_MAX_PER_FRAME:
		var entry: Dictionary = combustion_queue.pop_front()
		_detonate(entry)
		processed += 1


func _detonate(entry: Dictionary) -> void:
	var center: Vector2 = Vector2(entry.get("pos", core.player_pos))
	var stacks: int = clampi(int(entry.get("stacks", 1)), 1, core.HENRY_BURN_STACK_MAX)
	var depth: int = int(entry.get("depth", 0))
	var radius := combustion_radius(stacks)
	var damage: float = float(core.player_damage) * (COMBUSTION_DAMAGE_BASE + COMBUSTION_DAMAGE_PER_STACK * float(stacks))
	var spread: int = maxi(1, stacks - 1) if depth < COMBUSTION_MAX_DEPTH else 0
	var source_peer: int = int(entry.get("source_peer", 0))
	combustion_bursts.append({"pos": center, "radius": radius, "stacks": stacks, "life": COMBUSTION_VISUAL_LIFE, "max": COMBUSTION_VISUAL_LIFE})
	var radius_sq := radius * radius
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		if Vector2(enemy.get("pos", center)).distance_squared_to(center) > radius_sq:
			continue
		enemy["henry_combustion_depth"] = depth + 1
		for _i in range(spread):
			apply_burn_to_enemy(enemy, damage, source_peer, true)
		core._damage_enemy(enemy, damage, "henry_combustion", false, false, center, "status_tick", source_peer, "incendiario")
	if core._arauto_active() and Vector2(core.arauto.get("pos", center)).distance_squared_to(center) <= radius_sq:
		core._damage_arauto(damage, "henry_combustion", false, false, "status_tick", center, source_peer, "incendiario")
	if core.boss_active and core.boss_hp > 0.0 and core.boss_pos.distance_squared_to(center) <= radius_sq:
		if spread > 0:
			apply_burn_to_boss(damage, source_peer, true)
		core._damage_boss(damage, "henry_combustion", false, false, "status_tick", center, source_peer, "incendiario")
	if stacks >= 3:
		core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.08)
		core.screen_shake_strength = maxf(float(core.screen_shake_strength), 3.0 + float(stacks))


## --- Rastro de Brasa ---
func _add_trail_point(pos: Vector2) -> void:
	ember_trail.append({"pos": pos, "life": TRAIL_LIFE, "max": TRAIL_LIFE})
	while ember_trail.size() > TRAIL_MAX_POINTS:
		ember_trail.pop_front()


## Preenche a trilha em passos fixos ate a posicao atual (independe do tamanho do quadro).
func _extend_trail_to(pos: Vector2) -> void:
	if ember_trail.is_empty():
		_add_trail_point(pos)
		return
	var last: Vector2 = Vector2(ember_trail.back()["pos"])
	var distance := last.distance_to(pos)
	var steps := int(floor(distance / TRAIL_SPACING))
	for index in range(steps):
		_add_trail_point(last.lerp(pos, float(index + 1) * TRAIL_SPACING / distance))


func _update_trail(delta: float) -> void:
	if ember_trail.is_empty():
		return
	for point in ember_trail:
		point["life"] = float(point.get("life", 0.0)) - delta
	ember_trail = ember_trail.filter(func(point): return float(point.get("life", 0.0)) > 0.0)
	if not core._is_world_authority():
		return
	trail_tick -= delta
	if trail_tick > 0.0:
		return
	trail_tick = 0.15
	var radius_sq := TRAIL_RADIUS * TRAIL_RADIUS
	var damage: float = float(core.player_damage) * TRAIL_DAMAGE_MULT
	var now: float = float(core.time_alive)
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 or now < float(enemy.get("henry_trail_cd", -1.0)):
			continue
		var pos := Vector2(enemy.get("pos", core.player_pos))
		for point in ember_trail:
			if pos.distance_squared_to(Vector2(point["pos"])) <= radius_sq:
				enemy["henry_trail_cd"] = now + TRAIL_TICK
				apply_burn_to_enemy(enemy, damage / TRAIL_DAMAGE_MULT * SPARK_DAMAGE_MULT, 0, true)
				core._damage_enemy(enemy, damage, "henry_ember_trail", false, false, pos, "skill_shift")
				break
	if core.boss_active and core.boss_hp > 0.0 and now >= float(core.henry_boss_burn_state.get("trail_cd", -1.0)):
		for point in ember_trail:
			if core.boss_pos.distance_to(Vector2(point["pos"])) <= TRAIL_RADIUS + 60.0:
				core.henry_boss_burn_state["trail_cd"] = now + TRAIL_TICK
				apply_burn_to_boss(damage, 0, true)
				core._damage_boss(damage, "henry_ember_trail", false, false, "skill_shift", core.boss_pos)
				break


## --- Bola de fogo do 3o golpe: explode quando some antes do fim da vida (acertou algo) ---
func _update_fireballs() -> void:
	if fireballs.is_empty():
		return
	var alive: Dictionary = {}
	for bullet in core.bullets:
		var id := int(Dictionary(bullet).get("henry_fireball_id", 0))
		if id > 0:
			alive[id] = bullet
	var remaining: Array = []
	for entry in fireballs:
		var id := int(entry["id"])
		if alive.has(id):
			var bullet: Dictionary = alive[id]
			entry["pos"] = Vector2(bullet.get("pos", entry["pos"]))
			entry["life"] = float(bullet.get("life", 0.0))
			remaining.append(entry)
		elif float(entry.get("life", 0.0)) > 0.05:
			_explode_fireball(Vector2(entry["pos"]))
	fireballs = remaining


func _explode_fireball(center: Vector2) -> void:
	combustion_bursts.append({"pos": center, "radius": FIREBALL_RADIUS, "stacks": 1, "life": COMBUSTION_VISUAL_LIFE * 0.8, "max": COMBUSTION_VISUAL_LIFE * 0.8, "fireball": true})
	if not core._is_world_authority():
		return
	var damage: float = float(core.player_damage) * FIREBALL_DAMAGE_MULT
	var radius_sq := FIREBALL_RADIUS * FIREBALL_RADIUS
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) > 0.0 and Vector2(enemy.get("pos", center)).distance_squared_to(center) <= radius_sq:
			apply_burn_to_enemy(enemy, float(core.player_damage), 0, true)
			core._damage_enemy(enemy, damage, "henry_combustion", true, false, center, "basic_attack")
	if core.boss_active and core.boss_hp > 0.0 and core.boss_pos.distance_to(center) <= FIREBALL_RADIUS + 60.0:
		apply_burn_to_boss(float(core.player_damage), 0, true)
		core._damage_boss(damage, "henry_combustion", true, false, "basic_attack", center)



## Quadro do Rastro de Brasa (folha nova quando existir); null = usa o andar normal na direcao.
func dash_texture() -> Texture2D:
	var key: String = "henry_incendiary_dash_" + core._henry_direction_key(core.henry_spin_dash_direction)
	var frames: Array = core.textures.get(key, [])
	if frames.is_empty():
		return null
	var progress := clampf(core.henry_spin_elapsed / maxf(0.01, core.HENRY_SPIN_DURATION), 0.0, 1.0)
	return frames[clampi(int(progress * float(frames.size())), 0, frames.size() - 1)] as Texture2D



## Quadro da Ignicao Total pela linha do tempo (sem repetir a carga em loop).
func ultimate_frame(frame_count: int) -> int:
	var table: Array = ULT_FRAMES_V2 if frame_count >= 10 else ULT_FRAMES_V1
	var elapsed: float = core.henry_ultimate_cast_elapsed
	var frame := 0
	for entry in table:
		if elapsed >= float(entry[0]):
			frame = int(entry[1])
	return clampi(frame, 0, maxi(0, frame_count - 1))


func ultimate_progress() -> float:
	return clampf(core.henry_ultimate_cast_elapsed / ULT_TOTAL, 0.0, 1.0)
