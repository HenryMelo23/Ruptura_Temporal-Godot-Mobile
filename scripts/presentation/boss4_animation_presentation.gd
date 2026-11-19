class_name RTBoss4AnimationPresentation
extends RefCounted

# Presentation-only resolver for the Rupture Astronaut Frog. Combat authority,
# movement and hit timing remain in RTBoss4Controller.

const DRAW_SIZE := Vector2(224.0, 224.0)
const DEATH_DURATION := 1.50
const ORIGINAL_ART_FACING := -1.0
const Controller = preload("res://scripts/systems/bosses/boss4_controller.gd")
const MistGuide = preload("res://scripts/presentation/mist_guide_presentation.gd")
const ART_CELL := 384.0
## Ponto da boca (pixels da celula 384) por quadro da sequencia tongue_v2.
const TONGUE_MOUTH_ANCHORS := [Vector2(146.0, 186.0), Vector2(140.0, 182.0), Vector2(143.0, 202.0), Vector2(156.0, 196.0), Vector2(150.0, 196.0)]
const TONGUE_THICKNESS := 24.0
const TONGUE_TIP_SIZE := 52.0


static func reset(game: Node2D) -> void:
	game.boss4_visual_state = "idle"
	game.boss4_visual_state_elapsed = 0.0
	game.boss4_hit_timer = 0.0
	game.boss4_hit_duration = 0.22
	game.boss4_death_timer = 0.0
	game.boss4_death_duration = DEATH_DURATION
	game.boss4_death_pos = Vector2.ZERO
	game.boss4_ultimate_outcome = ""
	game.boss4_ultimate_outcome_timer = 0.0


static func update(game: Node2D, delta: float) -> void:
	game.boss4_hit_timer = maxf(0.0, game.boss4_hit_timer - delta)
	game.boss4_death_timer = maxf(0.0, game.boss4_death_timer - delta)
	game.boss4_ultimate_outcome_timer = maxf(0.0, game.boss4_ultimate_outcome_timer - delta)
	if game.boss4_ultimate_outcome_timer <= 0.0:
		game.boss4_ultimate_outcome = ""
	var next_state := visual_state(game)
	if next_state != game.boss4_visual_state:
		game.boss4_visual_state = next_state
		game.boss4_visual_state_elapsed = 0.0
	else:
		game.boss4_visual_state_elapsed += maxf(0.0, delta)


static func trigger_hit(game: Node2D, damage: float, source: String = "") -> void:
	if game.current_phase != 4 or damage <= 0.0 or death_active(game):
		return
	if source in ["veneno", "parasite_feast"] or source.begins_with("aura_"):
		return
	game.boss4_hit_timer = game.boss4_hit_duration


static func trigger_death(game: Node2D, death_position: Vector2 = Vector2.INF) -> void:
	if game.current_phase != 4 or death_active(game):
		return
	game.boss4_hit_timer = 0.0
	game.boss4_death_timer = DEATH_DURATION
	game.boss4_death_duration = DEATH_DURATION
	game.boss4_death_pos = game.boss_pos if not death_position.is_finite() else death_position
	game.boss4_visual_state = "death"
	game.boss4_visual_state_elapsed = 0.0


static func visual_state(game: Node2D) -> String:
	if death_active(game):
		return "death"
	if game.current_phase != 4:
		return ""
	if game.boss_entry_timer > 0.0:
		return "land"
	if game.boss4_hit_timer > 0.0:
		return "hit"
	if game.boss4_ultimate_outcome_timer > 0.0 and not game.boss4_ultimate_outcome.is_empty():
		return game.boss4_ultimate_outcome
	var state: String = String(game.boss4_controller.visual_state()) if game.boss4_controller != null else "idle"
	return state if not state.is_empty() else "idle"


static func active_texture(game: Node2D) -> Texture2D:
	var state := visual_state(game)
	if state.is_empty() or state == "death":
		return null
	var phased := _phased_frame(game, state)
	if not phased.is_empty():
		var phased_key: String = String(phased["key"])
		if not game.textures.has(phased_key):
			game._ensure_runtime_texture(phased_key)
		var phased_frames: Array = game.textures.get(phased_key, [])
		if not phased_frames.is_empty():
			return phased_frames[clampi(int(phased["index"]), 0, phased_frames.size() - 1)] as Texture2D
	var texture_key := "boss4_rework_" + state
	if not game.textures.has(texture_key):
		game._ensure_runtime_texture(texture_key)
	var frames: Array = game.textures.get(texture_key, [])
	if frames.is_empty():
		return null
	return frames[_frame_index(game, state, frames.size())] as Texture2D


