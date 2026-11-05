class_name RTRuntimeSpriteBatchRenderer
extends RefCounted

# Phase-scoped sprite batches for visually plain crowd members. Textures stay
# authored and unscaled in memory; only instance transforms/colors are packed.

const INITIAL_CAPACITY := 32
var groups: Dictionary = {}
var active_phase: int = -1
var captured_instances: int = 0
var _last_texture: Texture2D = null
var _last_group: Dictionary = {}


func begin_frame(phase: int) -> void:
	if phase != active_phase:
		groups.clear()
		_last_texture = null
		_last_group = {}
		active_phase = phase
	captured_instances = 0
	_clear_groups(groups)


func _clear_groups(target_groups: Dictionary) -> void:
	for group_value in target_groups.values():
		var group: Dictionary = group_value
		if group.has("positions"):
			var positions: Array = group["positions"]
			positions.clear()
		if group.has("sizes"):
			var sizes: Array = group["sizes"]
			sizes.clear()
		var colors: Array = group["colors"]
		colors.clear()
		if group.has("flips"):
			var flips: Array = group["flips"]
			flips.clear()
		if group.has("xforms"):
			var xforms: Array = group["xforms"]
			xforms.clear()
		var mesh: MultiMesh = group["mesh"]
		mesh.visible_instance_count = 0


func can_batch() -> bool:
	# Sprite crowds collapse dozens of identical texture submissions into one or
	# two groups and remain worthwhile even on software Vulkan. Projectile streaks
	# use a separate renderer because their tiny quads regress on that backend.
	return true


func append(texture: Texture2D, center: Vector2, size: Vector2, color: Color, flip_h: bool) -> bool:
	# QuadMesh UVs are vertically inverted relative to CanvasItem's
	# draw_texture_rect convention used by the legacy entity renderer.
	var xform := Transform2D(0.0, Vector2(size.x * (-1.0 if flip_h else 1.0), -size.y), 0.0, center)
	return append_xform(texture, xform, color, center)


# Arbitrary affine instance (rotation/skew/negative scale). The transform maps
# the unit quad centered on the origin; callers own the UV flip convention.
func append_xform(texture: Texture2D, xform: Transform2D, color: Color, center: Vector2 = Vector2.ZERO) -> bool:
	if texture == null or not can_batch():
		return false
	var group: Dictionary
	if texture == _last_texture:
		group = _last_group
	else:
		var key := texture.get_rid().get_id()
		group = groups.get(key, {})
	if group.is_empty():
		var key := texture.get_rid().get_id()
		group = {
			"texture": texture,
			"mesh": _new_multimesh(),
			"capacity": 0,
			"positions": [],
			"colors": [],
			"xforms": [],
		}
		groups[key] = group
	_last_texture = texture
	_last_group = group
	(group["positions"] as Array).append(center)
	(group["colors"] as Array).append(color)
	(group["xforms"] as Array).append(xform)
	captured_instances += 1
	return true


func submit(canvas_item: RID) -> int:
	if captured_instances <= 0 or not canvas_item.is_valid():
		return 0
	for group_value in groups.values():
		var group: Dictionary = group_value
		var xforms: Array = group["xforms"]
		var count := xforms.size()
		if count <= 0:
			continue
		_ensure_capacity(group, count)
		var colors: Array = group["colors"]
		var multimesh: MultiMesh = group["mesh"]
		for index in range(count):
			multimesh.set_instance_transform_2d(index, xforms[index])
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
