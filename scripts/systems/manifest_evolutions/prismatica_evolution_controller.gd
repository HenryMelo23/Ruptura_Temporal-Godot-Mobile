extends RefCounted
class_name RTPrismaticaEvolutionController

# Prismatica's twelve contracts live here instead of sharing the generic
# evolution presets.  Every collection is capped: no effect scans more than
# six formations and each persistent formation ticks at a fixed interval.

const EV1_REFLEXAO_DUPLA := "prismatica_ev1_reflexao_dupla"
const EV1_PRISMA_ESPELHADO := "prismatica_ev1_prisma_espelhado"
const EV1_TRIANGULACAO := "prismatica_ev1_triangulacao"
const EV1_ESPECTRO_SEPARADO := "prismatica_ev1_espectro_separado"
const EV1_PRISMA_ENCADEADO := "prismatica_ev1_prisma_encadeado"
const EV1_REFLEXO_FANTASMA := "prismatica_ev1_reflexo_fantasma"
const EV2_GEOMETRIA_PERFEITA := "prismatica_ev2_geometria_perfeita"
const EV2_LUZ_RECURSIVA := "prismatica_ev2_luz_recursiva"
const EV2_PRISMA_HARMONICO := "prismatica_ev2_prisma_harmonico"
const EV2_FOCO_ABSOLUTO := "prismatica_ev2_foco_absoluto"
const EV2_REDE_ESPECTRAL := "prismatica_ev2_rede_espectral"
const EV2_COLAPSO_CROMATICO := "prismatica_ev2_colapso_cromatico"

const MAX_FORMATIONS := 6
const MAX_GHOSTS := 2
const COLOR_CYAN := Color(0.30, 0.96, 1.0)
const COLOR_MAGENTA := Color(0.94, 0.36, 1.0)
const COLOR_GOLD := Color(1.0, 0.84, 0.38)


static func is_active(game: Node) -> bool:
	if String(game.manifestation_key) != "prismatica":
		return false
	for choice in Array(game.manifest_evolution_state.get("choices", [])):
		if String(Dictionary(choice).get("evolution", "")).begins_with("prismatica_ev"):
			return true
	return false


static func _ids(game: Node) -> Dictionary:
	var ids: Dictionary = {}
	for choice in Array(game.manifest_evolution_state.get("choices", [])):
		var evolution_id := String(Dictionary(choice).get("evolution", ""))
		if evolution_id != "":
			ids[evolution_id] = true
	return ids


static func _has(ids: Dictionary, evolution_id: String) -> bool:
	return bool(ids.get(evolution_id, false))


static func _state(game: Node) -> Dictionary:
	var state: Dictionary = Dictionary(game.manifest_evolution_state.get("prismatica", {}))
	if state.is_empty():
		state = {"formations": [], "ghosts": [], "focus": {}, "sequence": 0, "vfx": []}
		game.manifest_evolution_state["prismatica"] = state
	return state


static func _store(game: Node, state: Dictionary) -> void:
	game.manifest_evolution_state["prismatica"] = state


static func _next_id(state: Dictionary) -> int:
	var value := int(state.get("sequence", 0)) + 1
	state["sequence"] = value
	return value


static func apply_to_bullet(game: Node, bullet: Dictionary) -> void:
	var ids := _ids(game)
	var active_ids: Array = Array(bullet.get("manifest_evolution_ids", []))
	for evolution_id in ids.keys():
		if not active_ids.has(evolution_id):
			active_ids.append(evolution_id)
	bullet["manifest_evolution_ids"] = active_ids
	bullet["manifest_evolution_signature"] = "prismatica_geometry"
	bullet["prismatica_evolution"] = true
	if _has(ids, EV1_REFLEXAO_DUPLA):
		bullet["prism_reflections_left"] = 2
	if _has(ids, EV1_PRISMA_ESPELHADO):
		bullet["prism_mirror_left"] = 2
	if _has(ids, EV1_TRIANGULACAO):
		bullet["prism_triangle_ready"] = true
	if _has(ids, EV1_ESPECTRO_SEPARADO):
		bullet["prism_spectrum_ready"] = true
	if _has(ids, EV1_PRISMA_ENCADEADO):
		bullet["prism_chain_ready"] = true
	if _has(ids, EV2_GEOMETRIA_PERFEITA):
		bullet["prism_perfect_ready"] = true
	if _has(ids, EV2_LUZ_RECURSIVA):
		bullet["prism_recursive_left"] = 1
	if _has(ids, EV2_FOCO_ABSOLUTO):
		bullet["prism_focus_ready"] = true
	if _has(ids, EV2_REDE_ESPECTRAL):
		bullet["prism_network_ready"] = true


