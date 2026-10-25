class_name RTAncoradaAbilityController
extends "res://scripts/systems/abilities/ability_controller_base.gd"

const AncoradaEvolutionController = preload("res://scripts/systems/manifest_evolutions/ancorada_evolution_controller.gd")

## Gameplay owner for Ancorada's mobile-territory kit.
## Runtime fields remain on Main for save/network compatibility; this owner
## centralizes the rules so the manifestation no longer rewards immobility.

const ACCENT := Color(0.31, 1.0, 0.43)
const BRIGHT := Color(0.84, 1.0, 0.72)


func place_anchor(pos = null, linked_from = null, source: String = "ancorada_attack", claimable: bool = true) -> Dictionary:
	if not is_configured():
		return {}
	var anchor_pos: Vector2 = Vector2(pos) if pos is Vector2 else core.player_pos
	var link_pos: Vector2 = Vector2(linked_from) if linked_from is Vector2 else anchor_pos
	var anchor := {
		"pos": anchor_pos.clamp(Vector2(42.0, 42.0), core.WORLD_SIZE - Vector2(42.0, 42.0)),
		"link_from": link_pos.clamp(Vector2(42.0, 42.0), core.WORLD_SIZE - Vector2(42.0, 42.0)),
		"life": core.ANCORADA_ANCHOR_LIFE,
		"max": core.ANCORADA_ANCHOR_LIFE,
		"source": source,
		"claimable": claimable,
		"claimed": false,
		"tether_tick": 0.0,
		"tether_hits": {},
	}
	core.anchors.append(anchor)
	while core.anchors.size() > core.ANCORADA_ANCHOR_MAX_ACTIVE:
		core.anchors.pop_front()
	AncoradaEvolutionController.on_anchor_placed(core, anchor)
	return anchor


func attack_damage_multiplier() -> float:
	if not is_configured():
		return 1.0
	return 1.0 + float(core.lastro_stacks) * core.ANCORADA_LASTRO_DAMAGE_PER_STACK


func attack_interval_multiplier() -> float:
	if not is_configured():
		return 1.0
	var lastro_mult: float = 1.0 - float(core.lastro_stacks) * float(core.ANCORADA_LASTRO_ATTACK_SPEED_PER_STACK)
	return maxf(0.72, lastro_mult * (1.0 - ultimate_momentum() * core.ANCORADA_ULTIMATE_ATTACK_SPEED_BONUS))


func on_projectile_hit(bullet: Dictionary, target_pos: Vector2, target_key: String) -> void:
	if not is_configured() or String(bullet.get("kind", "")) != "ancorada":
		return
	var points_given := int(bullet.get("lastro_points_given", 0))
	if points_given < core.ANCORADA_LASTRO_BASIC_MAX_POINTS_PER_PROJECTILE:
		bullet["lastro_points_given"] = points_given + 1
		add_lastro_points(1, "basic_attack")
	if bool(bullet.get("ancorada_anchor_deployed", false)):
		return
	bullet["ancorada_anchor_deployed"] = true
	place_anchor(target_pos, Vector2(bullet.get("origin", core.player_pos)), "ancorada_hit_%s" % target_key, true)


func on_teleport(origin: Vector2, destination: Vector2) -> void:
	if not is_configured():
		return
	place_anchor(origin, origin, "ancorada_tp_origin", false)
	place_anchor(destination, origin, "ancorada_tp_arrival", true)


func on_evolution_hit(event_id: String, target: Dictionary, target_pos: Vector2) -> bool:
	return AncoradaEvolutionController.on_hit(core, event_id, target, target_pos)


func on_evolution_skill(center: Vector2) -> bool:
	return AncoradaEvolutionController.on_skill(core, center)


func on_evolution_teleport(origin: Vector2, destination: Vector2) -> bool:
	return AncoradaEvolutionController.on_teleport(core, origin, destination)


func update_evolutions(delta: float) -> void:
	AncoradaEvolutionController.update_effects(core, delta)


func draw_evolutions(camera: Vector2) -> void:
	AncoradaEvolutionController.draw_world(core, camera)


