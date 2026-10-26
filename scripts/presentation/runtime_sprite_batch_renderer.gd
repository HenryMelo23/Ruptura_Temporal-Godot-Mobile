class_name RTRuntimeSpriteBatchRenderer
extends RefCounted

# Phase-scoped sprite batches for visually plain crowd members. Textures stay
# authored and unscaled in memory; only instance transforms/colors are packed.

const INITIAL_CAPACITY := 32

var groups: Dictionary = {}
var active_phase: int = -1
var captured_instances: int = 0


func begin_frame(phase: int) -> void:
	if phase != active_phase:
		groups.clear()
		active_phase = phase
	captured_instances = 0
	for group_value in groups.values():
		var group: Dictionary = group_value
		group["positions"] = PackedVector2Array()
		group["sizes"] = PackedVector2Array()
		group["colors"] = PackedColorArray()
		group["flips"] = PackedByteArray()


func can_batch() -> bool:
	# Sprite crowds collapse dozens of identical texture submissions into one or
	# two groups and remain worthwhile even on software Vulkan. Projectile streaks
	# use a separate renderer because their tiny quads regress on that backend.
	return true


func append(texture: Texture2D, center: Vector2, size: Vector2, color: Color, flip_h: bool) -> bool:
	if texture == null or not can_batch():
		return false
	var key := texture.get_rid().get_id()
	if not groups.has(key):
		groups[key] = {
			"texture": texture,
			"mesh": _new_multimesh(),
			"capacity": 0,
			"positions": PackedVector2Array(),
			"sizes": PackedVector2Array(),
			"colors": PackedColorArray(),
			"flips": PackedByteArray(),
		}
	var group: Dictionary = groups[key]
	var positions: PackedVector2Array = group["positions"]
	var sizes: PackedVector2Array = group["sizes"]
	var colors: PackedColorArray = group["colors"]
	var flips: PackedByteArray = group["flips"]
	positions.append(center)
	sizes.append(size)
	colors.append(color)
	flips.append(1 if flip_h else 0)
	group["positions"] = positions
	group["sizes"] = sizes
	group["colors"] = colors
	group["flips"] = flips
	captured_instances += 1
	return true


func submit(canvas_item: RID) -> int:
	if captured_instances <= 0 or not canvas_item.is_valid():
		return 0
	for group_value in groups.values():
		var group: Dictionary = group_value
		var positions: PackedVector2Array = group["positions"]
		var count := positions.size()
		if count <= 0:
			continue
		_ensure_capacity(group, count)
		var sizes: PackedVector2Array = group["sizes"]
		var colors: PackedColorArray = group["colors"]
		var flips: PackedByteArray = group["flips"]
		var multimesh: MultiMesh = group["mesh"]
		for index in range(count):
			var transform := Transform2D(0.0, positions[index])
			transform.x *= sizes[index].x * (-1.0 if flips[index] == 1 else 1.0)
			# QuadMesh UVs are vertically inverted relative to CanvasItem's
			# draw_texture_rect convention used by the legacy entity renderer.
			transform.y *= -sizes[index].y
			multimesh.set_instance_transform_2d(index, transform)
			multimesh.set_instance_color(index, colors[index])
		multimesh.visible_instance_count = count
		var texture: Texture2D = group["texture"]
		RenderingServer.canvas_item_add_multimesh(canvas_item, multimesh.get_rid(), texture.get_rid())
	return captured_instances


static func _new_multimesh() -> MultiMesh:
	var result := MultiMesh.new()
	result.transform_format = MultiMesh.TRANSFORM_2D
	result.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	result.mesh = quad
	return result


static func _ensure_capacity(group: Dictionary, required: int) -> void:
	if required <= int(group["capacity"]):
		return
	var capacity := INITIAL_CAPACITY
	while capacity < required:
		capacity <<= 1
	var multimesh: MultiMesh = group["mesh"]
	multimesh.instance_count = capacity
	multimesh.visible_instance_count = 0
	group["capacity"] = capacity
