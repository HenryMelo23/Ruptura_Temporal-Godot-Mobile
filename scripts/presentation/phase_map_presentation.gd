extends Node2D

const LIFE_SHADER_CODE := """shader_type canvas_item;
render_mode unshaded;

uniform float elapsed = 0.0;
uniform float motion_scale = 1.0;
uniform bool fluid_surface = true;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float highest = max(base.r, max(base.g, base.b));
	float lowest = min(base.r, min(base.g, base.b));
	float pigment = smoothstep(0.10, 0.27, highest - lowest);
	float perimeter = smoothstep(0.18, 0.32, length(UV - vec2(0.5)));
	float mask = pigment * perimeter;
	vec4 flowing = base;
	if (fluid_surface) {
		vec2 drift = vec2(sin(UV.y * 47.0 + elapsed * 0.65),
			cos(UV.x * 39.0 - elapsed * 0.48));
		vec2 offset = drift * TEXTURE_PIXEL_SIZE * 0.85 * mask * motion_scale;
		flowing = texture(TEXTURE, clamp(UV + offset, TEXTURE_PIXEL_SIZE, vec2(1.0) - TEXTURE_PIXEL_SIZE));
	}
	float ripple = sin(UV.x * 68.0 + UV.y * 43.0 - elapsed * 0.72);
	vec3 color = mix(base.rgb, flowing.rgb, mask);
	color *= 1.0 + ripple * mask * 0.045 * motion_scale;
	COLOR = vec4(color, base.a);
}"""
const STATIC_SHADER_CODE := """shader_type canvas_item;
render_mode unshaded, blend_disabled;

void fragment() {
	COLOR = texture(TEXTURE, UV);
}"""
# World-space sampling blends neighboring cells across irregular strips. The
# authored altar remains part of the atlas; no decal or per-frame image baking.
const CHUNK_SHADER_CODE := """shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform vec2 camera_origin = vec2(0.0);
uniform vec2 altar_cell = vec2(0.0);
uniform sampler2D ground_terrain : filter_nearest;
uniform sampler2D altar_terrain : filter_nearest;
uniform vec2 altar_source_center = vec2(0.5);
uniform float chunk_size = 384.0;
uniform float elapsed = 0.0;
varying vec2 world_position;
void vertex() { world_position = VERTEX + camera_origin; }
float tile_id(vec2 cell) {
	if (all(lessThan(abs(cell - altar_cell), vec2(0.1)))) { return 5.0; }
	float id = mod(cell.x * 7.0 + cell.y * 11.0 + floor(cell.y / 3.0) * 4.0, 15.0);
	return id >= 5.0 ? id + 1.0 : id;
}
vec4 ground_sample(vec2 pixel_size, vec2 cell) {
	float id = tile_id(cell);
	vec2 local = 1.0 - abs(1.0 - mod(world_position / chunk_size - cell, vec2(2.0)));
	// Trim the atlas's ruler-like gravel margins on ordinary terrain only.
	float inset = id == 5.0 ? 0.0 : 0.095;
	local = mix(vec2(inset), vec2(1.0 - inset), local);
	if (id == 5.0) { local += altar_source_center - vec2(0.5); }
	vec2 tile = vec2(mod(id, 4.0), floor(id / 4.0));
	vec2 uv = (tile + local) / 4.0;
	// The altar's centered crop may include its adjacent authored ground.
	// Never clamp to its cell edge: that stretches a row into visible stripes.
	if (id == 5.0) {
		uv = clamp(uv, pixel_size * 0.5, vec2(1.0) - pixel_size * 0.5);
	} else {
		uv = clamp(uv, tile / 4.0 + pixel_size * 0.5,
			(tile + 1.0) / 4.0 - pixel_size * 0.5);
	}
	if (id == 5.0) { return texture(altar_terrain, uv); }
	return texture(ground_terrain, uv);
}
void fragment() {
	vec2 grid = world_position / chunk_size - 0.5;
	vec2 cell = floor(grid);
	vec2 local = fract(grid);
	vec2 ripple = vec2(sin(world_position.y * 0.037) + sin(world_position.y * 0.083),
		sin(world_position.x * 0.041) + sin(world_position.x * 0.071)) * 0.018;
	vec2 weight = smoothstep(vec2(0.47) + ripple, vec2(0.53) + ripple, local);
	vec2 left_cell = cell + vec2(weight.x >= 1.0 ? 1.0 : 0.0, weight.y >= 1.0 ? 1.0 : 0.0);
	vec4 left = ground_sample(TEXTURE_PIXEL_SIZE, left_cell);
	if (weight.y > 0.0 && weight.y < 1.0) {
		left = mix(left, ground_sample(TEXTURE_PIXEL_SIZE, vec2(left_cell.x, cell.y + 1.0)), weight.y);
	}
	vec4 result = left;
	if (weight.x > 0.0 && weight.x < 1.0) {
		vec4 right = ground_sample(TEXTURE_PIXEL_SIZE, cell + vec2(1.0, weight.y >= 1.0 ? 1.0 : 0.0));
		if (weight.y > 0.0 && weight.y < 1.0) {
			right = mix(right, ground_sample(TEXTURE_PIXEL_SIZE, cell + vec2(1.0, 1.0)), weight.y);
		}
		result = mix(left, right, weight.x);
	}
	float energy = smoothstep(0.12, 0.35, result.b - result.g);
	result.rgb *= 1.0 + energy * sin(elapsed * 0.7 + world_position.x * 0.013 + world_position.y * 0.009) * 0.035;
	COLOR = vec4(result.rgb, 1.0);
}
"""
const MAX_MOTES := 18
const LOW_RESOURCE_MOTES := 8
const TINTS := {
	1: Color(0.45, 0.40, 0.52), 2: Color(0.66, 0.77, 0.81),
	3: Color(0.42, 0.52, 0.28), 4: Color(0.55, 0.40, 0.54),
	5: Color(0.30, 0.53, 0.46), 6: Color(0.46, 0.53, 0.31),
	7: Color(0.63, 0.37, 0.24), 9: Color(0.35, 0.48, 0.36),
}

