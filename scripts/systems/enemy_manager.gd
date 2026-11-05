class_name EnemyManager
extends Node

const PHASE_DENSITY_CARRY_RATIO := 0.70
const SPATIAL_CELL_SIZE := 128.0
const MAX_ENTITY_PHYSICAL_RADIUS := 36.0
const PASSIVE_TIMER_KEYS: Array[StringName] = [
	&"ferrolho_root",
	&"blind_confusion",
	&"resonant_stun_notes",
	&"shield_flash",
	&"reconstitute_time",
	&"reconstitute_immunity",
]

# Cadencia de especiais pertence ao owner de spawn. Os valores experientes sao
# destinos explicitos, nao multiplicadores aplicados em cima do baseline.
const SPECIAL_SPAWN_PACING: Dictionary = {
	2: {
		"first_unlock": 45.0,
		"experienced_first_unlock": 30.0,
		"repeat_gap": 48.0,
		"experienced_repeat_gap": 38.0,
		"kamikaze_unlock": 45.0,
		"experienced_kamikaze_unlock": 30.0,
		"pyro_unlock": 180.0,
		"experienced_pyro_unlock": 120.0
	},
	3: {
		"first_unlock": 120.0,
		"experienced_first_unlock": 90.0,
		"repeat_gap": 54.0,
		"experienced_repeat_gap": 43.0,
		"flagelante_unlock": 150.0,
		"experienced_flagelante_unlock": 110.0,
		"incensario_unlock": 240.0,
		"experienced_incensario_unlock": 180.0,
		"salmodiante_unlock": 210.0,
		"experienced_salmodiante_unlock": 160.0,
		"guardiao_unlock": 360.0,
		"experienced_guardiao_unlock": 270.0,
		"relicario_unlock": 300.0,
		"experienced_relicario_unlock": 225.0
	},
	4: {
		"first_unlock": 0.0,
		"experienced_first_unlock": 0.0,
		"repeat_gap": 72.0,
		"experienced_repeat_gap": 58.0
	},
	5: {
		"first_unlock": 0.0,
		"experienced_first_unlock": 0.0,
		"repeat_gap": 72.0,
		"experienced_repeat_gap": 58.0
	},
	6: {
		"first_unlock": 120.0,
		"experienced_first_unlock": 90.0,
		"repeat_gap": 66.0,
		"experienced_repeat_gap": 52.0,
		"leech_unlock": 120.0,
		"experienced_leech_unlock": 90.0,
		"eel_unlock": 210.0,
		"experienced_eel_unlock": 158.0,
		"pustule_unlock": 330.0,
		"experienced_pustule_unlock": 255.0
	},
	7: {
		"first_unlock": 45.0,
		"experienced_first_unlock": 45.0,
		"repeat_gap": 60.0,
		"experienced_repeat_gap": 60.0
	}
}

var game: Node = null
var phase_density_carry_cap: int = 0
var phase_density_native_entry_cap: int = 0
var special_last_spawn_phase_time: float = -1.0
var special_spawn_history: Array[Dictionary] = []
var spatial_entities: Array = []
var spatial_physical_radii: Array[float] = []
## Posicoes no momento da indexacao (para consultas sem tocar nos dicionarios).
var spatial_positions: PackedVector2Array = PackedVector2Array()
## Limite de candidatos examinados no desvio (densidade alta nao escala o custo).
const AVOIDANCE_MAX_CANDIDATES := 18
var spatial_cells: Dictionary = {}
var spatial_active_cells: Array[Vector2i] = []
var spatial_index_query: Array[int] = []
var spatial_entity_query: Array = []
var separation_accumulator: float = 0.0
var dead_enemy_buffer: Array = []
var phase2_common_uid_buffer: Array[int] = []
var phase2_common_shooter_uids: Dictionary = {}
var horde = preload("res://scripts/systems/enemies/horde_pressure_controller.gd").new()
var lod_target_positions: Array = []


func bind_game(p_game: Node) -> void:
	game = p_game
	separation_accumulator = 0.0
	horde.configure(p_game)
	reset_special_pacing(true)
	clear_spatial_index()


func clear_spatial_index() -> void:
	spatial_entities.clear()
	spatial_physical_radii.clear()
	spatial_positions.clear()
	spatial_cells.clear()
	spatial_active_cells.clear()
	spatial_index_query.clear()
	spatial_entity_query.clear()


func _reset_spatial_frame() -> void:
	# Keep the cell buckets allocated between frames. Clearing the dictionary and
	# recreating one Array per occupied cell caused allocator/GC spikes in long
	# combat sessions even though the number of living enemies stayed bounded.
	spatial_entities.clear()
	spatial_physical_radii.clear()
	spatial_positions.clear()
	for cell in spatial_active_cells:
		var bucket: Array = spatial_cells.get(cell, [])
		bucket.clear()
	spatial_active_cells.clear()
	spatial_index_query.clear()
	spatial_entity_query.clear()


func rebuild_spatial_index() -> void:
	_reset_spatial_frame()
	if game == null:
		return
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) > 0.0:
			_add_spatial_entity(enemy)


func _add_spatial_entity(entity: Dictionary) -> void:
	var index: int = spatial_entities.size()
	var pos := Vector2(entity.get("pos", Vector2.ZERO))
	spatial_entities.append(entity)
	spatial_physical_radii.append(game._entity_physical_radius(entity))
	spatial_positions.append(pos)
	entity["_si"] = index
	var cell := _spatial_cell(pos)
	if not spatial_cells.has(cell):
		spatial_cells[cell] = []
	var bucket: Array = spatial_cells[cell]
	if bucket.is_empty():
		spatial_active_cells.append(cell)
	bucket.append(index)


