class_name RTRuntimeProjectileBatchRenderer
extends RefCounted

# Retained GPU batch for visually simplified basic attacks. Authoritative
# projectile Dictionaries remain untouched; this module only snapshots the
# visible position/direction/color fields into reusable packed arrays.

const FULL_TEXTURE_SIZE := Vector2i(32, 12)
const REDUCED_TEXTURE_SIZE := Vector2i(24, 10)
const EMERGENCY_TEXTURE_SIZE := Vector2i(16, 8)
const INITIAL_CAPACITY := 64

var positions := PackedVector2Array()
var directions := PackedVector2Array()
var colors := PackedColorArray()
var capacity: int = 0
var active_stage: int = -1
var glow_mesh: MultiMesh
var core_mesh: MultiMesh
var streak_texture: Texture2D


func reset() -> void:
	positions.clear()
	directions.clear()
	colors.clear()
	if glow_mesh:
		glow_mesh.visible_instance_count = 0
	if core_mesh:
		core_mesh.visible_instance_count = 0


func begin_frame(stage: int) -> void:
	positions.clear()
	directions.clear()
	colors.clear()
	if stage != active_stage or streak_texture == null:
		active_stage = stage
		streak_texture = _build_streak_texture(_texture_size_for_stage(stage))


func append(screen_pos: Vector2, direction: Vector2, color: Color) -> void:
	positions.append(screen_pos)
	directions.append(direction.normalized() if direction.length_squared() > 0.0001 else Vector2.RIGHT)
	colors.append(color)


func count() -> int:
	return positions.size()


func submit(canvas_item: RID, software_fallback_canvas: CanvasItem = null) -> int:
	var instance_total := positions.size()
	if instance_total <= 0 or not canvas_item.is_valid() or streak_texture == null:
		return 0
	if software_fallback_canvas != null and uses_software_renderer():
		_draw_software_fallback(software_fallback_canvas)
		return instance_total
	_ensure_capacity(instance_total)
	for index in range(instance_total):
		var direction := directions[index]
		var center := positions[index] - direction * 5.0
		var glow_transform := _instance_transform(direction, center, Vector2(31.0, 7.0))
		var core_transform := _instance_transform(direction, center + direction * 1.5, Vector2(24.0, 2.25))
		var color := colors[index]
		glow_mesh.set_instance_transform_2d(index, glow_transform)
		glow_mesh.set_instance_color(index, Color(color.r, color.g, color.b, 0.54))
		core_mesh.set_instance_transform_2d(index, core_transform)
		core_mesh.set_instance_color(index, Color(1.0, 1.0, 1.0, 0.86))
	glow_mesh.visible_instance_count = instance_total
	core_mesh.visible_instance_count = instance_total
	RenderingServer.canvas_item_add_multimesh(canvas_item, glow_mesh.get_rid(), streak_texture.get_rid())
	RenderingServer.canvas_item_add_multimesh(canvas_item, core_mesh.get_rid(), streak_texture.get_rid())
	return instance_total


func _draw_software_fallback(canvas: CanvasItem) -> void:
	var batches: Dictionary = {}
	var batch_colors: Dictionary = {}
	for index in range(positions.size()):
		var color := colors[index]
		var key := color.to_rgba32()
		var points := PackedVector2Array(batches.get(key, PackedVector2Array()))
		points.append(positions[index] - directions[index] * 16.0)
		points.append(positions[index] + directions[index] * 5.0)
		batches[key] = points
		batch_colors[key] = color
	for key in batches:
		var points: PackedVector2Array = batches[key]
		var color: Color = batch_colors[key]
		canvas.draw_multiline(points, Color(color.r, color.g, color.b, 0.56), 5.0, true)
		canvas.draw_multiline(points, Color(1.0, 1.0, 1.0, 0.82), 1.35, true)


static func uses_software_renderer() -> bool:
	var adapter := RenderingServer.get_video_adapter_name().to_lower()
	return adapter.contains("llvmpipe") or adapter.contains("swiftshader") or adapter.contains("software")


func _ensure_capacity(required: int) -> void:
	if glow_mesh == null:
		glow_mesh = _new_multimesh()
		core_mesh = _new_multimesh()
	if required <= capacity:
		return
	capacity = maxi(INITIAL_CAPACITY, _next_power_of_two(required))
	glow_mesh.instance_count = capacity
	core_mesh.instance_count = capacity
	glow_mesh.visible_instance_count = 0
	core_mesh.visible_instance_count = 0


static func _new_multimesh() -> MultiMesh:
	var result := MultiMesh.new()
	result.transform_format = MultiMesh.TRANSFORM_2D
	result.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	result.mesh = quad
	result.instance_count = 0
	return result


func _instance_transform(direction: Vector2, center: Vector2, target_size: Vector2) -> Transform2D:
	var transform := Transform2D(direction.angle(), center)
	transform.x *= target_size.x
	transform.y *= target_size.y
	return transform


static func _texture_size_for_stage(stage: int) -> Vector2i:
	if stage >= 2:
		return EMERGENCY_TEXTURE_SIZE
	if stage == 1:
		return REDUCED_TEXTURE_SIZE
	return FULL_TEXTURE_SIZE


static func _build_streak_texture(size: Vector2i) -> Texture2D:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in range(size.y):
		for x in range(size.x):
			var nx := (float(x) + 0.5) / float(size.x)
			var ny := absf((float(y) + 0.5) / float(size.y) * 2.0 - 1.0)
			var longitudinal := smoothstep(0.0, 0.16, nx) * (1.0 - smoothstep(0.72, 1.0, nx))
			var edge := 1.0 - smoothstep(0.22, 1.0, ny)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, longitudinal * edge))
	return ImageTexture.create_from_image(image)


static func _next_power_of_two(value: int) -> int:
	var result := 1
	while result < value:
		result <<= 1
	return result