func add_lastro_points(amount: int, _source_type: String = "") -> void:
	if not is_configured() or core.manifestation_key != "ancorada" or amount <= 0:
		return
	if core.lastro_stacks >= core.ANCORADA_LASTRO_MAX_STACKS:
		return
	core.lastro_decay_timer = 0.0
	core.lastro_decay_interval_timer = 0.0
	core.lastro_points += amount
	while core.lastro_points >= core.ANCORADA_LASTRO_POINTS_PER_STACK and core.lastro_stacks < core.ANCORADA_LASTRO_MAX_STACKS:
		core.lastro_points -= core.ANCORADA_LASTRO_POINTS_PER_STACK
		core.lastro_stacks += 1
	if core.lastro_stacks >= core.ANCORADA_LASTRO_MAX_STACKS:
		core.lastro_points = 0
		if not core.lastro_5_callout_triggered:
			core.lastro_5_callout_triggered = true
			core._add_text("FORTALEZA EM MARCHA", core.player_pos + Vector2(0, -96), BRIGHT, 1.2, 24)
			core._play_sfx("boss_impact", 0.03, 1.2, 1.1)
			core._vibrate(80, 0.3)


func update(delta: float) -> void:
	if not is_configured() or core.manifestation_key != "ancorada":
		return
	# Legacy fields remain readable for old saves/tests but never gain power.
	core.ancorada_crit_bonus = 0.0
	core.ancorada_weight_knockback = 5.0
	core.ancorada_still_timer = 0.0
	core.ancorada_weight_timer = 0.0
	update_hab1(delta)
	_update_lastro_decay(delta)
	_update_anchor_territory(delta)


func _update_lastro_decay(delta: float) -> void:
	if core.lastro_stacks <= 0 and core.lastro_points <= 0:
		return
	core.lastro_decay_timer += delta
	if core.lastro_decay_timer < core.ANCORADA_LASTRO_DECAY_DELAY:
		return
	core.lastro_points = 0
	core.lastro_decay_interval_timer += delta
	while core.lastro_decay_interval_timer >= core.ANCORADA_LASTRO_DECAY_INTERVAL:
		core.lastro_decay_interval_timer -= core.ANCORADA_LASTRO_DECAY_INTERVAL
		core.lastro_stacks = maxi(0, core.lastro_stacks - 1)
		if core.lastro_stacks < core.ANCORADA_LASTRO_MAX_STACKS:
			core.lastro_5_callout_triggered = false


func consume_all_lastro_stacks() -> void:
	if not is_configured():
		return
	core.lastro_hud_drain_prev_stacks = core.lastro_stacks
	core.lastro_hud_drain_timer = 0.22
	core.lastro_stacks = 0
	core.lastro_points = 0
	core.lastro_decay_timer = 0.0
	core.lastro_decay_interval_timer = 0.0
	core.lastro_5_callout_triggered = false


