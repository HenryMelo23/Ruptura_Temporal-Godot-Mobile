extends RefCounted

## Execucao da Coletora (Foice do Tempo). Quando um inimigo morre pela
## execucao, a foice (quadros em assets/sprites/coletora_scythe/) surge da
## sombra, toma angulo, ceifa o inimigo no meio e se desfaz; o inimigo se parte
## e explode, a barra de vida e ceifada junto e a alma sobe. So visual: a morte
## ja aconteceu no dano; desenhamos uma copia do inimigo e da barra dele.
##
## Linha do tempo (s):
##   0,00-0,32 foice forma (form_0..7)      | barra pisca em vermelho
##   0,32-0,44 toma angulo (recua)           |
##   0,44-0,54 corte (gira) + rastro (slash) |
##   0,54      inimigo se parte; barra escoa, quebra em duas e cai
##   0,54-0,86 explosao (burst_0..7)
##   0,58-0,82 foice se desfaz (dissolve_0..5)
##   0,60-1,40 alma sobe ondulando (soul_0..7) e some

const ROOT := "res://assets/sprites/coletora_scythe/"
const T_FORM := 0.32
const T_AIM := 0.44
const T_CUT := 0.54
const T_BURST := 0.32
const T_DISSOLVE := 0.58
const T_SOUL := 0.6
const T_END := 1.4
const LIMIT := 6
## Empunhadura na scythe.png (512x512); a foice tem ~420 px de altura.
const GRIP := Vector2(256, 440)
const SCYTHE_ART_H := 420.0
const BAR_W := 60.0

static var _frames: Dictionary = {}

var core: Node = null
var fx: Array = []


func configure(runtime_core: Node) -> void:
	core = runtime_core


func reset() -> void:
	fx.clear()


func on_enemy_killed(_enemy: Dictionary) -> void:
	pass


func movement_speed_bonus() -> float:
	return 0.0


func update(delta: float) -> void:
	for i in range(fx.size() - 1, -1, -1):
		fx[i]["t"] = float(fx[i]["t"]) + delta
		if float(fx[i]["t"]) >= T_END:
			fx.remove_at(i)


static func _seq(name: String, count: int) -> Array:
	if _frames.has(name):
		return _frames[name]
	var out: Array = []
	for i in range(count):
		var path := "%s%s_%d.png" % [ROOT, name, i]
		if not ResourceLoader.exists(path):
			out.clear()
			break
		out.append(load(path))
	_frames[name] = out
	return out


static func _art(name: String) -> Texture2D:
	if _frames.has(name):
		return _frames[name]
	var path := ROOT + name + ".png"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_frames[name] = tex
	return tex


## Inimigo executado (chamado antes da vida zerar): guarda aparencia e barra.
func on_execute(enemy: Dictionary) -> void:
	if core == null:
		return
	if fx.size() >= LIMIT:
		fx.pop_front()
	var size: Vector2 = core._enemy_draw_size(enemy)
	var pos: Vector2 = Vector2(enemy.get("pos", core.player_pos)) + core._enemy_visual_offset(enemy)
	fx.append({
		"pos": pos,
		"tex": core._enemy_texture(enemy),
		"size": size,
		"flip": bool(core._enemy_should_flip(enemy)),
		"side": -1.0 if pos.x < float(core.player_pos.x) else 1.0,
		"t": 0.0,
		"scale": clampf(size.y / 70.0, 0.85, 1.7),
		"ratio": clampf(float(enemy.get("hp", 0.0)) / maxf(0.001, float(enemy.get("max_hp", 1.0))), 0.0, 1.0),
		"bar": core._enemy_health_bar_style(enemy),
	})


## Chefe executado: foice grande, sem copia nem barra (o chefe tem morte propria).
func on_execute_boss() -> void:
	if core == null:
		return
	if fx.size() >= LIMIT:
		fx.pop_front()
	fx.append({"pos": Vector2(core.boss_pos), "tex": null, "size": Vector2(170, 170), "flip": false, "side": 1.0, "t": 0.0, "scale": 2.4, "ratio": 0.0, "bar": {}})


