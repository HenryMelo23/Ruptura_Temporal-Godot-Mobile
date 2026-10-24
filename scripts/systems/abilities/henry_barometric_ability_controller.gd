class_name RTHenryBarometricAbilityController
extends "res://scripts/systems/abilities/ability_controller_base.gd"

## Owns Henry's Barometric Mutation and the independently selectable Nimbo
## Effect.  The owner stores only transient combat state; selection/save data
## remains on Main beside the other character choices.

const MUTATION_KEY := "barometrico"
const EFFECT_KEY := "nimbo"

const BLADE_DAMAGE_MULT := 0.68
const BLADE_THIRD_DAMAGE_MULT := 0.86
const BLADE_SPEED_MULT := 1.32
const BLADE_LIFE := 1.18
const BLADE_MAX_HITS := 2
const BLADE_RETARGET_RADIUS := 260.0

const CORRIDOR_WINDUP := 0.38
const CORRIDOR_DURATION := 3.2
const CORRIDOR_LENGTH := 390.0
const CORRIDOR_HALF_WIDTH := 92.0
const CORRIDOR_TICK := 0.24
const CORRIDOR_DAMAGE_MULT := 0.12
const CORRIDOR_BOSS_DAMAGE_MULT := 0.055
const CORRIDOR_PULL_SPEED := 118.0
const CORRIDOR_PUSH_SPEED := 82.0

const STORM_WINDUP := 0.55
const STORM_DURATION := 6.5
const STORM_RADIUS := 285.0
const STORM_TICK := 0.42
const STORM_DAMAGE_MULT := 0.18
const STORM_BOSS_DAMAGE_MULT := 0.075
const STORM_ORBIT_SPEED := 88.0
const STORM_PULL_SPEED := 54.0

const NIMBO_RADIUS := 48.0
const NIMBO_DAMAGE_MULT := 0.42
const NIMBO_SPEED_MULT := 1.18
const NIMBO_LIFE := 1.2

var attack_combo := 0
var corridor_active := false
var corridor_elapsed := 0.0
var corridor_direction := Vector2.RIGHT
var corridor_tick_timer := 0.0
var corridor_event_id := ""

var storm_windup_active := false
var storm_active := false
var storm_elapsed := 0.0
var storm_tick_timer := 0.0
var storm_event_id := ""

var nimbo_attack_count := 0
var nimbo_phase := 0.0
var nimbo_flash := 0.0


func reset() -> void:
	attack_combo = 0
	corridor_active = false
	corridor_elapsed = 0.0
	corridor_direction = Vector2.RIGHT
	corridor_tick_timer = 0.0
	corridor_event_id = ""
	storm_windup_active = false
	storm_active = false
	storm_elapsed = 0.0
	storm_tick_timer = 0.0
	storm_event_id = ""
	nimbo_attack_count = 0
	nimbo_phase = 0.0
	nimbo_flash = 0.0


func mutation_active() -> bool:
	return is_configured() and core.active_character_key == core.CHARACTER_HENRY and core.mutation_key == MUTATION_KEY


func nimbo_active() -> bool:
	return is_configured() and core.active_character_key == core.CHARACTER_HENRY and core.effect_key == EFFECT_KEY


func fire_auto_attack() -> bool:
	if not mutation_active():
		return false
	var stage := attack_combo
	attack_combo = (attack_combo + 1) % 3
	core.henry_attack_visual_stage = stage
	core.henry_attack_combo = attack_combo
	var before: int = core.bullets.size()
	var damage_mult := BLADE_THIRD_DAMAGE_MULT if stage == 2 else BLADE_DAMAGE_MULT
	core._fire_projectile("henry_pressure", core.player_damage * damage_mult, core.BULLET_SPEED * BLADE_SPEED_MULT, BLADE_LIFE, true)
	if core.bullets.size() <= before:
		return false
	var bullet: Dictionary = core.bullets[-1]
	bullet["barometric_hits"] = 0
	bullet["barometric_third"] = stage == 2
	bullet["henry_combo_stage"] = stage
	bullet["source_character"] = core.CHARACTER_HENRY
	if stage == 2:
		bullet["visual_scale"] = maxf(float(bullet.get("visual_scale", 1.0)), 1.34)
	return true


func on_henry_auto_fired() -> void:
	if not nimbo_active():
		return
	nimbo_attack_count += 1
	if nimbo_attack_count < 3:
		return
	nimbo_attack_count = 0
	_fire_nimbo_copy()