func _spatial_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / SPATIAL_CELL_SIZE), floori(pos.y / SPATIAL_CELL_SIZE))


func nearby_entity_indices(pos: Vector2, radius: float, sort_result: bool = true) -> Array[int]:
	spatial_index_query.clear()
	var min_cell := _spatial_cell(pos - Vector2.ONE * radius)
	var max_cell := _spatial_cell(pos + Vector2.ONE * radius)
	for cell_y in range(min_cell.y, max_cell.y + 1):
		for cell_x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(cell_x, cell_y)
			if not spatial_cells.has(cell):
				continue
			for raw_index in spatial_cells[cell]:
				var index := int(raw_index)
				spatial_index_query.append(index)
	if sort_result:
		spatial_index_query.sort()
	return spatial_index_query


## Primeiro vizinho que bloqueia o caminho (indice no indice espacial) ou -1.
## Varre as celulas direto, com posicoes/raios ja calculados e teste de direcao sem
## normalizar; examina no maximo AVOIDANCE_MAX_CANDIDATES candidatos.
func find_avoidance_obstacle(pos: Vector2, my_radius: float, ray_length: float, desired_dir: Vector2, self_index: int) -> int:
	var search_radius: float = my_radius * 3.2 + MAX_ENTITY_PHYSICAL_RADIUS
	var min_cell := _spatial_cell(pos - Vector2.ONE * search_radius)
	var max_cell := _spatial_cell(pos + Vector2.ONE * search_radius)
	var examined := 0
	var count: int = spatial_positions.size()
	for cell_y in range(min_cell.y, max_cell.y + 1):
		for cell_x in range(min_cell.x, max_cell.x + 1):
			var bucket = spatial_cells.get(Vector2i(cell_x, cell_y))
			if bucket == null:
				continue
			for raw_index in bucket:
				var j: int = raw_index
				if j == self_index or j >= count:
					continue
				var to_other: Vector2 = spatial_positions[j] - pos
				var reach: float = my_radius + spatial_physical_radii[j] + ray_length
				var dist_sq: float = to_other.length_squared()
				if dist_sq <= 0.01 or dist_sq >= reach * reach:
					continue
				examined += 1
				# dot(desired, to_other / |to_other|) > 0.65 sem sqrt quando possivel.
				var d: float = desired_dir.dot(to_other)
				if d > 0.0 and d * d > 0.4225 * dist_sq:
					return j
				if examined >= AVOIDANCE_MAX_CANDIDATES:
					return -1
	return -1


func avoidance_neighbors(pos: Vector2, my_radius: float) -> Array:
	var search_radius: float = my_radius * 3.2 + MAX_ENTITY_PHYSICAL_RADIUS
	spatial_entity_query.clear()
	# Avoidance only needs a deterministic nearby candidate, not globally sorted
	# indices. Cell traversal and bucket insertion are already deterministic.
	for index in nearby_entity_indices(pos, search_radius, false):
		var entity: Dictionary = spatial_entities[index]
		if float(entity.get("hp", 0.0)) > 0.0:
			spatial_entity_query.append(entity)
	return spatial_entity_query


