class_name RTHenryColossusAbilityController
extends "res://scripts/systems/abilities/ability_controller_base.gd"

## Owns Colosso D37 combat state and the independently selectable Lastro
## effect. It never changes Henry's collision shape; the giant form gains reach
## through explicit hit queries so scenery and multiplayer movement stay safe.

const MUTATION_KEY := "colosso"
const EFFECT_KEY := "lastro"

const MELEE_RANGE := 118.0
const GIANT_MELEE_RANGE := 184.0
const GIANT_DURATION := 30.0
const TRANSFORM_DURATION := 1.2
const GIANT_DAMAGE_MULT := 2.0
const GIANT_DAMAGE_REDUCTION := 0.35
const GIANT_MOVE_MULT := 0.92
const GIANT_ATTACK_INTERVAL_MULT := 1.12
const GIANT_TEMP_HP_RATIO := 0.35
const IMPACT_ARMOR_GAIN_RATIO := 0.035
const IMPACT_ARMOR_CAP_RATIO := 0.14
const IMPACT_ARMOR_HOLD_TIME := 2.4
const IMPACT_ARMOR_DECAY_RATIO_PER_SECOND := 0.07
const GIANT_CLEAVE_DAMAGE_RATIO := 0.55
const GIANT_CLEAVE_DEPTH := 135.0
const GIANT_CLEAVE_HALF_WIDTH := 64.0
const GIANT_CLEAVE_MAX_TARGETS := 6

const GUARD_WINDOW := 0.42
const GUARD_DAMAGE_MULT := 0.30
const COUNTER_DAMAGE_MULT := 1.25
const FALLBACK_LUNGE_DISTANCE := 58.0
const CHARGE_DISTANCE := 220.0
const CHARGE_DURATION := 0.44
const CHARGE_DAMAGE_MULT := 1.70

const LASTRO_REQUIRED := 5
const LASTRO_WINDOW := 3.0
const LASTRO_HIT_THROTTLE := 0.12
const LASTRO_ENEMY_ANCHOR := 0.80
const LASTRO_BOSS_SLOW := 0.25
const LASTRO_BOSS_DURATION := 0.80

var combo_stage := 0
var combo_timer := 0.0
var impetus := 0

var guard_active := false
var guard_elapsed := 0.0
var guard_direction := Vector2.RIGHT
var guard_counter_pending := false
var guard_counter_triggered := false

var charge_active := false
var charge_elapsed := 0.0
var charge_origin := Vector2.ZERO
var charge_target := Vector2.ZERO
var charge_direction := Vector2.RIGHT
var charge_hit_uids := {}

var transforming := false
var shrinking := false
var transform_elapsed := 0.0
var giant_active := false
var giant_elapsed := 0.0
var giant_temp_hp := 0.0
var impact_armor := 0.0
var impact_armor_hold := 0.0

var boss_lastro_stacks := 0
var boss_lastro_timer := 0.0
var boss_lastro_slow_timer := 0.0
var arauto_lastro_stacks := 0
var arauto_lastro_timer := 0.0


func configure(runtime_core: Node) -> void:
	super.configure(runtime_core)
	# Warm immutable geometry before combat, never on the first punch.
	preload("res://scripts/presentation/henry_colossus_presentation.gd").warmup()


func reset() -> void:
	combo_stage = 0
	combo_timer = 0.0
	impetus = 0
	guard_active = false
	guard_elapsed = 0.0
	guard_counter_pending = false
	guard_counter_triggered = false
	charge_active = false
	charge_elapsed = 0.0
	charge_hit_uids.clear()
	transforming = false
	shrinking = false
	transform_elapsed = 0.0
	giant_active = false
	giant_elapsed = 0.0
	giant_temp_hp = 0.0
	impact_armor = 0.0
	impact_armor_hold = 0.0
	boss_lastro_stacks = 0
	boss_lastro_timer = 0.0
	boss_lastro_slow_timer = 0.0
	arauto_lastro_stacks = 0
	arauto_lastro_timer = 0.0
	if is_configured():
		for index in range(core.slashes.size() - 1, -1, -1):
			if String(core.slashes[index].get("kind", "")) == "henry_colossus_impact":
				core.slashes.remove_at(index)
		core.henry_skill_cast_active = false
		core.henry_ultimate_cast_active = false


func mutation_active() -> bool:
	return is_configured() and core.active_character_key == core.CHARACTER_HENRY and core.mutation_key == MUTATION_KEY