func begin_skill(target_world = null) -> bool:
	if not mutation_active() or corridor_active or core._local_player_controls_locked():
		return false
	corridor_direction = _target_direction(target_world)
	corridor_active = true
	corridor_elapsed = 0.0
	corridor_tick_timer = 0.0
	corridor_event_id = core._next_network_event_id("henry_corridor")
	core.henry_skill_cast_active = true
	core.henry_skill_cast_elapsed = 0.0
	core.henry_skill_cast_direction = corridor_direction
	core.henry_skill_damage_applied = false
	core._set_player_attack_visual_dir(corridor_direction)
	core._send_network_ability_visual(core.NET_ABILITY_SKILL, core.player_pos, core.player_pos + corridor_direction * CORRIDOR_LENGTH, CORRIDOR_DURATION)
	return true


func cast_ultimate() -> bool:
	if not mutation_active() or storm_windup_active or storm_active or core._local_player_controls_locked():
		return false
	storm_windup_active = true
	storm_active = false
	storm_elapsed = 0.0
	storm_tick_timer = 0.0
	storm_event_id = core._next_network_event_id("henry_storm")
	core.henry_ultimate_cast_active = true
	core.henry_ultimate_cast_elapsed = 0.0
	core.henry_ultimate_center = core.player_pos
	core.henry_ultimate_event_id = storm_event_id
	core._send_network_ability_visual(core.NET_ABILITY_SECONDARY, core.player_pos, core.player_pos, STORM_WINDUP + STORM_DURATION, STORM_WINDUP)
	return true


func update(delta: float) -> void:
	if not is_configured():
		return
	nimbo_phase = fposmod(nimbo_phase + delta * (1.9 if storm_active else 1.25), TAU)
	nimbo_flash = maxf(0.0, nimbo_flash - delta)
	if not mutation_active():
		if corridor_active or storm_windup_active or storm_active:
			_cancel_mutation_state()
		return
	_update_corridor(delta)
	_update_storm(delta)


func update_projectile(bullet: Dictionary, delta: float) -> void:
	if String(bullet.get("kind", "")) not in ["henry_pressure", "henry_nimbo_pressure"]:
		return
	var direction := Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	if int(bullet.get("barometric_hits", 0)) > 0 and bullet.has("barometric_curve_target"):
		var desired := (Vector2(bullet["barometric_curve_target"]) - Vector2(bullet.get("pos", core.player_pos))).normalized()
		if desired.length() > 0.01:
			direction = direction.lerp(desired, clampf(delta * 8.5, 0.0, 1.0)).normalized()
	bullet["dir"] = direction


func on_projectile_hit(bullet: Dictionary, hit_position: Vector2, hit_key: String) -> void:
	if String(bullet.get("kind", "")) not in ["henry_pressure", "henry_nimbo_pressure"]:
		return
	var hit_count := int(bullet.get("barometric_hits", 0)) + 1
	bullet["barometric_hits"] = hit_count
	if hit_count >= BLADE_MAX_HITS:
		bullet["life"] = 0.0
		return
	var next_target := _nearest_target_position(hit_position, Dictionary(bullet.get("hits", {})), hit_key, BLADE_RETARGET_RADIUS)
	if next_target == Vector2.INF:
		bullet["life"] = 0.0
		return
	bullet["barometric_curve_target"] = next_target
	var desired := (next_target - hit_position).normalized()
	if desired.length() > 0.01:
		bullet["dir"] = desired


func nimbo_position() -> Vector2:
	if not nimbo_active():
		return core.player_pos if is_configured() else Vector2.ZERO
	if corridor_active:
		return core.player_pos + corridor_direction * minf(CORRIDOR_LENGTH * 0.62, 170.0) + corridor_direction.orthogonal() * sin(nimbo_phase * 1.7) * 22.0
	var radius := STORM_RADIUS - 18.0 if storm_active else NIMBO_RADIUS
	return core.player_pos + Vector2.from_angle(nimbo_phase - 0.7) * radius


func visual_snapshot() -> Dictionary:
	return {
		"corridor_active": corridor_active,
		"corridor_elapsed": corridor_elapsed,
		"corridor_duration": CORRIDOR_DURATION,
		"corridor_direction": corridor_direction,
		"corridor_length": CORRIDOR_LENGTH,
		"corridor_half_width": CORRIDOR_HALF_WIDTH,
		"storm_windup_active": storm_windup_active,
		"storm_active": storm_active,
		"storm_elapsed": storm_elapsed,
		"storm_windup": STORM_WINDUP,
		"storm_duration": STORM_DURATION,
		"storm_radius": STORM_RADIUS,
		"nimbo_active": nimbo_active(),
		"nimbo_phase": nimbo_phase,
		"nimbo_flash": nimbo_flash,
		"nimbo_position": nimbo_position(),
	}


