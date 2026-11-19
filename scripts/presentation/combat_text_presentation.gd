extends RefCounted

const DAMAGE_FONT_PATH := "res://assets/fonts/World.otf"
const CRITICAL_FONT_PATH := "res://assets/fonts/Top_Menu.otf"
const KIND := "combat_text"
const MERGE_WINDOW_RATIO := 0.78
const MERGE_SCAN_LIMIT := 14

static var _damage_font: Font
static var _critical_font: Font


static func _resolved_font(game: Node2D, critical: bool) -> Font:
	var cached: Font = _critical_font if critical else _damage_font
	if cached != null:
		return cached
	var path := CRITICAL_FONT_PATH if critical else DAMAGE_FONT_PATH
	var loaded := load(path) as Font
	if loaded == null:
		loaded = game.font
	if critical:
		_critical_font = loaded
	else:
		_damage_font = loaded
	return loaded


static func add_damage(game: Node2D, amount: float, pos: Vector2, color: Color, target_key: String, critical: bool = false, accent_label: String = "") -> void:
	# This check happens before allocating the effect dictionary. Turning combat
	# text off therefore removes its update/draw/RAM cost instead of only hiding it.
	if game.damage_text_scale <= 0.0 or amount <= 0.0:
		return
	var rounded_amount := maxi(1, int(round(amount)))
	if not critical and accent_label == "":
		var first_index := maxi(0, game.effects.size() - MERGE_SCAN_LIMIT)
		for index in range(game.effects.size() - 1, first_index - 1, -1):
			var existing: Dictionary = game.effects[index]
			if String(existing.get("kind", "")) != KIND or bool(existing.get("critical", false)):
				continue
			if String(existing.get("target_key", "")) != target_key:
				continue
			var max_life := maxf(0.01, float(existing.get("max", 0.5)))
			if float(existing.get("life", 0.0)) / max_life < MERGE_WINDOW_RATIO:
				continue
			existing["amount"] = int(existing.get("amount", 0)) + rounded_amount
			existing["text"] = str(existing["amount"])
			existing["life"] = minf(max_life, float(existing.get("life", max_life)) + 0.055)
			existing["pos"] = Vector2(existing.get("pos", pos)).lerp(pos, 0.35)
			return
	var life := 0.72 if critical else 0.52
	var base_size := 25 if critical else 18
	game.effects.append({
		"kind": KIND,
		"text": str(rounded_amount),
		"amount": rounded_amount,
		"target_key": target_key,
		"critical": critical,
		"accent_label": accent_label,
		"pos": pos,
		"life": life,
		"max": life,
		"color": color,
		"size": game._damage_text_size(base_size),
		"vel": Vector2(0.0, -34.0 if critical else -24.0),
		"seed": target_key.hash() ^ rounded_amount,
	})


static func draw(game: Node2D, effect: Dictionary, camera: Vector2) -> void:
	var max_life := maxf(0.01, float(effect.get("max", 0.5)))
	var remaining := clampf(float(effect.get("life", 0.0)) / max_life, 0.0, 1.0)
	var progress := 1.0 - remaining
	var critical := bool(effect.get("critical", false))
	var size := int(effect.get("size", 18))
	var pos := Vector2(effect.get("pos", Vector2.ZERO)) - camera
	var tint: Color = effect.get("color", Color.WHITE)
	var fade := clampf(remaining * 2.8, 0.0, 1.0)
	tint.a *= fade
	var font: Font = _resolved_font(game, critical)
	var scale_value := 1.0
	var rotation := 0.0
	if critical:
		if progress < 0.16:
			scale_value = lerpf(0.58, 1.42, progress / 0.16)
		elif progress < 0.34:
			scale_value = lerpf(1.42, 1.04, (progress - 0.16) / 0.18)
		else:
			scale_value = 1.04
		rotation = lerpf(-0.075, 0.0, clampf(progress / 0.28, 0.0, 1.0))
	else:
		scale_value = lerpf(0.78, 1.0, clampf(progress / 0.18, 0.0, 1.0))

	game.draw_set_transform(pos, rotation, Vector2.ONE * scale_value)
	var text := String(effect.get("text", ""))
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var origin := Vector2(-text_size.x * 0.5, font.get_ascent(size) - text_size.y * 0.5)
	var outline_size := maxi(2, int(round(float(size) * (0.16 if critical else 0.11))))
	var outline := Color(0.035, 0.018, 0.02, 0.92 * fade)
	game.draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline_size, outline)
	game.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)
	if critical:
		var impact := clampf(1.0 - absf(progress - 0.16) / 0.16, 0.0, 1.0)
		var accent := Color(1.0, 0.78, 0.16, (0.42 + impact * 0.5) * fade)
		var radius := text_size.x * 0.62 + 12.0 + impact * 9.0
		game.draw_line(Vector2(-radius, 7.0), Vector2(-text_size.x * 0.48, 1.0), accent, 2.2, true)
		game.draw_line(Vector2(radius, 7.0), Vector2(text_size.x * 0.48, 1.0), accent, 2.2, true)
		var label := String(effect.get("accent_label", ""))
		if label == "":
			label = "CRÍTICO"
		var label_size := maxi(9, int(round(float(size) * 0.43)))
		var critical_font := _resolved_font(game, true)
		var label_width := critical_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
		var label_origin := Vector2(-label_width * 0.5, -text_size.y * 0.58)
		game.draw_string_outline(critical_font, label_origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, 2, outline)
		game.draw_string(critical_font, label_origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color(1.0, 0.91, 0.52, fade))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
