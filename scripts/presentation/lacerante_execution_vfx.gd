class_name RTLaceranteExecutionVfx
extends RefCounted

## Visual da execucao da Lacerante: barra de execucao, foco no alvo, 5 variacoes de
## cortes e o golpe final. A folha de sprites (10 quadros x 5 animacoes) substitui a
## Geovana durante a execucao (ver .codex/tasks/lacerante_execution_sprites.md).

const SHEET_PATH := "res://assets/sprites/player/lacerante/execution/execution_sheet.png"
const SHEET_COLS := 10
const SHEET_ROWS := 5
## A folha do jogo e a master do Codex (execution_raw/, 384x320 por celula) em
## meia resolucao: na tela a celula ocupa ~168x140 px, entao a nitidez e a mesma
## com 1/4 da memoria de video (~6 MB em vez de ~24 MB).
const AUTHORED_CELL := Vector2(384.0, 320.0)
const SHEET_DOWNSCALE := 2.0
const CELL := AUTHORED_CELL / SHEET_DOWNSCALE
## Pes da Geovana na celula (centro x, base y), ja na resolucao da folha.
const FEET := Vector2(192.0, 296.0) / SHEET_DOWNSCALE
## Base dos pes medida por animacao na folha master (o pedido era y=296 em todas).
## Na Ascensao (linha 2) vale a base dos quadros no chao; o salto 3-6 e intencional.
const ROW_FEET_Y := [296.0, 290.0, 304.0, 301.0, 307.0]
## player_pos nao e o chao: o ataque normal (attacks.png, celula 256 a 112 px com a
## base em player_pos.y + 40) apoia os pes 24 px abaixo dele. A execucao segue isso.
const GROUND_OFFSET := Vector2(0.0, 24.0)
## Mesma escala de pixel do attacks.png (celula 256 desenhada a 112 px), corrigida
## pela reducao da folha.
const SCALE := 112.0 / 256.0 * SHEET_DOWNSCALE
const CRIMSON := Color(1.0, 0.08, 0.16)
const BLOOD := Color(0.62, 0.0, 0.06)
const WHITE := Color(1.0, 0.96, 0.96)

static var _sheet: Texture2D = null
static var _sheet_checked := false


static func sheet() -> Texture2D:
	if not _sheet_checked:
		_sheet_checked = true
		if ResourceLoader.exists(SHEET_PATH):
			_sheet = load(SHEET_PATH)
	return _sheet


static func hides_player(game: Node2D) -> bool:
	return game.lacerante_execution.is_active() and sheet() != null


## Barra de execucao: faixa ate o dano do Reforco, marcador e cargas de Laceracao.
static func draw_bar_overlay(game: Node2D, pos: Vector2, width: float, height: float, health_ratio: float, ov: Dictionary) -> void:
	var tr: float = float(ov.get("ratio", 0.0))
	var executable: bool = bool(ov.get("executable", false))
	var t: float = float(game.time_alive)
	if tr > 0.0:
		game.draw_rect(Rect2(pos, Vector2(width * tr, height)), Color(1.0, 0.2, 0.26, 0.26), true)
		for i in range(int(width * tr / 5.0)):
			var x: float = pos.x + float(i) * 5.0
			game.draw_line(Vector2(x, pos.y + height), Vector2(minf(x + 4.0, pos.x + width * tr), pos.y), Color(0.0, 0.0, 0.0, 0.28), 1.0)
		var mx: float = pos.x + width * tr
		game.draw_line(Vector2(mx, pos.y - 3.0), Vector2(mx, pos.y + height + 3.0), Color(1.0, 0.9, 0.9, 0.95), 2.0)
	if executable:
		var pulse: float = 0.5 + 0.5 * sin(t * 12.0)
		game.draw_rect(Rect2(pos - Vector2(3.0, 3.0), Vector2(width + 6.0, height + 6.0)), Color(CRIMSON, 0.5 + pulse * 0.4), false, 2.0)
		var icon: Vector2 = pos + Vector2(width + 10.0, height * 0.5)
		game.draw_line(icon + Vector2(-5, 6), icon + Vector2(5, -6), WHITE, 2.4, true)
		game.draw_line(icon + Vector2(-5, -6), icon + Vector2(5, 6), Color(CRIMSON, 0.9), 2.0, true)
	var stacks: int = int(ov.get("stacks", 0))
	for i in range(stacks):
		game.draw_rect(Rect2(pos + Vector2(float(i) * 8.0, height + 3.0), Vector2(6.0, 3.0)), CRIMSON, true)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	var ctrl: RTLaceranteExecutionController = game.lacerante_execution
	var active: Dictionary = ctrl.active
	if not active.is_empty():
		var c: Vector2 = Vector2(active["target_pos"]) - camera
		var t: float = float(active["t"])
		var fade: float = minf(1.0, t / 0.12) * (1.0 - clampf((t - 0.78) / 0.12, 0.0, 1.0))
		game.draw_circle(c, 170.0, Color(0.0, 0.0, 0.0, 0.32 * fade))
		game.draw_arc(c, 62.0 + sin(t * 20.0) * 3.0, 0.0, TAU, 40, Color(CRIMSON, 0.55 * fade), 2.0, true)
		if t < 0.16:
			var from: Vector2 = Vector2(active["from"]) - camera
			var to: Vector2 = game.player_pos - camera
			game.draw_line(from, to, Color(CRIMSON, 0.6 * (1.0 - t / 0.16)), 10.0, true)
			game.draw_line(from, to, Color(WHITE, 0.8 * (1.0 - t / 0.16)), 2.0, true)
		if int(active["anim"]) == 4 and t < 0.45:
			# Corte do Tempo: o mundo "para" antes do golpe.
			game.draw_arc(c, 90.0, -PI * 0.5, -PI * 0.5 + TAU * (t / 0.45), 40, Color(WHITE, 0.6), 2.0, true)
			for i in range(12):
				var a: float = float(i) * TAU / 12.0
				game.draw_line(c + Vector2.from_angle(a) * 82.0, c + Vector2.from_angle(a) * 92.0, Color(WHITE, 0.45), 2.0, true)
		var tex: Texture2D = sheet()
		if tex != null:
			_draw_sheet_frame(game, tex, game.player_pos - camera + GROUND_OFFSET, int(active["anim"]), t, float(active["side"]))
	for ev in ctrl.slash_events:
		_draw_slash(game, Vector2(ev["pos"]) - camera, ev)


