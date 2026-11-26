class_name RTDialogueTextScale
extends RefCounted

## Opcao "TEXTO DAS CONVERSAS" (Jogabilidade): escala da fala, do nome e dos
## botoes de escolha. A caixa cresce junto para o texto maior caber.
const MIN := 1.0
const MAX := 2.0
const STEP := 0.25


static func sanitize(value: float) -> float:
	return clampf(snappedf(value, STEP), MIN, MAX)


## direction -1/+1; `wrap` (Enter/A) volta ao minimo depois do maximo.
static func adjust(game: Object, direction: int, wrap: bool = false) -> void:
	var current: float = sanitize(float(game.dialogue_text_scale))
	var next: float = current + STEP * float(signi(direction))
	if wrap and next > MAX + 0.001:
		next = MIN
	game.dialogue_text_scale = sanitize(next)


static func label(game: Object) -> String:
	return "%d%%" % int(round(sanitize(float(game.dialogue_text_scale)) * 100.0))


static func scale(game: Object) -> float:
	return sanitize(float(game.dialogue_text_scale))


## Maior tamanho (de `wanted` ate `floor_size`) em que a fala inteira cabe no
## quadro, com a mesma quebra de linha de MenusPresentation._draw_wrapped.
static func fit_size(game: Node2D, text: String, rect: Rect2, wanted: int, floor_size: int) -> int:
	var size: int = wanted
	while size > floor_size and _wrapped_height(game, text, rect.size.x, size) > rect.size.y:
		size -= 1
	return size


static func _wrapped_height(game: Node2D, text: String, width: float, size: int) -> float:
	var lines: int = 0
	for paragraph in text.split("\n"):
		var line := ""
		lines += 1
		for word in paragraph.split(" "):
			var test: String = line + (" " if line != "" else "") + word
			if line != "" and game.font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
				lines += 1
				line = word
			else:
				line = test
	return float(size) + float(lines - 1) * float(size + 4)