func _update_corridor(delta: float) -> void:
	if not corridor_active:
		return
	corridor_elapsed += delta
	core.henry_skill_cast_elapsed = minf(CORRIDOR_WINDUP, corridor_elapsed)
	if corridor_elapsed >= CORRIDOR_WINDUP:
		core.henry_skill_cast_active = false
		corridor_tick_timer -= delta
		_accelerate_corridor_projectiles()
		_deflect_enemy_projectiles(corridor_direction, false)
		if corridor_tick_timer <= 0.0:
			corridor_tick_timer += CORRIDOR_TICK
			_apply_corridor_tick()
	if corridor_elapsed >= CORRIDOR_DURATION:
		corridor_active = false
		core.henry_skill_cast_active = false
		core.henry_skill_cast_elapsed = 0.0


func _update_storm(delta: float) -> void:
	if storm_windup_active:
		storm_elapsed += delta
		core.henry_ultimate_cast_elapsed = minf(STORM_WINDUP, storm_elapsed)
		core.henry_ultimate_center = core.player_pos
		if storm_elapsed >= STORM_WINDUP:
			storm_windup_active = false
			storm_active = true
			storm_elapsed = 0.0
			core.henry_ultimate_cast_active = false
			core.henry_ultimate_cast_elapsed = 0.0
	if not storm_active:
		return
	storm_elapsed += delta
	core.henry_ultimate_center = core.player_pos
	storm_tick_timer -= delta
	_deflect_enemy_projectiles(Vector2.RIGHT, true)
	if storm_tick_timer <= 0.0:
		storm_tick_timer += STORM_TICK
		_apply_storm_tick()
	if storm_elapsed >= STORM_DURATION:
		storm_active = false
		storm_elapsed = 0.0
		storm_event_id = ""
		core.henry_ultimate_event_id = ""


func _apply_corridor_tick() -> void:
	var origin: Vector2 = core.player_pos
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var pos := Vector2(enemy.get("pos", origin))
		if not _inside_corridor(pos, origin):
			continue
		var along := clampf((pos - origin).dot(corridor_direction), 0.0, CORRIDOR_LENGTH)
		var axis_pos := origin + corridor_direction * along
		var pull := (axis_pos - pos).limit_length(CORRIDOR_PULL_SPEED * CORRIDOR_TICK)
		enemy["pos"] = (pos + pull + corridor_direction * CORRIDOR_PUSH_SPEED * CORRIDOR_TICK).clamp(Vector2(32.0, 32.0), core.WORLD_SIZE - Vector2(32.0, 32.0))
		core._damage_enemy(enemy, core.player_damage * CORRIDOR_DAMAGE_MULT, "henry_pressure_corridor", false, false, origin, "skill_q")
	if core.boss_active and core.boss_hp > 0.0 and _inside_corridor(core.boss_pos, origin):
		core._damage_boss(core.player_damage * CORRIDOR_BOSS_DAMAGE_MULT, "henry_pressure_corridor", false, false, "skill_q", origin)
	if core._arauto_active() and _inside_corridor(Vector2(core.arauto.get("pos", origin)), origin):
		core._damage_arauto(core.player_damage * CORRIDOR_BOSS_DAMAGE_MULT, "henry_pressure_corridor", false, false, "skill_q", origin)


func _apply_storm_tick() -> void:
	var center: Vector2 = core.player_pos
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var pos := Vector2(enemy.get("pos", center))
		var offset := pos - center
		var distance := offset.length()
		if distance > STORM_RADIUS or distance <= 0.01:
			continue
		var radial := offset / distance
		var tangential := radial.orthogonal()
		var displacement := tangential * STORM_ORBIT_SPEED * STORM_TICK + (-radial) * STORM_PULL_SPEED * STORM_TICK * (distance / STORM_RADIUS)
		enemy["pos"] = (pos + displacement).clamp(Vector2(32.0, 32.0), core.WORLD_SIZE - Vector2(32.0, 32.0))
		core._damage_enemy(enemy, core.player_damage * STORM_DAMAGE_MULT, "henry_eye_storm", false, false, center, "skill_e")
	if core.boss_active and core.boss_hp > 0.0 and center.distance_to(core.boss_pos) <= STORM_RADIUS:
		core._damage_boss(core.player_damage * STORM_BOSS_DAMAGE_MULT, "henry_eye_storm", false, false, "skill_e", center)
	if core._arauto_active() and center.distance_to(Vector2(core.arauto.get("pos", center))) <= STORM_RADIUS:
		core._damage_arauto(core.player_damage * STORM_BOSS_DAMAGE_MULT, "henry_eye_storm", false, false, "skill_e", center)


