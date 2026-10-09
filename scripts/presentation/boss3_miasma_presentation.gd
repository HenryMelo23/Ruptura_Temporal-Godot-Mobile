extends RefCounted

# Presentation only. Never advance timers, consume RNG or modify the replicated snapshot.
# Palette sampled from Pai-Rato's vestments, wax face and Catedral masonry.
const INK := Color("100f17")
const CLOTH := Color("272230")
const MOLD := Color("68733a")
const WAX := Color("b78d37")
const IVORY := Color("f0df9d")
const RESIDUE_META := &"boss3_miasma_visual_residue"


static func _pixel(p: Vector2) -> Vector2:
	return p.snapped(Vector2(2, 2))


static func _opacity(c: Color, alpha: float) -> Color:
	return Color(c.r, c.g, c.b, alpha)


static func _envelope(game: Node2D) -> float:
	var age: float = game.BOSS3_MIASMA_DURATION - game.boss3_miasma_timer
	return clampf(minf(age / 0.28, game.boss3_miasma_timer / 0.3), 0.0, 1.0)


static func _wisp(game: Node2D, p: Vector2, width: float, alpha: float) -> void:
	# A stepped, low lying wax/fume silhouette; no circular emitter or bloom.
	var shape := PackedVector2Array()
	for v in [Vector2(-1, 0), Vector2(-1, -0.16), Vector2(-0.7, -0.16), Vector2(-0.7, -0.32), Vector2(-0.35, -0.32), Vector2(-0.35, -0.46), Vector2(0.12, -0.46), Vector2(0.12, -0.3), Vector2(0.65, -0.3), Vector2(0.65, -0.12), Vector2(1, -0.12), Vector2(1, 0)]:
		var point := _pixel(p + v * width)
		if shape.is_empty() or shape[-1] != point:
			shape.append(point)
	if shape.size() > 1 and shape[-1] == shape[0]:
		shape.remove_at(shape.size() - 1)
	game.draw_colored_polygon(shape, _opacity(MOLD, alpha))
	game.draw_line(_pixel(p + Vector2(-width * 0.65, -4)), _pixel(p + Vector2(width * 0.12, -4)), _opacity(WAX, alpha * 0.7), 2, false)


static func clones(game: Node2D, camera: Vector2) -> void:
	if not game._boss3_miasma_active() or game.boss3_miasma_variant != 1:
		return
	var texture: Texture2D = game._boss_texture()
	if texture == null:
		return
	# Render the real boss and all four decoys together, with identical material,
	# size, shadow and depth policy. No index-dependent clue to the real identity.
	var positions: Array = game.boss3_miasma_clone_positions.duplicate()
	positions.append(game.boss_pos)
	positions.sort_custom(func(a: Vector2, b: Vector2): return a.y < b.y)
	var size: Vector2 = game._boss_draw_size()
	var tex_size := texture.get_size()
	var fit: Vector2 = tex_size * minf(size.x / tex_size.x, size.y / tex_size.y)
	var exchange: float = 1.0 - clampf((game.BOSS3_MIASMA_CLONE_SWAP - game.boss3_miasma_clone_timer) / 0.2, 0.0, 1.0)
	var slices := 6 if game.gfx_low_resource else 10
	for world_pos in positions:
		var p: Vector2 = _pixel(Vector2(world_pos) - camera)
		var phase: float = floorf(Vector2(world_pos).x * 0.07 + Vector2(world_pos).y * 0.03)
		game._draw_dynamic_shadow_fit(texture, p, size, false, true, 0.34)
		var rect := Rect2(p + Vector2(-fit.x * 0.5, size.y * 0.5 - fit.y), fit)
		if not game.gfx_low_resource:
			game.draw_texture_rect(texture, Rect2(rect.position + Vector2(-4, 0), rect.size), false, _opacity(WAX, 0.12 + exchange * 0.14))
			game.draw_texture_rect(texture, Rect2(rect.position + Vector2(4, -2), rect.size), false, _opacity(MOLD, 0.1 + exchange * 0.12))
		for row in range(slices):
			var offset := Vector2(roundf(sin(phase + row * 2.3) * 3.0 * exchange) * 2.0, 0)
			var dst := Rect2(rect.position + Vector2(0, fit.y * row / slices) + offset, Vector2(fit.x, fit.y / slices))
			var src := Rect2(0, tex_size.y * row / slices, tex_size.x, tex_size.y / slices)
			game.draw_texture_rect_region(texture, dst, src, Color(0.94, 0.92, 0.72, 0.94))
		var count := 2 if game.gfx_low_resource else 4
		for i in range(count):
			var breath: float = sin(game.time_alive * 1.3 + phase + i * 2.1)
			var foot := p + Vector2(-40 + i * 25 + breath * 6, size.y * 0.5 + i * 2)
			_wisp(game, foot, 22 + exchange * 16, (0.13 + exchange * 0.16) * _envelope(game))