func lastro_active() -> bool:
	return is_configured() and core.active_character_key == core.CHARACTER_HENRY and core.effect_key == EFFECT_KEY


func lastro_active_for_source(source_peer_id: int) -> bool:
	if not is_configured():
		return false
	if source_peer_id <= 0 or source_peer_id == core._mp_unique_id():
		return lastro_active()
	var state: Dictionary = core.net_players_by_peer.get(source_peer_id, {})
	if int(state.get("manifestation", -1)) != core.HENRY_SELECTION_INDEX:
		return false
	var effect_index := int(state.get("aura", -1))
	return effect_index >= 0 and effect_index < core.HENRY_EFFECTS.size() and String(core.HENRY_EFFECTS[effect_index].get("key", "")) == EFFECT_KEY


func is_giant_visual() -> bool:
	return mutation_active() and (giant_active or transforming or shrinking)


func transform_frame(frame_count: int = 8) -> int:
	var progress := clampf(transform_elapsed / TRANSFORM_DURATION, 0.0, 1.0)
	var frame := clampi(int(floor(progress * float(frame_count))), 0, frame_count - 1)
	return frame_count - 1 - frame if shrinking else frame


func visual_height_multiplier() -> float:
	if not mutation_active():
		return 1.0
	if giant_active:
		return 1.78
	if transforming or shrinking:
		var progress := clampf(transform_elapsed / TRANSFORM_DURATION, 0.0, 1.0)
		if shrinking:
			progress = 1.0 - progress
		return lerpf(1.0, 1.78, smoothstep(0.0, 1.0, progress))
	return 1.0


func move_speed_multiplier() -> float:
	return GIANT_MOVE_MULT if giant_active else 1.0


func attack_interval_multiplier() -> float:
	return GIANT_ATTACK_INTERVAL_MULT if giant_active else 1.0


func boss_move_multiplier() -> float:
	return 1.0 - LASTRO_BOSS_SLOW if boss_lastro_slow_timer > 0.0 else 1.0


func fire_auto_attack() -> bool:
	if not mutation_active() or transforming or shrinking or charge_active:
		return false
	var direction: Vector2 = core._aim_direction()
	if direction.length_squared() <= 0.001:
		direction = core.last_facing
	direction = direction.normalized()
	var melee_range: float = GIANT_MELEE_RANGE if giant_active else MELEE_RANGE
	var target: Dictionary = _nearest_target(direction, melee_range)
	core._set_player_attack_visual_dir(direction)
	core.henry_attack_visual_stage = combo_stage
	core.henry_attack_combo = combo_stage
	var stage_multipliers: Array = [0.72, 0.90, 1.28]
	var damage: float = float(core.player_damage) * float(stage_multipliers[combo_stage]) * (GIANT_DAMAGE_MULT if giant_active else 1.0)
	damage *= 1.0 + float(impetus) * 0.015
	var hit: bool = _damage_target(target, damage, "henry_colossus_melee", "basic_attack", core.player_pos)
	combo_stage = (combo_stage + 1) % 3
	combo_timer = 0.9
	if hit:
		impetus = mini(10, impetus + 1)
		_grant_impact_armor()
		if giant_active:
			_damage_targets_behind(target, direction, damage * GIANT_CLEAVE_DAMAGE_RATIO)
		core._spawn_radial_particles(Vector2(target.get("pos", core.player_pos + direction * melee_range)), Color(0.86, 0.72, 0.48), 5 if giant_active else 3)
	return true


func begin_skill(target_world = null) -> bool:
	if not mutation_active() or transforming or shrinking or guard_active or charge_active:
		return false
	var direction := _target_direction(target_world)
	core._set_player_attack_visual_dir(direction)
	core.henry_skill_cast_direction = direction
	core.henry_skill_cast_elapsed = 0.0
	core.henry_skill_damage_applied = false
	core.henry_skill_cast_active = true
	if giant_active:
		charge_active = true
		charge_elapsed = 0.0
		charge_origin = core.player_pos
		charge_target = (core.player_pos + direction * CHARGE_DISTANCE).clamp(Vector2(32.0, 32.0), core.WORLD_SIZE - Vector2(32.0, 32.0))
		charge_direction = direction
		charge_hit_uids.clear()
		core._send_network_ability_visual(core.NET_ABILITY_SKILL, charge_origin, charge_target, CHARGE_DURATION)
	else:
		guard_active = true
		guard_elapsed = 0.0
		guard_direction = direction
		guard_counter_pending = false
		guard_counter_triggered = false
		core._send_network_ability_visual(core.NET_ABILITY_SKILL, core.player_pos, core.player_pos + direction * FALLBACK_LUNGE_DISTANCE, GUARD_WINDOW)
	return true


