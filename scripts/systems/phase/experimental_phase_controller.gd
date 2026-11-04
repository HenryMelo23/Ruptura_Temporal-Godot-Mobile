class_name RTExperimentalPhaseController
extends RefCounted

const BASE_WORLD_SIZE := Vector2(1600.0, 900.0)
const EXPERIMENTAL_WORLD_SIZE := Vector2(3200.0, 2250.0)
const AREA_MULTIPLIER := 5.0
const CHUNK_SIZE := 384.0
const ATLAS_COLUMNS := 4
const ALTAR_TILE := 5
const TERRAIN_ATLAS_PATH := "res://assets/sprites/experimental/phase_ex_terrain_atlas.png"
const PHASES := {
	1: {"label": "FASE EX", "region": "RUINAS COSMICAS", "map_key": "map_phase_ex", "altar": "ALTAR DO CRONOGUEJO", "altar_uv": Vector2(0.5, 0.5)},
	2: {"label": "FASE EX2", "region": "FENDA GLACIAL", "map_key": "map_phase_ex2", "altar": "ALTAR DA SENTINELA GLACIAL", "altar_uv": Vector2(0.49, 0.35)},
	3: {"label": "FASE EX3", "region": "CATEDRAL DO ESGOTO", "map_key": "map_phase_ex3", "altar": "ALTAR DO PAI-RATO", "altar_uv": Vector2(0.5, 0.5)},
	4: {"label": "FASE EX4", "region": "CORACAO DO NEXO", "map_key": "map_phase_ex4", "altar": "ALTAR DO NEXO ANFIBIO", "altar_uv": Vector2(0.5, 0.5)},
	5: {"label": "FASE EX5", "region": "MENTE DA UMBRA", "map_key": "map_phase_ex5", "altar": "SELO DA UMBRA", "altar_uv": Vector2(0.5, 0.5)},
	6: {"label": "FASE EX6", "region": "CHAGA DE AMBAR", "map_key": "map_phase_ex6", "altar": "NINHO DA MATRIARCA DA CHAGA", "altar_uv": Vector2(0.5, 0.5)},
	7: {"label": "FASE EX7", "region": "CINZAS DA RUPTURA", "map_key": "map_phase_ex7", "altar": "CLAREIRA DA FENIX", "altar_uv": Vector2(0.5, 0.5)},
}
const ALTAR_INTERACTION_RADIUS := 118.0
const ALTAR_HOLD_TIME := 1.15
const ALTAR_WORLD_MARGIN := Vector2(300.0, 250.0)
const ALTAR_MIN_START_DISTANCE := 1180.0
const ENEMY_SPAWN_MIN_DISTANCE := 620.0
const ENEMY_SPAWN_MAX_DISTANCE := 860.0

var core: Node
var requested_phase: int = 1
var active_phase: int = 1
var landmarks: Array[Dictionary] = []
var route_points: Array[Vector2] = []


func configure(p_core: Node) -> void:
	core = p_core


func arm_phase(phase: int) -> void:
	assert(PHASES.has(phase))
	core.experimental_phase_requested = not (core.experimental_phase_requested and requested_phase == phase)
	requested_phase = phase if core.experimental_phase_requested else 1


func phase_label(phase: int = -1) -> String:
	return String(PHASES[active_phase if phase < 0 else phase]["label"])


func uses_definitive_world() -> bool:
	return not core.experimental_phase_active and PHASES.has(core.current_phase)


func terrain_phase() -> int:
	return int(core.current_phase) if uses_definitive_world() else active_phase


func map_key() -> String:
	var phase := terrain_phase()
	if phase == 5:
		var dimension_phase: int = {"vortice": 1, "gravidade": 2, "necrose": 3, "ressonancia": 4, "hemorragia": 6, "atrito": 7, "rastro": 3}.get(String(core.boss5_dimension), 5)
		return String(PHASES[dimension_phase]["map_key"])
	return String(PHASES[phase]["map_key"])


