class_name RTUltimateAutoAimPresentation
extends RefCounted

## Mira automatica da ultimate: segurando o botao sem arrastar, o preview fica
## sobre o inimigo de onde a habilidade vai sair, com uma trava girando nele.


## Destino do preview: o alvo automatico quando existe, senao o ponto manual.
static func resolve(game: Node2D, secondary: bool, manual_target: Vector2) -> Vector2:
	if not secondary:
		return manual_target
	var auto_target = game._secondary_quick_target_preview()
	return Vector2(auto_target) if auto_target is Vector2 else manual_target


static func draw_lock(game: Node2D, secondary: bool, target: Vector2, pulse: float) -> void:
	if not secondary or not (game._secondary_quick_target_preview() is Vector2):
		return
	var lock_r: float = 30.0 + pulse * 4.0
	var spin: float = float(Time.get_ticks_msec()) * 0.0015
	for corner in range(4):
		var a0: float = float(corner) * PI * 0.5 + PI * 0.25 + spin
		game.draw_arc(target, lock_r, a0 - 0.32, a0 + 0.32, 8, Color.WHITE, 3.0, true)
	game._draw_centered("ALVO", target + Vector2(0.0, -lock_r - 12.0), 12, Color(1.0, 1.0, 1.0, 0.9))