## Quadro por fase do golpe (salto, lingua). Vazio = usa o caminho antigo.
static func _phased_frame(game: Node2D, state: String) -> Dictionary:
	var ai: Dictionary = game.boss4_ai_state
	var ai_state := String(ai.get("state", ""))
	if state == "walk":
		var hop_phase := String(ai.get("hop_phase", Controller.HOP_PHASE_PAUSE))
		match hop_phase:
			Controller.HOP_PHASE_PREP:
				return {"key": "boss4_rework_hop", "index": 0}
			Controller.HOP_PHASE_PUSH:
				return {"key": "boss4_rework_hop", "index": 1}
			Controller.HOP_PHASE_AIR:
				return {"key": "boss4_rework_hop", "index": _air_frame(float(ai.get("hop_progress", 0.0)))}
			Controller.HOP_PHASE_IMPACT:
				return {"key": "boss4_rework_hop", "index": 5}
		return {"key": "boss4_rework_idle", "index": int(game.boss4_visual_state_elapsed * 5.0) % 4}
	if state == "jump":
		if ai_state == Controller.STATE_WINDUP:
			return {"key": "boss4_rework_hop", "index": 0 if float(ai.get("action_elapsed", 0.0)) < 0.42 else 1}
		return {"key": "boss4_rework_hop", "index": _air_frame(float(ai.get("jump_progress", 0.0)))}
	if state == "land":
		return {"key": "boss4_rework_hop", "index": 5}
	if state == "tongue":
		return {"key": "boss4_rework_tongue_v2", "index": tongue_frame_index(game)}
	if state == "comet":
		return comet_frame(game)
	if state == "gravity" and String(ai.get("action", "")) == "gravity":
		return gravity_frame(game)
	return {}


## Poco Gravitacional: gravity_v2 (sem anel/pedras pintados) ou quadros antigos; saltos usam hop.
static func gravity_frame(game: Node2D) -> Dictionary:
	var ai: Dictionary = game.boss4_ai_state
	var ai_state := String(ai.get("state", ""))
	var elapsed: float = float(ai.get("action_elapsed", 0.0))
	var v2: bool = ResourceLoader.exists("res://assets/sprites/boss4_rework/boss4_gravity_v2_00.png")
	var key: String = "boss4_rework_gravity_v2" if v2 else "boss4_rework_gravity"
	if ai_state == Controller.STATE_WINDUP:
		return {"key": key, "index": 0 if elapsed < 0.4 else 1}
	if ai_state == Controller.STATE_ACTIVE:
		match String(ai.get("hop_phase", Controller.HOP_PHASE_PAUSE)):
			Controller.HOP_PHASE_PREP:
				return {"key": "boss4_rework_hop", "index": 0}
			Controller.HOP_PHASE_PUSH:
				return {"key": "boss4_rework_hop", "index": 1}
			Controller.HOP_PHASE_AIR:
				return {"key": "boss4_rework_hop", "index": _air_frame(float(ai.get("hop_progress", 0.0)))}
			Controller.HOP_PHASE_IMPACT:
				return {"key": "boss4_rework_hop", "index": 5}
		return {"key": key, "index": 2}
	return {"key": key, "index": 3}


## Usa comet_v2 (sem raio pintado) quando existir; senao, os quadros antigos sem o 02.
static func comet_frame(game: Node2D) -> Dictionary:
	var ai: Dictionary = game.boss4_ai_state
	var ai_state := String(ai.get("state", ""))
	var elapsed: float = float(ai.get("action_elapsed", 0.0))
	var v2: bool = ResourceLoader.exists("res://assets/sprites/boss4_rework/boss4_comet_v2_00.png")
	var index: int = 0
	if ai_state == Controller.STATE_WINDUP:
		index = 0 if elapsed < 0.35 else 1
	elif ai_state == Controller.STATE_ACTIVE:
		index = (2 + int(elapsed * 10.0) % 2) if v2 else 1
	else:
		index = 4 if v2 else 3
	return {"key": "boss4_rework_comet_v2" if v2 else "boss4_rework_comet", "index": index}


static func _air_frame(progress: float) -> int:
	if progress < 0.38:
		return 2
	if progress < 0.68:
		return 3
	return 4


static func tongue_frame_index(game: Node2D) -> int:
	var ai: Dictionary = game.boss4_ai_state
	var ai_state := String(ai.get("state", ""))
	var elapsed: float = float(ai.get("action_elapsed", 0.0))
	if ai_state == Controller.STATE_WINDUP:
		return 0 if elapsed < Controller.TONGUE_TRACK_TIME else 1
	if ai_state == Controller.STATE_ACTIVE:
		return 2 if elapsed < Controller.TONGUE_FIRE_TIME else 3
	return 4


static func draw_size(_game: Node2D) -> Vector2:
	return DRAW_SIZE