static func darkness_boundary(angle: float, radius: float, clock: float) -> Vector2:
	# The irregular fringe only moves INWARD: nothing outside the 250px disk leaks.
	var intrusion := 4.0 + 4.0 * (0.5 + 0.5 * sin(angle * 13 + clock * 0.7)) + 3.0 * (0.5 + 0.5 * cos(angle * 21 - clock * 0.4))
	return _pixel(Vector2.from_angle(angle) * (radius - intrusion))


static func darkness(game: Node2D, center: Vector2, viewport: Vector2) -> void:
	var count := 64 if game.gfx_low_resource else 96
	var outer := viewport.length() + center.length() + 500.0
	var radius: float = game.BOSS3_MIASMA_DARK_RADIUS
	var clock: float = game.time_alive
	# Four concave polygons surround the aperture. Batching whole quadrants
	# preserves the exact boundary with 12 draws instead of 3 draws per segment.
	for quadrant in range(4):
		var edge := PackedVector2Array()
		var veil := PackedVector2Array()
		var penumbra := PackedVector2Array()
		var steps := count / 4
		for i in range(steps + 1):
			var angle := (quadrant + float(i) / steps) * PI * 0.5
			var p := darkness_boundary(angle, radius, clock)
			edge.append(center + p)
			veil.append(center + p + p.normalized() * (22 + 8 * sin(angle * 9 + clock * 0.4)))
			penumbra.append(center + _pixel(p.normalized() * (p.length() - 12)))
		var fill := PackedVector2Array([center + Vector2.from_angle(quadrant * PI * 0.5) * outer,
			center + Vector2.from_angle((quadrant + 1) * PI * 0.5) * outer])
		var reverse_edge := edge.duplicate()
		reverse_edge.reverse()
		fill.append_array(reverse_edge)
		game.draw_colored_polygon(fill, INK)
		veil.reverse()
		penumbra.reverse()
		var outer_band := edge.duplicate()
		outer_band.append_array(veil)
		game.draw_colored_polygon(outer_band, _opacity(CLOTH, 0.42))
		var inner_band := edge.duplicate()
		inner_band.append_array(penumbra)
		game.draw_colored_polygon(inner_band, _opacity(CLOTH, 0.42))
	var motes := 8 if game.gfx_low_resource else 12
	for i in range(motes):
		var angle := float(i) * TAU / motes
		var p := darkness_boundary(angle, radius, clock)
		_wisp(game, center + p + p.normalized() * 12, 10, 0.12 * _envelope(game))


static func qte_openness(game: Node2D) -> float:
	# Follow the actual contact flag, including replicas and frozen time. Do not
	# invent a second blink clock (the previous drawing used a different window).
	if qte_contact(game):
		return 0.0
	var progress := clampf(float(game.boss3_miasma_qte_taps) / maxf(1, game.boss3_miasma_qte_required), 0, 1)
	return lerpf(0.035, 0.96, smoothstep(0.0, 1.0, progress))


static func qte_contact(game: Node2D) -> bool:
	if game._is_world_authority():
		return game.boss3_miasma_qte_lids_touching
	# Existing packets carry elapsed/taps, not the host's contact flag. Project
	# that snapshot's exact 0.18s contact window; never run a local blink timer.
	var progress := float(game.boss3_miasma_qte_taps) / maxf(1, game.boss3_miasma_qte_required)
	return fposmod(maxf(0, game.boss3_miasma_qte_elapsed), game.BOSS3_MIASMA_QTE_BLINK_INTERVAL) < 0.18 and progress < 0.98