func cast_ultimate() -> bool:
	if not mutation_active() or transforming or shrinking or giant_active or charge_active:
		return false
	transforming = true
	transform_elapsed = 0.0
	core.henry_ultimate_cast_active = true
	core.henry_ultimate_cast_elapsed = 0.0
	core.henry_ultimate_center = core.player_pos
	core._send_network_ability_visual(core.NET_ABILITY_SECONDARY, core.player_pos, core.player_pos, TRANSFORM_DURATION + GIANT_DURATION + TRANSFORM_DURATION, TRANSFORM_DURATION)
	return true


func modify_incoming_damage(amount: float, _source: String) -> float:
	if not mutation_active() or amount <= 0.0:
		return amount
	var result := amount
	if guard_active:
		if not guard_counter_pending:
			_emit_impact(core.player_pos + guard_direction * 35.0, guard_direction, 25.0)
		result *= GUARD_DAMAGE_MULT
		guard_counter_pending = true
		guard_counter_triggered = true
	if giant_active:
		result *= 1.0 - GIANT_DAMAGE_REDUCTION
	if impact_armor > 0.0:
		var impact_absorbed := minf(impact_armor, result)
		impact_armor -= impact_absorbed
		result -= impact_absorbed
		if impact_absorbed > 0.0:
			_emit_impact(core.player_pos, -core.last_facing, 23.0)
	if giant_active:
		if giant_temp_hp > 0.0:
			var absorbed := minf(giant_temp_hp, result)
			giant_temp_hp -= absorbed
			result -= absorbed
			if absorbed > 0.0:
				core._add_text("D37 %d" % int(round(absorbed)), core.player_pos + Vector2(0, -92), Color(0.78, 0.9, 0.62), 0.42, 15)
	return maxf(0.0, result)


func on_damage_confirmed_enemy(enemy: Dictionary, actual_damage: float, source_peer_id: int) -> void:
	if actual_damage <= 0.0 or not lastro_active_for_source(source_peer_id):
		return
	var now := float(core.time_alive)
	if now - float(enemy.get("henry_lastro_last_hit", -999.0)) < LASTRO_HIT_THROTTLE:
		return
	enemy["henry_lastro_last_hit"] = now
	enemy["henry_lastro_timer"] = LASTRO_WINDOW
	enemy["henry_lastro_stacks"] = int(enemy.get("henry_lastro_stacks", 0)) + 1
	if int(enemy["henry_lastro_stacks"]) >= LASTRO_REQUIRED:
		enemy["henry_lastro_stacks"] = 0
		enemy["henry_lastro_timer"] = 0.0
		enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), LASTRO_ENEMY_ANCHOR)
		enemy["henry_lastro_anchor"] = LASTRO_ENEMY_ANCHOR
		core._add_text("LASTRO", Vector2(enemy.get("pos", core.player_pos)) + Vector2(0, -54), Color(0.72, 0.9, 0.66), 0.62, 16)


func on_damage_confirmed_boss(actual_damage: float, source_peer_id: int) -> void:
	if actual_damage <= 0.0 or not lastro_active_for_source(source_peer_id):
		return
	boss_lastro_stacks += 1
	boss_lastro_timer = LASTRO_WINDOW
	if boss_lastro_stacks >= LASTRO_REQUIRED:
		boss_lastro_stacks = 0
		boss_lastro_timer = 0.0
		boss_lastro_slow_timer = LASTRO_BOSS_DURATION
		core._add_text("LASTRO", core.boss_pos + Vector2(0, -104), Color(0.72, 0.9, 0.66), 0.62, 16)


func on_damage_confirmed_arauto(actual_damage: float, source_peer_id: int) -> void:
	if actual_damage <= 0.0 or not lastro_active_for_source(source_peer_id):
		return
	arauto_lastro_stacks += 1
	arauto_lastro_timer = LASTRO_WINDOW
	if arauto_lastro_stacks >= LASTRO_REQUIRED:
		arauto_lastro_stacks = 0
		arauto_lastro_timer = 0.0
		core.arauto["stun"] = maxf(float(core.arauto.get("stun", 0.0)), LASTRO_BOSS_DURATION * 0.5)
		core._add_text("LASTRO", Vector2(core.arauto.get("pos", core.player_pos)) + Vector2(0, -86), Color(0.72, 0.9, 0.66), 0.62, 16)