func apply_entity_separation(delta: float, spatial_index_ready: bool = false) -> void:
	if game == null or delta <= 0.0:
		return
	var interval: float = game._enemy_separation_interval() if game.has_method("_enemy_separation_interval") else 0.0
	if interval > 0.0:
		separation_accumulator += delta
		if separation_accumulator < interval:
			return
		separation_accumulator = fmod(separation_accumulator, interval)
	else:
		separation_accumulator = 0.0
	# The runtime builds this grid before projectile collision. Enemy movement is
	# bounded to a fraction of the 128 px cell size, so the same neighboring-cell
	# membership remains conservative for separation later in the frame.
	if not spatial_index_ready:
		rebuild_spatial_index()
	var count: int = spatial_entities.size()
	# As posicoes indexadas sao de antes do movimento deste quadro: atualiza.
	for k in range(count):
		spatial_positions[k] = spatial_entities[k]["pos"]
	var boss_blocks_entities: bool = game.boss_active and game.boss_hp > 0.0
	var local_player_targetable: bool = game._local_player_targetable()
	for i in range(count):
		var a: Dictionary = spatial_entities[i]
		if float(a.get("hp", 0.0)) <= 0.0:
			continue
		var pos_a := Vector2(a.get("pos", Vector2.ZERO))
		var r_a: float = spatial_physical_radii[i]

		if boss_blocks_entities:
			var min_boss_d: float = r_a + 64.0
			var d_boss_sq: float = pos_a.distance_squared_to(game.boss_pos)
			if d_boss_sq < min_boss_d * min_boss_d:
				var d_boss: float = sqrt(d_boss_sq)
				var push_b: Vector2 = (pos_a - game.boss_pos).normalized() if d_boss > 0.01 else Vector2.RIGHT.rotated(float(i))
				a["pos"] = (game.boss_pos + push_b * min_boss_d).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
				pos_a = Vector2(a["pos"])

		if local_player_targetable:
			var min_player_d: float = r_a + 24.0
			var d_player_sq: float = pos_a.distance_squared_to(game.player_pos)
			if d_player_sq < min_player_d * min_player_d:
				var d_player: float = sqrt(d_player_sq)
				var push_p: Vector2 = (pos_a - game.player_pos).normalized() if d_player > 0.01 else Vector2.UP.rotated(float(i))
				a["pos"] = (game.player_pos + push_p * min_player_d).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
				pos_a = Vector2(a["pos"])

		var search_radius: float = maxf(r_a + MAX_ENTITY_PHYSICAL_RADIUS, 50.0)
		# Pares j > i, celulas varridas direto (sem arrays intermediarios); posicoes
		# vivas ficam em spatial_positions e so os pares que se tocam escrevem no dict.
		spatial_positions[i] = pos_a
		var min_cell := _spatial_cell(pos_a - Vector2.ONE * search_radius)
		var max_cell := _spatial_cell(pos_a + Vector2.ONE * search_radius)
		for cell_y in range(min_cell.y, max_cell.y + 1):
			for cell_x in range(min_cell.x, max_cell.x + 1):
				var bucket = spatial_cells.get(Vector2i(cell_x, cell_y))
				if bucket == null:
					continue
				for raw_j in bucket:
					var j: int = raw_j
					if j <= i:
						continue
					var pos_b: Vector2 = spatial_positions[j]
					var r_b: float = spatial_physical_radii[j]
					var min_dist: float = r_a + r_b
					var dist_sq: float = pos_a.distance_squared_to(pos_b)
					if dist_sq >= min_dist * min_dist:
						continue
					var b: Dictionary = spatial_entities[j]
					if float(b.get("hp", 0.0)) <= 0.0:
						continue
					var dist: float = sqrt(dist_sq)
					var overlap: float = min_dist - dist
					var push_dir: Vector2 = (pos_a - pos_b) / dist if dist > 0.01 else Vector2.RIGHT.rotated(float(i * 3 + j * 7))
					var push_amount: Vector2 = push_dir * (maxf(overlap, 4.0) * 0.55)
					pos_a = (pos_a + push_amount).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
					pos_b = (pos_b - push_amount).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
					a["pos"] = pos_a
					b["pos"] = pos_b
					spatial_positions[i] = pos_a
					spatial_positions[j] = pos_b


func reset_special_pacing(clear_history: bool = false) -> void:
	if clear_history:
		horde.reset_run()
	special_last_spawn_phase_time = -1.0
	if clear_history:
		special_spawn_history.clear()


func prepare_phase_special_pacing() -> void:
	reset_special_pacing(false)


func _special_phase_profile(phase: int) -> Dictionary:
	return Dictionary(SPECIAL_SPAWN_PACING.get(phase, {}))


func _profile_time(profile: Dictionary, onboarding_key: String, experienced_key: String) -> float:
	if game != null and game._pacing_experienced_active():
		return float(profile.get(experienced_key, profile.get(onboarding_key, 0.0)))
	return float(profile.get(onboarding_key, 0.0))


func special_first_unlock_time(phase: int) -> float:
	var profile := _special_phase_profile(phase)
	return _profile_time(profile, "first_unlock", "experienced_first_unlock")


func special_repeat_gap(phase: int) -> float:
	var profile := _special_phase_profile(phase)
	return _profile_time(profile, "repeat_gap", "experienced_repeat_gap")


func special_kind_unlock_time(phase: int, kind: String) -> float:
	var profile := _special_phase_profile(phase)
	var onboarding_key := ""
	var experienced_key := ""
	if phase == 2:
		if kind == game.ENEMY_KAMIKAZE:
			onboarding_key = "kamikaze_unlock"
			experienced_key = "experienced_kamikaze_unlock"
		elif kind == game.ENEMY_PYRO_PENGUIN:
			onboarding_key = "pyro_unlock"
			experienced_key = "experienced_pyro_unlock"
	elif phase == 3:
		if kind == game.ENEMY_FLAGELANTE:
			onboarding_key = "flagelante_unlock"
			experienced_key = "experienced_flagelante_unlock"
		elif kind == game.ENEMY_INCENSARIO:
			onboarding_key = "incensario_unlock"
			experienced_key = "experienced_incensario_unlock"
		elif kind == game.ENEMY_SALMODIANTE:
			onboarding_key = "salmodiante_unlock"
			experienced_key = "experienced_salmodiante_unlock"
		elif kind == game.ENEMY_GUARDIAO:
			onboarding_key = "guardiao_unlock"
			experienced_key = "experienced_guardiao_unlock"
		elif kind == game.ENEMY_RELICARIO:
			onboarding_key = "relicario_unlock"
			experienced_key = "experienced_relicario_unlock"
	elif phase == 6:
		if kind == game.ENEMY_CHRONAL_LEECH:
			onboarding_key = "leech_unlock"
			experienced_key = "experienced_leech_unlock"
		elif kind == game.ENEMY_MIASMA_EEL:
			onboarding_key = "eel_unlock"
			experienced_key = "experienced_eel_unlock"
		elif kind == game.ENEMY_FOSSIL_PUSTULE:
			onboarding_key = "pustule_unlock"
			experienced_key = "experienced_pustule_unlock"
	if onboarding_key == "":
		return special_first_unlock_time(phase)
	return _profile_time(profile, onboarding_key, experienced_key)


