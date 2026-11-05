class_name RTExecutionCamera
extends RefCounted

## Foco de camera da execucao da Lacerante: afasta rapido, aproxima fechando no alvo
## enquanto os golpes acontecem, da um soco no golpe final e volta ao normal.
## Usa o canvas_transform do viewport (mundo + camada de mapa juntos); o HUD sai do ar
## nesse ~1 s e entram faixas de cinema desenhadas em espaco de tela.

## Recuo inicial: a camera da um passo para tras (sem zoom < 1, que mostraria
## a borda fora do mapa) antes de avancar sobre o alvo.
const PULL_BACK := 42.0
const ZOOM_IN := 1.38
const ZOOM_PUNCH := 1.46
const BAR_HEIGHT := 64.0


static func _ease(t: float) -> float:
	var x: float = clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func zoom_at(t: float) -> float:
	if t < 0.12:
		return 1.0
	if t < 0.32:
		return lerpf(1.0, ZOOM_IN, _ease((t - 0.12) / 0.2))
	if t < 0.7:
		return ZOOM_IN + sin((t - 0.32) * 9.0) * 0.012
	if t < 0.8:
		return lerpf(ZOOM_IN, ZOOM_PUNCH, _ease((t - 0.7) / 0.1))
	return lerpf(ZOOM_PUNCH, 1.0, _ease((t - 0.8) / (RTLaceranteExecutionController.CINE_TOTAL - 0.8)))


static func focus_at(t: float) -> float:
	if t < 0.12:
		return 0.0
	if t < 0.32:
		return _ease((t - 0.12) / 0.2)
	if t < 0.8:
		return 1.0
	return 1.0 - _ease((t - 0.8) / (RTLaceranteExecutionController.CINE_TOTAL - 0.8))


static func active(game: Node2D) -> bool:
	return not game.lacerante_execution.cine.is_empty() and game.mode == "game"


static func clear(game: Node2D) -> void:
	var vp: Viewport = game.get_viewport()
	if vp != null and vp.canvas_transform != Transform2D.IDENTITY:
		vp.canvas_transform = Transform2D.IDENTITY


static func apply(game: Node2D, viewport: Vector2, camera: Vector2) -> void:
	var vp: Viewport = game.get_viewport()
	if vp == null:
		return
	if not active(game):
		clear(game)
		return
	var cine: Dictionary = game.lacerante_execution.cine
	var t: float = float(cine["t"])
	var s: float = zoom_at(t)
	var focus: Vector2 = Vector2(cine["target"]) - camera + Vector2(0.0, -24.0)
	var pan: Vector2 = focus.lerp(viewport * 0.5, focus_at(t))
	# Passo para tras: afasta a imagem do alvo e depois avanca.
	var back: float = sin(clampf(t / 0.2, 0.0, 1.0) * PI) * PULL_BACK
	var away: Vector2 = (viewport * 0.5 - focus)
	pan += (away.normalized() if away.length() > 1.0 else Vector2.LEFT) * back
	vp.canvas_transform = Transform2D(0.0, Vector2(s, s), 0.0, pan - focus * s)


static func draw_overlay(game: Node2D, viewport: Vector2) -> void:
	var vp: Viewport = game.get_viewport()
	var cine: Dictionary = game.lacerante_execution.cine
	if vp == null or cine.is_empty():
		return
	var k: float = focus_at(float(cine["t"]))
	game.draw_set_transform_matrix(vp.canvas_transform.affine_inverse())
	var h: float = BAR_HEIGHT * k
	if h > 0.5:
		game.draw_rect(Rect2(0.0, 0.0, viewport.x, h), Color(0.0, 0.0, 0.0, 0.92), true)
		game.draw_rect(Rect2(0.0, viewport.y - h, viewport.x, h), Color(0.0, 0.0, 0.0, 0.92), true)
		game.draw_line(Vector2(0.0, h), Vector2(viewport.x, h), Color(0.9, 0.06, 0.16, 0.7 * k), 2.0)
		game.draw_line(Vector2(0.0, viewport.y - h), Vector2(viewport.x, viewport.y - h), Color(0.9, 0.06, 0.16, 0.7 * k), 2.0)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
