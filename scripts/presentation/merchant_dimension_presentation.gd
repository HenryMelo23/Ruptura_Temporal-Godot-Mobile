class_name RTMerchantDimensionPresentation
extends RefCounted

## Desenho da dimensao do Mercador: o chao da oficina, o teleportador quebrado
## no centro, o proprio Mercador, o portal de saida e a caixa de conversa.
## Enquanto a arte do Codex nao existe, tudo e desenhado proceduralmente com a
## mesma leitura, entao a dimensao e jogavel desde ja.

const ART_ROOT := "res://assets/sprites/merchant/"
const FLOOR := Color(0.16, 0.14, 0.22)
const BRASS := Color(0.85, 0.70, 0.34)
const GLOW := Color(0.52, 0.92, 1.0)
const VOID := Color(0.05, 0.06, 0.16)
## Cenario fixo da oficina, em coordenadas do mundo (ancorado no pe do movel).
const COUNTER_POS := Vector2(322.0, 628.0)
## A textura do chao cobre a dimensao inteira numa peca so: o quarto e menor
## que a folha, entao nao ha mosaico e nenhuma emenda aparece.
const FLOOR_COVER := 1560.0
## Altura da faixa de HUD no topo: nada da fenda pode subir acima disso.
const HUD_BAND := 98.0

static var _cache: Dictionary = {}
static var _seq_cache: Dictionary = {}

## Humor da fala -> sufixo do retrato (portrait_<quem>_<sufixo>[_talk_n|_blink]).
const MOOD_SUFFIX := {
	"triste": "sad", "surpresa": "surprised", "desconfiada": "suspicious",
	"irritada": "annoyed", "decidida": "determined", "preocupada": "worried",
	"animado": "excited", "sorrindo": "happy", "preocupado": "worried",
}
const LOOP_BOX_H := 1.3
const LOOP_FOOT_PAD := 0.03
## Loops do Mercador no mundo (quadros <nome>_0.. em assets/sprites/merchant/).
const MERCHANT_LOOP_FPS := {"merchant_idle_loop": 6.0, "merchant_work_loop": 9.0, "merchant_talk_loop": 8.0, "merchant_cheer_loop": 9.0}