func is_phase_special_kind(phase: int, kind: String) -> bool:
	match phase:
		2:
			return kind == game.ENEMY_KAMIKAZE or kind == game.ENEMY_PYRO_PENGUIN
		3:
			return kind in [game.ENEMY_DEVOTO, game.ENEMY_INCENSARIO, game.ENEMY_GUARDIAO, game.ENEMY_FLAGELANTE, game.ENEMY_SALMODIANTE, game.ENEMY_RELICARIO]
		4, 5:
			return kind in [game.ENEMY_NEXUS_CARTOGRAPHER, game.ENEMY_NEXUS_CHRONOPHAGE, game.ENEMY_NEXUS_REFRACTOR, game.ENEMY_NEXUS_WEAVER, game.ENEMY_NEXUS_ECHO]
		6:
			return kind == game.ENEMY_CHRONAL_LEECH or kind == game.ENEMY_MIASMA_EEL or kind == game.ENEMY_FOSSIL_PUSTULE
		7:
			return kind == game.ENEMY_PANGOLIRO or kind == game.ENEMY_CORVOL
	return false


func _special_spawn_due() -> bool:
	if game == null or game.current_phase < 2 or game.current_phase > 7:
		return false
	var elapsed: float = game._phase_elapsed_time()
	if elapsed < special_first_unlock_time(game.current_phase):
		return false
	if special_last_spawn_phase_time < 0.0:
		return true
	return elapsed - special_last_spawn_phase_time >= special_repeat_gap(game.current_phase)


func paced_special_type() -> String:
	if not _special_spawn_due():
		return ""
	var phase: int = game.current_phase
	var elapsed: float = game._phase_elapsed_time()
	match phase:
		2:
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_PYRO_PENGUIN) and game._enemy_type_count(game.ENEMY_PYRO_PENGUIN) < game.PHASE2_PYRO_LIMIT:
				return game.ENEMY_PYRO_PENGUIN
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_KAMIKAZE) and game._enemy_type_count(game.ENEMY_KAMIKAZE) < game.PHASE2_KAMIKAZE_LIMIT:
				return game.ENEMY_KAMIKAZE
		3:
			var candidates: Array[String] = []
			if elapsed >= special_first_unlock_time(phase) and game._enemy_type_count(game.ENEMY_DEVOTO) < 3:
				candidates.append(game.ENEMY_DEVOTO)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_FLAGELANTE) and game._enemy_type_count(game.ENEMY_FLAGELANTE) < 2:
				candidates.append(game.ENEMY_FLAGELANTE)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_INCENSARIO) and game._enemy_type_count(game.ENEMY_INCENSARIO) < 2:
				candidates.append(game.ENEMY_INCENSARIO)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_SALMODIANTE) and game._enemy_type_count(game.ENEMY_SALMODIANTE) < 2:
				candidates.append(game.ENEMY_SALMODIANTE)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_GUARDIAO) and game._enemy_type_count(game.ENEMY_GUARDIAO) < 1:
				candidates.append(game.ENEMY_GUARDIAO)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_RELICARIO) and game._enemy_type_count(game.ENEMY_RELICARIO) < 1:
				candidates.append(game.ENEMY_RELICARIO)
			if not candidates.is_empty():
				return candidates[game.rng.randi_range(0, candidates.size() - 1)]
		4, 5:
			var phase4_kind: String = game._choose_phase4_enemy_type()
			return phase4_kind if is_phase_special_kind(phase, phase4_kind) else ""
		6:
			var phase6_candidates: Array[String] = []
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_CHRONAL_LEECH) and game._enemy_type_count(game.ENEMY_CHRONAL_LEECH) < 2:
				phase6_candidates.append(game.ENEMY_CHRONAL_LEECH)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_MIASMA_EEL) and game._phase6_miasma_eel_count() < game._phase6_miasma_eel_cap():
				phase6_candidates.append(game.ENEMY_MIASMA_EEL)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_FOSSIL_PUSTULE) and not game._has_enemy_type(game.ENEMY_FOSSIL_PUSTULE):
				phase6_candidates.append(game.ENEMY_FOSSIL_PUSTULE)
			if not phase6_candidates.is_empty():
				return phase6_candidates[game.rng.randi_range(0, phase6_candidates.size() - 1)]
		7:
			if game._enemy_type_count(game.ENEMY_PANGOLIRO) < game.PHASE7_PANGOLIRO_LIMIT:
				return game.ENEMY_PANGOLIRO
			if game._enemy_type_count(game.ENEMY_CORVOL) < game.PHASE7_CORVOL_LIMIT:
				return game.ENEMY_CORVOL
	return ""


func record_special_spawn(kind: String) -> void:
	if game == null or not is_phase_special_kind(game.current_phase, kind):
		return
	var phase_time: float = game._phase_elapsed_time()
	special_last_spawn_phase_time = phase_time
	special_spawn_history.append({
		"phase": game.current_phase,
		"phase_time": phase_time,
		"run_time": game.time_alive,
		"kind": kind
	})