static func update_projectile(game: Node, bullet: Dictionary, delta: float) -> void:
	var state := _state(game)
	var formations: Array = Array(state.get("formations", []))
	var pos := Vector2(bullet.get("pos", game.player_pos))
	var ids := _ids(game)
	for formation_value in formations:
		var formation: Dictionary = Dictionary(formation_value)
		var kind := String(formation.get("kind", ""))
		if kind == "mirror" and int(bullet.get("prism_mirror_left", 0)) > 0:
			var mirror_pos := Vector2(formation.get("pos", pos))
			if pos.distance_to(mirror_pos) <= float(formation.get("radius", 34.0)):
				_reflect_on_normal(bullet, Vector2.from_angle(float(formation.get("angle", 0.0))))
				bullet["prism_mirror_left"] = int(bullet.get("prism_mirror_left", 0)) - 1
				bullet["prism_reflected"] = true
				_add_vfx(state, "mirror", mirror_pos, 0.26, COLOR_CYAN)
				game._play_sfx("prismatica_glass_hit", 0.026, 0.96, 1.05)
				break
		if (kind == "triangle" or kind == "perfect") and _point_in_triangle(pos, Array(formation.get("points", []))):
			if not bool(bullet.get("prism_geometry_crossed", false)):
				bullet["prism_geometry_crossed"] = true
				bullet["prism_triangle_charged"] = true
				if kind == "perfect" or _has(ids, EV2_GEOMETRIA_PERFEITA):
					var target := _nearest_target_pos(game, pos, {})
					if target != Vector2.ZERO:
						bullet["dir"] = (target - pos).normalized()
						bullet["prism_perfect_pierce"] = true
				_add_vfx(state, "geometry", pos, 0.22, COLOR_GOLD)
	_store(game, state)


static func on_projectile_hit(game: Node, bullet: Dictionary, target: Dictionary, target_pos: Vector2) -> bool:
	var ids := _ids(game)
	var state := _state(game)
	var keep := false
	var target_uid := str(target.get("uid", "target"))
	var was_reflected := bool(bullet.get("prism_reflected", false))
	var excluded: Dictionary = Dictionary(bullet.get("hits", {})).duplicate()
	excluded[target_uid] = true
	if _has(ids, EV1_REFLEXAO_DUPLA) and int(bullet.get("prism_reflections_left", 0)) > 0:
		var next_pos := _nearest_target_pos(game, target_pos, excluded)
		if next_pos != Vector2.ZERO:
			bullet["dir"] = (next_pos - target_pos).normalized()
			bullet["pos"] = target_pos + Vector2(bullet["dir"]) * 4.0
			bullet["prism_reflections_left"] = int(bullet.get("prism_reflections_left", 0)) - 1
			bullet["prism_reflected"] = true
			keep = true
			_add_vfx(state, "reflection", target_pos, 0.24, COLOR_CYAN)
			game._play_sfx("prismatica_glass_hit", 0.024, 0.92, 1.04)
	if _has(ids, EV1_ESPECTRO_SEPARADO) and bool(bullet.get("prism_spectrum_ready", false)):
		bullet["prism_spectrum_ready"] = false
		_spawn_spectrum_rays(game, bullet, target_pos)
		_add_vfx(state, "spectrum", target_pos, 0.30, COLOR_MAGENTA)
	if _has(ids, EV1_TRIANGULACAO) and bool(bullet.get("prism_triangle_charged", false)):
		bullet["prism_triangle_charged"] = false
		_apply_geometry_burst(game, target_pos, 96.0, 0.16, "triangulacao")
		_add_vfx(state, "triangle_hit", target_pos, 0.34, COLOR_GOLD)
	if _has(ids, EV1_PRISMA_ENCADEADO):
		_apply_chain_anchor(game, state, target_pos, target_uid)
	if _has(ids, EV2_LUZ_RECURSIVA) and was_reflected and int(bullet.get("prism_reflections_left", 0)) <= 0 and int(bullet.get("prism_recursive_left", 0)) > 0:
		var recursive_pos := _nearest_target_pos(game, target_pos, excluded)
		if recursive_pos != Vector2.ZERO:
			bullet["dir"] = (recursive_pos - target_pos).normalized()
			bullet["pos"] = target_pos + Vector2(bullet["dir"]) * 5.0
			bullet["prism_recursive_left"] = int(bullet.get("prism_recursive_left", 0)) - 1
			keep = true
			_add_vfx(state, "recursive", target_pos, 0.28, COLOR_MAGENTA)
	if _has(ids, EV2_FOCO_ABSOLUTO):
		_apply_focus(game, state, target, target_pos)
	if bool(bullet.get("prism_perfect_pierce", false)):
		bullet["prism_perfect_pierce"] = false
		keep = true
	_store(game, state)
	return keep