static func draw_position(game: Node2D) -> Vector2:
	var position: Vector2 = game.boss_pos
	var orbiting: bool = String(game.boss4_ai_state.get("state", "")) == Controller.STATE_ACTIVE and String(game.boss4_ai_state.get("action", "")) == "gravity"
	if (String(game.boss4_ai_state.get("state", "")) == Controller.STATE_WALK or orbiting) and String(game.boss4_ai_state.get("hop_phase", "")) == Controller.HOP_PHASE_AIR:
		position.y -= sin(clampf(float(game.boss4_ai_state.get("hop_progress", 0.0)), 0.0, 1.0) * PI) * Controller.HOP_HEIGHT
	if String(game.boss4_ai_state.get("state", "")) == "jump":
		var progress: float = clampf(float(game.boss4_ai_state.get("jump_progress", 0.0)), 0.0, 1.0)
		position.y -= sin(progress * PI) * 112.0
	return position


static func should_flip_h(game: Node2D) -> bool:
	return float(game.boss4_ai_state.get("facing", ORIGINAL_ART_FACING)) > 0.0


static func stage_modulate(game: Node2D) -> Color:
	var stage := clampi(int(game.boss4_stage), 1, 4)
	var colors := [Color.WHITE, Color(0.93, 1.0, 0.94), Color(1.0, 0.89, 0.95), Color(0.91, 0.76, 1.0)]
	var color: Color = colors[stage - 1]
	if game.boss4_hit_timer > 0.0:
		color = color.lerp(Color(1.0, 0.38, 0.36), 0.44)
	return color


static func death_active(game: Node2D) -> bool:
	return game.current_phase == 4 and game.boss4_death_timer > 0.0


static func draw_death(game: Node2D, camera: Vector2) -> void:
	var key := "boss4_rework_death"
	if not game.textures.has(key):
		game._ensure_runtime_texture(key)
	var frames: Array = game.textures.get(key, [])
	if frames.is_empty():
		return
	var progress: float = 1.0 - game.boss4_death_timer / maxf(0.001, game.boss4_death_duration)
	var index: int = clampi(int(floor(progress * float(frames.size()))), 0, frames.size() - 1)
	var texture := frames[index] as Texture2D
	var center: Vector2 = game.boss4_death_pos - camera
	var fade: float = 1.0 - clampf((progress - 0.86) / 0.14, 0.0, 1.0)
	if progress < 0.78:
		game._draw_dynamic_shadow_fit(texture, center + Vector2(0.0, 10.0), DRAW_SIZE, should_flip_h(game), true, 0.38 * fade)
	game._draw_entity_fit_flipped(texture, center, DRAW_SIZE, should_flip_h(game), Color(1.0, 1.0, 1.0, fade), true)


static func _frame_index(game: Node2D, state: String, frame_count: int) -> int:
	if frame_count <= 1:
		return 0
	if state == "hit":
		var progress: float = 1.0 - game.boss4_hit_timer / maxf(0.001, game.boss4_hit_duration)
		return clampi(int(floor(progress * float(frame_count))), 0, frame_count - 1)
	if state.begins_with("transition_"):
		var progress: float = clampf(game.boss4_visual_state_elapsed / 0.95, 0.0, 1.0)
		return clampi(int(floor(progress * float(frame_count))), 0, frame_count - 1)
	if state in ["slam", "tongue", "comet", "gravity"]:
		var total_by_state := {"slam": 1.31, "tongue": 1.22, "comet": 1.07, "gravity": 1.62}
		var total: float = float(total_by_state.get(state, 1.2))
		var progress: float = clampf(float(game.boss4_ai_state.get("action_total_elapsed", 0.0)) / total, 0.0, 1.0)
		return clampi(int(floor(progress * float(frame_count))), 0, frame_count - 1)
	if state == "jump":
		return clampi(int(floor(clampf(float(game.boss4_ai_state.get("jump_progress", 0.0)), 0.0, 1.0) * float(frame_count))), 0, frame_count - 1)
	if state == "land":
		var land_progress: float = clampf(float(game.boss4_ai_state.get("action_elapsed", 0.0)) / 0.18, 0.0, 1.0)
		return clampi(int(floor(land_progress * float(frame_count))), 0, frame_count - 1)
	if state in ["ultimate_interrupted", "ultimate_failure"]:
		var outcome_progress: float = 1.0 - game.boss4_ultimate_outcome_timer / 0.55
		return clampi(int(floor(outcome_progress * float(frame_count))), 0, frame_count - 1)
	if state == "ultimate":
		return mini(int(game.boss4_visual_state_elapsed * 6.0), frame_count - 1)
	var fps: float = 7.5 if state == "walk" else 5.0
	return int(game.boss4_visual_state_elapsed * fps) % frame_count