func special_spawn_report() -> Dictionary:
	var by_phase: Dictionary = {}
	for entry in special_spawn_history:
		var phase_key := str(int(entry.get("phase", 0)))
		if not by_phase.has(phase_key):
			by_phase[phase_key] = {"count": 0, "intervals": [], "kinds": {}}
		var phase_report: Dictionary = by_phase[phase_key]
		phase_report["count"] = int(phase_report.get("count", 0)) + 1
		var kind := String(entry.get("kind", ""))
		var kinds: Dictionary = phase_report.get("kinds", {})
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		phase_report["kinds"] = kinds
		var phase_entries: Array = special_spawn_history.filter(func(item): return int(item.get("phase", 0)) == int(entry.get("phase", 0)))
		if phase_entries.size() >= 2 and phase_entries[-1] == entry:
			var previous: Dictionary = phase_entries[-2]
			var intervals: Array = phase_report.get("intervals", [])
			intervals.append(maxf(0.0, float(entry.get("phase_time", 0.0)) - float(previous.get("phase_time", 0.0))))
			phase_report["intervals"] = intervals
		by_phase[phase_key] = phase_report
	return {"total": special_spawn_history.size(), "by_phase": by_phase}


func update(delta: float) -> void:
	if game == null:
		return
	horde.update(delta)
	if not game._is_world_authority() or game.spawn_timer > 0.0 or game.boss_active or game._tutorial_blocks_normal_spawn():
		return
	spawn_wave()


func update_enemies(delta: float) -> void:
	if game == null or not game._is_world_authority():
		return
	var cost_started := Time.get_ticks_usec()
	_update_enemies_body(delta)
	horde.note_update_cost(Time.get_ticks_usec() - cost_started)