static func on_skill(game: Node, center: Vector2) -> void:
	var ids := _ids(game)
	var state := _state(game)
	# Colapso consumes the geometry that existed before this cast.  It never
	# deletes a prism which the very same cast has just created.
	if _has(ids, EV2_COLAPSO_CROMATICO) and not Array(state.get("formations", [])).is_empty():
		_collapse_formations(game, state, center)
		_store(game, state)
		return
	if _has(ids, EV1_PRISMA_ESPELHADO):
		_add_formation(game, state, {"kind": "mirror", "pos": center, "angle": (center - game.player_pos).angle(), "radius": 34.0, "life": 7.0, "max": 7.0}, 2)
	if _has(ids, EV1_TRIANGULACAO):
		_add_triangle(game, state, center, 88.0, 6.5, "triangle", 1)
	if _has(ids, EV2_GEOMETRIA_PERFEITA):
		_add_triangle(game, state, center, 116.0, 7.5, "perfect", 1)
	if _has(ids, EV2_PRISMA_HARMONICO):
		_add_triangle(game, state, center, 82.0, 6.0, "harmonic", 1)
	if _has(ids, EV2_REDE_ESPECTRAL):
		_add_triangle(game, state, center, 122.0, 5.5, "network", 1)
	if _has(ids, EV2_COLAPSO_CROMATICO):
		_add_triangle(game, state, center, 70.0, 4.0, "collapse_seed", 1)
	_store(game, state)


static func on_teleport(game: Node, origin: Vector2, destination: Vector2) -> void:
	var ids := _ids(game)
	if not _has(ids, EV1_REFLEXO_FANTASMA):
		return
	var state := _state(game)
	var ghosts: Array = Array(state.get("ghosts", []))
	if ghosts.size() >= MAX_GHOSTS:
		ghosts.pop_front()
	var direction := (destination - origin).normalized()
	if direction.length() <= 0.05:
		direction = Vector2(game.last_facing).normalized()
	ghosts.append({"pos": origin, "dir": direction, "life": 0.42, "damage": float(game.player_damage) * 0.56})
	state["ghosts"] = ghosts
	_add_vfx(state, "ghost", origin, 0.48, COLOR_CYAN)
	_store(game, state)


