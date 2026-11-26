extends RefCounted

## Execucao da Coletora (Foice do Tempo): quando um inimigo morre pela
## execucao, a foice surge de particulas de sombra, toma angulo, ceifa o
## inimigo no meio e as duas metades explodem. So visual: a morte ja aconteceu
## no dano; aqui desenhamos uma copia do inimigo (textura, tamanho e lado
## guardados no instante da execucao).
##
## Linha do tempo (s): 0-0,26 sombras se juntam | 0,26-0,38 toma angulo |
## 0,38-0,5 corte | 0,5-0,8 metades se separam e explodem.

const T_FORM := 0.26
const T_AIM := 0.38
const T_CUT := 0.5
const T_END := 0.8
const LIMIT := 6
const SHADOW := Color(0.08, 0.02, 0.1)
const BLADE := Color(0.95, 0.1, 0.24)
const EDGE := Color(1.0, 0.82, 0.86)

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


## Inimigo executado: guarda a aparencia dele para a animacao. Com muitas
## execucoes ao mesmo tempo, as mais antigas cedem lugar (celular).
func on_execute(enemy: Dictionary) -> void:
	if core == null:
		return
	if fx.size() >= LIMIT:
		fx.pop_front()
	var size: Vector2 = core._enemy_draw_size(enemy)
	fx.append({
		"pos": Vector2(enemy.get("pos", core.player_pos)) + core._enemy_visual_offset(enemy),
		"tex": core._enemy_texture(enemy),
		"size": size,
		"flip": bool(core._enemy_should_flip(enemy)),
		"side": -1.0 if Vector2(enemy.get("pos", core.player_pos)).x < float(core.player_pos.x) else 1.0,
		"seed": core.rng.randf_range(0.0, TAU),
		"t": 0.0,
		"scale": clampf(size.y / 64.0, 0.8, 1.8),
	})


## Chefe executado: foice grande, sem a copia cortada (o chefe tem morte propria).
func on_execute_boss() -> void:
	if core == null:
		return
	if fx.size() >= LIMIT:
		fx.pop_front()
	fx.append({"pos": Vector2(core.boss_pos), "tex": null, "size": Vector2(160, 160), "flip": false, "side": 1.0, "seed": 0.7, "t": 0.0, "scale": 2.6})


func draw(game: Node2D, camera: Vector2) -> void:
	for item in fx:
		_draw_one(game, item, camera)


func _draw_one(game: Node2D, item: Dictionary, camera: Vector2) -> void:
	var t: float = float(item["t"])
	var at: Vector2 = Vector2(item["pos"]) - camera
	var s: float = float(item["scale"])
	var side: float = float(item["side"])
	var seed: float = float(item["seed"])
	# Onde a foice nasce: ao lado e acima do inimigo.
	var hold: Vector2 = at + Vector2(-side * 46.0 * s, -38.0 * s)
	if t < T_CUT:
		_draw_victim(game, item, at, 0.0, t)
	else:
		_draw_victim(game, item, at, smoothstep(T_CUT, T_END, t), t)
	if t < T_FORM:
		_draw_gathering(game, hold, s, seed, t / T_FORM)
	var angle: float = _blade_angle(t, side)
	var blade_alpha: float = clampf(t / T_FORM, 0.0, 1.0) * (1.0 - smoothstep(T_CUT + 0.12, T_END, t))
	var pivot: Vector2 = hold.lerp(at + Vector2(side * 34.0 * s, -8.0 * s), smoothstep(T_AIM, T_CUT, t))
	if t >= T_AIM and t < T_CUT + 0.08:
		_draw_sweep_trail(game, at, s, side, smoothstep(T_AIM, T_CUT, t))
	if blade_alpha > 0.01:
		_draw_scythe(game, pivot, angle, s, blade_alpha, side)
	if t >= T_CUT:
		_draw_burst(game, at, s, seed, smoothstep(T_CUT, T_END, t))
	if t >= T_CUT - 0.04 and t < T_CUT + 0.12:
		var flash: float = 1.0 - absf(t - T_CUT) / 0.12
		var half: float = float(Vector2(item["size"]).x) * 0.75
		game.draw_line(at + Vector2(-half, -6.0 * s), at + Vector2(half, 6.0 * s), Color(EDGE, flash), 5.0 * s)
		game.draw_line(at + Vector2(-half, -6.0 * s), at + Vector2(half, 6.0 * s), Color(BLADE, flash * 0.8), 11.0 * s)