static func art(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var path: String = ART_ROOT + name + ".png"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = tex
	return tex


## Sequencia <base>_0, <base>_1... (vazia se a arte ainda nao existe).
static func seq(base: String) -> Array:
	if _seq_cache.has(base):
		return _seq_cache[base]
	var frames: Array = []
	for i in range(24):
		var tex: Texture2D = art("%s_%d" % [base, i])
		if tex == null:
			break
		frames.append(tex)
	_seq_cache[base] = frames
	return frames


static func seq_frame(base: String, fps: float, t: float) -> Texture2D:
	var frames: Array = seq(base)
	if frames.is_empty():
		return null
	return frames[int(floor(t * fps)) % frames.size()]


# ================================================================ mundo
static func draw_world(game: Node2D, camera: Vector2) -> void:
	var dim: RTMerchantDimension = game._merchant_dimension()
	if not dim.active:
		return
	var t: float = float(game.time_alive)
	_draw_floor(game, camera, t)
	_draw_exit_portal(game, camera, t)
	_draw_workshop(game, camera, t)
	_draw_merchant(game, camera, t, dim)


static func _draw_floor(game: Node2D, camera: Vector2, t: float) -> void:
	var size: Vector2 = RTMerchantDimension.WORLD_SIZE
	var rect := Rect2(-camera, size)
	var tex: Texture2D = art("floor")
	if tex != null:
		# Escala uniforme, cobrindo o mundo todo: sem repetir, sem distorcer.
		var fit := Rect2(-camera, Vector2(FLOOR_COVER, FLOOR_COVER))
		game.draw_texture_rect(tex, fit, false)
		# O piso e vistoso demais cru: escurece para a Geovana continuar legivel.
		game.draw_rect(rect, Color(0.04, 0.05, 0.12, 0.46), true)
	else:
		game.draw_rect(rect, FLOOR, true)
		# Ladrilhos da oficina, para a corrida ter referencia de distancia.
		var step := 150.0
		var cols: int = int(size.x / step) + 1
		var rows: int = int(size.y / step) + 1
		for i in range(cols):
			for j in range(rows):
				if (i + j) % 2 != 0:
					continue
				var tile := Rect2(Vector2(float(i) * step, float(j) * step) - camera, Vector2(step, step))
				game.draw_rect(tile, Color(0.20, 0.18, 0.27, 0.55), true)
		for i in range(cols):
			var x: float = float(i) * step - camera.x
			game.draw_line(Vector2(x, -camera.y), Vector2(x, size.y - camera.y), Color(0.30, 0.26, 0.38, 0.6), 1.0)
		for j in range(rows):
			var y: float = float(j) * step - camera.y
			game.draw_line(Vector2(-camera.x, y), Vector2(size.x - camera.x, y), Color(0.30, 0.26, 0.38, 0.6), 1.0)
		# Tapete de trabalho em volta da geringonca. Com a arte do piso o arco
		# virava um fio solto no chao, entao so aparece no modo procedural.
		game.draw_circle(RTMerchantDimension.TELEPORTER_POS - camera, 230.0, Color(0.26, 0.20, 0.30, 0.55))
		game.draw_arc(RTMerchantDimension.TELEPORTER_POS - camera, 230.0, 0.0, TAU, 60, Color(BRASS.r, BRASS.g, BRASS.b, 0.35), 2.0)
	# Beirada da dimensao: o vazio que engole quem passa do limite.
	game.draw_rect(rect, Color(0.42, 0.72, 1.0, 0.22), false, 6.0)


static func _draw_exit_portal(game: Node2D, camera: Vector2, t: float) -> void:
	var at: Vector2 = RTMerchantDimension.EXIT_PORTAL_POS - camera
	var tex: Texture2D = art("exit_portal")
	if tex != null:
		var s: Vector2 = tex.get_size()
		var scale: float = 118.0 / maxf(1.0, maxf(s.x, s.y))
		game.draw_set_transform(at, 0.0, Vector2(scale, scale))
		game.draw_texture(tex, -s * 0.5)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		for ring in range(3):
			var r: float = 44.0 - float(ring) * 11.0 + sin(t * 2.4 + float(ring)) * 3.0
			game.draw_arc(at, r, t * (1.4 + float(ring) * 0.5), t * (1.4 + float(ring) * 0.5) + PI * 1.5, 28, Color(GLOW.r, GLOW.g, GLOW.b, 0.8 - 0.2 * float(ring)), 3.0, true)
		game.draw_circle(at, 22.0, Color(VOID.r, VOID.g, VOID.b, 0.85))
	game._draw_centered("SAÍDA", at + Vector2(0, -64), 14, Color(GLOW.r, GLOW.g, GLOW.b, 0.9))


## Desenha um movel/cenario ancorado pelo pe, na escala pedida. `flip` espelha
## para a mesma arte nao se repetir identica pela sala toda.
static func _draw_prop(game: Node2D, tex: Texture2D, foot: Vector2, height: float, flip: bool = false, tilt: float = 0.0, shade: float = 1.0) -> void:
	var s: Vector2 = tex.get_size()
	var scale: float = height / maxf(1.0, s.y)
	# Poca de contato: sem ela os moveis parecem colados no ar.
	var width: float = s.x * scale
	game.draw_texture_rect(RTWorldLighting.light_texture(), Rect2(foot - Vector2(width * 0.62, height * 0.13), Vector2(width * 1.24, height * 0.26)), false, Color(0.0, 0.0, 0.0, 0.34))
	game.draw_set_transform(foot, deg_to_rad(tilt), Vector2(-scale if flip else scale, scale))
	game.draw_texture(tex, Vector2(-s.x * 0.5, -s.y), Color(shade, shade, shade, 1.0))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Marcas no chao: tapete, oleo, queimadura, parafusos e moedas. Entram ANTES
## dos moveis e sem poca de contato, porque sao parte do piso.
## [arte, centro, largura, inclinacao, opacidade]
const DECALS: Array = [
	["decal_rug", Vector2(812.0, 574.0), 206.0, 0.0, 0.8],
	["decal_oil", Vector2(636.0, 706.0), 150.0, 18.0, 0.85],
	["decal_oil", Vector2(1186.0, 414.0), 118.0, -40.0, 0.7],
	["decal_scorch", Vector2(904.0, 764.0), 140.0, 8.0, 0.8],
	["decal_scorch", Vector2(262.0, 332.0), 122.0, -25.0, 0.7],
	["decal_bolts", Vector2(482.0, 542.0), 108.0, 12.0, 0.9],
	["decal_coins", Vector2(384.0, 702.0), 104.0, -10.0, 0.95],
]

## Oficina cheia de verdade: fileira de maquinas na parede de cima, moveis
## encostados nas laterais e miudeza espalhada pelo meio, sem fechar o caminho
## da entrada ate o Mercador nem a volta ate o portal de saida. Cada copia
## ainda varia escala, lado, inclinacao e luz.
## [arte, pe, altura, espelhado, inclinacao, luz]
const PROPS: Array = [
	# Parede de cima: a fileira de maquinas do conserto.
	["forge", Vector2(152.0, 252.0), 150.0, false, 0.0, 1.0],
	["workbench", Vector2(332.0, 238.0), 122.0, false, -2.0, 0.96],
	["stove", Vector2(502.0, 246.0), 142.0, false, 0.0, 1.0],
	["teleporter_off", Vector2(666.0, 258.0), 150.0, false, -3.0, 0.9],
	["ring_half", Vector2(842.0, 252.0), 148.0, true, 4.0, 1.0],
	["generator", Vector2(1012.0, 250.0), 144.0, false, 0.0, 0.97],
	["shelf_tall", Vector2(1182.0, 254.0), 166.0, false, 0.0, 1.0],
	["cabinet", Vector2(1344.0, 252.0), 158.0, true, 0.0, 0.93],
	# Parede da esquerda.
	["shelf_low", Vector2(152.0, 424.0), 116.0, false, 0.0, 1.0],
	["maptable", Vector2(164.0, 582.0), 130.0, false, 2.0, 0.95],
	["armchair", Vector2(150.0, 762.0), 126.0, true, -2.0, 1.0],
	["crates", Vector2(158.0, 912.0), 112.0, false, 3.0, 0.9],
	# Parede da direita.
	["safe", Vector2(1352.0, 444.0), 120.0, false, 0.0, 1.0],
	["barrel", Vector2(1346.0, 602.0), 116.0, true, -3.0, 0.96],
	["wheelbarrow", Vector2(1340.0, 762.0), 116.0, true, 2.0, 1.0],
	["crate_fallen", Vector2(1336.0, 906.0), 106.0, false, 5.0, 0.92],
	# Meio da sala.
	["scales", Vector2(432.0, 422.0), 110.0, false, 0.0, 1.0],
	["lamp_hanging", Vector2(902.0, 334.0), 122.0, false, 0.0, 1.0],
	["books", Vector2(984.0, 424.0), 86.0, true, -4.0, 1.0],
	["toolbox", Vector2(1122.0, 534.0), 80.0, false, 6.0, 0.95],
	["sign", Vector2(1214.0, 646.0), 112.0, false, -2.0, 1.0],
	["cables", Vector2(962.0, 642.0), 70.0, true, 0.0, 0.92],
	["coil", Vector2(1104.0, 704.0), 106.0, false, 0.0, 1.0],
	["plant", Vector2(268.0, 702.0), 116.0, true, 0.0, 1.0],
	["lamp_floor", Vector2(470.0, 764.0), 136.0, false, 0.0, 1.0],
	["crates", Vector2(1004.0, 874.0), 96.0, true, -6.0, 1.04],
	["scrap", Vector2(1186.0, 852.0), 100.0, false, 4.0, 0.95],
	["pet", Vector2(642.0, 884.0), 76.0, true, 0.0, 1.0],
]


## Moveis que brilham: cor e raio da poca de luz que eles jogam no chao.
const PROP_LIGHTS: Dictionary = {
	"forge": [Color(1.0, 0.55, 0.18), 118.0],
	"stove": [Color(1.0, 0.62, 0.26), 92.0],
	"generator": [Color(0.46, 0.92, 1.0), 104.0],
	"lamp_floor": [Color(0.52, 0.94, 1.0), 126.0],
	"lamp_hanging": [Color(0.52, 0.94, 1.0), 110.0],
	"coil": [Color(0.46, 0.92, 1.0), 96.0],
	"ring_half": [Color(0.42, 0.88, 1.0), 84.0],
	"barrel": [Color(0.42, 0.86, 1.0), 78.0],
}


## Marca de chao: centralizada, deitada no piso, sem poca de contato.
static func _draw_decals(game: Node2D, camera: Vector2, view: Rect2) -> void:
	for entry in DECALS:
		var pos: Vector2 = entry[1]
		if not view.has_point(pos):
			continue
		var tex: Texture2D = art(String(entry[0]))
		if tex == null:
			continue
		var s: Vector2 = tex.get_size()
		var scale: float = float(entry[2]) / maxf(1.0, s.x)
		game.draw_set_transform(pos - camera, deg_to_rad(float(entry[3])), Vector2(scale, scale))
		game.draw_texture(tex, -s * 0.5, Color(1.0, 1.0, 1.0, float(entry[4])))
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Cenario da oficina e as pecas ja entregues.
static func _draw_props(game: Node2D, camera: Vector2) -> void:
	var view := Rect2(camera - Vector2(300.0, 300.0), Vector2(game.get_viewport_rect().size) + Vector2(600.0, 600.0))
	_draw_decals(game, camera, view)
	for entry in PROPS:
		var pos: Vector2 = entry[1]
		if not view.has_point(pos):
			continue
		var name: String = String(entry[0])
		var tex: Texture2D = art(name)
		if tex == null:
			continue
		if PROP_LIGHTS.has(name) and bool(game.gfx_particles):
			var light: Array = PROP_LIGHTS[name]
			var radius: float = float(light[1]) * (0.94 + 0.06 * sin(float(game.time_alive) * 2.4 + pos.x * 0.01))
			var tint: Color = light[0]
			game.draw_texture_rect(RTWorldLighting.light_texture(), Rect2(pos - camera - Vector2(radius, radius * 0.72), Vector2(radius * 2.0, radius * 1.44)), false, Color(tint.r, tint.g, tint.b, 0.16))
		_draw_prop(game, tex, pos - camera, float(entry[2]), bool(entry[3]), float(entry[4]), float(entry[5]))
	var counter: Texture2D = art("counter")
	if counter != null:
		_draw_prop(game, counter, COUNTER_POS - camera, 128.0)
	# Pecas do teleportador ja encontradas, em fila na bancada.
	var part: Texture2D = art("part")
	var npc: RTMerchantNpc = game._merchant_npc()
	if part == null or npc.parts <= 0:
		return
	for i in range(npc.parts):
		var at: Vector2 = COUNTER_POS + Vector2(-44.0 + float(i) * 23.0, -138.0) - camera
		_draw_prop(game, part, at, 34.0)


## O teleportador no centro: a geringonca que vive abrindo sozinha.
static func _draw_workshop(game: Node2D, camera: Vector2, t: float) -> void:
	var at: Vector2 = RTMerchantDimension.TELEPORTER_POS - camera
	# Ele arde em pulsos: e isso que abre a fenda sem ninguem pedir.
	var lit: bool = fposmod(t, 3.4) < 1.1
	var tex: Texture2D = art("teleporter" if lit else "teleporter_off")
	if tex == null:
		tex = art("teleporter")
	if tex != null:
		_draw_props(game, camera)
		if lit:
			var pulse: float = 0.18 + 0.1 * sin(t * 6.0)
			game.draw_circle(at + Vector2(0.0, -44.0), 92.0, Color(GLOW.r, GLOW.g, GLOW.b, pulse))
		_draw_prop(game, tex, at + Vector2(0.0, 64.0), 190.0)
		return
	# Base, arco e faiscas do conserto.
	game.draw_circle(at + Vector2(0, 18), 96.0, Color(0.06, 0.07, 0.12, 0.8))
	game.draw_arc(at + Vector2(0, 18), 96.0, 0.0, TAU, 44, Color(BRASS.r, BRASS.g, BRASS.b, 0.75), 3.0)
	for leg in range(3):
		var a: float = float(leg) * TAU / 3.0 + 0.4
		game.draw_line(at + Vector2.from_angle(a) * 70.0 + Vector2(0, 18), at + Vector2(0, -58), Color(BRASS.r, BRASS.g, BRASS.b, 0.9), 5.0)
	var core_r: float = 30.0 + sin(t * 3.2) * 4.0
	game.draw_circle(at + Vector2(0, -58), core_r, Color(GLOW.r, GLOW.g, GLOW.b, 0.26))
	game.draw_arc(at + Vector2(0, -58), core_r, -t * 2.2, -t * 2.2 + PI * 1.3, 26, Color(0.8, 1.0, 1.0, 0.9), 2.5, true)
	if fposmod(t, 1.7) < 0.14:
		for spark in range(5):
			var sa: float = float(spark) * 1.27 + t
			game.draw_line(at + Vector2(0, -58), at + Vector2(0, -58) + Vector2.from_angle(sa) * 40.0, Color(1.0, 0.86, 0.4, 0.8), 2.0)


static func _draw_merchant(game: Node2D, camera: Vector2, t: float, dim: RTMerchantDimension) -> void:
	var at: Vector2 = RTMerchantDimension.MERCHANT_POS - camera
	var npc: RTMerchantNpc = game._merchant_npc()
	var pose: String = _merchant_pose(game, npc, t)
	var loop: String = _merchant_loop(game, npc)
	var tex: Texture2D = seq_frame(loop, float(MERCHANT_LOOP_FPS.get(loop, 8.0)), t)
	# Quadros de loop (tools/talk_slice.py) tem folga em cima e dos lados:
	# a altura dele em pe e 1/LOOP_BOX_H da imagem e os pes ficam a
	# LOOP_FOOT_PAD da base.
	var looped: bool = tex != null
	if tex == null:
		tex = art(pose)
	if tex == null:
		tex = art("merchant")
	if tex != null:
		var s: Vector2 = tex.get_size()
		var scale: float = (118.0 * LOOP_BOX_H if looped else 118.0) / maxf(1.0, s.y)
		var pad: float = s.y * LOOP_FOOT_PAD / LOOP_BOX_H if looped else 0.0
		game.draw_set_transform(at, 0.0, Vector2(scale, scale))
		game.draw_texture(tex, Vector2(-s.x * 0.5, -s.y + pad))
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		_draw_merchant_placeholder(game, at, t)
	# O balao sobe 138 px, mas nunca entra na faixa do HUD: quando ele esta
	# colado no topo da sala, o texto desce para continuar legivel.
	var speech_y: float = maxf(at.y - 138.0, HUD_BAND + 76.0)
	if npc.bubble != "":
		_draw_bubble(game, Vector2(at.x, speech_y), npc.bubble, clampf(npc.bubble_timer, 0.0, 1.0))
	elif not game._dialogue().busy():
		var hint: String = "TOQUE NELE PARA NEGOCIAR" if game.player_pos.distance_to(RTMerchantDimension.MERCHANT_POS) > RTMerchantDimension.TALK_RADIUS else ""
		if hint != "":
			game._draw_centered(hint, Vector2(at.x, speech_y - 10.0), 13, Color(0.7, 0.78, 0.9, 0.7))


## Pose dele: comemora no balao, conserta quando ela esta longe, conversa perto.
static func _merchant_pose(game: Node2D, npc: RTMerchantNpc, t: float) -> String:
	if npc.bubble != "":
		return "merchant_cheer"
	var far: bool = game.player_pos.distance_to(RTMerchantDimension.MERCHANT_POS) > RTMerchantDimension.TALK_RADIUS * 1.6
	if far and not game._dialogue().busy():
		return "merchant_work"
	return "merchant_idle_%02d" % (1 + int(t * 3.0) % 2)


## Loop animado equivalente a pose: conserta longe dela, gesticula quando e
## ele falando, comemora no balao, e respira/pisca no resto do tempo.
static func _merchant_loop(game: Node2D, npc: RTMerchantNpc) -> String:
	if npc.bubble != "":
		return "merchant_cheer_loop"
	var talk: RTDialogueController = game._dialogue()
	if talk.busy():
		return "merchant_talk_loop" if talk.speaker() == "mercador" and not talk.fully_revealed() else "merchant_idle_loop"
	if game.player_pos.distance_to(RTMerchantDimension.MERCHANT_POS) > RTMerchantDimension.TALK_RADIUS * 1.6:
		return "merchant_work_loop"
	return "merchant_idle_loop"


## Retrato da caixa de dialogo: boca mexendo enquanto o texto corre, piscada
## de vez em quando parado. Cai para o retrato neutro se o humor nao tiver arte.
static func _portrait(game: Node2D, talk: RTDialogueController, who: String) -> Texture2D:
	var t: float = float(game.time_alive)
	var bases: Array = []
	var suffix: String = String(MOOD_SUFFIX.get(talk.mood(), ""))
	if suffix != "":
		bases.append("portrait_%s_%s" % [who, suffix])
	bases.append("portrait_" + who)
	for base in bases:
		if art(base) == null and seq(base + "_talk").is_empty():
			continue
		if not talk.fully_revealed():
			var mouth: Texture2D = seq_frame(base + "_talk", 9.0, t)
			if mouth != null:
				return mouth
		elif fposmod(t, 3.4) < 0.13 and art(base + "_blink") != null:
			return art(base + "_blink")
		if art(base) != null:
			return art(base)
	return null


## Enquanto a arte nao chega: alien de bigode, para a silhueta ja ler certo.
static func _draw_merchant_placeholder(game: Node2D, at: Vector2, t: float) -> void:
	var bob: float = sin(t * 2.0) * 3.0
	var body := at + Vector2(0.0, bob)
	game.draw_circle(body + Vector2(0, -40), 34.0, Color(0.36, 0.78, 0.52))
	game.draw_circle(body + Vector2(-12, -46), 6.0, Color(0.05, 0.05, 0.08))
	game.draw_circle(body + Vector2(12, -46), 6.0, Color(0.05, 0.05, 0.08))
	# O bigode e a marca registrada: grande e simetrico.
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array([
			body + Vector2(0, -32), body + Vector2(side * 16.0, -38.0),
			body + Vector2(side * 34.0, -30.0), body + Vector2(side * 20.0, -24.0),
		])
		game.draw_colored_polygon(pts, Color(0.92, 0.86, 0.78))
	var torso := PackedVector2Array([body + Vector2(-26, -14), body + Vector2(26, -14), body + Vector2(20, 24), body + Vector2(-20, 24)])
	game.draw_colored_polygon(torso, Color(0.52, 0.22, 0.42))
	game.draw_polyline(PackedVector2Array([torso[0], torso[1], torso[2], torso[3], torso[0]]), Color(BRASS.r, BRASS.g, BRASS.b, 0.9), 2.0, true)
	var arm: float = sin(t * 7.0) * 10.0
	game.draw_line(body + Vector2(18, -6), body + Vector2(44, -24 + arm), Color(0.36, 0.78, 0.52), 6.0)


static func _draw_bubble(game: Node2D, at: Vector2, text: String, alpha: float) -> void:
	var width: float = clampf(float(text.length()) * 7.4 + 26.0, 120.0, 420.0)
	var rect := Rect2(at - Vector2(width * 0.5, 30.0), Vector2(width, 44.0))
	game.draw_rect(rect, Color(0.04, 0.05, 0.09, 0.92 * alpha), true)
	game.draw_rect(rect, Color(BRASS.r, BRASS.g, BRASS.b, 0.9 * alpha), false, 2.0)
	game.draw_colored_polygon(PackedVector2Array([at + Vector2(-9, 14), at + Vector2(9, 14), at + Vector2(0, 26)]), Color(0.04, 0.05, 0.09, 0.92 * alpha))
	game._draw_centered(text, at - Vector2(0.0, 2.0), 14, Color(1.0, 0.95, 0.86, alpha))


# ================================================================ tela de cartas
## A tela de cartas abre DENTRO da oficina, entao o fundo e a oficina: o braco
## da Geovana com o bracelete nao existe mais nesta loja.
static func draw_shop_backdrop(game: Node2D, viewport: Vector2) -> void:
	var tex: Texture2D = art("floor")
	if tex != null:
		var cover: float = maxf(viewport.x, viewport.y) * 1.2
		var at := Vector2((viewport.x - cover) * 0.5, (viewport.y - cover) * 0.5)
		game.draw_texture_rect(tex, Rect2(at, Vector2(cover, cover)), false)
	else:
		game.draw_rect(Rect2(Vector2.ZERO, viewport), FLOOR, true)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.02, 0.03, 0.07, 0.80), true)
	# O Mercador encostado na borda, olhando a compra acontecer.
	var merchant: Texture2D = art("merchant_cheer")
	if merchant == null:
		merchant = art("merchant")
	if merchant != null:
		var h: float = clampf(viewport.y * 0.44, 140.0, 300.0)
		_draw_prop(game, merchant, Vector2(viewport.x * 0.11, viewport.y * 1.02), h)
	var scrap: Texture2D = art("scrap")
	if scrap != null:
		var sh: float = clampf(viewport.y * 0.26, 90.0, 190.0)
		_draw_prop(game, scrap, Vector2(viewport.x * 0.93, viewport.y * 1.03), sh, true)