static func update_effects(game: Node, delta: float) -> void:
	var state := _state(game)
	var formations: Array = []
	for formation_value in Array(state.get("formations", [])):
		var formation: Dictionary = Dictionary(formation_value)
		formation["life"] = float(formation.get("life", 0.0)) - delta
		formation["tick"] = float(formation.get("tick", 0.0)) - delta
		if float(formation["life"]) <= 0.0:
			continue
		var kind := String(formation.get("kind", ""))
		if kind == "harmonic" and float(formation["tick"]) <= 0.0:
			formation["tick"] = 0.68
			_apply_formation_area(game, formation, 124.0, 0.07, 0.62, "harmonico")
			_add_vfx(state, "harmonic", Vector2(formation.get("pos", game.player_pos)), 0.20, COLOR_GOLD)
		elif kind == "network" and float(formation["tick"]) <= 0.0:
			formation["tick"] = 0.52
			_apply_network(game, formation)
		formations.append(formation)
	state["formations"] = formations
	var ghosts: Array = []
	for ghost_value in Array(state.get("ghosts", [])):
		var ghost: Dictionary = Dictionary(ghost_value)
		ghost["life"] = float(ghost.get("life", 0.0)) - delta
		if float(ghost["life"]) > 0.0:
			ghosts.append(ghost)
		else:
			_spawn_ghost_ray(game, ghost)
	state["ghosts"] = ghosts
	var vfx: Array = []
	for event_value in Array(state.get("vfx", [])):
		var event: Dictionary = Dictionary(event_value)
		event["life"] = float(event.get("life", 0.0)) - delta
		if float(event["life"]) > 0.0:
			vfx.append(event)
	state["vfx"] = vfx
	_store(game, state)


static func _add_formation(game: Node, state: Dictionary, formation: Dictionary, per_kind_limit: int) -> void:
	var formations: Array = Array(state.get("formations", []))
	var kind := String(formation.get("kind", ""))
	var same_kind: Array = formations.filter(func(value): return String(Dictionary(value).get("kind", "")) == kind)
	while same_kind.size() >= per_kind_limit:
		var remove_value = same_kind.pop_front()
		formations.erase(remove_value)
	if formations.size() >= MAX_FORMATIONS:
		formations.pop_front()
	formation["id"] = _next_id(state)
	formation["tick"] = float(formation.get("tick", 0.12))
	formations.append(formation)
	state["formations"] = formations
	_add_vfx(state, kind, Vector2(formation.get("pos", game.player_pos)), 0.30, COLOR_CYAN)


static func _add_triangle(game: Node, state: Dictionary, center: Vector2, radius: float, duration: float, kind: String, limit: int) -> void:
	var points: Array = []
	var base_angle: float = (center - game.player_pos).angle() - PI * 0.5
	for i in range(3):
		points.append((center + Vector2.from_angle(base_angle + TAU * float(i) / 3.0) * radius).clamp(Vector2(42, 42), game.WORLD_SIZE - Vector2(42, 42)))
	_add_formation(game, state, {"kind": kind, "pos": center, "points": points, "radius": radius, "life": duration, "max": duration}, limit)


static func _collapse_formations(game: Node, state: Dictionary, fallback_center: Vector2) -> bool:
	var formations: Array = Array(state.get("formations", []))
	if formations.is_empty():
		return false
	var center := Vector2.ZERO
	for formation_value in formations:
		center += Vector2(Dictionary(formation_value).get("pos", fallback_center))
	center /= float(formations.size())
	var radius := minf(230.0, 92.0 + formations.size() * 24.0)
	_apply_geometry_burst(game, center, radius, 0.22, "colapso_cromatico")
	game.shockwaves.append({"pos": center, "radius": 12.0, "max": radius, "life": 0.46, "damage": 0.0, "hit": {}, "visual_only": true, "color": COLOR_MAGENTA})
	state["formations"] = []
	_add_vfx(state, "collapse", center, 0.48, COLOR_MAGENTA)
	game._play_sfx("prismatica_shatter", 0.045, 0.88, 1.02)
	return true