func _update_anchor_territory(delta: float) -> void:
	for anchor in core.anchors:
		if not String(anchor.get("source", "")).begins_with("ancorada_"):
			continue
		var anchor_pos := Vector2(anchor.get("pos", core.player_pos))
		if bool(anchor.get("claimable", false)) and not bool(anchor.get("claimed", false)) and core.player_pos.distance_to(anchor_pos) <= core.ANCORADA_ANCHOR_CLAIM_RADIUS:
			anchor["claimed"] = true
			anchor["claim_flash"] = 0.5
			add_lastro_points(core.ANCORADA_ANCHOR_CLAIM_LASTRO_POINTS, "anchor_claim")
			core._add_text("LINHA FIRMADA", anchor_pos + Vector2(0, -48), ACCENT, 0.65, 16)
			core._play_sfx("boss_impact", 0.035, 1.3, 0.55)
		anchor["claim_flash"] = maxf(0.0, float(anchor.get("claim_flash", 0.0)) - delta)
		var link_from := Vector2(anchor.get("link_from", anchor_pos))
		if link_from.distance_squared_to(anchor_pos) < 225.0:
			continue
		anchor["tether_tick"] = float(anchor.get("tether_tick", 0.0)) - delta
		if float(anchor["tether_tick"]) > 0.0:
			continue
		anchor["tether_tick"] = core.ANCORADA_TETHER_SCAN_INTERVAL
		var hit_ids: Dictionary = anchor.get("tether_hits", {})
		for enemy in core.enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			var uid := str(enemy.get("uid", ""))
			if hit_ids.has(uid):
				continue
			if core._distance_to_segment(Vector2(enemy.get("pos", Vector2.ZERO)), link_from, anchor_pos) <= core.ANCORADA_TETHER_WIDTH:
				hit_ids[uid] = true
				core._damage_enemy(enemy, core.player_damage * core.ANCORADA_TETHER_DAMAGE_MULT, "ancorada", false)
				enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), core.ANCORADA_TETHER_SLOW_DURATION)
				enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), core.ANCORADA_TETHER_SLOW_MULT)
		if core.boss_active and core.boss_hp > 0.0 and not hit_ids.has("boss") and core._distance_to_segment(core.boss_pos, link_from, anchor_pos) <= core.ANCORADA_TETHER_WIDTH + 20.0:
			hit_ids["boss"] = true
			core._damage_boss(core.player_damage * core.ANCORADA_TETHER_BOSS_DAMAGE_MULT, "ancorada")
		if core._arauto_active() and not hit_ids.has("arauto") and core._distance_to_segment(Vector2(core.arauto.get("pos", Vector2.ZERO)), link_from, anchor_pos) <= core.ANCORADA_TETHER_WIDTH + 20.0:
			hit_ids["arauto"] = true
			core._damage_arauto(core.player_damage * core.ANCORADA_TETHER_BOSS_DAMAGE_MULT, "ancorada", false)
		anchor["tether_hits"] = hit_ids


func trigger_hab1(target_world = null) -> void:
	if not is_configured() or core.hab1_ancorada_active:
		return
	core.hab1_ancorada_active = true
	core.hab1_ancorada_timer = 0.0
	core.hab1_ancorada_impact_done = false
	var cast_pos: Vector2 = core.player_pos
	if target_world is Vector2:
		cast_pos = Vector2(target_world)
	elif core._uses_desktop_ui():
		cast_pos = core._desktop_aim_target_world()
	else:
		var target_enemy: Vector2 = core._nearest_target()
		cast_pos = target_enemy if target_enemy != Vector2.ZERO and target_enemy.distance_to(core.player_pos) <= 520.0 else core.player_pos + core._aim_direction() * 200.0
	core.hab1_ancorada_cast_origin = core.player_pos
	core.hab1_ancorada_cast_pos = cast_pos.clamp(Vector2(50, 50), core.WORLD_SIZE - Vector2(50, 50))
	core.hab1_ancorada_cast_lastro = core.lastro_stacks
	core._add_text("ARRANCO DE FUNDACAO", core.hab1_ancorada_cast_pos + Vector2(0, -60), ACCENT, 1.2, 24)
	core._play_sfx("boss_impact", 0.03, 0.95, 1.1)
	core._vibrate(90, 0.35)


func update_hab1(delta: float) -> void:
	if not is_configured() or not core.hab1_ancorada_active:
		return
	core.hab1_ancorada_timer += delta
	if not core.hab1_ancorada_impact_done and core.hab1_ancorada_timer >= core.ANCORADA_HAB1_IMPACT_TIME:
		core.hab1_ancorada_impact_done = true
		_apply_hab1_impact(core.hab1_ancorada_cast_pos, core.hab1_ancorada_cast_lastro)
		consume_all_lastro_stacks()
	if core.hab1_ancorada_timer >= core.ANCORADA_HAB1_IMPACT_TIME + 0.45:
		core.hab1_ancorada_active = false


