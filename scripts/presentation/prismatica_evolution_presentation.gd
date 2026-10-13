extends RefCounted
class_name RTPrismaticaEvolutionPresentation

# Lightweight CanvasItem geometry: no particles, sprites or per-frame node
# allocation.  The formations are intentionally readable on landscape mobile.

static func draw(game: Node2D, camera: Vector2) -> void:
	if String(game.manifestation_key) != "prismatica":
		return
	var state: Dictionary = Dictionary(game.manifest_evolution_state.get("prismatica", {}))
	for formation_value in Array(state.get("formations", [])):
		_draw_formation(game, Dictionary(formation_value), camera)
	for ghost_value in Array(state.get("ghosts", [])):
		var ghost: Dictionary = Dictionary(ghost_value)
		var pos := Vector2(ghost.get("pos", game.player_pos)) - camera
		var alpha := clampf(float(ghost.get("life", 0.0)) / 0.42, 0.0, 1.0)
		game.draw_circle(pos, 18.0, Color(0.30, 0.96, 1.0, 0.12 * alpha))
		game.draw_arc(pos, 18.0, 0.0, TAU, 20, Color(0.72, 1.0, 1.0, 0.72 * alpha), 2.0)
	for event_value in Array(state.get("vfx", [])):
		var event: Dictionary = Dictionary(event_value)
		var max_life := maxf(0.01, float(event.get("max", 0.2)))
		var alpha := clampf(float(event.get("life", 0.0)) / max_life, 0.0, 1.0)
		var pos := Vector2(event.get("pos", game.player_pos)) - camera
		var color: Color = event.get("color", Color(0.30, 0.96, 1.0))
		var radius := 16.0 + (1.0 - alpha) * 44.0
		game.draw_arc(pos, radius, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.68 * alpha), 2.2)


static func _draw_formation(game: Node2D, formation: Dictionary, camera: Vector2) -> void:
	var kind := String(formation.get("kind", ""))
	var life := float(formation.get("life", 0.0))
	var max_life := maxf(0.01, float(formation.get("max", 1.0)))
	var alpha := clampf(life / max_life, 0.0, 1.0)
	var pos := Vector2(formation.get("pos", game.player_pos)) - camera
	if kind == "mirror" or kind == "chain_anchor":
		var radius := float(formation.get("radius", 24.0))
		var angle := float(formation.get("angle", 0.0))
		var normal := Vector2.from_angle(angle)
		var tangent := normal.orthogonal()
		var cyan := Color(0.30, 0.96, 1.0, 0.84 * alpha)
		game.draw_line(pos - tangent * radius, pos + tangent * radius, cyan, 4.0)
		game.draw_line(pos - normal * 12.0, pos + normal * 12.0, Color(1.0, 1.0, 1.0, 0.66 * alpha), 1.5)
		game.draw_circle(pos, 6.0, Color(0.20, 0.76, 1.0, 0.32 * alpha))
		return
	var points: Array = Array(formation.get("points", []))
	if points.size() != 3:
		return
	var color := Color(1.0, 0.84, 0.38, 0.80 * alpha)
	if kind == "network":
		color = Color(0.90, 0.36, 1.0, 0.82 * alpha)
	elif kind == "harmonic":
		color = Color(0.42, 1.0, 0.94, 0.82 * alpha)
	elif kind == "perfect":
		color = Color(1.0, 0.94, 0.62, 0.86 * alpha)
	for index in range(3):
		var a := Vector2(points[index]) - camera
		var b := Vector2(points[(index + 1) % 3]) - camera
		game.draw_line(a, b, color, 3.2 if kind != "network" else 4.0)
		game.draw_circle(a, 5.0, Color(color.r, color.g, color.b, 0.86 * alpha))
	if kind == "harmonic":
		game.draw_arc(pos, 28.0 + sin(game.time_alive * 7.0) * 5.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.34 * alpha), 1.5)
