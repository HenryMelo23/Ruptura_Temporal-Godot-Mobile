class_name RTMapPropPresentation
extends Node2D

## Camada visual elevada para os mesmos objetos que RTMapPropColliders torna
## solidos. Reamostra a arte original do atlas; nao cria nem altera colisao.

const COLLISION_DIR := "res://assets/sprites/experimental/collision/"
const COLLISION_RES := 96
const ALTAR_TILE := 5
const HEIGHT_BY_MAP := {
	"map_phase_ex2": 7.0,
	"map_phase_ex6": 5.0,
	"map_phase_ex7": 6.0,
	"map_phase_ex8": 8.0,
}
const SIDE_TINT_BY_MAP := {
	"map_phase_ex2": Color(0.48, 0.62, 0.72),
	"map_phase_ex6": Color(0.52, 0.46, 0.30),
	"map_phase_ex7": Color(0.42, 0.27, 0.22),
	"map_phase_ex8": Color(0.56, 0.39, 0.27),
}
const PROP_SHADER_CODE := """shader_type canvas_item;
render_mode unshaded;

uniform sampler2D ground_terrain : filter_nearest, repeat_disable;
uniform sampler2D collision_field : filter_nearest, repeat_disable;
uniform vec2 camera_origin = vec2(0.0);
uniform vec2 altar_cell = vec2(-99999.0);
uniform vec3 side_tint = vec3(0.5);
uniform float chunk_size = 384.0;
uniform float height_world = 6.0;
uniform bool low_resource = false;
varying vec2 world_position;

void vertex() { world_position = VERTEX + camera_origin; }

float tile_id(vec2 cell) {
	if (all(lessThan(abs(cell - altar_cell), vec2(0.1)))) { return 5.0; }
	float id = mod(cell.x * 7.0 + cell.y * 11.0 + floor(cell.y / 3.0) * 4.0, 15.0);
	return id >= 5.0 ? id + 1.0 : id;
}

vec2 field_uv(float id, vec2 local) {
	vec2 tile = vec2(mod(id, 4.0), floor(id / 4.0));
	return (tile + clamp(local, vec2(0.002), vec2(0.998))) / 4.0;
}

float signed_distance(float id, vec2 local) {
	vec4 packed = texture(collision_field, field_uv(id, local));
	float high_byte = floor(packed.r * 255.0 + 0.5);
	float low_byte = floor(packed.g * 255.0 + 0.5);
	return (high_byte * 256.0 + low_byte - 32768.0) / 32.0;
}

float solid_mask(float id, vec2 local, float feather) {
	return smoothstep(feather, -feather, signed_distance(id, local));
}

vec3 ground_color(float id, vec2 local) {
	vec2 tile = vec2(mod(id, 4.0), floor(id / 4.0));
	vec2 cropped = mix(vec2(0.095), vec2(0.905), clamp(local, vec2(0.0), vec2(1.0)));
	return texture(ground_terrain, (tile + cropped) / 4.0).rgb;
}

vec4 over(vec4 under, vec3 color, float alpha) {
	float out_alpha = alpha + under.a * (1.0 - alpha);
	vec3 out_rgb = out_alpha > 0.001
		? (color * alpha + under.rgb * under.a * (1.0 - alpha)) / out_alpha
		: vec3(0.0);
	return vec4(out_rgb, out_alpha);
}

void fragment() {
	vec2 cell = floor(world_position / chunk_size);
	float id = tile_id(cell);
	if (id == 5.0) { discard; }
	vec2 local = world_position / chunk_size - cell;
	float lift = height_world / chunk_size;
	vec2 lifted_source = local + vec2(0.0, lift);
	float base = solid_mask(id, local, 1.7);
	float top = solid_mask(id, lifted_source, 1.7);
	float side = max(base - top, 0.0);
	float shadow = 0.0;
	if (!low_resource) {
		vec2 shadow_source = local - vec2(4.0, 5.0) / chunk_size;
		shadow = max(solid_mask(id, shadow_source, 3.4) - max(base, top), 0.0);
	}
	if (top <= 0.001 && side <= 0.001 && shadow <= 0.001) { discard; }
	vec4 result = vec4(0.0);
	result = over(result, vec3(0.015, 0.012, 0.018), shadow * 0.34);
	vec3 side_color = ground_color(id, local) * mix(vec3(0.42), side_tint, 0.32);
	result = over(result, side_color, side * 0.96);
	result = over(result, ground_color(id, lifted_source), top * 0.995);
	COLOR = result;
}
"""

static var _collision_cache: Dictionary = {}
static var _solid_tiles_cache: Dictionary = {}

var _ground_texture: Texture2D
var _collision_texture: Texture2D
var _chunks: Array[Dictionary] = []
var _shader_material: ShaderMaterial


