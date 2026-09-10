extends RefCounted

const HUD = preload("res://scripts/ui/combat_hud.gd")
const KEYS := ["pause_resume", "pause_deck", "pause_settings", "pause_menu"]


static func panel_rect(viewport: Vector2) -> Rect2:
	var size := Vector2(minf(920.0, viewport.x - 48.0), minf(480.0, viewport.y - 40.0))
	return Rect2((viewport - size) * 0.5, size)


static func action_rects(viewport: Vector2) -> Array[Rect2]:
	var panel := panel_rect(viewport)
	var compact := viewport.y < 580.0
	var padding := 22.0 if compact else 36.0
	var top := panel.position.y + (88.0 if compact else 132.0)
	var height := clampf((panel.end.y - 32.0 - top - 24.0) / 4.0, 44.0, 62.0)
	var result: Array[Rect2] = []
	for i in range(4):
		result.append(Rect2(panel.position.x + padding, top + i * (height + 8.0), panel.size.x * 0.48 - padding, height))
	return result


static func draw(host: Node2D, viewport: Vector2) -> void:
	var compact := viewport.y < 580.0
	var panel := panel_rect(viewport)
	var padding := 22.0 if compact else 36.0
	var x := panel.position.x + padding
	var top := panel.position.y
	host.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.015, 0.022, 0.027, 0.67))
	host.draw_rect(panel.grow(10), Color(0.0, 0.0, 0.0, 0.15))
	host.draw_rect(panel, Color(0.028, 0.042, 0.051, 0.97))
	host.draw_rect(panel, Color(HUD.MUTED, 0.2), false, 1.0)
	host.draw_line(panel.position, panel.position + Vector2(panel.size.x * 0.48, 0), HUD.CYAN, 2.0)
	host._draw_ui_text("RUPTURA TEMPORAL / INTERVALO", Vector2(x, top + 25), 10, HUD.CYAN)
	host._draw_ui_text("Pausa", Vector2(x, top + (66 if compact else 83)), 36 if compact else 48, HUD.TEXT)
	if not compact:
		host._draw_ui_text("Respire. A ruptura pode esperar.", Vector2(x, top + 108), 13, HUD.MUTED)
	var rects := action_rects(viewport)
	var labels := ["Continuar", "Deck · %d cartas" % host._deck_total_cards(), "Configurações", "Menu inicial"]
	for i in range(KEYS.size()):
		host.buttons[KEYS[i]] = rects[i]
		var focused: bool = host._pause_selection_active(i) or (host._uses_desktop_ui() and rects[i].has_point(host.get_global_mouse_position()))
		host._draw_hub_button(rects[i], labels[i], "", HUD.HURT if i == 3 else HUD.CYAN, focused, i == 0, KEYS[i])
	var divider := panel.position.x + panel.size.x * 0.53
	host.draw_line(Vector2(divider, top + 34), Vector2(divider, panel.end.y - 36), Color(HUD.MUTED, 0.17), 1.0)
	var right := Rect2(divider + padding, top + (38 if compact else 54), panel.end.x - padding - divider - padding, panel.size.y - 90)
	var width := right.size.x
	host._draw_ui_text("PARTIDA EM CURSO", right.position, 10, HUD.MUTED, width)
	host._draw_ui_text(host._manifestation_display_name(host.manifestation_key), right.position + Vector2(0, 34), 23 if compact else 28, HUD.TEXT, width)
	host._draw_ui_text("FASE %02d  /  %s" % [host.current_phase, "ONLINE" if host.is_multiplayer else "SOLO"], right.position + Vector2(0, 58), 11, HUD.CYAN, width)
	var health := Rect2(right.position + Vector2(0, 80), Vector2(width, 76))
	host.hud_feedback.health_panel(host, health, 1.0)
	var metric_y := health.end.y + (27 if compact else 39)
	host._draw_ui_text("TEMPO", Vector2(right.position.x, metric_y), 10, HUD.MUTED)
	host._draw_ui_text("PONTOS", Vector2(right.position.x + width * 0.53, metric_y), 10, HUD.MUTED)
	host._draw_ui_text("%02d:%02d" % [int(host.time_alive) / 60, int(host.time_alive) % 60], Vector2(right.position.x, metric_y + 27), 22, HUD.TEXT, width * 0.47)
	host._draw_ui_text(str(host.score), Vector2(right.position.x + width * 0.53, metric_y + 27), 22, HUD.TEXT, width * 0.47)
	if not compact:
		host.draw_line(Vector2(right.position.x, metric_y + 55), Vector2(right.end.x, metric_y + 55), Color(HUD.MUTED, 0.17), 1.0)
		host._draw_ui_wrap("Tempo suspenso. Retome quando estiver pronto.", Rect2(right.position.x, metric_y + 80, width, 50), 13, HUD.MUTED, 2)
	var hint := "Toque em uma opção para continuar"
	if host.is_gamepad_active:
		hint = "Direcional · navegar     Confirmar · selecionar"
	elif host._uses_desktop_ui():
		hint = "↑ ↓  navegar     Enter  selecionar     Esc  continuar"
	host._draw_ui_text(hint, Vector2(x, panel.end.y - 14), 10, HUD.MUTED, panel.size.x - padding * 2.0)