func update(delta: float) -> void:
	if not is_configured():
		return
	_update_lastro_timers(delta)
	if not mutation_active():
		if transforming or shrinking or giant_active or guard_active or charge_active:
			reset()
		return
	combo_timer = maxf(0.0, combo_timer - delta)
	_update_impact_armor(delta)
	if combo_timer <= 0.0:
		combo_stage = 0
		impetus = 0
	_update_guard(delta)
	_update_charge(delta)
	_update_transformation(delta)


func visual_snapshot() -> Dictionary:
	return {
		"transforming": transforming,
		"shrinking": shrinking,
		"transform_elapsed": transform_elapsed,
		"transform_duration": TRANSFORM_DURATION,
		"giant_active": giant_active,
		"giant_elapsed": giant_elapsed,
		"giant_duration": GIANT_DURATION,
		"guard_active": guard_active,
		"guard_elapsed": guard_elapsed,
		"charge_active": charge_active,
		"charge_elapsed": charge_elapsed,
		"charge_origin": charge_origin,
		"charge_target": charge_target,
		"impetus": impetus,
		"temp_hp": giant_temp_hp,
		"impact_armor": impact_armor,
		"impact_armor_cap": _impact_armor_cap(),
	}


func _update_guard(delta: float) -> void:
	if not guard_active:
		return
	guard_elapsed += delta
	core.henry_skill_cast_elapsed = guard_elapsed
	if guard_counter_pending:
		guard_counter_pending = false
		_apply_short_lunge(COUNTER_DAMAGE_MULT, 76.0, "henry_colossus_counter")
		guard_active = false
		core.henry_skill_cast_active = false
		return
	if guard_elapsed >= GUARD_WINDOW:
		_apply_short_lunge(0.72, FALLBACK_LUNGE_DISTANCE, "henry_colossus_fallback")
		guard_active = false
		core.henry_skill_cast_active = false


func _update_charge(delta: float) -> void:
	if not charge_active:
		return
	charge_elapsed += delta
	core.henry_skill_cast_elapsed = charge_elapsed
	var progress := clampf(charge_elapsed / CHARGE_DURATION, 0.0, 1.0)
	var desired := charge_origin.lerp(charge_target, smoothstep(0.0, 1.0, progress))
	core.player_pos = core._resolve_phase2_fire_wall_movement(core.player_pos, desired)
	_damage_charge_targets()
	if charge_elapsed >= CHARGE_DURATION:
		charge_active = false
		core.henry_skill_cast_active = false


func _update_transformation(delta: float) -> void:
	if transforming or shrinking:
		transform_elapsed += delta
		core.henry_ultimate_cast_elapsed = transform_elapsed
		core.henry_ultimate_center = core.player_pos
		if transform_elapsed >= TRANSFORM_DURATION:
			if transforming:
				transforming = false
				giant_active = true
				giant_elapsed = 0.0
				giant_temp_hp = maxf(1.0, core.player_hp_max * GIANT_TEMP_HP_RATIO)
				core._add_text("HIPERTROFIA ABSOLUTA", core.player_pos + Vector2(-94, -120), Color(0.86, 0.82, 0.58), 1.0, 20)
			else:
				shrinking = false
				giant_active = false
				giant_temp_hp = 0.0
			transform_elapsed = 0.0
			core.henry_ultimate_cast_active = false
	if giant_active:
		giant_elapsed += delta
		if giant_elapsed >= GIANT_DURATION:
			giant_active = false
			shrinking = true
			transform_elapsed = 0.0
			core.henry_ultimate_cast_active = true
			core.henry_ultimate_cast_elapsed = 0.0


func _update_lastro_timers(delta: float) -> void:
	for enemy in core.enemies:
		if enemy.has("henry_lastro_timer"):
			enemy["henry_lastro_timer"] = maxf(0.0, float(enemy.get("henry_lastro_timer", 0.0)) - delta)
			if float(enemy["henry_lastro_timer"]) <= 0.0:
				enemy["henry_lastro_stacks"] = 0
		if enemy.has("henry_lastro_anchor"):
			enemy["henry_lastro_anchor"] = maxf(0.0, float(enemy.get("henry_lastro_anchor", 0.0)) - delta)
	boss_lastro_timer = maxf(0.0, boss_lastro_timer - delta)
	boss_lastro_slow_timer = maxf(0.0, boss_lastro_slow_timer - delta)
	arauto_lastro_timer = maxf(0.0, arauto_lastro_timer - delta)
	if boss_lastro_timer <= 0.0:
		boss_lastro_stacks = 0
	if arauto_lastro_timer <= 0.0:
		arauto_lastro_stacks = 0