static func _lid_edge(game: Node2D, viewport: Vector2, openness: float, upper: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	var curves: Dictionary = game._miasma_eye_curves(viewport, openness)
	var source: PackedVector2Array = curves["upper" if upper else "lower"]
	var previous := Vector2.ZERO
	for i in range(source.size()):
		var p := _pixel(source[i])
		if openness <= 0.0:
			p.y = snappedf(viewport.y * 0.5, 2)
		if i > 0:
			var corner := Vector2(p.x, previous.y)
			if result[-1] != corner:
				result.append(corner)
		if result.is_empty() or result[-1] != p:
			result.append(p)
		previous = p
	return result


static func eyelids(game: Node2D, viewport: Vector2, openness: float) -> void:
	for is_upper in [true, false]:
		var edge := _lid_edge(game, viewport, openness, is_upper)
		var side := -1.0 if is_upper else 1.0
		var limit := -30.0 if is_upper else viewport.y + 30.0
		var fill := PackedVector2Array([Vector2(-30, limit)])
		fill.append_array(edge)
		fill.append(Vector2(viewport.x + 30, limit))
		game.draw_colored_polygon(fill, INK)
		# Relief sits on the CLOSED side of the lid, never shifting its opening.
		for band in range(4):
			var rim := PackedVector2Array()
			for j in range(edge.size()):
				var relief := 3 + band * 12 + absf(sin(j * 0.3 + band * 2.7)) * band * 4
				rim.append(_pixel(edge[j] + Vector2(0, side * relief)))
			game.draw_polyline(rim, _opacity(CLOTH if band > 0 else MOLD, 0.82 - band * 0.15), 6 if band == 0 else 14, false)
		var stride := 10 if game.gfx_low_resource else 6
		for i in range(2, edge.size() - 2, stride):
			var p := edge[i] + Vector2(0, side * (18 + i % 7 * 3))
			var cheese_tex: Texture2D = game.textures.get("boss3_cheese")
			if cheese_tex != null:
				# Reuse the real cheese's pits/grain in the closed tissue, not a new asset.
				var crop := Rect2(12 + i % 3 * 8, 12 + i % 2 * 8, 12, 8)
				for layer in range(2 if game.gfx_low_resource else 3):
					var dst := Rect2(_pixel(p + Vector2(-12 + layer * 9, (-12 if is_upper else 2) + side * layer * 14)), Vector2(30, 16))
					game.draw_texture_rect_region(cheese_tex, dst, crop, _opacity(MOLD, 0.2 - layer * 0.04))


static func cheese(game: Node2D, viewport: Vector2, openness: float) -> void:
	var upper := _lid_edge(game, viewport, openness, true)
	var lower := _lid_edge(game, viewport, openness, false)
	var progress := clampf(float(game.boss3_miasma_qte_taps) / maxf(1, game.boss3_miasma_qte_required), 0, 1)
	var count := 10 if game.gfx_low_resource else 16
	for i in range(count):
		var index := clampi(int((i + 0.5) / count * (upper.size() - 1)), 0, upper.size() - 1)
		var top := upper[index]
		var lower_index := clampi(int((i + 0.5) / count * (lower.size() - 1)), 0, lower.size() - 1)
		var bottom := lower[lower_index]
		var gap := maxf(0, bottom.y - top.y)
		var length := minf(gap * 0.34, (18 + i % 5 * 9) * (1.0 - progress * 0.6))
		for step in range(3):
			var width := float(10 - step * 2)
			var start := top + Vector2(-width * 0.5, length * step / 3)
			game.draw_rect(Rect2(_pixel(start), Vector2(width, maxf(2, snappedf(length / 3, 2)))), _opacity(WAX, 0.85 - step * 0.12))
			game.draw_rect(Rect2(_pixel(start + Vector2(2, 0)), Vector2(2, maxf(2, snappedf(length / 3, 2)))), _opacity(IVORY, 0.32))
		game.draw_rect(Rect2(_pixel(bottom + Vector2(-6, -4)), Vector2(12, 4)), _opacity(MOLD, 0.74))
		if progress < 0.65 and i % 3 == 0 and gap > 12:
			# A few thinning strands, not a curtain of bright cables.
			var filament := PackedVector2Array([top, _pixel(top.lerp(bottom, 0.55) + Vector2(4, 0)), bottom])
			game.draw_polyline(filament, _opacity(WAX, (1 - progress) * 0.38), 2, false)


static func faith_link(game: Node2D, camera: Vector2) -> void:
	var from: Vector2 = game.player_pos - camera + Vector2(0, -24)
	var to: Vector2 = game.boss_pos - camera + Vector2(0, -48)
	var side := (to - from).normalized().orthogonal()
	var clock: float = game.boss3_miasma_qte_elapsed
	for strand in range(2):
		var points := PackedVector2Array()
		for i in range(17):
			var t := lerpf(0.12, 0.88, i / 16.0)
			var tension := sin(t * PI) * sin(t * 12 + clock * 2.0 + strand * PI) * 5
			points.append(_pixel(from.lerp(to, t) + side * (tension + strand * 4)))
		game.draw_polyline(points, _opacity(INK, 0.8), 5, false)
		game.draw_polyline(points, _opacity(WAX if strand == 0 else MOLD, 0.7), 2, false)
		var fleck := points[clampi(int(fposmod(clock * 3 + strand * 7, 16)), 0, 16)]
		game.draw_rect(Rect2(fleck, Vector2(3, 3)), IVORY)


static func _label(game: Node2D, value: String, center: Vector2, size: int, color: Color) -> void:
	var font: Font = game.menu_button_font if game.menu_button_font != null else game.font
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var origin := (center - Vector2(width * 0.5, 0)).round()
	game.draw_string_outline(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, INK)
	game.draw_string(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func qte_prompt(game: Node2D, viewport: Vector2) -> void:
	var center := (viewport * 0.5).round()
	var progress := clampf(float(game.boss3_miasma_qte_taps) / maxf(1, game.boss3_miasma_qte_required), 0, 1)
	var overtime: bool = game.boss3_miasma_qte_time_left <= 0
	var accent := Color("da8966") if overtime else IVORY
	# Compact manuscript label at the EXISTING center touch target, no new input.
	var box := Rect2(center - Vector2(156, 49), Vector2(312, 104))
	game.draw_style_box(_panel(), box)
	_label(game, "OLHOS FECHADOS", center + Vector2(0, -26), 14, WAX)
	_label(game, "APERTE ESPAÇO" if game._uses_desktop_ui() else "TOQUE AQUI", center + Vector2(0, -1), 21, IVORY)
	var seconds := "%.1f s" % game.boss3_miasma_qte_time_left
	if overtime:
		seconds = "FÉ CORROMPIDA +%.1f s" % maxf(0, game.boss3_miasma_qte_elapsed - game.BOSS3_MIASMA_QTE_DURATION)
	_label(game, "%d/%d  ·  %s" % [game.boss3_miasma_qte_taps, game.boss3_miasma_qte_required, seconds], center + Vector2(0, 21), 14, accent)
	for i in range(18):
		game.draw_rect(Rect2(center + Vector2(-132 + i * 15, 34), Vector2(12, 4)), WAX if (i + 1) / 18.0 <= progress else CLOTH)
	if qte_contact(game):
		_label(game, "RESISTA", center + Vector2(0, -64), 16, Color("da8966"))


static func _panel() -> StyleBoxFlat:
	# Small reusable resource, cached by the script; no node or particle pool.
	return PanelCache.STYLE


class PanelCache:
	static var STYLE: StyleBoxFlat = create_style()
	static func create_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.063, 0.059, 0.09, 0.96)
		style.border_color = Color("68733a")
		style.set_border_width_all(2)
		style.set_corner_radius_all(0)
		return style


static func overlay(game: Node2D, viewport: Vector2, camera: Vector2) -> void:
	if game.current_phase != 3 or not game.boss_active or game.boss_hp <= 0 or game.player_hp <= 0 or game.online_local_spectator:
		if game.has_meta(RESIDUE_META):
			game.remove_meta(RESIDUE_META)
		return
	if not game._boss3_miasma_active():
		if game.has_meta(RESIDUE_META):
			var age: float = game.time_alive - float(game.get_meta(RESIDUE_META))
			if age >= 0.24 or age < 0:
				game.remove_meta(RESIDUE_META)
			else:
				_edge_residue(game, viewport, (1 - age / 0.24) * 0.18)
		return
	game.set_meta(RESIDUE_META, game.time_alive)
	match int(game.boss3_miasma_variant):
		1:
			_edge_residue(game, viewport, _envelope(game) * 0.22)
		2:
			darkness(game, game.player_pos - camera, viewport)
		4:
			faith_link(game, camera)
			var openness := qte_openness(game)
			eyelids(game, viewport, openness)
			cheese(game, viewport, openness)
			qte_prompt(game, viewport)
	if game.boss3_miasma_variant != 4:
		_label(game, "MIASMA DA VIDA · %ds" % ceili(game.boss3_miasma_timer), Vector2(viewport.x * 0.5, 113), 17, IVORY)


static func _edge_residue(game: Node2D, viewport: Vector2, alpha: float) -> void:
	var count := 10 if game.gfx_low_resource else 18
	for i in range(count):
		var x := viewport.x * (i + 0.5) / count
		var drift: float = sin(game.time_alive * 0.8 + i * 2.3) * 6
		_wisp(game, Vector2(x, 12 + drift), 26, alpha)
		_wisp(game, Vector2(viewport.x - x, viewport.y + drift), 32, alpha)