func _apply_hab1_impact(cast_pos: Vector2, stacks: int) -> void:
	var lastro := clampi(stacks, 0, core.ANCORADA_LASTRO_MAX_STACKS)
	var radius := 105.0 + 14.0 * float(lastro)
	var common_damage_mult := 0.95 + 0.25 * float(lastro)
	var boss_damage_mult := 0.80 + 0.18 * float(lastro)
	var common_speed_mult := maxf(0.12, 0.42 - 0.06 * float(lastro))
	var common_duration := 0.45 + 0.10 * float(lastro)
	var pull_ratio: float = float(core.ANCORADA_HAB1_PULL_BASE) + float(core.ANCORADA_HAB1_PULL_PER_LASTRO) * float(lastro)
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var enemy_pos := Vector2(enemy.get("pos", Vector2.ZERO))
		if enemy_pos.distance_to(cast_pos) > radius:
			continue
		var is_elite: bool = String(enemy.get("type", "")).begins_with("elite") or String(enemy.get("type", "")) in [core.ENEMY_FOSSIL_PUSTULE, core.ENEMY_MIASMA_EEL]
		core._damage_enemy(enemy, core.player_damage * common_damage_mult, "ancorada", false)
		var effective_pull: float = pull_ratio * (0.6 if is_elite else 1.0)
		enemy["pos"] = enemy_pos.lerp(cast_pos, effective_pull).clamp(Vector2(40, 40), core.WORLD_SIZE - Vector2(40, 40))
		enemy["velocity"] = Vector2.ZERO
		enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), common_duration * (0.75 if is_elite else 1.0))
		enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), lerpf(1.0, common_speed_mult, 0.65 if is_elite else 1.0))
	if core.boss_active and core.boss_hp > 0.0 and core.boss_pos.distance_to(cast_pos) <= radius:
		core._damage_boss(core.player_damage * boss_damage_mult, "ancorada")
	if core._arauto_active() and Vector2(core.arauto.get("pos", Vector2.ZERO)).distance_to(cast_pos) <= radius:
		core._damage_arauto(core.player_damage * boss_damage_mult, "ancorada", false)
	for bullet in core.enemy_bullets:
		if Vector2(bullet.get("pos", Vector2.ZERO)).distance_to(cast_pos) > radius:
			continue
		var projectile_mult := maxf(0.075, 0.30 - 0.045 * float(lastro))
		if core._damage_source_is_boss(String(bullet.get("type", ""))):
			projectile_mult = lerpf(1.0, projectile_mult, 0.5)
		bullet["speed_mult"] = minf(float(bullet.get("speed_mult", 1.0)), projectile_mult)
		bullet["slow_timer"] = maxf(float(bullet.get("slow_timer", 0.0)), 0.35 + 0.07 * float(lastro))
	place_anchor(cast_pos, core.hab1_ancorada_cast_origin, "ancorada_q", true)
	core.screen_shake_strength = maxf(core.screen_shake_strength, 3.2 + 0.9 * float(lastro))
	core.screen_shake_timer = maxf(core.screen_shake_timer, 0.09 + 0.01 * float(lastro))
	core._spawn_ancorada_counterweight_vfx(cast_pos, lastro)


func spawn_ultimate(_target_world = null) -> void:
	if not is_configured():
		return
	var center: Vector2 = core.player_pos
	core.manifestation_secondaries.append({
		"kind": "ancorada",
		"life": core.SECONDARY_ANCORADA_DURATION,
		"max": core.SECONDARY_ANCORADA_DURATION,
		"center": center,
		"last_player_pos": center,
		"radius": core.ANCORADA_ULTIMATE_RADIUS,
		"drop_tick": 0.0,
		"momentum": 0.0,
		"distance": 0.0,
		"trail_tick": 0.0,
		"trail": [center],
		"drops": [],
		"impacts": [],
	})
	place_anchor(center, center, "ancorada_ultimate_start", false)
	AncoradaEvolutionController.on_ultimate_started(core, center)
	core._add_text("MARCHA DA FORTALEZA", center + Vector2(0, -110), ACCENT, 1.4, 28)
	core._spawn_radial_particles(center, ACCENT, 32)