static func _draw_sheet_frame(game: Node2D, tex: Texture2D, feet: Vector2, anim: int, t: float, side: float) -> void:
	var frame: int = clampi(int(t / RTLaceranteExecutionController.EXECUTION_TIME * float(SHEET_COLS)), 0, SHEET_COLS - 1)
	var src := Rect2(Vector2(float(frame) * CELL.x, float(anim) * CELL.y), CELL)
	var scale: float = SCALE
	var size: Vector2 = CELL * scale
	var anchor := Vector2(FEET.x, float(ROW_FEET_Y[clampi(anim, 0, ROW_FEET_Y.size() - 1)]) / SHEET_DOWNSCALE)
	var origin: Vector2 = feet - anchor * scale
	if side < 0.0:
		game.draw_set_transform(feet, 0.0, Vector2(-1.0, 1.0))
		game.draw_texture_rect_region(tex, Rect2(-anchor * scale, size), src)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		game.draw_texture_rect_region(tex, Rect2(origin, size), src)


static func _slash_dirs(anim: int, index: int, side: float) -> Array:
	match anim:
		0:
			return [Vector2(side, -0.9)] if index == 0 else ([Vector2(side, 0.9)] if index == 1 else [Vector2(side, -0.12), Vector2(side, 0.12)])
		1:
			return [Vector2.from_angle(float(index) * 2.1 + 0.4)]
		2:
			return [Vector2(0.15 * side, -1.0)] if index == 0 else [Vector2(0.1 * side, 1.0), Vector2(side, 0.0)]
		3:
			var a: float = float(index) * 2.399 + 0.6
			return [Vector2.from_angle(a)] if index < 5 else [Vector2(1, 1), Vector2(1, -1)]
		_:
			return [Vector2(side, 0.05)] if index == 0 else [Vector2(side, 0.0), Vector2(side, -0.35), Vector2(side, 0.35)]


static func _draw_slash(game: Node2D, c: Vector2, ev: Dictionary) -> void:
	var p: float = 1.0 - float(ev["life"]) / maxf(0.01, float(ev["max"]))
	var finisher: bool = bool(ev["finisher"])
	var length: float = 150.0 if finisher else 96.0
	var center: Vector2 = c + Vector2(0, -26)
	var dirs: Array = _slash_dirs(int(ev["anim"]), int(ev["index"]), float(ev["side"]))
	var reveal: float = minf(1.0, p / 0.35)
	var alpha: float = 1.0 - clampf((p - 0.35) / 0.65, 0.0, 1.0)
	for d in dirs:
		var dir: Vector2 = Vector2(d).normalized()
		var a: Vector2 = center - dir * length * 0.5
		var b: Vector2 = a + dir * length * reveal
		game.draw_line(a, b, Color(CRIMSON, 0.35 * alpha), 18.0 if finisher else 12.0, true)
		game.draw_line(a, b, Color(CRIMSON, 0.85 * alpha), 6.0 if finisher else 4.0, true)
		game.draw_line(a, b, Color(WHITE, alpha), 2.0, true)
	if finisher:
		if p < 0.3:
			game.draw_circle(center, 46.0 * (1.0 - p / 0.3) + 8.0, Color(WHITE, 0.55 * (1.0 - p / 0.3)))
		game.draw_arc(center, 30.0 + p * 90.0, 0.0, TAU, 40, Color(CRIMSON, alpha * 0.9), 4.0 * alpha + 1.0, true)
		for i in range(10):
			var ang: float = float(i) * TAU / 10.0 + 0.2
			var r0: float = 20.0 + p * 40.0
			game.draw_line(center + Vector2.from_angle(ang) * r0, center + Vector2.from_angle(ang) * (r0 + 22.0 * alpha), Color(BLOOD, alpha), 3.0, true)