## Angulo da lamina: aparece deitada, recua (toma angulo) e desce no corte.
func _blade_angle(t: float, side: float) -> float:
	var rest: float = -0.6
	var wind: float = -2.2
	var cut: float = 1.2
	var a: float = rest
	if t >= T_FORM and t < T_AIM:
		a = lerpf(rest, wind, smoothstep(T_FORM, T_AIM, t))
	elif t >= T_AIM:
		a = lerpf(wind, cut, smoothstep(T_AIM, T_CUT, t))
	return a * side


func _draw_gathering(game: Node2D, hold: Vector2, s: float, seed: float, k: float) -> void:
	# Fiapos de sombra espiralam para dentro ate formar a foice.
	for i in range(14):
		var a: float = seed + float(i) * TAU / 14.0 + k * 3.0
		var r: float = lerpf(70.0, 4.0, k) * s * (0.7 + 0.3 * sin(float(i) * 2.1))
		var p: Vector2 = hold + Vector2.from_angle(a) * r
		var tail: Vector2 = hold + Vector2.from_angle(a - 0.5) * (r + 12.0 * s)
		game.draw_line(tail, p, Color(0.16, 0.02, 0.14, 0.7 * k + 0.25), 5.0 * s)
		game.draw_circle(p, 3.5 * s, Color(0.55, 0.06, 0.25, 0.8 * (1.0 - k) + 0.2))
	var glow: Texture2D = RTWorldLighting.light_texture()
	var r2: float = 60.0 * s * k
	game.draw_texture_rect(glow, Rect2(hold - Vector2(r2, r2), Vector2(r2, r2) * 2.0), false, Color(0.3, 0.0, 0.15, 0.6 * k))


func _draw_scythe(game: Node2D, pivot: Vector2, angle: float, s: float, alpha: float, side: float) -> void:
	var dir: Vector2 = Vector2.from_angle(angle)
	var normal: Vector2 = dir.orthogonal() * side
	var handle_len: float = 92.0 * s
	var head: Vector2 = pivot + dir * handle_len
	var tail: Vector2 = pivot - dir * 26.0 * s
	var glow: Texture2D = RTWorldLighting.light_texture()
	var aura: float = 70.0 * s
	game.draw_texture_rect(glow, Rect2(head - Vector2(aura, aura), Vector2(aura, aura) * 2.0), false, Color(0.35, 0.02, 0.12, 0.55 * alpha))
	game.draw_line(tail, head, Color(0.05, 0.02, 0.04, alpha), 9.0 * s)
	game.draw_line(tail, head, Color(0.42, 0.24, 0.2, alpha), 4.0 * s)
	game.draw_circle(tail, 4.5 * s, Color(BLADE, alpha))
	# Lamina curva na ponta do cabo.
	var pts := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in range(9):
		var u: float = float(i) / 8.0
		var curve: Vector2 = head + normal * (u * 78.0 * s) - dir * (sin(u * PI * 0.9) * 30.0 * s + u * u * 16.0 * s)
		pts.append(curve)
		inner.append(curve + dir * (22.0 * (1.0 - u) * s + 2.0 * s))
	var blade := PackedVector2Array(pts)
	for i in range(inner.size() - 1, -1, -1):
		blade.append(inner[i])
	game.draw_colored_polygon(blade, Color(SHADOW.lerp(BLADE, 0.55), alpha))
	game.draw_polyline(inner, Color(SHADOW, alpha), 2.0 * s)
	game.draw_polyline(pts, Color(EDGE, alpha), 3.0 * s)
	game.draw_circle(head, 6.0 * s, Color(BLADE, alpha))


