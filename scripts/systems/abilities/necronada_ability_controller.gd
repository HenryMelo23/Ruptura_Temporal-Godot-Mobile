class_name RTNecronadaAbilityController
extends "res://scripts/systems/abilities/ability_controller_base.gd"

## Owns HAB1's summon transaction and the existing remnant update loop. Its
## state and combat primitives stay on Main for now, which keeps saves,
## replication and existing public helpers compatible while later Necronada
## slices are extracted separately.

func try_use_skill(target_world = null) -> bool:
	if not is_configured():
		return false
	var center: Vector2 = Vector2(target_world) if target_world is Vector2 else core.player_pos
	var summoned := 0
	var remaining: Array = []
	for vestige in core.necronada_vestiges:
		var rose_pos: Vector2 = Vector2(vestige.get("pos", core.player_pos))
		if rose_pos.distance_to(center) <= core.NECRONADA_ROSE_SUMMON_RADIUS:
			var slot := {
				"id": int(vestige.get("id", core.necronada_next_id)),
				"enemy_type": String(vestige.get("enemy_type", core.ENEMY_COMMON)),
				"profile": Dictionary(vestige.get("profile", {})),
				"depth": int(vestige.get("depth", 1)),
				"stored_at": core.time_alive
			}
			if core._summon_necronada_remnant(rose_pos, slot):
				summoned += 1
			else:
				remaining.append(vestige)
		else:
			remaining.append(vestige)
	core.necronada_vestiges = remaining
	if summoned <= 0:
		core._add_text("NENHUMA ALMA NO RAIO", core.player_pos + Vector2(0, -90), Color(0.72, 0.88, 1.0), 0.8, 17)
		return false
	core._add_necronada_horde_progress(summoned)
	core._add_text("LEVANTE x%d" % summoned, center + Vector2(0, -92), core._necronada_accent(), 1.0, 20)
	core._spawn_radial_particles(center, core._necronada_color(), 24)
	core.necronada_vfx.append({"kind": "rose_summon_ring", "pos": center, "life": 0.48, "max": 0.48, "radius": core.NECRONADA_ROSE_SUMMON_RADIUS})
	# Necronada leaves _use_skill early.  The generic event must fire only after
	# a successful summon, never for an empty or capped request.
	core._manifest_evolution_on_skill(center)
	return true