var map_texture: Texture2D
var map_rect := Rect2()
var map_tile_rects: Array[Rect2] = []
var map_chunks: Array[Dictionary] = []
var chunk_material: ShaderMaterial
var life_material: ShaderMaterial
var static_material: ShaderMaterial
var presented_surface: int = -1
var presented_low_resource: bool = false


func _init() -> void:
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	life_material = ShaderMaterial.new()
	var life_shader := Shader.new()
	life_shader.code = LIFE_SHADER_CODE
	life_material.shader = life_shader
	static_material = ShaderMaterial.new()
	var static_shader := Shader.new()
	static_shader.code = STATIC_SHADER_CODE
	static_material.shader = static_shader
	chunk_material = ShaderMaterial.new()
	var chunk_shader := Shader.new()
	chunk_shader.code = CHUNK_SHADER_CODE
	chunk_material.shader = chunk_shader
	material = life_material


func present(texture: Texture2D, rect: Rect2, surface: int, elapsed: float, low_resource: bool) -> void:
	var geometry_changed: bool = texture != map_texture or not rect.is_equal_approx(map_rect) or not map_tile_rects.is_empty() or not map_chunks.is_empty()
	var material_mode_changed: bool = surface != presented_surface or low_resource != presented_low_resource or material == chunk_material
	if geometry_changed:
		map_texture = texture
		map_rect = rect
		map_tile_rects.clear()
		map_chunks.clear()
	_apply_presentation(surface, elapsed, low_resource, geometry_changed, material_mode_changed)