func draw(game: Node2D, camera: Vector2) -> void:
	if fx.is_empty() or _art("scythe") == null:
		return
	for item in fx:
		_draw_one(game, item, camera)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_one(game: Node2D, item: Dictionary, camera: Vector2) -> void:
	var t: float = float(item["t"])
	var at: Vector2 = Vector2(item["pos"]) - camera
	var s: float = float(item["scale"])
	var side: float = float(item["side"])
	var size: Vector2 = item["size"]
	var split: float = smoothstep(T_CUT, T_CUT + 0.3, t)
	if t < T_CUT + 0.3:
		_draw_victim(game, item, at, split, t)
	_draw_bar(game, item, at, t)
	# A foice fica do lado oposto ao da Geovana e corta atravessando o inimigo.
	var grip: Vector2 = at + Vector2(side * size.x * 1.2, -size.y * 0.05)
	var angle: float = _blade_angle(t)
	var scale: float = size.y * 1.35 / SCYTHE_ART_H
	if t < T_FORM:
		var form: Array = _seq("form", 8)
		if not form.is_empty():
			_draw_scythe_frame(game, form[mini(form.size() - 1, int(t / T_FORM * float(form.size())))], grip, angle, scale, side, 1.0)
	elif t < T_DISSOLVE:
		_draw_scythe_frame(game, _art("scythe"), grip, angle, scale, side, 1.0)
	else:
		var dis: Array = _seq("dissolve", 6)
		var k: int = int((t - T_DISSOLVE) / 0.24 * float(dis.size()))
		if not dis.is_empty() and k < dis.size():
			_draw_scythe_frame(game, dis[k], grip, angle, scale, side, 1.0)
	if t >= T_AIM + 0.02 and t < T_CUT + 0.16:
		var slash: Array = _seq("slash", 6)
		var k2: int = int((t - T_AIM - 0.02) / 0.24 * float(slash.size()))
		if not slash.is_empty() and k2 < slash.size():
			var w: float = size.x * 2.4 / 512.0
			_draw_centered(game, slash[k2], at + Vector2(0, -size.y * 0.05), Vector2(256, 128), w * (-side if side < 0.0 else 1.0), w, side * 0.18)
	if t >= T_CUT and t < T_CUT + T_BURST:
		var burst: Array = _seq("burst", 8)
		var k3: int = int((t - T_CUT) / T_BURST * float(burst.size()))
		if not burst.is_empty() and k3 < burst.size():
			var b: float = size.x * 2.6 / 256.0
			_draw_centered(game, burst[k3], at, Vector2(128, 128), b, b, 0.0)
	if t >= T_SOUL:
		_draw_soul(game, at, size, s, t)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Angulo da foice (radianos, 0 = de pe): inclinada, recua e desce no corte.
func _blade_angle(t: float) -> float:
	var rest: float = -0.25
	var wind: float = -0.95
	var cut: float = 2.05
	if t < T_FORM:
		return rest
	if t < T_AIM:
		return lerpf(rest, wind, ease(smoothstep(T_FORM, T_AIM, t), 0.5))
	return lerpf(wind, cut, ease(smoothstep(T_AIM, T_CUT, t), 2.4))


func _draw_scythe_frame(game: Node2D, tex: Texture2D, grip: Vector2, angle: float, scale: float, side: float, alpha: float) -> void:
	if tex == null:
		return
	# Empunhadura a esquerda do alvo: arte original (lamina para a direita).
	# A direita: espelhada, e o giro tambem.
	game.draw_set_transform(grip, angle * -side, Vector2(scale * -side, scale))
	game.draw_texture(tex, -GRIP, Color(1, 1, 1, alpha))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_centered(game: Node2D, tex: Texture2D, at: Vector2, anchor: Vector2, sx: float, sy: float, rot: float) -> void:
	game.draw_set_transform(at, rot, Vector2(sx, sy))
	game.draw_texture(tex, -anchor)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Copia do inimigo: treme no recuo; no corte, as metades se afastam e somem.
func _draw_victim(game: Node2D, item: Dictionary, at: Vector2, split: float, t: float) -> void:
	var tex: Texture2D = item.get("tex")
	if tex == null:
		return
	var size: Vector2 = item["size"]
	var tsize: Vector2 = tex.get_size()
	var flip: bool = bool(item["flip"])
	var base := Rect2(at - size * 0.5, size)
	if split <= 0.0:
		var shake: float = sin(t * 70.0) * 1.5 if t > T_FORM else 0.0
		var dread := Color(1.0, 1.0 - 0.35 * smoothstep(0.0, T_CUT, t), 1.0 - 0.35 * smoothstep(0.0, T_CUT, t))
		_draw_tex(game, tex, Rect2(base.position + Vector2(shake, 0), size), Rect2(Vector2.ZERO, tsize), flip, dread)
		return
	var fade: float = 1.0 - split
	var drift: float = split * 30.0
	var side: float = float(item["side"])
	var top := Rect2(base.position + Vector2(side * drift, -drift * 0.7), Vector2(size.x, size.y * 0.5))
	var bot := Rect2(base.position + Vector2(-side * drift * 0.5, size.y * 0.5 + drift * 0.4), Vector2(size.x, size.y * 0.5))
	var tint := Color(1.0, 0.5, 0.55, fade)
	_draw_tex(game, tex, top, Rect2(Vector2.ZERO, Vector2(tsize.x, tsize.y * 0.5)), flip, tint)
	_draw_tex(game, tex, bot, Rect2(Vector2(0, tsize.y * 0.5), Vector2(tsize.x, tsize.y * 0.5)), flip, tint)


