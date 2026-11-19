class_name RTBaileCrowdPresentation
extends RefCounted

## Multidao da Roda (Fase 10). Fileiras densas de borboletas de VARIAS especies
## fecham o chao fora do circulo; so o miolo da Roda fica visivel.
## So apresentacao: colisao e dano da Roda continuam no RTBoss10Controller.
##
## Custo: a disposicao (angulo, fileira, especie, tamanho, tom, espelho, fase do
## balanco) e montada UMA vez por fase num MultiMesh por especie x quadro de
## danca. Giro, crescimento do raio, chegada/saida do publico e balanco na batida
## sao uniforms do shader: por quadro a CPU so troca uniforms (e redesenha 12
## comandos quando o quadro de danca vira). Fica num filho com show_behind_parent,
## criado depois do mapa: acima do chao e abaixo de tudo que o jogo desenha.
## Um anel escuro por baixo cobre o chao entre as borboletas.

const SPECIES := ["b10_monarca", "b10_garrafeira", "b10_sombrinha", "b10_paredinha", "b10_hype", "b10_dancarina"]
## Peso de cada especie no publico (a dancarina e a mais comum).
const SPECIES_WEIGHT := [0.2, 0.14, 0.12, 0.1, 0.14, 0.3]
const FIRST_ROW := 40.0
const SIZE := 70.0
const BUILD_RADIUS := 520.0       # raio maximo da Roda: monta sem buracos
const NORMAL := {"gap": 34.0, "spacing": 40.0, "depth": 900.0}
const LOW := {"gap": 46.0, "spacing": 56.0, "depth": 700.0}
const ARRIVE := 320.0             # de onde o publico vem ao fechar a roda
const FLOATS := 16                # Transform2D (8) + cor (4) + custom (4)
const UNDERLAY := Color(0.07, 0.03, 0.08, 0.93)

const SHADER := """shader_type canvas_item;
uniform vec2 u_center;
uniform float u_inner;
uniform float u_spin;
uniform float u_beat;
uniform float u_appear;
uniform float u_size;
void vertex() {
	float a = INSTANCE_CUSTOM.x + u_spin * INSTANCE_CUSTOM.z;
	float r = u_inner + INSTANCE_CUSTOM.y + (1.0 - u_appear) * %s;
	float phase = abs(INSTANCE_CUSTOM.w);
	float flip = sign(INSTANCE_CUSTOM.w);
	float s = u_size * (0.7 + 0.5 * COLOR.a);
	vec2 p = u_center + vec2(cos(a), sin(a)) * r;
	p.y -= sin(u_beat * 3.14159265 + phase) * 4.0;
	VERTEX = VERTEX * vec2(s * flip, -s) + p;
	COLOR.a = u_appear;
}
""" % ARRIVE

static var instance_count := 0
static var _built_low := -1
static var _groups: Array = []    # [especie * 2 + paridade] -> {mesh, tex0, tex1}


class CrowdLayer extends Node2D:
	var groups: Array = []
	var frame := 0

	func _draw() -> void:
		for k in range(groups.size()):
			var g: Dictionary = groups[k]
			if g.is_empty():
				continue
			var parity: int = k % 2
			var tex: Texture2D = g["tex0"] if (frame + parity) % 2 == 0 else g["tex1"]
			if tex != null:
				draw_multimesh(g["mesh"], tex)


class UnderlayLayer extends Node2D:
	var center := Vector2.ZERO
	var r_in := 0.0
	var r_out := 0.0
	var alpha := 0.0

	func _draw() -> void:
		if alpha <= 0.01:
			return
		var col := Color(UNDERLAY.r, UNDERLAY.g, UNDERLAY.b, UNDERLAY.a * alpha)
		var seg := 48
		for k in range(seg):
			var a0: float = TAU * float(k) / float(seg)
			var a1: float = TAU * float(k + 1) / float(seg)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2.from_angle(a0) * r_in, center + Vector2.from_angle(a1) * r_in,
				center + Vector2.from_angle(a1) * r_out, center + Vector2.from_angle(a0) * r_out,
			]), col)