## Boca no mundo a partir da ancora do quadro atual da lingua.
static func tongue_mouth_world(game: Node2D) -> Vector2:
	var anchor: Vector2 = TONGUE_MOUTH_ANCHORS[clampi(tongue_frame_index(game), 0, TONGUE_MOUTH_ANCHORS.size() - 1)]
	var scale: float = minf(DRAW_SIZE.x, DRAW_SIZE.y) / ART_CELL
	var offset: Vector2 = (anchor - Vector2(ART_CELL, ART_CELL) * 0.5) * scale
	if should_flip_h(game):
		offset.x = -offset.x
	return draw_position(game) + offset


## Mira (preparacao) e lingua texturizada (ataque/recolher). Camada de mundo.
static func draw_tongue(game: Node2D, camera: Vector2) -> void:
	if game.current_phase != 4 or not game.boss_active or death_active(game):
		return
	var ai: Dictionary = game.boss4_ai_state
	if String(ai.get("action", "")) != "tongue":
		return
	var ai_state := String(ai.get("state", ""))
	var mouth: Vector2 = tongue_mouth_world(game) - camera
	var direction := Vector2(ai.get("attack_dir", Vector2.LEFT)).normalized()
	if ai_state == Controller.STATE_WINDUP:
		_draw_tongue_aim(game, mouth, direction, bool(ai.get("aim_locked", false)))
		return
	if ai_state not in [Controller.STATE_ACTIVE, Controller.STATE_RECOVER]:
		return
	var length: float = float(ai.get("tongue_len", 0.0))
	var tip: Vector2 = Vector2(ai.get("tongue_tip", game.boss_pos)) - camera
	if bool(ai.get("tongue_hit", false)) and tip.distance_to(mouth) > 1.0:
		direction = (tip - mouth).normalized()
	if ai_state == Controller.STATE_RECOVER:
		var retract: float = clampf(float(ai.get("action_elapsed", 0.0)) / 0.18, 0.0, 1.0)
		length *= 1.0 - retract * retract
	if length < 6.0:
		return
	_draw_tongue_body(game, mouth, direction, length)


static func _draw_tongue_aim(game: Node2D, mouth: Vector2, direction: Vector2, locked: bool) -> void:
	var t: float = float(Time.get_ticks_msec()) * 0.001
	var color := Color(1.0, 0.25, 0.3, 0.85) if locked else Color(1.0, 0.62, 0.82, 0.38)
	var width: float = 3.0 if locked else 1.6
	var dash: float = 18.0
	var gap: float = 12.0 if locked else 16.0
	var travelled: float = fposmod(t * (260.0 if locked else 120.0), dash + gap)
	while travelled < Controller.TONGUE_RANGE:
		var a: Vector2 = mouth + direction * travelled
		var b: Vector2 = mouth + direction * minf(travelled + dash, Controller.TONGUE_RANGE)
		game.draw_line(a, b, color, width, true)
		travelled += dash + gap
	var end: Vector2 = mouth + direction * Controller.TONGUE_RANGE
	if locked:
		var pulse: float = 0.5 + 0.5 * sin(t * 22.0)
		game.draw_arc(end, 20.0 + pulse * 6.0, 0.0, TAU, 32, Color(1.0, 0.22, 0.28, 0.9), 2.5, true)
		game.draw_line(end - direction.orthogonal() * 14.0, end + direction.orthogonal() * 14.0, Color(1.0, 0.3, 0.3, 0.9), 2.0, true)
	else:
		game.draw_arc(end, 14.0, 0.0, TAU, 24, Color(color, 0.5), 1.5, true)


static func _draw_tongue_body(game: Node2D, mouth: Vector2, direction: Vector2, length: float) -> void:
	if not game.textures.has("boss4_tongue_segment"):
		game._ensure_runtime_texture("boss4_tongue_segment")
	var segment: Texture2D = game.textures.get("boss4_tongue_segment") as Texture2D
	if not game.textures.has("boss4_tongue_tip"):
		game._ensure_runtime_texture("boss4_tongue_tip")
	var tip_texture: Texture2D = game.textures.get("boss4_tongue_tip") as Texture2D
	game.draw_set_transform(mouth, direction.angle(), Vector2.ONE)
	if segment != null:
		var tex_size: Vector2 = segment.get_size()
		var scale: float = TONGUE_THICKNESS / maxf(1.0, tex_size.y)
		var piece: float = tex_size.x * scale
		var x: float = 0.0
		while x < length:
			var width: float = minf(piece, length - x)
			game.draw_texture_rect_region(segment, Rect2(x, -TONGUE_THICKNESS * 0.5, width, TONGUE_THICKNESS), Rect2(0.0, 0.0, width / scale, tex_size.y))
			x += piece
	else:
		game.draw_line(Vector2.ZERO, Vector2(length, 0.0), Color(0.95, 0.4, 0.62), TONGUE_THICKNESS * 0.7, true)
	if tip_texture != null:
		var tip_scale: float = TONGUE_TIP_SIZE / maxf(1.0, tip_texture.get_size().x)
		game.draw_texture_rect(tip_texture, Rect2(Vector2(length - 8.0 * tip_scale, -TONGUE_TIP_SIZE * 0.5), Vector2(TONGUE_TIP_SIZE, TONGUE_TIP_SIZE)), false)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Anel do Salto Esmagador (hazard boss4_shock_ring).
