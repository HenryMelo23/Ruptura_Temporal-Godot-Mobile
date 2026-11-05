class_name RTBoss2DissolvePresentation
extends RefCounted

## Pinguim se desfazendo em neve ao entrar na Nevasca e se remontando ao sair dela.
## O sprite e cortado numa grade; cada pedaco tem um limiar. O lado que entra primeiro
## na nevoa some primeiro; ao sair, o lado voltado para o anel aparece primeiro.
## Pedacos fora do limiar viram lascas/flocos levados pelo vento da tempestade.

const COLS := 12
const ROWS := 14
const BAND := 0.38
const SNOW := Color(0.9, 0.97, 1.0)

static var _cells: Array = []


static func _build() -> void:
	_cells.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xB055
	for y in range(ROWS):
		for x in range(COLS):
			var u: float = (float(x) + 0.5) / float(COLS)
			var v: float = (float(y) + 0.5) / float(ROWS)
			var edge: float = clampf(Vector2((u - 0.5) * 2.0, (v - 0.55) * 1.7).length(), 0.0, 1.0)
			var inside: bool = Vector2((u - 0.5) / 0.48, (v - 0.56) / 0.5).length() <= 1.0
			var noise: float = rng.randf()
			var ang: float = rng.randf_range(-0.9, 0.9)
			_cells.append({
				"x": x, "y": y, "edge": edge, "noise": noise, "inside": inside,
				"cv": Vector2((u - 0.5) * 2.0, (v - 0.55) * 1.7).limit_length(1.0),
				"drift": Vector2.from_angle(-PI * 0.5 + ang) * rng.randf_range(0.5, 1.0),
				"swirl": rng.randf_range(0.6, 1.4) * (1.0 if rng.randf() < 0.5 else -1.0),
				"dist": rng.randf_range(70.0, 170.0),
				"phase": rng.randf() * TAU,
			})


## reveal 0..1 (1 = inteiro). wind = direcao da tempestade; front = direcao que aponta
## para dentro da nevasca (o lado do corpo que esta mais fundo na neve).
static func draw(game: Node2D, tex: Texture2D, center: Vector2, max_size: Vector2, flip_h: bool, modulate: Color, reveal: float, wind: Vector2, front: Vector2, low: bool) -> void:
	if tex == null:
		return
	if reveal >= 0.999:
		game._draw_entity_fit_flipped(tex, center, max_size, flip_h, modulate, true)
		return
	if _cells.is_empty():
		_build()
	var tex_size: Vector2 = tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale: float = minf(max_size.x / tex_size.x, max_size.y / tex_size.y)
	var draw_size: Vector2 = tex_size * scale
	var origin := Vector2(-draw_size.x * 0.5, max_size.y * 0.5 - draw_size.y)
	var cell_tex: Vector2 = tex_size / Vector2(COLS, ROWS)
	var cell_px: Vector2 = draw_size / Vector2(COLS, ROWS)
	var t: float = float(game.time_alive)
	var fx: float = -1.0 if flip_h else 1.0
	# Vento local: empurra para o lado da tempestade e um pouco para cima.
	var w: Vector2 = (Vector2(wind.x * fx, wind.y) * 0.6 + Vector2(front.x * fx, front.y) * 0.6).normalized()
	var f_local := Vector2(front.x * fx, front.y)
	var mist: float = sin(clampf(reveal, 0.0, 1.0) * PI)
	var body_mid: Vector2 = center + Vector2(0.0, max_size.y * 0.5 - draw_size.y * 0.5)
	# Neblina colada no corpo: esconde as bordas dos pedacos e "funde" com a nevasca.
	for m in range(3):
		game.draw_circle(body_mid + Vector2(sin(t * 1.3 + float(m) * 2.1), cos(t + float(m))) * 10.0, draw_size.x * (0.55 - float(m) * 0.12), Color(SNOW, 0.07 * mist * modulate.a))
	game.draw_set_transform(center, 0.0, Vector2(fx, 1.0))
	var step: int = 2 if low else 1
	for i in range(0, _cells.size(), step):
		var c: Dictionary = _cells[i]
		var side: float = 0.5 + 0.5 * Vector2(c["cv"]).dot(f_local)
		var th: float = clampf(side * 0.42 + float(c["edge"]) * 0.08 + float(c["noise"]) * 0.18, 0.0, 1.0 - BAND)
		var k: float = clampf((reveal - th) / BAND, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		var src := Rect2(Vector2(float(c["x"]), float(c["y"])) * cell_tex, cell_tex)
		var home: Vector2 = origin + Vector2(float(c["x"]), float(c["y"])) * cell_px
		if k >= 0.999:
			game.draw_texture_rect_region(tex, Rect2(home, cell_px), src, modulate)
			continue
		# Pedaco no lugar: so esmaece e embranquece (sem buraco duro).
		if k > 0.01:
			var stay: Color = SNOW.lerp(modulate, sqrt(k))
			stay.a = modulate.a * k
			game.draw_texture_rect_region(tex, Rect2(home, cell_px), src, stay)
		if not bool(c["inside"]):
			continue
		var away: float = 1.0 - k
		var dist: float = float(c["dist"]) * away
		var spin: float = float(c["swirl"]) * away * 2.4 + float(c["phase"])
		var swirl := Vector2(cos(spin + t * 2.0), sin(spin + t * 2.0))
		var off: Vector2 = (Vector2(c["drift"]) * 0.45 + w * 0.9) * dist + swirl * 14.0 * away
		var pos: Vector2 = home + cell_px * 0.5 + off
		var life: float = sin(away * PI)
		# Lasca que voa com o vento (branca, encolhendo).
		if life > 0.05:
			var sz: Vector2 = cell_px * lerpf(0.25, 0.8, k)
			var chip: Color = SNOW.lerp(modulate, k * 0.6)
			chip.a = modulate.a * life * 0.85
			game.draw_texture_rect_region(tex, Rect2(pos - sz * 0.5, sz), src, chip)
			# Flocos que a lasca solta.
			var r: float = 1.8 + 2.2 * away
			game.draw_circle(pos, r * 2.4, Color(SNOW, life * 0.16 * modulate.a))
			game.draw_circle(pos, r, Color(SNOW, life * 0.9 * modulate.a))
			var trail: Vector2 = pos - (w * 0.9 + Vector2(c["drift"]) * 0.45) * 22.0 * away + swirl * 6.0
			game.draw_circle(trail, r * 0.7, Color(SNOW, life * 0.55 * modulate.a))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
