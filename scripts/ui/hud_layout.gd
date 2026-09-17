class_name RTHudLayout
extends RefCounted

const UNSAVED_PANEL_POS: = Vector2(-1.0, -1.0)
const SAFE_MARGIN: = Vector2(28.0, 28.0)


static func is_portrait(viewport: Vector2) -> bool:
	return viewport.y > viewport.x


static func saved_center_or_default(saved_pos: Vector2, default_pos: Vector2) -> Vector2:
	if saved_pos != Vector2.ZERO:
		return saved_pos
	return default_pos


static func saved_panel_or_default(saved_pos: Vector2, default_pos: Vector2) -> Vector2:
	if saved_pos != UNSAVED_PANEL_POS:
		return saved_pos
	return default_pos


static func edit_layout_safe_margin(_viewport: Vector2) -> Vector2:
	return SAFE_MARGIN


static func edit_layout_safe_rect(viewport: Vector2) -> Rect2:
	var margin: Vector2 = edit_layout_safe_margin(viewport)
	return Rect2(margin, (viewport - margin * 2.0).max(Vector2(64.0, 64.0)))


static func clamp_layout_point(target: Vector2, viewport: Vector2, padding: float = 28.0) -> Vector2:
	var min_pos: = Vector2(padding, padding)
	var max_pos: = viewport - Vector2(padding, padding)
	if max_pos.x < min_pos.x:
		max_pos.x = min_pos.x
	if max_pos.y < min_pos.y:
		max_pos.y = min_pos.y
	return Vector2(clampf(target.x, min_pos.x, max_pos.x), clampf(target.y, min_pos.y, max_pos.y))


static func clamp_layout_rect_position(target: Vector2, size: Vector2, viewport: Vector2, padding: float = 28.0) -> Vector2:
	var min_pos: = Vector2(padding, padding)
	var max_pos: = viewport - size - Vector2(padding, padding)
	if max_pos.x < min_pos.x:
		max_pos.x = min_pos.x
	if max_pos.y < min_pos.y:
		max_pos.y = min_pos.y
	return Vector2(clampf(target.x, min_pos.x, max_pos.x), clampf(target.y, min_pos.y, max_pos.y))


static func clamp_layout_center(target: Vector2, radius: float, viewport: Vector2, padding: float = 28.0) -> Vector2:
	return clamp_layout_point(target, viewport, padding + radius)


static func default_joy_center(viewport: Vector2) -> Vector2:
	return Vector2(maxf(96.0, viewport.x * 0.13), viewport.y - 84.0)


