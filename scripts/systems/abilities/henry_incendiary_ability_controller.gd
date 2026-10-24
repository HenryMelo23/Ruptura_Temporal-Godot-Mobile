class_name RTHenryIncendiaryAbilityController
extends "res://scripts/systems/abilities/ability_controller_base.gd"

## Gameplay owner for Henry's first Mutation/Effect pair. Runtime fields stay on
## Main so snapshots and existing combat authority remain compatible.

const SPARK_DAMAGE_MULT := 0.72
const SPARK_SPEED_MULT := 1.12
const SPARK_LIFE := 1.15
const SKILL_NEAR_DAMAGE_MULT := 2.0
const SKILL_FAR_DAMAGE_MULT := 0.82
const ULTIMATE_DAMAGE_MULT := 0.78
const ULTIMATE_PUSH_DISTANCE := 54.0

const ENTRY_WANDER_TIME := 1.2
const ENTRY_BRAKE_TIME := 0.65
var entrance_active := false
var entrance_elapsed := 0.0
var entrance_peers: Array = []
var entrance_spawn_clock := 0.0
var entrance_finished := false
var entrance_phase := 0


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
	core.henry_heat_waves.clear()
	core.henry_boss_burn_state.clear()
	core.henry_friction = 0.0
	core.henry_friction_release_timer = 0.0
	core.henry_incandescence_active_timer = 0.0
	core.henry_incandescence_tick_timer = 0.0
	core.henry_incandescence_intensity = 0.0
	core.henry_incandescence_target_dwell.clear()
	core.henry_incandescence_zones.clear()
	core._reset_henry_idle_animation()
	for enemy in core.enemies:
		_clear_burn(enemy)
		enemy.erase("henry_incandescence_heat")


func on_player_damaged(actual_damage: int) -> void:
	if not is_configured() or core.active_character_key != core.CHARACTER_HENRY or core.effect_key != "incandescencia" or actual_damage <= 0:
		return
	var hp_reference := maxf(1.0, float(core.player_hp_max))
	var friction_gain: float = float(actual_damage) / hp_reference * core.HENRY_FRICTION_MAX
	core.henry_friction = minf(core.HENRY_FRICTION_MAX, core.henry_friction + friction_gain)
	if core.henry_friction_release_timer <= 0.0 and core.henry_incandescence_active_timer <= 0.0:
		core.henry_friction_release_timer = core.HENRY_FRICTION_RELEASE_INTERVAL


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
	core._send_network_ability_visual(
		core.NET_ABILITY_SECONDARY,
		core.henry_ultimate_center,
		core.henry_ultimate_center,
		core.HENRY_ULTIMATE_CAST_DURATION + core.HENRY_ULTIMATE_WAVE_DURATION,
		core.HENRY_ULTIMATE_CAST_DURATION
	)
	return true


func _release_ultimate() -> void:
	var center: Vector2 = core.henry_ultimate_center
	core.henry_heat_waves.append({
		"center": center,
		"radius": 0.0,
		"max_radius": core.HENRY_ULTIMATE_RADIUS,
		"life": core.HENRY_ULTIMATE_WAVE_DURATION,
		"max": core.HENRY_ULTIMATE_WAVE_DURATION,
		"event_id": core.henry_ultimate_event_id,
	})
	_apply_heat_wave(center)
	core.henry_ultimate_cast_active = false
	core.henry_ultimate_cast_elapsed = 0.0
	core.henry_ultimate_center = Vector2.ZERO
	core.henry_ultimate_event_id = ""


func update(delta: float) -> void:
	if not is_configured():
		return
	if core.mutation_key == "incendiario":
		_update_cast(delta)
		_update_ultimate_cast(delta)
	_update_incandescence(delta)
	for cone in core.henry_flame_cones:
		cone["life"] = maxf(0.0, float(cone.get("life", 0.0)) - delta)
	core.henry_flame_cones = core.henry_flame_cones.filter(func(cone): return float(cone.get("life", 0.0)) > 0.0)
	for wave in core.henry_heat_waves:
		wave["life"] = maxf(0.0, float(wave.get("life", 0.0)) - delta)
		var progress := 1.0 - float(wave["life"]) / maxf(0.01, float(wave.get("max", 0.72)))
		wave["radius"] = float(wave.get("max_radius", core.HENRY_ULTIMATE_RADIUS)) * clampf(progress, 0.0, 1.0)
	core.henry_heat_waves = core.henry_heat_waves.filter(func(wave): return float(wave.get("life", 0.0)) > 0.0)
	if not core._is_world_authority():
		return
	for enemy in core.enemies:
		_update_enemy_burn(enemy, delta)
	if not core.arauto.is_empty():
		_update_enemy_burn(core.arauto, delta)
	_update_boss_burn(delta)


func _update_ultimate_cast(delta: float) -> void:
	if not core.henry_ultimate_cast_active:
		return
	core.henry_ultimate_cast_elapsed = minf(core.HENRY_ULTIMATE_CAST_DURATION, core.henry_ultimate_cast_elapsed + delta)
	if core.henry_ultimate_cast_elapsed >= core.HENRY_ULTIMATE_CAST_DURATION:
		_release_ultimate()


