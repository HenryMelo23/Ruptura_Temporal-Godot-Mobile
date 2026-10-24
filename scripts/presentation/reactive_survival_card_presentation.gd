extends RefCounted

## Low-cost world presentation for the two reactive survival cards.


static func draw(game: Node2D, camera: Vector2) -> void:
	var controller = game.reactive_survival_card_controller
	if controller == null:
		return
	_draw_fragments(game, camera, controller.fragments)
	_draw_bastion(game, camera, controller)


static func _draw_fragments(game: Node2D, camera: Vector2, fragments: Array) -> void:
	for fragment in fragments:
		var pos := Vector2(fragment.get("pos", Vector2.ZERO)) - camera
		var target := Vector2(fragment.get("target_pos", fragment.get("pos", Vector2.ZERO))) - camera
		var direction := (target - pos).normalized()
		if direction.length_squared() <= 0.001:
			direction = Vector2.RIGHT
		var side := direction.orthogonal()
		var life_ratio: float = clampf(float(fragment.get("life", 0.0)) / maxf(0.01, float(fragment.get("max", 1.0))), 0.0, 1.0)
		var trail := pos - direction * (18.0 + 8.0 * life_ratio)
		game.draw_line(trail, pos, Color(0.92, 0.08, 0.22, 0.26 + 0.34 * life_ratio), 5.0, true)
		game.draw_line(trail + side * 1.5, pos, Color(0.32, 0.9, 1.0, 0.38 + 0.32 * life_ratio), 1.7, true)
		var shard := PackedVector2Array([
			pos + direction * 10.0,
			pos - direction * 7.0 + side * 5.0,
			pos - direction * 3.0,
			pos - direction * 7.0 - side * 5.0,
		])
		game.draw_colored_polygon(shard, Color(0.08, 0.1, 0.16, 0.98))
		game.draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2], shard[3], shard[0]]), Color(0.42, 0.94, 1.0, 0.86), 1.5, true)


static func _draw_bastion(game: Node2D, camera: Vector2, controller) -> void:
	if controller.bastion_card_count() <= 0:
		return
	var strength: float = clampf(float(controller.stationary_strength), 0.0, 1.0)
	var settle_ratio: float = clampf(float(controller.stationary_time) / maxf(0.01, float(controller.BASTION_SETTLE_TIME)), 0.0, 1.0)
	if strength <= 0.01 and settle_ratio <= 0.01:
		return
	var pos := Vector2(game.player_pos) - camera
	var t := float(game.time_alive)
	if strength < 0.98:
		game.draw_arc(pos + Vector2(0, 13), 39.0, -PI * 0.5, -PI * 0.5 + TAU * settle_ratio, 42, Color(0.48, 0.9, 1.0, 0.22 + 0.34 * settle_ratio), 2.0, true)
	var plate_color := Color(0.34, 0.29, 0.23, 0.28 + 0.52 * strength)
	var edge_color := Color(0.94, 0.68, 0.28, 0.24 + 0.58 * strength)
	var seam_color := Color(0.26, 0.88, 1.0, 0.18 + 0.54 * strength)
	for index in range(4):
		var angle := PI * 0.25 + float(index) * PI * 0.5
		var radial := Vector2.from_angle(angle)
		var side := radial.orthogonal()
		var center := pos + Vector2(0, 14) + radial * (27.0 + sin(t * 2.2 + index) * 1.0)
		var plate := PackedVector2Array([
			center + radial * 13.0,
			center + side * 8.0,
			center - radial * 9.0 + side * 4.0,
			center - radial * 7.0 - side * 5.0,
			center - side * 8.0,
		])
		game.draw_colored_polygon(plate, plate_color)
		game.draw_polyline(PackedVector2Array([plate[0], plate[1], plate[2], plate[3], plate[4], plate[0]]), edge_color, 1.7, true)
		game.draw_line(center - radial * 5.0, center + radial * 8.0, seam_color, 1.5, true)
		var brace_start := center + radial * 6.0
		game.draw_line(brace_start, brace_start + radial * (11.0 + 5.0 * strength), edge_color, 3.0, true)
	if strength > 0.05:
		game.draw_line(pos + Vector2(-28, 27), pos + Vector2(-45, 27), Color(0.3, 0.88, 1.0, 0.24 * strength), 1.5, true)
		game.draw_line(pos + Vector2(28, 31), pos + Vector2(47, 31), Color(0.3, 0.88, 1.0, 0.18 * strength), 1.5, true)