func altar_source_center() -> Vector2:
	return Vector2(PHASES[terrain_phase()]["altar_uv"])


func altar_label() -> String:
	return String(PHASES[terrain_phase()]["altar"])


func prepare_new_run(clear_interrupted_save: bool) -> void:
	var requested := clear_interrupted_save and bool(core.experimental_phase_requested)
	core.experimental_phase_rejected_online = requested and (core.is_multiplayer or core.dedicated_server_mode or core.online_connected)
	core.experimental_phase_active = requested and not core.experimental_phase_rejected_online
	active_phase = requested_phase if core.experimental_phase_active and PHASES.has(requested_phase) else 1
	requested_phase = 1
	core.experimental_phase_requested = false
	core.WORLD_SIZE = core.DEFAULT_WORLD_SIZE if core.experimental_phase_active else EXPERIMENTAL_WORLD_SIZE
	_reset_altar_state()


func _reset_altar_state() -> void:
	core.experimental_boss_altar_pos = Vector2.ZERO
	core.experimental_boss_altar_hold = 0.0
	core.experimental_boss_altar_near = false
	core.experimental_boss_altar_discovered = false
	core.experimental_boss_altar_used = false
	core.experimental_boss_altar_authorized = false
	landmarks.clear()
	route_points.clear()


func begin_definitive_phase(phase: int) -> void:
	if core.experimental_phase_active or not PHASES.has(phase):
		return
	active_phase = phase
	core.WORLD_SIZE = EXPERIMENTAL_WORLD_SIZE
	_reset_altar_state()
	core.experimental_boss_altar_pos = _roll_altar_position()
	_build_layout()
	core.boss_ready = true
	core.boss_pos = core.experimental_boss_altar_pos + Vector2(-230.0, -40.0)
	if phase == 4:
		core.boss4_entry_target = core.experimental_boss_altar_pos


func restore_after_snapshot() -> void:
	if core.experimental_phase_active:
		core.WORLD_SIZE = core.DEFAULT_WORLD_SIZE
		return
	active_phase = int(core.current_phase)
	core.WORLD_SIZE = EXPERIMENTAL_WORLD_SIZE
	if core.experimental_boss_altar_pos == Vector2.ZERO:
		core.experimental_boss_altar_pos = _roll_altar_position()
	landmarks.clear()
	route_points.clear()
	_build_layout()
	if core.current_phase == 4:
		core.boss4_entry_target = core.experimental_boss_altar_pos


func activate_after_phase_setup() -> void:
	if core.experimental_phase_rejected_online:
		core._add_text("FASE EX DISPONIVEL APENAS EM SOLO", core.player_pos + Vector2(0.0, -112.0), Color(1.0, 0.54, 0.24), 2.4, 22)
		core.experimental_phase_rejected_online = false
	if core.experimental_phase_active:
		core.current_phase = active_phase
		core.WORLD_SIZE = core.DEFAULT_WORLD_SIZE
		core._add_text("%s: MAPA CLASSICO" % phase_label(), core.player_pos + Vector2(0.0, -112.0), Color(0.34, 0.94, 1.0), 2.8, 27)
		return
	begin_definitive_phase(core.current_phase)
	core._add_text("FASE %d: %s" % [active_phase, PHASES[active_phase]["region"]], core.player_pos + Vector2(0.0, -112.0), Color(0.34, 0.94, 1.0), 2.8, 27)
	core._add_text("MAPA EXPANDIDO 5X", core.player_pos + Vector2(0.0, -150.0), Color(1.0, 0.76, 0.28), 2.3, 20)