func update_ultimate(secondary: Dictionary, delta: float) -> void:
	if not is_configured():
		return
	var previous_player := Vector2(secondary.get("last_player_pos", core.player_pos))
	var moved := previous_player.distance_to(core.player_pos)
	secondary["last_player_pos"] = core.player_pos
	secondary["center"] = core.player_pos
	secondary["distance"] = float(secondary.get("distance", 0.0)) + moved
	var momentum := float(secondary.get("momentum", 0.0))
	momentum = clampf(momentum + moved / core.ANCORADA_ULTIMATE_MOMENTUM_DISTANCE - delta * core.ANCORADA_ULTIMATE_MOMENTUM_DECAY, 0.0, 1.0)
	secondary["momentum"] = momentum
	secondary["charge"] = momentum * core.SECONDARY_ANCORADA_DURATION # legacy visual/snapshot compatibility
	secondary["trail_tick"] = float(secondary.get("trail_tick", 0.0)) - delta
	if float(secondary["trail_tick"]) <= 0.0:
		secondary["trail_tick"] = core.ANCORADA_ULTIMATE_TRAIL_INTERVAL
		var trail: Array = secondary.get("trail", [])
		if trail.is_empty() or Vector2(trail.back()).distance_to(core.player_pos) >= 18.0:
			trail.append(core.player_pos)
		while trail.size() > core.ANCORADA_ULTIMATE_TRAIL_POINTS:
			trail.pop_front()
		secondary["trail"] = trail
	secondary["drop_tick"] = float(secondary.get("drop_tick", 0.0)) - delta
	if float(secondary["drop_tick"]) <= 0.0 and float(secondary.get("life", 0.0)) > 0.0:
		secondary["drop_tick"] = maxf(0.8, core.ANCORADA_ULTIMATE_DROP_INTERVAL - momentum * core.ANCORADA_ULTIMATE_DROP_INTERVAL_BONUS)
		secondary["drop_cycle_lastro_points"] = 0
		_spawn_ultimate_drops(secondary, core.player_pos, float(secondary.get("radius", core.ANCORADA_ULTIMATE_RADIUS)))
	_update_ultimate_impacts(secondary, delta)
	_update_ultimate_drops(secondary, delta, core.player_pos, float(secondary.get("radius", core.ANCORADA_ULTIMATE_RADIUS)))


func _spawn_ultimate_drops(secondary: Dictionary, center: Vector2, radius: float) -> void:
	var drops: Array = secondary.get("drops", [])
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) > 0.0 and Vector2(enemy.get("pos", Vector2.ZERO)).distance_to(center) <= radius:
			drops.append(_make_ultimate_drop(Vector2(enemy["pos"]), "enemy", int(enemy.get("uid", -1))))
	if core.boss_active and core.boss_hp > 0.0 and core.boss_pos.distance_to(center) <= radius:
		drops.append(_make_ultimate_drop(core.boss_pos, "boss", -1))
	if core._arauto_active() and Vector2(core.arauto.get("pos", Vector2.ZERO)).distance_to(center) <= radius:
		drops.append(_make_ultimate_drop(Vector2(core.arauto["pos"]), "arauto", -1))
	secondary["drops"] = drops


func _make_ultimate_drop(target: Vector2, target_kind: String, target_uid: int) -> Dictionary:
	var camera: Vector2 = core._camera(core.get_viewport_rect().size)
	return {
		"target": target,
		"start": Vector2(target.x + core.rng.randf_range(-42.0, 42.0), camera.y - core.rng.randf_range(92.0, 168.0)),
		"age": 0.0,
		"fall": core.ANCORADA_ULTIMATE_FALL_TIME,
		"kind": target_kind,
		"uid": target_uid,
		"seed": core.rng.randf_range(0.0, 1000.0),
		"hit": false,
		"hit_ids": {},
	}