func _init() -> void:
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_shader_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = PROP_SHADER_CODE
	_shader_material.shader = shader
	material = _shader_material


static func _collision_texture_for_key(map_key: String) -> Texture2D:
	if _collision_cache.has(map_key):
		return _collision_cache[map_key]
	var texture: Texture2D = null
	var path := COLLISION_DIR + map_key + ".png"
	if ResourceLoader.exists(path):
		texture = load(path)
	_collision_cache[map_key] = texture
	return texture


static func _solid_tiles_for_key(map_key: String, texture: Texture2D) -> Array[int]:
	if _solid_tiles_cache.has(map_key):
		return _solid_tiles_cache[map_key]
	var result: Array[int] = []
	if texture == null:
		_solid_tiles_cache[map_key] = result
		return result
	var image := texture.get_image()
	if image == null:
		_solid_tiles_cache[map_key] = result
		return result
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGB8)
	if image.get_width() != COLLISION_RES * 4 or image.get_height() != COLLISION_RES * 4:
		_solid_tiles_cache[map_key] = result
		return result
	var bytes := image.get_data()
	var width := image.get_width()
	for tile in range(16):
		if tile == ALTAR_TILE:
			continue
		var found := false
		for y in range(COLLISION_RES):
			for x in range(COLLISION_RES):
				var px := (tile % 4) * COLLISION_RES + x
				var py := (tile / 4) * COLLISION_RES + y
				var index := (py * width + px) * 3
				var distance := float(int(bytes[index]) * 256 + int(bytes[index + 1]) - 32768) / 32.0
				if distance < 0.0:
					found = true
					break
			if found:
				break
		if found:
			result.append(tile)
	_solid_tiles_cache[map_key] = result
	return result


static func supported(game: Node) -> bool:
	if game.experimental_phase_controller == null or not game.experimental_phase_controller.uses_definitive_world():
		return false
	return _collision_texture_for_key(game.experimental_phase_controller.map_key()) != null


static func solid_tiles(game: Node) -> Array[int]:
	var key: String = game.experimental_phase_controller.map_key()
	return _solid_tiles_for_key(key, _collision_texture_for_key(key)).duplicate()


static func present_for(game: Node2D, ground_texture: Texture2D, chunks: Array[Dictionary], camera: Vector2, altar: Vector2, low_resource: bool) -> void:
	var layer := game.get_node_or_null("MapPropLayer") as RTMapPropPresentation
	if not supported(game):
		if layer != null:
			layer.hide()
		return
	if layer == null:
		layer = RTMapPropPresentation.new()
		layer.name = "MapPropLayer"
		game.add_child(layer)
	layer.present(game, ground_texture, chunks, camera, altar, low_resource)


static func hide_for(game: Node) -> void:
	var layer := game.get_node_or_null("MapPropLayer") as RTMapPropPresentation
	if layer != null:
		layer.hide()


func present(game: Node, ground_texture: Texture2D, chunks: Array[Dictionary], camera: Vector2, altar: Vector2, low_resource: bool) -> void:
	var map_key: String = game.experimental_phase_controller.map_key()
	var collision_texture := _collision_texture_for_key(map_key)
	var solid: Array[int] = _solid_tiles_for_key(map_key, collision_texture)
	var visible_chunks: Array[Dictionary] = []
	for chunk in chunks:
		if int(chunk.get("tile", ALTAR_TILE)) in solid:
			visible_chunks.append(chunk)
	var geometry_changed := _ground_texture != ground_texture or _collision_texture != collision_texture or _chunks != visible_chunks
	_ground_texture = ground_texture
	_collision_texture = collision_texture
	_chunks = visible_chunks
	_shader_material.set_shader_parameter("ground_terrain", ground_texture)
	_shader_material.set_shader_parameter("collision_field", collision_texture)
	_shader_material.set_shader_parameter("camera_origin", camera)
	_shader_material.set_shader_parameter("altar_cell", (altar / RTExperimentalPhaseController.CHUNK_SIZE).floor())
	_shader_material.set_shader_parameter("chunk_size", RTExperimentalPhaseController.CHUNK_SIZE)
	_shader_material.set_shader_parameter("height_world", float(HEIGHT_BY_MAP.get(map_key, 6.0)))
	var tint: Color = SIDE_TINT_BY_MAP.get(map_key, Color(0.5, 0.5, 0.5))
	_shader_material.set_shader_parameter("side_tint", Vector3(tint.r, tint.g, tint.b))
	_shader_material.set_shader_parameter("low_resource", low_resource)
	if not visible:
		show()
	if geometry_changed:
		queue_redraw()


func _draw() -> void:
	if _ground_texture == null or _collision_texture == null:
		return
	for chunk in _chunks:
		draw_rect(Rect2(chunk["rect"]), Color.WHITE, true)