func update(delta: float) -> void:
	if not uses_definitive_world():
		return
	if core.mode != "game" or core.boss_active or core.boss_dead or core.boss_call_timer >= 0.0 or core.experimental_boss_altar_used:
		core.experimental_boss_altar_hold = 0.0
		core.experimental_boss_altar_near = false
		return
	core.boss_ready = true
	if not core.experimental_boss_altar_discovered and _altar_visible_on_screen():
		core.experimental_boss_altar_discovered = true
		core._add_text("ALTAR DESCOBERTO", core.experimental_boss_altar_pos + Vector2(0.0, -194.0), Color(1.0, 0.72, 0.22), 1.35, 22)
	var distance: float = Vector2(core.player_pos).distance_to(Vector2(core.experimental_boss_altar_pos))
	var was_near: bool = bool(core.experimental_boss_altar_near)
	core.experimental_boss_altar_near = distance <= ALTAR_INTERACTION_RADIUS
	if not core.experimental_boss_altar_near:
		core.experimental_boss_altar_hold = maxf(0.0, core.experimental_boss_altar_hold - delta * 2.5)
		return
	if core._arauto_active():
		core.experimental_boss_altar_hold = 0.0
		return
	core.experimental_boss_altar_hold = minf(ALTAR_HOLD_TIME, core.experimental_boss_altar_hold + delta)
	if core.experimental_boss_altar_hold < ALTAR_HOLD_TIME:
		return
	core.experimental_boss_altar_used = true
	core.experimental_boss_altar_authorized = true
	core._start_boss_call()
	if not core.is_multiplayer:
		core.experimental_boss_altar_authorized = false


func boss_call_allowed() -> bool:
	var processing_remote_call: bool = bool(core.is_multiplayer) and int(core.multiplayer.get_remote_sender_id()) != 0
	return not uses_definitive_world() or core.experimental_boss_altar_authorized or processing_remote_call


func should_show_boss_button() -> bool:
	return not uses_definitive_world()


func can_persist_run() -> bool:
	return not core.experimental_phase_active


func boss_encounter_center() -> Vector2:
	if uses_definitive_world():
		return Vector2(core.experimental_boss_altar_pos)
	return Vector2(core.WORLD_SIZE) * 0.5


func boss7_entry_target() -> Vector2:
	return boss_encounter_center() + (Vector2.ZERO if uses_definitive_world() and terrain_phase() == 7 else Vector2(0, -72))

func boss2_wind_center() -> Vector2:
	if uses_definitive_world() and terrain_phase() == 2:
		return Vector2(core.boss2_ultimate_center) if core.boss2_ultimate_timer > 0.0 else boss_encounter_center()
	return Vector2(core.WORLD_SIZE) * 0.5


func boss_encounter_rect() -> Rect2:
	var world_size := Vector2(core.WORLD_SIZE)
	var encounter_size := Vector2(
		minf(BASE_WORLD_SIZE.x, world_size.x),
		minf(BASE_WORLD_SIZE.y, world_size.y)
	)
	if not uses_definitive_world():
		return Rect2(Vector2.ZERO, world_size)
	var max_origin := world_size - encounter_size
	var origin := (boss_encounter_center() - encounter_size * 0.5).clamp(Vector2.ZERO, max_origin)
	return Rect2(origin, encounter_size)


func clamp_to_boss_encounter(position: Vector2, margin: Vector2 = Vector2.ZERO) -> Vector2:
	var encounter := boss_encounter_rect()
	var minimum := encounter.position + margin
	var maximum := encounter.end - margin
	return position.clamp(minimum, maximum)


func terrain_chunks(camera: Vector2, viewport: Vector2) -> Array[Dictionary]:
	var chunks: Array[Dictionary] = []
	if not uses_definitive_world():
		return chunks
	# Integer world cells keep the artwork stable through camera movement/shake.
	var first := Vector2i((camera / CHUNK_SIZE).floor())
	var last := Vector2i(((camera + viewport) / CHUNK_SIZE).floor())
	var altar_cell := Vector2i((Vector2(core.experimental_boss_altar_pos) / CHUNK_SIZE).floor())
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell := Vector2i(x, y)
			# Coprime strides avoid adjacent duplicates, excluding the unique altar.
			var tile := posmod(x * 7 + y * 11 + floori(float(y) / 3.0) * 4, 15)
			if tile >= ALTAR_TILE:
				tile += 1
			if cell == altar_cell:
				tile = ALTAR_TILE
			chunks.append({"rect": Rect2(Vector2(cell) * CHUNK_SIZE - camera, Vector2.ONE * CHUNK_SIZE), "tile": tile})
	return chunks