static func joy_center(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	return saved_center_or_default(saved_pos, default_joy_center(viewport))


static func default_attack_center(viewport: Vector2) -> Vector2:
	var row = _default_touch_row(viewport)
	return row[0]


static func attack_center(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	return saved_center_or_default(saved_pos, default_attack_center(viewport))


static func default_secondary_center(viewport: Vector2) -> Vector2:
	var row = _default_touch_row(viewport)
	return row[2]


static func secondary_center(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	return saved_center_or_default(saved_pos, default_secondary_center(viewport))


static func default_dash_center(viewport: Vector2) -> Vector2:
	var row = _default_touch_row(viewport)
	return row[3]


static func dash_center(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	return saved_center_or_default(saved_pos, default_dash_center(viewport))


static func lacerante_empower_center(
	viewport: Vector2,
	saved_pos: Vector2,
	attack: Vector2,
	skill_position: Vector2,
	skill_scale: float,
	secondary: Vector2,
	dash: Vector2
) -> Vector2:
	if saved_pos != UNSAVED_PANEL_POS:
		return saved_pos
	var skill_radius = 46.0 * skill_scale
	var skill = skill_position + Vector2(skill_radius, skill_radius)
	var occupied = [attack, skill, secondary, dash]
	var candidates = [
		attack + Vector2(-10.0, -145.0),
		skill + Vector2(92.0, -76.0),
		secondary + Vector2(96.0, -72.0),
		attack + Vector2(-148.0, -62.0),
		Vector2(viewport.x * 0.88, viewport.y * 0.44)
	]
	var best = Vector2(candidates[0]).clamp(Vector2(viewport.x * 0.52, 70.0), viewport - Vector2(54.0, 48.0))
	var best_clearance = -INF
	for raw_candidate in candidates:
		var candidate = Vector2(raw_candidate).clamp(Vector2(viewport.x * 0.52, 70.0), viewport - Vector2(54.0, 48.0))
		var clearance = INF
		for control in occupied:
			clearance = min(clearance, candidate.distance_to(Vector2(control)))
		if clearance > best_clearance:
			best_clearance = clearance
			best = candidate
	return best


static func left_panel_width(viewport: Vector2) -> float:
	return 236.0 if not is_portrait(viewport) else min(236.0, viewport.x * 0.46)


static func right_panel_width(viewport: Vector2) -> float:
	return 220.0 if not is_portrait(viewport) else min(220.0, viewport.x * 0.44)


static func aura_panel_size(viewport: Vector2, scale: float) -> Vector2:
	return Vector2(min(224.0, viewport.x * 0.46), 48.0) * scale


static func cards_panel_size(viewport: Vector2, scale: float) -> Vector2:
	return Vector2(min(224.0, viewport.x * 0.46), 94.0) * scale


static func coagulum_panel_size(scale: float) -> Vector2:
	return Vector2(160.0, 48.0) * scale


static func default_left_panel_pos(_viewport: Vector2) -> Vector2:
	return Vector2(16.0, 14.0)


static func left_panel_pos(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	return saved_panel_or_default(saved_pos, default_left_panel_pos(viewport))


static func default_right_panel_pos(viewport: Vector2) -> Vector2:
	var right_w = right_panel_width(viewport)
	return Vector2(viewport.x - right_w - 16.0, 14.0)


static func right_panel_pos(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	return saved_panel_or_default(saved_pos, default_right_panel_pos(viewport))


static func default_boss_panel_pos(viewport: Vector2) -> Vector2:
	return Vector2(viewport.x * 0.5 - 190.0, 16.0)


static func boss_panel_pos(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	return saved_panel_or_default(saved_pos, default_boss_panel_pos(viewport))


static func default_edit_layout_boss_panel_pos(viewport: Vector2) -> Vector2:
	return clamp_layout_rect_position(Vector2(viewport.x * 0.5 - 190.0, 96.0), Vector2(380.0, 30.0), viewport)


static func aura_panel_pos(_viewport: Vector2, saved_pos: Vector2, anchor: Rect2) -> Vector2:
	return saved_panel_or_default(saved_pos, Vector2(anchor.position.x, anchor.end.y + 8.0))


static func cards_panel_pos(_viewport: Vector2, saved_pos: Vector2, anchor: Rect2) -> Vector2:
	return saved_panel_or_default(saved_pos, Vector2(anchor.position.x, anchor.end.y + 62.0))


static func coagulum_hud_center(
	viewport: Vector2,
	saved_pos: Vector2,
	group_width: float,
	orb_radius: float,
	center_y: float
) -> Vector2:
	return saved_panel_or_default(saved_pos, Vector2(viewport.x * 0.5 - group_width * 0.5 + orb_radius, center_y))


static func skill_pos(viewport: Vector2, saved_pos: Vector2, skill_scale: float) -> Vector2:
	if saved_pos != UNSAVED_PANEL_POS:
		return saved_pos
	var radius: float = 46.0 * skill_scale
	var row = _default_touch_row(viewport)
	return Vector2(row[1]) - Vector2(radius, radius)


static func _default_touch_row(viewport: Vector2) -> Array[Vector2]:
	var gap: float = 14.0
	var radii: Array[float] = [62.0, 46.0, 48.0, 52.0]
	var row_width: float = 0.0
	for radius_index in range(radii.size()):
		var radius: float = radii[radius_index]
		row_width += radius * 2.0
		if radius_index < radii.size() - 1:
			row_width += gap
	var left_margin: float = maxf(222.0, viewport.x * 0.34)
	var row_x: float = maxf(left_margin, viewport.x - 18.0 - row_width)
	var row_y: float = viewport.y - 62.0 - 26.0
	var centers: Array[Vector2] = []
	var x: float = row_x
	for radius in radii:
		centers.append(Vector2(x + radius, row_y))
		x += radius * 2.0 + gap
	return centers


static func pause_pos(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	return saved_panel_or_default(saved_pos, Vector2(viewport.x - 72.0, 18.0))


static func boss_call_pos(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	if saved_pos != UNSAVED_PANEL_POS:
		return saved_pos
	var x := viewport.x - (134.0 if is_portrait(viewport) else 170.0)
	var y := 204.0 if is_portrait(viewport) else 184.0
	return Vector2(maxf(18.0, x), y)


static func manual_shop_pos(viewport: Vector2, saved_pos: Vector2) -> Vector2:
	if saved_pos != UNSAVED_PANEL_POS:
		return saved_pos
	var x := viewport.x - (142.0 if is_portrait(viewport) else 178.0)
	var y := 154.0 if is_portrait(viewport) else 134.0
	return Vector2(maxf(18.0, x), y)


static func desktop_button_rects(
	viewport: Vector2,
	include_empower: bool,
	include_detonator: bool,
	include_shop_manual: bool,
	desktop_scale: float = 1.0
) -> Dictionary:
	var rects: = {}
	var scale: float = clampf(desktop_scale, 0.5, 1.0)
	var card_w: = 92.0 * scale
	var card_h: = 96.0 * scale
	# Keep a readable hit-target separation when the desktop rail is reduced.
	# At the minimum 50% scale, cards are 46px wide, so a 32px gutter keeps
	# adjacent centers at least 78px apart and prevents accidental overlaps.
	var gap: = maxf(12.0 * scale, 78.0 - card_w)
	var total_cards: int = 4 + (1 if (include_empower or include_detonator) else 0)
	var total_w: = card_w * float(total_cards) + gap * float(total_cards - 1)
	var x: = viewport.x * 0.5 - total_w * 0.5
	var y: = viewport.y - card_h - 24.0
	rects["attack"] = Rect2(x, y, card_w, card_h)
	rects["skill"] = Rect2(x + (card_w + gap), y, card_w, card_h)
	rects["secondary"] = Rect2(x + (card_w + gap) * 2.0, y, card_w, card_h)
	rects["dash"] = Rect2(x + (card_w + gap) * 3.0, y, card_w, card_h)
	if include_empower:
		rects["lacerante_empower"] = Rect2(x + (card_w + gap) * 4.0, y, card_w, card_h)
	if include_detonator:
		rects["bombastica_detonator"] = Rect2(x + (card_w + gap) * 4.0, y, card_w, card_h)
	rects["pause"] = Rect2(viewport.x - 58.0, 16.0, 42.0, 36.0)
	rects["boss"] = Rect2(viewport.x - 178.0, 186.0, 160.0, 44.0)
	if include_shop_manual:
		rects["shop_manual"] = Rect2(viewport.x - 178.0, 134.0, 160.0, 44.0)
	return rects


static func touch_button_rects(
	attack_center_value: Vector2,
	attack_scale: float,
	skill_position: Vector2,
	skill_scale: float,
	secondary_center_value: Vector2,
	secondary_scale: float,
	dash_center_value: Vector2,
	dash_scale: float,
	empower_center_value: Vector2,
	empower_scale: float,
	include_empower: bool,
	include_detonator: bool,
	pause_position: Vector2,
	boss_position: Vector2,
	shop_position: Vector2,
	include_shop_manual: bool
) -> Dictionary:
	var rects: = {}
	var atk_r = 62.0 * attack_scale
	rects["attack"] = Rect2(attack_center_value - Vector2(atk_r, atk_r), Vector2(atk_r * 2.0, atk_r * 2.0))
	var skill_r = 46.0 * skill_scale
	rects["skill"] = Rect2(skill_position, Vector2(skill_r * 2.0, skill_r * 2.0))
	var secondary_r = 48.0 * secondary_scale
	rects["secondary"] = Rect2(secondary_center_value - Vector2(secondary_r, secondary_r), Vector2(secondary_r * 2.0, secondary_r * 2.0))
	var dash_r = 52.0 * dash_scale
	rects["dash"] = Rect2(dash_center_value - Vector2(dash_r, dash_r), Vector2(dash_r * 2.0, dash_r * 2.0))
	if include_empower:
		var empower_r = 32.0 * empower_scale
		rects["lacerante_empower"] = Rect2(empower_center_value - Vector2(empower_r, empower_r), Vector2(empower_r * 2.0, empower_r * 2.0))
	if include_detonator:
		var det_r = 32.0 * empower_scale
		rects["bombastica_detonator"] = Rect2(empower_center_value - Vector2(det_r, det_r), Vector2(det_r * 2.0, det_r * 2.0))
	rects["pause"] = Rect2(pause_position, Vector2(52.0, 42.0))
	rects["boss"] = Rect2(boss_position, Vector2(96.0, 42.0))
	if include_shop_manual:
		rects["shop_manual"] = Rect2(shop_position, Vector2(104.0, 42.0))
	return rects


static func organized_touch_button_rects(
	viewport: Vector2,
	attack_scale: float,
	skill_scale: float,
	secondary_scale: float,
	dash_scale: float,
	extra_scale: float,
	include_extra: bool
) -> Dictionary:
	# Keep the combat controls in one readable rail. The extra control sits above it
	# so a large touch target never collides with the attack/skill row.
	var gap: float = 14.0
	var left_margin: float = maxf(222.0, viewport.x * 0.34)
	var right_margin: float = 18.0
	var available_width: float = maxf(180.0, viewport.x - left_margin - right_margin)
	var requested_width: float = 124.0 * attack_scale + 92.0 * skill_scale + 96.0 * secondary_scale + 104.0 * dash_scale + gap * 3.0
	var fit: float = minf(1.0, available_width / maxf(1.0, requested_width))
	var attack_radius: float = 62.0 * attack_scale * fit
	var skill_radius: float = 46.0 * skill_scale * fit
	var secondary_radius: float = 48.0 * secondary_scale * fit
	var dash_radius: float = 52.0 * dash_scale * fit
	var row_width: float = attack_radius * 2.0 + skill_radius * 2.0 + secondary_radius * 2.0 + dash_radius * 2.0 + gap * 3.0
	var row_x: float = maxf(left_margin, viewport.x - right_margin - row_width)
	var max_radius: float = maxf(62.0, maxf(attack_radius, maxf(skill_radius, maxf(secondary_radius, dash_radius))))
	var row_y: float = viewport.y - max_radius - 26.0
	var rects: = {}
	var attack_center: = Vector2(row_x + attack_radius, row_y)
	var skill_center: = Vector2(attack_center.x + attack_radius + gap + skill_radius, row_y)
	var secondary_center: = Vector2(skill_center.x + skill_radius + gap + secondary_radius, row_y)
	var dash_center: = Vector2(secondary_center.x + secondary_radius + gap + dash_radius, row_y)
	rects["attack"] = Rect2(attack_center - Vector2(attack_radius, attack_radius), Vector2(attack_radius * 2.0, attack_radius * 2.0))
	rects["skill"] = Rect2(skill_center - Vector2(skill_radius, skill_radius), Vector2(skill_radius * 2.0, skill_radius * 2.0))
	rects["secondary"] = Rect2(secondary_center - Vector2(secondary_radius, secondary_radius), Vector2(secondary_radius * 2.0, secondary_radius * 2.0))
	rects["dash"] = Rect2(dash_center - Vector2(dash_radius, dash_radius), Vector2(dash_radius * 2.0, dash_radius * 2.0))
	if include_extra:
		var extra_radius: float = 32.0 * extra_scale * fit
		var extra_center: = Vector2(skill_center.x + skill_radius * 0.5, row_y - max_radius - extra_radius - 18.0)
		rects["extra"] = Rect2(extra_center - Vector2(extra_radius, extra_radius), Vector2(extra_radius * 2.0, extra_radius * 2.0))
	return rects