## No lugar do bracelete: a geringonca de bancada dele que projeta o visor.
## O centro continua sendo o pivo da animacao das cartas compradas.
static func draw_shop_projector(game: Node2D, center: Vector2, open: float, now: float, small: bool) -> void:
	var tex: Texture2D = art("part")
	var height: float = 76.0 if not small else 58.0
	if tex != null:
		_draw_prop(game, tex, center + Vector2(0.0, height * 0.46), height)
	else:
		game.draw_rect(Rect2(center - Vector2(46.0, 16.0), Vector2(92.0, 32.0)), Color(0.18, 0.12, 0.2), true)
		game.draw_rect(Rect2(center - Vector2(46.0, 16.0), Vector2(92.0, 32.0)), Color(BRASS.r, BRASS.g, BRASS.b, 0.9), false, 2.0)
	var pulse: float = 0.5 + 0.5 * sin(now * 4.0)
	game.draw_circle(center, 22.0 + pulse * 5.0 + open * 6.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.14 + 0.10 * open))
	game.draw_circle(center, 9.0, Color(0.72, 0.98, 1.0, 0.92))
	game.draw_arc(center, 13.0, now * 1.4, now * 1.4 + PI * 1.4, 22, Color(GLOW.r, GLOW.g, GLOW.b, 0.85), 2.0, true)


