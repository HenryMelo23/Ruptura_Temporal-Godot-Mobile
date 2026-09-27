extends Node2D

const LIFE_SHADER = preload("res://shaders/phase_map_life.gdshader")
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
var life_material: ShaderMaterial


func _init() -> void:
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	life_material = ShaderMaterial.new()
	life_material.shader = LIFE_SHADER
	material = life_material


func present(texture: Texture2D, rect: Rect2, surface: int, elapsed: float, low_resource: bool) -> void:
	map_texture = texture
	map_rect = rect
	life_material.set_shader_parameter("elapsed", elapsed)
	life_material.set_shader_parameter("fluid_surface", not low_resource and surface not in [1, 4])
	life_material.set_shader_parameter("motion_scale", 0.65 if low_resource else 1.0)
	show()
	queue_redraw()


func _draw() -> void:
	if map_texture != null:
		draw_texture_rect(map_texture, map_rect, false)


static func surface_for(game: Node2D) -> int:
	if game.current_phase == 5:
		return int(String(game._boss5_dimension_map_key(game.boss5_dimension)).get_slice("_", 2))
	return clampi(int(game.current_phase), 1, 7)


static func draw_ambient(game: Node2D, camera: Vector2, surface: int) -> void:
	if not game.gfx_particles:
		return
	var count: int = LOW_RESOURCE_MOTES if game.gfx_low_resource or game._memory_saver_active() else MAX_MOTES
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