func _draw_sweep_trail(game: Node2D, at: Vector2, s: float, side: float, k: float) -> void:
	var r: float = 52.0 * s
	var start: float = (-2.4 if side > 0.0 else -0.7)
	var arc: float = 2.2 * k * side
	game.draw_arc(at + Vector2(-side * 10.0 * s, -10.0 * s), r, start, start + arc, 20, Color(BLADE, 0.55 * (1.0 - k * 0.5)), 6.0 * s)
	game.draw_arc(at + Vector2(-side * 10.0 * s, -10.0 * s), r, start, start + arc, 20, Color(EDGE, 0.8), 2.0 * s)


## Copia do inimigo: inteira ate o corte; depois, duas metades se afastam e somem.
func _draw_victim(game: Node2D, item: Dictionary, at: Vector2, split: float, t: float) -> void:
	var tex: Texture2D = item.get("tex")
	if tex == null:
		return
	var size: Vector2 = item["size"]
	var tsize: Vector2 = tex.get_size()
	var flip: bool = bool(item["flip"])
	var fade: float = 1.0 - smoothstep(0.55, 1.0, split)
	var base := Rect2(at - size * 0.5, size)
	if split <= 0.0:
		var shake: float = sin(t * 70.0) * 1.5 if t > T_AIM else 0.0
		_draw_tex(game, tex, Rect2(base.position + Vector2(shake, 0), size), Rect2(Vector2.ZERO, tsize), flip, Color(1, 1, 1, 1))
		return
	var drift: float = split * 26.0
	var top_src := Rect2(Vector2.ZERO, Vector2(tsize.x, tsize.y * 0.5))
	var bot_src := Rect2(Vector2(0, tsize.y * 0.5), Vector2(tsize.x, tsize.y * 0.5))
	var top := Rect2(base.position + Vector2(-drift, -drift * 0.8), Vector2(size.x, size.y * 0.5))
	var bot := Rect2(base.position + Vector2(drift * 0.6, size.y * 0.5 + drift * 0.3), Vector2(size.x, size.y * 0.5))
	var burn := Color(1.0, 0.55, 0.6, fade)
	_draw_tex(game, tex, top, top_src, flip, burn)
	_draw_tex(game, tex, bot, bot_src, flip, burn)
	# Linha do corte brilhando entre as metades.
	game.draw_line(top.position + Vector2(0, top.size.y), top.position + Vector2(top.size.x, top.size.y), Color(EDGE, fade), 2.0)


func _draw_tex(game: Node2D, tex: Texture2D, dst: Rect2, src: Rect2, flip: bool, tint: Color) -> void:
	if flip:
		dst = Rect2(Vector2(dst.end.x, dst.position.y), Vector2(-dst.size.x, dst.size.y))
	game.draw_texture_rect_region(tex, dst, src, tint)


func _draw_burst(game: Node2D, at: Vector2, s: float, seed: float, k: float) -> void:
	var glow: Texture2D = RTWorldLighting.light_texture()
	var r: float = (30.0 + 60.0 * k) * s
	game.draw_texture_rect(glow, Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(BLADE, 0.55 * (1.0 - k)))
	game.draw_arc(at, (10.0 + 56.0 * k) * s, 0.0, TAU, 28, Color(BLADE, 0.9 * (1.0 - k)), 3.0 * s)
	for i in range(16):
		var a: float = seed + float(i) * TAU / 16.0
		var d: float = (8.0 + 70.0 * k * (0.6 + 0.4 * sin(float(i) * 3.3))) * s
		var p: Vector2 = at + Vector2.from_angle(a) * d
		var c: Color = BLADE if i % 3 != 0 else Color(0.2, 0.04, 0.12)
		game.draw_rect(Rect2(p - Vector2(2, 2) * s, Vector2(4, 4) * s), Color(c, 1.0 - k), true)