# ================================================================ interface
## Cronometro da fenda e caixa de conversa, em espaco de tela.
static func draw_overlay(game: Node2D, viewport: Vector2) -> void:
	var dim: RTMerchantDimension = game._merchant_dimension()
	# Durante a fala o relogio esta parado e a tela e dele: nada de barra.
	var talking: bool = game._dialogue().busy()
	if dim.active and not dim.stable() and not talking:
		_draw_timer(game, viewport, dim)
		if dim.counting_down():
			_draw_countdown(game, viewport, dim)
	if dim.active and dim.mp_ready and not dim.counting_down() and not talking:
		_draw_team_wait(game, viewport, dim)
	if dim.active and dim.collapsing > 0.0:
		var k: float = clampf(dim.collapsing / RTMerchantDimension.COLLAPSE_TIME, 0.0, 1.0)
		game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.5, 0.08, 0.12, 0.45 * (1.0 - k)), true)
	_draw_dialogue(game, viewport)


## Barra da fenda. Fica ABAIXO da faixa do HUD: no topo ela colidia com o
## relogio do centro e com os paineis das pontas.
static func _draw_timer(game: Node2D, viewport: Vector2, dim: RTMerchantDimension) -> void:
	var left: float = dim.remaining()
	var ratio: float = clampf(left / maxf(1.0, dim.limit), 0.0, 1.0)
	var w: float = minf(320.0, viewport.x * 0.46)
	var top: float = maxf(HUD_BAND, viewport.y * 0.145)
	var rect := Rect2(Vector2(viewport.x * 0.5 - w * 0.5, top), Vector2(w, 14.0))
	var danger: bool = dim.urgent()
	var col: Color = Color(1.0, 0.34, 0.34) if danger else Color(0.5, 0.9, 1.0)
	if danger:
		col.a = 0.65 + 0.35 * sin(float(game.time_alive) * 12.0)
	game.draw_rect(rect, Color(0.03, 0.04, 0.07, 0.86), true)
	game.draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), col, true)
	game.draw_rect(rect, Color(0.7, 0.8, 0.95, 0.5), false, 1.5)
	game._draw_centered("ESTABILIDADE DA FENDA  %ds" % int(ceil(left)), rect.get_center() + Vector2(0.0, 20.0), 12, Color(0.86, 0.92, 1.0))