static func draw_shock_ring(game: Node2D, camera: Vector2, hazard: Dictionary) -> void:
	var progress: float = clampf(float(hazard.get("age", 0.0)) / maxf(0.01, float(hazard.get("max", Controller.SHOCK_RING_LIFE))), 0.0, 1.0)
	var radii: Vector2 = Vector2(hazard.get("radii", Controller.SHOCK_RING_RADIUS))
	var radius: float = Controller.shock_ring_radius(progress, radii)
	var center: Vector2 = Vector2(hazard.get("center", game.boss_pos)) - camera
	var fade: float = 1.0 - smoothstep(0.7, 1.0, progress)
	game.draw_arc(center, radius, 0.0, TAU, 72, Color(0.25, 0.08, 0.02, 0.5 * fade), Controller.SHOCK_RING_BAND * 1.4, true)
	game.draw_arc(center, radius, 0.0, TAU, 72, Color(1.0, 0.56, 0.22, 0.75 * fade), 7.0, true)
	game.draw_arc(center, radius - 9.0, 0.0, TAU, 72, Color(1.0, 0.9, 0.62, 0.6 * fade), 2.0, true)
	var debris: int = 14 if not game._runtime_visual_budget_active() else 7
	for index in range(debris):
		var angle: float = float(index) / float(debris) * TAU + float(hazard.get("center", Vector2.ZERO).x) * 0.01
		var jitter: float = sin(float(index) * 12.9 + progress * 9.0) * 6.0
		game.draw_circle(center + Vector2.from_angle(angle) * (radius + jitter), 3.0 + (1.0 - progress) * 2.0, Color(0.62, 0.5, 0.42, 0.8 * fade))
	if progress < 0.35:
		var crack_alpha: float = 1.0 - progress / 0.35
		for index in range(6):
			var angle2: float = float(index) * TAU / 6.0 + 0.3
			game.draw_line(center, center + Vector2.from_angle(angle2) * (60.0 + float(index % 3) * 22.0), Color(0.12, 0.04, 0.02, 0.7 * crack_alpha), 3.0, true)



## Raio do Capacete: setor de aviso na carga e raio varrendo na fase ativa.
static func draw_helmet_beam(game: Node2D, camera: Vector2) -> void:
	if game.current_phase != 4 or not game.boss_active or death_active(game):
		return
	var ai: Dictionary = game.boss4_ai_state
	if String(ai.get("action", "")) != "comet":
		return
	var ai_state := String(ai.get("state", ""))
	var origin: Vector2 = game.boss4_controller.beam_origin() - (game.boss_pos - draw_position(game)) - camera
	var from_angle: float = float(ai.get("beam_from", 0.0))
	var to_angle: float = float(ai.get("beam_to", 0.0))
	var t: float = float(Time.get_ticks_msec()) * 0.001
	var elapsed: float = float(ai.get("action_elapsed", 0.0))
	if ai_state == Controller.STATE_WINDUP:
		var charge: float = clampf(elapsed / 0.7, 0.0, 1.0)
		_draw_beam_sector(game, origin, from_angle, to_angle, charge, t)
		_draw_charge_glow(game, origin, charge, t)
		return
	if ai_state == Controller.STATE_ACTIVE:
		var angle: float = float(ai.get("beam_angle", from_angle))
		_draw_beam_trail(game, origin, from_angle, angle)
		_draw_beam(game, origin, angle, 1.0, t)
		return
	if ai_state == Controller.STATE_RECOVER:
		var fade: float = 1.0 - clampf(elapsed / 0.22, 0.0, 1.0)
		if fade > 0.01:
			_draw_beam(game, origin, float(ai.get("beam_angle", to_angle)), fade, t)