func _accelerate_corridor_projectiles() -> void:
	for bullet in core.bullets:
		if String(bullet.get("kind", "")) not in ["henry_pressure", "henry_nimbo_pressure"] or bool(bullet.get("barometric_corridor_boosted", false)):
			continue
		if _inside_corridor(Vector2(bullet.get("pos", core.player_pos)), core.player_pos):
			bullet["speed"] = float(bullet.get("speed", core.BULLET_SPEED)) * 1.18
			bullet["barometric_corridor_boosted"] = true


func _deflect_enemy_projectiles(direction: Vector2, radial: bool) -> void:
	var center: Vector2 = core.player_pos
	for bullet in core.enemy_bullets:
		var pos := Vector2(bullet.get("pos", center))
		if radial:
			if center.distance_to(pos) > STORM_RADIUS:
				continue
			var out := (pos - center).normalized()
			if out.length() <= 0.01:
				out = Vector2.RIGHT
			bullet["dir"] = Vector2(bullet.get("dir", out)).normalized().lerp(out.orthogonal(), 0.2).normalized()
		elif _inside_corridor(pos, center):
			var side := direction.orthogonal()
			if (pos - center).dot(side) < 0.0:
				side = -side
			var diverted := (direction + side * 0.8).normalized()
			bullet["dir"] = Vector2(bullet.get("dir", direction)).normalized().lerp(diverted, 0.42).normalized()


func _inside_corridor(position: Vector2, origin: Vector2) -> bool:
	var offset := position - origin
	var along := offset.dot(corridor_direction)
	return along >= -18.0 and along <= CORRIDOR_LENGTH and absf(offset.dot(corridor_direction.orthogonal())) <= CORRIDOR_HALF_WIDTH


func _fire_nimbo_copy() -> void:
	var origin := nimbo_position()
	var target := _nearest_target_position(origin, {}, "", 780.0)
	var direction: Vector2 = core._aim_direction()
	if target != Vector2.INF:
		direction = (target - origin).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	var palette: Dictionary = core._projectile_palette("henry_nimbo_pressure")
	core._add_bullet({
		"pos": origin,
		"origin": origin,
		"source_category": "henry_effect_nimbo",
		"dir": direction,
		"life": NIMBO_LIFE,
		"max_life": NIMBO_LIFE,
		"age": 0.0,
		"phase": nimbo_phase,
		"trail_cd": 0.0,
		"damage": core.player_damage * NIMBO_DAMAGE_MULT,
		"player_damage": core.player_damage,
		"speed": core.BULLET_SPEED * NIMBO_SPEED_MULT,
		"kind": "henry_nimbo_pressure",
		"pierce": true,
		"hits": {},
		"barometric_hits": 0,
		"nimbo_shot": true,
		"ricochets": 0,
		"durability": 0.0,
		"fly_sfx_cd": 0.0,
		"color": palette.get("glow", Color(0.5, 0.94, 1.0)),
		"visual_scale": 0.82,
	})
	core._spawn_projectile_muzzle("henry_nimbo_pressure", origin, direction)
	nimbo_flash = 0.28


func _nearest_target_position(origin: Vector2, ignored_hits: Dictionary, ignored_key: String, radius: float) -> Vector2:
	var best := Vector2.INF
	var best_distance := radius
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var key := str(enemy.get("uid", ""))
		if key == ignored_key or ignored_hits.has(key):
			continue
		var pos := Vector2(enemy.get("pos", origin))
		var distance := origin.distance_to(pos)
		if distance < best_distance:
			best = pos
			best_distance = distance
	if core._arauto_active() and ignored_key != "arauto" and not ignored_hits.has("arauto"):
		var arauto_pos := Vector2(core.arauto.get("pos", origin))
		var arauto_distance := origin.distance_to(arauto_pos)
		if arauto_distance < best_distance:
			best = arauto_pos
			best_distance = arauto_distance
	if core.boss_active and core.boss_hp > 0.0 and ignored_key != "boss" and not ignored_hits.has("boss"):
		var boss_distance := origin.distance_to(core.boss_pos)
		if boss_distance < best_distance:
			best = core.boss_pos
	return best


func _target_direction(target_world) -> Vector2:
	var direction: Vector2 = core._aim_direction()
	if target_world is Vector2:
		direction = Vector2(target_world) - core.player_pos
	if direction.length_squared() <= 0.001:
		direction = core.last_facing
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT


func _cancel_mutation_state() -> void:
	corridor_active = false
	storm_windup_active = false
	storm_active = false
	core.henry_skill_cast_active = false
	core.henry_ultimate_cast_active = false