func _update_enemies_body(delta: float) -> void:
	dead_enemy_buffer.clear()
	_refresh_phase2_common_shooters()
	var lacerante_secondary: Dictionary = game._active_lacerante_secondary()
	var lacerante_storm: bool = not lacerante_secondary.is_empty()
	var prismatica_active: bool = not game._active_prismatica_secondary().is_empty()
	var combat_targets: Array = game._combat_targets()
	var remote_target_peer_ids: Array[int] = game._targetable_remote_peer_ids()
	var phase1_boss_freeze: bool = game._phase1_boss_freezes_enemies()
	var lod_active: bool = game.enemies.size() >= horde.AI_LOD_MIN_CROWD
	lod_target_positions.clear()
	if lod_active:
		for target_value in combat_targets:
			lod_target_positions.append(Vector2(Dictionary(target_value).get("pos", game.player_pos)))
		if lod_target_positions.is_empty():
			lod_target_positions.append(game.player_pos)
	var enemy_index := -1
	var kind_common: String = game.ENEMY_COMMON
	var kind_kamikaze: String = game.ENEMY_KAMIKAZE
	var contact_blocked_kinds := {game.ENEMY_CHRONAL_LEECH: true, game.ENEMY_AMBER_SUTURE_NODE: true}
	var custom_move_kinds := {
		game.ENEMY_LODARIO: true, game.ENEMY_MIASMA_EEL: true, game.ENEMY_CHRONAL_LEECH: true,
		game.ENEMY_AMBER_SUTURER: true, game.ENEMY_AMBER_SUTURE_NODE: true,
		game.ENEMY_CINERIDO: true, game.ENEMY_PANGOLIRO: true, game.ENEMY_CORVOL: true,
		game.ENEMY_SINEIRO_BOREAL: true,
	}
	var bargain_capsule_vulnerable: bool = game._bargain_capsule_vulnerable()
	RTFrameProfiler.mark("e_setup")
	for enemy in game.enemies:
		enemy_index += 1
		# LOD de IA: longe de todos os alvos, atualiza em quadros alternados com o tempo acumulado.
		var enemy_delta: float = delta
		if lod_active:
			if horde.ai_lod_skip(enemy, enemy_index, lod_target_positions):
				enemy["lod_dt"] = float(enemy.get("lod_dt", 0.0)) + delta
				continue
			enemy_delta += float(enemy.get("lod_dt", 0.0))
			enemy["lod_dt"] = 0.0
		var kind := String(enemy.get("type", ""))
		if kind == game.ENEMY_FOSSIL_PUSTULE:
			enemy["phase"] = float(enemy.get("phase", 0.0)) + enemy_delta * 2.0
		else:
			enemy["phase"] = float(enemy.get("phase", 0.0)) + enemy_delta * 7.0
		if float(enemy.get("hit_cd", 0.0)) > 0.0:
			enemy["hit_cd"] = maxf(0.0, float(enemy["hit_cd"]) - enemy_delta)
		if float(enemy.get("contact_grace", 0.0)) > 0.0:
			enemy["contact_grace"] = maxf(0.0, float(enemy["contact_grace"]) - enemy_delta)
		if float(enemy.get("stun", 0.0)) > 0.0:
			enemy["stun"] = maxf(0.0, float(enemy["stun"]) - enemy_delta)
		if float(enemy.get("tesla_shock", 0.0)) > 0.0:
			enemy["tesla_shock"] = maxf(0.0, float(enemy["tesla_shock"]) - enemy_delta)
		if float(enemy.get("eletrica_static_timer", 0.0)) > 0.0:
			enemy["eletrica_static_timer"] = maxf(0.0, float(enemy.get("eletrica_static_timer", 0.0)) - enemy_delta)
			if float(enemy["eletrica_static_timer"]) <= 0.0:
				enemy["eletrica_static_stacks"] = 0
				enemy["eletrica_static_last_source"] = ""
		for timer_key in PASSIVE_TIMER_KEYS:
			var timer_value := float(enemy.get(timer_key, 0.0))
			if timer_value > 0.0:
				enemy[timer_key] = maxf(0.0, timer_value - enemy_delta)
		var evolution_slow := float(enemy.get("evolution_slow", 0.0))
		if evolution_slow > 0.0:
			evolution_slow = maxf(0.0, evolution_slow - enemy_delta)
			enemy["evolution_slow"] = evolution_slow
			if evolution_slow <= 0.0:
				enemy["evolution_slow_mult"] = 1.0
		var fragilidade_cronal := float(enemy.get("fragilidade_cronal", 0.0))
		if fragilidade_cronal > 0.0:
			fragilidade_cronal = maxf(0.0, fragilidade_cronal - enemy_delta)
			enemy["fragilidade_cronal"] = fragilidade_cronal
			if fragilidade_cronal <= 0.0:
				enemy["fragilidade_cronal_bonus"] = 0.0
		game._update_shield_reflector(enemy, enemy_delta)
		game._update_enemy_dots(enemy, enemy_delta)
		if float(enemy.get("hp", 0.0)) <= 0.0:
			dead_enemy_buffer.append(enemy)
			continue
		if phase1_boss_freeze:
			continue
		# Plain commons (most of the horde) have no per-kind update.
		if kind != kind_common:
			if kind == game.ENEMY_CURATER:
				game._update_curater(enemy, enemy_delta)
			if kind == game.ENEMY_STALKER:
				game._update_stalker(enemy, enemy_delta)
			if kind == game.ENEMY_PROJECTOR:
				game._update_projector(enemy, enemy_delta)
			if kind == game.ENEMY_ATIRADOR:
				game._update_atirador(enemy, enemy_delta)
			if kind == game.ENEMY_KAMIKAZE:
				game._update_kamikaze(enemy, enemy_delta)
			if kind == game.ENEMY_LARAPIO:
				game._update_larapio(enemy, enemy_delta)
			if kind == game.ENEMY_FOSSIL_PUSTULE and game._update_fossil_pustule(enemy, enemy_delta):
				dead_enemy_buffer.append(enemy)
				continue
			if kind == game.ENEMY_LODARIO:
				game._update_lodario(enemy, enemy_delta)
			if kind == game.ENEMY_MIASMA_EEL:
				game._update_miasma_eel(enemy, enemy_delta)
			if kind == game.ENEMY_CHRONAL_LEECH:
				if game._update_sanguessuga_cronal(enemy, enemy_delta):
					dead_enemy_buffer.append(enemy)
					continue
			if kind == game.ENEMY_AMBER_SUTURER:
				game.amber_suturer_controller.update_enemy(enemy, enemy_delta)
			if kind == game.ENEMY_AMBER_SUTURE_NODE:
				game.amber_suturer_controller.update_node(enemy, enemy_delta)
			if kind == game.ENEMY_CINERIDO:
				game._update_cinerido(enemy, enemy_delta)
			if kind == game.ENEMY_PANGOLIRO:
				game._update_pangoliro(enemy, enemy_delta)
			if kind == game.ENEMY_CORVOL:
				game._update_corvol(enemy, enemy_delta)
			if kind == game.ENEMY_COUT_ATTACK_SPEED:
				game._update_cout_attack_speed(enemy, enemy_delta)
			if kind == game.ENEMY_PYRO_PENGUIN:
				game._update_pyro_penguin(enemy, enemy_delta)
			if kind == game.ENEMY_SINEIRO_BOREAL:
				game.sineiro_boreal_controller.update_enemy(enemy, enemy_delta)
		if game.current_phase == 2 and kind == game.ENEMY_COMMON:
			game._update_phase2_common_penguin(enemy, enemy_delta)
		if game.current_phase == 3:
			game._update_phase3_enemy(enemy, enemy_delta)
		elif game.current_phase == 4:
			game._update_phase4_enemy(enemy, enemy_delta)
		var custom_move: bool = custom_move_kinds.has(kind)
		if not custom_move and float(enemy.get("stun", 0.0)) <= 0.0 and float(enemy.get("ferrolho_root", 0.0)) <= 0.0 and (not bool(enemy.get("parado", false)) or prismatica_active):
			game._move_enemy(enemy, enemy_delta, lacerante_secondary, prismatica_active, combat_targets)

		var t_pos: Vector2 = game._get_nearest_player_pos(Vector2(enemy["pos"]), combat_targets) if kind == kind_kamikaze else Vector2.ZERO
		if not lacerante_storm and kind == kind_kamikaze and Vector2(enemy["pos"]).distance_to(t_pos) < 60.0:
			if game._target_pos_is_local_player(t_pos):
				game._damage_player(game.player_hp_max * 0.15, game.ENEMY_KAMIKAZE)
				if not game._player_invulnerable():
					game.player_stun_timer = game._hostile_control_duration(1.0)
					game._add_text("CONGELADO!", game.player_pos + Vector2(0, -40), Color(0.0, 0.88, 1.0), 1.5, 20)
					game._spawn_radial_particles(Vector2(enemy["pos"]), Color(0.6, 0.9, 1.0), 16)
			else:
				var kamikaze_peer: int = game._peer_id_at_target_pos(t_pos)
				if kamikaze_peer != 0:
					game._send_peer_damage(kamikaze_peer, int(game.player_hp_max * 0.15), game.ENEMY_KAMIKAZE)
			enemy["hp"] = -1.0
			continue

		var contact_blocked: bool = contact_blocked_kinds.has(kind)
		if not lacerante_storm and not contact_blocked and not bool(enemy.get("invisible", false)) and float(enemy.get("hit_cd", 0.0)) <= 0.0:
			if bargain_capsule_vulnerable and game._try_damage_bargain_capsule_contact(enemy):
				enemy["hit_cd"] = 0.55
			else:
				var enemy_pos := Vector2(enemy.get("pos", game.player_pos))
				if enemy_pos.distance_squared_to(game.player_pos) < 46.0 * 46.0 and game._local_player_damageable_by_contact():
					enemy["hit_cd"] = 0.55
					game._damage_player(game._enemy_damage(enemy), enemy["type"])
				else:
					for peer_id in remote_target_peer_ids:
						var remote_state: Dictionary = game.net_players_by_peer.get(peer_id, {})
						if enemy_pos.distance_squared_to(Vector2(remote_state.get("pos", Vector2(-10000, -10000)))) < 46.0 * 46.0:
							enemy["hit_cd"] = 0.55
							game._send_peer_damage(peer_id, game._enemy_damage(enemy), kind)
							break

	RTFrameProfiler.mark("e_contact_tail")
	for enemy in dead_enemy_buffer:
		game._kill_enemy(enemy)
	RTFrameProfiler.mark("e_kills")