func update_remnants(delta: float) -> void:
	if not is_configured():
		return
	for remnant in core.necronada_remnants:
		remnant["phase"] = float(remnant.get("phase", 0.0)) + delta * 4.0
		remnant["empower_timer"] = maxf(0.0, float(remnant.get("empower_timer", 0.0)) - delta)

		if float(remnant.get("summon", 0.0)) > 0.0:
			remnant["summon"] = maxf(0.0, float(remnant.get("summon", 0.0)) - delta)
			if float(remnant["summon"]) <= 0.0:
				core._necronada_last_act(remnant)
			continue

		var wait_timer := maxf(0.0, float(remnant.get("wait_timer", 0.0)) - delta)
		remnant["wait_timer"] = wait_timer
		if wait_timer > 0.0:
			continue

		remnant["target_timer"] = float(remnant.get("target_timer", 0.0)) - delta
		if float(remnant["target_timer"]) <= 0.0 or not core._necronada_target_alive(remnant):
			var target: Dictionary = core._necronada_find_target(Vector2(remnant.get("pos", core.player_pos)))
			if target.is_empty():
				remnant["target_kind"] = ""
				remnant["target_uid"] = -1
				remnant["target_pos"] = Vector2(remnant.get("pos", core.player_pos))
			else:
				remnant["target_kind"] = String(target.get("kind", ""))
				remnant["target_uid"] = int(target.get("uid", -1))
				remnant["target_pos"] = Vector2(target.get("pos", core.player_pos))
			remnant["target_timer"] = core.NECRONADA_REMNANT_TARGET_INTERVAL
			remnant["blocked_retries"] = 0
		else:
			remnant["target_pos"] = core._necronada_remnant_target_pos(remnant)

		var profile: Dictionary = Dictionary(remnant.get("profile", {}))
		var pos := Vector2(remnant.get("pos", core.player_pos))
		var target_pos := Vector2(remnant.get("target_pos", core.player_pos))
		var to_target := target_pos - pos
		var distance := to_target.length()
		var is_ranged := bool(remnant.get("is_ranged", false))
		var is_curate := bool(remnant.get("is_curate", false))
		var profile_range := float(profile.get("range", 62.0))
		var attack_range := profile_range
		if is_ranged:
			attack_range = maxf(profile_range, core.NECRONADA_REMNANT_RANGED_RANGE_MIN)
		elif is_curate:
			attack_range = maxf(profile_range, core.NECRONADA_REMNANT_SUPPORT_RANGE_MIN)
		else:
			attack_range = maxf(profile_range, core.NECRONADA_REMNANT_MELEE_RANGE_MIN)
		var move_speed: float = maxf(float(profile.get("speed", 118.0)), core.player_speed * 0.5)
		if bool(remnant.get("supreme", false)):
			move_speed *= 1.15
		if float(remnant.get("empower_timer", 0.0)) > 0.0:
			move_speed *= core.NECRONADA_EMPOWER_ALLY_SPEED_MULT
			var empowered_pos := Vector2(remnant.get("empower_target_pos", target_pos))
			var empowered_target: Dictionary = core._necronada_find_target_near(empowered_pos)
			if not empowered_target.is_empty():
				remnant["target_kind"] = String(empowered_target.get("kind", remnant.get("target_kind", "")))
				remnant["target_uid"] = int(empowered_target.get("uid", remnant.get("target_uid", -1)))
				remnant["target_pos"] = Vector2(empowered_target.get("pos", target_pos))
				target_pos = Vector2(remnant["target_pos"])
				to_target = target_pos - pos
				distance = to_target.length()

		var desired := Vector2.ZERO
		if distance > attack_range * 0.85:
			desired = to_target.normalized()
		elif is_ranged and distance < 100.0:
			desired = -to_target.normalized()

		var direction: Vector2 = core._steer_entity_with_avoidance(remnant, pos, desired, delta)
		var old_pos := pos
		if direction.length_squared() > 0.001:
			remnant["facing_dir"] = direction
			remnant["pos"] = (pos + direction * move_speed * delta).clamp(Vector2(40, 40), core.WORLD_SIZE - Vector2(40, 40))

		var moved_dist := old_pos.distance_to(Vector2(remnant.get("pos", old_pos)))
		if distance > attack_range and moved_dist < 0.5:
			remnant["blocked_retries"] = int(remnant.get("blocked_retries", 0)) + 1
			if int(remnant["blocked_retries"]) >= 5:
				remnant["blocked_retries"] = 0
				var current_uid := int(remnant.get("target_uid", -1))
				var alternate_target: Dictionary = core._necronada_find_target(pos, [current_uid])
				if not alternate_target.is_empty():
					remnant["target_kind"] = String(alternate_target.get("kind", ""))
					remnant["target_uid"] = int(alternate_target.get("uid", -1))
					remnant["target_pos"] = Vector2(alternate_target.get("pos", core.player_pos))
				else:
					remnant["wait_timer"] = 15.0

		remnant["attack_cd"] = float(remnant.get("attack_cd", 0.0)) - delta
		if float(remnant["attack_cd"]) <= 0.0:
			if is_curate:
				remnant["attack_cd"] = 3.5
				for other_remnant in core.necronada_remnants:
					if float(other_remnant.get("hp", 0.0)) > 0.0 and Vector2(other_remnant.get("pos", core.player_pos)).distance_to(pos) <= 160.0:
						var max_health := float(other_remnant.get("max_hp", core.player_hp_max * 0.6))
						var heal := maxf(1.0, max_health * 0.12 * 0.3)
						other_remnant["hp"] = minf(max_health, float(other_remnant["hp"]) + heal)
						core._add_text("+%.0f" % heal, Vector2(other_remnant.get("pos", core.player_pos)) + Vector2(0, -30), Color(0.2, 1.0, 0.4), 0.8, 16)
			elif distance <= attack_range and String(remnant.get("target_kind", "")) != "":
				core._necronada_remnant_attack(remnant)
				var archetype := String(profile.get("archetype", "predador"))
				remnant["attack_cd"] = 1.05 if is_ranged else (1.35 if archetype == "bastiao" else 0.76)
	core.necronada_remnants = core.necronada_remnants.filter(func(remnant): return float(remnant.get("hp", 0.0)) > 0.0)