func altar_progress() -> float:
	return clampf(core.experimental_boss_altar_hold / ALTAR_HOLD_TIME, 0.0, 1.0)


func altar_visible_on_screen(camera: Vector2, viewport: Vector2) -> bool:
	var screen_pos: Vector2 = Vector2(core.experimental_boss_altar_pos) - camera
	return Rect2(Vector2(-112.0, -112.0), viewport + Vector2(224.0, 224.0)).has_point(screen_pos)


func _altar_visible_on_screen() -> bool:
	var viewport: Vector2 = core.get_viewport_rect().size
	return altar_visible_on_screen(core._camera(viewport), viewport)


func _roll_altar_position() -> Vector2:
	var roll_rng: RandomNumberGenerator = core.rng
	if core.is_multiplayer or core.dedicated_server_mode or core.online_connected:
		roll_rng = RandomNumberGenerator.new()
		roll_rng.seed = 0xE6A2026 + int(active_phase) * 7919
	var minimum := ALTAR_WORLD_MARGIN
	var maximum := EXPERIMENTAL_WORLD_SIZE - ALTAR_WORLD_MARGIN
	var first_cell := Vector2i(((minimum - Vector2.ONE * CHUNK_SIZE * 0.5) / CHUNK_SIZE).ceil())
	var last_cell := Vector2i(((maximum - Vector2.ONE * CHUNK_SIZE * 0.5) / CHUNK_SIZE).floor())
	var best := Vector2(last_cell) * CHUNK_SIZE + Vector2.ONE * CHUNK_SIZE * 0.5
	var best_distance := best.distance_to(core.PLAYER_START)
	for _attempt in range(18):
		var cell := Vector2(roll_rng.randi_range(first_cell.x, last_cell.x), roll_rng.randi_range(first_cell.y, last_cell.y))
		var candidate := (cell + Vector2.ONE * 0.5) * CHUNK_SIZE
		var distance := candidate.distance_to(core.PLAYER_START)
		if distance > best_distance:
			best = candidate
			best_distance = distance
		if distance >= ALTAR_MIN_START_DISTANCE:
			return candidate
	return best


func enemy_spawn_point() -> Vector2:
	var margin := Vector2(52.0, 52.0)
	var best: Vector2 = Vector2(core.player_pos)
	var best_distance := 0.0
	for _attempt in range(10):
		var angle: float = core.rng.randf_range(0.0, TAU)
		var distance: float = core.rng.randf_range(ENEMY_SPAWN_MIN_DISTANCE, ENEMY_SPAWN_MAX_DISTANCE)
		var candidate: Vector2 = (core.player_pos + Vector2.from_angle(angle) * distance).clamp(margin, core.WORLD_SIZE - margin)
		var actual_distance: float = candidate.distance_to(core.player_pos)
		if actual_distance > best_distance:
			best = candidate
			best_distance = actual_distance
		if actual_distance >= ENEMY_SPAWN_MIN_DISTANCE * 0.82:
			return candidate
	return best


func _build_layout() -> void:
	route_points = [
		core.PLAYER_START,
		core.experimental_boss_altar_pos,
	]
	var layout_rng := RandomNumberGenerator.new()
	layout_rng.seed = 0xF45E2026
	for index in range(46):
		var position := Vector2(
			layout_rng.randf_range(150.0, EXPERIMENTAL_WORLD_SIZE.x - 150.0),
			layout_rng.randf_range(130.0, EXPERIMENTAL_WORLD_SIZE.y - 130.0)
		)
		if position.distance_to(core.PLAYER_START) < 260.0 or position.distance_to(route_points[-1]) < 230.0:
			continue
		landmarks.append({
			"pos": position,
			"kind": index % 4,
			"scale": layout_rng.randf_range(0.72, 1.28),
			"phase": layout_rng.randf_range(0.0, TAU),
		})