func _update_ultimate_drops(secondary: Dictionary, delta: float, center: Vector2, radius: float) -> void:
	var drops: Array = secondary.get("drops", [])
	for drop in drops:
		drop["age"] = float(drop.get("age", 0.0)) + delta
		var fall_time := maxf(0.05, float(drop.get("fall", core.ANCORADA_ULTIMATE_FALL_TIME)))
		if not bool(drop.get("hit", false)) and float(drop["age"]) >= fall_time:
			drop["hit"] = true
			_apply_ultimate_impact(drop, secondary, center, radius)
	secondary["drops"] = drops.filter(func(drop): return float(drop.get("age", 0.0)) <= float(drop.get("fall", core.ANCORADA_ULTIMATE_FALL_TIME)) + 0.42)


func _update_ultimate_impacts(secondary: Dictionary, delta: float) -> void:
	var impacts: Array = secondary.get("impacts", [])
	for impact in impacts:
		impact["life"] = float(impact.get("life", 0.0)) - delta
	secondary["impacts"] = impacts.filter(func(impact): return float(impact.get("life", 0.0)) > 0.0)


func _apply_ultimate_impact(drop: Dictionary, secondary: Dictionary, center: Vector2, radius: float) -> void:
	var target := Vector2(drop.get("target", center))
	var hit_ids: Dictionary = drop.get("hit_ids", {})
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var enemy_pos := Vector2(enemy.get("pos", Vector2.ZERO))
		if enemy_pos.distance_to(center) > radius or enemy_pos.distance_to(target) > core.ANCORADA_ULTIMATE_IMPACT_RADIUS:
			continue
		var uid := int(enemy.get("uid", -1))
		if hit_ids.has(uid):
			continue
		hit_ids[uid] = true
		core._damage_enemy(enemy, core.player_damage * core.ANCORADA_ULTIMATE_DAMAGE_MULT, "ancorada", false)
		enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), core.ANCORADA_ULTIMATE_SLOW_DURATION)
		enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), core.ANCORADA_ULTIMATE_SLOW_MULT)
	if core.boss_active and core.boss_hp > 0.0 and core.boss_pos.distance_to(center) <= radius and core.boss_pos.distance_to(target) <= core.ANCORADA_ULTIMATE_IMPACT_RADIUS:
		core._damage_boss(core.player_damage * core.ANCORADA_ULTIMATE_BOSS_DAMAGE_MULT, "ancorada")
	if core._arauto_active() and Vector2(core.arauto.get("pos", Vector2.ZERO)).distance_to(center) <= radius and Vector2(core.arauto.get("pos", Vector2.ZERO)).distance_to(target) <= core.ANCORADA_ULTIMATE_IMPACT_RADIUS:
		core._damage_arauto(core.player_damage * core.ANCORADA_ULTIMATE_BOSS_DAMAGE_MULT, "ancorada", false)
	drop["hit_ids"] = hit_ids
	var impacts: Array = secondary.get("impacts", [])
	impacts.append({"pos": target, "life": 0.58, "max": 0.58, "radius": core.ANCORADA_ULTIMATE_IMPACT_RADIUS, "seed": float(drop.get("seed", 0.0))})
	secondary["impacts"] = impacts
	core._spawn_radial_particles(target, ACCENT, 18)
	var cycle_points := int(secondary.get("drop_cycle_lastro_points", 0))
	if cycle_points < core.ANCORADA_LASTRO_E_MAX_POINTS_PER_DROP_CYCLE:
		var points := 2 if String(drop.get("kind", "")) in ["boss", "arauto", "elite"] else 1
		var to_add := mini(points, core.ANCORADA_LASTRO_E_MAX_POINTS_PER_DROP_CYCLE - cycle_points)
		if to_add > 0:
			secondary["drop_cycle_lastro_points"] = cycle_points + to_add
			add_lastro_points(to_add, "marcha_fortaleza")


func ultimate_momentum() -> float:
	if not is_configured():
		return 0.0
	var best := 0.0
	for secondary in core.manifestation_secondaries:
		if String(secondary.get("kind", "")) == "ancorada":
			best = maxf(best, clampf(float(secondary.get("momentum", 0.0)), 0.0, 1.0))
	return best