static func _draw_beam_sector(game: Node2D, origin: Vector2, from_angle: float, to_angle: float, charge: float, t: float) -> void:
	var steps: int = 22
	var points := PackedVector2Array([origin])
	for index in range(steps + 1):
		points.append(origin + Vector2.from_angle(lerp_angle(from_angle, to_angle, float(index) / float(steps))) * Controller.BEAM_RANGE)
	game.draw_colored_polygon(points, Color(0.62, 0.18, 0.9, 0.06 + charge * 0.1))
	var edge := Color(0.86, 0.5, 1.0, 0.35 + charge * 0.4)
	game.draw_line(origin, points[1], Color(1.0, 0.86, 1.0, 0.75), 2.5, true)
	game.draw_line(origin, points[points.size() - 1], edge, 1.5, true)
	var arc_points := PackedVector2Array()
	for index in range(1, points.size()):
		arc_points.append(points[index])
	game.draw_polyline(arc_points, edge, 2.0, true)
	# Seta do sentido da varredura, correndo ao longo do arco.
	var run: float = fposmod(t * 1.4, 1.0)
	for k in range(3):
		var u: float = fposmod(run + float(k) * 0.33, 1.0)
		var angle: float = lerp_angle(from_angle, to_angle, u)
		var tip: Vector2 = origin + Vector2.from_angle(angle) * (Controller.BEAM_RANGE * 0.82)
		var tangent: Vector2 = Vector2.from_angle(angle).orthogonal() * signf(to_angle - from_angle)
		var radial: Vector2 = Vector2.from_angle(angle)
		var arrow := PackedVector2Array([tip + tangent * 12.0, tip - tangent * 4.0 + radial * 8.0, tip - tangent * 4.0 - radial * 8.0])
		game.draw_colored_polygon(arrow, Color(1.0, 0.84, 1.0, (0.4 + charge * 0.5) * (1.0 - absf(u - 0.5))))


static func _draw_charge_glow(game: Node2D, origin: Vector2, charge: float, t: float) -> void:
	var pulse: float = 0.85 + 0.15 * sin(t * 30.0)
	MistGuide.draw_blob(game, origin, Vector2(90.0, 90.0) * (0.4 + charge) * pulse, Color(0.72, 0.3, 1.0, 0.55 * charge))
	MistGuide.draw_blob(game, origin, Vector2(36.0, 36.0) * (0.5 + charge), Color(1.0, 0.92, 1.0, 0.8 * charge))
	for index in range(6):
		var angle: float = float(index) * TAU / 6.0 + t * 3.0
		var radius: float = lerpf(70.0, 8.0, fposmod(t * 1.8 + float(index) * 0.17, 1.0))
		game.draw_circle(origin + Vector2.from_angle(angle) * radius, 2.2, Color(1.0, 0.8, 1.0, 0.8 * charge))


static func _draw_beam_trail(game: Node2D, origin: Vector2, from_angle: float, angle: float) -> void:
	var steps: int = 10
	var points := PackedVector2Array([origin])
	for index in range(steps + 1):
		points.append(origin + Vector2.from_angle(lerp_angle(from_angle, angle, float(index) / float(steps))) * Controller.BEAM_RANGE)
	if points.size() >= 4:
		game.draw_colored_polygon(points, Color(0.5, 0.1, 0.7, 0.08))


static func _draw_beam(game: Node2D, origin: Vector2, angle: float, alpha: float, t: float) -> void:
	var direction := Vector2.from_angle(angle)
	var finish: Vector2 = origin + direction * Controller.BEAM_RANGE
	var segment: Texture2D = _optional_texture(game, "boss4_beam_segment")
	if segment != null:
		var height: float = Controller.BEAM_HALF_WIDTH * 2.6
		var tex_size: Vector2 = segment.get_size()
		var scale: float = height / maxf(1.0, tex_size.y)
		var piece: float = tex_size.x * scale
		var scroll: float = fposmod(t * 900.0, piece)
		game.draw_set_transform(origin, angle, Vector2.ONE)
		var x: float = -scroll
		while x < Controller.BEAM_RANGE:
			var start: float = maxf(0.0, x)
			var width: float = minf(x + piece, Controller.BEAM_RANGE) - start
			if width > 0.5:
				var src_x: float = (start - x) / scale
				game.draw_texture_rect_region(segment, Rect2(start, -height * 0.5, width, height), Rect2(src_x, 0.0, width / scale, tex_size.y), Color(1.0, 1.0, 1.0, alpha))
			x += piece
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var flicker: float = 0.9 + 0.1 * sin(t * 47.0)
		game.draw_line(origin, finish, Color(0.48, 0.1, 0.72, 0.3 * alpha), Controller.BEAM_HALF_WIDTH * 2.4, true)
		game.draw_line(origin, finish, Color(0.86, 0.36, 1.0, 0.7 * alpha * flicker), Controller.BEAM_HALF_WIDTH * 1.2, true)
		game.draw_line(origin, finish, Color(1.0, 0.94, 1.0, 0.95 * alpha), Controller.BEAM_HALF_WIDTH * 0.45, true)
		for index in range(8):
			var u: float = fposmod(t * 2.6 + float(index) * 0.125, 1.0)
			var side: float = sin(float(index) * 7.3 + t * 9.0) * Controller.BEAM_HALF_WIDTH * 0.7
			game.draw_circle(origin + direction * Controller.BEAM_RANGE * u + direction.orthogonal() * side, 2.4, Color(1.0, 0.86, 1.0, 0.8 * alpha))
	var origin_tex: Texture2D = _optional_texture(game, "boss4_beam_origin")
	var impact_tex: Texture2D = _optional_texture(game, "boss4_beam_impact")
	var flare: float = 1.0 + 0.12 * sin(t * 38.0)
	if origin_tex != null:
		game.draw_texture_rect(origin_tex, Rect2(origin - Vector2(46.0, 46.0) * flare, Vector2(92.0, 92.0) * flare), false, Color(1.0, 1.0, 1.0, alpha))
	else:
		MistGuide.draw_blob(game, origin, Vector2(70.0, 70.0) * flare, Color(1.0, 0.86, 1.0, 0.8 * alpha))
	if impact_tex != null:
		game.draw_texture_rect(impact_tex, Rect2(finish - Vector2(52.0, 52.0) * flare, Vector2(104.0, 104.0) * flare), false, Color(1.0, 1.0, 1.0, alpha))
	else:
		MistGuide.draw_blob(game, finish, Vector2(90.0, 56.0) * flare, Color(0.86, 0.42, 1.0, 0.7 * alpha))
		game.draw_arc(finish, 26.0 * flare, 0.0, TAU, 28, Color(1.0, 0.8, 1.0, 0.7 * alpha), 2.0, true)