static func _spawn_spectrum_rays(game: Node, source: Dictionary, origin: Vector2) -> void:
	if game.bullets.size() >= int(game.MAX_BULLETS) - 2:
		return
	var direction := Vector2(source.get("dir", Vector2.RIGHT)).normalized()
	for offset in [-0.32, 0.32]:
		game._add_bullet({
			"pos": origin + direction * 6.0,
			"origin": origin,
			"source_category": String(source.get("source_category", "basic_attack")),
			"dir": direction.rotated(offset), "speed": float(source.get("speed", game.BULLET_SPEED)) * 0.82,
			"life": minf(0.72, float(source.get("life", 0.72))), "max_life": minf(0.72, float(source.get("life", 0.72))),
			"age": 0.0, "phase": 0.0, "trail_cd": 0.0,
			"damage": float(source.get("damage", game.player_damage)) * 0.36,
			"kind": "prismatica", "color": COLOR_MAGENTA if offset > 0.0 else COLOR_CYAN,
			"pierce": false, "hits": {}, "refracted": true, "prism_spectrum_child": true,
			"ricochets": 0, "durability": 0.0
		})


static func _apply_chain_anchor(game: Node, state: Dictionary, target_pos: Vector2, target_uid: String) -> void:
	var formations: Array = Array(state.get("formations", []))
	var anchors: Array = formations.filter(func(value): return String(Dictionary(value).get("kind", "")) == "chain_anchor")
	if not anchors.is_empty():
		var prior: Dictionary = Dictionary(anchors.back())
		var from := Vector2(prior.get("pos", target_pos))
		if from.distance_to(target_pos) > 12.0:
			_apply_line_damage(game, from, target_pos, 30.0, 0.13, "prisma_encadeado")
			formations.erase(anchors.back())
			formations.append({"id": _next_id(state), "kind": "chain_link", "pos": (from + target_pos) * 0.5, "points": [from, target_pos], "life": 4.8, "max": 4.8, "tick": 0.28})
			state["formations"] = formations
			_add_vfx(state, "chain", target_pos, 0.30, COLOR_GOLD)
			return
	_add_formation(game, state, {"kind": "chain_anchor", "pos": target_pos, "target_uid": target_uid, "radius": 18.0, "life": 5.5, "max": 5.5}, 1)


static func _apply_focus(game: Node, state: Dictionary, target: Dictionary, target_pos: Vector2) -> void:
	var focus: Dictionary = Dictionary(state.get("focus", {}))
	var uid := str(target.get("uid", "boss"))
	var count := int(focus.get(uid, 0)) + 1
	if count < 4:
		focus[uid] = count
		_add_vfx(state, "focus", target_pos, 0.18, COLOR_GOLD)
		state["focus"] = focus
		return
	focus[uid] = 0
	state["focus"] = focus
	_apply_geometry_burst(game, target_pos, 76.0, 0.18, "foco_absoluto")
	if String(target.get("kind", "")) == "boss":
		game.boss_tp_stun_timer = maxf(float(game.boss_tp_stun_timer), 0.18)
	elif String(target.get("kind", "")) == "arauto":
		game.arauto["stun"] = maxf(float(game.arauto.get("stun", 0.0)), 0.18)
	else:
		target["stun"] = maxf(float(target.get("stun", 0.0)), 0.18)
	_add_vfx(state, "focus_release", target_pos, 0.34, COLOR_GOLD)


static func _apply_geometry_burst(game: Node, center: Vector2, radius: float, damage_ratio: float, source: String) -> void:
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) > 0.0 and center.distance_to(Vector2(enemy.get("pos", center))) <= radius:
			game._damage_enemy(enemy, float(game.player_damage) * damage_ratio, source, false)
	if bool(game.boss_active) and float(game.boss_hp) > 0.0 and center.distance_to(Vector2(game.boss_pos)) <= radius:
		game._damage_boss(float(game.player_damage) * damage_ratio * 0.45, source, false)
	if game._arauto_active() and center.distance_to(Vector2(game.arauto.get("pos", center))) <= radius:
		game._damage_arauto(float(game.player_damage) * damage_ratio * 0.45, source, false)
	game.shockwaves.append({"pos": center, "radius": 10.0, "max": radius, "life": 0.28, "damage": 0.0, "hit": {}, "visual_only": true, "color": COLOR_CYAN})