func _apply_short_lunge(damage_mult: float, distance: float, source: String) -> void:
	var destination: Vector2 = (Vector2(core.player_pos) + guard_direction * distance).clamp(Vector2(32.0, 32.0), Vector2(core.WORLD_SIZE) - Vector2(32.0, 32.0))
	core.player_pos = core._resolve_phase2_fire_wall_movement(core.player_pos, destination)
	var target: Dictionary = _nearest_target(guard_direction, 96.0)
	_damage_target(target, core.player_damage * damage_mult, source, "skill_q", core.player_pos)
	core._spawn_radial_particles(core.player_pos + guard_direction * 28.0, Color(0.9, 0.82, 0.62), 6)


func _damage_charge_targets() -> void:
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var uid := int(enemy.get("uid", 0))
		if charge_hit_uids.has(uid) or core.player_pos.distance_to(Vector2(enemy.get("pos", core.player_pos))) > 74.0:
			continue
		charge_hit_uids[uid] = true
		core._damage_enemy(enemy, core.player_damage * CHARGE_DAMAGE_MULT * GIANT_DAMAGE_MULT, "henry_colossus_charge", true, true, core.player_pos, "skill_q")
		_emit_impact(Vector2(enemy.get("pos", core.player_pos)), charge_direction, 39.0)
	if core.boss_active and core.boss_hp > 0.0 and not charge_hit_uids.has(-1) and core.player_pos.distance_to(core.boss_pos) <= 104.0:
		charge_hit_uids[-1] = true
		core._damage_boss(core.player_damage * CHARGE_DAMAGE_MULT * GIANT_DAMAGE_MULT, "henry_colossus_charge", true, true, "skill_q", core.player_pos)
		_emit_impact(core.boss_pos, charge_direction, 45.0)
	if core._arauto_active() and not charge_hit_uids.has(-2) and core.player_pos.distance_to(Vector2(core.arauto.get("pos", core.player_pos))) <= 92.0:
		charge_hit_uids[-2] = true
		core._damage_arauto(core.player_damage * CHARGE_DAMAGE_MULT * GIANT_DAMAGE_MULT, "henry_colossus_charge", true, true, "skill_q", core.player_pos)
		_emit_impact(Vector2(core.arauto.get("pos", core.player_pos)), charge_direction, 39.0)