static func _optional_texture(game: Node2D, key: String) -> Texture2D:
	if game.textures.has(key):
		return game.textures.get(key) as Texture2D
	if ResourceLoader.exists("res://assets/sprites/boss4_rework/%s.png" % key):
		game._ensure_runtime_texture(key)
		return game.textures.get(key) as Texture2D
	return null



## Poco Gravitacional: aviso no ponto durante a carga do sapo.
static func draw_gravity_telegraph(game: Node2D, camera: Vector2) -> void:
	if game.current_phase != 4 or not game.boss_active or death_active(game):
		return
	var ai: Dictionary = game.boss4_ai_state
	if String(ai.get("action", "")) != "gravity" or String(ai.get("state", "")) != Controller.STATE_WINDUP:
		return
	var center: Vector2 = Vector2(ai.get("well_pos", game.boss_pos)) - camera
	var charge: float = clampf(float(ai.get("action_elapsed", 0.0)) / 0.8, 0.0, 1.0)
	var t: float = float(Time.get_ticks_msec()) * 0.001
	var radius: float = Controller.WELL_PULL_RADIUS
	game.draw_circle(center, radius * (0.3 + charge * 0.7), Color(0.18, 0.04, 0.3, 0.1 + charge * 0.1))
	game.draw_arc(center, radius, t * 1.6, t * 1.6 + TAU * (0.25 + charge * 0.75), 72, Color(0.86, 0.5, 1.0, 0.35 + charge * 0.45), 2.5, true)
	game.draw_arc(center, Controller.WELL_CORE_RADIUS, 0.0, TAU, 32, Color(1.0, 0.7, 1.0, 0.4 + charge * 0.5), 2.0, true)
	for index in range(8):
		var angle: float = float(index) * TAU / 8.0 - t * 0.8
		var run: float = fposmod(t * 1.3 + float(index) * 0.125, 1.0)
		var tip: Vector2 = center + Vector2.from_angle(angle) * lerpf(radius * 0.95, Controller.WELL_CORE_RADIUS + 12.0, run)
		var inward: Vector2 = Vector2.from_angle(angle + PI)
		var side: Vector2 = inward.orthogonal()
		game.draw_colored_polygon(PackedVector2Array([tip + inward * 10.0, tip - inward * 4.0 + side * 6.0, tip - inward * 4.0 - side * 6.0]), Color(1.0, 0.8, 1.0, (0.3 + charge * 0.6) * sin(run * PI)))