static func _apply_formation_area(game: Node, formation: Dictionary, radius: float, damage_ratio: float, slow: float, source: String) -> void:
	var center := Vector2(formation.get("pos", game.player_pos))
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 or center.distance_to(Vector2(enemy.get("pos", center))) > radius:
			continue
		enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), 0.52)
		enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), slow)
		game._damage_enemy(enemy, float(game.player_damage) * damage_ratio, source, false)
	if bool(game.boss_active) and float(game.boss_hp) > 0.0 and center.distance_to(Vector2(game.boss_pos)) <= radius:
		game._damage_boss(float(game.player_damage) * damage_ratio * 0.35, source, false)


static func _apply_network(game: Node, formation: Dictionary) -> void:
	var points: Array = Array(formation.get("points", []))
	if points.size() != 3:
		return
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var enemy_pos := Vector2(enemy.get("pos", game.player_pos))
		for index in range(3):
			if _distance_to_segment(enemy_pos, Vector2(points[index]), Vector2(points[(index + 1) % 3])) <= 24.0:
				enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), 0.45)
				enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), 0.60)
				game._damage_enemy(enemy, float(game.player_damage) * 0.075, "rede_espectral", false)
				break


static func _apply_line_damage(game: Node, from: Vector2, to: Vector2, width: float, damage_ratio: float, source: String) -> void:
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) > 0.0 and _distance_to_segment(Vector2(enemy.get("pos", from)), from, to) <= width:
			game._damage_enemy(enemy, float(game.player_damage) * damage_ratio, source, false)
	game.slashes.append({"a": from, "b": to, "life": 0.22, "max": 0.22, "color": COLOR_CYAN, "width": 6.0})


static func _spawn_ghost_ray(game: Node, ghost: Dictionary) -> void:
	if game.bullets.size() >= int(game.MAX_BULLETS):
		return
	var direction := Vector2(ghost.get("dir", Vector2.RIGHT)).normalized()
	game._add_bullet({"pos": Vector2(ghost.get("pos", game.player_pos)), "origin": Vector2(ghost.get("pos", game.player_pos)), "source_category": "ability", "dir": direction, "speed": float(game.BULLET_SPEED) * 0.86, "life": 0.72, "max_life": 0.72, "age": 0.0, "phase": 0.0, "trail_cd": 0.0, "damage": float(ghost.get("damage", game.player_damage * 0.56)), "kind": "prismatica", "color": COLOR_CYAN, "pierce": false, "hits": {}, "refracted": true, "prism_ghost": true, "ricochets": 0, "durability": 0.0})


static func _nearest_target_pos(game: Node, origin: Vector2, excluded: Dictionary) -> Vector2:
	var best := Vector2.ZERO
	var best_distance := INF
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 or excluded.has(str(enemy.get("uid", ""))):
			continue
		var pos := Vector2(enemy.get("pos", origin))
		var distance := origin.distance_squared_to(pos)
		if distance < best_distance:
			best_distance = distance
			best = pos
	if bool(game.boss_active) and float(game.boss_hp) > 0.0 and not excluded.has("boss"):
		var boss_distance := origin.distance_squared_to(Vector2(game.boss_pos))
		if boss_distance < best_distance:
			best = Vector2(game.boss_pos)
	return best


static func _reflect_on_normal(bullet: Dictionary, normal: Vector2) -> void:
	var direction := Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
	bullet["dir"] = direction.bounce(normal.normalized()).normalized()


static func _point_in_triangle(point: Vector2, points: Array) -> bool:
	if points.size() != 3:
		return false
	var a := Vector2(points[0])
	var b := Vector2(points[1])
	var c := Vector2(points[2])
	var d1 := _cross(point - b, a - b)
	var d2 := _cross(point - c, b - c)
	var d3 := _cross(point - a, c - a)
	return (d1 >= 0.0 and d2 >= 0.0 and d3 >= 0.0) or (d1 <= 0.0 and d2 <= 0.0 and d3 <= 0.0)


static func _cross(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x


static func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(a + segment * t)


static func _add_vfx(state: Dictionary, kind: String, pos: Vector2, life: float, color: Color) -> void:
	var vfx: Array = Array(state.get("vfx", []))
	if vfx.size() >= 12:
		vfx.pop_front()
	vfx.append({"kind": kind, "pos": pos, "life": life, "max": life, "color": color})
	state["vfx"] = vfx