func _update_incandescence(delta: float) -> void:
	for enemy in core.enemies:
		if float(enemy.get("henry_incandescence_heat", 0.0)) > 0.0:
			enemy["henry_incandescence_heat"] = maxf(0.0, float(enemy["henry_incandescence_heat"]) - delta)
	if core.active_character_key != core.CHARACTER_HENRY or core.effect_key != "incandescencia" or core.is_dead or core.player_hp <= 0.0:
		core.henry_incandescence_active_timer = 0.0
		core.henry_incandescence_target_dwell.clear()
		core.henry_incandescence_zones.clear()
		return
	for zone in core.henry_incandescence_zones:
		zone["center"] = core.player_pos
		zone["life"] = maxf(0.0, float(zone.get("life", 0.0)) - delta)
	core.henry_incandescence_zones = core.henry_incandescence_zones.filter(func(zone): return float(zone.get("life", 0.0)) > 0.0)
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


func apply_burn_to_enemy(enemy: Dictionary, source_damage: float, source_peer_id: int = 0, overdrive: bool = false) -> void:
	if enemy.is_empty() or float(enemy.get("hp", 0.0)) <= 0.0:
		return
	var was_burning := float(enemy.get("henry_burn_time", 0.0)) > 0.0
	enemy["henry_burn_time"] = core.HENRY_BURN_DURATION
	enemy["henry_burn_tick"] = minf(float(enemy.get("henry_burn_tick", core.HENRY_BURN_TICK_INTERVAL)), core.HENRY_BURN_TICK_INTERVAL)
	enemy["henry_burn_damage"] = maxf(float(enemy.get("henry_burn_damage", 0.0)), maxf(1.0, source_damage * core.HENRY_BURN_DAMAGE_RATIO))
	enemy["henry_burn_source_peer"] = source_peer_id if source_peer_id > 0 else core._mp_unique_id()
	if overdrive and was_burning:
		enemy["henry_burn_overdrive"] = core.HENRY_BURN_OVERDRIVE_DURATION


func apply_burn_to_boss(source_damage: float, source_peer_id: int = 0, overdrive: bool = false) -> void:
	if not core.boss_active or core.boss_hp <= 0.0:
		return
	var was_burning := float(core.henry_boss_burn_state.get("time", 0.0)) > 0.0
	core.henry_boss_burn_state["time"] = core.HENRY_BURN_DURATION
	core.henry_boss_burn_state["tick"] = minf(float(core.henry_boss_burn_state.get("tick", core.HENRY_BURN_TICK_INTERVAL)), core.HENRY_BURN_TICK_INTERVAL)
	core.henry_boss_burn_state["damage"] = maxf(float(core.henry_boss_burn_state.get("damage", 0.0)), maxf(1.0, source_damage * core.HENRY_BURN_DAMAGE_RATIO))
	core.henry_boss_burn_state["source_peer"] = source_peer_id if source_peer_id > 0 else core._mp_unique_id()
	if overdrive and was_burning:
		core.henry_boss_burn_state["overdrive"] = core.HENRY_BURN_OVERDRIVE_DURATION


func _update_cast(delta: float) -> void:
	if not core.henry_skill_cast_active:
		return
	core.henry_skill_cast_elapsed += delta
	if not core.henry_skill_damage_applied and core.henry_skill_cast_elapsed >= core.HENRY_SKILL_IMPACT_TIME:
		core.henry_skill_damage_applied = true
		_apply_flame_cone(core.player_pos, core.henry_skill_cast_direction)
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


func _apply_heat_wave(center: Vector2) -> void:
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var enemy_pos := Vector2(enemy.get("pos", center))
		var distance := center.distance_to(enemy_pos)
		if distance > core.HENRY_ULTIMATE_RADIUS:
			continue
		core._damage_enemy(enemy, core.player_damage * ULTIMATE_DAMAGE_MULT, "henry_heat_wave", true, true, center, "skill_e")
	if core._arauto_active() and center.distance_to(Vector2(core.arauto.get("pos", center))) <= core.HENRY_ULTIMATE_RADIUS:
		core._damage_arauto(core.player_damage * ULTIMATE_DAMAGE_MULT, "henry_heat_wave", true, true, "skill_e", center)
	if core.boss_active and core.boss_hp > 0.0 and center.distance_to(core.boss_pos) <= core.HENRY_ULTIMATE_RADIUS:
		core._damage_boss(core.player_damage * ULTIMATE_DAMAGE_MULT, "henry_heat_wave", true, true, "skill_e", center)


func apply_heat_wave_push(target: Dictionary, center: Vector2) -> void:
	if target.is_empty():
		return
	var target_pos := Vector2(target.get("pos", center))
	var push_dir := (target_pos - center).normalized()
	if push_dir.length_squared() <= 0.001:
		push_dir = Vector2.RIGHT.rotated(float(int(target.get("uid", 0)) % 16) * TAU / 16.0)
	target["pos"] = (target_pos + push_dir * ULTIMATE_PUSH_DISTANCE).clamp(Vector2(40.0, 40.0), core.WORLD_SIZE - Vector2(40.0, 40.0))


func _update_enemy_burn(enemy: Dictionary, delta: float) -> void:
	var remaining := maxf(0.0, float(enemy.get("henry_burn_time", 0.0)) - delta)
	var overdrive := maxf(0.0, float(enemy.get("henry_burn_overdrive", 0.0)) - delta)
	enemy["henry_burn_time"] = remaining
	enemy["henry_burn_overdrive"] = overdrive
	if remaining <= 0.0 or float(enemy.get("hp", 0.0)) <= 0.0:
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
	var direction: Vector2 = core._aim_direction()
	if target_world is Vector2:
		direction = Vector2(target_world) - core.player_pos
	if direction.length_squared() <= 0.001:
		direction = core.last_facing
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT


func _clear_burn(enemy: Dictionary) -> void:
	for key in ["henry_burn_time", "henry_burn_tick", "henry_burn_damage", "henry_burn_overdrive", "henry_burn_source_peer"]:
		enemy.erase(key)