func _draw_tex(game: Node2D, tex: Texture2D, dst: Rect2, src: Rect2, flip: bool, tint: Color) -> void:
	if flip:
		dst = Rect2(Vector2(dst.end.x, dst.position.y), Vector2(-dst.size.x, dst.size.y))
	game.draw_texture_rect_region(tex, dst, src, tint)


## Barra de vida ceifada: pisca em vermelho, escoa a zero, quebra em duas e cai.
func _draw_bar(game: Node2D, item: Dictionary, at: Vector2, t: float) -> void:
	var style: Dictionary = item["bar"]
	if style.is_empty() or t > T_CUT + 0.36:
		return
	var size: Vector2 = item["size"]
	var h: float = float(style.get("height", 7.0))
	var pos: Vector2 = at + Vector2(-BAR_W * 0.5, -size.y * 0.55 - 10.0)
	var back := Color(style.get("back", Color(0.04, 0.06, 0.06, 0.9)))
	var border := Color(style.get("border", Color(0.7, 1.0, 0.7)))
	var red := Color(0.95, 0.08, 0.24)
	var ratio: float = float(item["ratio"])
	if t < T_CUT:
		var pulse: float = 0.5 + 0.5 * sin(t * 30.0)
		game.draw_rect(Rect2(pos - Vector2(2, 2), Vector2(BAR_W + 4, h + 4)), Color(0, 0, 0, 0.62), true)
		game.draw_rect(Rect2(pos, Vector2(BAR_W, h)), back, true)
		game.draw_rect(Rect2(pos, Vector2(BAR_W * ratio, h)), red.lerp(Color(1, 0.8, 0.85), pulse * 0.4), true)
		game.draw_rect(Rect2(pos, Vector2(BAR_W, h)), border.lerp(red, pulse), false, 1.4)
		return
	# Depois do corte: a vida que sobrava escoa e a barra se parte no meio.
	var k: float = (t - T_CUT) / 0.36
	var drain: float = ratio * (1.0 - smoothstep(0.0, 0.25, k))
	var fall: float = smoothstep(0.2, 1.0, k)
	var alpha: float = 1.0 - smoothstep(0.55, 1.0, k)
	for half in [0, 1]:
		var dir: float = -1.0 if half == 0 else 1.0
		var off := Vector2(dir * (2.0 + fall * 10.0), fall * fall * 26.0)
		var piece := Rect2(pos + Vector2(BAR_W * 0.5 * float(half), 0) + off, Vector2(BAR_W * 0.5 - 1.0, h))
		game.draw_set_transform(piece.get_center(), dir * fall * 0.5, Vector2.ONE)
		var local := Rect2(-piece.size * 0.5, piece.size)
		game.draw_rect(local, Color(back, back.a * alpha), true)
		var fill_w: float = clampf(BAR_W * drain - BAR_W * 0.5 * float(half), 0.0, piece.size.x)
		if fill_w > 0.0:
			game.draw_rect(Rect2(local.position, Vector2(fill_w, h)), Color(red, alpha), true)
		game.draw_rect(local, Color(red, alpha), false, 1.4)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Alma sobe ondulando e some.
func _draw_soul(game: Node2D, at: Vector2, size: Vector2, s: float, t: float) -> void:
	var soul: Array = _seq("soul", 8)
	if soul.is_empty():
		return
	var k: float = (t - T_SOUL) / (T_END - T_SOUL)
	var frame: Texture2D = soul[int((t - T_SOUL) * 12.0) % soul.size()]
	var rise: float = ease(k, 0.6) * (70.0 + size.y * 0.6) * s
	var sway: float = sin(t * 7.0) * 6.0 * s
	var alpha: float = smoothstep(0.0, 0.15, k) * (1.0 - smoothstep(0.6, 1.0, k))
	var sc: float = size.y * 0.75 / 192.0 * (0.9 + 0.2 * k)
	game.draw_set_transform(at + Vector2(sway, -rise), 0.0, Vector2(sc, sc))
	game.draw_texture(frame, -Vector2(64, 176), Color(1, 1, 1, alpha))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