## Barra da fenda DENTRO da tela de cartas. O relogio corre enquanto ela
## escolhe, entao ela precisa ver o relogio correndo - sem isso o tempo some
## sem aviso e a expulsao parece injusta.
static func draw_shop_timer(game: Node2D, viewport: Vector2, visor: Rect2) -> void:
	var dim: RTMerchantDimension = game._merchant_dimension()
	if not dim.active or dim.stable() or game._dialogue().busy():
		return
	var left: float = dim.remaining()
	var ratio: float = clampf(left / maxf(1.0, dim.limit), 0.0, 1.0)
	var w: float = minf(360.0, visor.size.x * 0.42)
	var top: float = visor.position.y + 26.0
	var rect := Rect2(Vector2(viewport.x * 0.5 - w * 0.5, top), Vector2(w, 13.0))
	var danger: bool = dim.urgent()
	var beat: float = 0.5 + 0.5 * sin(float(game.time_alive) * 11.0)
	var col: Color = Color(1.0, 0.34, 0.34) if danger else Color(BRASS.r, BRASS.g, BRASS.b, 1.0)
	if danger:
		col.a = 0.6 + 0.4 * beat
	game.draw_rect(rect.grow(3.0), Color(0.02, 0.02, 0.05, 0.9), true)
	game.draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), col, true)
	game.draw_rect(rect, Color(0.75, 0.68, 0.5, 0.55), false, 1.5)
	var label: String = "A FENDA FECHA EM %ds" % int(ceil(left))
	var tint := Color(1.0, 0.92, 0.78, 0.95)
	if danger:
		label = "SAIA DO BALCÃO  %ds" % int(ceil(left))
		tint = Color(1.0, 0.55 - 0.25 * beat, 0.45 - 0.2 * beat)
	game._draw_centered_outlined(label, rect.get_center() + Vector2(0.0, 24.0), 15 if danger else 13, tint, Color(0.0, 0.0, 0.0, 0.9), 3)


