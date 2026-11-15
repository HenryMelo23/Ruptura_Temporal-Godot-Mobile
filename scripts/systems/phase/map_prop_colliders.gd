class_name RTMapPropColliders
extends RefCounted

## Fisica dos objetos pintados no chao do mundo expandido (cacto, pedra, tronco,
## costela, cristal...). Cada atlas de chao tem um mapa de distancia com sinal (SDF)
## gerado por tools/build_map_collision.py a partir do contorno desenhado de cada
## objeto (tools/map_collision_shapes.json). O jogador e os inimigos que andam no chao
## sao empurrados para fora pelo gradiente e deslizam rente ao contorno real.
##
## Mapa: assets/sprites/experimental/collision/<map_key>.png, 4x4 ladrilhos de 96 px
## (1 texel = 4 unidades do mundo); distancia = (R*256 + G - 32768) / 32.

const DIR := "res://assets/sprites/experimental/collision/"
const RES := 96
const ALTAR_TILE := 5
const FREE := 1000.0
const PLAYER_RADIUS := 13.0
## O sprite da Geovana e desenhado centrado em player_pos; a colisao usa os pes.
const PLAYER_FEET := Vector2(0, 26)
const ENEMY_RADIUS := 18.0
const GRAD_STEP := 4.0

static var _cache: Dictionary = {}


static func _field(game: Node) -> PackedByteArray:
	var ctrl = game.experimental_phase_controller
	if ctrl == null or not ctrl.uses_definitive_world():
		return PackedByteArray()
	var key: String = ctrl.map_key()
	if _cache.has(key):
		return _cache[key]
	var data := PackedByteArray()
	var path := DIR + key + ".png"
	if ResourceLoader.exists(path):
		var tex = load(path)
		var img: Image = tex.get_image() if tex is Texture2D else null
		if img != null:
			if img.is_compressed():
				img.decompress()
			img.convert(Image.FORMAT_RGB8)
			if img.get_width() == RES * 4 and img.get_height() == RES * 4:
				data = img.get_data()
	_cache[key] = data
	return data


static func active(game: Node) -> bool:
	return not _field(game).is_empty()


static func _texel(data: PackedByteArray, tile: int, x: int, y: int) -> float:
	x = clampi(x, 0, RES - 1)
	y = clampi(y, 0, RES - 1)
	var px: int = (tile % 4) * RES + x
	var py: int = (tile / 4) * RES + y
	var i: int = (py * RES * 4 + px) * 3
	return float(int(data[i]) * 256 + int(data[i + 1]) - 32768) / 32.0


## Distancia com sinal (unidades do mundo) ate o objeto solido mais proximo.
static func distance_at(game: Node, pos: Vector2, data: PackedByteArray = PackedByteArray()) -> float:
	if data.is_empty():
		data = _field(game)
		if data.is_empty():
			return FREE
	var ctrl = game.experimental_phase_controller
	var size: float = ctrl.CHUNK_SIZE
	var cell := Vector2i((pos / size).floor())
	var tile: int = ctrl.tile_at_cell(cell)
	if tile == ALTAR_TILE:
		return FREE
	var local: Vector2 = (pos - Vector2(cell) * size) / size * float(RES) - Vector2(0.5, 0.5)
	var x0: int = floori(local.x)
	var y0: int = floori(local.y)
	var fx: float = local.x - float(x0)
	var fy: float = local.y - float(y0)
	var a: float = _texel(data, tile, x0, y0)
	var b: float = _texel(data, tile, x0 + 1, y0)
	var c: float = _texel(data, tile, x0, y0 + 1)
	var d: float = _texel(data, tile, x0 + 1, y0 + 1)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


## Empurra `pos` para fora de qualquer objeto, deslizando pelo contorno.
static func push_out(game: Node, pos: Vector2, radius: float) -> Vector2:
	var data := _field(game)
	if data.is_empty():
		return pos
	var p := pos
	for _i in range(3):
		var dist := distance_at(game, p, data)
		if dist >= radius:
			break
		var grad := Vector2(
			distance_at(game, p + Vector2(GRAD_STEP, 0), data) - distance_at(game, p - Vector2(GRAD_STEP, 0), data),
			distance_at(game, p + Vector2(0, GRAD_STEP), data) - distance_at(game, p - Vector2(0, GRAD_STEP), data))
		if grad.length_squared() < 0.0001:
			grad = Vector2.DOWN
		p += grad.normalized() * (radius - dist + 0.25)
	return p


static func push_player(game: Node, pos: Vector2) -> Vector2:
	if not active(game):
		return pos
	return push_out(game, pos + PLAYER_FEET, PLAYER_RADIUS) - PLAYER_FEET


static func blocked(game: Node, pos: Vector2, radius: float) -> bool:
	return distance_at(game, pos) < radius