## Singularidade: espiral girando, nucleo, fiapos sugados, aviso e explosao da implosao.
static func draw_singularity(game: Node2D, camera: Vector2, hazard: Dictionary) -> void:
	var center: Vector2 = Vector2(hazard.get("pos", game.boss_pos)) - camera
	var age: float = float(hazard.get("age", 0.0))
	var t: float = float(Time.get_ticks_msec()) * 0.001
	var grow: float = clampf(age / 0.35, 0.0, 1.0)
	var low: bool = game._runtime_visual_budget_active()
	if age < Controller.WELL_COLLAPSE_AT:
		var warn: float = clampf((age - (Controller.WELL_COLLAPSE_AT - Controller.WELL_COLLAPSE_WARN)) / Controller.WELL_COLLAPSE_WARN, 0.0, 1.0)
		var radius: float = Controller.WELL_PULL_RADIUS * grow
		var swirl: Texture2D = _optional_texture(game, "boss4_singularity_swirl")
		if swirl != null:
			game.draw_set_transform(center, -t * 1.4, Vector2.ONE)
			# A arte ocupa ~78% da imagem: escala para os bracos chegarem ao raio de puxao.
			var swirl_r: float = radius * 1.22
			game.draw_texture_rect(swirl, Rect2(-Vector2(swirl_r, swirl_r), Vector2(swirl_r, swirl_r) * 2.0), false, Color(1.0, 1.0, 1.0, 0.55 * grow))
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			game.draw_circle(center, radius, Color(0.16, 0.03, 0.26, 0.16 * grow))
			game.draw_circle(center, radius * 0.6, Color(0.2, 0.04, 0.32, 0.16 * grow))
			var arms: int = 3 if low else 4
			for arm in range(arms):
				var points := PackedVector2Array()
				for step in range(14):
					var u: float = float(step) / 13.0
					var a: float = float(arm) * TAU / float(arms) - t * 1.4 + u * 2.6
					points.append(center + Vector2.from_angle(a) * lerpf(radius, Controller.WELL_CORE_RADIUS * 0.7, u))
				game.draw_polyline(points, Color(0.74, 0.34, 1.0, 0.4 * grow), 3.0, true)
		game.draw_arc(center, radius, 0.0, TAU, 72, Color(0.8, 0.46, 1.0, 0.45 * grow), 2.0, true)
		var motes: int = 10 if low else 18
		for index in range(motes):
			var run: float = fposmod(t * 0.9 + float(index) * 0.61, 1.0)
			var a2: float = float(index) * 2.39 - t * 1.4 + run * 2.4
			var p: Vector2 = center + Vector2.from_angle(a2) * lerpf(radius, Controller.WELL_CORE_RADIUS * 0.5, run * run)
			game.draw_circle(p, 1.6 + run * 2.0, Color(1.0, 0.84, 1.0, 0.75 * sin(run * PI) * grow))
		var core_size: float = Controller.WELL_CORE_RADIUS * 2.3 * (0.4 + 0.6 * grow) * (1.0 + warn * 0.35 + 0.05 * sin(t * 12.0))
		var core: Texture2D = _optional_texture(game, "boss4_singularity_core")
		if core != null:
			game.draw_set_transform(center, t * 2.6, Vector2.ONE)
			game.draw_texture_rect(core, Rect2(-Vector2(core_size, core_size) * 0.5, Vector2(core_size, core_size)), false)
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			MistGuide.draw_blob(game, center, Vector2(core_size, core_size) * 1.4, Color(0.7, 0.2, 1.0, 0.5))
			game.draw_circle(center, core_size * 0.36, Color(0.03, 0.0, 0.06, 0.95))
			game.draw_arc(center, core_size * 0.4, t * 4.0, t * 4.0 + TAU * 0.7, 32, Color(1.0, 0.6, 1.0, 0.9), 3.0, true)
		if warn > 0.0:
			var flash: float = 0.5 + 0.5 * sin(t * 28.0)
			game.draw_circle(center, Controller.WELL_BURST_RADIUS, Color(1.0, 0.25, 0.6, (0.06 + 0.12 * warn) * (0.6 + 0.4 * flash)))
			game.draw_arc(center, lerpf(Controller.WELL_PULL_RADIUS, Controller.WELL_BURST_RADIUS, warn), 0.0, TAU, 72, Color(1.0, 0.4, 0.8, 0.5 + warn * 0.4), 3.0, true)
			game.draw_arc(center, Controller.WELL_BURST_RADIUS, 0.0, TAU, 72, Color(1.0, 0.75, 0.95, 0.4 + 0.5 * warn * flash), 2.0, true)
		return
	var burst_t: float = clampf((age - Controller.WELL_COLLAPSE_AT) / maxf(0.01, Controller.WELL_LIFE - Controller.WELL_COLLAPSE_AT), 0.0, 1.0)
	var fade: float = 1.0 - burst_t
	var size: float = Controller.WELL_BURST_RADIUS * 2.0 * (0.5 + burst_t * 0.8)
	var burst: Texture2D = _optional_texture(game, "boss4_singularity_burst")
	if burst != null:
		game.draw_texture_rect(burst, Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), false, Color(1.0, 1.0, 1.0, fade))
	else:
		MistGuide.draw_blob(game, center, Vector2(size, size), Color(0.9, 0.5, 1.0, 0.6 * fade))
		game.draw_arc(center, size * 0.5, 0.0, TAU, 64, Color(1.0, 0.85, 1.0, 0.9 * fade), 6.0 * fade + 1.0, true)
		game.draw_arc(center, size * 0.36, 0.0, TAU, 48, Color(0.8, 0.3, 1.0, 0.7 * fade), 3.0, true)
		for index in range(12):
			var a3: float = float(index) * TAU / 12.0 + 0.2
			game.draw_line(center + Vector2.from_angle(a3) * size * 0.2, center + Vector2.from_angle(a3) * size * 0.55, Color(1.0, 0.8, 1.0, 0.7 * fade), 2.0, true)