func _refresh_phase2_common_shooters() -> void:
	phase2_common_uid_buffer.clear()
	phase2_common_shooter_uids.clear()
	if game == null or game.current_phase != 2:
		return
	for candidate in game.enemies:
		if String(candidate.get("type", "")) == game.ENEMY_COMMON and float(candidate.get("hp", 0.0)) > 0.0:
			phase2_common_uid_buffer.append(int(candidate.get("uid", 0)))
	phase2_common_uid_buffer.sort()
	if phase2_common_uid_buffer.size() <= 2:
		for uid in phase2_common_uid_buffer:
			phase2_common_shooter_uids[uid] = true
		return
	var group_count: int = int(ceil(float(phase2_common_uid_buffer.size()) / 2.0))
	var cycle: int = int(floor(game._phase_elapsed_time() / 2.35)) % maxi(1, group_count)
	var start_index: int = cycle * 2
	var end_index: int = mini(start_index + 2, phase2_common_uid_buffer.size())
	for index in range(start_index, end_index):
		phase2_common_shooter_uids[phase2_common_uid_buffer[index]] = true


func phase2_common_penguin_can_shoot(enemy: Dictionary) -> bool:
	if game == null or game.current_phase != 2 or String(enemy.get("type", "")) != game.ENEMY_COMMON:
		return true
	return phase2_common_shooter_uids.has(int(enemy.get("uid", 0)))


func spawn_wave() -> void:
	if game == null or not game._is_world_authority():
		return
	game.spawn_timer = horde.spawn_interval(get_enemy_spawn_interval())
	if game.boss_active or game._arauto_active():
		return
	var desired: int = get_desired_enemy_limit()
	var limit: int = horde.clamp_limit(desired)
	var ratio: float = horde.overflow_ratio(desired)
	for _spawn in range(horde.spawns_this_tick(limit, game.enemies.size())):
		var before: int = game.enemies.size()
		var kind = game._choose_enemy_type()
		game._spawn_enemy(kind, game._spawn_point_for_type(kind))
		if game.enemies.size() > before:
			horde.apply_overflow(game.enemies.back(), ratio)


## Limite efetivo de inimigos vivos: o desejado (que cresce sem fim) preso ao orcamento do aparelho.
func get_enemy_limit(native_only: bool = false) -> int:
	if native_only:
		return get_desired_enemy_limit(true)
	return horde.clamp_limit(get_desired_enemy_limit())


func get_desired_enemy_limit(native_only: bool = false) -> int:
	var mp_bonus: int = game._multiplayer_enemy_limit_bonus()
	var native_limit: int = 0
	if game.current_phase == 7:
		native_limit = _phase7_enemy_limit() + mp_bonus
	elif game.current_phase == 6:
		native_limit = _phase6_enemy_limit() + mp_bonus
	elif game.current_phase == 5:
		native_limit = 5 + mp_bonus
	elif game.current_phase == 4:
		native_limit = (game.PHASE4_LIMIT_EARLY if game._phase_elapsed_time() < game._phase4_adapt_time() else game.PHASE4_LIMIT_FULL) + mp_bonus
	elif game.current_phase == 3:
		var elapsed3: float = game._phase_elapsed_time()
		native_limit = (game.PHASE3_LIMIT_EARLY if elapsed3 < game._phase3_common_only_time() else (game.PHASE3_LIMIT_MID if elapsed3 < game._phase3_guardiao_unlock_time() else game.PHASE3_LIMIT_FULL)) + mp_bonus
	elif game.current_phase == 2:
		var elapsed: float = game._phase_elapsed_time()
		native_limit = game.PHASE2_COMMON_LIMIT + (game.PHASE2_KAMIKAZE_LIMIT if elapsed >= game._phase2_kamikaze_unlock_time() else 0) + (game.PHASE2_PYRO_LIMIT if elapsed >= game._phase2_pyro_unlock_time() else 0) + mp_bonus
	else:
		var elapsed1: float = game._phase_elapsed_time()
		if elapsed1 >= game.PHASE1_LIMIT_BREAK_TIME:
			if game.phase1_limit_break_kills_start < 0:
				game.phase1_limit_break_kills_start = game.enemies_killed
			var kills_after_break = max(0, game.enemies_killed - game.phase1_limit_break_kills_start)
			native_limit = game.ENEMY_MAX_BASE + int(floor(float(kills_after_break) / float(game.PHASE1_LIMIT_KILLS_PER_EXTRA))) + mp_bonus
		else:
			game.phase1_limit_break_kills_start = -1
			native_limit = game.ENEMY_MAX_BASE + mp_bonus
	native_limit += maxi(game._long_run_enemy_limit_bonus(), horde.extra_enemies())
	if native_only or game.current_phase <= 1 or phase_density_carry_cap <= 0:
		return native_limit
	var growth_after_entry: int = maxi(0, native_limit - phase_density_native_entry_cap)
	return phase_density_carry_cap + growth_after_entry


