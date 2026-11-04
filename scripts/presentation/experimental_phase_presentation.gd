class_name RTExperimentalPhasePresentation
extends RefCounted

const ALTAR_CYAN := Color(0.22, 0.92, 1.0)
const ALTAR_AMBER := Color(1.0, 0.62, 0.18)
const MistGuide = preload("res://scripts/presentation/mist_guide_presentation.gd")


static func draw_world(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	if not game.experimental_phase_controller.uses_definitive_world():
		return
	_draw_landmarks(game, camera, viewport)
	if not game.experimental_boss_altar_used and not game.boss_active and game.boss_call_timer < 0.0:
		_draw_altar(game, camera, viewport)


static func _draw_landmarks(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	# Illustrated landmarks are integrated into each terrain atlas.
	if game.experimental_phase_controller.terrain_phase() in [1, 2, 3, 4, 5, 6, 7]:
		return
	var visible_rect := Rect2(Vector2(-100.0, -100.0), viewport + Vector2(200.0, 200.0))
	var cold: bool = game.experimental_phase_controller.terrain_phase() == 2
	var landmarks: Array[Dictionary] = game.experimental_phase_controller.landmarks
	for landmark_index in range(landmarks.size()):
		if game._runtime_visual_budget_active() and landmark_index % 2 != 0:
			continue
		var landmark: Dictionary = landmarks[landmark_index]
		var center := Vector2(landmark.get("pos", Vector2.ZERO)) - camera
		if not visible_rect.has_point(center):
			continue
		var scale := float(landmark.get("scale", 1.0))
		var kind := int(landmark.get("kind", 0))
		match kind:
			0:
				game.draw_circle(center + Vector2(4.0, 8.0) * scale, 16.0 * scale, Color(0.03, 0.04, 0.05, 0.34))
				game.draw_colored_polygon(PackedVector2Array([center + Vector2(-16, 8) * scale, center + Vector2(-8, -13) * scale, center + Vector2(12, -17) * scale, center + Vector2(20, 8) * scale]), (Color(0.31, 0.43, 0.54, 0.86) if cold else Color(0.28, 0.25, 0.24, 0.86)))
			1:
				game.draw_line(center + Vector2(-20, 12) * scale, center + Vector2(18, -10) * scale, (Color(0.49, 0.71, 0.83, 0.58) if cold else Color(0.58, 0.28, 0.16, 0.58)), 4.0 * scale, true)
				game.draw_line(center + Vector2(-8, -4) * scale, center + Vector2(10, 14) * scale, (Color(0.8, 0.92, 1.0, 0.26) if cold else Color(0.9, 0.48, 0.18, 0.26)), 2.0 * scale, true)
			2:
				game.draw_rect(Rect2(center - Vector2(7, 25) * scale, Vector2(14, 50) * scale), (Color(0.26, 0.38, 0.46, 0.82) if cold else Color(0.22, 0.19, 0.18, 0.82)), true)
				game.draw_circle(center - Vector2(0, 24) * scale, 10.0 * scale, (Color(0.59, 0.76, 0.86, 0.88) if cold else Color(0.42, 0.34, 0.23, 0.88)))
			3:
				for petal in range(5):
					var direction := Vector2.from_angle(float(petal) * TAU / 5.0 + float(landmark.get("phase", 0.0)))
					game.draw_circle(center + direction * 8.0 * scale, 5.0 * scale, (Color(0.59, 0.76, 0.8, 0.72) if cold else Color(0.32, 0.42, 0.20, 0.72)))


static func _draw_altar(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	var world_pos: Vector2 = game.experimental_boss_altar_pos
	var center := world_pos - camera
	var t: float = float(game.time_alive)
	var pulse := 0.5 + 0.5 * sin(t * 2.4)
	if game.experimental_boss_altar_discovered:
		_draw_discovered_altar_path(game, camera, viewport, world_pos, t)
	if game.experimental_phase_controller.altar_visible_on_screen(camera, viewport):
		game.draw_arc(center, 92.0 + pulse * 4.0, 0.0, TAU, 80, Color(ALTAR_CYAN, 0.34 + pulse * 0.22), 3.0, true)
		if game.experimental_boss_altar_near and not game._arauto_active():
			game.draw_arc(center, 72.0, -t * 0.62, -t * 0.62 + TAU * game.experimental_phase_controller.altar_progress(), 64, Color(ALTAR_AMBER, 0.88), 5.0, true)
		game._draw_centered(game.experimental_phase_controller.altar_label(), center + Vector2(0.0, -128.0), 18, Color(0.92, 1.0, 0.98))
		var status := "DERROTE O ARAUTO" if game._arauto_active() else ("INVOCANDO..." if game.experimental_boss_altar_near else "APROXIME-SE PARA INVOCAR")
		game._draw_centered(status, center + Vector2(0.0, 124.0), 14, ALTAR_AMBER if game.experimental_boss_altar_near else ALTAR_CYAN)
		if game.experimental_boss_altar_near and not game._arauto_active():
			var bar := Rect2(center + Vector2(-78.0, 140.0), Vector2(156.0, 9.0))
			game.draw_rect(bar, Color(0.01, 0.025, 0.035, 0.92), true)
			game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * game.experimental_phase_controller.altar_progress(), bar.size.y)), ALTAR_AMBER, true)


## Nevoa-guia ate o altar descoberto (substitui a linha ondulada antiga).
## A seta de borda e desenhada na camada de HUD por MistGuidePresentation.draw_overlay.
static func _draw_discovered_altar_path(game: Node2D, camera: Vector2, viewport: Vector2, world_pos: Vector2, _time: float) -> void:
	if game.mode not in ["game", "boss_call", "pause_countdown"]:
		return
	var distance: float = Vector2(game.player_pos).distance_to(world_pos)
	# Some suavemente quando o jogador chega no altar, para nao poluir a invocacao.
	var arrival_fade: float = smoothstep(game.experimental_phase_controller.ALTAR_INTERACTION_RADIUS, game.experimental_phase_controller.ALTAR_INTERACTION_RADIUS * 3.2, distance)
	MistGuide.draw_floor(game, camera, viewport, world_pos, MistGuide.PALETTE_ALTAR, arrival_fade, 1.37)