func projectile_slow_at(pos: Vector2) -> float:
	if not is_configured():
		return 1.0
	var slow := 1.0
	for secondary in core.manifestation_secondaries:
		if String(secondary.get("kind", "")) != "ancorada":
			continue
		var center := Vector2(secondary.get("center", core.player_pos))
		if pos.distance_to(center) <= float(secondary.get("radius", core.ANCORADA_ULTIMATE_RADIUS)):
			var momentum := clampf(float(secondary.get("momentum", 0.0)), 0.0, 1.0)
			slow = minf(slow, 0.58 - momentum * 0.20)
	return maxf(0.28, slow)


func update_network_replica(visual: Dictionary, previous_center: Vector2, delta: float) -> void:
	if not is_configured():
		return
	var center := Vector2(visual.get("center", previous_center))
	var moved := previous_center.distance_to(center)
	visual["momentum"] = clampf(float(visual.get("momentum", 0.0)) + moved / core.ANCORADA_ULTIMATE_MOMENTUM_DISTANCE - delta * core.ANCORADA_ULTIMATE_MOMENTUM_DECAY, 0.0, 1.0)
	visual["trail_tick"] = float(visual.get("trail_tick", 0.0)) - delta
	if float(visual["trail_tick"]) <= 0.0:
		visual["trail_tick"] = core.ANCORADA_ULTIMATE_TRAIL_INTERVAL
		var trail: Array = visual.get("trail", [])
		if trail.is_empty() or Vector2(trail.back()).distance_to(center) >= 18.0:
			trail.append(center)
		while trail.size() > core.ANCORADA_ULTIMATE_TRAIL_POINTS:
			trail.pop_front()
		visual["trail"] = trail

	var impacts: Array = visual.get("impacts", [])
	for impact in impacts:
		impact["life"] = float(impact.get("life", 0.0)) - delta
	impacts = impacts.filter(func(impact): return float(impact.get("life", 0.0)) > 0.0)
	visual["drop_tick"] = float(visual.get("drop_tick", 0.0)) - delta
	if float(visual["drop_tick"]) <= 0.0:
		visual["drop_tick"] = core.ANCORADA_ULTIMATE_DROP_INTERVAL
		var cycle := int(visual.get("drop_cycle", 0))
		visual["drop_cycle"] = cycle + 1
		var drops: Array = visual.get("drops", [])
		var count := 2 if core.gfx_low_resource or core._memory_saver_active() else 3
		var seed := int(visual.get("seed", 0))
		for index in range(count):
			var angle := float(seed % 8191) * 0.001 + float(cycle) * 2.39996 + float(index) * TAU / float(count)
			var distance := 96.0 + fposmod(float(seed + cycle * 41 + index * 67), 112.0)
			var target := (center + Vector2.from_angle(angle) * distance).clamp(Vector2(50, 50), core.WORLD_SIZE - Vector2(50, 50))
			drops.append({"target": target, "start": target + Vector2(0.0, -145.0), "age": 0.0, "fall": core.ANCORADA_ULTIMATE_FALL_TIME, "kind": "visual", "uid": -1, "seed": float(seed + cycle * 97 + index * 17), "hit": false, "hit_ids": {}})
		visual["drops"] = drops

	var replica_drops: Array = visual.get("drops", [])
	for drop in replica_drops:
		drop["age"] = float(drop.get("age", 0.0)) + delta
		var fall_time := maxf(0.05, float(drop.get("fall", core.ANCORADA_ULTIMATE_FALL_TIME)))
		if not bool(drop.get("hit", false)) and float(drop["age"]) >= fall_time:
			drop["hit"] = true
			impacts.append({"pos": Vector2(drop.get("target", center)), "life": 0.58, "max": 0.58, "radius": core.ANCORADA_ULTIMATE_IMPACT_RADIUS, "seed": float(drop.get("seed", 0.0))})
	visual["drops"] = replica_drops.filter(func(drop): return float(drop.get("age", 0.0)) <= float(drop.get("fall", core.ANCORADA_ULTIMATE_FALL_TIME)) + 0.42)
	visual["impacts"] = impacts