## Contagem regressiva grande dos ultimos segundos: numero pulsando, aviso de
## correr para a saida, seta apontando o portal e as bordas piscando.
static func _draw_countdown(game: Node2D, viewport: Vector2, dim: RTMerchantDimension) -> void:
	var left: float = dim.remaining()
	var urgency: float = clampf(1.0 - left / RTMerchantDimension.COUNTDOWN_SECONDS, 0.0, 1.0)
	var now: float = float(game.time_alive)
	var beat: float = 0.5 + 0.5 * sin(now * lerpf(5.0, 13.0, urgency))
	# Bordas pulsando em vermelho, sem cobrir o meio da tela.
	var edge := Color(1.0, 0.18, 0.22, (0.10 + 0.22 * urgency) * (0.45 + 0.55 * beat))
	var band: float = 26.0 + 22.0 * urgency
	game.draw_rect(Rect2(Vector2.ZERO, Vector2(viewport.x, band)), edge, true)
	game.draw_rect(Rect2(Vector2(0.0, viewport.y - band), Vector2(viewport.x, band)), edge, true)
	game.draw_rect(Rect2(Vector2.ZERO, Vector2(band, viewport.y)), edge, true)
	game.draw_rect(Rect2(Vector2(viewport.x - band, 0.0), Vector2(band, viewport.y)), edge, true)
	var center := Vector2(viewport.x * 0.5, viewport.y * 0.30)
	var size: int = int((56.0 if viewport.x < 900.0 else 72.0) * (1.0 + 0.07 * beat))
	var tint := Color(1.0, lerpf(0.72, 0.1, urgency), lerpf(0.5, 0.1, urgency))
	game._draw_centered_outlined(str(int(ceil(left))), center, size, tint, Color(0.0, 0.0, 0.0, 1.0), 6)
	var warn: String = "CORRA PARA A SAÍDA"
	if dim.mp_ready:
		warn = "AGUARDANDO A EQUIPE  %d/%d" % [dim.mp_ready_total(), maxi(1, int(game.shop_mp_expected_count))]
	elif dim.multiplayer_room():
		warn = "TODOS PRECISAM TOCAR A SAÍDA"
	game._draw_centered_outlined(warn, center + Vector2(0.0, size * 0.72), 16, Color(1.0, 0.9, 0.86), Color(0.0, 0.0, 0.0, 0.9), 3)
	if not dim.mp_ready:
		_draw_exit_arrow(game, viewport, center + Vector2(0.0, size * 0.72 + 34.0), beat)