func present_chunks(texture: Texture2D, chunks: Array[Dictionary], camera: Vector2, altar: Vector2, altar_uv: Vector2, surface: int, elapsed: float, low_resource: bool, altar_texture: Texture2D = null) -> void:
	var geometry_changed := map_texture != texture or map_chunks != chunks
	var material_mode_changed := presented_surface != surface or low_resource != presented_low_resource
	map_texture = texture
	map_chunks = chunks
	map_tile_rects.clear()
	_apply_presentation(surface, elapsed, low_resource, geometry_changed, material_mode_changed)
	material = chunk_material
	chunk_material.set_shader_parameter("ground_terrain", texture)
	chunk_material.set_shader_parameter("altar_terrain", altar_texture if altar_texture != null else texture)
	chunk_material.set_shader_parameter("camera_origin", camera)
	chunk_material.set_shader_parameter("altar_source_center", altar_uv)
	chunk_material.set_shader_parameter("altar_cell", (altar / RTExperimentalPhaseController.CHUNK_SIZE).floor())
	chunk_material.set_shader_parameter("elapsed", elapsed)
	chunk_material.set_shader_parameter("chunk_size", RTExperimentalPhaseController.CHUNK_SIZE)


func _apply_presentation(surface: int, elapsed: float, low_resource: bool, geometry_changed: bool, material_mode_changed: bool) -> void:
	if material_mode_changed:
		presented_surface = surface
		presented_low_resource = low_resource
		# The full-screen animated shader and alpha blend dominate Android frame
		# time. The map is opaque, so performance/adaptive modes use a one-sample
		# shader with blending disabled while preserving the authored texture.
		material = static_material if low_resource else life_material
		life_material.set_shader_parameter("fluid_surface", not low_resource and surface not in [1, 4])
		life_material.set_shader_parameter("motion_scale", 0.65 if low_resource else 1.0)
	if not low_resource:
		life_material.set_shader_parameter("elapsed", elapsed)
	if not visible:
		show()
	if geometry_changed:
		queue_redraw()


func _draw() -> void:
	if map_texture == null:
		return
	if not map_chunks.is_empty():
		var source_size := Vector2(map_texture.get_size()) / 4.0
		for chunk in map_chunks:
			var tile: int = chunk["tile"]
			var source := Rect2(Vector2(tile % 4, tile / 4) * source_size, source_size)
			draw_texture_rect_region(map_texture, chunk["rect"], source)
		return
	if map_tile_rects.is_empty():
		draw_texture_rect(map_texture, map_rect, false)
		return
	for tile_rect in map_tile_rects:
		draw_texture_rect(map_texture, tile_rect, true, Color(0.78, 0.80, 0.88))


static func surface_for(game: Node2D) -> int:
	if game.current_phase == 5:
		return int(String(game._boss5_dimension_map_key(game.boss5_dimension)).get_slice("_", 2))
	return clampi(int(game.current_phase), 1, 7)


static func draw_ambient(game: Node2D, camera: Vector2, surface: int) -> void:
	if not game.gfx_particles:
		return
	var count: int = LOW_RESOURCE_MOTES if game._runtime_visual_budget_active() else MAX_MOTES
	var elapsed: float = game.time_alive
	var viewport: Rect2 = game.get_viewport_rect().grow(12.0)
	var tint: Color = TINTS.get(surface, TINTS[1])
	for index in range(count):
		var seed_value := float(index) * 2.399963
		var life := fposmod(elapsed / (14.0 + float(index % 5)) + seed_value, 1.0)
		var origin := Vector2(fposmod(seed_value * 317.0, game.WORLD_SIZE.x), fposmod(seed_value * 191.0, game.WORLD_SIZE.y))
		var down := 1.0 if surface == 2 else -1.0
		var pos := origin + Vector2(sin(elapsed * 0.27 + seed_value) * 22.0 + life * 28.0, (life - 0.5) * 145.0 * down) - camera
		if not viewport.has_point(pos):
			continue
		# Fade at both ends; motion is world-anchored and cannot resemble a projectile.
		tint.a = sin(life * PI) * (0.40 if surface == 2 else 0.26)
		var size := Vector2(3.0, 2.0) if surface != 2 else Vector2(3.0, 3.0)
		game.draw_rect(Rect2(pos.round(), size), tint)
		if surface == 2 and index % 3 == 0:
			game.draw_line(pos + Vector2(-2, 1), pos + Vector2(5, 1), Color(tint, tint.a * 0.55), 1.0)