## Variacao estavel por (fileira, indice).
static func _hash(row: int, i: int) -> int:
	var h: int = (row * 73856093) ^ (i * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


static func _species_for(h: int) -> int:
	var u: float = float(h % 1000) / 1000.0
	var acc := 0.0
	for k in range(SPECIES_WEIGHT.size()):
		acc += float(SPECIES_WEIGHT[k])
		if u < acc:
			return k
	return SPECIES.size() - 1


## Monta a disposicao (uma vez por fase / troca de modo leve). Independe de onde
## a Roda abre: tudo e relativo ao centro e ao raio interno. Duas passadas sobre
## um unico buffer local (escrever num PackedArray dentro de Array o copiaria).
static func build(low: bool) -> void:
	var cfg: Dictionary = LOW if low else NORMAL
	var gap: float = cfg["gap"]
	var spacing: float = cfg["spacing"]
	var groups_n: int = SPECIES.size() * 2
	var rows: Array = []          # [off, count]
	var off: float = FIRST_ROW
	while off <= float(cfg["depth"]):
		rows.append([off, int(TAU * (BUILD_RADIUS + off) / spacing)])
		off += gap
	var counts := PackedInt32Array()
	counts.resize(groups_n)
	for row in range(rows.size()):
		for i in range(int(rows[row][1])):
			var h0: int = _hash(row, i)
			counts[_species_for(h0) * 2 + (h0 >> 3) % 2] += 1
	var cursor := PackedInt32Array()
	cursor.resize(groups_n)
	var total := 0
	for k in range(groups_n):
		cursor[k] = total
		total += counts[k]
	var all := PackedFloat32Array()
	all.resize(total * FLOATS)
	for row in range(rows.size()):
		var r_base: float = rows[row][0]
		var count: int = rows[row][1]
		var step: float = TAU / float(count)
		var dir: float = 1.0 if row % 2 == 0 else -0.6
		var depth: float = clampf(1.0 - 0.04 * float(row), 0.42, 1.0)
		for i in range(count):
			var h: int = _hash(row, i)
			var k: int = _species_for(h) * 2 + (h >> 3) % 2
			var o: int = cursor[k] * FLOATS
			cursor[k] += 1
			var tone: float = depth * (0.88 + float((h >> 17) % 100) / 800.0)
			var flip: float = -1.0 if (h >> 5) % 2 == 0 else 1.0
			all[o] = 1.0
			all[o + 1] = 0.0
			all[o + 2] = 0.0
			all[o + 3] = 0.0
			all[o + 4] = 0.0
			all[o + 5] = 1.0
			all[o + 6] = 0.0
			all[o + 7] = 0.0
			all[o + 8] = tone
			all[o + 9] = tone * (0.94 + float((h >> 19) % 10) / 100.0)
			all[o + 10] = tone
			all[o + 11] = float((h >> 11) % 100) / 100.0
			all[o + 12] = float(i) * step + float(row) * 0.37 + (float(h % 100) / 100.0 - 0.5) * step * 0.5
			all[o + 13] = r_base + (float((h >> 7) % 100) / 100.0 - 0.5) * gap * 0.45
			all[o + 14] = dir
			all[o + 15] = (0.1 + float(h % 628) * 0.01) * flip
	instance_count = total
	_groups.clear()
	var start := 0
	for k in range(groups_n):
		var n: int = counts[k]
		var tex0: Texture2D = RTBailePresentation.tex("%s_0" % SPECIES[k / 2])
		var tex1: Texture2D = RTBailePresentation.tex("%s_1" % SPECIES[k / 2])
		if n == 0 or tex0 == null:
			_groups.append({})
			start += n
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_2D
		mm.use_colors = true
		mm.use_custom_data = true
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		mm.mesh = quad
		mm.instance_count = n
		mm.buffer = all.slice(start * FLOATS, (start + n) * FLOATS)
		# Sem AABB fixo o MultiMesh seria cortado pela posicao "base" das instancias.
		mm.custom_aabb = AABB(Vector3(-100000, -100000, -1), Vector3(200000, 200000, 2))
		_groups.append({"mesh": mm, "tex0": tex0, "tex1": tex1 if tex1 != null else tex0})
		start += n
	_built_low = 1 if low else 0


static func _layers(game: Node2D) -> Array:
	var under: UnderlayLayer = game.get_node_or_null("BaileCrowdUnderlay")
	var crowd: CrowdLayer = game.get_node_or_null("BaileCrowdLayer")
	if under != null and crowd != null:
		return [under, crowd]
	# Precisa nascer depois do mapa para ficar acima do chao.
	if game.phase_map_layer == null or not is_instance_valid(game.phase_map_layer):
		return []
	under = UnderlayLayer.new()
	under.name = "BaileCrowdUnderlay"
	under.show_behind_parent = true
	game.add_child(under)
	crowd = CrowdLayer.new()
	crowd.name = "BaileCrowdLayer"
	crowd.show_behind_parent = true
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = SHADER
	mat.shader = shader
	crowd.material = mat
	game.add_child(crowd)
	return [under, crowd]


## Aquece a disposicao (chamar fora da luta: na entrada da fase).
static func prewarm(low: bool) -> void:
	if _built_low != (1 if low else 0):
		build(low)


## Atualiza a multidao. Chamado a cada quadro do desenho da fase 10.
static func update(game: Node2D, camera: Vector2, viewport: Vector2, active: bool, center: Vector2, inner: float, spin: float, appear: float, beat_pos: float, low: bool) -> void:
	prewarm(low)
	var layers: Array = _layers(game)
	if layers.is_empty():
		return
	var under: UnderlayLayer = layers[0]
	var crowd: CrowdLayer = layers[1]
	var on: bool = active and appear > 0.01
	under.visible = on
	crowd.visible = on
	if not on:
		return
	var c: Vector2 = center - camera
	var far: float = 0.0
	for corner in [Vector2.ZERO, Vector2(viewport.x, 0), viewport, Vector2(0, viewport.y)]:
		far = maxf(far, c.distance_to(corner))
	under.center = c
	under.r_in = inner + FIRST_ROW + (1.0 - appear) * ARRIVE - SIZE * 0.35
	under.r_out = far + 60.0
	under.alpha = appear
	under.queue_redraw()
	var mat: ShaderMaterial = crowd.material
	mat.set_shader_parameter("u_center", c)
	mat.set_shader_parameter("u_inner", inner)
	mat.set_shader_parameter("u_spin", spin)
	mat.set_shader_parameter("u_beat", beat_pos)
	mat.set_shader_parameter("u_appear", appear)
	mat.set_shader_parameter("u_size", SIZE)
	if crowd.groups != _groups:
		crowd.groups = _groups
		crowd.queue_redraw()
	var frame: int = int(beat_pos * 2.0) % 2
	if frame != crowd.frame:
		crowd.frame = frame
		crowd.queue_redraw()


## Esconde as camadas (fora da fase 10 ou sem Roda).
static func hide(game: Node2D) -> void:
	for n in ["BaileCrowdUnderlay", "BaileCrowdLayer"]:
		var node: Node2D = game.get_node_or_null(n)
		if node != null:
			node.visible = false