## Seta curta apontando o portal, para ninguem perder o caminho no susto.
static func _draw_exit_arrow(game: Node2D, viewport: Vector2, at: Vector2, beat: float) -> void:
	var to: Vector2 = RTMerchantDimension.EXIT_PORTAL_POS - Vector2(game.player_pos)
	if to.length() < 24.0:
		return
	var dir: Vector2 = to.normalized()
	var tip: Vector2 = at + dir * (18.0 + 6.0 * beat)
	var side: Vector2 = dir.orthogonal() * 11.0
	var tail: Vector2 = at - dir * 9.0
	game.draw_colored_polygon(PackedVector2Array([tip, tail + side, tail - side]), Color(0.55, 0.95, 1.0, 0.75 + 0.25 * beat))


## Aviso calmo de quem ja chegou no portal e espera os companheiros.
static func _draw_team_wait(game: Node2D, viewport: Vector2, dim: RTMerchantDimension) -> void:
	var text: String = "NA SAÍDA  %d/%d  ESPERANDO A EQUIPE" % [dim.mp_ready_total(), maxi(1, int(game.shop_mp_expected_count))]
	var at := Vector2(viewport.x * 0.5, maxf(HUD_BAND, viewport.y * 0.145) + 46.0)
	game._draw_centered_outlined(text, at, 15, Color(0.62, 0.95, 1.0), Color(0.0, 0.0, 0.0, 0.9), 3)