func _nearest_target(direction: Vector2, query_range: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = query_range
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var offset: Vector2 = Vector2(enemy.get("pos", core.player_pos)) - Vector2(core.player_pos)
		var target_distance: float = offset.length()
		if target_distance <= best_distance and (target_distance <= 42.0 or direction.dot(offset.normalized()) >= 0.30):
			best = {"kind": "enemy", "enemy": enemy, "pos": enemy.get("pos", core.player_pos)}
			best_distance = target_distance
	if core._arauto_active():
		var arauto_pos: Vector2 = Vector2(core.arauto.get("pos", core.player_pos))
		var arauto_offset: Vector2 = arauto_pos - Vector2(core.player_pos)
		if arauto_offset.length() <= best_distance and (arauto_offset.length() <= 54.0 or direction.dot(arauto_offset.normalized()) >= 0.25):
			best = {"kind": "arauto", "pos": arauto_pos}
			best_distance = arauto_offset.length()
	if core.boss_active and core.boss_hp > 0.0:
		var boss_offset: Vector2 = Vector2(core.boss_pos) - Vector2(core.player_pos)
		if boss_offset.length() <= best_distance + 24.0 and (boss_offset.length() <= 68.0 or direction.dot(boss_offset.normalized()) >= 0.20):
			best = {"kind": "boss", "pos": core.boss_pos}
	return best


func _damage_target(target: Dictionary, damage: float, source: String, category: String, origin: Vector2) -> bool:
	if target.is_empty():
		return false
	match String(target.get("kind", "")):
		"enemy":
			core._damage_enemy(target["enemy"], damage, source, true, true, origin, category)
		"boss":
			core._damage_boss(damage, source, true, true, category, origin)
		"arauto":
			core._damage_arauto(damage, source, true, true, category, origin)
		_:
			return false
	var impact_pos := Vector2(target.get("pos", core.player_pos))
	_emit_impact(impact_pos, (impact_pos - origin).normalized(), 39.0 if giant_active else 26.0)
	return true


func _grant_impact_armor() -> void:
	var cap := _impact_armor_cap()
	var before := impact_armor
	impact_armor = minf(cap, impact_armor + maxf(1.0, float(core.player_hp_max) * IMPACT_ARMOR_GAIN_RATIO))
	impact_armor_hold = IMPACT_ARMOR_HOLD_TIME
	if before <= 0.0 and impact_armor > 0.0:
		core._spawn_radial_particles(core.player_pos, Color(0.74, 0.62, 0.4), 3)


func _impact_armor_cap() -> float:
	return maxf(1.0, float(core.player_hp_max) * IMPACT_ARMOR_CAP_RATIO) if is_configured() else 1.0


func _update_impact_armor(delta: float) -> void:
	if impact_armor <= 0.0:
		impact_armor = 0.0
		impact_armor_hold = 0.0
		return
	impact_armor_hold = maxf(0.0, impact_armor_hold - delta)
	if impact_armor_hold <= 0.0:
		impact_armor = maxf(0.0, impact_armor - float(core.player_hp_max) * IMPACT_ARMOR_DECAY_RATIO_PER_SECOND * delta)


func _damage_targets_behind(primary: Dictionary, direction: Vector2, cleave_damage: float) -> void:
	if primary.is_empty() or direction.length_squared() <= 0.001:
		return
	var impact_pos := Vector2(primary.get("pos", core.player_pos))
	var forward := direction.normalized()
	var hit_count := 0
	var primary_enemy: Dictionary = primary.get("enemy", {})
	for enemy in core.enemies:
		if hit_count >= GIANT_CLEAVE_MAX_TARGETS:
			break
		if enemy == primary_enemy or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var target_pos := Vector2(enemy.get("pos", impact_pos))
		if not _inside_cleave_corridor(target_pos, impact_pos, forward):
			continue
		core._damage_enemy(enemy, cleave_damage, "henry_colossus_cleave", true, true, impact_pos, "basic_attack")
		_emit_impact(target_pos, forward, 31.0)
		hit_count += 1
	if hit_count < GIANT_CLEAVE_MAX_TARGETS and String(primary.get("kind", "")) != "arauto" and core._arauto_active():
		var arauto_pos := Vector2(core.arauto.get("pos", impact_pos))
		if _inside_cleave_corridor(arauto_pos, impact_pos, forward):
			core._damage_arauto(cleave_damage, "henry_colossus_cleave", true, true, "basic_attack", impact_pos)
			_emit_impact(arauto_pos, forward, 34.0)
			hit_count += 1
	if hit_count < GIANT_CLEAVE_MAX_TARGETS and String(primary.get("kind", "")) != "boss" and core.boss_active and core.boss_hp > 0.0:
		if _inside_cleave_corridor(core.boss_pos, impact_pos, forward):
			core._damage_boss(cleave_damage, "henry_colossus_cleave", true, true, "basic_attack", impact_pos)
			_emit_impact(core.boss_pos, forward, 38.0)


func _inside_cleave_corridor(target_pos: Vector2, impact_pos: Vector2, direction: Vector2) -> bool:
	var offset := target_pos - impact_pos
	var forward_distance := offset.dot(direction)
	if forward_distance < 8.0 or forward_distance > GIANT_CLEAVE_DEPTH:
		return false
	return absf(offset.dot(direction.orthogonal())) <= GIANT_CLEAVE_HALF_WIDTH


func _emit_impact(position: Vector2, direction: Vector2, size: float) -> void:
	# One short-lived cosmetic event per contact, using the existing expiry,
	# culling and reset collection. This event never performs hit queries.
	var cap := 12 if core._runtime_visual_budget_active() else 32
	if core.slashes.size() >= cap:
		return
	core.slashes.append({"kind": "henry_colossus_impact", "pos": position,
		"dir": direction, "size": size, "life": 0.3, "max": 0.3})


func _target_direction(target_world) -> Vector2:
	var direction: Vector2 = core._aim_direction()
	if target_world is Vector2:
		direction = Vector2(target_world) - core.player_pos
	if direction.length_squared() <= 0.001:
		direction = core.last_facing
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