func prepare_phase_density_carry(previous_effective_cap: int) -> void:
	if game == null or game.current_phase <= 1:
		phase_density_carry_cap = 0
		phase_density_native_entry_cap = 0
		return
	phase_density_carry_cap = maxi(1, int(floor(float(maxi(1, previous_effective_cap)) * PHASE_DENSITY_CARRY_RATIO)))
	phase_density_native_entry_cap = get_enemy_limit(true)


func get_enemy_spawn_interval() -> float:
	if game.current_phase == 7:
		return _phase7_spawn_interval()
	if game.current_phase == 6:
		return _phase6_spawn_interval()
	if game.current_phase == 5:
		return _long_run_spawn_interval(1.1)
	if game.current_phase == 4:
		return _long_run_spawn_interval(1.42 if game._phase_elapsed_time() < game._phase4_adapt_time() else 1.24)
	var interval = game.ENEMY_SPAWN_INTERVAL
	if game.current_phase == 3:
		var elapsed3: float = game._phase_elapsed_time()
		interval = 1.3 if elapsed3 < game._phase3_common_only_time() else (1.16 if elapsed3 < game._phase3_guardiao_unlock_time() else 1.02)
		interval = _long_run_spawn_interval(interval)
		if not game._active_prismatica_secondary().is_empty():
			interval *= 0.5
		return interval
	if game.current_phase == 2:
		var elapsed: float = game._phase_elapsed_time()
		interval = 1.32 if elapsed < game._phase2_kamikaze_unlock_time() else (1.12 if elapsed < game._phase2_pyro_unlock_time() else 0.98)
		interval = _long_run_spawn_interval(interval)
		if not game._active_prismatica_secondary().is_empty():
			interval *= 0.5
		return interval
	if game.current_phase != 2:
		var ramp_window = max(1.0, game.ENEMY_RAMP_PEAK_TIME - game.ENEMY_RAMP_START_TIME)
		var progress = clamp((game._phase_elapsed_time() - game.ENEMY_RAMP_START_TIME) / ramp_window, 0.0, 1.0)
		interval = lerp(game.ENEMY_SPAWN_INTERVAL_EARLY, game.ENEMY_SPAWN_INTERVAL_LATE, progress)
	interval = _long_run_spawn_interval(interval)
	if not game._active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval


func _long_run_spawn_interval(interval: float) -> float:
	return maxf(0.36, interval * game._long_run_spawn_interval_multiplier())


func get_curater_limit() -> int:
	return 3 if game._phase_elapsed_time() < 1500.0 else 5


func _phase6_enemy_limit() -> int:
	var elapsed: float = game._phase_elapsed_time()
	if elapsed >= game.PHASE1_LIMIT_BREAK_TIME:
		if game.phase1_limit_break_kills_start < 0:
			game.phase1_limit_break_kills_start = game.enemies_killed
		var kills_after_break = max(0, game.enemies_killed - game.phase1_limit_break_kills_start)
		return game.ENEMY_MAX_BASE + int(floor(float(kills_after_break) / float(game.PHASE1_LIMIT_KILLS_PER_EXTRA)))
	game.phase1_limit_break_kills_start = -1
	return game.ENEMY_MAX_BASE


func _phase7_enemy_limit() -> int:
	var elapsed: float = game._phase_elapsed_time()
	if elapsed >= game.PHASE7_LIMIT_BREAK_TIME:
		if game.phase1_limit_break_kills_start < 0:
			game.phase1_limit_break_kills_start = game.enemies_killed
		var kills_after_break = max(0, game.enemies_killed - game.phase1_limit_break_kills_start)
		return game.PHASE7_ENEMY_LIMIT_BASE + int(floor(float(kills_after_break) / float(game.PHASE7_LIMIT_KILLS_PER_EXTRA)))
	game.phase1_limit_break_kills_start = -1
	return game.PHASE7_ENEMY_LIMIT_BASE


func _phase6_spawn_interval() -> float:
	var ramp_window = max(1.0, game.ENEMY_RAMP_PEAK_TIME - game.ENEMY_RAMP_START_TIME)
	var progress = clamp((game._phase_elapsed_time() - game.ENEMY_RAMP_START_TIME) / ramp_window, 0.0, 1.0)
	var interval = _long_run_spawn_interval(lerp(game.ENEMY_SPAWN_INTERVAL_EARLY, game.ENEMY_SPAWN_INTERVAL_LATE, progress))
	if not game._active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval


func _phase7_spawn_interval() -> float:
	var progress: float = clampf(game._phase_elapsed_time() / 300.0, 0.0, 1.0)
	var interval: float = _long_run_spawn_interval(lerpf(1.22, 0.92, progress))
	if not game._active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval
