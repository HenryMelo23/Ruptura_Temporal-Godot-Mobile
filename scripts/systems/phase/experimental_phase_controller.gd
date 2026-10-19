class_name RTExperimentalPhaseController
extends RefCounted

const BASE_WORLD_SIZE := Vector2(1600.0, 900.0)
const EXPERIMENTAL_WORLD_SIZE := Vector2(3200.0, 2250.0)
const AREA_MULTIPLIER := 5.0
const ALTAR_INTERACTION_RADIUS := 118.0
const ALTAR_HOLD_TIME := 1.15
const ALTAR_WORLD_MARGIN := Vector2(300.0, 250.0)
const ALTAR_MIN_START_DISTANCE := 1180.0
const ENEMY_SPAWN_MIN_DISTANCE := 620.0
const ENEMY_SPAWN_MAX_DISTANCE := 860.0

var core: Node
var landmarks: Array[Dictionary] = []
var route_points: Array[Vector2] = []


func configure(p_core: Node) -> void:
	core = p_core


func prepare_new_run(clear_interrupted_save: bool) -> void:
	var requested := clear_interrupted_save and bool(core.experimental_phase_requested)
	core.experimental_phase_rejected_online = requested and (core.is_multiplayer or core.dedicated_server_mode or core.online_connected)
	core.experimental_phase_active = requested and not core.experimental_phase_rejected_online
	core.experimental_phase_requested = false
	core.WORLD_SIZE = EXPERIMENTAL_WORLD_SIZE if core.experimental_phase_active else core.DEFAULT_WORLD_SIZE
	core.experimental_boss_altar_pos = Vector2.ZERO
	core.experimental_boss_altar_hold = 0.0
	core.experimental_boss_altar_near = false
	core.experimental_boss_altar_discovered = false
	core.experimental_boss_altar_used = false
	core.experimental_boss_altar_authorized = false
	landmarks.clear()
	route_points.clear()
	if core.experimental_phase_active:
		core.experimental_boss_altar_pos = _roll_altar_position()
		_build_layout()


func activate_after_phase_setup() -> void:
	if core.experimental_phase_rejected_online:
		core._add_text("FASE EX DISPONIVEL APENAS EM SOLO", core.player_pos + Vector2(0.0, -112.0), Color(1.0, 0.54, 0.24), 2.4, 22)
		core.experimental_phase_rejected_online = false
		return
	if not core.experimental_phase_active:
		return
	core.current_phase = 1
	core.boss_ready = true
	core.boss_pos = core.experimental_boss_altar_pos + Vector2(-230.0, -40.0)
	core._add_text("FASE EX: EXPLORE AS RUINAS", core.player_pos + Vector2(0.0, -112.0), Color(0.34, 0.94, 1.0), 2.8, 27)
	core._add_text("MAPA EXPERIMENTAL 5X", core.player_pos + Vector2(0.0, -150.0), Color(1.0, 0.76, 0.28), 2.3, 20)


func update(delta: float) -> void:
	if not core.experimental_phase_active:
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
	core._start_boss_call_local()
	core.experimental_boss_altar_authorized = false


func boss_call_allowed() -> bool:
	return not core.experimental_phase_active or core.experimental_boss_altar_authorized


func should_show_boss_button() -> bool:
	return not core.experimental_phase_active


func can_persist_run() -> bool:
	return not core.experimental_phase_active


func map_tile_rects(camera: Vector2) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if not core.experimental_phase_active:
		return rects
	var overscan: Vector2 = core._map_camera_overscan(core.get_viewport_rect().size)
	# One world-anchored tiled surface keeps the pattern continuous across the
	# whole experimental arena instead of restarting UVs at district borders.
	rects.append(Rect2(-camera - overscan, core.WORLD_SIZE + overscan * 2.0))
	return rects


func altar_progress() -> float:
	return clampf(core.experimental_boss_altar_hold / ALTAR_HOLD_TIME, 0.0, 1.0)


func altar_visible_on_screen(camera: Vector2, viewport: Vector2) -> bool:
	var screen_pos: Vector2 = Vector2(core.experimental_boss_altar_pos) - camera
	return Rect2(Vector2(-112.0, -112.0), viewport + Vector2(224.0, 224.0)).has_point(screen_pos)


func _altar_visible_on_screen() -> bool:
	var viewport: Vector2 = core.get_viewport_rect().size
	return altar_visible_on_screen(core._camera(viewport), viewport)


func _roll_altar_position() -> Vector2:
	var minimum := ALTAR_WORLD_MARGIN
	var maximum := EXPERIMENTAL_WORLD_SIZE - ALTAR_WORLD_MARGIN
	var best := maximum
	var best_distance := 0.0
	for _attempt in range(18):
		var candidate := Vector2(core.rng.randf_range(minimum.x, maximum.x), core.rng.randf_range(minimum.y, maximum.y))
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