## Caixa estilo RPG: retrato de um lado, texto do outro, avanca no toque.
static func _draw_dialogue(game: Node2D, viewport: Vector2) -> void:
	var talk: RTDialogueController = game._dialogue()
	if not talk.busy():
		return
	var who: String = talk.speaker()
	var portrait_size: float = clampf(viewport.y * 0.3, 96.0, 168.0)
	var box_h: float = clampf(viewport.y * 0.3, 132.0, 196.0)
	var margin: float = 16.0
	var box := Rect2(Vector2(margin, viewport.y - box_h - margin), Vector2(viewport.x - margin * 2.0, box_h))
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.03, 0.45), true)
	game.draw_rect(box, Color(0.04, 0.05, 0.10, 0.96), true)
	game.draw_rect(box, Color(BRASS.r, BRASS.g, BRASS.b, 0.9), false, 2.5)
	# Retrato encostado na borda de cima da caixa.
	var portrait_rect := Rect2(box.position + Vector2(10.0, -portrait_size * 0.52), Vector2(portrait_size, portrait_size))
	var portrait: Texture2D = _portrait(game, talk, who)
	game.draw_rect(portrait_rect, Color(0.02, 0.03, 0.07, 0.95), true)
	if portrait != null:
		game._draw_entity_fit(portrait, portrait_rect.get_center(), portrait_rect.size)
	else:
		_draw_portrait_placeholder(game, portrait_rect, who)
	game.draw_rect(portrait_rect, Color(BRASS.r, BRASS.g, BRASS.b, 0.95), false, 2.0)
	# Ele so vira "Bussola" na placa depois de se apresentar.
	var name_text: String = "GEOVANA"
	if who == "mercador":
		name_text = "BÚSSOLA" if game._merchant_npc().seen.has("intro") else "MERCADOR"
	game.draw_string(game.font, portrait_rect.position + Vector2(0.0, portrait_rect.size.y + 18.0), name_text, HORIZONTAL_ALIGNMENT_CENTER, portrait_rect.size.x, 13, Color(BRASS.r, BRASS.g, BRASS.b, 1.0))
	var text_rect := Rect2(Vector2(portrait_rect.end.x + 18.0, box.position.y + 18.0), Vector2(box.end.x - portrait_rect.end.x - 34.0, box.size.y - 44.0))
	game._draw_wrapped(talk.visible_text(), text_rect, 17, Color(0.94, 0.95, 1.0))
	if talk.fully_revealed():
		var arrow: Vector2 = Vector2(box.end.x - 26.0, box.end.y - 18.0 + sin(float(game.time_alive) * 5.0) * 2.5)
		game.draw_colored_polygon(PackedVector2Array([arrow + Vector2(-7, -5), arrow + Vector2(7, -5), arrow + Vector2(0, 5)]), Color(BRASS.r, BRASS.g, BRASS.b, 0.95))


static func _draw_portrait_placeholder(game: Node2D, rect: Rect2, who: String) -> void:
	var c: Vector2 = rect.get_center()
	if who == "mercador":
		game.draw_circle(c + Vector2(0, 6), rect.size.x * 0.3, Color(0.36, 0.78, 0.52))
		for side in [-1.0, 1.0]:
			game.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, 14), c + Vector2(side * rect.size.x * 0.16, 8.0),
				c + Vector2(side * rect.size.x * 0.33, 18.0), c + Vector2(side * rect.size.x * 0.18, 24.0),
			]), Color(0.92, 0.86, 0.78))
		game.draw_circle(c + Vector2(-10, 0), 4.0, Color(0.05, 0.05, 0.08))
		game.draw_circle(c + Vector2(10, 0), 4.0, Color(0.05, 0.05, 0.08))
	else:
		var tex: Texture2D = game._get_texture("player")
		if tex != null:
			game._draw_entity_fit(tex, c, rect.size * 0.85)
		else:
			game.draw_circle(c, rect.size.x * 0.28, Color(0.5, 0.75, 1.0))
